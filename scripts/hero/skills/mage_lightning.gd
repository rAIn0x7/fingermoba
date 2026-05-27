class_name MageLightning
extends SkillBase

@export var primary_damage: float = 280.0
@export var chain_damage: float = 140.0
@export var chain_count: int = 2
@export var chain_radius: float = 150.0
@export var projectile_speed: float = 600.0
@export var max_range: float = 500.0

func _ready() -> void:
	super()
	cooldown = 7.0

func cast(direction: Vector2, _target: HeroBase) -> void:
	var dir = direction if direction != Vector2.ZERO \
		else (Vector2.UP if _hero.team == GameManager.Team.RADIANT else Vector2.DOWN)
	_fire_bolt(dir.normalized())

func _fire_bolt(dir: Vector2) -> void:
	var pos = _hero.global_position
	var traveled = 0.0

	while traveled < max_range:
		var step = projectile_speed * get_process_delta_time()
		pos += dir * step
		traveled += step

		for node in _hero.get_tree().get_nodes_in_group("heroes"):
			var hero = node as HeroBase
			if hero == null or hero.team == _hero.team or hero.is_dead:
				continue
			if pos.distance_to(hero.global_position) < 25.0:
				var amp = 1.0 + _hero.magic_power / 100.0
				hero.take_damage(primary_damage * amp, _hero)
				_chain(hero, amp)
				return
		await _hero.get_tree().process_frame

func _chain(first: HeroBase, amp: float) -> void:
	var chained = 0
	for node in _hero.get_tree().get_nodes_in_group("heroes"):
		if chained >= chain_count:
			break
		var hero = node as HeroBase
		if hero == null or hero == first or hero.team == _hero.team or hero.is_dead:
			continue
		if first.global_position.distance_to(hero.global_position) <= chain_radius:
			hero.take_damage(chain_damage * amp, _hero)
			chained += 1
