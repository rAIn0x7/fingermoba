extends Node

var items: Array[ItemData] = []

func _ready() -> void:
	_load_items()

func _load_items() -> void:
	var paths = [
		"res://resources/items/sword.tres",
		"res://resources/items/armor.tres",
		"res://resources/items/staff.tres",
		"res://resources/items/boots.tres",
	]
	for path in paths:
		var item = load(path) as ItemData
		if item:
			items.append(item)

func try_buy(hero: HeroBase, item: ItemData) -> bool:
	if not GoldManager.try_spend(hero.player_id, item.cost):
		return false
	hero.add_bonus_attack(item.bonus_attack)
	hero.add_bonus_hp(item.bonus_hp)
	hero.add_bonus_magic_power(item.bonus_magic_power)
	hero.add_bonus_move_speed(item.bonus_move_speed)
	return true
