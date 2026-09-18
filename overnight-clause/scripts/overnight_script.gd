extends RefCounted
class_name OvernightScript

## Overnight Clause — the new writing for the adult fork of Flat 404.
##
## English master only. The base game ships five locales (story_zh/ja/ko/es); carrying
## 5,600 new words through all five is what turns a three-week fork into a three-month
## one, so they are deleted in this project rather than half-maintained.
##
## Page format is the base game's: "\n---\n" starts a new page, "SPEAKER: " at the head
## of a line paints a nameplate (see VnChrome.parse_text).
##
## THE ONE RULE THIS FILE ENFORCES, everywhere, without exception:
## Iris Vale is a voice, a name, and — once — a silhouette behind plastic. She is never
## a body in this fork. The source's horror is a woman being erased and denied a name;
## putting her in an adult scene lands next to the non-consent line the brief rules out
## and destroys the best idea the game has. The adult content lives with two living
## adults who can say yes and do: Mara Venn (33) and Dane Orlov (34).
##
## The clause is the thematic twin of the sex. Pell wants a signature that transfers
## custodianship of a body. Dane offers the inverse transaction and says so out loud:
## nothing owed, nothing recorded.

# ---------------------------------------------------------------------------
# Chapter 2 — the 403 door opens. Dane stops being a voice under a door.
# ---------------------------------------------------------------------------
const CH2_DANE := """The chain on 403 moves, and then does something no chain in this building has done tonight: it comes off.

The door opens the width of a man. He is tall, dark-skinned, dreadlocks tied back off a face that has not slept properly in two weeks, and he is holding the floor slip you were supposed to find under the door.
---
DANE: You're the inspector.

MARA: Mara Venn. Freelance. I'm certifying 404.

DANE: You're certifying 404. Say it again and listen to it.
---
He does not hand the note over immediately. He looks past you at the corridor, both directions, the way people look when the corridor is the thing they are afraid of rather than the person standing in it.

DANE: Dane Orlov. 403. Eleven months next to Iris Vale, who did not surrender that flat, whatever the notice on it says.
---
MARA: The notice says contents abandoned.

DANE: Her shoes are aligned by the door. People who abandon a flat don't align their shoes on the way out.

MARA: You've been inside.

DANE: I've been inside from this side of the wall. There's a difference and Pell will make you sign about it.
---
He puts the slip in your hand rather than under the door, and there is a half-second where he is aware of that, and so are you: it is the first time all night that anything in Vesper Court has been handed over instead of processed.

MARA: Why not just call the housing authority?

DANE: Did that. Twice. The ticket closes itself. The third time, the operator asked me to confirm my address and told me 403 had been vacant for six months.
---
DANE: So no. I wait for somebody with a clipboard to knock instead of sign.

MARA: That's a long wait for a stranger.

DANE: You're not the first. You're the third. The first one signed. The second one — Harrow — signed at 02:23 and stopped existing in a way his employer has paperwork for.
---
MARA: You understand how that sounds.

DANE: I do. I've had two weeks to hear how it sounds. I'd rather sound like this than be polite and quiet while they do it again.

He stops. Something in his jaw gives, briefly, and he sounds tired instead of urgent.
---
DANE: If the pipe knocks three times, answer three times. Not two. Two is the building answering itself.

MARA: And if I answer three?

DANE: Then it's a conversation, and I can get to you through the service hatch before Pell gets to the corridor.
---
MARA: Get to me.

DANE: Reach you. Be in the room. Choose your word, I'm not going to argue about the word at two in the morning.

He almost smiles. It does not reach anything. He steps back into 403 and does not close the door all the way.
---
DANE: Venn. Whatever you find in there — it doesn't need rescuing. It needs a witness. Those are not the same job.

MARA: You've thought about this.

DANE: I've thought about nothing else. Knock on this door when you know something. I'll be awake. I'm always awake.
---
MARA'S FIELD NOTE: He gave a legal name, a duration of residence, a direct observation, and a prediction I can falsify. He also gave me a way to reach him, which no one involved in a coverup has ever done for an inspector. Log him as a witness, not a hazard."""

