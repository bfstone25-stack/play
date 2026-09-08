## 03_endscreen.rpy — End CTA after full 5-chapter free arc

screen end_screen_cta():
    tag menu

    key "K_g" action ShowMenu("cg_gallery")
    key "g" action ShowMenu("cg_gallery")
    key "K_r" action Start()
    key "r" action Start()
    key "K_m" action MainMenu()
    key "m" action MainMenu()

    add "images/bg/study_normal.webp"

    vbox:
        xalign 0.5
        yalign 0.42
        spacing 22

        text _("ELENA: CRIMSON ARCHIVES") size 42 color "#d99b66" bold True xalign 0.5
        text _("Chapters 1–5 Complete") size 28 color "#c8b8b0" xalign 0.5

        null height 12

        frame:
            xsize 1120
            ysize 210
            background Transform("#1d1424", alpha=0.92)
            padding (36, 22, 36, 22)

            vbox:
                spacing 10
                xalign 0.5
                text _("Thank you for reading to the end. Support the next chapters:") size 24 color "#ffdfa0" bold True xalign 0.5
                text _("• Uncensored CG packs, voice, and side routes") size 20 color "#f0e6dc"
                text _("• Early Chapter updates via Patreon / SubscribeStar") size 20 color "#f0e6dc"
                text _("• Paid DRM-free builds on itch (Adult) + DLsite") size 20 color "#f0e6dc"

        null height 10

        hbox:
            xalign 0.5
            spacing 18

            textbutton _("★ Full game on itch.io ($2.99)"):
                action [Function(tel_cta_click, "itch"), OpenURL("https://bfstone25-stack.itch.io/elena-crimson-archives")]
                text_size 20
                text_color "#ffffff"
                text_hover_color "#ffe0a0"
                background Transform("#d95a43", alpha=0.9)
                hover_background Transform("#f2725c", alpha=1.0)
                padding (16, 12, 16, 12)

            textbutton _("Patreon"):
                action [Function(tel_cta_click, "patreon"), OpenURL("https://www.patreon.com/")]
                text_size 20
                text_color "#ffffff"
                text_hover_color "#ffe0a0"
                background Transform("#f96854", alpha=0.9)
                hover_background Transform("#ff7a68", alpha=1.0)
                padding (16, 12, 16, 12)

            textbutton _("SubscribeStar"):
                action [Function(tel_cta_click, "subscribestar"), OpenURL("https://subscribestar.adult/")]
                text_size 20
                text_color "#ffffff"
                text_hover_color "#ffe0a0"
                background Transform("#2f6f4e", alpha=0.9)
                hover_background Transform("#3d8f64", alpha=1.0)
                padding (16, 12, 16, 12)

            textbutton _("DLsite"):
                action [Function(tel_cta_click, "dlsite"), OpenURL("https://www.dlsite.com/maniax/")]
                text_size 20
                text_color "#ffffff"
                text_hover_color "#ffe0a0"
                background Transform("#2b5bb8", alpha=0.9)
                hover_background Transform("#3d75e0", alpha=1.0)
                padding (16, 12, 16, 12)

        null height 8

        textbutton _("💬 F95zone Thread"):
            xalign 0.5
            action [Function(tel_cta_click, "f95"), OpenURL("https://f95zone.to/threads/elena-crimson-archives-v0-1-0-flat-404.313771/")]
            text_size 20
            text_color "#e0d0ff"
            text_hover_color "#ffffff"
            padding (12, 8, 12, 8)

        null height 14

        hbox:
            xalign 0.5
            spacing 36

            textbutton _("🖼 CG Gallery"):
                action ShowMenu("cg_gallery")
                text_size 24
                text_color "#ffdfa0"
                text_hover_color "#ffffff"
                background Transform("#24172a", alpha=0.92)
                hover_background Transform("#3d2238", alpha=0.95)
                padding (18, 10, 18, 10)

            textbutton _("↺ Replay from Chapter 1"):
                action Start()
                text_size 24
                text_color "#d99b66"
                text_hover_color "#ffe0a0"
                background Transform("#24172a", alpha=0.92)
                hover_background Transform("#3d2238", alpha=0.95)
                padding (18, 10, 18, 10)

            textbutton _("⌂ Title"):
                action MainMenu()
                text_size 24
                text_color "#d99b66"
                text_hover_color "#ffe0a0"
                background Transform("#24172a", alpha=0.92)
                hover_background Transform("#3d2238", alpha=0.95)
                padding (18, 10, 18, 10)

