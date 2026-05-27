class_name ResultScreen
extends CanvasLayer

func _ready() -> void:
	hide()
	GameManager.game_over.connect(_on_game_over)

func _on_game_over(winner: int) -> void:
	show()
	get_tree().paused = true

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var label = Label.new()
	var is_player_win = winner == GameManager.Team.RADIANT
	label.text = "胜利！" if is_player_win else "失败"
	label.add_theme_font_size_override("font_size", 80)
	label.add_theme_color_override("font_color",
		Color.YELLOW if is_player_win else Color.GRAY)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(390, 800)
	add_child(label)

	var btn = Button.new()
	btn.text = "再来一局"
	btn.add_theme_font_size_override("font_size", 40)
	btn.position = Vector2(390, 1000)
	btn.size = Vector2(300, 80)
	btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/game_scene.tscn")
	)
	add_child(btn)
