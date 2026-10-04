#!/usr/bin/env python3
"""The five nights of OCCUPANCY, as RPG 'nights': floors to walk, standoffs, the office board.

The fiction is Overtime Landlord's (ops/adult_forks/overtime_idle.md): Mirei owns a tower she
cannot quite afford; the ground under it belongs to the Halvard Trust; the staff who work late
are the building's whole margin. You are the new night manager. Each night is one floor with a
rent crisis at the end of it, and each crisis is a person from the Trust across a desk.

What carries the second genre (HYBRIDS.md): every night has an office console (scripts/
office.gd) where the floor's 5x4 board is built and run once, and the rent fund it fills is
what the crisis is paid from. Paid, the crisis is the ordinary standoff; short, it is the hard
row (more Resolve, Pressure already at 25) and Mirei shows you what eviction looks like.
Recruiting (the staff gacha) is paid from the same fund; there is no real money anywhere.

Trust: one named track per woman (mara / priya / nia / sol / mirei). Talk choices, the shift
(a woman who worked the board you built gets +1 once a night), gifts from Supplies and close
crisis wins (Mirei) raise it. Each woman has two after-hours scenes, at Trust 3 and Trust 5,
offered at the end of every night (two a night at most): adults, consensual, warm, nothing
explicit. Writing is new here, EN + JA, with T(key, en, ja); this script emits
tools/strings_nights.py.

    python3 tools/build_nights.py   -> data/nights/n1..n5.json, tools/strings_nights.py
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "data/nights"
STR = {}
OFFICE = "res://scripts/office.gd"


def T(key, en, ja):
    if key in STR and STR[key] != (en, ja):
        raise SystemExit("duplicate string key with different text: " + key)
    STR[key] = (en, ja)
    return key


def V(key):
    """One of Mirei's 21 voiced lines (tools/strings_voice.py)."""
    return {"say": "mirei", "key": key}


def say(who, key):
    return {"say": who, "key": key}


def N(key, en, ja):
    return say("narrator", T(key, en, ja))


def S(who, key, en, ja):
    return say(who, T(key, en, ja))


def door(i, to, pos, **kw):
    return {"id": i, "kind": "door", "to": to, "pos": pos, **kw}


def search(i, pos, event, label, en, ja, **kw):
    return {"id": i, "kind": "search", "pos": pos, "event": event, "label_key": T("hs_" + label, en, ja), **kw}


def enemy(i, e, pos, pre, post, **kw):
    return {"id": i, "kind": "enemy", "enemy": e, "pos": pos, "event": pre, "after": post, **kw}


def ev(i, pos, event, label, en, ja, **kw):
    return {"id": i, "kind": "event", "pos": pos, "event": event, "label_key": T("hs_" + label, en, ja), **kw}


def give_q(item, n=1):
    return {"give": item, "n": n, "quiet": True}


def opt(key, en, ja, do, **kw):
    return {"key": T(key, en, ja), "do": do, **kw}


def trust(track, n=1):
    return {"trust": n, "track": track}


MOOD = {
    "lobby": {"ambient": "#e8e0d8", "lamps": [[0.3, 0.3, 1.0, "#ffd9a0"], [0.75, 0.35, 0.9, "#ffd9a0"]]},
    "open_plan": {"ambient": "#e4dcd6", "lamps": [[0.4, 0.35, 1.1, "#ffd090"]]},
    "copy_room": {"ambient": "#e8e2da", "lamps": [[0.5, 0.25, 1.0, "#fff0d0"]]},
    "break_room": {"ambient": "#ece2d6", "lamps": [[0.5, 0.3, 1.1, "#ffcf90"]]},
    "sublet": {"ambient": "#e0d8d0", "lamps": [[0.45, 0.3, 1.0, "#ffd090"]]},
    "meeting_room": {"ambient": "#dcdde4", "lamps": [[0.5, 0.25, 1.0, "#fff0d8"]]},
    "stairwell": {"ambient": "#dcd8d0", "lamps": [[0.5, 0.2, 1.0, "#fff0c8"]]},
    "accounts": {"ambient": "#e6ddd0", "lamps": [[0.35, 0.35, 1.0, "#ffd090"], [0.7, 0.35, 0.9, "#ffd090"]]},
    "records": {"ambient": "#e2d8cc", "lamps": [[0.5, 0.25, 1.0, "#ffd9a0"]]},
    "server_room": {"ambient": "#d0dae8", "lamps": [[0.5, 0.3, 1.0, "#c0e0ff"]]},
    "newsroom": {"ambient": "#e6dcd0", "lamps": [[0.4, 0.3, 1.1, "#ffcf90"]]},
    "print_room": {"ambient": "#e8dccc", "lamps": [[0.5, 0.3, 1.1, "#ffc880"]]},
    "rooftop": {"ambient": "#c8cce0", "lamps": [[0.3, 0.25, 0.9, "#ffd090"], [0.7, 0.25, 0.9, "#ffd090"]]},
    "penthouse": {"ambient": "#ece0d4", "lamps": [[0.5, 0.35, 1.2, "#ffcf90"]]},
    "boardroom": {"ambient": "#e6dcd0", "lamps": [[0.5, 0.2, 1.1, "#ffe0a8"]]},
    "vault": {"ambient": "#e0d6c8", "lamps": [[0.5, 0.35, 1.1, "#ffd090"]]},
}
# the building's directory, ground to penthouse (the map is a cross-section)
MAP = {"lobby": [0.30, 0.88], "open_plan": [0.55, 0.78], "copy_room": [0.80, 0.78], "break_room": [0.30, 0.78],
       "stairwell": [0.12, 0.60], "sublet": [0.40, 0.60], "meeting_room": [0.70, 0.60],
       "accounts": [0.40, 0.45], "records": [0.70, 0.45], "server_room": [0.15, 0.45],
       "newsroom": [0.40, 0.30], "print_room": [0.70, 0.30], "rooftop": [0.40, 0.06],
       "penthouse": [0.40, 0.17], "boardroom": [0.70, 0.17], "vault": [0.15, 0.17]}


def room(rid, hotspots, enter=None, music="explore"):
    r = {"name_key": "r_" + rid, "plate": rid, "music": music, "mood": MOOD.get(rid, {}), "hotspots": hotspots}
    if enter:
        r["enter_event"] = enter
    return r


for rid, en, ja in [("lobby", "The lobby", "ロビー"), ("open_plan", "Floor two — the open plan", "二階 — オープンフロア"),
                    ("copy_room", "The copy room", "コピー室"), ("break_room", "The break room", "休憩室"),
                    ("sublet", "Floor seven — the sublet", "七階 — 又貸しのフロア"), ("meeting_room", "The glass meeting room", "ガラスの会議室"),
                    ("stairwell", "The east stairwell", "東階段"), ("accounts", "Floor six — accounts", "六階 — 経理"),
                    ("records", "The records room", "記録室"), ("server_room", "The server room", "サーバー室"),
                    ("newsroom", "Floor eight — the newsroom", "八階 — 新聞部"), ("print_room", "The print room", "印刷室"),
                    ("rooftop", "The roof", "屋上"), ("penthouse", "The penthouse", "ペントハウス"),
                    ("boardroom", "The boardroom", "役員会議室"), ("vault", "The vault under the penthouse", "ペントハウス下の金庫室")]:
    T("r_" + rid, en, ja)


def night(nid, en, ja, sub_en, sub_ja, turns, clock, per, start_room, start_event, rooms, events):
    T(nid + "_title", en, ja)
    T(nid + "_sub", sub_en, sub_ja)
    return {"id": nid, "title_key": nid + "_title", "sub_key": nid + "_sub", "turns": turns, "clock_start": clock,
            "minutes_per_turn": per, "start_room": start_room, "start_event": start_event,
            "map": {"image": "tower", "rooms": {r: MAP[r] for r in rooms}}, "rooms": rooms, "events": events}


def console(nid, plate):
    return [{"screen": OFFICE, "args": {"floor": nid, "plate": plate}}]


def crisis(nid, boss, rent, pre, short_lines):
    """The rent check, then the standoff: paid -> the ordinary row; short -> the hard row."""
    return pre + [
        {"if_has": "coin", "n": rent,
         "then": [{"take": "coin", "n": rent}, {"flag": nid + "_paid"},
                  N(nid + "_paid_msg", f"You count out ${rent} from the rent fund. It is all there.", f"家賃資金から${rent}を数えて出す。全額そろっている。"),
                  {"battle": boss}],
         "else": [N(nid + "_short_msg", "The rent fund is short. Everyone in the room can see it.", "家賃資金が足りない。部屋の全員にそれが見えている。"),
                  {"cg": "cg_evicted"}] + short_lines + [{"hide_cg": True}, {"battle": boss + "_short"}]}]


# ---------------------------------------------------------------- after hours (the scenes)
SCENES = {}


def scene(who, tier, cg, lines, en, ja, need_flag=None):
    key = f"ah_{who}_{'a' if tier == 3 else 'b'}"
    seen = f"seen_{who}_{'a' if tier == 3 else 'b'}"
    o = opt(key, en, ja, [{"music": "intimate"}, {"cg": cg}] + lines + [{"hide_cg": True}, {"flag": seen}, {"music": "explore"}],
            req_trust=tier, req_track=who, if_not_flag=seen, auto_rank=2 + tier)
    if tier == 5:
        o["if_flag"] = f"seen_{who}_a"
    elif need_flag:
        o["if_flag"] = need_flag
    SCENES.setdefault(who, []).append(o)


