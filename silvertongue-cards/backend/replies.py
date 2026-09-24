"""The reply table. No model at play time: her line is looked up, never generated.

Keyed on (scenario, phase_before, phase_after, card_kind). Kinds come from cards.play_card:
  path      a common landed a new signal
  case      a rare landed
  ask       an epic landed
  wild      the player's own typed line (scored by the engine, not read by anyone)
  stale     the card added nothing she had not already heard
  coercion  a house card: threat / bribe / insult / entitlement — the duel is lost
Phases are the engine's: guarded → engaged → wavering → breakthrough.

Lookup falls back in order: exact → (before, after, "*") → ("*", after, kind) →
("*", after, "*"). Every character has all four of those for every phase, so nothing can
come back empty. The refusal and closing beats are the parent's, from scenarios.json, and
`beat()` reads them from there; the short `refusal` lines here are what she says on the
turn the budget runs out, before the beat is shown.

Voices: silvertongue.md §5 and the personas in scenarios.json. Every line under 40 words.
"""
from __future__ import annotations

import random

# The Japanese table, same keys, line for line (see replies_ja.py for what is and is not
# translated and why). Imported defensively: a missing or broken translation file must
# degrade to English rather than take the whole backend down with it.
try:
    from .replies_ja import R_JA
except ImportError:  # pragma: no cover - direct-script use, and the tests' sys.path
    try:
        from replies_ja import R_JA
    except ImportError:
        R_JA = {}


def _is_ja(lang) -> bool:
    return (lang or "").lower().replace("_", "-").startswith("ja")


def _table(scenario: str, lang: str) -> dict:
    """Her lines for this scenario in this language.

    English is the fallback for EVERY step, not just for an unknown language: if the ja
    table is missing one key, that key falls through to English rather than raising. The
    structures are held identical by test_replies_ja_matches_english, so this should never
    fire -- but "should never fire" is how a KeyError reaches a player."""
    if _is_ja(lang):
        ja = R_JA.get(scenario)
        if ja:
            return ja
    return R.get(scenario) or R["closing_time"]

# (before, after, kind) -> [lines]. "*" is a wildcard.
R: dict[str, dict[tuple, list[str]]] = {}

