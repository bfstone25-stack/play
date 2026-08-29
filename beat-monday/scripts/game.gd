extends Node2D

var area_index := 0
var flags := {
	"eli_stance": "",
	"compliance": "",
	"escape_route": "",
	"contract": ""
}
var discoveries: Array[String] = []
var completed_hotspots: Dictionary = {}
var current_hotspot := ""
var pending := ""
var started := false
var ending_id := ""
var world: OfficeBuilder
var hud: HorrorHud
var hotspot_layer: Control
var soundscape: Soundscape

const NVL_HOTSPOTS := ["coffee", "drawer", "ledger", "camera", "intercom", "alarm"]

func _ready() -> void:
	add_to_group("game")
	world = OfficeBuilder.new()
	world.name = "PixelWorld"
	add_child(world)
	soundscape = Soundscape.new()
	soundscape.name = "Soundscape"
	add_child(soundscape)
	hud = HorrorHud.new()
	hud.name = "HUD"
	add_child(hud)
	hud.choice_made.connect(_on_choice)
	hud.route_requested.connect(_on_route)
	hud.restart_requested.connect(restart)
	hud.title_requested.connect(start_game)
	await get_tree().process_frame
	hotspot_layer = Control.new()
	hotspot_layer.name = "Hotspots"
	hotspot_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.root_ui.add_child(hotspot_layer)
	hud.root_ui.move_child(hotspot_layer, 1)
	world.build("cubicle", flags)
	hud.set_header(Loc.t("idle.chapter"), Loc.t("idle.place"), Loc.t("idle.clock"), Loc.t("idle.objective"))

func start_game() -> void:
	if started:
		return
	started = true
	area_index = 0
	_load_area()

func restart() -> void:
	area_index = 0
	flags = {"eli_stance": "", "compliance": "", "escape_route": "", "contract": ""}
	discoveries.clear()
	completed_hotspots.clear()
	current_hotspot = ""
	pending = ""
	started = false
	ending_id = ""
	_clear_hotspots()
	hud.reset_ui()
	world.build("cubicle", flags)
	hud.set_header(Loc.t("idle.chapter"), Loc.t("idle.place"), Loc.t("idle.clock"), Loc.t("idle.objective"))

func _load_area() -> void:
	_clear_hotspots()
	var area: Dictionary = StoryData.live()[area_index]
	world.build(area.id, flags)
	hud.set_header(area.chapter, area.place, area.clock, area.objective)
	pending = "opening"
	hud.show_dialogue(_expand(area.opening), false)

func _show_hotspots() -> void:
	_clear_hotspots()
	var area: Dictionary = StoryData.live()[area_index]
	var count := 0
	for hotspot in area.hotspots:
		var id := str(hotspot[0])
		var rect: Array = hotspot[2]
		var button := Button.new()
		button.name = "Hotspot_%s" % id
		button.position = Vector2(rect[0] * 2.0, rect[1] * 2.0)
		button.size = Vector2(rect[2] * 2.0, rect[3] * 2.0)
		button.text = ""
		button.tooltip_text = str(hotspot[1])
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color.TRANSPARENT
		var hover := normal.duplicate()
		hover.bg_color = Color("#1b405733")
		hover.border_color = Color("#84efff")
		hover.set_border_width_all(1)
		var pressed := normal.duplicate()
		pressed.bg_color = Color("#56242c55")
		pressed.border_color = Color("#ff5264")
		pressed.set_border_width_all(1)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		UiFont.apply_button(button)
		button.pressed.connect(_on_hotspot.bind(id))
		button.add_to_group("hotspot")
		hotspot_layer.add_child(button)
		var marker := Label.new()
		marker.position = Vector2(4, 4)
		marker.size = Vector2(26, 17)
		marker.text = "◆ %02d" % (count + 1)
		marker.add_theme_font_size_override("font_size", 8)
		marker.add_theme_color_override("font_color", Color("#b8f4ff"))
		marker.add_theme_color_override("font_outline_color", Color("#05070d"))
		marker.add_theme_constant_override("outline_size", 3)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiFont.apply_label(marker)
		button.add_child(marker)
		count += 1

func _on_hotspot(id: String) -> void:
	if hud.is_busy() or completed_hotspots.has(_area_key(id)):
		return
	var area: Dictionary = StoryData.live()[area_index]
	for hotspot in area.hotspots:
		if hotspot[0] == id:
			current_hotspot = id
			pending = "hotspot"
			soundscape.cue(_cue_for(id))
			hud.show_dialogue(_expand(hotspot[3]), str(id) in NVL_HOTSPOTS)
			return

