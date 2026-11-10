extends Control
## Pokémon-like battle against Mme Bertrand (guichet du Bureau 3).
## Win: bring the DOSSIER gauge to 100 %. Lose: PATIENCE at 0, or the clock reaching closing time.
## She plans her attack one turn ahead; the dangerous ones are announced so that DÉFENSE is a real choice.
## All numbers and texts live in data/rpg2d.json ("battle"). Tests drive it with `fast` + `chooser`.

signal _picked(value)
signal _advance

static var fast := false      ## tests: no animation, no waiting for input
static var chooser: Callable  ## tests: func(kind, options, battle) -> value, replaces the menu

const PORTRAIT_SIZE := Vector2(600, 800)
const PORTRAIT_SCALE := 0.68
const DEMANDS := ["stylo", "photocopie", "timbre"]
const NAV := [["up", SIDE_TOP], ["down", SIDE_BOTTOM], ["left", SIDE_LEFT], ["right", SIDE_RIGHT]]
const UI_Y := 544.0
const UI_H := 164.0

var D: Dictionary  # battle data
var T: Dictionary  # battle texts
var dossier := 0.0
var patience := 100.0
var max_patience := 100.0
var close := 720
var st := {}            # player statuses: id -> turns left
var guard := ""         # defense chosen this turn: "poli" | "tenir"
var destab := false     # her next attack fails
var turn := 0
var next_atk := {}
var hint := ""
var last_id := ""
var demands: Array = []
var demand_at := 2
var egare_done := false
var soon_said := false
var piece_i := 0
var result := ""

var portrait: Control
var layers := {}
var hero: Control
var hero_tex: TextureRect
var dossier_bar: ProgressBar
var dossier_pct: Label
var hint_label: Label
var clock_label: Label
var pat_bar: ProgressBar
var pat_fill: StyleBoxFlat
var pat_num: Label
var badges: HBoxContainer
var text_panel: Panel
var text_label: Label
var arrow: Label
var menu_panel: Panel
var grid: GridContainer
var _waiting := false
var _menu_open := false
var _can_cancel := false
var _cursor := {}
var _prompt := ""
var _idle_stamp: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	D = Game.data2d.battle
	T = D.texts
	if not Game.has_ticket: # scene launched directly: sensible defaults
		Game.has_ticket = true
		Game.clock = 680
		Game.inv = {"cafe": 1, "stylo": 1, "photocopie": 1, "timbre": 1}
	Game.checkpoint = {"clock": Game.clock, "inv": Game.inv.duplicate()}
	dossier = float(D.dossier)
	max_patience = float(D.patience)
	patience = max_patience
	close = int(D.close)
	demands = Array(D.demands).duplicate()
	demands.shuffle()
	demand_at = int(D.demand_first)
	_prompt = String(D.prompt)
	_build()
	if not fast:
		Fx.overlay(self)
	_plan()
	_refresh(false)
	var intro: Array = []
	for l in D.intro:
		intro.append(String(l) % Game.clock_text() if String(l).contains("%s") else String(l))
	await _say(intro)
	_loop()


# ---------------- UI ----------------

func _lbl(text: String, size := 18, c := Color(0.88, 0.86, 0.8)) -> Label:
	var l := Fx.label(text, size, c)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