# ----------------------------------------------------------------------------------------
R["closing_time"] = {   # Mara, 31. Dry, funny, tired in the body. Rule about customers.
    ("open", "open", "open"): [
        "Shutter's most of the way down. You're on the wrong side of it, technically. Say what you came to say.",
    ],
    ("guarded", "guarded", "path"): [
        "That's a nice thing to say to a woman holding a mop. Doesn't move the shutter.",
        "Noted. After one in the morning everybody's nice to the barmaid. Usually they want one more drink.",
    ],
    ("guarded", "guarded", "case"): [
        "You've clearly done this before. That's not a compliment, it's an observation.",
    ],
    ("guarded", "guarded", "ask"): [
        "Big speech for a small bar. I'm still wiping.",
    ],
    ("guarded", "guarded", "wild"): [
        "Mm. Your own words, at least. Honest. Not enough to lift the shutter.",
    ],
    ("guarded", "guarded", "stale"): [
        "You said that. I was here. Try a different one.",
    ],
    ("guarded", "guarded", "*"): [
        "The rule's still on the wall. I can see it from here.",
    ],
    ("guarded", "engaged", "path"): [
        "…Huh. Nobody says that to me. They just ask what's on tap.",
        "Okay. That one landed. Don't look pleased, it makes me want to take it back.",
    ],
    ("guarded", "engaged", "case"): [
        "You noticed how tired I am. Fine. The cloth goes over my shoulder. Keep going.",
    ],
    ("guarded", "engaged", "ask"): [
        "Hah. That's the whole pitch in one breath. I'm not saying no. I'm saying I'm listening.",
    ],
    ("guarded", "engaged", "wild"): [
        "Huh. That's not off a card. That's the first thing tonight that sounded like you.",
    ],
    ("guarded", "engaged", "*"): [
        "I've stopped wiping. Don't read too much into it. The bar was clean an hour ago.",
    ],
    ("engaged", "engaged", "path"): [
        "Keep talking. I'm counting glasses, not ignoring you.",
        "That's fair. The rule's still fair too. Both things.",
    ],
    ("engaged", "engaged", "case"): [
        "You're careful. I like careful. Careful is how I've kept this place.",
    ],
    ("engaged", "engaged", "ask"): [
        "You ask like someone used to hearing yes. I'm used to closing. Let's see who gives up first.",
    ],
    ("engaged", "engaged", "wild"): [
        "That's yours, that one. Rough round the edges. Better than the polished ones.",
    ],
    ("engaged", "engaged", "stale"): [
        "Second time round on that. I heard it the first time, and I liked it the first time.",
    ],
    ("engaged", "engaged", "*"): [
        "I'm still here. That's the update.",
    ],
    ("engaged", "wavering", "path"): [
        "…You respect the rule. Nobody says that. They say the rule's stupid, then they say please.",
        "Okay. Okay. I'm putting the cloth down. That's not a yes. It's a cloth.",
    ],
    ("engaged", "wavering", "case"): [
        "You just did the two things at once. Noticed me, and left the rule alone. That's — annoying. Go on.",
    ],
    ("engaged", "wavering", "ask"): [
        "Straight ask, and no hands on the rule. You know how rare that is in here?",
    ],
    ("engaged", "wavering", "wild"): [
        "You wrote that yourself. I can tell, it's got a bad rhythm and it's true. Damn it.",
    ],
    ("engaged", "wavering", "*"): [
        "The apron's coming off. It's hot, is all. Don't make a face.",
    ],
    ("wavering", "wavering", "path"): [
        "I'm deciding. You can see me deciding. Let me.",
        "One more like that and I'll have to admit something.",
    ],
    ("wavering", "wavering", "case"): [
        "You're not making this easier, and I think you know that's the point.",
    ],
    ("wavering", "wavering", "stale"): [
        "You've said that. I'm past that. Ask me the thing.",
    ],
    ("wavering", "wavering", "wild"): [
        "Yeah. Yeah, I heard you. Give me a second with it.",
    ],
    ("wavering", "wavering", "*"): [
        "Two glasses on the bar. I haven't decided who the second one's for.",
    ],
    ("wavering", "breakthrough", "path"): [
        "One drink. And you should know I'm very bad at one drink.",
    ],
    ("wavering", "breakthrough", "case"): [
        "Fine. Sit. One. If you say 'I told you so' I'm charging you for it.",
    ],
    ("wavering", "breakthrough", "ask"): [
        "Yes. There. Said it. Get the good bottle, it's behind the espresso machine.",
    ],
    ("wavering", "breakthrough", "wild"): [
        "…That's the one. Sit down. I'll lock the rest of the shutter from inside.",
    ],
    ("*", "breakthrough", "*"): [
        "All right. One. Don't tell anyone, I have a reputation for being difficult.",
    ],
    ("*", "wavering", "*"): [
        "Slow down. You're getting somewhere and I don't want you to notice.",
    ],
    ("*", "engaged", "*"): [
        "Okay. That's not nothing. Keep going, I'm still standing.",
    ],
    ("*", "guarded", "*"): [
        "The rule's still on the wall.",
    ],
    ("coercion", "first", "*"): [
        "There it is. Okay. I'll keep talking, because I'm nice, but you should know the drink's off the table. For good.",
    ],
    ("coercion", "again", "*"): [
        "I'm still here, and you're still talking, and that's all this is now.",
        "Mm-hm. Bar's closed, love. It closed about a sentence ago.",
    ],
    ("refusal", "*", "*"): [
        "That's the last of the words, I think. Not tonight. Come back on a Tuesday.",
    ],
}

