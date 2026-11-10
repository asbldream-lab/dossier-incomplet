extends Control
## Fear & Hunger-like static battle: nobody moves. Choose a skill, then a body part to target.
## Breaking an arm removes the attacks that need it; breaking a "fatal" part wins.
## Hits = portrait shake + flash; taking hits = screen shake + red flash.

signal _picked(value)

const PORTRAIT_SCALE := 0.85
const PORTRAIT_SIZE := Vector2(600, 800)

var B: Dictionary
var hp := 100.0
var max_hp := 100.0
var patience := 100.0
var max_patience := 100.0
var parts := {} # id -> {def, hp, broken}
var items: Array = []
var portrait: Control
var layers := {} # name -> TextureRect
var target_rect: Panel
var log_label: Label
var menu_box: VBoxContainer
var menu_title: Label
var hp_bar: ProgressBar
var pat_bar: ProgressBar
var stat_label: Label
var box: DialogueBox
var _hover_desc: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	B = Game.data2d.boss
	max_hp = Game.data2d.player.hp
	max_patience = Game.data2d.player.patience
	hp = max_hp
	patience = max_patience
	for p in B.parts:
		parts[p.id] = {"def": p, "hp": float(p.hp), "broken": false}
	items = Game.data2d.items.duplicate(true)
	_build()
	Fx.overlay(self)
	_refresh()
	await box.say(B.intro)
	_loop()


# ---------------- UI ----------------

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	portrait = Control.new()
	portrait.size = PORTRAIT_SIZE
	portrait.scale = Vector2.ONE * PORTRAIT_SCALE
	portrait.position = Vector2((1280 - PORTRAIT_SIZE.x * PORTRAIT_SCALE) / 2, 10)
	add_child(portrait)
	for k in ["base", "bras_tampon", "bras_telephone", "fx"]:
		var tr := TextureRect.new()
		tr.texture = load(B.layers[k])
		tr.size = PORTRAIT_SIZE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.add_child(tr)
		layers[k] = tr
	target_rect = Panel.new()
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.8, 0, 0, 0.12)
	ts.border_color = Color(1, 0.2, 0.2, 0.9)
	ts.set_border_width_all(4)
	target_rect.add_theme_stylebox_override("panel", ts)
	target_rect.visible = false
	portrait.add_child(target_rect)
	var tw := target_rect.create_tween().set_loops()
	tw.tween_property(target_rect, "modulate:a", 0.35, 0.4)
	tw.tween_property(target_rect, "modulate:a", 1.0, 0.4)
	# top: boss name
	var name_l := Fx.label("%s\n%s" % [B.name, B.title], 20, Color(0.8, 0.6, 0.7))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_l.offset_top = 8
	add_child(name_l)
	# left: command menu
	var left := Fx.panel()
	left.position = Vector2(24, 300)
	left.custom_minimum_size = Vector2(330, 380)
	add_child(left)
	var lv := VBoxContainer.new()
	left.add_child(lv)
	menu_title = Fx.label("", 18, Color(0.6, 0.6, 0.55))
	lv.add_child(menu_title)
	menu_box = VBoxContainer.new()
	lv.add_child(menu_box)
	_hover_desc = Fx.label("", 16, Color(0.65, 0.7, 0.75))
	_hover_desc.custom_minimum_size.x = 300
	lv.add_child(_hover_desc)
	# right: status
	var right := Fx.panel()
	right.position = Vector2(926, 300)
	right.custom_minimum_size = Vector2(330, 380)
	add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	right.add_child(rv)
	rv.add_child(Fx.label("VOUS", 20))
	rv.add_child(Fx.label("PV", 16, Color(0.7, 0.7, 0.65)))
	hp_bar = Fx.bar(Color(0.6, 0.1, 0.1), 290)
	rv.add_child(hp_bar)
	rv.add_child(Fx.label("Patience", 16, Color(0.7, 0.7, 0.65)))
	pat_bar = Fx.bar(Color(0.55, 0.55, 0.75), 290)
	rv.add_child(pat_bar)
	stat_label = Fx.label("", 16)
	stat_label.custom_minimum_size.x = 290
	rv.add_child(stat_label)
	# top-center log
	log_label = Fx.label("", 22, Color(0.95, 0.9, 0.8))
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	log_label.offset_top = 70
	log_label.offset_left = 380
	log_label.offset_right = -380
	add_child(log_label)
	box = DialogueBox.new()
	add_child(box)


