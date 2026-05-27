class_name MinionSpawner
extends Node

@export var spawn_interval: float = 30.0
@export var minions_per_lane: int = 4

var radiant_waypoints: Array  # Array of Array[Vector2], one per lane
var dire_waypoints: Array
var radiant_spawn: Vector2
var dire_spawn: Vector2

var _timer: float = 5.0  # first wave in 5s
var _minion_scene: PackedScene

func _ready() -> void:
	_minion_scene = preload("res://scenes/prefabs/minion.tscn")

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = spawn_interval
	_spawn_wave(GameManager.Team.RADIANT)
	_spawn_wave(GameManager.Team.DIRE)

func _spawn_wave(team: int) -> void:
	var wps = radiant_waypoints if team == GameManager.Team.RADIANT else dire_waypoints
	var spawn_pos = radiant_spawn if team == GameManager.Team.RADIANT else dire_spawn
	for lane_wps in wps:
		_spawn_lane(team, spawn_pos, lane_wps)

func _spawn_lane(team: int, spawn_pos: Vector2, lane_wps: Array[Vector2]) -> void:
	if lane_wps.is_empty():
		return
	for i in range(minions_per_lane):
		var minion = _minion_scene.instantiate() as MinionController
		get_parent().add_child(minion)
		minion.global_position = spawn_pos + Vector2(randf_range(-20, 20), i * 30.0)
		minion.init(team, lane_wps)