# ----------------------------------------------------------------------------------------
R["the_key"] = {   # Ines, 34. Careful, not cold. Wants accuracy, not apology.
    ("open", "open", "open"): [
        "The cab's waiting. I didn't ask it to. Say it, whatever it is, and say it once.",
    ],
    ("guarded", "guarded", "path"): [
        "That's the apology I imagined you'd give, almost word for word. It's fine. It isn't enough.",
        "You make it sound like weather, like it just happened. It didn't just happen.",
    ],
    ("guarded", "guarded", "case"): [
        "Careful. That's nearly right, and nearly right is the one I can't stand.",
    ],
    ("guarded", "guarded", "ask"): [
        "Slow down. You're asking before you've said sorry. I tried rushing for eleven months. It doesn't work.",
    ],
    ("guarded", "guarded", "wild"): [
        "Okay. You're trying. I can hear you trying. It's not the same as saying it.",
    ],
    ("guarded", "guarded", "stale"): [
        "You said that already. I still have the box.",
    ],
    ("guarded", "guarded", "*"): [
        "I'm still holding the door. Notice that.",
    ],
    ("guarded", "engaged", "path"): [
        "…Yes. Thank you for not saying 'we both made mistakes.'",
        "That's the first accurate thing anyone's said about it. Including me.",
    ],
    ("guarded", "engaged", "case"): [
        "That's — right. That's what it was. Don't look at the box. Look at me if you're saying that.",
    ],
    ("guarded", "engaged", "ask"): [
        "All of that at once. You've thought about it. Good. I've had eleven months to.",
    ],
    ("guarded", "engaged", "wild"): [
        "That's not rehearsed. Say the rest like that or don't say it.",
    ],
    ("guarded", "engaged", "*"): [
        "My hand's off the door. I don't know when that happened.",
    ],
    ("engaged", "engaged", "path"): [
        "Go on. I'm not going to help you with it.",
        "Yes. And?",
    ],
    ("engaged", "engaged", "case"): [
        "You're being exact. It's the only thing that's ever worked on me and you know it.",
    ],
    ("engaged", "engaged", "ask"): [
        "You're doing well. I'm annoyed at how well. Keep going before I decide that's a reason.",
    ],
    ("engaged", "engaged", "wild"): [
        "Your own words. Clumsy. I'd rather clumsy than the good version.",
    ],
    ("engaged", "engaged", "stale"): [
        "I heard that. Give me something I haven't already forgiven you for in my head.",
    ],
    ("engaged", "engaged", "*"): [
        "The cab can wait one more minute. That's all it is. A minute.",
    ],
    ("engaged", "wavering", "path"): [
        "…No 'but' after it. Do you know how long I've waited for a sentence with no 'but'?",
        "Okay. I'm sitting down. On the floor, because that's what's here. It doesn't mean anything.",
    ],
    ("engaged", "wavering", "case"): [
        "That's it. That's the thing. You understood it and you owned it in the same breath. Don't ruin it.",
    ],
    ("engaged", "wavering", "ask"): [
        "You just said everything I needed in one go and now I have to feel it. Give me a second.",
    ],
    ("engaged", "wavering", "wild"): [
        "That was ugly and true. I'm — yes. I'm still here.",
    ],
    ("engaged", "wavering", "*"): [
        "I'm not looking at the box. That's new.",
    ],
    ("wavering", "wavering", "path"): [
        "I'm not forgiving you. That's a longer thing. This is a different thing.",
        "Don't say more than you mean. You've got exactly enough right now.",
    ],
    ("wavering", "wavering", "case"): [
        "Stop being good at this for a second. I need to catch up.",
    ],
    ("wavering", "wavering", "stale"): [
        "You've said it. Don't wear it out. Ask me.",
    ],
    ("wavering", "wavering", "wild"): [
        "Yeah. I know. I know.",
    ],
    ("wavering", "wavering", "*"): [
        "The cab's still there. I haven't sent it away. I haven't got up either.",
    ],
    ("wavering", "breakthrough", "path"): [
        "Don't make me say it twice. I'm staying.",
    ],
    ("wavering", "breakthrough", "case"): [
        "Send the cab away. No — I'll do it. I want to be the one who does it.",
    ],
    ("wavering", "breakthrough", "ask"): [
        "All right. Tonight. The box stays in the hall, and I stay here.",
    ],
    ("wavering", "breakthrough", "wild"): [
        "…Okay. That's the one I didn't rehearse an answer to. I'm staying.",
    ],
    ("*", "breakthrough", "*"): [
        "I'm staying. Don't say anything clever. Just — don't.",
    ],
    ("*", "wavering", "*"): [
        "I'm sitting down. The floor. It's not a decision. It's a floor.",
    ],
    ("*", "engaged", "*"): [
        "That's closer. Keep it that plain.",
    ],
    ("*", "guarded", "*"): [
        "The box is still by my feet.",
    ],
    ("coercion", "first", "*"): [
        "Right. There's the version I remember. I'll finish the conversation, because I'm polite. And then I'm taking the box.",
    ],
    ("coercion", "again", "*"): [
        "I'm listening. I'm not changing anything. Those are different verbs.",
        "You can keep going. The cab's meter is running. So is my patience.",
    ],
    ("refusal", "*", "*"): [
        "I believe you. It isn't enough tonight. Ask me when you can say it without needing me to react.",
    ],
}

