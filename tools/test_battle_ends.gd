extends SceneTree
## Checks the three losing endings and their buttons in a real window (simulated keys + mouse).
## Run: godot -s tools/test_battle_ends.gd -- /out/dir
var G: Node
var out := ""
var mode := ""

func _init() -> void:
	_run()

func _act(action: String) -> void:
	for p in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = p
		Input.parse_input_event(e)
		await process_frame
		await process_frame

func _click(c: Control) -> void:
	var pos := c.get_global_rect().get_center()
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	root.push_input(m, true)
	await process_frame
	for p in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = p
		e.position = pos
		e.global_position = pos
		root.push_input(e, true)
		await process_frame
		await process_frame

func _choose(kind: String, opts: Array, _b: Node) -> Variant:
	match kind:
		"main":
			return "defense" if mode == "closed" else "attack"
		"confirm":
			return true
	for o in opts: # first usable line
		if not o.has("locked"):
			return o.value
	return null

func _battle() -> Node:
	change_scene_to_file("res://scenes/battle2d.tscn")
	await process_frame
	while current_scene == null or current_scene.name != "Battle2d" or not current_scene.is_node_ready():
		await process_frame
	return current_scene

func _play(b: Node) -> void:
	var frames := 0
	while b.result == "" and frames < 60000:
		frames += 1
		if b._waiting:
			await _act("ui_accept")
		else:
			await process_frame

func _end_buttons() -> Array:
	for i in 80: # overlay fades in, lines appear one by one
		await create_timer(0.1).timeout
	var found: Array = []
	var todo: Array = [current_scene]
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		if n is Button and n.is_visible_in_tree() and n.get_parent() is VBoxContainer:
			found.append(n)
		todo.append_array(n.get_children())
	found.sort_custom(func(x, y): return x.global_position.y < y.global_position.y)
	return found

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0] if a.size() > 0 else ""
	await process_frame
	G = root.get_node("Game")
	Engine.time_scale = 3.0
	var B: Script = load("res://scripts/2d/battle2d.gd")

	# 1. closed (only defending) -> « Retenter » with the keyboard reloads the battle at the checkpoint
	mode = "closed"
	B.set("chooser", _choose)
	var b: Node = await _battle()
	var cp: Dictionary = G.checkpoint.duplicate(true)
	await _play(b)
	var btns: Array = await _end_buttons()
	if out != "": root.get_texture().get_image().save_png(out + "/end_closed.png")
	print("closed: result=%s clock=%d buttons=%s" % [b.result, G.clock, btns.map(func(x): return x.text)])
	await _act("ui_accept")
	for i in 20: await process_frame
	b = current_scene
	print("  retry: scene=%s result='%s' clock=%d (checkpoint %d) inv_ok=%s dossier=%d" % [b.name, b.result, G.clock, cp.clock, G.inv == cp.inv, b.dossier])

	# 2. crack (patience forced low) -> « Retour à la salle d'attente » with the mouse
	mode = "crack"
	while not b.is_node_ready(): await process_frame
	b.patience = 6
	await _play(b)
	btns = await _end_buttons()
	if out != "": root.get_texture().get_image().save_png(out + "/end_crack.png")
	print("crack: result=%s patience=%d buttons=%s" % [b.result, b.patience, btns.map(func(x): return x.text)])
	await _click(btns[1])
	for i in 30: await process_frame
	print("  restart(mouse): scene=%s has_ticket=%s" % [current_scene.name, G.has_ticket])

	# 3. flee, real menus, mouse only
	B.set("chooser", Callable())
	b = await _battle()
	var frames := 0
	while b.result == "" and frames < 20000:
		frames += 1
		if b._waiting:
			await _click(b.text_label)
		elif b._menu_open:
			var cells: Array = b.grid.get_children()
			if cells.size() == 4:
				await _click(cells[3]) # FUIR
			else:
				if out != "": root.get_texture().get_image().save_png(out + "/flee_confirm.png")
				await _click(cells[1]) # yes
		else:
			await process_frame
	btns = await _end_buttons()
	if out != "": root.get_texture().get_image().save_png(out + "/end_flee.png")
	print("flee(mouse): result=%s frames=%d buttons=%s" % [b.result, frames, btns.map(func(x): return x.text)])
	quit()
