function dnd3.apply_effect(target, effect)
	return {
		applied = true,
		target = target,
		effect = effect,
		timestamp = core.get_us_time(),
	}
end
