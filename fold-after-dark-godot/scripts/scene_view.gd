## SceneView — the reward. A full-bleed plate, her line in the one italic, her voice.
##
## It draws ONLY what Unlock delivered (scripts/unlock.gd): `source_for(id)` is "" unless
## the bytes for this install landed through the ticket path or the paid package carries
## them, and then this returns null and nothing opens. There is no fallback picture. The
## teaser plate on the map card is the parent game's own *_x_locked frame and never
## appears here.
##
## Mosaic: a pixelation shader over the plate, for the DLsite build; off by default because
## the Nutaku build is uncensored (0 of its top 100 carry mosaic). It is a filter on the
## picture, not a shape drawn on it.
class_name SceneView

const MOSAIC_SHADER := """
shader_type canvas_item;
uniform float cells = 40.0;
void fragment() {
	vec2 uv = (floor(UV * cells) + 0.5) / cells;
	COLOR = texture(TEXTURE, uv);
}
"""


static func plate_for(id: String) -> Texture2D:
	var path := Unlock.source_for(id)
	if path == "":
		return null
	if path.begins_with("res://"):
		return load(path)
	var img := Image.new()
	if img.load(path) != OK:
		return null
	return ImageTexture.create_from_image(img)


## Build the viewer under `layer`. Returns null (and adds nothing) when there is no
## delivered plate. `on_close` runs after the viewer is gone.
static func open(layer: Node, scene: Dictionary, on_close: Callable) -> Control:
	var id := str(scene.get("id", ""))
	var tex := plate_for(id)
	if tex == null:
		return null
	var root := Control.new()
	root.name = "SceneView"
	root.theme = StudioTheme.build()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var ground := ColorRect.new()
	ground.color = Palette.GROUND_DEEP
	ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(ground)

	var pic := TextureRect.new()
	pic.name = "Plate"
	pic.texture = tex
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(pic)
	_apply_mosaic(pic, Save.get_v("ad_mosaic", "0") == "1")

	# a dark gradient along the bottom so her line and the controls sit on the picture
	# without a panel eating it
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	grad.colors = PackedColorArray([Color(Palette.GROUND_DEEP, 0.0), Color(Palette.GROUND_DEEP, 0.0), Color(Palette.GROUND_DEEP, 0.85)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var scrim := TextureRect.new()
	scrim.texture = gt
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)

	var foot := VBoxContainer.new()
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -170
	foot.offset_left = 48
	foot.offset_right = -48
	foot.offset_bottom = -28
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", 10)
	root.add_child(foot)

	var title := StudioTheme.display_label(str(scene.get("title", "")).to_upper(), 22, Palette.GOLD)
	foot.add_child(title)

	var line := str(scene.get("line", ""))
	if line != "":
		var paper := PanelContainer.new()
		paper.theme_type_variation = "Paper"
		paper.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var say := StudioTheme.say_label(17)
		say.custom_minimum_size = Vector2(520, 0)
		say.fit_content = true
		var who := str(scene.get("who", ""))
		say.text = ("[b]%s[/b]  " % who if who != "" else "") + "“%s”" % line
		paper.add_child(say)
		foot.add_child(paper)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	foot.add_child(row)

	var mosaic := CheckButton.new()
	mosaic.name = "Mosaic"
	mosaic.text = I18n.t("mosaic")
	mosaic.button_pressed = Save.get_v("ad_mosaic", "0") == "1"
	mosaic.toggled.connect(func(on: bool):
		Save.set_v("ad_mosaic", "1" if on else "0")
		_apply_mosaic(pic, on))
	row.add_child(mosaic)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var close := Button.new()
	close.name = "Close"
	close.text = I18n.t("close")
	close.theme_type_variation = "Primary"
	close.pressed.connect(func():
		root.queue_free()
		on_close.call())
	row.add_child(close)

	# her voice — the parent's rendered line, when the scene has one
	var v := str(scene.get("voice", ""))
	if v != "" and ResourceLoader.exists("res://assets/voice/%s.ogg" % v) and Save.sfx_on():
		var ap := AudioStreamPlayer.new()
		ap.stream = load("res://assets/voice/%s.ogg" % v)
		ap.volume_db = -2.0
		root.add_child(ap)
		ap.play()

	root.modulate.a = 0.0
	root.create_tween().tween_property(root, "modulate:a", 1.0, 0.35)
	Tel.ev("scene_viewed", {"scene": id})
	return root


static func _apply_mosaic(pic: TextureRect, on: bool) -> void:
	if not on:
		pic.material = null
		return
	var sh := Shader.new()
	sh.code = MOSAIC_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	pic.material = m
