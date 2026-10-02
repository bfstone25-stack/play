#!/usr/bin/env python3
"""Nights 2-5 of the Elena RPG: rooms, hotspots, standoffs and events, with the VN's chapter
text pulled in by source range ({"rpy": "chN:a-b"} -> tools/rpy2events.py) so the writing is
the VN's own. Night 1 is hand-written JSON (data/nights/night1.json) and is left alone.

    python3 tools/build_nights.py   -> data/nights/night2..5.json
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from rpy2events import compile_range  # noqa: E402

OUT = HERE.parent / "data/nights"


def rpy(spec):
    ch, rng = spec.split(":")
    a, b = rng.split("-")
    return compile_range(int(ch[2:]), int(a), int(b))


def say(who, key):
    return {"say": who, "key": key}


def gate(trust, spec_or_steps, hint):
    steps = rpy(spec_or_steps) if isinstance(spec_or_steps, str) else spec_or_steps
    return {"if_trust": trust, "then": steps, "else": [say("narrator", hint)]}


def expand(steps):
    out = []
    for s in steps:
        if "rpy" in s:
            out.extend(rpy(s["rpy"]))
        else:
            out.append(s)
    return out


def door(i, to, pos, **kw):
    return {"id": i, "kind": "door", "to": to, "pos": pos, **kw}


def search(i, pos, event, **kw):
    return {"id": i, "kind": "search", "pos": pos, "event": event, **kw}


def enemy(i, e, pos, pre, post, **kw):
    return {"id": i, "kind": "enemy", "enemy": e, "pos": pos, "event": pre, "after": post, **kw}


MOOD = {
    "vault": {"ambient": "#5e5868", "lamps": [[0.32, 0.48, 1.0, "#ffb050"]]},
    "corridor": {"ambient": "#8a6f60", "lamps": [[0.1, 0.62, 0.9, "#ffb060"], [0.44, 0.7, 0.9, "#ffb060"]]},
    "dock": {"ambient": "#5d6474", "lamps": [[0.8, 0.2, 0.9, "#c0d0ff"]]},
    "cellar": {"ambient": "#5d6474", "lamps": [[0.85, 0.2, 0.8, "#c0d0ff"]]},
    "study": {"ambient": "#7d7480", "lamps": [[0.69, 0.47, 0.9, "#ffc070"]]},
    "deans_corridor": {"ambient": "#7a7480", "lamps": [[0.5, 0.2, 1.0, "#ffd090"]]},
    "reading_room": {"ambient": "#8a7a78", "lamps": [[0.7, 0.3, 1.0, "#ffd090"]]},
    "common_room": {"ambient": "#7a6e78", "lamps": [[0.72, 0.3, 1.0, "#ffc070"]]},
    "annex": {"ambient": "#6a6070", "lamps": [[0.3, 0.45, 1.0, "#ffb050"]]},
    "deans_office": {"ambient": "#7d7480", "lamps": [[0.4, 0.45, 0.9, "#ffc070"]]},
    "carrel": {"ambient": "#8a8496", "lamps": [[0.5, 0.3, 1.0, "#ffd0a0"]]},
    "stair": {"ambient": "#6f7486", "lamps": [[0.5, 0.4, 0.9, "#ffc080"]]},
    "muniment": {"ambient": "#6a7068", "lamps": [[0.6, 0.35, 1.0, "#c0ffc0"]]},
}


def room(name_key, plate, hotspots, enter=None, music="explore"):
    r = {"name_key": name_key, "plate": plate, "music": music, "mood": MOOD.get(plate, {}), "hotspots": hotspots}
    if enter:
        r["enter_event"] = enter
    return r


NIGHTS = {}

# ------------------------------------------------------------------------------ night 2
NIGHTS["night2"] = {
    "id": "night2", "title_key": "n2_title", "sub_key": "n2_sub", "turns": 30, "clock_start": 341, "minutes_per_turn": 12,
    "start_room": "vault", "start_event": "n2_open",
    "map": {"image": "blackwood", "rooms": {"vault": [0.85, 0.72], "corridor": [0.42, 0.2], "dock": [0.2, 0.72], "cellar": [0.5, 0.72], "study": [0.14, 0.2]}},
    "rooms": {
        "vault": room("r_vault", "vault", [door("to_corridor", "corridor", [0.1, 0.86])]),
        "corridor": room("r_corridor", "corridor", [
            enemy("vey", "vey", [0.6, 0.5], "n2_vey_pre", "n2_vey_post"),
            search("phone", [0.25, 0.4], "n2_phone", label_key="hs_lodge_phone", xp=10, gives=["porter_rota"]),
            search("keys", [0.8, 0.35], "n2_keys", label_key="hs_lodge", gives=["keyring"], **{"if_flag": "vey_done"}),
            door("to_vault", "vault", [0.1, 0.86]),
            door("to_dock", "dock", [0.9, 0.86], if_flag="vey_done"),
        ], enter="n2_lodge"),
        "dock": room("r_dock", "dock", [
            enemy("hollis", "hollis", [0.55, 0.5], "n2_hollis_pre", "n2_hollis_post"),
            search("manifest", [0.2, 0.45], "n2_manifest", label_key="hs_manifest", xp=10),
            search("window", [0.8, 0.25], "n2_window", label_key="hs_window2", gives=["tea"]),
            {"id": "trolley", "kind": "event", "pos": [0.45, 0.68], "event": "n2_swap", "label_key": "hs_trolley", "if_flag": "hollis_done"},
            enemy("grice", "grice", [0.7, 0.5], "n2_grice_pre", "n2_grice_post", if_flag="swapped"),
            door("to_corridor", "corridor", [0.1, 0.86]),
            door("to_cellar", "cellar", [0.9, 0.86], if_flag="grice_done"),
        ], enter="n2_dock"),
        "cellar": room("r_cellar", "cellar", [
            enemy("crane", "crane", [0.55, 0.45], "n2_crane_pre", "n2_crane_post"),
            door("to_dock", "dock", [0.1, 0.86], if_not_flag="crane_done"),
            door("to_study", "study", [0.9, 0.86], if_flag="crane_done", label_key="hs_back"),
        ], enter="n2_coal"),
        "study": room("r_study", "study", [], enter="n2_end"),
    },
    "events": {
        "n2_open": [{"bg": "vault"}, {"music": "explore"}, {"rpy": "ch2:18-110"}, {"join": True},
                    {"show": ""}, say("narrator", "n2_plan_1")],
        "n2_lodge": [say("narrator", "n2_lodge_1")],
        "n2_vey_pre": [say("vey", "n2_vey_1"), say("narrator", "n2_vey_2")],
        "n2_vey_post": [say("narrator", "n2_vey_3"), {"flag": "vey_done"}],
        "n2_phone": [say("narrator", "n2_phone_1")],
        "n2_keys": [say("narrator", "n2_keyring_1")],
        "n2_dock": [{"rpy": "ch2:116-133"}, {"show": ""}],
        "n2_hollis_pre": [say("narrator", "n2_dock_hollis_1"), say("hollis", "n2_dock_hollis_2")],
        "n2_hollis_post": [{"flag": "hollis_done"}],
        "n2_manifest": [say("narrator", "n2_manifest_1")],
        "n2_window": [say("narrator", "n2_window_1")],
        "n2_swap": [say("narrator", "n2_trolley_1"), {"rpy": "ch2:135-159"}, {"show": ""}, {"flag": "swapped"}],
        "n2_grice_pre": [say("narrator", "n2_dock_grice_1"), say("elena", "n2_dock_grice_2")],
        "n2_grice_post": [{"flag": "grice_done"}],
        "n2_coal": [say("narrator", "n2_coal_1")],
        "n2_crane_pre": [say("narrator", "n2_crane_1"), say("crane", "n2_crane_2"), say("narrator", "n2_crane_3")],
        "n2_crane_post": [say("narrator", "n2_crane_4"), say("narrator", "n2_crane_5"), {"flag": "crane_done"}],
        "n2_end": [say("narrator", "n2_back_1"), {"rpy": "ch2:161-179"},
                   gate(5, "ch2:181-238", "n2_trust_hint"), {"hide_cg": True},
                   {"rpy": "ch2:240-249"}, {"show": ""}, {"end_night": True, "next": "night3"}],
    },
}

# ------------------------------------------------------------------------------ night 3
NIGHTS["night3"] = {
    "id": "night3", "title_key": "n3_title", "sub_key": "n3_sub", "turns": 26, "clock_start": 16 * 60, "minutes_per_turn": 15,
    "start_room": "study", "start_event": "n3_open",
    "map": {"image": "blackwood", "rooms": {"study": [0.14, 0.2], "deans_corridor": [0.42, 0.2], "reading_room": [0.7, 0.2], "common_room": [0.7, 0.72]}},
    "rooms": {
        "study": room("r_study", "study", [
            search("gift", [0.6, 0.66], "n3_gift", label_key="hs_desk", gives=["gift_pen", "evening"]),
            door("to_corridor", "deans_corridor", [0.9, 0.82]),
        ]),
        "deans_corridor": room("r_deans_corridor", "deans_corridor", [
            enemy("grice", "grice_n3", [0.55, 0.5], "n3_grice_pre", "n3_grice_post"),
            search("portraits", [0.25, 0.35], "n3_portraits", label_key="hs_portraits", xp=10),
            door("to_study", "study", [0.1, 0.86]),
            door("to_hall", "reading_room", [0.9, 0.86], if_flag="grice3_done"),
        ], enter="n3_corr"),
        "reading_room": room("r_reading_room", "reading_room", [
            enemy("sallis", "sallis", [0.55, 0.5], "n3_sallis_pre", "n3_sallis_post"),
            search("programme", [0.25, 0.6], "n3_programme", label_key="hs_programme", xp=10, gives=["survey"]),
            door("to_corridor", "deans_corridor", [0.1, 0.86]),
            door("to_common", "common_room", [0.9, 0.86], if_flag="sallis_done"),
        ], enter="n3_hall"),
        "common_room": room("r_common_room", "common_room", [
            enemy("ambrose", "ambrose", [0.4, 0.5], "n3_ambrose_pre", "n3_ambrose_post"),
            search("decanter", [0.75, 0.55], "n3_decanter", label_key="hs_decanter", gives=["brandy"]),
            enemy("penhallow", "penhallow_boss", [0.6, 0.45], "n3_pen_pre", "n3_pen_post", if_flag="ambrose_done"),
            door("to_hall", "reading_room", [0.1, 0.86], if_not_flag="pen3_done"),
        ], enter="n3_common"),
    },
    "events": {
        "n3_open": [{"bg": "study"}, {"music": "explore"}, {"rpy": "ch3:16-58"}, {"show": ""}, say("narrator", "n3_plan_1")],
        "n3_gift": [say("narrator", "n3_gift_1")],
        "n3_corr": [say("narrator", "n3_corr_1")],
        "n3_grice_pre": [say("narrator", "n3_grice_1"), say("grice", "n3_grice_2")],
        "n3_grice_post": [say("grice", "n3_grice_3"), {"flag": "grice3_done"}],
        "n3_portraits": [say("narrator", "n3_portraits_1")],
        "n3_hall": [say("narrator", "n3_hall_1"), {"rpy": "ch3:62-67"}],
        "n3_sallis_pre": [say("narrator", "n3_sallis_1"), say("sallis", "n3_sallis_2")],
        "n3_sallis_post": [say("sallis", "n3_sallis_3"), {"flag": "sallis_done"}],
        "n3_programme": [say("narrator", "n3_programme_1")],
        "n3_common": [say("narrator", "n3_common_1"), {"rpy": "ch3:69-70"}],
        "n3_ambrose_pre": [say("ambrose", "n3_ambrose_1")],
        "n3_ambrose_post": [say("ambrose", "n3_ambrose_2"), {"flag": "ambrose_done"}],
        "n3_decanter": [say("narrator", "n3_decanter_1")],
        "n3_pen_pre": [say("narrator", "n3_pen_pre_1"), {"rpy": "ch3:72-78"}],
        "n3_pen_post": [{"rpy": "ch3:80-101"}, {"show": ""}, {"flag": "pen3_done"}, {"event": "n3_end"}],
        "n3_end": [say("narrator", "n3_back_1"), {"bg": "study"}, {"rpy": "ch3:103-137"},
                   gate(7, "ch3:139-166", "n3_trust_hint"), {"hide_cg": True},
                   {"rpy": "ch3:167-183"}, {"show": ""}, {"end_night": True, "next": "night4"}],
    },
}

# ------------------------------------------------------------------------------ night 4
NIGHTS["night4"] = {
    "id": "night4", "title_key": "n4_title", "sub_key": "n4_sub", "turns": 26, "clock_start": 9 * 60, "minutes_per_turn": 15,
    "start_room": "study", "start_event": "n4_open",
    "map": {"image": "blackwood", "rooms": {"study": [0.14, 0.2], "deans_corridor": [0.42, 0.2], "annex": [0.7, 0.2], "deans_office": [0.7, 0.72], "carrel": [0.3, 0.72]}},
    "rooms": {
        "study": room("r_study", "study", [
            search("biscuits", [0.44, 0.52], "n4_biscuits", label_key="hs_tin", gives=["biscuits", "gown"]),
            door("to_corridor", "deans_corridor", [0.9, 0.82]),
        ]),
        "deans_corridor": room("r_deans_corridor", "deans_corridor", [
            enemy("vey", "vey_n4", [0.55, 0.5], "n4_vey_pre", "n4_vey_post"),
            search("desk", [0.25, 0.6], "n4_desk", label_key="hs_vey_desk", xp=10, if_flag="vey4_done"),
            door("to_study", "study", [0.1, 0.86], if_not_flag="tea_done"),
            door("to_annex", "annex", [0.9, 0.86], if_flag="vey4_done", if_not_flag="tea_done"),
            door("to_files", "deans_office", [0.5, 0.86], if_flag="tea_done"),
        ], enter="n4_corr"),
        "annex": room("r_annex", "annex", [
            enemy("hollis", "hollis_n4", [0.3, 0.5], "n4_hollis_pre", "n4_hollis_post"),
            search("fire", [0.75, 0.6], "n4_fire", label_key="hs_fireplace", xp=10, if_flag="hollis4_done"),
            enemy("dean", "dean_tea", [0.55, 0.45], "n4_tea_pre", "n4_tea_post", if_flag="hollis4_done"),
            door("to_corridor", "deans_corridor", [0.1, 0.86], if_flag="tea_done"),
        ], enter="n4_annex"),
        "deans_office": room("r_deans_office", "deans_office", [
            {"id": "files", "kind": "event", "pos": [0.4, 0.55], "event": "n4_files", "label_key": "hs_files"},
            enemy("crane", "crane_n4", [0.65, 0.45], "n4_crane_pre", "n4_crane_post", if_flag="files_done"),
            door("to_carrel", "carrel", [0.9, 0.86], if_flag="crane4_done"),
        ]),
        "carrel": room("r_carrel", "carrel", [], enter="n4_end"),
    },
    "events": {
        "n4_open": [{"bg": "study"}, {"music": "explore"}, {"rpy": "ch4:16-56"}, {"show": ""}],
        "n4_biscuits": [say("narrator", "n4_tin_1")],
        "n4_corr": [say("narrator", "n4_corr_1")],
        "n4_vey_pre": [say("narrator", "n4_vey_1"), say("vey", "n4_vey_2")],
        "n4_vey_post": [say("narrator", "n4_vey_3"), {"flag": "vey4_done"}],
        "n4_desk": [say("narrator", "n4_vey_3")],
        "n4_annex": [say("narrator", "n4_annex_1")],
        "n4_hollis_pre": [say("narrator", "n4_hollis_1")],
        "n4_hollis_post": [say("hollis", "n4_hollis_2"), {"flag": "hollis4_done"}],
        "n4_fire": [say("narrator", "n4_fire_1")],
        "n4_tea_pre": [{"rpy": "ch4:58-79"}],
        "n4_tea_post": [{"rpy": "ch4:81-102"}, {"show": ""}, {"flag": "tea_done"}],
        "n4_files": [say("narrator", "n4_files_1"), {"rpy": "ch4:104-157"}, {"hide_cg": True}, {"show": ""},
                     {"give": "plan_1994"}, {"give": "page_two"}, {"flag": "files_done"}],
        "n4_crane_pre": [say("narrator", "n4_crane_1"), say("crane", "n4_crane_2")],
        "n4_crane_post": [say("crane", "n4_crane_3"), {"flag": "crane4_done"}],
        "n4_end": [say("narrator", "n4_carrel_1"), say("narrator", "n4_window_1"),
                   gate(7, "ch4:159-208", "n4_trust_hint"), {"hide_cg": True},
                   {"rpy": "ch4:210-216"}, {"show": ""}, {"end_night": True, "next": "night5"}],
    },
}

# ------------------------------------------------------------------------------ night 5
ENDINGS = {
    "rewrite": ("ch5:111-130", "ch5:131-143", "ch5:144-157"),
    "expose": ("ch5:161-176", "ch5:177-187", "ch5:188-200"),
    "abscond": ("ch5:204-219", "ch5:220-230", "ch5:231-243"),
}
end_events = {}
for name, (pub, intimate, after) in ENDINGS.items():
    end_events["n5_end_" + name] = [{"rpy": pub}, gate(9, intimate, "n5_trust_hint"), {"hide_cg": True}, {"rpy": after}, {"show": ""}]

NIGHTS["night5"] = {
    "id": "night5", "title_key": "n5_title", "sub_key": "n5_sub", "turns": 26, "clock_start": 23 * 60, "minutes_per_turn": 15,
    "start_room": "cellar", "start_event": "n5_open",
    "map": {"image": "blackwood", "rooms": {"cellar": [0.2, 0.72], "stair": [0.5, 0.72], "muniment": [0.8, 0.72]}},
    "rooms": {
        "cellar": room("r_cellar", "cellar", [
            enemy("crane", "crane_n5", [0.55, 0.45], "n5_crane_pre", "n5_crane_post"),
            search("bricks", [0.25, 0.5], "n5_bricks", label_key="hs_bricks", xp=10, gives=["biscuits"], if_flag="crane5_done"),
            door("to_stair", "stair", [0.9, 0.86], if_flag="crane5_done"),
        ]),
        "stair": room("r_stair", "stair", [
            enemy("grice", "grice_n5", [0.55, 0.5], "n5_grice_pre", "n5_grice_post"),
            enemy("ambrose", "ambrose_n5", [0.35, 0.45], "n5_ambrose_pre", "n5_ambrose_post", if_flag="grice5_done"),
            door("to_cellar", "cellar", [0.1, 0.86]),
            door("to_muniment", "muniment", [0.9, 0.86], if_flag="ambrose5_done"),
        ], enter="n5_stair"),
        "muniment": room("r_muniment", "muniment", [], enter="n5_muniment"),
    },
    "events": {
        "n5_open": [{"bg": "cellar"}, {"music": "explore"}, {"rpy": "ch5:19-33"}, {"show": ""}],
        "n5_crane_pre": [say("narrator", "n5_crane_1"), say("crane", "n5_crane_2")],
        "n5_crane_post": [say("narrator", "n5_crane_3"), {"flag": "crane5_done"}],
        "n5_bricks": [say("narrator", "n5_bricks_1"), {"rpy": "ch5:35-37"}],
        "n5_stair": [say("narrator", "n5_stair_1")],
        "n5_grice_pre": [say("narrator", "n5_grice_1"), say("grice", "n5_grice_2")],
        "n5_grice_post": [say("grice", "n5_grice_3"), {"flag": "grice5_done"}],
        "n5_ambrose_pre": [say("narrator", "n5_ambrose_1"), say("ambrose", "n5_ambrose_2")],
        "n5_ambrose_post": [say("ambrose", "n5_ambrose_3"), {"flag": "ambrose5_done"}],
        "n5_muniment": [{"rpy": "ch5:42-85"}, say("narrator", "n5_pen_pre_1"), {"battle": "penhallow_final"},
                        {"show": "dean_holloway", "x": 0.3}, say("narrator", "n5_pen_post_1"), {"rpy": "ch5:90-107"},
                        {"if_flag": "ending_rewrite", "then": [{"event": "n5_end_rewrite"}],
                         "else": [{"if_flag": "ending_expose", "then": [{"event": "n5_end_expose"}],
                                   "else": [{"event": "n5_end_abscond"}]}]},
                        {"music": "title"}, {"bg": "study"}, {"rpy": "ch5:255-262"},
                        say("narrator", "credits_1"), say("narrator", "credits_2"), {"end_night": True, "next": ""}],
        **end_events,
    },
}


def walk(steps):
    out = []
    for s in steps:
        if "rpy" in s:
            out.extend(walk(rpy(s["rpy"])))
            continue
        s = dict(s)
        for k in ("then", "else"):
            if k in s:
                s[k] = walk(s[k])
        if "choice" in s:
            s["choice"] = [{**o, "do": walk(o.get("do", []))} for o in s["choice"]]
        out.append(s)
    return out


def main():
    for nid, n in NIGHTS.items():
        n["events"] = {k: walk(v) for k, v in n["events"].items()}
        (OUT / f"{nid}.json").write_text(json.dumps(n, ensure_ascii=False, indent=1))
        print(nid, len(n["rooms"]), "rooms", len(n["events"]), "events")


if __name__ == "__main__":
    main()
