## 03_veil.rpy — Appraisal 3: Widow Merrow, the mourning veil.
##
## Grief, not shame. The vision is the night before the funeral, not the funeral. Per the
## design this is the scene that has to land emotionally or the whole fork reads as smut with
## a spreadsheet attached — so the erotic register here is entirely "a woman alone in a room
## deciding what she will be tomorrow", and the CG costs mercy rather than curiosity.

label act_veil:
    call chapter_gate(2) from _call_chapter_gate_2
    $ tel_track("act_veil_start", {"till": run.till})
    scene bg shop
    with dissolve

    nar "Ten past one. The rain has stopped and left the street shining, which is worse."
    nar "The woman who comes in does not hurry and does not apologise for the hour, and she closes the door behind her with two hands, quietly, the way you close a door in a hospital."

    nar "Early forties. Tall, long-necked, black hair with one white streak in it that is not dye and is not age either — it is the other thing, the kind that arrives in a fortnight."
    nar "Black dress, high collar, and a brooch at the throat that is worth more than the contents of this shop."

    mer "You are Elsa's girl."
    nara "I'm Elsa's niece."
    mer "That is what I said."

    nar "She puts a folded square of black crepe on the counter and smooths it flat with the back of her hand, twice, which is a gesture that belongs to fabric and not to money."

    nara "A veil."
    mer "A mourning veil. There is a difference and you will want it for your ticket."
    nara "Merrow."
    mer "Widow Merrow, since about March. You may use either. I have not settled on which one I am."

    nar "The crepe is old, good, and the pleating at the crown has been pressed exactly once. It has been worn exactly once. It has never been washed, and you do not wash crepe anyway, so that is not neglect, it is preservation."

    nara "It's been out of a box recently."
    mer "It has been out of a box for six months. It is on the chair in my bedroom and I go past it four times a day and I have decided that is a stupid way to run a house."

    nara "You could throw it away."
    mer "I could. That would be a decision about him. I would rather it were a transaction about a piece of cloth."

    nar "Thirty-five. Antique crepe in this condition goes to a costumier for thirty-five, or to a collector of very specific and unwholesome things for more, and Nara does not sell to those."
    nar "A reading costs the shop twenty, and Merrow has not told her not to, and that is somehow worse than Ivo, because it means it is entirely Nara's to decide."

    $ tel_track("choice_read_shown", {"item": "veil"})

    menu:
        "Nobody has said no."

        "Read it. ([fee_for('veil')] out of the till)" if reading_affordable("veil"):
            nara "May I."
            mer "May you what?"
            nara "Elsa will have told you what this shop does. May I."
            nar "Merrow looks at her for a long moment and then does a thing with her chin that in her family has meant yes for four generations."
            mer "She said it costs you. Is that true, or is it a thing you say to make people feel bought?"
            nara "It's true. It comes out of the drawer."
            mer "Then spend it, and afterwards you will tell me what you saw, because I was there and I want to know if it is the same."
            call reading_take("veil") from _call_reading_veil
            jump veil_after_reading

        "Read it — the drawer is short. ([fee_for('veil')] needed, [run.till] in it)" if not reading_affordable("veil"):
            nar "She asks the shop and the shop looks at the drawer and says no, in the way it says no: nothing at all happens, expensively."
            nara "I can't. I haven't got it tonight."
            mer "That is the most honest thing anyone has said to me since March."
            $ run.record_refusal("veil")
            $ tel_track("reading_declined", {"item": "veil", "why": "broke", "till": run.till})
            jump veil_price

        "Don't. It's a widow's veil and she is standing right there.":
            $ run.record_refusal("veil")
            $ tel_track("reading_declined", {"item": "veil", "why": "chose"})
            nara "I'll price it as cloth."
            mer "You are allowed to look. Elsa looked."
            nara "Elsa looked at everything and died owing two hundred pounds and knowing what every object in this building had been doing. I'm not sure those are unrelated."
            nar "Merrow almost smiles, which on her is an event."
            mer "No. I don't imagine they are."
            jump veil_price