func _rect(pos: Vector2, size: Vector2, c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _box(pos: Vector2, width: float, border := Color(0.55, 0.55, 0.5)) -> VBoxContainer:
	var p := Fx.panel(border)
	p.position = pos
	p.custom_minimum_size.x = width
	add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	return v


func _build() -> void:
	# the office wall, with the guichet window in the middle
	_rect(Vector2.ZERO, Vector2(1280, 720), Color(0.13, 0.155, 0.135))
	_rect(Vector2(0, 310), Vector2(1280, 410), Color(0.075, 0.09, 0.08))
	_rect(Vector2(0, 304), Vector2(1280, 7), Color(0.04, 0.05, 0.045))
	var frame := Panel.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0.02, 0.02, 0.02)
	fs.border_color = Color(0.2, 0.17, 0.13)
	fs.set_border_width_all(10)
	fs.shadow_color = Color(0, 0, 0, 0.6)
	fs.shadow_size = 18
	frame.add_theme_stylebox_override("panel", fs)
	var psize := PORTRAIT_SIZE * PORTRAIT_SCALE
	var ppos := Vector2(640 - psize.x / 2, -10)
	frame.position = ppos - Vector2(10, 10)
	frame.size = psize + Vector2(20, 20)
	add_child(frame)
	portrait = Control.new()
	portrait.size = PORTRAIT_SIZE
	portrait.pivot_offset = PORTRAIT_SIZE / 2
	portrait.scale = Vector2.ONE * PORTRAIT_SCALE
	portrait.position = ppos - PORTRAIT_SIZE * (1.0 - PORTRAIT_SCALE) / 2
	add_child(portrait)
	for k in ["base", "bras_tampon", "bras_telephone", "fx"]:
		var tr := TextureRect.new()
		tr.texture = load(Game.data2d.boss.layers[k])
		tr.size = PORTRAIT_SIZE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(tr)
		layers[k] = tr
	# the player, seen from behind (cut by the text box, like a Pokémon back sprite)
	hero = Control.new()
	hero.position = Vector2(96, 232)
	hero.modulate = Color(1.45, 1.4, 1.35) # he stands in the dark corner of the room: lift him a little
	add_child(hero)
	hero_tex = TextureRect.new()
	hero_tex.texture = load("res://assets/2d/chars/player_battle.svg")
	hero_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(hero_tex)
	_rect(Vector2(0, UI_Y - 10), Vector2(1280, 190), Color(0.015, 0.015, 0.015))
	_rect(Vector2(0, UI_Y - 12), Vector2(1280, 3), Color(0.3, 0.28, 0.24))

	# her box: name + DOSSIER gauge
	var bv := _box(Vector2(24, 22), 372)
	var h1 := HBoxContainer.new()
	bv.add_child(h1)
	h1.add_child(_lbl(String(Game.data2d.boss.name).to_upper(), 24, Color(0.92, 0.7, 0.78)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h1.add_child(sp)
	h1.add_child(_lbl("Guichet 3", 15, Color(0.6, 0.6, 0.55)))
	var h2 := HBoxContainer.new()
	h2.add_theme_constant_override("separation", 10)
	bv.add_child(h2)
	h2.add_child(_lbl("DOSSIER", 15, Color(0.8, 0.78, 0.6)))
	dossier_bar = Fx.bar(Color(0.86, 0.8, 0.5), 190)
	dossier_bar.custom_minimum_size.y = 16
	dossier_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h2.add_child(dossier_bar)
	dossier_pct = _lbl("", 20, Color(0.95, 0.9, 0.6))
	dossier_pct.custom_minimum_size.x = 62
	dossier_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h2.add_child(dossier_pct)
	hint_label = _lbl("", 15, Color(1.0, 0.6, 0.3))
	bv.add_child(hint_label)

	# the clock
	var cv := _box(Vector2(1000, 22), 228, Color(0.5, 0.2, 0.12))
	clock_label = _lbl("", 46, Color(1.0, 0.36, 0.14))
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(clock_label)
	var cl2 := _lbl("Fermeture du guichet : 12h00", 14, Color(0.7, 0.62, 0.55))
	cl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(cl2)

	# our box: PATIENCE + statuses
	var pv := _box(Vector2(888, 398), 340)
	var h3 := HBoxContainer.new()
	pv.add_child(h3)
	h3.add_child(_lbl("VOUS", 24))
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h3.add_child(sp2)
	h3.add_child(_lbl("Ticket n° %d" % int(Game.data2d.ticket), 15, Color(0.6, 0.6, 0.55)))
	var h4 := HBoxContainer.new()
	h4.add_theme_constant_override("separation", 10)
	pv.add_child(h4)
	h4.add_child(_lbl("PATIENCE", 15, Color(0.7, 0.8, 0.7)))
	pat_bar = Fx.bar(Color(0.4, 0.75, 0.4), 150)
	pat_bar.custom_minimum_size.y = 16
	pat_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pat_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pat_fill = pat_bar.get_theme_stylebox("fill")
	h4.add_child(pat_bar)
	pat_num = _lbl("", 18)
	pat_num.custom_minimum_size.x = 76
	pat_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h4.add_child(pat_num)
	badges = HBoxContainer.new()
	badges.custom_minimum_size.y = 26
	badges.add_theme_constant_override("separation", 6)
	pv.add_child(badges)

	# bottom: text box (left) + menu (right)
	text_panel = Panel.new()
	text_panel.add_theme_stylebox_override("panel", _solid_style())
	add_child(text_panel)
	text_label = Fx.label("", 24, Color(0.95, 0.92, 0.84))
	text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	text_panel.add_child(text_label)
	arrow = _lbl("▼", 20, Color(1.0, 0.6, 0.3))
	arrow.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	arrow.visible = false
	text_panel.add_child(arrow)
	var atw := arrow.create_tween().set_loops()
	atw.tween_property(arrow, "modulate:a", 0.2, 0.35)
	atw.tween_property(arrow, "modulate:a", 1.0, 0.35)
	menu_panel = Panel.new()
	menu_panel.add_theme_stylebox_override("panel", _solid_style())
	add_child(menu_panel)
	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	menu_panel.add_child(grid)
	_layout("text")

	if fast:
		return
	# idle life: she breathes, we shift our weight
	for k in ["bras_tampon", "bras_telephone"]:
		var tw: Tween = layers[k].create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		tw.tween_property(layers[k], "position:y", 4.0 if k == "bras_tampon" else 2.0, 1.6)
		tw.tween_property(layers[k], "position:y", 0.0, 1.6)
		if k == "bras_tampon":
			_idle_stamp = tw
	var htw := hero_tex.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	htw.tween_property(hero_tex, "position:y", 5.0, 1.3)
	htw.tween_property(hero_tex, "position:y", 0.0, 1.3)


func _solid_style() -> StyleBoxFlat:
	var s := Fx.panel_style(Color(0.62, 0.6, 0.52))
	s.bg_color = Color(0.03, 0.03, 0.03)
	s.set_border_width_all(3)
	s.set_corner_radius_all(4)
	return s


## "text": text box on the full width; "main": text + 2×2 menu; "sub": short text + wide list.
func _layout(mode: String) -> void:
	var split := {"text": 1260.0, "main": 800.0, "sub": 420.0}
	var x: float = split[mode]
	text_panel.position = Vector2(20, UI_Y)
	text_panel.size = Vector2(x - 20, UI_H)
	text_label.add_theme_font_size_override("font_size", 19 if mode == "sub" else 24)
	menu_panel.visible = mode != "text"
	menu_panel.position = Vector2(x + 12, UI_Y)
	menu_panel.size = Vector2(1260 - x - 12, UI_H)


func _refresh(animate := true) -> void:
	dossier_pct.text = "%d %%" % roundi(dossier)
	pat_num.text = "%d/%d" % [ceili(patience), int(max_patience)]
	var r := patience / max_patience
	pat_fill.bg_color = Color(0.4, 0.75, 0.4) if r > 0.5 else (Color(0.9, 0.65, 0.2) if r > 0.25 else Color(0.85, 0.2, 0.15))
	if animate and not fast:
		create_tween().tween_property(dossier_bar, "value", dossier, 0.4)
		create_tween().tween_property(pat_bar, "value", r * 100.0, 0.4)
	else:
		dossier_bar.value = dossier
		pat_bar.value = r * 100.0
	clock_label.text = Game.clock_text()
	clock_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.1) if close - Game.clock <= 10 else Color(1.0, 0.36, 0.14))
	var tips: Array[String] = []
	if destab:
		tips.append("DÉSTABILISÉE")
	if hint != "":
		tips.append("▶ " + hint)
	hint_label.text = "   ".join(tips)
	hint_label.visible = not tips.is_empty()
	for c in badges.get_children():
		badges.remove_child(c)
		c.queue_free()
	var shown := st.keys()
	if guard != "":
		shown.append(guard)
	for id in shown:
		var bad: bool = D.status.has(id)
		var p := PanelContainer.new()
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.5, 0.12, 0.1) if bad else Color(0.15, 0.35, 0.2)
		s.set_corner_radius_all(3)
		s.content_margin_left = 6
		s.content_margin_right = 6
		p.add_theme_stylebox_override("panel", s)
		p.add_child(_lbl(String(D.status[id].name) if bad else ("POLI" if id == "poli" else "DOSSIER EN MAIN"), 13, Color(1, 0.95, 0.9)))
		if bad:
			p.tooltip_text = String(D.status[id].desc)
		badges.add_child(p)


