## Symbols — the one glyph fallback. The three OFL faces (Lilita One, Nunito, Playfair
## Display Italic) are Latin and carry none of ♥ ◆ ⚡ ★ ◈ ✕, and a web export has no
## system font to fall through to; DejaVu Sans Bold stays bundled for those six glyphs
## only and is attached as a fallback to the three FontFiles at boot. It lives here and
## not in studio_theme.gd because that file is shared verbatim with
## play/overtime-idle-godot, which draws no symbol glyphs at all.
class_name Symbols

const FONT := "res://assets/fonts/fallback_symbols.ttf"


static func install() -> void:
	var fb: Font = load(FONT)
	if fb == null:
		return
	for path in [StudioTheme.FONT_DISPLAY, StudioTheme.FONT_UI, StudioTheme.FONT_ITALIC]:
		var f: Font = load(path)
		if f is FontFile and (f as FontFile).fallbacks.is_empty():
			(f as FontFile).fallbacks = [fb]
