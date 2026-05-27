class_name GameScene
extends Node2D

const TOWER_SCENE = preload("res://scenes/prefabs/tower.tscn")
const CRYSTAL_SCENE = preload("res://scenes/prefabs/crystal.tscn")

var _hud: HeroHUD
var _joystick: VirtualJoystick
var _shop_ui: ShopUI

func _ready() -> void:
	_build_background()
	_setup_map()
	GameManager.start_game(self)
	_setup_spawner()
	_build_hud()
	_build_result_screen()

func _build_background() -> void:
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0.08, 0.16, 0.08, 1)
	add_child(bg)

	# Lane strips
	for x in [150, 540, 930]:
		var lane = ColorRect.new()
		lane.size = Vector2(46, 1920)
		lane.position = Vector2(x - 23, 0)
		lane.color = Color(0.13, 0.22, 0.13, 1)
		add_child(lane)

	# Team base zones
	var radiant_base = ColorRect.new()
	radiant_base.size = Vector2(1080, 140)
	radiant_base.position = Vector2(0, 1780)
	radiant_base.color = Color(0.1, 0.3, 0.1, 0.6)
	add_child(radiant_base)

	var dire_base = ColorRect.new()
	dire_base.size = Vector2(1080, 140)
	dire_base.position = Vector2(0, 0)
	dire_base.color = Color(0.3, 0.1, 0.1, 0.6)
	add_child(dire_base)

func _setup_map() -> void:
	GameManager.radiant_spawns = [
		Vector2(150, 1750), Vector2(540, 1750), Vector2(930, 1750)
	]
	GameManager.dire_spawns = [
		Vector2(150, 170), Vector2(540, 170), Vector2(930, 170)
	]

	var rl0: Array[Vector2] = [Vector2(150, 1400), Vector2(150, 960), Vector2(150, 520), Vector2(150, 170)]
	var rl1: Array[Vector2] = [Vector2(540, 1350), Vector2(540, 960), Vector2(540, 470), Vector2(540, 170)]
	var rl2: Array[Vector2] = [Vector2(930, 1400), Vector2(930, 960), Vector2(930, 520), Vector2(930, 170)]
	GameManager.radiant_waypoints = [rl0, rl1, rl2]

	var dl0: Array[Vector2] = [Vector2(150, 520), Vector2(150, 960), Vector2(150, 1400), Vector2(150, 1750)]
	var dl1: Array[Vector2] = [Vector2(540, 470), Vector2(540, 960), Vector2(540, 1350), Vector2(540, 1750)]
	var dl2: Array[Vector2] = [Vector2(930, 520), Vector2(930, 960), Vector2(930, 1400), Vector2(930, 1750)]
	GameManager.dire_waypoints = [dl0, dl1, dl2]

	# Towers: 3 per team
	_spawn_tower(GameManager.Team.RADIANT, Vector2(150, 1400))
	_spawn_tower(GameManager.Team.RADIANT, Vector2(540, 1350))
	_spawn_tower(GameManager.Team.RADIANT, Vector2(930, 1400))
	_spawn_tower(GameManager.Team.DIRE,    Vector2(150,  520))
	_spawn_tower(GameManager.Team.DIRE,    Vector2(540,  470))
	_spawn_tower(GameManager.Team.DIRE,    Vector2(930,  520))

	# Crystals: 1 per team
	_spawn_crystal(GameManager.Team.RADIANT, Vector2(540, 1840))
	_spawn_crystal(GameManager.Team.DIRE,    Vector2(540,   80))

func _setup_spawner() -> void:
	var spawner = MinionSpawner.new()
	add_child(spawner)
	spawner.radiant_waypoints = GameManager.radiant_waypoints
	spawner.dire_waypoints    = GameManager.dire_waypoints
	spawner.radiant_spawn     = GameManager.radiant_spawns[1]
	spawner.dire_spawn        = GameManager.dire_spawns[1]

func _build_hud() -> void:
	var player = GameManager.player_hero
	if player == null:
		return

	_hud = HeroHUD.new()
	add_child(_hud)

	# HP bar
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(320, 24)
	hp_bg.position = Vector2(380, 28)
	hp_bg.color = Color(0.5, 0.05, 0.05, 1)
	_hud.add_child(hp_bg)

	var hp_fill = ColorRect.new()
	hp_fill.size = Vector2(320, 24)
	hp_fill.color = Color(0.1, 0.85, 0.2, 1)
	hp_bg.add_child(hp_fill)

	_hud.set_hp_bar(hp_bg, hp_fill)

	# Labels
	var level_lbl = Label.new()
	level_lbl.add_theme_font_size_override("font_size", 30)
	level_lbl.position = Vector2(20, 18)
	_hud.add_child(level_lbl)

	var gold_lbl = Label.new()
	gold_lbl.add_theme_font_size_override("font_size", 30)
	gold_lbl.position = Vector2(20, 58)
	_hud.add_child(gold_lbl)

	_hud.set_labels(level_lbl, gold_lbl)

	# Skill buttons (stacked right side)
	var skill_btns: Array[SkillButton] = []
	var idx = 0
	for child in player.get_children():
		if child is SkillBase:
			var btn = SkillButton.new()
			btn.size = Vector2(120, 120)
			btn.position = Vector2(940, 1700 - idx * 140)
			_hud.add_child(btn)
			btn.init(child as SkillBase)
			skill_btns.append(btn)
			idx += 1

	_hud.init(player, skill_btns)

	# Joystick (left half, lower area)
	_joystick = VirtualJoystick.new()
	_joystick.position = Vector2(0, 1300)
	_hud.add_child(_joystick)

	# Player movement controller (added to player hero at runtime)
	var controller = HeroController.new()
	player.add_child(controller)
	controller.set_joystick(_joystick)

	# Disable bot AI on player hero
	var bot = player.get_node_or_null("BotController")
	if bot:
		bot.set_process(false)

	# Shop
	_shop_ui = ShopUI.new()
	_hud.add_child(_shop_ui)
	_shop_ui.setup(player)

	var shop_btn = Button.new()
	shop_btn.text = "商店"
	shop_btn.size = Vector2(130, 70)
	shop_btn.position = Vector2(18, 1820)
	shop_btn.add_theme_font_size_override("font_size", 32)
	shop_btn.pressed.connect(_shop_ui.toggle)
	_hud.add_child(shop_btn)

func _build_result_screen() -> void:
	var result = ResultScreen.new()
	add_child(result)

func _spawn_tower(team: int, pos: Vector2) -> void:
	var tower = TOWER_SCENE.instantiate() as TowerController
	add_child(tower)
	tower.global_position = pos
	tower.team = team
	tower.add_to_group("team_%d" % team)

func _spawn_crystal(team: int, pos: Vector2) -> void:
	var crystal = CRYSTAL_SCENE.instantiate() as Crystal
	add_child(crystal)
	crystal.global_position = pos
	crystal.team = team
	crystal.add_to_group("team_%d" % team)
