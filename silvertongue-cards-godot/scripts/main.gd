## Main — the frame every screen sits in: the room, the top bar (wordmark, nav, wallet),
## the toast, and the screen switcher. Screens are scenes under res://scenes/ and are
## swapped with a short crossfade. Also owns the web test bridge (window.stc) the
## headless browser driver uses to play through the real build.
extends Control

const SCREENS := {
	"title": "res://scenes/title.tscn",
	"home": "res://scenes/home.tscn",
	"duel": "res://scenes/duel.tscn",
	"gacha": "res://scenes/gacha.tscn",
	"affection": "res://scenes/affection.tscn",
	"deck": "res://scenes/deck.tscn",
	"campaign": "res://scenes/campaign.tscn",
	"store": "res://scenes/store.tscn",
}

var current := ""
var screen: Node
var state := {}                      # last /cards/state
var difficulty := "silver"
var _room: Control
var _bar: PanelContainer
var _nav := {}
var _gold: Counter
var _gold_tag: Label
var _energy_n: Label
var _energy_bar: ProgressBar
var _energy_next: Label
var _daily_tag: Label
var _offline_chip: Label
var _lang_button: Button
var _host: Control
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _energy_left := 0
var _energy_tick := 0.0
var _bridge_cb: JavaScriptObject
var busy := false


func _ready() -> void:
	Symbols.install(Loc.code())
	theme = StudioTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_room()
	_build_bar()
	_host = Control.new()
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.offset_top = 52
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_host)
	_build_toast()
	Api.economy_changed.connect(render_wallet)
	# Online, a dropped request is worth a toast. Offline it is the normal condition and
	# saying so every few seconds would be noise, so the banner says it once instead.
	Api.request_failed.connect(func(_p, e): if not Api.offline: toast("Backend unreachable: " + e))
	# The font stack is part of the language: switching to ja without reinstalling it
	# leaves three Latin faces in front of the Japanese one and the whole screen draws as
	# empty boxes. Rebuild first, THEN re-text and rebuild the screen.
	# Three things have to happen, in this order, and the first build of the language
	# switch did only the middle one:
	#   1. the font stack, or ja draws as empty boxes behind three Latin faces;
	#   2. the top bar's own labels;
	#   3. a REFETCH. `state` holds the scenario rows already resolved to a locale, so
	#      rebuilding the screen without this redraws the roster in the old language --
	#      which is what the first ja capture showed: a Japanese top bar over five
	#      English character cards.
	Loc.changed.connect(func(c):
		Symbols.install(str(c))
		_relabel()
		_relocalise())
	_install_bridge()
	# Ask once whether there is a backend, BEFORE any screen is built. Without this the
	# first screen renders against a state that came back empty, which is how a build with
	# no server reachable showed a roster with nothing in it to press.
	await Api.probe()
	await refresh()
	# The title screen goes in FRONT of the game, and it does not change what the game
	# does when it starts: the resume-aware expression that used to live here is now
	# scripts/title.gd's _start(), unchanged, so a player with a duel in flight still
	# lands back in that duel when they press the first row.
	go("title")


## Refetch in the new language, then rebuild whatever screen is up. Separate from the
## lambda above only because `await` needs a real function.
func _relocalise() -> void:
	await refresh()
	if current != "":
		go(current)


# --- the room ---------------------------------------------------------------------------------
func _build_room() -> void:
	_room = Control.new()
	_room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = Palette.GROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_room.add_child(bg)
	# dark ground, hot accents: a magenta lamp upper right, a plum pool lower left, both
	# faint enough that the ground stays deep under the art
	_room.add_child(_glow(Color(Palette.ACCENT, 0.13), Vector2(0.86, 0.05), 1.15))
	_room.add_child(_glow(Color(Palette.PLUM, 0.28), Vector2(0.08, 0.95), 1.0))
	add_child(_room)


