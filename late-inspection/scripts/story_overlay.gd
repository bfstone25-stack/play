extends RefCounted
class_name StoryOverlay

static func apply(s: int, flags: Dictionary, texts: Dictionary) -> Array[Dictionary]:
	var items := StoryContent.stage(s, flags)
	var localized: Array[Dictionary] = []
	for item in items:
		var copy: Dictionary = item.duplicate(true)
		var key := str(item["id"])
		if key == "followup":
			key = "followup_yes" if bool(flags["photo_kept"]) or bool(flags["pipe_answered"]) else "followup_no"
		elif key == "final_evidence":
			key = "final_signed" if bool(flags["clause_signed"]) else "final_refused"
		var loc: Dictionary = texts.get(key, {})
		if loc.has("prompt"):
			copy["prompt"] = loc["prompt"]
		if loc.has("text"):
			copy["text"] = loc["text"]
		if loc.has("a"):
			copy["a"] = loc["a"]
			copy["b"] = loc["b"]
		localized.append(copy)
	return localized
