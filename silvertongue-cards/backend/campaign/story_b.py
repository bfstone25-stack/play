"""SUASION: THE NIGHT LEDGER -- the campaign's words, part B: chapters 4-6 and the ending.
Same rules as story_a.py."""
from __future__ import annotations

from .story_a import S

# ==========================================================================================
CH4 = {
    "id": "c4", "title": "Checkout", "house": "The Aurel Front Desk", "who": "teodora",
    "intro": (
        "The Hotel Aurel has four hundred rooms, a ballroom nobody has danced in since the "
        "harbour strike, and a front desk that has been run for nine years by Teodora "
        "Ansah. She is forty-one. She knows every guest's floor, every guest's umbrella, "
        "and which of them lie about their names. She wears the gold crossed keys of the "
        "concierges' guild on her lapel, and in three weeks she is leaving Vell for good.\n\n"
        "The desk signs the Ledger. The desk is Teodora, for three more weeks. Sanne said: "
        "'She's heard every story in the city. Don't tell her one. Give her something back.'"),
    "outro": (
        "She signs at the desk, on the Aurel's paper, in the copperplate she learned in "
        "her first week. Then she unpins the crossed keys and puts them in your palm and "
        "closes your fingers over them. 'Not for the job,' she says. 'For you. Somebody "
        "should remember which floor I liked.'\n\n"
        "At eleven the next morning, you are not at the airport. She asked you not to be. "
        "You keep that promise too."),
    "stages": [
        S("c4s01", "The Night Desk", "teodora",
          "Get Teodora to talk to you as a person, not a guest.",
          [{"empathy"}], {"accountability"}, "silver",
          "The lobby at one in the morning: marble, a clock that runs two minutes fast on "
          "purpose, and Teodora at the desk in navy and gold, writing in the night book. "
          "'Good evening. Your key, or a message?' She says it to everyone. She says it "
          "beautifully.",
          "She puts the pen down. 'Neither, then.' For the first time she looks at you "
          "rather than at the clock. 'Sit. The chair's for guests, but nobody's watching.'",
          "'Good night.' She is already writing the next line in the night book."),
        S("c4s02", "The Lost Umbrella", "teodora",
          "Make a fair trade with Teodora for the lost-property cupboard key.",
          [{"exchange"}], {"respect"}, "silver",
          "Behind the desk is a cupboard of nine years of lost things: umbrellas, one glove "
          "of every pair, a violin, a wedding ring nobody came back for. You lost a scarf here "
          "a year ago. The key to the cupboard is on her ring and she does not give things away.",
          "She finds the scarf in under a minute. It has been folded and tagged with the date. "
          "'I kept it in front,' she says. 'I thought you would come back for it.'",
          "'Lost property is for guests.' The scarf stays folded, in front, waiting."),
        S("c4s03", "Room 409", "teodora",
          "Own up to what happened the last time you stayed at the Aurel.",
          [{"accountability", "empathy"}], {"respect"}, "silver",
          "A year ago, on your last night in Vell, you left room 409 without checking out, "
          "and without paying, and without saying goodbye to the woman who had handed you "
          "your key every night for a month. She has not mentioned it. The bill is in her drawer.",
          "She takes the bill out, reads it once, and tears it in half. 'You came back to "
          "say it. That was the payment.' She keeps one half, though.",
          "She puts the bill back in the drawer. It is very neatly filed."),
        S("c4s04", "The Guild Dinner", "teodora",
          "Ask Teodora to let you walk her to the concierges' dinner.",
          [{"direct_request", "empathy"}], {"accountability"}, "silver",
          "The concierges of Vell have dinner together once a year, and this year it is "
          "her farewell. She has been dressed for it since midnight and has not left the desk. "
          "'Someone has to be here,' she says, as if the building might wander off.",
          "You walk her there along the harbour. She takes your arm at the corner and does "
          "not let go until the restaurant door. 'Nine years,' she says. 'Nobody walked me.'",
          "She goes alone, late, and leaves early."),
        S("c4s05", "The Ballroom", "teodora",
          "Offer Teodora something in return for opening the ballroom.",
          [{"exchange", "respect"}], {"empathy"}, "silver",
          "The Aurel's ballroom has been locked since the strike. Dust sheets over the "
          "chairs, a chandelier in a bag. Teodora has the key. The Long Night is held here, "
          "the old way, if anyone can get the doors open. She has not decided if anyone should.",
          "The doors open on a smell of old wax. She pulls one dust sheet off and there is a "
          "gold chair under it, like new. 'It was always beautiful,' she says. 'It was only asleep.'",
          "The key goes back on her ring. The chandelier stays in its bag."),
        S("c4s06", "Suite Nine", "celeste",
          "Get Celeste to give up the suite's balcony for Teodora's last sunrise.",
          [{"empathy", "exchange"}], {"accountability"}, "gold",
          "Celeste lives at the Aurel, in suite nine, and has for seven years. The suite has "
          "the only balcony facing east. Teodora has watched the harbour from the front steps "
          "for nine years and never once from up there. Celeste opens the door in a robe and "
          "looks at you over a coffee cup. 'At this hour? This had better be good.'",
          "She hands you the balcony key. 'Tell her it's from me. No, don't. Tell her it's "
          "from you.' She closes the door. You hear her laugh through it.",
          "'Go away, darling. Some of us sleep.' The door closes softly and decisively.",
          mods={"muted": 1, "steal_every": 4}),
        S("c4s07", "The Night Book", "teodora",
          "Get Teodora to show you what she writes in the night book.",
          [{"empathy", "accountability"}], {"exchange"}, "gold",
          "Every night for nine years she has written in the night book. Arrivals, "
          "departures, complaints, the weather. You have seen her write in it a hundred "
          "times. Tonight she closes it when you come in, and puts her hand flat on the cover.",
          "She opens it to last March. Your name, every night for a month. Next to it, in "
          "pencil, very small: kind to the night porter. She closes it again. 'Don't make it a thing.'",
          "'Hotel business.' The book goes in the safe."),
        S("c4s08", "Replacement", "teodora",
          "Help Teodora choose who will run the desk when she's gone.",
          [{"evidence", "empathy"}], {"exchange", "accountability"}, "gold",
          "Three applicants for her job, three files on the desk. She has read each one "
          "nine times. None of them is good enough, because none of them is her, and she "
          "knows that is not a reason and is using it as one anyway.",
          "She picks the night porter. He has been at the Aurel longer than she has and "
          "nobody ever thought to ask. She goes down to tell him herself.",
          "'I'll decide in the morning.' In the morning, the management decides for her."),
        S("c4s09", "The Keys", "teodora",
          "Ask Teodora why she is really leaving Vell.",
          [{"empathy", "direct_request"}, {"accountability", "exchange"}], {"respect"}, "gold",
          "She turns the crossed keys on her lapel with one finger, over and over, while you "
          "talk. You have never seen her fidget. 'Everyone asks where I'm going,' she says. "
          "'Nobody asks why.'",
          "'Because if I stay one more year I will stay for ever, and I will have handed "
          "keys to the whole world and never once gone through a door myself.' She lets go "
          "of the pin. 'There. Somebody knows.'",
          "'A new job,' she says, which is true, and is not the answer."),
        S("c4s10", "Umbrella Weather", "teodora",
          "Get Teodora to walk out in the rain with you.",
          [{"exchange", "warmth"}], {"empathy", "accountability"}, "gold",
          "It is raining on the harbour the way it only rains in Vell, sideways and warm. "
          "Teodora has handed out forty umbrellas tonight. She has never once used one. "
          "She is watching the rain from inside the revolving door.",
          "No umbrella. She walks out into it with her face up and laughs, and her hair comes "
          "down, and she does not care who sees.",
          "She hands you an umbrella, professionally. The revolving door turns her back inside."),
        S("c4s11", "Last Guest", "teodora",
          "Keep Teodora company until the last guest goes up.",
          [{"empathy", "exchange", "accountability"}], {"respect"}, "gold",
          "Her second to last night. The last guest is a drunk tenor who will not go to "
          "bed and will not stop singing, and Teodora is handling him the way she has handled "
          "everything for nine years: perfectly, and alone.",
          "The tenor goes up at midnight. Teodora sits down on the lobby sofa, which she "
          "has never done in uniform, and puts her feet up on the marble.",
          "She handles him perfectly, alone, until three. Then she goes home without a word."),
        S("c4s12", "BOSS: Checkout", "teodora",
          "Get Teodora to spend her last night with you. Own your part before you offer anything. Nine turns.",
          [{"empathy", "exchange"}], {"accountability"}, "gold",
          "The last guest went up at midnight. The lobby lamp is on its overnight setting and "
          "the ledger is closed. Nine years she has handed you keys and taken your umbrella "
          "and known which floor you like. Tomorrow at eleven she is on a plane, and she has "
          "just unpinned the gold keys from her lapel. She will not take a deal from anyone "
          "who has not first owned what they owe.",
          "'Tonight,' she says. 'Only tonight. And then I go.' She takes your hand and the "
          "service lift, which guests are not allowed to use.",
          "'Good night.' She pins the keys back on for the last hour of her last shift.",
          mods={"turns": 9, "order": [["accountability", "exchange"]],
                "boss": "Checkout: nine turns, and own your part (accountability) before you "
                        "offer a deal (exchange)."},
          reply="last_night"),
    ],
}

