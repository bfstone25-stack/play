## GUI configuration for Ren'Py 8 (1920x1080 Full HD)

init -1 python:
    gui.init(1920, 1080)

## Colors
define gui.accent_color = '#d99b66'
define gui.idle_color = '#b0a8a0'
define gui.idle_small_color = '#908880'
define gui.hover_color = '#ffcc88'
define gui.selected_color = '#f2be8d'
define gui.insensitive_color = '#605855'
define gui.muted_color = '#7d685c'
define gui.hover_muted_color = '#a88c7c'
define gui.text_color = '#f5f0eb'
define gui.interface_text_color = '#f5f0eb'

## Fonts
define gui.text_font = "DejaVuSans.ttf"
define gui.name_text_font = "DejaVuSans.ttf"
define gui.interface_text_font = "DejaVuSans.ttf"

## Font sizes
define gui.text_size = 32
define gui.name_text_size = 36
define gui.interface_text_size = 28
define gui.label_text_size = 34
define gui.notify_text_size = 24
define gui.title_text_size = 64

## Dialogue Box
define gui.textbox_height = 270
define gui.textbox_yalign = 1.0

define gui.name_xpos = 360
define gui.name_ypos = 0
define gui.name_xalign = 0.0
define gui.namebox_width = None
define gui.namebox_height = None
define gui.namebox_borders = Borders(5, 5, 5, 5)
define gui.namebox_tile = False

define gui.dialogue_xpos = 360
define gui.dialogue_ypos = 65
define gui.dialogue_width = 1200
define gui.dialogue_text_xalign = 0.0

## Choice Buttons
define gui.choice_button_width = 1100
define gui.choice_button_height = None
define gui.choice_button_tile = False
define gui.choice_button_borders = Borders(60, 15, 60, 15)
define gui.choice_button_text_font = gui.text_font
define gui.choice_button_text_size = gui.text_size
define gui.choice_button_text_xalign = 0.5
define gui.choice_button_text_idle_color = "#e8e0d5"
define gui.choice_button_text_hover_color = "#ffe0a0"

## Quick Menu Buttons
define gui.quick_button_text_size = 20
define gui.quick_button_text_idle_color = "#8f827a"
define gui.quick_button_text_hover_color = "#f5d4a4"
define gui.quick_button_text_selected_color = gui.accent_color

## Navigation / Main Menu
define gui.main_menu_background = "#140f18"
define gui.game_menu_background = "#18121d"

## History
define gui.history_height = 210
define gui.history_name_xpos = 200
define gui.history_name_ypos = 0
define gui.history_name_width = 250
define gui.history_name_xalign = 1.0
define gui.history_text_xpos = 280
define gui.history_text_ypos = 5
define gui.history_text_width = 1100
define gui.history_text_xalign = 0.0

## Default borders
define gui.frame_borders = Borders(15, 15, 15, 15)
define gui.confirm_frame_borders = Borders(60, 60, 60, 60)
define gui.skip_frame_borders = Borders(24, 8, 75, 8)
define gui.notify_frame_borders = Borders(24, 8, 60, 8)
define gui.navigation_xpos = 120
