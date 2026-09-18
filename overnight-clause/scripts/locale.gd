class_name Loc
extends Object

const SETTINGS_PATH := "user://settings.cfg"
const ALLOWED := ["en"]
const NATIVE := {
	"en": "English",
}

static var code: String = ""
static var _hooks: Array[Callable] = []

static func current() -> String:
	if code == "":
		_load()
	return code


static func is_zh() -> bool:
	return current() == "zh"


static func set_code(next: String) -> void:
	if next not in ALLOWED:
		next = "en"
	if code == next:
		for hook in _hooks:
			if hook.is_valid():
				hook.call()
		return
	code = next
	_save()
	for hook in _hooks:
		if hook.is_valid():
			hook.call()


static func on_change(cb: Callable) -> void:
	_hooks.append(cb)


static func table() -> Dictionary:
	return EN



static func t(key: String, args: Array = []) -> String:
	var text := str(table().get(key, EN.get(key, key)))
	if args.is_empty():
		return text
	return text % args


static func _load() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--locale="):
			var forced := arg.trim_prefix("--locale=")
			code = forced if forced in ALLOWED else "en"
			return
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var saved := str(cfg.get_value("locale", "code", ""))
		if saved in ALLOWED:
			code = saved
			return
	code = _os_default()


static func _os_default() -> String:
	var lang := OS.get_locale_language().to_lower()
	if lang in ALLOWED:
		return lang
	if lang.begins_with("zh"):
		return "zh"
	return "en"


static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("locale", "code", current())
	cfg.save(SETTINGS_PATH)


