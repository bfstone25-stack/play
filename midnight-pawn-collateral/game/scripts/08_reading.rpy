## 08_reading.rpy — the reading gate, which is the whole reason this fork exists.
##
## ops/adult_forks/midnight-pawn.md §7 calls this the riskiest part of the design: asking a
## player to spend in-fiction currency for a CG is untested in the catalogue, and it fails in
## two named ways —
##
##   (a) it reads as a *second paywall* stacked on the real one, and they quit;
##   (b) they hoard cash, refuse every reading, and a paying customer finishes having seen
##       two of six CGs and feels cheated.
##
## Five things in this file are there to answer those, and they are the answer worth
## reporting:
##
##   1. **The fee is refunded if the art does not arrive.** `reading_delivered()` asks
##      whether the uncensored plate actually landed. On a free track, a player who pays the
##      shop fee and then declines the distribution gate gets the fee back, in-fiction, with
##      a line that says so. Charging shop cash for a silhouette is precisely what (a) feels
##      like, and it is now impossible.
##   2. **The two gates never appear in the same breath.** The fee menu is the shop's own
##      voice and its own colours, and it never mentions money that is not shop money. The
##      real paywall is `cg_gate`'s screen, a beat later, and it is the only thing in the
##      game that says a dollar sign. There is no path from the fee menu to a purchase.
##   3. **Every fee is affordable on an honest run.** tools/playthrough.py asserts it: price
##      everything FAIR and you can pay for all three optional readings and still clear the
##      debt. The fee punishes cheating the clients, not curiosity.
##   4. **The refusal is always priced out loud** — the menu shows the fee and the till, so a
##      refusal is a decision and never an accident. That is the stated mitigation for (b).
##   5. **The Reading Ledger is shown before the final appraisal**, with the greyed slots
##      visible, while one appraisal is still left to spend on.

label reading_offer(item):
    ## Offer the reading, take the fee, hand it back if the plate does not arrive.
    $ _fee = fee_for(item)
    $ _client = core.ITEMS[item]["client"]
    $ _clue = core.ITEMS[item]["clue"]

    nar "[_clue]"
    $ tel_track("reading_offered", {"item": item, "fee": _fee, "till": run.till})

    if _fee == 0:
        call reading_take(item) from _call_reading_take_free
        return

    if not reading_affordable(item):
        nar "You put two fingers on it and the till answers before the object does: there is not [_fee] in the drawer to spend on knowing."
        $ run.record_refusal(item)
        $ tel_track("reading_declined", {"item": item, "why": "broke", "till": run.till})
        return

    menu:
        "A reading costs the shop [_fee]. The till holds [run.till]."

        "Take the reading. ([_fee] out of the till)":
            call reading_take(item) from _call_reading_take_offer

        "Price it blind. (the reading stays unbought)":
            $ run.record_refusal(item)
            $ tel_track("reading_declined", {"item": item, "why": "chose", "till": run.till})
            nar "She turns it over twice with the backs of her fingers, which is how you handle a thing you have decided not to know, and writes a number that is only arithmetic."
            nara "Some nights you want the whole story. Some nights the story is a cost."

    return


label reading_take(item):
    ## Charge, show, and hand the fee back if the plate never arrived.
    ##
    ## Split out of reading_offer because tools/simulate.py caught the scenes asking twice:
    ## the story menu in 02_ring.rpy ("take the reading anyway — he asked you not to") already
    ## states the fee and already *is* the decision, and then reading_offer asked for the fee
    ## again on the next screen. A fee prompt that appears after the player has already said
    ## yes is exactly what a second paywall feels like. So a scene that has asked in its own
    ## voice calls this directly, and nobody is asked for the same money twice.
    $ _fee = fee_for(item)
    $ run.charge_reading(item)
    $ tel_track("reading_taken", {"item": item, "fee": _fee, "till": run.till})
    if _fee:
        nar "She counts it out of the drawer before she touches anything, because Elsa's rule was that the shop pays first and looks second, and the one time Nara did it the other way round she saw a thing she could not afford to have seen."
    $ run.record_reading(item)
    call reading_show(item) from _call_reading_show_paid

    ## The refund rule. If the free track left the plate censored, the shop did not get what
    ## it paid for, and neither did the player.
    if _fee and not reading_delivered(item):
        $ _back = run.refund_reading(item)
        nar "It does not come. Not all of it — a shape, a direction, the weather of the thing, and then the object goes quiet in her hand like a phone with the screen off."
        nara "That's not a reading. That's a receipt for one."
        nar "She puts the [_back] back in the drawer. The shop does not charge for what it failed to show you."
        $ tel_track("reading_refunded", {"item": item, "fee": _back, "till": run.till})
    return


