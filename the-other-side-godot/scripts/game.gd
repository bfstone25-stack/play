extends Node3D

## The Other Side — the adult night twin of Across the Hall (ops/adult_forks/across-the-hall.md §2).
##
## The one rule that makes it a different world (ops/adult_forks/TWO_WORLDS.md): in Across
## the Hall there was never anyone across the hall. Here there was never anyone, and then
## there was. Across the hall is a woman — not your face rested, not a version of you, but
## the life you did not claim, standing in it. The mirror shows her because at 02:17 the
## glass stops showing you what you settled for, and the game is walking toward her. Cut
## the figure and the rule has no payoff.
##
## Recast 2026-09-19 (Blaze). The neighbour was a man, and the payoff was a half-dressed
## man in a doorway on a shelf whose payers are men. Changing the premise's gender cost the
## premise nothing; every line below was rewritten, not pronoun-swapped, because she is a
## different person from the player rather than a copy of him.
##
## Four beats, playable end to end:
##   1. wake in 401, reach the bathroom mirror — it shows a woman who moves when you do not
##   2. cross the hall — 402 opens this time; it is 401 mirrored, one real thing per room
##   3. the neighbour resolves into a rendered person as you approach; an exchange, a choice
##   4. the choice decides whether the mirror keeps its image; the clear state; the board

## The prose moved to scripts/loc.gd, which holds every line in en / ja / zh / zh-Hant.
## STANDARD.md rule 7 puts ja first for this title — 507 of the 581 DLsite works we
## scraped are Japanese — and this game's text is short enough that the translation is
## the work, not the plumbing. Nothing here may be an English literal any more: a literal
## is a line that ships untranslated in four storefronts and nothing fails.

## Three lines and a choice, through the click-to-advance panel (hud.show_dialogue).
## The ids are resolved at show time so a locale chosen on the splash still applies.
const CONFRONT_IDS := ["c_line1", "c_line2", "c_line3", "c_line4"]
const CHOICE_IDS := ["c_choice1", "c_choice2"]

## How far back the camera settles for the exchange, in metres.
const CONFRONT_STANDOFF := 2.3

var items := {}
var phase := 0
var chapter := 1
var ending := false
var apt401_open := false
var apt402_open := false
var visited_402 := false
var mirror_seen := false
var confronting := false
var choice := -1
var await_restart := false
var caught_t := 0.0
var title_t := 5.5

## The voice. ops/barks/lines.json -> assets/voice/, played by ambience.gd's shared bark
## layer. `amb` used to be a local in _ready(), so nothing could ever ask it to speak.
var amb: Node
var _greeted := false
var _idle_t := 0.0
var _idle_from := Vector3.ZERO
## How many of this run's five objects the player actually looked at. The difference
## between "win" and "win_big" is curiosity, not the ending taken.
var _looked := {}
const LOOKED_ALL := 5
## How many times this player has crossed the hall before. Drives the "streak" line.
var runs := 0
const RUNS_CFG := "user://runs.cfg"

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $HUD
@onready var tape_player: AudioStreamPlayer = $Tape
@onready var drone: AudioStreamPlayer = $Drone
@onready var sfx: AudioStreamPlayer3D = $Sfx
var unlock: Node

func _ready() -> void:
	add_to_group("game")
	player.add_to_group("player")
	unlock = Node.new()
	unlock.set_script(preload("res://scripts/unlock.gd"))
	add_child(unlock)
	_setup_audio()
	_spawn_pickups()
	amb = Node.new()
	amb.set_script(preload("res://scripts/ambience.gd"))
	add_child(amb)
	_count_run()
	hud.show_title(I18n.t("title") + "\n" + I18n.t("ch1_card"))
	hud.set_objective(I18n.t("ch1_obj"))
	if OS.has_feature("web"):
		var env: Environment = $WorldEnvironment.environment
		# GL compatibility has no SSAO and no glow, so the web build loses the contact
		# shadows and the bulb's bloom and needs a little lift to compensate — a LITTLE.
		# The old values (ambient 0.62, exposure 1.28) lifted it by 5.6x and 1.35x, which
		# is most of how the night palette became a pink wash on the web.
		env.ssao_enabled = false
		env.glow_enabled = false
		env.fog_density = 0.0035
		# Measured on the GPU box (real WebGL2), not in a software rasteriser: compat's
		# own output is DARKER than both the desktop renderer and headless SwiftShader,
		# so the web branch lifts rather than cuts.
		env.ambient_light_energy = 0.24
		env.tonemap_exposure = 1.28
		# The saturation lift was added to stop the desktop frames reading washed. Compat
		# has no glow to bleed a highlight's hue back toward white, so the same lift here
		# renders the whole flat as one pink. The lights carry the colour; the grade does
		# not need to help them. (The lights themselves are trimmed in
		# world_builder._compat_trim.)
		env.adjustment_saturation = 0.92
	else:
		player.capture_mouse()
	# The mirror is the first thing lit: the plum room, one hot bulb through the bathroom door.
	_dim_hall(0.9)
	show_note(I18n.t("n_wake"))