func on_dialogue_done() -> void:
	match pending:
		"opening":
			pending = ""
			_show_hotspots()
		"hotspot":
			completed_hotspots[_area_key(current_hotspot)] = true
			discoveries.append("%s — %s" % [StoryData.live()[area_index].place, _hotspot_label(current_hotspot)])
			current_hotspot = ""
			pending = ""
			_show_hotspots()
			if _area_complete():
				_clear_hotspots()
				var area: Dictionary = StoryData.live()[area_index]
				if area.has("choice"):
					hud.show_choice(area.choice)
				else:
					hud.enable_route(Loc.t("route.next"))
		"choice_after":
			pending = ""
			hud.enable_route(Loc.t("route.decision"))
		"transition":
			pending = ""
			area_index += 1
			_load_area()
		"ending":
			pending = ""
			hud.show_ending_card(StoryData.live_endings()[ending_id][-1][1])

func _on_choice(value: String) -> void:
	var area: Dictionary = StoryData.live()[area_index]
	var flag_name := str(area.choice.id)
	flags[flag_name] = value
	world.build(area.id, flags)
	discoveries.append(Loc.t("log.decision", [flag_name.to_upper().replace("_", " "), value]))
	soundscape.cue("choice")
	pending = "choice_after"
	hud.show_dialogue(_expand(area.after[value]), str(area.id) == "manager")

func _on_route() -> void:
	hud.hide_route()
	var area: Dictionary = StoryData.live()[area_index]
	if area_index == StoryData.live().size() - 1:
		_begin_ending()
		return
	pending = "transition"
	hud.show_dialogue(_expand(area.get("transition", [])), false)

func _begin_ending() -> void:
	ending_id = StoryData.resolve(flags)
	discoveries.append(Loc.t("log.ending", [ending_id.replace("_", " ")]))
	pending = "ending"
	soundscape.cue("ending")
	world.show_ending(ending_id)
	var lines: Array = StoryData.live_endings()[ending_id].duplicate(true)
	lines.pop_back()
	hud.show_dialogue(_expand(lines), true)

func _area_complete() -> bool:
	var area: Dictionary = StoryData.live()[area_index]
	for hotspot in area.hotspots:
		if not completed_hotspots.has(_area_key(hotspot[0])):
			return false
	return true

func _area_key(id: String) -> String:
	return "%s/%s" % [StoryData.live()[area_index].id, id]

func _hotspot_label(id: String) -> String:
	for hotspot in StoryData.live()[area_index].hotspots:
		if hotspot[0] == id:
			return hotspot[1]
	return id

func _clear_hotspots() -> void:
	if hotspot_layer == null:
		return
	for child in hotspot_layer.get_children():
		child.queue_free()

func _cue_for(id: String) -> String:
	if "phone" in id or id == "intercom":
		return "phone"
	if id == "printer" or id == "ledger":
		return "printer"
	if id == "seal" or id == "directory":
		return "elevator"
	return "scanner"

func _expand(lines: Array) -> Array:
	var result: Array = []
	for raw in lines:
		if raw[0] != "CONDITIONAL":
			result.append(raw)
			continue
		result.append(StoryData.conditional_line(str(raw[1]), flags))
	return result

func on_locale_changed() -> void:
	if not started:
		hud.set_header(Loc.t("idle.chapter"), Loc.t("idle.place"), Loc.t("idle.clock"), Loc.t("idle.objective"))
		return
	if hud.is_busy():
		return
	var area: Dictionary = StoryData.live()[area_index]
	hud.set_header(area.chapter, area.place, area.clock, area.objective)

func get_case_log_text() -> String:
	var pending := Loc.t("log.pending")
	var lines := PackedStringArray([
		Loc.t("log.objective", [StoryData.live()[area_index].objective]),
		Loc.t("log.decisions"),
		Loc.t("log.eli", [flags.eli_stance if flags.eli_stance else pending]),
		Loc.t("log.compliance", [flags.compliance if flags.compliance else pending]),
		Loc.t("log.route", [flags.escape_route if flags.escape_route else pending]),
		Loc.t("log.contract", [flags.contract if flags.contract else pending]),
		Loc.t("log.evidence", [completed_hotspots.size()])
	])
	for i in range(max(0, discoveries.size() - 8), discoveries.size()):
		lines.append("• " + discoveries[i])
	return "\n".join(lines)

static func simulate_route(route: Dictionary) -> Dictionary:
	var delayed := []
	delayed.append("stair_gate_open" if route.get("eli_stance") == "TRUST" else "eli_phone_compliance")
	delayed.append("ledger_preserved" if route.get("compliance") == "REFUSE" else "permanent_badge")
	delayed.append("replacement_list" if route.get("escape_route") == "STAIRS" else "rusk_keycard")
	return {"ending": StoryData.resolve(route), "delayed": delayed, "areas": StoryData.AREAS.size(), "hotspots": StoryData.total_hotspots()}
