extends Control
## Main — the screens, the input, the wiring. The rules are in Kernel, the offline gate in
## Idle, the cabinet in TableView. Screens are built in code so they live in git as text
## and share one Theme (StudioTheme), which is what the sibling titles do
## (play/beat-monday-godot/scripts/main.gd, play/overtime-idle-godot/scripts/building.gd).
##
## Flow: title -> the return screen if the gate collected while away -> the table.
## The night ends -> the casual board is offered once -> NEW NIGHT. Prestige past night 3
## goes through Gate (ops/DUAL_TRACK.md).

const W := 420.0
const H := 640.0
const CJK := "res://assets/fonts/NotoSansCJK-subset.otf"

var table: Node2D
var hud: Control
var overlay: Control
var title: Control
var screen := "title"
var _run_started_ms := 0
var _first_hit := false
var _first_buy := false
var _kept_fonts: Array = []
var _save_accum := 0.0
## Barks. `ops/bark_wire.py` put the player in Sfx and the lines are rendered under
## assets/voice, and until now NOTHING in this game called Sfx.bark() -- twenty-three
## recorded lines that could not be reached from the running game. These three fields are
## the state the nine slots need: how long since the player last touched anything (idle),
## whether the last-hose line has already been said this night (near), and the combo the
## streak line last fired on, so a combo that sits at 3 does not say it every rebound.
var _quiet := 0.0
var _said_near := false
var _streak_at := 0
var _claim: Callable = Callable()
## The LEDGER stub that lives on the table itself — see _build_table_ledger().
var _ledger_stub: Button = null


func _ready() -> void:
	theme = StudioTheme.build()
	_install_cjk()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Sfx.muted = not Game.sound

	table = Node2D.new()
	table.set_script(load("res://scripts/table_view.gd"))
	table.visible = false
	add_child(table)
	table.connect("events", _on_events)

	hud = Control.new()
	hud.set_script(load("res://scripts/hud.gd"))
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	# The table's pieces carry z_index 8..20 so they stack correctly *on the bed*. Those
	# indices are canvas-wide, not local, so without these two lines the bumpers and the
	# ball draw straight through the HUD and over every panel — which is exactly what the
	# first full screenshot sheet showed: a ball sitting on top of the NEW NIGHT button.
	hud.z_index = 100
	add_child(hud)

	_build_table_ledger()

	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 200
	add_child(overlay)

	Game.bridge_handler = _bridge
	Game.tel("visit", {"lang": Game.lang})
	show_title()


## An idle tycoon whose ledger cannot be opened while the night is running.
##
## 2026-09-21: scripts/hud.gd is MOUSE_FILTER_IGNORE and draws no controls, and no other
## node was parented over the table, so between TAKE THE GATE and SHIFT OVER this game had
## NO buttons on screen at all. The coins that the whole loop exists to earn piled up for
## three hoses with nowhere to spend them, and the only ways back to the ledger were to
## finish the night or to have gone there from the title before starting. That is the one
## screen an idle game must never put behind a wait.
##
## So the table gets its own stub, bottom centre, over the apron under the flippers. It is
## the same torn ticket as every other button here. Three notes on the position:
##
##   * bottom centre is the portrait thumb rest, and it is also the one column
##     ops/play_driver.py can reach on a 420x640 cabinet letterboxed into 1280x720 — the
##     ledger was unreachable to the matrix for exactly the reason it was unreachable to a
##     player.
##   * it eats a 132x40 patch of the plunger's touch zone (everything below H*0.78). That
##     is deliberate and cheap: the apron under the flippers is not where a thumb pumps,
##     and Space and the rest of the band still plunge.
##   * it pauses nothing by itself — show_ledger() does that, and closing from
##     "ledger_from_table" un-pauses, which is the path that already existed.
func _build_table_ledger() -> void:
	_ledger_stub = StudioTheme.ticket(t("shop"), "Ghost", 132.0, 40.0)
	_ledger_stub.add_theme_font_size_override("font_size", 13)
	_ledger_stub.position = Vector2((W - 132.0) / 2.0, H - 46.0)
	_ledger_stub.z_index = 110
	_ledger_stub.visible = false
	_ledger_stub.pressed.connect(Sfx.tap)
	_ledger_stub.pressed.connect(func() -> void:
		if screen != "table":
			return
		table.paused = true
		show_ledger()
		screen = "ledger_from_table")
	add_child(_ledger_stub)


## The three Latin faces carry no CJK; the zh-Hans strings fall through to a Noto subset.
## The Theme is built first (its static cache keeps the instances) and the fonts are kept
## here too, because ResourceCache holds resources weakly and a dropped FontFile is re-read
## with no fallbacks on the web export. Same note as beat-monday's _install_cjk.
func _install_cjk() -> void:
	var fb: Font = load(CJK) if ResourceLoader.exists(CJK) else null
	if fb == null:
		return
	_kept_fonts.append(fb)
	for path in [StudioTheme.FONT_DISPLAY, StudioTheme.FONT_UI, StudioTheme.FONT_ITALIC]:
		var f: Font = load(path)
		_kept_fonts.append(f)
		if f is FontFile and (f as FontFile).fallbacks.is_empty():
			(f as FontFile).fallbacks = [fb]


