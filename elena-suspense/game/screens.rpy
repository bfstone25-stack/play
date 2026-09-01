## Screens configuration for Ren'Py 8

init -1:
    style default:
        font gui.text_font
        size gui.text_size
        color gui.text_color

    style say_label:
        font gui.name_text_font
        size gui.name_text_size
        color gui.accent_color
        bold True

    style say_dialogue:
        font gui.text_font
        size gui.text_size
        color gui.text_color

    style say_thought:
        font gui.text_font
        size gui.text_size
        color "#c8c0b8"
        italic True

    style say_window:
        background Transform("#100c14", alpha=0.88)
        xalign 0.5
        xsize 1800
        yalign 0.98
        ysize 260
        padding (50, 30, 50, 30)

    style choice_vbox:
        xalign 0.5
        yalign 0.5
        spacing 25

    style choice_button:
        background Transform("#241a28", alpha=0.92)
        hover_background Transform("#3d2238", alpha=0.95)
        xsize 1100
        ysize 75
        padding (30, 15, 30, 15)

    style choice_button_text:
        xalign 0.5
        yalign 0.5
        size 30
        idle_color "#f0e6dc"
        hover_color "#ffdfa0"

## Say Screen
screen say(who, what):
    style_prefix "say"

    window:
        id "window"

        if who is not None:
            window:
                id "namebox"
                style "namebox"
                text who id "who"

        text what id "what"

    use quick_menu

## Choice Screen
screen choice(items):
    style_prefix "choice"

    vbox:
        for i in items:
            textbutton i.caption action i.action

## Quick Menu
screen quick_menu():
    zorder 100

    if quick_menu:
        hbox:
            style_prefix "quick"
            xalign 0.95
            yalign 0.98
            spacing 20

            textbutton _("Back") action Rollback()
            textbutton _("History") action ShowMenu('history')
            textbutton _("Skip") action Skip() alternate Skip(fast=True)
            textbutton _("Auto") action Preference("auto-forward", "toggle")
            textbutton _("Save") action ShowMenu('save')
            textbutton _("Q.Save") action QuickSave()
            textbutton _("Q.Load") action QuickLoad()
            textbutton _("Prefs") action ShowMenu('preferences')

default quick_menu = True

## Main Menu Screen
screen main_menu():
    tag menu

    add "#0d0912"

    # Dark Academia ambient decoration
    vbox:
        xalign 0.12
        yalign 0.4
        spacing 25

        text _("ELENA") size 72 color "#d99b66" bold True
        text _("CRIMSON ARCHIVES") size 34 color "#a88c7c"

        null height 30

        textbutton _("Start Game") action Start() text_size 32 text_hover_color "#ffdfa0"
        textbutton _("Load Game") action ShowMenu("load") text_size 32 text_hover_color "#ffdfa0"
        textbutton _("CG Gallery") action ShowMenu("cg_gallery") text_size 32 text_hover_color "#ffdfa0"
        textbutton _("Preferences") action ShowMenu("preferences") text_size 32 text_hover_color "#ffdfa0"
        textbutton _("About") action ShowMenu("about") text_size 32 text_hover_color "#ffdfa0"
        textbutton _("Quit") action Quit(confirm=not main_menu) text_size 32 text_hover_color "#ffdfa0"

    vbox:
        xalign 0.92
        yalign 0.95
        text _("v0.1.0 MVP | Ren'Py 8") size 20 color "#685850"

