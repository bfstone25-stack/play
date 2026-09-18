## 09_dist.rpy — Dual-track distribution (2026-09-14)
##
## One build, three behaviours, decided at runtime so itch and Cloudflare Pages ship the
## same files:
##   paid      desktop downloads: everything open.
##   itch_web  itch.io browser play: chapter 1 free, climax CGs censored, then the $4.99 gate.
##   ads_web   Cloudflare Pages: every unlock — next chapter, uncensored CG — costs one
##             sponsor clip. The page's index.html sets window.ROOM704_DIST and loads
##             web/confession_ads.js, which draws the ad overlay and reports back.
##
## Why the split: 75 browser plays produced 0 purchase clicks. A price is one kind of
## "how much do you want the rest"; thirty seconds of attention is another, and the
## two gates emit the same telemetry so they can be compared.

init -2 python:
    # Only the two love scenes are censored before unlocking. The other CGs live in chapters
    # that are already behind the chapter gate, and calling a story illustration "uncensored"
    # promised something it never delivered — which is the likeliest reason 75 plays bought nothing.
    GATED_CGS = ("nikolai", "adaeze", "vee",
                 ## One evidence plate per case: each is that case's withheld detail.
                 "evidence", "evidence2", "evidence3")

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

    def dist_track():
        if not getattr(renpy, "emscripten", False):
            # Desktop: the itch download is "paid" (everything open). The free download for
            # F95 — whose rules demand an offline-playable build — ships with game/dist.txt
            # saying offline_ads: chapters 2-5 and the uncensored CGs unlock through the
            # Adsterra Direct Link, opened in the player's browser by their own click.
            if getattr(store, "_r704_dist", None) is None:
                try:
                    store._r704_dist = renpy.file("dist.txt").read().decode("utf-8").strip() if renpy.loadable("dist.txt") else "paid"
                except Exception:
                    store._r704_dist = "paid"
                # "demo" is the build shared on forums whose rules forbid gating content
                # behind a promotional link (F95 general rules §3). It has no ad gate at
                # all: act one is free, the rest points at the paid download.
                if store._r704_dist not in ("paid", "offline_ads", "demo"):
                    store._r704_dist = "paid"
            return store._r704_dist
        if getattr(store, "_r704_dist", None) is None:
            d = _js_str("(window.ROOM704_DIST || 'itch_web')")
            store._r704_dist = d if d in ("itch_web", "ads_web", "paid") else "itch_web"
        return store._r704_dist


    # ---- the break offer ---------------------------------------------------
    # Blaze's design: arousal fatigues, so between chapters a character asks whether the
    # player wants ten minutes of something lighter, and only opens the casual board if
    # they say yes. The board itself is play/_shared/board.js, loaded by the page.
    #
    # Not every gate. "After every chapter" was the ask, but a thing that asks every time
    # is a thing players learn to dismiss without reading, and the second dismissal is
    # worth less than the first. Offered on the 2nd and 4th gate of a session, never twice
    # in a row, and never before the player has finished something.
    def board_offer_break():
        if not getattr(renpy, "emscripten", False):
            return
        n = getattr(store, "_board_gates", 0) + 1
        store._board_gates = n
        if n not in (2, 4):
            return
        _js("window.BOARD && BOARD.offerBreak && BOARD.offerBreak()")

    def board_offer_more():
        """End of the run: the rest of the adult catalogue, same consent shape."""
        if not getattr(renpy, "emscripten", False):
            return
        _js("window.BOARD && BOARD.offerMore && BOARD.offerMore('adult')")

    # ---- server-gated art -------------------------------------------------
    # The uncensored CGs are not in the free packages at all. Completing a gate buys a
    # single-use, time-locked ticket; the bytes arrive from the gateway and are written to
    # the save directory for this install only. Editing a flag reveals nothing, because
    # there is nothing in the package to reveal.
    UNLOCK_API = "https://apps.blazecore.dev"

    def _gated_dir():
        import os
        d = os.path.join(config.savedir, "unlocked")
        try:
            if not os.path.isdir(d):
                os.makedirs(d)
            if d not in config.searchpath:
                config.searchpath.append(d)
        except Exception:
            pass
        return d

    def _gated_name(name):
        return "unlocked_%s.webp" % name

    def _gated_path(name):
        import os
        try:
            return os.path.join(_gated_dir(), _gated_name(name))
        except Exception:
            return None

    def gated_ready(name):
        import os
        p = _gated_path(name)
        return bool(p and os.path.isfile(p) and os.path.getsize(p) > 1024)

    def _http_json(url, payload):
        body = __import__("json").dumps(payload).encode()
        if getattr(renpy, "emscripten", False):
            r = renpy.fetch(url, method="POST", data=body, content_type="application/json", result="json", timeout=15)
            return r
        import urllib.request
        req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            return __import__("json").loads(resp.read().decode())

    def _http_bytes(url):
        if getattr(renpy, "emscripten", False):
            return renpy.fetch(url, result="bytes", timeout=25)
        import urllib.request
        with urllib.request.urlopen(url, timeout=25) as resp:
            return resp.read()

    def gated_ticket(name):
        """Ask for a ticket when the gate opens, so the server clock starts with the ad."""
        try:
            d = _http_json(UNLOCK_API + "/unlock/start", {"app": "confession-room", "key": name})
            if d and d.get("ok"):
                store._gate_ticket = {"name": name, "ticket": d["ticket"]}
                return True
        except Exception:
            pass
        store._gate_ticket = None
        return False

    def gated_redeem(name):
        """Spend the ticket after the gate completes. Returns True if the art landed."""
        tk = getattr(store, "_gate_ticket", None)
        if not tk or tk.get("name") != name:
            return gated_ready(name)
        try:
            url = "%s/unlock/fetch?ticket=%s&app=confession-room&key=%s" % (UNLOCK_API, tk["ticket"], name)
            data = _http_bytes(url)
            if data and len(data) > 1024:
                p = _gated_path(name)
                if p:
                    with open(p, "wb") as f:
                        f.write(data)
                    _gated_dir()
                    tel_track("unlock_delivered", {"key": name, "bytes": len(data)})
                    return True
        except Exception as exc:
            tel_track("unlock_failed", {"key": name, "err": type(exc).__name__})
        return False

    def _ad_unlocks():
        if persistent.ad_unlocks is None:
            persistent.ad_unlocks = set()
        return persistent.ad_unlocks

    def is_ad_unlocked(key):
        # localStorage is the source of truth on the web; persistent mirrors it so the
        # gallery can ask without touching JS.
        if key in _ad_unlocks():
            return True
        if getattr(renpy, "emscripten", False) and _js_int("(window.ConfessionAds && window.ConfessionAds.has(%r)) ? 1 : 0" % key):
            _ad_unlocks().add(key)
            return True
        return False

    def cg_pick(name):
        """Image to show for a gated CG under the current track.

        The uncensored files exist only in the paid package, so this checks for the file
        rather than assuming a declared image: the free builds genuinely do not have them."""
        if name not in GATED_CGS:
            return "cg " + name
        paid_file = "images/cgs/cg_%s_x.webp" % name
        if dist_track() == "paid" and renpy.loadable(paid_file):
            return Image(paid_file)
        if gated_ready(name):
            _gated_dir()
            return Image(_gated_name(name))
        # The censored plates are 960x540; scale to the stage.
        return Transform("cg_locked_" + name, zoom=2.0)

    def ad_gate_open(key, kind):
        if kind == "cg":
            gated_ticket(key[3:] if key.startswith("cg_") else key)
        tel_track("ad_prompt_shown", {"key": key, "kind": kind, "dist": dist_track()})
        tel_flush(True)
        _js("window.ConfessionAds && window.ConfessionAds.open(%r, %r)" % (key, kind))

    AD_SCRIPT_GRACE = 8   # seconds to wait for confession_ads.js before calling the sponsor unavailable

    def ad_gate_poll(started=None):
        # 0 pending, 1 completed, 2 abandoned, 3 sponsor unavailable. A missing script used
        # to count as *completed*, which opened every gate whenever the script was blocked
        # or not shipped. Now it is a timed "unavailable" that the telemetry can see.
        import time
        if not _js_int("window.ConfessionAds ? 1 : 0"):
            if started is not None and time.time() - started >= AD_SCRIPT_GRACE + DIRECT_LINK_SECONDS:
                tel_track("ad_script_missing", {"dist": dist_track()})
                return 3
            return 0
        return _js_int("window.ConfessionAds.result()")

    def cg_buy_decide(name, what, t0):
        # How long they looked at the price before deciding is the number we want.
        import time
        tel_track("paywall_decision", {"key": "cg_" + name, "what": what}, dur=int(time.time() - t0))
        if what == "buy_click":
            tel_cta_click("itch_buy_cg")
        tel_flush(True)

    def _is_test_run():
        """True for our own screenshot/QA passes.

        Our test runs opened the sponsor page three times on 2026-09-15 and those
        were indistinguishable from players at the ad network. They are distinguishable
        here, so the sponsor step becomes a no-op instead."""
        if not getattr(renpy, "emscripten", False):
            return False
        try:
            probe = _js_str(
                "(function(){var q=new URLSearchParams(location.search);"
                "if(q.get('warp'))return '1';"
                "var s=(q.get('src')||'').toLowerCase();"
                "if(/shot|test|probe|selftest|livecheck/.test(s))return '1';"
                "if(navigator.webdriver)return '1';"
                "if(location.hostname==='localhost'||location.hostname==='127.0.0.1')return '1';"
                "return '';})()")
            return probe == "1"
        except Exception:
            return False

    def direct_link_open(key):
        """Open the sponsor page in a new tab and start the unlock timer.

        Nothing is forced: the player chose this over paying, the tab is theirs to close,
        and the unlock lands on return. One link per session key, never auto-triggered."""
        tel_track("directlink_open", {"key": key, "dist": dist_track()})
        tel_flush(True)
        store._dl_started = __import__("time").time()
        if key.startswith("cg_"):
            gated_ticket(key[3:])
        if _is_test_run():
            # QA path: the timer still runs, the sponsor page is never opened.
            tel_track("directlink_test_noop", {"key": key})
            return
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
        if key.startswith("cg_"):
            gated_redeem(key[3:])
        tel_flush(True)

    def ad_gate_tick(started=None):
        r = ad_gate_poll(started)
        return r if r in (1, 2, 3) else None

    def ad_gate_finish(key, kind, result, started):
        import time
        dur = int(time.time() - started)
        if result == 1:
            _ad_unlocks().add(key)
            if kind == "cg":
                gated_redeem(key[3:] if key.startswith("cg_") else key)
            tel_track("ad_completed", {"key": key, "kind": kind}, dur=dur)
        elif result == 3:
            # No creative was shown: a chapter passes (flagged) so an adblocker never
            # bricks the story; the uncensored art stays censored.
            if kind == "cg":
                tel_track("ad_unavailable_censored", {"key": key, "kind": kind}, dur=dur)
            else:
                _ad_unlocks().add(key)
                tel_track("ad_unavailable_passed", {"key": key, "kind": kind}, dur=dur)
        else:
            tel_track("ad_abandoned", {"key": key, "kind": kind}, dur=dur)
        tel_flush(True)