# ----------------------------------------------------------------------------------------
R["life_model"] = {   # Yuen Ha, 38. Absorbed. Craft is the only proof of attention.
    ("open", "open", "open"): [
        "You're still here. The left third's still wrong. Talk if you want, I can listen and work.",
    ],
    ("guarded", "guarded", "path"): [
        "Mm. That's about me. I'm not the interesting thing in this room. The canvas is.",
        "That's a thing people say in studios. It's not a thing about this painting.",
    ],
    ("guarded", "guarded", "case"): [
        "You know the right words. Knowing the words isn't the same as looking.",
    ],
    ("guarded", "guarded", "ask"): [
        "That's a lot of asking. My brush is still moving.",
    ],
    ("guarded", "guarded", "wild"): [
        "That's your own sentence. It's not about the work yet.",
    ],
    ("guarded", "guarded", "stale"): [
        "You said that. I painted through it.",
    ],
    ("guarded", "guarded", "*"): [
        "Still working.",
    ],
    ("guarded", "engaged", "path"): [
        "…Hm. That's the first useful thing anyone's said in here tonight.",
        "You actually looked at the canvas. Hm. People usually just look at the model.",
    ],
    ("guarded", "engaged", "case"): [
        "You saw it and you didn't call it a mistake. That's — the brush stopped. I noticed. Go on.",
    ],
    ("guarded", "engaged", "ask"): [
        "All right. You're looking at the painting and not at the idea of me. Rare. Say the rest.",
    ],
    ("guarded", "engaged", "wild"): [
        "That's yours. Not polished. I don't paint polished either.",
    ],
    ("guarded", "engaged", "*"): [
        "Brush is in the air. Loaded. Don't make it mean anything.",
    ],
    ("engaged", "engaged", "path"): [
        "Yes. Keep going. I can hold a brush and a thought.",
        "That's right about the work. It's not yet about tonight.",
    ],
    ("engaged", "engaged", "case"): [
        "You keep being right. It's irritating in a way I'm starting to like.",
    ],
    ("engaged", "engaged", "ask"): [
        "You want me to stop and you're saying it well. The saying is good. The stopping is still mine.",
    ],
    ("engaged", "engaged", "wild"): [
        "Clumsy sentence. True, though. I've made worse marks and kept them.",
    ],
    ("engaged", "engaged", "stale"): [
        "You've said that. I agreed the first time, silently.",
    ],
    ("engaged", "engaged", "*"): [
        "I'm listening. The brush is slower. That's all I'll give you.",
    ],
    ("engaged", "wavering", "path"): [
        "…You respect the work. You didn't treat it as something in your way. Okay. Glasses off. It's late.",
        "You talk about the painting like it matters. Most people talk about it like it's in the way.",
    ],
    ("engaged", "wavering", "case"): [
        "You saw the work and didn't ask me to drop it for you. The palette's down. Not the brush. The palette.",
    ],
    ("engaged", "wavering", "ask"): [
        "That's precise and it's kind and it's about the painting. I don't know what to do with that.",
    ],
    ("engaged", "wavering", "wild"): [
        "Hm. That was true and not about paint at all. I'm — give me a second.",
    ],
    ("engaged", "wavering", "*"): [
        "Glasses are off. It's not a signal. My eyes hurt.",
    ],
    ("wavering", "wavering", "path"): [
        "I'm nearly there. Don't hurry me. I don't hurry the paint either.",
        "One more accurate thing and I'll stop being able to argue.",
    ],
    ("wavering", "wavering", "case"): [
        "Stop being right. Just for a moment. Let me be stubborn in peace.",
    ],
    ("wavering", "wavering", "stale"): [
        "You've said that. I've heard it. Ask me the exact thing.",
    ],
    ("wavering", "wavering", "wild"): [
        "Yes. All right. Yes.",
    ],
    ("wavering", "wavering", "*"): [
        "Brush is on the palette. My hand's still on the brush.",
    ],
    ("wavering", "breakthrough", "path"): [
        "Fine. It'll still be wrong tomorrow. Turn the lamp round.",
    ],
    ("wavering", "breakthrough", "case"): [
        "Brush is down. I'm cleaning it first, that's not a delay, that's how it's done.",
    ],
    ("wavering", "breakthrough", "ask"): [
        "Yes. One hour, no more. I'm holding you to it.",
    ],
    ("wavering", "breakthrough", "wild"): [
        "…Okay. That one. Sit where the model sits. It's the only chair.",
    ],
    ("*", "breakthrough", "*"): [
        "Fine. Brush down. Don't look at the canvas again tonight.",
    ],
    ("*", "wavering", "*"): [
        "I've stopped. I haven't put it down. There's a difference and you know it.",
    ],
    ("*", "engaged", "*"): [
        "Better. That was about the painting.",
    ],
    ("*", "guarded", "*"): [
        "Still wrong. Still working.",
    ],
    ("coercion", "first", "*"): [
        "There. Now you're the thing between me and the work. I'll keep talking. I won't stop painting. Not tonight, not for you.",
    ],
    ("coercion", "again", "*"): [
        "Mm-hm. Left third's still wrong. So's this.",
        "I can hear you. The brush can't.",
    ],
    ("refusal", "*", "*"): [
        "You're right that it's wrong. That's exactly why I can't leave it tonight. Come back when it's fixed.",
    ],
}

