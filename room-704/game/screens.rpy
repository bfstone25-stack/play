## Screens for Room 704 — the skin described in ops/adult_forks/TITLE_SCREENS.md.
##
## One face, one treatment: Marcellus (the engraved plate, images/title/logo.png, drawn
## by ops/keyvisual_art/logotype.py) for headings and buttons, Josefin Sans for what is
## read. Brass, night blue, cream. The title screen is the key visual — Mira at the night
## desk, the register, the bell, the key box — under a breathing camera, rain on the glass,
## the lamp swelling and the neon through the window; the plate settles in on the right,
## where the counter is dark.

init -1:
    style default:
        font gui.text_font
        size gui.text_size
        color gui.text_color

    style say_label:
        font gui.name_text_font
        size gui.name_text_size
        color gui.accent_color
        bold False

    style say_dialogue:
        font gui.text_font
        size gui.text_size
        color gui.text_color
        line_spacing 4

    style namebox:
        xalign 0.0
        yalign 0.0
        padding (0, 0, 0, 0)

    style namebox_label:
        font gui.name_text_font
        size gui.name_text_size
        color gui.accent_color

    style say_thought:
        font gui.text_font
        size gui.text_size
        color "#d5ccb8"
        italic True

    style say_window:
        background Frame("images/ui/textbox.png", 0, 60, 0, 0)
        xalign 0.5
        xsize 1920
        yalign 1.0
        ysize 290
        padding (200, 62, 200, 30)

    style choice_vbox:
        xalign 0.5
        yalign 0.5
        spacing 22

    style choice_button:
        background Frame("images/ui/choice_idle.png", 14, 14)
        hover_background Frame("images/ui/choice_hover.png", 14, 14)
        xsize 1100
        ysize 78
        padding (30, 15, 30, 15)
        hover_sound "audio/ui_hover.ogg"
        activate_sound "audio/ui_click.ogg"

    style choice_button_text:
        font gui.interface_text_font
        xalign 0.5
        yalign 0.5
        size 26
        idle_color "#eee2c8"
        hover_color "#fff7e6"

    ## Every button in the game: the same face, the same two sounds.
    style button:
        hover_sound "audio/ui_hover.ogg"
        activate_sound "audio/ui_click.ogg"

    style button_text:
        font gui.interface_text_font
        size gui.interface_text_size
        idle_color gui.idle_color
        hover_color gui.hover_color
        selected_color gui.selected_color
        insensitive_color gui.insensitive_color

    ## Title-screen menu entries: Cinzel, tracked out, a brass rule that grows on hover.
    style title_button:
        xsize 380
        ysize 56
        padding (18, 6, 18, 6)
        background None
        hover_background Frame("images/ui/title_hover.png", 6, 6)

    style title_button_text:
        font "fonts/Marcellus-Regular.ttf"
        size 30
        kerning 4
        idle_color "#e7dcbe"
        hover_color "#fff7e6"
        insensitive_color "#6b6350"
        outlines [(3, "#04060c", 0, 0), (1, "#04060c", 0, 2)]

    style nav_button:
        xsize 300
        ysize 48
        padding (10, 4, 10, 4)
        background None
        hover_background Frame("images/ui/title_hover.png", 6, 6)

    style nav_button_text:
        font "fonts/Marcellus-Regular.ttf"
        size 24
        kerning 2
        idle_color "#cbbfa2"
        hover_color "#fff7e6"
        selected_color "#eee2c8"

    style pref_button:
        background None
        padding (10, 4, 10, 4)
        hover_background Frame("images/ui/title_hover.png", 6, 6)

    style pref_button_text:
        font gui.text_font
        size 26
        idle_color "#bdb298"
        hover_color "#fff7e6"
        selected_color "#eee2c8"

    style heading_text:
        font "fonts/Marcellus-Regular.ttf"
        size 30
        kerning 2
        color gui.accent_color