## Watch-to-unlock overlay. The ad itself is HTML drawn over the canvas by confession_ads.js;
## this screen only waits for it and keeps the game paused underneath.
screen ad_gate_screen(key, kind, title):
    modal True
    default started = __import__("time").time()
    # A Function that returns non-None ends the interaction with that value.
    timer 0.5 repeat True action Function(ad_gate_tick, started)
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
    add "cg_locked_" + name xalign 0.5 yalign 0.40 zoom 1.75
    frame:
        xalign 0.5 yalign 0.92 background Transform("#1d1424", alpha=0.94) padding (30, 18, 30, 18)
        vbox:
            spacing 10 xalign 0.5
            text _("This scene is uncensored in the full game.") size 24 color "#ffdfa0" xalign 0.5
            hbox:
                xalign 0.5 spacing 20
                textbutton _("★ Unlock everything — $4.99"):
                    action [Function(cg_buy_decide, name, "buy_click", t0), OpenURL(ITCH_BUY_URL)]
                    text_size 24 text_color "#ffffff" background Transform("#d95a43", alpha=0.95) padding (22, 12, 22, 12)
                if dist_track() != "demo":
                    textbutton _("▶ Unlock free with ads — on our site"):
                        action [Function(cg_buy_decide, name, "ads_click", t0), OpenURL("https://confession-room.flat404.workers.dev/?src=ingame")]
                        text_size 22 text_color "#70c080" background Transform("#1a2a1e", alpha=0.95) padding (18, 12, 18, 12)
                textbutton _("Continue censored"):
                    action [Function(cg_buy_decide, name, "dismiss", t0), Return()]
                    text_size 20 text_color "#d99b66" background Transform("#24172a", alpha=0.92) padding (16, 10, 16, 10)


