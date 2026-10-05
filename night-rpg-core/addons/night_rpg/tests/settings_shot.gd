extends Node
## Settings screen shots in en / de / ja (the longest labels) after a row is added. Needs a
## real renderer, on the GPU box only:
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver vulkan --path . res://addons/night_rpg/tests/settings_shot.tscn -- --out=/abs/dir

func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	var out := "/tmp"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	print("RENDER DEVICE: ", RenderingServer.get_video_adapter_name(), " / ", RenderingServer.get_current_rendering_driver_name())
	var main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.5).timeout
	for l in ["en", "de", "ja"]:
		Loc.set_lang(l)
		main.show_settings()
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/settings_%s.png" % [out, l])
		print("SHOT ", l)
	get_tree().quit(0)
