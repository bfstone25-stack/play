## 11_voice.rpy — voice acting playback. The only file the voice pass adds to the game.
##
## Nothing in the story scripts changed to make this work, and nothing in screens.rpy,
## gui.rpy or options.rpy is touched: the title agent owns the slider UI, and the mixer
## this file plays on is the stock Ren'Py `voice` channel, which that slider already
## knows how to drive.
##
## Two lookups, because the games have two kinds of line.
##
##   1. A real say statement has a *translation identifier* -- the label plus a hash of
##      the statement, e.g. route_pact_e8dde90f. Ren'Py hands that to config.auto_voice,
##      so that is the key, and it is a script location: editing one line invalidates
##      exactly that line's audio and nothing else.
##
##   2. Confession Room's suspect statements are strings in a python list, spoken through
##      one `$ _c(statement_text(id))` call. They share a single statement and therefore a
##      single identifier, so auto_voice cannot tell them apart. Those are matched on a
##      hash of the text actually being said, via a hook on ADVCharacter.__call__.
##
## Both tables live in game/audio/voice/manifest.json, written by ops/vn_voice.py. A file
## that is missing simply does not play -- a part-voiced build is a normal state here, not
## an error, because the heroines are generated first and the rest arrives later.

init -5 python:
    import json as _vn_json

    ## Per-character on/off. Keys are the character names ops/vn_voice.py uses, which are
    ## also the directory names under game/audio/voice/.
    if persistent.voice_off is None:
        persistent.voice_off = set()

    def voice_enabled(character):
        return character not in (persistent.voice_off or set())

    def toggle_voice(character):
        off = set(persistent.voice_off or set())
        if character in off:
            off.discard(character)
        else:
            off.add(character)
        persistent.voice_off = off

    ## Used by a settings screen if one is ever added; the title agent owns that file, so
    ## this exposes the data rather than drawing anything.
    def voice_characters():
        return list(_vn_voice.get("characters", []))


init -4 python:
    import hashlib as _vn_hashlib

    def _vn_load_manifest():
        try:
            with renpy.open_file("audio/voice/manifest.json") as fh:
                return _vn_json.loads(fh.read().decode("utf-8"))
        except Exception:
            return {"by_id": {}, "by_text": {}, "characters": []}

    _vn_voice = _vn_load_manifest()

    def _vn_character_of(path):
        ## "audio/voice/mira/act1_end_44026d3a.ogg" -> "mira"
        parts = path.split("/")
        return parts[2] if len(parts) > 3 else ""

    def _vn_pick(path):
        if not path:
            return None
        if not voice_enabled(_vn_character_of(path)):
            return None
        if not renpy.loadable(path):
            return None
        return path

    def vn_auto_voice(voice_id):
        """config.auto_voice: translation identifier -> voice file, or None."""
        return _vn_pick(_vn_voice["by_id"].get(voice_id))

    config.auto_voice = vn_auto_voice


init 500 python:
    ## The text-keyed fallback, for lines that are data rather than statements.
    ## Wrapping ADVCharacter.__call__ catches both `nik "..."` and `$ nik(text)`; the
    ## auto_voice path has already run for the former, and renpy.voice() on a line that
    ## already has voice is a no-op we avoid by checking the id table first.
    if _vn_voice["by_text"]:
        import renpy.character as _vn_rc

        _vn_orig_call = _vn_rc.ADVCharacter.__call__

        def _vn_voiced_call(self, what, *args, **kwargs):
            try:
                if isinstance(what, str):
                    key = _vn_hashlib.sha1(what.encode("utf-8")).hexdigest()[:16]
                    path = _vn_pick(_vn_voice["by_text"].get(key))
                    if path:
                        renpy.voice(path)
            except Exception:
                pass
            return _vn_orig_call(self, what, *args, **kwargs)

        _vn_rc.ADVCharacter.__call__ = _vn_voiced_call