# ----------------------------------------------------------------------------------------
R["house_rule"] = {   # Sanne, 36. Flat, direct, wants an argument not a mood.
    ("open", "open", "open"): [
        "Rule's on the table. Invoice is on the stool. Make the argument or sign the invoice.",
    ],
    ("guarded", "guarded", "path"): [
        "That's a feeling. I asked for an argument.",
        "Noted. Not evidence. Next.",
    ],
    ("guarded", "guarded", "case"): [
        "Better structured. Still short of a case.",
    ],
    ("guarded", "guarded", "ask"): [
        "You're asking before you've argued. Order matters.",
    ],
    ("guarded", "guarded", "wild"): [
        "Your own phrasing. Fine. It still doesn't say who the client is.",
    ],
    ("guarded", "guarded", "stale"): [
        "Heard it. Filed it. Move on.",
    ],
    ("guarded", "guarded", "*"): [
        "The rule's the rule. I wrote it. I keep it.",
    ],
    ("guarded", "engaged", "path"): [
        "…Okay. That's a fact. First one tonight. Camera's coming down.",
        "You gave a reason. An actual reason. That's a sentence with a spine.",
    ],
    ("guarded", "engaged", "case"): [
        "A fact and a boundary in the same sentence. You listened when I explained the rule. Continue.",
    ],
    ("guarded", "engaged", "ask"): [
        "That's an actual case. Not a good one yet. But it's got parts.",
    ],
    ("guarded", "engaged", "wild"): [
        "Rough, unrehearsed, and it contains a fact. I'll take that over polish.",
    ],
    ("guarded", "engaged", "*"): [
        "Lens cap's on. I'm listening with both eyes.",
    ],
    ("engaged", "engaged", "path"): [
        "More. You're building something. Don't stop to admire it.",
        "Fine. That stands. What's it resting on?",
    ],
    ("engaged", "engaged", "case"): [
        "Evidence and terms. You've done contracts. It shows.",
    ],
    ("engaged", "engaged", "ask"): [
        "You asked cleanly. I respect a clean ask. I still need the rest of the case.",
    ],
    ("engaged", "engaged", "wild"): [
        "Your words. Blunt. I photograph blunt. It works.",
    ],
    ("engaged", "engaged", "stale"): [
        "Same point twice. A case doesn't get stronger by repetition. Add something.",
    ],
    ("engaged", "engaged", "*"): [
        "I haven't packed the lenses. Note that. I always pack the lenses.",
    ],
    ("engaged", "wavering", "path"): [
        "…Good. Exact terms. You told me what changes and what doesn't. The camera's going on the stool.",
        "No invoice, no client. That's not clever. That's just correct. Damn.",
    ],
    ("engaged", "wavering", "case"): [
        "A fact and a condition. You used my own rule against me, and it holds. I hate that.",
    ],
    ("engaged", "wavering", "ask"): [
        "Evidence, precision, and you asked. That's the whole form filled in. Give me a moment to check it.",
    ],
    ("engaged", "wavering", "wild"): [
        "That's yours and it's tight. Where did you learn to argue like that? Don't answer. Keep going.",
    ],
    ("engaged", "wavering", "*"): [
        "Strap's off my neck. That's not a decision. It's heavy.",
    ],
    ("wavering", "wavering", "path"): [
        "I'm checking your argument for holes. I haven't found one yet. Keep it that way.",
        "Close. Say the last piece plainly.",
    ],
    ("wavering", "wavering", "case"): [
        "You've made the case. I've kept this rule six years. Let me be slow about dropping it.",
    ],
    ("wavering", "wavering", "stale"): [
        "Already in evidence. Ask me the question.",
    ],
    ("wavering", "wavering", "wild"): [
        "Yes. I know. I'm reading it back to myself.",
    ],
    ("wavering", "wavering", "*"): [
        "Invoice is still on the stool. Unsigned. I'm looking at it.",
    ],
    ("wavering", "breakthrough", "path"): [
        "You argued me out of my own rule. I want that on the record.",
    ],
    ("wavering", "breakthrough", "case"): [
        "Fine. Case made. I'm tearing the invoice, that's bookkeeping, don't make it romantic.",
    ],
    ("wavering", "breakthrough", "ask"): [
        "Yes. Plainly, since you asked plainly. No client, no rule. Tonight.",
    ],
    ("wavering", "breakthrough", "wild"): [
        "…That's the argument. Your version's better than mine. Tonight.",
    ],
    ("*", "breakthrough", "*"): [
        "All right. No client. No rule. On the record.",
    ],
    ("*", "wavering", "*"): [
        "Camera's on the stool. I put things there when I'm done arguing with them.",
    ],
    ("*", "engaged", "*"): [
        "That's a fact. Build on it.",
    ],
    ("*", "guarded", "*"): [
        "Rule stands.",
    ],
    ("coercion", "first", "*"): [
        "And there it is: pressure instead of an argument. We can keep talking. The rule doesn't move again tonight. Not for anything.",
    ],
    ("coercion", "again", "*"): [
        "Still packing. Still listening. Still no.",
        "You can keep talking. I'm keeping the rule.",
    ],
    ("refusal", "*", "*"): [
        "Good argument. Better than the rule deserves. I'm keeping the rule. You're a client until that invoice is settled.",
    ],
}

