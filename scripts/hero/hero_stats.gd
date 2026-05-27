class_name HeroStats
extends Resource

@export var hero_name: String = ""

@export_group("Base Stats")
@export var max_hp: float = 1000.0
@export var attack: float = 60.0
@export var move_speed: float = 200.0   # px/sec
@export var attack_speed: float = 1.0   # attacks/sec
@export var attack_range: float = 80.0  # px
@export var physical_armor: float = 0.0 # 0–1 flat reduction
@export var magic_resist: float = 0.0

@export_group("Per Level Growth")
@export var hp_per_level: float = 80.0
@export var attack_per_level: float = 4.0

@export_group("Visuals")
@export var color: Color = Color.WHITE
@export var portrait: Texture2D
