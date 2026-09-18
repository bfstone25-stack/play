#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""End-to-end HTTP playthrough against a running After Hours backend.

Proves the no-LLM path over the wire, not just in-process: /say never touches a
model, /choose returns the chapter-clear reward with its CG slot, /continue
advances, and the ending screen carries its own CG.

    python3 -m uvicorn backend.app:app --port 8931
    python3 tests/http_playthrough.py --port 8931 [--route ethan] [--lane anxious]
"""
import argparse
import json
import sys
import time
import urllib.request

def post(base, path, body):
    req = urllib.request.Request(base + path, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=30).read())


# Deliberately lane-flavoured player input: the anxious run trips
# attachment.detect() and should pull the anxious variants of the lane beats.
LINES = {
    "secure": ["I had a good day, actually. Tell me about you.",
               "I understand. I think we can take our time with this.",
               "Thank you for saying that — I care about you and I wanted you to know.",
               "How was your day? I'd love to hear the real version."],
    "anxious": ["are you still there?", "did i do something wrong?",
                "please don't leave. i'm scared you'll get bored of me",
                "do you still like me? reassure me"],
    "avoidant": ["whatever, it doesn't matter", "i'm fine on my own, don't worry about me",
                 "never mind, it's nothing", "i need space, this is moving too fast"],
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8931)
    ap.add_argument("--route", default="ethan")
    ap.add_argument("--lane", default="secure", choices=list(LINES))
    ap.add_argument("--pick", type=int, default=0)
    args = ap.parse_args()
    base = f"http://127.0.0.1:{args.port}"

    pid = f"probe-{int(time.time())}"
    hist, state, aff = [], {}, 0
    lane_seen, cgs, cleared, t0 = set(), [], [], time.time()

    for turn in range(300):
        # interaction_signals() penalises verbatim repetition, so a probe that
        # loops four lines stalls the affection curve forever — which is correct
        # behaviour for a player who says the same thing all night, and useless
        # as a test. Vary the tail.
        msg = LINES[args.lane][turn % len(LINES[args.lane])] + f" ({turn})"
        r = post(base, "/say", {"route": args.route, "history": hist, "message": msg,
                                "affection": aff, "lang": "en", "pid": pid,
                                "story_state": state})
        if r.get("error"):
            sys.exit("say error: " + r["error"])
        if not r.get("static"):
            sys.exit("route did not take the static path — a model would have been called")
        hist += [{"role": "user", "content": msg}, {"role": "assistant", "content": r["reply"]}]
        aff, state = r["affection"], r.get("story_state", state)
        if r.get("attach"):
            lane_seen.add(r["attach"]["type"])
        if r.get("cg"):
            cgs.append(("affection-60", r["cg"]))
            print(f"  CG  affection crossed 60 -> {r['cg']}")
        story = r.get("story") or {}
        if not r["reply"]:
            sys.exit(f"empty turn at {story.get('chapter_index')}")

        choice = story.get("choice")
        if not choice:
            continue

        idx = min(args.pick, len(choice["options"]) - 1)
        c = post(base, "/choose", {"route": args.route, "chapter": choice["chapter"],
                                   "choice": choice["id"], "option": idx, "affection": aff,
                                   "story_state": state, "lang": "en",
                                   "lane": (r.get("attach") or {}).get("type", "")})
        aff, state = c["affection"], c["story_state"]
        if c.get("cg"):
            cgs.append(("affection-60(choice)", c["cg"]))
            print(f"  CG  affection crossed 60 on a choice -> {c['cg']}")
        if c.get("chapter_clear"):
            rw = c["chapter_clear"]["reward"]
            cleared.append(c["chapter_clear"]["chapter"])
            print(f"  CLEAR {c['chapter_clear']['chapter']}  reward={rw['kind']}  cg={rw.get('cg')}")
            if rw.get("cg"):
                cgs.append(("chapter-clear", rw["cg"]))
            n = post(base, "/continue", {"route": args.route, "story_state": state, "lang": "en"})
            if n.get("error"):
                sys.exit("continue error: " + n["error"])
            state, hist = n["story_state"], []
        if c.get("ending"):
            e = c["ending"]
            print(f"  ENDING {e['id']}  cg={e.get('cg')}")
            if e.get("cg"):
                cgs.append(("ending", e["cg"]))
            print(f"\nroute={args.route} lane={args.lane} pick={args.pick} "
                  f"turns={turn + 1} aff={aff} flags={state.get('flags')}")
            print(f"chapters cleared: {cleared}")
            print(f"CGs earned: {cgs}")
            print(f"attachment lanes observed: {sorted(lane_seen) or ['unknown']}")
            print(f"wall clock: {time.time() - t0:.1f}s for {turn + 1} turns "
                  f"({(time.time() - t0) / (turn + 1) * 1000:.0f} ms/turn, no GPU)")
            return
    sys.exit("never reached an ending")


if __name__ == "__main__":
    main()
