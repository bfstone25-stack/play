## Mount the exported web pack and prove the title face is really inside it — not just a
## path in the directory, but a FontFile that loads and measures text.
extends SceneTree
func _init() -> void:
	var pck := "res://build/web/index.pck"
	if not ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(pck), false):
		push_error("could not mount %s" % pck); quit(1); return
	for p in ["res://assets/fonts/WorkSans-Bold.ttf", "res://assets/fonts/WorkSans-Regular.ttf",
			"res://assets/fonts/floor13_pixel_12.fnt", "res://assets/fonts/floor13_pixel_16.fnt",
			"res://assets/title/keyvisual.webp", "res://assets/title/logotype.png",
			"res://assets/title/overlay.png"]:
		if not ResourceLoader.exists(p):
			push_error("MISSING FROM PACK: %s" % p); quit(1); return
		var r = load(p)
		if r is Font:
			var w = r.get_string_size("BEGIN NIGHT SHIFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			print("  IN PACK  %-44s %s  name=%s  'BEGIN NIGHT SHIFT'@15 = %.1fpx" % [p, r.get_class(), r.get_font_name(), w])
		else:
			print("  IN PACK  %-44s %s" % [p, r.get_class()])
	print("FONT_PACK_OK")
	quit(0)
