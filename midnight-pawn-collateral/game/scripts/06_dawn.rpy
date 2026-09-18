## 06_dawn.rpy — Dawn. Three endings, resolved from the ledger and nothing else.
##
## No romance decides this and no affection meter exists. What you own at dawn, and what owns
## you. `collateral_core.ending_of()` is the whole rule and tools/playthrough.py asserts that
## all three are reachable.

label act_dawn:
    scene bg dawn
    with fade
    stop music fadeout 3.0
    play music theme fadein 2.0

    $ ending = core.ending_of(run)
    $ _name = core.ENDING_NAMES[ending]
    $ _net = run.net_worth()
    python:
        # A `$` statement is a *single* Ren'Py line; this dict used to be spread over five of
        # them, which the engine would have rejected at load. tools/check_rpy.py caught it.
        tel_track("ending", {
            "ending": ending, "till": run.till, "stock": run.stock_value(), "net": _net,
            "taken": run.readings_taken, "refused": run.readings_refused,
            "sold": run.sold_reading, "fees_paid": run.fees_paid,
            "fees_refunded": run.fees_refunded,
        })
    $ tel_flush(True)

    nar "Five ten. The window goes from black to the colour of a bruise going down, and the gold letters come back the right way round for about four minutes, which they do every morning and she has seen perhaps six times."

    nar "The count."
    nar "Till: [run.till]. On the shelf: [run.stock_value()] — a finial, a ring, a veil, none of them claimed, all of them thirty days from being the shop's."
    nar "Against the estate: [core.DEBT]."
    nar "Net: [_net]."

    if ending == core.FACTOR:
        jump ending_factor
    elif ending == core.COLLATERAL:
        jump ending_collateral
    else:
        jump ending_solvent


## ---------------------------------------------------------------------------
label ending_solvent:
    nar "Clear. Not comfortable — clear."

    nar "At eight she walks the two hundred to the estate office in an envelope, because Elsa never trusted a transfer, and the man behind the glass stamps a thing and the shop stops being a debt and starts being a shop."

    if len(run.readings_refused) >= 3:
        nar "In the back of the book, in the ruled section, three lines with nothing after them."
        nar "She looks at them for a while on the walk back."
        nara "I could have. That's the bit. It wasn't that I couldn't."

        nar "She did not see Tamsin's room, or Ivo's, or Merrow's mirror. She priced three strangers on the evidence of brass, gold and crepe, and she got two of the three roughly right, and the third one she will never know about, which is the cost and she has decided she can carry it."
    else:
        nar "In the back of the book, some lines filled in and some not, and a balance that came out on the correct side of the line by an amount that would not survive one bad week."

    nar "Nothing comes due. The stair behind the stock room has forty-one treads on it and the newest one near the top has her name on it and a date that was yesterday, and yesterday has now been and gone and nothing happened."
    nar "That is what an unpaid instalment looks like from the outside. Nothing happening, indefinitely."

    nara "Thirty days on the ticket."
    nar "She says it to the shop, out loud, at eight forty in the morning, and the shop does not answer, which she has decided to read as terms accepted."

    nar "Tamsin Bell comes back on the Thursday with the other three finials. Nara pays her for a set."

    $ tel_track("ending_shown", {"ending": "solvent"})
    jump dawn_outro


## ---------------------------------------------------------------------------
label ending_factor:
    $ _sold_client = core.ITEMS[run.sold_reading]["client"]
    nar "The estate is settled by nine with sixty-odd left over, which is more money than this shop has had at one time since Elsa was upright."

    nar "And a week later, exactly as advertised, she stops being able to picture it."

    nar "She can still say the sentence. {i}[_sold_client] — the room, the light, what happened in it.{/i} She can tell you the facts in the flat voice you use for facts."
    nar "But the picture is gone, and what is worse is that it was not taken from her. She sold it. She has a receipt, in the fourth column, in the credit side, which she did not know the fourth column had."

    nar "In March, Calder comes up the stairs."

    nar "He has never done that. Nobody from down there has ever done that. He stands on the customer's side of the counter in an apron over good clothes and looks around at the stock with the expression of a man doing a survey."

    cal "You've had a good quarter."
    nara "I've had a quiet one."
    cal "Same thing at your end. I'll take three this time."
    nara "I've only got —"
    cal "You'll have looked at more by now. You always do after the first. That's not a criticism, Quill, it's inventory forecasting."

    nar "And the thing that finishes it is that he is right, and she knows he is right before he has got to the door, because she has spent three months taking readings she did not need and telling herself it was diligence."

    nar "The shop is solvent. It has one supplier and one customer and they are the same man, and the product is other people, and it was never going to be anything else from the moment she found out what the fourth column was for."

    nara "Come back in March."
    cal "I did."

    $ tel_track("ending_shown", {"ending": "factor"})
    jump dawn_outro


