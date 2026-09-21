# -*- coding: utf-8 -*-
"""derive_from_parent — build stories_x/*.json as a DERIVATIVE of play/flutter.

The fork is not a rewrite. Every chapter, beat, trigger, choice, option, flag,
affection value and ending in `play/flutter/backend/stories/<route>.json` is
copied through verbatim. This script only *adds*:

  story.adult / static / cast_note_en   the adult frame and the stated ages
  story.cg_heat, chapter.cg, ending.cg  the three state-earned CG hooks
  story.hold_en[]                       lines for turns after a chapter's beats
  beat.text_en                          his spoken line, authored from the
                                        parent's own `inject` stage direction
                                        (the parent had the model say this; a
                                        static route cannot, so it is written
                                        once here instead of per player)
  beat.lane{}                           an authored attachment-lane opener in
                                        front of the kept base line
  + 2 beats per route                   the adult turn, in ch4 and ch5, placed
                                        where the parent's own beats already
                                        build to it
  + 2 options per route                 an explicit decline on each escalation
                                        chapter, which costs no affection
  ending.text_en += coda                one sentence of adult frame appended to
                                        the parent's kept ending prose

Run:  python3 tools/derive_from_parent.py [--report]
"""
import argparse
import json
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
# The Chinese half of everything this file adds. Four routes, not six -- see
# derive_zh's docstring for the measurement that decided which four.
from derive_zh import (ZH_ROUTES, CAST_ZH, FRAME_ZH, HOLD_ZH, LANE_ZH, TEXT_ZH,
                       ADULT_ZH, DECLINE_ZH, CODA_ZH)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PARENT = os.path.join(os.path.dirname(os.path.dirname(ROOT)), "play", "flutter",
                      "backend", "stories")
OUT = os.path.join(ROOT, "backend", "stories_x")

ROUTES = ["ethan", "luxingye", "guyan", "liam", "adrian", "fushen"]

# Everyone depicted is an adult and is stated as one in-scene.
CAST = {
    "ethan": "Ethan Cole, 38. The player character is 29. Both adults.",
    "luxingye": "Lu Xingye, 27. The player character is 26. Both adults.",
    "guyan": "Gu Yan, 33. The player character is 30. Both adults.",
    "liam": "Liam Reyes, 34. The player character is 31. Both adults.",
    "adrian": "Adrian Vale, 31. The player character is 28. Both adults.",
    "fushen": "Fu Shen, 36. The player character is 30. Both adults.",
}

# One sentence appended to chapter 1's kept opening, so the adult frame is
# established in-scene rather than only in metadata.
FRAME = {
    "ethan": "You are twenty-nine; he is thirty-eight, and neither of you is "
             "anywhere you have to be tomorrow.",
    "luxingye": "He is twenty-seven, you are twenty-six, and the only person "
                "waiting up for either of you tonight is the other one.",
    "guyan": "He is thirty-three, you are thirty, and the shop keeps whatever "
             "hours the two of you decide it keeps.",
    "liam": "He is thirty-four, you are thirty-one, and the fence between the "
            "two yards is the only thing either of you answers to.",
    "adrian": "He is thirty-one, you are twenty-eight, and the crew went home "
              "an hour ago.",
    "fushen": "He is thirty-six, you are thirty, and for once there is no one "
              "in this house but the two of you.",
}

HOLD = {
    "ethan": ["He doesn't fill the silence. He lets it sit, and watches what you do with it.",
              "\"Keep going,\" he says. \"I'm not going anywhere tonight.\"",
              "He turns the glass a quarter turn on the table and doesn't drink from it.",
              "\"Say that again,\" he says. \"Slower. I want to be sure I heard it.\""],
    "luxingye": ["He drops his chin onto the back of the chair and grins up at you. \"Go on. I'm listening.\"",
                 "\"You know nobody talks to me like this,\" he says. \"Don't stop on my account.\"",
                 "He plays two notes, stops, and looks at you instead of the strings.",
                 "\"Say more things,\" he says. \"I like your voice better than the room.\""],
    "guyan": ["He nods, slowly, the way he does when he is memorising something.",
              "\"Take your time,\" he says. \"The rain isn't in a hurry either.\"",
              "Dango settles between you, and he takes that as permission to stay quiet a while.",
              "\"I'd like to hear the rest of that,\" he says, and goes pink at his own boldness."],
    "liam": ["He leans back against the tailgate and gives you his whole attention, which is a lot of attention.",
             "\"Keep talking,\" he says. \"I've got nowhere I need to be till six.\"",
             "Biscuit sighs and flops across both your feet, pinning you there.",
             "\"That's the good stuff,\" he says. \"Say the rest of it.\""],
    "adrian": ["He doesn't answer. He watches you, which from him is the same as answering.",
               "\"Don't stop,\" he says, short. \"I'm not bored yet.\"",
               "He mutes the strings with his palm so he can hear you better, and pretends he didn't.",
               "\"Again,\" he says. \"That part. Say it again.\""],
    "fushen": ["He says nothing. The silence is not a wall this time; it is an invitation, and you can tell the difference now.",
               "\"Continue,\" he says. It is the closest he gets to please.",
               "He sets his glass down without a sound and waits.",
               "\"I'm listening,\" he says, and he is — completely, which from him is rare."],
}