## One line from the voice. Never awaited and never checked: a bark that does not fire
## (muted, already speaking, not installed in this package) must not change the game.
func bark(slot: String) -> void:
	if amb and amb.has_method("bark"):
		amb.bark(slot)


## A run counter in user://, read before the first bark so a returning player is greeted as
## one. Web builds keep it in the browser's own storage, which is per-origin and survives a
## reload — exactly the player this line is for.
func _count_run() -> void:
	var c := ConfigFile.new()
	c.load(RUNS_CFG)
	runs = int(c.get_value("run", "n", 0)) + 1
	c.set_value("run", "n", runs)
	c.save(RUNS_CFG)


func _setup_audio() -> void:
	drone.stream = _tone_stream(44.0, 0.32)
	drone.volume_db = -20.0
	drone.play()
	tape_player.stream = _tape_stream()

func _unhandled_input(event: InputEvent) -> void:
	if hud.dialogue_input(event):
		return
	if await_restart:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	if ending or confronting:
		return
	if hud and hud.has_method("hide_splash") and hud.splash and hud.splash.visible:
		if event is InputEventMouseButton and event.pressed:
			hud.hide_splash()
			player.capture_mouse()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var t = player.interact_target()
		if t:
			t.interact(self)
			return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		var t = player.interact_target()
		if t:
			t.interact(self)

## Web drive hook for playing the build from a script: window.__cmd =
## "goto x z yaw [pitch]" | "lookat x z tx ty tz" | "use" | "look dx" | "state". Read
## once a frame, cleared after. Costs nothing without it and does nothing off the web — the same shape as Gate's ?warp=board.
var _last_cmd := ""

func _drive() -> void:
	if not OS.has_feature("web"):
		return
	var c = JavaScriptBridge.eval("window.__cmd||''")
	var cmd := str(c) if c != null else ""
	if cmd == "" or cmd == _last_cmd:
		return
	_last_cmd = cmd
	# Commands are "<seq> <verb> ..." so the same verb can be sent twice.
	var parts := cmd.split(" ").slice(1)
	match parts[0]:
		"goto":
			player.global_position = Vector3(float(parts[1]), 0.05, float(parts[2]))
			player.rotation.y = float(parts[3])
			# Optional fourth argument: head pitch in radians. Without it every driven frame
			# is shot dead level.
			var gp := 0.0 if parts.size() < 5 else float(parts[4])
			player.pitch = gp
			player.head.rotation.x = gp
			player.velocity = Vector3.ZERO
		"lookat":
			# "lookat x z tx ty tz" — stand at (x, z) and aim at a point, which is exactly what
			# tests/walkthrough.gd::_place does in the engine.
			#
			# The angle form above makes the CALLER turn a target into a yaw, and a caller that
			# gets the convention wrong does not get an error — it gets a photograph of a wall.
			# That is what the first web capture of the beat-1 mirror was, and it took a
			# side-by-side with the desktop frame to see it, because a wall lit by the bathroom
			# bulb looks like a deliberately abstract shot. Same arithmetic, in the one place
			# that already knows it.
			player.global_position = Vector3(float(parts[1]), 0.05, float(parts[2]))
			player.velocity = Vector3.ZERO
			var tgt := Vector3(float(parts[3]), float(parts[4]), float(parts[5]))
			var flat := Vector3(tgt.x, player.global_position.y, tgt.z)
			if flat.distance_to(player.global_position) > 0.05:
				player.look_at(flat, Vector3.UP)
				player.rotation.x = 0.0
				player.rotation.z = 0.0
			var lp := clampf(atan2(tgt.y - (player.global_position.y + 1.55),
				Vector2(tgt.x - player.global_position.x, tgt.z - player.global_position.z).length()), -1.2, 1.2)
			player.pitch = lp
			player.head.rotation.x = lp
		"look":
			player.rotate_y(float(parts[1]))
		"use":
			var t = player.interact_target()
			if t:
				t.interact(self)
		"state":
			JavaScriptBridge.eval("window.__state=%s" % JSON.stringify({
				"phase": phase, "chapter": chapter, "choice": choice, "ending": ending,
				"x": player.global_position.x, "z": player.global_position.z,
				"confronting": confronting, "prompt": hud.prompt.text, "objective": hud.objective.text,
				# Is the title still up? Without this a driver cannot tell "beat 3" from
				# "the splash I never dismissed, photographed for the third time" -- which
				# is exactly what tests/web_walkthrough.py did on 2026-09-21: eight frames
				# named for eight beats, all of them this screen, reported as a pass.
				"splash": hud.splash != null and hud.splash.visible,
				# Where she actually is. tests/web_walkthrough.py has to walk in on her to
				# let tenant.gd resolve by distance, and a hard-coded doorway would go on
				# reporting success after the doorway moved.
				"tenant": _tenant_xz()}))