scene("mara", 3, "cg_mara_sofa", [
    N("mara_a_1", "The sofa on twelve is the one nobody is supposed to know about. Mara knows about it. She has the key on the ring.", "十二階のソファは誰も知らないことになっている。マーラは知っている。鍵は輪についている。"),
    S("mara", "mara_a_2", "Sit. You've been standing since ten. I count.", "座って。十時からずっと立ってる。数えてたのよ。"),
    N("mara_a_3", "She undoes two buttons of her shirt like a woman taking off a uniform rather than putting on a show, and lies back with the lanyard still round her neck.", "彼女はシャツのボタンを二つ外す。見せるためではなく、制服を脱ぐ女の手つきで。そして名札を首にかけたまま横になる。"),
    S("mara", "mara_a_4", "Ten minutes. Then we go and look at the boiler. Come here.", "十分。それからボイラーを見に行く。こっちに来て。"),
    N("mara_a_5", "It is longer than ten minutes. Neither of you mentions the boiler again until it is almost light.", "十分では済まない。夜が明けかけるまで、どちらもボイラーの話を二度としなかった。")],
    "Stay late with Mara — the sofa on twelve", "マーラと残業 — 十二階のソファ")
scene("mara", 5, "cg_mara_corners", [
    N("mara_b_1", "The corner office has been empty for a year. Mara keeps it clean anyway; it has the best view in the building and nobody else has the key.", "角部屋は一年空いている。それでもマーラは掃除を欠かさない。ビルで一番の眺めで、鍵を持っているのは彼女だけだ。"),
    S("mara", "mara_b_2", "I used to want this office. Then I realised I already had every office.", "昔はこの部屋が欲しかった。でも気づいたの。もう全部の部屋を持ってるって。"),
    N("mara_b_3", "She sits on the desk with her shirt open and her chin up, and asks you to look at her the way you look at a floor plan: properly, all of it, nothing skipped.", "シャツをはだけて机に腰掛け、顎を上げる。図面を見るように見て、と彼女は言う。きちんと、全部、何も飛ばさずに。"),
    S("mara", "mara_b_4", "Good. You're learning the building.", "いいわ。ビルのことがわかってきたわね。")],
    "Stay late with Mara — the corner office", "マーラと残業 — 角部屋")
scene("priya", 3, "cg_priya_rooftop", [
    N("priya_a_1", "Priya fixes the roof door at five to six and refuses to go home until the sun has done something worth staying for.", "プリヤは六時五分前に屋上の扉を直し、日の出が待つ価値のあることをするまで帰らないと言い張る。"),
    S("priya", "priya_a_2", "Sit on the ledge. No — the inside of the ledge. I'm not filling in the form if you fall.", "縁に座って。違う、内側。落ちたら書類を書くのは私なんだから。"),
    N("priya_a_3", "The hi-vis jacket comes off one shoulder, then the strap under it. She laughs at you for looking, and then she lets you.", "反射ジャケットが片方の肩から落ち、その下の肩紐も。見とれるあなたを笑い、それから、見るのを許してくれる。"),
    S("priya", "priya_a_4", "Six nights a week I'm on call for this building. Tonight I'm off the clock. Act like it.", "週六日、このビルの呼び出し待ち。今夜は時間外よ。そのつもりでいて。")],
    "Stay late with Priya — the roof at sunrise", "プリヤと残業 — 夜明けの屋上")
scene("priya", 5, "cg_priya_x", [
    N("priya_b_1", "The service corridor behind the lifts has one bulb and a railing and Priya, who has been waiting there with her jacket off.", "エレベーター裏の業務用通路には、電球がひとつと手すり、そしてジャケットを脱いで待っていたプリヤがいる。"),
    S("priya", "priya_b_2", "Every camera in this building has a blind spot. I installed half of them. This is the best one.", "このビルのカメラには全部死角がある。半分は私が取り付けた。ここが一番いい死角。"),
    N("priya_b_3", "She lets the shirt fall down her back and looks over her shoulder at you, flushed and grinning, a hand on the cold rail.", "シャツを背中まで落とし、肩越しにあなたを見る。頬を染めて笑い、片手は冷たい手すりに。"),
    S("priya", "priya_b_4", "Well? I'm not going to fix this one for you.", "で？ これは直してあげないわよ。")],
    "Stay late with Priya — the service corridor", "プリヤと残業 — 業務用通路")
scene("nia", 3, "cg_nia_ledger", [
    N("nia_a_1", "Nia has found the error. It was eleven dollars in 2021, and it has been eating the building ever since. She is very pleased.", "ニアは誤りを見つけた。2021年の十一ドルが、それ以来ずっとビルを蝕んでいた。彼女はとても満足している。"),
    S("nia", "nia_a_2", "Do you know how rare it is to be right at two in the morning? Sit down. Celebrate with me. Quietly.", "午前二時に正しいって、どれだけ珍しいかわかる？ 座って。一緒に祝って。静かにね。"),
    N("nia_a_3", "She sits on the desk with the ledger in her lap and the blazer slipping, and reads you the corrected total in a voice that should not make a number sound like that.", "台帳を膝にのせて机に腰掛け、ブレザーが滑り落ちる。そして訂正後の合計を読み上げる。数字がそんなふうに聞こえていいはずのない声で。")],
    "Stay late with Nia — the ledger", "ニアと残業 — 帳簿")
scene("nia", 5, "cg_nia_after", [
    N("nia_b_1", "After the audit, the window. Nia takes her glasses off, which she never does, and holds them like evidence.", "監査のあとは窓辺。ニアは決して外さない眼鏡を外し、証拠品のように持つ。"),
    S("nia", "nia_b_2", "I don't do this. I want that on the record.", "私はこういうことはしない。記録に残しておいて。"),
    N("nia_b_3", "The blazer is the only thing left and she lets it hang open at the back, looking at you over her shoulder against a sky going pink.", "残ったのはブレザーだけ。背中を開けたまま、桃色に染まりはじめた空を背に、肩越しにあなたを見る。"),
    S("nia", "nia_b_4", "Noted. Approved. Come here.", "記録。承認。こっちに来て。")],
    "Stay late with Nia — after the audit", "ニアと残業 — 監査のあとで")
scene("sol", 3, "cg_sol_press", [
    N("sol_a_1", "Sol files at four, still, for a paper that stopped printing in March. Tonight she reads you the piece before she sends it nowhere.", "ソルは今も四時に入稿する。三月に印刷をやめた新聞に。今夜は送り先のない記事を、送る前にあなたに読んでくれる。"),
    S("sol", "sol_a_2", "It's about this building. You're in paragraph six. Don't let it go to your head.", "このビルの記事よ。あなたは第六段落にいる。のぼせないでね。"),
    N("sol_a_3", "The cardigan has slid off one shoulder and she doesn't fix it. She leans on her hand and watches you read, warm and tired and very much awake.", "カーディガンが片方の肩から滑り落ちても直さない。頬杖をついて、あなたが読むのを見ている。温かく、疲れていて、すっかり目が覚めている。")],
    "Stay late with Sol — the last edition", "ソルと残業 — 最終版")
scene("sol", 5, "cg_sol_after", [
    N("sol_b_1", "Four in the morning, the sofa in the newsroom, a lamp, a stack of papers nobody will read. Sol, laughing, holding her own arms across herself.", "午前四時、新聞部のソファ、ランプ、誰も読まない新聞の山。自分の腕で胸を隠し、笑っているソル。"),
    S("sol", "sol_b_2", "I've been writing about other people's nights for twenty years. I wanted one of my own.", "二十年、他人の夜のことを書いてきた。自分の夜がひとつ欲しかったの。"),
    N("sol_b_3", "She makes room on the sofa. The story, for once, is not going to be filed.", "彼女はソファに場所を空ける。今回ばかりは、この話は入稿されない。")],
    "Stay late with Sol — four in the morning", "ソルと残業 — 午前四時")
scene("mirei", 3, "cg_mirei_window", [
    N("mirei_a_1", "The penthouse at the hour the city turns gold. Mirei in a silk robe, a glass of something old, her back to you and the view in front of her.", "街が金色に変わる時刻のペントハウス。絹のローブのミレイ、古い何かを注いだグラス。背中をこちらに向け、眺めを前にしている。"),
    S("mirei", "mirei_a_2", "My father bought this building with money he didn't have. I've been paying for it with nights I don't have. You're the first person who's helped.", "父はないお金でこのビルを買った。私はない夜で払い続けてきた。手伝ってくれたのは、あなたが初めて。"),
    N("mirei_a_3", "The robe slides off her shoulders. She doesn't turn round. She doesn't need to; she can see you in the glass.", "ローブが肩から滑り落ちる。彼女は振り向かない。その必要はない。ガラスに映るあなたが見えている。")],
    "Stay late with Mirei — the penthouse window", "ミレイと残業 — ペントハウスの窓", need_flag="n2_done")
scene("mirei", 5, "cg_glass_office", [
    N("mirei_b_1", "Her office, the lights off, the city on the other side of the glass. Mirei with one hand flat on the window, as if she were holding the skyline up.", "灯りを消した彼女のオフィス。ガラスの向こうの街。片手を窓に平らに当てたミレイ。まるで摩天楼を支えているように。"),
    S("mirei", "mirei_b_2", "Everyone out there pays rent to someone. Tonight I'd like to owe you something.", "外の人たちは皆、誰かに家賃を払ってる。今夜は、あなたに借りを作りたいの。"),
    N("mirei_b_3", "She looks back at you over a bare shoulder, and for once the woman who owns the building is not the one in charge.", "裸の肩越しに振り返る。今回ばかりは、ビルの持ち主が主導権を握る側ではない。")],
    "Stay late with Mirei — against the glass", "ミレイと残業 — ガラス越しに")

T("ah_home", "Go home. It's late even for this building.", "帰る。このビルにしても遅すぎる。")
T("ah_menu", "The floor is quiet. Someone is still here.", "フロアは静かだ。まだ誰かが残っている。")


