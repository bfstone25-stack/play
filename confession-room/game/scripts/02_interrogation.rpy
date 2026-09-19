## 02_interrogation.rpy — the loop the whole game hangs on.
##
## Ask a topic, spend a question. Press a suspect, spend two and raise their pressure.
## High pressure opens the lines they would never volunteer — and the optional route
## where the interrogation stops being procedural. Those routes are where the explicit
## art lives, which is the point: in a crime story the nudity is leverage, not a pit
## stop, so the gate sits somewhere the player already wants to go.

screen interrogation(sid):
    tag menu
    modal True
    $ s = SUSPECTS[sid]
    $ avail = available_statements(sid)
    $ locked = locked_count(sid)

    frame:
        xalign 0.5 yalign 0.5 xsize 1180 padding (34, 28)
        background Solid("#07070bE8")
        vbox:
            spacing 10
            text s["name"] size 42 color "#e8d9b0"
            text s["role"] size 22 color "#9aa3ad"
            null height 6
            hbox:
                spacing 28
                text "[questions_left] questions left" size 24 color ("#d9b08a" if questions_left > 3 else "#d96a5a")
                text "Pressure [pressure[sid]]/3" size 24 color "#8fd6c2"
                if locked:
                    text ("[locked] line" + ("" if locked == 1 else "s") + " they are not giving you yet") size 22 color "#7f8fa0"
            null height 10

            for st in avail:
                textbutton ("Ask about [st[2]]" + ("  ·  heard" if st[1] in heard else "")):
                    action [Return(("ask", st[1]))]
                    text_size 26
                    text_color ("#7f8fa0" if st[1] in heard else "#efe7dc")

            null height 12
            if pressure[sid] < 3 and questions_left >= 2:
                textbutton "Press [s['name']]  (2 questions)":
                    action Return(("press", sid))
                    text_size 26 text_color "#d68fa8"
            if pressure[sid] >= 3:
                textbutton "Close the door":
                    action Return(("route", sid))
                    text_size 26 text_color "#d68fa8"
            null height 8
            textbutton "Step out" action Return(("leave", sid)) text_size 26


label interrogate(who):
    ## A label parameter does not survive the jump into the loop below, so the suspect
    ## lives in a store variable for as long as the door is shut.
    $ cur_suspect = who
    $ tel_track("interrogation_open", {"suspect": cur_suspect, "q_left": questions_left})
    scene bg room at cold_tint
    with dissolve

    $ _c = {"nikolai": nik, "adaeze": ade, "vee": vee}[cur_suspect]
    if cur_suspect not in heard:
        $ heard.add(cur_suspect)
        $ _c(SUSPECTS[cur_suspect]["open"])

label interrogate_loop:
    if questions_left <= 0:
        jump out_of_questions

    call screen interrogation(cur_suspect)
    $ _act, _arg = _return

    if _act == "leave":
        return

    if _act == "ask":
        $ questions_left -= 1
        $ heard.add(_arg)
        $ tel_track("statement_heard", {"id": _arg, "suspect": cur_suspect})
        $ _c = {"nikolai": nik, "adaeze": ade, "vee": vee}[cur_suspect]
        $ _c(statement_text(_arg))
        jump interrogate_loop

    if _act == "press":
        $ questions_left -= 2
        $ pressure[cur_suspect] = min(3, pressure[cur_suspect] + 1)
        $ tel_track("pressure_raised", {"suspect": cur_suspect, "to": pressure[cur_suspect]})
        call press_beat(cur_suspect)
        jump interrogate_loop

    if _act == "route":
        call suspect_route(cur_suspect)
        jump interrogate_loop

    jump interrogate_loop


## What pressing actually looks like. Three steps, escalating, none of them explicit —
## the explicit branch is opt-in and comes after.
label press_beat(sid):
    $ _c = {"nikolai": nik, "adaeze": ade, "vee": vee}[sid]
    $ _p = pressure[sid]

    if _p == 1:
        you "I'm not writing any of this down yet. That's a courtesy, and courtesies expire."
        $ _c("Then let's both be quick.")
    elif _p == 2:
        you "Everyone in this building thinks you're the easy one. I'd like to keep disagreeing."
        $ _c("...")
        nar "Something goes out of their shoulders. Not fear — calculation, arriving late."
    else:
        you "There's a version of tonight where you walk out of here. I need something to trade for it."
        $ _c("And if what I've got isn't the kind of thing you write down either?")
        nar "The room gets smaller. The door is still open, and it stays open unless you close it."
    return


