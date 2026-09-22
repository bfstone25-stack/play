## Gate.gd — dual-track unlock gate for the Godot web exports (ops/DUAL_TRACK.md).
##
## Autoload as "Gate". At a cut point:
##     if await Gate.require("ch2", "Chapter 2"):
##         _advance_to_chapter_2()
##
## On the web it hands the decision to gate.js on the page (a price on itch, a sponsor
## clip on free.blazecore.dev) and waits for the answer; on desktop (the paid download)
## everything is open and it returns true at once.
extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # the gate keeps ticking while the tree is paused
	_board_warp()

func is_web() -> bool:
	return OS.has_feature("web")

func has(key: String) -> bool:
	if not is_web():
		return true
	var r = JavaScriptBridge.eval("(window.Gate && window.Gate.has(%s)) ? 1 : 0" % JSON.stringify(key))
	return int(r) == 1

func require(key: String, title: String, kind: String = "chapter") -> bool:
	if not is_web():
		return true
	if not JavaScriptBridge.eval("window.Gate ? 1 : 0"):
		return true  # page without gate.js (local test): never brick the game
	if has(key):
		return true
	var js = """
		window.__gate = window.__gate || {};
		window.__gate[%s] = "";
		window.Gate.require(%s, {title: %s, kind: %s}).then(function (r) { window.__gate[%s] = r; });
	""" % [JSON.stringify(key), JSON.stringify(key), JSON.stringify(title), JSON.stringify(kind), JSON.stringify(key)]
	JavaScriptBridge.eval(js)
	var result := ""
	while result == "":
		await get_tree().create_timer(0.4).timeout
		var r = JavaScriptBridge.eval("(window.__gate && window.__gate[%s]) || ''" % JSON.stringify(key))
		result = str(r) if r != null else ""
	return result == "unlocked"

## Fire-and-forget form for places that cannot await: pauses the whole tree while the
## page shows the gate, resumes on unlock. A refusal reloads the page — the free part
## starts over, which is what "the demo ends here" means on the itch track.
func block(key: String, title: String, kind: String = "chapter") -> void:
	if not is_web() or has(key):
		return
	if not JavaScriptBridge.eval("window.Gate ? 1 : 0"):
		return
	get_tree().paused = true
	var ok := await _require_paused(key, title, kind)
	if ok:
		get_tree().paused = false
	else:
		JavaScriptBridge.eval("location.reload()")

func _require_paused(key: String, title: String, kind: String) -> bool:
	var js = """
		window.__gate = window.__gate || {};
		window.__gate[%s] = "";
		window.Gate.require(%s, {title: %s, kind: %s}).then(function (r) { window.__gate[%s] = r; });
	""" % [JSON.stringify(key), JSON.stringify(key), JSON.stringify(title), JSON.stringify(kind), JSON.stringify(key)]
	JavaScriptBridge.eval(js)
	var result := ""
	while result == "":
		await get_tree().create_timer(0.4, true, false, true).timeout   # runs while paused
		var r = JavaScriptBridge.eval("(window.__gate && window.__gate[%s]) || ''" % JSON.stringify(key))
		result = str(r) if r != null else ""
	return result == "unlocked"


## ---- the cross-promotion board (play/_shared/board.js) ----------------------------
##
## The board is a JS object on the host page, so from a wasm export it is only reachable
## through JavaScriptBridge — and only when there *is* a page. A desktop export has no
## window at all, so every entry point returns before it evaluates anything; that is the
## Godot equivalent of room-704's `renpy.emscripten` guard
## (play/room-704/game/scripts/09_dist.rpy).
##
## Both calls are no-ops when the page did not load board.js, rather than errors. That is
## deliberate but it is NOT a licence to ship without it: play/confession-room had the
## call wired and the script missing, and the board never appeared in production once.
## The build scripts (ops/godot_build.sh, ops/floor13x_build.sh) copy board.js into the
## exported web directory and add the <script> tag, and they verify it afterwards.

var _board_breaks := 0

## Between chapters, inside an adult title: offer the *casual* board.
##
## Not on every crossing. Blaze's design is that arousal fatigues and a player forty
## minutes in wants ten minutes of something else — but a thing that asks every time is a
## thing players learn to dismiss without reading. Offered on the 2nd and 4th crossing of
## a session, which is the gating room-704 settled on.
## Returns true only when the board was actually offered, so a caller that has to change
## the game around it (a mouse-captured first-person game has to release the mouse, or the
## player cannot click the thing they were just asked about) does not do that on the three
## crossings out of four where nothing is drawn.
func board_offer_break() -> bool:
	if not is_web():
		return false
	_board_breaks += 1
	if _board_breaks != 2 and _board_breaks != 4:
		return false
	if not JavaScriptBridge.eval("(window.BOARD && window.BOARD.offerBreak) ? 1 : 0"):
		return false
	JavaScriptBridge.eval("BOARD.offerBreak()")
	return true

