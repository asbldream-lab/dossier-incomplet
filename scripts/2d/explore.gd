extends Node2D
## 2D exploration (grid, top-down) of the préfecture. Map/texts in data/rpg2d.json.
## Legend: # wall, . floor, S start, L floor + neon, c chair, T ticket machine, P poster (wall), N npc, D door (Bureau 3).

const T := 48 # tile size
const STEP_TIME := 0.15
const SOLID := "#cTPND"

var map: Array = []
var texts: Dictionary
var grid := Vector2i.ZERO
var facing := Vector2i.DOWN
var moving := false
var locked := false
var door_open := false
var player: Node2D
var cam: Camera2D
var box: DialogueBox
var _neons: Array[PointLight2D] = []
var _walk_t := 0.0


func _ready() -> void:
	texts = Game.data2d.texts
	map = Game.data2d.map
	for y in map.size():
		var x: int = String(map[y]).find("S")
		if x >= 0:
			grid = Vector2i(x, y)
	var cm := CanvasModulate.new()
	cm.color = Color(0.2, 0.22, 0.2)
	add_child(cm)
	_build_lights()
	player = Node2D.new()
	player.position = _center(grid)
	player.draw.connect(_draw_player)
	add_child(player)
	var pl := PointLight2D.new()
	pl.texture = Fx.light_texture()
	pl.texture_scale = 2.6
	pl.color = Color(1.0, 0.92, 0.8)
	pl.energy = 1.1
	player.add_child(pl)
	cam = Camera2D.new()
	cam.zoom = Vector2(1.7, 1.7)
	cam.position_smoothing_enabled = true
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = String(map[0]).length() * T
	cam.limit_bottom = map.size() * T
	player.add_child(cam)
	box = DialogueBox.new()
	add_child(box)
	Fx.overlay(self)
	if not Game.has_ticket:
		await box.say(texts.intro)


func _build_lights() -> void:
	for y in map.size():
		for x in String(map[y]).length():
			if _tile(Vector2i(x, y)) == "L":
				var l := PointLight2D.new()
				l.texture = Fx.light_texture()
				l.texture_scale = 3.2
				l.color = Color(0.75, 0.9, 0.75)
				l.energy = 0.9
				l.position = _center(Vector2i(x, y))
				add_child(l)
				_neons.append(l)


func _tile(p: Vector2i) -> String:
	if p.y < 0 or p.y >= map.size() or p.x < 0 or p.x >= String(map[p.y]).length():
		return "#"
	return String(map[p.y])[p.x]


func _center(p: Vector2i) -> Vector2:
	return Vector2(p.x * T + T / 2.0, p.y * T + T / 2.0)


# ---------------- loop ----------------

func _process(d: float) -> void:
	for l in _neons: # flicker
		l.energy = 0.9 if randf() > 0.015 else randf_range(0.05, 0.4)
	if moving:
		_walk_t += d
		player.queue_redraw()
	if moving or locked or box.busy:
		return
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("up"): dir = Vector2i.UP
	elif Input.is_action_pressed("down"): dir = Vector2i.DOWN
	elif Input.is_action_pressed("left"): dir = Vector2i.LEFT
	elif Input.is_action_pressed("right"): dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO:
		facing = dir
		player.queue_redraw()
		var target := grid + dir
		if not SOLID.contains(_tile(target)):
			_step(target)


## Interact via events (not polling): the key press that closes a dialogue is consumed by the box,
## so it can't instantly re-open the same conversation.
func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") and not e.is_echo() and not (moving or locked or box.busy):
		get_viewport().set_input_as_handled()
		_interact(grid + facing)


func _step(target: Vector2i) -> void:
	moving = true
	grid = target
	var tw := create_tween()
	tw.tween_property(player, "position", _center(target), STEP_TIME)
	await tw.finished
	moving = false
	player.queue_redraw()


func _interact(p: Vector2i) -> void:
	match _tile(p):
		"T":
			if Game.has_ticket:
				await box.say(texts.ticket_again)
			else:
				Game.has_ticket = true
				await box.say(texts.ticket_take)
		"N":
			await box.say(texts.npc)
		"P":
			var key := "%d,%d" % [p.x, p.y]
			if texts.posters.has(key):
				await box.say(texts.posters[key])
		"D":
			if not Game.has_ticket:
				await box.say(texts.door_locked)
			else:
				_open_door()


func _open_door() -> void:
	locked = true
	await box.say(texts.door_open)
	door_open = true
	queue_redraw()
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