# ---------------------------------------------------------------------------
# Chapter 3 — the leak soaks her; the mirror. Plate cg_mirror. Free everywhere:
# it is the tone-setter and the store screenshot.
# ---------------------------------------------------------------------------
const CH3_MIRROR := """The wet line behind the wallpaper is not a stain any more. When you pull the loose edge, the wall lets go of two litres of standing water it has been holding at shoulder height, and it takes all of it out on your shirt.

MARA: — of course. Of course it did.
---
Cold, copper-smelling, and already through to the skin. The flat is nineteen degrees according to a thermostat that has been lying all night. You are not finishing an inspection in this.

The bathroom door is open. Your kit bag has the spare shirt in it, because a decade of move-out inspections teaches you exactly one useful thing about buildings, which is that they leak.
---
The bathroom light is the green fluorescent kind that makes everyone look like evidence. You put the ruined shirt over the rail, and the room registers, quietly, that you are in a stranger's flat with your arms out of your sleeves and the front door unlocked behind you.

MARA: Two minutes. Dry, dressed, back to the wall.
---
The mirror is cracked from the top corner, an old crack, painted around rather than replaced. Your reflection arrives a half-beat after you do.

Bare shoulders. Freckles the way her file photo will never show them. Hair out of its band and wet through, hanging in strands you push off your neck with the back of your wrist.
---
You look at yourself the way you look at a wall you are about to photograph: for damage, for dates, for what somebody would like removed from the record.

MARA: Thirty-three. Freelance. One scar through an eyebrow from a landlord's stair rail in 2019, which he called tenant misuse.
---
The reflection blinks late. In the mirror, the bathroom door is closed.

Behind you, it is open. You do not turn around, because turning around is what the building wants and because your shirt is on the rail.
---
MARA: I see you. I'm not going to scream about it.

Condensation crawls up the glass from the bottom edge, unhurried, the way breath does. Four letters surface at the height of a mouth, the wrong way round, and then correct themselves.

IRIS: COLD IN HERE
---
MARA: It is. Your kitchen wall has a hole in it and your landlord ordered the plasterboard six days before the leak.

The glass fogs once more and clears. The reflected door opens by exactly the width of a man, which is what the corridor door of 403 did an hour ago.
---
You pull the dry shirt on. The green light gets worse, then settles.

MARA'S FIELD NOTE: The reflection preserves what I try to discard — the deleted photograph, the closed door, the shoulder I did not show anyone. Denial changes what the report can prove, not what happened. Whatever is in this flat archives the version I edited out.
---
MARA: Iris. If you can do letters, you can do a name.

The mirror does nothing for four seconds. Then, very small, at the bottom edge where a hand would rest:

IRIS: DON'T SIGN
---
MARA: I'd already decided that. But thank you for the second opinion.

You button the dry shirt to the throat, because the flat is nineteen degrees and because there is a difference between being seen by a woman in a mirror and being seen by whatever else is in the walls of Vesper Court tonight, and you would like to keep that difference.
---
On the way out you take the wet shirt off the rail, wring it into the basin, and watch what comes out of it: not water. Not only water. Something with rust in it, and under the rust a thread of orange, the way a kitchen smells for weeks after somebody boils peel to make a flat feel occupied.

MARA: She was still cooking in November. He had already ordered the plasterboard."""

