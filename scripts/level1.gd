extends Node3D
## Level 1 — Préfecture waiting room. Beat 4 office monsters, then the secretary appears -> battle.

const W := 18.0
const D := 14.0
const SPAWNS := {
	"agrafeuse": Vector3(-5.5, 0, -2.5),
	"classeur": Vector3(5.5, 0, -2.5),
	"dossier": Vector3(-2.0, 0, -3.5),
	"tampon": Vector3(2.0, 0, -3.5),
}

var player: Player
var hud: Hud
var alive := 0


func _ready() -> void:
	Game.build_room(self, W, D)
	_furnish()
	player = Player.new()
	player.position = Vector3(0, 0, 5)
	add_child(player)
	hud = Hud.new()
	add_child(hud)
	player.hp_changed.connect(hud.set_hp)
	player.died.connect(_on_player_died)
	hud.set_hp(player.hp, player.max_hp)
	hud.show_message("Préfecture — 8h47\nLe guichet 3 est fermé… et les fournitures attaquent !", 3.0)
	await get_tree().create_timer(1.5).timeout
	for kind in SPAWNS:
		var m := Monster.new()
		m.kind = kind
		m.position = SPAWNS[kind]
		add_child(m)
		m.died.connect(_on_monster_died)
		alive += 1
	_update_objective()


func _furnish() -> void:
	var counter := Color(0.55, 0.42, 0.3)
	Game.box(self, Vector3(W - 2, 1.1, 0.8), Vector3(0, 0.55, -5.4), counter)
	Game.box(self, Vector3(W, 3.5, 0.1), Vector3(0, 1.75, -5.0), Color(0, 0, 0, 0), true).visible = false # keeps player out from behind
	for i in 3:
		var x := -5.0 + i * 5.0
		var glass: GeometryInstance3D = Game.box(self, Vector3(3.6, 1.2, 0.05), Vector3(x, 1.75, -5.4), Color(0.7, 0.85, 1.0, 0.25), false)
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var txt := "GUICHET %d\n%s" % [i + 2, "FERMÉ" if i != 1 else "Prochain : ???"]
		Game.label3d(self, txt, Vector3(x, 2.6, -5.35), 40, Color(1, 0.9, 0.5))
	Game.label3d(self, "PRÉFECTURE — Service des titres de séjour", Vector3(0, 3.1, -6.8), 72, Color(0.15, 0.2, 0.45))
	# ticket screen
	Game.box(self, Vector3(1.8, 0.7, 0.1), Vector3(6.5, 2.6, -6.8), Color(0.05, 0.05, 0.05), false)
	Game.label3d(self, "N° 004\nVotre n° : 847", Vector3(6.5, 2.6, -6.72), 36, Color(1, 0.2, 0.15))
	# posters
	var p := Game.label3d(self, "TOUT DOSSIER INCOMPLET\nNE SERA PAS TRAITÉ", Vector3(-8.83, 2.2, -1), 44, Color(0.7, 0.05, 0.05))
	p.rotation.y = PI / 2
	var p2 := Game.label3d(self, "Merci de votre patience.\nTemps d'attente estimé : 6 mois", Vector3(8.83, 2.2, 0), 40, Color(0.1, 0.1, 0.1))
	p2.rotation.y = -PI / 2
	# waiting chairs
	for side in [-1, 1]:
		for row in 2:
			Game.box(self, Vector3(3.0, 0.45, 0.5), Vector3(side * 5.0, 0.225, 1.8 + row * 1.6), Color(0.95, 0.5, 0.15))
			Game.box(self, Vector3(3.0, 0.5, 0.08), Vector3(side * 5.0, 0.7, 2.05 + row * 1.6), Color(0.95, 0.5, 0.15), false)


func _update_objective() -> void:
	hud.objective.text = "Fournitures hostiles : %d" % alive if alive > 0 else "Le guichet 3 ouvre…"


func _on_monster_died() -> void:
	alive -= 1
	_update_objective()
	if alive == 0:
		_boss_intro()


func _boss_intro() -> void:
	await get_tree().create_timer(1.0).timeout
	player.freeze()
	hud.show_message("Le guichet 3 ouvre…", 2.0)
	var sec := Game.make_secretary_model()
	sec.idle = "Idle_No"
	sec.position = Vector3(0, 0, -6.2)
	sec.rotation.y = PI # face the room (+Z)
	add_child(sec)
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 3.4, -4.5)
	spot.rotation_degrees = Vector3(-70, 0, 0)
	spot.light_color = Color(1, 0.85, 0.6)
	spot.light_energy = 6
	add_child(spot)
	var boss: Dictionary = Game.data.bosses.secretaire
	Game.label3d(self, boss.name, Vector3(0, 2.3, -6.2), 40, Color(1, 0.7, 1), true)
	await get_tree().create_timer(2.2).timeout
	hud.show_message(boss.intro, 2.5)
	await get_tree().create_timer(3.0).timeout
	hud.show_message("COMBAT !", 1.0)
	await get_tree().create_timer(1.0).timeout
	Game.go_battle("secretaire")


func _on_player_died() -> void:
	hud.show_message("Vous avez été découragé(e)…\nRetour à la file d'attente.", 3.0)
	await get_tree().create_timer(3.5).timeout
	get_tree().reload_current_scene()
