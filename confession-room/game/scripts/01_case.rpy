## 01_case.rpy — the three cases, the recurring cast, and every line they can be made to say.
##
## Authored, not generated at runtime. TELL asks a live model on the GPU box, which is
## fine for a browser game and impossible for F95, where the audience downloads a build
## and plays it on a plane. So the cases are written ahead of time (the TELL case
## generator is a fine drafting tool) and baked in. The game needs no network to play.
##
## Fairness rule inherited from TELL: the file, the public facts and the opening
## statements are immutable. The guilty suspect may hide and may lie, but may not
## rewrite the world, and the decisive slip is a detail that was never released.
##
## Why one cast across three cases rather than three casts: art. A new trio per case is
## nine more character CGs and nine more censored plates, and the writing budget would go
## into introducing strangers. A recurring ensemble spends it on the thing an adult VN
## actually needs — the routes get somewhere across three nights instead of resetting.
## It is also how the genre works: Reyes keeps pulling the same three people back in.

init python:

    ## A pressure threshold no suspect can reach. Marks the lines that exist only behind
    ## an optional route.
    ROUTE = 99

    ## The cast. Names, faces and CGs are fixed; what each of them IS to the victim
    ## changes with the case, so role and opening line live in the case.
    CAST = {
        "nikolai": {"name": "Nikolai", "cg": "nikolai"},
        "adaeze":  {"name": "Adaeze",  "cg": "adaeze"},
        "vee":     {"name": "Vee",     "cg": "vee"},
    }

    CASES = [

    ## ================================================================== case 1
    {
        "id": "cold_room",
        "title": "The Cold Room",
        "night": "Thursday",
        "victim": "Marek Sandoval, 41. Vice informant. Off the books for nine months.",
        "public": [
            "Found at 04:10 in the back office of the Paloma, behind the desk.",
            "Cause of death: a single blow to the back of the skull.",
            "The club closed to the public at 02:00. Three people had keys.",
            "No forced entry. Nothing taken from the register or the safe.",
        ],
        ## Never released to the suspects, the press, or the file they were shown.
        "withheld": "Marek was killed in the walk-in cooler and moved. His left shoe is still in there.",
        "solution": "vee",
        "decisive": "vee_cold",
        "roles": {
            "nikolai": "Fixer. Forty-two. Paid to make the Paloma's problems quiet.",
            "adaeze":  "Manager. Twenty-nine. The only one whose name is on the lease.",
            "vee":     "Courier. Thirty-one. Moves things nobody writes down.",
        },
        "open": {
            "nikolai": "I was in the office until two. Then I was somewhere else. That's the whole of it.",
            "adaeze":  "I counted the drawer, I set the alarm, I went home. You can have the tape.",
            "vee":     "I dropped a crate and I left. I never went past the bar.",
        },
        ## (suspect, id, topic, pressure needed, text)
        "statements": [
            ## --- Nikolai ------------------------------------------------------
            ("nikolai", "nik_keys", "the keys", 0,
             "Three keys. Mine, hers, and the one Marek was never supposed to still have."),
            ("nikolai", "nik_two", "after two", 0,
             "I locked the office and I walked. Ask the camera on Delgado Street. It likes me."),
            ("nikolai", "nik_job", "what you do here", 0,
             "I am what a place like this has instead of a complaints procedure."),
            ("nikolai", "nik_marek", "Marek", 1,
             "He was selling. Not product — names. Mine was on the list he was building."),
            ("nikolai", "nik_list", "the list", 1,
             "Nine months of it. Every name on that list is still walking around being very calm."),
            ("nikolai", "nik_money", "the safe", 2,
             "Nothing was taken because nothing in there was worth what he already had in his head."),
            ("nikolai", "nik_room", "the back rooms", 3,
             "I don't go past the bar. Hasn't been my job since I stopped being cheap."),
            ("nikolai", "nik_curtain", "the strip curtain", ROUTE,
             "Somebody was past the bar. I heard the strip curtain. I did not look, "
             "because looking is how you end up on a list."),

            ## --- Adaeze -------------------------------------------------------
            ("adaeze", "ade_drawer", "closing up", 0,
             "Four hundred and ten in the drawer, same as every Thursday. I wrote it down."),
            ("adaeze", "ade_alarm", "the alarm", 0,
             "I set it. It logs. If it logs me at 02:14 then I was at the panel at 02:14."),
            ("adaeze", "ade_staff", "who was left", 0,
             "Me, Nikolai, a courier who should have been gone. That is not a crowd."),
            ("adaeze", "ade_marek", "Marek", 1,
             "He came in through the kitchen. He always did. I stopped telling him not to."),
            ("adaeze", "ade_kitchen", "the kitchen", 1,
             "Deliveries, ice, the cooler, the yard door. Everything that isn't for customers."),
            ("adaeze", "ade_vee", "Vee", 2,
             "Vee stayed. I watched them not leave. That's the part I didn't want to say."),
            ("adaeze", "ade_lease", "the lease", 3,
             "Everything here has my name on it. Including whatever you decide happened."),
            ("adaeze", "ade_seal", "the cooler door", ROUTE,
             "The cooler door has a seal, it drags. I heard it drag after I set the alarm, "
             "and I told myself it was the compressor."),

            ## --- Vee ----------------------------------------------------------
            ("vee", "vee_crate", "the delivery", 0,
             "One crate, off the van, onto the floor by the bar. Eleven minutes, end to end."),
            ("vee", "vee_leave", "leaving", 0,
             "I was gone before she counted the drawer. Ask her."),
            ("vee", "vee_van", "the van", 0,
             "Not mine. I don't own anything that can be traced to an address."),
            ("vee", "vee_marek", "Marek", 1,
             "He owed me. Not money. He was supposed to keep a name out of a file."),
            ("vee", "vee_name", "whose name", 1,
             "Does it matter? It was never going to be his own."),
            ("vee", "vee_bar", "past the bar", 2,
             "I said I never went past the bar. I'd like to keep saying that."),
            ## The slip. Nobody was told he was in the cooler. Vee is describing the room
            ## where it happened, because Vee was standing in it.
            ("vee", "vee_cold", "the cold", 3,
             "You want me to say it. Fine. It was cold in there. My hands stopped working "
             "and I couldn't pick the thing back up. That's what I remember. The cold."),
            ("vee", "vee_hands", "eleven minutes", ROUTE,
             "Everyone keeps saying eleven minutes. I was there long enough to stop feeling "
             "my hands."),
        ],
    },

    ## ================================================================== case 2
    {
        "id": "loading_bay",
        "title": "The Second Key",
        "night": "three weeks later",
        "victim": "Iris Toma, 38. The Paloma's bookkeeper. Nobody's idea of a suspect.",
        "public": [
            "Found at 05:40 in her own car in the Paloma's loading bay, doors unlocked.",
            "Cause of death: drowning.",
            "The bay floods when it rains. It rained until three.",
            "Her keys were in the ignition. Her bag was on the passenger seat, untouched.",
        ],
        ## The bay water is rain and diesel. Her lungs had neither — she was drowned in
        ## the mop room's deep sink, in clean water, and carried out to the car.
        "withheld": "Iris drowned in clean water. She was killed in the mop room and put in the car.",
        "solution": "adaeze",
        "decisive": "ade2_basin",
        "roles": {
            "nikolai": "Fixer. Still. Nobody has found a reason to stop paying him.",
            "adaeze":  "Manager. Signed off every page Iris ever wrote.",
            "vee":     "Courier. Out on bail you did not ask about.",
        },
        "open": {
            "nikolai": "I liked her. Write that down first, because nothing after it sounds like it.",
            "adaeze":  "I was in the office with the books until four. Alone. I know how that sounds.",
            "vee":     "I wasn't there. For once in my life I have somewhere else to be and no way to prove it.",
        },
        "statements": [
            ## --- Nikolai ------------------------------------------------------
            ("nikolai", "nik2_iris", "Iris", 0,
             "Thirty-eight, twice as smart as this place needed, and she stayed anyway."),
            ("nikolai", "nik2_rain", "the rain", 0,
             "Stopped at three. Everyone keeps saying it like it settles something."),
            ("nikolai", "nik2_car", "her car", 0,
             "She backed it in. Always. Said she liked being able to leave in one move."),
            ("nikolai", "nik2_books", "the books", 1,
             "Two sets. That is not an accusation, that is a Tuesday."),
            ("nikolai", "nik2_second", "the second set", 1,
             "The real one had her handwriting in the margins. Somebody has been reading it."),
            ("nikolai", "nik2_ade", "Adaeze", 2,
             "She signed every page. If the pages are wrong, there is exactly one signature on them."),
            ("nikolai", "nik2_offer", "what Iris wanted", 3,
             "She asked me what it costs to leave a place like this. I told her nobody had "
             "ever paid it in one go."),
            ("nikolai", "nik2_light", "the bay light", ROUTE,
             "The bay light is on a timer and it was off. Somebody killed it from inside, "
             "and the switch for it is in the mop room."),

            ## --- Adaeze -------------------------------------------------------
            ("adaeze", "ade2_four", "until four", 0,
             "Books, coffee, the desk lamp. No door, no phone, no witness. I am aware."),
            ("adaeze", "ade2_iris", "Iris", 0,
             "She worked for me for six years and I do not know the name of her sister."),
            ("adaeze", "ade2_bay", "the loading bay", 0,
             "It floods. It has flooded every winter since before my name went on anything."),
            ("adaeze", "ade2_sign", "your signature", 1,
             "On every page. That is what a manager is. A person who is on every page."),
            ("adaeze", "ade2_audit", "the audit", 1,
             "There was going to be one. She told me. She told me like she was doing me a kindness."),
            ("adaeze", "ade2_night", "that night", 2,
             "I heard her car. I did not hear it leave. I told myself she was on the phone."),
            ## The slip. The bay water is rain and diesel; nobody released that her lungs
            ## held neither. Adaeze is describing the only clean deep water in the building.
            ("adaeze", "ade2_basin", "clean water", 3,
             "You keep saying drowned like the bay explains it. That water is filthy. "
             "The only clean basin in this building is the mop room sink and it is deep "
             "enough to lose an arm in. I have known that for six years."),
            ("adaeze", "ade2_mop", "the mop room", ROUTE,
             "I was in there at half past three. I will say that before you find someone "
             "who says it for me."),

            ## --- Vee ----------------------------------------------------------
            ("vee", "vee2_where", "where you were", 0,
             "A room with a door that locks from outside. You can check. Please check."),
            ("vee", "vee2_bail", "the bail", 0,
             "Somebody paid it. I did not ask who, because I know what asking costs."),
            ("vee", "vee2_iris", "Iris", 0,
             "She wrote down what I brought in. Every crate. She never once wrote down my name."),
            ("vee", "vee2_kind", "why that mattered", 1,
             "Because everyone else in my life keeps a list, and hers was the only one I wasn't on."),
            ("vee", "vee2_paid", "who paid", 1,
             "I have a guess. My guess is a man who likes people to owe him something soft."),
            ("vee", "vee2_cold", "the last case", 2,
             "You think I don't know what you all decided about me. I know."),
            ("vee", "vee2_scared", "what you're afraid of", 3,
             "That it doesn't matter what I did. That there's a shape people have decided "
             "I am, and it has a chair in it, and the chair is this one."),
            ("vee", "vee2_seen", "what you saw", ROUTE,
             "I came back for a jacket. Around four. There was a light on in the mop room "
             "and I did not go in, and I have been sick about it since."),
        ],
    },

    ## ================================================================== case 3
    {
        "id": "fire_stairs",
        "title": "What the Room Heard",
        "night": "the last night",
        "victim": "Bo Kestrel, 45. Licensing inspector. Held the Paloma's future in a folder.",
        "public": [
            "Found at 01:20 on the fire stairs between the second and third landing.",
            "Cause of death: a fall. The fall is consistent with the stairs.",
            "The inspection was booked for the following morning.",
            "His folder was on the landing beside him. Nothing in it was missing.",
        ],
        ## He did not fall on the stairs. He was struck in the office, where the safe
        ## stood open, and the safe's inner drawer — the ledger, not the money — is empty.
        "withheld": "Bo was killed in the office. The safe's inner drawer was emptied of a ledger.",
        "solution": "nikolai",
        "decisive": "nik3_drawer",
        "roles": {
            "nikolai": "Fixer. Has been in this room more than you have.",
            "adaeze":  "Manager. Out on your paperwork, back behind your table.",
            "vee":     "Courier. Has stopped pretending to have anywhere else to be.",
        },
        "open": {
            "nikolai": "Third time, Reyes. At some point this stops being detective work and starts being a habit.",
            "adaeze":  "You let me out of one of these six days ago. I have not redecorated since.",
            "vee":     "I'm here. I didn't wait for you to send anyone. That has to be worth something.",
        },
        "statements": [
            ## --- Nikolai ------------------------------------------------------
            ("nikolai", "nik3_bo", "Bo Kestrel", 0,
             "An inspector who took a folder everywhere. A man can be honest and still be a problem."),
            ("nikolai", "nik3_stairs", "the fire stairs", 0,
             "Concrete, steel nosing, no handrail on the turn. The building has been trying "
             "to kill somebody there for thirty years."),
            ("nikolai", "nik3_morning", "the inspection", 0,
             "Nine in the morning. Everyone in this building had somewhere to be at nine."),
            ("nikolai", "nik3_folder", "the folder", 1,
             "Still beside him. Which is the part nobody wants to talk about, so let us not."),
            ("nikolai", "nik3_paloma", "the Paloma", 1,
             "It has been dying for two years. Three deaths is not a run of luck, it is a diagnosis."),
            ("nikolai", "nik3_safe", "the safe", 2,
             "Open, I'm told. Money still in it, I'm told. You keep handing me facts "
             "I am supposed to find surprising."),
            ## The slip. That the safe has an inner drawer, and that the ledger lived in
            ## it, was never released — the file says only that nothing was missing.
            ("nikolai", "nik3_drawer", "what was worth taking", 3,
             "Nothing in that safe was worth a life. The money, I mean. The money was never "
             "the thing. The inner drawer is the thing, and you already know it was the "
             "ledger in there and not a single note, or you would not have come back a third time."),
            ("nikolai", "nik3_tired", "why you keep coming back", ROUTE,
             "Because I am the only one of the three who has never once asked you for anything. "
             "You should have found that strange a long time ago."),

            ## --- Adaeze -------------------------------------------------------
            ("adaeze", "ade3_lease", "the lease, again", 0,
             "Still mine. Getting heavier."),
            ("adaeze", "ade3_bo", "Bo Kestrel", 0,
             "He was polite to me in a way that meant he had already written his report."),
            ("adaeze", "ade3_night", "last night", 0,
             "Upstairs, in the flat over the club, with the lights off, doing nothing at all."),
            ("adaeze", "ade3_report", "the report", 1,
             "It was going to close us. He did not say so. You do not have to say so."),
            ("adaeze", "ade3_after", "since Iris", 1,
             "I sign nothing now. Somebody else can be on every page for a while."),
            ("adaeze", "ade3_nik", "Nikolai", 2,
             "He has never asked me for one thing in six years. I used to find that restful."),
            ("adaeze", "ade3_owe", "what he is owed", 3,
             "A man who is never owed anything is a man who has already taken it."),
            ("adaeze", "ade3_office", "the office light", ROUTE,
             "There was a light in the office at one. From upstairs you can see it in the "
             "yard, on the wall. I watched it go out and I did not come down."),

            ## --- Vee ----------------------------------------------------------
            ("vee", "vee3_here", "why you came in", 0,
             "Because the third time you send someone for me, I would rather have walked in myself."),
            ("vee", "vee3_bo", "Bo Kestrel", 0,
             "Never met him. That is the first true thing I have said in this room in a month."),
            ("vee", "vee3_night", "last night", 0,
             "Outside the yard door from midnight. Smoking. I can tell you what colour the "
             "wall is at one in the morning."),
            ("vee", "vee3_yard", "the yard", 1,
             "You can hear the office through the vent. You cannot hear words. You can hear "
             "that there are words."),
            ("vee", "vee3_heard", "what you heard", 1,
             "Two people. One of them doing most of it. Then one set of feet on the stairs, "
             "going down slow, like carrying."),
            ("vee", "vee3_tell", "why you didn't say", 2,
             "Because last time I told the truth about a room I was standing in, it took "
             "eleven months off my life."),
            ("vee", "vee3_believe", "what you want", 3,
             "One person in this city to hear me say a thing and write it down the way I said it."),
            ("vee", "vee3_slow", "going down slow", ROUTE,
             "Slow on the way down. Quick on the way up. Nobody carries anything up."),
        ],
    },

    ]

    CASE_COUNT = len(CASES)

    ## Lines that only the optional routes produce, by case and suspect.
    ROUTE_FACT = {
        "cold_room":   {"nikolai": "nik_curtain",  "adaeze": "ade_seal",  "vee": "vee_hands"},
        "loading_bay": {"nikolai": "nik2_light",   "adaeze": "ade2_mop",  "vee": "vee2_seen"},
        "fire_stairs": {"nikolai": "nik3_tired",   "adaeze": "ade3_office", "vee": "vee3_slow"},
    }

    def load_case(idx):
        """Make CASES[idx] the live case and clear everything the last one left behind."""
        store.case_index = idx
        c = CASES[idx]
        store.CASE = c
        store.SUSPECTS = {
            sid: {"name": CAST[sid]["name"], "cg": CAST[sid]["cg"],
                  "role": c["roles"][sid], "open": c["open"][sid]}
            for sid in CAST
        }
        store.STATEMENTS = c["statements"]
        store.questions_left = 12
        store.pressure = {sid: 0 for sid in CAST}
        store.heard = set()
        store.accused = None
        store.decisive = None
        store.cur_suspect = None
        store.interrogations_done = 0
        store.route = None

    def learn_route_fact(sid):
        """Put the route's line on the board. Called from suspect_route."""
        fid = ROUTE_FACT.get(CASE["id"], {}).get(sid)
        if fid:
            heard.add(fid)

    def statements_for(sid):
        return [s for s in STATEMENTS if s[0] == sid]

    def available_statements(sid):
        p = pressure.get(sid, 0)
        return [s for s in statements_for(sid) if s[3] != ROUTE and s[3] <= p]

    def locked_count(sid):
        p = pressure.get(sid, 0)
        return len([s for s in statements_for(sid) if s[3] != ROUTE and s[3] > p])

    def statement_text(stmt_id):
        for s in STATEMENTS:
            if s[1] == stmt_id:
                return s[4]
        return ""

    def heard_statements():
        return [s for s in STATEMENTS if s[1] in heard]
