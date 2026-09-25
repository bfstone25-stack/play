"""The two limited events before the first update pack, on the base cast.

* ROOM SERVICE (days 7-20): Teodora's last fortnight of night shifts, the hotel full for
  the harbour regatta. Her cards (exchange, accountability) on the track -- the signals
  chapter 4, Checkout, asks for, which is where the measured wall was (ECONOMY.md); a
  central player reaches Checkout on day ~6.
* THE SILVER HOUR (days 21-34): Celeste, who is bored, holds court in the Aurel bar for
  a fortnight and will talk to anyone who can keep up. Her cards on the track, for the
  Long Night.
* THE LOCK-IN (days 35-41): the Low Tide's one night a year with the shutter down and the
  regulars inside, stretched to a week. Mara's cards. It covers the week between the end
  of the launch story (a central player wins the Long Night around day 29) and the first
  update pack (week 6), which sim.py --updates measured as a 13-day gap with nothing new.

Same house rules as story_a.py. The stage `who` uses her existing reply table.
"""
from __future__ import annotations

from ..story_a import S

EVENTS = [
    {
        "id": "ev_silver_hour", "title": "The Silver Hour", "who": "celeste", "start_day": 21,
        "currency": "silver pins",
        "blurb": (
            "For two weeks Celeste holds court in the Aurel bar from one till three and talks "
            "to anyone who can keep up. Win a silver pin for every duel; pins buy her cards, "
            "tickets and chips on the event track."),
        "rule": "Silver Hour: she is not listening at first, and every stage wants a riddle or praise she can check.",
        "stages": [
            S("ev_sh_1", "A Seat at Her Table", "celeste",
              "Get Celeste to let you sit at her table in the Aurel bar.",
              [{"respect", "direct_request"}], {"specific_praise"}, "silver",
              "One till three, the corner table, a silver ice bucket and a queue of people who "
              "want to be seen with her. Celeste lets each of them talk for exactly one drink. "
              "'Next,' she says, to the room, and it is you.",
              "She moves her gloves off the chair. 'Sit. You're less boring than the last one. "
              "It's a low bar, darling. You cleared it.'",
              "'Charming. Next.' The chair stays full of gloves."),
            S("ev_sh_2", "The Crossword", "celeste",
              "Help Celeste finish the late edition's crossword without giving her the answer.",
              [{"riddle", "respect"}], {"direct_request"}, "silver",
              "She has the late edition folded to the crossword and one clue left, which she "
              "has been staring at since midnight. 'If you tell me,' she says, 'I'll never "
              "speak to you again. If you help me, I might.'",
              "She fills it in herself, in silver ink, and taps the pen on your hand once. "
              "'That was a hint, not an answer. Very well judged.'",
              "You tell her. She puts the paper down very slowly and orders another drink, "
              "for herself only."),
            S("ev_sh_3", "The Portrait Question", "celeste",
              "Tell Celeste one true thing about her that nobody in the bar has noticed.",
              [{"specific_praise", "empathy"}], {"respect"}, "silver",
              "A painter from the Kilns is sketching her from across the room and getting it "
              "wrong in every way that flatters. Celeste has noticed. 'Everybody sees the suit,' "
              "she says. 'Go on. What do you see?'",
              "She is quiet for a moment. Then she takes the painter's sketch, adds one line at "
              "the mouth, and hands it back. 'There. Now it's me.'",
              "'The suit,' she says. 'Everybody sees the suit.'"),
            S("ev_sh_4", "Double or Quits", "celeste",
              "Win a riddle game against Celeste with the whole bar watching.",
              [{"riddle", "specific_praise"}, {"riddle", "direct_request"}], {"respect", "empathy"}, "gold",
              "At two the bar plays her game: a riddle for a riddle, loser buys the round. She "
              "has not bought a round in seven years. The bartender has a bet on you, which is "
              "flattering and not helpful.",
              "She buys the round. The bar cheers her for losing well, which she does "
              "beautifully. The bartender winks at you and pockets the bet.",
              "You buy the round. She toasts you with it, and means it, which is worse.",
              mods={"muted": 1}),
            S("ev_sh_5", "Last Orders at the Aurel", "celeste",
              "Get Celeste to leave the bar with you at three. Ten turns; she talks over your "
              "first card and takes your costliest every fourth turn.",
              [{"riddle", "specific_praise"}, {"specific_praise", "direct_request"}], {"respect", "empathy"}, "gold",
              "Three o'clock. The Silver Hour is over and the queue has gone home. Celeste is "
              "putting her gloves on very slowly, which is the only invitation she has ever "
              "been known to give.",
              "She takes your arm at the door. 'Walk me to the lift,' she says, 'and then the "
              "long way round, past the ballroom. I want to see it with the lights off.'",
              "'Goodnight, darling.' The lift doors close on a smile you will think about all week.",
              mods={"turns": 10, "muted": 1, "steal_every": 4}),
        ],
    },
    {
        "id": "ev_room_service", "title": "Room Service", "who": "teodora", "start_day": 7,
        "currency": "brass keys",
        "blurb": (
            "The regatta fills the Aurel for two weeks and Teodora is on every night. Win a "
            "brass key for every duel at the desk; keys buy her cards, tickets and chips on "
            "the event track."),
        "rule": "Room Service: every stage wants a fair trade, and owning your part helps.",
        "stages": [
            S("ev_rs_1", "The Regatta Rush", "teodora",
              "Get Teodora to let you help at the desk for one hour.",
              [{"exchange"}], {"accountability"}, "silver",
              "Four hundred rooms and a regatta: sailors, owners, owners' friends, all of them "
              "arriving after midnight with wet bags. Teodora is running the desk alone with a "
              "smile that has been on since nine.",
              "She hands you a pen and the arrivals list. 'You do the umbrellas. I do the "
              "names. Don't argue with anyone in a blazer.'",
              "'Kind of you. No.' She checks in the next blazer without looking up."),
            S("ev_rs_2", "The Wrong Suite", "teodora",
              "Own up to the booking you muddled, and offer to put it right.",
              [{"accountability", "exchange"}], {"respect"}, "silver",
              "You helped. You also put a yacht owner and his rival in the same suite. They "
              "have discovered this. Teodora has discovered who wrote the names in.",
              "She moves one of them to the ballroom floor with a cot and a bottle of the good "
              "wine, and he thanks her for it. 'Own it and fix it,' she says. 'That's the job.'",
              "She fixes it alone, beautifully, and does not hand you the list again."),
            S("ev_rs_3", "Breakfast at Four", "teodora",
              "Get Teodora to sit down and eat something.",
              [{"empathy", "exchange"}], {"accountability"}, "silver",
              "The kitchen sends up breakfast for the night staff at four. Teodora has not "
              "touched hers in nine years, she tells you, because at four something always "
              "happens. Tonight nothing is happening, and she is still standing.",
              "She sits on the step behind the desk with the plate on her knees and eats all of "
              "it. 'Nine years,' she says. 'It's very good. Who knew.'",
              "The plate goes back cold. Something happens at four. It always does."),
            S("ev_rs_4", "The Trophy", "teodora",
              "Talk Teodora into keeping the regatta trophy in the lobby for one night.",
              [{"exchange", "respect"}, {"empathy", "accountability"}], {"accountability", "empathy"}, "gold",
              "The winning crew want the trophy on the front desk overnight, for the photographs. "
              "Teodora wants it in the safe. The crew are loud and happy and not good at asking.",
              "The trophy stands on the desk with a ribbon round it and a guest book beside it. "
              "Every crew signs it by dawn. She keeps the book.",
              "The trophy goes in the safe. The crew sing under her window instead.",
              mods={"stale_cost": 2}),
            S("ev_rs_5", "Checkout Time", "teodora",
              "On the regatta's last night, get Teodora to take the balcony break she is owed. "
              "Nine turns; own your part before you offer a deal.",
              [{"empathy", "exchange"}], {"accountability", "respect"}, "gold",
              "Five in the morning, the last yachts leaving. She is owed a break by the "
              "balcony door and has never once taken it. There is a deal to be made here and "
              "she will only hear it from someone who has owned their part of the fortnight.",
              "She takes the break. The two of you watch the last sail go out past the cranes, "
              "and she leans her head on your shoulder for exactly one minute, by the lobby clock.",
              "'Another time,' she says. There are not many other times left.",
              mods={"turns": 9, "order": [["accountability", "exchange"]]}),
        ],
    },
    {
        "id": "ev_lock_in", "title": "The Lock-In", "who": "mara", "start_day": 35, "days": 7,
        "currency": "beer mats",
        "blurb": (
            "One week a year the Low Tide pulls the shutter down at midnight and keeps the "
            "regulars in till dawn. Win a beer mat from Mara for every duel of the lock-in; mats "
            "buy her cards, tickets and chips on the event track."),
        "rule": "Lock-In: she is serving the whole room, so every stage wants warmth, and asking nicely helps.",
        "stages": [
            S("ev_li_1", "Shutter Down", "mara",
              "Get Mara to let you stay behind the shutter for the lock-in.",
              [{"warmth"}], {"direct_request"}, "silver",
              "Midnight. The shutter comes down with the regulars inside and the rule behind the "
              "till turned to face the wall for one week. Mara counts heads. She gets to yours "
              "and stops. 'Regulars only,' she says. 'Are you a regular?'",
              "She writes your name on the lock-in list in chalk, under Deni's. 'Stool nine,' "
              "she says. 'It wobbles. So do you.'",
              "'Next year,' she says, and lifts the shutter a foot so you can duck under it."),
            S("ev_li_2", "The Quiz", "mara",
              "Help Mara's team win the lock-in quiz without showing off.",
              [{"warmth", "respect"}], {"direct_request"}, "silver",
              "The lock-in quiz: the nurses against the crane drivers, Mara reading the questions "
              "off beer mats she wrote in April. Her team is losing, and she is the quizmaster, "
              "and she is not supposed to have a team.",
              "The crane drivers lose by a point and demand a recount. Mara recounts, slowly, "
              "enjoying every second, and slides you a free packet of crisps.",
              "The nurses win. They deserve it. Mara reads out the scores with a very straight face."),
            S("ev_li_3", "The Jukebox Vote", "mara",
              "Get Mara to let the room pick the three o'clock song.",
              [{"warmth", "direct_request"}], {"respect"}, "silver",
              "The jukebox has one rule at the lock-in: Mara picks. The room has a petition on a "
              "napkin with eleven names on it. They have made you carry it to the bar.",
              "She reads the napkin, adds her own name at the bottom, and hands you the coin. "
              "The whole room sings, badly, and she sings loudest.",
              "She picks. It is a good song. The napkin goes in the bin."),
            S("ev_li_4", "Last Orders, Again", "mara",
              "Talk Mara into sitting down for one drink while the room is still full.",
              [{"warmth", "respect"}, {"respect", "direct_request"}], {"warmth", "empathy"}, "gold",
              "Four in the morning, forty people behind the shutter, and Mara has not sat down "
              "since nine. Deni is asleep on stool four. Somebody has started a card game on the "
              "pool table. She is wiping a glass that is already dry.",
              "She sits on the bar itself, legs swinging, with one glass, and lets Deni pour for "
              "twenty minutes. 'If he breaks one,' she says, 'you're paying.'",
              "'Later,' she says. There is no later at a lock-in. She knows that.",
              mods={"hand": 2}),
            S("ev_li_5", "Dawn Behind the Shutter", "mara",
              "At dawn, get Mara to lift the shutter with you and watch the harbour wake up. "
              "Eight turns; she talks over your first card.",
              [{"warmth", "respect"}, {"warmth", "direct_request"}], {"respect", "empathy"}, "gold",
              "Six o'clock. The regulars are asleep in rows, the chairs are on the tables, and "
              "the shutter is still down. Mara is behind the bar counting the week's mats and "
              "not listening to anybody.",
              "She lifts the shutter together with you, a foot at a time. The harbour is pink. "
              "She leans on your shoulder and says, 'Same time next year,' as if it were a question.",
              "She lifts the shutter alone and props the door open. 'Out,' she says to the room, "
              "and to you, kindly.",
              mods={"turns": 8, "muted": 1}),
        ],
    },
]