label end_cta_screen:
    stop music fadeout 2.0
    stop ambience fadeout 2.0
    play music suspense_theme fadein 2.0
    $ tel_track("end_cta", {"chapters": chapter_cleared, "ending": chosen_ending})
    $ tel_flush(True)
    call screen end_screen_cta
    return


## Web demo gate: Chapter 1 is free in the browser; the paid download continues the story.
screen demo_paywall_screen():
    tag menu
    key "K_g" action ShowMenu("cg_gallery")
    key "K_m" action MainMenu()

    add "images/bg/study_dark.webp"

    vbox:
        xalign 0.5
        yalign 0.40
        spacing 18

        text _("THE FREE CHAPTER ENDS HERE") size 44 color "#d99b66" bold True xalign 0.5
        if demo_cut == "control":
            text _("She has your key in her hand and has not given it back.") size 26 color "#c8b8b0" xalign 0.5
        elif demo_cut == "pact":
            text _("She kissed you first. It was careful for about two seconds.") size 26 color "#c8b8b0" xalign 0.5
        else:
            text _("She walked out with the photographs and your handwriting.") size 26 color "#c8b8b0" xalign 0.5

        null height 6

        text _("Six more scenes are in the full game.") size 22 color "#ffdfa0" xalign 0.5

        hbox:
            xalign 0.5
            spacing 10
            add "cg_locked_climax_control" zoom 0.62
            add "cg_locked_climax_pact" zoom 0.62
            add "cg_locked_coal_store" zoom 0.62
            add "cg_locked_annex" zoom 0.62
            add "cg_locked_muniment" zoom 0.62
            add "cg_locked_aftermath" zoom 0.62

        null height 4

        frame:
            xsize 1120
            xalign 0.5
            background Transform("#1d1424", alpha=0.92)
            padding (34, 18, 34, 18)
            vbox:
                spacing 8
                xalign 0.5
                text _("Chapters 1-5, DRM-free, Windows / Mac / Linux") size 22 color "#f0e6dc" xalign 0.5
                text _("Both routes played out in full, the crypt, the Dean's annex, the muniment room, three endings") size 20 color "#f0e6dc" xalign 0.5
                text _("$2.99 once. Every future chapter included.") size 24 color "#ffffff" bold True xalign 0.5

        null height 10

        hbox:
            xalign 0.5
            spacing 22

            textbutton _("★ Unlock the full game - $2.99"):
                action [Function(tel_cta_click, "itch_buy"), OpenURL(ITCH_BUY_URL)]
                text_size 26
                text_color "#ffffff"
                text_hover_color "#ffe0a0"
                background Transform("#d95a43", alpha=0.95)
                hover_background Transform("#f2725c", alpha=1.0)
                padding (26, 15, 26, 15)

            textbutton _("↺ Try the other route"):
                action Start()
                text_size 20
                text_color "#d99b66"
                text_hover_color "#ffe0a0"
                background Transform("#24172a", alpha=0.92)
                hover_background Transform("#3d2238", alpha=0.95)
                padding (18, 12, 18, 12)

            textbutton _("💬 F95zone"):
                action [Function(tel_cta_click, "f95"), OpenURL("https://f95zone.to/threads/elena-crimson-archives-v0-1-0-flat-404.313771/")]
                text_size 20
                text_color "#e0d0ff"
                text_hover_color "#ffffff"
                padding (14, 12, 14, 12)

label demo_paywall:
    stop music fadeout 2.0
    stop ambience fadeout 2.0
    play music suspense_theme fadein 2.0
    $ tel_track("end_cta", {"chapters": chapter_cleared, "ending": chosen_ending, "demo": True, "cut": demo_cut})
    $ tel_flush(True)
    call screen demo_paywall_screen
    return