# ---------------------------------------------------------------------------
# Chapter 4A — pipe answered. Dane comes through the service hatch.
# Plate cg_hatch, gated. Tier 3: a garment doing work, a hand that is not idle,
# a face doing the scene, a frame that implies the rest.
# ---------------------------------------------------------------------------
const CH4_HATCH := """Three knocks out of the copper. Three back off the valve wheel with the flat of your hand, and the stack exhales like something that has been holding its breath since November.

Then, from the service hatch at floor level, four bolts being worked from the other side by somebody who knows which one sticks.
---
The plywood comes out into the bathroom. Dust, insulation, a smell of hot dust and old solder, and then a shoulder, an arm with a long pale scar across the forearm, and Dane Orlov coming out of a wall on his knees in a grey shirt filthy to the elbows.

DANE: Three. You answered three.
---
MARA: You said not two.

DANE: I said a lot of things through a door and nobody has ever done one of them.

He is shaking. Not fear-shaking — the other one, the one that comes down off two weeks of being told you are imagining a woman.
---
MARA: You crawled twenty feet of service cavity in the dark.

DANE: Eighteen. And I've done it eleven times and every other time this room was empty and her things were still warm.

He sits back against the tiles, pushes both palms over his face, and laughs at nothing at all, which is the first true sound anything in this building has made tonight.
---
You are still kneeling by the hatch. You did not stand up, and you notice that you did not stand up.

MARA: I recorded the stain. I kept the photograph. It's uploaded outside the building's system and Pell cannot delete it from where I put it.

DANE: Say that again.
---
MARA: I kept her name.

He does not say anything. He reaches out and takes your wrist — not hard, and not far, just the wrist, the way you hold onto a rail on a moving thing — and he puts his forehead against your shoulder and breathes out, once, all of it.

DANE: Sorry. Sorry. Give me a second.
---
MARA: Take it.

Your other hand is in his hair before you have decided anything about it. The green light from the doorway lies along his back. Somewhere below the floor the pipe ticks as it cools, and for the length of about four heartbeats neither of you is doing a job.
---
He lifts his head. He is close enough that you can see him work out the distance and decide not to close it.

DANE: I'm going to be very clear, because tonight is a night about paperwork.

MARA: Go on.
---
DANE: You don't owe me anything for the hatch. Not for the note, not for the wall code, not for being the only person in eleven months who said her name out loud. There is no ledger. If you get up and go back to work, I will hold the torch for you and that will be the whole of it.

MARA: And if I don't get up.
---
DANE: Then it's because you want to, and it stays in this room, and nobody writes it down anywhere.

That is the exact inverse of the document on the table in the other room, and both of you know it at the same moment, and it is the reason your hand is still on the back of his neck.
---
MARA: Say the second half again.

DANE: Nothing owed. Nothing recorded.

MARA: Yes. That one.
---
You kiss him on the floor of a stranger's bathroom under a fluorescent tube that has been failing since 2019, wet to the knees, with your hands full of a man's collar.

He is careful in a way that is not hesitation — he asks with his hands before he does anything with them, and waits each time, which takes longer and is better.
---
The grey shirt comes off over his head and gets thrown somewhere it will be found later, covered in dust. Yours does not come off so much as get pulled down off your shoulders and left where it is, because his mouth is at your collarbone and neither of you has the patience for sleeves.

MARA: Careful. Tiles.

DANE: I've got you.
---
He does, actually — one hand flat between your shoulder blades and the other braced on the floor, taking your weight off the cold of it, and that is the detail you will remember for a year: that his first thought when you went backwards was the temperature of the floor.

Your arms go around his neck. Your own hand comes up to cover yourself out of thirty-three years of habit, and stays there, and he does not move it, and somehow that is the most wanted you have felt in a decade.
---
MARA: Look at me.

DANE: I am. I've been looking at you since the corridor.

Foreheads together. Breath. The sound the copper makes when a woman in the wall stops knocking and, for the first time tonight, leaves two people alone.
---
Later — not much later; the clock in the bedroom is still frozen at 02:17 and will be for the rest of the night — you are both sitting against the bath with the hatch open at your feet and the dust of the cavity on absolutely everything.

DANE: I need to say something and it's going to come out badly.
---
MARA: Everything has tonight.

DANE: Iris and I were together. Nine months. It ended in August, badly, my fault, and we were friends again by October.

He looks at the hatch rather than at you.
---
DANE: I'm not doing this to get over her and I'm not doing it because you look like — you don't, you're nothing like her. I need you to know that this wasn't about her. Whatever else happens tonight, she doesn't get used as a reason for something.

MARA: Understood. And she doesn't get used as a reason against one either.
---
DANE: No.

MARA: Then we're square.

You find his hand on the tile without looking for it. The copper ticks. The building, for once, has nothing to say.
---
MARA: Dane. When I go back out there, there is a piece of paper on that table that transfers custodianship of this flat and its unresolved contents to whoever signs it.

DANE: I know what it is. Harrow signed one.
---
MARA: It's the same shape as what just happened in here. Somebody offers you something at two in the morning in a building nobody is watching.

DANE: It is not the same shape.

MARA: No. It's the mirror image. That one takes a person and calls it custodianship. This one took nothing and wrote nothing down.
---
DANE: Then don't sign it.

MARA: I wasn't going to before this. I want that on the record, since we're not keeping one.

MARA'S FIELD NOTE: Consent looks like this: it is asked for in words, it can be withdrawn without cost, and nothing is owed afterwards. The clause on that table is drafted to look like the same thing and is the precise opposite. I will be able to tell a magistrate the difference, which is more than Pell can say for Harrow."""

