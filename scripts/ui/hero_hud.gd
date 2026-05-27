class_name HeroHUD
extends CanvasLayer

var _hero: HeroBase
var _hp_bar: ColorRect
var _hp_fill: ColorRect
var _level_label: Label
var _gold_label: Label
var _skill_buttons: Array[SkillButton] = []

func init(hero: HeroBase, skill_btns: Array[SkillButton]) -> void:
	_hero = hero
	_skill_buttons = skill_btns
	GoldManager.gold_changed.connect(_on_gold_changed)

func _process(_delta: float) -> void:
	if _hero == null:
		return
	if _hp_fill:
		_hp_fill.size.x = (_hero.current_hp / _hero.max_hp) * 300.0
	if _level_label:
		_level_label.text = "Lv.%d" % _hero.level
	if _gold_label:
		_gold_label.text = "%d金" % GoldManager.get_gold(_hero.player_id)

func _on_gold_changed(player_id: int) -> void:
	if _hero and player_id == _hero.player_id and _gold_label:
		_gold_label.text = "%d金" % GoldManager.get_gold(player_id)

func set_hp_bar(bg: ColorRect, fill: ColorRect) -> void:
	_hp_bar = bg
	_hp_fill = fill

func set_labels(level_lbl: Label, gold_lbl: Label) -> void:
	_level_label = level_lbl
	_gold_label = gold_lbl