def after_hours(nid):
    """Two after-hours scenes a night at most; each gated by that woman's Trust (3, then 5)."""
    def menu(n):
        opts = [dict(o) for who in ("mirei", "mara", "priya", "nia", "sol") for o in SCENES[who]]
        opts.append({"key": "ah_home", "do": [{"flag": f"{nid}_home{n}"}], "auto_rank": 0})
        return {"choice": opts}
    return [N(f"{nid}_ah", "The floor is quiet. Someone is still here.", "フロアは静かだ。まだ誰かが残っている。"),
            menu(1),
            {"if_flag": f"{nid}_home1", "then": [], "else": [menu(2)]}]


# hired_* flags gate the tier-3 options of the recruited women
for who in ("priya", "nia", "sol"):
    SCENES[who][0]["if_flag"] = "hired_" + who

NIGHTS = {}

# ================================================================== NIGHT ONE: floor two (trial)
n1_rooms = {
    "lobby": room("lobby", [
        enemy("courier", "courier", [0.62, 0.5], "n1_courier_pre", "n1_courier_post"),
        search("desk", [0.32, 0.6], "n1_desk", "desk", "The reception desk", "受付", gives=["sign_in_sheet"], xp=5),
        search("clock", [0.5, 0.2], "n1_clock", "clock", "The brass clock", "真鍮の時計", xp=5),
        door("to_open", "open_plan", [0.9, 0.84]),
    ]),
    "open_plan": room("open_plan", [
        ev("console", [0.48, 0.55], "n1_console", "console", "The floor console — build and run the shift", "フロアの端末 — 配置してシフトを回す"),
        search("desks", [0.2, 0.45], "n1_desks", "desks", "Abandoned desks", "空いた机", gives=["voucher"], xp=5),
        {"id": "pryce", "kind": "event", "pos": [0.75, 0.48], "event": "n1_crisis", "label_key": T("hs_crisis_pryce", "The rent crisis — Gideon Pryce, rent agent", "家賃の危機 — Gideon Pryce, rent agent"), "sim_last": True},
        door("to_lobby", "lobby", [0.08, 0.84]),
        door("to_copy", "copy_room", [0.92, 0.84]),
        door("to_break", "break_room", [0.5, 0.86]),
    ], enter="n1_open_enter"),
    "copy_room": room("copy_room", [
        ev("priya", [0.4, 0.55], "n1_priya", "priya_copier", "Priya and the copier", "プリヤとコピー機"),
        search("vending", [0.8, 0.5], "n1_vending", "vending", "The vending machine", "自販機", gives=["energy"]),
        enemy("cleaner", "cleaner", [0.6, 0.48], "n1_cleaner_pre", "n1_cleaner_post"),
        door("to_open", "open_plan", [0.08, 0.84]),
    ], enter="n1_copy_enter"),
    "break_room": room("break_room", [
        ev("mara", [0.45, 0.55], "n1_mara", "mara_coffee", "Mara at the coffee machine", "コーヒーマシンのマーラ"),
        search("fridge", [0.75, 0.45], "n1_fridge", "fridge", "The fridge", "冷蔵庫", gives=["pastry"]),
        search("board", [0.2, 0.35], "n1_board", "noticeboard", "The noticeboard", "掲示板", xp=10),
        door("to_open", "open_plan", [0.5, 0.86]),
    ]),
}
n1_events = {
    "n1_open": [{"bg": "lobby"}, {"music": "explore"},
                N("n1_o1", "Ten at night, the Occupancy Building. Thirty-one floors of glass, nine of them lit, and a woman in a pinstripe suit waiting at the reception desk with a pen.", "夜十時、オキュパンシー・ビル。三十一階分のガラス、灯りがついているのは九フロア。受付台でペンを持って待つピンストライプのスーツの女。"),
                {"show": "mirei", "x": 0.7},
                V("v_greet_0"),
                S("mirei", "n1_o2", "You're the night manager. Mirei Kurosawa — I own the building. Mostly. Sit, sign, and I'll tell you which part I don't own.", "あなたが夜間管理人ね。黒沢ミレイ — このビルの持ち主。ほぼね。座って、署名して。持っていない部分を教えるわ。"),
                {"cg": "cg_mirei_lease"},
                S("mirei", "n1_o3", "The ground under us belongs to the Halvard Trust. Every floor pays them ground rent, every night it's due, and five floors are behind.", "この下の土地はハルヴァード信託のもの。どのフロアも地代を払う。毎晩が期日で、五フロアが滞納してる。"),
                S("mirei", "n1_o4", "If one floor defaults, the Trust can call the whole lease. They've wanted this tower for thirty years.", "一フロアでも払えなければ、信託は賃貸契約ごと解除できる。三十年前からこのタワーを狙ってるのよ。"),
                S("mirei", "n1_o5", "Tonight their agent comes for floor two. Your job is to have the rent when he does.", "今夜、代理人が二階に来る。あなたの仕事は、そのとき家賃を用意しておくこと。"),
                {"hide_cg": True},
                {"choice": [
                    opt("n1_c_how", "\"How much, and with what?\"", "「いくら、何で？」", [
                        S("mirei", "n1_how_1", "With people. The staff who stay late are the only margin this building has. Put them where they work best and the floor pays.", "人でよ。遅くまで残るスタッフが、このビルの唯一の余力。一番働ける場所に置けば、フロアは稼ぐ。"),
                        trust("mirei")], auto_rank=2),
                    opt("n1_c_why", "\"Why hire a stranger for this?\"", "「なぜ見知らぬ人間を？」", [
                        S("mirei", "n1_why_1", "Because everyone I know has already told me to sell.", "知り合いは皆、もう売れって言ったから。"),
                        trust("mirei")], auto_rank=1),
                    opt("n1_c_sign", "Sign. Ask nothing.", "署名する。何も聞かない。", [], auto_rank=0)]},
                {"show": "mara_work", "x": 0.3},
                S("mara", "n1_o6", "Mara. Building manager. I have keys to every floor and opinions about every tenant. You'll want both.", "マーラ。ビル管理。全フロアの鍵と、全入居者への意見を持ってる。どっちも必要になるわよ。"),
                {"join": True},
                S("mirei", "n1_o7", "And you'll want more hands than Mara's. The first hire is on me.", "それにマーラの手だけじゃ足りない。最初の採用は私の奢り。"),
                {"screen": OFFICE, "args": {"mode": "hire", "id": "priya", "floor": "n1", "plate": "lobby"}},
                {"show": "priya_work", "x": 0.72},
                S("priya", "n1_o8", "Priya. Facilities. I have keys I'm not supposed to have and a very good reason for each.", "プリヤ。設備担当。持っちゃいけない鍵を持ってて、どれにもちゃんとした理由がある。"),
                {"show": ""},
                N("n1_tut1", "(The floor console on each floor is the office: place staff and objects on the 5×4 floor, then run the night shift once. Neighbours link — coffee beside Dan, Mara lifting everyone round her — and every link multiplies the whole floor. The shift pays the rent fund.)", "（各フロアの端末がオフィス。5×4のフロアにスタッフと備品を置き、夜勤シフトを一度だけ回す。隣同士が連携する — ダンの隣のコーヒー、周りを底上げするマーラ — 連携ごとにフロア全体の倍率が上がる。シフトの稼ぎが家賃資金になる。）"),
                N("n1_tut2", "(Recruit more staff from the same fund — in-game money only. Each night's rent is due when its crisis arrives: paid, it is an ordinary standoff; short, a hard one. Standoffs: wear down their Resolve before their Pressure reaches 100. Read them first: everyone has soft spots.)", "（同じ資金でスタッフを採用できる — ゲーム内通貨のみ。各夜の家賃は危機が来たときに支払う。払えれば普通の対決、足りなければ厳しい対決。対決では、相手の圧力が100に達する前に意地を削りきる。まずは相手を読むこと。誰にでも弱みがある。）")],
    "n1_open_enter": [N("n1_oe1", "Floor two: an open plan for eighty, lit for nine. Monitors asleep in rows. Somebody's cardigan on a chair since spring.", "二階：八十人用のオープンフロアに、九人分の灯り。並んで眠るモニター。春から椅子に掛かったままの誰かのカーディガン。")],
    "n1_console": console("n1", "open_plan"),
    "n1_desk": [N("n1_desk1", "The night sign-in sheet, in Mara's square capitals. Who came in, who went up, who never signed out. Paperwork is a weapon in the right meeting.", "マーラの角ばった大文字で書かれた夜間入館記録。誰が来て、誰が上がり、誰が退館しなかったか。しかるべき会議では、書類は武器になる。")],
    "n1_clock": [N("n1_clock1", "The lobby clock was a gift from the Trust in 1974. It runs four minutes fast. Mirei has never had it fixed, on principle.", "ロビーの時計は1974年に信託から贈られたもの。四分進んでいる。ミレイは主義として一度も直させていない。")],
    "n1_desks": [N("n1_desks1", "Eleven empty desks, each with a name card for somebody who left. In one drawer, a parking pass nobody came back for.", "空いた机が十一。それぞれに、去った誰かの名札。引き出しのひとつに、誰も取りに戻らなかった駐車券。")],
    "n1_vending": [N("n1_vend1", "The vending machine takes your dollar, considers it, and gives you two energy drinks. You keep the second one for later.", "自販機はあなたの一ドルを受け取り、検討し、エナジードリンクを二本くれた。二本目はあとにとっておく。")],
    "n1_fridge": [N("n1_fridge1", "A labelled shelf (MARA. DO NOT.) and an unlabelled one. The unlabelled one has a night-shift pastry in it.", "名前つきの棚（マーラ。触るな）と、名前のない棚。名前のない方に夜勤のペストリーがある。")],
    "n1_board": [N("n1_board1", "Fire drill notices, a lost cat (found), and a printed chart of rent by floor going back six years. Every line goes up. One floor's goes up faster: two.", "避難訓練のお知らせ、迷い猫（見つかった）、そして六年分のフロア別家賃の表。どの線も上がっている。一本だけ速く上がる線がある。二階だ。")],
    "n1_copy_enter": [N("n1_ce1", "The copy room hums. The copier is making a sound copiers are not meant to make.", "コピー室が唸っている。コピー機が、コピー機の出してはいけない音を出している。")],
    "n1_priya": [{"show": "priya_work", "x": 0.7},
                 S("priya", "n1_p1", "Don't touch it. It's not jammed, it's offended. There's a difference.", "触らないで。詰まってるんじゃない、拗ねてるの。違いがあるのよ。"),
                 {"choice": [
                     opt("n1_p_help", "Hold the panel while she works.", "彼女が作業するあいだパネルを押さえる。", [
                         S("priya", "n1_p_help1", "See, you're useful. Mirei said you would be. I said we'd see.", "ほら、役に立つじゃない。ミレイはそう言ってた。私は様子見って言ったけど。"),
                         trust("priya")], auto_rank=2),
                     opt("n1_p_ask", "\"Why do you do nights?\"", "「どうして夜勤を？」", [
                         S("priya", "n1_p_ask1", "Days have managers. Nights have me. I like being the person who knows where the water shut-off is.", "昼には管理職がいる。夜には私がいる。止水栓の場所を知ってる人でいるのが好きなの。"),
                         trust("priya")], auto_rank=1),
                     opt("n1_p_leave", "Leave her to it.", "任せておく。", [], auto_rank=0)]},
                 {"show": ""}, {"xp": 10}],
    "n1_mara": [{"show": "mara_work", "x": 0.7},
                S("mara", "n1_m1", "Coffee. Black. Don't make that face; the machine only does black. It used to do latte. Then it saw things.", "コーヒー。ブラック。そんな顔しないで。この機械はブラックしか出ない。昔はラテも出た。それから色々見ちゃったのよ。"),
                {"choice": [
                    opt("n1_m_keys", "\"How long have you had all the keys?\"", "「いつから全部の鍵を？」", [
                        S("mara", "n1_m_keys1", "Nine years. I've outlasted three owners and two managers. I'm hoping to outlast the Trust.", "九年。オーナー三人と管理人二人より長くいる。信託より長くいられたらいいわね。"),
                        trust("mara")], auto_rank=2),
                    opt("n1_m_mirei", "\"What's Mirei like?\"", "「ミレイはどんな人？」", [
                        S("mara", "n1_m_mirei1", "Stubborn. Generous. Late. She's the only owner who's ever asked my name twice.", "頑固。気前がいい。遅刻魔。私の名前を二度聞いたオーナーは彼女だけ。"),
                        trust("mara"), trust("mirei")], auto_rank=1),
                    opt("n1_m_none", "Drink the coffee in silence.", "黙ってコーヒーを飲む。", [], auto_rank=0)]},
                {"show": ""}, {"xp": 10}],
    "n1_courier_pre": [N("n1_cou1", "A courier in a yellow rain jacket is blocking the revolving door with a bike and an envelope.", "黄色いレインジャケットの配達人が、自転車と封筒で回転扉をふさいでいる。"),
                       S("courier", "n1_cou2", "Summons for 'whoever runs this building'. Sign, or I leave it in the rain and you can explain that to a judge.", "「このビルを仕切ってる人」宛ての召喚状。サインして。じゃなきゃ雨の中に置いてく。判事に説明するのはそっちよ。")],
    "n1_courier_post": [N("n1_cou3", "The envelope is from the Trust: notice of the rent agent's visit, eleven o'clock, floor two. As if you didn't know.", "封筒は信託から：二階、十一時、家賃代理人の訪問通知。知らなかったとでもいうように。"), {"flag": "courier_done"}],
    "n1_cleaner_pre": [N("n1_cl1", "The cleaning agency's night supervisor, with a contract and a crew waiting in the lift.", "清掃会社の夜間主任。契約書を手に、班をエレベーターで待たせている。"),
                       S("cleaner", "n1_cl2", "Contract lapsed at midnight. No signature, no hoovers. Your floors, your dust.", "契約は零時で切れた。サインがなきゃ掃除機は動かない。あなたのフロア、あなたの埃。")],
    "n1_cleaner_post": [N("n1_cl3", "Two floors down, the hoovers start up again. It sounds, absurdly, like applause.", "二つ下の階で、掃除機がまた動き出す。ばかばかしいほど、拍手のように聞こえる。")],
    "n1_pryce_pre": crisis("n1", "pryce", 1500, [
        N("n1_pr1", "Eleven exactly. A grey man with a pocket-watch chain and a ledger opens the Trust's book on the nearest desk.", "十一時ちょうど。懐中時計の鎖をつけた灰色の男が、手近な机に信託の台帳を開く。"),
        S("pryce", "n1_pr2", "Gideon Pryce, for the Halvard Trust. Floor two, ground rent, one night. Fifteen hundred dollars, or the floor is in default.", "ギデオン・プライス、ハルヴァード信託の者だ。二階、地代、一晩分。千五百ドル。払えなければこのフロアは債務不履行となる。")],
        [S("mirei", "n1_short1", "This is what default looks like. A desk, a box, a lanyard. Somebody's whole job in one carton. Don't let it be floor two.", "不履行ってこういうことよ。机ひとつ、箱ひとつ、名札ひとつ。誰かの仕事がまるごと段ボール一箱。二階をそうさせないで。")]),
    "n1_pryce_post": [V("v_win_0"), {"show": "mirei", "x": 0.7},
                      S("mirei", "n1_after1", "Floor two, paid. One down. Four floors to go, and they get more expensive.", "二階、支払済。一つ目。あと四フロア、しかも高くなる。"),
                      V("v_unlock_0"),
                      S("mirei", "n1_after2", "Seven tomorrow. There's a tenant up there called Wes. You'll like him for about ten minutes.", "明日は七階。ウェスって入居者がいる。十分くらいは好きになれるわよ。"),
                      {"show": ""}, {"flag": "n1_done"}] + after_hours("n1") + [{"end_night": True, "next": "n2"}],
}
def crisis_events(ev, nid, boss):
    ev[nid + "_crisis"] = ev[f"{nid}_{boss}_pre"] + ev.pop(f"{nid}_{boss}_post")


