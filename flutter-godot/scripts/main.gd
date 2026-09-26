extends Control

## The root of the Godot rebuild. The title screen is Step 0; route select (step 2) and
## the chat loop (step 1) are wired below it — see PORT_PLAN.md. Editions (step 3), the
## memory archive/opening (step 6), the promo board (step 7) and PWA install (step 8) are
## not ported yet; PUNCHLIST.md tracks the gap.
##
## The signal handler below is the seam every menu item plugs into. "begin" now goes
## somewhere; the other three still don't.

const RouteSelectScene := preload("res://scenes/route_select.tscn")
const ChatScene := preload("res://scenes/chat.tscn")

@onready var title: TitleScreen = $TitleScreen

var route_select: Control = null
var chat: Control = null


func _ready() -> void:
	title.chose.connect(_on_chose)
	# A screenshot hook for the legibility check TITLE_SCREENS.md demands, and the reason
	# it is here rather than in a test: the check is "capture the real frame and read it",
	# so the frame has to come out of the real game, at a real size, with the real motion
	# running. `--headless` cannot draw one; this runs a visible window and quits.
	#   godot --path play/flutter-godot -- --shot user://title.png --shot-after 2.6
	var shot := ""
	var after := 2.6
	var hover := -1
	var argv := OS.get_cmdline_user_args()
	for i in argv.size():
		if argv[i] == "--shot" and i + 1 < argv.size():
			shot = argv[i + 1]
		elif argv[i] == "--shot-after" and i + 1 < argv.size():
			after = float(argv[i + 1])
		elif argv[i] == "--hover" and i + 1 < argv.size():
			hover = int(argv[i + 1])
		elif argv[i] == "--motion-probe":
			_motion_probe()
			return
	var goto_screen := ""
	var say_text := ""
	var story_kind := ""
	for a in argv:
		if a.begins_with("--goto="):
			goto_screen = a.substr(7)
		elif a.begins_with("--say="):
			say_text = a.substr(6)
		elif a.begins_with("--story="):
			story_kind = a.substr(8)
	# QA-only screen jump: the shot hook above only ever saw the title, and route select /
	# chat have no way to get in front of the camera on a headless capture without a mouse
	# to click "begin" with. Nothing in the game calls this.
	if goto_screen == "route_select":
		_show_route_select()
	elif goto_screen == "archive":
		_show_archive()
	elif goto_screen == "chat":
		_show_route_select()
		_on_route_picked({
			"id": "ethan", "name": "Ethan Cole", "title": "the quiet architect",
			"tag": "Slow burn", "emoji": "🏛", "hue": 210,
		})
		if say_text != "":
			# Proves the real thing api.gd exists for: a real HTTPClient SSE round trip
			# against the live backend, not just that the chat screen can draw itself.
			# --shot-after has to clear the LLM's actual generation time, not a frame or
			# two — the caller is expected to pass something like 20-30 for this.
			chat.debug_send(say_text)
		if story_kind != "":
			chat.debug_story(story_kind)
	if shot != "":
		# --hover forces a rail item into its hover state before the frame is taken.
		# Hover and press are item 4 of TITLE_SCREENS.md and the only way to check them is
		# to look at one; a mouse cannot be driven into a headless-ish capture run, so the
		# state is entered directly. QA only — nothing in the game calls this.
		if hover >= 0:
			await get_tree().create_timer(max(0.1, after - 0.6)).timeout
			var kids := title.rail.get_children()
			if hover < kids.size():
				title._hover(kids[hover] as Control, true)
			_shoot(shot, 0.6)
		else:
			_shoot(shot, after)


func _on_chose(action: String) -> void:
	match action:
		"begin":
			Tel.ev("gate_passed", {"via": "click", "phase": "title"})   # = index.html:1947
			_show_route_select()
		"memories":
			_show_archive()
		"opening":
			push_warning("opening is not ported yet — PORT_PLAN.md step 5")
		"language":
			# PORT_PLAN.md step 3: cycle the edition; the next route list is that edition's cast
			Edition.cycle()
			if title.has_method("relabel_language"):
				title.relabel_language()


func _show_title() -> void:
	if route_select:
		route_select.hide()
	if chat:
		chat.hide()
	title.show()


