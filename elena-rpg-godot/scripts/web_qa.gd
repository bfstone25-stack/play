## Web-only QA hook for the free edition's live acceptance test: setting
## `window.__elenaWarp = "night2"` from the page jumps to the start of that night through the
## real start_night() path, so the night-boundary sponsor gate can be reached without playing
## 40 minutes. Inert off the web (the DLsite download returns in _ready). It only skips story;
## it unlocks nothing the free edition does not already give, and still goes through the gate.
extends Node


func _ready() -> void:
	if not OS.has_feature("web"):
		set_process(false)
		return
	while true:
		await get_tree().create_timer(1.0, true).timeout
		var w := str(JavaScriptBridge.eval("(typeof window.__elenaWarp === 'string') ? window.__elenaWarp : ''"))
		if w == "" or not RPG.nights.has(w):
			continue
		JavaScriptBridge.eval("window.__elenaWarp = ''; 0")
		var main = get_tree().root.find_child("Main", true, false)
		if main == null or not main.has_method("start_night"):
			continue
		if RPG.s.is_empty() or not RPG.s.has("night"):
			RPG.new_game()
		main._clear_overlay()
		main.start_night(w)
