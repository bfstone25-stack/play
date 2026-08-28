extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("main.tscn failed to load")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	if scene.get_node_or_null("ScaleWrap") == null:
		push_error("missing ScaleWrap")
		quit(2)
		return
	var office := scene.find_child("Office", true, false)
	if office == null or office.get_child_count() < 10:
		push_error("office did not build geometry")
		quit(3)
		return
	var hotspots := get_nodes_in_group("hotspot")
	if hotspots.size() < 4:
		push_error("expected 4 hotspots")
		quit(4)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	# Skip title card for clean desk shot.
	scene.title_t = 0.0
	var hud: Node = scene.get_node_or_null("HUD")
	if hud and hud.has_method("show_title"):
		hud.call("show_title", false)
	for i in 45:
		RenderingServer.force_draw()
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("/tmp/floor13-smoke.png")
		print("SMOKE_PNG /tmp/floor13-smoke.png ", img.get_width(), "x", img.get_height())
	# Desk PC dialogue.
	scene.call("_on_hotspot", "pc")
	for i in 25:
		RenderingServer.force_draw()
		await process_frame
	img = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("/tmp/floor13-crt.png")
		print("SMOKE_PNG /tmp/floor13-crt.png ", img.get_width(), "x", img.get_height())
	# Drain dialogue, force coworker + choice.
	if hud and hud.has_method("_advance_dialogue"):
		hud.call("_advance_dialogue")
		hud.call("_advance_dialogue")
		await process_frame
	scene.flags["pc"] = true
	scene.flags["sticky"] = true
	scene.flags["coworker"] = false
	scene.flags["choice_done"] = false
	scene.ending = false
	scene.call("_on_hotspot", "coworker")
	for i in 20:
		RenderingServer.force_draw()
		await process_frame
	# Finish coworker lines → open flee/obey choice.
	if hud and hud.has_method("_advance_dialogue"):
		hud.call("_advance_dialogue")
		hud.call("_advance_dialogue")
		await process_frame
		await process_frame
	if hud and hud.has_method("on_dialogue_done") == false and scene.has_method("on_dialogue_done"):
		scene.call("on_dialogue_done")
	for i in 20:
		RenderingServer.force_draw()
		await process_frame
	img = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("/tmp/floor13-choice.png")
		print("SMOKE_PNG /tmp/floor13-choice.png ", img.get_width(), "x", img.get_height())
	print("SMOKE_OK office_children=", office.get_child_count(), " hotspots=", hotspots.size())
	quit(0)