func _text(t: String) -> void:
	text_label.text = t
	text_label.visible_ratio = 1.0
	arrow.visible = false


func _say(lines: Array) -> void:
	_layout("text")
	for raw in lines:
		var t := String(raw)
		_text(t)
		if fast:
			continue
		text_label.visible_ratio = 0.0
		var tw := create_tween()
		tw.tween_property(text_label, "visible_ratio", 1.0, 0.016 * t.length())
		tw.tween_callback(func(): arrow.visible = true)
		_waiting = true
		await _advance
		if text_label.visible_ratio < 1.0: # first press finishes the line
			tw.kill()
			text_label.visible_ratio = 1.0
			arrow.visible = true
			await _advance
		_waiting = false
		arrow.visible = false


## Shows a menu and waits. options: [{text, value, desc?, locked?}]. Cancel returns null.
func _choose(kind: String, options: Array, can_cancel := true) -> Variant:
	if chooser.is_valid():
		return chooser.call(kind, options, self)
	var big := kind == "main"
	_layout("main" if big else "sub")
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	var opts := options.duplicate()
	if can_cancel:
		opts.append({"text": "← Retour", "value": null, "desc": _prompt})
	var cells: Array[Button] = []
	for o in opts:
		var b := Fx.button(String(o.text))
		b.add_theme_font_size_override("font_size", 27 if big else 19)
		b.custom_minimum_size = Vector2(0, 64 if big else 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		if big:
			b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var locked: String = o.get("locked", "")
		var desc: String = o.get("desc", _prompt)
		if locked != "":
			for cn in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
				b.add_theme_color_override(cn, Color(0.42, 0.42, 0.4))
			desc += "\n" + locked
		var v = o.value
		b.pressed.connect(func():
			if locked == "":
				_picked.emit(v))
		b.focus_entered.connect(func(): _text(desc))
		b.mouse_entered.connect(b.grab_focus)
		grid.add_child(b)
		cells.append(b)
	await get_tree().process_frame
	var start := clampi(int(_cursor.get(kind, 0)), 0, cells.size() - 1) if big else 0
	if not big: # sub-menus open on the first usable line
		for i in opts.size():
			if not opts[i].has("locked"):
				start = i
				break
	cells[start].grab_focus()
	_can_cancel = can_cancel
	_menu_open = true
	var r = await _picked
	_menu_open = false
	var f := get_viewport().gui_get_focus_owner()
	if f is Button and cells.has(f):
		_cursor[kind] = cells.find(f)
	_layout("text")
	return r


func _input(e: InputEvent) -> void:
	if e.is_echo():
		return
	if _waiting:
		if e.is_action_pressed("interact") or e.is_action_pressed("ui_accept") \
				or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
			get_viewport().set_input_as_handled()
			_advance.emit()
		return
	var f := get_viewport().gui_get_focus_owner()
	if f == null:
		return
	if _menu_open and _can_cancel and e.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_picked.emit(null)
		return
	for d in NAV: # ZQSD moves the cursor too (arrows are handled by the engine)
		if e.is_action_pressed(d[0]) and not e.is_action("ui_" + d[0]):
			get_viewport().set_input_as_handled()
			var n := f.find_valid_focus_neighbor(d[1])
			if n:
				n.grab_focus()
			return
	if e.is_action_pressed("interact") and not e.is_action("ui_accept") and f is Button:
		get_viewport().set_input_as_handled()
		f.pressed.emit()


func _wait(t: float) -> void:
	if not fast:
		await get_tree().create_timer(t).timeout


func _float(text: String, at: Vector2, c: Color, size := 34) -> void:
	if fast:
		return
	var l := _lbl(text, size, c)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.position = at
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", at.y - 46, 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.7)
	tw.tween_callback(l.queue_free)


# ---------------- rules ----------------

func _tick(minutes: int) -> void:
	if minutes <= 0:
		return
	Game.clock = mini(Game.clock + minutes, close)
	_float("+%d min" % minutes, Vector2(1070, 124), Color(1.0, 0.5, 0.3), 22)


## Adds to the dossier (stylo bleu halves, missing timbre caps). Returns a note to display, or "".
func _gain(n: float) -> String:
	var note := ""
	var g := n
	if st.has("stylo"):
		g *= 0.5
		note = String(T.halved)
	var cap := float(D.timbre_cap) if st.has("timbre") else 100.0
	var target := minf(dossier + g, maxf(cap, dossier))
	if target < dossier + g and cap < 100.0:
		note = String(T.capped)
	_float("+%d %%" % roundi(target - dossier), Vector2(300, 118), Color(0.75, 1.0, 0.55))
	dossier = target
	return note


## Removes from the dossier, unless we hold it. Returns false when blocked.
func _lose(n: float) -> bool:
	if guard == "tenir":
		_float("PROTÉGÉ", Vector2(270, 118), Color(0.6, 0.85, 1.0), 26)
		return false
	dossier = maxf(0.0, dossier - n)
	_float("-%d %%" % roundi(n), Vector2(300, 118), Color(1.0, 0.35, 0.3))
	return true


func _hurt(n: float) -> void:
	if guard == "poli":
		n *= 0.5
	patience = maxf(0.0, patience - n)
	_float("-%d" % roundi(n), Vector2(1090, 356), Color(1.0, 0.35, 0.3))


func _calm(n: float) -> void:
	patience = minf(max_patience, patience + n)
	_float("+%d" % roundi(n), Vector2(1090, 356), Color(0.6, 1.0, 0.6))


## She chooses her next attack one turn ahead (so the big ones can be announced).
func _plan() -> void:
	var t := turn + 1
	var id := ""
	if D.stamp_turns.has(float(t)):
		id = "tampon"
	elif not demands.is_empty() and t >= demand_at:
		id = demands.pop_front()
		demand_at = t + int(D.demand_gap)
	elif not egare_done and dossier >= float(D.egare_at):
		id = "egare"
		egare_done = true
	else:
		var pool: Array = Array(D.pool).duplicate()
		pool.erase(last_id)
		id = pool.pick_random()
	next_atk = D.attacks[id].duplicate()
	next_atk.id = id
	hint = String(next_atk.get("hint", ""))


# ---------------- flow ----------------

func _loop() -> void:
	while true:
		var r: String = await _player_turn()
		if r == "fled":
			await _end("flee")
			return
		if dossier >= 100.0:
			await _end("win")
			return
		if Game.clock >= close:
			await _end("closed")
			return
		await _boss_turn()
		if patience <= 0.0:
			await _end("crack")
			return
		if Game.clock >= close:
			await _end("closed")
			return


func _player_turn() -> String:
	guard = ""
	if st.has("attente"):
		st.erase("attente")
		_tick(int(D.wait_min))
		_refresh()
		await _say(T.waiting)
		return "ok"
	_refresh()
	while true:
		_text(_prompt)
		var m: Array = D.menu
		var cmd = await _choose("main", [
			{"text": m[0], "value": "attack"}, {"text": m[1], "value": "defense"},
			{"text": m[2], "value": "items"}, {"text": m[3], "value": "flee"}], false)
		match cmd:
			"attack":
				var opts := []
				for mv in D.moves:
					var o := {"text": mv.name, "value": mv, "desc": mv.desc}
					if patience <= float(mv.cost):
						o.locked = T.no_patience
					opts.append(o)
				var move = await _choose("moves", opts)
				if move != null:
					await _do_move(move)
					return "ok"
			"defense":
				var opts := []
				for df in D.defenses:
					opts.append({"text": df.name, "value": df, "desc": df.desc})
				var def = await _choose("defenses", opts)
				if def != null:
					guard = def.id
					_tick(int(def.min))
					if def.has("patience"):
						_calm(float(def.patience))
					_refresh()
					await _say(def.use)
					return "ok"
			"items":
				var opts := []
				for it in Game.data2d.items:
					var n := int(Game.inv.get(it.id, 0))
					if n <= 0:
						continue
					var o := {"text": "%s  ×%d" % [it.name, n], "value": it, "desc": it.desc}
					if it.has("cures") and not st.has(it.cures):
						o.locked = T.no_item
					opts.append(o)
				if opts.is_empty():
					await _say([T.empty_bag])
					continue
				var item = await _choose("items", opts)
				if item != null:
					await _do_item(item)
					return "ok"
			"flee":
				var yes = await _choose("confirm", [
					{"text": T.flee_no, "value": false, "desc": T.flee_ask},
					{"text": T.flee_yes, "value": true, "desc": T.flee_ask}], false)
				if yes == true:
					return "fled"
	return "ok"


func _do_move(m: Dictionary) -> void:
	patience -= float(m.cost)
	_tick(int(m.min))
	var use := String(m.use)
	if use.contains("%s"):
		use = use % String(D.pieces[piece_i % D.pieces.size()])
		piece_i += 1
	_refresh()
	await _say([use])
	if m.has("chance") and randf() > float(m.chance):
		_tick(int(m.ko_min))
		_refresh()
		await _say([m.ko])
		return
	await _anim_throw()
	var note := _gain(float(m.dossier))
	if m.get("destab", false):
		destab = true
	_refresh()
	var lines := [m.get("hit", D.reactions.pick_random())]
	if note != "":
		lines.append(note)
	await _say(lines)


func _do_item(it: Dictionary) -> void:
	Game.inv[it.id] = int(Game.inv.get(it.id, 0)) - 1
	_tick(1)
	var lines: Array = Array(it.use).duplicate()
	if it.has("patience"):
		_calm(float(it.patience))
	if it.has("cures"):
		st.erase(it.cures)
		await _anim_throw()
		var note := _gain(float(it.dossier))
		if note != "":
			lines.append(note)
	_refresh()
	await _say(lines)


func _boss_turn() -> void:
	turn += 1
	var a: Dictionary = next_atk
	hint = ""
	if destab:
		destab = false
		if a.get("demand", false):
			demands.push_front(a.id)
		_refresh()
		await _say(T.destab)
	else:
		_layout("text")
		_text(String(a.name))
		await _wait(0.75)
		if a.get("anim", "") == "stamp":
			await _anim_stamp()
		else:
			await _anim_boss_hit()
		var blocked := false
		if a.has("min"):
			_tick(int(a.min))
		if a.has("patience"):
			_hurt(float(a.patience))
		if a.has("dossier"):
			blocked = not _lose(float(a.dossier))
		if a.has("status"):
			st[a.status] = int(D.demand_turns) if a.get("demand", false) else 1
		last_id = String(a.id)
		_refresh()
		await _wait(0.5)
		await _say(a.blocked if blocked and a.has("blocked") else a.text)
	if patience <= 0.0 or Game.clock >= close:
		return
	# end of the round: statuses, then she prepares her next move
	if st.has("photocopie"):
		dossier = maxf(0.0, dossier - float(D.copy_drain))
		_float("-%d %%" % int(D.copy_drain), Vector2(300, 118), Color(1.0, 0.35, 0.3))
		_refresh()
		await _say([T.drain])
	for id in DEMANDS:
		if st.has(id):
			st[id] -= 1
			if st[id] <= 0:
				st.erase(id)
				_refresh()
				await _say([String(T.expire) % String(T.expire_names[id])])
	if not soon_said and close - Game.clock <= 5:
		soon_said = true
		await _say([T.soon])
	_plan()
	_refresh()
	if next_atk.has("tell"):
		await _say([next_atk.tell])


# ---------------- animations ----------------

## We step forward and slide a sheet under the glass.
func _anim_throw() -> void:
	if fast:
		return
	var tw := hero.create_tween()
	tw.tween_property(hero, "position", hero.position + Vector2(34, -22), 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(hero, "position", hero.position, 0.22)
	var sheet := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.93, 0.9, 0.8)
	s.border_color = Color(0.1, 0.1, 0.1)
	s.set_border_width_all(2)
	sheet.add_theme_stylebox_override("panel", s)
	sheet.size = Vector2(30, 40)
	sheet.pivot_offset = sheet.size / 2
	sheet.position = Vector2(330, 360)
	add_child(sheet)
	move_child(sheet, hero.get_index() + 1)
	var st2 := sheet.create_tween()
	st2.tween_property(sheet, "position", Vector2(620, 400), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	st2.parallel().tween_property(sheet, "rotation", TAU, 0.3)
	st2.tween_callback(sheet.queue_free)
	await st2.finished
	Fx.shake(portrait, 8, 0.25)
	var base: TextureRect = layers.base
	var ft := base.create_tween()
	ft.tween_property(base, "modulate", Color(1.8, 1.7, 1.4), 0.05)
	ft.tween_property(base, "modulate", Color.WHITE, 0.25)
	await _wait(0.3)


## She leans in; we take it.
func _anim_boss_hit() -> void:
	if fast:
		return
	var tw := portrait.create_tween()
	tw.tween_property(portrait, "scale", Vector2.ONE * PORTRAIT_SCALE * 1.06, 0.08)
	tw.tween_property(portrait, "scale", Vector2.ONE * PORTRAIT_SCALE, 0.18)
	await _wait(0.1)
	_impact(12, Color(0.7, 0, 0, 0.35))
	await _wait(0.3)


func _impact(strength: float, c: Color) -> void:
	Fx.shake(hero, strength, 0.35)
	Fx.flash(self, c, 0.35)
	var tw := hero_tex.create_tween()
	tw.tween_property(hero_tex, "modulate", Color(2.4, 0.5, 0.5), 0.05)
	tw.tween_property(hero_tex, "modulate", Color.WHITE, 0.3)


## The stamp arm rises, slams down, and a red REFUSÉ lands on the screen.
func _anim_stamp() -> void:
	if fast:
		return
	var arm: TextureRect = layers.bras_tampon
	_idle_stamp.pause()
	var tw := arm.create_tween()
	tw.tween_property(arm, "position", Vector2(-6, -46), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_property(arm, "position", Vector2(40, 120), 0.07)
	await tw.finished
	Fx.shake(self, 22, 0.45)
	_impact(20, Color(0.8, 0, 0, 0.55))
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.8, 0.05, 0.05, 0.1)
	s.border_color = Color(0.86, 0.08, 0.08)
	s.set_border_width_all(10)
	s.set_corner_radius_all(12)
	s.content_margin_left = 34
	s.content_margin_right = 34
	p.add_theme_stylebox_override("panel", s)
	p.add_child(_lbl("REFUSÉ", 112, Color(0.86, 0.08, 0.08)))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	var ms := p.get_combined_minimum_size()
	p.pivot_offset = ms / 2
	p.position = Vector2(640, 270) - ms / 2
	p.rotation = -0.2
	p.scale = Vector2(2.6, 2.6)
	p.modulate.a = 0.0
	var mt := p.create_tween()
	mt.tween_property(p, "scale", Vector2.ONE, 0.1)
	mt.parallel().tween_property(p, "modulate:a", 0.92, 0.08)
	mt.tween_interval(0.9)
	mt.tween_property(p, "modulate:a", 0.0, 0.4)
	mt.tween_callback(p.queue_free)
	await _wait(0.6)
	var back := arm.create_tween()
	back.tween_property(arm, "position", Vector2.ZERO, 0.4)
	back.tween_callback(_idle_stamp.play)
	await _wait(0.5)


# ---------------- end ----------------

func _end(kind: String) -> void:
	result = kind
	if fast:
		return
	_layout("text")
	_text("")
	var E: Dictionary = T.end[kind]
	var cl := CanvasLayer.new()
	cl.layer = 25
	add_child(cl)
	var dark := ColorRect.new()
	dark.color = Color(0, 0, 0, 0)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(dark)
	dark.create_tween().tween_property(dark, "color:a", 0.88, 0.9)
	await _wait(0.9)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.add_theme_constant_override("separation", 14)
	cl.add_child(v)
	var title := _lbl(String(E.title), 60, Color(String(E.color)))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	if kind == "win":
		Fx.flash(self, Color(1, 1, 0.8, 0.5), 0.6)
	for raw in E.lines:
		var t := String(raw)
		if t.contains("%d"):
			t = t % roundi(dossier)
		var l := _lbl(t, 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		v.add_child(l)
		l.create_tween().tween_property(l, "modulate:a", 1.0, 0.4)
		await _wait(0.7)
	var gap := Control.new()
	gap.custom_minimum_size.y = 12
	v.add_child(gap)
	var first: Button
	var actions := [[T.replay, _restart]] if kind == "win" else [[T.retry, _retry], [T.restart, _restart]]
	for a in actions:
		var b := Fx.button(String(a[0]))
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(a[1])
		b.mouse_entered.connect(b.grab_focus)
		v.add_child(b)
		if first == null:
			first = b
	first.grab_focus()


func _retry() -> void:
	Game.clock = int(Game.checkpoint.clock)
	Game.inv = Game.checkpoint.inv.duplicate()
	get_tree().reload_current_scene()


func _restart() -> void:
	Game.reset_run()
	Game.go_explore()
