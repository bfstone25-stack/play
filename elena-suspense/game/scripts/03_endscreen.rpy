## 03_endscreen.rpy - High-Conversion CTA Endscreen for Patreon, DLsite, F95zone, and Community Channels

screen end_screen_cta():
    tag menu

    key "K_g" action ShowMenu("cg_gallery")
    key "g" action ShowMenu("cg_gallery")
    key "K_r" action Start()
    key "r" action Start()
    key "K_m" action MainMenu()
    key "m" action MainMenu()

    # Background
    add "images/bg/study_normal.webp"

    vbox:
        xalign 0.5
        yalign 0.45
        spacing 25

        text _("CHAPTER 1 COMPLETE") size 56 color "#d99b66" bold True xalign 0.5
        text _("Elena: Crimson Archives — Chapter 2 Coming Soon") size 26 color "#c8b8b0" xalign 0.5

        null height 20

        frame:
            xsize 1100
            ysize 230
            background Transform("#1d1424", alpha=0.92)
            padding (40, 25, 40, 25)

            vbox:
                spacing 12
                xalign 0.5
                text _("Support the development to unlock:") size 24 color "#ffdfa0" bold True xalign 0.5
                text _("• Chapter 2 & 3: The Crypt Vault & Forbidden Rituals") size 20 color "#f0e6dc"
                text _("• 12+ Full HD Uncensored Ecchi & H-CGs with Animated Live2D/WebM variants") size 20 color "#f0e6dc"
                text _("• Exclusive Voice Acting DLC & Early Access Beta Builds") size 20 color "#f0e6dc"

        null height 15

        # Call-to-Action Buttons
        hbox:
            xalign 0.5
            spacing 30

            textbutton _("★ Support on Patreon (Early Builds)"):
                action OpenURL("https://www.patreon.com/")
                text_size 24
                text_color "#ffffff"
                text_hover_color "#ffe0a0"
                background Transform("#d95a43", alpha=0.9)
                hover_background Transform("#f2725c", alpha=1.0)
                padding (25, 15, 25, 15)

            textbutton _("🛒 DLsite Official Store Page"):
                action OpenURL("https://www.dlsite.com/")
                text_size 24
                text_color "#ffffff"
                text_hover_color "#ffe0a0"
                background Transform("#2b5bb8", alpha=0.9)
                hover_background Transform("#3d75e0", alpha=1.0)
                padding (25, 15, 25, 15)

            textbutton _("💬 F95zone Discussion Thread"):
                action OpenURL("https://f95zone.to/")
                text_size 24
                text_color "#ffffff"
                text_hover_color "#ffe0a0"
                background Transform("#5a3c78", alpha=0.9)
                hover_background Transform("#7850a0", alpha=1.0)
                padding (25, 15, 25, 15)

        null height 20

        # Navigation Buttons
        hbox:
            xalign 0.5
            spacing 40

            textbutton _("🖼 View CG Gallery"):
                action Show("cg_gallery")
                text_size 26
                text_color "#ffdfa0"
                text_hover_color "#ffffff"
                background Transform("#24172a", alpha=0.92)
                hover_background Transform("#3d2238", alpha=0.95)
                padding (20, 10, 20, 10)

            textbutton _("↺ Replay Chapter 1"):
                action Start()
                text_size 26
                text_color "#d99b66"
                text_hover_color "#ffe0a0"
                background Transform("#24172a", alpha=0.92)
                hover_background Transform("#3d2238", alpha=0.95)
                padding (20, 10, 20, 10)

            textbutton _("⌂ Return to Title"):
                action MainMenu()
                text_size 26
                text_color "#d99b66"
                text_hover_color "#ffe0a0"
                background Transform("#24172a", alpha=0.92)
                hover_background Transform("#3d2238", alpha=0.95)
                padding (20, 10, 20, 10)

label end_cta_screen:
    stop music fadeout 2.0
    stop ambience fadeout 2.0
    play music suspense_theme fadein 2.0
    call screen end_screen_cta
    return
