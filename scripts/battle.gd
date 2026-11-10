extends Node3D
## Turn-based boss battle. Every attack is a real animated hit:
## the attacker runs to the target, strikes, the target reacts, then returns.
## Boss turn: press SPACE right as a hit lands to PARRY. Parry every hit => counter-attack.

signal action_chosen(atk: Dictionary)

const PLAYER_HOME := Vector3(-2.6, 0, 0)
const BOSS_HOME := Vector3(2.6, 0, 0)
const MELEE_GAP := 1.3
const CUE_LEAD := 0.45 # "!" shown this long before a hit
const PARRY_WINDOW := 0.33 # valid press: [hit - 0.25, hit + 0.08]
const PARRY_LATE := 0.08

var pdata: Dictionary
var bdata: Dictionary
var player: CharacterModel
var boss: CharacterModel
var cam: Camera3D
var hp := 100.0
var max_hp := 100.0
var boss_hp := 100.0
var boss_max := 100.0
var ap := 0
var stunned := false
var phase2 := false
var boss_turn := false
var _cue_on := false
var _last_press := -10.0
var _lockout := 0.0
var _cue: Label3D

# UI
var boss_bar: ProgressBar
var hp_bar: ProgressBar
var hp_text: Label
var ap_bar: ProgressBar
var ap_text: Label
var menu: VBoxContainer
var desc: Label
var banner: Label
var hint: Label
var result: PanelContainer
var result_text: Label
var result_btn: Button
var _banner_tw: Tween


func _ready() -> void:
	pdata = Game.data.player
	bdata = Game.data.bosses[Game.current_boss]
	max_hp = pdata.hp
	hp = max_hp
	boss_max = bdata.hp
	boss_hp = boss_max
	ap = int(pdata.ap_start)
	_build_arena()
	_build_ui()
	_refresh()
	await _wait(0.6)
	await _banner(bdata.name, Color(1, 0.7, 1), 1.6)
	await _banner(bdata.intro, Color.WHITE, 1.8)
	_loop()


# ---------------- scene ----------------

func _build_arena() -> void:
	Game.build_room(self, 14, 10)
	Game.box(self, Vector3(3, 1.0, 1.0), Vector3(5.2, 0.5, -1.5), Color(0.55, 0.42, 0.3)) # her desk
	Game.box(self, Vector3(0.5, 0.35, 0.4), Vector3(5.0, 1.2, -1.5), Color(0.15, 0.15, 0.15), false) # monitor
	Game.label3d(self, "GUICHET 3", Vector3(0, 3.0, -4.8), 80, Color(0.15, 0.2, 0.45))
	Game.label3d(self, "Pièces justificatives : originaux + 3 copies + ???", Vector3(0, 2.3, -4.8), 40, Color(0.5, 0.1, 0.1))
	player = Game.make_player_model()
	player.idle = "Idle"
	player.position = PLAYER_HOME
	add_child(player)
	Game.face(player, Vector3.RIGHT)
	boss = Game.make_secretary_model()
	boss.idle = "Idle_FoldArms"
	boss.position = BOSS_HOME
	add_child(boss)
	Game.face(boss, Vector3.LEFT)
	cam = Camera3D.new()
	cam.fov = 50
	add_child(cam)
	cam.position = Vector3(-6.0, 2.4, 4.8)
	cam.look_at(Vector3(0.4, 1.0, 0))
	_cue = Game.label3d(self, "!", Vector3(0, 0, 0), 220, Color(1, 0.9, 0.2), true)
	_cue.no_depth_test = true
	_cue.visible = false


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	# boss (top)
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 20)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	ui.add_child(top)
	var bn := Game.ui_label(bdata.name, 24, Color(1, 0.75, 1))
	bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(bn)
	boss_bar = Game.ui_bar(Color(0.85, 0.2, 0.3), 520)
	top.add_child(boss_bar)
	# player (bottom-left)
	var pl := VBoxContainer.new()
	pl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	pl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ui.add_child(pl)
	pl.add_child(Game.ui_label("VOUS", 24))
	hp_bar = Game.ui_bar(Color(0.3, 0.85, 0.4))
	pl.add_child(hp_bar)
	hp_text = Game.ui_label("", 18)
	pl.add_child(hp_text)
	ap_bar = Game.ui_bar(Color(0.95, 0.8, 0.2), 200)
	pl.add_child(ap_bar)
	ap_text = Game.ui_label("", 18, Color(1, 0.9, 0.5))
	pl.add_child(ap_text)
	# action menu (bottom-right)
	var right := VBoxContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ui.add_child(right)
	desc = Game.ui_label("", 18, Color(0.85, 0.9, 1))
	right.add_child(desc)
	menu = VBoxContainer.new()
	right.add_child(menu)
	for atk in pdata.attacks:
		var b := Button.new()
		b.custom_minimum_size = Vector2(460, 42)
		b.add_theme_font_size_override("font_size", 19)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.set_meta("atk", atk)
		b.pressed.connect(func(): action_chosen.emit(atk))
		b.focus_entered.connect(func(): desc.text = atk.desc)
		b.mouse_entered.connect(func(): desc.text = atk.desc)
		menu.add_child(b)
	menu.visible = false
	# banner + hint
	banner = Game.ui_label("", 40)
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 100
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(banner)
	hint = Game.ui_label("ESPACE au moment de l'impact pour PARER", 20, Color(1, 0.9, 0.3))
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 30)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.visible = false
	ui.add_child(hint)
	# result
	result = PanelContainer.new()
	result.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result.grow_vertical = Control.GROW_DIRECTION_BOTH
	var rb := VBoxContainer.new()
	rb.add_theme_constant_override("separation", 20)
	result.add_child(rb)
	result_text = Game.ui_label("", 34)
	result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rb.add_child(result_text)
	result_btn = Button.new()
	result_btn.add_theme_font_size_override("font_size", 22)
	rb.add_child(result_btn)
	result.visible = false
	ui.add_child(result)


