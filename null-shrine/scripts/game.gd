extends Node
## Midnight Pawn & Crypt — closed micro-run host (Day shop ↔ Night dungeon).

enum Phase { TITLE, DAY, NIGHT, SETTLE, COMPLETE }

const STARTER_GOLD := 40
const CURIO_POOL := [
	{"id": "rusty_bell", "name": "Rusty Bell", "name_zh": "锈铃", "base": 8, "tag": "mundane"},
	{"id": "moon_coin", "name": "Moon Coin", "name_zh": "月币", "base": 14, "tag": "curious"},
	{"id": "bone_key", "name": "Bone Key", "name_zh": "骨钥", "base": 18, "tag": "curious"},
	{"id": "void_shard", "name": "Void Shard", "name_zh": "虚无碎片", "base": 28, "tag": "cursed"},
	{"id": "lantern_oil", "name": "Lantern Oil", "name_zh": "提灯油", "base": 10, "tag": "mundane"},
	{"id": "crypt_map", "name": "Torn Crypt Map", "name_zh": "残破密图", "base": 22, "tag": "curious"},
]

signal phase_changed(phase: int)
signal gold_changed(gold: int)
signal bag_changed(bag: Array)
signal shelf_changed(shelf: Array)
signal log_line(text: String)
signal run_complete(score: int)

var phase: Phase = Phase.TITLE
var gold: int = 0
var bag: Array = [] ## unappraised / inventory curios
var shelf: Array = [] ## up to 3 stocked items {curio, appraised:bool, value:int}
var selected_shelf: int = -1
var night_looted: int = 0
var day_index: int = 0
var score: int = 0
var locale_zh: bool = true

@onready var shop: Control = $Shop
@onready var dungeon: Node2D = $Dungeon
@onready var hud: CanvasLayer = $HUD
@onready var title_ui: Control = $Title
@onready var complete_ui: Control = $Complete


func _ready() -> void:
	randomize()
	shop.visible = false
	dungeon.visible = false
	complete_ui.visible = false
	title_ui.visible = true
	_wire_ui()
	_emit_all()
	_log("午夜典当行开张预备。Midnight Pawn ready.")


func _wire_ui() -> void:
	if title_ui.has_signal("start_pressed") == false and title_ui.has_method("bind"):
		title_ui.bind(self)
	if shop.has_method("bind"):
		shop.bind(self)
	if dungeon.has_method("bind"):
		dungeon.bind(self)
	if complete_ui.has_method("bind"):
		complete_ui.bind(self)
	if hud.has_method("bind"):
		hud.bind(self)


func start_run() -> void:
	gold = STARTER_GOLD
	bag = [_make_curio("rusty_bell"), _make_curio("lantern_oil")]
	shelf = [null, null, null]
	selected_shelf = -1
	night_looted = 0
	day_index = 1
	score = 0
	title_ui.visible = false
	complete_ui.visible = false
	_enter_day("Run start — stock the tiny pawn shop.")


func _make_curio(id: String) -> Dictionary:
	for c in CURIO_POOL:
		if c["id"] == id:
			return {
				"id": c["id"],
				"name": c["name"],
				"name_zh": c["name_zh"],
				"base": c["base"],
				"tag": c["tag"],
				"appraised": false,
				"value": 0,
			}
	return {
		"id": id,
		"name": id,
		"name_zh": id,
		"base": 5,
		"tag": "mundane",
		"appraised": false,
		"value": 0,
	}


func _random_loot() -> Dictionary:
	var pick: Dictionary = CURIO_POOL[randi() % CURIO_POOL.size()]
	return _make_curio(pick["id"])


func _enter_day(reason: String) -> void:
	phase = Phase.DAY
	dungeon.visible = false
	if dungeon.has_method("deactivate"):
		dungeon.deactivate()
	shop.visible = true
	if shop.has_method("refresh"):
		shop.refresh()
	phase_changed.emit(phase)
	_emit_all()
	_log("DAY %d — %s" % [day_index, reason])


func enter_night() -> void:
	if phase != Phase.DAY:
		return
	phase = Phase.NIGHT
	shop.visible = false
	dungeon.visible = true
	if dungeon.has_method("activate"):
		dungeon.activate()
	phase_changed.emit(phase)
	_emit_all()
	_log("NIGHT — descend the pocket crypt. Grab loot, then extract.")


func return_from_dungeon() -> void:
	if phase != Phase.NIGHT:
		return
	day_index += 1
	if day_index >= 3:
		_enter_settle()
	else:
		_enter_day("Appraise night haul, sell, then close again.")


func _enter_settle() -> void:
	phase = Phase.SETTLE
	dungeon.visible = false
	if dungeon.has_method("deactivate"):
		dungeon.deactivate()
	shop.visible = true
	if shop.has_method("refresh"):
		shop.refresh()
	phase_changed.emit(phase)
	_emit_all()
	_log("SETTLE — final sales. Then close the run.")


