## scene_gallery_shot.gd: photograph the tier map (the scene gallery) and three scene
## viewers. Added 2026-09-23 with the Folding House scenes (ops/nutaku/fold_f2p/SCENES.md).
## The player's save is snapshotted and restored, so the shot run leaves no progress behind.
##   godot --path . --script res://tests/scene_gallery_shot.gd
extends SceneTree

const OUT := "user://shots"
const VIEW := ["coco_a1", "sable_a3", "coco_a6"]

var _save := {}


func _init() -> void:
	call_deferred("_run")


func _wait(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


func _shot(name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT + "/" + name + ".png")
	print("SHOT ", ProjectSettings.globalize_path(OUT + "/" + name + ".png"))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var save: Node = root.get_node("Save")
	var tier: Node = root.get_node("Tier")
	_save = (save.get("_data") as Dictionary).duplicate(true)
	# clear the first 13 tiers so a row of new scenes shows lit, the rest locked
	for i in range(tier.last_level(12) + 1):
		save.record(i, 3)
	for t in range(tier.count()):
		tier.mark_unlocked(str(tier.scene_for(t)["id"]))
	var map: Node = load("res://scenes/map.tscn").instantiate()
	root.add_child(map)
	await _wait(1500)
	var sc: ScrollContainer = map.get("_scroll")
	if sc != null:
		for y in [2600, 3500]:
			sc.scroll_vertical = y
			await _wait(600)
			_shot("gallery_%d" % y)
	map.queue_free()
	await _wait(300)
	var sv = load("res://scripts/scene_view.gd")
	for id in VIEW:
		var layer := CanvasLayer.new()
		root.add_child(layer)
		var v: Control = sv.open(layer, tier.scene_by_id(id), func(): pass)
		await _wait(1200)
		_shot("scene_" + id)
		layer.queue_free()
		await _wait(200)
	save.set("_data", _save)
	save.flush()
	quit(0)