# Lane openers. The kept base line follows them unchanged, so the lane costs one
# authored sentence rather than a second script.
LANE = {
    "ethan": {"anxious": "He hears the question under your question, and answers that one first. \"You're not in the way here. Nobody put you here by accident.\" Then, evenly: ",
              "avoidant": "He doesn't crowd you. He gives you the length of the room and starts somewhere it's safe to start. "},
    "luxingye": {"anxious": "\"Hey — hey. Look at me a sec.\" The grin drops, just for a moment. \"You're not a rumour to me. Okay?\" Then he's bright again: ",
                 "avoidant": "He reads the step back and takes one of his own, cheerfully, like it was his idea. \"No pressure. I talk enough for two anyway.\" "},
    "guyan": {"anxious": "He sets the book down and answers the worried thing first, carefully, because he knows that fear. \"You haven't overstayed. I'd say so.\" Then, softer: ",
              "avoidant": "He doesn't reach. He puts the words somewhere between you and lets you pick them up in your own time. "},
    "liam": {"anxious": "\"Whoa, hey.\" He crouches to your eye level, easy as breathing. \"I'm not going anywhere. You can ask me twice, I don't mind.\" Then: ",
             "avoidant": "He gives you room — literally, sliding a foot down the tailgate — and talks to the yard instead of to your face, which makes it easier. "},
    "adrian": {"anxious": "\"Stop.\" It comes out sharper than he means, so he tries again, worse and more honestly. \"You didn't do anything. It's not you.\" Then: ",
               "avoidant": "He recognises the shutters coming down, because they're his. He doesn't push. He just keeps talking at the middle distance. "},
    "fushen": {"anxious": "He answers the unasked question before the asked one, which he does for no one else. \"You are not a guest here.\" Then, in his ordinary flat register: ",
               "avoidant": "He lets the distance stand. He does not take a step, and he does not soften his voice to coax you across. "},
}

