#!/usr/bin/env python3
"""VESPER's nights: the prologue (choose whose night) and five per route (one per chapter).

Every chapter is explored on four painted rooms -- your flat, the city, the late café and the
chapter's own venue -- and the venue runs the parent's chapter in the parent's order:
opening on entry, then each beat as a hotspot, a date standoff with him after the first beat
(a rival boss before it in ch4), the fork's adult turn as an explicit Trust-gated choice with
its decline beside it (ch4 Trust 5, ch5 Trust 7), the chapter-end choices with his replies,
the ch2 CG at chapter clear, and in ch5 the ending the run has earned. All story text comes
from data/story (tools/import_story.py); the RPG's own writing is in tools/strings_*.py.

    python3 tools/build_nights.py   -> data/nights/*.json, data/story/rpg.json (menu JA)
"""
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
D = HERE.parent / "data"
OUT = D / "nights"
ROUTES = ["guyan", "ethan", "luxingye", "liam", "adrian", "fushen"]
RIVAL = {"ethan": "hale", "luxingye": "han", "guyan": "pratt", "liam": "morrow", "adrian": "sterling", "fushen": "fu_elder"}
STRANGER = {1: "doorman", 2: "paparazzo", 3: "columnist"}
HEAT_TRUST = {4: 5, 5: 7}
STAY = {4: ("Say yes. Go with him tonight.", "「はい」と言う。今夜、彼と一緒に行く。"),
        5: ("Say yes. Stay until morning.", "「はい」と言う。朝まで一緒にいる。")}
WARDROBE = {1: "dress", 2: "trench", 3: "slip", 4: None, 5: "his_shirt"}
DESK = {1: "notebook", 2: "umbrella", 3: "cake", 4: "wine", 5: "cake"}
MAP = {"home": [0.2, 0.72], "street": [0.47, 0.5], "cafe": [0.24, 0.26], "venue": [0.77, 0.32]}
MOOD = {"home": {"ambient": "#e0d4dc", "lamps": [[0.3, 0.45, 0.9, "#ffd8b0"]]},
        "street": {"ambient": "#c8c4dc", "lamps": [[0.7, 0.3, 1.0, "#ff90b0"], [0.2, 0.35, 0.8, "#ffd090"]]},
        "cafe": {"ambient": "#e4d8cc", "lamps": [[0.5, 0.25, 1.0, "#ffd8a0"]]},
        "venue": {"ambient": "#e0d8e0", "lamps": [[0.6, 0.3, 0.9, "#ffd0c0"]]}}


def load_routes_mod():
    spec = importlib.util.spec_from_file_location("sr", HERE / "strings_routes.py")
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def say(key, who="narrator"):
    return {"say": who, "key": key}


def lines(rng):
    return {"lines": rng}


def trust_delta(aff):
    """The parent's affection value of a choice -> Trust: its warmest answers (aff >= 5) +1,
    its cool ones (aff <= 2) -1, pushing him away (aff <= -3) -2, the middling ones 0. With a
    won date worth +1 per chapter, a player who always answers coolly ends under Trust 5 (the
    parent's low ending) and a warm one reaches 7+ (its best)."""
    if aff >= 5:
        return 1
    if aff <= -3:
        return -2
    if aff <= 2:
        return -1
    return 0


def option(o):
    do = []
    if o["flag"]:
        do.append({"flag": o["flag"]})
    t = trust_delta(o["aff"])
    if t:
        do.append({"trust": t})
    do.append(lines(o["reply"]))
    return {"menu": o["text_en"], "do": do}


def ending_steps(e, r):
    return [{"music": "ending"}, say("ev_ending"), {"cg": e["cg"]}, lines(e["range"]), {"flag": "ending_" + e["id"]},
            {"flag": "ending_rank_" + {1: "best", 2: "mid"}.get(e["priority"], "low")}, {"hide_cg": True}]


def endings(ri, r):
    es = sorted(ri["endings"], key=lambda e: e["priority"])
    best, mid, low = es[0], es[1], es[2]
    best_steps = ending_steps(best, r) + [say("vb_win_big_2")]
    mid_steps = ending_steps(mid, r)
    low_steps = ending_steps(low, r)
    # best: Trust 8 and one of the parent's flags; else the middle at Trust 5; else the low one
    chain = mid_steps
    for f in reversed(best["flags_any"]):
        chain = [{"if_flag": f, "then": best_steps, "else": chain}]
    return [{"if_trust": 8, "then": chain, "else": [{"if_trust": 5, "then": mid_steps, "else": low_steps}]}]


