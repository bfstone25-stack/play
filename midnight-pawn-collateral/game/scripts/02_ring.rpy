## 02_ring.rpy — Appraisal 2: Ivo Lask, the ring. The fork's first real transgression.
##
## He asks you not to look. Looking costs 35 out of the till and it is the only CG in the
## game whose unlock condition includes a person having said no — which is deliberate and is
## the thing the scene has to earn rather than enjoy.

label act_ring:
    $ tel_track("act_ring_start", {"till": run.till})
    scene bg shop
    with dissolve

    nar "Twelve twenty. The shelves have done their second shuffle of the night, quieter, the way a house settles."
    nar "The man who comes in has been outside for a while. You can tell by the way he does not react to the warmth."

    nar "Late thirties. Brown hair going back at the temples, short beard, forearms out of a rolled shirt with old ink on the left one that has gone the green of a tattoo somebody got at twenty-two."
    nar "He puts a ring on the counter from about six inches up, so it lands and rolls and he has to stop it with one finger."

    ivo "How much."
    nara "Depends what it is."
    ivo "It's a ring. That's the whole of it."

    nar "It is a woman's wedding band. Yellow gold, narrow, worn thin on the inside curve the way a ring goes when it has been worn every day for years and taken off for nothing."
    nar "There is an engraving inside. She turns it to the lamp before he can stop her."

    nara "There's a date in it."
    ivo "There is."

    nar "It is eleven months after the date Nara would put on a decree if she were putting one on a decree, which she is not, because she does not know this man."
    nar "But you learn to read a date the way you read a hallmark. This one is not the date of a wedding. It is the date of a thing that happened after a wedding had finished happening."

    nara "Ivo?"
    ivo "How do you —"
    nara "It's on the card you're holding. You've been turning it over since you came in."

    nar "He looks at his own hand. Pawn ticket from three years ago, another shop, softened at the corners."

    ivo "Ivo Lask. I've done this before, is what that means. Not here."
    nara "Most people have done it before. It's a shop, not a confession."

    ## ---- the refusal, and it has to be unambiguous ------------------------
    nar "She puts two fingers on the band, and it is not a gesture that means anything to anyone who does not know what she is, but he goes very still."

    ivo "Don't do that."
    nara "Do what."
    ivo "Elsa did that. Same face, same two fingers. She told me what it was and I have thought about it every week since and I am asking you not to do it."

    nar "Nara takes her hand off the ring."

    nara "All right."
    ivo "It's mine to sell and it isn't mine to show you."

    nara "Whose is it?"
    ivo "Maya's. Not my wife. I want to be exact about that because everybody gets it wrong and then they look at me a certain way for the rest of the transaction."
    ivo "I was married. It ended. It ended properly — she left, we did the paperwork, we did it badly for a year and then we did it fine, and she is in Leeds and we speak at Christmas."
    ivo "Eleven months after all of that was finished, I bought that ring for someone else. And then I was an idiot about it in a way that had nothing to do with anybody but me."

    nara "So it's not —"
    ivo "It is not that. I want that said out loud in the shop before you write a number, because it is going to be the cheapest thing about tonight and I would still rather have it."

    nar "Nara writes something in the margin of the ledger, which is not a number."
    $ run.ivo_refused = True
    $ tel_track("ivo_refusal_stated")

    nar "Forty is what it is. Narrow band, low carat, a gram and a half of gold and no market for the sentiment."
    nar "A reading costs the shop thirty-five, which is very nearly the price of the object, and that is not a coincidence — the shop has always charged most for the things somebody has just told her not to look at."

    $ tel_track("choice_read_shown", {"item": "ring", "refused_by_client": True})

    menu:
        "He asked you not to."

        "Take the reading anyway. ([fee_for('ring')] out of the till)" if reading_affordable("ring"):
            nara "..."
            nar "She waits until he has turned to look at the case of pocket watches, which takes about four seconds, and she puts her whole palm on it."
            nar "That is the transgression and there is no version of it that is not one. She is not going to pretend otherwise later and neither is the ledger."
            call reading_take("ring") from _call_reading_ring
            jump ring_after_reading

        "Take the reading anyway — but the drawer is short. ([fee_for('ring')] needed, [run.till] in it)" if not reading_affordable("ring"):
            nar "She puts her palm on it and the shop counts the drawer and declines. The gold stays gold."
            nara "Nothing."
            nar "The first honest thing about the night is that she tried."
            $ run.record_refusal("ring")
            $ tel_track("reading_declined", {"item": "ring", "why": "broke", "till": run.till})
            jump ring_price

        "Don't. He asked.":
            $ run.record_refusal("ring")
            $ tel_track("reading_declined", {"item": "ring", "why": "chose"})
            nar "She leaves her hands on the ledger where he can see both of them, which is a thing Elsa did and Nara has never admitted she copied."
            nara "I didn't look."
            ivo "I know. I was watching in the case glass."
            nara "Then why did you ask?"
            ivo "Because asking is the part I get to do."
            jump ring_price