# ==========================================================================================
CH5 = {
    "id": "c5", "title": "The Box in the Hall", "house": "The Ledger's Keeper", "who": "ines",
    "intro": (
        "Four signatures. The fifth is the keeper's, and the keeper signs last. The keeper "
        "is Ines Okafor. She is thirty-four, she has kept the Night Ledger in the back "
        "office of the Aurel for five years, and eleven months ago you lived with her.\n\n"
        "You left. You never said why. There is a box of her things still in the hall of "
        "the flat you kept, and she has not come for it.\n\n"
        "Teodora said it on her last night: 'You can talk any door in Vell open. That one "
        "you will have to walk through.'"),
    "outro": (
        "She does not sign in the back office. She takes the green book home, to the flat, "
        "and opens it on the kitchen table where you used to eat, and signs on the line "
        "under Teodora's copperplate in her own small upright hand.\n\n"
        "The box in the hall stays where it is. 'I'll take it next week,' she says. 'Or I "
        "won't. Let's find out.' Five signatures. The Long Night is in three days."),
    "stages": [
        S("c5s01", "The Back Office", "ines",
          "Get Ines to let you into the back office.",
          [{"respect", "accountability"}], {"empathy"}, "silver",
          "The back office of the Aurel is a room the size of a wardrobe with a lamp, a "
          "chair and the green book in a glass case. Ines is at the desk with her cardigan "
          "pulled shut. She saw you come in through the lobby. She has had four minutes to "
          "decide what her face will do.",
          "'Sit.' There is only one chair. She gives it to you and leans on the case, which "
          "she has told a thousand people not to do.",
          "'The office is closed.' She says it to the green book."),
        S("c5s02", "What the Ledger Says", "ines",
          "Get Ines to tell you what the Ledger says about you.",
          [{"empathy", "respect"}], {"accountability"}, "silver",
          "Every name in the Ledger has a line beside it, written by the keeper. You have "
          "four signatures and a line you have never read. Ines has her hand on the page. "
          "'You won't like it,' she says. 'I wrote it the week you left.'",
          "She lets you read it. Three words, in her small upright hand: DOES NOT STAY. Under "
          "it, fresh ink, one more: YET.",
          "She closes the book. 'Some other night.'"),
        S("c5s03", "The Cab", "ines",
          "Ask Ines to send the waiting cab away.",
          [{"direct_request", "empathy"}], {"respect"}, "silver",
          "She always keeps a cab waiting when she talks to you. It is out on the "
          "forecourt now with its meter running, and she keeps glancing at it through "
          "the lobby glass, the way you glance at an exit in a theatre.",
          "She goes out and pays the driver and comes back in without a coat, and does not "
          "look at the forecourt again all night.",
          "The cab takes her home at one. The meter has been running for two hours."),
        S("c5s04", "Eleven Months", "ines",
          "Own the way you left, without excuses.",
          [{"accountability"}], {"respect", "empathy"}, "gold",
          "'You left a note,' Ines says. 'It said SORRY. Five letters. I read it every "
          "morning for a month. I was waiting for the rest of the word.'",
          "You give her the rest of the word. She listens to all of it without interrupting, "
          "which she has never once done in her life. At the end she says, 'Thank you.' Only that.",
          "'That's still five letters,' she says, and goes back to the green book."),
        S("c5s05", "Her Mother's Cardigan", "ines",
          "Get Ines to tell you why she wears the grey cardigan.",
          [{"empathy", "warmth"}], {"respect"}, "gold",
          "The cardigan is grey and too big and she has worn it every night this month. "
          "You bought it for her. No: you did not. You remember wrong. She is watching you "
          "remember wrong, and waiting to see if you will pretend.",
          "'It was my mother's. You never asked.' She pulls it tighter, and then lets it go "
          "loose. 'You're asking now. That's something.'",
          "'It's warm,' she says, and that is all it is allowed to be."),
        S("c5s06", "An Old Friend", "celeste",
          "Get Celeste to tell you what Ines was like the night you left.",
          [{"empathy", "respect"}], {"accountability", "direct_request"}, "gold",
          "Celeste is waiting for you on the Aurel's stairs with two glasses and no "
          "bottle. 'She came to me that night,' she says. 'Not to you. To me. I'll tell you "
          "what she said, if you can make me believe you should hear it.'",
          "She tells you. It takes a long time and she does not dress it up. At the end she "
          "says, 'I have wanted to beat you for a month. I'd rather you won this one.'",
          "'Ask her yourself.' She goes up the stairs with both glasses.",
          mods={"muted": 1, "hand": 2}),
        S("c5s07", "The Flat", "ines",
          "Ask Ines to come back to the flat, just to see it.",
          [{"direct_request", "respect"}, {"empathy", "accountability"}], {"warmth"}, "gold",
          "The flat you kept is four streets from the Aurel. She has walked the long way "
          "round it for eleven months. Tonight she stops at the corner and looks up at the "
          "window, where the light is on.",
          "She walks up the stairs and stands in the hall and looks at the box for a long "
          "time. She does not open it. She does not leave either.",
          "She takes the long way home."),
        S("c5s08", "The Kitchen Table", "ines",
          "Get Ines to sit down at the table you used to share.",
          [{"warmth", "empathy"}], {"accountability", "respect"}, "gold",
          "She is in the kitchen. She has put the kettle on, because her hands needed "
          "something to do. The table has a burn mark from a pan you swore you would sand "
          "out. You never sanded it out.",
          "She sits. She puts her finger on the burn mark. 'You never fixed this.' You say "
          "you will. 'Don't,' she says. 'I'd miss it.'",
          "She drinks her tea standing up, and leaves the cup on the draining board."),
        S("c5s09", "Precisely", "ines",
          "Tell Ines exactly what you want, and exactly what you don't.",
          [{"precision", "empathy"}], {"accountability", "respect"}, "gold",
          "'You always said you wanted everything,' she says. 'Everything is a lazy word. "
          "Tell me precisely. I keep a ledger. I like things written down.'",
          "She writes it on the back of a receipt while you talk. Then she folds it into her "
          "purse, next to her keys, where she keeps things she means to keep.",
          "'Everything,' she repeats. 'Still.' She does not write it down."),
        S("c5s10", "The Keeper's Line", "ines",
          "Get Ines to admit what she wrote beside her own name.",
          [{"empathy", "accountability", "respect"}], {"warmth"}, "gold",
          "The keeper writes a line beside every name, including her own. Nobody has ever "
          "read hers. The page is folded down, and she has her palm on it, and she is "
          "deciding, in front of you, whether you are somebody who gets to read it.",
          "She unfolds the page. Beside INES OKAFOR, in her hand, a year old: WAITS TOO LONG. "
          "She crosses it out while you watch.",
          "The page stays folded. She puts the Ledger back in its case."),
        S("c5s11", "Five Letters", "ines",
          "Say the thing you left out of the note.",
          [{"accountability", "empathy"}, {"direct_request", "respect", "warmth"}], {"respect"},
          "gold",
          "Three in the morning in the flat. The last night before the keeper decides. She "
          "is sitting on the box in the hall, which is the only place she could find to sit "
          "that was not a choice.",
          "When you finish she gets up off the box. 'That's the rest of the word,' she says. "
          "'It took you eleven months and it was worth it. Almost.'",
          "'Five letters,' she says, very quietly, and goes out to the forecourt to find a cab."),
        S("c5s12", "BOSS: The Box in the Hall", "ines",
          "Get Ines to stay tonight. She has heard every apology before: a repeated line costs two turns.",
          [{"empathy", "accountability"}], {"respect", "warmth"}, "gold",
          "She has come for the box. Half past ten, with a cab she did not ask to wait. She "
          "is standing in the doorway with the cardigan pulled shut in one fist. You were "
          "the one who left. Whatever you say next she has already heard the apology "
          "version of in her head for eleven months, and she will not hear it twice.",
          "The cab leaves without her. She puts the cardigan over the back of the chair "
          "where she always used to put it.",
          "She picks up the box. It is lighter than she remembered. She goes.",
          mods={"stale_cost": 2, "support": 2,
                "boss": "The Box in the Hall: she has heard it before. A card that adds "
                        "nothing new costs two turns, and she needs both kinds of support."},
          reply="the_key"),
    ],
}