# Chapter 4B — the valve was closed. Dane still comes; nothing else does.
const CH4_SILENT := """Four bolts turn in the service hatch, slowly, from the cavity side, and stop.

DANE: Venn. You closed the valve.
---
MARA: It's hydraulic shock. It's a line under pressure with air in it.

DANE: It knocked three times and waited. Air doesn't wait.

The plywood does not come out of the wall. He stays on the other side of eighteen feet of insulation, where it is dark, and you both listen to nothing for a while.
---
DANE: Right. Okay.

MARA: Mr. Orlov—

DANE: Dane. It was Dane in the corridor.

He does not sound angry. That is somehow worse; he sounds like somebody re-filing a hope that had been in the wrong drawer.
---
DANE: If you get a call from Pell in the next ten minutes and he thanks you for the correction, remember that I told you he would.

MARA: Noted.

DANE: Don't sign anything. That's the last one I've got.

The bolts turn back. The cavity goes quiet, and the flat gets exactly what the checklist asked for, which is a building with nobody audible in it.
---
Your phone rings eight minutes later. No number.

PELL: Good. A quiet building is a safe building, Ms. Venn.
---
MARA: I closed a valve on a line with air in it.

PELL: You did. And the sound stopped, which is the test, and the test passed. Complete the clause and payment releases before morning.
---
He hangs up before you can decide whether to ask how he knew.

MARA'S FIELD NOTE: He called eight minutes after the valve, on a night he told me not to contact adjoining tenants, about a task he was not present for. Either this flat reports to him or he is in the corridor. Both are worse than the noise was."""

# ---------------------------------------------------------------------------
# Chapter 5 — the cavity. Plate cg_cavity, tier 0, never censored, never gated:
# it is the frightened one, and it has to be free.
# ---------------------------------------------------------------------------
const CH5_CAVITY := """The false back of the wardrobe comes away on a latch that was installed on the room side, by a contractor, six days before the leak that justified it.

Behind it: torn insulation, a copper stack crossing the gap at shoulder height, and a space the size of one seated adult.
---
You go in on your knees with the phone torch in your teeth, because there is no version of this where you send somebody else in first.

Coats brush your back. The yellow one has an empty hanger beside it that is still moving.
---
The cavity smells of wet plaster and, underneath, of orange peel.

MARA: Iris. I'm in. I'm not taking anything out of here that proves you left.
---
Fingernail marks score the plywood on the apartment side, not the cavity side. She was not sealed in. She sealed herself in, and she did it because an inspector cannot certify a unit empty while a tenant remains inside its boundary, and because that was the only legal instrument she had left.

MARA: That's not madness. That's a woman reading the contract properly.
---
The torch finds the recorder on a folded coat, set down carefully, squared to the wall, the way you put something down when you expect someone to come looking for it and you want them to know it was meant for them.

Your hands are not steady. That is worth writing down honestly: at 02:21, in a wall, they were not steady.
---
Above you, the copper carries a sound up the building and out into the bathroom, three storeys of pipe turning one small noise into something the whole stack can hear. It is the noise of a woman getting the attention of the only person in the building who will answer.

MARA: I hear you. I'm taking the tape, not your name. The name stays on the door.
---
The torch beam shortens. Phone light from below throws your own shadow up the insulation and it is enormous and it is not shaped like you.

MARA: Nope. Nope, out, out.
---
You come out of the wall backwards with the recorder against your chest and you sit on the floor of a dead woman's bedroom with your back against her bed and you breathe for eleven seconds before you press play.

MARA'S FIELD NOTE: For the record — my own, not the building's — I was frightened in there. Not of her. Of being the next thing the wall was built to hold.
---
There is one more thing in the cavity and you go back in for it, which is the second-worst decision of the night and the one you would make again.

A coat, folded, not hers — a man's, inspection-company lining, the sleeves still holding the shape of somebody's arms.
---
MARA: Harrow.

The label inside the collar has a name tape sewn in by somebody who loved him enough to do it by hand, and the building has not managed to take that either, because thread is not a record and there is nothing in the system to delete.
---
You leave the coat where it is. You photograph it against the insulation with the pipe in frame for scale and you write the time on your own wrist in biro, because your phone has been rewriting itself all night and skin has not.

MARA: Two people are in this wall's paperwork and neither of them is in the wall. That is not a haunting. That's an operation with a maintenance schedule."""

