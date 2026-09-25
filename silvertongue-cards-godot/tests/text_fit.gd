## text_fit.gd -- does every visible string fit where it is drawn? (2026-09-24, with de/fr/es/ko)
##
## German runs ~30% longer than English, and a label that overflows its button draws over
## its neighbour with no error anywhere. The screenshots show it to a person; this says it
## in the log, so the shot run can fail on it:
##
##   OVERFLOW <node path> <text width> > <box width> "<text>"   a one-line Label/Button
##       whose text is wider than the whole box (no wrap, no clip, no ellipsis): it spills
##       past the button's edge, not merely into its padding
##   OFFSCREEN <node path> "<text>"   a text control reaching past the viewport's edge
##       (not counting content inside a clipping parent such as a ScrollContainer, which
##       is scrolled, not cut)
##
## Called by the walkthroughs' shot() after each still. Custom-drawn words (ShapedButton,
## ObjectButton, draw_string) are not Labels; the screenshots are the check for those.
extends RefCounted


static func scan(root: Node) -> Array[String]:
	var out: Array[String] = []
	var vp := root.get_viewport()
	if vp == null:
		return out
	var view := vp.get_visible_rect().grow(2.0)
	_walk(root, view, out)
	return out


static func _walk(n: Node, view: Rect2, out: Array[String], clipped := false) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Control:
		var c := n as Control
		var text := ""
		if c is Label:
			text = (c as Label).text
		elif c is Button:
			text = (c as Button).text
		elif c is RichTextLabel:
			text = (c as RichTextLabel).get_parsed_text()
		if text.strip_edges() != "" and c.size.x > 1.0 and c.modulate.a > 0.05:
			var r := c.get_global_rect()
			if not clipped and not view.encloses(r) and view.intersects(r):
				out.append("OFFSCREEN %s \"%s\"" % [c.get_path(), text.left(60)])
			var need := _one_line_width(c, text)
			if need > 0.0 and need > c.size.x + 2.0:
				out.append("OVERFLOW %s %d > %d \"%s\"" % [c.get_path(), int(need), int(c.size.x), text.left(60)])
	var clips := clipped or (n is Control and ((n as Control).clip_contents or n is ScrollContainer))
	for ch in n.get_children():
		_walk(ch, view, out, clips)


## Width a single-line text control needs, or 0 when it wraps, clips or ellipsises (those
## cannot overflow sideways).
static func _one_line_width(c: Control, text: String) -> float:
	var font: Font = c.get_theme_font("font")
	var fs: int = c.get_theme_font_size("font_size")
	if font == null:
		return 0.0
	var pad := 0.0
	if c is Label:
		var l := c as Label
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF or l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			return 0.0
	elif c is Button:
		var b := c as Button
		if b.clip_text or b.autowrap_mode != TextServer.AUTOWRAP_OFF or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			return 0.0
		if b.icon:
			pad += b.icon.get_width() + b.get_theme_constant("h_separation")
	else:
		return 0.0
	var widest := 0.0
	for line in text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	return widest + pad