func _tenant_xz() -> Array:
	var t := get_tree().get_first_node_in_group("tenant") as Node3D
	return [] if t == null else [t.global_position.x, t.global_position.z, t.visible]

func _process(delta: float) -> void:
	_drive()
	_voice(delta)
	if title_t > 0.0:
		title_t -= delta
		if title_t <= 0.0:
			hud.hide_title()
	if ending:
		return
	_track_402()
	var t = player.interact_target()
	if t and t.get("prompt") and not confronting:
		hud.set_prompt(I18n.t("hint_use") + str(t.prompt))
	else:
		hud.set_prompt("")
	if caught_t > 0.0:
		caught_t -= delta
		hud.set_fear(0.55)
		if caught_t <= 0.0:
			_reset_catch()
	else:
		hud.set_fear(0.35 if confronting else 0.0)

## The two barks that are not fired by an event: the greeting, and the line she says when
## the player has stopped moving.
##
## Greet waits for the splash to come DOWN rather than firing in _ready(), because _ready()
## runs behind the title screen and the first thing the player would hear is a voice talking
## over a picture they have not finished looking at.
func _voice(delta: float) -> void:
	if ending:
		return
	if not _greeted:
		if hud and hud.get("splash") and not hud.splash.visible:
			_greeted = true
			_idle_from = player.global_position
			# Third crossing or later, she says so instead of saying hello.
			bark("streak" if runs >= 3 else "greet")
		return
	# Idle is distance, not input: a player holding W against a wall is not idle, and a
	# player reading a note with their hands off the keys is.
	if player.global_position.distance_to(_idle_from) > 1.2:
		_idle_from = player.global_position
		_idle_t = 0.0
		return
	_idle_t += delta
	if _idle_t >= 26.0:
		_idle_t = 0.0
		bark("idle")


func _spawn_pickups() -> void:
	# The flashlight is on your own table this time; you live here.
	_pickup(Vector3(-3.25, 0.46, 2.4), "flashlight", I18n.t("p_flashlight"), "", Color(0.75, 0.72, 0.35), Vector3(0.28, 0.07, 0.08))
	_inspect(Vector3(-5.9, 0.85, 0.7), "clock", I18n.t("p_clock"), I18n.t("n_clock"), Color(0.2, 0.18, 0.16), Vector3(0.16, 0.16, 0.08))
	_inspect(Vector3(3.55, 0.56, 8.05), "lease", I18n.t("p_lease"), I18n.t("n_lease"), Color(0.92, 0.88, 0.72), Vector3(0.32, 0.03, 0.42))
func _inspect(pos: Vector3, id: String, prompt: String, note: String, color: Color, size: Vector3) -> void:
	var p := StaticBody3D.new()
	p.set_script(preload("res://scripts/inspect.gd"))
	p.position = pos
	p.inspect_id = id
	p.prompt = prompt
	p.note_text = note
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	p.add_child(mesh)
	# No billboard label. Interaction is announced once, at the bottom of the screen, by
	# hud.set_prompt(); a second copy floating in the world only ever collides with
	# something (it landed on the title card in the first capture) and reads as scaffolding.
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size + Vector3(0.22, 0.22, 0.22)
	col.shape = sh
	p.add_child(col)
	p.collision_layer = 1
	p.collision_mask = 0
	add_child(p)

func _pickup(pos: Vector3, id: String, prompt: String, note: String, color: Color, size: Vector3) -> void:
	var p := StaticBody3D.new()
	p.set_script(preload("res://scripts/pickup.gd"))
	p.position = pos
	p.item_id = id
	p.prompt = prompt
	p.note_text = note
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	p.add_child(mesh)
	# No billboard label. Interaction is announced once, at the bottom of the screen, by
	# hud.set_prompt(); a second copy floating in the world only ever collides with
	# something (it landed on the title card in the first capture) and reads as scaffolding.
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size + Vector3(0.25, 0.25, 0.25)
	col.shape = sh
	p.add_child(col)
	p.collision_layer = 1
	p.collision_mask = 0
	add_child(p)

