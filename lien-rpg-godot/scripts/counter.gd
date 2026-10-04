extends Control
## LIEN's second genre: the pawn counter (shop management / appraisal). Opened by the step
## {"screen": "res://scripts/counter.gd", "args": {"mode": "counter"|"market", "hour": "h1"}}.
##
## The loop, all in game.json "shop" (tools/build_data.py) and run state RPG.s["shop"]:
##   counter  pledges due this hour settle first (redeemed: principal + interest back in the
##            till and reputation up; forfeited: the object becomes stock). Then the hour's
##            walk-ins, one at a time. A seller's object shows what it LOOKS worth; laying a
##            hand on it (3 moves) shows what it IS worth, and finds the fakes. Lend against
##            it (they may come back with interest, or not), buy it outright, or send them
##            away. Lowballs that land cost reputation; generous offers earn it, and
##            reputation moves every seller's floor. A buyer wants one kind of curio and pays
##            half again over value -- curios come up from the descent.
##   market   the Ossuary stalls buy stock (relics at a premium) and sell what the descent
##            needs: bone charms (Pay in kind), tea, brandy, peppermints.
## The sim plays it with the same code (main.auto). `--counter=ignore` on the command line
## is the player who never uses it: sends everyone away, sells and buys nothing.

signal _picked(v)

var main
var shop: Dictionary
var st: Dictionary
var auto := false
var lazy := false
var body: VBoxContainer
var side: VBoxContainer


func run(m, args: Dictionary) -> String:
	main = m
	auto = bool(main.auto)
	lazy = "--counter=ignore" in OS.get_cmdline_user_args()
	shop = RPG.game.get("shop", {})
	if not RPG.s.has("shop"):
		RPG.s["shop"] = {"rep": int(shop.get("rep_start", 5)), "pledges": [], "log": []}
	st = RPG.s["shop"]
	_build()
	if args.get("mode", "counter") == "market":
		await _market()
	else:
		await _counter(str(args.get("hour", RPG.s.get("night", ""))))
	RPG.changed.emit()
	return "ok"


# ------------------------------------------------------------------ ui

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var p := PanelContainer.new()
	p.position = Vector2(40, 40)
	p.custom_minimum_size = Vector2(800, 640)
	add_child(p)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	p.add_child(body)
	var q := PanelContainer.new()
	q.position = Vector2(860, 40)
	q.custom_minimum_size = Vector2(380, 640)
	add_child(q)
	side = VBoxContainer.new()
	side.add_theme_constant_override("separation", 6)
	q.add_child(side)


func _clear() -> void:
	for c in body.get_children():
		c.queue_free()
	_ledger()


func _ledger() -> void:
	for c in side.get_children():
		c.queue_free()
	side.add_child(NRSkin.heading(Loc.t("sh_ledger"), 28))
	side.add_child(NRSkin.label(Loc.t("sh_till") % coin(), 20, Color(0.87, 0.74, 0.52)))
	side.add_child(NRSkin.label(Loc.t("sh_rep") % [rep(), _stars(rep())], 20))
	side.add_child(NRSkin.heading(Loc.t("sh_pledges"), 22))
	if st["pledges"].is_empty():
		side.add_child(NRSkin.label("—", 17))
	for pl in st["pledges"]:
		side.add_child(NRSkin.label(Loc.t("sh_pledge_row") % [Loc.t("it_" + pl["item"]), int(pl["principal"]), Loc.t(pl["due"] + "_title")], 17))
	side.add_child(NRSkin.heading(Loc.t("sh_stock"), 22))
	var any := false
	for id in RPG.s["items"].keys():
		if RPG.item_def(id).get("kind", "") == "stock":
			any = true
			side.add_child(NRSkin.label("%s ×%d  (£%d)" % [Loc.t("i_" + id), int(RPG.s["items"][id]), int(RPG.item_def(id).get("value", 0))], 17))
	if not any:
		side.add_child(NRSkin.label("—", 17))


func _stars(r: int) -> String:
	return "●".repeat(clampi(r, 0, 10)) + "○".repeat(10 - clampi(r, 0, 10))


func _say(text: String) -> void:
	body.add_child(NRSkin.label(text, 20))


func _icon(col: int) -> void:
	var img: Texture2D = load("res://assets/ui/curios.png") if ResourceLoader.exists("res://assets/ui/curios.png") else null
	if img == null or col < 0:
		return
	var at := AtlasTexture.new()
	at.atlas = img
	at.region = Rect2(col * 32, 0, 32, 32)
	var tr := TextureRect.new()
	tr.texture = at
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.custom_minimum_size = Vector2(128, 128)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.add_child(tr)


var _box: VBoxContainer


