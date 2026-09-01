## Options configuration for Ren'Py 8
## Elena: Crimson Archives - Softcore / Suspense Narrative MVP

define config.name = _("Elena: Crimson Archives")
define gui.show_name = True
define config.version = "0.1.0"
define gui.about = _("Elena: Crimson Archives\nA Dark Academia Suspense & Softcore Romance Visual Novel MVP.\nCreated with Ren'Py 8.")

define build.name = "elena_crimson_archives"

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

default preferences.text_cps = 50
default preferences.afm_time = 15

define config.save_directory = "elena_crimson_archives-1725200000"

define config.window_icon = ""

define config.check_conflicting_properties = True

init python:
    build.directory_name = "elena-crimson-archives-v0.1.0"
    build.executable_name = "ElenaCrimsonArchives"
    build.include_update = False

    build.classify('**~', None)
    build.classify('**.bak', None)
    build.classify('**/.**', None)
    build.classify('**/#**', None)
    build.classify('**/thumbs.db', None)
    build.classify('tools/**', None)
    build.classify('raw_assets/**', None)

    build.classify('game/**.png', 'archive')
    build.classify('game/**.jpg', 'archive')
    build.classify('game/**.webp', 'archive')
    build.classify('game/**.ogg', 'archive')
    build.classify('game/**.rpy', 'archive')
    build.classify('game/**.rpyc', 'archive')

    build.documentation('*.html')
    build.documentation('*.txt')
