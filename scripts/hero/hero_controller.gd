class_name HeroController
extends Node

var _hero: HeroBase
var _joystick: VirtualJoystick
var _locked_target: HeroBase
var _attack_timer: float = 0.0

func _ready() -> void:
	_hero = get_parent() as HeroBase

func _process(delta: float) -> void:
	if _hero == null or _hero.is_dead:
		return
	_handle_movement()
	_handle_attack(delta)

func set_joystick(j: VirtualJoystick) -> void:
	_joystick = j

func set_target(target: HeroBase) -> void:
	_locked_target = target

func _handle_movement() -> void:
	if _hero.is_stunned or _joystick == null or not _joystick.is_active:
		_hero.velocity = Vector2.ZERO
		return
	var dir = _joystick.direction
	_hero.velocity = dir * _hero.move_speed
	if dir.x != 0.0:
		_hero.scale.x = 1.0 if dir.x > 0.0 else -1.0

func _handle_attack(delta: float) -> void:
	_attack_timer -= delta
	if _locked_target == null or _locked_target.is_dead:
		_locked_target = null
		return
	var dist = _hero.global_position.distance_to(_locked_target.global_position)
	if dist > _hero.stats.attack_range or _attack_timer > 0.0:
		return
	_locked_target.take_damage(_hero.attack, _hero)
	_hero.gain_xp(5)
	_attack_timer = 1.0 / _hero.stats.attack_speed