func _glow(c: Color, at: Vector2, radius: float) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, c)
	g.set_color(1, Color(c, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.anchor_left = at.x - radius
	r.anchor_right = at.x + radius
	r.anchor_top = at.y - radius
	r.anchor_bottom = at.y + radius
	r.offset_left = 0; r.offset_right = 0; r.offset_top = 0; r.offset_bottom = 0
	return r


# --- top bar ----------------------------------------------------------------------------------
func _build_bar() -> void:
	_bar = PanelContainer.new()
	_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar.offset_bottom = 52
	var s := StudioTheme.flat(Palette.PANEL_TOP, Palette.PANEL_EDGE, 0, 0, Vector2(14, 0))
	s.border_width_bottom = 1
	_bar.add_theme_stylebox_override("panel", s)
	add_child(_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_bar.add_child(row)
	var wm := VBoxContainer.new()
	wm.add_theme_constant_override("separation", -4)
	var w1 := StudioTheme.display_label("SUASION", 18, Palette.TEXT)
	var w2 := StudioTheme.mono_label("AFTER HOURS · CARDS", 8, Palette.ACCENT_SOFT)
	wm.add_child(w1)
	wm.add_child(w2)
	wm.mouse_filter = Control.MOUSE_FILTER_STOP
	wm.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: go("home"))
	row.add_child(wm)
	row.add_child(_spacer(18))
	# wallet: a coin, the gold count in the display face (it counts up), "GOLD" as a tag
	row.add_child(Coin.new())
	_gold = Counter.new()
	_gold.add_theme_font_override("font", StudioTheme.font("display"))
	_gold.add_theme_font_size_override("font_size", 20)
	_gold.add_theme_color_override("font_color", Palette.GOLD)
	_gold.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gold.set_now(0)
	row.add_child(_gold)
	var gold_tag := StudioTheme.mono_label("GOLD", 10, Palette.GOLD)
	gold_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(gold_tag)
	_gold_tag = gold_tag
	row.add_child(_spacer(10))
	# energy: coral, a bolt, the bar is heat
	_energy_n = StudioTheme.mono_label("⚡ 15/15", 12, Palette.HEAT)
	row.add_child(_energy_n)
	_energy_bar = ProgressBar.new()
	_energy_bar.show_percentage = false
	_energy_bar.custom_minimum_size = Vector2(120, 8)
	_energy_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_energy_bar.max_value = 15
	row.add_child(_energy_bar)
	_energy_next = StudioTheme.mono_label("", 10, Palette.MUTED)
	row.add_child(_energy_next)
	_daily_tag = StudioTheme.mono_label("", 10, Palette.SUCCESS)
	row.add_child(_daily_tag)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	# Offline is a state the player is entitled to know about: their collection lives in
	# this browser rather than in their account. One quiet chip, not a toast every request.
	_offline_chip = StudioTheme.mono_label("", 9, Palette.MUTED)
	_offline_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_offline_chip)
	row.add_child(_spacer(10))
	_lang_button = Button.new()
	_lang_button.focus_mode = Control.FOCUS_NONE
	_lang_button.tooltip_text = "Language"
	_lang_button.pressed.connect(func(): Sfx.play("ui_click"); Loc.next())
	StudioTheme.style_button(_lang_button, "quiet")
	row.add_child(_lang_button)
	var navs := [["home", "DUELS"], ["gacha", "GACHA"], ["affection", "AFFECTION"], ["deck", "DECK"]]
	if F2P.on():
		navs = [["home", "LEDGER"], ["gacha", "GACHA"], ["affection", "BOND"], ["deck", "DECK"], ["store", "STORE"]]
	for pair in navs:
		var b := Button.new()
		b.text = Loc.t(pair[1])
		b.set_meta("key", pair[1])
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): Sfx.play("ui_click"); go(pair[0]))
		row.add_child(b)
		_nav[pair[0]] = b
	_relabel()


## Re-text every label the top bar owns. Called on boot and whenever Loc changes, so the
## language switch does not need the bar rebuilt (which would lose the wallet's animation).
func _relabel() -> void:
	for k in _nav:
		var b: Button = _nav[k]
		if b.has_meta("key"):
			b.text = Loc.t(str(b.get_meta("key")))
	if _lang_button:
		_lang_button.text = Loc.name_of(Loc.code())
	if _offline_chip:
		_offline_chip.text = Loc.t("NO BACKEND — PLAYING OFFLINE") if Api.offline else ""


