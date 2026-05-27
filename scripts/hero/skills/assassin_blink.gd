class_name AssassinBlink
extends SkillBase

@export var damage_multiplier: float = 2.0
@export var seek_range: float = 300.0

func _ready() -> void:
	super()
	cooldown = 10.0

func cast(_direction: Vector2, target: HeroBase) -> void:
	if target == null:
		target = _hero.find_nearest_enemy(seek_range)
	if target == null:
		return
	var to_target = (_hero.global_position.direction_to(target.global_position))
	_hero.global_position = target.global_position - to_target * 30.0
	target.take_damage(_hero.attack * damage_multiplier, _hero)