func _refresh() -> void:
	boss_bar.max_value = boss_max
	boss_bar.value = boss_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_text.text = "PV %d / %d" % [hp, max_hp]
	ap_bar.max_value = pdata.ap_max
	ap_bar.value = ap
	ap_text.text = "Points d'Action : %d / %d" % [ap, pdata.ap_max]
	for b: Button in menu.get_children():
		var atk: Dictionary = b.get_meta("atk")
		b.text = "%s   (%d PA)" % [atk.name, atk.cost]
		b.disabled = ap < int(atk.cost)


# ---------------- helpers ----------------

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _wait(t: float) -> void:
	if t > 0:
		await get_tree().create_timer(t).timeout


func _banner(text: String, c := Color.WHITE, hold := 1.4) -> void:
	if _banner_tw:
		_banner_tw.kill()
	banner.text = text
	banner.add_theme_color_override("font_color", c)
	banner.modulate.a = 1.0
	banner.scale = Vector2.ONE
	_banner_tw = create_tween()
	_banner_tw.tween_property(banner, "modulate:a", 0.0, 0.4).set_delay(hold)
	await _wait(hold * 0.6)


func _move(actor: CharacterModel, to: Vector3, look: Vector3) -> void:
	var dir := to - actor.position
	dir.y = 0
	if dir.length() > 0.05:
		Game.face(actor, dir)
		actor.play("Sprint")
		var tw := create_tween()
		tw.tween_property(actor, "position", to, dir.length() / 9.0)
		await tw.finished
	Game.face(actor, look)
	actor.play(actor.idle)