func _spacer(w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.x = w
	return c


func render_wallet(eco: Dictionary) -> void:
	if eco.is_empty():
		return
	_gold.set_target(float(int(eco.get("gold", 0))))
	if eco.has("tickets"):
		var tk := int(eco.get("tickets", 0))
		_gold_tag.text = "CHIPS · %d TICKET%s" % [tk, "" if tk == 1 else "S"]
	var e: Dictionary = eco.get("energy", {})
	_energy_n.text = ("⚡ CHARM %d/%d" if F2P.on() else "⚡ %d/%d") % [int(e.get("energy", 0)), int(e.get("pool", 15))]
	_energy_bar.max_value = int(e.get("pool", 15))
	_energy_bar.value = int(e.get("energy", 0))
	_energy_left = int(e.get("next_in_s", 0))
	_energy_tick = 0.0
	_show_energy_next(int(e.get("energy", 0)) < int(e.get("pool", 15)))
	_daily_tag.text = "DAILY DUEL FREE" if eco.get("daily_available", false) else ""


func _show_energy_next(show: bool) -> void:
	_energy_next.text = ("+1 in %d:%02d" % [_energy_left / 60, _energy_left % 60]) if show and _energy_left > 0 else ""


func _process(delta: float) -> void:
	if _energy_left > 0:
		_energy_tick += delta
		if _energy_tick >= 1.0:
			_energy_tick -= 1.0
			_energy_left -= 1
			_show_energy_next(true)
			if _energy_left <= 0:
				refresh()


# --- screens ---------------------------------------------------------------------------------
func refresh() -> Dictionary:
	var s := await Api.state()
	if s.has("error"):
		toast(str(s["error"]))
		return s
	state = s
	render_wallet(s.get("economy", {}))
	return s


func go(name: String, args: Dictionary = {}) -> void:
	# On Nutaku the roster is the campaign: the Night Ledger's map replaces the five-duel
	# home screen (F2P.on() is false everywhere else, and nothing below changes).
	if F2P.on() and name == "home":
		name = "campaign"
	if not SCREENS.has(name):
		return
	if screen and is_instance_valid(screen):
		var old := screen
		var tw := create_tween()
		tw.tween_property(old, "modulate:a", 0.0, 0.14)
		tw.tween_callback(old.queue_free)
	current = name
	for k in _nav:
		var b: Button = _nav[k]
		b.theme_type_variation = ""
		if k == name or (k == "home" and name == "campaign"):
			StudioTheme.style_button(b, "active")
	screen = load(SCREENS[name]).instantiate()
	screen.set("main", self)
	if screen.has_method("setup"):
		screen.setup(args)
	_host.add_child(screen)
	screen.modulate.a = 0.0
	var tw2 := create_tween()
	tw2.tween_property(screen, "modulate:a", 1.0, 0.18)
	# The top bar is the loop's furniture — the wordmark, the nav, the wallet. Drawing it
	# over a title screen's key visual is the "a panel stacked on a picture" read that
	# ops/adult_forks/TITLE_SCREENS.md exists to remove, so the title gets the same
	# full-bleed treatment a duel does.
	var chrome_off := name == "duel" or name == "title"
	_bar.visible = not chrome_off
	_host.offset_top = 0 if chrome_off else 52


func scenario(id: String) -> Dictionary:
	for s in state.get("scenarios", []):
		if s.get("id") == id:
			return s
	return {}


# --- toast -----------------------------------------------------------------------------------
func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.PANEL_TOP, Palette.ACCENT, 10, 1, Vector2(14, 8)))
	_toast_label = StudioTheme.mono_label("", 12, Palette.TEXT)
	_toast.add_child(_toast_label)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.offset_bottom = -22
	_toast.modulate.a = 0.0
	_toast.z_index = 100
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)


## `accent` colours the edge: magenta by default, coral for a dupe, gold for a gift.
func toast(text: String, secs: float = 2.4, accent: Color = Palette.ACCENT) -> void:
	_toast_label.text = text
	_toast.add_theme_stylebox_override("panel", StudioTheme.glow(StudioTheme.flat(Palette.PANEL_TOP, accent, 10, 1, Vector2(14, 8)), accent, 10, 0.4))
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.12)
	_toast_tween.tween_interval(secs)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.3)


# --- web test bridge --------------------------------------------------------------------------
## window.stc.call(cmd, arg) -> drives the real build; window.stc.snapshot() -> JSON state.
## Only on the web, only reads what the screens expose; it is how tools/e2e_web.py plays.
func _install_bridge() -> void:
	if not OS.has_feature("web"):
		return
	_bridge_cb = JavaScriptBridge.create_callback(_bridge)
	var win := JavaScriptBridge.get_interface("window")
	win.set("__stc_cb", _bridge_cb)
	JavaScriptBridge.eval("""
		window.stc = {
			_res: null,
			call: function (cmd, arg) { window.stc._res = null; window.__stc_cb(cmd, JSON.stringify(arg === undefined ? null : arg)); },
			result: function () { return window.stc._res; }
		};
	""")


