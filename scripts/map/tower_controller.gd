class_name TowerController
extends StaticBody2D

@export var team: int
@export var max_hp: float = 2000.0
@export var attack: float = 120.0
@export var attack_range: float = 200.0
@export var attack_cooldown: float = 1.5
@export var physical_armor: float = 0.3

var is_destroyed: bool = false
var _current_hp: float
var _attack_timer: float = 0.0

func _ready() -> void:
	_current_hp = max_hp
	add_to_group("towers")

func _process(delta: float) -> void:
	if is_destroyed:
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	var target = _find_nearest_enemy()
	if target == null:
		return
	if target is HeroBase:
		(target as HeroBase).take_damage(attack)
	elif target is MinionController:
		(target as MinionController).take_damage(attack, null)
	_attack_timer = attack_cooldown

func _find_nearest_enemy() -> Node:
	var best: Node = null
	var best_dist = INF
	# Prioritize minions (standard MOBA tower behavior)
	for node in get_tree().get_nodes_in_group("minions"):
		var m = node as MinionController
		if m == null or m.team == team or m.is_dead:
			continue
		var d = global_position.distance_to(m.global_position)
		if d <= attack_range and d < best_dist:
			best_dist = d
			best = m
	if best != null:
		return best
	for node in get_tree().get_nodes_in_group("heroes"):
		var h = node as HeroBase
		if h == null or h.team == team or h.is_dead:
			continue
		var d = global_position.distance_to(h.global_position)
		if d <= attack_range and d < best_dist:
			best_dist = d
			best = h
	return best

func take_damage(damage: float, is_magic: bool = false) -> void:
	if is_destroyed:
		return
	var reduced = damage if is_magic else damage * (1.0 - physical_armor)
	_current_hp = max(0.0, _current_hp - reduced)
	if _current_hp <= 0.0:
		_destroy()

func _destroy() -> void:
	is_destroyed = true
	hide()
	# Award gold to all enemies
	for node in get_tree().get_nodes_in_group("heroes"):
		var hero = node as HeroBase
		if hero != null and hero.team != team and not hero.is_dead:
			GoldManager.add(hero.player_id, GoldManager.TOWER_KILL / 3)