def room(rid, plate, hotspots, name_key, pose="", enter=None, music="explore"):
    r = {"name_key": name_key, "plate": plate, "music": music, "mood": MOOD[rid], "hotspots": hotspots, "heroine_pose": pose,
         "heroine_x": 0.74}
    if enter:
        r["enter_event"] = enter
    return r


def door(i, to, pos, **kw):
    return {"id": i, "kind": "door", "to": to, "pos": pos, **kw}


def search(i, pos, event, gives=(), xp=5, **kw):
    h = {"id": i, "kind": "search", "pos": pos, "event": event, "label_key": "hs_" + i, "xp": xp, **kw}
    if gives:
        h["gives"] = list(gives)
    return h


# ---------------------------------------------------------------- the date planner (otome sim)
# Each night starts at home with a plan: where to go first, how to be with him, and what you are
# wearing (the equipped outfit). His taste is a table per route, hinted by his schedule line;
# 2 of 3 right = a well-planned evening: Trust +1 and the date starts at his lower-guard variant.
TASTE = {  # route -> (first stop, approach, outfit)
    "guyan": ("cafe", "patient", "trench"), "ethan": ("straight", "sincere", "blouse"),
    "luxingye": ("walk", "playful", "dress"), "liam": ("walk", "playful", "blouse"),
    "adrian": ("straight", "sincere", "slip"), "fushen": ("cafe", "patient", "dress")}
STOPS = [("cafe", "Stop at the late café first.", "まず深夜のカフェに寄る。"),
         ("walk", "Take the long way through the city.", "遠回りして街を歩く。"),
         ("straight", "Go straight to him.", "まっすぐ彼のもとへ。")]
WAYS = [("playful", "Keep it light and playful.", "軽やかに、楽しく。"),
        ("sincere", "Be sincere; say what you mean.", "誠実に。思ったことを言う。"),
        ("patient", "Be patient; let him come to you.", "辛抱強く。彼が来るのを待つ。")]


def planner(r, c, menus):
    stop, way, wear = TASTE[r]
    for _, en, ja in STOPS + WAYS:
        menus[en] = ja
    steps = [say(f"pl_day_{c}"), say(f"pl_hint_{r}"), say("pl_q_stop"),
             {"choice": [{"menu": en, "auto_rank": 2 if k == stop else 0,
                          "do": ([{"flag": f"c{c}_pv"}, say("pl_fit")] if k == stop else [say("pl_miss")])} for k, en, _ in STOPS]},
             say("pl_q_way"),
             {"choice": [{"menu": en, "auto_rank": 2 if k == way else 0,
                          "do": ([{"flag": f"c{c}_pa"}, say("pl_fit")] if k == way else [say("pl_miss")])} for k, en, _ in WAYS]},
             {"if_equipped": wear, "then": [{"flag": f"c{c}_po"}, say("pl_wear_ok")], "else": [say("pl_wear_no")]}]
    good = [{"flag": f"plan{c}"}, say("pl_good"), {"trust": 1}, {"xp": 10}]
    bad = [say("pl_bad"), {"xp": 5}]
    # two of three: (pv and (pa or po)) or (pa and po)
    steps.append({"if_flag": f"c{c}_pv", "then": [{"if_flag": f"c{c}_pa", "then": good, "else": [{"if_flag": f"c{c}_po", "then": good, "else": bad}]}],
                  "else": [{"if_flag": f"c{c}_pa", "then": [{"if_flag": f"c{c}_po", "then": good, "else": bad}], "else": bad}]})
    steps.append({"flag": f"c{c}_planned"})
    return steps


