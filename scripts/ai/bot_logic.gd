class_name BotLogic

static func should_retreat(current_hp: float, max_hp: float) -> bool:
	return current_hp / max_hp < 0.20

static func is_in_range(distance: float, range_px: float) -> bool:
	return distance <= range_px
