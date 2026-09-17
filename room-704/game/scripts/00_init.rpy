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

## Scene CGs. The two uncensored ones are deliberately absent from the package: they are
## fetched from the gateway when a gate is completed (see 09_dist.rpy), so unzipping the
## game or editing a saved flag reveals nothing.
image cg checkin = "images/cgs/cg_checkin.webp"
image cg door = "images/cgs/cg_door.webp"
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
## The sponsor page is a *secondary* option and lives on our own domain only. It opens a
## new tab, which F95 called malware and banned us for on 2026-09-16 — so no downloadable
## build may reach it, and on the web it is never the only way forward: the banner
## countdown is, and that one keeps the player on the page.
##
## The URL itself is NOT here. A string in a script ends up in the .rpa of every package,
## downloads included, where anyone grepping the archive finds an ad network's domain in a
## build that never calls it. It is served to the web track by ads_config.js instead, and
## direct_link_url() reads it from the page at runtime — so a download simply has no URL.
define DIRECT_LINK_SECONDS = 20

init 100 python:
    if ROOM704_WEB_DEMO and renpy.emscripten:
        config.allow_skipping = False
        config.fast_skipping = False
