extends SceneTree

## Asserts each locale paints one language: no leftover EN+ZH concatenations.


func _init() -> void:
	call_deferred("_run")


func _mixed(text: String) -> bool:
	if text.strip_edges() == "Language / 语言":
		return false
	var slash := RegEx.new()
	slash.compile("[A-Za-z]{3,}[^\\n]{0,40} / [^\\n]{0,40}[\\u4e00-\\u9fff]")
	if slash.search(text):
		return true
	var stacked := RegEx.new()
	stacked.compile("[A-Za-z]{3,}[^\\n]{0,48}\\n[\\u4e00-\\u9fff]")
	return stacked.search(text) != null


func _collect(node: Node, into: Array[String]) -> void:
	if node is Label or node is Button or node is RichTextLabel:
		var text := str(node.get("text"))
		if text != "":
			into.append(text)
	for child in node.get_children():
		_collect(child, into)


func _scan(game: Node, locale: String) -> int:
	Loc.set_code(locale)
	await process_frame
	await process_frame
	var texts: Array[String] = []
	_collect(game, texts)
	var fails := 0
	for text in texts:
		if _mixed(text):
			push_error("MIXED %s: %s" % [locale, text.replace("\n", "\\n")])
			fails += 1
	print("LOCALE_SCAN ", locale, " labels=", texts.size(), " mixed=", fails)
	return fails


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var fails := await _scan(game, "zh")
	fails += await _scan(game, "en")
	if game.title.text != "Midnight Pawn & Crypt":
		push_error("EN title not applied")
		fails += 1
	Loc.set_code("zh")
	await process_frame
	if game.title.text != "午夜典当行与地下密室":
		push_error("ZH title not applied immediately")
		fails += 1
	var has_cjk := false
	for ch in game.title.text:
		if ch >= "一":
			has_cjk = true
	if not has_cjk:
		push_error("ZH title missing CJK")
		fails += 1
	game.queue_free()
	if fails > 0:
		push_error("LOCALE_SCAN_FAILED %d" % fails)
		quit(1)
	else:
		print("LOCALE_SCAN_OK")
		quit(0)
