extends SceneTree

## Render real frames. The headless tests prove the rules; this proves there is a game on
## the screen — the shop drawn at 640x360, a plate filling the scene window, the Reading
## Ledger over the top. Run it under xvfb; it writes PNGs next to the project.

const C := preload("res://scripts/collateral_core.gd")

var out_dir := "user://shots"
var game: Node


func _init() -> void:
	call_deferred("_run")


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("  shot %s %dx%d" % [name, img.get_width(), img.get_height()])


func _advance_to_menu() -> void:
	var guard := 0
	while not game.awaiting_choice and not game.finished and guard < 400:
		guard += 1
		game.advance()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await _shot("01_cold_open")

	_advance_to_menu()                 # the finial: look, or don't
	await _shot("02_first_choice")

	game.choose(0)                     # put a hand on it
	# The clue and the "this one is free" line come before the plate itself.
	var guard := 0
	while game.plates.current == "" and guard < 20:
		guard += 1
		game.advance()
	await _shot("03_plate")
	if game.plates.current == "":
		push_error("no plate on screen after the first reading")
		quit(1)
		return

	_advance_to_menu()                 # the price menu
	await _shot("04_price_menu")

	game.open_ledger()
	await _shot("05_ledger")
	game.close_ledger()

	# ---- the three states a plate slot can be in, over the real shop ----
	#
	# This is the frame Blaze asked about: a 300x240 authored pixel room with a 1152x768
	# painted illustration dropped into the same window. It cannot be judged from the
	# plate file, only from the composite, and only against the pixel art it replaces.
	game.stage.set_scene("shop")
	game.plates.show_plate("cg_finial")        # installed, uncensored
	await _shot("06_plate_real")
	game.plates.show_plate("cg_ring")          # no uncensored art: the censored stand-in
	await _shot("07_plate_locked")
	game.plates.show_plate("cg_veil")          # no art at all: the pixel floor
	await _shot("08_plate_pixel_floor")
	game.plates.hide_plate()
	await _shot("09_shop_no_plate")            # the same frame with the plate gone
	game.stage.set_scene("market")
	game.ground.texture = game.GROUNDS["market"]
	game.plates.show_plate("cg_market")
	await _shot("10_market_plate")
	game.plates.hide_plate()
	await _shot("11_market_pixel")
	game.stage.set_scene("shop")
	game.ground.texture = game.GROUNDS["shop"]
	game.plates.show_plate("cg_collateral")
	await _shot("12_plate_collateral")
	quit(0)
