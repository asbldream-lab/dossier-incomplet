extends Node
## Autoload "Game": inputs, shared animation library, data, builders, scene flow.

const MALE := "res://assets/characters/UAL1_Standard.glb"
const FEMALE := "res://assets/characters/Mannequin_F.glb"
const ANIM_SOURCES := ["res://assets/characters/UAL1_Standard.glb", "res://assets/characters/UAL2_Standard.glb"]
const MODEL_YAW := PI # rotate imported models so they face -Z (Godot forward). Set 0.0 if they look backwards.
## Only these loop (anims originally suffixed "_Loop", which Godot strips on import, + Sword_Idle).
const LOOPS := ["Crouch_Fwd", "Crouch_Idle", "Dance", "Driving", "Idle", "Idle_Talking", "Idle_Torch", "Jog_Fwd",
	"Jump", "Pistol_Idle", "Push", "Sitting_Idle", "Sitting_Talking", "Spell_Simple_Idle", "Sprint", "Swim_Fwd",
	"Swim_Idle", "Walk_Formal", "Walk", "Idle_FoldArms", "Idle_Lantern", "Idle_No", "Idle_Rail", "Idle_Shield",
	"Idle_TalkingPhone", "NinjaJump_Idle", "Slide", "TreeChopping", "Walk_Carry", "Zombie_Idle", "Zombie_Walk_Fwd", "Sword_Idle"]

var data: Dictionary = {}
var data2d: Dictionary = {} # 2D RPG version (data/rpg2d.json)
var has_ticket := false
## Waiting-room run state (reset by reset_run)
var called := 844      # number shown on the call screen
var clock := 527       # minutes since midnight (8h47)
var talked := {}       # npc id -> true
var inv := {}          # item id -> count
var skipped := false   # our number was skipped: the door can be opened
var coffee_taken := false
var checkpoint := {}   # state at the start of the battle (clock, inv), to retry it
var current_boss := "secretaire"
var _lib: AnimationLibrary


func _ready() -> void:
	_setup_inputs()
	var f := FileAccess.open("res://data/combat.json", FileAccess.READ)
	data = JSON.parse_string(f.get_as_text())
	data2d = JSON.parse_string(FileAccess.get_file_as_string("res://data/rpg2d.json"))
	reset_run()


func _setup_inputs() -> void:
	# physical keys => WASD on QWERTY = ZQSD on AZERTY
	var keys := {
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"attack": [KEY_J], "dodge": [KEY_SPACE], "parry": [KEY_SPACE],
		"interact": [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E], "cancel": [KEY_ESCAPE, KEY_BACKSPACE],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mb)


## All animations of UAL1 + UAL2 merged in one library (same rig for male & female mannequins).
func anim_library() -> AnimationLibrary:
	if _lib:
		return _lib
	_lib = AnimationLibrary.new()
	for path in ANIM_SOURCES:
		var inst: Node = (load(path) as PackedScene).instantiate()
		for ap: AnimationPlayer in inst.find_children("*", "AnimationPlayer", true, false):
			for lib_name in ap.get_animation_library_list():
				var lib := ap.get_animation_library(lib_name)
				for n in lib.get_animation_list():
					if _lib.has_animation(n):
						continue
					var a := lib.get_animation(n)
					a.loop_mode = Animation.LOOP_LINEAR if n in LOOPS else Animation.LOOP_NONE
					_lib.add_animation(n, a)
		inst.free()
	return _lib


# ---------- characters ----------

func make_player_model() -> CharacterModel:
	var m := CharacterModel.new()
	m.setup_deferred(MALE, Color(0.22, 0.45, 0.85), Color(0.12, 0.12, 0.16))
	return m


func make_secretary_model() -> CharacterModel:
	var m := CharacterModel.new()
	m.setup_deferred(FEMALE, Color(0.62, 0.36, 0.62), Color(0.2, 0.12, 0.2))
	m.weapon = _stamp(0.6)
	return m


func _rolled_cerfa() -> Node3D:
	var w := Node3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.05; c.bottom_radius = 0.05; c.height = 0.75
	add_mesh(w, c, Color(0.95, 0.95, 0.9), Vector3(0, 0.3, 0))
	var band := CylinderMesh.new()
	band.top_radius = 0.055; band.bottom_radius = 0.055; band.height = 0.08
	add_mesh(w, band, Color(0.85, 0.1, 0.1), Vector3(0, 0.3, 0))
	return w