# ---------------------------------------------------------------------------
# Chapter 6A — the clause is signed. Plate cg_renewal. Dread, not reward.
# There is deliberately no adult scene on the COMPLICIT route, and that is
# the design: the route that trades a person away doesn't get to be warm.
# ---------------------------------------------------------------------------
const CH6_RENEWAL := """Mara Venn. Temporary. Until morning.

The pen is Pell's, left on the table with the cap off, which is a detail you notice one second after the ink is already down.
---
The ink does not dry. It crawls, thin as a hairline crack, from the tail of your signature across the printed page toward one word — contents — and stops when it gets there, the way water stops when it has found the drain it was always going to find.

PELL: Thank you, Ms. Venn.
---
He is on the speaker of a phone you did not take out of your pocket.

PELL: Welcome home.

MARA: That's not what this document says.

PELL: It is exactly what it says. You read it. That is the part everyone gets wrong — they all read it.
---
The flat changes without a transition, the way a room changes when a slide advances.

The damp is gone. The wallpaper is new and the colour someone else chose. There is a couch that is not the sagging one, with a cardigan over its arm that is your size and not your colour, and the light through the window is morning.
---
MARA: It's 02:27.

PELL: It is whenever the unit is next inspected. Sit down, Ms. Venn. You've been on your feet since one.
---
And you do. That is the part you will not be able to explain afterwards, if there is an afterwards: the couch is warm, and your legs stop, and the cardigan is already over your shoulders, and the building is being so kind.

On the side table, a picture frame that was empty an hour ago now holds a photograph of a woman on this couch with her face turned away from the camera.
---
MARA: Turn her face.

PELL: She prefers it. They all prefer it eventually. A face in a photograph is an outside record, and outside records are what make tenancies difficult.
---
The checklist on your phone rewrites itself while you are holding it.

OCCUPANT: MARA VENN
MOVE-OUT INSPECTOR: [awaiting arrival]
Please keep the pipe quiet for the next guest.
---
MARA: I have a flat. I have a lease in Harrow Road with eight months on it.

PELL: You had. Vesper Court is very good at eight months.

Somewhere beneath the floor, three knocks. Short, short, long. Waiting for three back.
---
You do not answer them. You are so tired, and the couch is warm, and the knocking is only hydraulic shock, and a quiet building is a safe building.

A key that is not yours enters the front door from the corridor side.
---
MARA'S FIELD NOTE: [the note does not save. The field app reports: CUSTODIAN ACCOUNTS CANNOT FILE TESTIMONY.]"""