func finish_run() -> void:
	score = gold + night_looted * 5
	for slot in shelf:
		if slot != null:
			score += int(slot.get("value", slot.get("base", 0)))
	phase = Phase.COMPLETE
	shop.visible = false
	dungeon.visible = false
	complete_ui.visible = true
	if complete_ui.has_method("show_score"):
		complete_ui.show_score(score, gold, night_looted)
	phase_changed.emit(phase)
	run_complete.emit(score)
	_log("RUN COMPLETE — score %d" % score)


func stock_from_bag(bag_index: int) -> void:
	if phase != Phase.DAY and phase != Phase.SETTLE:
		return
	if bag_index < 0 or bag_index >= bag.size():
		return
	var free_slot: int = -1
	for i in shelf.size():
		if shelf[i] == null:
			free_slot = i
			break
	if free_slot < 0:
		_log("Shelves full (3). Sell or hold.")
		return
	var item: Dictionary = bag[bag_index] as Dictionary
	bag.remove_at(bag_index)
	shelf[free_slot] = item
	selected_shelf = free_slot
	_emit_all()
	_log("Stocked: %s" % _label(item))


func appraise_selected() -> void:
	if phase != Phase.DAY and phase != Phase.SETTLE:
		return
	if selected_shelf < 0 or selected_shelf >= shelf.size() or shelf[selected_shelf] == null:
		_log("Select a shelf item to appraise.")
		return
	var item: Dictionary = shelf[selected_shelf]
	if item.get("appraised", false):
		_log("Already appraised: %s (%s) = %dG" % [_label(item), item["tag"], item["value"]])
		return
	var jitter: int = randi_range(-2, 4)
	item["value"] = maxi(1, int(item["base"]) + jitter)
	item["appraised"] = true
	shelf[selected_shelf] = item
	_emit_all()
	_log("Appraised %s → %s · %dG" % [_label(item), item["tag"], item["value"]])


func sell_selected() -> void:
	if phase != Phase.DAY and phase != Phase.SETTLE:
		return
	if selected_shelf < 0 or selected_shelf >= shelf.size() or shelf[selected_shelf] == null:
		_log("Select a shelf item to sell.")
		return
	var item: Dictionary = shelf[selected_shelf]
	if not item.get("appraised", false):
		# Quick-sell at half base if unappraised
		var payout: int = maxi(1, int(item["base"]) / 2)
		gold += payout
		_log("Sold unappraised %s for %dG (half)." % [_label(item), payout])
	else:
		gold += int(item["value"])
		_log("Sold %s for %dG." % [_label(item), item["value"]])
	shelf[selected_shelf] = null
	selected_shelf = -1
	gold_changed.emit(gold)
	shelf_changed.emit(shelf)
	_emit_all()


func select_shelf(index: int) -> void:
	if index < 0 or index >= shelf.size():
		return
	selected_shelf = index
	shelf_changed.emit(shelf)
	if shop.has_method("refresh"):
		shop.refresh()


func add_loot(item: Dictionary) -> void:
	bag.append(item)
	night_looted += 1
	bag_changed.emit(bag)
	_log("Looted: %s" % _label(item))


func spawn_night_loot() -> Array:
	var drops: Array = []
	var count: int = 3 + (randi() % 3)
	for _i in count:
		drops.append(_random_loot())
	return drops


func _label(item: Dictionary) -> String:
	if locale_zh:
		return str(item.get("name_zh", item.get("name", "?")))
	return str(item.get("name", "?"))


func _log(text: String) -> void:
	log_line.emit(text)
	print("[MPC] ", text)


func _emit_all() -> void:
	gold_changed.emit(gold)
	bag_changed.emit(bag)
	shelf_changed.emit(shelf)
	phase_changed.emit(phase)
	if shop.has_method("refresh"):
		shop.refresh()
	if hud.has_method("refresh"):
		hud.refresh()


func phase_name() -> String:
	match phase:
		Phase.TITLE:
			return "TITLE"
		Phase.DAY:
			return "DAY"
		Phase.NIGHT:
			return "NIGHT"
		Phase.SETTLE:
			return "SETTLE"
		Phase.COMPLETE:
			return "COMPLETE"
	return "?"


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: Key = event.keycode
	# Demo / accessibility hotkeys (also used for automated walkthrough)
	if k == KEY_1 and (phase == Phase.DAY or phase == Phase.SETTLE):
		if bag.size() > 0:
			stock_from_bag(0)
			select_shelf(0)
	elif k == KEY_2 and (phase == Phase.DAY or phase == Phase.SETTLE):
		appraise_selected()
	elif k == KEY_3 and (phase == Phase.DAY or phase == Phase.SETTLE):
		sell_selected()
	elif k == KEY_4 and phase == Phase.DAY:
		enter_night()
	elif k == KEY_0 and phase == Phase.NIGHT:
		# Demo: force extract with a free loot
		add_loot(_random_loot())
		return_from_dungeon()
	elif k == KEY_5 and phase == Phase.SETTLE:
		finish_run()
	elif k == KEY_ENTER or k == KEY_KP_ENTER:
		if phase == Phase.TITLE:
			start_run()
		elif phase == Phase.COMPLETE:
			start_run()