# beat.text_en — his line, authored once from the parent's own `inject`.
TEXT = {
 "ethan": {
  "b1_call": "\"That was the chairman,\" he says, and doesn't elaborate. He sets the phone face-down. \"He'll survive until Monday.\" Then he looks at you properly for the first time, the way a man looks at something he has decided to actually see. \"You're still here.\"",
  "b2_blackout": "\"Generators take ninety seconds.\" His voice has dropped without his permission. He moves half a step closer, and offers no reason for it. \"Don't move toward the desk, there's a chair leg. Just — stay where you are. I can hear you breathing, so I know where you are.\"",
  "b3_name": "\"What's your name?\" It arrives out of nowhere, and he seems faintly annoyed at himself for not having asked. When you tell him, he repeats it once, quietly, the way he'd write something on a page he intends to keep. \"All right. Now I know.\"",
  "b1_remember": "\"They keep a case of it downstairs,\" he says, handing it over, which is not an answer and you both know it. He mentioned nothing, ordered nothing, and there it is. \"Don't look at me like that. I have an excellent memory and very few uses for it.\"",
  "b2_why_here": "\"My father worked this building. Night shift, thirty years, that door to that door.\" He still isn't looking at you. \"I bought it eleven years ago. Nobody here knows that, and I'd prefer it stayed that way.\" A beat. \"Your glass is empty. Say something else.\"",
  "b3_interrupt": "\"Leave them on the desk. Goodnight.\" The door closes on a man who has never once seen anyone up here after ten. Ethan doesn't explain you to him, before or after. \"He'll be insufferable about it by Wednesday,\" he says. \"I find I don't mind.\"",
  "b1_umbrella": "\"It's rain,\" he says, as if that settles it, the entire right side of his coat going dark. When you push the umbrella back toward him he pushes it back. \"I'm not being gallant. I'm being efficient. One of us dry is better arithmetic than two of us damp.\"",
  "b2_photo": "He picks it up faster than he needs to. Then, because you saw: \"That's him. That's me, at fifteen.\" A long pause, and he gives you the short version because the short version is all he can carry. \"He worked nights so I wouldn't have to. That's the whole story.\"",
  "b1_accusation": "\"It's my signature and it's the right date.\" No defence, no preamble. Only when you ask him straight does the rest come, flat and complete: \"The bank would have taken his house. I couldn't stop the vote. So I paid his debts for two years through a third party and let him hate me instead. He still does.\"",
  "b2_leave": "He crosses the entire room to you with every lens in the building following, and stops close enough that there is nothing else to call it. \"They'll run this everywhere by morning,\" he says. \"I'd like you to know I did the arithmetic on the stairs, and I walked down them anyway.\"",
  "b1_offer": "\"New York. Three years, running the whole region.\" He turns the glass and doesn't drink. \"I haven't answered them.\" He doesn't say why he hasn't. He looks at you and lets the silence do the asking, because he has never learned to do it himself.",
  "b2_truth": "He turns around at last. \"Everything I've ever taken, I never actually wanted.\" He doesn't soften it, doesn't dress it, doesn't follow it with anything clever. He is simply standing there, out of armour, in the dark of his own building. \"That's the whole sentence. I've never said it out loud before.\"",
 },
 "luxingye": {
  "b1_riceball": "\"Okay. Okay!\" He shoves the rice ball behind his back and lifts his chin like a man with dignity, sauce on his cheek. \"You saw nothing. Nation's top idol, impeccable diet, photographed for magazines.\" A beat. \"...There's a second one in the bag. It's yours if you never speak of this.\"",
  "b2_deal": "\"Tell you what.\" He leans in, bright-eyed, all mischief on the surface. \"Your silence, and I show you a version of me that hasn't been on a single broadcast. Fair trade.\" He says it like a game. He is, quietly, hoping very much that you say yes, and he would deny that under oath.",
  "b3_name": "Someone outside is shouting his name for the third time and he does not move. \"Hang on, hang on — what's yours? I can't have a secret-keeper I can't file under anything.\" You tell him, and he repeats it once, grinning, tasting it. \"Right. Noted. Permanently.\"",
  "b1_song": "\"This bit's mine. I wrote it.\" The melody wanders on under his hands, unhurried. \"Label says it's not commercial. They're probably right, they usually are.\" He's watching your face while pretending not to. \"...You can say if it's bad. People don't, and it makes me insane.\"",
  "b2_cage": "\"Three years since anyone asked if I was tired,\" he says, chin on his knees, light as a shrug. \"They ask if I'm in good form. Different question.\" Then, immediately, because being seen makes his skin itch: \"Anyway — tragic idol backstory, very on-brand, please clap.\"",
  "b3_photo": "He tilts the screen so you can read the trending tag, watching you and not it. \"Late-night secret rendezvous. They'll have me engaged by Thursday.\" A grin that's doing a lot of work. \"This is the part where most people remember an early morning. I'm just saying. In case you were about to.\"",
  "b1_song_for_you": "\"This last one,\" he tells forty thousand people, and it is not forty thousand people he's telling, \"the label said it wasn't commercial enough to put out.\" His hand isn't quite steady on the mic. \"So tonight I'm going to sing it for one person, and they know who they are.\"",
  "b2_confession": "He doesn't bow. The last note is still ringing and he is looking at row seven with the whole arena holding its breath. \"The person in row seven.\" His voice cracks the arena open. \"I don't care how many headlines this makes tomorrow. I like you.\" Then silence. Then a tsunami.",
  "b1_statement": "The statement says it was a stage gimmick. The pen is being held out. He looks at it for a long moment and does not take it. \"They want me to say it was a bit,\" he says, to you, not to them, and very quietly. \"I'm not going to say it was a bit.\"",
  "b2_walk": "He stands up mid-sentence, walks out through the glass door, and crosses to you in front of every executive who has ever owned a piece of him. \"That's it. That's the whole meeting.\" He's shaking slightly and grinning like an idiot. \"Ask me later if it was worth it. I'll say yes.\"",
  "b1_new_song": "\"New one,\" he says, tuning a string. \"It's called Row Seven.\" Forty people go quiet instead of forty thousand, and he prefers it. Every line is you. He sings it straight at you and doesn't perform a single bar of it, which is the most naked he has ever been on a stage.",
  "b2_ask_forever": "He sets the guitar down, steps off the little stage and goes down on one knee on a floor that is definitely sticky. \"I said it to tens of thousands. Now I'm asking something bigger in front of about forty.\" His hands are unsteady. \"I gave up the empire. I'd like to keep you.\"",
 },
 "guyan": {
  "b1_dango": "\"That's — unusual.\" He blinks at the cat winding round your ankle. \"He doesn't do that. He doesn't do that for me, and I feed him.\" When you tease him about being outranked by his own cat, the tips of his ears go faintly pink. \"He has opinions. Apparently he's decided.\"",
  "b2_book": "He slides the book of poems to rest by your hand, as though it simply ended up there. \"This one never sells,\" he says, which is a lie of omission; he has taken it off the shelf every time it nearly did. \"Keep it here for now. If you like it. The third poem is the good one.\"",
  "b3_close": "The clock strikes nine. He glances at the door sign and leaves it exactly as it is. When you point out the time he looks at the window instead of at you. \"The rain hasn't let up,\" he says. \"It would be unkind to send anyone out into that. The shop doesn't mind.\"",
  "b1_tea": "He slides the cup across without a word — osmanthus oolong, which you mentioned once, weeks ago, in passing. When you notice, he busies himself with the pot. \"I had some. Lying around. It was going to go stale.\" The tin is new. He knows you can see that the tin is new.",
  "b2_shop": "\"It was my grandfather's.\" His fingers follow the grain of the counter, an old habit. \"Everyone said sell it when he passed. But I come in in the morning and it's as if he's just gone to the back to make tea.\" Then, gently, closing the door: \"You'd like the poetry shelf. Come.\"",
  "b3_note": "\"Oh — those.\" He reaches for the slip and doesn't quite take it from you. \"I write them for whoever gets there next. It's a foolish habit, I've never explained it to anyone.\" When you read one aloud he studies the floor intently. \"...You weren't supposed to find that one so quickly.\"",
  "b1_umbrella": "\"I'm fine. I'm hardier than I look — it's books that can't take the rain.\" He has tipped the umbrella so far toward you that his own shoulder is a dark soak, and he keeps it there when you push back. \"No, leave it. You'll only make us both wet and then it was for nothing.\"",
  "b2_confess_edge": "\"I'm — not very good at saying these things.\" The rain is loud on the awning and he has run out of sentence. His ears have gone entirely red. If you help him along he doesn't get any braver, only more honest, in pieces: \"It's only — I'd rather you didn't go up yet. That's all it is.\"",
  "b1_letter": "\"They'd clear the debt and then some.\" He states it like a stock figure. \"Every sensible person I know says take it.\" Only when you ask what he wants does it come out at all, quietly: \"I don't want to let it go. That's not an argument. It's just the truth of it.\"",
  "b2_boxes": "He packs in silence because packing looks like deciding. Then his hand stops over the poetry book from the evening you walked in, and stays stopped. \"...I can't put this one in,\" he says, and his voice isn't steady. \"I've tried twice. I keep finding it back on the counter.\"",
  "b1_newline": "He has written a second line under the old one on the flyleaf and he cannot look at you while you read it: *I used to write for someone I wasn't sure would ever come. Now I know — she already has.* \"Don't read it aloud,\" he says, hopelessly. \"Please. Just — read it.\"",
  "b2_ask": "\"That sentence I could never finish.\" He has rehearsed this and it is still unsteady. \"Will you let me finish it today?\" He waits for your yes before he says it, and when he says it there is no flourish at all — only a shy man saying a true thing, once, properly, and meaning every syllable.",
 },
 "liam": {
  "b1_dog": "\"That's Biscuit. My partner.\" He takes the sock off him with an apologetic grin. \"Way more enthusiastic about fetching than firefighting, which is a problem, since that's the job.\" He says *the job* the way other people say *the bus* — no weight on it. \"Station's six blocks that way.\"",
  "b2_fix": "The toolbox is out of the truck before you've finished the sentence about the faucet. \"Five-minute job. Sit down, have a root beer.\" When you thank him he waves it off with the wrench still in his hand. \"Can't have my neighbour's sink haunting me. I'm between shifts, I've got nothing but time till six.\"",
  "b3_call": "The pager goes and his face changes a shade — not dramatic, just *on*. \"Sorry. Call-out with the crew.\" He's three steps away when he turns back. \"Hey — what was your name again? I'd like to know whose faucet I fixed.\" You tell him. He repeats it once, grinning, and goes.",
  "b1_chili": "He hands you the bowl and then very obviously does not watch you eat it. \"It's just chili,\" he says, which is untrue in every way that matters; it's his mother's, and he makes it about twice a year. If you ask about the recipe he rubs the back of his neck. \"...It was my mom's. Yeah.\"",
  "b2_scar": "The sleeve slips and he catches you seeing it. The grin dims one notch and doesn't go out. \"Souvenir of the job. Big fire, three years back.\" A beat, plainly, no performance: \"There was somebody I couldn't get out in time.\" Then he turns the burgers, because that's what there is to do.",
  "b3_dance": "He wipes his hands on his jeans twice, which is one more time than necessary, and holds one out. \"I dance about as smooth as a fire hydrant.\" Biscuit is losing his mind circling you both. \"But it's a good song and you're standing right there, so — wanna give it a shot?\"",
  "b1_watch": "He comes out of the smoke with a man on his back, hands him to the medics, and then walks straight to you and presses the watch into your palm. \"Since the day you left it on my truck.\" He's sooty and hoarse and entirely matter-of-fact about it. \"Put it in my pocket before I went in.\"",
  "b2_shaking": "The street empties and the cup of water in his hand is trembling, just slightly. He sees you see it and doesn't bother with the grin. \"Every time,\" he says. \"Not just tonight. Every single time.\" Then, after a moment, he lets his shoulder come to rest against yours and stays there.",
  "b1_letter": "\"Best shot I've had in ten years. Three states, though.\" He hands you the letter instead of an opinion, and he doesn't put a thumb on the scale. When you ask what *he* wants, he takes a while. \"First time the job isn't the thing I'd most hate to lose. That's new. I'm still getting used to it.\"",
  "b2_biscuit": "Biscuit drops your glove between you and sits, pleased with himself. Liam laughs, ruefully, at the floor. \"Even the dog's got an opinion.\" He turns the glove over in his hands. \"He's been sleeping by your side of the fence for a month. I'm not going to pretend I don't know why.\"",
  "b1_key": "He opens his hand: a new-cut key, and a short leather cord with one corner burned. \"Key's to my place. And this was tied to your watch the night of the fire — I kept it.\" He's nervous and doing a bad job of hiding it. \"Figured I'd give you both at once, when it was time.\"",
  "b2_ask": "He rubs the back of his head and takes a breath. \"I'm no good at big speeches, so, plain: I don't want to be the neighbour who fixes your sink.\" The grin is gone; what's under it is steadier. \"I want to be the guy who comes home to you. That a job you'd give me?\"",
 },
 "adrian": {
  "b1_melody": "His hand kills the strings the second he sees you. \"You didn't hear that.\" It comes out harder than he intends and he doesn't take it back. \"It's not anything. It's not finished, it's not a song, it's not going anywhere.\" A pause, flatter: \"Forget the whole thing. Seriously.\"",
  "b2_notfan": "\"No photo. No signature. Nothing.\" He looks up properly for the first time, sizing you up like a lock he intends to pick. \"Everybody who gets back here wants something. You coiled my cables.\" A beat. \"So either you're playing a longer game than they do, or you actually don't care. I can't tell which yet.\"",
  "b3_name": "\"Hey. Whatever your name is.\" He makes it sound like an afterthought, tosses it over his shoulder, and then ruins it: \"...Actually. What is it?\" You tell him. He doesn't repeat it, doesn't warm up, just files it away behind a look you can't read, and it lands harder than he'd ever admit.",
  "b1_lyrics": "He crosses the bus in one stride and takes the page out of your hand. *she doesn't ask me to be anyone.* \"That's nothing. Scratch work.\" His ears have gone red and he's furious about it. \"It's not about anybody. It's a line. Lines aren't about people, they're about scanning.\"",
  "b2_why_music": "He strums a chord that resolves nowhere. \"Everyone wants the guy on stage.\" Flat, almost a warning. \"Nobody sticks around for the one who can't say a damn thing without a guitar in his hands.\" He doesn't look up to check whether you're still there. He is listening very carefully for whether you are.",
  "b3_jealous": "Two words and you hang up. His fingers stop; the string under his hand is pressed dead flat. \"...Boyfriend?\" Studied indifference, badly built. When you answer he shrugs one shoulder like the whole exchange bored him. \"Didn't ask because I cared. Was just — the timing. Of the call. Whatever.\"",
  "b1_song": "He starts it on one guitar under one light and it's the song off the floor of the bus — *she doesn't ask me to be anyone* — sung now to tens of thousands of people, none of whom know who it's for. He doesn't say. He doesn't have to. His voice goes through the armour on the chorus.",
  "b2_look": "The arena detonates and he ignores all of it. Under the spotlight he lifts his head, past every hand in the front row, finds you, and mouths it silently, for exactly one person: *that one was yours.* Then he stands there in the noise, waiting, deaf to forty thousand people.",
  "b1_contract": "\"They want the line rewritten.\" Cold and short, for the suits' benefit. \"And they want a name attached to the muse, for press.\" He looks at the pen and doesn't touch it. Then, to you, at normal volume, in front of all of them: \"It's the only honest thing I've made. I'm not selling it.\"",
  "b2_walk": "He stands, takes the guitar, and pushes the contract back to the middle of the glass table. \"The song's not for sale. Neither is she.\" No explanation, no goodbye, nothing for the room at all. He is cold the whole length of the table and then he reaches the door and he isn't.",
  "b1_finished": "The song has a last verse now. After the chorus comes a line no one in the world has heard: *and for the first time, I wrote a song I don't wanna keep to myself.* On that line he lifts his eyes off the fretboard and puts them on you and leaves them there.",
  "b2_ask": "He sets the guitar down and comes off the stage with nothing in his hands, which for him is the whole point. \"I spent years hiding it in songs and denying every word. I'm done denying.\" No swagger left anywhere. \"So — plainly. No guitar. I'm yours. Are you mine?\"",
 },
 "fushen": {
  "b1_wine": "He pours a second glass and pushes it to the edge of the table. \"Standing's uncomfortable.\" That is the entire invitation and there will not be a warmer one. When you thank him he looks back out at the city. \"It was going to waste. Don't read anything into it.\"",
  "b2_notice": "\"You're not looking at the apartment, and you're not looking at me.\" It is the first thing he has said with any interest in it. \"You're watching the one streetlight on that corner that never goes off. Why.\" Not a question, in his mouth. It is still, unmistakably, a question.",
  "b3_name": "\"Your name.\" Not phrased as a request; he does not appear to know how. When you give it he doesn't repeat it and doesn't thank you. He simply files it somewhere permanent, and somehow you can tell that he has. \"...Good night. The driver is downstairs. He'll take you.\"",
  "b1_remember": "He waves the champagne tray off before it reaches you and asks for warm water instead — you said once, weeks ago, that you can't really drink. He doesn't mention it. When you notice he's already looking elsewhere. \"The champagne here is mediocre,\" he says. \"You'd have regretted it.\"",
  "b2_rumor": "The murmur carries — *acquired his own brother's company overnight.* His face does not move; only his hand tightens on the glass for a fraction. He offers nothing. If you ask him directly and gently, it comes in as few words as possible: \"The creditors would have taken everything he had. It was faster my way. He doesn't know. Leave it.\"",
  "b3_leave": "The most important man in the room wants ten minutes. Fu Shen glances at his watch, then at you. \"Another day,\" he tells him, and turns back, as though it cost nothing. It cost something. He does not intend for you to be told what.",
  "b1_madam": "You open your mouth to ask about *Young Madam* and he reaches over and straightens the collar the wind has turned up, eyes somewhere past your shoulder. \"It's what they're used to saying. Pay it no mind.\" He does not correct one member of his staff, then or later.",
  "b2_room": "Your flowers. Your books. The bedside lamp at the exact warm temperature you once complained no hotel ever gets right. \"The housekeeper handles the rooms,\" he says, which would be more convincing if the housekeeper had ever met you. \"If anything is wrong with it, say so and it will be changed tonight.\"",
  "b1_cheque": "The cheque slides to rest by your hand. Fu Shen does not speak. The air around him has gone very cold and very still, and still he waits — he will not price you in front of you, or answer for you. Only when you have met it does he turn to his family, quietly: \"Now. My turn.\"",
  "b2_stand": "He stands and pushes the card back across the table to the patriarch. \"This match, I refuse.\" Not loud. The hall goes silent anyway, because nobody in it has ever heard him refuse anything out loud. He moves one step sideways, between you and every elder in the room, and stays there.",
  "b1_offer": "\"The family wants me to take the overseas division. London. Five years, at least.\" He watches the skyline go pale. \"I haven't given them an answer.\" He does not say that yours decides his. He simply stops talking, and waits, and gives away nothing at all.",
  "b2_truth": "He turns and looks at you. \"Nothing I have ever owned was something I actually wanted to keep.\" A pause with nothing in it — no joke coming, no retreat. \"Until you.\" Then he says nothing more and lets it stand there in the open between you, which for him is an act of enormous violence.",
 },
}