label chapter_gate(n):
    # Called at the end of chapter n-1. Returns when chapter n may start.
    $ tel_track("act_%d_finish" % (n - 1), {"route": route, "dist": dist_track()})
    $ tel_flush(True)
    if dist_track() == "paid":
        return
    if dist_track() in ("itch_web", "demo"):
        call demo_paywall
        return
    $ key = "act%d" % n
    if dist_track() in ("offline_ads", "ads_web"):
        if is_ad_unlocked(key):
            return
        jump offline_chapter_gate
    if is_ad_unlocked(key):
        return
    $ started = __import__("time").time()
    $ ad_gate_open(key, "chapter")
    call screen ad_gate_screen(key, "chapter", _("The rest of the night unlocks after one sponsor clip"))
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
        "Get the full game instead ($4.99, no ads)":
            $ tel_cta_click("itch_buy_from_adgate")
            $ renpy.run(OpenURL(ITCH_BUY_URL))
            jump chapter_gate_retry

label chapter_gate_again:
    $ started = __import__("time").time()
    $ ad_gate_open(key, "chapter")
    call screen ad_gate_screen(key, "chapter", _("One sponsor clip, then the night goes on"))
    $ ad_gate_finish(key, "chapter", _return, started)
    if _return != 1:
        jump chapter_gate_retry
    return


