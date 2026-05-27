class_name Crystal
extends Area2D

@export var team: int
@export var max_hp: float = 3000.0

var current_hp: float
var is_destroyed: bool = false

func _ready() -> void:
	current_hp = max_hp
	add_to_group("crystals")

func take_damage(damage: float) -> void:
	if is_destroyed:
		return
	current_hp = max(0.0, current_hp - damage)
	if current_hp <= 0.0:
		_destroy()

func _destroy() -> void:
	is_destroyed = true
	hide()
	GameManager.on_crystal_destroyed(team)
