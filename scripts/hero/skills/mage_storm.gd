class_name MageStorm
extends SkillBase

@export var damage_per_second: float = 120.0
@export var duration: float = 3.0
@export var radius: float = 120.0
@export var cast_range: float = 180.0

func _ready() -> void:
	super()
	cooldown = 15.0

func cast(direction: Vector2, target: HeroBase) -> void:
	var center = target.global_position if target != null \
		else _hero.global_position + direction.normalized() * cast_range
	_do_storm(center)

func _do_storm(center: Vector2) -> void:
	var elapsed = 0.0
	while elapsed < duration:
		elapsed += get_process_delta_time()
		var amp = 1.0 + _hero.magic_power / 100.0
		for node in _hero.get_tree().get_nodes_in_group("heroes"):
			var hero = node as HeroBase
			if hero == null or hero.team == _hero.team or hero.is_dead:
				continue
			if center.distance_to(hero.global_position) <= radius:
				hero.take_damage(damage_per_second * amp * get_process_delta_time(), _hero)
		await _hero.get_tree().process_frame
