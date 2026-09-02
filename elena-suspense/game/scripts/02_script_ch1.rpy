## 02_script_ch1.rpy - 15-Minute Branching Narrative: "Elena: Crimson Archives - Chapter 1"
## Suspense investigation, ecchi encounters, choices, variable tracking & CG unlocking

label start:
    # Reset local run variables
    $ elena_suspicion = 0
    $ elena_affection = 0
    $ secret_ledger_discovered = False
    $ chosen_ending = "none"

    # Start atmospheric soundscape
    play ambience rain_ambience fadein 2.0
    play music suspense_theme fadein 3.0

    scene bg study_normal
    with dissolve

    narrator "Saint Jude Academy — Department of Antiquities, 11:42 PM."
    narrator "Rain lashes relentlessly against the tall Gothic windows of the faculty archives."
    narrator "The smell of ancient leather, aged parchment, and rain-soaked cedar hangs heavy in the midnight air."

    protagonist "Another missing research ledger from the 19th-century occult bequest..."
    protagonist "Someone inside the department has been systematically altering the catalog logs."

    play sound page_flip

    narrator "You flip through the archive register on the mahogany desk. A soft click of a lock turning echoes through the corridor outside."

    play sound click

    narrator "The heavy oak door eases open. A slender silhouette steps quietly into the lamplight, clutching an embossed leather folder to her chest."

    show elena neutral at center
    with dissolve

    narrator "Elena. 22 years old, your most brilliant — and notoriously distant — postgraduate research assistant."
    narrator "Her Dark Academia wool blazer and neat silk tie are immaculate, but her breathing is unusually shallow."

    elena "Professor Vance...? I... didn't expect you to still be in the department at this hour."

    protagonist "I could say the same about you, Elena. The lower vault is restricted after curfew."

    elena "I was merely verifying cross-references for our joint monograph on the Blackwood codices."

    narrator "As she speaks, her fingers tighten around the leather folder. A gilded corner of an uncataloged ledger slips slightly into view."

    # Choice 1: Initial Investigation Approach
    menu:
        "“What is that folder in your hands, Elena?”":
            $ elena_suspicion += 1
            show elena flustered
            with dissolve
            elena "This? Just... preliminary transcription drafts! Nothing of administrative concern, I assure you."
            protagonist "Drafts don't carry the gold seal of the Archival Vault, Elena."
            narrator "Elena bites her lower lip, a faint tremor running through her posture."

        "“You're drenched from the rain. Step closer to the lamp.”":
            $ elena_affection += 1
            show elena flustered
            with dissolve
            elena "Ah... thank you, Professor. It began pouring right as I crossed the courtyard."
            narrator "She steps into the warm glow of the desk lamp. The rain has dampened her dark auburn curls, tracing delicate trails down her pale neck."
            narrator "Her composed facade wavers beneath your calm gaze."

        "Say nothing and step between her and the archive exit.":
            $ elena_suspicion += 2
            show elena flustered
            with dissolve
            narrator "You rise quietly from your chair and step toward the heavy arched door, cutting off her path."
            elena "Professor...? What are you doing?"
            protagonist "You look ready to bolt, Elena. That makes me curious."

    # Mid-investigation Confrontation
    narrator "The wind rattles the arched glass, casting dancing shadows across the mahogany study."

    play sound audio.heartbeat

    protagonist "Elena. Lay the folder on the desk."

    show elena flustered
    with dissolve

    elena "Professor Vance, please... You don't understand what is at stake. If the Dean discovers this ledger exists—"

    protagonist "Then you admit you took it."

    narrator "Before she can retreat, you close the distance. Elena backs up until her spine meets the towering cedar bookshelf."
    narrator "Trapped between the shelves and your towering frame, her composure crumbles completely."

    # Unlock Event CG 1: Confrontation
    $ unlock_cg("cg_confrontation")

    scene cg confrontation
    with fade

    narrator "Her breath catches. The scent of sweet vanilla perfume and damp rain radiates from her collarbone."
    narrator "Her glasses tilt slightly as she looks up into your eyes, trapped, flustered, and exquisitely vulnerable."

    elena "Vance... please. Don't look at me like that."
    elena "I didn't steal it for money. My family... our name was scrubbed from these records thirty years ago. I only wanted proof!"

    protagonist "Proof of what, Elena?"

    elena "Proof that I belong here... that I was never an outsider to your world."

    narrator "Her voice drops to a breathless whisper. Pressed firmly against the archive shelves, the warmth of her body radiates through her disheveled blouse."

    # Choice 2: Pivotal Branching Choice (Suspense vs Ecchi Submission)
    menu:
        "Press closer and demand the full truth with uncompromising intimacy.":
            $ elena_affection += 2
            $ elena_suspicion += 0
            jump scene_ecchi_surrender

        "Strictly seize the ledger and question her academic integrity.":
            $ elena_suspicion += 3
            jump scene_strict_interrogation

        "Offer a clandestine pact in exchange for her absolute loyalty.":
            $ elena_affection += 3
            $ secret_ledger_discovered = True
            jump scene_secret_pact

