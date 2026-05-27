class_name SkillBase
extends Node

@export var cooldown: float = 8.0

var cooldown_remaining: float = 0.0
var is_ready: bool: get = _get_is_ready

var _hero: HeroBase

func _get_is_ready() -> bool:
	return cooldown_remaining <= 0.0

func _ready() -> void:
	_hero = get_parent() as HeroBase

func _process(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining -= delta

func try_cast(direction: Vector2, target: HeroBase = null) -> void:
	if not is_ready or _hero.is_dead or _hero.is_stunned:
		return
	cooldown_remaining = cooldown
	cast(direction, target)

func cast(_direction: Vector2, _target: HeroBase) -> void:
	pass  # override in subclasses
