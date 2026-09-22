## Screens for Confession Room — the skin described in ops/adult_forks/TITLE_SCREENS.md.
##
## One face, one treatment: Stardos Stencil for the mark (images/title/logo.png, drawn by
## ops/keyvisual_art/logotype.py — bone-white stencil, ink bleed, a red case stamp),
## Courier Prime for everything else, because everything else in this game is a police
## file. Ink, bone white, red stamp. The title screen is the key visual — the suspect at
## the table under the one lamp, her face half-lit — under a breathing camera, the lamp
## swinging its light, haze drifting, the blinds' shadow across the wall.

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
        color "#cfc8b8"
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
        idle_color "#ece5d6"
        hover_color "#1a1a1c"

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
        font "fonts/CourierPrime-Bold.ttf"
        size 28
        kerning 2
        idle_color "#e8e2d6"
        hover_color "#ffffff"
        insensitive_color "#5e5a52"
        outlines [(3, "#060607", 0, 0), (1, "#060607", 0, 2)]
        hover_outlines [(3, "#060607", 0, 0), (1, "#c41e24", 0, 0)]

    style nav_button:
        xsize 300
        ysize 48
        padding (10, 4, 10, 4)
        background None
        hover_background Frame("images/ui/title_hover.png", 6, 6)

    style nav_button_text:
        font "fonts/CourierPrime-Bold.ttf"
        size 24
        kerning 2
        idle_color "#c4bdae"
        hover_color "#ffffff"
        selected_color "#ece5d6"

    style pref_button:
        background None
        padding (10, 4, 10, 4)
        hover_background Frame("images/ui/title_hover.png", 6, 6)

    style pref_button_text:
        font gui.text_font
        size 26
        idle_color "#b8b1a2"
        hover_color "#ffffff"
        selected_color "#ece5d6"

    style heading_text:
        font "fonts/CourierPrime-Bold.ttf"
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
    font "fonts/CourierPrime-Bold.ttf"
    size 17
    kerning 1
    idle_color "#847e72"
    hover_color "#ece5d6"
    selected_color gui.accent_color

default quick_menu = True

## ---- Title screen ------------------------------------------------------------------------
## The key visual with a breathing camera: 18 seconds out, 18 seconds back, never still.
transform kv_breathe:
    subpixel True
    xalign 0.5 yalign 0.5
    zoom 1.03 xoffset 0 yoffset 0
    block:
        ease 18.0 zoom 1.08 xoffset -14 yoffset 6
        ease 18.0 zoom 1.03 xoffset 0 yoffset 0
        repeat

## The one lamp, swinging: its pool of light slides a little and swells with it.
transform lamp_swing:
    subpixel True
    alpha 0.62 xoffset -26
    block:
        ease 3.4 alpha 0.72 xoffset 26
        ease 3.4 alpha 0.60 xoffset -26
        repeat

## Haze: two copies of a low-frequency sheet crossing each other slowly.
transform haze_drift_a:
    subpixel True
    alpha 0.26 xoffset -80
    block:
        ease 26.0 xoffset 80 alpha 0.34
        ease 26.0 xoffset -80 alpha 0.26
        repeat

transform haze_drift_b:
    subpixel True
    alpha 0.18 xoffset 60 yoffset 30
    block:
        ease 31.0 xoffset -60 yoffset -30
        ease 31.0 xoffset 60 yoffset 30
        repeat

transform logo_settle:
    subpixel True
    alpha 0.0 zoom 1.06 yoffset -10
    pause 0.7
    ease 1.6 alpha 1.0 zoom 1.0 yoffset 0

## The stamp lands after the mark: a hard snap, not a fade.
transform fade_in_after(t):
    alpha 0.0 xoffset -16
    pause t
    ease 0.7 alpha 1.0 xoffset 0

transform scrim_in:
    alpha 0.0
    ease 1.2 alpha 1.0

screen main_menu():
    tag menu

    on "show" action Play("sound", "audio/title_sting.ogg")

    add "#060607"
    add "images/title/keyvisual.webp" at kv_breathe
    # Blinds and haze were set before the key visual existed, against a placeholder that
    # was nearly black. Over the real plate — whose back wall is a lit one-way mirror —
    # they stacked into bright horizontal banding across the whole right half and flattened
    # the room. They are atmosphere, not a second subject: enough to move, not enough to see.
    add "images/title/blinds.png" alpha 0.22
    add "images/title/light.png" at lamp_swing
    add "images/title/haze.png" at haze_drift_a
    add "images/title/haze.png" at haze_drift_b
    add "images/title/vignette.png"
    add "images/title/scrim.png" at scrim_in

    key "K_s" action Start()
    key "K_RETURN" action Start()
    key "K_SPACE" action Start()

    ## The mark, stencilled on the wall left of the table.
    add "images/title/logo.png":
        at logo_settle
        xpos 60 ypos 60
        zoom 0.4

    text _("Three suspects. Twelve questions. One detail only the killer could know."):
        at fade_in_after(2.0)
        font "fonts/CourierPrime-Regular.ttf"
        size 24
        color "#e8e2d6"
        outlines [(3, "#060607", 0, 0)]
        xpos 96 ypos 396

    vbox:
        xpos 96 ypos 470
        spacing 4
        at fade_in_after(2.3)

        textbutton _("Open the case") action Start() style "title_button"
        textbutton _("Continue") action ShowMenu("load") style "title_button"
        textbutton _("Preferences") action ShowMenu("preferences") style "title_button"
        textbutton _("About") action ShowMenu("about") style "title_button"
        textbutton _("Quit") action Quit(confirm=not main_menu) style "title_button"

    ## Rating and studio mark: small, bottom left, always the same place.
    hbox:
        at fade_in_after(2.6)
        xpos 60 yalign 0.955
        spacing 22
        add "images/ui/rating.png" zoom 0.72 yalign 0.5
        vbox:
            yalign 0.5
            spacing 4
            add "images/ui/studio.png"
            text "v[config.version]" font "fonts/CourierPrime-Regular.ttf" size 15 color "#7e7970" outlines [(2, "#060607", 0, 0)]

## Game Menu Screen (Shell for Save/Load/Prefs)
screen game_menu(title, scroll=None, yinitial=0.0):
    style_prefix "game_menu"

    add "#060607"
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
                            color "#e2dccd"

## Preferences Screen
screen preferences():
    tag menu
    use game_menu(_("Preferences")):
        style_prefix "pref"
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
                    text _("Sound") style "heading_text"
                    textbutton _("Mute all") action Preference("all mute", "toggle")

            ## Second row: four columns, three of them 350px wide, overflowed 1920 next to
            ## the menu's left nav and pushed the sliders off the screen.
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
                        text FileTime(slot, format=_("{#file_time}%Y-%m-%d %H:%M"), empty=_("empty slot")) size 18 color "#a29b8c" xalign 0.5

## About Screen
screen about():
    tag menu
    use game_menu(_("About")):
        vbox:
            spacing 20
            add "images/title/logo.png" zoom 0.36
            text _("Version [config.version!t]") size 24 color "#b8b1a2"
            null height 20
            text _("An interrogation. Three suspects, twelve questions, and one detail only the killer could know.") size 26 color "#e2dccd"
            text _("Designed for multi-platform release on F95zone, DLsite, Patreon, and Web portals.") size 26 color "#e2dccd"
            null height 30
            add "images/ui/studio.png"
            text _("Engine: Ren'Py [renpy.version_only]") size 22 color "#6e6960"

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
            text message size 28 color "#ece5d6" xalign 0.5 text_align 0.5
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
        text message size 24 color "#ece5d6"

    timer 3.25 action Hide('notify')
