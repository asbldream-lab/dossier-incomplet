extends SceneTree
## Real-window screenshot of a scene. Run: godot -s tools/shot.gd -- res://scenes/x.tscn out.png [frames] [ticket]
func _init() -> void:
	_run()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	await process_frame
	var G := root.get_node("Game")
	if a.size() > 3:
		G.has_ticket = true
		G.called = 845
		G.clock = 590
		G.talked = {"2": true}
		G.inv = {"stylo": 1, "cafe": 1}
	change_scene_to_file(a[0])
	for i in int(a[2]) if a.size() > 2 else 90:
		await process_frame
	root.get_texture().get_image().save_png(a[1])
	quit()
