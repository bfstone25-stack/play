## 07_paywall.rpy — the itch web track's cut point.
##
## In room-704 this lived in 03_act3.rpy; here it gets its own file because the fork's cut is
## in a different place and says a different thing. The browser sample is the cold open plus
## the first two appraisals — Tamsin and Ivo — which is exactly enough to have used the
## reading fee twice and to have been asked, once, by a person, not to look.
##
## This is the ONLY screen in the game that says a dollar sign. The reading fee never does.
## Keeping those two vocabularies apart is mitigation (2) for the second-paywall risk: the
## shop's money is the shop's money and is never convertible.

screen demo_paywall_screen():
    tag menu
    add "bg black"
    vbox:
        xalign 0.5
        yalign 0.28
        spacing 14
        text _("THE FREE PART ENDS HERE") size 46 color "#e8b84a" bold True xalign 0.5
        if "ring" in run.readings_taken:
            text _("You put your palm on a ring a man had just asked you not to touch. There are three more objects in the book tonight and one of them has your name on the ticket.") size 23 color "#c8b8b0" xalign 0.5
        elif run.readings_refused:
            text _("You priced them on brass and gold and let them go home. There are three more objects in the book tonight and one of them has your name on the ticket.") size 23 color "#c8b8b0" xalign 0.5
        else:
            text _("Two appraisals down. There are three more objects in the book tonight and one of them has your name on the ticket.") size 23 color "#c8b8b0" xalign 0.5
        null height 6
        text _("Till: [run.till] · readings taken: [len(run.readings_taken)] · against the estate: [core.DEBT]") size 19 color "#7f7a8c" xalign 0.5
        null height 8
        hbox:
            xalign 0.5
            spacing 12
            add "cg_locked_veil" zoom 0.30
            add "cg_locked_market" zoom 0.30
            add "cg_locked_collateral" zoom 0.30
        null height 8
        frame:
            xsize 1120
            xalign 0.5
            background Transform("#161422", alpha=0.94)
            padding (34, 18, 34, 18)
            vbox:
                spacing 8
                xalign 0.5
                text _("Midnight Pawn: Collateral — the whole night, nothing censored") size 24 color "#f0e6dc" xalign 0.5
                text _("Five appraisals, the Ossuary Market, six readings, three endings. A Reading Ledger that remembers what you refused to look at. Windows / macOS / Linux, DRM-free, no ads.") size 19 color "#f0e6dc" xalign 0.5
                text _("[GAME_PRICE] once.") size 26 color "#ffffff" bold True xalign 0.5
        null height 10
        hbox:
            xalign 0.5
            spacing 20
            textbutton _("★ Unlock the whole night — [GAME_PRICE]"):
                action [Function(tel_cta_click, "itch_buy"), OpenURL(ITCH_BUY_URL)]
                text_size 26 text_color "#ffffff" text_hover_color "#ffe0a0"
                background Transform("#c8503c", alpha=0.95)
                hover_background Transform("#e8674f", alpha=1.0)
                padding (26, 15, 26, 15)
            textbutton _("↺ Price them differently"):
                action Start()
                text_size 20 text_color "#d99b66" text_hover_color "#ffe0a0"
                background Transform("#24202e", alpha=0.92)
                padding (18, 12, 18, 12)
        null height 8
        textbutton _("Open the Reading Ledger"):
            action Call("show_ledger", from_current=True)
            xalign 0.5
            text_size 20 text_color "#e8b84a"
            background Transform("#24172a", alpha=0.92)
            padding (16, 9, 16, 9)
        null height 10
        text _("Prefer free? The ad-supported web edition unlocks every reading with short sponsor clips.") size 18 color "#8d8f9b" xalign 0.5
        null height 14
        use cross_promo


label demo_paywall:
    stop music fadeout 2.0
    play music theme fadein 2.0
    $ demo_cut = "appraisal_2"
    $ tel_track("end_cta", {"acts": act_cleared, "till": run.till, "demo": True, "cut": demo_cut, "taken": len(run.readings_taken)})
    $ tel_flush(True)
    call screen demo_paywall_screen
    return