## Say Screen
screen say(who, what):
    style_prefix "say"

    window:
        id "window"

        vbox:
            spacing 6
            if who is not None:
                window:
                    id "namebox"
                    style "namebox"
                    background Frame("images/ui/namebox.png", 8, 8)
                    xsize 420
                    ysize 52
                    padding (22, 8, 22, 8)
                    yoffset -70
                    text who id "who" yalign 0.5

            text what id "what"

    use quick_menu

## Choice Screen
screen choice(items):
    style_prefix "choice"

    key "K_1" action items[0].action
    key "1" action items[0].action
    if len(items) > 1:
        key "K_2" action items[1].action
        key "2" action items[1].action
    if len(items) > 2:
        key "K_3" action items[2].action
        key "3" action items[2].action

    vbox:
        yalign 0.5
        xalign 0.5
        spacing 22

        for i in items:
            textbutton i.caption action i.action:
                style "choice_button"

## Quick Menu
screen quick_menu():
    zorder 100

    if quick_menu:
        hbox:
            style_prefix "quick"
            xalign 0.98
            yalign 0.995
            spacing 24

            textbutton _("Back") action Rollback()
            textbutton _("History") action ShowMenu('history')
            textbutton _("Skip") action Skip() alternate Skip(fast=True)
            textbutton _("Auto") action Preference("auto-forward", "toggle")
            textbutton _("Save") action ShowMenu('save')
            textbutton _("Q.Save") action QuickSave()
            textbutton _("Q.Load") action QuickLoad()
            textbutton _("Prefs") action ShowMenu('preferences')

style quick_button:
    background None
    padding (6, 2, 6, 2)
    hover_sound None
    activate_sound "audio/ui_click.ogg"

style quick_button_text:
    font "fonts/Marcellus-Regular.ttf"
    size 17
    kerning 1
    idle_color "#8c8470"
    hover_color "#eee2c8"
    selected_color gui.accent_color

default quick_menu = True

## ---- Title screen ------------------------------------------------------------------------
## The key visual with a breathing camera: 18 seconds out, 18 seconds back, never still.
transform kv_breathe:
    subpixel True
    xalign 0.5 yalign 0.5
    zoom 1.03 xoffset 0 yoffset 0
    block:
        ease 18.0 zoom 1.075 xoffset 16 yoffset -10
        ease 18.0 zoom 1.03 xoffset 0 yoffset 0
        repeat

## The desk lamp: a slow swell with a couple of faster dips — a bulb, not a strobe.
transform lamp_flicker:
    alpha 0.55
    block:
        ease 2.6 alpha 0.72
        ease 1.9 alpha 0.54
        ease 0.18 alpha 0.66
        ease 0.22 alpha 0.50
        ease 3.1 alpha 0.70
        ease 0.5 alpha 0.60
        repeat

## The neon sign across the street: on, a stutter, on.
transform neon_buzz:
    alpha 0.45
    block:
        pause 2.3
        ease 0.08 alpha 0.15
        ease 0.10 alpha 0.48
        pause 0.4
        ease 0.06 alpha 0.20
        ease 0.14 alpha 0.42
        pause 3.7
        ease 0.9 alpha 0.52
        ease 1.4 alpha 0.44
        repeat

## Rain: the sheet is stacked twice and scrolled down by its own height, so it wraps.
transform rain_fall:
    subpixel True
    yoffset -1080 xoffset 0
    block:
        linear 2.4 yoffset 0 xoffset -12
        yoffset -1080 xoffset 0
        repeat

transform logo_settle:
    subpixel True
    alpha 0.0 zoom 1.04 yoffset -12
    pause 0.7
    ease 1.7 alpha 1.0 zoom 1.0 yoffset 0

transform fade_in_after(t):
    alpha 0.0 xoffset 16
    pause t
    ease 0.7 alpha 1.0 xoffset 0

transform scrim_in:
    alpha 0.0
    ease 1.2 alpha 1.0

