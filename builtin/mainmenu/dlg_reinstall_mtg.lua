-- dnd3
-- Copyright (C) 2023 Gregor Parzefall
-- SPDX-License-Identifier: LGPL-2.1-or-later

---- IMPORTANT ----
-- This whole file can be removed after a while.
-- It was only directly useful for upgrades from 5.7.0 to 5.8.0, but
-- maybe some odd fellow directly upgrades from 5.6.1 to 5.9.0 in the future...
-- see <https://github.com/dnd3-org/dnd3/pull/13850> in case it's not obvious
---- ----

local SETTING_NAME = "no_mtg_notification"

function check_reinstall_mtg(parent)
	-- used to be in dnd3.conf
	if core.settings:get_bool(SETTING_NAME) then
		cache_settings:set_bool(SETTING_NAME, true)
		core.settings:remove(SETTING_NAME)
	end

	if cache_settings:get_bool(SETTING_NAME) then
		return parent
	end

	local games = core.get_games()
	for _, game in ipairs(games) do
		if game.id == "dnd3" then
			cache_settings:set_bool(SETTING_NAME, true)
			return parent
		end
	end

	local mtg_world_found = false
	local worlds = core.get_worlds()
	for _, world in ipairs(worlds) do
		if world.gameid == "dnd3" then
			mtg_world_found = true
			break
		end
	end
	if not mtg_world_found then
		cache_settings:set_bool(SETTING_NAME, true)
		return parent
	end

	local dlg = create_reinstall_mtg_dlg()
	dlg:set_parent(parent)
	parent:hide()
	dlg:show()
	ui.update()

	return dlg
end

local function get_formspec(dialogdata)
	local markup = table.concat({
		"<big>", hgettext("dnd3 Game is no longer installed by default"), "</big>\n",
		hgettext("For a long time, dnd3 shipped with a default game called \"dnd3 Game\". " ..
				"Since version 5.8.0, dnd3 ships without a default game."), "\n",
		hgettext("If you want to continue playing in your dnd3 Game worlds, you need to reinstall dnd3 Game."),
	})

	return table.concat({
		"formspec_version[6]",
		"size[12.8,7]",
		"hypertext[0.375,0.375;12.05,5.2;text;", core.formspec_escape(markup), "]",
		"container[0.375,5.825]",
		"style[dismiss;bgcolor=red]",
		-- TRANSLATORS: Dismiss a dialog window/message
		"button[0,0;4,0.8;dismiss;", fgettext("Dismiss"), "]",
		"button[4.25,0;8,0.8;reinstall;", fgettext("Reinstall dnd3 Game"), "]",
		"container_end[]",
	})
end

local function buttonhandler(this, fields)
	if fields.reinstall then
		local parent = this.parent

		-- Don't set "no_mtg_notification" here so that the dialog will be shown
		-- again if downloading MTG fails for whatever reason.
		this:delete()

		local dlg = create_contentdb_dlg(nil, "dnd3/dnd3")
		dlg:set_parent(parent)
		parent:hide()
		dlg:show()

		return true
	end

	if fields.dismiss then
		cache_settings:set_bool(SETTING_NAME, true)
		this:delete()
		return true
	end
end

local function eventhandler(event)
	if event == "DialogShow" then
		mm_game_theme.set_engine()
		return true
	elseif event == "MenuQuit" then
		-- Don't allow closing the dialog with ESC, but still allow exiting
		-- dnd3
		core.close()
		return true
	end
	return false
end

function create_reinstall_mtg_dlg()
	local dlg = dialog_create("dlg_reinstall_mtg", get_formspec,
			buttonhandler, eventhandler)
	return dlg
end
