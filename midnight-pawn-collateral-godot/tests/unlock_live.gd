extends SceneTree

## The reveal, against the real gateway, through the code the browser build actually runs.
##
## Everything else about the dual-track model is asserted offline: tests/plates.gd proves a
## gated plate resolves to the censored file without bytes, tools/pack_audit.sh proves the
## bytes are not in the free download. Neither of them ever proved the half in between —
## that a ticket can be got, waited out, spent, and not spent twice — and that half was in
## fact broken twice over when it was first run: nothing in the game called start() or
## redeem() at all, and the bytes the gateway serves are webp while the client wrote them
## to "<id>.png", where no decoder would touch them.
##
##   godot --headless -s res://tests/unlock_live.gd
##
## Takes about 25 seconds, because the gateway's minimum wait is 18 and waiting it out is
## the thing being tested. Needs the network; skips cleanly without one.

const APP := "midnight-pawn-collateral"
const KEY := "cg_finial"

var failures: Array[String] = []
var unlock: Unlock


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	failures.append(msg)


func _run() -> void:
	Unlock.simulate_free = true          # pretend this checkout is the free web package
	Unlock.allow_network = true
	Unlock.clear(KEY)
	unlock = Unlock.new()
	root.add_child(unlock)
	await process_frame

	if Unlock.ready_for(KEY):
		_fail("%s reported ready before anything was fetched" % KEY)

	# 1. the ticket
	var got: bool = await unlock.start(KEY)
	if not got:
		print("SKIP: /unlock/start did not issue a ticket (offline, or %s is not staged)" % KEY)
		quit(0)
		return
	print("  ticket issued for %s/%s" % [APP, KEY])

	# 2. the wait. Spending it immediately must fail, and must not leave bytes behind.
	var early: bool = await unlock.redeem(KEY)
	if early:
		_fail("the ticket was spendable immediately — the wait is not enforced")
	if Unlock.saved_path(KEY) != "":
		_fail("a refused fetch still wrote a file")
	print("  immediate redeem refused")

	await _sleep(20.0)

	# 3. the bytes
	var ok: bool = await unlock.redeem(KEY)
	if not ok:
		_fail("redeem after the wait did not deliver the plate")
	else:
		var path := Unlock.saved_path(KEY)
		if not path.ends_with(".webp"):
			_fail("the gateway serves webp and it landed as %s" % path)
		var img := Image.new()
		if img.load(path) != OK:
			_fail("the delivered bytes did not decode as an image")
		elif img.get_width() < 100:
			_fail("the delivered image is %dx%d" % [img.get_width(), img.get_height()])
		else:
			print("  delivered %s  %dx%d" % [path.get_file(), img.get_width(), img.get_height()])
		# and the plate layer must now resolve the real one
		var layer := PlateLayer.new()
		root.add_child(layer)
		await process_frame
		var picked: Array = layer.pick(KEY)
		if picked[0] == null or bool(picked[1]) or int(picked[2]) != layer.SRC_REAL:
			_fail("the plate layer did not resolve the delivered plate as the real one")
		else:
			print("  plate layer resolves %s uncensored" % KEY)

	# 4. the same ticket, a second time
	Unlock.clear(KEY)
	var reuse: bool = await unlock.redeem(KEY)
	if reuse:
		_fail("the ticket was accepted twice — it is not single-use")
	if Unlock.saved_path(KEY) != "":
		_fail("the refused reuse still wrote a file")
	print("  ticket reuse refused")

	Unlock.clear(KEY)
	Unlock.simulate_free = false
	Unlock.allow_network = false
	if failures.is_empty():
		print("UNLOCK_LIVE_OK app=%s key=%s" % [APP, KEY])
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)


func _sleep(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		await create_timer(0.25).timeout
		t += 0.25