screen main_menu():
    tag menu

    on "show" action Play("sound", "audio/title_sting.ogg")

    add "#04060c"
    add "images/title/keyvisual.webp" at kv_breathe
    add "images/title/neon.png" at neon_buzz
    add "images/title/light.png" at lamp_flicker
    add "images/title/rain.png" at rain_fall alpha 0.55
    add "images/title/rain.png" at rain_fall yoffset 1080 alpha 0.55
    add "images/title/vignette.png"
    add "images/title/scrim.png" at scrim_in

    key "K_s" action Start()
    key "K_RETURN" action Start()
    key "K_SPACE" action Start()

    ## The plate, screwed to the wall above the key box.
    add "images/title/logo.png":
        at logo_settle
        xanchor 1.0 xpos 1856 ypos 300
        zoom 0.56

    text _("One night. One floor. Nobody in the book."):
        at fade_in_after(2.0)
        font "fonts/JosefinSans-Regular.ttf"
        size 26
        kerning 1
        color "#e7dcbe"
        outlines [(3, "#04060c", 0, 0)]
        xanchor 1.0 xpos 1846 ypos 548

    vbox:
        xanchor 1.0 xpos 1856 ypos 610
        spacing 4
        at fade_in_after(2.3)

        textbutton _("Check In") action Start() style "title_button" text_xalign 1.0
        textbutton _("Continue") action ShowMenu("load") style "title_button" text_xalign 1.0
        textbutton _("Preferences") action ShowMenu("preferences") style "title_button" text_xalign 1.0
        textbutton _("About") action ShowMenu("about") style "title_button" text_xalign 1.0
        textbutton _("Quit") action Quit(confirm=not main_menu) style "title_button" text_xalign 1.0

    ## Rating and studio mark: small, bottom right, always the same place.
    hbox:
        at fade_in_after(2.6)
        xanchor 1.0 xpos 1860 yalign 0.955
        spacing 22
        vbox:
            yalign 0.5
            spacing 4
            xalign 1.0
            add "images/ui/studio.png" xalign 1.0
            text "v[config.version]" font "fonts/JosefinSans-Regular.ttf" size 15 color "#8d8670" outlines [(2, "#04060c", 0, 0)] xalign 1.0
        add "images/ui/rating.png" zoom 0.72 yalign 0.5

## Game Menu Screen (Shell for Save/Load/Prefs)
screen game_menu(title, scroll=None, yinitial=0.0):
    style_prefix "game_menu"

    add "#04060c"
    add "images/title/keyvisual.webp" alpha 0.35 xalign 0.5 yalign 0.5 zoom 1.03
    add "images/title/vignette.png"

    frame:
        style "game_menu_outer_frame"
        xsize 1920
        ysize 1080
        background None

        hbox:
            # Navigation Left Column
            vbox:
                xsize 340
                yalign 0.14
                spacing 8
                xoffset 80

                text title style "heading_text" size 36
                add "images/ui/rule.png" xsize 280 ysize 2
                null height 16

                textbutton _("Return") action Return() style "nav_button"
                textbutton _("History") action ShowMenu("history") style "nav_button"
                textbutton _("Save") action ShowMenu("save") style "nav_button"
                textbutton _("Load") action ShowMenu("load") style "nav_button"
                textbutton _("Preferences") action ShowMenu("preferences") style "nav_button"
                textbutton _("Main Menu") action MainMenu() style "nav_button"
                textbutton _("Quit") action Quit() style "nav_button"

            # Content Right Box
            frame:
                xsize 1400
                ysize 900
                xalign 0.5
                yalign 0.5
                background Frame("images/ui/panel.png", 16, 16)
                padding (40, 40, 40, 40)
                transclude

## History Screen
screen history():
    tag menu
    use game_menu(_("History"), scroll=("vpgrid" if gui.history_height else "viewport")):
        style_prefix "history"
        viewport:
            scrollbars "vertical"
            mousewheel True
            draggable True
            vbox:
                spacing 25
                for h in _history_list:
                    window:
                        has vbox
                        if h.who:
                            text h.who:
                                style "history_name"
                                font gui.name_text_font
                                color gui.accent_color
                        $ what = renpy.filter_text_tags(h.what, allow=gui.history_allow_tags)
                        text what:
                            style "history_text"
                            color "#e6dfcc"