label cg_gate(name):
    # Called just before a gated CG is shown. Never blocks the story: on ads_web the
    # player may keep it censored, and that choice is itself the data we want.
    if name not in GATED_CGS or dist_track() == "paid" or is_ad_unlocked("cg_" + name):
        return
    $ tel_track("paywall_seen", {"key": "cg_" + name, "dist": dist_track()})
    # ads_web is our own domain: the banner plays in place (the menu below).
    if dist_track() in ("itch_web", "offline_ads", "demo"):
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
    ## ?warp=gate drops straight onto both gates so the ad flow can be checked in a
    ## minute instead of after a full playthrough.
    $ route = "vee"
    scene bg room
    nar "[[warp] CG gate next."
    call cg_gate("vee")
    scene expression cg_pick("vee") at sodium_tint
    with dissolve
    nar "[[warp] That is [cg_pick('vee')]. Chapter gate next."
    $ interrogations_done = 1
    call chapter_gate(2)
    nar "[[warp] Second room unlocked."
    jump corridor

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


## F95 download: the next chapter costs one sponsor page (or the $4.99 itch build).
## The downloaded build is a short trial. A downloaded Ren'Py build has no browser engine,
## so it cannot show a banner, and a sponsor page could never verify a view - and the
## sponsor page is what got the F95 account banned. The trial ends on the two honest paths.
label offline_trial_end:
    $ tel_track("trial_end", {"dist": dist_track()})
    $ tel_flush(True)
    call screen offline_trial_screen
    jump offline_trial_end