## Leap backwards to `home` while still facing the opponent.
func _jump_back(actor: CharacterModel, home: Vector3, look: Vector3) -> void:
	Game.face(actor, look)
	actor.play_once("Jump_Start", 1.6)
	var dur := 0.6
	var tw := create_tween()
	tw.tween_property(actor, "position:x", home.x, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(actor, "position:z", home.z, dur)
	tw.parallel().tween_property(actor, "position:y", 0.9, dur * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(actor, "position:y", 0.0, dur * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(dur * 0.45)
	await _wait(0.2)
	actor.play("Jump")
	await tw.finished
	actor.position = home
	actor.play_once("Jump_Land", 1.5)
	await _wait(0.25)


## Hit reaction without restarting the animation on every hit of a combo (avoids jitter).
func _hit_react(actor: CharacterModel, push: Vector3) -> void:
	var cur := String(actor.anim.current_animation)
	if cur != "Hit_Chest" or actor.anim.current_animation_position > 0.25:
		actor.play_once("Hit_Chest")
	var base := PLAYER_HOME if actor == player else BOSS_HOME
	var tw := create_tween()
	tw.tween_property(actor, "position", base + push * 0.25, 0.08)
	tw.tween_property(actor, "position", base, 0.2)


func _shake(amount := 0.15) -> void:
	var tw := create_tween()
	for i in 4:
		tw.tween_property(cam, "h_offset", randf_range(-amount, amount), 0.04)
		tw.parallel().tween_property(cam, "v_offset", randf_range(-amount, amount), 0.04)
	tw.tween_property(cam, "h_offset", 0.0, 0.05)
	tw.parallel().tween_property(cam, "v_offset", 0.0, 0.05)


func _projectile(from: Vector3, to: Vector3, t: float) -> void:
	var p := Node3D.new()
	add_child(p)
	var b := BoxMesh.new()
	b.size = Vector3(0.35, 0.03, 0.45)
	Game.add_mesh(p, b, Color(0.98, 0.98, 0.95), Vector3.ZERO)
	p.global_position = from
	var tw := create_tween()
	tw.tween_property(p, "global_position", to, t)
	tw.parallel().tween_property(p, "rotation", Vector3(TAU * 2, TAU, 0), t)
	tw.tween_callback(p.queue_free)


# ---------------- input (parry) ----------------

func _unhandled_input(e: InputEvent) -> void:
	if not boss_turn or not e.is_action_pressed("parry") or e.is_echo():
		return
	var now := _now()
	if now < _lockout:
		return
	if not _cue_on:
		_lockout = now + 0.8 # pressed too early: punished
		Game.float_text(self, player.global_position + Vector3(0, 2.2, 0), "Trop tôt !", Color(0.7, 0.7, 0.7), 40)
		return
	_last_press = now
	_lockout = now + 0.5
	player.play_once("Sword_Block", 1.6)


# ---------------- battle flow ----------------

func _loop() -> void:
	while true:
		await _player_turn()
		if boss_hp <= 0:
			_victory()
			return
		if not phase2 and boss_hp <= boss_max * 0.5 and bdata.has("phase2_attacks"):
			phase2 = true
			await _banner(bdata.phase2, Color(1, 0.5, 0.5), 2.2)
			boss.play_once("Idle_Shield_Break")
			await _wait(1.0)
		await _boss_turn()
		if hp <= 0:
			_defeat()
			return


func _player_turn() -> void:
	if stunned:
		stunned = false
		await _banner("Le système est en panne… vous patientez (tour perdu)", Color(0.7, 0.7, 0.8), 1.6)
		return
	_refresh()
	menu.visible = true
	desc.text = ""
	for b: Button in menu.get_children():
		if not b.disabled:
			b.grab_focus()
			break
	var atk: Dictionary = await action_chosen
	menu.visible = false
	desc.text = ""
	ap -= int(atk.cost)
	_refresh()
	await _banner(atk.name, Color(0.6, 0.85, 1), 1.2)
	if atk.has("heal"):
		var L := player.play_once(atk.anim)
		await _wait(L * 0.6)
		hp = min(max_hp, hp + atk.heal)
		Game.float_text(self, player.global_position + Vector3(0, 2, 0), "+%d PV" % atk.heal, Color(0.4, 1, 0.5))
		_refresh()
		await _wait(L * 0.4)
	else:
		await _move(player, BOSS_HOME - Vector3(MELEE_GAP, 0, 0), Vector3.RIGHT)
		for mv in atk.moves:
			var L := player.play_once(mv.anim)
			var start := _now()
			for f in mv.hits:
				await _wait(start + L * f - _now())
				_hurt_boss(mv.dmg)
			await _wait(start + L * 0.92 - _now())
		await _jump_back(player, PLAYER_HOME, Vector3.RIGHT)
	ap = min(int(pdata.ap_max), ap + int(atk.get("gain", 0)))
	_refresh()


func _hurt_boss(dmg: float) -> void:
	boss_hp = max(0.0, boss_hp - dmg)
	_hit_react(boss, Vector3.RIGHT)
	Game.float_text(self, boss.global_position + Vector3(0, 2.1, 0), str(int(dmg)), Color(1, 0.9, 0.3))
	_shake(0.08)
	_refresh()


func _boss_turn() -> void:
	var pool: Array = bdata.attacks.duplicate()
	if phase2:
		pool += bdata.phase2_attacks
	var atk: Dictionary = pool.pick_random()
	await _banner(atk.name, Color(1, 0.35, 0.35), 1.4)
	boss_turn = true
	hint.visible = true
	var ranged: bool = atk.get("ranged", false)
	if not ranged:
		await _move(boss, PLAYER_HOME + Vector3(MELEE_GAP, 0, 0), Vector3.LEFT)
	var hits := 0
	var parried := 0
	for mv in atk.moves:
		var L := boss.play_once(mv.anim)
		var start := _now()
		for f in mv.hits:
			var hit_t: float = start + L * f
			await _wait(hit_t - CUE_LEAD - _now())
			_show_cue(true)
			if ranged:
				_projectile(boss.global_position + Vector3(0, 1.4, 0), player.global_position + Vector3(0, 1.2, 0), max(0.1, hit_t - _now()))
			await _wait(hit_t + PARRY_LATE - _now())
			_show_cue(false)
			hits += 1
			if _now() - _last_press <= PARRY_WINDOW:
				parried += 1
				Game.float_text(self, player.global_position + Vector3(0, 2.2, 0), "PARÉ !", Color(1, 0.95, 0.3), 80)
				_shake(0.05)
			else:
				_hurt_player(mv.dmg, atk.get("knockback", false))
		await _wait(start + L * 0.92 - _now())
	boss_turn = false
	hint.visible = false
	if parried < hits and hp > 0:
		if atk.has("ap_drain"):
			ap = max(0, ap - int(atk.ap_drain))
			Game.float_text(self, player.global_position + Vector3(0, 2.6, 0), "-%d PA" % atk.ap_drain, Color(1, 0.8, 0.2), 56)
		if atk.get("stun", false):
			stunned = true
	_refresh()
	if not ranged:
		await _jump_back(boss, BOSS_HOME, Vector3.LEFT)
	if hits > 0 and parried == hits and hp > 0:
		await _counter()


func _show_cue(on: bool) -> void:
	_cue_on = on
	_cue.visible = on
	_cue.global_position = player.global_position + Vector3(0, 2.4, 0)


func _hurt_player(dmg: float, knockback: bool) -> void:
	hp = max(0.0, hp - dmg)
	Game.float_text(self, player.global_position + Vector3(0, 2.1, 0), "-%d" % dmg, Color(1, 0.3, 0.3))
	_shake(0.05)
	if hp <= 0:
		player.idle = ""
		player.play_once("Death01")
	else:
		_hit_react(player, Vector3.LEFT * (2.0 if knockback else 1.0))
	_refresh()


func _counter() -> void:
	var c: Dictionary = pdata.counter
	await _banner(c.name, Color(1, 0.95, 0.4), 1.0)
	await _move(player, BOSS_HOME - Vector3(MELEE_GAP, 0, 0), Vector3.RIGHT)
	var L := player.play_once(c.anim)
	await _wait(L * c.hit)
	_hurt_boss(c.dmg)
	await _wait(L * (0.9 - c.hit))
	await _jump_back(player, PLAYER_HOME, Vector3.RIGHT)


func _victory() -> void:
	boss.idle = ""
	boss.play_once("Death01")
	player.set_idle("Dance")
	await _wait(1.5)
	_show_result(bdata.victory, "Rejouer le niveau 1 (niveau 2 à venir)", Game.go_level1)


func _defeat() -> void:
	await _wait(1.5)
	_show_result(bdata.defeat, "Reprendre un ticket", get_tree().reload_current_scene)


func _show_result(text: String, btn: String, cb: Callable) -> void:
	result_text.text = text
	result_btn.text = btn
	result_btn.pressed.connect(cb)
	result.visible = true
	result_btn.grab_focus()
