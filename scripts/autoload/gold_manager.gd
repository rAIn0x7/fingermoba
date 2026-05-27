extends Node

const MINION_KILL: int = 40
const HERO_KILL:   int = 200
const HERO_ASSIST: int = 100
const TOWER_KILL:  int = 150
const DROP_RATE:   float = 0.5

signal gold_changed(player_id: int)

var _gold: Dictionary = {}

func init_player(player_id: int) -> void:
	_gold[player_id] = 0

func add(player_id: int, amount: int) -> void:
	if player_id not in _gold:
		_gold[player_id] = 0
	_gold[player_id] = max(0, _gold[player_id] + amount)
	gold_changed.emit(player_id)

func get_gold(player_id: int) -> int:
	return _gold.get(player_id, 0)

func calculate_drop(player_id: int) -> int:
	return int(get_gold(player_id) * DROP_RATE)

func apply_drop(player_id: int) -> void:
	if player_id in _gold:
		_gold[player_id] -= calculate_drop(player_id)
		gold_changed.emit(player_id)

func can_afford(player_id: int, cost: int) -> bool:
	return get_gold(player_id) >= cost

func try_spend(player_id: int, cost: int) -> bool:
	if not can_afford(player_id, cost):
		return false
	_gold[player_id] -= cost
	gold_changed.emit(player_id)
	return true
