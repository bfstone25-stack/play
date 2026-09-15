## 09_dist.rpy — Dual-track distribution (2026-09-14)
##
## One build, three behaviours, decided at runtime so itch and Cloudflare Pages ship the
## same files:
##   paid      desktop downloads: everything open.
##   itch_web  itch.io browser play: chapter 1 free, climax CGs censored, then the $2.99 gate.
##   ads_web   Cloudflare Pages: every unlock — next chapter, uncensored CG — costs one
##             sponsor clip. The page's index.html sets window.ELENA_DIST and loads
##             web/elena_ads.js, which draws the ad overlay and reports back.
##
## Why the split: 75 browser plays produced 0 purchase clicks. A price is one kind of
## "how much do you want the rest"; thirty seconds of attention is another, and the
## two gates emit the same telemetry so they can be compared.

init -2 python:
    GATED_CGS = ("climax_control", "climax_pact", "coal_store", "annex", "muniment", "aftermath")

    def _js_str(code):
        try:
            import emscripten
            return emscripten.run_script_string(code) or ""
        except Exception:
            return ""

    def _js_int(code):
        # run_script_string is the one variant proven to round-trip in the web build;
        # run_script_int returned 0 for a true expression and let the gate fall open.
        try:
            return int(float(_js_str("String(%s)" % code) or 0))
        except Exception:
            return 0

    def _js(code):
        try:
            import emscripten
            emscripten.run_script(code)
        except Exception:
            pass

    def elena_dist():
        if not getattr(renpy, "emscripten", False):
            # Desktop: the itch download is "paid" (everything open). The free download for
            # F95 — whose rules demand an offline-playable build — ships with game/dist.txt
            # saying offline_ads: chapters 2-5 and the uncensored CGs unlock through the
            # Adsterra Direct Link, opened in the player's browser by their own click.
            if getattr(store, "_elena_dist", None) is None:
                try:
                    store._elena_dist = renpy.file("dist.txt").read().decode("utf-8").strip() if renpy.loadable("dist.txt") else "paid"
                except Exception:
                    store._elena_dist = "paid"
                if store._elena_dist not in ("paid", "offline_ads"):
                    store._elena_dist = "paid"
            return store._elena_dist
        if getattr(store, "_elena_dist", None) is None:
            d = _js_str("(window.ELENA_DIST || 'itch_web')")
            store._elena_dist = d if d in ("itch_web", "ads_web", "paid") else "itch_web"
        return store._elena_dist

    def _ad_unlocks():
        if persistent.ad_unlocks is None:
            persistent.ad_unlocks = set()
        return persistent.ad_unlocks

    def is_ad_unlocked(key):
        # localStorage is the source of truth on the web; persistent mirrors it so the
        # gallery can ask without touching JS.
        if key in _ad_unlocks():
            return True
        if getattr(renpy, "emscripten", False) and _js_int("(window.ElenaAds && window.ElenaAds.has(%r)) ? 1 : 0" % key):
            _ad_unlocks().add(key)
            return True
        return False

    def cg_pick(name):
        """Image to show for a climax CG under the current track."""
        if name not in GATED_CGS or elena_dist() == "paid" or is_ad_unlocked("cg_" + name):
            return "cg " + name
        # The locked teasers are 480x270 thumbnails made for the paywall strip; on the
        # 1920x1080 stage they need scaling up (they are blurred, so nothing is lost).
        return Transform("cg_locked_" + name, zoom=4.0)

    def ad_gate_open(key, kind):
        tel_track("ad_prompt_shown", {"key": key, "kind": kind, "dist": elena_dist()})
        tel_flush(True)
        _js("window.ElenaAds && window.ElenaAds.open(%r, %r)" % (key, kind))

    def ad_gate_poll():
        # 0 pending, 1 completed, 2 abandoned; a page without elena_ads.js (dev, or the
        # script failed to load) must never brick the story, so it counts as completed.
        if not _js_int("window.ElenaAds ? 1 : 0"):
            return 1
        return _js_int("window.ElenaAds.result()")

    def cg_buy_decide(name, what, t0):
        # How long they looked at the price before deciding is the number we want.
        import time
        tel_track("paywall_decision", {"key": "cg_" + name, "what": what}, dur=int(time.time() - t0))
        if what == "buy_click":
            tel_cta_click("itch_buy_cg")
        tel_flush(True)

    def direct_link_open(key):
        """Open the sponsor page in a new tab and start the unlock timer.

        Nothing is forced: the player chose this over paying, the tab is theirs to close,
        and the unlock lands on return. One link per session key, never auto-triggered."""
        tel_track("directlink_open", {"key": key, "dist": elena_dist()})
        tel_flush(True)
        store._dl_started = __import__("time").time()
        if getattr(renpy, "emscripten", False):
            _js("window.open(%r, '_blank')" % DIRECT_LINK_URL)
        else:
            renpy.run(OpenURL(DIRECT_LINK_URL))

    def direct_link_elapsed():
        import time
        return int(time.time() - getattr(store, "_dl_started", 0))

    def direct_link_finish(key):
        tel_track("directlink_returned", {"key": key}, dur=direct_link_elapsed())
        _ad_unlocks().add(key)
        tel_flush(True)

    def ad_gate_tick():
        r = ad_gate_poll()
        return r if r in (1, 2) else None

    def ad_gate_finish(key, kind, result, started):
        import time
        dur = int(time.time() - started)
        if result == 1:
            _ad_unlocks().add(key)
            tel_track("ad_completed", {"key": key, "kind": kind}, dur=dur)
        else:
            tel_track("ad_abandoned", {"key": key, "kind": kind}, dur=dur)
        tel_flush(True)


