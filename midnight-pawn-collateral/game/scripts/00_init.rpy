## 00_init.rpy — Midnight Pawn: Collateral
##
## The adult fork of Midnight Pawn & Crypt (Flat 404). Built as a new Ren'Py project on the
## play/room-704/ skeleton rather than as a patch to the Godot original, per
## ops/adult_forks/midnight-pawn.md §0 — the Godot gate (scripts/gate.gd, 71 lines) has never
## shipped a fork, and 09_dist.rpy here has shipped two.
##
## What this file owns: cast, art declarations, the night's state, the reading economy's
## Ren'Py-side wrappers, and the business rules. The *rules* themselves live in
## game/python-packages/collateral_core.py so they can be tested without an SDK.

init -2 python:
    import collateral_core as core

    renpy.music.register_channel("ambience", "music", True)
    if persistent.unlocked_cgs is None:
        persistent.unlocked_cgs = set()

    def unlock_cg(cg_id):
        if persistent.unlocked_cgs is None:
            persistent.unlocked_cgs = set()
        persistent.unlocked_cgs.add(cg_id)

    def is_cg_unlocked(cg_id):
        return bool(persistent.unlocked_cgs) and cg_id in persistent.unlocked_cgs


## ---------------------------------------------------------------------------
## Cast
## ---------------------------------------------------------------------------
## Five clients, each seen once, each named. This is the structural answer to the Room 704
## overlap (ops/adult_forks/midnight-pawn.md §1): if these ever collapse into one woman at a
## counter, the fork is cancelled.

define nar = Character(None, what_italic=False)
define nara = Character("Nara", color="#e8b84a", what_color="#f1dfb0")
define tam = Character("Tamsin", color="#d98a6a", what_color="#f1dfb0")
define ivo = Character("Ivo", color="#8fa8c0", what_color="#f1dfb0")
define mer = Character("Merrow", color="#b9a7c8", what_color="#f1dfb0")
define cal = Character("Calder", color="#7f9a7a", what_color="#f1dfb0")
define shop = Character("the shop", color="#6b6478", what_color="#c8bfd0")

## Backgrounds
image bg shop = "images/bg/bg_shop.webp"
image bg market = "images/bg/bg_market.webp"
image bg black = Solid("#100d18")
image bg dawn = Solid("#201928")

## Readings. The uncensored files are deliberately absent from the free packages: they are
## fetched from the gateway when a gate completes (09_dist.rpy), so unzipping the game or
## editing a save reveals nothing.
image cg tamsin = "images/cgs/cg_tamsin.webp"
image cg finial = "images/cgs/cg_finial.webp"
image cg ring = "images/cgs/cg_ring.webp"
image cg veil = "images/cgs/cg_veil.webp"
image cg market = "images/cgs/cg_market.webp"
image cg collateral = "images/cgs/cg_collateral.webp"

## Censored stand-ins — dark plates, not mosaics (ART_DIRECTION: the same composition lit
## from behind into silhouette, nudity tags dropped).
image cg_locked_finial = "images/cgs/cg_finial_x_locked.webp"
image cg_locked_ring = "images/cgs/cg_ring_x_locked.webp"
image cg_locked_veil = "images/cgs/cg_veil_x_locked.webp"
image cg_locked_market = "images/cgs/cg_market_x_locked.webp"
image cg_locked_collateral = "images/cgs/cg_collateral_x_locked.webp"

transform lamp_tint:
    matrixcolor TintMatrix("#e8b84a") * BrightnessMatrix(-0.04)

transform crypt_tint:
    matrixcolor TintMatrix("#7f8fd0") * BrightnessMatrix(-0.08)

transform dawn_tint:
    matrixcolor TintMatrix("#c9b08a") * BrightnessMatrix(0.05)

define audio.theme = "audio/suspense_theme.ogg"
define audio.warm = "audio/ecchi_theme.ogg"
define audio.crypt = "audio/heartbeat.ogg"
define audio.dust = "audio/rain_ambience.ogg"


## ---------------------------------------------------------------------------
## The night's state
## ---------------------------------------------------------------------------

default run = None            # a collateral_core.Run, made in `start`
default ledger_shown = False
default act_cleared = 0
default ending = "none"
default demo_cut = "none"


init -1 python:

    def new_run():
        store.run = core.Run()
        return store.run

    def till():
        return store.run.till if store.run else core.TILL_START

    def fee_for(item):
        return core.ITEMS[item]["fee"]

    def value_of(item):
        return core.ITEMS[item]["value"]

    def price_of(item, tier):
        return core.price_of(item, tier)

    def reading_affordable(item):
        return store.run.can_afford(core.ITEMS[item]["fee"])

    def reading_delivered(name):
        """Did the player actually get the uncensored plate for `name`?

        This is the pivot of the fee-refund rule below. A free-track player who pays shop
        cash and then declines the distribution gate must not be left poorer *and* looking
        at a silhouette — that is the exact shape of "a second paywall" that the design
        names as the riskiest part of the fork.
        """
        if name not in GATED_CGS:
            return True
        if dist_track() == "paid":
            return True
        if is_ad_unlocked("cg_" + name):
            return True
        return gated_ready(name)

    def ledger_rows():
        """(key, title, unlocked, reason) for the Reading Ledger screen."""
        conds = core.cg_conditions(store.run) if store.run else {}
        rows = []
        for key, title in LEDGER_TITLES:
            ok, why = conds.get(key, (False, ""))
            rows.append((key, title, bool(ok) and is_cg_unlocked(key), why))
        return rows


init python:
    LEDGER_TITLES = [
        ("tamsin", "The finial — what the room looked like"),
        ("finial", "The finial — what she was doing in it"),
        ("ring", "The ring — eleven months after"),
        ("veil", "The veil — the night before the funeral"),
        ("market", "Calder's proof — somebody else's night"),
        ("collateral", "The Black Ledger — your own hand"),
    ]


## ---------------------------------------------------------------------------
## Business rules (see ops/DUAL_TRACK.md)
## ---------------------------------------------------------------------------
## Browser build: the cold open and the first two appraisals are free. The paid download is
## the whole night with nothing censored.

define COLLATERAL_WEB_DEMO = True
define ITCH_BUY_URL = "https://bfstone25-stack.itch.io/midnight-pawn-collateral/purchase"
define GAME_PRICE = "$3.49"
## The sponsor URL is NOT in this file. A string in a script ends up in the .rpa of every
## package, downloads included — see the f95-ban-direct-link-ads note. It is served to the
## web track by ads_config.js and read at runtime, so a download simply has no URL.
define DIRECT_LINK_SECONDS = 20

init 100 python:
    if COLLATERAL_WEB_DEMO and renpy.emscripten:
        config.allow_skipping = False
        config.fast_skipping = False