# The adult turn. Placed in ch4 and ch5, where the parent's own beats already
# build to it. Consensual, both adults, and the door closes on the scene.
ADULT = {
 "ethan": [
  ("bx_after_hours", "ch4",
   "The car doesn't go to your building. Neither of you says anything about that until the lift doors close on the forty-first floor.",
   "\"I'm going to say this badly.\" He hasn't let go of your hand since the gala floor. \"I have spent eleven years being extremely careful about what I want, and I'd like to stop, tonight, with you, if that's something you also want. Say no and I'll take you home and nothing about tomorrow changes.\" You don't say no. He exhales like a man setting down something heavy, and the last thing you see before the lights go is the city, forty-one floors down, doing its work without either of you."),
  ("bx_morning", "ch5",
   "Six a.m. The top-floor light is off for the first time in eleven years, and he is still asleep.",
   "He wakes up slowly, which you would not have thought he knew how to do. \"Don't,\" he says, when you reach for your phone, and pulls you back under his arm without opening his eyes. \"Nine minutes. The building has survived worse.\" It is the most extravagant thing you have ever watched him spend."),
 ],
 "luxingye": [
  ("bx_after_hours", "ch4",
   "The car is a decoy and the flat is borrowed and nobody on earth knows where either of you is. He locks the door and puts his back against it, laughing, out of breath.",
   "\"Okay. Okay.\" He's grinning and it keeps slipping into something less practised. \"Full disclosure: I've been famous since I was nineteen and I have no idea how to do this part without it being a bit. So tell me if it's too fast, tell me if you want to just eat noodles and sit on the floor, tell me anything —\" You tell him. He stops talking, which almost never happens, and the borrowed flat is very quiet for a long time after that."),
  ("bx_morning", "ch5",
   "Morning. No call time, no car, no manager. He has been awake for an hour and has not once picked up his phone.",
   "\"I worked out what's different,\" he says into your shoulder. \"Nobody's waiting for me to come out and be someone.\" He thinks about it. \"Terrifying. Ten out of ten. I'd like to do it every day for a while and then see.\""),
 ],
 "guyan": [
  ("bx_after_hours", "ch4",
   "The boxes stay unpacked on the shop floor. He turns the sign to Closed for the first time in the whole story, and he is very careful about the lock, because his hands are not steady.",
   "\"I want to say it properly, so I'm going to say it slowly.\" His ears are scarlet and his voice is level, which costs him. \"I would like you to stay tonight. Not because of the shop, or the letter, or any of it. If you'd rather not, we'll make tea and I'll walk you home and I won't be any different tomorrow — I need you to believe that part before you answer.\" You answer. He closes his eyes for a second. Then he takes the poetry book off the counter, and puts it back on the shelf where it has always belonged, and turns off the lamp."),
  ("bx_morning", "ch5",
   "Morning in the reopened shop. Dango has taken the warm patch. The new sign is still crooked.",
   "\"I have been trying for an hour,\" he says, from somewhere near your hair, \"to think of a line for the flyleaf, and everything I come up with is too pleased with itself.\" He gives up happily. \"I'll just write the date. I'll know what it means.\""),
 ],
 "liam": [
  ("bx_after_hours", "ch4",
   "The letter is still on the bench in the garage. The truck goes home instead of to the station, and Biscuit is put out in the yard with a look of profound betrayal.",
   "\"I'm gonna be real clear, 'cause I'd rather be clumsy than wrong.\" He's holding both your hands, which makes him look enormous and about nineteen. \"I'd like you to stay tonight. No part of that's connected to the letter — I'll want this whether I take the job or don't. You can say no and I'll get you a blanket and take the couch and we'll have pancakes and it'll be fine.\" You don't want the couch. \"Yeah,\" he says, quiet, \"okay,\" and the porch light goes off behind him."),
  ("bx_morning", "ch5",
   "Sunrise on the new porch. Two root beers, unopened, from last night. A dog asleep across the doorway like a draught excluder.",
   "\"Didn't set an alarm,\" he says, amazed at himself. \"Ten years, never once.\" He tucks the singed cord back into your hand and closes your fingers on it. \"Keep that. I've had it long enough.\""),
 ],
 "adrian": [
  ("bx_after_hours", "ch4",
   "The lift down from the label takes forty seconds and he doesn't say a word for any of them. Then the street, then a cab, then his door, and the guitar goes in the corner still in its case.",
   "\"I can't do this in a song.\" It comes out rough; he's angry at his own mouth for not being a fretboard. \"So — I want you to stay. That's it, that's the sentence, there's no clever version. If you don't, say so now and I'll walk you down and I won't be weird about it tomorrow.\" A pause, and then the most honest thing he owns: \"I'll be a little weird about it tomorrow. But not at you.\" You stay. He stops talking altogether, which is the only time all night he isn't hiding."),
  ("bx_morning", "ch5",
   "Late morning. The guitar has not come out of its case. He has let it sit there for nine hours, which is a record.",
   "\"I woke up and I didn't want to write anything,\" he says, faintly appalled. \"Just — wanted to be in the room.\" He considers this. \"Don't tell the band. They'll think I'm ill.\""),
 ],
 "fushen": [
  ("bx_after_hours", "ch4",
   "The estate empties. The elders go, the staff are dismissed for the night, and for the first time in its hundred years the house has two people in it and nobody else.",
   "\"I have refused them for you,\" he says, \"and that obliges you to nothing. I want that understood before anything else is.\" He is standing very straight, which is what he does instead of trembling. \"I would like you to stay tonight. If the answer is no it will not cost you one thing — not the room, not the house, not me.\" The answer is not no. Something in his shoulders finally lets go, and he crosses the distance he has been refusing to cross since the first glass of wine, and after that the old house keeps its own counsel."),
  ("bx_morning", "ch5",
   "Dawn on the terrace. No staff. A pot of coffee he made himself, badly.",
   "\"I have never eaten breakfast in this house without an audience,\" he says, and drinks the bad coffee anyway. Then, without any particular ceremony, he moves his chair around to your side of the table. \"This is better. We will do it this way from now on.\""),
 ],
}

