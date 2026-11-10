extends Node2D
## Level 1, part 1: the waiting room (top-down grid RPG). Content in data/rpg2d.json.
## Flow: take a ticket -> wait (talk to the 3 other users, each gives an item, time passes, numbers get called)
##       -> your number is skipped -> go and complain at the door of Bureau 3 -> boss.
## Background = assets/2d/salle.svg (tools/boss/room.py), sprites = assets/2d/chars (tools/boss/chars.py).

const T := 48
const STEP_TIME := 0.16
const WALKABLE := ".S"
const CHARS := "res://assets/2d/chars/%s.svg"
const DIRS := {Vector2i.DOWN: "front", Vector2i.UP: "back", Vector2i.LEFT: "side", Vector2i.RIGHT: "side"}
const LIGHTS := [Vector2(5, 3), Vector2(14, 3), Vector2(5, 7.5), Vector2(14, 7.5)]

var map: Array = []
var texts: Dictionary
var grid := Vector2i.ZERO
var facing := Vector2i.DOWN
var moving := false
var locked := false
var player: Sprite2D
var cam: Camera2D
var box: DialogueBox
var _frames := {}            # "front_0" -> Texture2D
var _step_i := 0
var _neons: Array[PointLight2D] = []
var _marks := {}             # npc id -> "!" bubble
var _screen: Label
var _hands: Node2D
var _goal: Label
var _status: Label
var _hint: Label


func _ready() -> void:
	texts = Game.data2d.texts
	map = Game.data2d.map
	for y in map.size():
		var x: int = String(map[y]).find("S")
		if x >= 0:
			grid = Vector2i(x, y)
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/2d/salle.svg")
	bg.centered = false
	bg.scale = Vector2(0.5, 0.5)
	add_child(bg)
	_build_wall_widgets()
	var cm := CanvasModulate.new()
	cm.color = Color(0.42, 0.46, 0.42)
	add_child(cm)
	for p in LIGHTS:
		var l := PointLight2D.new()
		l.texture = Fx.light_texture()
		l.texture_scale = 3.4
		l.color = Color(0.8, 0.95, 0.78)
		l.energy = 0.85
		l.position = p * T
		add_child(l)
		_neons.append(l)
	var ents := Node2D.new()
	ents.y_sort_enabled = true
	add_child(ents)
	_build_npcs(ents)
	for d in ["front", "back", "side"]:
		for i in 3:
			_frames["%s_%d" % [d, i]] = load(CHARS % ("player_%s_%d" % [d, i]))
	player = _sprite(_frames.front_0, grid)
	ents.add_child(player)
	var pl := PointLight2D.new()
	pl.texture = Fx.light_texture()
	pl.texture_scale = 2.2 * 3.0 # the sprite is scaled 1/3
	pl.color = Color(1.0, 0.93, 0.8)
	pl.energy = 0.7
	pl.position = Vector2(0, -90)
	player.add_child(pl)
	cam = Camera2D.new()
	cam.zoom = Vector2(1.2, 1.2) # the whole room fits; a band is left free at the top for the HUD
	cam.position = Vector2(String(map[0]).length() * T / 2.0, 230)
	add_child(cam)
	RenderingServer.set_default_clear_color(Color(0.03, 0.035, 0.03))
	_build_hud()
	box = DialogueBox.new()
	add_child(box)
	Fx.overlay(self)
	_refresh()
	if not Game.has_ticket:
		await box.say(texts.intro)


# ---------------- construction ----------------

func _sprite(tex: Texture2D, cell: Vector2i) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = Vector2(-72, -198) # feet (24, 66) of the 48x72 drawing, x3
	s.scale = Vector2.ONE / 3.0
	s.position = _feet(cell)
	return s


func _feet(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * T + T / 2.0, cell.y * T + 42.0)


