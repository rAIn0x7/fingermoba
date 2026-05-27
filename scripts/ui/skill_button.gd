class_name SkillButton
extends Control

@export var skill_index: int = 0

var _skill: SkillBase
var _bg: ColorRect
var _cd_overlay: ColorRect
var _drag_start: Vector2
var _drag_dir: Vector2
var _touch_id: int = -1

func _ready() -> void:
	_bg = ColorRect.new()
	_bg.size = size
	_bg.color = Color(0.2, 0.2, 0.6, 0.8)
	add_child(_bg)

	_cd_overlay = ColorRect.new()
	_cd_overlay.size = size
	_cd_overlay.color = Color(0, 0, 0, 0.5)
	_cd_overlay.visible = false
	add_child(_cd_overlay)

func init(skill: SkillBase) -> void:
	_skill = skill

func _process(_delta: float) -> void:
	if _skill == null:
		return
	var ready = _skill.is_ready
	_cd_overlay.visible = not ready
	if not ready:
		var ratio = _skill.cooldown_remaining / _skill.cooldown
		_cd_overlay.size = Vector2(size.x, size.y * ratio)

func _input(event: InputEvent) -> void:
	if _skill == null:
		return
	var rect = Rect2(global_position, size)

	if event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		if touch.pressed and rect.has_point(touch.position):
			_touch_id = touch.index
			_drag_start = touch.position
			_drag_dir = Vector2.ZERO
		elif not touch.pressed and touch.index == _touch_id:
			_touch_id = -1
			var drag_dist = touch.position.distance_to(_drag_start)
			var dir = _drag_dir if drag_dist > 20.0 else Vector2.ZERO
			_skill.try_cast(dir)

	elif event is InputEventScreenDrag:
		var drag = event as InputEventScreenDrag
		if drag.index == _touch_id:
			var d = drag.position - _drag_start
			if d.length() > 20.0:
				_drag_dir = d.normalized()
