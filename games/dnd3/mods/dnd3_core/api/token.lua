function dnd3.register_token(id, def)
	return dnd3.token_set(id, def)
end

function dnd3.move_token(id, pos)
	return dnd3.token_move(id, pos)
end

function dnd3.transform_token(id, transform)
	return dnd3.token_transform(id, transform)
end
