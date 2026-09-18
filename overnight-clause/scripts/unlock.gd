extends Node
class_name Unlock

## Server-gated art, ported from play/room-704/game/scripts/09_dist.rpy:110-140.
##
## The point of the model, and the reason it is copied rather than reinvented: the
## uncensored plates are NOT in the free package at all. res://assets/plates_x/ is
## excluded from both Web presets in export_presets.cfg, so the free browser build
## genuinely has nothing to reveal — editing a save flag, or a URL, or the scene tree
## gets you a censored plate, because that is the only plate in the download.
##
## Three tracks, decided at runtime from the same files:
##   paid      desktop download — assets/plates_x/ is in the package; nothing is fetched,
##             nothing is called. A download makes no network request of any kind.
##   web       browser build — censored plates ship; the real bytes come from the gateway
##             against a single-use ticket and land in user://unlocked/ for this install.
##   slice     the free browser slice ends before the first gated plate anyway.

const API := "https://apps.blazecore.dev"
const APP := "overnight-clause"
const PAID_DIR := "res://assets/plates_x/"
const SAVE_DIR := "user://unlocked/"

## Test hook: pretend this package is a free web build (no assets/plates_x/), so the
## gate path can be exercised from a desktop checkout where those files do exist.
static var simulate_free := false

var _ticket := {}
var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


## True when this build carries the uncensored plates in its own package: the paid
## desktop download. Never true on web — the files are export-excluded there.
static func paid_package(id: String) -> bool:
	if simulate_free:
		return false
	return ResourceLoader.exists(PAID_DIR + id + ".png") or FileAccess.file_exists(PAID_DIR + id + ".png")


static func saved_path(id: String) -> String:
	return SAVE_DIR + id + ".png"


## True when the real bytes are available to this install, by either route.
static func ready_for(id: String) -> bool:
	if paid_package(id):
		return true
	var f := FileAccess.open(saved_path(id), FileAccess.READ)
	if f == null:
		return false
	var n := f.get_length()
	f.close()
	return n > 1024


## Ask for a ticket when the gate opens, so the server clock starts with the gate and
## not with the redeem. Desktop downloads never reach here.
func start(id: String) -> bool:
	if not OS.has_feature("web"):
		return false
	var body := JSON.stringify({"app": APP, "key": id})
	var err := _http.request(API + "/unlock/start", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		return false
	var res: Array = await _http.request_completed
	if int(res[1]) != 200:
		return false
	var parsed = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	if typeof(parsed) == TYPE_DICTIONARY and parsed.get("ok", false) and parsed.has("ticket"):
		_ticket = {"key": id, "ticket": str(parsed["ticket"])}
		return true
	_ticket = {}
	return false


## Spend the ticket once the gate completes. Returns true if the art actually landed —
## a gate that "succeeds" without bytes must not report an unlock.
func redeem(id: String) -> bool:
	if ready_for(id):
		return true
	if not OS.has_feature("web"):
		return false
	if _ticket.get("key", "") != id:
		return false
	var url := "%s/unlock/fetch?ticket=%s&app=%s&key=%s" % [API, _ticket["ticket"], APP, id]
	var err := _http.request(url)
	if err != OK:
		return false
	var res: Array = await _http.request_completed
	if int(res[1]) != 200:
		return false
	var data: PackedByteArray = res[3]
	if data.size() <= 1024:
		return false
	return write_delivered(id, data)


## Split out so the tests can deliver bytes without a network: the write-and-verify half
## is the half that can silently fail on a read-only or full user dir.
static func write_delivered(id: String, data: PackedByteArray) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open(saved_path(id), FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(data)
	f.close()
	return ready_for(id)


## Where the plate layer should load a gated plate from, or "" when it must fall back
## to the censored one.
static func source_for(id: String) -> String:
	if paid_package(id):
		return PAID_DIR + id + ".png"
	if ready_for(id):
		return saved_path(id)
	return ""