# The decline. An escalation chapter must offer a no that keeps the route alive
# and does not dock affection.
DECLINE = {
 "ethan": [("Not tonight — but don't take me home yet.",
            "\"Then we'll stay here,\" he says, and means it entirely. \"I've got a whole city and no plans. Sit down.\""),
           ("Slower than this. I want the whole thing.",
            "\"Slower,\" he agrees. \"I've never been any good at slow. I'd like to find out if I can be.\"")],
 "luxingye": [("Not tonight. Sit on the floor and eat noodles with me.",
               "\"Oh thank God,\" he says, sliding down the door. \"Noodles. I'm so much better at noodles.\""),
              ("Ask me again when the storm's over.",
               "\"Deal.\" He grins, and for once it's the unrehearsed one. \"I'm very good at waiting. I'll be terrible at it. Both things are true.\"")],
 "guyan": [("Make the tea. I'll stay for the tea.",
            "\"Tea,\" he says, visibly relieved to have something to do with his hands. \"Yes. Tea I can manage.\""),
           ("Finish the sentence first. Everything else can wait.",
            "\"...That's fair,\" he says softly. \"That's more than fair. Sit down, then, and let me try again.\"")],
 "liam": [("Take the couch, Reyes. I'll still be here in the morning.",
           "\"Couch it is.\" He's already getting the blanket, grinning. \"Pancakes at seven. Biscuit gets none of them.\""),
          ("Ask me once more when you know what you want to do.",
           "\"That's — yeah. That's the right call.\" He nods slowly. \"I'll know by Friday. I'll ask you Friday.\"")],
 "adrian": [("Not tonight. Play me the rest of it instead.",
             "He looks at the case for a long second. Then he gets the guitar out. \"Fine. But you don't get to laugh at the bridge.\""),
            ("Say it again tomorrow, sober, in daylight.",
             "\"I'll say it every day for a week,\" he says, short. \"You'll get sick of it before I do.\"")],
 "fushen": [("Stay where you are. Just — don't go back behind the glass.",
             "He does not move a step closer. He does not go back either. \"Very well,\" he says. \"I will stay here.\""),
            ("Answer London first. Then ask me.",
             "\"...That is the correct order,\" he says, after a moment. \"I had them the wrong way round. Thank you.\"")],
}