label reading_show(item):
    ## The three-line shape from play/room-704/game/scripts/02_act2.rpy:154-157 — charge,
    ## gate, show. The charge has already happened above; the gate and the show are here.
    $ unlock_cg(item)
    call cg_gate(item) from _call_cg_gate_reading
    scene expression cg_pick(item) at lamp_tint
    with dissolve
    $ tel_track("reading_shown", {"item": item, "dist": dist_track(), "delivered": reading_delivered(item)})
    return


label price_menu(item):
    ## LOW / FAIR / HIGH. The base game's pricing verb, now aimed at a person whose worst or
    ## best hour you may have just watched.
    $ _v = value_of(item)
    $ _low = price_of(item, "low")
    $ _fair = price_of(item, "fair")
    $ _high = price_of(item, "high")
    $ _client = core.ITEMS[item]["client"]

    menu:
        "What do you write on the ticket?"

        "LOW — [_low]. They will take it.":
            $ run.pay_client(item, "low")
            $ tel_track("price_set", {"item": item, "tier": "low", "cash": _low, "till": run.till})

        "FAIR — [_fair]. What it is worth.":
            $ run.pay_client(item, "fair")
            $ tel_track("price_set", {"item": item, "tier": "fair", "cash": _fair, "till": run.till})

        "HIGH — [_high]. More than it is worth.":
            $ run.pay_client(item, "high")
            $ tel_track("price_set", {"item": item, "tier": "high", "cash": _high, "till": run.till})

    return


## ---------------------------------------------------------------------------
## The Reading Ledger
## ---------------------------------------------------------------------------
## Doubles as the CG gallery. Refused slots stay greyed, permanently, per save — it is the
## completionist hook and it is also mitigation (4): the player sees the cost of refusing
## while there is still an appraisal left to spend on.

screen reading_ledger(can_close=True):
    tag menu
    modal True
    add "bg black"
    frame:
        xalign 0.5
        yalign 0.5
        xsize 1180
        background Transform("#181322", alpha=0.96)
        padding (36, 26, 36, 26)
        vbox:
            spacing 12
            text _("THE READING LEDGER") size 40 color "#e8b84a" bold True xalign 0.5
            text _("Every object that crossed the counter, and whether you looked.") size 20 color "#9c93a8" xalign 0.5
            null height 8
            for key, title, unlocked, why in ledger_rows():
                hbox:
                    spacing 16
                    if unlocked:
                        imagebutton:
                            idle Transform("cg " + key, zoom=0.16)
                            action Show("ledger_view", cg_key=key)
                    else:
                        add Transform(Solid("#241d30"), xysize=(154, 87))
                    vbox:
                        spacing 2
                        text title size 22 color ("#f1dfb0" if unlocked else "#5c5468")
                        if unlocked:
                            text why size 17 color "#7f9a7a"
                        else:
                            text _("Not taken. This one stays dark.") size 17 color "#5c5468"
            null height 10
            text _("Readings taken: [run.readings_taken] · refused: [run.readings_refused] · till: [run.till]") size 18 color "#9c93a8" xalign 0.5
            if can_close:
                textbutton _("Close the book"):
                    action Return()
                    xalign 0.5
                    text_size 22 text_color "#e8b84a"
                    background Transform("#24172a", alpha=0.92)
                    padding (20, 10, 20, 10)

screen ledger_view(cg_key):
    tag menu
    modal True
    add Solid("#000000e8")
    add ("cg " + cg_key) xalign 0.5 yalign 0.5 zoom 1.0
    textbutton _("Back"):
        action Hide("ledger_view")
        xalign 0.5 yalign 0.95
        text_size 22 text_color "#e8b84a"
        background Transform("#24172a", alpha=0.92)
        padding (18, 10, 18, 10)

label show_ledger:
    $ ledger_shown = True
    $ tel_track("ledger_opened", {"taken": len(run.readings_taken), "refused": len(run.readings_refused)})
    call screen reading_ledger(True)
    return
