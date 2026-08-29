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
			if item["kind"] == "note":
				text += StoryContent.commentary(item["id"])
			words += text.replace("\n", " ").split(" ", false).size()
			pages += text.split("\n---\n", false).size()
			if item["kind"] == "choice":
				choices += 1
			else:
				notes += 1
	# 170 wpm reading + four seconds/page handling + five seconds/inspection +
	# four minutes of measured traversal/composition. This excludes pause/idling.
	var expected_seconds := int(float(words) / 170.0 * 60.0) + pages * 4 + notes * 5 + choices * 15 + 240
	if words < 2900 or pages < 80 or notes < 20 or choices != 4 or expected_seconds < 1500 or expected_seconds > 2100:
		push_error("content budget failed words=%d pages=%d notes=%d choices=%d seconds=%d" % [words,pages,notes,choices,expected_seconds])
		quit(1)
		return
	print("CONTENT_AUDIT_OK words=", words, " pages=", pages, " notes=", notes, " choices=", choices, " expected_seconds=", expected_seconds)
	quit(0)
