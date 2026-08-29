extends SceneTree

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hud: Node = scene.get_node("HUD")
	hud.hide_splash()
	if hud.has_method("hide_title"):
		hud.hide_title()
	DirAccess.make_dir_recursive_absolute("/tmp/late-vn")
	var order: Node = scene.active_ids["order"]
	order.interact(scene)
	await process_frame
	await process_frame
	if not hud.is_vn_open() or hud.is_nvl_open():
		push_error("order folio should open as ADV")
		quit(1)
		return
	if hud.document_pages.size() < 3:
		push_error("order folio lost page splits")
		quit(2)
		return
	await process_frame
	var tex := root.get_viewport().get_texture()
	if tex:
		var img := tex.get_image()
		if img:
			img.save_png("/tmp/late-vn/adv.png")
	var guard := 0
	while hud.is_vn_open() and guard < 80:
		hud._next_document_page()
		await process_frame
		guard += 1
	if hud.is_vn_open() or scene.stage != 1:
		push_error("ADV close did not advance")
		quit(3)
		return
	var letters := """DRAFT 1: Damp returns only when management schedules an inspection.
---
Inspector—do not rescue me by removing the proof I remained."""
	hud.show_story("letters", letters, true, Callable())
	await process_frame
	if not hud.is_nvl_open():
		push_error("diary should open as NVL")
		quit(4)
		return
	await process_frame
	tex = root.get_viewport().get_texture()
	if tex:
		var nvl_img := tex.get_image()
		if nvl_img:
			nvl_img.save_png("/tmp/late-vn/nvl.png")
	print("VN_CHROME_OK adv=1 nvl=1 pages=", hud.document_pages.size(), " lines=", hud.vn.line_count())
	quit(0)
