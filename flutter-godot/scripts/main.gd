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
	for a in argv:
		if a.begins_with("--goto="):
			goto_screen = a.substr(7)
		elif a.begins_with("--say="):
			say_text = a.substr(6)
	# QA-only screen jump: the shot hook above only ever saw the title, and route select /
	# chat have no way to get in front of the camera on a headless capture without a mouse
	# to click "begin" with. Nothing in the game calls this.
	if goto_screen == "route_select":
		_show_route_select()
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
			_show_route_select()
		"memories":
			push_warning("memory archive is not ported yet — PORT_PLAN.md step 6")
		"opening":
			push_warning("opening is not ported yet — PORT_PLAN.md step 5")
		"language":
			push_warning("edition switch is not ported yet — PORT_PLAN.md step 3")


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
		chat.back.connect(_show_route_select)
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
