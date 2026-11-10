class_name Monster
extends CharacterBody3D
## Hostile office supply. Set `kind` before add_child: agrafeuse, classeur, dossier, tampon.

signal died

var kind := "dossier"
var st: Dictionary
var hp := 1.0
var body := Node3D.new() # visual root (hops / squashes)
var part: Node3D # hinged piece (jaw, cover) opened on wind-up
var mats: Array[StandardMaterial3D] = []
var label: Label3D
var player
var busy := false
var dead := false
var _cd := 1.5
var _t := 0.0
var _knock := Vector3.ZERO
var _col: CollisionShape3D


func _ready() -> void:
	add_to_group("monsters")
	st = Game.data.monsters[kind]
	hp = st.hp
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.6
	sh.height = 1.2
	col.shape = sh
	col.position.y = 0.6
	add_child(col)
	_col = col
	add_child(body)
	call("_build_" + kind)
	label = Game.label3d(self, "", Vector3(0, 2.1, 0), 36, Color.WHITE, true)
	_update_label()
	player = get_tree().get_first_node_in_group("player")
	_t = randf() * 10
	# pop-in
	scale = Vector3.ONE * 0.01
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _m(mesh: Mesh, c: Color, pos: Vector3, parent: Node3D = null, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := Game.add_mesh(parent if parent else body, mesh, c, pos, rot)
	mats.append(mi.material_override)
	return mi


func _bm(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _eyes(parent: Node3D, pos: Vector3, gap := 0.14, r := 0.09) -> void:
	for sx in [-1, 1]:
		var s := SphereMesh.new()
		s.radius = r
		s.height = r * 2
		_m(s, Color.WHITE, pos + Vector3(sx * gap, 0, 0), parent)
		var p := SphereMesh.new()
		p.radius = r * 0.45
		p.height = r * 0.9
		_m(p, Color.BLACK, pos + Vector3(sx * gap, 0, -r * 0.75), parent)
		_m(_bm(Vector3(r * 2.2, r * 0.4, r * 0.4)), Color(0.1, 0.05, 0.05),
			pos + Vector3(sx * gap, r * 1.2, -r * 0.4), parent, Vector3(0, 0, -sx * 0.45)) # angry brow


func _build_agrafeuse() -> void:
	_m(_bm(Vector3(0.55, 0.22, 1.5)), Color(0.2, 0.2, 0.22), Vector3(0, 0.15, 0))
	part = Node3D.new()
	part.position = Vector3(0, 0.32, 0.65)
	body.add_child(part)
	_m(_bm(Vector3(0.5, 0.24, 1.45)), Color(0.75, 0.12, 0.12), Vector3(0, 0.1, -0.68), part)
	_m(_bm(Vector3(0.3, 0.06, 0.08)), Color(0.85, 0.85, 0.9), Vector3(0, -0.03, -1.3), part) # staple
	_eyes(part, Vector3(0, 0.3, -1.1))


func _build_classeur() -> void:
	_m(_bm(Vector3(1.0, 1.4, 0.4)), Color(0.15, 0.3, 0.75), Vector3(0, 0.75, 0))
	_m(_bm(Vector3(0.6, 0.35, 0.02)), Color(0.95, 0.95, 0.95), Vector3(0, 0.55, -0.21))
	var ring := CylinderMesh.new()
	ring.top_radius = 0.07; ring.bottom_radius = 0.07; ring.height = 0.03
	_m(ring, Color(0.05, 0.05, 0.05), Vector3(0, 0.25, -0.21), null, Vector3(PI / 2, 0, 0))
	_m(_bm(Vector3(0.08, 0.5, 0.08)), Color(0.7, 0.7, 0.75), Vector3(0.55, 0.9, 0), null, Vector3(0, 0, 0.3)) # lever
	_eyes(body, Vector3(0, 1.15, -0.22), 0.2, 0.11)
	Game.label3d(body, "ARCHIVES", Vector3(0, 0.55, -0.23), 28, Color(0.1, 0.1, 0.1)).rotation.y = PI


func _build_dossier() -> void:
	_m(_bm(Vector3(1.0, 0.04, 0.75)), Color(0.9, 0.75, 0.45), Vector3(0, 0.6, 0))
	_m(_bm(Vector3(0.9, 0.08, 0.68)), Color(0.98, 0.98, 0.95), Vector3(0.03, 0.66, 0.02))
	part = Node3D.new()
	part.position = Vector3(0, 0.72, 0.37)
	body.add_child(part)
	_m(_bm(Vector3(1.0, 0.04, 0.75)), Color(0.88, 0.72, 0.4), Vector3(0, 0, -0.37), part)
	_eyes(part, Vector3(0, 0.1, -0.55), 0.15, 0.08)
	Game.label3d(part, "INCOMPLET", Vector3(0, 0.03, -0.37), 30, Color(0.8, 0.1, 0.1)).rotation = Vector3(-PI / 2, PI, 0)


func _build_tampon() -> void:
	_m(_bm(Vector3(0.95, 0.35, 0.95)), Color(0.55, 0.08, 0.08), Vector3(0, 0.2, 0))
	_m(_bm(Vector3(0.9, 0.05, 0.9)), Color(0.9, 0.1, 0.1), Vector3(0, 0.02, 0))
	var h := CylinderMesh.new()
	h.top_radius = 0.14; h.bottom_radius = 0.18; h.height = 0.8
	_m(h, Color(0.45, 0.28, 0.15), Vector3(0, 0.75, 0))
	var k := SphereMesh.new()
	k.radius = 0.3; k.height = 0.6
	_m(k, Color(0.5, 0.3, 0.16), Vector3(0, 1.25, 0))
	_eyes(body, Vector3(0, 0.25, -0.5), 0.2, 0.1)
	Game.label3d(body, "REFUSÉ", Vector3(0, 0.12, -0.49), 40, Color(1, 0.85, 0.85)).rotation.y = PI


func _physics_process(d: float) -> void:
	if dead or player == null:
		return
	_t += d
	_cd -= d
	var base := 0.3 if kind == "dossier" else 0.0
	if not busy:
		body.position.y = base + abs(sin(_t * 6)) * 0.12
	var to: Vector3 = player.global_position - global_position
	to.y = 0
	var dist := to.length()
	if not busy and dist > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 8 * d)
	var vel := Vector3.ZERO
	if not busy and player.state != "dead":
		if dist > st.reach * 0.8:
			vel = to.normalized() * st.speed
		elif _cd <= 0:
			_attack()
	velocity = vel + _knock
	_knock = _knock.move_toward(Vector3.ZERO, 20 * d)
	move_and_slide()
	position.y = 0


func _player_in_reach(extra := 0.0) -> bool:
	var to: Vector3 = player.global_position - global_position
	to.y = 0
	return to.length() < st.reach + extra


func _attack() -> void:
	busy = true
	_tint(Color(1, 0.75, 0.1), 0.6) # telegraph
	var tw := create_tween()
	if kind == "tampon":
		tw.tween_property(body, "position:y", 1.8, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(body, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN)
		await tw.finished
		if dead:
			return
		_slam_fx()
		if _player_in_reach():
			player.take_damage(st.dmg, (player.global_position - global_position).normalized())
	else:
		tw.tween_property(body, "scale", Vector3(1.15, 0.85, 1.15), 0.4)
		if part:
			tw.parallel().tween_property(part, "rotation:x", 0.8, 0.4)
		await tw.finished
		if dead:
			return
		_knock = -global_basis.z * 7
		var tw2 := create_tween()
		tw2.tween_property(body, "scale", Vector3.ONE, 0.12)
		if part:
			tw2.parallel().tween_property(part, "rotation:x", 0.0, 0.12)
		await tw2.finished
		if dead:
			return
		if _player_in_reach(0.4):
			player.take_damage(st.dmg, -global_basis.z)
	_tint(Color.BLACK, 0)
	_cd = randf_range(1.2, 2.2)
	busy = false


func _slam_fx() -> void:
	var l := Game.label3d(get_parent(), "REFUSÉ", global_position + Vector3(0, 0.03, 0), 160, Color(0.85, 0.05, 0.05))
	l.rotation = Vector3(-PI / 2, randf() * TAU, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 1.5).set_delay(0.8)
	tw.tween_callback(l.queue_free)


func _tint(c: Color, e: float) -> void:
	for m in mats:
		m.emission_enabled = e > 0
		m.emission = c
		m.emission_energy_multiplier = e


func _update_label() -> void:
	label.text = "%s\n%d / %d" % [st.name, max(0, hp), st.hp]


func take_damage(dmg: float, dir: Vector3) -> void:
	if dead:
		return
	hp -= dmg
	_knock = dir * 6
	Game.float_text(get_parent(), global_position + Vector3(0, 1.6, 0), str(int(dmg)), Color(1, 0.9, 0.3))
	_update_label()
	if hp <= 0:
		_die()
		return
	_tint(Color.WHITE, 2.5)
	await get_tree().create_timer(0.08).timeout
	if not dead:
		if busy:
			_tint(Color(1, 0.75, 0.1), 0.6)
		else:
			_tint(Color.BLACK, 0)


func _die() -> void:
	dead = true
	remove_from_group("monsters")
	_col.set_deferred("disabled", true)
	Game.float_text(get_parent(), global_position + Vector3(0, 2.2, 0), "Classé sans suite !", Color(0.6, 1, 0.6), 48)
	died.emit()
	var tw := create_tween()
	tw.tween_property(self, "rotation:y", rotation.y + TAU, 0.5)
	tw.parallel().tween_property(self, "scale", Vector3.ONE * 0.01, 0.5)
	tw.tween_callback(queue_free)