const EN := {
	"lang.caption": "Language",
	"splash.title": "Late Inspection: Flat 404",
	"splash.hint": "Click to enter  ·  WASD  mouse  E interact  Esc",
	"splash.start": "ENTER THE BUILDING",
	"pause.title": "INSPECTION PAUSED\nEsc resumes · Mouse recaptures on return",
	"pause.resume": "RESUME INSPECTION",
	"pause.restart": "RESTART FROM ARRIVAL",
	"doc.continue": "CONTINUE  ›",
	"doc.close": "CLOSE",
	"doc.page": "PAGE %d / %d",
	"vn.advance": "E / click",
	"vn.choose": "A / B",
	"vn.pressure": "PRESSURE",
	"spk.mara": "MARA",
	"spk.iris": "IRIS",
	"spk.dane": "DANE",
	"spk.pell": "PELL",
	"spk.harrow": "HARROW",
	"spk.inner": "INNER",
	"spk.system": "SYSTEM",
	"btn.continue": "CONTINUE",
	"btn.credits": "CREDITS",
	"btn.restart": "RESTART",
	"ending.thanks": "OVERNIGHT CLAUSE\n\nThank you for witnessing.\n\nPress R to restart the inspection.",
	"evidence": "EVIDENCE %02d / 23",
	"prompt.prefix": "E / click  ",
	"title.card": "OVERNIGHT CLAUSE\nVesper Court, 01:47",
	"zone.6": "FLAT 403",
	"gallery.title": "PLATES",
	"gallery.hint": "G closes the gallery. Seven plates; five open in every build.",
	"gallery.unseen": "not reached",
	"gallery.seen": "seen",
	"gallery.locked": "seen — censored in this build",
	"gallery.locked_hint": "This plate is censored in this package. The uncensored file is not in the download at all; it arrives from the unlock, or it ships in the paid build.",
	"gallery.missing": "No plate file in this build yet.",
	"splash.adult": "18+. Everyone depicted is an adult. Artwork is AI-assisted, directed and culled by hand; the writing is human, every line.",
	"ch.0": "CHAPTER I — AFTER HOURS",
	"ch.1": "CHAPTER II — PREMISES SURRENDERED",
	"ch.2": "CHAPTER III — STILL HERE",
	"ch.3": "CHAPTER IV — THE PIPE SPEAKS",
	"ch.4": "CHAPTER V — ONE MINUTE",
	"ch.5": "CHAPTER VI — TEMPORARY CUSTODIAN",
	"ch.6": "CHAPTER VII — THE FINAL KNOCK",
	"obj.0": "Read the after-hours inspection order in the lift lobby.",
	"obj.order": "Find Flat 404. Read the notice taped over its number.",
	"obj.dane": "Read the access notice on Flat 404.",
	"obj.notice": "Enter 404 and inspect the checklist in the living room.",
	"obj.checklist": "Search the living room. Play the answering machine when ready.",
	"obj.answering": "Investigate the kitchen and document the damp wall.",
	"obj.stain": "Follow the wet line into the bathroom. Read the service tag.",
	"obj.service": "The pipe is waiting. Answer it or close the valve.",
	"obj.pipe": "Wet footprints lead to the bedroom. Search before opening the wardrobe.",
	"obj.wardrobe": "Play the cassette hidden inside the wall cavity.",
	"obj.cassette": "Return to the living room. Pell is calling.",
	"obj.followup": "Read the overnight clause on the coffee table.",
	"obj.clause": "Inspect the changed key and look through the peephole.",
	"obj.final": "The final knock is waiting at the front door.",
	"note.stain_keep": "MARA: Evidence first. Pell can explain the impossible part.\nThe letters IRIS VALE remain visible inside the damp.",
	"note.stain_wipe": "MARA: A reflection. Bad compression. Finish the job.\nThe letters smear into a five-fingered handprint.",
	"note.pipe_yes": "MARA knocks three times.\nIRIS, through copper: Bedroom. Behind the coats. Record me.\nDANE: You heard her. Don't let Pell make it maintenance.",
	"note.pipe_no": "The valve resists like a held wrist, then turns.\nPELL: Good. A quiet building is a safe building.",
	"note.clause_yes": "MARA VENN. Temporary. Until morning.\nInk crawls from your signature toward the printed word 'contents.'",
	"note.clause_no": "MARA: No. This inspection is suspended.\nBoth torn halves now read UNIT 404: NOT FOUND.",
	"end.witness": "ENDING — WITNESS",
	"end.complicit": "ENDING — COMPLICIT",
	"end.404": "ERROR 404 — INSPECTOR NOT FOUND",
	"title.slice": "FREE BROWSER SLICE — THROUGH THE KITCHEN WALL",
	"slice.end": "FREE SLICE — INSPECTION SUSPENDED",
	"slice.beat.0": "MARA: The checklist is real. The flat is not vacant. Something answers from inside the walls.",
	"slice.beat.1": "The full inspection continues: the pipe that knocks three times and the man who comes through the wall when you answer it, the bedroom wardrobe, the overnight clause — and the final knock at 02:29.",
	"slice.beat.2": "Seven chapters. Three endings. Your choices decide whether Iris Vale is witnessed, replaced, or erased.",
	"slice.thanks": "OVERNIGHT CLAUSE — FREE SLICE\n\nThe full inspection waits in the complete edition below.\n\nPress R to walk the corridor again.",
	"beat.witness.0": "The door opens onto the service cavity. Iris stands behind translucent pipework, one hand against the wall.",
	"beat.witness.1": "MARA: Iris Vale occupied this flat. I heard her. I recorded her. I am not certifying it vacant.\nIRIS: Then look at me.",
	"beat.witness.2": "Door 404 bears IRIS VALE. Dawn reaches the corridor.\nDANE: Did she come out?\nMARA: Her name did.",
	"beat.witness.3": "Vesper Court received seventeen inspection requests that morning.\nFlat 404 was never listed as vacant again.",
	"beat.complicit.0": "You turn off the standing lamp. The knocking stops halfway through a strike.",
	"beat.complicit.1": "Daylight. The flat is immaculate. Family photographs now show you with your face turned away.\nPELL: Inspection accepted. Your renewal begins today.",
	"beat.complicit.2": "OCCUPANT: MARA VENN\nMOVE-OUT INSPECTOR: [awaiting arrival]\nPlease keep the pipe quiet for the next guest.",
	"beat.complicit.3": "A new inspector's key enters from the corridor.\nYou made the building quiet. The building made you easy to replace.",
	"beat.404.0": "Every fourth-floor door now reads 403. Your key passes through the wall where 404 stood.",
	"beat.404.1": "MARA: I was inside. Kitchen, bath, bedroom—\nOPERATOR: Vesper Court has no fourth unit on any floor.",
	"beat.404.2": "Your inventory erases itself: cassette, photograph, clause, then MARA VENN.\nIRIS: A witness who will not choose is only another missing room.",
	"beat.404.3": "The lift opens on a brick wall.\nThe next appointment is at 01:47. Please bring identification.",
	"zone.0": "LIFT LOBBY",
	"zone.1": "FOURTH-FLOOR CORRIDOR",
	"zone.2": "LIVING ROOM",
	"zone.3": "KITCHEN",
	"zone.4": "BATHROOM",
	"zone.5": "BEDROOM",
	"world.tonight": "TONIGHT",
	"world.iris": "IRIS VALE",
}




