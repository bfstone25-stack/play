extends SceneTree

func _init() -> void:
	# The Gate autoload is not registered yet while a --script SceneTree is constructing,
	# so loading main.tscn here fails to compile game.gd (game.gd:498 references Gate) and
	# the scene instantiates as a bare Node3D. Worse, the resulting error is raised inside
	# a coroutine _init, which kills the coroutine without ever calling quit() — the test
	# hangs instead of failing. Deferring to after the tree is up is the whole fix, and it
	# is what tests/playthrough.gd already did.
	call_deferred("_run")


func _run() -> void:
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