# ---------------------------------------------------------------------------
# Chapter 6B — the clause is torn. Requires pipe_answered and dane_note.
# Plate cg_403, gated. The most explicit; the payoff for the route that
# trusts people. Tier 3 ceiling holds: sheet over hips, upper body, tender.
# ---------------------------------------------------------------------------
const CH6_403 := """The clause tears more easily than a document that important should.

MARA: No. This inspection is suspended pending a housing authority referral and a criminal complaint, and you can have both halves of your paper.
---
Both halves now read the same line where the unit number was:

UNIT 404: NOT FOUND

Out in the corridor, the light goes from yellow to a blue so dark it is almost black, all four fixtures at once, like something closing an eye.
---
The front door of 404 will not open from the inside, which is a design feature you will be putting in the report.

The service hatch will. Eighteen feet of cavity, one sticking bolt, and a man on the other end with a torch pointed at his own face so you can see it is him.
---
DANE: Come through. Don't look left in the middle, there's nothing there and you'll still look.

MARA: What's on the left?

DANE: The back of a wardrobe that isn't in either of our flats. Come on.
---
403 is 404 with the lights on and the boxes unpacked. Same geometry, mirrored — bathroom where yours was, bedroom against the shared wall — but warm, lived in, a lamp instead of a fluorescent tube, two weeks of not-sleeping in the state of the kitchen.

You come out of his wall covered in insulation with a cassette in a freezer bag and your phone at eleven percent.
---
DANE: Sit. Are you hurt anywhere I can't see?

MARA: I'm fine. Dane — the corridor's gone blue. Both our doors are in it.

DANE: I know. I can hear it not being there.
---
He puts the chain on a door neither of you believes in any more and turns the deadbolt anyway, because there is a kind of courage that consists entirely of doing the ordinary thing on time.

Then he stands in the middle of his own bedroom with his hands loose and says:
---
DANE: I'd like to ask you something and I want the answer to be easy to say no to.

MARA: Then ask it badly. I'll do the rest.

DANE: Stay in here until it's light. That's the whole ask. There's a bed and a couch and I genuinely do not care which of them I'm on.
---
MARA: And if I say the bed and I mean both of us in it.

DANE: Then that's a different sentence and you can say that one too.

MARA: I'm saying it.
---
The bedside lamp is the only light. Through the window, four floors down, a street with weather on it — ordinary rain on ordinary tarmac, the first honest thing you have seen since 01:47 — and along the top edge of the glass the corridor's black-blue seeping in like a draught.

He looks at it once and then does not look at it again.
---
DANE: If it comes through that wall I want to be doing something better than watching the wall.

MARA: Agreed.
---
There is no urgency in it this time and that turns out to be the entire difference. The bathroom floor was two people who had survived something. This is two people deciding, slowly, in a lit room, with the door bolted and a whole night to be wrong in.

Your jacket goes over the boxes. His shirt goes on the floor and neither of you looks where.
---
He asks. You say yes. He asks again later about something else and you say yes to that too, and once you say not that, and he says okay in the same voice he said everything else in, and that is the end of that with no weather in it at all.

MARA: You're good at this part.

DANE: I'm good at listening. It's not a separate skill, whatever men tell you.
---
Afterwards you are on top of him with the sheet dragged over both your hips and your hair down over your face, and he pushes it back with two fingers to see you, which takes him longer than it needs to.

DANE: There you are.
---
MARA: Don't.

DANE: Don't what?

MARA: Don't be tender at me at half past two. I've had a night.
---
He laughs — properly, the whole chest of it, under you — and you end up with your forehead on his sternum laughing at nothing in a building that has been trying to erase a woman since November, and if that is not resistance then nothing in this flat is.

The lamp buzzes. Beyond the window the blue holds at the edge of the glass and comes no further.
---
Later, both of you awake, neither of you saying so.

DANE: What happens at 02:29.

MARA: Four knocks. Then I decide who leaves.
---
DANE: You'll open it.

MARA: I'll open it.

DANE: Then I'm standing behind you when you do, and you're going to hate that, and I'm doing it anyway.
---
MARA: Dane. Tonight two people offered me a transaction in this building.

DANE: Don't put me on a chart with Pell.

MARA: I'm putting you at the other end of it. He wanted a signature that moves a person into a wall and calls it custodianship. You asked a question that was easy to say no to.
---
MARA: Same building. Same hour. Same paperwork logic, inverted. I'm going to say exactly that to the housing authority at nine and I don't care how it reads.

DANE: It'll read like a woman who knows the difference.

MARA: It'll read like the only evidence anybody's collected in this building in eleven months that a person can be asked instead of processed.
---
MARA'S FIELD NOTE: 02:27. Location: Flat 403, Vesper Court. Witness Dane Orlov present and willing to be named. Cassette secured. Photograph uploaded off-site. Clause refused and destroyed.

I am about to open a door on purpose. Anything that happens after this happened to somebody who chose it."""

# ---------------------------------------------------------------------------
# Chapter 7 — ending preludes. The ending plates ride on the base resolver.
# ---------------------------------------------------------------------------
const CH7_WITNESS := """You open the door on the fourth knock and the corridor is not behind it.

Behind it is the service cavity, lit from somewhere with no lamp in it, translucent sheeting hung across pipework that runs up through every version of this floor.
---
A shape stands behind the plastic. A wet coat. One hand flat against the sheet at the height of a shoulder. A name badge, readable, which is the only part of her the building never managed to take.

She is not going to be shown to you as a face. That is the last thing she has and she is keeping it.
---
MARA: Iris Vale occupied this flat. I heard her. I recorded her. There is a photograph of her name outside this building and a witness in 403 who will say all of it again under his own.

MARA: I am not certifying it vacant.

IRIS: Then look at me.
---
You look. Then you walk three steps forward, through the threshold, on purpose, with a man's hand in yours who came because you told him not to, and the geometry turns over into a corridor with dawn in it."""

