local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_terms(expr)
	local terms = {}
	local current = ""
	local sign = 1
	for i = 1, #expr do
		local ch = expr:sub(i, i)
		if ch == "+" or ch == "-" then
			if current ~= "" then
				terms[#terms + 1] = { sign = sign, token = current }
				current = ""
			end
			sign = (ch == "+") and 1 or -1
		else
			current = current .. ch
		end
	end
	if current ~= "" then
		terms[#terms + 1] = { sign = sign, token = current }
	end
	return terms
end

local function keep_or_drop(rolls, mode, count)
	if not mode or not count then
		return rolls, {}
	end
	local indexed = {}
	for i, v in ipairs(rolls) do
		indexed[#indexed + 1] = { i = i, v = v }
	end
	table.sort(indexed, function(a, b)
		if a.v == b.v then
			return a.i < b.i
		end
		return a.v < b.v
	end)

	local keep = {}
	if mode == "kh" then
		for i = #indexed - count + 1, #indexed do
			local item = indexed[i]
			if item then
				keep[item.i] = true
			end
		end
	elseif mode == "kl" then
		for i = 1, count do
			local item = indexed[i]
			if item then
				keep[item.i] = true
			end
		end
	elseif mode == "dh" then
		for i = 1, #indexed - count do
			local item = indexed[i]
			if item then
				keep[item.i] = true
			end
		end
	elseif mode == "dl" then
		for i = count + 1, #indexed do
			local item = indexed[i]
			if item then
				keep[item.i] = true
			end
		end
	end

	local kept, dropped = {}, {}
	for i, v in ipairs(rolls) do
		if keep[i] then
			kept[#kept + 1] = v
		else
			dropped[#dropped + 1] = v
		end
	end
	return kept, dropped
end

local function roll_die(sides)
	return math.random(1, sides)
end

local VISUAL_DIE_ITEMS = {
	[2] = "dice_classic:coin",
	[4] = "dice_classic:classic_d4",
	[6] = "dice_classic:classic_d6",
	[8] = "dice_classic:classic_d8",
	[12] = "dice_classic:classic_d12",
	[20] = "dice_classic:classic_d20",
}

local discovered_visual_items = {}

local function find_visual_die_item(sides)
	if discovered_visual_items[sides] ~= nil then
		return discovered_visual_items[sides]
	end

	local preferred = VISUAL_DIE_ITEMS[sides]
	if preferred and core.registered_items and core.registered_items[preferred] then
		discovered_visual_items[sides] = preferred
		return preferred
	end

	local first_fallback
	for item_name, def in pairs(core.registered_items or {}) do
		if type(def) == "table" and type(def.groups) == "table" then
			for group_name, group_val in pairs(def.groups) do
				if type(group_name) == "string" and group_name:sub(1, 5) == "dice_" and tonumber(group_val) == sides then
					if not item_name:find("template", 1, true) then
						discovered_visual_items[sides] = item_name
						return item_name
					end
					first_fallback = first_fallback or item_name
				end
			end
		end
	end

	discovered_visual_items[sides] = first_fallback or false
	return discovered_visual_items[sides] or nil
end

local function resolve_visual_player(opts)
	if type(opts.player_name) == "string" and opts.player_name ~= "" then
		local p = core.get_player_by_name(opts.player_name)
		if p then
			return p
		end
	end

	if type(opts.token_id) == "string" and opts.token_id ~= "" and dnd3.token_get then
		local token = dnd3.token_get(opts.token_id)
		if token and token.owner and token.owner ~= "" then
			local p = core.get_player_by_name(token.owner)
			if p then
				return p
			end
		end
	end
	return nil
end

local function visualize_expression(expr, opts)
	if opts.visual == false then
		return
	end
	if not (_G.dice and type(dice.throw_die) == "function") then
		return
	end

	local player = resolve_visual_player(opts)
	if not player then
		return
	end

	for _, term in ipairs(split_terms(expr)) do
		local token = trim(term.token)
		local count_s, sides_s = token:match("^(%d*)d(%d+)")
		local count = tonumber(count_s) or 1
		local sides = tonumber(sides_s)
		if sides then
			local die_item = find_visual_die_item(sides)
			if die_item then
				count = math.max(1, math.min(count, 20))
				for _ = 1, count do
					pcall(dice.throw_die, player, ItemStack(die_item))
				end
			end
		end
	end
end

local function roll_term(token)
	token = trim(token)
	local count_s, sides_s, mod_s, explode = token:match("^(%d*)d(%d+)([kd][hl]%d+)?(!?)$")
	if not sides_s then
		local number = tonumber(token)
		if not number then
			return nil, "invalid token: " .. token
		end
		return {
			total = number,
			kind = "flat",
			token = token,
			rolls = { number },
			dropped = {},
		}
	end

	local count = tonumber(count_s) or 1
	local sides = tonumber(sides_s)
	if count < 1 or count > 200 then
		return nil, "dice count out of range"
	end
	if sides < 2 or sides > 1000 then
		return nil, "dice sides out of range"
	end

	local rolls = {}
	local explode_count = 0
	for _ = 1, count do
		local r = roll_die(sides)
		rolls[#rolls + 1] = r
		if explode == "!" then
			while r == sides and explode_count < 100 do
				r = roll_die(sides)
				rolls[#rolls + 1] = r
				explode_count = explode_count + 1
			end
		end
	end

	local mode, mode_count
	if mod_s then
		mode = mod_s:sub(1, 2)
		mode_count = tonumber(mod_s:sub(3))
	end

	local kept, dropped = keep_or_drop(rolls, mode, mode_count)
	local total = 0
	for _, v in ipairs(kept) do
		total = total + v
	end

	return {
		total = total,
		kind = "dice",
		token = token,
		rolls = rolls,
		kept = kept,
		dropped = dropped,
		mode = mode,
		mode_count = mode_count,
		exploding = explode == "!",
	}
end

local function eval_expression(expr)
	local terms = split_terms(expr)
	if #terms == 0 then
		return nil, "empty expression"
	end

	local detail = {}
	local total = 0
	for _, term in ipairs(terms) do
		local rolled, err = roll_term(term.token)
		if not rolled then
			return nil, err
		end
		rolled.sign = term.sign
		detail[#detail + 1] = rolled
		total = total + (rolled.total * term.sign)
	end

	return {
		expression = expr,
		total = total,
		terms = detail,
	}
end

function dnd3._roll_internal(expression, opts)
	opts = opts or {}
	expression = trim(expression or "")
	if expression == "" then
		return nil, "expression is required"
	end

	if opts.advantage or opts.disadvantage then
		visualize_expression(expression, opts)
		local first, err = eval_expression(expression)
		if not first then
			return nil, err
		end
		visualize_expression(expression, opts)
		local second, err2 = eval_expression(expression)
		if not second then
			return nil, err2
		end

		local pick_first
		if opts.advantage then
			pick_first = first.total >= second.total
		else
			pick_first = first.total <= second.total
		end
		local picked = pick_first and first or second

		return {
			expression = expression,
			total = picked.total,
			mode = opts.advantage and "advantage" or "disadvantage",
			first = first,
			second = second,
			picked = pick_first and 1 or 2,
		}
	end

	visualize_expression(expression, opts)
	return eval_expression(expression)
end

core.register_chatcommand("dnd3_roll", {
	params = "<expression>",
	description = "Roll a dnd3 dice expression (example: 1d20+5, 4d6dl1)",
	func = function(name, param)
		if not dnd3.can(name, "dice_roll") then
			return false, "You are not allowed to roll in this session"
		end
		local result, err = dnd3.roll(param, { player_name = name })
		if not result then
			return false, err
		end
		local msg = string.format("[dnd3] %s rolled %s = %d", name, result.expression, result.total)
		core.chat_send_all(msg)
		return true, msg
	end,
})
