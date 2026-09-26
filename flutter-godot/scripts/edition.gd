extends Node
## Edition autoload — PORT_PLAN.md step 3. The five Flutter editions (en, es, pt-BR, zh,
## ja), each its own cast and its own voice, read from assets/editions.json. That file is
## generated from the web build's own source by tools/extract_editions.js, so there is one
## copy of every string and palette: never edit the JSON by hand, re-run the extractor.

signal changed(id: String)

const DATA := "res://assets/editions.json"
const SETTINGS := "user://settings.cfg"

var order: Array = []
var editions: Dictionary = {}
var current := "en"


func _ready() -> void:
	var f := FileAccess.open(DATA, FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			order = d.get("order", [])
			editions = d.get("editions", {})
	var cfg := ConfigFile.new()
	var saved := ""
	if cfg.load(SETTINGS) == OK:
		saved = str(cfg.get_value("edition", "id", ""))
	current = normalize(saved if saved != "" else OS.get_locale())
	for a in OS.get_cmdline_user_args():   # QA: --edition=zh (engine shots on the GPU box)
		if a.begins_with("--edition="):
			current = normalize(a.substr(10))


## Same rules as editions.js normalize(): exact id, then the aliases, then the base tag.
func normalize(value: String) -> String:
	var raw := value.strip_edges().replace("_", "-")
	if editions.has(raw):
		return raw
	var low := raw.to_lower()
	var aliases := {"pt": "pt-BR", "pt-br": "pt-BR", "zh-cn": "zh", "zh-hans": "zh"}
	if aliases.has(low):
		return aliases[low]
	var base := low.split("-")[0]
	if aliases.has(base):
		return aliases[base]
	return base if editions.has(base) else "en"


func set_edition(id: String) -> void:
	current = normalize(id)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("edition", "id", current)
	cfg.save(SETTINGS)
	changed.emit(current)


## en -> es -> pt-BR -> zh -> ja -> en, the order the web build's switch walks.
func cycle() -> void:
	if order.is_empty():
		return
	set_edition(order[(order.find(current) + 1) % order.size()])


func data() -> Dictionary:
	return editions.get(current, editions.get("en", {}))


## The lang the backend's /routes and /say_stream expect (pt-BR's content set is "pt").
func content_set() -> String:
	return str(data().get("contentSet", "en"))


func label() -> String:
	return str(data().get("label", "EN"))


func ui(key: String, fallback := "") -> String:
	var u: Dictionary = data().get("ui", {})
	return str(u.get(key, fallback))
