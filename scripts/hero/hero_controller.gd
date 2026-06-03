class_name HeroController
extends Node

var _hero: HeroBase
var _joystick: VirtualJoystick
var _locked_target: HeroBase
var _attack_timer: float = 0.0
var _skills: Array = []

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

# Desktop: WASD / 方向键移动（触摸摇杆未激活时生效）
func _keyboard_dir() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		d.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		d.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		d.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		d.y += 1.0
	return d.normalized()

func _handle_movement() -> void:
	if _hero.is_stunned:
		_hero.velocity = Vector2.ZERO
		return
	var dir := Vector2.ZERO
	if _joystick != null and _joystick.is_active:
		dir = _joystick.direction
	else:
		dir = _keyboard_dir()
	_hero.velocity = dir * _hero.move_speed
	if dir.x != 0.0:
		_hero.scale.x = 1.0 if dir.x > 0.0 else -1.0

# Desktop: Q / E 释放技能 A / B（触屏用屏幕上的技能按钮）
func _unhandled_input(event: InputEvent) -> void:
	if _hero == null or _hero.is_dead:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc = (event as InputEventKey).physical_keycode
		if kc == KEY_Q:
			_cast_skill(0)
		elif kc == KEY_E:
			_cast_skill(1)

func _cast_skill(index: int) -> void:
	if _skills.is_empty():
		for c in _hero.get_children():
			if c is SkillBase:
				_skills.append(c)
	if index >= 0 and index < _skills.size():
		(_skills[index] as SkillBase).try_cast(_keyboard_dir())

func _handle_attack(delta: float) -> void:
	_attack_timer -= delta
	if _locked_target == null or _locked_target.is_dead:
		_locked_target = _hero.find_nearest_enemy(_hero.stats.attack_range)
	if _locked_target == null:
		return
	var dist = _hero.global_position.distance_to(_locked_target.global_position)
	if dist > _hero.stats.attack_range or _attack_timer > 0.0:
		return
	_locked_target.take_damage(_hero.attack, _hero)
	_hero.gain_xp(5)
	_attack_timer = 1.0 / _hero.stats.attack_speed
