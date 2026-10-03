#!/usr/bin/env python3
"""The three cases and the epilogue of the Confession Room RPG: rooms, hotspots, standoffs
and events, with the VN's text pulled in by story range (data/story/*.json, see
tools/import_story.py) so the writing is the VN's own.

The VN's loop -- ask (1 question), press (2 questions, pressure +1, new lines open), the
optional route behind pressure 3, the accusation (who + which line) -- becomes:
  * every testimony is an "Ask" hotspot in that suspect's interview room (1 move); the lines
    a suspect only gives under pressure appear once that pressure flag is set;
  * pressing is a standoff against the suspect (2 moves); winning sets c<case>_<sid>_p<n>
    and raises that suspect's Trust; the guilty suspect's pressure-3 standoff is the boss;
  * "Close the door" (the optional, consensual adult route) opens at pressure 3 and needs
    Trust 3 / 5 / 7 with that suspect in cases 1 / 2 / 3; it ends with a fact on the board;
  * "Name someone" at your desk: who, then which heard line; clean / right-name / wrong
    endings from the VN, then the next case.
The 12-question budget is the night's move budget (the captain's shift).

    python3 tools/build_nights.py   -> data/nights/night1..3.json, epilogue.json
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "data/nights"
IX = json.loads((HERE.parent / "data/story/cases_index.json").read_text())
SUSPECTS = ("nikolai", "adaeze", "vee")
ROUTE_NEED = 99
ROUTE_TRUST = {1: 3, 2: 5, 3: 7}
# the nine routes in 02_interrogation.rpy, by source line; the route CG per case
ROUTE_LINES = {1: {"nikolai": "interr:159-169", "adaeze": "interr:172-183", "vee": "interr:186-195"},
               2: {"nikolai": "interr:214-225", "adaeze": "interr:228-240", "vee": "interr:243-256"},
               3: {"nikolai": "interr:265-276", "adaeze": "interr:279-290", "vee": "interr:293-304"}}
ROUTE_CG = {1: {s: f"cg_{s}_x" for s in SUSPECTS},
            2: {"nikolai": "cg_nikolai_x", "adaeze": "cg_trust5_adaeze", "vee": "cg_vee_x"},
            3: {"nikolai": "cg_trust7_nikolai", "adaeze": "cg_adaeze_x", "vee": "cg_vee_x"}}
ROUTE_FACT = {1: {"nikolai": "nik_curtain", "adaeze": "ade_seal", "vee": "vee_hands"},
              2: {"nikolai": "nik2_light", "adaeze": "ade2_mop", "vee": "vee2_seen"},
              3: {"nikolai": "nik3_tired", "adaeze": "ade3_office", "vee": "vee3_slow"}}
# the clean endings (03_board.rpy) per case: lines before the closing CG, the CG line
CLEAN = {1: ("board:154-158", "board:161-161"), 2: ("board:165-171", "board:174-174"), 3: ("board:178-184", "board:187-187")}
LOCKER = {1: ("cg_evidence_x", "start:123-125", "photo1"), 2: ("cg_evidence2_x", "start:127-129", "photo2"),
          3: ("cg_evidence3_x", "start:131-133", "photo3")}
PRESS_PRE = {1: ["interr:103-103", "pb1_reply"], 2: ["interr:106-106", "pb2_reply", "interr:108-108"],
             3: ["interr:110-110", "pb3_reply", "interr:112-112"]}
MOOD = {
    "precinct": {"ambient": "#8a8ca0", "lamps": [[0.3, 0.45, 1.0, "#ffd28a"], [0.78, 0.3, 0.8, "#b0c8ff"]]},
    "corridor": {"ambient": "#8890a0", "lamps": [[0.5, 0.15, 1.3, "#d8e8ff"]]},
    "interview": {"ambient": "#7a8290", "lamps": [[0.5, 0.2, 1.1, "#ffe0a0"]]},
    "lockup": {"ambient": "#808898", "lamps": [[0.5, 0.2, 1.0, "#e0ecff"]]},
    "archive": {"ambient": "#88847c", "lamps": [[0.35, 0.35, 1.0, "#ffd890"]]},
    "morgue": {"ambient": "#8a98a8", "lamps": [[0.5, 0.2, 1.2, "#d0f0ff"]]},
    "alley": {"ambient": "#6e6a80", "lamps": [[0.2, 0.25, 1.0, "#ffb060"], [0.8, 0.35, 0.8, "#ff6080"]]},
    "club": {"ambient": "#786c80", "lamps": [[0.3, 0.4, 1.0, "#ff8060"], [0.75, 0.3, 0.9, "#ffc070"]]},
    "back_office": {"ambient": "#88807a", "lamps": [[0.45, 0.4, 1.0, "#ffd080"]]},
    "cooler": {"ambient": "#8aa0b0", "lamps": [[0.5, 0.15, 1.1, "#d8f0ff"]]},
    "loading_bay": {"ambient": "#7a8290", "lamps": [[0.7, 0.2, 1.1, "#ffd890"]]},
    "mop_room": {"ambient": "#8a8a80", "lamps": [[0.5, 0.15, 0.9, "#ffe0a0"]]},
    "fire_stairs": {"ambient": "#80848c", "lamps": [[0.25, 0.3, 0.9, "#ffd890"]]},
    "flat": {"ambient": "#6a6878", "lamps": [[0.75, 0.4, 0.9, "#ffb070"]]},
    "safe_house": {"ambient": "#7a7080", "lamps": [[0.3, 0.45, 1.1, "#ffc880"]]},
}


def say(who, key):
    return {"say": who, "key": key}


def door(i, to, pos, **kw):
    return {"id": i, "kind": "door", "to": to, "pos": pos, **kw}


def search(i, pos, event, **kw):
    return {"id": i, "kind": "search", "pos": pos, "event": event, **kw}


def enemy(i, e, pos, pre, post, **kw):
    return {"id": i, "kind": "enemy", "enemy": e, "pos": pos, "event": pre, "after": post, **kw}


def room(name_key, plate, hotspots, enter=None, music="explore"):
    r = {"name_key": name_key, "plate": plate, "music": music, "mood": MOOD.get(plate, {}), "hotspots": hotspots}
    if enter:
        r["enter_event"] = enter
    return r


def interview_rooms(c, events, lawyer=False):
    """Three interview rooms off the corridor; every testimony an Ask hotspot, three
    standoffs, the route behind pressure 3."""
    case = IX["cases"][c - 1]
    rooms = {}
    for sid in SUSPECTS:
        hs = []
        asks = [st for st in case["statements"] if st["who"] == sid and st["need"] != ROUTE_NEED]
        cols = [0.17, 0.5, 0.83]
        for k, st in enumerate(asks):
            kw = {"turns": 1}
            if st["need"] > 0:
                kw["if_flag"] = f"c{c}_{sid}_p{st['need']}"
            hs.append({"id": st["id"], "kind": "event", "pos": [cols[k % 3], 0.26 + 0.11 * (k // 3)], "event": "ask_" + st["id"],
                       "label_key": "hs_ask_" + st["id"], **kw})
            events["ask_" + st["id"]] = [{"show": sid, "x": 0.72}, {"lines": f"cases:{st['src']}-{st['src']}"},
                                         {"flag": "heard_" + st["id"]}, {"xp": 4}]
            if st["id"] == case["decisive"]:
                events["ask_" + st["id"]].append({"flag": f"c{c}_decisive_heard"})
        for p in (1, 2, 3):
            kw = {"turns": 2, "label_key": f"hs_press_{sid}_{p}"}
            if p > 1:
                kw["if_flag"] = f"c{c}_{sid}_p{p - 1}"
            hs.append(enemy(f"press{p}", f"{sid}_c{c}_p{p}", [cols[(p - 1) % 3], 0.6], f"pb{p}_{sid}", f"pa{p}_c{c}_{sid}", **kw))
            pre = [{"show": sid, "x": 0.72}]
            for item in PRESS_PRE[p]:
                pre.append({"lines": item} if ":" in item else say(sid, item))
            events[f"pb{p}_{sid}"] = pre
            events[f"pa{p}_c{c}_{sid}"] = [{"flag": f"c{c}_{sid}_p{p}"}, say("narrator", f"pa_{p}")]
        # the optional route: consent first, Trust with this person, a fact at the end
        fact = ROUTE_FACT[c][sid]
        hs.append({"id": "route", "kind": "event", "pos": [0.5, 0.74], "event": f"route_c{c}_{sid}", "label_key": "hs_close_door",
                   "turns": 1, "if_flag": f"c{c}_{sid}_p3"})
        events[f"route_c{c}_{sid}"] = [{"show": sid, "x": 0.72}, {"lines": "interr:122-122"}, {"choice": [
            {"key": "ch_close_it", "req_trust": ROUTE_TRUST[c], "req_track": sid, "auto_rank": 2, "do": [
                {"music": "intimate"}, {"cg": ROUTE_CG[c][sid]}, {"lines": ROUTE_LINES[c][sid]},
                {"give": "fact_" + fact}, {"flag": "heard_" + fact}, {"trust": 1, "track": sid},
                {"hide_cg": True}, {"lines": "interr:198-198"}, {"flag": f"route_c{c}_{sid}"}, {"music": "explore"}]},
            {"key": "ch_leave_open", "auto_rank": 0, "do": [{"lines": "interr:127-127"}]}]}]
        doors = [door("to_corridor", "corridor", [0.1, 0.9])]
        rooms[f"interview_{sid}"] = room(f"r_interview_{sid}", "interview", hs + doors, enter=f"c{c}_{sid}_enter")
        events[f"c{c}_{sid}_enter"] = [{"show": sid, "x": 0.72}, {"lines": f"cases:{c * 1000 + SUSPECTS.index(sid) + 1}-{c * 1000 + SUSPECTS.index(sid) + 1}"}]
    return rooms


def accusation(c, events):
    """'Name someone': who, then which heard line (hidden until heard). Endings from the VN."""
    case = IX["cases"][c - 1]
    nxt = {1: "night2", 2: "night3", 3: "epilogue"}[c]
    events[f"c{c}_epilogue"] = [{"hide_cg": True}, {"show": ""},
                                {"if_flag": f"c{c}_cleared", "then": [say("narrator", "ep_closed")], "else": [say("narrator", "ep_open")]},
                                say("narrator", f"ep_next_c{c}"), {"end_night": True, "next": nxt}]
    who_opts = []
    for sid in SUSPECTS:
        why_opts = []
        for st in case["statements"]:
            if st["who"] != sid or st["need"] == 0:
                continue
            right = sid == case["solution"] and st["id"] == case["decisive"]
            if right:
                before, cg_line = CLEAN[c]
                do = [{"flag": f"c{c}_clean"}, {"flag": f"c{c}_cleared"}, {"flag": f"c{c}_done"}, {"hide_cg": True},
                      {"bg": "interview"}, {"music": "boss"}, {"show": sid, "x": 0.72}, {"lines": before}, {"show": ""},
                      {"cg": "cg_closing"}, {"lines": cg_line}, say("narrator", f"end_clean_c{c}"), {"xp": 150},
                      {"event": f"c{c}_epilogue"}]
            elif sid == case["solution"]:
                do = [{"flag": f"c{c}_cleared"}, {"flag": f"c{c}_done"}, {"hide_cg": True}, {"bg": "interview"},
                      {"lines": "board:197-198"}, {"xp": 60}, {"event": f"c{c}_epilogue"}]
            else:
                do = [{"flag": f"c{c}_done"}, {"hide_cg": True}, {"bg": "precinct"}, {"lines": "board:205-206"},
                      {"event": f"c{c}_epilogue"}]
            # the option shows the testimony itself (EN; the VN has no JA, so JA falls back)
            why_opts.append({"menu": next(l["en"] for l in LINES if l["id"] == st["id"]), "if_flag": "heard_" + st["id"],
                             "auto_rank": 3 if right else 0, "do": do})
        why_opts.append({"key": "acc_back", "auto_rank": 1, "do": [{"hide_cg": True}]})
        who_opts.append({"key": f"acc_who_{sid}", "auto_rank": 3 if sid == case["solution"] else 0,
                         "do": [say("narrator", "acc_why"), {"choice": why_opts}]})
    who_opts.append({"key": "acc_not_yet", "auto_rank": 1, "do": [{"hide_cg": True}]})
    events[f"c{c}_accuse"] = [{"cg": "cg_board"}, say("narrator", "acc_intro"), say("narrator", "acc_who"), {"choice": who_opts}]
    # one hotspot, at your desk; the sim leaves it for last (tests/sim.gd honours sim_last)
    return {"id": "board", "kind": "event", "pos": [0.5, 0.5], "event": f"c{c}_accuse", "label_key": "hs_board",
            "once": False, "if_not_flag": f"c{c}_done", "sim_last": True}


def locker(c, events):
    cg, lines, photo = LOCKER[c]
    events[f"c{c}_tray"] = [{"choice": [
        {"key": "ch_look", "auto_rank": 2, "do": [{"cg": cg}, {"lines": lines}, {"give": photo}, {"xp": 10}, {"hide_cg": True}]},
        {"key": "ch_leave_tray", "auto_rank": 0, "do": []}]}]
    return room("r_lockup", "lockup", [
        {"id": "tray", "kind": "event", "pos": [0.5, 0.5], "event": f"c{c}_tray", "label_key": "hs_tray", "turns": 1},
        door("to_corridor", "corridor", [0.1, 0.9])], enter=f"c{c}_lockup")


def casefile(c, events):
    base = c * 1000
    events[f"c{c}_file"] = [{"lines": f"cases:{base + 10}-{base + 14}"}, {"lines": "board:78-78"}]
    return search("casefile", [0.3, 0.5], f"c{c}_file", label_key="hs_casefile", xp=5)


LINES = json.loads((HERE.parent / "data/story/cases.json").read_text())["lines"]
NIGHTS = {}

# ------------------------------------------------------------------------------ night 1
ev = {}
rooms = {
    "precinct": room("r_precinct", "precinct", [
        casefile(1, ev),
        search("drawer", [0.7, 0.5], "n1_drawer", label_key="hs_drawer", gives=["notebook", "flask", "marker", "marker"]),
        accusation(1, ev),
        door("to_corridor", "corridor", [0.15, 0.9]), door("to_alley", "alley", [0.85, 0.9]),
    ]),
    "corridor": room("r_corridor", "corridor", [
        door("to_nik", "interview_nikolai", [0.2, 0.55]), door("to_ade", "interview_adaeze", [0.5, 0.55]), door("to_vee", "interview_vee", [0.8, 0.55]),
        door("to_lockup", "lockup", [0.8, 0.9]), door("to_precinct", "precinct", [0.15, 0.9]),
    ], enter="c1_corridor"),
    **interview_rooms(1, ev),
    "lockup": locker(1, ev),
    "alley": room("r_alley", "alley", [
        enemy("bouncer", "bouncer", [0.5, 0.5], "n1_bouncer_pre", "n1_bouncer_post", turns=2),
        search("dumpster", [0.2, 0.6], "n1_dumpster", label_key="hs_dumpster", gives=["lighter", "docket"]),
        search("yard_door", [0.8, 0.4], "n1_yard", label_key="hs_yard_door", xp=8),
        door("to_precinct", "precinct", [0.15, 0.9]), door("to_club", "club", [0.85, 0.9], if_flag="c1_bouncer"),
    ], enter="n1_alley"),
    "club": room("r_club", "club", [
        search("bar", [0.25, 0.5], "n1_bar", label_key="hs_bar", gives=["whisky"]),
        search("curtain", [0.55, 0.4], "n1_curtain", label_key="hs_curtain", xp=10),
        search("booth", [0.8, 0.6], "n1_booth", label_key="hs_booth", gives=["marker"]),
        door("to_alley", "alley", [0.15, 0.9]), door("to_office", "back_office", [0.5, 0.9]), door("to_cooler", "cooler", [0.85, 0.9]),
    ], enter="n1_club"),
    "back_office": room("r_back_office", "back_office", [
        search("desk", [0.3, 0.55], "n1_desk", label_key="hs_desk", gives=["key_list"]),
        search("safe", [0.75, 0.6], "n1_safe", label_key="hs_safe", gives=["alarm_log", "marker"]),
        search("blinds", [0.55, 0.3], "n1_blinds", label_key="hs_blinds", xp=6),
        door("to_club", "club", [0.15, 0.9]),
    ], enter="n1_office"),
    "cooler": room("r_cooler", "cooler", [
        search("rack", [0.5, 0.65], "n1_rack", label_key="hs_rack", gives=["shoe"], xp=12),
        door("to_club", "club", [0.15, 0.9]),
    ], enter="n1_cooler"),
}
ev.update({
    "n1_open": [{"bg": "precinct"}, {"music": "explore"}, {"lines": "start:27-28"}, say("narrator", "n1_open_1"), say("narrator", "n1_open_2")],
    "c1_corridor": [{"cg": "cg_intake"}, {"lines": "start:41-42"}, {"hide_cg": True}],
    "c1_lockup": [{"lines": "start:106-106"}],
    "n1_drawer": [say("narrator", "n1_drawer_1")],
    "n1_alley": [{"cg": "cg_rpg_paloma"}, say("narrator", "n1_alley_1"), {"hide_cg": True}],
    "n1_bouncer_pre": [{"show": "bouncer", "x": 0.7}, say("bouncer", "n1_bouncer_1")],
    "n1_bouncer_post": [{"flag": "c1_bouncer"}, say("narrator", "n1_bouncer_2"), {"show": ""}],
    "n1_dumpster": [say("narrator", "n1_dumpster_1")], "n1_yard": [say("narrator", "n1_yard_1")],
    "n1_club": [say("narrator", "n1_club_1")], "n1_bar": [say("narrator", "n1_bar_1")],
    "n1_curtain": [say("narrator", "n1_curtain_1")], "n1_booth": [say("narrator", "n1_booth_1")],
    "n1_office": [say("narrator", "n1_office_1")], "n1_desk": [say("narrator", "n1_desk_1")],
    "n1_safe": [say("narrator", "n1_safe_1")], "n1_blinds": [say("narrator", "n1_blinds_1")],
    "n1_cooler": [say("narrator", "n1_cooler_1")], "n1_rack": [say("narrator", "n1_rack_1")],
})
NIGHTS["night1"] = {
    "id": "night1", "title_key": "n1_title", "sub_key": "n1_sub", "turns": 92, "clock_start": 23 * 60 + 20, "minutes_per_turn": 5,
    "start_room": "precinct", "start_event": "n1_open",
    "map": {"image": "board", "rooms": {"precinct": [0.14, 0.22], "corridor": [0.38, 0.22], "interview_nikolai": [0.62, 0.12],
                                        "interview_adaeze": [0.62, 0.36], "interview_vee": [0.86, 0.22], "lockup": [0.38, 0.5],
                                        "alley": [0.14, 0.76], "club": [0.38, 0.76], "back_office": [0.62, 0.76], "cooler": [0.86, 0.76]}},
    "rooms": rooms, "events": ev,
}

# ------------------------------------------------------------------------------ night 2
ev = {}
rooms = {
    "precinct": room("r_precinct", "precinct", [
        casefile(2, ev),
        search("locker", [0.7, 0.5], "n2_locker", label_key="hs_locker", gives=["suit", "coffee"]),
        accusation(2, ev),
        door("to_corridor", "corridor", [0.15, 0.9]), door("to_archive", "archive", [0.5, 0.9]), door("to_alley", "alley", [0.85, 0.9]),
    ]),
    "corridor": room("r_corridor", "corridor", [
        door("to_nik", "interview_nikolai", [0.2, 0.55]), door("to_ade", "interview_adaeze", [0.5, 0.55]), door("to_vee", "interview_vee", [0.8, 0.55]),
        door("to_lockup", "lockup", [0.65, 0.9]), door("to_morgue", "morgue", [0.85, 0.9]), door("to_precinct", "precinct", [0.15, 0.9]),
    ]),
    **interview_rooms(2, ev),
    "lockup": locker(2, ev),
    "archive": room("r_archive", "archive", [
        search("books", [0.35, 0.5], "n2_books", label_key="hs_books", gives=["ledgers"], xp=10),
        search("file_drawer", [0.7, 0.6], "n2_filedrawer", label_key="hs_file_drawer", gives=["pen", "aspirin"]),
        door("to_precinct", "precinct", [0.15, 0.9]),
    ], enter="n2_archive"),
    "morgue": room("r_morgue", "morgue", [
        enemy("sergeant", "sergeant", [0.5, 0.45], "n2_sergeant_pre", "n2_sergeant_post", turns=2),
        search("drawer7", [0.75, 0.6], "n2_drawer7", label_key="hs_morgue_drawer", gives=["autopsy"], xp=12, if_flag="c2_sergeant"),
        door("to_corridor", "corridor", [0.15, 0.9]),
    ], enter="n2_morgue"),
    "alley": room("r_alley", "alley", [
        search("dumpster", [0.2, 0.6], "n2_dumpster", label_key="hs_dumpster", gives=["cigarettes"]),
        door("to_precinct", "precinct", [0.15, 0.9]), door("to_club", "club", [0.5, 0.9]), door("to_bay", "loading_bay", [0.85, 0.9]),
    ], enter="n2_alley"),
    "club": room("r_club", "club", [
        search("bar", [0.25, 0.5], "n2_bar", label_key="hs_bar", gives=["whisky"]),
        door("to_alley", "alley", [0.15, 0.9]), door("to_office", "back_office", [0.5, 0.9]),
    ]),
    "back_office": room("r_back_office", "back_office", [
        search("desk", [0.3, 0.55], "n2_desk", label_key="hs_desk", xp=8),
        search("safe", [0.75, 0.6], "n2_safe", label_key="hs_safe", xp=4),
        door("to_club", "club", [0.15, 0.9]),
    ]),
    "loading_bay": room("r_loading_bay", "loading_bay", [
        search("car", [0.4, 0.55], "n2_car", label_key="hs_car", xp=10, gives=["watch"]),
        search("bay_light", [0.75, 0.25], "n2_light", label_key="hs_bay_light", gives=["timer"], xp=8),
        door("to_alley", "alley", [0.15, 0.9]), door("to_mop", "mop_room", [0.85, 0.9]),
    ], enter="n2_bay"),
    "mop_room": room("r_mop_room", "mop_room", [
        search("sink", [0.5, 0.5], "n2_sink", label_key="hs_sink", gives=["sink_note"], xp=12),
        search("bucket", [0.25, 0.65], "n2_bucket", label_key="hs_bucket", gives=["marker"]),
        door("to_bay", "loading_bay", [0.15, 0.9]),
    ], enter="n2_mop"),
}
ev.update({
    "n2_open": [{"bg": "precinct"}, {"music": "explore"}, say("narrator", "n2_open_1"), say("narrator", "n2_open_2")],
    "c2_lockup": [{"lines": "start:106-106"}],
    "n2_locker": [say("narrator", "n2_locker_1")],
    "n2_archive": [say("narrator", "n2_archive_1")], "n2_books": [say("narrator", "n2_books_1")], "n2_filedrawer": [say("narrator", "n2_filedrawer_1")],
    "n2_morgue": [say("narrator", "n2_morgue_1")],
    "n2_sergeant_pre": [{"show": "sergeant", "x": 0.7}, say("sergeant", "n2_sergeant_1")],
    "n2_sergeant_post": [{"flag": "c2_sergeant"}, say("narrator", "n2_sergeant_2"), {"show": ""}],
    "n2_drawer7": [say("narrator", "n2_drawer7_1")],
    "n2_alley": [say("narrator", "n2_alley_1")], "n2_dumpster": [say("narrator", "n3_dumpster_1")],
    "n2_bar": [say("narrator", "n2_bar_1")], "n2_desk": [say("narrator", "n2_desk_1")], "n2_safe": [say("narrator", "n2_safe_1")],
    "n2_bay": [{"cg": "cg_rpg_bay"}, say("narrator", "n2_bay_1"), {"hide_cg": True}],
    "n2_car": [say("narrator", "n2_car_1")], "n2_light": [say("narrator", "n2_light_1")],
    "n2_mop": [say("narrator", "n2_mop_1")], "n2_sink": [say("narrator", "n2_sink_1")], "n2_bucket": [say("narrator", "n2_bucket_1")],
})
NIGHTS["night2"] = {
    "id": "night2", "title_key": "n2_title", "sub_key": "n2_sub", "turns": 104, "clock_start": 23 * 60, "minutes_per_turn": 5,
    "start_room": "precinct", "start_event": "n2_open",
    "map": {"image": "board", "rooms": {"precinct": [0.14, 0.22], "corridor": [0.38, 0.22], "interview_nikolai": [0.62, 0.1],
                                        "interview_adaeze": [0.62, 0.34], "interview_vee": [0.86, 0.1], "lockup": [0.86, 0.34],
                                        "archive": [0.14, 0.5], "morgue": [0.38, 0.5],
                                        "alley": [0.14, 0.78], "club": [0.38, 0.78], "back_office": [0.62, 0.78],
                                        "loading_bay": [0.86, 0.6], "mop_room": [0.86, 0.86]}},
    "rooms": rooms, "events": ev,
}

# ------------------------------------------------------------------------------ night 3
ev = {}
rooms = {
    "precinct": room("r_precinct", "precinct", [
        casefile(3, ev),
        search("drawer", [0.7, 0.5], "n3_drawer", label_key="hs_drawer", gives=["coffee", "coffee", "marker"]),
        accusation(3, ev),
        door("to_corridor", "corridor", [0.15, 0.9]), door("to_archive", "archive", [0.5, 0.9]), door("to_alley", "alley", [0.85, 0.9]),
    ]),
    "corridor": room("r_corridor", "corridor", [
        enemy("lawyer", "lawyer", [0.5, 0.4], "n3_lawyer_pre", "n3_lawyer_post", turns=2),
        door("to_nik", "interview_nikolai", [0.2, 0.6]), door("to_ade", "interview_adaeze", [0.5, 0.6], if_flag="c3_lawyer"),
        door("to_vee", "interview_vee", [0.8, 0.6]),
        door("to_lockup", "lockup", [0.8, 0.9]), door("to_precinct", "precinct", [0.15, 0.9]),
    ]),
    **interview_rooms(3, ev),
    "lockup": locker(3, ev),
    "archive": room("r_archive", "archive", [
        search("file_drawer", [0.7, 0.6], "n3_filedrawer", label_key="hs_file_drawer", gives=["aspirin", "marker"]),
        door("to_precinct", "precinct", [0.15, 0.9]),
    ]),
    "alley": room("r_alley", "alley", [
        search("yard_door", [0.8, 0.4], "n3_yard", label_key="hs_yard_door", gives=["vent_note"], xp=10),
        search("dumpster", [0.2, 0.6], "n3_dumpster", label_key="hs_dumpster", gives=["whisky"]),
        door("to_precinct", "precinct", [0.15, 0.9]), door("to_club", "club", [0.5, 0.9]), door("to_flat", "flat", [0.85, 0.9]),
    ]),
    "club": room("r_club", "club", [
        door("to_alley", "alley", [0.15, 0.9]), door("to_office", "back_office", [0.5, 0.9]), door("to_stairs", "fire_stairs", [0.85, 0.9]),
    ], enter="n3_club"),
    "back_office": room("r_back_office", "back_office", [
        search("safe", [0.75, 0.6], "n3_safe", label_key="hs_safe", gives=["safe_photo"], xp=12),
        search("desk", [0.3, 0.55], "n3_desk", label_key="hs_desk", xp=8),
        door("to_club", "club", [0.15, 0.9]),
    ]),
    "fire_stairs": room("r_fire_stairs", "fire_stairs", [
        search("landing", [0.5, 0.55], "n3_landing", label_key="hs_landing", gives=["folder"], xp=12),
        door("to_club", "club", [0.15, 0.9]),
    ], enter="n3_stairs"),
    "flat": room("r_flat", "flat", [
        search("window", [0.75, 0.35], "n3_window", label_key="hs_window", gives=["yard_light"], xp=10),
        search("sofa", [0.35, 0.6], "n3_sofa", label_key="hs_sofa", gives=["cufflinks"]),
        door("to_alley", "alley", [0.15, 0.9]),
    ], enter="n3_flat"),
}
ev.update({
    "n3_open": [{"bg": "precinct"}, {"music": "explore"}, say("narrator", "n3_open_1"), say("narrator", "n3_open_2")],
    "c3_lockup": [{"lines": "start:106-106"}],
    "n3_drawer": [say("narrator", "n3_drawer_1")],
    "n3_lawyer_pre": [{"show": "lawyer", "x": 0.7}, say("lawyer", "n3_lawyer_1")],
    "n3_lawyer_post": [{"flag": "c3_lawyer"}, say("narrator", "n3_lawyer_2"), {"show": ""}],
    "n3_filedrawer": [say("narrator", "n2_filedrawer_1")],
    "n3_yard": [say("narrator", "n3_yard_1")], "n3_dumpster": [say("narrator", "n3_dumpster_1")],
    "n3_club": [say("narrator", "n3_club_1")], "n3_safe": [say("narrator", "n3_safe_1")], "n3_desk": [say("narrator", "n3_desk_1")],
    "n3_stairs": [{"cg": "cg_rpg_stairs"}, say("narrator", "n3_stairs_1"), {"hide_cg": True}], "n3_landing": [say("narrator", "n3_landing_1")],
    "n3_flat": [say("narrator", "n3_flat_1")], "n3_window": [say("narrator", "n3_window_1")], "n3_sofa": [say("narrator", "n3_sofa_1")],
})
NIGHTS["night3"] = {
    "id": "night3", "title_key": "n3_title", "sub_key": "n3_sub", "turns": 104, "clock_start": 23 * 60, "minutes_per_turn": 5,
    "start_room": "precinct", "start_event": "n3_open",
    "map": {"image": "board", "rooms": {"precinct": [0.14, 0.22], "corridor": [0.38, 0.22], "interview_nikolai": [0.62, 0.1],
                                        "interview_adaeze": [0.62, 0.34], "interview_vee": [0.86, 0.1], "lockup": [0.86, 0.34],
                                        "archive": [0.14, 0.5],
                                        "alley": [0.14, 0.78], "club": [0.38, 0.78], "back_office": [0.62, 0.78],
                                        "fire_stairs": [0.86, 0.6], "flat": [0.86, 0.86]}},
    "rooms": rooms, "events": ev,
}

# ------------------------------------------------------------------------------ epilogue
ev = {}
visits = []
for sid, cg in (("nikolai", "cg_nikolai_x"), ("adaeze", "cg_adaeze_x"), ("vee", "cg_trust9_vee")):
    visits.append({"id": "visit_" + sid, "kind": "event", "pos": [{"nikolai": 0.2, "adaeze": 0.5, "vee": 0.8}[sid], 0.5],
                   "event": "ep_" + sid, "label_key": "hs_visit_" + sid, "turns": 1})
    ev["ep_" + sid] = [{"if_trust": 9, "track": sid, "then": [
        {"music": "intimate"}, {"show": sid, "x": 0.72}, say(sid, f"ep_{sid}_1"), say("narrator", f"ep_{sid}_2"),
        {"cg": cg}, say("narrator", f"ep_{sid}_3"), {"trust": 1, "track": sid}, {"flag": "ep_" + sid},
        {"hide_cg": True}, {"show": ""}, {"music": "dawn"}],
        "else": [say("narrator", f"ep_{sid}_no")]}]
rooms = {"safe_house": room("r_safe_house", "safe_house", visits + [
    {"id": "lamp", "kind": "event", "pos": [0.5, 0.78], "event": "ep_end", "label_key": "hs_end_run", "sim_last": True}], music="dawn")}
ev.update({
    "ep_open": [{"bg": "safe_house"}, {"music": "dawn"}, {"lines": "board:240-240"},
                {"if_flag": "c1_cleared", "then": [{"if_flag": "c2_cleared", "then": [{"if_flag": "c3_cleared", "then": [say("narrator", "ep_all")],
                 "else": [say("narrator", "ep_some")]}], "else": [say("narrator", "ep_some")]}], "else": [say("narrator", "ep_some")]},
                say("narrator", "ep_safe_1")],
    "ep_end": [say("narrator", "ep_lamp_1"), {"lines": "board:245-245"}, {"end_night": True, "next": ""}],
})
NIGHTS["epilogue"] = {
    "id": "epilogue", "title_key": "ep_title", "sub_key": "ep_sub", "turns": 12, "clock_start": 5 * 60, "minutes_per_turn": 5,
    "start_room": "safe_house", "start_event": "ep_open",
    "map": {"image": "board", "rooms": {"safe_house": [0.5, 0.5]}},
    "rooms": rooms, "events": ev,
}

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for nid, n in NIGHTS.items():
        (OUT / f"{nid}.json").write_text(json.dumps(n, indent=1, ensure_ascii=False))
        print(nid, len(n["rooms"]), "rooms", len(n["events"]), "events",
              sum(len(r["hotspots"]) for r in n["rooms"].values()), "hotspots")