## Preferences Screen
screen preferences():
    tag menu
    use game_menu(_("Preferences")):
        style_prefix "pref"
        ## Two rows, not one. Five columns — two of buttons and three 350px bars — added up
        ## past 1920 with the menu's left nav, so the volume bars sat off the right edge of
        ## the screen. A player on LewdCorner reported the menu music as "a very loud
        ## constant buzzing sound" and said there were "no sliders/mute under the audio
        ## tab": there were, he just could not see them.
        vbox:
            spacing 30
            hbox:
                spacing 60
                vbox:
                    spacing 12
                    text _("Display") style "heading_text"
                    textbutton _("Window") action Preference("display", "window")
                    textbutton _("Fullscreen") action Preference("display", "fullscreen")

                vbox:
                    spacing 12
                    text _("Language") style "heading_text"
                    textbutton "English" action Language(None)
                    textbutton "日本語" action Language("japanese")

                vbox:
                    spacing 12
                    text _("Sound") style "heading_text"
                    textbutton _("Mute all") action Preference("all mute", "toggle")

            hbox:
                spacing 60
                vbox:
                    spacing 12
                    text _("Music Volume") style "heading_text"
                    bar value Preference("music volume") xsize 350

                vbox:
                    spacing 12
                    text _("Sound Volume") style "heading_text"
                    bar value Preference("sound volume") xsize 350

                vbox:
                    spacing 12
                    text _("Text Speed") style "heading_text"
                    bar value Preference("text speed") xsize 350

## Save & Load Screens
screen save():
    tag menu
    use file_slots(_("Save"))

screen load():
    tag menu
    use file_slots(_("Load"))

screen file_slots(title):
    use game_menu(title):
        grid 3 2:
            spacing 30
            xalign 0.5
            yalign 0.5
            for i in range(1, 7):
                $ slot = i
                button:
                    action FileAction(slot)
                    xsize 400
                    ysize 320
                    background Frame("images/ui/slot_idle.png", 10, 10)
                    hover_background Frame("images/ui/slot_hover.png", 10, 10)

                    vbox:
                        xalign 0.5
                        yalign 0.5
                        spacing 10
                        text _("Slot [slot]") style "heading_text" size 22 xalign 0.5
                        add FileScreenshot(slot) xalign 0.5 xsize 360 ysize 202
                        text FileTime(slot, format=_("{#file_time}%Y-%m-%d %H:%M"), empty=_("empty slot")) size 18 color "#aca38c" xalign 0.5

## About Screen
screen about():
    tag menu
    use game_menu(_("About")):
        vbox:
            spacing 20
            add "images/title/logo.png" zoom 0.42
            text _("Version [config.version!t]") size 24 color "#bdb298"
            null height 20
            text _("A 15-minute branching narrative Suspense / Softcore Ecchi Visual Novel.") size 26 color "#e6dfcc"
            text _("Designed for multi-platform release on F95zone, DLsite, Patreon, and Web portals.") size 26 color "#e6dfcc"
            null height 30
            add "images/ui/studio.png"
            text _("Engine: Ren'Py [renpy.version_only]") size 22 color "#7d7660"

## Confirm Screen
screen confirm(message, yes_action, no_action):
    modal True
    zorder 200
    add Transform("#000000", alpha=0.7)

    frame:
        xalign 0.5
        yalign 0.5
        xsize 720
        ysize 320
        background Frame("images/ui/confirm.png", 16, 16)
        padding (40, 40, 40, 40)

        vbox:
            xalign 0.5
            yalign 0.5
            spacing 40
            text message size 28 color "#eee2c8" xalign 0.5 text_align 0.5
            hbox:
                xalign 0.5
                spacing 80
                textbutton _("Yes") action yes_action style "title_button" xsize 160 text_xalign 0.5
                textbutton _("No") action no_action style "title_button" xsize 160 text_xalign 0.5

## Notify Screen
screen notify(message):
    zorder 150
    style_prefix "notify"

    frame:
        xalign 0.5
        yalign 0.08
        background Frame("images/ui/namebox.png", 8, 8)
        padding (30, 15, 30, 15)
        text message size 24 color "#eee2c8"

    timer 3.25 action Hide('notify')