# One sentence of adult frame appended to each kept ending.
CODA = {
 "ethan": "The top-floor light stays off. Two adults, one city, and no meeting behind it.",
 "luxingye": "No call time, no cameras, no one waiting for either of you to be someone else.",
 "guyan": "The shop keeps its own hours now, and so do the two of you.",
 "liam": "Two chairs, one porch, and nobody's shift starting in the morning.",
 "adrian": "The song is finished, the case stays shut, and neither of you is hiding anything.",
 "fushen": "The old house has learned to be quiet for two people instead of none.",
}

# Ethan's route is the one the parent left with `reply_zh` only on its choice
# options. These are translations of the parent's authored replies, not new
# lines — the fork's content pack is English, and _field() would otherwise show
# Chinese to an English player.
REPLY_EN = {
 "ethan": {
  ("ch1", 0): "He laughs under his breath. \"Then I owe the elevator something.\"",
  ("ch1", 1): "Two seconds of silence. Then: \"...Interesting.\"",
  ("ch1", 2): "He raises an eyebrow and pushes the second glass across to you.",
  ("ch2", 0): "He doesn't speak for a long time. Then: \"...Nobody's ever put it that way.\"",
  ("ch2", 1): "\"Control is a luxury good,\" he says. \"I can simply afford it.\"",
  ("ch2", 2): "He laughs — and this time it's a real one.",
  ("ch3", 0): "He nods, and says nothing else at all.",
  ("ch3", 1): "A long silence. Then: \"...I don't know either.\"",
  ("ch3", 2): "He goes completely still. The rain keeps falling. He doesn't move.",
  ("ch4", 0): "\"It's real,\" he says. \"It isn't all of it. Do you want to hear the rest?\"",
  ("ch4", 1): "He glances at the ring of lenses around you and nods. \"...Thank you.\"",
  ("ch4", 2): "Something in his face gives for a second — like a man who hasn't been believed without conditions in a very long time.",
  ("ch5", 0): "He crosses to you, slowly. \"I want a reason to stay in this city.\"",
  ("ch5", 1): "\"I want you,\" he says, very quietly. \"That's the one thing I've stopped doing the arithmetic on.\"",
  ("ch5", 2): "He doesn't move for a long moment. Then a small smile. \"...All right.\"",
 },
}