# ==========================================================================================
CH6 = {
    "id": "c6", "title": "The Long Night", "house": "The Silver Seat", "who": "celeste",
    "intro": (
        "The last night of the year. The ballroom of the Aurel has its dust sheets off and "
        "its chandelier lit for the first time since the strike, and all of after-hours "
        "Vell is on the stairs: dockers, painters, photographers, porters, the night nurses "
        "from stool three. The Ledger is open on a gold chair at the top of the room.\n\n"
        "Five signatures make you a challenger. They do not make you the Silver Tongue. On "
        "the Long Night the challenger and the holder talk, in front of everyone, until one "
        "of them concedes. Celeste Marrow has not conceded in seven years.\n\n"
        "She is waiting at the top of the stairs in the grey silk. 'Finally,' she says. "
        "'Somebody who did it the other way.'"),
    "outro": (
        "Celeste concedes at a quarter to five, in front of the whole city, in one word. "
        "Then she laughs, and takes the silver pen from the gold chair, and writes your name "
        "on the first page herself.\n\n"
        "'Seven years,' she says, under the noise. 'Do you know what it is like, to have "
        "every door open? Nobody talks to you. They just let you in.' She gives you the pen. "
        "'Talk to me. That's the only thing I want. Talk to me like I'm a door.'\n\n"
        "Out on the harbour the sun comes up over the cranes. Mara's stout, Yuen Ha's blue "
        "painting, Sanne's print of Glass Street at four in the morning, Teodora's keys in "
        "your pocket, a box still in a hall. The Night Ledger has a new first page. Vell "
        "has a new Silver Tongue.\n\n"
        "The doors will need talking to again tomorrow night. That is the job."),
    "stages": [
        S("c6s01", "The Stairs", "celeste",
          "Get Celeste to let you climb the ballroom stairs beside her.",
          [{"riddle"}, {"specific_praise"}], {"respect"}, "silver",
          "Two hundred people on the stairs and one clear path up the middle, and Celeste "
          "standing on it. 'Every challenger walks up alone,' she says. 'Tradition. I "
          "invented it. Give me a reason to break it.'",
          "She offers her arm. You climb together, and the stairs go quiet, and then loud.",
          "You climb alone. Somebody on the stairs laughs. It is not unkind. It is worse.",
          reply="celeste"),
        S("c6s02", "Mara's Round", "mara",
          "Ask Mara to stand at your shoulder tonight.",
          [{"warmth", "direct_request"}, {"respect", "craft"}], {"respect"}, "gold",
          "Mara has brought the Low Tide with her: a crate of stout and THE STRANGER in a "
          "flask. She is behind the ballroom bar as if she owns it. 'I signed,' she says. "
          "'Signing's not cheering. What do you want from me tonight?'",
          "'Fine. Shoulder.' She comes round the bar with two glasses. 'If you lose I'm "
          "pretending I don't know you.'",
          "'I'll be at the bar.' She is. She watches every minute."),
        S("c6s03", "The First Exchange", "celeste",
          "Win the opening round against Celeste in front of the room.",
          [{"riddle", "respect"}], {"direct_request"}, "gold",
          "The first round of the Long Night is a riddle. It always is. Celeste asks one; "
          "the challenger answers and asks one back. Seven years of challengers lost on the "
          "first riddle, because they came to win an argument, and this is not an argument.",
          "She laughs, genuinely, and the room hears it. 'One-nil,' somebody shouts. It is "
          "the crane driver from stool four.",
          "'Nil-one,' says Celeste pleasantly. 'Try to keep up.'",
          mods={"muted": 1}, reply="celeste"),
        S("c6s04", "Yuen Ha's Portrait", "yuenha",
          "Get Yuen Ha to unveil the portrait she painted of Celeste.",
          [{"craft", "respect"}, {"precision", "empathy"}], {"direct_request"}, "gold",
          "Against the ballroom wall, under a sheet, is the portrait of Celeste as the city. "
          "Yuen Ha finished it at noon. She has paint on her jaw and she is refusing to lift "
          "the sheet. 'It's too true,' she says. 'She'll hate it.'",
          "The sheet comes off. Celeste, painted as Vell at night: every light a window, "
          "every window a little lonely. Celeste looks at it for a very long time.",
          "The sheet stays on. Celeste walks past it without knowing what it is."),
        S("c6s05", "Legends", "celeste",
          "Get Celeste to tell the room how she won her first Long Night.",
          [{"specific_praise", "empathy"}], {"respect", "direct_request"}, "gold",
          "'Everyone knows how I won,' Celeste says to the room. They do not. Seven years "
          "of stories and none of them the same. She has let every version stand, because a "
          "legend is only useful as long as nobody checks it.",
          "'I talked to the holder until dawn,' she says, 'and she was lonely, and I noticed.' "
          "The room goes very quiet. She looks at you. 'That's the whole trick.'",
          "'A lady never tells.' The room cheers. It is the answer they wanted.",
          mods={"steal_every": 4}, reply="celeste"),
        S("c6s06", "Sanne's Exposure", "sanne",
          "Get Sanne to show the room her print of Glass Street.",
          [{"evidence", "precision"}, {"direct_request", "respect"}], {"direct_request"}, "gold",
          "Sanne has the print of Glass Street at four in the morning in a portfolio under "
          "her arm, and a contract in her pocket for the right to show it, which she has "
          "drafted and not signed. 'It's not for anyone,' she says, from habit.",
          "She pins it on the wall beside the portrait. Every closed shop on the street. At "
          "the end of it, very small, two people walking. She did not tell you she kept that frame.",
          "The portfolio stays shut. She takes it home at dawn."),
        S("c6s07", "The Silver Pen", "celeste",
          "Get Celeste to put the silver pen down on the chair between you.",
          [{"riddle", "specific_praise"}], {"direct_request", "respect"}, "gold",
          "Midnight. Celeste has had the Ledger's silver pen in her hand all night, turning "
          "it, the way Teodora used to turn her keys. 'It's heavy,' she says. 'Nobody tells "
          "you it's heavy.'",
          "She puts it on the gold chair. Neither of you picks it up. The room has stopped "
          "pretending to talk about anything else.",
          "She puts the pen in her pocket, and pats it.",
          mods={"muted": 1, "steal_every": 4}, reply="celeste"),
        S("c6s08", "Long Distance", "teodora",
          "Get Teodora to stay on the line until the final round.",
          [{"empathy", "exchange"}, {"accountability", "respect"}], {"empathy"}, "gold",
          "The desk phone rings at three in the morning and the night porter, who runs the "
          "desk now, holds the receiver out to you across the ballroom. Long distance. "
          "Teodora, from an airport lounge somewhere it is already tomorrow. 'I have eleven "
          "minutes before boarding,' she says. 'Spend them well.'",
          "She stays on until they call her flight twice. 'Whichever floor you end up on,' "
          "she says, 'I hope you like it. Keep the keys.' The line clicks. The porter "
          "pretends he was not listening.",
          "'They're calling my flight.' The line goes to a long, polite tone.",
          reply="last_night"),
        S("c6s09", "Ines Signs the Page", "ines",
          "Get Ines to open the Ledger to the first page.",
          [{"empathy", "accountability"}, {"precision", "respect"}], {"respect", "warmth"}, "gold",
          "The keeper opens the Ledger at dawn and not before, and it is four in the "
          "morning. Ines is standing by the gold chair in the grey cardigan, which is not "
          "what anyone else is wearing. 'Rules,' she says. 'I keep them. You know that.'",
          "She opens it to the first page. Seven years of CELESTE MARROW, in seven hands. "
          "Below the last one, space. She looks up at you. 'An hour early. Don't make me regret it.'",
          "The Ledger stays closed until dawn, as it should."),
        S("c6s10", "The Tired Queen", "celeste",
          "Get Celeste to admit she wants to lose.",
          [{"empathy", "specific_praise", "riddle"}], {"respect"}, "gold",
          "Four-thirty. The room is tired and Celeste is not; she is lit from inside like a "
          "lamp with the shade off. She has never been better. She has never looked so "
          "much like someone asking to be stopped.",
          "'Yes,' she says. Very quietly. Only you hear it. 'Now make me say it in front of "
          "them. Properly. I won't make it easy.'",
          "'Never,' she says, beautifully, and the room applauds.",
          mods={"hand": 2, "muted": 1}, reply="celeste"),
        S("c6s11", "Before Dawn", "celeste",
          "Keep Celeste talking until the sky turns.",
          [{"riddle", "warmth"}, {"specific_praise", "respect"}], {"direct_request", "empathy"},
          "gold",
          "The last half-hour before the final exchange. Celeste takes you out onto the "
          "Aurel's east balcony, suite nine's, for air. The harbour is black. The cranes are "
          "shapes. 'Tell me something,' she says. 'Anything. Nobody has told me anything in years.'",
          "You tell her something. She tells you something back. The sky goes from black to "
          "the colour of stout. 'All right,' she says. 'Let's go and lose.'",
          "'That's what they all say,' she sighs, and goes back in alone.",
          mods={"steal_every": 3}, reply="celeste"),
        S("c6s12", "FINAL: The Silver Tongue", "celeste",
          "Win the Long Night. Celeste talks over your first line, takes a card every third "
          "turn, and needs both kinds of support. Twelve turns.",
          [{"riddle", "specific_praise", "direct_request"}, {"empathy", "accountability", "exchange"}],
          {"respect", "warmth"}, "gold",
          "Dawn in the ballroom. The whole of after-hours Vell is watching. Celeste stands by "
          "the gold chair with the silver pen and seven years in her face. 'Seven years,' she "
          "says to the room, 'and not one of them could do it without a threat or a bribe or "
          "an order. Let's see.' She smiles at you. She means it. She will not make it easy.",
          "'Yes.' One word, in front of everyone. She hands you the silver pen.",
          "'Eight years,' says Celeste, and the room applauds, and she looks, for one "
          "second, disappointed.",
          mods={"turns": 12, "muted": 1, "steal_every": 3, "support": 2,
                "boss": "The Long Night: twelve turns; she talks over your first card, takes "
                        "your costliest card every third turn, and wants both kinds of support."},
          reply="celeste"),
    ],
}
