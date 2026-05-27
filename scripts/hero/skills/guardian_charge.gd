class_name GuardianCharge
extends SkillBase

@export var dash_distance: float = 200.0
@export var dash_speed: float = 1000.0
@export var stun_duration: float = 1.0
@export var damage: float = 80.0

func _ready() -> void:
	super()
	cooldown = 8.0

func cast(direction: Vector2, _target: HeroBase) -> void:
	var dir = direction if direction != Vector2.ZERO \
		else (Vector2.UP if _hero.team == GameManager.Team.RADIANT else Vector2.DOWN)
	_do_dash(dir.normalized())

func _do_dash(dir: Vector2) -> void:
	var dest = _hero.global_position + dir * dash_distance
	var duration = dash_distance / dash_speed
	var elapsed = 0.0
	var start = _hero.global_position
	var hit_heroes: Array = []

	while elapsed < duration:
		elapsed += get_process_delta_time()
		_hero.global_position = start.lerp(dest, elapsed / duration)
		for node in _hero.get_tree().get_nodes_in_group("heroes"):
			var hero = node as HeroBase
			if hero == null or hero.team == _hero.team or hero.is_dead:
				continue
			if hero in hit_heroes:
				continue
			if _hero.global_position.distance_to(hero.global_position) < 40.0:
				hero.take_damage(damage, _hero)
				hero.apply_stun(stun_duration)
				hit_heroes.append(hero)
		await _hero.get_tree().process_frame

	_hero.global_position = dest
