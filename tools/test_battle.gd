extends SceneTree
## Balance + logic check of the battle, without UI. Run: godot --headless -s tools/test_battle.gd [-- N]
## Plays N battles with three policies and prints the outcomes.
var G: Node
var policy := ""

func _init() -> void:
	_run()

func _pick(opts: Array, id: String) -> Variant:
	for o in opts:
		if typeof(o.value) == TYPE_DICTIONARY and o.value.id == id and not o.has("locked"):
			return o.value
	return null

func _choose(kind: String, opts: Array, b: Node) -> Variant:
	if policy == "random":
		if kind == "main":
			return ["attack", "attack", "defense", "items"].pick_random()
		var free := opts.filter(func(o): return not o.has("locked"))
		return null if free.is_empty() else free.pick_random().value
	var cure := false
	for id in ["stylo", "photocopie", "timbre"]:
		if b.st.has(id) and int(G.inv.get(id, 0)) > 0:
			cure = true
	var threat: bool = b.hint != "" and not b.destab
	match kind:
		"main":
			if policy == "spam":
				return "attack"
			if cure: return "items"
			if b.patience < 40 and int(G.inv.get("cafe", 0)) > 0: return "items"
			if threat: return "defense"
			if b.patience < 28: return "defense"
			return "attack"
		"moves":
			if policy == "spam":
				return _pick(opts, "piece")
			var left: float = 100.0 - b.dossier
			if b.patience > 45 or (left <= 18 and b.patience > 14):
				return _pick(opts, "tout")
			return _pick(opts, "piece")
		"defenses":
			return _pick(opts, "tenir" if threat else "poli")
		"items":
			for id in ["stylo", "photocopie", "timbre", "cafe"]:
				var v = _pick(opts, id)
				if v != null: return v
	return null

func _run() -> void:
	await process_frame
	G = root.get_node("Game")
	var a := OS.get_cmdline_user_args()
	var n := int(a[0]) if a.size() > 0 else 300
	var B: Script = load("res://scripts/2d/battle2d.gd") # loaded here: the Game autoload must exist first
	B.set("fast", true)
	B.set("chooser", _choose)
	for p in ["smart", "spam", "random"]:
		policy = p
		var res := {}
		var turns := 0
		for i in n:
			G.has_ticket = true
			G.clock = 680
			G.inv = {"cafe": 1, "stylo": 1, "photocopie": 1, "timbre": 1}
			var b: Node = load("res://scenes/battle2d.tscn").instantiate()
			root.add_child(b)
			var guard := 0
			while b.result == "" and guard < 600:
				await process_frame
				guard += 1
			res[b.result] = int(res.get(b.result, 0)) + 1
			turns += b.turn
			b.free()
		print("%-7s %s  avg turns %.1f" % [p, res, float(turns) / n])
	quit()
