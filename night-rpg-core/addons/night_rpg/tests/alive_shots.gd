extends Node2D
## Motion evidence for the alive pass: every standing figure and every CG of the title,
## eight frames across one breath each, saved as <out>/<kind>_<name>_<i>.png. A local script
## diffs the frames (motion must be visible but small) and builds the review sheet.
##   godot --rendering-driver vulkan --path <game> res://addons/night_rpg/tests/alive_shots.tscn -- --out=DIR [--limit=N]

var out := "user://alive"
var limit := 999


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--limit="):
			limit = int(a.trim_prefix("--limit="))
	DirAccess.make_dir_recursive_absolute(out)
	print("RENDER DEVICE: ", RenderingServer.get_video_adapter_name(), " / ", RenderingServer.get_current_rendering_driver_name())
	RPG.persist["motion"] = true
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.1, 0.14)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var items: Array = []
	var man: Dictionary = NRArt.manifest()
	for kind in ["sprites", "enemies", "cg"]:
		var sect = man.get(kind, {})
		if sect is Dictionary:
			for id in sect.keys():
				var p := NRArt.path(kind, id)
				if p != "":
					items.append([kind, id, p])
	print("ALIVE ITEMS: ", items.size())
	var n := 0
	for it in items:
		if n >= limit:
			break
		n += 1
		var tex: Texture2D = load(it[2])
		var is_fig: bool = it[0] != "cg"
		var node: CanvasItem
		if is_fig:
			var sp := Sprite2D.new()
			sp.texture = tex
			var k := 720.0 * 0.92 / tex.get_height()
			sp.scale = Vector2(k, k)
			sp.position = Vector2(640, 360)
			sp.material = NRAlive.material_for(tex, true)
			NRAlive.fit(sp.material, tex, true)
			node = sp
		else:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.size = Vector2(1280, 720)
			tr.material = NRAlive.material_for(tex, false)
			NRAlive.fit(tr.material, tex, false)
			node = tr
		# phase 0 so frame 0 is the exhale for every item
		(node.material as ShaderMaterial).set_shader_parameter("phase", 0.0)
		add_child(node)
		for i in 8:
			await get_tree().create_timer(0.52).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%s_%s_%d.png" % [out, it[0], it[1], i])
		node.queue_free()
	print("ALIVE DONE ", n)
	get_tree().quit()
