class_name Archive
## The memory archive (PORT_PLAN.md step 6): chapter rewards and endings the player has
## earned, one file per edition, the same {rewards:[], endings:[]} shape index.html keeps in
## localStorage under flutter_archive_<edition>.


static func _path() -> String:
	return "user://archive_%s.json" % Edition.current


static func load_all() -> Dictionary:
	var f := FileAccess.open(_path(), FileAccess.READ)
	if f == null:
		return {"rewards": [], "endings": []}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {"rewards": [], "endings": []}


## kind is "reward" or "ending"; an item already collected (same title) is not added twice.
static func collect(kind: String, item: Dictionary) -> void:
	var d := load_all()
	var key := "rewards" if kind == "reward" else "endings"
	var list: Array = d.get(key, [])
	for x in list:
		if x is Dictionary and str(x.get("title", "")) == str(item.get("title", "")):
			return
	var entry := item.duplicate()
	entry["at"] = Time.get_datetime_string_from_system()
	list.append(entry)
	d[key] = list
	var f := FileAccess.open(_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