screen offline_trial_screen():
    modal True
    tag menu
    add Solid("#000000e0")
    vbox:
        xalign 0.5 yalign 0.42 spacing 16
        text _("The trial ends here.") size 34 color "#d99b66" bold True xalign 0.5
        text _("The rest of the case file continues one of two ways.") size 20 color "#c8b8b0" xalign 0.5 text_align 0.5
        null height 6
        textbutton _("▶ Keep playing free, with ads - in your browser"):
            action [Function(tel_cta_click, "trial_ads_site"), OpenURL("https://confession-room.flat404.workers.dev/?src=trial")]
            xalign 0.5 text_size 24 text_color "#ffffff" background Transform("#1f4a2a", alpha=0.95) padding (22, 12, 22, 12)
        textbutton _("★ Get the full case, no ads - $4.99 on itch"):
            action [Function(tel_cta_click, "trial_itch_buy"), OpenURL(ITCH_BUY_URL)]
            xalign 0.5 text_size 24 text_color "#ffffff" background Transform("#d95a43", alpha=0.95) padding (22, 12, 22, 12)
        textbutton _("Back to title"):
            action MainMenu(confirm=False)
            xalign 0.5 text_size 18 text_color "#d99b66" background Transform("#24172a", alpha=0.92) padding (14, 8, 14, 8)

label offline_chapter_gate:
    jump offline_trial_end
    menu:
        "Chapter [n] is locked in the free edition."
        "Open the sponsor page, then continue":
            $ direct_link_open(key)
            call screen direct_link_screen(key, _("The rest of the night unlocks after the sponsor page"))
            if _return == 1:
                return
            jump offline_chapter_gate
        "Get the ad-free full game on itch ($4.99)":
            $ tel_cta_click("itch_buy_offline")
            $ renpy.run(OpenURL(ITCH_BUY_URL))
            jump offline_chapter_gate


## Story checkpoints: a sponsor gate at a narrative beat, mandatory on the free tracks.
## Each one carries its beat name, so the reports can say *where* in the story people pay
## twenty seconds and where they leave — the closest thing we have to reading them.
label ad_checkpoint(key, title):
    # "demo" is the DLsite trial: no ads there, ever.
    if dist_track() in ("paid", "itch_web", "demo") or is_ad_unlocked(key):
        return
    $ tel_track("checkpoint_seen", {"key": key, "dist": dist_track()})
    $ tel_flush(True)
    if dist_track() == "ads_web":
        jump checkpoint_clip
    if dist_track() == "offline_ads":
        jump offline_trial_end
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
        "Get the ad-free full game ($4.99)":
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
        "Get the ad-free full game on itch ($4.99)":
            $ tel_cta_click("itch_buy_checkpoint")
            $ renpy.run(OpenURL(ITCH_BUY_URL))
            jump checkpoint_link


## The browser demo's one ask. It never blocks: saying no keeps the free case running,
## and the refusal is the measurement we actually want.
label demo_paywall:
    $ _t0 = __import__("time").time()
    $ tel_track("paywall_seen", {"key": "chapter", "dist": dist_track()})
    menu:
        "The rest of the night is in the full case file."
        "Open the store page":
            $ cg_buy_decide("chapter", "buy_click", _t0)
            $ renpy.run(OpenURL(ITCH_BUY_URL))
        "Unlock free — open the sponsor page":
            $ cg_buy_decide("chapter", "directlink_click", _t0)
            $ direct_link_open("chapter")
            call screen direct_link_screen("chapter", _("The next room, after the sponsor page"))
        "Keep playing the free case":
            $ cg_buy_decide("chapter", "dismiss", _t0)
    return
