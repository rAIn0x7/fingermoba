class_name ShopUI
extends Control

var _hero: HeroBase
var _panel: PanelContainer
var _visible_state: bool = false

func _ready() -> void:
	visible = false

func setup(hero: HeroBase) -> void:
	_hero = hero
	_build_ui()

func toggle() -> void:
	_visible_state = not _visible_state
	visible = _visible_state

func _build_ui() -> void:
	var panel = PanelContainer.new()
	panel.size = Vector2(500, 600)
	panel.position = Vector2(290, 660)
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "商店"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for item in ShopController.items:
		var btn = Button.new()
		btn.text = "%s  %d金" % [item.item_name, item.cost]
		btn.pressed.connect(func(): _buy(item))
		vbox.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(toggle)
	vbox.add_child(close_btn)

func _buy(item: ItemData) -> void:
	if _hero == null:
		return
	if not ShopController.try_buy(_hero, item):
		push_warning("金币不足")