func _show_route_select() -> void:
	title.hide()
	if chat:
		chat.hide()
	if route_select == null:
		route_select = RouteSelectScene.instantiate()
		route_select.picked.connect(_on_route_picked)
		route_select.back.connect(_show_title)
		add_child(route_select)
	route_select.show()
	route_select.reload()


func _on_route_picked(route: Dictionary) -> void:
	route_select.hide()
	if chat == null:
		chat = ChatScene.instantiate()
		chat.back.connect(_leave_chat)
		add_child(chat)
	chat.show()
	chat.start(route)


func _motion_probe() -> void:
	## Does this screen still move while the tree is PAUSED?
	##
	## Not a rhetorical question. Gate.require() pauses the tree, and the fork's web title
	## once shipped frozen at frame one because its title node inherited its process mode —
	## no drift, no light, the mark stuck at the alpha it fades from. That was found by
	## measuring two canvas grabs 1.8 s apart and getting a difference of zero pixels, and
	## this is that measurement, kept, so the claim in title_screen.gd is checked rather
	## than believed.
	await get_tree().create_timer(1.5).timeout
	get_tree().paused = true
	await RenderingServer.frame_post_draw
	var a := get_viewport().get_texture().get_image()
	await get_tree().create_timer(1.8).timeout
	await RenderingServer.frame_post_draw
	var b := get_viewport().get_texture().get_image()
	var diff := 0
	var total := a.get_width() * a.get_height()
	for y in a.get_height():
		for x in a.get_width():
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				diff += 1
	print("motion probe (tree paused): %d of %d pixels changed over 1.8s" % [diff, total])
	print("RESULT: ", "MOVING" if diff > total / 100 else "FROZEN — the title is not animating while paused")
	get_tree().paused = false
	get_tree().quit(0 if diff > total / 100 else 1)


func _shoot(path: String, after: float) -> void:
	# Waited out in real seconds, not frames: the point of the delay is to let the
	# entrance finish and the drift get somewhere, and both are written in seconds.
	await get_tree().create_timer(after).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("shot: ", ProjectSettings.globalize_path(path), " ", img.get_width(), "x", img.get_height())
	get_tree().quit()


## Leaving a chat is the port's natural break. PORT_PLAN.md step 7: the board is the page's
## board.js through the bridge (it decides adult vs SFW by hostname, which is the safety
## property), offered on the 2nd and 4th crossing like every other title. The web build
## also offers the rest of the catalogue at a story ending (index.html:1692); that call
## lands with the story engine, which this port does not have yet.
func _leave_chat() -> void:
	Gate.board_offer_break()
	_show_route_select()


## The memory archive (PORT_PLAN.md step 6): every chapter reward and ending earned in the
## current edition, over the title. Empty says so in the edition's own words.
var _archive: Control


func _show_archive() -> void:
	if is_instance_valid(_archive):
		_archive.queue_free()
	_archive = Control.new()
	_archive.set_anchors_preset(Control.PRESET_FULL_RECT)
	_archive.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_archive)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.04, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_archive.add_child(dim)
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2a1422")
	sb.border_color = Color("#d59a82")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(26)
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(560, 360)
	card.position = Vector2(360, 140)
	_archive.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)
	var head := Label.new()
	head.text = Edition.story("archive", "MEMORIES")
	head.add_theme_font_size_override("font_size", 24)
	vb.add_child(head)
	var d := Archive.load_all()
	var items: Array = []
	for e in d.get("endings", []):
		items.append(["◆", e])
	for r in d.get("rewards", []):
		items.append(["◇", r])
	if items.is_empty():
		var empty := Label.new()
		empty.text = Edition.story("empty", "Nothing collected yet.")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(empty)
	for it in items:
		var l := Label.new()
		l.text = "%s  %s — %s" % [it[0], str(it[1].get("title", "")), str(it[1].get("text", ""))]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(l)
	var close := ShapedButton.new()
	close.shape = ShapedButton.Shape.FOLD
	close.label = Edition.story("close", "CLOSE")
	close.custom_minimum_size = Vector2(160, 40)
	close.pressed.connect(func(): _archive.queue_free())
	vb.add_child(close)
