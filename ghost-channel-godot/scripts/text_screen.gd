## HOW TO PLAY and CREDITS — the two reading screens, off one script.
##
## Set behind a glass panel over the station rather than on a flat ground, because the room
## should not disappear when the player opens the rules: the console is still lit, the rain
## is still on the glass, and the page is a clipboard held up in front of it.
extends Control

var main: Control
var page := "how"

var _title: Label
var _body: RichTextLabel
var _back: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glass := PanelContainer.new()
	glass.theme_type_variation = "Glass"
	glass.position = Vector2(84, 92)
	glass.custom_minimum_size = Vector2(760, 520)
	add_child(glass)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	glass.add_child(col)

	_title = StudioTheme.display_label("", 34, Palette.TEXT)
	col.add_child(_title)

	var rule := ColorRect.new()
	rule.color = Color(Palette.ACCENT, 0.5)
	rule.custom_minimum_size = Vector2(0, 2)
	col.add_child(rule)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(720, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.custom_minimum_size = Vector2(716, 0)
	scroll.add_child(_body)

	_back = Button.new()
	_back.theme_type_variation = "Ghost"
	_back.custom_minimum_size = Vector2(150, 0)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back.pressed.connect(func():
		Sfx.click()
		main.show_screen("title"))
	col.add_child(_back)
	relocalise()


func on_show() -> void:
	relocalise()


func relocalise() -> void:
	_back.text = Game.t("back")
	if page == "how":
		_title.text = Game.t("howTitle")
		_body.text = _how()
	else:
		_title.text = Game.t("credTitle")
		_body.text = _credits()


func _key(k: String, color: Color) -> String:
	return "[b][color=#%s]%s[/color][/b]" % [color.to_html(false), Game.t(k)]


## Drop a leading ALL-CAPS Latin verb, and nothing else: the zh strings do not have one
## and must come back untouched.
func _trim_verb(s: String) -> String:
	var first := s.split(" ")[0].trim_suffix(".").trim_suffix(",")
	if first.length() >= 4 and first == first.to_upper() and first.to_lower() != first:
		return s.substr(s.find(" ") + 1)
	return s


func _how() -> String:
	var lines := [
		Game.t("how1"),
		"",
		# the prototype's howA/howD/howQ each open by repeating the verb the key already
		# says ("AUTHORIZE fire, extract, ..."), which reads as a stutter once the key is
		# set beside it. The first word goes.
		"%s  %s" % [_key("auth", Palette.ACCENT), _trim_verb(Game.t("howA"))],
		"%s  %s" % [_key("deny", Palette.HEAT), _trim_verb(Game.t("howD"))],
		"%s  %s" % [_key("q", Palette.GOLD), _trim_verb(Game.t("howQ"))],
		"",
		Game.t("howMap"),
		"",
		"[b]" + Game.t("howWin") + "[/b]",
		"",
		"[color=#%s]%s[/color]" % [Palette.MUTED.to_html(false), Game.t("hint")],
	]
	return "\n".join(lines)


func _credits() -> String:
	var voiced: Array = Voice.have()
	var voice_line := Game.t("voiceNote") if not voiced.is_empty() else Game.t("noVoiceNote")
	var lines := [
		"[b]" + Game.t("cred1") + "[/b]",
		Game.t("cred2"),
		"",
		Game.t("cred4"),
		"",
		# The prototype's cred3 claimed "no generative image or audio models", which was
		# true of the Canvas build and is emphatically not true of this one. Saying so is
		# not optional: it is what several of the channels this ships through require, and
		# the ULMF post carries the AI Generated prefix for the same reason.
		"[color=#%s]%s[/color]" % [Palette.MUTED.to_html(false),
			"Art: SDXL (Animagine XL 4.0) through the studio's render queue. " + voice_line],
		"",
		"[color=#%s]%s[/color]" % [Palette.DIM.to_html(false),
			"Godot 4.7 · Fira Sans (SIL OFL) · Droid Sans Fallback (Apache 2.0) · " + Game.t("rating")],
	]
	return "\n".join(lines)