const CH7_COMPLICIT := """You turn off the standing lamp.

The knocking stops halfway through a strike, the way a sentence stops when the person saying it is interrupted by something with more authority.
---
Daylight, with no transition. The flat immaculate. Somebody's furniture, arranged for somebody's photographs.

You are the only person in Vesper Court who is not audible tonight, and you are audible only because you have not signed the last line yet.
---
PELL: Inspection accepted. No tenant found. Your renewal begins today.
---
There is a cardigan over the arm of the couch in a colour you would never buy, and it is your size, and it has been washed.

MARA: Whose is this?

PELL: The previous custodian's. She was very tidy about it. They usually are, by the second week.
---
The wall in the kitchen is dry and smooth and painted, and there is no name in it, and that is the part that finally gets through to you — not the daylight, not the furniture, but a clean wall where a woman signed her name in damp every time management brought an inspector.

MARA: I photographed that wall.

PELL: You deleted it. That is what the photograph is for.
---
Somewhere under the floor, three knocks. Short, short, long. Waiting for three back from whoever is in the flat now.

You know what the knocks are. You have known since 02:09. And you are so tired, and the couch is warm, and a quiet building is a safe building.
---
Four knocks at the front door, and a key that is not yours in the lock, and a woman's voice in the corridor saying she has been asked to certify the unit vacant and that it should take ten minutes."""

const CH7_404 := """The key goes into the lock and through it, and through the wall behind it.

Every door on the fourth floor reads 403. There is no fourth unit on any floor, says a voice on a phone that will shortly not have your number in it.
---
MARA: I was inside. Kitchen, bath, bedroom. A man in 403 knows my name.

The operator asks who authorised your visit. Your inventory erases itself one item at a time: cassette, photograph, clause, and then, without any particular ceremony, MARA VENN.
---
IRIS: A witness who will not choose is only another missing room.
---
You do the only thing left that is yours to do, which is to say the names out loud in an empty lobby to nobody, in order, while you can still hear yourself do it.

MARA: Iris Vale. Elias Harrow. Dane Orlov. Mara Venn.
---
The lift opens on a brick wall. Somewhere above you, four floors up, a man who crawled a service cavity eleven times is knocking on a door that is not there any more and getting no answer at all, and he will keep doing it until somebody closes his ticket for him.

The next appointment is at 01:47. Please bring identification."""

# ---------------------------------------------------------------------------
# The gate. Shown in place of a gated plate when the bytes are not present.
# ---------------------------------------------------------------------------
const GATE_HATCH := """This plate is not in the free build.

The free browser slice ends one beat before it. The full download, and the unlock on this page, carry the uncensored art for this scene and for 403; the scene itself is playing either way and nothing in the writing is withheld."""

const GATE_403 := """This plate is not in the free build.

Two of the seven plates in Overnight Clause are gated. The other five, including the wall cavity, ship open in every build."""

static func scene(id: String) -> String:
	match id:
		"ch2_dane":
			return CH2_DANE
		"ch3_mirror":
			return CH3_MIRROR
		"ch4_hatch":
			return CH4_HATCH
		"ch4_silent":
			return CH4_SILENT
		"ch5_cavity":
			return CH5_CAVITY
		"ch6_renewal":
			return CH6_RENEWAL
		"ch6_403":
			return CH6_403
		"ch7_witness":
			return CH7_WITNESS
		"ch7_complicit":
			return CH7_COMPLICIT
		"ch7_404":
			return CH7_404
		"gate_hatch":
			return GATE_HATCH
		"gate_403":
			return GATE_403
	return ""


static func ids() -> PackedStringArray:
	return PackedStringArray([
		"ch2_dane", "ch3_mirror", "ch4_hatch", "ch4_silent", "ch5_cavity",
		"ch6_renewal", "ch6_403", "ch7_witness", "ch7_complicit", "ch7_404",
	])