## Game Menu Screen (Shell for Save/Load/Prefs)
screen game_menu(title, scroll=None, yinitial=0.0):
    style_prefix "game_menu"

    add "#120e18"

    frame:
        style "game_menu_outer_frame"
        xsize 1920
        ysize 1080
        background None

        hbox:
            # Navigation Left Column
            vbox:
                xsize 340
                yalign 0.15
                spacing 20
                xoffset 80

                text title size 42 color "#d99b66" bold True
                null height 20

                textbutton _("Return") action Return() text_size 28
                textbutton _("History") action ShowMenu("history") text_size 28
                textbutton _("Save") action ShowMenu("save") text_size 28
                textbutton _("Load") action ShowMenu("load") text_size 28
                textbutton _("CG Gallery") action ShowMenu("cg_gallery") text_size 28
                textbutton _("Preferences") action ShowMenu("preferences") text_size 28
                textbutton _("Main Menu") action MainMenu() text_size 28
                textbutton _("Quit") action Quit() text_size 28

            # Content Right Box
            frame:
                xsize 1400
                ysize 900
                xalign 0.5
                yalign 0.5
                background Transform("#1d1522", alpha=0.9)
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
                                color "#d99b66"
                                bold True
                        $ what = renpy.filter_text_tags(h.what, allow=gui.history_allow_tags)
                        text what:
                            style "history_text"
                            color "#e0d8cf"

## Preferences Screen
screen preferences():
    tag menu
    use game_menu(_("Preferences")):
        vbox:
            spacing 30
            hbox:
                spacing 60
                vbox:
                    spacing 15
                    text _("Display") size 30 color "#d99b66"
                    textbutton _("Window") action Preference("display", "window")
                    textbutton _("Fullscreen") action Preference("display", "fullscreen")

                vbox:
                    spacing 15
                    text _("Music Volume") size 30 color "#d99b66"
                    bar value Preference("music volume") xsize 350

                vbox:
                    spacing 15
                    text _("Sound Volume") size 30 color "#d99b66"
                    bar value Preference("sound volume") xsize 350

                vbox:
                    spacing 15
                    text _("Text Speed") size 30 color "#d99b66"
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
                    background Transform("#281c2e", alpha=0.9)
                    hover_background Transform("#462b4c", alpha=0.95)

                    vbox:
                        xalign 0.5
                        yalign 0.5
                        spacing 10
                        text "Slot [slot]" size 26 color "#d99b66" xalign 0.5
                        add FileScreenshot(slot) xalign 0.5 xsize 360 ysize 202
                        text FileTime(slot, format=_("{#file_time}%Y-%m-%d %H:%M"), empty=_("empty slot")) size 18 color "#a09890" xalign 0.5

## About Screen
screen about():
    tag menu
    use game_menu(_("About")):
        vbox:
            spacing 20
            text "[config.name!t]" size 38 color "#d99b66" bold True
            text _("Version [config.version!t]") size 24 color "#b0a095"
            null height 20
            text _("A 15-minute branching narrative Suspense / Softcore Ecchi Visual Novel.") size 26 color "#e0d8d0"
            text _("Designed for multi-platform release on F95zone, DLsite, Patreon, and Web portals.") size 26 color "#e0d8d0"
            null height 30
            text _("Engine: Ren'Py [renpy.version_only]") size 22 color "#807068"

## Confirm Screen
screen confirm(message, yes_action, no_action):
    modal True
    zorder 200
    add Transform("#000000", alpha=0.7)

    frame:
        xalign 0.5
        yalign 0.5
        xsize 700
        ysize 300
        background Transform("#1d1522", alpha=0.98)
        padding (40, 40, 40, 40)

        vbox:
            xalign 0.5
            yalign 0.5
            spacing 40
            text message size 28 color "#f0e6dc" xalign 0.5
            hbox:
                xalign 0.5
                spacing 80
                textbutton _("Yes") action yes_action text_size 30 text_hover_color "#d99b66"
                textbutton _("No") action no_action text_size 30 text_hover_color "#d99b66"

## Notify Screen
screen notify(message):
    zorder 150
    style_prefix "notify"

    frame:
        xalign 0.5
        yalign 0.08
        background Transform("#2b1b30", alpha=0.92)
        padding (30, 15, 30, 15)
        text message size 24 color "#ffdfa0"

    timer 3.25 action Hide('notify')
