extends SceneTree


func _is_cjk(ch: String) -> bool:
	var o := ch.unicode_at(0)
	return o >= 0x4E00 and o <= 0x9FFF


func _is_latin(ch: String) -> bool:
	return (ch >= "A" and ch <= "Z") or (ch >= "a" and ch <= "z")


func _strip_bbcode(text: String) -> String:
	var re := RegEx.new()
	re.compile("\\[[^\\]]+\\]")
	return re.sub(text, " ", true)


func _has_latin_word(s: String) -> bool:
	var run := 0
	for ch in s:
		if _is_latin(ch):
			run += 1
			if run >= 3:
				return true
		else:
			run = 0
	return false


func _has_cjk(s: String) -> bool:
	for ch in s:
		if _is_cjk(ch):
			return true
	return false


func _mixed(text: String) -> bool:
	if text.strip_edges().begins_with("Language / 语言"):
		return false
	var plain := _strip_bbcode(text)
	return _has_latin_word(plain) and _has_cjk(plain)


func _collect(node: Node, into: Array[String]) -> void:
	if node is Label or node is Button or node is RichTextLabel or node is Label3D:
		var text := str(node.get("text"))
		if text != "":
			into.append(text)
	for child in node.get_children():
		_collect(child, into)


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var fails := 0
	for locale in ["zh", "en"]:
		Loc.set_code(locale)
		await process_frame
		var texts: Array[String] = []
		_collect(scene, texts)
		for text in texts:
			if _mixed(text):
				push_error("MIXED %s: %s" % [locale, text.replace("\n", "\\n")])
				fails += 1
		print("LOCALE_SCAN ", locale, " labels=", texts.size())
	var hud: Node = scene.get_node("HUD")
	Loc.set_code("zh")
	await process_frame
	if "深夜验房" not in hud.splash_title.text:
		push_error("ZH splash missing")
		fails += 1
	if "Late Inspection" in hud.splash_title.text:
		push_error("ZH splash still bilingual")
		fails += 1
	Loc.set_code("en")
	await process_frame
	if "Late Inspection" not in hud.splash_title.text:
		push_error("EN splash missing")
		fails += 1
	if "深夜验房" in hud.splash_title.text:
		push_error("EN splash still bilingual")
		fails += 1
	if fails > 0:
		quit(1)
	else:
		print("LOCALE_SCAN_OK")
		quit(0)


func _init() -> void:
	call_deferred("_run")