## Offer buttons; returns the picked index. In auto mode `auto_pick` decides.
func _choose(opts: Array, auto_pick: int) -> int:
	if auto:
		if main.shot_hook.is_valid():
			# a screenshot run shows the offer buttons the player would see (inert here)
			if _box != null and is_instance_valid(_box):
				_box.queue_free()
			_box = VBoxContainer.new()
			_box.add_theme_constant_override("separation", 6)
			body.add_child(_box)
			for o in opts:
				var bb := NRSkin.button(o["text"], func(): pass, 19)
				bb.disabled = o.get("disabled", false)
				_box.add_child(bb)
			await get_tree().create_timer(0.3).timeout
			await main.shot_hook.call("counter")
		return auto_pick
	if _box != null and is_instance_valid(_box):
		_box.queue_free()
	var box := VBoxContainer.new()
	_box = box
	box.add_theme_constant_override("separation", 6)
	body.add_child(box)
	for i in opts.size():
		var o: Dictionary = opts[i]
		var b := NRSkin.button(o["text"], func(): _picked.emit(i), 19)
		b.disabled = o.get("disabled", false)
		box.add_child(b)
	return int(await _picked)


func _pause() -> void:
	if auto:
		return
	var b := NRSkin.button(Loc.t("ds_continue"), func(): _picked.emit(-1), 19)
	body.add_child(b)
	await _picked


# ------------------------------------------------------------------ state

func coin() -> int:
	return int(RPG.s["items"].get("coin", 0))


func rep() -> int:
	return int(st.get("rep", 5))


func add_rep(n: int) -> void:
	st["rep"] = clampi(rep() + n, 0, 10)


func pay(n: int) -> void:
	RPG.take("coin", n)


func earn(n: int) -> void:
	RPG.give("coin", n)


# ------------------------------------------------------------------ the counter

func _counter(hour: String) -> void:
	_clear()
	body.add_child(NRSkin.heading(Loc.t("sh_open") % Loc.t(hour + "_title"), 32))
	# 1. what comes due this hour
	var keep := []
	var settled := false
	for pl in st["pledges"]:
		var order: Array = RPG.game["nights"]
		if order.find(pl["due"]) > order.find(hour):
			keep.append(pl)
			continue
		settled = true
		var it: Dictionary = shop["items"][pl["item"]]
		if bool(it.get("redeem", false)):
			var back := int(round(float(pl["principal"]) * (1.0 + float(shop.get("interest", 0.25)))))
			earn(back)
			add_rep(1)
			_say(Loc.t("sh_redeemed") % [Loc.t("it_" + pl["item"]), back])
		else:
			RPG.give(it["stock"])
			_say(Loc.t("sh_forfeit") % Loc.t("it_" + pl["item"]))
	st["pledges"] = keep
	if settled:
		_ledger()
		await _pause()
	# 2. the hour's walk-ins
	for wid in shop.get("walkins", {}).get(hour, []):
		var w: Dictionary = shop["items"][wid]
		if w.get("buyer", false):
			await _buyer(wid, w)
		else:
			await _seller(wid, w, hour)
	_clear()
	body.add_child(NRSkin.heading(Loc.t("sh_closed"), 30))
	_say(Loc.t("sh_closed_body"))
	await _pause()


func _seller(wid: String, w: Dictionary, hour: String) -> void:
	_clear()
	body.add_child(NRSkin.heading(Loc.t("it_" + wid), 28))
	_icon(int(w.get("icon", -1)))
	_say(Loc.t("wi_" + wid))
	var looks := int(w["looks"])
	var est := looks
	var touched := false
	var est_lbl := NRSkin.label(Loc.t("sh_looks") % looks, 22, Color(0.87, 0.74, 0.52))
	body.add_child(est_lbl)
	while true:
		var opts := []
		var floor_v := _floor(w)
		opts.append({"text": Loc.t("sh_touch"), "disabled": touched})
		for f in shop["loan_tiers"]:
			opts.append({"text": Loc.t("sh_lend") % [int(round(est * f)), int(f * 100)], "disabled": int(round(est * f)) > coin() or est <= 0})
		for f in shop["buy_tiers"]:
			opts.append({"text": Loc.t("sh_buy") % [int(round(est * f)), int(f * 100)], "disabled": int(round(est * f)) > coin() or est <= 0})
		opts.append({"text": Loc.t("sh_away")})
		var nl: int = shop["loan_tiers"].size()
		var nb: int = shop["buy_tiers"].size()
		var pick: int = await _choose(opts, _auto_seller(w, touched, est, floor_v, nl))
		if pick == 0:
			touched = true
			RPG.spend_turns(int(shop.get("touch_moves", 3)))
			est = int(w["value"])
			est_lbl.text = Loc.t("sh_fake") if bool(w.get("fake", false)) else Loc.t("sh_worth") % est
			_say(Loc.t("tw_" + wid))
			if auto:
				continue
			continue
		if pick == opts.size() - 1:
			_say(Loc.t("sh_away_line"))
			await _pause()
			return
		var is_loan := pick <= nl
		var f: float = shop["loan_tiers"][pick - 1] if is_loan else shop["buy_tiers"][pick - 1 - nl]
		var offer := int(round(est * f))
		if offer < floor_v:
			_say(Loc.t("sh_refused") % offer)
			if auto:
				return
			continue
		pay(offer)
		if f <= 0.5:
			add_rep(-1)
		elif f >= 0.9:
			add_rep(1)
		if is_loan:
			st["pledges"].append({"item": wid, "principal": offer, "due": w["due"]})
			_say(Loc.t("sh_lent") % [offer, Loc.t(w["due"] + "_title")])
		else:
			RPG.give(w["stock"])
			_say(Loc.t("sh_bought") % offer)
		_ledger()
		await _pause()
		return