# Branch A: Ecchi Surrender & Climax
label scene_ecchi_surrender:
    stop music fadeout 2.0
    play music ecchi_theme fadein 2.0

    narrator "You place one hand firmly against the bookshelf beside her ear, leaning in until your lips graze the delicate curve of her earlobe."

    elena "Ah... Professor..."

    protagonist "If you want this secret buried, Elena... you will have to convince me right here, in this room."

    narrator "A deep crimson flush spreads down Elena's neck, down past the loosened silk tie of her blouse."
    narrator "Her knees tremble, and with a soft gasp of complete surrender, she lets the heavy leather ledger slide onto the mahogany desk."

    # Unlock Event CG 2: Climax
    $ unlock_cg("cg_climax")

    scene cg climax
    with dissolve

    narrator "Under the silver moonlight filtering through the Gothic arch, Elena reclines back against the cool mahogany desk."
    narrator "Her blazer slips down her arms. The delicate buttons of her blouse yield to the heated urgency of the midnight hour."

    elena "I... I can't hide anything from you anymore, Vance..."
    elena "Take everything... my secrets, my pride... just don't cast me away."

    protagonist "You never had to hide from me, Elena."

    narrator "Her breathless whimpers mingle with the rhythmic drumming of rain outside."
    narrator "The lines between mentor and scholar, captor and captive, dissolve into an intoxicating haze of ecstasy and devotion."

    jump scene_dawn_resolution

# Branch B: Strict Interrogation leading to compliance
label scene_strict_interrogation:
    scene bg study_dark
    show elena submission at center
    with dissolve

    protagonist "Academic fraud carries immediate expulsion, Elena. Hand over the ledger."

    narrator "Elena lowers her gaze, her shoulders slumping in total defeat. She places the forbidden manuscript into your hands."

    elena "What will you do to me now, Professor? Turn me in to the Academic Tribunal?"

    protagonist "That depends on how compliant you are from this moment onward."

    show elena flustered
    with dissolve

    elena "I... I will do whatever you instruct. Anything to remain by your side in the archives."

    # Leads into intimacy through submission
    jump scene_ecchi_surrender

# Branch C: Secret Romantic & Suspense Pact
label scene_secret_pact:
    stop music fadeout 2.0
    play music ecchi_theme fadein 2.0

    scene bg study_normal
    show elena flustered at center
    with dissolve

    protagonist "Your family's erased lineage... I already knew, Elena. I've been protecting those records for two years."

    elena "What...? You knew all along?!"

    protagonist "I needed to see how far you would go. And how much you truly trusted me."

    show elena submission at center
    with dissolve

    narrator "Tears of relief glisten in the corners of her cyan eyes. She throws her arms around your chest, trembling against your embrace."

    elena "You cruel, wonderful man... Why didn't you tell me sooner?"

    protagonist "Because some truths are sweeter when earned in the dark."

    # Unlock Event CG 2 & Climax
    $ unlock_cg("cg_climax")
    scene cg climax
    with fade

    narrator "The confession unlocks a reservoir of unspoken passion that has simmered between you for months."
    narrator "On the grand archive desk, amidst centuries of scholarly secrets, you seal an unbreakable pact in the quiet heat of midnight."

    jump scene_dawn_resolution

# Resolution: Dawn & Aftermath
label scene_dawn_resolution:
    stop music fadeout 3.0
    play music suspense_theme fadein 3.0

    # Unlock Event CG 3: Aftermath
    $ unlock_cg("cg_aftermath")

    scene cg aftermath
    with fade

    narrator "5:30 AM. Amber dawn light filters through the rain-streaked arched window."
    narrator "The storm outside has softened into a gentle morning mist."
    narrator "Elena rests peacefully in the velvet archive armchair, draped in your wool overcoat, a contented smile gracing her lips."

    elena "Good morning... Professor."

    protagonist "Morning, Elena. Did you sleep well?"

    elena "Better than I have in years. The missing ledger... what will we do with it now?"

    protagonist "We rewrite history together. Starting with Chapter 2."

    narrator "Elena blushes softly, resting her cheek against your hand."

    elena "I look forward to our next private research session, Vance..."

    # Branch to End CTA Screen
    jump end_cta_screen