func _build_npcs(ents: Node2D) -> void:
	for y in map.size():
		for x in String(map[y]).length():
			var c := _tile(Vector2i(x, y))
			if not Game.data2d.npcs.has(c):
				continue
			var s := _sprite(load(CHARS % Game.data2d.npcs[c].sprite), Vector2i(x, y))
			ents.add_child(s)
			var tw := s.create_tween().set_loops() # breathing
			tw.tween_property(s, "scale:y", 1.03 / 3.0, 0.9 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
			tw.tween_property(s, "scale:y", 1.0 / 3.0, 0.9 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
			var m := Fx.label("!", 96, Color(1.0, 0.85, 0.3))
			m.add_theme_color_override("font_outline_color", Color.BLACK)
			m.add_theme_constant_override("outline_size", 24)
			m.position = Vector2(-18, -330)
			s.add_child(m)
			var tm := m.create_tween().set_loops()
			tm.tween_property(m, "position:y", -350.0, 0.4).set_trans(Tween.TRANS_SINE)
			tm.tween_property(m, "position:y", -330.0, 0.4).set_trans(Tween.TRANS_SINE)
			_marks[c] = m


func _build_wall_widgets() -> void:
	_screen = Fx.label("", 22, Color(1.0, 0.25, 0.12))
	_screen.autowrap_mode = TextServer.AUTOWRAP_OFF
	_screen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_screen.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_screen.position = Vector2(4 * T - 19, 20)
	_screen.size = Vector2(86, 28)
	add_child(_screen)
	_hands = Node2D.new()
	_hands.position = Vector2(11 * T + 24, 32)
	_hands.draw.connect(_draw_hands)
	add_child(_hands)


func _draw_hands() -> void:
	var m := float(Game.clock % 60) / 60.0 * TAU
	var h := float(Game.clock % 720) / 720.0 * TAU
	_hands.draw_line(Vector2.ZERO, Vector2(sin(h), -cos(h)) * 8.0, Color(0.05, 0.04, 0.03), 2.4)
	_hands.draw_line(Vector2.ZERO, Vector2(sin(m), -cos(m)) * 12.5, Color(0.05, 0.04, 0.03), 1.4)
	_hands.draw_circle(Vector2.ZERO, 1.6, Color(0.05, 0.04, 0.03))


func _build_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 25
	add_child(cl)
	var left := Fx.panel()
	left.position = Vector2(16, 12)
	cl.add_child(left)
	_goal = Fx.label("", 20)
	_goal.autowrap_mode = TextServer.AUTOWRAP_OFF
	left.add_child(_goal)
	var right := Fx.panel()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.position.y = 12
	right.offset_right = -16
	cl.add_child(right)
	_status = Fx.label("", 20)
	_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_status)
	_hint = Fx.label("[Espace]", 18, Color(1.0, 0.85, 0.3))
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hint.visible = false
	cl.add_child(_hint)


## Sync everything that shows the run state (HUD, wall screen, clock, "!" marks).
func _refresh() -> void:
	var goals: Array = Game.data2d.goals
	var g := 0 if not Game.has_ticket else (2 if Game.skipped else 1)
	_goal.text = "OBJECTIF : " + String(goals[g])
	var s := "%s   ·   N° appelé : %d" % [Game.clock_text(), Game.called]
	if Game.has_ticket:
		s += "   ·   Votre ticket : %d" % int(Game.data2d.ticket)
	var names: Array[String] = []
	for it in Game.data2d.items:
		if int(Game.inv.get(it.id, 0)) > 0:
			names.append(String(it.name))
	if not names.is_empty():
		s += "\nSac : " + ", ".join(names)
	_status.text = s
	_screen.text = "N° %d" % Game.called
	_hands.queue_redraw()
	for id in _marks:
		_marks[id].visible = Game.has_ticket and not Game.talked.has(id)


func _tile(p: Vector2i) -> String:
	if p.y < 0 or p.y >= map.size() or p.x < 0 or p.x >= String(map[p.y]).length():
		return "#"
	return String(map[p.y])[p.x]


# ---------------- loop ----------------

func _process(_d: float) -> void:
	for l in _neons: # flicker
		l.energy = 0.85 if randf() > 0.012 else randf_range(0.1, 0.4)
	var idle := not (moving or locked or box.busy)
	_hint.visible = idle and _tile(grid + facing) not in ["#", ".", "S"]
	_hint.position = get_viewport().get_canvas_transform() * (player.position + Vector2(0, -78)) - Vector2(_hint.size.x / 2.0, 30)
	if not idle:
		return
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("up"): dir = Vector2i.UP
	elif Input.is_action_pressed("down"): dir = Vector2i.DOWN
	elif Input.is_action_pressed("left"): dir = Vector2i.LEFT
	elif Input.is_action_pressed("right"): dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO:
		facing = dir
		if WALKABLE.contains(_tile(grid + dir)):
			_step(grid + dir)
		else:
			_show(0)


## Interact via events (not polling): the key press that closes a dialogue is consumed by the box,
## so it can't instantly re-open the same conversation.
func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") and not e.is_echo() and not (moving or locked or box.busy):
		get_viewport().set_input_as_handled()
		_interact(grid + facing)


func _show(frame: int) -> void:
	player.texture = _frames["%s_%d" % [DIRS[facing], frame]]
	player.flip_h = facing == Vector2i.RIGHT
	player.offset.x = -72.0 # flip_h mirrors around the texture, whose feet are centred: no shift needed


func _step(target: Vector2i) -> void:
	moving = true
	grid = target
	_step_i += 1
	_show(1 + _step_i % 2)
	var tw := create_tween()
	tw.tween_property(player, "position", _feet(target), STEP_TIME)
	await tw.finished
	moving = false
	if not (Input.is_action_pressed("up") or Input.is_action_pressed("down") or Input.is_action_pressed("left") or Input.is_action_pressed("right")):
		_show(0)


# ---------------- interactions ----------------

func _interact(p: Vector2i) -> void:
	var c := _tile(p)
	match c:
		"T":
			if Game.has_ticket:
				await box.say(texts.ticket_again)
			else:
				await box.say(texts.ticket_take)
				Game.has_ticket = true
				Game.clock += 18
		"E":
			await box.say(_fmt(texts.screen, Game.called))
		"H":
			await box.say(_fmt(texts.clock, Game.clock_text()))
		"A":
			var key := "%d,%d" % [p.x, p.y]
			if texts.posters.has(key):
				await box.say(texts.posters[key])
		"M":
			if Game.coffee_taken:
				await box.say(texts.coffee)
			else:
				Game.coffee_taken = true
				Game.give("cafe")
				await box.say(texts.coffee_first)
		"X":
			await box.say(texts.copier)
		"F":
			await box.say(texts.ficus)
		"c":
			await box.say(texts.chair)
		"D":
			if not Game.has_ticket:
				await box.say(texts.door_no_ticket)
			elif not Game.skipped:
				await box.say(texts.door_wait)
			else:
				_open_door()
				return
		_:
			if Game.data2d.npcs.has(c):
				await _talk(c)
	_refresh()


func _fmt(lines: Array, v: Variant) -> Array:
	var out: Array = []
	for l in lines:
		out.append(String(l) % v if String(l).contains("%") else l)
	return out


func _talk(id: String) -> void:
	var n: Dictionary = Game.data2d.npcs[id]
	if not Game.has_ticket:
		await box.say(texts.need_ticket)
		return
	if Game.talked.has(id):
		await box.say(n.again)
		return
	await box.say(n.talk)
	Game.talked[id] = true
	Game.give(n.item)
	_refresh()
	await _time_passes(int(n.minutes))
	if Game.talked.size() < Game.data2d.npcs.size():
		Game.called += 1
		_refresh()
		await box.say(_fmt(texts.ding, Game.called))
	else:
		Game.called = int(Game.data2d.ticket) + 1 # ...and yours never came up
		Game.skipped = true
		_refresh()
		Fx.shake(cam, 5, 0.3)
		await box.say(texts.skipped)


## Waiting, made visible: the room fades out, the clock jumps.
func _time_passes(minutes: int) -> void:
	locked = true
	var cl := CanvasLayer.new()
	cl.layer = 28
	add_child(cl)
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, 0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(r)
	var l := Fx.label("… %d minutes plus tard …" % minutes, 34)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.modulate.a = 0.0
	cl.add_child(l)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 1.0, 0.45)
	tw.tween_property(l, "modulate:a", 1.0, 0.3)
	tw.tween_interval(0.9)
	tw.tween_callback(func() -> void:
		Game.clock += minutes
		l.text = Game.clock_text()
		_refresh())
	tw.tween_interval(0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_property(r, "color:a", 0.0, 0.45)
	await tw.finished
	cl.queue_free()
	locked = false


func _open_door() -> void:
	locked = true
	await box.say(texts.door_open)
	Fx.shake(cam, 10, 0.5)
	await get_tree().create_timer(0.7).timeout
	# jump scare: she appears
	var cl := CanvasLayer.new()
	cl.layer = 20
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(holder)
	var layers: Dictionary = Game.data2d.boss.layers
	for k in ["base", "bras_tampon", "bras_telephone", "fx"]:
		var tr := TextureRect.new()
		tr.texture = load(layers[k])
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		holder.add_child(tr)
	holder.modulate.a = 0.0
	holder.pivot_offset = get_viewport_rect().size / 2
	holder.scale = Vector2(1.25, 1.25)
	var tw := holder.create_tween()
	tw.tween_property(holder, "modulate:a", 1.0, 0.08)
	tw.parallel().tween_property(holder, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT)
	Fx.flash(self, Color(1, 1, 1, 0.8), 0.25)
	Fx.shake(holder, 24, 0.5)
	await get_tree().create_timer(1.4).timeout
	get_tree().change_scene_to_file("res://scenes/battle2d.tscn")
