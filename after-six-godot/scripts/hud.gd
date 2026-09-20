## HUD — the strip across the top of a day: HP, XP, level, the clock, the rant pattern,
## and the boss bar. Owns no numbers; reads the run.
extends Control

var run: Dictionary = {}
var clock := 0.0


func _process(dt: float) -> void:
	clock += dt
	queue_redraw()


func _draw() -> void:
	if run.is_empty():
		return
	var w := size.x
	draw_rect(Rect2(0, 0, w, 54), Color(Palette.GROUND_DEEP, 0.82))
	draw_rect(Rect2(0, 54, w, 1), Color(Palette.TUBE, 0.25))
	var bold := StudioTheme.font("bold")
	var disp := StudioTheme.font("display")
	# HP
	var hp_frac: float = clampf(run["hp"] / run["maxHp"], 0.0, 1.0)
	Sprites.rrect(self, Rect2(12, 10, 236, 13), Color("3A1A22"), 4)
	if hp_frac > 0:
		Sprites.rrect(self, Rect2(12, 10, 236 * hp_frac, 13), Palette.ACCENT if hp_frac > 0.3 else Palette.HEAT, 4)
	draw_string(bold, Vector2(16, 20), "%d / %d" % [ceil(run["hp"]), run["maxHp"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.9))
	# XP
	var xp_frac: float = clampf(float(run["xp"]) / BMCore.xp_needed(run["level"]), 0.0, 1.0)
	Sprites.rrect(self, Rect2(12, 27, 236, 6), Color("2A2410"), 3)
	if xp_frac > 0:
		Sprites.rrect(self, Rect2(12, 27, 236 * xp_frac, 6), Palette.GOLD, 3)
	draw_string(disp, Vector2(258, 24), "LV %d" % run["level"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.GOLD)
	var left: int = maxi(0, int(ceil(run["day"]["dur"] - run["t"])))
	var right := BMStrings.t("boss") if run["phase"] == "boss" else BMStrings.t("left", {"s": left})
	draw_string(bold, Vector2(258, 40), right, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.MUTED if run["phase"] != "boss" else Palette.ACCENT_SOFT)
	if run["day"]["mode"] == "rant":
		var pat: String = str(run["lastPattern"]).to_upper() + "  x%d" % run["rantCombo"].size()
		var tw := disp.get_string_size(pat, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(disp, Vector2(w - 12 - tw, 24), pat, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.ACCENT)
	var kills := BMStrings.t("kills", {"n": run["kills"]})
	var kw := bold.get_string_size(kills, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(bold, Vector2(w - 12 - kw, 40), kills, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Palette.MUTED)
	if run["boss"] != null:
		var b: Dictionary = run["boss"]
		var frac: float = clampf(b["hp"] / b["maxHp"], 0.0, 1.0)
		Sprites.rrect(self, Rect2(12, 44, w - 24, 7), Color("2A1A22"), 3)
		Sprites.rrect(self, Rect2(12, 44, (w - 24) * frac, 7), Palette.HEAT, 3)
		var name := BMStrings.t("boss_" + run["day"]["boss"])
		var nw := disp.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string_outline(disp, Vector2(w / 2 - nw / 2, 66), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Palette.GROUND_DEEP)
		draw_string(disp, Vector2(w / 2 - nw / 2, 66), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.TEXT)
