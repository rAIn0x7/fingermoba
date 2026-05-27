extends Node

enum Team { RADIANT = 0, DIRE = 1 }
enum Phase { PLAYING, GAME_OVER }

signal game_over(winner: int)

var phase: Phase = Phase.PLAYING
var winner: int = -1

# Set by GameScene after it loads
var map_root: Node2D
var radiant_spawns: Array[Vector2] = []
var dire_spawns: Array[Vector2] = []
var radiant_waypoints: Array  # Array of Array[Vector2] per lane
var dire_waypoints: Array

var player_hero: HeroBase

const HERO_SCENE_PATHS = {
	"guardian": "res://scenes/prefabs/guardian.tscn",
	"assassin": "res://scenes/prefabs/assassin.tscn",
	"mage":     "res://scenes/prefabs/mage.tscn",
}

func start_game(scene_root: Node2D) -> void:
	phase = Phase.PLAYING
	winner = -1
	map_root = scene_root
	_spawn_all_heroes(scene_root)

func _spawn_all_heroes(root: Node2D) -> void:
	var guardian = preload("res://scenes/prefabs/guardian.tscn")
	var assassin = preload("res://scenes/prefabs/assassin.tscn")
	var mage     = preload("res://scenes/prefabs/mage.tscn")

	# Player: Radiant guardian, lane mid
	player_hero = _spawn_hero(guardian, Team.RADIANT, 0, radiant_spawns[1], root)
	player_hero.is_player = true

	# Radiant bots
	_spawn_hero(assassin, Team.RADIANT, 1, radiant_spawns[0], root)
	_spawn_hero(mage,     Team.RADIANT, 2, radiant_spawns[2], root)

	# Dire bots
	_spawn_hero(guardian, Team.DIRE, 10, dire_spawns[0], root)
	_spawn_hero(assassin, Team.DIRE, 11, dire_spawns[1], root)
	_spawn_hero(mage,     Team.DIRE, 12, dire_spawns[2], root)

func _spawn_hero(scene: PackedScene, team: int, pid: int, spawn: Vector2, root: Node2D) -> HeroBase:
	var hero = scene.instantiate() as HeroBase
	root.add_child(hero)
	hero.global_position = spawn
	hero.setup(team, pid, spawn)
	if team == Team.DIRE or pid > 0:
		var bot = hero.get_node("BotController") as BotController
		if bot:
			var lane_idx = pid % 3 if pid < 10 else (pid - 10) % 3
			var wps = dire_waypoints[lane_idx] if team == Team.DIRE else radiant_waypoints[lane_idx]
			bot.set_lane(wps, spawn)
	return hero

func on_crystal_destroyed(team: int) -> void:
	if phase != Phase.PLAYING:
		return
	phase = Phase.GAME_OVER
	winner = Team.DIRE if team == Team.RADIANT else Team.RADIANT
	game_over.emit(winner)
