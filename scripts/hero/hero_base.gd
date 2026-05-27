class_name HeroBase
extends CharacterBody2D

const XP_TO_NEXT: Array[int] = [100, 150, 180, 200, 220, 250, 280, 300, 350]

static func calc_respawn_time(lvl: int) -> float:
	return 5.0 + lvl * 2.0

signal died(hero: HeroBase, killer: HeroBase)
signal leveled_up(hero: HeroBase)

@export var stats: HeroStats

var team: int        # GameManager.Team
var player_id: int
var is_player: bool = false

var current_hp: float
var level: int = 1
var xp: int = 0
var is_dead: bool = false
var is_stunned: bool: get = _get_is_stunned

var _stun_timer: float = 0.0
var _spawn_pos: Vector2
var _bonus_attack: float = 0.0
var _bonus_hp: float = 0.0
var _bonus_magic_power: float = 0.0
var _bonus_move_speed: float = 0.0

var max_hp: float:     get = _get_max_hp
var attack: float:     get = _get_attack
var move_speed: float: get = _get_move_speed
var magic_power: float: get = _get_magic_power

func _get_max_hp() -> float:
	return stats.max_hp + (level - 1) * stats.hp_per_level + _bonus_hp
func _get_attack() -> float:
	return stats.attack + (level - 1) * stats.attack_per_level + _bonus_attack
func _get_move_speed() -> float:
	return stats.move_speed + _bonus_move_speed
func _get_magic_power() -> float:
	return _bonus_magic_power
func _get_is_stunned() -> bool:
	return _stun_timer > 0.0

func setup(p_team: int, p_id: int, p_spawn: Vector2) -> void:
	team = p_team
	player_id = p_id
	_spawn_pos = p_spawn
	GoldManager.init_player(player_id)
	add_to_group("heroes")
	add_to_group("team_%d" % team)

func _ready() -> void:
	current_hp = max_hp
	_build_visuals()

func _build_visuals() -> void:
	var rect = ColorRect.new()
	rect.size = Vector2(40, 40)
	rect.position = Vector2(-20, -20)
	rect.color = stats.color if stats else Color.WHITE
	add_child(rect)

func _physics_process(delta: float) -> void:
	if _stun_timer > 0.0:
		_stun_timer -= delta
	if not is_dead:
		move_and_slide()

func take_damage(damage: float, attacker: HeroBase = null) -> void:
	if is_dead:
		return
	var shield = get_node_or_null("GuardianShield") as GuardianShield
	if shield:
		damage = shield.absorb_damage(damage)
	current_hp = max(0.0, current_hp - damage)
	if current_hp <= 0.0:
		_die(attacker)

func _die(killer: HeroBase) -> void:
	is_dead = true
	hide()
	GoldManager.apply_drop(player_id)
	if killer:
		GoldManager.add(killer.player_id, GoldManager.HERO_KILL)
	died.emit(self, killer)
	get_tree().create_timer(calc_respawn_time(level)).timeout.connect(_respawn)

func _respawn() -> void:
	is_dead = false
	current_hp = max_hp
	global_position = _spawn_pos
	show()

func gain_xp(amount: int) -> void:
	if level >= 10:
		return
	xp += amount
	while level < 10 and xp >= XP_TO_NEXT[level - 1]:
		xp -= XP_TO_NEXT[level - 1]
		_level_up()

func _level_up() -> void:
	level += 1
	current_hp = min(current_hp + stats.hp_per_level, max_hp)
	leveled_up.emit(self)

func apply_stun(duration: float) -> void:
	_stun_timer = max(_stun_timer, duration)

func add_bonus_attack(v: float) -> void:      _bonus_attack += v
func add_bonus_hp(v: float) -> void:          _bonus_hp += v; current_hp += v
func add_bonus_magic_power(v: float) -> void: _bonus_magic_power += v
func add_bonus_move_speed(v: float) -> void:  _bonus_move_speed += v

func find_nearest_enemy(range_px: float) -> HeroBase:
	var best: HeroBase = null
	var best_dist = INF
	for node in get_tree().get_nodes_in_group("heroes"):
		var hero = node as HeroBase
		if hero == null or hero.team == team or hero.is_dead:
			continue
		var d = global_position.distance_to(hero.global_position)
		if d <= range_px and d < best_dist:
			best_dist = d
			best = hero
	return best