func t(k: String, v: Dictionary = {}) -> String:
	return RTStrings.t(k, v)


# ---------- overlay helpers -----------------------------------------------------------------
func _clear_overlay() -> void:
	for c in overlay.get_children():
		c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _dim(alpha := 0.72) -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(Palette.GROUND_DEEP, alpha)
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(d)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	return d


func _label(text: String, variation := "", size := 0, color := Color(0, 0, 0, 0), wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	if color.a > 0:
		l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 300
	return l


## Every screen's ACTION button is a torn ticket stub (StudioTheme.ticket, STANDARD #4).
## The ledger's rows stay plain: the shape is the game's object, and a shelf of forty
## identical stubs stops being an object and becomes wallpaper.
func _button(text: String, variation: String, fn: Callable, min_w := 220.0) -> Button:
	var b := StudioTheme.ticket(text, variation, min_w, 48.0)
	b.pressed.connect(Sfx.tap)
	b.pressed.connect(fn)
	return b


func _panel(pos_y: float, width := 360.0, variation := "Glass") -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.theme_type_variation = variation
	pc.position = Vector2((W - width) / 2.0, pos_y)
	pc.custom_minimum_size.x = width
	pc.size.x = width
	overlay.add_child(pc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	return v


func _show(name: String) -> void:
	screen = name
	# The stub belongs to the table and to nothing else: it must not sit on top of the
	# title's menu, and it must not be pressable from behind an overlay.
	if _ledger_stub != null and is_instance_valid(_ledger_stub):
		_ledger_stub.visible = name == "table"
	Game.tel("screen", {"screen": name})


# ---------- title -----------------------------------------------------------------------
func show_title() -> void:
	_clear_overlay()
	table.visible = false
	table.paused = true
	hud.visible = false
	if _ledger_stub != null and is_instance_valid(_ledger_stub):
		_ledger_stub.visible = false
	# Rebuilt every time rather than re-shown: its labels are baked at build time, so a
	# language change that only re-showed it left an English menu on a Chinese game.
	if title != null and is_instance_valid(title):
		title.queue_free()
	title = Control.new()
	title.set_script(load("res://scripts/title_screen.gd"))
	add_child(title)
	move_child(title, 0)
	title.connect("start_pressed", _enter_game)
	title.connect("ledger_pressed", show_ledger)
	title.connect("lang_pressed", func():
		Game.set_lang(RTStrings.next_lang(Game.lang))
		show_title())
	title.connect("sound_pressed", _toggle_sound)
	title.connect("motion_pressed", _cycle_motion)
	_apply_motion()
	_show("title")


## Reduced motion is re-read every frame rather than cached, so "Auto" tracks the system
## switch live — flip it in the OS and the next frame is already calm. This is the one
## place that hands it to the three scripts that gate on it (table_view, title_screen and
## the logotype the title owns); set() rather than a typed property because these screens
## are plain Controls with a script attached.
func _apply_motion() -> void:
	var r := Game.reduce_motion()
	table.set("reduce_motion", r)
	if title != null and is_instance_valid(title):
		title.set("reduce_motion", r)
		var logo = title.get("_logo")
		if logo != null and is_instance_valid(logo):
			logo.set("reduce_motion", r)


func _cycle_motion() -> void:
	Game.cycle_motion()
	show_title()


func _toggle_sound() -> void:
	Game.sound = not Game.sound
	Sfx.muted = not Game.sound
	Game.save()
	show_title()


## From the title into the cabinet — through the return screen first, when the gate
## collected something while the player was away.
func _enter_game() -> void:
	if not Game.pending_return.is_empty():
		show_return(Game.pending_return)
		return
	start_table()


func start_table() -> void:
	if title and is_instance_valid(title):
		title.visible = false
	_clear_overlay()
	table.state = Game.st
	table.visible = true
	hud.visible = true
	# A save can carry a finished night — the run ends, the player leaves, the gate
	# collects, and they come back through the return screen. Dropping them straight onto
	# the table then left them looking at a dead one: no ball, no hose, and Kernel.step
	# returning early forever because the mode is "nightover". The screenshot run caught
	# it (the night could never end a second time); the fix is to show them where they
	# actually are.
	if str(Game.st["mode"]) == "nightover":
		show_nightover()
		return
	table.visible = true
	table.paused = false
	hud.visible = true
	Game.started = true
	_run_started_ms = Time.get_ticks_msec()
	Game.tel_play_start({"night": int(Game.st["night"]), "era": Kernel.era_id(Game.st), "lang": Game.lang})
	Game.tel("start", {"lang": Game.lang, "era": Kernel.era_id(Game.st)})
	Game.save()
	_show("table")
	_bark_night_reset()
	Sfx.bark("greet")


# ---------- the return screen (the offline gate) ------------------------------------------
func show_return(settled: Dictionary) -> void:
	_clear_overlay()
	_dim(0.8)
	var coins := int(settled["coins"])
	var v := _panel(150.0, 340.0, "Card")
	v.add_child(_label(t("return_title"), "Title", 22, Palette.GOLD))
	v.add_child(_label(t("return_body", {
		"t": RTStrings.away(float(settled["awaySeconds"])), "c": Kernel.format_coins(coins)}),
		"", 14, Palette.TEXT, true))
	if bool(settled["capped"]):
		v.add_child(_label(t("return_capped", {"t": RTStrings.away(float(settled["awaySeconds"]))}),
			"Tag", 11, Palette.MUTED, true))
	v.add_child(_label("+ " + Kernel.format_coins(coins), "Big", 40, Palette.GOLD))
	v.add_child(_label(t("return_rate", {"r": "%.1f" % float(settled["rate"])}), "Tag", 11, Palette.MUTED))
	_claim = func():
		Idle.claim(Game.st, coins)
		Game.pending_return = {}
		Game.tel("offline_claim", {"coins": coins, "s": int(settled["seconds"])})
		Sfx.buy()
		Game.save()
		start_table()
	v.add_child(_button(t("return_claim"), "Primary", _claim))
	Game.tel("offline_return", {"coins": coins, "s": int(settled["seconds"]), "capped": settled["capped"]})
	_show("return")


# ---------- the ledger: upgrades + perks ---------------------------------------------------
func show_ledger() -> void:
	_clear_overlay()
	_dim(0.86)
	var head := _label(t("shop"), "Title", 24, Palette.GOLD)
	head.position = Vector2(0, 18)
	head.size.x = W
	overlay.add_child(head)
	var sub := _label(t("shop_hint"), "Tag", 11, Palette.MUTED)
	sub.position = Vector2(0, 50)
	sub.size.x = W
	overlay.add_child(sub)

	var sc := ScrollContainer.new()
	sc.position = Vector2(20, 72)
	sc.size = Vector2(W - 40, H - 140)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(sc)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = W - 52
	col.add_theme_constant_override("separation", 6)
	sc.add_child(col)

	var last_group := ""
	for u in Kernel.UPGRADES:
		if str(u["group"]) != last_group:
			last_group = str(u["group"])
			var gl := _label(RTStrings.tm("groups", last_group), "Tag", 11, Palette.ACCENT_SOFT)
			gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			col.add_child(gl)
		col.add_child(_shop_row(str(u["id"]), false))
	var pl := _label(t("prestige") + " · " + str(int(Game.st["tokens"])) + " " + t("tokens"),
		"Tag", 11, Palette.GOLD)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(pl)
	for p in Kernel.PERKS:
		col.add_child(_shop_row(str(p["id"]), true))
	col.add_child(_prestige_row())

	var back := _button(t("close"), "Ghost", func():
		if screen == "ledger_from_table":
			_clear_overlay()
			table.paused = false
			_show("table")
		else:
			show_title(), 160.0)
	back.position = Vector2((W - 160) / 2.0, H - 58)
	overlay.add_child(back)
	_show("ledger" if not table.visible else "ledger_from_table")


func _shop_row(id: String, is_perk: bool) -> Button:
	var lv := Kernel.perk_of(Game.st, id) if is_perk else Kernel.level_of(Game.st, id)
	var cost := Kernel.perk_cost(id, lv) if is_perk else Kernel.upgrade_cost(id, lv)
	var can := Kernel.can_buy_perk(Game.st, id) if is_perk else Kernel.can_buy(Game.st, id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 54)
	b.disabled = not can
	b.theme_type_variation = "Amber" if is_perk else ""
	b.text = "%s · %d        %s" % [
		RTStrings.tm("perks" if is_perk else "upgrades", id), lv + 1,
		(str(cost) if is_perk else Kernel.format_coins(cost))]
	b.tooltip_text = RTStrings.tm("perk_hints" if is_perk else "hints", id)
	b.pressed.connect(func(): _buy(id, is_perk))
	return b


func _buy(id: String, is_perk: bool) -> void:
	var res := Kernel.buy_perk(Game.st, id) if is_perk else Kernel.buy(Game.st, id)
	if not bool(res["ok"]):
		Sfx.drain()
		return
	var prev_era := Kernel.era_id(Game.st)
	var was_new := (Kernel.perk_of(Game.st, id) if is_perk else Kernel.level_of(Game.st, id)) == 0
	Game.st = res["state"]
	table.state = Game.st
	Sfx.buy()
	if not _first_buy:
		_first_buy = true
		Game.tel("first_buy", {"id": id})
	if Kernel.era_id(Game.st) != prev_era:
		Game.tel("era_up", {"era": Kernel.era_id(Game.st)})
		# "stage" is the four era lines, in order, and Kernel.ERAS is in that order too, so
		# the right one is said rather than a random one of the four.
		Sfx.bark_at("stage", Kernel.era_index(Game.st))
	elif was_new:
		Sfx.bark("unlock")
	Game.save()
	var was := screen
	show_ledger()
	screen = was


func _prestige_row() -> Control:
	var v := VBoxContainer.new()
	var ok := Kernel.can_prestige(Game.st)
	var tokens := Kernel.prestige_tokens_for(Game.st)
	v.add_child(_label(t("prestige_hint") if ok else t("prestige_locked"), "Tag", 11,
		Palette.GOLD_PALE if ok else Palette.MUTED, true))
	var b := _button(t("prestige_go") + (" +" + str(tokens) if ok else ""), "Primary", _do_prestige)
	b.disabled = not ok
	v.add_child(b)
	return v


func _do_prestige() -> void:
	var night := int(Game.st["night"]) + 1
	if night > Game.FREE_NIGHTS:
		var key := "night%d" % night
		if not await Gate.require(key, "%s %d" % [t("night"), night], "level"):
			return
	var res := Kernel.do_prestige(Game.st)
	if not bool(res["ok"]):
		return
	Game.st = res["state"]
	table.state = Game.st
	Sfx.prestige()
	Game.tel("prestige", {"tokens": res["tokens"], "night": int(Game.st["night"])})
	Game.save()
	show_ledger()


# ---------- the booth: pause, and the way out --------------------------------------------
## Until now a night could only be left by finishing it.
##
## 2026-09-21: between TAKE THE GATE and SHIFT OVER there was no pause, no way back to the
## title, and nothing bound to Escape or to a gamepad's B. On a portal that is a hard
## requirement (CrazyGames expects a way back to the menu) and on a phone it is what the
## back gesture is for; here it also means the table keeps running while the player is
## reading something else, which is how the night's state got lost.
##
## Escape opens it, Escape closes it, and it pauses the bed while it is up.
func show_booth() -> void:
	if screen != "table":
		return
	_clear_overlay()
	_dim(0.72)
	table.paused = true
	var v := _panel(200.0, 320.0, "Card")
	v.add_child(_label(t("settings"), "Title", 22, Palette.ACCENT))
	v.add_child(_label(t("booth_hint"), "", 13, Palette.MUTED, true))
	v.add_child(_button(t("resume"), "Primary", func():
		_clear_overlay()
		table.paused = false
		_show("table")))
	v.add_child(_button(t("shop"), "Amber", func():
		show_ledger()
		screen = "ledger_from_table"))
	v.add_child(_button(t("sound") + ": " + (t("on") if not Sfx.muted else t("off")),
		"Amber", func():
			Sfx.muted = not Sfx.muted
			Game.sound = not Sfx.muted
			Game.save()
			show_booth()))
	# Leaving does NOT throw the night away: Game.save() has been writing the run every
	# four seconds, and start_table() picks a live night back up from the title.
	v.add_child(_button(t("quit"), "Ghost", func():
		Game.save()
		show_title(), 160.0))
	_show("booth")


# ---------- the night ends ------------------------------------------------------------------
func show_nightover() -> void:
	_clear_overlay()
	_dim(0.78)
	table.paused = true
	var v := _panel(170.0, 340.0, "Card")
	v.add_child(_label(t("nightover"), "Title", 24, Palette.HEAT))
	v.add_child(_label(RTStrings.tm("lines", "nightover"), "", 14, Palette.TEXT, true))
	v.add_child(_label(Kernel.format_coins(int(Game.st["score"])), "Big", 40, Palette.GOLD))
	v.add_child(_label(t("rent"), "Tag", 11, Palette.MUTED))
	v.add_child(_button(t("again"), "Primary", new_night))
	v.add_child(_button(t("shop"), "Amber", func():
		show_ledger()
		screen = "ledger_from_table"))
	v.add_child(_button(t("back"), "Ghost", show_title, 140.0))
	Sfx.nightover()
	# A record is the only thing worth the big line. Kernel carries no best -- it is
	# conformance-locked -- so Game keeps it (game.gd `best_night`), and it is read BEFORE
	# it is updated, or every night is a record.
	var rent := int(Game.st["score"])
	if rent > Game.best_night and Game.best_night > 0:
		Sfx.bark("win_big")
	else:
		Sfx.bark("win")
	Game.best_night = maxi(Game.best_night, rent)
	Game.tel_play_end({"night": int(Game.st["night"]), "era": Kernel.era_id(Game.st)},
		int((Time.get_ticks_msec() - _run_started_ms) / 1000))
	# The night is over: that is where this catalogue offers the rest of itself. Offered,
	# never forced — "casual" explicitly, this is a mainstream title.
	Game.offer_board()
	_show("nightover")


## A new night, from the SHIFT OVER button, from Space (the JS build's key), or from the
## bridge. One path, so the three cannot drift apart.
func new_night() -> void:
	Game.st = Kernel.new_night(Game.st)
	table.state = Game.st
	Game.save()
	_clear_overlay()
	table.visible = true
	hud.visible = true
	table.paused = false
	Sfx.tap()
	_show("table")
	_bark_night_reset()


# ---------- events from the table -------------------------------------------------------
func _on_events(list: Array) -> void:
	for ev in list:
		var kind := str(ev["type"])
		match kind:
			"bumper", "sling", "target", "saucer", "gate":
				Sfx.coin(int(Game.st["combo"]))
				if kind == "bumper":
					Sfx.bumper()
					table.kick(0.5)
				if kind == "target" or kind == "gate":
					Sfx.intercom()
				if kind == "gate":
					table.kick(1.0)
				var ball = Game.st.get("ball")
				if ball != null:
					var at: Vector2 = table.to_px(float(ball["x"]), float(ball["y"]))
					table.spark(at, Palette.GOLD_PALE, 9)
					table.float_text(at + Vector2(0, -14), "+" + str(int(ev.get("pts", 0))))
				hud.say(RTStrings.tm("hits", str(ev.get("id", kind))))
				table.guard_mood("cheer", 1.0)
				var combo := int(Game.st["combo"])
				if combo >= 3 and combo != _streak_at:
					_streak_at = combo
					Sfx.bark("streak")
				if kind == "gate":
					Sfx.bark("win")
				if not _first_hit:
					_first_hit = true
					Game.tel("first_rebound", {"kind": kind})
			"launch":
				Sfx.launch(float(ev.get("charge", 1.0)))
				hud.say(RTStrings.tm("lines", "launch"))
			"cannon":
				Sfx.cannon()
				table.kick(0.8)
				hud.say(RTStrings.tm("hits", "cannon"))
			"drain":
				Sfx.drain()
				table.guard_mood("oops", 1.6)
				hud.say(RTStrings.tm("lines", "drain"))
				_streak_at = 0
				Sfx.bark("fail")
				Game.save()
			"save":
				Sfx.save_ball()
				table.guard_mood("cheer", 1.4)
				hud.say(RTStrings.tm("lines", "save"))
			"reload":
				hud.say(t("launch_hint"))
				# "near" is the tease slot: one move from the win. In this game that is the
				# last hose of the night being racked -- everything after it is the board.
				if int(Game.st["balls"]) <= 1 and not _said_near:
					_said_near = true
					Sfx.bark("near")
			"nightover":
				show_nightover()


func _process(dt: float) -> void:
	hud.state = Game.st
	_apply_motion()
	_probe_step()
	if screen == "table":
		_quiet += dt
		# The hose racks ITSELF if nobody pumps it.
		#
		# This is an idle tycoon, and it was not idle: with the ball in the lane and the
		# mode at "plunge", Kernel.step does nothing at all until an input arrives, so a
		# player who put the phone down came back to a night that had not moved a frame.
		# ops/play_matrix.py caught the same thing from the other side -- the driver reached
		# the table and then twelve frames of the same picture, two "stages" of twelve,
		# because between its taps the table simply stopped. Three hoses were never spent,
		# so the night never ended, so the board and the ledger were unreachable.
		#
		# Fired through table.input, the same dictionary a thumb writes to -- NOT through
		# Kernel. The rules are an exact port of the JS build and tests/run_tests.gd
		# compares 56,409 doubles against it with `==`; an auto-launch that reached into
		# the state would have to be ported back into kernel.js or the suite goes red. So
		# the auto-rack is worth exactly what a tap is worth (Kernel.launch_ball floors a
		# fired charge at 0.78) and a held pump is still the only way to a full 1.0.
		#
		# The countdown runs on its OWN clock, not on `_quiet`. 2026-09-21: it used
		# `_quiet`, and `_quiet` is reset by _unhandled_input on EVERY event, including the
		# ones this game ignores. So a player idly tapping, or pressing an unused key, held
		# the hose racked indefinitely -- each tap put the 3.2 s countdown back to zero and
		# the hose the countdown exists to fire never fired. ops/play_driver.py sat on the
		# last hose of a night for six interactions that way and the night never ended.
		# Two timers, because they answer two questions: `_quiet` is "has the player gone
		# away" (the idle bark), `_rack` is "has this hose been sitting in the lane".
		if str(Game.st.get("mode", "")) == "plunge" and not table.paused \
				and not bool(table.input.get("plunge", false)):
			_rack += dt
		else:
			_rack = 0.0
		if _rack > 3.2:
			_rack = 0.0
			table.input["plunge"] = false
			table.input["fire"] = true
			hud.say(t("launch_hint"))
		_rescue_step(dt)
		# The idle line: a tycoon that sits silent while the player looks away has no voice
		# at all. 22 s, and only on the table -- never over a panel the player is reading.
		if _quiet > 22.0:
			_quiet = 0.0
			Sfx.bark("idle")
	_save_accum += dt
	if _save_accum > 4.0:
		_save_accum = 0.0
		if screen == "table":
			Game.save()


## ---------- the ball goes to sleep, and the night never ends -----------------------------
##
## 2026-09-21. The play matrix reported 2 stages of 28 frames and it was read, twice, as a
## driver that could not find the buttons. It was not. The bridge (`op: "state"`, now
## carrying the ball) showed the ball parked at (0.238639336875166, 0.86038169921771) with
## a speed of 0.0036, IDENTICAL to fifteen significant figures across forty seconds of
## wall clock, mode still "live", three hoses still in hand.
##
## That spot is a corner the table builds out of two separate constraints: the left inlane
## wall ends at (0.230, 0.875) and the left flipper pivots at (0.255, 0.865), 0.027 apart
## with a ball 0.034 across. Each solver pass pushes the ball to exactly BALL_R off its own
## segment, the two pushes cancel, and the ball sits there for the rest of time. Gravity
## never wins because it is answered every substep. There is no drain under it -- the drain
## mouth is 0.40..0.60 -- so `balls` never decrements, so the night never ends, so SHIFT
## OVER, the ledger and every screen behind them are unreachable for the rest of the
## session. A real player loses the night to it, not only the driver.
##
## The rules cannot be where this is fixed: scripts/kernel.gd is a bit-exact port of
## kernel.js and tests/run_tests.gd compares 56,409 doubles against it with `==`, so a
## change to `Kernel.step` turns the suite red and has to be ported back into the JS. So
## the rescue lives here, above the rules, and does what the cabinet does:
##
##   1.4 s asleep -> **nudge the table**. Both flippers, hard, for a few frames. It is the
##        in-world verb (a night guard kicks the machine), it is free, and it frees most
##        wedges because raising the flipper moves the very constraint the ball is resting
##        against.
##   three nudges and still asleep -> concede the hose. `Kernel.drain_ball` is a static on
##        the state and is NOT part of `Kernel.step`, so calling it here costs the
##        conformance suite nothing, and it routes through `_on_events` so the HUD line,
##        the sound, the bark and SHIFT OVER all behave exactly as a real drain.
##
## The threshold is on SPEED, not on position, so it covers the corners nobody has found
## yet as well as this one. 1.4 s is longer than any legitimate slow roll on this table --
## gravity is 1.35 and the bed is one screen tall, so a ball genuinely in play is never
## under 0.05 for a second and a half.
## Two ways a ball stops being in play, and only one of them is standing still.
##
## ASLEEP is the wedge above: speed under 0.05, which on this table means held. PENNED is
## the other half, found in the same trace — the ball mooching around the left pocket at a
## real speed of 0.08 to 0.3 and never leaving a patch 0.05 across, for forty seconds. The
## speed test cannot see that one, and a player watching it cannot tell it from the wedge:
## the hose count does not move and the night does not end. So the rescue also watches
## DISPLACEMENT — where the ball is now against where it was three seconds ago.
const ASLEEP_SPEED := 0.05
const ASLEEP_S := 1.4
const PENNED_RADIUS := 0.05
const PENNED_S := 3.0
const NUDGE_LIMIT := 3

var _asleep := 0.0
var _penned := 0.0
var _penned_at := Vector2.ZERO
var _nudges := 0
var _nudge_left := 0.0
## How long the current hose has sat in the lane untouched — see the auto-rack.
var _rack := 0.0


func _rescue_step(dt: float) -> void:
	# The nudge holds the flippers up for a few frames and then lets them go, the same way
	# a held key would -- the flippers must come back down or the next ball rests on them.
	if _nudge_left > 0.0:
		_nudge_left -= dt
		if _nudge_left <= 0.0:
			table.input["left"] = false
			table.input["right"] = false
	if table.paused or str(Game.st.get("mode", "")) != "live":
		_rescue_reset()
		return
	var b = Game.st.get("ball")
	if b == null:
		_rescue_reset()
		return
	var at := Vector2(float(b["x"]), float(b["y"]))
	var sp := sqrt(float(b["vx"]) * float(b["vx"]) + float(b["vy"]) * float(b["vy"]))

	# penned: hasn't got anywhere, however fast it looks
	if at.distance_to(_penned_at) > PENNED_RADIUS:
		_penned = 0.0
		_penned_at = at
	else:
		_penned += dt

	# asleep: isn't moving at all
	if sp >= ASLEEP_SPEED:
		_asleep = 0.0
	else:
		_asleep += dt

	if _asleep < ASLEEP_S and _penned < PENNED_S:
		return
	_asleep = 0.0
	_penned = 0.0
	_penned_at = at
	if _nudges < NUDGE_LIMIT:
		_nudges += 1
		_nudge()
		return
	# Three kicks and it is still in the same corner. Take the hose rather than the night.
	_nudges = 0
	var ev := Kernel.drain_ball(Game.st)
	table.state = Game.st
	_on_events([{"type": ev}])


func _rescue_reset() -> void:
	_asleep = 0.0
	_penned = 0.0
	_penned_at = Vector2.ZERO
	_nudges = 0


func _nudge() -> void:
	table.input["left"] = true
	table.input["right"] = true
	_nudge_left = 0.14
	table.kick(0.7)
	Sfx.flip()
	hud.say(RTStrings.tm("lines", "nudge"))
	table.guard_mood("oops", 0.9)


# ---------- input ------------------------------------------------------------------------
## The JS build's keys, plus the thumb zones: the lower quarter is the plunger, the left
## and right halves above it are the flippers.
## Each night starts the bark state over: the last-hose line is said once a night, and the
## streak line must not carry a combo across the board.
func _bark_night_reset() -> void:
	_quiet = 0.0
	_said_near = false
	_streak_at = 0


## Escape / Back closes whatever panel is open, from anywhere.
##
## 2026-09-21: nothing in this game was bound to `ui_cancel`. On the ledger the only exit
## was one 160 px CLOSE stub, so a keyboard player, a gamepad B button and Android's back
## gesture all did nothing at all — and ops/play_matrix.py found the same wall from the
## other side: it opened the ledger on its fifteenth interaction and spent every
## interaction after that inside it, because the tree of screens behind that panel had no
## way out. A menu-driven game whose panels cannot be left is a game with one screen.
##
## The table is the place to land: closing from a panel opened mid-night un-pauses and
## goes back to the bed, and closing from a panel opened off the title goes to the title.
## SHIFT OVER is deliberately NOT closable — there is nothing behind it but a dead table,
## which is the exact bug start_table()'s "mode == nightover" branch exists to prevent.
func _close_panel() -> bool:
	match screen:
		"table":
			show_booth()
			return true
		"booth":
			_clear_overlay()
			table.paused = false
			_show("table")
			return true
		"ledger_from_table":
			_clear_overlay()
			table.paused = false
			_show("table")
			return true
		"ledger", "return":
			show_title()
			return true
	return false


func _unhandled_input(e: InputEvent) -> void:
	_quiet = 0.0
	if e.is_action_pressed("ui_cancel"):
		if _close_panel():
			get_viewport().set_input_as_handled()
		return
	# Space starts the next night from SHIFT OVER, the way the JS build did.
	if screen == "nightover" and e is InputEventKey and (e as InputEventKey).pressed \
			and not (e as InputEventKey).echo and _map_key(e as InputEventKey) == "plunge":
		get_viewport().set_input_as_handled()
		new_night()
		return
	if screen != "table":
		return
	if e is InputEventKey:
		var k := _map_key(e as InputEventKey)
		if k == "":
			return
		get_viewport().set_input_as_handled()
		if (e as InputEventKey).echo:
			if k == "plunge":
				table.input["plunge"] = true
			return
		if (e as InputEventKey).pressed:
			table.input[k] = true
			if k == "left" or k == "right":
				Sfx.flip()
		else:
			table.input[k] = false
			if k == "plunge":
				table.input["fire"] = true
	elif e is InputEventScreenTouch or e is InputEventMouseButton:
		var pressed: bool = e.pressed if e is InputEventMouseButton else (e as InputEventScreenTouch).pressed
		var pos: Vector2 = e.position
		if pressed:
			if pos.y > H * 0.78:
				table.input["plunge"] = true
			elif pos.x < W * 0.5:
				table.input["left"] = true
				Sfx.flip()
			else:
				table.input["right"] = true
				Sfx.flip()
		else:
			if table.input["plunge"]:
				table.input["fire"] = true
			table.input["left"] = false
			table.input["right"] = false
			table.input["plunge"] = false


## The observable side of the four reduced-motion branches, so a test can assert that each
## one *ran* rather than that the flag was set — which is the whole reason this feature was
## dead for as long as it was. Each entry is something the full-motion path writes and the
## reduced path does not, accumulated across frames rather than sampled, because every one
## of them passes through its resting value once a cycle:
##   titleDrift    title_screen._process  — the parallax layers offset from their base
##   logoFlickers  logotype._process      — the neon tube stuttering
##   tableDrift    table_view._breathe    — the sky sliding against the table
##   sparks        table_view.spark       — the particles a rebound throws
var _probe := {"titleDrift": 0.0, "logoFlickers": 0, "skyMin": INF, "skyMax": -INF, "sparks": 0}


func _probe_reset() -> void:
	_probe = {"titleDrift": 0.0, "logoFlickers": 0, "skyMin": INF, "skyMax": -INF, "sparks": 0}


func _probe_step() -> void:
	if title != null and is_instance_valid(title):
		var layers = title.get("_layers")
		if layers is Array:
			for l in layers:
				var n = l["node"]
				if n != null and is_instance_valid(n):
					_probe["titleDrift"] = maxf(_probe["titleDrift"],
						(Vector2(n.position) - Vector2(l["base"])).length())
		var logo = title.get("_logo")
		if logo != null and is_instance_valid(logo):
			_probe["logoFlickers"] = maxi(_probe["logoFlickers"], int(logo.get("flickers")))
	var sky = table.get("_sky")
	if sky != null and is_instance_valid(sky):
		_probe["skyMin"] = minf(_probe["skyMin"], float(sky.position.x))
		_probe["skyMax"] = maxf(_probe["skyMax"], float(sky.position.x))
	var sparks = table.get("_sparks")
	if sparks is Array:
		_probe["sparks"] = maxi(_probe["sparks"], sparks.size())


## null when there is no ball on the bed, otherwise where it is and how fast.
func _ball_probe() -> Variant:
	var b = Game.st.get("ball")
	if b == null:
		return null
	return {"x": float(b["x"]), "y": float(b["y"]), "vx": float(b["vx"]), "vy": float(b["vy"]),
		"speed": sqrt(float(b["vx"]) * float(b["vx"]) + float(b["vy"]) * float(b["vy"]))}


func _motion_probe() -> Dictionary:
	var span := 0.0
	if _probe["skyMax"] > -INF and _probe["skyMin"] < INF:
		span = float(_probe["skyMax"]) - float(_probe["skyMin"])
	return {
		"titleDrift": float(_probe["titleDrift"]), "logoFlickers": int(_probe["logoFlickers"]),
		"tableDrift": span, "sparks": int(_probe["sparks"]),
	}


func _map_key(e: InputEventKey) -> String:
	match e.keycode:
		KEY_LEFT, KEY_Z, KEY_A: return "left"
		KEY_RIGHT, KEY_SLASH, KEY_X, KEY_L: return "right"
		KEY_SPACE, KEY_DOWN, KEY_ENTER, KEY_SHIFT: return "plunge"
	return ""


# ---------- web dev bridge (tests/headless_web.py) -----------------------------------------
## Every command is something a thumb can also do, plus "clock", which moves the save's
## idea of when the player left so the offline gate can be seen inside a screenshot run,
## and "sim", which steps the kernel faster than real time.
func _bridge(cmd: Dictionary) -> Dictionary:
	var op := str(cmd.get("op", ""))
	match op:
		"state":
			return {
				"screen": screen, "night": int(Game.st["night"]), "coins": int(Game.st["coins"]),
				"score": int(Game.st["score"]), "balls": int(Game.st["balls"]),
				"era": Kernel.era_id(Game.st), "mode": str(Game.st["mode"]),
				"tokens": int(Game.st["tokens"]), "combo": int(Game.st["combo"]),
				"lang": Game.lang, "pending": not Game.pending_return.is_empty(),
				"motionPref": Game.motion_pref, "reduceMotion": Game.reduce_motion(),
				"platformReduceMotion": Game.platform_reduce_motion(),
				# What the gated code is actually doing, not what the flag says it should
				# be doing: a branch that is never taken is the bug this op exists to catch.
				"motionProbe": _motion_probe(),
				# What the BALL is doing, not only what the scoreboard says. A night that
				# stops dead reads identically to a night nobody is playing: same screen,
				# same mode, same hose count, a score that simply stops moving. Without the
				# ball's position and speed there is no way to tell "asleep in a pocket"
				# from "the driver never pressed anything", and a whole play-matrix run was
				# spent on that question (ops/play_matrix.py: 2 stages of 28 frames).
				"ball": _ball_probe(),
				"flipL": float(Game.st.get("flipL", 0.0)),
				"flipR": float(Game.st.get("flipR", 0.0)),
				"input": {"left": bool(table.input.get("left", false)),
					"right": bool(table.input.get("right", false)),
					"plunge": bool(table.input.get("plunge", false))},
				"paused": bool(table.paused),
			}
		"motion":
			# Set it outright when asked, otherwise cycle — the button cycles, the test sets.
			if cmd.has("pref"):
				var pref := str(cmd["pref"])
				if pref in Game.MOTION_PREFS:
					Game.motion_pref = pref
					Game.save()
					_apply_motion()
					if screen == "title":
						show_title()
				else:
					return {"ok": false, "why": "bad_pref"}
			elif not bool(cmd.get("reset", false)):
				_cycle_motion()
			if bool(cmd.get("reset", false)):
				_probe_reset()
			return {"ok": true, "pref": Game.motion_pref, "reduceMotion": Game.reduce_motion()}
		"start":
			_enter_game()
			return {"ok": true}
		"title":
			show_title()
			return {"ok": true}
		"again":
			if screen != "nightover":
				return {"ok": false, "why": "not_nightover"}
			new_night()
			return {"ok": true, "night": int(Game.st["night"])}
		"ledger":
			show_ledger()
			if table.visible:
				screen = "ledger_from_table"
			return {"ok": true}
		"buy":
			_buy(str(cmd.get("id", "springs")), bool(cmd.get("perk", false)))
			return {"ok": true, "level": Kernel.level_of(Game.st, str(cmd.get("id", "springs")))}
		"grant":
			Game.st["coins"] = int(Game.st["coins"]) + int(cmd.get("coins", 0))
			return {"ok": true, "coins": int(Game.st["coins"])}
		"hold":
			table.input[str(cmd.get("key", "plunge"))] = bool(cmd.get("down", true))
			if str(cmd.get("key", "")) == "plunge" and not bool(cmd.get("down", true)):
				table.input["fire"] = true
			return {"ok": true}
		"claim":
			if _claim.is_valid():
				_claim.call()
				return {"ok": true, "coins": int(Game.st["coins"])}
			return {"ok": false, "why": "nothing_to_claim"}
		"sim":
			# Step the same kernel the frame loop does, at a fixed dt — with the frame loop
			# held still. Otherwise the two race for the same input dictionary and the same
			# state, which made the first screenshot run non-deterministic (a `fire` flag
			# consumed by whichever got there first, and real frames of chaotic physics
			# interleaved between commands).
			var was_paused: bool = table.paused
			table.paused = true
			var n := int(cmd.get("frames", 60))
			var dt := float(cmd.get("dt", 1.0 / 60.0))
			for _i in range(n):
				var out := Kernel.step(Game.st, table.input, dt, Game.rng())
				Game.st = out["state"]
				table.input["fire"] = false
				table.state = Game.st
				if not out["events"].is_empty():
					_on_events(out["events"])
				if screen != "table":
					break
			table.paused = was_paused
			return {"ok": true, "coins": int(Game.st["coins"]), "score": int(Game.st["score"]),
				"mode": str(Game.st["mode"]), "balls": int(Game.st["balls"])}
		"clock":
			# "you left N seconds ago": rewind lastSeen and re-settle, exactly as a cold
			# load would, so the return screen can be seen without waiting eight hours
			Game.save()
			Game.last_seen = Game.now_ms() - int(cmd.get("awaySeconds", 3600)) * 1000
			Game.pending_return = Idle.settle(Game.st, Game.last_seen, Game.now_ms())
			return {"ok": true, "coins": int(Game.pending_return.get("coins", 0))}
		"lang":
			Game.set_lang(str(cmd.get("lang", "en")))
			show_title()
			return {"ok": true, "lang": Game.lang}
		"reset":
			Game.reset()
			show_title()
			return {"ok": true}
	return {"ok": false, "why": "unknown_op"}
