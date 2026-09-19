## Hand — the fan of cards at the bottom of the table, and its state machine.
##
##   IDLE       cards fanned, hover lifts, click plays (if affordable)
##   WILD       the wild card was chosen: the LineEdit is open, the fan is dimmed
##   PLAYING    a card is flying to the table; input ignored until the owner resolves
##   LOCKED     duel over / waiting on the backend; nothing lifts, nothing plays
##
## The hand never scores anything: `card_chosen(id, text)` is a request the owner sends
## to the backend, and `set_hand()` with the backend's answer is the only way it changes.
class_name Hand
extends Control

signal card_chosen(id: String, text: String)
signal wild_opened
signal wild_closed
signal state_changed(state: int)

enum State { IDLE, WILD, PLAYING, LOCKED }

const FAN_ANGLE := 7.0          # degrees between neighbours
const LIFT := 34.0
const CARD_GAP := 14.0

var state: int = State.IDLE
var cards: Array[Card] = []
var nerve := 1
var wild_left := 1
var wild_card: Card
var _hovered: Card
var _table_target := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(layout)


func set_table_target(p: Vector2) -> void:
	_table_target = p


## Rebuild from the backend's view. `hand` is the list of public card dicts.
func set_hand(hand: Array, nerve_now: int, wild_now: int) -> void:
	nerve = nerve_now
	wild_left = wild_now
	for c in cards:
		c.queue_free()
	cards.clear()
	wild_card = null
	_hovered = null
	for d in hand:
		var c := Card.new()
		add_child(c)
		c.setup(d, int(d.get("cost", 1)) <= nerve)
		c.pressed.connect(_on_pressed)
		c.hovered.connect(_on_hovered)
		cards.append(c)
	if wild_left > 0:
		var w := Card.new()
		add_child(w)
		w.setup({"id": "wild", "rarity": "wild", "kind": "wild", "cost": 2, "character": "wild"}, 2 <= nerve)
		w.pressed.connect(_on_pressed)
		w.hovered.connect(_on_hovered)
		wild_card = w
		cards.append(w)
	_set_state(State.IDLE)
	layout()
	# deal-in: each card slides up from below in turn
	for i in cards.size():
		var c := cards[i]
		var final := c.position
		c.position = final + Vector2(0, 160)
		c.modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(c, "position", final, 0.32).set_delay(0.05 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "modulate:a", 1.0 if c.affordable else 0.55, 0.2).set_delay(0.05 * i)


func ids() -> Array[String]:
	var out: Array[String] = []
	for c in cards:
		out.append(str(c.data.get("id", "")))
	return out


func card_by_id(id: String) -> Card:
	for c in cards:
		if str(c.data.get("id", "")) == id:
			return c
	return null


func layout() -> void:
	var n := cards.size()
	if n == 0:
		return
	var total_w := n * Card.W + (n - 1) * CARD_GAP
	var scale := minf(1.0, (size.x - 20.0) / total_w)
	var step := (Card.W + CARD_GAP) * scale
	var x0 := (size.x - (n - 1) * step - Card.W * scale) / 2.0
	var mid := (n - 1) / 2.0
	for i in n:
		var c := cards[i]
		var k := i - mid
		var lifted := c == _hovered and state == State.IDLE and c.affordable
		c.scale = Vector2(scale, scale) * (1.06 if lifted else 1.0)
		c.rotation_degrees = k * FAN_ANGLE * 0.6 if not lifted else 0.0
		var arc: float = abs(k) * abs(k) * 5.0
		c.position = Vector2(x0 + i * step, 16 + arc - (LIFT if lifted else 0.0))
		c.z_index = 10 if lifted else i
		c.interactive = state == State.IDLE
		if state == State.WILD:
			c.modulate.a = 1.0 if c == wild_card else 0.35
		elif state == State.IDLE:
			c.modulate.a = 1.0 if c.affordable else 0.55


func _on_hovered(c: Card, on: bool) -> void:
	if state != State.IDLE:
		return
	_hovered = c if on else (null if _hovered == c else _hovered)
	layout()


func _on_pressed(c: Card) -> void:
	if state != State.IDLE or not c.affordable:
		return
	var id := str(c.data.get("id", ""))
	if id == "wild":
		open_wild()
		return
	choose(id)


## Programmatic play (tests, the web driver): same path a click takes.
func choose(id: String, text: String = "") -> bool:
	if state != State.IDLE:
		return false
	var c := card_by_id(id)
	if c == null or not c.affordable:
		return false
	_set_state(State.PLAYING)
	_hovered = null
	Sfx.play("card_play")
	fly_to_table(c)
	card_chosen.emit(id, text)
	return true


func open_wild() -> void:
	if state != State.IDLE or wild_card == null or not wild_card.affordable:
		return
	_set_state(State.WILD)
	layout()
	Sfx.play("ui_click")
	wild_opened.emit()


func cancel_wild() -> void:
	if state != State.WILD:
		return
	_set_state(State.IDLE)
	layout()
	wild_closed.emit()


func submit_wild(text: String) -> bool:
	if state != State.WILD:
		return false
	var t := text.strip_edges()
	if t.is_empty():
		return false
	_set_state(State.PLAYING)
	Sfx.play("card_play")
	wild_closed.emit()
	if wild_card:
		fly_to_table(wild_card)
	card_chosen.emit("wild", t)
	return true


func lock() -> void:
	_set_state(State.LOCKED)
	layout()


func unlock() -> void:
	if state == State.LOCKED or state == State.PLAYING:
		_set_state(State.IDLE)
		layout()


func _set_state(s: int) -> void:
	if state == s:
		return
	state = s
	state_changed.emit(s)


## The card leaves the fan for the table: lift, straighten, shrink toward the target
## (the speech panel), fade. The node is dropped when the tween ends; the next
## set_hand() rebuilds the fan from the backend's view.
func fly_to_table(c: Card) -> void:
	c.interactive = false
	c.z_index = 50
	var target := _table_target if _table_target != Vector2.ZERO else Vector2(size.x / 2, -220)
	target = target - global_position - Vector2(Card.W * 0.3, Card.H * 0.3)
	# bound to the card: if set_hand() frees it mid-flight the tween dies with it
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "position", c.position + Vector2(0, -40), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "rotation_degrees", 0.0, 0.12)
	tw.chain().tween_property(c, "position", target, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(c, "scale", Vector2(0.6, 0.6), 0.38).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(c, "modulate:a", 0.0, 0.3).set_delay(0.2)
	tw.chain().tween_callback(func():
		if is_instance_valid(c):
			cards.erase(c)
			c.queue_free())