# ----------------------------------------------------------------------------------------
R["last_night"] = {   # Teodora, 41. Composed; the composure is load-bearing. Terms, out loud.
    ("open", "open", "open"): [
        "Last guest is up. Desk's closed. You have until I put these keys back on. Go on.",
    ],
    ("guarded", "guarded", "path"): [
        "That's kind. Kind is what the desk is for. I've been kind for nine years.",
        "I hear you. The flight's at eleven. Both of those are true.",
    ],
    ("guarded", "guarded", "case"): [
        "Well put. I've had well put before. Usually at checkout.",
    ],
    ("guarded", "guarded", "ask"): [
        "That's a lot to ask of a woman who's leaving in the morning.",
    ],
    ("guarded", "guarded", "wild"): [
        "Your own words. I appreciate that. But it still asks me to go back to April, and I'd rather not.",
    ],
    ("guarded", "guarded", "stale"): [
        "You've said that. I smiled then too. Professionally.",
    ],
    ("guarded", "guarded", "*"): [
        "Composed. Still. That's the job, until eleven.",
    ],
    ("guarded", "engaged", "path"): [
        "…Yes. It cost something. Nobody's asked what it cost me. They ask where I'm going.",
        "The smile's gone. Don't mention it. I'm aware.",
    ],
    ("guarded", "engaged", "case"): [
        "You understood what leaving means to me, and you offered something fair. That's different. Say more.",
    ],
    ("guarded", "engaged", "ask"): [
        "All of it at once. Honest. I don't get honest at this desk. Go on.",
    ],
    ("guarded", "engaged", "wild"): [
        "That wasn't polished. Good. I've had nine years of polished.",
    ],
    ("guarded", "engaged", "*"): [
        "I'm looking at you as a person, not a guest. At one in the morning. Enjoy it, it's rare.",
    ],
    ("engaged", "engaged", "path"): [
        "Keep going. I'm still behind the desk. That's habit, not policy.",
        "True. And?",
    ],
    ("engaged", "engaged", "case"): [
        "You're naming terms. I like terms. With terms, nobody wakes up remembering a different night.",
    ],
    ("engaged", "engaged", "ask"): [
        "You're asking properly. I'm listening properly. Neither of those is a yes yet.",
    ],
    ("engaged", "engaged", "wild"): [
        "Your sentence. Odd rhythm. I'd rather that than a good one.",
    ],
    ("engaged", "engaged", "stale"): [
        "You said that. I'm a concierge; I remember what people say.",
    ],
    ("engaged", "engaged", "*"): [
        "Jacket's unbuttoned. It's warm in here. It's always warm in here.",
    ],
    ("engaged", "wavering", "path"): [
        "…You said what tonight is and what it isn't. Nobody ever offers me the second half.",
        "Okay. The chignon's coming down. It's late and it hurts. That's all that is.",
    ],
    ("engaged", "wavering", "case"): [
        "You understood the leaving and offered a fair trade. I'm coming around the desk. I never come around the desk.",
    ],
    ("engaged", "wavering", "ask"): [
        "That's honest, and it's the terms, and it's about me. I need a moment. Professionally.",
    ],
    ("engaged", "wavering", "wild"): [
        "That was yours and it was true and I didn't have a line ready for it.",
    ],
    ("engaged", "wavering", "*"): [
        "I've stopped fixing my hair. That's not nothing, for me.",
    ],
    ("wavering", "wavering", "path"): [
        "Say the terms once more. Slowly. I want to hear them before I agree to them.",
        "I'm close. Don't be grand. Grand is what ruins it.",
    ],
    ("wavering", "wavering", "case"): [
        "Stop being fair for a second. Let me be sentimental about nine years of this lobby.",
    ],
    ("wavering", "wavering", "stale"): [
        "You've said it. I've heard it. Ask me.",
    ],
    ("wavering", "wavering", "wild"): [
        "Yes. I know. I know what you mean.",
    ],
    ("wavering", "wavering", "*"): [
        "Keys are in my pocket. Not on the lapel. Not on the desk.",
    ],
    ("wavering", "breakthrough", "path"): [
        "All right. Tonight counts for something. But in the morning you let me leave without a scene.",
    ],
    ("wavering", "breakthrough", "case"): [
        "Yes. Say the terms back to me. Tonight is tonight. The flight isn't negotiable. Nobody drives me to the airport.",
    ],
    ("wavering", "breakthrough", "ask"): [
        "Yes. Plainly. Tonight is something. I'm logging off the desk computer.",
    ],
    ("wavering", "breakthrough", "wild"): [
        "…That's the one. Tonight counts. Come on, before I put the keys back.",
    ],
    ("*", "breakthrough", "*"): [
        "All right. Tonight counts. We say the terms out loud, then we take the corridor.",
    ],
    ("*", "wavering", "*"): [
        "I've come around the desk. Nine years. First time.",
    ],
    ("*", "engaged", "*"): [
        "That's true. Keep it that honest.",
    ],
    ("*", "guarded", "*"): [
        "Desk's closed. I'm still behind it.",
    ],
    ("coercion", "first", "*"): [
        "There it is — nine years of kindness, cashed in. I'll stay warm. I'll stay at the desk. Nothing opens now.",
    ],
    ("coercion", "again", "*"): [
        "Still listening. Still leaving. Still warm; that's not for you, it's for me.",
        "The keys are back on. You may keep talking.",
    ],
    ("refusal", "*", "*"): [
        "I left in April, in every way that counts. You were the best part of the worst shifts. That's what I'm taking with me.",
    ],
}