## The optional branch. It is a real choice with a real cost, it is skippable, and
## skipping it never locks the case: the decisive line is reachable on pressure alone.
## Everyone here is an adult and the game says so on the way in.
label suspect_route(sid):
    $ _c = {"nikolai": nik, "adaeze": ade, "vee": vee}[sid]
    menu:
        "Close the door?"
        "Close it.":
            pass
        "Leave it open.":
            $ tel_track("route_declined", {"suspect": sid})
            you "Leave it open. I'd rather you lied to me with your clothes on."
            return

    $ route = sid
    $ tel_track("route_taken", {"suspect": sid})
    call ad_checkpoint("route_" + sid, SUSPECTS[sid]["name"]) from _call_ck_route
    call cg_gate(sid) from _call_cg_gate_route
    scene expression cg_pick(sid) at sodium_tint
    with dissolve
    $ unlock_cg(sid)

    ## Each route ends with a fact, not just a CG. That is the whole argument of the
    ## game: pressing someone opens lines they would never volunteer. A route that only
    ## unlocked art would be a gallery with a deduction game stapled to it, and the
    ## player would correctly stop taking them once the picture was seen.
    ##
    ## Three cases, three versions of each route. They escalate: night one is a
    ## transaction, night two is after somebody has died who nobody had a reason to
    ## kill, and night three is three people who have all now been in this room twice.
    ## The same CG carries all three — what changes is what it costs them.
    if CASE["id"] == "loading_bay":
        call route_bay(sid) from _call_route_bay
        $ pressure[sid] = 3
        nar "Afterwards the room is exactly as loud as it was."
        return
    elif CASE["id"] == "fire_stairs":
        call route_stairs(sid) from _call_route_stairs
        $ pressure[sid] = 3
        nar "Afterwards the room is exactly as loud as it was."
        return

    if sid == "nikolai":
        nar "He does not perform. He negotiates, the way he does everything, and the negotiation is the part he cannot help enjoying."
        nik "You understand this doesn't buy you the truth. It buys you my attention."
        you "Attention's cheaper than a lawyer."
        nik "Everything is, until you need one."
        nar "He is unhurried in a way that is meant to be read, and he lets it be read. Somewhere underneath, a man is doing arithmetic and not liking the total."
        nik "You want to know why I'm still in this room. It isn't you."
        nik "It's that I locked the office at two and the office was empty, and I have spent every hour since then being the only person that is inconvenient for."
        you "Somebody was past the bar."
        nik "Somebody was past the bar. I heard the strip curtain. I did not look, because looking is how you end up on a list."
        $ learn_route_fact("nikolai")
        nar "He says it like a man setting a stone down. Then he is finished, and the finishing is as deliberate as the rest of it."

    elif sid == "adaeze":
        nar "She decides it, start to finish. You are the one being interviewed, and you both know it before the lamp is off."
        ade "When you write this up, spell my name right."
        you "A-D-A-E-Z-E."
        ade "Good. People get one chance at that."
        nar "There is nothing nervous in her. Whatever she is spending here she has already priced, and the price was never the point."
        ade "My name is on the lease. Do you understand what that means at four in the morning with a dead man in my office?"
        ade "It means it is mine. Whatever happened in my building, I own it before anyone hands it to me."
        you "Then own this. What did you hear?"
        nar "The pause is the only crack she lets you see."
        ade "The cooler door. It has a seal, it drags. I heard it drag after I set the alarm, and I told myself it was the compressor, and I went home."
        $ learn_route_fact("adaeze")
        ade "Write that down too. I'd rather you had it than kept it."

    else:
        nar "Vee shakes. Not because of you. Because of something that was in the room before you got here."
        vee "Don't stop asking. If you stop asking I'll start thinking."
        you "About what?"
        vee "About how long a room takes to get warm again."
        nar "Whatever this is, it is not appetite. It is a person holding on to the nearest solid thing. You have decided to be the solid thing. You can decide later whether that was a kindness."
        vee "Everyone keeps saying eleven minutes. Off the van, on the floor, gone. I said it so many times it stopped being a sentence."
        you "How long were you really there?"
        vee "Long enough to stop feeling my hands."
        $ learn_route_fact("vee")
        nar "Vee hears it land. Does not take it back. Does not look at you either."

    $ pressure[sid] = 3
    nar "Afterwards the room is exactly as loud as it was."
    return


label out_of_questions:
    $ tel_track("budget_spent", {})
    scene bg precinct at cold_tint
    with fade
    dsp "That's your twelve, Reyes. Captain wants a name or wants them walking."
    jump accusation

