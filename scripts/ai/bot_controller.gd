class_name BotController
extends Node

var _hero: HeroBase
var _retreat_pos: Vector2
var _lane_waypoints: Array[Vector2] = []
var _wp_index: int = 0
var _attack_timer: float = 0.0

func _ready() -> void:
	_hero = get_parent() as HeroBase

func set_lane(wps: Array[Vector2], retreat: Vector2) -> void:
	_lane_waypoints = wps
	_retreat_pos = retreat
	_wp_index = 0

func _process(delta: float) -> void:
	if _hero == null or _hero.is_dead or _hero.is_stunned:
		return
	_attack_timer -= delta

	if BotLogic.should_retreat(_hero.current_hp, _hero.max_hp):
		_move_to(_retreat_pos)
		return

	var enemy = _hero.find_nearest_enemy(400.0)
	if enemy != null:
		var dist = _hero.global_position.distance_to(enemy.global_position)
		if BotLogic.is_in_range(dist, _hero.stats.attack_range):
			_try_cast_skill(enemy)
			if _attack_timer <= 0.0:
				enemy.take_damage(_hero.attack, _hero)
				_attack_timer = 1.0 / _hero.stats.attack_speed
		else:
			_move_to(enemy.global_position)
		return

	_push_lane()

func _try_cast_skill(target: HeroBase) -> void:
	for child in _hero.get_children():
		var skill = child as SkillBase
		if skill != null and skill.is_ready:
			skill.try_cast(Vector2.ZERO, target)
			return

func _push_lane() -> void:
	if _wp_index >= _lane_waypoints.size():
		return
	_move_to(_lane_waypoints[_wp_index])
	if _hero.global_position.distance_to(_lane_waypoints[_wp_index]) < 15.0:
		_wp_index += 1

func _move_to(target: Vector2) -> void:
	var dir = _hero.global_position.direction_to(target)
	_hero.velocity = dir * _hero.move_speed
	if dir.x != 0.0:
		_hero.scale.x = 1.0 if dir.x > 0.0 else -1.0
