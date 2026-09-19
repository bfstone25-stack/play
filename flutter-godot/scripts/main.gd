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
	var argv := OS.get_cmdline_user_args()
	for i in argv.size():
		if argv[i] == "--shot" and i + 1 < argv.size():
			shot = argv[i + 1]
		elif argv[i] == "--shot-after" and i + 1 < argv.size():
			after = float(argv[i + 1])
	if shot != "":
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


func _shoot(path: String, after: float) -> void:
	# Waited out in real seconds, not frames: the point of the delay is to let the
	# entrance finish and the drift get somewhere, and both are written in seconds.
	await get_tree().create_timer(after).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("shot: ", ProjectSettings.globalize_path(path), " ", img.get_width(), "x", img.get_height())
	get_tree().quit()