# ---------------- drawing ----------------

func _draw() -> void:
	var f := Fx.font
	for y in map.size():
		for x in String(map[y]).length():
			var p := Vector2i(x, y)
			var r := Rect2(x * T, y * T, T, T)
			var c := _tile(p)
			# floor everywhere first
			var checker := (x + y) % 2 == 0
			draw_rect(r, Color(0.36, 0.38, 0.33) if checker else Color(0.32, 0.34, 0.3))
			draw_rect(r, Color(0, 0, 0, 0.25), false, 1.0)
			match c:
				"#", "P":
					draw_rect(r, Color(0.2, 0.21, 0.18))
					if _tile(p + Vector2i.DOWN) not in ["#", "P"]: # front face of wall
						draw_rect(Rect2(r.position + Vector2(0, T * 0.55), Vector2(T, T * 0.45)), Color(0.42, 0.42, 0.34))
						draw_rect(Rect2(r.position + Vector2(0, T - 5), Vector2(T, 5)), Color(0.15, 0.14, 0.12))
					if c == "P":
						draw_rect(Rect2(r.position + Vector2(8, 8), Vector2(T - 16, T - 14)), Color(0.82, 0.8, 0.68))
						for i in 3:
							draw_line(r.position + Vector2(13, 16 + i * 7), r.position + Vector2(T - 13, 16 + i * 7), Color(0.3, 0.1, 0.1), 2)
				"c":
					draw_rect(Rect2(r.position + Vector2(5, 10), Vector2(T - 10, T - 16)), Color(0.55, 0.28, 0.1))
					draw_rect(Rect2(r.position + Vector2(5, 6), Vector2(T - 10, 9)), Color(0.4, 0.2, 0.08))
				"T":
					draw_rect(Rect2(r.position + Vector2(8, 2), Vector2(T - 16, T - 6)), Color(0.55, 0.06, 0.06))
					draw_rect(Rect2(r.position + Vector2(14, 10), Vector2(T - 28, 10)), Color(0.05, 0.05, 0.05))
					draw_string(f, r.position + Vector2(15, 19), "004", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.2, 0.1))
					draw_rect(Rect2(r.position + Vector2(18, 28), Vector2(T - 36, 4)), Color(0.9, 0.9, 0.85))
				"N":
					_draw_person(self, r.get_center(), Color(0.3, 0.3, 0.38), Vector2i.DOWN, true)
				"D":
					if door_open:
						draw_rect(r, Color(0, 0, 0))
					else:
						draw_rect(Rect2(r.position + Vector2(10, 2), Vector2(T - 12, T - 4)), Color(0.33, 0.22, 0.12))
						draw_rect(Rect2(r.position + Vector2(10, 2), Vector2(T - 12, T - 4)), Color(0.15, 0.1, 0.05), false, 3)
						draw_circle(r.position + Vector2(16, T / 2.0), 3, Color(0.75, 0.65, 0.3))
						draw_string(f, r.position + Vector2(22, 20), "3", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.85, 0.6))
				"L":
					draw_rect(Rect2(r.position + Vector2(4, 20), Vector2(T - 8, 8)), Color(0.85, 0.95, 0.85, 0.35))


func _draw_player() -> void:
	var bob := absf(sin(_walk_t * 18.0)) * 3.0 if moving else 0.0
	_draw_person(player, Vector2(0, -bob), Color(0.2, 0.32, 0.55), facing, false)


func _draw_person(on: CanvasItem, c: Vector2, coat: Color, dir: Vector2i, sitting: bool) -> void:
	on.draw_circle(c + Vector2(0, 16), 13, Color(0, 0, 0, 0.35)) # shadow
	var h := 12.0 if sitting else 18.0
	on.draw_rect(Rect2(c + Vector2(-10, -2), Vector2(20, h)), coat) # body
	on.draw_circle(c + Vector2(0, -9), 10, Color(0.78, 0.68, 0.56)) # head
	on.draw_arc(c + Vector2(0, -10), 10, PI, TAU, 12, Color(0.12, 0.09, 0.07), 6) # hair
	if dir != Vector2i.UP:
		var off := Vector2(dir.x * 4, 0)
		on.draw_circle(c + Vector2(-4, -8) + off, 1.8, Color.BLACK)
		on.draw_circle(c + Vector2(4, -8) + off, 1.8, Color.BLACK)
	if sitting:
		on.draw_rect(Rect2(c + Vector2(-8, 2), Vector2(16, 10)), Color(0.85, 0.75, 0.45)) # folder held tight
