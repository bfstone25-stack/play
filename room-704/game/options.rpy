## Options configuration for Ren'Py 8
## Elena: Crimson Archives - Softcore / Suspense Narrative MVP

define config.screen_width = 1920
define config.screen_height = 1080

define config.name = _("Room 704")
define gui.show_name = True
define config.version = "0.1.0"
define gui.about = _("Elena: Crimson Archives\nA Dark Academia suspense romance visual novel.\nFlat 404 / Ren'Py 8.")

define build.name = "room_704"

define config.has_sound = True
define config.has_music = True
define config.has_voice = False

define config.main_menu_music = "audio/suspense_theme.ogg"
define config.enter_transition = dissolve
define config.exit_transition = dissolve
define config.intra_transition = dissolve
define config.after_load_transition = dissolve
define config.end_game_transition = fade
define config.window_show_transition = Dissolve(.2)
define config.window_hide_transition = Dissolve(.2)

default preferences.text_cps = 0
default preferences.afm_time = 15

define config.save_directory = "room_704-1789600000"

define config.window_icon = ""

define config.check_conflicting_properties = True

init python:
    build.directory_name = "room-704-v0.1.0"
    build.executable_name = "Room704"
    build.include_update = False

    build.classify('**~', None)
    build.classify('**.bak', None)
    build.classify('**/.**', None)
    build.classify('**/#**', None)
    build.classify('**/thumbs.db', None)
    build.classify('tools/**', None)
    build.classify('raw_assets/**', None)
    build.classify('dist/**', None)
    ## The browser ad script must never ride along in a downloadable build: desktop
    ## Ren'Py cannot run it, and a sponsor domain sitting inside a build we describe
    ## as ad-free is exactly what got the F95 account banned on 2026-09-16.
    build.classify('web/**', None)
    # Store-page art and writing must not ship inside the build (was ~8 MB of the web download).
    build.classify('promo/**', None)
    build.classify('f95_posts/**', None)
    build.classify('itch_posts/**', None)
    build.classify('**.md', None)
    build.classify('errors.txt', None)
    build.classify('log.txt', None)
    build.classify('progressive_download.txt', None)

    build.classify('game/**.png', 'archive')
    build.classify('game/**.jpg', 'archive')
    build.classify('game/**.webp', 'archive')
    build.classify('game/**.ogg', 'archive')
    build.classify('game/**.rpy', 'archive')
    build.classify('game/**.rpyc', 'archive')

    build.documentation('*.html')
    build.documentation('*.txt')