func _bridge(args: Array) -> void:
	var cmd := str(args[0])
	var arg = JSON.parse_string(str(args[1])) if args.size() > 1 else null
	_bridge_run(cmd, arg)


func _bridge_run(cmd: String, arg) -> void:
	var out = await bridge_command(cmd, arg)
	JavaScriptBridge.eval("window.stc._res = %s" % JSON.stringify(JSON.stringify(out)))


## Shared with the desktop tests: every command a driver needs, by name.
func bridge_command(cmd: String, arg) -> Variant:
	match cmd:
		"snapshot":
			return {"screen": current, "pid": Api.pid, "busy": busy,
				"duel": screen.duel if current == "duel" and screen and "duel" in screen else null,
				"hand": screen.hand.ids() if current == "duel" and screen and "hand" in screen else [],
				"hand_state": screen.hand.state if current == "duel" and screen and "hand" in screen else -1,
				"ended": screen.ended if current == "duel" and screen and "ended" in screen else false,
				"economy": Api.last_economy, "sfx": Sfx.log.slice(-12)}
		"set_pid":
			Api.set_pid(str(arg))
			await refresh()
			return {"ok": true, "pid": Api.pid}
		"go":
			go(str(arg))
			await get_tree().process_frame
			return {"ok": true}
		"difficulty":
			difficulty = str(arg)
			return {"ok": true}
		"start":
			var a: Dictionary = arg if typeof(arg) == TYPE_DICTIONARY else {}
			var r := await start_duel(str(a.get("scenario", "closing_time")), bool(a.get("daily", false)))
			return r
		"play":
			if current != "duel" or screen == null:
				return {"error": "not in a duel"}
			var a: Dictionary = arg if typeof(arg) == TYPE_DICTIONARY else {"card": str(arg)}
			return await screen.drive_play(str(a.get("card", "")), str(a.get("text", "")))
		"wild_open":
			if current == "duel" and screen:
				screen.hand.open_wild()
			return {"ok": true}
		"wild_type":
			if current == "duel" and screen:
				screen.wild_input.text = str(arg)
			return {"ok": true}
		"wild_submit":
			if current == "duel" and screen:
				return await screen.drive_wild_submit()
			return {"error": "not in a duel"}
		"leave":
			if current == "duel" and screen:
				screen.leave()
			return {"ok": true}
		"pull":
			if current == "gacha" and screen:
				return await screen.drive_pull(int(arg))
			return {"error": "not on gacha"}
		"dev_gold":
			var r := await Api.dev_gold(int(arg) if arg != null else 1000)
			await refresh()
			return r
		"board":
			if current == "duel" and screen:
				screen.offer_board()
			return {"ok": true}
		"mute":
			Sfx.muted = true
			return {"ok": true}
	return {"error": "unknown command " + cmd}


## Start a duel from anywhere (home roster, the bridge).
func start_duel(scenario_id: String, daily: bool) -> Dictionary:
	if busy:
		return {"error": "busy"}
	busy = true
	var r := await Api.start(scenario_id, difficulty, daily)
	busy = false
	if r.has("error"):
		toast(str(r["error"]))
		return r
	go("duel", {"start": r})
	return {"ok": true, "resumed": r.get("resumed", false), "duel": r.get("duel", {})}


## The coin beside the gold count: drawn, so it is gold on every platform and never a
## font's idea of a diamond.
class Coin extends Control:
	func _ready() -> void:
		custom_minimum_size = Vector2(20, 20)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c + Vector2(0, 1.5), 9.0, Color(0, 0, 0, 0.35))
		draw_circle(c, 9.0, Palette.GOLD_DEEP)
		draw_circle(c, 7.4, Palette.GOLD)
		draw_arc(c, 5.2, 0.0, TAU, 24, Palette.GOLD_DEEP, 1.2)
		draw_circle(c + Vector2(-2.6, -2.6), 2.4, Color(Palette.GOLD_PALE, 0.9))
