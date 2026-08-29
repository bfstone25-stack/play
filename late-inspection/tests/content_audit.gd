extends SceneTree

func _init() -> void:
	var flags := {"photo_kept":true, "pipe_answered":true, "clause_signed":true, "clause_refused":false}
	var words := 0
	var pages := 0
	var notes := 0
	var choices := 0
	for stage in 13:
		for item in StoryContent.stage(stage, flags):
			var text: String = item["text"]
			words += text.replace("\n", " ").split(" ", false).size()
			pages += text.split("\n---\n", false).size()
			if item["kind"] == "choice":
				choices += 1
			else:
				notes += 1
	if words < 2200 or pages < 45 or notes < 20 or choices != 4:
		push_error("content budget failed words=%d pages=%d notes=%d choices=%d" % [words,pages,notes,choices])
		quit(1)
		return
	print("CONTENT_AUDIT_OK words=", words, " pages=", pages, " notes=", notes, " choices=", choices)
	quit(0)
