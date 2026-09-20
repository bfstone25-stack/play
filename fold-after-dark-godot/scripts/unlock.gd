extends Node
## Autoloaded as "Unlock" in FOLD: After Dark; the class_name is dropped for that.

## Server-gated art. Ported from play/overnight-clause/scripts/unlock.gd, which is itself a
## port of play/room-704/game/scripts/09_dist.rpy:110-140. Copied rather than reinvented on
## purpose: this is the third product to use the same model and the second Godot one.
##
## The point of the model: the uncensored plates are NOT in the free package at all.
## res://assets/plates_x/ is excluded from both Web presets in export_presets.cfg, so the
## free browser build genuinely has nothing to reveal — editing a save flag, or a URL, or
## the scene tree gets you a censored plate, because that is the only plate in the
## download. tests/pack_audit.gd greps the exported .pck to prove it.
##
## Three tracks, decided at runtime from the same files:
##   paid      desktop download — assets/plates_x/ is in the package; nothing is fetched,
##             nothing is called. A download makes no network request of any kind.
##   web       browser build — censored plates ship; the real bytes come from the gateway
##             against a single-use ticket and land in user://unlocked/ for this install.
##   demo      the free browser slice ends at the cut point before the third appraisal.

const API := "https://apps.blazecore.dev"
## Per scene, not per game: the pool is two parents' worth of plates, and each is fetched
## under the app that owns it (Tier.scene_app). Nothing is renamed on the server.
const APP := "fold-after-dark"
const PAID_DIR := "res://assets/plates_x/"
const SAVE_DIR := "user://unlocked/"

## Test hook: pretend this package is a free web build (no assets/plates_x/), so the gate
## path can be exercised from a desktop checkout where those files do exist.
static var simulate_free := false

## Test hook: let a desktop build make the two requests a browser would, so the reveal can
## be exercised against the live gateway from a headless run. tests/unlock_live.gd is the
## only thing that sets it. It cannot make a shipped download talk to the network — nothing
## in the game ever assigns it — and the point of it is that the thing under test is this
## file, not a re-implementation of it in curl.
static var allow_network := false


static func _networked() -> bool:
	return OS.has_feature("web") or allow_network

var _ticket := {}
var last_status := 0
var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


## True when this build carries the uncensored plates in its own package: the paid desktop
## download. Never true on web — the files are export-excluded there.
static func paid_package(id: String) -> bool:
	if simulate_free:
		return false
	return ResourceLoader.exists(PAID_DIR + id + ".webp") or FileAccess.file_exists(PAID_DIR + id + ".webp")


## The gateway serves image/webp (gateway/app.py:309 — the bytes on disk are
## ops/gated_assets/<app>/<key>.webp), and Godot picks its image decoder from the file
## extension. Writing those bytes to "<id>.png", which is what this did until a live fetch
## was actually run against apps.blazecore.dev, produces a file that is over the
## 1024-byte "it arrived" threshold and cannot be decoded by anything: ready_for() says
## yes, the fee is not refunded, and the player gets a blank. So the extension is decided
## by the bytes.
const EXTS := ["webp", "png", "jpg"]


static func ext_of(data: PackedByteArray) -> String:
	if data.size() >= 12 and data[0] == 0x52 and data[1] == 0x49 and data[2] == 0x46 and data[3] == 0x46 \
			and data[8] == 0x57 and data[9] == 0x45 and data[10] == 0x42 and data[11] == 0x50:
		return "webp"
	if data.size() >= 4 and data[0] == 0x89 and data[1] == 0x50 and data[2] == 0x4E and data[3] == 0x47:
		return "png"
	if data.size() >= 3 and data[0] == 0xFF and data[1] == 0xD8 and data[2] == 0xFF:
		return "jpg"
	return ""


## The delivered file for `id`, whatever it was encoded as, or "" if nothing landed.
static func saved_path(id: String) -> String:
	for ext in EXTS:
		var path := "%s%s.%s" % [SAVE_DIR, id, ext]
		if FileAccess.file_exists(path):
			return path
	return ""


## Remove every delivered encoding of `id`. Used by the tests and before a re-delivery.
static func clear(id: String) -> void:
	for ext in EXTS:
		DirAccess.remove_absolute("%s%s.%s" % [SAVE_DIR, id, ext])


## True when the real bytes are available to this install, by either route.
static func ready_for(id: String) -> bool:
	if paid_package(id):
		return true
	var path := saved_path(id)
	if path == "":
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var n := f.get_length()
	f.close()
	return n > 1024


## Ask for a ticket when the gate opens, so the server clock starts with the gate and not
## with the redeem. Desktop downloads never reach here.
func start(id: String) -> bool:
	if not _networked():
		return false
	var body := JSON.stringify({"app": Tier.scene_app(id), "key": Tier.scene_key(id)})
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


## Spend the ticket once the gate completes. Returns true if the art actually landed — a
## gate that "succeeds" without bytes must not report an unlock, because the refund rule
## reads this answer and hands the shop fee back when it is false.
func redeem(id: String) -> bool:
	if ready_for(id):
		return true
	if not _networked():
		return false
	if str(_ticket.get("key", "")) != id:
		return false
	var url := "%s/unlock/fetch?ticket=%s&app=%s&key=%s" % [API, _ticket["ticket"], Tier.scene_app(id), Tier.scene_key(id)]
	var err := _http.request(url)
	if err != OK:
		return false
	var res: Array = await _http.request_completed
	last_status = int(res[1])
	if int(res[1]) != 200:
		return false
	var data: PackedByteArray = res[3]
	if data.size() <= 1024:
		return false
	return write_delivered(id, data)


## Split out so the tests can deliver bytes without a network: the write-and-verify half is
## the half that can silently fail on a read-only or full user dir.
static func write_delivered(id: String, data: PackedByteArray) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var ext := ext_of(data)
	if ext == "":
		# Not an image at all — an error page, a truncated body, a captive portal. Landing
		# it on disk would make ready_for() lie and cost the player their reading fee.
		return false
	clear(id)
	var f := FileAccess.open("%s%s.%s" % [SAVE_DIR, id, ext], FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(data)
	f.close()
	# Decoding it here is the difference between "bytes arrived" and "there is a picture".
	# The refund rule reads this answer.
	if not ready_for(id):
		return false
	var img := Image.new()
	if img.load(saved_path(id)) != OK or img.get_width() < 16:
		clear(id)
		return false
	return true


## Where the plate layer should load a gated plate from, or "" when it must fall back to
## the censored one.
static func source_for(id: String) -> String:
	if paid_package(id):
		return PAID_DIR + id + ".webp"
	if ready_for(id):
		return saved_path(id)
	return ""
