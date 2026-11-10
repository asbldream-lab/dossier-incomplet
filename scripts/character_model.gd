class_name CharacterModel
extends Node3D
## A UAL mannequin with the merged animation library. Node faces -Z.

var anim: AnimationPlayer
var skeleton: Skeleton3D
var idle := "Idle" # played after any one-shot; "" = hold last pose (death)
var weapon: Node3D # attached to hand_r on ready
var weapon_bone := "hand_r"
var _glb := ""
var _body := Color.WHITE
var _joints := Color.GRAY


func setup_deferred(glb: String, body: Color, joints: Color) -> void:
	_glb = glb
	_body = body
	_joints = joints


func _ready() -> void:
	var m: Node3D = (load(_glb) as PackedScene).instantiate()
	m.rotation.y = Game.MODEL_YAW
	add_child(m)
	for old in m.find_children("*", "AnimationPlayer", true, false):
		old.get_parent().remove_child(old)
		old.free()
	anim = AnimationPlayer.new()
	m.add_child(anim) # root_node ".." => same track paths as the imported player
	anim.add_animation_library("", Game.anim_library())
	anim.animation_finished.connect(_on_finished)
	var sk := m.find_children("*", "Skeleton3D", true, false)
	if sk.size() > 0:
		skeleton = sk[0]
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			var joint := src != null and src.resource_name.contains("Joint")
			mi.set_surface_override_material(i, Game.mat(_joints if joint else _body, 0.6))
	if weapon:
		attach(weapon_bone, weapon)
	anim.play(idle)


func _on_finished(_n: StringName) -> void:
	if idle != "":
		anim.play(idle, 0.2)


func play(n: String, speed := 1.0) -> void:
	if anim.current_animation != n:
		anim.play(n, 0.2, speed)


## Restart a one-shot animation; returns its real duration in seconds.
func play_once(n: String, speed := 1.0) -> float:
	if not anim.has_animation(n):
		push_warning("missing anim " + n)
		return 0.5
	anim.play(n, 0.1, speed)
	anim.seek(0.0, true)
	return anim.get_animation(n).length / speed


func set_idle(n: String) -> void:
	idle = n
	if n != "":
		play(n)


func length(n: String) -> float:
	return anim.get_animation(n).length if anim.has_animation(n) else 0.5


func attach(bone: String, item: Node3D) -> void:
	if skeleton == null or skeleton.find_bone(bone) < 0:
		push_warning("bone not found: " + bone)
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skeleton.add_child(ba)
	ba.add_child(item)
	var s := skeleton.global_transform.basis.get_scale()
	item.scale = Vector3(1.0 / s.x, 1.0 / s.y, 1.0 / s.z)
