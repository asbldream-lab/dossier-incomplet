extends SceneTree
## Plays a real battle through the UI with simulated key presses and saves screenshots.
## Run (real window): godot -s tools/test_battle_ui.gd -- /out/dir
var b: Node
var out := ""
var shots := {}

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

func _shot(name: String) -> void:
	if out == "" or shots.has(name):
		return
	shots[name] = true
	await process_frame
	root.get_texture().get_image().save_png("%s/battle_%s.png" % [out, name])

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0] if a.size() > 0 else ""
	await process_frame
	change_scene_to_file("res://scenes/battle2d.tscn")
	while current_scene == null or current_scene.name != "Battle2d":
		await process_frame
	b = current_scene
	var frames := 0
	var target := ""
	var stamp_at := -1
	while b.result == "" and frames < 40000:
		frames += 1
		if frames % 300 == 0:
			var f := root.gui_get_focus_owner()
			print("f=%d turn=%d waiting=%s menu=%s cells=%d focus=%s text=%s" % [frames, b.turn, b._waiting, b._menu_open, b.grid.get_child_count(), f.text if f else "-", b.text_label.text.left(40)])
		if b.turn == 3 and stamp_at < 0:
			stamp_at = frames
		if stamp_at > 0 and frames - stamp_at > 90 and frames - stamp_at < 100 and not b._waiting:
			await _shot("stamp")
		if b._waiting:
			if b.turn >= 1:
				await _shot("text")
			await _act("ui_accept")
		elif b._menu_open:
			if b.grid.get_child_count() == 4 and b.menu_panel.size.x < 500: # main menu
				await _shot("main")
				b.grid.get_child(0).grab_focus() # the game remembers the cursor: start from ATTAQUE
				var want := ""
				for id in ["stylo", "photocopie", "timbre"]:
					if b.st.has(id) and int(root.get_node("Game").inv.get(id, 0)) > 0:
						want = id
				if want == "" and b.patience < 40 and int(root.get_node("Game").inv.get("cafe", 0)) > 0:
					want = "cafe"
				target = {"stylo": "Stylo", "photocopie": "Photocopie", "timbre": "Timbre", "cafe": "Café"}.get(want, "")
				if target != "":
					await _act("down") # OBJETS (ZQSD path)
				elif b.hint != "":
					await _act("right") # DÉFENSE
					target = "Garder"
				await _act("ui_accept")
			else:
				await _shot("sub")
				if target != "":
					for c in b.grid.get_children():
						if String(c.text).begins_with(target):
							c.grab_focus()
					await _shot("sub2")
				await _act("ui_accept")
		else:
			await process_frame
	print("result=%s turn=%d dossier=%d patience=%d clock=%d frames=%d" % [b.result, b.turn, b.dossier, b.patience, root.get_node("Game").clock, frames])
	for i in 330:
		await process_frame
	shots.erase("end")
	await _shot("end")
	await _act("ui_accept") # first button: retry (or replay)
	for i in 30:
		await process_frame
	print("after button: scene=%s" % (current_scene.name if current_scene else "null"))
	quit()
