#!/usr/bin/env python3
"""The four 'nights' of the Room 704 RPG -- three shifts and the epilogue: rooms, hotspots,
standoffs and events, with the VN's act text pulled in by label ({"vn": "act1:start"} ->
tools/rpy2events.py) so the writing is the VN's own. The RPG writing between the VN beats
is in tools/strings_s*.py.

    python3 tools/build_nights.py   -> data/nights/shift1..3.json, epilogue.json
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from rpy2events import compile_label, compile_range  # noqa: E402

OUT = HERE.parent / "data/nights"


def say(who, key):
    return {"say": who, "key": key}


def N(*keys):
    return [say("narrator", k) for k in keys]


def door(i, to, pos, **kw):
    return {"id": i, "kind": "door", "to": to, "pos": pos, **kw}


def search(i, pos, event, **kw):
    return {"id": i, "kind": "search", "pos": pos, "event": event, **kw}


def enemy(i, e, pos, pre, post, **kw):
    return {"id": i, "kind": "enemy", "enemy": e, "pos": pos, "event": pre, "after": post, **kw}


def vn(label, cut=(), lines=None):
    ch = int(label.split(":")[0][3:])
    return compile_label(ch, label.split(":")[1], cut=cut, lines=lines)


def req_trust(steps, flag, trust, rank_yes=1, rank_no=0):
    """Choice options that set `flag` need Trust >= trust (the VN's 'say yes' becomes a Trust branch)."""
    out = []
    for s in steps:
        s = dict(s)
        if "choice" in s:
            opts = []
            for o in s["choice"]:
                o = dict(o)
                sets = any(d.get("flag") == flag for d in o.get("do", []) if isinstance(d, dict))
                if sets:
                    o["req_trust"] = trust
                    o["auto_rank"] = rank_yes
                else:
                    o["auto_rank"] = rank_no
                o["do"] = req_trust(o.get("do", []), flag, trust, rank_yes, rank_no)
                opts.append(o)
            s["choice"] = opts
        for k in ("then", "else"):
            if k in s:
                s[k] = req_trust(s[k], flag, trust, rank_yes, rank_no)
        out.append(s)
    return out


MOOD = {
    "lobby": {"ambient": "#8a8294", "lamps": [[0.3, 0.45, 1.0, "#ffd090"], [0.85, 0.3, 0.8, "#ff6070"]]},
    "corridor4": {"ambient": "#7a7080", "lamps": [[0.3, 0.3, 0.9, "#ffc080"], [0.75, 0.3, 0.7, "#ffc080"]]},
    "room704": {"ambient": "#8a8090", "lamps": [[0.25, 0.5, 1.0, "#ffd0a0"], [0.8, 0.3, 0.7, "#ff6070"]]},
    "back_office": {"ambient": "#8a8480", "lamps": [[0.4, 0.45, 1.0, "#ffd090"]]},
    "bar": {"ambient": "#8a7a70", "lamps": [[0.6, 0.35, 1.0, "#ffc070"]]},
    "kitchen": {"ambient": "#8a9098", "lamps": [[0.5, 0.2, 1.2, "#e0f0ff"]]},
    "service_stair": {"ambient": "#7a7a88", "lamps": [[0.5, 0.2, 0.9, "#ffd8a0"]]},
    "lift": {"ambient": "#8a8488", "lamps": [[0.5, 0.3, 1.0, "#ffd090"]]},
    "corridor_2": {"ambient": "#7a8078", "lamps": [[0.2, 0.3, 0.9, "#ffc080"], [0.7, 0.3, 0.9, "#ffc080"]]},
    "room_212": {"ambient": "#80808c", "lamps": [[0.5, 0.25, 0.9, "#ffe0b0"]]},
    "room_702": {"ambient": "#8a8088", "lamps": [[0.3, 0.5, 1.0, "#ffd0a0"]]},
    "linen": {"ambient": "#8a8880", "lamps": [[0.5, 0.3, 1.0, "#ffe0b0"]]},
    "roof": {"ambient": "#7880a0", "lamps": [[0.7, 0.25, 1.2, "#ff8090"], [0.2, 0.4, 0.8, "#c0d0ff"]]},
    "manager_flat": {"ambient": "#8a8078", "lamps": [[0.35, 0.5, 1.0, "#ffd090"]]},
    "boiler": {"ambient": "#8a7a70", "lamps": [[0.5, 0.35, 1.0, "#ffb060"]]},
    "laundry": {"ambient": "#8a9098", "lamps": [[0.5, 0.2, 1.2, "#e8f0ff"]]},
    "loading_bay": {"ambient": "#7a7a88", "lamps": [[0.7, 0.3, 0.9, "#ffc080"], [0.2, 0.5, 0.6, "#ff6070"]]},
    "street": {"ambient": "#8088a0", "lamps": [[0.6, 0.25, 1.1, "#ff6070"], [0.2, 0.3, 0.8, "#ffd090"]]},
}
MAP = {"street": [0.1, 0.62], "lobby": [0.3, 0.62], "back_office": [0.5, 0.62], "bar": [0.7, 0.62], "kitchen": [0.9, 0.62],
       "lift": [0.3, 0.42], "corridor_2": [0.5, 0.42], "room_212": [0.7, 0.42], "service_stair": [0.9, 0.42],
       "room_702": [0.3, 0.22], "corridor4": [0.5, 0.22], "room704": [0.7, 0.22], "linen": [0.9, 0.22],
       "manager_flat": [0.3, 0.06], "roof": [0.7, 0.06],
       "loading_bay": [0.3, 0.86], "boiler": [0.5, 0.86], "laundry": [0.7, 0.86]}


def room(rid, hotspots, enter=None, music="explore"):
    r = {"name_key": "r_" + rid, "plate": rid, "music": music, "mood": MOOD.get(rid, {}), "hotspots": hotspots}
    if enter:
        r["enter_event"] = enter
    return r


def night(nid, title, turns, clock, per, start_room, start_event, rooms, events):
    return {"id": nid, "title_key": title + "_title", "sub_key": title + "_sub", "turns": turns, "clock_start": clock,
            "minutes_per_turn": per, "start_room": start_room, "start_event": start_event,
            "map": {"image": "marbeck", "rooms": {r: MAP[r] for r in rooms}}, "rooms": rooms, "events": events}


NIGHTS = {}

# ------------------------------------------------------------------ shift 1: the front desk
# The VN's act 1 up to "She goes up", then the auditor's rounds, then the man from the car
# at the desk (the VN's visitor menu, then the boss standoff, then the VN's own aftermath).
s1_rooms = {
    "lobby": room("lobby", [
        search("register", [0.5, 0.62], "n1_register", label_key="hs_register", gives=["register_page"], xp=10),
        search("board", [0.8, 0.4], "n1_board", label_key="hs_board", xp=5),
        enemy("dace_phone", "dace_phone", [0.25, 0.55], "n1_phone_pre", "n1_phone_post", label_key="e_dace_phone", if_flag="lift_done"),
        {"id": "doors", "kind": "event", "pos": [0.15, 0.78], "event": "n1_gale", "label_key": "hs_doors", "if_flag": "car_seen"},
        door("to_office", "back_office", [0.62, 0.86]),
        door("to_bar", "bar", [0.85, 0.86]),
        door("to_lift", "lift", [0.38, 0.86]),
        door("to_stair", "service_stair", [0.1, 0.86], needs="passkey", locked_key="hs_locked_msg"),
        door("to_street", "street", [0.15, 0.28], turns=1),
    ]),
    "back_office": room("back_office", [
        search("keysafe", [0.3, 0.4], "n1_keysafe", label_key="hs_keysafe", gives=["passkey"], xp=5),
        search("cctv", [0.7, 0.35], "n1_cctv", label_key="hs_cctv", gives=["cctv_tape"], xp=10),
        search("kettle", [0.85, 0.6], "n1_kettle", label_key="hs_kettle", gives=["coffee"]),
        search("drawer", [0.5, 0.68], "n1_drawer", label_key="hs_drawer", gives=["revolver"], xp=5),
        search("ledger", [0.2, 0.6], "n1_ledger", label_key="hs_register", gives=["ledger704"], xp=15),
        door("to_lobby", "lobby", [0.1, 0.86]),
    ], enter="n1_office"),
    "bar": room("bar", [
        enemy("guest212", "guest212", [0.55, 0.5], "n1_g212_pre", "n1_g212_post"),
        search("bottles", [0.3, 0.35], "n1_bottles", label_key="hs_bottles", gives=["whisky"]),
        search("till", [0.75, 0.6], "n1_till", label_key="hs_till", gives=["cash", "cash"], if_flag="g212_done"),
        search("mirror", [0.5, 0.3], "n1_mirror", label_key="hs_mirror", xp=10),
        door("to_lobby", "lobby", [0.1, 0.86]),
        door("to_kitchen", "kitchen", [0.9, 0.86]),
    ], enter="n1_bar"),
    "kitchen": room("kitchen", [
        search("fridge", [0.25, 0.45], "n1_fridge", label_key="hs_fridge", gives=["minibar"]),
        search("pans", [0.6, 0.3], "n1_pans", label_key="hs_pans", xp=5),
        search("service_door", [0.85, 0.5], "n1_service", label_key="hs_service_door", xp=5),
        door("to_bar", "bar", [0.1, 0.86]),
    ], enter="n1_kitchen"),
    "lift": room("lift", [
        search("dial", [0.5, 0.25], "n1_dial", label_key="hs_dial", xp=5),
        search("gate", [0.5, 0.6], "n1_gate", label_key="hs_gate", xp=10),
        door("to_lobby", "lobby", [0.1, 0.86]),
        door("to_corridor2", "corridor_2", [0.9, 0.86], if_flag="lift_done"),
    ], enter="n1_lift"),
    "service_stair": room("service_stair", [
        search("footprints", [0.45, 0.6], "n1_footprints", label_key="hs_footprints", xp=10),
        search("landing", [0.7, 0.3], "n1_landing", label_key="hs_landing", xp=5),
        door("to_lobby", "lobby", [0.1, 0.86]),
        door("to_corridor2", "corridor_2", [0.9, 0.86]),
    ], enter="n1_stair"),
    "corridor_2": room("corridor_2", [
        enemy("haskell", "haskell", [0.55, 0.5], "n1_haskell_pre", "n1_haskell_post"),
        search("sconce", [0.25, 0.3], "n1_sconce", label_key="hs_sconce", xp=5),
        search("extinguisher", [0.8, 0.4], "n1_extinguisher", label_key="hs_extinguisher", gives=["torch"], if_flag="haskell_done"),
        door("to_stair", "service_stair", [0.1, 0.86]),
        door("to_lift", "lift", [0.4, 0.86]),
        door("to_212", "room_212", [0.9, 0.86], if_flag="haskell_done"),
    ], enter="n1_corr2"),
    "room_212": room("room_212", [
        search("dustsheet", [0.3, 0.6], "n1_dustsheet", label_key="hs_dustsheet", gives=["aspirin"]),
        {"id": "window212", "kind": "event", "pos": [0.7, 0.3], "event": "n1_window", "label_key": "hs_window212"},
        door("to_corridor2", "corridor_2", [0.1, 0.86]),
    ], enter="n1_212"),
    "street": room("street", [
        search("noodle", [0.75, 0.45], "n1_noodle", label_key="hs_noodle", gives=["coffee"]),
        search("car", [0.3, 0.55], "n1_car", label_key="hs_car", xp=10, if_flag="car_seen"),
        door("to_lobby", "lobby", [0.1, 0.86], turns=1),
    ], enter="n1_street"),
}
s1_events = {
    # the RPG's door CG goes in just before the VN's check-in CG
    "n1_open": [x for st in vn("act1:start") for x in ([{"cg": "cg_rpg_doors"}, {"say": "narrator", "key": "n1_doors_1"}, st] if st.get("cg") == "cg_checkin" else [st])] + [{"event": "vn_gives_key"}, {"hide_cg": True}, {"show": ""}] + N("n1_open_1", "n1_open_2", "n1_open_3"),
    "vn_ask_why": vn("act1:ask_why", cut=["gives_key"]),
    "vn_take_cash": vn("act1:take_cash", cut=["gives_key"]),
    "vn_by_the_book": vn("act1:by_the_book", cut=["gives_key"]),
    "vn_gives_key": vn("act1:gives_key", lines=(95, 105)),
    "n1_register": [{"cg": "cg_rpg_register"}] + N("n1_register_1", "n1_register_2") + [{"hide_cg": True}],
    "n1_board": N("n1_board_1", "n1_board_2"),
    "n1_office": N("n1_office_1"),
    "n1_keysafe": N("n1_keysafe_1"), "n1_cctv": N("n1_cctv_1"), "n1_kettle": N("n1_kettle_1"), "n1_drawer": N("n1_drawer_1"),
    "n1_ledger": N("n1_ledger_1", "n1_ledger_2"),
    "n1_bar": N("n1_bar_1"),
    "n1_g212_pre": N("n1_g212_1") + [say("guest212", "n1_g212_2")] + N("n1_g212_3", "n1_tutorial_1", "n1_tutorial_2"),
    "n1_g212_post": [say("guest212", "n1_g212_4"), {"flag": "g212_done"}],
    "n1_bottles": N("n1_bottles_1"), "n1_till": N("n1_till_1"), "n1_mirror": N("n1_mirror_1"),
    "n1_kitchen": N("n1_kitchen_1"), "n1_fridge": N("n1_fridge_1"), "n1_pans": N("n1_pans_1"), "n1_service": N("n1_service_locked"),
    "n1_lift": N("n1_lift_1", "n1_lift_2") + [{"flag": "lift_done"}],
    "n1_dial": N("n1_dial_1"), "n1_gate": N("n1_gate_1"),
    "n1_phone_pre": N("n1_phone_1") + [say("dace", "n1_phone_2")],
    "n1_phone_post": [say("dace", "n1_phone_3"), {"flag": "phone_done"}],
    "n1_stair": N("n1_stair_1"), "n1_footprints": N("n1_footprints_1"), "n1_landing": N("n1_landing_1"),
    "n1_corr2": N("n1_corr2_1"),
    "n1_haskell_pre": N("n1_haskell_1") + [say("haskell", "n1_haskell_2")] + N("n1_haskell_3"),
    "n1_haskell_post": [say("haskell", "n1_haskell_4")] + N("n1_haskell_5") + [{"flag": "haskell_done"}],
    "n1_sconce": N("n1_sconce_1"), "n1_extinguisher": N("n1_extinguisher_1"),
    "n1_212": N("n1_212_1"), "n1_dustsheet": N("n1_dustsheet_1"),
    "n1_window": [{"cg": "cg_rpg_car"}] + N("n1_window_1", "n1_window_2") + [{"hide_cg": True}, {"xp": 15}, {"flag": "car_seen"}],
    "n1_street": N("n1_street_1"), "n1_noodle": N("n1_noodle_1"), "n1_car": N("n1_car_1"),
    # the man from the car: VN lines 108-135 (his entrance + the visitor menu, jumps cut),
    # then the boss, then the VN's own aftermath for the route taken, then the phone call.
    "n1_gale": [{"hide_cg": True}, {"bg": "lobby"}] + compile_range(1, 108, 135, cut=["lie_to_him", "show_register", "stonewall"])
               + N("n1_gale_1", "n1_gale_2") + [{"battle": "gale"},
               {"if_flag": "route_cover", "then": vn("act1:lie_to_him", cut=["act1_end"]),
                "else": [{"if_flag": "route_sold", "then": vn("act1:show_register", cut=["act1_end"]), "else": vn("act1:stonewall", cut=["act1_end"])}]},
               {"flag": "gale_done"}, {"hide_cg": True}] + compile_range(1, 174, 177) + N("n1_end_1") + [{"end_night": True, "next": "shift2"}],
}
NIGHTS["shift1"] = night("shift1", "n1", 60, 2 * 60 + 14, 2, "lobby", "n1_open", s1_rooms, s1_events)

# ------------------------------------------------------------------ shift 2: the fourth floor
# Opens with the VN's act 2 up to "Sit down" (Mira joins), then the floor, the roof, Mrs
# Dace, the boss on the landing, and back in 704 the VN's chair/bed/window choice -- the
# intimate scene is the Trust 5 branch; below it, the VN's own decline.
s2_rooms = {
    "room704": room("room704", [
        search("bag", [0.3, 0.6], "n2_bag", label_key="hs_bag", gives=["train_ticket"], xp=5),
        search("window704", [0.8, 0.3], "n2_window704", label_key="hs_window704", xp=10),
        search("bathroom", [0.15, 0.4], "n2_bath", label_key="hs_bathroom", gives=["whisky"]),
        search("coat", [0.6, 0.45], "n2_coat", label_key="i_coat", gives=["coat"]),
        {"id": "bed704", "kind": "event", "pos": [0.5, 0.7], "event": "n2_sit", "label_key": "hs_bed704", "if_flag": "gale2_done"},
        door("to_corridor", "corridor4", [0.1, 0.86], if_not_flag="scene_done"),
    ], music="intimate"),
    "corridor4": room("corridor4", [
        enemy("haskell", "haskell_2", [0.55, 0.5], "n2_haskell_pre", "n2_haskell_post"),
        search("sconce", [0.3, 0.3], "n2_sconce4", label_key="hs_sconce", xp=5),
        enemy("gale", "gale_2", [0.45, 0.5], "n2_gale_pre", "n2_gale_post", if_flag="flat_done"),
        door("to_704", "room704", [0.9, 0.86]),
        door("to_702", "room_702", [0.25, 0.86], if_flag="haskell2_done"),
        door("to_linen", "linen", [0.6, 0.86], if_flag="haskell2_done"),
        door("to_lift", "lift", [0.1, 0.86]),
        door("to_stair", "service_stair", [0.42, 0.86]),
    ], enter="n2_corr"),
    "room_702": room("room_702", [
        search("newspapers", [0.3, 0.55], "n2_newspapers", label_key="hs_newspapers", gives=["cash"]),
        search("ashtray", [0.7, 0.4], "n2_ashtray", label_key="hs_ashtray", xp=10),
        search("suitcase", [0.5, 0.7], "n2_suitcase", label_key="hs_suitcase", gives=["shirt"], xp=5),
        door("to_corridor", "corridor4", [0.1, 0.86]),
    ], enter="n2_702"),
    "linen": room("linen", [
        search("towels", [0.3, 0.4], "n2_towels", label_key="hs_towels", gives=["robe"]),
        search("chute", [0.7, 0.55], "n2_chute", label_key="hs_chute", xp=10),
        door("to_corridor", "corridor4", [0.1, 0.86]),
        door("to_roof", "roof", [0.85, 0.25], label_key="hs_ladder"),
    ], enter="n2_linen"),
    "roof": room("roof", [
        enemy("constable", "constable", [0.4, 0.5], "n2_constable_pre", "n2_constable_post"),
        search("tank", [0.2, 0.35], "n2_tank", label_key="hs_tank", xp=5),
        search("sign", [0.75, 0.3], "n2_sign", label_key="hs_sign", xp=5),
        search("parapet", [0.6, 0.65], "n2_parapet", label_key="hs_parapet", xp=10, if_flag="constable_done"),
        door("to_linen", "linen", [0.1, 0.86], label_key="hs_ladder"),
    ], enter="n2_roof"),
    "lift": room("lift", [
        enemy("guest212", "guest212_2", [0.5, 0.5], "n2_g212_pre", "n2_g212_post"),
        search("dial", [0.5, 0.25], "n2_dial4", label_key="hs_dial", xp=5),
        door("to_corridor", "corridor4", [0.1, 0.86]),
    ], enter="n2_lift"),
    "service_stair": room("service_stair", [
        enemy("dace", "dace", [0.5, 0.45], "n2_dace_pre", "n2_dace_post", if_flag="roof_done"),
        door("to_corridor", "corridor4", [0.1, 0.86]),
        door("to_flat", "manager_flat", [0.75, 0.3], if_flag="dace_done"),
    ], enter="n2_stair"),
    "manager_flat": room("manager_flat", [
        search("cat", [0.35, 0.6], "n2_cat", label_key="hs_cat", xp=5),
        search("photos", [0.7, 0.35], "n2_photos", label_key="hs_photos", xp=15),
        search("nail", [0.15, 0.4], "n2_nail", label_key="hs_nail", gives=["basement_key"], xp=5),
        door("to_stair", "service_stair", [0.1, 0.86]),
    ], enter="n2_flat"),
}
s2_events = {
    "n2_open": vn("act2:act2", lines=(5, 52)) + [{"join": True}, {"show": "mira_neutral", "x": 0.7}] + N("n2_join_1") + [say("mira", "n2_join_3")] + N("n2_join_2", "n2_join_4") + [{"show": ""}],
    "n2_bag": N("n2_bag_1") + [say("mira", "n2_bag_2")], "n2_window704": N("n2_window704_1"), "n2_bath": N("n2_bath_1"),
    "n2_coat": N("n2_coat_1") + [say("mira", "n2_coat_2")],
    "n2_corr": N("n2_corr_1"),
    "n2_haskell_pre": [say("haskell", "n2_haskell_1")] + N("n2_haskell_2"),
    "n2_haskell_post": N("n2_haskell_3") + [{"flag": "haskell2_done"}],
    "n2_sconce4": N("n2_sconce4_1"),
    "n2_702": N("n2_702_1"), "n2_newspapers": N("n2_newspapers_1"), "n2_ashtray": N("n2_ashtray_1"), "n2_suitcase": N("n2_suitcase_1"),
    "n2_linen": N("n2_linen_1"), "n2_towels": N("n2_towels_1"), "n2_chute": N("n2_chute_1"),
    "n2_roof": N("n2_roof_1") + [{"cg": "cg_rpg_roof_city"}] + N("n2_roof_2") + [say("mira", "n2_roof_3"), {"hide_cg": True}, {"trust": 1}],
    "n2_constable_pre": N("n2_constable_1") + [say("constable", "n2_constable_2")] + N("n2_constable_3"),
    "n2_constable_post": N("n2_constable_4") + [{"flag": "constable_done"}, {"flag": "roof_done"}],
    "n2_tank": N("n2_tank_1"), "n2_sign": N("n2_sign_1"), "n2_parapet": N("n2_parapet_1"),
    "n2_lift": N("n2_lift_1"),
    "n2_g212_pre": [say("guest212", "n2_g212_1")],
    "n2_g212_post": N("n2_g212_2") + [{"flag": "g212b_done"}],
    "n2_dial4": N("n2_dial4_1"),
    "n2_stair": N("n2_stair_1") + [{"if_trust": 3, "then": [{"cg": "cg_trust3_stair"}] + N("n2_t3_1", "n2_t3_2") + [say("mira", "n2_t3_3"), {"hide_cg": True}],
                                   "else": N("n2_trust_hint")}],
    "n2_dace_pre": N("n2_dace_1") + [say("dace", "n2_dace_2")] + N("n2_dace_3"),
    "n2_dace_post": [say("dace", "n2_dace_4"), {"flag": "dace_done"}],
    "n2_flat": N("n2_flat_1"),
    "n2_cat": N("n2_cat_1") + [say("mira", "n2_cat_2")], "n2_photos": N("n2_photos_1", "n2_photos_2"),
    "n2_nail": N("n2_nail_1") + [{"flag": "flat_done"}],
    "n2_gale_pre": N("n2_gale_1") + [say("gale", "n2_gale_2")] + N("n2_gale_3"),
    "n2_gale_post": N("n2_gale_4") + [say("mira", "n2_gale_5"), {"flag": "gale2_done"}],
    # back in 704: the VN's choice. "Say yes" needs Trust 5; otherwise the VN's own decline.
    "n2_sit": N("n2_back_1") + req_trust(compile_range(2, 56, 69), "scene_yes", 5) + [{"flag": "scene_done"}, {"hide_cg": True}] + N("n2_after_1")
              + [{"end_night": True, "next": "shift3"}],
    "vn_act2_chair": req_trust(vn("act2:act2_chair"), "scene_yes", 5),
    "vn_act2_bed": req_trust(vn("act2:act2_bed"), "scene_yes", 5),
    "vn_act2_window": req_trust(vn("act2:act2_window"), "scene_yes", 5),
    "vn_act2_decline": vn("act2:act2_decline", cut=["act3"]) + N("n2_trust5_hint"),
    "vn_scene_bed": vn("act2:scene_bed", cut=["act3"]),
    "vn_scene_window": vn("act2:scene_window", cut=["act3"]),
}
NIGHTS["shift2"] = night("shift2", "n2", 56, 4 * 60 + 10, 2, "room704", "n2_open", s2_rooms, s2_events)

# ------------------------------------------------------------------ shift 3: six-forty
# The VN's morning (act 3 to "you watch her decide something"), the Trust 7 / 5 scenes, then
# the basement, the alley, Haskell with the register, Penhallow at the doors, and the
# ending the night has earned.
s3_rooms = {
    "room704": room("room704", [
        door("to_corridor", "corridor4", [0.1, 0.86]),
    ]),
    "corridor4": room("corridor4", [
        door("to_704", "room704", [0.9, 0.86]),
        door("to_stair", "service_stair", [0.42, 0.86]),
    ], enter="n3_corr"),
    "service_stair": room("service_stair", [
        door("to_corridor", "corridor4", [0.1, 0.86]),
        door("to_boiler", "boiler", [0.6, 0.7], needs="basement_key", locked_key="n1_service_locked"),
        door("to_lobby", "lobby", [0.9, 0.86], if_flag="haskell3_done"),
    ], enter="n3_stair"),
    "boiler": room("boiler", [
        search("gauges", [0.3, 0.35], "n3_gauges", label_key="hs_gauges", xp=10),
        search("pipes", [0.7, 0.5], "n3_pipes", label_key="hs_pipes", gives=["whisky"], xp=5),
        door("to_stair", "service_stair", [0.1, 0.86]),
        door("to_laundry", "laundry", [0.9, 0.86]),
    ], enter="n3_boiler"),
    "laundry": room("laundry", [
        enemy("dace", "dace_2", [0.5, 0.45], "n3_dace_pre", "n3_dace_post"),
        search("washers", [0.25, 0.5], "n3_washers", label_key="hs_washers", gives=["minibar"]),
        search("sheets", [0.75, 0.4], "n3_sheets", label_key="hs_sheets", xp=10, if_flag="dace2_done"),
        door("to_boiler", "boiler", [0.1, 0.86]),
        door("to_bay", "loading_bay", [0.9, 0.86], if_flag="dace2_done"),
    ], enter="n3_laundry"),
    "loading_bay": room("loading_bay", [
        enemy("constable", "constable_2", [0.45, 0.5], "n3_constable_pre", "n3_constable_post"),
        search("shutter", [0.7, 0.3], "n3_shutter", label_key="hs_shutter", xp=10),
        search("bins", [0.2, 0.55], "n3_bins", label_key="hs_bins", gives=["card_gale"], xp=5, if_flag="constable2_done"),
        door("to_laundry", "laundry", [0.1, 0.86]),
        door("to_street", "street", [0.9, 0.86], if_flag="constable2_done"),
    ], enter="n3_bay"),
    "street": room("street", [
        search("car", [0.3, 0.55], "n3_car_gone", label_key="hs_car", xp=10),
        search("noodle", [0.75, 0.45], "n3_noodle", label_key="hs_noodle", gives=["coffee", "coffee"]),
        door("to_bay", "loading_bay", [0.1, 0.86]),
        door("to_office", "back_office", [0.9, 0.86]),
    ], enter="n3_street"),
    "back_office": room("back_office", [
        enemy("haskell", "haskell_3", [0.5, 0.5], "n3_haskell_pre", "n3_haskell_post"),
        search("register", [0.25, 0.6], "n3_register3", label_key="hs_register", gives=["register_page"], xp=10, if_flag="haskell3_done"),
        door("to_lobby", "lobby", [0.9, 0.86], if_flag="haskell3_done"),
        door("to_street", "street", [0.1, 0.86]),
    ], enter="n3_office"),
    "lobby": room("lobby", [
        enemy("penhallow", "penhallow", [0.4, 0.5], "n3_pen_pre", "n3_pen_post"),
    ], enter="n3_lobby"),
}
ENDINGS = {
    "together": [{"flag": "ending_together"}] + vn("act3:end_together", cut=["epilogue"]),
    "train": [{"flag": "ending_train"}] + vn("act3:end_train", cut=["epilogue"]),
    "alone": [{"flag": "ending_alone"}] + vn("act3:end_alone", cut=["epilogue"]),
}
s3_events = {
    "n3_open": vn("act3:act3", lines=(5, 16)) + [
        {"if_trust": 7, "then": [{"cg": "cg_trust7_sheets"}] + N("n3_t7_1") + [say("mira", "n3_t7_2")] + N("n3_t7_3") + [{"hide_cg": True}], "else": []},
        {"if_trust": 5, "then": [{"cg": "cg_trust5_bath"}] + N("n3_t5_1") + [say("mira", "n3_t5_2"), {"hide_cg": True}], "else": []},
        {"hide_cg": True}, {"show": "mira_wry", "x": 0.7}] + N("n3_plan_1", "n3_plan_2") + [say("mira", "n3_plan_3"), {"show": ""}],
    "n3_corr": N("n3_corr_1"), "n3_stair": N("n3_stair_1"),
    "n3_boiler": N("n3_boiler_1"), "n3_gauges": N("n3_gauges_1"), "n3_pipes": N("n3_pipes_1"),
    "n3_laundry": N("n3_laundry_1"),
    "n3_dace_pre": [say("dace", "n3_dace_1")] + N("n3_dace_2"),
    "n3_dace_post": [say("dace", "n3_dace_3"), {"flag": "dace2_done"}],
    "n3_washers": N("n3_washers_1"), "n3_sheets": N("n3_sheets_1"),
    "n3_bay": N("n3_bay_1"),
    "n3_constable_pre": N("n3_constable_1") + [say("constable", "n3_constable_2")],
    "n3_constable_post": N("n3_constable_3") + [{"flag": "constable2_done"}],
    "n3_shutter": N("n3_shutter_1"), "n3_bins": N("n3_bins_1"),
    "n3_street": N("n3_street_1"), "n3_car_gone": N("n3_car_gone_1"), "n3_noodle": N("n3_noodle_1"),
    "n3_office": N("n3_office_1"),
    "n3_haskell_pre": [say("haskell", "n3_haskell_1")],
    "n3_haskell_post": N("n3_haskell_2") + [{"flag": "haskell3_done"}],
    "n3_register3": N("n3_register3_1"),
    "n3_lobby": N("n3_lobby_1"),
    "n3_pen_pre": [say("penhallow", "n3_pen_1")] + N("n3_pen_2", "n3_pen_3"),
    "n3_pen_post": N("n3_pen_4", "n3_pen_5") + [{"flag": "pen_done"}, {"show": "mira_neutral", "x": 0.7}] + N("n3_end_pre") + [
        # the ending the night has earned: together needs Trust 7 and a desk that did not sell her;
        # alone is a sold register that trust never repaired
        {"if_trust": 7, "then": [{"if_flag": "route_sold", "then": ENDINGS["train"], "else": ENDINGS["together"]}],
         "else": [{"if_trust": 5, "then": ENDINGS["train"],
                   "else": [{"if_trust": 3, "then": [{"if_flag": "route_sold", "then": ENDINGS["alone"], "else": ENDINGS["train"]}],
                             "else": ENDINGS["alone"]}]}]},
        {"show": ""}, {"end_night": True, "next": "epilogue"}],
}
NIGHTS["shift3"] = night("shift3", "n3", 44, 6 * 60 + 20, 1, "room704", "n3_open", s3_rooms, s3_events)

# ------------------------------------------------------------------ epilogue: seven o'clock
s4_rooms = {
    "lobby": room("lobby", [
        enemy("porter", "porter", [0.45, 0.5], "n4_porter_pre", "n4_porter_post"),
        search("board", [0.8, 0.4], "n4_board", label_key="hs_board", xp=10, if_flag="porter_done"),
        door("to_street", "street", [0.15, 0.78], if_flag="porter_done", label_key="hs_doors"),
    ]),
    "street": room("street", [], enter="n4_street"),
}
s4_events = {
    "n4_open": [{"hide_cg": True}, {"bg": "lobby"}, {"music": "explore"}] + compile_range(3, 63, 63) + N("n4_open_1"),
    "n4_porter_pre": [say("porter", "n4_porter_1"), say("porter", "n4_porter_2")],
    "n4_porter_post": compile_range(3, 64, 64) + N("n4_porter_3") + [{"flag": "porter_done"}],
    "n4_board": N("n4_board_1"),
    "n4_street": [
        {"if_flag": "ending_together", "then": [{"cg": "cg_rpg_corner"}] + N("n4_corner_1", "n4_corner_2") + [{"hide_cg": True}],
         "else": [{"if_flag": "ending_train", "then": N("n4_train_1", "n4_train_2"), "else": N("n4_alone_1", "n4_alone_2")}]},
        {"if_flag": "ending_alone", "then": [], "else": [
            {"if_trust": 9, "then": [{"hide_cg": True}, {"bg": "lobby"}] + N("n4_t9_1") + [{"cg": "cg_trust9_morning"}, say("mira", "n4_t9_2"), say("mira", "n4_t9_3")] + N("n4_t9_4") + [{"hide_cg": True}], "else": []}]},
        {"music": "title"}] + N("credits_1", "credits_2") + [{"end_night": True, "next": ""}],
}
NIGHTS["epilogue"] = night("epilogue", "n4", 12, 7 * 60, 3, "lobby", "n4_open", s4_rooms, s4_events)


def main():
    for nid, n in NIGHTS.items():
        (OUT / f"{nid}.json").write_text(json.dumps(n, ensure_ascii=False, indent=1))
        print(nid, len(n["rooms"]), "rooms", len(n["events"]), "events")


if __name__ == "__main__":
    main()
