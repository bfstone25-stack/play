## 10_i18n.rpy — make the Japanese translation actually readable.
##
## DejaVuSans has no kana and no kanji, so without this every Japanese line renders as
## a row of empty boxes. Ren'Py fires config.change_language_callbacks on every
## Language() switch, so the swap happens live rather than only at boot.

define JP_FONT = "fonts/NotoSansCJKjp-Regular.otf"

init python:
    def _apply_language_font():
        jp = _preferences.language == "japanese"
        # Back to the skin's own faces when leaving Japanese — this used to reset
        # everything to DejaVu, which would have undone gui.rpy on every boot.
        latin = {"default": gui.text_font, "say_dialogue": gui.text_font, "say_label": gui.name_text_font,
                 "button_text": gui.interface_text_font, "input": gui.text_font,
                 "label_text": gui.interface_text_font, "prompt": gui.text_font,
                 "nvl_dialogue": gui.text_font, "nvl_label": gui.name_text_font}
        for s in latin:
            try:
                style.__dict__[s].font = JP_FONT if jp else latin[s]
            except Exception:
                pass
        # Japanese has no spaces, so it needs character-level wrapping or lines break
        # in the middle of nothing.
        try:
            style.default.language = "japanese" if jp else "unicode"
        except Exception:
            pass
        renpy.style.rebuild()

    config.change_language_callbacks.append(_apply_language_font)

init 1500 python:
    # Also on boot, for a player who left the game set to Japanese last time.
    _apply_language_font()
