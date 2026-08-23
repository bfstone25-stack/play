#!/usr/bin/env python3
"""Generate the English vocal-theme pilot for Flutter's My Moment song system."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

LYRICS = """[Verse 1]
I knew how to leave a light on
For a room I wouldn't stay
Knew a hundred ways to smile
And keep the truest words away

[Pre-Chorus]
Then you learned the quiet language
I was certain no one knew
Now the silence isn't empty
When I'm standing next to you

[Chorus]
Here is where my heart comes home
Not a place, not a promise carved in stone
When the whole world moves, one thing stays true
I find my way, I find my way to you
Here is where my heart comes home
I don't have to carry everything alone
Let tomorrow come, there's nothing left to prove
I find my way, I find my way to you

[Verse 2]
Every almost, every maybe
Led me softly to this door
You don't ask me to be fearless
You just make me want it more

[Pre-Chorus]
If the night forgets the morning
If the road forgets its name
I will know you by the feeling
Of my breathing falling into place

[Chorus]
Here is where my heart comes home
Not a place, not a promise carved in stone
When the whole world moves, one thing stays true
I find my way, I find my way to you
Here is where my heart comes home
I don't have to carry everything alone
Let tomorrow come, there's nothing left to prove
I find my way, I find my way to you

[Bridge]
No perfect line, no grand design
Just your hand finding mine

[Final Chorus]
Here is where my heart comes home
For the first time I am not afraid to know
When the whole world moves, one thing stays true
I choose this life, I choose this life with you
"""

JOB = {
    "bpm": 76,
    "key": "D major",
    "duration": 132.0,
    "language": "en",
    "lyrics": LYRICS,
    "tags": (
        "original premium contemporary English pop love song for a prestige romance series, intimate expressive "
        "adult female lead vocal, natural human phrasing and breath, emotionally specific conversational verses, "
        "irresistible memorable chorus hook, melody written for a real singer with a comfortable range and clear "
        "repeatable contour, piano and warm Rhodes, melodic electric bass, restrained live drums, acoustic guitar, "
        "cello and luminous strings that support rather than replace the voice, mature sweet belonging, slow-burn "
        "love finally becoming certain, polished timeless radio-quality production, no vocal acrobatics, no choir, "
        "no musical theatre, no ambient soundtrack, no generic corporate music, no imitation or quotation of any "
        "existing singer or song"
    ),
}


def main():
    result = base.post("/prompt", {"prompt": base.workflow("en-my-moment-vocal-pilot", JOB)})
    prompt_id = result["prompt_id"]
    print(f"queued {prompt_id}", flush=True)
    while True:
        history = base.get("/history/" + prompt_id)
        if prompt_id in history:
            status = history[prompt_id].get("status", {})
            if status.get("completed"):
                print("complete", flush=True)
                return
            if status.get("status_str") == "error":
                raise RuntimeError(json.dumps(history[prompt_id], ensure_ascii=False))
        time.sleep(5)


if __name__ == "__main__":
    main()