## ---------------------------------------------------------------- case two routes
## Three weeks on. Iris is dead and none of them can make her fit the shape of a person
## who gets killed, which is its own kind of pressure and does more of the work than you do.
label route_bay(sid):
    if sid == "nikolai":
        nar "He is slower than last time. Not softer — a man moving something heavy and not wanting it heard."
        nik "Second time in a month. You will forgive me for knowing where the chair is."
        you "You said to write down that you liked her."
        nik "I said it first so you would not be able to put it anywhere clever later."
        nar "For a while he is exactly as present as he intends to be. Then for a moment he is not, and he notices, which costs him more than it costs you."
        nik "She asked me what it costs to leave a place like this. I gave her a number. I have been trying for three weeks to remember whether it was a kind number."
        you "Was it?"
        nik "It was accurate. I have only ever been good at accurate."
        you "Then be accurate now. What was wrong out there?"
        nik "The bay light. It is on a timer and it was off, and it does not fail. Somebody killed it from inside, and the switch for it is in the mop room."
        $ learn_route_fact("nikolai")
        nar "He gives you that, and then he is a closed office again. Lights off, everything filed."

    elif sid == "adaeze":
        nar "She closes the door herself this time. She does not ask, and she does not hurry, and somewhere in there is the answer to a question you have not asked yet."
        ade "Six years. I signed every page she wrote."
        you "You keep saying that like it's an alibi."
        ade "It is the opposite of an alibi. Try to keep up."
        nar "She is not performing grief and she is not hiding it. She is holding it the way you hold a glass you have decided not to set down."
        ade "Do you know what she did, the last time I saw her? She warned me. An auditor was coming and she told me first, because she thought that was decent."
        you "It was decent."
        ade "It was the most frightening thing anyone has ever done to me."
        nar "That is the closest she comes to giving you anything, and she gives it with her chin up, the way she does everything."
        you "Where were you at half three?"
        ade "The mop room. I will say it before you find someone who says it for me."
        $ learn_route_fact("adaeze")
        ade "Write it down. All of it. Spell my name right."

    else:
        nar "Vee does not shake this time. Vee is very still, which you have learned is worse."
        vee "You came and got me again."
        you "I came and asked."
        vee "You came with two uniforms and asked."
        nar "There is nothing to say to that, so you do not say it, and the not-saying is the first honest thing either of you has managed tonight."
        vee "She wrote down every crate I ever brought through that door. Six years. She never once wrote down my name."
        you "Why does that matter."
        vee "Because everybody else in my life keeps a list. Hers was the only one I wasn't on."
        nar "Whatever happens after that happens slowly, and none of it is about you, and you let it not be about you, which is the most you have to give."
        vee "I came back for a jacket. Around four. There was a light on in the mop room."
        you "Did you go in."
        vee "No. I have been sick about it every day since."
        $ learn_route_fact("vee")
        nar "Vee says it to the ceiling. You write it down anyway."
    return


## -------------------------------------------------------------- case three routes
## Night three. Everyone in this room has been in this room. Nobody is startled any more,
## and that turns out to be the condition under which people finally say things.
label route_stairs(sid):
    if sid == "nikolai":
        nar "He is the one who closes the door. He has never done that before, and he lets you see that he has never done it before."
        nik "Third time, Reyes."
        you "Third time."
        nik "At some point a habit is a relationship. I am not sure which of us that should worry."
        nar "He is unhurried, the way he has been every time. Tonight it reads differently: not a man taking his time, a man with nowhere left to be."
        nik "Marek. Iris. Now an inspector with a folder. You have sat across from me for all three and you have never once asked me for anything."
        you "Should I have."
        nik "Everyone else in this building has. Adaeze asks. Vee asks with their whole body. I am the only one who never has, and you have found that restful."
        nar "He waits for that to be worth something. It is."
        nik "Ask yourself why the patient one is patient. That is the whole case and I have just handed it to you for nothing."
        $ learn_route_fact("nikolai")
        nar "He straightens his cuff. He is, as ever, finished exactly when he intended to be."

    elif sid == "adaeze":
        nar "She is not in charge tonight and does not pretend to be, and the missing performance is more intimate than the performance ever was."
        ade "I signed nothing this month."
        you "I noticed."
        ade "Somebody else can be on every page for a while. I have been on every page since I was twenty-three."
        nar "She is tired in a way the hour does not explain, and for once she lets the room see it, and you are the room."
        ade "Do you know what I did last night? Sat upstairs with the lights off, doing nothing at all, which is the only thing left that nobody can countersign."
        you "You saw something."
        ade "The office light. From the flat you can see it thrown on the yard wall. It was on at one. I watched it go out."
        you "And you didn't come down."
        ade "I have come down twice. Both times there was a person on the floor and my name on the lease."
        $ learn_route_fact("adaeze")
        nar "She says it without excuse, which is not the same as without shame, and she knows you know the difference."

    else:
        nar "Vee came in alone. Walked the four blocks. Sat down before anyone asked, and that is the part you keep turning over afterwards."
        vee "I'm here. Nobody had to come and get me."
        you "I know."
        vee "That has to be worth something. Not to a judge. To you."
        nar "It is worth something. There is no box on the form for it, so you put it where you put the rest of it."
        vee "I was in the yard from midnight. You can hear the office through the vent. Not words. Just that there are words."
        you "And then?"
        vee "Feet on the stairs. Going down slow, like carrying."
        you "Slow down, quick up?"
        vee "Slow down. Quick up. Nobody carries anything up."
        $ learn_route_fact("vee")
        nar "Vee waits to be disbelieved. You do not, and it takes them a long moment to find anywhere to put that."
    return
