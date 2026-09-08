## 00_init.rpy - System Initialization, Variables, Character Definitions, Audio Channels, and Persistent Flags

init -2 python:
    # Register audio channels if needed
    renpy.music.register_channel("ambience", "music", True)
    renpy.music.register_channel("sfx_loop", "sound", True)

    # Initialize persistent CG gallery flags
    if persistent.unlocked_cgs is None:
        persistent.unlocked_cgs = set()

    def unlock_cg(cg_id):
        """Unlocks a CG in persistent storage and displays a notification."""
        if persistent.unlocked_cgs is None:
            persistent.unlocked_cgs = set()
        if cg_id not in persistent.unlocked_cgs:
            persistent.unlocked_cgs.add(cg_id)
            renpy.notify(_("New CG Unlocked in Gallery!"))

    def is_cg_unlocked(cg_id):
        """Checks if a CG has been unlocked."""
        if persistent.unlocked_cgs is None:
            return False
        return cg_id in persistent.unlocked_cgs

## Character Definitions
define protagonist = Character(
    _("Professor Vance"),
    color="#d99b66",
    who_bold=True,
    what_prefix="“",
    what_suffix="”"
)

define elena = Character(
    _("Elena"),
    color="#e08498",
    who_bold=True,
    what_prefix="“",
    what_suffix="”"
)

define narrator = Character(
    None,
    what_italic=True,
    what_color="#d0c8c0"
)

## Visual Asset Image Definitions
image bg study_normal = "images/bg/study_normal.webp"
image bg study_dark = "images/bg/study_dark.webp"

image elena neutral = "images/characters/elena_neutral.webp"
image elena flustered = "images/characters/elena_flustered.webp"
image elena submission = "images/characters/elena_submission.webp"

image cg confrontation = "images/cgs/cg_confrontation.webp"
image cg climax = "images/cgs/cg_climax.webp"
image cg aftermath = "images/cgs/cg_aftermath.webp"

## Default Narrative State Variables
default elena_suspicion = 0
default elena_affection = 0
default secret_ledger_discovered = False
default chosen_ending = "none"

## Audio Definitions
define audio.rain_ambience = "audio/rain_ambience.ogg"
define audio.suspense_theme = "audio/suspense_theme.ogg"
define audio.ecchi_theme = "audio/ecchi_theme.ogg"
define audio.heartbeat = "audio/heartbeat.ogg"
define audio.page_flip = "audio/page_flip.ogg"
define audio.click = "audio/click.ogg"