label veil_after_reading:
    nar "The night before, not the day of."
    nar "That is the first thing and it reorganises everything, because Nara had braced for a church."

    nar "A bedroom with the furniture wrong — a bed slept in by one person in the middle rather than two people at the edges, and a chair with a black dress laid out on it flat, sleeves arranged, the way you lay out a thing you are frightened of."
    nar "Candles, because the electricity in that house is Victorian and so is the house. A lily in a jug that somebody has sent and somebody else has put somewhere without thinking about it."

    nar "Merrow is at the mirror, and she is trying it on."

    nar "The veil first. Over the face, then lifted, then over again, and the third time she leaves it and stands there looking at the shape of herself through black crepe, which is a thing a person does the night before, alone, in order to find out whether they can get through the day."
    nar "The dress is not on yet. She has come to the mirror in the middle of undressing and got stopped by the veil, so the dress is at her waist and her arms are down at her sides and she is not holding anything, and that stillness is the whole scene."

    nar "It is not modesty and it is not the other thing either. It is a woman looking at her own bare shoulders in a mirror, under a black veil, twelve hours before the worst appointment of her life, working out whether she is going to be able to stand up straight."
    nar "The mirror does most of the work. You are watching the reflection and the reflection is watching her and Nara is a third thing, four feet up, with no right to be there at all."

    nar "She is composed. That is what makes it hard. There is no crying in this scene, and the reading does not offer any, and the total absence of it is the most naked thing in the room."

    nar "After about a minute she lifts the veil back off her face, and looks at herself without it, and says one word to the mirror."
    nar "Then she folds the veil over the arm of the chair and blows the candle out."

    $ act_cleared = 3
    nar "The lamp. The counter. The crepe under her palm, cool."

    mer "Well."
    nara "You were at the mirror."
    mer "Yes."
    nara "You had it over your face and then you took it off."
    mer "Yes."
    nara "You said something."
    mer "..."
    mer "I said his name. To check that I could."

    nar "Nara does not say anything, because there is nothing that is not worse than nothing."

    mer "And could I, in your version?"
    nara "You said one word. The reading doesn't carry sound."
    mer "Good. That is exactly the correct amount of it to have."

    nar "She smooths the crepe flat again with the back of her hand. Twice."

    mer "I will tell you what I expected, since I have paid for the right to be embarrassed. I expected the funeral. I have been dreading that you would see me at the funeral, where I was very badly behaved."
    nara "I got the night before."
    mer "The night before I was alone and had my arms down and was frightened. That is the version I can stand a stranger having."
    nara "It wasn't frightened."
    mer "Wasn't it."
    nara "It was somebody finding out they could do it. That's a different picture."

    nar "Merrow looks at the veil on the counter for a while."

    mer "Thirty-five, Elsa would have said."

    jump veil_price


label veil_price:
    nar "Thirty-five is the number. Twenty-three is what a costumier pays a stranger. Fifty-two is not a price for cloth."
    nar "And this is the one where the arithmetic is honest about itself: to unlock what she just saw — to have any right to it — the shop has to go above the number. Mercy costs, or it was only curiosity wearing a better coat."

    call price_menu("veil") from _call_price_veil
    $ _tier = run.prices["veil"]

    if _tier == "low":
        nar "Twenty-three. Merrow reads the ticket and her face does not move at all, which is a skill and she has had six months to practise it."
        mer "That is a costumier's number."
        nara "It's a fair trade number."
        mer "It is a number for a woman who does not know what she has. Thank you for the demonstration."
        nar "She takes it. At the door she does not turn round."
    elif _tier == "fair":
        nar "Thirty-five. She writes it, and Merrow nods once."
        mer "Elsa's number."
        nara "It's the right number."
        mer "It is the right number. You will find that the right number is very rarely the whole of what is owed, but it is a good place to start and I am glad you started there."
        nar "At the door she pauses with a hand on the glass."
        mer "You will not tell anyone."
        nara "No."
        mer "No. I did not think you would. That is a different thing from not being able to."
    else:
        nar "Fifty-two. She turns the ticket round and pushes it across the crepe."
        mer "That is seventeen pounds more than it is worth."
        nara "Yes."
        mer "Why."
        nara "Because I went into your bedroom on the worst night of your life without asking properly and I looked at you, and thirty-five is what the cloth costs and seventeen is what I owe."
        mer "That is not how a shop works."
        nara "It's how this one works after one in the morning."

        nar "Merrow takes the money, and then does something nobody has done across this counter in three years: she puts her hand flat on the back of Nara's, on the crepe, for about two seconds."
        mer "You will want to be careful, Elsa's girl. That column adds up in both directions."
        nara "Which column?"
        mer "The fourth one."
        nar "And she is gone, and the veil is on the shelf, and the shop is very quiet in the specific way it is quiet when it has got what it wanted."

    $ tel_track("act_veil_done", {"tier": _tier, "till": run.till, "read": "veil" in run.readings_taken})
    jump act_market
