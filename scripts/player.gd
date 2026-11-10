class_name Player
extends CharacterBody3D
## Real-time player: move (ZQSD/arrows), attack combo (J / click), roll (Space).

signal hp_changed(hp: float, max_hp: float)
signal died

const SPEED := 5.0
const ROLL_SPEED := 8.5
const COMBO := ["Punch_Jab", "Punch_Cross", "Melee_Hook"]
const CAM_OFFSET := Vector3(0, 7.5, 7.0)

var max_hp := 100.0
var hp := 100.0
var state := "move" # move, attack, roll, hit, frozen, dead
var model: CharacterModel
var cam: Camera3D
var _combo := 0
var _queued := false
var _act := 0 # action id: invalidates stale coroutines
var _invuln := 0.0
var _roll_dir := Vector3.ZERO


func _ready() -> void:
	add_to_group("player")
	max_hp = Game.data.player.hp
	hp = max_hp
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)
	model = Game.make_player_model()
	model.idle = "Idle"
	add_child(model)
	cam = Camera3D.new()
	cam.top_level = true
	cam.fov = 50
	add_child(cam)
	_update_cam(1.0)


func _physics_process(d: float) -> void:
	_invuln = max(0.0, _invuln - d)
	var inp := Input.get_vector("left", "right", "up", "down")
	var dir := Vector3(inp.x, 0, inp.y)
	match state:
		"move":
			velocity = dir * SPEED
			if dir.length() > 0.1:
				Game.face(self, dir)
				model.play("Jog_Fwd")
			else:
				model.play("Idle")
			if Input.is_action_just_pressed("attack"):
				_attack()
			elif Input.is_action_just_pressed("dodge"):
				_roll(dir if dir.length() > 0.1 else -global_basis.z)
		"attack":
			velocity = velocity.move_toward(Vector3.ZERO, 30 * d)
			if Input.is_action_just_pressed("attack"):
				_queued = true
		"roll":
			velocity = _roll_dir * ROLL_SPEED
		"hit":
			velocity = velocity.move_toward(Vector3.ZERO, 15 * d)
		_:
			velocity = Vector3.ZERO
	velocity.y = 0
	move_and_slide()
	position.y = 0
	_update_cam(d)


func _update_cam(d: float) -> void:
	var target := global_position + CAM_OFFSET
	cam.global_position = cam.global_position.lerp(target, min(1.0, 6 * d))
	cam.look_at(cam.global_position - CAM_OFFSET + Vector3(0, 1, 0))


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _attack() -> void:
	_act += 1
	var id := _act
	state = "attack"
	_queued = false
	var n: String = COMBO[_combo]
	_combo = (_combo + 1) % COMBO.size()
	var L := model.play_once(n, 1.4)
	await _wait(L * 0.4)
	if id != _act:
		return
	_hit_monsters(25.0 if n == "Melee_Hook" else 15.0)
	await _wait(L * 0.3)
	if id != _act:
		return
	if _queued:
		_attack()
	else:
		_combo = 0
		state = "move"


func _hit_monsters(dmg: float) -> void:
	var fwd := -global_basis.z
	for m in get_tree().get_nodes_in_group("monsters"):
		var to: Vector3 = m.global_position - global_position
		to.y = 0
		if to.length() < 2.0 and fwd.dot(to.normalized()) > 0.2:
			m.take_damage(dmg, to.normalized())


func _roll(dir: Vector3) -> void:
	_act += 1
	var id := _act
	state = "roll"
	_roll_dir = dir.normalized()
	Game.face(self, dir)
	var L := model.play_once("Roll", 1.3)
	_invuln = L * 0.8
	await _wait(L * 0.8)
	if id == _act:
		state = "move"


func take_damage(dmg: float, from_dir: Vector3) -> void:
	if state in ["dead", "roll", "frozen"] or _invuln > 0:
		return
	hp = max(0.0, hp - dmg)
	hp_changed.emit(hp, max_hp)
	Game.float_text(get_parent(), global_position + Vector3(0, 2, 0), "-%d" % dmg, Color(1, 0.3, 0.3))
	_act += 1
	if hp <= 0:
		state = "dead"
		model.idle = ""
		model.play_once("Death01")
		died.emit()
		return
	var id := _act
	state = "hit"
	_invuln = 0.7
	velocity = from_dir * 5
	model.play_once("Hit_Chest", 1.3)
	await _wait(0.45)
	if id == _act:
		state = "move"


func freeze() -> void:
	_act += 1
	state = "frozen"
	model.play("Idle")
