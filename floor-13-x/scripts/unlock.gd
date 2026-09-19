extends Node
class_name Unlock

## Server-delivered uncensored plates, ported from play/overnight-clause/scripts/unlock.gd
## (which is itself room-704's 09_dist.rpy model). Floor 13: Retention shipped with no
## unlock code at all: CgGate.request_unlock() ran the page gate, got "unlocked" back, and
## then drew the same censored plate, because the uncensored bytes are excluded from the
## web packages and nothing ever fetched them. A gate that clears and reveals nothing is
## worse than no gate — the player paid the price and got the locked art.
##
## Two calls against the gateway, the same pair every other fork uses:
##   POST /unlock/start   {"app": "floor-13-x", "key": "<slot>"}  -> {"ok", "ticket", "wait"}
##   GET  /unlock/fetch?ticket=..&app=..&key=..                   -> the image bytes
##
## The ticket is taken when the gate OPENS, so the server's clock starts with the gate and
## not with the redeem; a ticket is single-use. Delivered bytes land in user://unlocked/
## for this install and are what is/loaded afterwards — so "unlocked" means "the real
## bytes are on this machine", never "a boolean was set".
##
## The gateway serves WebP (ops/export_gated.py stages .webp). Godot's Image.load() picks
## its decoder from the extension, so the saved file keeps the .webp extension and is
## decoded explicitly; saving webp bytes as ".png" is a silent, total failure.
##
## Desktop downloads never reach any of this: every entry point returns before touching the
## network when OS.has_feature("web") is false. An Adsterra popunder cost the studio its
## F95 account (memory f95-ban-direct-link-ads) and a download that phones home is the same
## mistake with a different filename.

const API := "https://apps.blazecore.dev"
const APP := "floor-13-x"
const SAVE_DIR := "user://unlocked/"

## Test hook: pretend this build is a free web package even on desktop, so the fetch path
## can be exercised from a headless checkout where the open plates do exist in res://.
static var simulate_free := false

var _ticket := {}
var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


static func saved_path(slot: String) -> String:
	return SAVE_DIR + slot + ".webp"


## True when the real bytes for this slot are available to this install, by any route.
static func delivered(slot: String) -> bool:
	var f := FileAccess.open(saved_path(slot), FileAccess.READ)
	if f == null:
		return false
	var n := f.get_length()
	f.close()
	return n > 1024


## Ask for a ticket. Called when the gate opens, before the player watches anything.
func start(slot: String) -> bool:
	if not _online():
		return false
	if _http == null:
		return false
	var body := JSON.stringify({"app": APP, "key": slot})
	var err := _http.request(API + "/unlock/start", ["Content-Type: application/json"],
		HTTPClient.METHOD_POST, body)
	if err != OK:
		return false
	var res: Array = await _http.request_completed
	if int(res[1]) != 200:
		return false
	var parsed = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	if typeof(parsed) == TYPE_DICTIONARY and parsed.get("ok", false) and parsed.has("ticket"):
		# `wait` is the gateway's minimum dwell: a ticket redeemed before it is refused.
		# That is the server half of "the clip has to actually run", so it is honoured
		# rather than worked around.
		_ticket = {"key": slot, "ticket": str(parsed["ticket"]),
			"ready_at": Time.get_ticks_msec() + int(parsed.get("wait", 0)) * 1000}
		return true
	_ticket = {}
	return false


## Spend the ticket once the gate has completed. Returns true only if bytes actually
## landed AND decode — a gate that "succeeds" without art must not report an unlock.
func redeem(slot: String) -> bool:
	if delivered(slot):
		return true
	if not _online():
		return false
	if str(_ticket.get("key", "")) != slot:
		return false
	# The gate normally takes longer than the dwell, so this usually sleeps for nothing.
	# When it does not — a player who paid on itch and never watched a countdown — waiting
	# here is the difference between a reveal and a silent "unavailable".
	var left := int(_ticket.get("ready_at", 0)) - Time.get_ticks_msec()
	if left > 0:
		await get_tree().create_timer(left / 1000.0 + 0.5, true, false, true).timeout
	var url := "%s/unlock/fetch?ticket=%s&app=%s&key=%s" % [API, _ticket["ticket"], APP, slot]
	_ticket = {}
	var err := _http.request(url)
	if err != OK:
		return false
	var res: Array = await _http.request_completed
	if int(res[1]) == 425:
		# "Too soon": the gateway's dwell had not quite run down. The wait above normally
		# covers it; clocks disagree by a second and that must not cost the reveal.
		await get_tree().create_timer(3.0, true, false, true).timeout
		if _http.request(url) != OK:
			return false
		res = await _http.request_completed
	if int(res[1]) != 200:
		push_warning("unlock: /unlock/fetch for %s returned HTTP %d: %s"
			% [slot, int(res[1]), (res[3] as PackedByteArray).slice(0, 200).get_string_from_utf8()])
		return false
	return write_delivered(slot, res[3] as PackedByteArray)


## Split out so a test can deliver bytes with no network. The write-and-verify half is the
## half that fails silently on a full or read-only user directory.
static func write_delivered(slot: String, data: PackedByteArray) -> bool:
	if data.size() <= 1024:
		return false
	if texture_from_bytes(data) == null:
		return false   # 404 page, HTML error, truncated body: not art, do not claim art
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open(saved_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(data)
	f.close()
	return delivered(slot)


## Decode delivered bytes. The gateway serves WebP; PNG and JPEG are accepted too so a
## re-staged asset in another format does not brick the reveal.
static func texture_from_bytes(data: PackedByteArray) -> Texture2D:
	var img := Image.new()
	if img.load_webp_from_buffer(data) != OK:
		if img.load_png_from_buffer(data) != OK:
			if img.load_jpg_from_buffer(data) != OK:
				return null
	if img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


## The delivered plate as a texture, or null when nothing has been delivered.
static func delivered_texture(slot: String) -> Texture2D:
	if not delivered(slot):
		return null
	var f := FileAccess.open(saved_path(slot), FileAccess.READ)
	if f == null:
		return null
	var data := f.get_buffer(f.get_length())
	f.close()
	return texture_from_bytes(data)


func _online() -> bool:
	return OS.has_feature("web") or simulate_free
