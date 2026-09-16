## 00_init.rpy — Room 704: characters, art, state, and the dual-track business rules.
##
## Everything Elena got wrong on day one is set here on day one instead:
##   * AI disclosure is in the game, not just the store page
##   * the ad-supported track and the paid track are both wired before release
##   * the explicit CGs ship censored, and the uncensored versions actually exist

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

define nar = Character(None, what_italic=False)
define m = Character("Mira", color="#e8d9b0", what_color="#efe7dc")
define you = Character("You", color="#9fc2d6", what_color="#efe7dc")
define man = Character("???", color="#b0b0b0", what_color="#d8d8d8")

## Backgrounds
image bg lobby = "images/bg/bg_lobby.webp"
image bg corridor = "images/bg/bg_corridor.webp"
image bg room = "images/bg/bg_room.webp"
image bg black = Solid("#07070b")

## Scene CGs
image cg checkin = "images/cgs/cg_checkin.webp"
image cg door = "images/cgs/cg_door.webp"
image cg bed = "images/cgs/cg_bed_x.webp"
image cg window = "images/cgs/cg_window_x.webp"
image cg morning = "images/cgs/cg_morning.webp"

## Censored stand-ins, shown until the scene is unlocked.
image cg_locked_bed = "images/cgs/cg_bed_x_locked.webp"
image cg_locked_window = "images/cgs/cg_window_x_locked.webp"

## Narrative state
default trust = 0          # how straight you played it with her
default covered_for_her = False
default route = "none"
default act_cleared = 0
default demo_cut = "none"

transform neon_tint:
    matrixcolor TintMatrix("#7f8fd0") * BrightnessMatrix(-0.06)

transform dawn_tint:
    matrixcolor TintMatrix("#c9b08a") * BrightnessMatrix(0.04)

define audio.rain = "audio/rain_ambience.ogg"
define audio.theme = "audio/suspense_theme.ogg"
define audio.warm = "audio/ecchi_theme.ogg"
define audio.heartbeat = "audio/heartbeat.ogg"

## Business rules (see ops/DUAL_TRACK.md). The browser build is act 1 free; the paid
## download is the whole night with nothing censored.
define ROOM704_WEB_DEMO = True
define ITCH_BUY_URL = "https://bfstone25-stack.itch.io/room-704/purchase"
## Downloadable builds cannot show a banner, so the ad-supported offline track sends the
## player to a sponsor page for a timed visit instead (ops/DUAL_TRACK.md).
define DIRECT_LINK_URL = "https://www.profitableratecpmnetwork.com/zwp8ud7ja?key=a1512482200926a2de2d9ef3cb26a8a9"
define DIRECT_LINK_SECONDS = 20

init 100 python:
    if ROOM704_WEB_DEMO and renpy.emscripten:
        config.allow_skipping = False
        config.fast_skipping = False