crisis_events(n1_events, "n1", "pryce")
NIGHTS["n1"] = night("n1", "Night one", "第一夜", "Floor two — the open plan", "二階 — オープンフロア",
                     44, 22 * 60, 8, "lobby", "n1_open", n1_rooms, n1_events)

# ================================================================== NIGHT TWO: the sublet on seven
n2_rooms = {
    "stairwell": room("stairwell", [
        ev("priya", [0.45, 0.55], "n2_priya", "priya_lift", "Priya and the dead lift", "プリヤと止まったエレベーター"),
        search("landing", [0.2, 0.4], "n2_landing", "landing", "The landing", "踊り場", gives=["espresso"]),
        door("to_sublet", "sublet", [0.9, 0.84]),
    ]),
    "sublet": room("sublet", [
        ev("console", [0.5, 0.58], "n2_console", "console", "The floor console — build and run the shift", "フロアの端末 — 配置してシフトを回す"),
        enemy("subletter", "subletter", [0.7, 0.48], "n2_sub_pre", "n2_sub_post"),
        ev("mara", [0.25, 0.55], "n2_mara", "mara_sublet", "Mara counting desks", "机を数えるマーラ"),
        search("boxes", [0.85, 0.65], "n2_boxes", "boxes", "Cardboard boxes", "段ボール", gives=["voucher", "clipboard"], xp=5),
        door("to_stair", "stairwell", [0.08, 0.84]),
        door("to_meeting", "meeting_room", [0.92, 0.84]),
    ], enter="n2_sublet_enter"),
    "meeting_room": room("meeting_room", [
        enemy("subletter2", "subletter2", [0.35, 0.5], "n2_sub2_pre", "n2_sub2_post"),
        ev("mirei", [0.6, 0.35], "n2_mirei", "mirei_call", "Mirei on the speakerphone", "スピーカーフォンのミレイ"),
        {"id": "wes", "kind": "event", "pos": [0.7, 0.5], "event": "n2_crisis", "label_key": T("hs_crisis_wes", "The rent crisis — Wes", "家賃の危機 — Wes"), "sim_last": True},
        door("to_sublet", "sublet", [0.08, 0.84]),
    ]),
}
n2_events = {
    "n2_open": [{"bg": "stairwell"}, {"music": "explore"}, V("v_stage_0"),
                N("n2_o1", "Night two. The lift to seven has stopped between six and seven with nobody in it, which Priya says is the lift's way of making a point.", "第二夜。七階行きのエレベーターが六階と七階のあいだで止まった。誰も乗っていない。プリヤいわく、エレベーターなりの意思表示らしい。"),
                S("mara", "n2_o2", "Seven is Wes's floor. He leases a third of it and rents out all of it. The Trust's lawyers have noticed. So has the fire marshal.", "七階はウェスのフロア。三分の一を借りて、全部を貸してる。信託の弁護士も気づいた。消防署もね。"),
                S("mara", "n2_o3", "Tonight the Trust's agent for seven is Wes himself, because he signed as our sub-agent. Don't ask me how. I'd have to draw a diagram.", "今夜の七階の信託代理人はウェス本人。うちの副代理人として署名したから。どうやってかは聞かないで。図を描くことになる。")],
    "n2_sublet_enter": [N("n2_se1", "Folding tables, extension leads, a whiteboard that says COMMUNITY in four colours. Eleven people pay for desks here. There are six desks.", "折りたたみ机、延長コード、四色で『コミュニティ』と書かれたホワイトボード。ここで十一人が机代を払っている。机は六つ。")],
    "n2_console": console("n2", "sublet"),
    "n2_landing": [N("n2_land1", "Someone keeps an espresso machine on the sixth-floor landing, plugged into the emergency lighting. It is the best coffee in the building.", "誰かが六階の踊り場にエスプレッソマシンを置き、非常灯の電源につないでいる。ビルで一番うまいコーヒーだ。")],
    "n2_boxes": [N("n2_box1", "Boxes of Wes's merchandise: tote bags that say THE SPACE. Under them, a clipboard and a parking pass from a tenant who left without either.", "ウェスのグッズの箱：『ザ・スペース』と書かれたトートバッグ。その下に、どちらも持たずに去った入居者のクリップボードと駐車券。")],
    "n2_priya": [{"show": "priya_work", "x": 0.7},
                 S("priya", "n2_p1", "Hold the torch. Higher. No, at the cable, not at my face — I know what my face looks like.", "ライト持って。もっと上。違う、ケーブルに。顔じゃなくて — 自分の顔は知ってるから。"),
                 {"choice": [
                     opt("n2_p_steady", "Hold it steady, and say nothing about her face.", "しっかり照らし、顔のことは何も言わない。", [
                         S("priya", "n2_p_st1", "Good. You can stay.", "よし。いてもいいわ。"), trust("priya")], auto_rank=1),
                     opt("n2_p_tease", "\"I'd rather look at your face.\"", "「顔の方を見ていたいな」", [
                         S("priya", "n2_p_te1", "...Hold the torch. Higher. And keep talking like that after I've fixed this.", "……ライト持って。もっと上。それと、これを直したあとも、そういうこと言い続けて。"),
                         trust("priya", 2)], auto_rank=2),
                     opt("n2_p_go", "Leave her the torch.", "ライトを渡して離れる。", [], auto_rank=0)]},
                 {"show": ""}, {"xp": 15}],
    "n2_mara": [{"show": "mara_work", "x": 0.7},
                S("mara", "n2_m1", "Six desks, eleven tenants, and a sign-in sheet that says nobody's been here since Tuesday. Somebody's lying, and it's the furniture.", "机が六つ、入居者が十一人、入館記録には火曜から誰も来てないとある。誰かが嘘をついてる。家具がね。"),
                {"choice": [
                    opt("n2_m_help", "Count them with her, twice.", "彼女と一緒に、二度数える。", [
                        S("mara", "n2_m_h1", "Twice. Good. Nobody counts twice. You're hired, again.", "二度。いいわね。誰も二度は数えない。あなた、改めて採用。"),
                        trust("mara")], auto_rank=2),
                    opt("n2_m_wes", "\"Why does Mirei keep Wes?\"", "「ミレイはなぜウェスを置いておく？」", [
                        S("mara", "n2_m_w1", "Because he pays, eventually, and because she likes people who don't give up. It's her worst quality and the reason I still work here.", "最終的には払うから。それに諦めない人が好きだから。彼女の最悪の欠点で、私がまだここで働いてる理由。"),
                        trust("mara"), trust("mirei")], auto_rank=1)]},
                {"show": ""}, {"xp": 15}],
    "n2_mirei": [V("v_idle_1"), S("mirei", "n2_mi1", "Is he charming you? He charms everyone. He charmed me into a five-year lease.", "あの人、あなたを口説いてる？ 誰でも口説くのよ。私なんか五年契約を口説き落とされた。"),
                 {"choice": [
                     opt("n2_mi_tell", "\"He's going to have to charm the ledger.\"", "「台帳を口説くしかないね」", [
                         S("mirei", "n2_mi_t1", "Ha. Yes. I'm going to like you, I think. I'll tell you when I'm sure.", "ふふ。そうね。あなたのこと好きになりそう。確信したら言うわ。"),
                         trust("mirei")], auto_rank=2),
                     opt("n2_mi_ask", "\"Do you want him gone?\"", "「彼を追い出したい？」", [
                         S("mirei", "n2_mi_a1", "I want him honest. If you can do that, hire him. I mean it.", "正直でいてほしいの。それができたら雇って。本気よ。"),
                         trust("mirei")], auto_rank=1)]},
                 {"xp": 10}],
    "n2_sub_pre": [S("tenant", "n2_s1", "Are you management? I paid Wes for a desk with a window and he gave me a desk with a poster of a window.", "管理の人？ ウェスに窓つきの机代を払ったら、窓のポスター付きの机をくれたんだけど。")],
    "n2_sub_post": [N("n2_s2", "He takes his laptop and the poster. You let him keep the poster.", "彼はノートパソコンとポスターを持っていく。ポスターは持たせてやる。")],
    "n2_sub2_pre": [N("n2_s21", "Two tenants have barricaded the meeting room with a whiteboard and are holding a stand-up about it.", "入居者二人がホワイトボードで会議室にバリケードを築き、その件で立ち会議をしている。")],
    "n2_sub2_post": [N("n2_s22", "They leave together, already arguing about who gets to host the podcast.", "二人は連れ立って出ていく。もうポッドキャストの司会をどちらがやるかで揉めている。")],
    "n2_wes_pre": crisis("n2", "wes", 1900, [
        N("n2_w1", "Wes, on the boardroom table, tie loose, a smile he has used on better landlords than you.", "会議机の上のウェス。ネクタイは緩め、あなたより上等な家主たちにも使ってきた笑み。"),
        S("wes", "n2_w2", "Seven owes the Trust nineteen hundred. As the Trust's sub-agent, I'm obliged to collect. As a tenant, I'm obliged to say I don't have it.", "七階は信託に千九百の借り。信託の副代理人として回収する義務がある。入居者としては、持ってないと言う義務がある。")],
        [S("wes", "n2_short1", "See, this is why I sublet. Nobody can ever pay the whole thing. That box? That's the last guy who tried.", "ほらね、だから又貸しするんだ。誰も全額なんて払えない。あの箱？ 全部払おうとした最後のやつだよ。")]),
    "n2_wes_post": [S("wes", "n2_w3", "Fine. Fine! Put me on payroll. Board staff, nights. I'm terrific with people as long as someone else is doing the maths.", "わかった、わかったよ！ 給料を払ってくれ。夜勤のフロアスタッフで。誰かが計算してくれるなら、人あしらいは抜群なんだ。"),
                    N("n2_w4", "(Wes joins the recruit pool. He works the board — and taxes the wrong neighbours, unless someone gives them headphones.)", "（ウェスが採用候補に加わった。フロアで働く — ただしヘッドホンで守らないと、隣の人から取り立てる。）"),
                    {"flag": "wes_done"}, V("v_unlock_1"), V("v_win_1"),
                    S("mirei", "n2_after1", "Two floors. Six tomorrow — the Trust's sending an auditor. A real one.", "二フロア。明日は六階 — 信託が監査人を送ってくる。本物のね。"),
                    {"flag": "n2_done"}] + after_hours("n2") + [{"end_night": True, "next": "n3"}],
}
crisis_events(n2_events, "n2", "wes")
NIGHTS["n2"] = night("n2", "Night two", "第二夜", "Floor seven — the sublet", "七階 — 又貸し",
                     46, 22 * 60, 8, "stairwell", "n2_open", n2_rooms, n2_events)