func _stamp(s: float) -> Node3D:
	var w := Node3D.new()
	var h := CylinderMesh.new()
	h.top_radius = 0.06 * s; h.bottom_radius = 0.06 * s; h.height = 0.5 * s
	add_mesh(w, h, Color(0.45, 0.28, 0.15), Vector3(0, 0.15, 0))
	var b := BoxMesh.new()
	b.size = Vector3(0.35, 0.15, 0.25) * s
	add_mesh(w, b, Color(0.75, 0.08, 0.08), Vector3(0, 0.45 * s, 0))
	return w


# ---------- builders ----------

func mat(c: Color, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func add_mesh(parent: Node3D, mesh: Mesh, c: Color, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(c)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, solid := true) -> Node3D:
	var bm := BoxMesh.new()
	bm.size = size
	if not solid:
		return add_mesh(parent, bm, c, pos)
	var sb := StaticBody3D.new()
	sb.position = pos
	parent.add_child(sb)
	add_mesh(sb, bm, c, Vector3.ZERO)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	sb.add_child(col)
	return sb


func label3d(parent: Node3D, text: String, pos: Vector3, size := 64, c := Color.WHITE, billboard := false) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = size / 6
	l.modulate = c
	l.pixel_size = 0.005
	l.position = pos
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
	return l


func float_text(parent: Node3D, pos: Vector3, text: String, c: Color, size := 72) -> void:
	var l := label3d(parent, text, Vector3.ZERO, size, c, true)
	l.no_depth_test = true
	l.global_position = pos
	var tw := l.create_tween()
	tw.tween_property(l, "global_position", pos + Vector3(0, 1.0, 0), 1.0)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.5)
	tw.tween_callback(l.queue_free)


## Office room: floor, walls, lights, environment. Room spans x in [-w/2,w/2], z in [-d/2,d/2].
func build_room(root: Node3D, w: float, d: float) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.82, 0.9)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 25, 0)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	root.add_child(sun)
	for x in [-w / 4, w / 4]:
		var o := OmniLight3D.new()
		o.position = Vector3(x, 3.4, 0)
		o.omni_range = w * 0.6
		o.light_color = Color(0.9, 0.95, 1.0)
		o.light_energy = 1.2
		root.add_child(o)

	box(root, Vector3(w, 0.2, d), Vector3(0, -0.1, 0), Color(0.72, 0.72, 0.68)) # floor
	# floor tile lines
	for i in range(int(-w / 2) + 1, int(w / 2)):
		box(root, Vector3(0.03, 0.01, d), Vector3(i, 0.005, 0), Color(0.6, 0.6, 0.57), false)
	var wall := Color(0.86, 0.82, 0.7)
	box(root, Vector3(w, 3.5, 0.3), Vector3(0, 1.75, -d / 2), wall)
	box(root, Vector3(0.3, 3.5, d), Vector3(-w / 2, 1.75, 0), wall)
	box(root, Vector3(0.3, 3.5, d), Vector3(w / 2, 1.75, 0), wall)
	box(root, Vector3(w, 0.6, 0.3), Vector3(0, 0.3, d / 2), wall) # low front wall (camera side)
	box(root, Vector3(w, 0.4, 0.32), Vector3(0, 0.2, -d / 2 + 0.01), Color(0.35, 0.33, 0.3), false) # skirting


func face(node: Node3D, dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() > 0.001:
		node.rotation.y = atan2(-dir.x, -dir.z)


# ---------- UI helpers ----------

func ui_label(text: String, size := 22, c := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", max(4, size / 5))
	return l


func ui_bar(c: Color, width := 320.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(width, 20)
	b.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new()
	fg.bg_color = c
	fg.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b


# ---------- flow ----------

func go_battle(boss_id: String) -> void:
	current_boss = boss_id
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


func go_explore() -> void:
	get_tree().change_scene_to_file("res://scenes/explore.tscn")


func go_level1() -> void:
	get_tree().change_scene_to_file("res://scenes/level1.tscn")


func reset_run() -> void:
	has_ticket = false
	called = 844
	clock = int(data2d.clock_start)
	talked = {}
	inv = {}
	skipped = false
	coffee_taken = false


func give(id: String, n := 1) -> void:
	inv[id] = int(inv.get(id, 0)) + n


func clock_text() -> String:
	return "%dh%02d" % [clock / 60, clock % 60]
