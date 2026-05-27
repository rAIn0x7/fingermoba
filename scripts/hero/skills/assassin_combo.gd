class_name AssassinCombo
extends SkillBase

@export var hit_count: int = 3
@export var per_hit_multiplier: float = 0.6
@export var time_between_hits: float = 0.15

func _ready() -> void:
	super()
	cooldown = 6.0

func cast(_direction: Vector2, target: HeroBase) -> void:
	if target == null:
		target = _hero.find_nearest_enemy(_hero.stats.attack_range * 1.5)
	if target != null:
		_do_combo(target)

func _do_combo(target: HeroBase) -> void:
	for i in range(hit_count):
		if target == null or target.is_dead:
			return
		target.take_damage(_hero.attack * per_hit_multiplier, _hero)
		await get_tree().create_timer(time_between_hits).timeout