## Watch-to-unlock overlay. The ad itself is HTML drawn over the canvas by elena_ads.js;
## this screen only waits for it and keeps the game paused underneath.
screen ad_gate_screen(key, kind, title):
    modal True
    default started = __import__("time").time()
    # A Function that returns non-None ends the interaction with that value.
    timer 0.5 repeat True action Function(ad_gate_tick)
    add Solid("#000000cc")
    vbox:
        xalign 0.5 yalign 0.12 spacing 10
        text title size 30 color "#d99b66" bold True xalign 0.5
        text _("The sponsor clip is playing above. The story continues when it ends.") size 20 color "#c8b8b0" xalign 0.5


## Buy prompt for a censored CG on the itch web track: the one place a player is asked
## for money while wanting something specific, so it gets its own telemetry key.
screen cg_buy_screen(name):
    modal True
    tag menu
    default t0 = __import__("time").time()
    add Solid("#000000d0")
    add "cg_locked_" + name xalign 0.5 yalign 0.42 zoom 2.6
    frame:
        xalign 0.5 yalign 0.92 background Transform("#1d1424", alpha=0.94) padding (30, 18, 30, 18)
        vbox:
            spacing 10 xalign 0.5
            text _("This scene is uncensored in the full game.") size 24 color "#ffdfa0" xalign 0.5
            hbox:
                xalign 0.5 spacing 20
                textbutton _("★ Unlock everything - $2.99"):
                    action [Function(cg_buy_decide, name, "buy_click", t0), OpenURL(ITCH_BUY_URL)]
                    text_size 24 text_color "#ffffff" background Transform("#d95a43", alpha=0.95) padding (22, 12, 22, 12)
                if DIRECT_LINK_URL:
                    textbutton _("▶ Unlock free — open sponsor"):
                        action [Function(cg_buy_decide, name, "directlink_click", t0), Return("directlink")]
                        text_size 22 text_color "#70c080" background Transform("#1a2a1e", alpha=0.95) padding (18, 12, 18, 12)
                else:
                    textbutton _("▶ Free with ads"):
                        action [Function(cg_buy_decide, name, "ads_click", t0), OpenURL(ADS_SITE_URL)]
                        text_size 22 text_color "#70c080" background Transform("#1a2a1e", alpha=0.95) padding (18, 12, 18, 12)
                textbutton _("Continue censored"):
                    action [Function(cg_buy_decide, name, "dismiss", t0), Return()]
                    text_size 20 text_color "#d99b66" background Transform("#24172a", alpha=0.92) padding (16, 10, 16, 10)


label chapter_gate(n):
    # Called at the end of chapter n-1. Returns when chapter n may start.
    $ tel_track("chapter_%d_finish" % (n - 1), {"ending": chosen_ending, "dist": elena_dist()})
    $ tel_flush(True)
    if elena_dist() == "paid":
        return
    if elena_dist() == "itch_web":
        jump demo_paywall
    $ key = "ch%d" % n
    if elena_dist() == "offline_ads":
        if is_ad_unlocked(key):
            return
        jump offline_chapter_gate
    if is_ad_unlocked(key):
        return
    $ started = __import__("time").time()
    $ ad_gate_open(key, "chapter")
    call screen ad_gate_screen(key, "chapter", _("Chapter %d unlocks after one sponsor clip") % n)
    $ ad_gate_finish(key, "chapter", _return, started)
    if _return != 1:
        # They closed the ad. Ask again rather than dumping them to the menu.
        jump chapter_gate_retry
    return

label chapter_gate_retry:
    menu:
        "That chapter stays locked until the clip plays through."
        "Play the sponsor clip":
            jump chapter_gate_again
        "Get the full game instead ($2.99, no ads)":
            $ tel_cta_click("itch_buy_from_adgate")
            $ renpy.run(OpenURL(ITCH_BUY_URL))
            jump chapter_gate_retry

label chapter_gate_again:
    $ started = __import__("time").time()
    $ ad_gate_open(key, "chapter")
    call screen ad_gate_screen(key, "chapter", _("One sponsor clip, then the story goes on"))
    $ ad_gate_finish(key, "chapter", _return, started)
    if _return != 1:
        jump chapter_gate_retry
    return


