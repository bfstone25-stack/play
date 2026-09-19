## Deck — the collection as a grid of small cards; click adds a copy to the deck for the
## chosen scenario, click again removes it. Copies count. SAVE posts the list, AUTO asks
## the backend for its own fill. The wild card is always in the deck and never counts.
extends Control

var main: Node
var scenario := "closing_time"
var deck: Array = []
var collection: Array = []
var deck_size := 18
var _grid: GridContainer
var _count: Label
var _tabs := {}
var _sub: Label


func setup(_args: Dictionary) -> void:
	pass


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 14
	col.offset_bottom = -12
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var tbox := VBoxContainer.new()
	tbox.add_theme_constant_override("separation", 0)
	tbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tbox.add_child(StudioTheme.display_label("DECK", 34, Palette.GOLD))
	_sub = StudioTheme.serif_label("", 13, Palette.MUTED)
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tbox.add_child(_sub)
	head.add_child(tbox)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_count = StudioTheme.display_label("0/18", 20, Palette.GOLD)
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(_count)
	var save := Button.new()
	save.text = "SAVE DECK"
	save.focus_mode = Control.FOCUS_NONE
	StudioTheme.style_button(save, "primary")
	save.pressed.connect(_save)
	actions.add_child(save)
	var auto := Button.new()
	auto.text = "AUTO"
	auto.focus_mode = Control.FOCUS_NONE
	auto.pressed.connect(func(): Sfx.play("ui_click"); _load(true))
	actions.add_child(auto)
	head.add_child(actions)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	col.add_child(tabs)
	for sc in main.state.get("scenarios", []):
		var b := Button.new()
		b.text = str(sc.get("name", "")).to_upper()
		b.focus_mode = Control.FOCUS_NONE
		var id := str(sc.get("id", ""))
		b.pressed.connect(func(): Sfx.play("ui_click"); scenario = id; _load(false))
		tabs.add_child(b)
		_tabs[id] = b
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)
	resized.connect(_fit)
	call_deferred("_fit")
	_load(false)


func _fit() -> void:
	_grid.columns = maxi(2, int((size.x - 60) / (Card.W + 10)))


func _load(auto: bool) -> void:
	for k in _tabs:
		var b: Button = _tabs[k]
		b.theme_type_variation = ""
		if k == scenario:
			StudioTheme.style_button(b, "active")
	var r := await Api.deck(scenario, auto)
	if r.has("error"):
		main.toast(str(r["error"]))
		return
	collection = r.get("collection", [])
	deck = r.get("deck", []).duplicate()
	deck_size = int(r.get("deck_size", 18))
	_sub.text = "Pick up to %d. Copies count. The wild card is always in the deck and never counts." % deck_size
	_render()


func _render() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var count := {}
	for id in deck:
		count[id] = int(count.get(id, 0)) + 1
	for d in collection:
		var id := str(d.get("id", ""))
		var in_deck := int(count.get(id, 0))
		var own := int(d.get("n", 0))
		var wrap := Control.new()
		wrap.custom_minimum_size = Vector2(Card.W, Card.H + 22)
		_grid.add_child(wrap)
		var c := Card.new()
		wrap.add_child(c)
		c.setup(d, true)
		c.set_selected(in_deck > 0)
		var n := StudioTheme.mono_label("%d/%d in deck" % [in_deck, own], 10, Palette.GOLD if in_deck > 0 else Palette.MUTED)
		n.position = Vector2(6, Card.H + 4)
		wrap.add_child(n)
		c.pressed.connect(func(_c):
			Sfx.play("ui_click")
			if in_deck < own and deck.size() < deck_size:
				deck.append(id)
			elif in_deck > 0:
				deck.erase(id)
			_render())
	_count.text = "%d/%d" % [deck.size(), deck_size]


func _save() -> void:
	Sfx.play("ui_click")
	var r := await Api.save_deck(scenario, deck)
	if r.get("ok", false):
		main.toast("Deck saved")
		deck = r.get("deck", deck)
		_render()
	else:
		main.toast(str(r.get("error", "failed")))