## End of a run. `kind` is which catalogue: "adult" (the default — the rest of the adult
## catalogue, offered by the adult forks) or "casual" (the other small games, offered by
## the mainstream titles). board.js refuses to draw the adult board anywhere it is not
## allowed, so the call site does not have to remember — but a mainstream title on
## free.blazecore.dev that asks for "adult" gets exactly nothing, silently, which is why
## the four mainstream Godot games pass "casual" explicitly.
func board_offer_more(kind: String = "adult") -> void:
	if not is_web():
		return
	if kind != "casual":
		kind = "adult"
	# Guard first, then call plainly — the same two steps as board_offer_break() above.
	#
	# This used to be one expression: `window.BOARD && BOARD.offerMore && BOARD.offerMore(k)`.
	# It drew nothing, in every title, at the end of every run. Isolated 2026-09-20 with
	# ?warp=board on The Other Side's web build: `second: 1` (offerBreak draws) and
	# `more: 0, tiles: 0` (offerMore does not), while calling BOARD.offerMore("adult")
	# straight from the page on the same build draws the board in under five seconds. The
	# bridge works and board.js works; only the compound form does not — offerMore returns
	# a Promise, and a short-circuit chain whose value is a Promise is not something to
	# hand JavaScriptBridge.eval when the plain call is right there.
	#
	# This is the failure the ?warp=board hook exists to catch, and it is worth saying that
	# it only showed up because someone ran the hook rather than reading the source: the
	# call was wired, the script shipped, the host allowed it, and the board never appeared.
	#
	# Re-measured AFTER the fix, 2026-09-20 ~03:30, on the GPU box's real WebGL2 rather
	# than a software rasteriser: a cold load of build/godot-ads/the-other-side with
	# ?warp=board gives `wraps=1 tiles=3`, no page errors. The record above was the
	# before; this is the after, and a fix with only a "before" is an argument.
	#
	# How that was measured matters as much as the number. offerMore is async on top of a
	# catalogue fetch, so the driver POLLS for up to 60s instead of sampling once: "it
	# drew nothing" and "it has not drawn YET" are the same observation at t=0, and two
	# other checks were caught lying that way the same night.
	if not JavaScriptBridge.eval("(window.BOARD && window.BOARD.offerMore) ? 1 : 0"):
		return
	JavaScriptBridge.eval("BOARD.offerMore(%s)" % JSON.stringify(kind))


## Is a board panel on screen right now? board.js draws exactly one .bd-wrap and removes
## it on every close path, so this is the whole of "has the player finished with it".
func board_open() -> bool:
	if not is_web():
		return false
	return int(JavaScriptBridge.eval("document.querySelector('.bd-wrap') ? 1 : 0")) == 1


## ?warp=board — drive the board from a cold page load.
##
## The same idea as room-704's ?warp=gate (09_dist.rpy): a Godot game draws into a canvas,
## so there is no way to check the board by reading the DOM without first playing to a
## chapter crossing, and "it is wired in the source" is exactly the evidence that let
## play/confession-room ship a board that never once appeared. This exercises the real
## entry points — including the 2nd-and-4th gating, so a run of it also proves the first
## offer stays silent — against the real wasm build on the real page.
##
## `&more=casual` makes the end-of-run step offer the casual board instead of the adult
## one — the mainstream titles' call, and the only one that can draw on the AdSense host.
##
## Costs nothing in a normal session: no query string, no work.
func _board_warp() -> void:
	if not is_web():
		return
	var q = JavaScriptBridge.eval("new URLSearchParams(location.search).get('warp') || ''")
	if str(q) != "board":
		return
	var more_kind := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('more') || 'adult'"))
	# Set before the first await, so a run that never gets past it is distinguishable from
	# a run where the hook was not in the build at all.
	JavaScriptBridge.eval("window.__board_warp = {started: 1}")
	await _warp_wait(90)
	# first crossing: must draw nothing
	board_offer_break()
	JavaScriptBridge.eval("window.__board_warp.first = document.querySelector('.bd-wrap') ? 1 : 0")
	# second crossing: the casual board
	board_offer_break()
	await _warp_wait(90)
	JavaScriptBridge.eval("window.__board_warp.second = document.querySelector('.bd-wrap') ? 1 : 0")
	JavaScriptBridge.eval("window.__board_warp.open_probe = %d" % (1 if board_open() else 0))
	JavaScriptBridge.eval("var w = document.querySelector('.bd-wrap'); w && w.remove()")
	# end of a run: the adult catalogue, or the casual one when asked
	board_offer_more(more_kind)
	await _warp_wait(90)
	JavaScriptBridge.eval("window.__board_warp.more = document.querySelector('.bd-wrap') ? 1 : 0;"
		+ "window.__board_warp.tiles = document.querySelectorAll('.bd-tile').length;"
		+ "window.__board_warp.done = 1")


## Wait n frames. SceneTree.process_frame fires whether or not the tree is paused, and a
## SceneTree timer does not: floor-13-x is paused behind its title card at the moment an
## autoload's _ready runs, and a timer-based wait there never resumes at all. This is only
## used by the warp hook above.
func _warp_wait(frames: int) -> void:
	for _i in range(frames):
		await get_tree().process_frame