# ================================================================== NIGHT THREE: accounts on six
n3_rooms = {
    "accounts": room("accounts", [
        ev("console", [0.5, 0.58], "n3_console", "console", "The floor console — build and run the shift", "フロアの端末 — 配置してシフトを回す"),
        enemy("junior", "junior", [0.3, 0.5], "n3_junior_pre", "n3_junior_post"),
        ev("mara", [0.15, 0.45], "n3_mara", "mara_blinds", "Mara at the blinds", "ブラインド際のマーラ"),
        {"id": "varga", "kind": "event", "pos": [0.72, 0.5], "event": "n3_crisis", "label_key": T("hs_crisis_varga", "The rent crisis — Ilse Varga, auditor", "家賃の危機 — Ilse Varga, auditor"), "sim_last": True},
        door("to_records", "records", [0.92, 0.84]),
        door("to_server", "server_room", [0.08, 0.84]),
    ], enter="n3_acc_enter"),
    "records": room("records", [
        ev("nia", [0.45, 0.55], "n3_nia", "nia_boxes", "Nia among the boxes", "箱の中のニア"),
        enemy("records_clerk", "records_clerk", [0.7, 0.48], "n3_rc_pre", "n3_rc_post"),
        search("shelf", [0.2, 0.4], "n3_shelf", "shelf", "Box 1974", "1974年の箱", xp=15),
        door("to_acc", "accounts", [0.08, 0.84]),
    ]),
    "server_room": room("server_room", [
        ev("priya", [0.5, 0.55], "n3_priya", "priya_servers", "Priya in the cold aisle", "冷気の通路のプリヤ"),
        search("rack", [0.8, 0.45], "n3_rack", "rack", "Rack nine", "九番ラック", gives=["mints", "tablet"]),
        door("to_acc", "accounts", [0.92, 0.84]),
    ]),
}
n3_events = {
    "n3_open": [{"bg": "accounts"}, {"music": "explore"}, V("v_idle_0"), V("v_stage_1"),
                N("n3_o1", "Night three. Floor six: accounts, for a company that moved to Lisbon and left its filing cabinets as a deposit.", "第三夜。六階：経理。リスボンへ移った会社が、敷金代わりに書類棚を置いていった。"),
                S("mirei", "n3_o2", "The Trust's auditor is Ilse Varga. She has never once been wrong in public. I've brought someone who might ruin that.", "信託の監査人はイルゼ・ヴァルガ。人前で間違えたことが一度もない。それを台無しにできそうな人を連れてきたわ。"),
                {"screen": OFFICE, "args": {"mode": "join", "id": "nia", "floor": "n3", "plate": "accounts"}},
                {"show": "nia_work", "x": 0.72},
                S("nia", "n3_o3", "Nia. Forensic accountant. I've read the Trust's last six years of letters to this building. They have a typo problem and a greed problem, in that order.", "ニア。法務会計士。信託がこのビルに送った六年分の手紙を読んだ。誤字の問題と強欲の問題がある。その順番でね。"),
                {"show": ""}],
    "n3_acc_enter": [N("n3_ae1", "Filing cabinets to the ceiling. A calculator on every desk, like a place setting.", "天井まで届く書類棚。どの机にも、食器のように電卓が一台ずつ。")],
    "n3_console": console("n3", "accounts"),
    "n3_shelf": [N("n3_sh1", "Box 1974: the building's original deed of trust, typed, carbon-copied, initialled by Mirei's father and a Halvard. Clause nine is underlined in pencil. Someone read it once.", "1974年の箱：ビル最初の信託証書。タイプ打ち、カーボン複写、ミレイの父とハルヴァード家の誰かのイニシャル。第九条に鉛筆で下線。誰かが一度読んだのだ。")],
    "n3_rack": [N("n3_rack1", "Rack nine has been running a cryptocurrency miner since 2022. Priya unplugs it with real joy. Behind it: a building tablet and a tin of mints.", "九番ラックは2022年から暗号通貨の採掘機を回していた。プリヤが心から嬉しそうに抜く。その裏に、ビル管理タブレットとミントの缶。")],
    "n3_nia": [{"show": "nia_work", "x": 0.7},
               S("nia", "n3_n1", "Hand me 2019. No — the other 2019. There are two. That's the first lie.", "2019年を取って。違う、もう一つの2019年。二つあるの。それが最初の嘘。"),
               {"choice": [
                   opt("n3_n_both", "Hand her both, and ask which is the lie.", "両方渡して、どちらが嘘か聞く。", [
                       S("nia", "n3_n_b1", "Both. Different lies. You'd be wasted on day shifts.", "両方よ。違う嘘。あなた、昼勤じゃもったいないわ。"),
                       trust("nia", 2)], auto_rank=2),
                   opt("n3_n_why", "\"Why audit for us and not for them?\"", "「どうして向こうじゃなく、こっちの監査を？」", [
                       S("nia", "n3_n_w1", "Because they pay better and I'd be bored. Mirei pays late and I'm never bored.", "向こうの方が払いがいいけど、退屈だから。ミレイは払いが遅いけど、退屈したことはない。"),
                       trust("nia")], auto_rank=1)]},
               {"show": ""}, {"xp": 20}],
    "n3_priya": [{"show": "priya_work", "x": 0.7},
                 S("priya", "n3_p1", "It's eleven degrees in here. I've got a jumper you can have, it says SECURITY on it, nobody will believe you.", "ここは十一度。セーター貸してあげる。『警備』って書いてあるけど、誰も信じないわ。"),
                 {"choice": [
                     opt("n3_p_take", "Take the jumper.", "セーターを借りる。", [
                         S("priya", "n3_p_t1", "Suits you. Keep it. Give it back when you're less cold. Or don't.", "似合う。持ってて。寒くなくなったら返して。返さなくてもいい。"),
                         trust("priya")], auto_rank=2),
                     opt("n3_p_share", "\"Share it?\"", "「一緒に着る？」", [
                         S("priya", "n3_p_s1", "It's a jumper, not a tent. ...Come here, then. Quickly. The cameras in here are mine.", "セーターよ、テントじゃない。……じゃあ、こっち来て。早く。ここのカメラは私のだから。"),
                         trust("priya", 2)], auto_rank=1)]},
                 {"show": ""}, {"xp": 15}],
    "n3_mara": [{"show": "mara_work", "x": 0.7},
                S("mara", "n3_m1", "I've opened every floor in this building for nine years and I've never once been on the Trust's side of the desk. Tonight I'd like to see their face.", "九年このビルの全フロアを開けてきて、一度も信託側の机に座ったことはない。今夜は向こうの顔を見てみたい。"),
                {"choice": [
                    opt("n3_m_stand", "\"Stand next to me when she arrives.\"", "「彼女が来たら隣に立って」", [
                        S("mara", "n3_m_s1", "I was going to anyway. But thank you for asking.", "どうせそうするつもりだった。でも頼んでくれてありがとう。"),
                        trust("mara")], auto_rank=2),
                    opt("n3_m_rest", "\"Rest. I'll call you.\"", "「休んで。呼ぶから」", [
                        S("mara", "n3_m_r1", "Nobody tells me to rest. ...Ten minutes.", "誰も私に休めなんて言わない。……十分ね。"),
                        trust("mara")], auto_rank=1)]},
                {"show": ""}, {"xp": 15}],
    "n3_junior_pre": [S("ames", "n3_j1", "I'm just here to count the cabinets. Ms. Varga said not to talk to anyone. You're anyone.", "書類棚を数えに来ただけです。ヴァルガさんに誰とも話すなと言われてます。あなたは誰かです。")],
    "n3_junior_post": [N("n3_j2", "She ticks a box she was not told about and goes looking for a vending machine that takes cards.", "教わっていない欄にチェックを入れ、カードの使える自販機を探しに行く。")],
    "n3_rc_pre": [N("n3_rc1", "The Trust has rented the records room for a week and left one woman in it with a stamp and a rule.", "信託は記録室を一週間借り、判子と規則を持った女を一人置いていった。")],
    "n3_rc_post": [N("n3_rc2", "She stamps your box RETURNED and slides an audit trail across with it, six years, in order.", "あなたの箱に『返却』の判を押し、監査証跡を添えて滑らせてくる。六年分、順番どおりに。")],
    "n3_varga_pre": crisis("n3", "varga", 2400, [
        N("n3_v1", "Ilse Varga lays six years of the building across the conference table in the order in which they lie.", "イルゼ・ヴァルガは六年分のビルを、嘘をついている順に会議机に並べる。"),
        S("varga", "n3_v2", "Floor six: two thousand four hundred, and an explanation for 2021 that does not involve the word 'rounding'.", "六階：二千四百。それと、『端数』という言葉を使わない2021年の説明を。")],
        [S("varga", "n3_short1", "Short. I do not negotiate with short. I itemise it.", "不足ね。不足とは交渉しない。明細にするだけ。"), V("v_fail_1")]),
    "n3_varga_post": [S("varga", "n3_v3", "Clean. Irritatingly. Ms. Nia — you would be wasted at the Trust. Don't tell them I said so.", "きれいね。腹立たしいほど。ニアさん — あなたは信託ではもったいない。私が言ったとは言わないで。"),
                      V("v_win_2"), V("v_streak_0"),
                      S("mirei", "n3_after1", "Three. Tomorrow's eight, the newsroom. They're sending the Bailiff, which means somebody at the Trust is frightened.", "三つ。明日は八階、新聞部。執行官を送ってくる。信託の誰かが怯えてるってことよ。"),
                      {"flag": "n3_done"}] + after_hours("n3") + [{"end_night": True, "next": "n4"}],
}
crisis_events(n3_events, "n3", "varga")
NIGHTS["n3"] = night("n3", "Night three", "第三夜", "Floor six — the audit", "六階 — 監査",
                     46, 22 * 60, 8, "accounts", "n3_open", n3_rooms, n3_events)