## The least a seller takes: a fraction of what the object LOOKS worth (they do not know it is
## fake), lowered by the shop's reputation.
func _floor(w: Dictionary) -> int:
	var fr: float = float(w.get("floor", 0.6)) - (rep() - 5) * float(shop.get("rep_floor", 0.03))
	return int(round(float(w["looks"]) * fr))


func _auto_seller(w: Dictionary, touched: bool, est: int, floor_v: int, nl: int) -> int:
	if lazy:
		return 1 + nl + shop["buy_tiers"].size()
	if not touched:
		return 0
	if bool(w.get("fake", false)):
		return 1 + nl + shop["buy_tiers"].size()
	# the cheapest loan tier the seller will take; loans earn interest or become stock
	# a fair shop: the middle tier first (a lowball costs reputation), the generous one if needed
	for i in [1, 2, 0]:
		if i < nl and int(round(est * shop["loan_tiers"][i])) >= floor_v and int(round(est * shop["loan_tiers"][i])) <= coin():
			return 1 + i
	return 1 + nl + shop["buy_tiers"].size()


func _buyer(wid: String, w: Dictionary) -> void:
	_clear()
	body.add_child(NRSkin.heading(Loc.t("it_" + wid), 28))
	_icon(int(w.get("icon", -1)))
	_say(Loc.t("wi_" + wid))
	var want: String = w["wants"]
	var opts := []
	var have := []
	for id in RPG.s["items"].keys():
		var d := RPG.item_def(id)
		if d.get("kind", "") == "stock" and d.get("curio", "") == want:
			have.append(id)
	for id in have:
		var price := int(round(float(RPG.item_def(id)["value"]) * float(shop.get("buyer_premium", 1.5))))
		opts.append({"text": Loc.t("sh_sell_to") % [Loc.t("i_" + id), price], "id": id, "price": price})
	opts.append({"text": Loc.t("sh_nothing")})
	var pick: int = await _choose(opts, opts.size() - 1 if (lazy or have.is_empty()) else 0)
	if pick < have.size():
		RPG.take(opts[pick]["id"])
		earn(int(opts[pick]["price"]))
		add_rep(1)
		_say(Loc.t("sh_sold_buyer") % int(opts[pick]["price"]))
	else:
		_say(Loc.t("sh_buyer_gone"))
	_ledger()
	await _pause()


# ------------------------------------------------------------------ the market stalls

func _market() -> void:
	while true:
		_clear()
		body.add_child(NRSkin.heading(Loc.t("sh_market"), 30))
		_say(Loc.t("sh_market_body"))
		var opts := []
		for id in RPG.s["items"].keys():
			var d := RPG.item_def(id)
			if d.get("kind", "") == "stock":
				var price := int(round(float(d["value"]) * (float(shop.get("relic_premium", 1.3)) if d.get("relic", false) else 1.0)))
				opts.append({"text": Loc.t("sh_sell") % [Loc.t("i_" + id), price], "sell": id, "price": price})
		for g in shop.get("goods", []):
			opts.append({"text": Loc.t("sh_buy_good") % [Loc.t("i_" + g["item"]), int(g["price"])], "buy": g["item"], "price": int(g["price"]),
				"disabled": int(g["price"]) > coin()})
		opts.append({"text": Loc.t("sh_leave")})
		var pick: int = await _choose(opts, _auto_market(opts))
		var o: Dictionary = opts[pick]
		if o.has("sell"):
			RPG.take(o["sell"])
			earn(int(o["price"]))
		elif o.has("buy"):
			pay(int(o["price"]))
			RPG.give(o["buy"])
		else:
			return


var _bought := 0


func _auto_market(opts: Array) -> int:
	if lazy:
		return opts.size() - 1
	for i in opts.size():
		var o: Dictionary = opts[i]
		# keep the curios a counter buyer will pay more for; sell everything else
		if o.has("sell") and RPG.item_def(o["sell"]).get("curio", "") == "":
			return i
	# then stock up for the descent, while the till stays well above the debt line
	for i in opts.size():
		var o: Dictionary = opts[i]
		if o.has("buy") and _bought < 3 and coin() - int(o["price"]) > 160:
			_bought += 1
			return i
	return opts.size() - 1