def chapter_night(r, c, ri, menus):
    ch = ri["chapters"][c - 1]
    nid = f"{r}_c{c}"
    ev = {}
    # -------- home
    ev["w"] = [say("ev_wardrobe" if WARDROBE[c] else "ev_wardrobe_n")]
    ev["d"] = [say("ev_desk")]
    ev["plan"] = planner(r, c, menus)
    home = room("home", "v_home", [
        {"id": "plan", "kind": "event", "event": "plan", "pos": [0.56, 0.34], "label_key": "hs_plan"},
        door("out", "street", [0.14, 0.74], label_key="r_street"),
        search("wardrobe", [0.72, 0.46], "w", gives=[WARDROBE[c] or "coffee"]),
        search("desk", [0.42, 0.62], "d", gives=[DESK[c]]),
    ], "r_home")
    # -------- street
    st_hs = [door("home", "home", [0.12, 0.78], label_key="r_home"), door("cafe", "cafe", [0.3, 0.42], label_key="r_cafe")]
    if c in STRANGER:
        g = STRANGER[c]
        ev["stranger_after"] = [say("post_" + g), {"flag": f"c{c}_street"}]
        st_hs.append({"id": "stranger", "kind": "enemy", "enemy": f"{g}_{r}", "pos": [0.6, 0.6], "after": "stranger_after", "if_flag": f"c{c}_planned"})
        st_hs.append(door("venue", "venue", [0.86, 0.4], label_key=f"r_v_{r}_{c}", if_flag=f"c{c}_street"))
    else:
        ev["s"] = [say("ev_stall")]
        ev["k"] = [say("ev_kiosk")]
        st_hs.append(search("stall", [0.55, 0.62], "s", gives=["tea"]))
        st_hs.append(search("kiosk", [0.68, 0.5], "k", gives=["coffee"]))
        st_hs.append(door("venue", "venue", [0.86, 0.4], label_key=f"r_v_{r}_{c}", if_flag=f"c{c}_planned"))
    street = room("street", "v_street", st_hs, "r_street")
    # -------- café
    ev["cc"] = [say("ev_counter")]
    ev["cn"] = [say("ev_corner")]
    cafe_hs = [door("street", "street", [0.12, 0.78], label_key="r_street"),
               search("counter", [0.5, 0.5], "cc", gives=["macarons", "coffee"]),
               search("corner", [0.78, 0.6], "cn", gives=[f"ks_{r}_{c}"])]
    if c == 2:
        ev["b"] = [say("ev_board")]
        cafe_hs.append(search("board", [0.3, 0.38], "b", gives=[f"gift_{r}"]))
    cafe = room("cafe", "v_cafe", cafe_hs, "r_cafe")
    # -------- the venue: the chapter
    ev["open"] = [{"music": "venue"}, lines(ch["open"]), {"flag": f"c{c}_venue"}]
    plain = [b for b in ch["beats"] if not b["heat"]]
    heat = [b for b in ch["beats"] if b["heat"]]
    seq = [("beat", plain[0])]
    if c == 4:
        seq.append(("rival", None))
    seq.append(("date", None))
    seq += [("beat", b) for b in plain[1:]]
    hs = []
    xs = [0.3, 0.42, 0.54, 0.3, 0.42, 0.54]
    ys = [0.42, 0.56, 0.42, 0.66, 0.7, 0.66]
    for i, (kind, b) in enumerate(seq):
        cond = {"if_flag": f"c{c}_s{i}"} if i else {"if_flag": f"c{c}_venue"}
        pos = [xs[i], ys[i]]
        if kind == "beat":
            ev[f"beat{i}"] = [lines(b["range"]), {"xp": 10}, {"flag": f"c{c}_s{i + 1}"}]
            hs.append({"id": f"beat{i}", "kind": "event", "event": f"beat{i}", "pos": pos, "label_key": f"hs_b{min(3, 1 + sum(1 for k, _ in seq[:i] if k == 'beat'))}", **cond})
        elif kind == "date":
            ev[f"after{i}"] = [say(f"vb_stage_{min(c, 4)}" if c < 5 else "vb_win_big_1"), {"flag": f"c{c}_s{i + 1}"}]
            ev[f"date{i}"] = [{"if_flag": f"plan{c}", "then": [{"battle": f"date_{r}_{c}_p"}], "else": [{"battle": f"date_{r}_{c}"}]},
                              {"event": f"after{i}"}]
            hs.append({"id": f"date{i}", "kind": "event", "event": f"date{i}", "pos": pos, "label_key": f"e_date_{r}_{c}", "turns": 2, **cond})
        else:
            rv = RIVAL[r]
            ev[f"after{i}"] = [say("post_" + rv), {"flag": f"c{c}_s{i + 1}"}]
            hs.append({"id": f"rival{i}", "kind": "enemy", "enemy": f"rival_{r}", "pos": pos, "after": f"after{i}", **cond})
    end = []
    choices = [dict(cj, options=[o for o in cj["options"] if not (o["added"] and o["flag"].startswith("slow_"))]) for cj in ch["choices"]]
    slow = [o for cj in ch["choices"] for o in cj["options"] if o["added"] and o["flag"].startswith("slow_")]
    if heat:
        assert len(heat) == 1 and len(slow) == 1, (nid, heat, slow)
        hb, so = heat[0], slow[0]
        need = HEAT_TRUST[c]
        menus[STAY[c][0]] = STAY[c][1]
        yes = [{"music": "intimate"}, lines(hb["range"])]
        if c == 4:
            yes.insert(1, {"cg": ri["cg_heat"]})
        yes += [{"flag": f"heat_c{c}"}, {"hide_cg": True}, {"music": "venue"}]
        end += [say("ev_heat_gate"), {"if_trust": need, "then": [], "else": [say("ev_heat_locked")]},
                {"choice": [{"menu": STAY[c][0], "req_trust": need, "auto_rank": 2, "do": yes},
                            {"menu": so["text_en"], "auto_rank": 1, "do": [{"flag": so["flag"]}, lines(so["reply"])]}]}]
    for cj in choices:
        end += [lines(cj["prompt"]), {"choice": [option(o) for o in cj["options"]]}]
    if ch["cg"]:
        end += [{"cg": ch["cg"]}, say("ev_chapter_cg"), {"hide_cg": True}]
    if c < 5:
        end += [say("vb_unlock_1"), {"end_night": True, "next": f"{r}_c{c + 1}"}]
    else:
        end += endings(ri, r) + [{"end_night": True, "next": ""}]
    ev["end"] = end
    hs.append({"id": "end", "kind": "event", "event": "end", "pos": [0.66, 0.56], "label_key": "hs_end", "if_flag": f"c{c}_s{len(seq)}"})
    hs.insert(0, door("street", "street", [0.1, 0.8], label_key="r_street"))
    venue = room("venue", f"v_{r}_{c}", hs, f"r_v_{r}_{c}", pose=f"{r}_smile", enter="open", music="venue")
    ev["start"] = [say(["vb_idle_2", "hb_open_2", "hb_open_1", "vb_idle_1", "hb_open_2"][c - 1])]
    rooms = {"home": home, "street": street, "cafe": cafe, "venue": venue}
    return {"id": nid, "title_key": f"nt_{r}_{c}", "sub_key": f"ns_{r}_{c}", "turns": 24, "clock_start": 19 * 60 + 30,
            "minutes_per_turn": 15, "start_room": "home", "start_event": "start",
            "map": {"image": "city", "rooms": {k: MAP[k] for k in rooms}}, "rooms": rooms, "events": ev}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for f in OUT.glob("*.json"):
        f.unlink()
    idx = json.loads((D / "story_index.json").read_text())
    sr = load_routes_mod()
    menus = {}
    opts = []
    for r in ROUTES:
        en, ja = sr.R[r]["pick"]
        menus[en] = ja
        opts.append({"menu": en, "if_night": f"{r}_c1",
                     "do": [{"flag": "r_" + r}, {"join": True}, say("ev_route_joined"), {"end_night": True, "next": f"{r}_c1"}]})
    pro = {"id": "prologue", "title_key": "nt_prologue", "sub_key": "ns_prologue", "turns": 24, "clock_start": 19 * 60,
           "minutes_per_turn": 15, "start_room": "home", "start_event": "start",
           "map": {"image": "city", "rooms": {"home": MAP["home"]}},
           "rooms": {"home": room("home", "v_home", [], "r_home")},
           "events": {"start": [say("ev_pro_1"), say("ev_pro_2"), say("ev_pro_3"), {"choice": opts}]}}
    (OUT / "prologue.json").write_text(json.dumps(pro, ensure_ascii=False, indent=1))
    n = 1
    for r in ROUTES:
        for c in range(1, 6):
            night = chapter_night(r, c, idx[r], menus)
            (OUT / f"{night['id']}.json").write_text(json.dumps(night, ensure_ascii=False, indent=1))
            n += 1
    (D / "story/rpg.json").write_text(json.dumps({"lines": [], "menus": menus}, ensure_ascii=False, indent=1))
    print(f"build_nights: {n} nights, {len(menus)} translated menus")


if __name__ == "__main__":
    main()
