extends SceneTree
## Plays the whole waiting room with simulated key presses. Run: godot --headless -s tools/test_explore.gd
var ex: Node
var G: Node

func _init() -> void:
	_run()

func _press() -> void:
	for p in [true, false]:
		var e := InputEventAction.new()
		e.action = "interact"
		e.pressed = p
		Input.parse_input_event(e)
		await process_frame
		await process_frame

func _use(cell: Vector2i, label: String) -> void:
	ex.grid = cell + Vector2i.DOWN
	ex.facing = Vector2i.UP
	await _press()
	var n := 0
	while is_instance_valid(ex) and (ex.box.busy or ex.locked) and n < 4000:
		await _press()
		n += 1
	print("%-10s ticket=%s called=%d clock=%s talked=%d skipped=%s inv=%s presses=%d" % [label, G.has_ticket, G.called, G.clock_text(), G.talked.size(), G.skipped, G.inv, n])

func _run() -> void:
	await process_frame
	G = root.get_node("Game")
	change_scene_to_file("res://scenes/explore.tscn")
	while current_scene == null or current_scene.name != "Explore":
		await process_frame
	ex = current_scene
	while ex.box == null or not ex.box.busy:
		await process_frame
	while ex.box.busy:
		await _press()
	print("goal: ", ex._goal.text.replace("\n", " | "))
	await _use(Vector2i(15, 1), "door0")
	await _use(Vector2i(5, 4), "npc-early")
	await _use(Vector2i(1, 2), "ticket")
	await _use(Vector2i(1, 2), "ticket2")
	await _use(Vector2i(12, 2), "coffee")
	await _use(Vector2i(15, 1), "door-wait")
	await _use(Vector2i(5, 4), "mamie")
	await _use(Vector2i(5, 4), "mamie2")
	await _use(Vector2i(13, 4), "etudiant")
	await _use(Vector2i(4, 1), "screen")
	await _use(Vector2i(11, 1), "clock")
	await _use(Vector2i(10, 7), "homme")
	print("goal: ", ex._goal.text.replace("\n", " | "), "  status: ", ex._status.text.replace("\n", " | "))
	# walking: hold right for a moment
	ex.grid = Vector2i(1, 8); ex.player.position = ex._feet(ex.grid)
	Input.action_press("right")
	for i in 40: await process_frame
	Input.action_release("right")
	for i in 20: await process_frame
	print("walked to ", ex.grid, " moving=", ex.moving)
	await _use(Vector2i(15, 1), "door-open")
	for i in 200:
		await process_frame
		if current_scene != ex: break
	print("scene: ", current_scene.name if current_scene else "null")
	quit()
