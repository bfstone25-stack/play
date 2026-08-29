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
	if node is Label or node is Button or node is RichTextLabel:
		var text := str(node.get("text"))
		if text != "":
			into.append(text)
	for child in node.get_children():
		_collect(child, into)


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var fails := 0
	for locale in ["zh", "en"]:
		Loc.set_code(locale)
		await process_frame
		var texts: Array[String] = []
		_collect(game, texts)
		for text in texts:
			if _mixed(text):
				push_error("MIXED %s: %s" % [locale, text.replace("\n", "\\n")])
				fails += 1
		print("LOCALE_SCAN ", locale, " labels=", texts.size())
	var hud: Node = game.get_node("HUD")
	Loc.set_code("zh")
	await process_frame
	if "13层" not in hud.title_name.text:
		push_error("ZH title missing")
		fails += 1
	if _mixed(hud.title_name.text):
		push_error("ZH title still bilingual")
		fails += 1
	Loc.set_code("en")
	await process_frame
	if "FLOOR 13" not in hud.title_name.text:
		push_error("EN title missing")
		fails += 1
	if _has_cjk(hud.title_name.text):
		push_error("EN title still bilingual")
		fails += 1
	if fails > 0:
		quit(1)
	else:
		print("LOCALE_SCAN_OK")
		quit(0)


func _init() -> void:
	call_deferred("_run")