# ================================================================== NIGHT FOUR: the newsroom on eight
n4_rooms = {
    "newsroom": room("newsroom", [
        ev("console", [0.5, 0.58], "n4_console", "console", "The floor console — build and run the shift", "フロアの端末 — 配置してシフトを回す"),
        enemy("mover", "mover", [0.28, 0.5], "n4_mover_pre", "n4_mover_post"),
        ev("nia", [0.15, 0.45], "n4_nia", "nia_desk", "Nia at Sol's desk", "ソルの机のニア"),
        {"id": "bailiff", "kind": "event", "pos": [0.72, 0.5], "event": "n4_crisis", "label_key": T("hs_crisis_bailiff", "The rent crisis — The Bailiff", "家賃の危機 — The Bailiff"), "sim_last": True},
        door("to_print", "print_room", [0.92, 0.84]),
        door("to_roof", "rooftop", [0.5, 0.86]),
    ], enter="n4_news_enter"),
    "print_room": room("print_room", [
        ev("sol", [0.45, 0.55], "n4_sol", "sol_press", "Sol at the press", "印刷機のソル"),
        enemy("printer_rep", "printer_rep", [0.7, 0.48], "n4_rep_pre", "n4_rep_post"),
        search("proofs", [0.2, 0.35], "n4_proofs", "proofs", "Hanging proofs", "吊るされた校正刷り", xp=15),
        door("to_news", "newsroom", [0.08, 0.84]),
    ]),
    "rooftop": room("rooftop", [
        ev("priya", [0.4, 0.55], "n4_priya", "priya_tank", "Priya on the water tank", "給水塔のプリヤ"),
        search("garden", [0.75, 0.6], "n4_garden", "garden", "The rooftop garden", "屋上庭園", gives=["pastry", "earpiece"]),
        door("to_news", "newsroom", [0.5, 0.86]),
    ]),
}
n4_events = {
    "n4_open": [{"bg": "newsroom"}, {"music": "explore"}, V("v_stage_2"), V("v_near_0"),
                N("n4_o1", "Night four. Floor eight: the newsroom of a paper that stopped printing in March and did not stop coming in.", "第四夜。八階：三月に印刷をやめ、それでも出社をやめなかった新聞の編集部。"),
                S("mirei", "n4_o2", "Sol has been the night editor here for twenty years. She doesn't work for us. She works for the story. Tonight that's us.", "ソルはここで二十年、夜間デスクをしてる。うちのために働いてるんじゃない。記事のために働いてる。今夜は、それがうちなの。"),
                {"screen": OFFICE, "args": {"mode": "join", "id": "sol", "floor": "n4", "plate": "newsroom"}},
                {"show": "sol_work", "x": 0.72},
                S("sol", "n4_o3", "Sol. I file at four. If the Bailiff is still here at four, he's in the story. He knows that. It makes him careful.", "ソル。四時に入稿する。四時にまだ執行官がいたら、記事に載る。本人もわかってる。だから慎重になるの。"),
                {"show": ""}],
    "n4_news_enter": [N("n4_ne1", "Desks buried in newspapers. Clocks for five cities, all of them right. One lamp on, Sol's.", "新聞に埋もれた机。五都市分の時計、どれも正確。灯りはひとつだけ、ソルのもの。")],
    "n4_console": console("n4", "newsroom"),
    "n4_proofs": [N("n4_pr1", "Proofs on a line like washing. One is a front page from 1974: HALVARD TRUST WINS GROUND LEASE ON TOWER SITE. Someone has circled the date.", "洗濯物のように紐に吊るされた校正刷り。一枚は1974年の一面：『ハルヴァード信託、タワー用地の地上権を獲得』。誰かが日付に丸をつけている。")],
    "n4_garden": [N("n4_g1", "Tomatoes, two deckchairs, an earpiece someone lost while pretending to take a call up here. A pastry under a cloche, for whoever needs it.", "トマト、デッキチェア二脚、ここで電話するふりをしていた誰かが落としたイヤーピース。必要な誰かのために、クロッシュの下にペストリー。")],
    "n4_sol": [{"show": "sol_work", "x": 0.7},
               S("sol", "n4_s1", "Twenty years on this press and it's never once been on time. I love it like a bad dog.", "この印刷機と二十年、一度も時間どおりに動いたことがない。駄犬みたいに愛してるわ。"),
               {"choice": [
                   opt("n4_s_story", "\"Tell me the story you'd run tonight.\"", "「今夜載せる記事を聞かせて」", [
                       S("sol", "n4_s_st1", "A woman who won't sell a building, and the people who stay up with her. It's not news. It's the only kind I still believe.", "ビルを売らない女と、一緒に夜更かしする人たちの話。ニュースじゃない。今でも信じられる唯一の種類の話よ。"),
                       trust("sol", 2)], auto_rank=2),
                   opt("n4_s_help", "Feed the paper while she sets the type.", "彼女が組版するあいだ紙を差す。", [
                       S("sol", "n4_s_h1", "Steady hands. Good. Writers never have them.", "手がぶれない。いいわね。物書きは持ってないのよ。"),
                       trust("sol")], auto_rank=1)]},
               {"show": ""}, {"xp": 20}],
    "n4_nia": [{"show": "nia_work", "x": 0.7},
               S("nia", "n4_n1", "The Bailiff's order is dated 2025. It's 2026. Courts make typos too. Shall we be rude about it?", "執行官の命令書は2025年付け。今は2026年。裁判所も誤字をする。礼儀知らずにいきましょうか？"),
               {"choice": [
                   opt("n4_n_yes", "\"Very rude. Politely.\"", "「とても失礼に。丁寧に」", [
                       S("nia", "n4_n_y1", "My favourite register. You're getting dangerous.", "私の好きな口調。あなた、危険になってきたわね。"),
                       trust("nia")], auto_rank=2),
                   opt("n4_n_sleep", "\"Have you slept?\"", "「寝た？」", [
                       S("nia", "n4_n_s1", "I'll sleep when the Trust's been audited. Ask me again at dawn. I might say yes to something.", "信託を監査し終えたら寝る。夜明けにもう一度聞いて。何かに「はい」と言うかもしれない。"),
                       trust("nia")], auto_rank=1)]},
               {"show": ""}, {"xp": 15}],
    "n4_priya": [{"show": "priya_work", "x": 0.7},
                 S("priya", "n4_p1", "Best view in the city and nobody comes up here except me and the pigeons. Sit. Not there, that's a pigeon's.", "街一番の眺めなのに、ここに来るのは私と鳩だけ。座って。そこじゃない、そこは鳩の席。"),
                 {"choice": [
                     opt("n4_p_view", "Sit beside her and say nothing for a while.", "隣に座って、しばらく何も言わない。", [
                         S("priya", "n4_p_v1", "...Yeah. That. That's the thing I come up here for.", "……うん。それ。それのためにここに来るの。"),
                         trust("priya")], auto_rank=2),
                     opt("n4_p_ask", "\"What will you do if we lose the building?\"", "「ビルを失ったらどうする？」", [
                         S("priya", "n4_p_a1", "Find another one. But I'd miss this roof. And the company.", "別のを探す。でもこの屋上は恋しくなる。それに、一緒にいる人も。"),
                         trust("priya")], auto_rank=1)]},
                 {"show": ""}, {"xp": 15}],
    "n4_mover_pre": [N("n4_mv1", "A van at the loading bay and a foreman with a list: the newsroom's desks, chairs, clocks. All five clocks.", "搬入口にバン、そして一覧を持った班長。新聞部の机、椅子、時計。時計は五つ全部。"),
                     S("foreman", "n4_mv2", "Just doing the job. Desk, desk, chair, desk.", "仕事してるだけだ。机、机、椅子、机。")],
    "n4_mover_post": [N("n4_mv3", "He folds the list into his pocket. The clocks stay. All five go on being right.", "彼は一覧をポケットにしまう。時計は残る。五つとも正確なまま。")],
    "n4_rep_pre": [N("n4_rp1", "A lease-company rep at two in the morning, here to repossess a printing press with a tablet.", "午前二時、タブレットで印刷機を引き取りに来たリース会社の担当者。")],
    "n4_rep_post": [N("n4_rp2", "He photographs the press, for the file, and leaves the court order behind with the wrong year on it.", "彼は記録用に印刷機を撮影し、年の間違った命令書を置いて帰った。")],
    "n4_bailiff_pre": crisis("n4", "bailiff", 3200, [
        N("n4_b1", "The Bailiff reads the order aloud in the newsroom, slowly, so that everyone who still works there can hear it.", "執行官は新聞部で命令書を読み上げる。まだここで働く全員に聞こえるよう、ゆっくりと。"),
        S("bailiff", "n4_b2", "Floor eight: three thousand two hundred, tonight, or the contents are distrained.", "八階：三千二百、今夜中に。さもなくば什器を差し押さえる。")],
        [S("bailiff", "n4_short1", "Short. I have a van. The van is not short.", "不足だ。こちらにはバンがある。バンは不足していない。")]),
    "n4_bailiff_post": [S("bailiff", "n4_b3", "Not tonight, then. Off the record — I hope she keeps it.", "では今夜ではない。記録外だが — 彼女が守りきるといい。"),
                        V("v_win_big_0"), V("v_streak_1"),
                        S("mirei", "n4_after1", "Four. Tomorrow there's only the penthouse — and Corinne Halvard, who has decided to come herself.", "四つ。明日はペントハウスだけ — それとコリンヌ・ハルヴァード。本人が来ることにしたのよ。"),
                        {"flag": "n4_done"}] + after_hours("n4") + [{"end_night": True, "next": "n5"}],
}
crisis_events(n4_events, "n4", "bailiff")
NIGHTS["n4"] = night("n4", "Night four", "第四夜", "Floor eight — the newsroom", "八階 — 新聞部",
                     46, 22 * 60, 8, "newsroom", "n4_open", n4_rooms, n4_events)

