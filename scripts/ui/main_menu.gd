class_name MainMenu
extends CanvasLayer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.08, 0.05, 1)
	add_child(bg)

	var title = Label.new()
	title.text = "指尖MOBA"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(390, 600)
	add_child(title)

	var sub = Label.new()
	sub.text = "3v3 竖屏对战"
	sub.add_theme_font_size_override("font_size", 36)
	sub.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.position = Vector2(390, 720)
	add_child(sub)

	var btn = Button.new()
	btn.text = "开始游戏"
	btn.add_theme_font_size_override("font_size", 48)
	btn.size = Vector2(340, 110)
	btn.position = Vector2(370, 960)
	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/game_scene.tscn")
	)
	add_child(btn)