def derive(route):
    st = json.load(open(os.path.join(PARENT, route + ".json"), encoding="utf-8"))

    st["adult"] = True
    st["static"] = True
    st["derived_from"] = "play/flutter/backend/stories/%s.json" % route
    st["cast_note_en"] = CAST[route]
    st["cg_heat"] = "cg_%s_heat" % route
    st["hold_en"] = HOLD[route]
    zh = route in ZH_ROUTES
    if zh:
        st["cast_note_zh"] = CAST_ZH[route]
        st["hold_zh"] = HOLD_ZH[route]

    chs = st["chapters"]
    for i, ch in enumerate(chs):
        if i == 0:
            ch["opening_en"] = ch["opening_en"].rstrip() + " " + FRAME[route]
            if zh and ch.get("opening_zh"):
                ch["opening_zh"] = ch["opening_zh"].rstrip() + FRAME_ZH[route]
        if ch["id"] == "ch2":
            ch["cg"] = "cg_%s_ch2" % route

        beats = ch["beats"]
        for b in beats:
            b["text_en"] = TEXT[route][b["id"]]
            if zh:
                b["text_zh"] = TEXT_ZH[route][b["id"]]
        # the chapter's last parent beat carries the attachment lanes
        last = beats[-1]
        last["lane_beat"] = True
        last["lane"] = {k: LANE[route][k] + last["text_en"] for k in ("anxious", "avoidant")}
        if zh:
            last["lane_zh"] = {k: LANE_ZH[route][k] + last["text_zh"]
                               for k in ("anxious", "avoidant")}

        for n, o in enumerate(ch["choices"][0]["options"]):
            if not o.get("reply_en"):
                o["reply_en"] = REPLY_EN[route][(ch["id"], n)]

    by_id = {c["id"]: c for c in chs}
    for bid, chid, event, text in ADULT[route]:
        ch = by_id[chid]
        beat = {
            "id": bid,
            "trigger": {"turns": len(ch["beats"]) * 3 + 3, "aff_min": ch["aff_gate"]},
            "added_by_fork": True,
            "event_en": event,
            "text_en": text,
            "heat": 2,
        }
        if zh:
            beat["event_zh"], beat["text_zh"] = ADULT_ZH[route][bid]
        ch["beats"].append(beat)

    for n, chid in enumerate(("ch4", "ch5")):
        text, reply = DECLINE[route][n]
        opt = {
            "text_en": text,
            "aff": 3,
            "flag": "slow_" + chid,
            "reply_en": reply,
            "added_by_fork": True,
        }
        if zh:
            opt["text_zh"], opt["reply_zh"] = DECLINE_ZH[route][n]
        by_id[chid]["choices"][0]["options"].append(opt)

    for e in st["endings"]:
        e["cg"] = "cg_%s_end" % route
        e["text_en"] = e["text_en"].rstrip() + " " + CODA[route]
        if zh and e.get("text_zh"):
            e["text_zh"] = e["text_zh"].rstrip() + CODA_ZH[route]

    return st


