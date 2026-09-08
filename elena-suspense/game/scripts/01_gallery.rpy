## 01_gallery.rpy - Dynamic 3-Slot Persistent CG Gallery with Modal View & Unlock System

init python:
    # Gallery metadata registry
    GALLERY_ENTRIES = [
        {
            "id": "cg_confrontation",
            "title": _("I. Cornered Scholar"),
            "subtitle": _("Archive confrontation & forbidden records"),
            "full_image": "images/cgs/cg_confrontation.webp",
            "thumb": "images/cgs/cg_confrontation_thumb.webp"
        },
        {
            "id": "cg_climax",
            "title": _("II. Midnight Surrender"),
            "subtitle": _("Ecchi desk climax & tangled confessions"),
            "full_image": "images/cgs/cg_climax.webp",
            "thumb": "images/cgs/cg_climax_thumb.webp"
        },
        {
            "id": "cg_aftermath",
            "title": _("III. Amber Dawn Pact"),
            "subtitle": _("Intimate quiet after the storm"),
            "full_image": "images/cgs/cg_aftermath.webp",
            "thumb": "images/cgs/cg_aftermath_thumb.webp"
        }
    ]

screen cg_gallery():
    tag menu

    use game_menu(_("Memories & CG Gallery")):
        vbox:
            spacing 25
            xalign 0.5
            yalign 0.5

            hbox:
                xalign 0.5
                spacing 40

                $ unlocked_count = len([item for item in GALLERY_ENTRIES if is_cg_unlocked(item["id"])])
                text _("Unlocked: [unlocked_count] / 3 Event CGs") size 24 color "#d99b66" bold True

            null height 15

            # 3-Slot Horizontal CG Grid
            hbox:
                xalign 0.5
                spacing 35

                for entry in GALLERY_ENTRIES:
                    $ is_unlocked = is_cg_unlocked(entry["id"])

                    frame:
                        xsize 420
                        ysize 440
                        background Transform("#24172a", alpha=0.92)
                        padding (15, 15, 15, 15)

                        vbox:
                            xalign 0.5
                            spacing 15

                            if is_unlocked:
                                # Clickable unlocked thumbnail
                                imagebutton:
                                    idle entry["thumb"]
                                    hover entry["thumb"]
                                    action Show("cg_modal_view", cg_image=entry["full_image"], cg_title=entry["title"])
                                    xalign 0.5
                                    xsize 390
                                    ysize 219

                                text entry["title"] size 22 color "#ffdfa0" bold True xalign 0.5
                                text entry["subtitle"] size 16 color "#c8b8b0" xalign 0.5 text_align 0.5

                                textbutton _("View Full CG"):
                                    action Show("cg_modal_view", cg_image=entry["full_image"], cg_title=entry["title"])
                                    xalign 0.5
                                    text_size 18
                                    text_color "#d99b66"
                                    text_hover_color "#ffe0a0"
                            else:
                                # Locked placeholder
                                frame:
                                    xsize 390
                                    ysize 219
                                    background Transform("#120d16", alpha=0.95)
                                    vbox:
                                        xalign 0.5
                                        yalign 0.5
                                        spacing 10
                                        text _("LOCKED") size 28 color "#685850" bold True xalign 0.5
                                        text _("Play Chapter 1 to unlock") size 16 color "#504440" xalign 0.5

                                text entry["title"] size 22 color "#685850" bold True xalign 0.5
                                text _("Classified Archive Memory") size 16 color "#483c38" xalign 0.5

                                textbutton _("Locked"):
                                    action NullAction()
                                    xalign 0.5
                                    text_size 18
                                    text_color "#504440"
                                    insensitive_background None

## Modal Fullscreen CG Viewer
screen cg_modal_view(cg_image, cg_title):
    modal True
    zorder 300

    # Backdrop
    add "#050308"

    # Fullscreen CG
    add cg_image:
        xalign 0.5
        yalign 0.5
        fit "contain"

    # Top overlay bar with dismiss controls
    frame:
        xalign 0.5
        yalign 0.03
        xsize 1800
        ysize 70
        background Transform("#100a16", alpha=0.85)
        padding (30, 10, 30, 10)

        hbox:
            yalign 0.5
            text cg_title size 26 color "#ffdfa0" bold True
            null width 800
            text _("(Click anywhere or press Return to close)") size 18 color "#a09088" yalign 0.5

        # Close button
        textbutton _("✕ Close"):
            xalign 0.98
            yalign 0.5
            action Hide("cg_modal_view")
            text_size 26
            text_color "#ffdfa0"
            text_hover_color "#ffffff"

    # Screen dismissal trigger on full background click
    button:
        xsize 1920
        ysize 1080
        action Hide("cg_modal_view")
        background None
