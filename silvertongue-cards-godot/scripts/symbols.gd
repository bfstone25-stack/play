## Symbols — the glyph fallback stack for the three Latin faces.
##
## Two separate jobs, both of them "this font does not have that character, and a font that
## does not have a character draws a blank box and reports nothing":
##
##   1. **The six UI symbols.** Lilita One, Nunito and Playfair Display Italic are Latin
##      and carry none of ♥ ◆ ⚡ ★ ◈ ✕, and a web export has no system font to fall
##      through to. DejaVu Sans Bold stays bundled for those six glyphs only.
##
##   2. **CJK.** Added 2026-09-21 with ja, and it turns out zh and zh-Hant needed it all
##      along: this game has offered 简体中文 and 繁體中文 in its language picker since it
##      shipped, with three Latin faces and no CJK face anywhere in the package. Every
##      Chinese string in it has been drawing as empty boxes on the web export. Nothing
##      failed, nothing logged, and the picker looked finished.
##
## Why fallbacks rather than play/across-the-hall's per-label `Cjk.apply_label()`: this
## game routes everything through `StudioTheme` and several hundred
## `add_theme_font_override` calls, so a per-call-site approach would have to reach all of
## them and would miss the next one someone writes. A fallback on the FontFile is set once
## and applies to every label that face ever draws, including the ones added later.
##
## THE TWO RULES, both of them paid for by other games in this studio:
##
##   * **Hold the resources.** A FontFile loaded and dropped is freed, and the web export
##     then draws in the engine default with no error at all — memory note
##     `godot-web-font-fallback`. `_kept` is what keeps them alive for the life of the run.
##   * **load(), never preload().** A language whose subset is missing from a build should
##     cost that language its glyphs, not refuse to compile the script and take the whole
##     game with it.
##
## The subsets are built by tools/font_pack.py from BOTH scripts/loc.gd and the offline
## data package, so the scenario prose and her 225 reply lines are inside the font and not
## just the 39 chrome keys. Re-run it after either changes.
class_name Symbols

const FONT := "res://assets/fonts/fallback_symbols.ttf"
const CJK_DIR := "res://assets/fonts/"
const CJK := {
	"zh": "NotoSansCJKsc-subset.ttf",
	"zh-Hant": "NotoSansCJKtc-subset.ttf",
	"ja": "NotoSansCJKjp-subset.ttf",
}

## Every Font and FontFile this has touched, held for the life of the run. See rule one.
static var _kept: Array = []


## The CJK subset for a language, or null for English (and for a language whose subset is
## not in this build).
static func cjk_face(lang: String) -> Font:
	if not CJK.has(lang):
		return null
	var path: String = CJK_DIR + str(CJK[lang])
	if not ResourceLoader.exists(path):
		push_warning("CJK subset missing: %s — %s will draw as empty boxes" % [path, lang])
		return null
	var f: Font = load(path)
	if f != null and not _kept.has(f):
		_kept.append(f)
	return f


## Install the fallback stack for `lang` on all three faces. Called at boot and again on
## every language change: the stack is rebuilt rather than appended to, so switching
## en → ja → zh does not leave Japanese ahead of Chinese in the chain and quietly render
## Chinese text in Japanese glyph forms.
static func install(lang: String = "en") -> void:
	var symbols: Font = load(FONT)
	if symbols != null and not _kept.has(symbols):
		_kept.append(symbols)
	var cjk := cjk_face(lang)
	var stack: Array[Font] = []
	# CJK first: it is the one that decides whether a whole screen is readable, and it
	# carries none of the six symbol glyphs, so the two never compete.
	if cjk != null:
		stack.append(cjk)
	if symbols != null:
		stack.append(symbols)
	for path in [StudioTheme.FONT_DISPLAY, StudioTheme.FONT_UI, StudioTheme.FONT_ITALIC]:
		var f: Font = load(path)
		if f is FontFile:
			(f as FontFile).fallbacks = stack
			if not _kept.has(f):
				_kept.append(f)
