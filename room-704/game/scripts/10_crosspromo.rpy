## crosspromo.rpy - promote a SFW title at the end of an adult game.
##
## The adult titles are where the audience actually is: Elena's F95 thread has ~26k views
## against ~850 itch plays for the whole SFW catalogue. This sends a slice of that attention
## back across the portfolio, one randomly chosen game per playthrough so no single title
## soaks up every impression.
##
## Shared by Elena and Room 704 - edit here, then copy into each game/scripts/.
## Links go to itch rather than free.blazecore.dev on purpose: blazecore.dev is pending
## AdSense review, and pointing adult-game traffic at it during review is a risk with no
## upside. Flip PROMO_BASE once the account is approved if we want the ad inventory instead.

init -1 python:
    PROMO_BASE = "https://bfstone25-stack.itch.io/"

    # Only titles with a working itch page and a real play rate. Keep the hooks concrete -
    # "a game about X" reads as filler; a specific image does not.
    SFW_GAMES = [
        ("ghost-channel",   "Ghost Channel",   "Five voices on a dead station. One of them is lying."),
        ("tell",            "Tell",            "Interview four suspects. Everyone has a tell."),
        ("rebound-tycoon",  "Rebound Tycoon",  "Build a streak, then a tiny empire, at a strange checkpoint."),
        ("fold",            "Fold",            "Fold space in three dimensions until the tiles become one."),
        ("office-landlord", "Office Landlord", "Staple a company together one floor at a time."),
        ("cyber-merit",     "Cyber Merit",     "Earn your social score. Spend it badly."),
        ("silvertongue",    "SilverTongue",    "Talk your way out. The concession rules are not on your side."),
        ("across-the-hall", "Across the Hall", "The door opposite yours was not there yesterday."),
    ]

    def promo_pick():
        """One game per playthrough, stable once chosen so the panel does not shuffle
        under the player's cursor while they read it."""
        if getattr(store, "_promo_choice", None) is None:
            try:
                store._promo_choice = renpy.random.choice(SFW_GAMES)
            except Exception:
                store._promo_choice = SFW_GAMES[0]
        return store._promo_choice

    def promo_url(slug):
        return PROMO_BASE + slug

    def promo_click(slug):
        try:
            tel_track("cross_promo_click", {"dest": slug, "from": "end_screen"})
            tel_flush(True)
        except Exception:
            pass


screen cross_promo():
    ## Drop `use cross_promo` into a game's end screen.
    python:
        _pslug, _pname, _phook = promo_pick()
    frame:
        xsize 1100
        xalign 0.5
        background Transform("#12161f", alpha=0.94)
        padding (30, 18, 30, 18)
        vbox:
            spacing 6
            xalign 0.5
            text _("While you're here - something completely different") size 19 color "#7e8ba0" xalign 0.5
            text _(_pname) size 30 color "#9fd0ff" bold True xalign 0.5
            text _(_phook) size 20 color "#c6cedb" xalign 0.5
            null height 6
            textbutton _("Play it free in your browser →"):
                xalign 0.5
                action [Function(promo_click, _pslug), OpenURL(promo_url(_pslug))]
                text_size 21 text_color "#0b1220" text_hover_color "#0b1220"
                background Transform("#9fd0ff", alpha=0.95)
                hover_background Transform("#c9e4ff", alpha=1.0)
                padding (22, 12, 22, 12)
