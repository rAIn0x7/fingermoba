class_name GuardianShield
extends SkillBase

@export var shield_amount: float = 300.0
@export var shield_duration: float = 4.0

var _shield_remaining: float = 0.0

func _ready() -> void:
	super()
	cooldown = 12.0

func cast(_direction: Vector2, _target: HeroBase) -> void:
	_shield_remaining = shield_amount
	get_tree().create_timer(shield_duration).timeout.connect(func(): _shield_remaining = 0.0)

func absorb_damage(incoming: float) -> float:
	if _shield_remaining <= 0.0:
		return incoming
	var absorbed = min(_shield_remaining, incoming)
	_shield_remaining -= absorbed
	return incoming - absorbed