def measure(route, forked):
    """The same measurement the correction used: beats, and text overlap."""
    par = json.load(open(os.path.join(PARENT, route + ".json"), encoding="utf-8"))

    def strings(st, only_parent_beats=False):
        out = []
        for ch in st["chapters"]:
            for k in ("title_en", "scene_en", "goal_en", "opening_en"):
                if ch.get(k):
                    out.append(ch[k])
            for b in ch["beats"]:
                if only_parent_beats and b.get("added_by_fork"):
                    continue
                if b.get("event_en"):
                    out.append(b["event_en"])
            for c in ch.get("choices", []):
                for o in c["options"]:
                    if o.get("added_by_fork"):
                        continue
                    out += [o.get("text_en", ""), o.get("reply_en", "")]
        return [s for s in out if s]

    p = strings(par)
    kept = sum(1 for s in p if any(s in f for f in strings(forked)))
    words_kept = sum(len(s.split()) for s in p)
    new = []
    for ch in forked["chapters"]:
        for b in ch["beats"]:
            new.append(b["text_en"])
            if b.get("added_by_fork"):
                new.append(b["event_en"])
        for o in ch["choices"][0]["options"]:
            if o.get("added_by_fork"):
                new += [o["text_en"], o["reply_en"]]
    new += forked["hold_en"]
    words_new = sum(len(s.split()) for s in new)
    return {
        "parent_beats": sum(len(c["beats"]) for c in par["chapters"]),
        "fork_beats": sum(len(c["beats"]) for c in forked["chapters"]),
        "parent_strings": len(p),
        "parent_strings_kept_verbatim": kept,
        "words_kept_from_parent": words_kept,
        "words_written_new": words_new,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", action="store_true")
    a = ap.parse_args()

    os.makedirs(OUT, exist_ok=True)
    rows = []
    for r in ROUTES:
        st = derive(r)
        with open(os.path.join(OUT, r + ".json"), "w", encoding="utf-8") as f:
            json.dump(st, f, ensure_ascii=False, indent=1)
        rows.append((r, measure(r, st)))
    for r, m in rows:
        print(r, json.dumps(m))
    tot = {}
    for _r, m in rows:
        for k, v in m.items():
            tot[k] = tot.get(k, 0) + v
    print("TOTAL", json.dumps(tot))
    if tot["parent_strings_kept_verbatim"] != tot["parent_strings"]:
        raise SystemExit("a parent string was lost — the fork must be additive")


if __name__ == "__main__":
    main()