label ring_after_reading:
    ## Again: the vision is Ivo's, and Ivo is not the one it is really about. Nara is a
    ## fixed point four feet away with no ability to intervene, and the scene is framed from
    ## behind and past an object. Nobody in this room is at a counter at midnight.
    nar "A bedroom with the lamp on the floor because the nightstand is a stack of books, which is a flat somebody has lived in for four months and expects to leave."
    nar "Rain on the window. Different rain, harder, further north."

    nar "Two people asleep, or one asleep and one not. The sheet is up over both of them. Bare shoulder, bare back, an arm across. From behind and slightly above, the way readings always are, which is the only mercy in the whole arrangement."
    nar "The reading is not interested in them. It is interested in the ring, because the ring is what she is holding, and the ring is on the stack of books next to the lamp, in focus, with the rest of the room going soft around it."

    nar "That is what an object remembers. Not the night. The eleven centimetres of nightstand it spent the night on, and the hand that reached over at some point in it and moved it two centimetres to the left for no reason."

    nar "It was a good hour. Nara wants that noted. Whatever happened after — and something clearly happened after, or it would not be on her counter with a man outside it asking her not to look — the last use of this object was somebody being happy and slightly careless with it at two in the morning."

    nar "Then a hand takes it off the books. And the light goes."

    $ act_cleared = 2
    nar "Nara's palm is flat on the counter with nothing under it. Ivo has not turned round."

    ivo "Well?"
    nara "Forty."
    ivo "That isn't what I asked."
    nara "It's what I'm answering."

    nar "He turns round then, and he looks at her hand, and he does the arithmetic that anybody would do."

    ivo "You did it."
    nara "I did it."
    ivo "What did you —"
    nara "No."
    ivo "That's not fair."
    nara "No. It isn't. I took a thing you asked me not to take and I'm not going to make it worse by making you pay to hear it described."

    nar "There is a silence in which a clock that has been wrong since 1998 gets to be the loudest thing in the room."

    ivo "Was she happy."
    nara "..."
    nara "It was a nice room. The lamp was on the floor."
    ivo "It was always on the floor. She hated the — yeah."
    nar "He laughs at nothing, once, and rubs his face with the heel of his hand."
    ivo "Right. Write your number."

    jump ring_price


label ring_price:
    nar "Forty is the number. Twenty-six insults him and he will take it. Sixty is not a price, it is an apology with a receipt."

    call price_menu("ring") from _call_price_ring
    $ _tier = run.prices["ring"]

    if _tier == "low":
        nar "Twenty-six. He looks at the ticket and does not say anything about it, which is how you can tell."
        ivo "Fine."
        nara "It's a gram and a half."
        ivo "It's twenty-six quid and you know exactly what it is. That's what I came for."
        nar "The bell. The door. The rain taking him back."
    elif _tier == "fair":
        nar "Forty. He reads it twice."
        ivo "That's the real number."
        nara "That's the real number."
        ivo "Nobody gives me the real number. They give me the number they think I'll take because I look like a man who'll take it."
        nara "You do look like that. It's still forty."
        nar "He puts the money in his shirt pocket rather than his trousers, which is what people do when they are not going to spend it tonight."
        ivo "If I come back in a month, is it still here?"
        nara "Thirty days on the ticket. After that it's the shop's."
        ivo "And the shop's is —"
        nara "The shop's."
        nar "He nods like that was a straight answer, which it was, and goes."
    else:
        nar "Sixty. He does not pick the ticket up."
        ivo "No."
        nara "Take it."
        ivo "You're paying me for the thing you took. I can see you doing it. Don't."
        nara "I'm paying you sixty pounds for a gold ring, Mr Lask, and if you want to argue about the till you can come round this side of it."
        nar "He takes it, eventually, and he is angry in a way that is mostly aimed inward, and at the door he says the sentence she will still be carrying at four in the morning."
        ivo "The thing about your aunt is she never once told me I could have it back."
        nara "It's thirty days on the ticket."
        ivo "That's not the same shape of sentence and you know it."

    $ tel_track("act_ring_done", {"tier": _tier, "till": run.till, "read": "ring" in run.readings_taken})
    jump act_interlude


## ---------------------------------------------------------------------------
label act_interlude:
    ## The ledger balances. The dead's column is now non-zero, and Nara notices that she is
    ## also being priced.
    scene bg shop
    with dissolve
    $ tel_track("interlude", {"till": run.till, "taken": len(run.readings_taken)})

    nar "One in the morning. She does the halfway count because Elsa did the halfway count."

    nara "Till: [run.till]."
    nar "Stock on the shelf behind her: [run.stock_value()] of other people's brass and gold."
    nar "Against the estate, due in five hours: [core.DEBT]."

    if run.fees_paid > 0:
        nar "And in the fourth column, in Elsa's hand, in a ruled section Nara has never filled in and never had to explain: [run.fees_paid] spent on knowing."
        nar "The column has a heading. The heading is not in English and Nara has never looked it up, on the grounds that there is no version of the answer that improves her night."
    else:
        nar "And in the fourth column, in Elsa's hand, in a ruled section Nara has never filled in: nothing. Zero. Cleanest that column has been in three years."
        nara "Good."
        nar "It does not feel like good. It feels like the shop is waiting."

    nar "She turns the page and finds, on the reverse, in pencil, in her own handwriting, which she does not remember doing:"
    nar "{i}N. Quill — held against reading. Value: pending.{/i}"

    nara "..."
    nara "That's not funny."
    shop "..."

    nar "She puts her hand flat on the ledger, because of course she does, and gets absolutely nothing, which is the first time an object in this building has ever declined her."
    nar "Either it has no last use yet, or the last use has not finished."

    if "ring" in run.readings_taken:
        nar "Downstairs, under the floor, something that is not the boiler makes the sound the boiler makes. It has been doing that since she looked at the ring."
    else:
        nar "Downstairs, under the floor, the boiler makes the sound the boiler makes, and for once that is all it is."

    nar "There is a hatch behind the stock room that Elsa called the stairs and everyone else called a hole. It goes down to the Receipt Stair and from there to the Market."
    nar "She is not going down tonight. There is one more name in the book."

    jump act_veil