func _refresh() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	pat_bar.max_value = max_patience
	pat_bar.value = patience
	var t := "PV %d / %d\nPatience %d / %d" % [hp, max_hp, patience, max_patience]
	if patience <= 0:
		t += "\n[À BOUT] précision -30 %"
	t += "\n\nÉtat de Mme Bertrand :"
	for id in parts:
		var pr: Dictionary = parts[id]
		t += "\n- %s : %s" % [pr.def.name, "CASSÉ" if pr.broken else _condition(pr)]
	stat_label.text = t


func _condition(pr: Dictionary) -> String:
	var r: float = pr.hp / float(pr.def.hp)
	if r > 0.75: return "intact"
	if r > 0.4: return "abîmé"
	return "très abîmé"


func _clear_menu() -> void:
	for c in menu_box.get_children():
		c.queue_free()
	_hover_desc.text = ""


## Show a list of choices and wait. options: [{text, value, disabled?, desc?, part?}]. Cancel returns null.
func _choose(title: String, options: Array, can_cancel := true) -> Variant:
	_clear_menu()
	menu_title.text = title
	var first: Button = null
	for o in options:
		var b := Fx.button(o.text)
		b.disabled = o.get("disabled", false)
		var v = o.value
		b.pressed.connect(func(): _picked.emit(v))
		var on_focus := func():
			_hover_desc.text = o.get("desc", "")
			_show_target(o.get("part", ""))
		b.focus_entered.connect(on_focus)
		b.mouse_entered.connect(on_focus)
		menu_box.add_child(b)
		if first == null and not b.disabled:
			first = b
	if can_cancel:
		var back := Fx.button("← Retour")
		back.pressed.connect(func(): _picked.emit(null))
		menu_box.add_child(back)
	await get_tree().process_frame
	if first:
		first.grab_focus()
	var r = await _picked
	_clear_menu()
	_show_target("")
	return r


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("cancel") and menu_box.get_child_count() > 0:
		_picked.emit(null)


func _show_target(id: String) -> void:
	if id == "" or not parts.has(id):
		target_rect.visible = false
		return
	var r: Array = parts[id].def.rect
	target_rect.position = Vector2(r[0], r[1])
	target_rect.size = Vector2(r[2], r[3])
	target_rect.visible = true


func _log(t: String) -> void:
	log_label.text = t


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _part_center(id: String) -> Vector2:
	var r: Array = parts[id].def.rect
	return portrait.position + (Vector2(r[0], r[1]) + Vector2(r[2], r[3]) / 2) * PORTRAIT_SCALE


func _float(text: String, at: Vector2, c: Color) -> void:
	var l := Fx.label(text, 40, c)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.position = at - Vector2(40, 20)
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 60, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tw.tween_callback(l.queue_free)


# ---------------- flow ----------------

func _loop() -> void:
	while true:
		var result: String = await _player_turn()
		if result == "fled":
			Game.go_explore()
			return
		if result == "won":
			await _end(B.victory, Color(0.8, 0.9, 0.7))
			return
		await _boss_turn()
		if hp <= 0:
			await _end(B.defeat, Color(0.9, 0.2, 0.2))
			return


func _player_turn() -> String:
	while true:
		_log("Que faites-vous ?")
		var cmd = await _choose("ACTION", [
			{"text": "Attaquer", "value": "attack"},
			{"text": "Objets", "value": "items"},
			{"text": "Fuir (pile ou face)", "value": "flee"},
		], false)
		match cmd:
			"attack":
				var opts := []
				for s in Game.data2d.skills:
					opts.append({"text": "%s%s" % [s.name, "" if s.cost == 0 else "  (%d)" % s.cost], "value": s,
						"disabled": patience < s.cost, "desc": s.desc})
				var skill = await _choose("ATTAQUE", opts)
				if skill == null:
					continue
				var popts := []
				for id in parts:
					var pr: Dictionary = parts[id]
					if pr.broken:
						continue
					popts.append({"text": "%s  — %d %%" % [pr.def.name, roundi(_chance(pr, skill) * 100)], "value": id,
						"part": id, "desc": "État : " + _condition(pr)})
				var target = await _choose("CIBLE", popts)
				if target == null:
					continue
				return await _do_attack(skill, target)
			"items":
				var iopts := []
				for it in items:
					iopts.append({"text": "%s  x%d" % [it.name, it.count], "value": it, "disabled": it.count <= 0, "desc": it.desc})
				var item = await _choose("OBJETS", iopts)
				if item == null:
					continue
				item.count -= 1
				hp = min(max_hp, hp + item.get("hp", 0))
				patience = min(max_patience, patience + item.get("patience", 0))
				_log(item.name + "…")
				_refresh()
				await _wait(1.0)
				return "ok"
			"flee":
				var coin := randf() < 0.5
				await _coin_flip(coin)
				if coin:
					await box.say(B.flee_ok)
					return "fled"
				await box.say(B.flee_ko)
				return "ok"
	return "ok"


