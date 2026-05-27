class_name MinionController
extends CharacterBody2D

@export var max_hp: float = 400.0
@export var attack: float = 30.0
@export var move_speed: float = 120.0
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 1.2
@export var xp_reward: int = 30
@export var gold_reward: int = 40

var team: int
var is_dead: bool = false

var _current_hp: float
var _attack_timer: float = 0.0
var _waypoints: Array[Vector2] = []
var _wp_index: int = 0

func init(p_team: int, p_waypoints: Array[Vector2]) -> void:
	team = p_team
	_waypoints = p_waypoints
	_current_hp = max_hp
	add_to_group("minions")
	add_to_group("team_%d_minions" % team)
	_build_visual()

func _build_visual() -> void:
	var rect = ColorRect.new()
	rect.size = Vector2(24, 24)
	rect.position = Vector2(-12, -12)
	rect.color = Color.GREEN if team == GameManager.Team.RADIANT else Color.RED
	add_child(rect)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_attack_timer -= delta
	var enemy = _find_nearest_enemy()
	if enemy != null and global_position.distance_to(_get_target_pos(enemy)) <= attack_range:
		if _attack_timer <= 0.0:
			_attack_enemy(enemy)
			_attack_timer = attack_cooldown
		velocity = Vector2.ZERO
	else:
		_follow_waypoints()
	move_and_slide()

func _find_nearest_enemy() -> Node:
	var best: Node = null
	var best_dist = INF
	for group in ["heroes", "towers", "crystals"]:
		for node in get_tree().get_nodes_in_group(group):
			if not _is_enemy_target(node):
				continue
			var d = global_position.distance_to(_get_target_pos(node))
			if d < best_dist:
				best_dist = d
				best = node
	return best

func _is_enemy_target(node: Node) -> bool:
	if node is HeroBase:
		return (node as HeroBase).team != team and not (node as HeroBase).is_dead
	if node is MinionController:
		return (node as MinionController).team != team and not (node as MinionController).is_dead
	if node is TowerController:
		return (node as TowerController).team != team and not (node as TowerController).is_destroyed
	if node is Crystal:
		return (node as Crystal).team != team and not (node as Crystal).is_destroyed
	return false

func _get_target_pos(node: Node) -> Vector2:
	return (node as Node2D).global_position

func _attack_enemy(enemy: Node) -> void:
	if enemy is HeroBase:   (enemy as HeroBase).take_damage(attack)
	elif enemy is MinionController: (enemy as MinionController).take_damage(attack, null)
	elif enemy is TowerController:  (enemy as TowerController).take_damage(attack)
	elif enemy is Crystal:          (enemy as Crystal).take_damage(attack)

func _follow_waypoints() -> void:
	if _wp_index >= _waypoints.size():
		velocity = Vector2.ZERO
		return
	var target = _waypoints[_wp_index]
	velocity = global_position.direction_to(target) * move_speed
	if global_position.distance_to(target) < 8.0:
		_wp_index += 1

func take_damage(damage: float, killer: HeroBase) -> void:
	if is_dead:
		return
	_current_hp = max(0.0, _current_hp - damage)
	if _current_hp <= 0.0:
		_die(killer)

func _die(killer: HeroBase) -> void:
	is_dead = true
	if killer != null:
		GoldManager.add(killer.player_id, gold_reward)
		killer.gain_xp(xp_reward)
	queue_free()
