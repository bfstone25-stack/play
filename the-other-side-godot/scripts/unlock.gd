extends Node
class_name Unlock

## Server-gated art, ported from play/room-704/game/scripts/09_dist.rpy:110-140, via play/overnight-clause/scripts/unlock.gd.
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
const APP := "the-other-side"
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


## The gateway serves WEBP (gateway/app.py:304 reads ops/gated_assets/<app>/<key>.webp
## and answers media_type="image/webp"). This used to write those bytes to "<id>.png" and
## load them with Image.load(), which picks its decoder from the file extension — so a
## redeemed ticket landed real bytes on disk and then failed to decode them, and the
## player saw the censored plate after clearing the gate. Verified against the live
## gateway on 2026-09-18: /unlock/fetch returns RIFF....WEBP, 104420 bytes.
##
## The extension is therefore not guessed. Bytes are stored under a neutral name and the
## decoder is chosen from the file's magic number.
static func saved_path(id: String) -> String:
	return SAVE_DIR + id + ".plate"


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
	# The gateway will not spend a ticket less than _MIN_WAIT (18s) after issuing it
	# (gateway/app.py:302) — it answers 425 with the seconds remaining, and a redeem that
	# only accepted 200 could never succeed no matter how the gate behaved. Confirmed
	# live on 2026-09-18: an immediate fetch is 425 {"error":"too soon","wait":17}; the
	# same ticket 20s later is 200 image/webp. A 425 is not a failure, it is a clock.
	for attempt in 4:
		var err := _http.request(url)
		if err != OK:
			return false
		var res: Array = await _http.request_completed
		var code := int(res[1])
		if code == 425:
			var wait := 3.0
			var parsed = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
			if typeof(parsed) == TYPE_DICTIONARY:
				wait = clampf(float(parsed.get("wait", 3)) + 1.0, 1.0, 30.0)
			await Engine.get_main_loop().create_timer(wait, true, false, true).timeout
			continue
		if code != 200:
			return false
		var data: PackedByteArray = res[3]
		if data.size() <= 1024:
			return false
		return write_delivered(id, data)
	return false


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


## Decode a delivered file without trusting its name. PNG, WEBP and JPEG all announce
## themselves in their first bytes; anything else is treated as not delivered rather than
## as a texture, so a gateway error page can never become a "plate".
static func decode_delivered(path: String) -> Texture2D:
	var data := FileAccess.get_file_as_bytes(path)
	if data.size() <= 1024:
		return null
	var img := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	if data.size() > 12 and data[0] == 0x52 and data[1] == 0x49 and data[2] == 0x46 and data[3] == 0x46 \
			and data[8] == 0x57 and data[9] == 0x45 and data[10] == 0x42 and data[11] == 0x50:
		err = img.load_webp_from_buffer(data)
	elif data[0] == 0x89 and data[1] == 0x50:
		err = img.load_png_from_buffer(data)
	elif data[0] == 0xFF and data[1] == 0xD8:
		err = img.load_jpg_from_buffer(data)
	if err != OK or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)
