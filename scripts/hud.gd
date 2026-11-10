class_name Hud
extends CanvasLayer
## Real-time HUD: HP bar, objective, centered messages.

var hp_bar: ProgressBar
var objective: Label
var msg: Label
var _tw: Tween


func _ready() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(24, 20)
	add_child(box)
	box.add_child(Game.ui_label("VOUS", 22))
	hp_bar = Game.ui_bar(Color(0.3, 0.85, 0.4))
	box.add_child(hp_bar)
	objective = Game.ui_label("", 20, Color(1, 0.95, 0.7))
	box.add_child(objective)
	var help := Game.ui_label("ZQSD/flèches : bouger   J/clic : frapper   Espace : roulade", 16, Color(1, 1, 1, 0.7))
	help.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)
	help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(help)
	msg = Game.ui_label("", 40)
	msg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	msg.offset_top = 150
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(msg)
	set_hp(1, 1)


func set_hp(hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp


func show_message(text: String, duration := 2.5) -> void:
	if _tw:
		_tw.kill()
	msg.text = text
	msg.modulate.a = 1.0
	_tw = create_tween()
	_tw.tween_property(msg, "modulate:a", 0.0, 0.5).set_delay(duration)
