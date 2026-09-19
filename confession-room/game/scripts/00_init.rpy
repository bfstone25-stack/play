## 00_init.rpy — Confession Room: cast, art registry, case state, business rules.
##
## This is the adult fork of TELL. The deduction engine is the same idea — three
## suspects, a question budget, one detail only the guilty one could know — but the
## pressure that makes a suspect slip is sexual and social, not procedural, and the
## case is authored and baked in so the game runs fully offline for F95.
##
## Everything Room 704 learned is carried over:
##   * AI disclosure lives in the game, not only on the store page
##   * both tracks (ad-supported and paid) are wired before the first release
##   * explicit CGs ship censored; the uncensored files are fetched on unlock

init -2 python:
    renpy.music.register_channel("ambience", "music", True)
    if persistent.unlocked_cgs is None:
        persistent.unlocked_cgs = set()

    def unlock_cg(cg_id):
        if persistent.unlocked_cgs is None:
            persistent.unlocked_cgs = set()
        persistent.unlocked_cgs.add(cg_id)

    def is_cg_unlocked(cg_id):
        return bool(persistent.unlocked_cgs) and cg_id in persistent.unlocked_cgs

## ---------------------------------------------------------------- cast
## Every character is an adult and is stated to be. The cast deliberately spans
## genders and orientations: the F95 tag wall is how an unknown title gets found,
## and a straight-only cast forecloses most of it.
define nar = Character(None, what_italic=False)
define you = Character("Reyes", color="#9fc2d6", what_color="#efe7dc")
define dsp = Character("Dispatch", color="#7f8fa0", what_color="#cfd6dc")

define nik = Character("Nikolai", color="#c2a37a", what_color="#efe7dc")   # 42, the fixer
define ade = Character("Adaeze", color="#d68fa8", what_color="#efe7dc")    # 29, the club manager
define vee = Character("Vee", color="#8fd6c2", what_color="#efe7dc")       # 31, the courier

## ---------------------------------------------------------------- backgrounds
image bg precinct = "images/bg/bg_precinct.webp"
image bg room = "images/bg/bg_room.webp"
image bg club = "images/bg/bg_club.webp"
image bg locker = "images/bg/bg_locker.webp"
image bg black = Solid("#07070b")

## ---------------------------------------------------------------- CGs
## Clothed story art ships in the package.
image cg intake = "images/cgs/cg_intake.webp"
image cg board = "images/cgs/cg_board.webp"
image cg closing = "images/cgs/cg_closing.webp"

## Censored stand-ins for the three explicit scenes. The uncensored versions are not
## in the archive at all — cg_pick() in 09_dist.rpy swaps in a file fetched from the
## gateway once a gate is cleared, so unzipping the game or editing a save shows
## nothing. Same trick Room 704 uses.
image cg_locked_nikolai = "images/cgs/cg_nikolai_x_locked.webp"
image cg_locked_adaeze = "images/cgs/cg_adaeze_x_locked.webp"
image cg_locked_vee = "images/cgs/cg_vee_x_locked.webp"

## The evidence photo. Censored in the free run; the uncensored plate is also the
## clue, which is why unlocking it is a fair trade rather than a tax.
image cg_locked_evidence = "images/cgs/cg_evidence_x_locked.webp"
image cg_locked_evidence2 = "images/cgs/cg_evidence2_x_locked.webp"
image cg_locked_evidence3 = "images/cgs/cg_evidence3_x_locked.webp"

## ---------------------------------------------------------------- case state
default questions_left = 12      # the budget; spending it all ends the interrogation
default pressure = {"nikolai": 0, "adaeze": 0, "vee": 0}
default heard = set()            # statement ids the player has actually pulled
default accused = None
default decisive = None
default cur_suspect = None
default interrogations_done = 0
default case_cleared = False
default route = "none"

## Which of the three cases is live, and which have been closed correctly. load_case()
## in 01_case.rpy fills CASE/SUSPECTS/STATEMENTS; they are declared here so a save made
## mid-case restores them rather than the ones the last init happened to leave behind.
default case_index = 0
default cases_cleared = set()
default board_page = 0
default CASE = {}
default SUSPECTS = {}
default STATEMENTS = []

## ---------------------------------------------------------------- business rules
## See ops/DUAL_TRACK.md. Browser build: the intake and one interrogation are free,
## everything past the first slip is gated. Paid download: the whole case, uncensored.
define CONFESSION_WEB_DEMO = True
define ITCH_BUY_URL = "https://bfstone25-stack.itch.io/confession-room/purchase"
## A downloadable build cannot render a banner, so the ad-supported offline track
## sends the player to a sponsor page for a timed visit instead.
define DIRECT_LINK_URL = ""   # sponsor page removed from every track 2026-09-16 (F95 ban; unverifiable views)
define DIRECT_LINK_SECONDS = 20

transform sodium_tint:
    matrixcolor TintMatrix("#c9a06a") * BrightnessMatrix(-0.05)

transform cold_tint:
    matrixcolor TintMatrix("#7f8fd0") * BrightnessMatrix(-0.08)

define audio.room_tone = "audio/room_tone.ogg"
define audio.theme = "audio/noir_theme.ogg"
define audio.pressure = "audio/pressure.ogg"
define audio.heartbeat = "audio/heartbeat.ogg"
