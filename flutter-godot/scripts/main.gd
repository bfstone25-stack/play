extends Control

## The root of the Godot rebuild. Today it is a title screen and four menu items that have
## nowhere to go yet — see PORT_PLAN.md. That is deliberate: the title screen is the piece
## Blaze asked for, and the rest of the game is days of work he has not yet agreed to.
##
## The signal handler below is the seam. Every one of the four items already emits, so
## when a screen exists to show, it is wired here and nowhere else.

@onready var title: TitleScreen = $TitleScreen


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
			push_warning("route select is not ported yet — PORT_PLAN.md step 4")
		"memories":
			push_warning("memory archive is not ported yet — PORT_PLAN.md step 6")
		"opening":
			push_warning("opening is not ported yet — PORT_PLAN.md step 5")
		"language":
			push_warning("edition switch is not ported yet — PORT_PLAN.md step 3")


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