label cg_gate(name):
    # Called just before a gated CG is shown. Never blocks the story: on ads_web the
    # player may keep it censored, and that choice is itself the data we want.
    if name not in GATED_CGS or elena_dist() == "paid" or is_ad_unlocked("cg_" + name):
        return
    $ tel_track("paywall_seen", {"key": "cg_" + name, "dist": elena_dist()})
    if elena_dist() in ("itch_web", "offline_ads"):
        call screen cg_buy_screen(name)
        if _return == "directlink":
            $ direct_link_open("cg_" + name)
            call screen direct_link_screen("cg_" + name, _("Uncensored after the sponsor page"))
        return
    menu:
        "This scene is censored. Unlock the uncensored version?"
        "Watch a sponsor clip to unlock":
            $ started = __import__("time").time()
            $ ad_gate_open("cg_" + name, "cg")
            call screen ad_gate_screen("cg_" + name, "cg", _("Uncensored after one sponsor clip"))
            $ ad_gate_finish("cg_" + name, "cg", _return, started)
            return
        "Keep it censored":
            $ tel_track("paywall_decision", {"key": "cg_" + name, "what": "dismiss"})
            return


## Test hook: ?warp=gate on a web build jumps straight to the two gates so the ad flow
## can be checked in a minute instead of after a full read of chapter 1.
label splashscreen:
    if getattr(renpy, "emscripten", False) and _js_str("new URLSearchParams(location.search).get('warp') || ''") == "gate":
        jump warp_gate
    return

label warp_gate:
    $ chosen_ending = "control"
    scene bg study_normal
    narrator "[[warp] CG gate next."
    call cg_gate("climax_control")
    scene expression cg_pick("climax_control") at night_deep
    with dissolve
    narrator "[[warp] This is [cg_pick('climax_control')]. Chapter gate next."
    $ chapter_cleared = 1
    $ demo_cut = chosen_ending
    call chapter_gate(2)
    narrator "[[warp] Chapter 2 unlocked."
    jump chapter_2


## Sponsor-page unlock for the itch build: Adsterra's Direct Link runs on their own page,
## so it needs no domain of ours. The player comes back and the scene opens.
screen direct_link_screen(key, title):
    modal True
    tag menu
    add Solid("#000000d8")
    vbox:
        xalign 0.5 yalign 0.40 spacing 14
        text title size 30 color "#70c080" bold True xalign 0.5
        text _("The sponsor page opened in a new tab. Come back when you are done.") size 20 color "#c8b8b0" xalign 0.5
        text _("[direct_link_elapsed()] / [DIRECT_LINK_SECONDS] seconds") size 22 color "#ffdfa0" xalign 0.5
        timer 1.0 repeat True action Function(renpy.restart_interaction)
        hbox:
            xalign 0.5 spacing 18
            if direct_link_elapsed() >= DIRECT_LINK_SECONDS:
                textbutton _("✓ Unlock"):
                    action [Function(direct_link_finish, key), Return(1)]
                    text_size 24 text_color "#ffffff" background Transform("#3a7a4a", alpha=0.95) padding (22, 12, 22, 12)
            textbutton _("Cancel"):
                action Return(0)
                text_size 20 text_color "#d99b66" background Transform("#24172a", alpha=0.92) padding (16, 10, 16, 10)


## F95 download: the next chapter costs one sponsor page (or the $2.99 itch build).
label offline_chapter_gate:
    menu:
        "Chapter [n] is locked in the free edition."
        "Open the sponsor page, then continue":
            $ direct_link_open(key)
            call screen direct_link_screen(key, _("Chapter %d unlocks after the sponsor page") % n)
            if _return == 1:
                return
            jump offline_chapter_gate
        "Get the ad-free full game on itch ($2.99)":
            $ tel_cta_click("itch_buy_offline")
            $ renpy.run(OpenURL(ITCH_BUY_URL))
            jump offline_chapter_gate


## Story checkpoints: a sponsor gate at a narrative beat, mandatory on the free tracks.
## Each one carries its beat name, so the reports can say *where* in the story people pay
## twenty seconds and where they leave — the closest thing we have to reading them.
label ad_checkpoint(key, title):
    if elena_dist() in ("paid", "itch_web") or is_ad_unlocked(key):
        return
    $ tel_track("checkpoint_seen", {"key": key, "dist": elena_dist()})
    $ tel_flush(True)
    if elena_dist() == "ads_web":
        jump checkpoint_clip
    jump checkpoint_link

label checkpoint_clip:
    $ started = __import__("time").time()
    $ ad_gate_open(key, "checkpoint")
    call screen ad_gate_screen(key, "checkpoint", title)
    $ ad_gate_finish(key, "checkpoint", _return, started)
    if _return == 1:
        return
    menu:
        "The story continues after one sponsor clip."
        "Play the clip":
            jump checkpoint_clip
        "Get the ad-free full game ($2.99)":
            $ tel_cta_click("itch_buy_checkpoint")
            $ renpy.run(OpenURL(ITCH_BUY_URL))
            jump checkpoint_clip

label checkpoint_link:
    menu:
        "[title]"
        "Open the sponsor page, then continue":
            $ direct_link_open(key)
            call screen direct_link_screen(key, title)
            if _return == 1:
                return
            jump checkpoint_link
        "Get the ad-free full game on itch ($2.99)":
            $ tel_cta_click("itch_buy_checkpoint")
            $ renpy.run(OpenURL(ITCH_BUY_URL))
            jump checkpoint_link
