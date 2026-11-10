class_name DialogueBox
extends CanvasLayer
## Bottom text box with typewriter effect. `await box.say([...])` — Space/Enter to advance.

signal _advance

var busy := false
var _panel: PanelContainer
var _label: Label
var _tw: Tween


func _ready() -> void:
	layer = 30
	_panel = Fx.panel()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 140
	_panel.offset_right = -140
	_panel.offset_top = -170
	_panel.offset_bottom = -30
	add_child(_panel)
	_label = Fx.label("", 24)
	_panel.add_child(_label)
	_panel.visible = false


func say(lines: Array) -> void:
	busy = true
	_panel.visible = true
	for line in lines:
		_label.text = line
		_label.visible_ratio = 0.0
		_tw = create_tween()
		_tw.tween_property(_label, "visible_ratio", 1.0, 0.025 * String(line).length())
		await _advance
		if _label.visible_ratio < 1.0: # first press finishes the line
			_tw.kill()
			_label.visible_ratio = 1.0
			await _advance
	_panel.visible = false
	await get_tree().process_frame
	busy = false


func _unhandled_input(e: InputEvent) -> void:
	if busy and e.is_action_pressed("interact") and not e.is_echo():
		get_viewport().set_input_as_handled()
		_advance.emit()
