extends Control
## Daytime tiny pawn shop — stock / appraise / sell stubs.

var game: Node = null

@onready var title_label: Label = $Panel/VBox/Title
@onready var gold_label: Label = $Panel/VBox/Gold
@onready var shelf_row: HBoxContainer = $Panel/VBox/ShelfRow
@onready var bag_list: ItemList = $Panel/VBox/BagList
@onready var log_label: Label = $Panel/VBox/Log
@onready var btn_stock: Button = $Panel/VBox/Actions/Stock
@onready var btn_appraise: Button = $Panel/VBox/Actions/Appraise
@onready var btn_sell: Button = $Panel/VBox/Actions/Sell
@onready var btn_night: Button = $Panel/VBox/Actions/EnterCrypt
@onready var btn_finish: Button = $Panel/VBox/Actions/FinishRun


func bind(g: Node) -> void:
	game = g
	game.log_line.connect(_on_log)
	game.gold_changed.connect(func(_v): refresh())
	game.bag_changed.connect(func(_v): refresh())
	game.shelf_changed.connect(func(_v): refresh())
	btn_stock.pressed.connect(_on_stock)
	btn_appraise.pressed.connect(func(): game.appraise_selected())
	btn_sell.pressed.connect(func(): game.sell_selected())
	btn_night.pressed.connect(func(): game.enter_night())
	btn_finish.pressed.connect(func(): game.finish_run())
	for i in shelf_row.get_child_count():
		var b: Button = shelf_row.get_child(i)
		var idx := i
		b.pressed.connect(func(): game.select_shelf(idx))
	refresh()


func refresh() -> void:
	if game == null:
		return
	var phase_name: String = game.phase_name()
	title_label.text = "午夜典当 · %s  (Day %d)" % [phase_name, game.day_index]
	gold_label.text = "Gold: %dG   Bag: %d   Looted nights: %d" % [game.gold, game.bag.size(), game.night_looted]
	for i in shelf_row.get_child_count():
		var b: Button = shelf_row.get_child(i)
		var slot = game.shelf[i] if i < game.shelf.size() else null
		if slot == null:
			b.text = "Shelf %d\n(empty)" % (i + 1)
		else:
			var mark := "✓" if slot.get("appraised", false) else "?"
			var val := str(slot["value"]) if slot.get("appraised", false) else "??"
			b.text = "Shelf %d [%s]\n%s\n%sG" % [i + 1, mark, game._label(slot), val]
		b.modulate = Color(1.2, 1.15, 0.8) if i == game.selected_shelf else Color.WHITE
	bag_list.clear()
	for item in game.bag:
		bag_list.add_item("%s  (base %d)" % [game._label(item), item["base"]])
	var settling: bool = game.phase == game.Phase.SETTLE
	btn_night.visible = not settling and game.phase == game.Phase.DAY
	btn_finish.visible = settling
	btn_night.disabled = settling
	btn_finish.disabled = not settling


func _on_stock() -> void:
	var selected: PackedInt32Array = bag_list.get_selected_items()
	if selected.is_empty():
		game._log("Select a bag curio, then Stock.")
		return
	game.stock_from_bag(selected[0])


func _on_log(text: String) -> void:
	log_label.text = text
