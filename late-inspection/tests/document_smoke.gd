extends SceneTree

func _init() -> void:
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var order: Node = scene.active_ids["order"]
	order.interact(scene)
	await process_frame
	var hud = scene.get_node("HUD")
	if not hud.is_vn_open() or hud.is_nvl_open() or hud.document_pages.size() != 4:
		push_error("ADV viewer did not open order folio")
		quit(1)
		return
	while hud.is_vn_open():
		hud._next_document_page()
		await process_frame
	if scene.stage != 1 or scene.player.locked:
		push_error("document close did not complete progression and unlock player")
		quit(2)
		return
	print("DOCUMENT_SMOKE_OK pages=4 stage=", scene.stage)
	quit(0)
