extends SceneTree

func _mixed(text: String) -> bool:
	if text.strip_edges().begins_with("Language / 语言"):
		return false
	var slash := RegEx.new()
	slash.compile("[A-Za-z]{3,}[^\\n]{0,40} / [^\\n]{0,40}[\\u4e00-\\u9fff]")
	if slash.search(text):
		return true
	var stacked := RegEx.new()
	stacked.compile("[A-Za-z]{3,}[^\\n]{0,48}\\n[\\u4e00-\\u9fff]")
	return stacked.search(text) != null


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