## ---------------------------------------------------------------------------
label ending_collateral:
    if _net >= core.DEBT:
        nar "The estate is settled, narrowly, out of a drawer that spent most of the night going the wrong way."
    else:
        nar "The estate is not settled. She is [(core.DEBT - _net)] short and she signs the extension at nine fifteen, which she is told is routine and which the man behind the glass does not look up for."

    nar "But that was never what the night was about, and she knew it standing at the counter with her hand on a book."

    nar "Four readings. Five. Every line in the ruled section filled in, every instalment paid, on terms she agreed to by putting her palm on things."
    nar "The ticket said thirty days from the date of first reading. The date of first reading was last night. She has done the arithmetic and she is not going to do it again."

    nar "Nothing dramatic happens on the thirtieth day. That is not the shape of this."

    nar "What happens is that around the twenty-second she notices she has stopped going upstairs to the flat, and around the twenty-sixth she notices the shelves have stopped shuffling at midnight because they no longer need to do it while she is not looking."
    nar "And on the thirtieth she is behind the counter at eleven fifty-eight with a stub of pencil and four columns, and the bell goes, and it is a woman in the rain with something in both hands."

    nar "Nara says the sentence. It comes out in Elsa's cadence, which she has never managed before and will never manage otherwise again."

    nara "I buy anything I can price."

    nar "And somewhere behind her in the dark of the case glass, the shop has her exactly where it has always had every single thing in this building: forward, in the lamp, priced, and waiting for whoever it is that will need her."

    shop "Thirty days on the ticket."

    $ tel_track("ending_shown", {"ending": "collateral"})
    jump dawn_outro


## ---------------------------------------------------------------------------
label dawn_outro:
    scene bg dawn
    with dissolve
    nar "{b}[_name].{/b}"
    nar "Readings taken: [len(run.readings_taken)] of 5. Refused: [len(run.readings_refused)]."
    if run.fees_refunded:
        nar "Refunded by the shop for readings it failed to deliver: [run.fees_refunded]."

    call show_ledger from _call_show_ledger_end
    $ act_cleared = 6
    $ demo_cut = ending
    $ tel_track("end_cta", {"ending": ending, "acts": act_cleared, "dist": dist_track()})
    $ tel_flush(True)

    call screen dawn_end_screen
    return


screen dawn_end_screen():
    tag menu
    add "bg black"
    vbox:
        xalign 0.5
        yalign 0.32
        spacing 14
        text _("MIDNIGHT PAWN: COLLATERAL") size 44 color "#e8b84a" bold True xalign 0.5
        text _("Ending: [_name]") size 28 color "#f1dfb0" xalign 0.5
        text _("Two prices on everything. You have just found out which one you were.") size 21 color "#9c93a8" xalign 0.5
        null height 10
        hbox:
            xalign 0.5
            spacing 16
            textbutton _("Open the Reading Ledger"):
                action Call("show_ledger", from_current=True)
                text_size 22 text_color "#e8b84a"
                background Transform("#24172a", alpha=0.92)
                padding (18, 11, 18, 11)
            textbutton _("Run the night again"):
                action Start()
                text_size 22 text_color "#d99b66"
                background Transform("#24172a", alpha=0.92)
                padding (18, 11, 18, 11)
        null height 14
        if dist_track() != "paid":
            frame:
                xsize 1080
                xalign 0.5
                background Transform("#161422", alpha=0.94)
                padding (30, 16, 30, 16)
                vbox:
                    spacing 6
                    xalign 0.5
                    text _("Midnight Pawn: Collateral — the whole night, nothing censored") size 23 color "#f0e6dc" xalign 0.5
                    text _("Five appraisals, six readings, three endings. Windows / macOS / Linux, DRM-free, no ads.") size 19 color "#f0e6dc" xalign 0.5
                    text _("[GAME_PRICE] once.") size 25 color "#ffffff" bold True xalign 0.5
            null height 8
            textbutton _("★ Unlock the whole night — [GAME_PRICE]"):
                action [Function(tel_cta_click, "itch_buy"), OpenURL(ITCH_BUY_URL)]
                xalign 0.5
                text_size 25 text_color "#ffffff"
                background Transform("#c8503c", alpha=0.95)
                padding (26, 14, 26, 14)
        null height 14
        use cross_promo