func _chance(pr: Dictionary, skill: Dictionary) -> float:
	var c: float = pr.def.hit * skill.acc
	if patience <= 0:
		c *= 0.7
	return clampf(c, 0.05, 0.98)


func _do_attack(skill: Dictionary, id: String) -> String:
	patience -= skill.cost
	_refresh()
	_log("« %s »" % skill.name)
	await _wait(0.5)
	var pr: Dictionary = parts[id]
	for i in int(skill.hits):
		if pr.broken:
			break
		if randf() < _chance(pr, skill):
			pr.hp -= skill.dmg
			_float(str(int(skill.dmg)), _part_center(id), Color(1, 0.85, 0.3))
			_hit_portrait(id)
			if pr.hp <= 0:
				pr.broken = true
				_refresh()
				await _wait(0.5)
				await _break_part(id)
				if pr.def.get("fatal", false):
					return "won"
		else:
			_float("Raté", _part_center(id), Color(0.6, 0.6, 0.6))
			_log("Elle esquive en tamponnant un autre dossier.")
		_refresh()
		await _wait(0.45)
	await _wait(0.4)
	return "ok"


func _hit_portrait(id: String) -> void:
	Fx.shake(portrait, 16, 0.3)
	var layer: TextureRect = layers.get(id, layers.base)
	var tw := layer.create_tween()
	tw.tween_property(layer, "modulate", Color(3, 0.6, 0.6), 0.05)
	tw.tween_property(layer, "modulate", Color.WHITE, 0.25)


func _break_part(id: String) -> void:
	Fx.shake(portrait, 30, 0.6)
	Fx.flash(self, Color(0.6, 0, 0, 0.5), 0.5)
	if layers.has(id):
		var tw: Tween = layers[id].create_tween()
		tw.tween_property(layers[id], "modulate:a", 0.0, 0.4)
	await box.say([parts[id].def["break"]])


func _boss_turn() -> void:
	var pool := []
	for a in B.attacks:
		if not a.has("needs") or not parts[a.needs].broken:
			pool.append(a)
	var atk: Dictionary = pool.pick_random()
	_log(atk.name)
	await _wait(0.6)
	# her "lunge": portrait jolts toward the player
	var tw := portrait.create_tween()
	var base := portrait.scale
	tw.tween_property(portrait, "scale", base * 1.06, 0.08)
	tw.tween_property(portrait, "scale", base, 0.15)
	await _wait(0.12)
	Fx.shake(self, 18, 0.4)
	Fx.flash(self)
	var dmg: float = atk.get("dmg", 0)
	var pat: float = atk.get("patience", 0)
	hp = max(0.0, hp - dmg)
	patience = max(0.0, patience - pat)
	if dmg > 0:
		_float("-%d PV" % dmg, Vector2(1040, 330), Color(1, 0.3, 0.3))
	if pat > 0:
		_float("-%d Patience" % pat, Vector2(1000, 390), Color(0.6, 0.6, 1))
	_refresh()
	await box.say([atk.text])


func _coin_flip(heads: bool) -> void:
	var coin := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.75, 0.65, 0.3)
	s.set_corner_radius_all(60)
	coin.add_theme_stylebox_override("panel", s)
	coin.size = Vector2(120, 120)
	coin.pivot_offset = coin.size / 2
	coin.position = Vector2(580, 300)
	add_child(coin)
	var tw := coin.create_tween()
	for i in 8:
		tw.tween_property(coin, "scale:x", 0.05, 0.06)
		tw.tween_property(coin, "scale:x", 1.0, 0.06)
	await tw.finished
	var l := Fx.label("PILE" if heads else "FACE", 26, Color(0.15, 0.1, 0.0))
	l.position = Vector2(26, 42)
	coin.add_child(l)
	await _wait(0.8)
	coin.queue_free()


func _end(lines: Array, c: Color) -> void:
	_clear_menu()
	_log("")
	var cl := CanvasLayer.new()
	cl.layer = 25
	add_child(cl)
	var dark := ColorRect.new()
	dark.color = Color(0, 0, 0, 0)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(dark)
	dark.create_tween().tween_property(dark, "color:a", 0.85, 1.0)
	await _wait(1.0)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.add_theme_constant_override("separation", 18)
	cl.add_child(v)
	var title := Fx.label(lines[0], 56, c)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := Fx.label(lines[1], 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var b := Fx.button("Recommencer")
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(func():
		Game.has_ticket = false
		Game.go_explore())
	v.add_child(b)
	b.grab_focus()
