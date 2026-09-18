extends SceneTree

func _init() -> void:
	var flags := {"photo_kept":true, "pipe_answered":true, "clause_signed":true, "clause_refused":false}
	var words := 0
	var pages := 0
	var notes := 0
	var choices := 0
	for stage in 13:
		for item in Overnight.stage(stage, flags):
			var text: String = item["text"]
			if item["kind"] == "note":
				text += Overnight.commentary(item["id"])
			words += text.replace("\n", " ").split(" ", false).size()
			pages += text.split("\n---\n", false).size()
			if item["kind"] == "choice":
				choices += 1
			else:
				notes += 1
	# 170 wpm reading + actual page handling, inspection, and choice input.
	# Traversal is deliberately excluded so this cannot pass by adding idle time.
	var expected_seconds := int(float(words) / 170.0 * 60.0) + pages * 4 + notes * 5 + choices * 15
	var fork := _fork_words()
	# One route's worth, which is what a player actually reads: the Witness run, where
	# both adult scenes are reachable. The all-scenes figure above counts every branch.
	var fork_route := _fork_words_on(["ch2_dane", "ch3_mirror", "ch4_hatch", "ch5_cavity", "ch6_403", "ch7_witness"])
	var total := words + fork_route
	# Overnight Clause runs 40-50 minutes; the base episode's 25-35 is the floor it is
	# built on, so the ceiling moves with the new writing rather than staying at 2100.
	var total_seconds := int(float(total) / 170.0 * 60.0) + pages * 4 + notes * 5 + choices * 15
	if words < 2900 or pages < 80 or notes < 20 or choices != 4 or expected_seconds < 1500:
		push_error("base content budget failed words=%d pages=%d notes=%d choices=%d seconds=%d" % [words,pages,notes,choices,expected_seconds])
		quit(1)
		return
	if fork < 5000:
		push_error("fork writing under budget: %d new words, design says ~5,600" % fork)
		quit(1)
		return
	if total_seconds < 2400 or total_seconds > 3600:
		push_error("fork run time out of the 40-50 minute band: %d seconds" % total_seconds)
		quit(1)
		return
	print("CONTENT_AUDIT_OK base_words=", words, " fork_words_all=", fork, " fork_words_witness_route=", fork_route, " total=", total,
		" pages=", pages, " notes=", notes, " choices=", choices, " total_seconds=", total_seconds)
	quit(0)


# The fork's new writing, audited separately from the base episode: the design budgeted
# ~5,600 words of English master and explicitly launches English-only, because carrying
# five locales through it turns a three-week fork into a three-month one.
func _fork_words() -> int:
	return _fork_words_on(OvernightScript.ids())


func _fork_words_on(ids) -> int:
	var total := 0
	for id in ids:
		total += OvernightScript.scene(str(id)).replace("\n", " ").split(" ", false).size()
	return total