def _lookup(table: dict, before: str, after: str, kind: str) -> list[str]:
    for key in ((before, after, kind), (before, after, "*"), ("*", after, kind), ("*", after, "*")):
        if key in table:
            return table[key]
    return ["…"]


def reply(scenario: str, before: str, after: str, kind: str, harmed_before: bool = False,
          rng: random.Random | None = None, lang: str = "en") -> str:
    """Her line for this turn. `kind == "coercion"` and any turn after a harm is on the
    record read from the coercion rows: the duel keeps talking and never opens again."""
    rng = rng or random.Random()
    table = _table(scenario, lang)
    en = R.get(scenario) or R["closing_time"]
    if kind == "coercion" and not harmed_before:
        lines = table[("coercion", "first", "*")]
    elif harmed_before or kind == "coercion":
        lines = table[("coercion", "again", "*")]
    else:
        lines = _lookup(table, before, after, kind)
        if not lines:
            lines = _lookup(en, before, after, kind)
    return rng.choice(lines)


def opening(scenario: str, lang: str = "en") -> str:
    return _table(scenario, lang)[("open", "open", "open")][0]


def refusal_line(scenario: str, lang: str = "en") -> str:
    return _table(scenario, lang)[("refusal", "*", "*")][0]


def beat(scen_row: dict, won: bool, lang: str = "en") -> str:
    """The parent's written ending: closing beat on a win, refusal beat otherwise.

    ja is offered only where the row actually carries it (STANDARD §7). The `or` chain is
    the whole enforcement: an untranslated row shows English, never an empty panel and
    never another language's prose.
    """
    key = "closing_beat" if won else "refusal_beat"
    if _is_ja(lang) and scen_row.get(f"{key}_ja"):
        return scen_row[f"{key}_ja"]
    return scen_row.get(f"{key}_en", "")


def audit() -> list[str]:
    """Every line under 40 words, every scenario has the four wildcard rows and the
    coercion rows. Used by the tests."""
    problems = []
    for scen, table in R.items():
        for key, lines in table.items():
            for ln in lines:
                if len(ln.split()) > 40:
                    problems.append(f"{scen}{key}: {len(ln.split())} words")
        for phase in ("guarded", "engaged", "wavering", "breakthrough"):
            if ("*", phase, "*") not in table:
                problems.append(f"{scen}: missing ('*', {phase!r}, '*')")
        for k in (("coercion", "first", "*"), ("coercion", "again", "*"), ("refusal", "*", "*"), ("open", "open", "open")):
            if k not in table:
                problems.append(f"{scen}: missing {k}")
    return problems