func give_item(id: String) -> void:
	items[id] = true
	click_sfx()
	_looked[id] = true
	if id == "flashlight":
		player.give_flashlight()

func show_note(text: String) -> void:
	hud.show_note(text)

func inspect(id: String, text: String) -> void:
	show_note(text)
	click_sfx()
	_looked[id] = true

## Beat 1. Looking is the first act. On the web she is the censored plate until the
## page's gate reports a rendered sponsor creative AND the gateway ticket lands the bytes
## (scripts/mirror.gd, scripts/unlock.gd); a gate that passes with no creative unlocks nothing.
func look_in_mirror(mirror: Node) -> void:
	click_sfx()
	if not mirror_seen:
		mirror_seen = true
		phase = maxi(phase, 1)
		show_note(I18n.t("n_mirror1"))
		hud.note_t = 7.0
		await get_tree().create_timer(4.5).timeout
		show_note(I18n.t("n_mirror2"))
		_set_chapter(2, I18n.t("ch2_obj"))
		knock_behind_401()
		return
	if Gate.is_web() and not mirror.unlocked:
		player.locked = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.captured = false
		var ok: bool = await mirror.try_unlock(unlock)
		player.locked = false
		player.capture_mouse()
		show_note(I18n.t("n_glass_clears" if ok else "n_glass_fogged"))
		return
	show_note(I18n.t("n_mirror1") if choice < 0 else I18n.t("n_kept" if choice == 0 else "n_refused"))

func open_401() -> void:
	if apt401_open:
		return
	apt401_open = true
	click_sfx()
	var world := get_node_or_null("World")
	if world and world.has_method("open_door"):
		world.open_door("401")
	show_note(I18n.t("n_door401"))

## Beat 2. In Across the Hall this door was always open and 401 was locked; here it is
## the other way round, and it opens because you looked.
func open_402() -> void:
	if apt402_open:
		return
	apt402_open = true
	phase = maxi(phase, 2)
	click_sfx()
	var world := get_node_or_null("World")
	if world and world.has_method("open_door"):
		world.open_door("402")
	bark("unlock")
	show_note(I18n.t("n_door402"))
	_set_chapter(3, I18n.t("ch3_obj"))

func _track_402() -> void:
	if player.global_position.x > 1.9 and not visited_402:
		visited_402 = true
		show_note(I18n.t("n_flat402"))
		hud.note_t = 9.0

## Beat 3. The neighbour has resolved and is within arm's reach.
func confront() -> void:
	if confronting or choice >= 0 or ending:
		return
	confronting = true
	player.locked = true
	hud.set_prompt("")
	drone.volume_db = -8.0
	# No title card here. _set_chapter(3) already raised one on entering 402, and a second
	# card at the confrontation lands squarely on the face of the person you crossed the
	# hall to look at.
	var tenant := get_tree().get_first_node_in_group("tenant") as Node3D
	if tenant:
		player.look_at(Vector3(tenant.global_position.x, player.global_position.y, tenant.global_position.z), Vector3.UP)
		player.rotation.x = 0.0
		player.rotation.z = 0.0
		# Take a step back before she speaks. The trigger fires at 1.7 m and the walk
		# usually closes to about 1.3 — at which range a full-height figure is a face
		# filling the screen and the exchange has no staging at all. 2.3 m puts a whole
		# person in frame with the doorway behind her, which is the shot the beat wants.
		var away: Vector3 = player.global_position - tenant.global_position
		away.y = 0.0
		if away.length() > 0.05 and away.length() < CONFRONT_STANDOFF:
			player.global_position = tenant.global_position \
				+ away.normalized() * CONFRONT_STANDOFF
			player.global_position.y = 0.05
			player.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.captured = false
	var lines: Array = []
	for id in CONFRONT_IDS:
		lines.append(I18n.t(id))
	var choices: Array = []
	for id in CHOICE_IDS:
		choices.append(I18n.t(id))
	var picked: int = await hud.show_dialogue(lines, choices)
	choice = picked
	click_sfx()
	player.locked = false
	player.capture_mouse()
	confronting = false
	_resolve(picked)

## Beat 4. The choice decides whether the mirror keeps its image. Then the clear state.
func _resolve(picked: int) -> void:
	phase = 4
	for m in get_tree().get_nodes_in_group("mirror"):
		m.set_kept(picked == 0)
	if picked == 0:
		_set_chapter(4, I18n.t("ch4_kept_obj"))
		show_note(I18n.t("n_kept_line"))
	else:
		_set_chapter(4, I18n.t("ch4_refused_obj"))
		show_note(I18n.t("n_refused_line"))
	hud.note_t = 8.0
	await get_tree().create_timer(6.0).timeout
	_begin_ending()