# ================================================================== NIGHT FIVE: the penthouse
ENDING_KEEP = [
    {"music": "dawn"},
    {"if_count": ["n1_paid", "n2_paid", "n3_paid", "n4_paid", "n5_paid"], "n": 5,
     "then": [{"if_trust": 5, "track": "mirei",
               "then": [{"music": "intimate"}, {"cg": "cg_vault_x"},
                        N("n5_vault1", "The vault under the penthouse, which Mirei's father built for money he never had. Tonight it holds the rent fund, all of it, stacked on the desk.", "ペントハウスの下の金庫室。ミレイの父が、持っていなかったお金のために造った部屋。今夜は家賃資金がすべて、机の上に積まれている。"),
                        S("mirei", "n5_vault2", "Do you know, nobody has ever paid every floor in one week. Not my father. Not me. Sit with me. I want to look at it with someone.", "知ってる？ 一週間で全フロアを払いきった人はいないの。父も、私も。一緒に座って。誰かと一緒に眺めたいの。"),
                        N("n5_vault3", "She leans back in the chair with the jacket open and her hand on the money, smug and lovely and, for the first time since you met her, not tired.", "ジャケットをはだけて椅子にもたれ、片手をお金に置く。得意げで、美しく、出会ってから初めて、疲れていない。"),
                        {"hide_cg": True}, {"music": "dawn"}], "else": []},
              {"if_trust": 5, "track": "mara", "then": [{"if_trust": 5, "track": "mirei", "then": [
                  {"music": "intimate"}, {"cg": "cg_quiet_floor"},
                  N("n5_quiet1", "Later, on the quiet floor, you find Mara and Mirei on the sofa by the window with a jacket over their knees, kissing like two people who have been meaning to for nine years.", "あとで、静かなフロアで、窓辺のソファにマーラとミレイを見つける。膝にジャケットをかけ、九年越しにやっとそうしているふたりのように口づけている。"),
                  N("n5_quiet2", "Mirei opens her eyes, sees you, and holds out a hand. Mara moves over. There is room on the sofa; there always was.", "ミレイが目を開け、あなたに気づき、手を差し出す。マーラが詰める。ソファには場所がある。ずっとあったのだ。"),
                  {"hide_cg": True}, {"music": "dawn"}]}]},
              {"cg": "cg_keys"},
              S("mirei", "n5_keys1", "Every floor paid. The building's mine — ours. Here. These are the penthouse keys. Don't lose them; Mara will never let you forget it.", "全フロア支払済。ビルは私のもの — 私たちのもの。はい、ペントハウスの鍵。なくさないで。マーラが一生言い続けるから。"),
              V("v_stage_3"),
              N("n5_keys2", "FULL OCCUPANCY. The lights on thirty-one floors, every one of them paid for.", "満室。三十一階すべての灯り、どれも支払済。"),
              {"flag": "ending_full"}, {"hide_cg": True}],
     "else": [{"cg": "cg_floor9"},
              S("mirei", "n5_hold1", "We kept it. Not cleanly — there are floors I'll be paying back till spring. But we kept it, and the Trust has gone home.", "守りきった。きれいにじゃない — 春まで払い続けるフロアもある。でも守った。信託は帰ったわ。"),
              N("n5_hold2", "HOLDING ON. Dawn over the unfinished top floors. Next time, build the floors better and every one of them pays.", "持ちこたえて。未完成の最上階に夜明け。次は、フロアをもっと上手く組めば、全部が払える。"),
              V("v_fail_0"),
              {"flag": "ending_hold"}, {"hide_cg": True}]},
]
n5_rooms = {
    "penthouse": room("penthouse", [
        ev("console", [0.35, 0.6], "n5_console", "console", "The floor console — build and run the shift", "フロアの端末 — 配置してシフトを回す"),
        ev("mirei", [0.6, 0.4], "n5_mirei", "mirei_desk", "Mirei at her father's desk", "父の机のミレイ"),
        {"id": "halvard", "kind": "event", "pos": [0.75, 0.5], "event": "n5_crisis", "label_key": T("hs_crisis_halvard", "The rent crisis — Corinne Halvard", "家賃の危機 — Corinne Halvard"), "sim_last": True},
        door("to_board", "boardroom", [0.92, 0.84]),
        door("to_vault", "vault", [0.08, 0.84]),
    ], enter="n5_ph_enter"),
    "boardroom": room("boardroom", [
        enemy("lawyer", "lawyer", [0.5, 0.48], "n5_lawyer_pre", "n5_lawyer_post"),
        ev("sol", [0.2, 0.5], "n5_sol", "sol_board", "Sol taking notes", "メモを取るソル"),
        door("to_ph", "penthouse", [0.08, 0.84]),
    ]),
    "vault": room("vault", [
        ev("mara", [0.4, 0.55], "n5_mara", "mara_vault", "Mara with the vault keys", "金庫の鍵を持つマーラ"),
        search("deposit", [0.75, 0.45], "n5_deposit", "deposit", "Deposit box 9", "九番の貸金庫", gives=["gold_lanyard", "mints"], xp=20),
        door("to_ph", "penthouse", [0.92, 0.84]),
    ]),
}
n5_events = {
    "n5_open": [{"bg": "penthouse"}, {"music": "explore"}, V("v_greet_1"), V("v_near_1"),
                N("n5_o1", "Night five. The penthouse, which Mirei has not slept in for a year because she couldn't stand to see the view and not own it.", "第五夜。ペントハウス。眺めを見ながらそれを持っていないことに耐えられず、ミレイが一年寝ていない部屋。"),
                S("mirei", "n5_o2", "Corinne Halvard is the heir. We were at school together. She was better at everything except wanting things.", "コリンヌ・ハルヴァードは相続人。学校が一緒だった。欲しがること以外は、何でも彼女の方が上手だった。"),
                S("mirei", "n5_o3", "The penthouse rent is the big one. Build the last floor well. Then help me face her.", "ペントハウスの家賃が一番大きい。最後のフロアをうまく組んで。それから、彼女と向き合うのを手伝って。")],
    "n5_ph_enter": [N("n5_pe1", "Floor-to-ceiling glass, a desk older than the tower, and thirty-one floors of lights below you, most of them now on.", "床から天井までのガラス、タワーより古い机、そして眼下に三十一階分の灯り。今はそのほとんどがついている。")],
    "n5_console": console("n5", "penthouse"),
    "n5_deposit": [N("n5_dep1", "Box nine, opened with Mara's key: a gold lanyard engraved NIGHT MANAGER and a date thirty years ago. Somebody had this job before you, and was good at it.", "マーラの鍵で開けた九番の箱：『夜間管理人』と三十年前の日付が刻まれた金の名札紐。あなたの前にもこの仕事をした誰かがいて、上手だったのだ。")],
    "n5_mirei": [{"show": "mirei", "x": 0.7},
                 S("mirei", "n5_m1", "My father sat here and lied to the Trust for twenty years. I've sat here and told them the truth for ten. Neither of us could make the rent.", "父はここに座って二十年、信託に嘘をついた。私は十年、本当のことを言ってきた。どちらも家賃は払えなかった。"),
                 {"choice": [
                     opt("n5_m_we", "\"You couldn't. We can.\"", "「あなた一人では。でも私たちなら」", [
                         S("mirei", "n5_m_we1", "...Say that again when she's here. I want her to hear it.", "……彼女がいるときに、もう一度言って。聞かせたいの。"),
                         trust("mirei", 2)], auto_rank=2),
                     opt("n5_m_sell", "\"Would it be so bad to sell?\"", "「売るのはそんなに悪いこと？」", [
                         S("mirei", "n5_m_s1", "Yes. Not for me. For them — every one of them on every floor. Ask me again after tonight.", "ええ。私にとってじゃない。彼らにとって — 全フロアの一人ひとりにとって。今夜が終わったらもう一度聞いて。"),
                         trust("mirei")], auto_rank=1)]},
                 {"show": ""}, {"xp": 20}],
    "n5_sol": [{"show": "sol_work", "x": 0.7},
               S("sol", "n5_s1", "I'm taking notes. Not for the paper. For the building. Somebody should write down how this went.", "メモを取ってるの。新聞のためじゃない。ビルのために。どうなったか、誰かが書き残すべきだから。"),
               {"choice": [
                   opt("n5_s_ending", "\"How does it end?\"", "「どう終わる？」", [
                       S("sol", "n5_s_e1", "With the lights on, I hope. Ask me at four.", "灯りがついたまま、だといいわね。四時に聞いて。"),
                       trust("sol")], auto_rank=2),
                   opt("n5_s_in", "\"Put Mara in it. She'll pretend to hate it.\"", "「マーラを書いて。嫌がるふりをするから」", [
                       S("sol", "n5_s_i1", "She's already in it. She's in every paragraph. She just doesn't know.", "もう書いてある。全段落に出てくる。本人が知らないだけ。"),
                       trust("sol"), trust("mara")], auto_rank=1)]},
               {"show": ""}, {"xp": 15}],
    "n5_mara": [{"show": "mara_work", "x": 0.7},
                S("mara", "n5_ma1", "Nine years and I've never opened this one. Mirei's father had the only key. Turns out I had a copy. Don't tell her.", "九年、これだけは開けたことがない。ミレイの父が唯一の鍵を持ってた。私が合鍵を持ってたってわけ。彼女には内緒よ。"),
                {"choice": [
                    opt("n5_ma_open", "\"Open it with me.\"", "「一緒に開けよう」", [
                        S("mara", "n5_ma_o1", "With you. Yes. That's the right way to do it.", "あなたと。ええ。それが正しいやり方ね。"),
                        trust("mara", 2)], auto_rank=2),
                    opt("n5_ma_tell", "\"I'm telling her.\"", "「彼女に言うよ」", [
                        S("mara", "n5_ma_t1", "Traitor. ...She'll laugh. Fine. Tell her.", "裏切り者。……彼女は笑うわね。いいわ、言って。"),
                        trust("mara"), trust("mirei")], auto_rank=1)]},
                {"show": ""}, {"xp": 15}],
    "n5_lawyer_pre": [S("sallow", "n5_l1", "A courtesy, before Ms. Halvard arrives: sign here, and here, and the Trust will take the building at a fair price. Everyone keeps their jobs. For a while.", "ハルヴァード様が来られる前に、ご好意として。ここと、ここに署名を。信託が適正価格でビルを引き取ります。皆さん職は残ります。しばらくは。")],
    "n5_lawyer_post": [N("n5_l2", "He caps his pen and leaves the 1974 deed on the table, open at clause nine. He had brought it to show you that it said nothing. It says something.", "彼はペンにキャップをし、1974年の証書を第九条で開いたまま机に置いていく。何も書いていないと見せるために持ってきたのだ。だが、書いてある。")],
    "n5_halvard_pre": crisis("n5", "halvard", 4200, [
        N("n5_h1", "Corinne Halvard takes Mirei's chair as if it had been kept warm for her, in a white suit that has never been near a filing cabinet.", "コリンヌ・ハルヴァードは、自分のために温められていたかのようにミレイの椅子に座る。書類棚に近づいたことのない白いスーツで。"),
        S("halvard", "n5_h2", "The penthouse: four thousand two hundred, tonight. Or the lease, which is worth considerably more to me than it is to you.", "ペントハウス：四千二百、今夜。さもなくば賃貸契約を。あなたより、私にとってずっと価値があるものよ。")],
        [S("halvard", "n5_short1", "Short, Mirei. You always were. I'll take the building and keep the staff. I'm told they're very good.", "足りないわね、ミレイ。昔からそう。ビルはもらって、スタッフは残すわ。とても優秀だそうね。")]),
    "n5_halvard_post": [S("halvard", "n5_h3", "Clause nine. Of course it's clause nine. Keep it, then, Mirei. Make it worth something.", "第九条。もちろん第九条よね。じゃあ持っていなさい、ミレイ。価値のあるものにして。"),
                        V("v_win_big_1"), {"flag": "n5_done"}] + ENDING_KEEP + after_hours("n5") + [{"end_night": True, "next": ""}],
}
crisis_events(n5_events, "n5", "halvard")
NIGHTS["n5"] = night("n5", "Night five", "第五夜", "The penthouse", "ペントハウス",
                     46, 22 * 60, 8, "penthouse", "n5_open", n5_rooms, n5_events)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for nid, n in NIGHTS.items():
        (OUT / f"{nid}.json").write_text(json.dumps(n, ensure_ascii=False, indent=1))
        print(nid, len(n["rooms"]), "rooms", len(n["events"]), "events")
    body = "# GENERATED by tools/build_nights.py -- edit the writing there, not here.\nS = {\n"
    for k, (en, ja) in STR.items():
        body += f"{k!r}: ({en!r}, {ja!r}),\n"
    (HERE / "strings_nights.py").write_text(body + "}\n")
    print(len(STR), "night strings -> tools/strings_nights.py")


if __name__ == "__main__":
    main()
