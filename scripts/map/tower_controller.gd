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
	var target = _find_nearest_enemy_hero()
	if target == null:
		return
	target.take_damage(attack)
	_attack_timer = attack_cooldown

func _find_nearest_enemy_hero() -> HeroBase:
	var best: HeroBase = null
	var best_dist = INF
	for node in get_tree().get_nodes_in_group("heroes"):
		var hero = node as HeroBase
		if hero == null or hero.team == team or hero.is_dead:
			continue
		var d = global_position.distance_to(hero.global_position)
		if d <= attack_range and d < best_dist:
			best_dist = d
			best = hero
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