func _set_chapter(n: int, objective: String) -> void:
	if n > chapter:
		if n >= 3:
			Gate.block("ch%d" % n, "Chapter %d" % n)   # dual-track (ops/DUAL_TRACK.md)
		chapter = n
		hud.show_title(I18n.f("chapter_n", n))
		title_t = 3.2
		# One stage line per chapter, and there are exactly four of each.
		bark("stage")
	hud.set_objective(objective)

func _begin_ending() -> void:
	ending = true
	# Kept is the win; refused is the "fail" set, which in this game is not a loss —
	# it is the line she says through a door that is closing. win_big belongs to the
	# player who looked at everything on the way, whichever door they took.
	if _looked.size() >= LOOKED_ALL:
		bark("win_big")
	else:
		bark("win" if choice == 0 else "fail")
	tape_player.play()
	_dim_hall(0.35)
	show_note(I18n.t("n_kept" if choice == 0 else "n_refused"))
	hud.note_t = 40.0
	player.locked = true
	drone.volume_db = -6.0
	hud.set_objective(I18n.t("end_kept_obj" if choice == 0 else "end_refused_obj"))
	hud.set_prompt(I18n.t("restart"))
	hud.show_title(I18n.t("title") + "\n" + I18n.t("end_kept_card" if choice == 0 else "end_refused_card"))
	await_restart = true
	# End of the run: the cross-promotion board (play/_shared/board.js). Adult fork, adult
	# host only — board.js refuses to draw the adult board anywhere else, and this build is
	# never served from blazecore.dev (ops/check_adsense_isolation.py).
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.captured = false
	Gate.board_offer_more("adult")

func knock_behind_401() -> void:
	sfx.global_position = Vector3(-1.6, 1.2, 2.4)
	sfx.stream = _click_stream(70.0, 0.16)
	sfx.volume_db = -4.0
	sfx.play()

func on_tenant_seen() -> void:
	sfx.stream = _click_stream(220.0, 0.08)
	sfx.volume_db = -8.0
	sfx.play()
	hud.set_fear(0.35)
	bark("near")

func caught() -> void:
	if ending or caught_t > 0.0 or confronting:
		return
	caught_t = 2.2
	player.locked = true
	hud.show_note(I18n.t("n_caught"))
	drone.volume_db = -3.0

func _reset_catch() -> void:
	player.locked = false
	drone.volume_db = -20.0
	hud.set_objective(I18n.t("n_letgo"))

## A scale on each fixture's own energy, not an assignment. Assigning flattened six lights
## that had been balanced against each other to a single value, which is half of why the
## night palette stopped having any range in it.
func _dim_hall(scale: float) -> void:
	for n in get_tree().get_nodes_in_group("hall_light"):
		if n is OmniLight3D:
			(n as OmniLight3D).light_energy = float(n.get_meta("base_energy", 1.0)) * scale

func footstep(pos: Vector3) -> void:
	sfx.global_position = pos
	sfx.stream = _click_stream(randf_range(85.0, 130.0), 0.055)
	sfx.volume_db = -15.0
	sfx.play()

func click_sfx() -> void:
	sfx.stream = _click_stream(420.0, 0.04)
	sfx.volume_db = -10.0
	sfx.play()

func _tone_stream(hz: float, amp: float) -> AudioStreamWAV:
	var sr := 22050
	var n := sr * 4
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var s := sin(TAU * hz * i / sr) * amp + sin(TAU * (hz * 0.5) * i / sr) * amp * 0.4
		s += sin(TAU * 0.2 * i / sr) * 0.05
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.data = data
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = n
	return st

func _click_stream(hz: float, dur: float) -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var env := 1.0 - float(i) / float(n)
		var s := sin(TAU * hz * i / sr) * env * env
		var v := int(clampf(s, -1.0, 1.0) * 20000.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.data = data
	return st

func _tape_stream() -> AudioStreamWAV:
	var sr := 22050
	var n := sr * 7
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / sr
		var hiss := (randf() - 0.5) * 0.1
		var breath := 0.0
		if t > 0.8:
			breath = sin(TAU * 1.7 * t) * 0.16 * maxf(0.0, sin(TAU * 0.22 * t))
		var voice := 0.0
		if t > 2.8 and t < 6.0:
			voice = sin(TAU * 98.0 * t) * 0.05 * sin(TAU * 2.4 * t)
		var s := hiss + breath + voice
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.data = data
	return st
