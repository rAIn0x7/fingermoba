class_name VirtualJoystick
extends Control

@export var max_radius: float = 70.0

var direction: Vector2 = Vector2.ZERO
var is_active: bool = false

var _bg: ColorRect
var _handle: ColorRect
var _origin: Vector2

func _ready() -> void:
	_bg = ColorRect.new()
	_bg.size = Vector2(140, 140)
	_bg.color = Color(1, 1, 1, 0.15)
	add_child(_bg)

	_handle = ColorRect.new()
	_handle.size = Vector2(60, 60)
	_handle.color = Color(1, 1, 1, 0.35)
	add_child(_handle)

	size = Vector2(300, 300)
	_reset_handle()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		if touch.position.x < get_viewport_rect().size.x * 0.5:
			if touch.pressed:
				is_active = true
				_origin = touch.position
				_bg.global_position = _origin - _bg.size * 0.5
				_update_handle(_origin)
			else:
				is_active = false
				direction = Vector2.ZERO
				_reset_handle()
	elif event is InputEventScreenDrag:
		var drag = event as InputEventScreenDrag
		if is_active and drag.position.x < get_viewport_rect().size.x * 0.5:
			_update_handle(drag.position)

func _update_handle(pos: Vector2) -> void:
	var delta = pos - _origin
	if delta.length() > max_radius:
		delta = delta.normalized() * max_radius
	direction = delta / max_radius
	_handle.global_position = _origin + delta - _handle.size * 0.5

func _reset_handle() -> void:
	_handle.position = Vector2(120, 120)
