#!/usr/bin/env python3
"""The five hours of LIEN's night, as RPG 'nights': rooms, hotspots, standoffs, events.

The writing is the fork's own: {"lines": "lien:A-B"} pulls story.gd's lines A..B (by source
line, see tools/import_story.py), so every appraisal, every reading and all three endings
are the original text with the original Japanese. What is new is the RPG between those
beats -- the shop's back rooms, the Receipt Stair, the Market's people -- and it is written
here, EN + JA, with T(key, en, ja). This script emits tools/strings_nights.py from those.

The economy is the original's, unchanged: the till starts at 260, fees are 35 (ring) and 20
(veil), the price tiers are 2/3, 1, 3/2 of value, the Market haul is 30, Calder pays 90, the
debt is 200 against till + stock (stock is always the three objects, 97). The RPG adds no
coin anywhere, so the three endings resolve exactly as CollateralCore.ending_of() did:
  FACTOR      sold a reading to Calder
  COLLATERAL  all three client readings taken (or short of the debt)
  SOLVENT     net >= 200 (till >= 103)

Trust (named tracks: tamsin / ivo / mara) is new and gates the adult readings that are new:
cg_finial needs Tamsin's trust 3 on top of the original HIGH condition, and each client's
second, deeper reading of the object on the shelf (hour five) needs that client's trust 5.
Ivo's needs it most honestly: his trust only reaches 5 if you did NOT look when he asked,
and the second reading happens because he writes on the back of his ticket that you may.

    python3 tools/build_nights.py   -> data/nights/h1..h5.json, tools/strings_nights.py
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "data/nights"
STR = {}


def T(key, en, ja):
    if key in STR and STR[key] != (en, ja):
        raise SystemExit("duplicate string key with different text: " + key)
    STR[key] = (en, ja)
    return key


def V(key):
    """One of Nara's 21 voiced lines (tools/strings_voice.py)."""
    return {"say": "nara", "key": key}


def L(a, b=None):
    return {"lines": f"lien:{a}-{b or a}"}


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


def q(*steps):            # quiet bookkeeping
    return list(steps)


def give_q(item, n=1):
    return {"give": item, "n": n, "quiet": True}


def opt(key, en, ja, do, **kw):
    return {"key": T(key, en, ja), "do": do, **kw}


MOOD = {
    "shop": {"ambient": "#a89888", "lamps": [[0.5, 0.42, 1.1, "#ffc070"]]},
    "stockroom": {"ambient": "#8a8078", "lamps": [[0.5, 0.2, 1.0, "#ffd090"]]},
    "street": {"ambient": "#8088a8", "lamps": [[0.3, 0.3, 1.0, "#ffb060"], [0.8, 0.2, 0.8, "#ffd090"]]},
    "cellar": {"ambient": "#7a8088", "lamps": [[0.45, 0.4, 0.9, "#ffc080"]]},
    "receipt_stair": {"ambient": "#70888a", "lamps": [[0.5, 0.3, 1.0, "#ffc070"]]},
    "toll_gate": {"ambient": "#708088", "lamps": [[0.3, 0.3, 0.9, "#ffc070"], [0.7, 0.3, 0.9, "#ffc070"]]},
    "bone_arcade": {"ambient": "#80708a", "lamps": [[0.5, 0.25, 1.1, "#ffc070"]]},
    "reliquary": {"ambient": "#88708a", "lamps": [[0.4, 0.4, 1.0, "#ffb070"]]},
    "lantern_row": {"ambient": "#70889a", "lamps": [[0.3, 0.3, 1.0, "#ffd090"], [0.75, 0.35, 1.0, "#ffd090"]]},
    "archive": {"ambient": "#8a8070", "lamps": [[0.5, 0.2, 1.0, "#ffd090"]]},
    "market": {"ambient": "#70888a", "lamps": [[0.5, 0.3, 1.1, "#ffc070"]]},
    "counting_house": {"ambient": "#708a78", "lamps": [[0.5, 0.35, 1.0, "#a0ffb0"]]},
    "heart_vault": {"ambient": "#906870", "lamps": [[0.5, 0.45, 1.3, "#ff6060"]]},
    "mirror_hall": {"ambient": "#88788a", "lamps": [[0.3, 0.35, 1.0, "#ffc080"], [0.7, 0.35, 1.0, "#ffc080"]]},
    "dawn": {"ambient": "#b0b8c8", "lamps": []},
}
MAP = {"street": [0.12, 0.08], "shop": [0.38, 0.08], "stockroom": [0.64, 0.08],
       "cellar": [0.38, 0.27], "receipt_stair": [0.38, 0.46], "mirror_hall": [0.64, 0.46],
       "bone_arcade": [0.12, 0.65], "reliquary": [0.12, 0.86], "lantern_row": [0.38, 0.65],
       "archive": [0.64, 0.65], "toll_gate": [0.88, 0.46], "market": [0.88, 0.65],
       "counting_house": [0.88, 0.86], "heart_vault": [0.64, 0.86]}


def room(rid, hotspots, enter=None, music="explore"):
    r = {"name_key": "r_" + rid, "plate": rid, "music": music, "mood": MOOD.get(rid, {}), "hotspots": hotspots}
    if enter:
        r["enter_event"] = enter
    return r


for rid, en, ja in [("shop", "The shop", "店"), ("stockroom", "The stock room", "在庫部屋"), ("street", "Gilt Lane", "ギルト小路"),
                    ("cellar", "The cellar", "地下室"), ("receipt_stair", "The Receipt Stair", "受領の階段"),
                    ("toll_gate", "The toll gate", "通行税の門"), ("bone_arcade", "The Bone Arcade", "骨のアーケード"),
                    ("reliquary", "The reliquary stall", "聖遺物の屋台"), ("lantern_row", "Lantern Row", "灯籠通り"),
                    ("archive", "The unclaimed archive", "未請求の書庫"), ("market", "The Ossuary Market", "骨の市場"),
                    ("counting_house", "Calder's counting house", "カルダーの勘定場"), ("heart_vault", "The vault under the Market", "市場の下の金庫室"),
                    ("mirror_hall", "The last landing", "最後の踊り場"), ("dawn", "The shop, at dawn", "夜明けの店")]:
    T("r_" + rid, en, ja)


def night(nid, en, ja, sub_en, sub_ja, turns, clock, per, start_room, start_event, rooms, events):
    T(nid + "_title", en, ja)
    T(nid + "_sub", sub_en, sub_ja)
    return {"id": nid, "title_key": nid + "_title", "sub_key": nid + "_sub", "turns": turns, "clock_start": clock,
            "minutes_per_turn": per, "start_room": start_room, "start_event": start_event,
            "map": {"image": "ledger", "rooms": {r: MAP[r] for r in rooms}}, "rooms": rooms, "events": events}


def price(item, tiers, vals, branches, trust_track, after):
    """LOW / FAIR / HIGH with the original numbers; FAIR earns 1 trust, HIGH 2."""
    keys = {"low": ("LOW — %d. They will take it.", "安値 — %d。相手は呑むだろう。"),
            "fair": ("FAIR — %d. What it is worth.", "適正 — %d。物の値打ちどおり。"),
            "high": ("HIGH — %d. More than it is worth.", "高値 — %d。値打ち以上。")}
    opts = []
    for tier, rank in (("low", 0), ("fair", 2), ("high", 1)):
        en, ja = keys[tier]
        do = [{"take": "coin", "n": vals[tier]}, {"flag": f"price_{item}_{tier}"}]
        if tier == "fair":
            do.append({"trust": 1, "track": trust_track})
        if tier == "high":
            do.append({"trust": 2, "track": trust_track})
        do += branches[tier]
        opts.append(opt(f"price_{item}_{tier}", en % vals[tier], ja % vals[tier], do, auto_rank=rank))
    return [{"choice": opts}] + after


NIGHTS = {}

# ================================================================== HOUR ONE: midnight (trial)
h1_rooms = {
    "shop": room("shop", [
        ev("counter", [0.42, 0.55], "h1_counter", "counter", "Open the counter", "カウンターを開ける", if_flag="tamsin_done"),
        search("window", [0.18, 0.32], "h1_window", "window", "The gold letters", "金文字", xp=5),
        search("shelves", [0.82, 0.38], "h1_shelves", "shelves", "The shelves", "棚", gives=["tea"]),
        search("clock", [0.62, 0.22], "h1_clock", "clock", "The wrong clock", "狂った時計", xp=5),
        door("to_stock", "stockroom", [0.92, 0.84]),
        door("to_street", "street", [0.08, 0.84], turns=1),
        door("to_cellar", "cellar", [0.5, 0.84], if_flag="tamsin_done"),
    ]),
    "stockroom": room("stockroom", [
        search("safe", [0.3, 0.6], "h1_safe", "safe", "Elsa's safe", "エルサの金庫", gives=["lantern"], xp=5),
        search("boxes", [0.7, 0.62], "h1_boxes", "boxes", "Unclaimed boxes", "請け出されない箱", gives=["salts"]),
        search("ledgers", [0.55, 0.3], "h1_ledgers", "ledgers", "Old ledgers", "古い帳簿", gives=["elsa_note"], xp=10),
        door("to_shop", "shop", [0.08, 0.84]),
    ], enter="h1_stock"),
    "street": room("street", [
        enemy("pledge", "pledge", [0.62, 0.5], "h1_pledge_pre", "h1_pledge_post"),
        search("gutter", [0.3, 0.75], "h1_gutter", "gutter", "The gutter", "側溝", gives=["bone_charm"]),
        ev("shelter", [0.85, 0.45], "h1_shelter", "shelter", "The bus shelter", "バス停", if_flag="tamsin_done"),
        door("to_shop", "shop", [0.5, 0.84], turns=1),
    ], enter="h1_street"),
    "cellar": room("cellar", [
        search("candle", [0.3, 0.4], "h1_candle", "candle", "The candle", "蝋燭", xp=5),
        ev("hatch", [0.55, 0.66], "h1_hatch", "hatch", "The hatch", "跳ね上げ戸", if_not_flag="hatch_open"),
        door("to_shop", "shop", [0.08, 0.84]),
        door("to_stair", "receipt_stair", [0.6, 0.84], if_flag="hatch_open"),
    ], enter="h1_cellar"),
    "receipt_stair": room("receipt_stair", [
        enemy("keeper", "keeper", [0.42, 0.5], "h1_keeper_pre", "h1_keeper_post"),
        search("slips", [0.18, 0.35], "h1_slips", "slips", "Tickets in the wall", "壁の質札", xp=10),
        search("niche", [0.8, 0.6], "h1_niche", "niche", "A niche", "壁龕", gives=["bone_charm", "bone_charm", "curio_key"], if_flag="keeper_done"),
        enemy("clerk", "clerk", [0.6, 0.45], "h1_clerk_pre", "h1_clerk_post", if_flag="keeper_done"),
        door("to_cellar", "cellar", [0.08, 0.84]),
    ], enter="h1_stair"),
}
h1_events = {
    "h1_open": [{"bg": "shop"}, {"music": "explore"}, L(171, 191), {"show": "tamsin", "x": 0.7}, L(199, 218),
                N("h1_talk_0", "She waits for a number. You could give her something else first.", "彼女は数字を待っている。その前に、別のものを渡すこともできる。"),
                {"choice": [
                    opt("h1_talk_flat", "\"Two days. Where are you going after?\"", "「あと二日。そのあとはどこへ？」", [
                        S("tam", "h1_flat_1", "My sister's. Box room. I'll be thirty-five in a box room with a single bed and a view of a bin.", "妹のところ。物置部屋。三十五にもなって、シングルベッドとゴミ箱しか見えない物置部屋よ。"),
                        S("nara", "h1_flat_2", "I've had worse views.", "もっとひどい景色も見たことあるわ。"),
                        S("tam", "h1_flat_3", "Have you? Good. That helps, actually. Weirdly.", "そうなの？よかった。なんだか、それ効くわね。妙に。"),
                        {"trust": 1, "track": "tamsin"}], auto_rank=2),
                    opt("h1_talk_cast", "\"It's a good casting. Somebody chose this.\"", "「いい鋳物ね。誰かが選んだものよ」", [
                        S("tam", "h1_cast_1", "I chose it. Out of a catalogue, eight years ago, on a Sunday, with someone reading the prices out.", "私が選んだの。八年前の日曜、カタログで。誰かが値段を読み上げてくれて。"),
                        N("h1_cast_2", "She does not say who. She does not have to; the finial is warm from her hands, and it remembers.", "誰とは言わない。言う必要もない。飾りは彼女の手で温まっていて、覚えている。"),
                        {"trust": 1, "track": "tamsin"}], auto_rank=1),
                    opt("h1_talk_none", "Say nothing. Price it.", "何も言わず、値をつける。", [], auto_rank=0)]},
                {"choice": [
                    opt("h1_read", "Put a hand on it. (the shop is not charging for this one)", "手を置く。（今回は店も代金を取らない）", [
                        V("v_greet_1"),
                        N("h1_clue", "Unscrewed in a hurry. The thread is bright where the tool slipped.", "急いで外された。工具が滑ったところだけ、ねじ山が光っている。"),
                        L(229),
                        N("h1_duel_1", "Her palm goes flat. The brass does not open. It pushes back, the way a held breath pushes back.", "掌を平らに置く。真鍮は開かない。止めた息のように、押し返してくる。"),
                        N("h1_duel_2", "Every object has an hour it would rather keep. You have to talk it out of its hands.", "どの品にも、手放したくない一時がある。それを手から引き剥がすように、説き伏せなければならない。"),
                        V("v_near_0"),
                        {"battle": "echo_finial"}, V("v_win_0"),
                        L(256), {"cg": "cg_tamsin"}, L(257, 263), {"hide_cg": True}, L(265, 269),
                        {"flag": "read_finial"}, give_q("n_read")], auto_rank=1),
                    opt("h1_blind", "Leave it. Price the brass and let her go home.", "やめておく。真鍮の値をつけて帰してやる。", [
                        L(243, 246), {"flag": "refused_finial"}, give_q("n_refused")], auto_rank=0)]},
                L(276, 277)] + price("finial", None, {"low": 14, "fair": 22, "high": 33}, {
                    "low": [L(287, 292)],
                    "fair": [V("v_win_2"), L(296, 306)],
                    "high": [L(310, 318),
                             {"if_flag": "read_finial", "then": [{"if_trust": 3, "track": "tamsin",
                                                                  "then": [V("v_unlock_0"), {"cg": "cg_finial"}, L(320, 321), {"hide_cg": True}],
                                                                  "else": [L(320, 321), N("h1_finial_hint", "(Tamsin's trust 3 would have shown you the rest of that morning.)", "（タムシンの信頼が3あれば、あの朝の続きが見えた。）")]}],
                              "else": [L(320, 321)]}]}, "tamsin", [
                    {"show": ""}, {"give": "ticket_tamsin"}, {"flag": "tamsin_done"},
                    N("h1_after_1", "The bell. The rain. The finial on the shelf behind her, being worth twenty-two.", "ベル。雨。背後の棚の上で、二十二の値打ちのままの飾り。"),
                    N("h1_after_2", "And under the floor, under the stock room, something that is not the boiler knocks three times, politely, like a clerk at a door.", "そして床の下、在庫部屋の下で、ボイラーではない何かが三度、礼儀正しく叩く。扉の前の書記のように。"),
                    S("nara", "h1_after_3", "Not tonight. I've got a full book.", "今夜はだめ。帳簿が埋まってるの。"),
                    N("h1_after_4", "It knocks again. The shop has never once cared how full her book is.", "また叩く。店は一度だって、彼女の帳簿の混み具合など気にしたことがない。"),
                    N("h1_counter_tip", "(Between clients the counter is yours: walk-ins with things to pledge or sell. Touch them to see what they are worth and catch the fakes, lend at interest, buy, sell what the descent brings up. The stair takes a toll every time; the estate wants 200 at dawn.)", "（客と客のあいだ、カウンターはあなたのもの。質入れや売却に来る飛び込み客。手で触れて値打ちを見極め、偽物を見抜き、利息つきで貸し、買い取り、下で手に入れた品を売る。階段は降りるたびに通行税を取り、夜明けには遺産が200を求める。）"),
                    N("h1_tutorial", "(Walk the rooms: click a place to look, a door to go through. Haggles and readings are standoffs — wear their Resolve down before their Claim on you reaches 100. Appraise first: everyone has soft spots.)", "（部屋を歩いて調べよう。場所をクリックで調べ、扉で移動。値切りと読み取りは「対決」だ。相手の請求が100に達する前に、意地を削りきろう。まずは鑑定。誰にでも弱みがある。）")]),
    "h1_counter": [V("v_greet_0"), {"screen": "res://scripts/counter.gd", "args": {"mode": "counter", "hour": "h1"}}],
    "h2_counter": [{"screen": "res://scripts/counter.gd", "args": {"mode": "counter", "hour": "h2"}}],
    "h3_counter": [{"screen": "res://scripts/counter.gd", "args": {"mode": "counter", "hour": "h3"}}],
    "h5_counter": [{"screen": "res://scripts/counter.gd", "args": {"mode": "counter", "hour": "h5"}}],
    "h2_stalls": [{"screen": "res://scripts/counter.gd", "args": {"mode": "market"}}],
    "h4_stalls": [{"screen": "res://scripts/counter.gd", "args": {"mode": "market"}}],
    "h1_window": [V("v_idle_1"), N("h1_window_1", "TWO PRICES ON EVERYTHING, backwards, in gold, from the inside. From in here it reads like a spell, which Elsa always said it was.", "「すべてのものに二つの値段」。内側から、逆さまの金文字で。ここから見ると呪文のようだ。エルサはいつも、実際そうだと言っていた。")],
    "h1_shelves": [N("h1_shelves_1", "Tonight's restock: a clarinet with no reed, six teaspoons, a tin of tea nobody pawned. The tea she takes.", "今夜の入荷。リードのないクラリネット、ティースプーン六本、誰も質入れしていない紅茶の缶。紅茶はもらっておく。")],
    "h1_clock": [N("h1_clock_1", "Wrong since 1998, by eleven minutes, always the same eleven. Elsa said the clock was keeping somebody else's time and it would be rude to correct it.", "1998年から十一分狂っている。いつも同じ十一分。誰か別の人の時間を刻んでいるのだから直すのは失礼だ、とエルサは言っていた。")],
    "h1_stock": [N("h1_stock_1", "Shelves to the ceiling of things whose thirty days ran out. They are the shop's now. They do not look grateful.", "天井まで続く棚。三十日が過ぎた品々。今はもう店のものだ。ありがたがっている様子はない。")],
    "h1_safe": [N("h1_safe_1", "Elsa's safe, combination her birthday, which is a thing she told Nara and the window cleaner. Inside: the stair lantern, still trimmed.", "エルサの金庫。暗証番号は彼女の誕生日。それをナラと窓拭きに教えていた。中には階段用のランタン。芯はまだ整えてある。")],
    "h1_boxes": [N("h1_boxes_1", "A box of a stranger's medicine cabinet. The smelling salts are older than she is and still work.", "見知らぬ誰かの薬棚の中身を詰めた箱。気付け塩は彼女より年上で、まだ効く。")],
    "h1_ledgers": [N("h1_ledgers_1", "1974 to 1981. Elsa's hand. A note is folded into July 1979: Never pay the Bailiff in coin. He keeps the coin AND the debt.", "1974年から1981年。エルサの字。1979年7月の頁にメモが挟んである。『執達吏に硬貨で払うな。硬貨も借りも両方持っていかれる』")],
    "h1_street": [N("h1_street_1", "Gilt Lane at midnight: one lamp, the shop's window, and the rain standing in the air.", "真夜中のギルト小路。街灯がひとつ、店の窓、そして宙に立ちつくす雨。")],
    "h1_gutter": [N("h1_gutter_1", "A bone charm in the gutter, washed up from somewhere it should not have been able to wash up from. Market money. She pockets it.", "側溝に骨の護符。流れてくるはずのない場所から流れてきた。市場の通貨だ。ポケットにしまう。")],
    "h1_shelter": [{"if_flag": "price_finial_low",
                    "then": [N("h1_shelter_low", "Tamsin is at the bus shelter. She sees the shop's lamp and turns her back to it, and that is fair.", "タムシンがバス停にいる。店の灯りを見ると、背を向けた。当然のことだ。")],
                    "else": [N("h1_shelter_1", "Tamsin is at the bus shelter with the money in her back pocket and no coat. She lifts a hand. Nara lifts one back.", "タムシンが、尻ポケットに金を入れ、コートもなしにバス停にいる。手を上げる。ナラも上げ返す。"),
                             S("tam", "h1_shelter_2", "I'm going to bring you the other three!", "残りの三つも持ってくるから！"),
                             S("nara", "h1_shelter_3", "I'll be here. I'm always here.", "いるわ。いつもいる。"),
                             {"trust": 1, "track": "tamsin"}]}],
    "h1_pledge_pre": [N("h1_pledge_1", "Someone is standing at the shop window with their hands cupped to the glass. Not solid. A pledge who never came back for their ticket, and still looks in.", "誰かが店の窓に両手を当てて覗き込んでいる。実体がない。質札を受け取りに戻らなかった質入れ人が、今も覗いている。"),
                      S("nara", "h1_pledge_2", "We're closed. And you're thirty days late. About thirty years late.", "閉店よ。それに三十日遅れ。三十年くらい遅れてる。")],
    "h1_pledge_post": [N("h1_pledge_3", "It takes its hands off the glass. The prints stay a while, then the rain has them.", "それは窓から手を離す。手形はしばらく残り、やがて雨にさらわれた。"), {"flag": "pledge_done"}],
    "h1_cellar": [N("h1_cellar_1", "Brick arches, a ladder, a hatch in the floor with a ring for a handle. The ring is warm.", "煉瓦のアーチ、梯子、床の跳ね上げ戸。取っ手の輪が温かい。")],
    "h1_candle": [N("h1_candle_1", "One candle, always lit. Nobody lights it.", "蝋燭が一本、いつも灯っている。誰も灯していないのに。")],
    "h1_hatch": [N("h1_hatch_1", "She lifts it. Under it, steps: paper, pressed hard as slate, going down out of the candle's reach.", "持ち上げる。その下に階段。石板のように固く押し固められた紙が、蝋燭の届かないところへ降りていく。"),
                 {"cg": "cg_descent"},
                 N("h1_hatch_2", "The Receipt Stair. Forty-one treads to the Market, and on a night like this, landings that are not always there, and people on them who want something stamped.", "受領の階段。市場まで四十一段。今夜のような夜には、いつもはない踊り場が現れ、そこに何かに判を押してほしい者たちがいる。"),
                 S("nara", "h1_hatch_3", "One landing. Then back up for the next name.", "踊り場ひとつ分だけ。それから次の名前のために戻る。"),
                 {"hide_cg": True}, {"flag": "hatch_open"}, {"xp": 10}],
    "h1_stair": [V("v_stage_1"), N("h1_stair_1", "Paper underfoot. The walls are tickets too, side-on, thousands of them, and the oldest still smell of the pockets they were kept in.", "足元は紙。壁も横向きの質札で、何千枚もある。いちばん古いものは、しまわれていたポケットの匂いがまだする。")],
    "h1_slips": [N("h1_slips_1", "Silver christening cup. Held 30 days. Unredeemed. — She stops reading at the second one. She always stops at the second one.", "『銀の洗礼杯。三十日預かり。請け出しなし』。二枚目で読むのをやめる。いつも二枚目でやめる。")],
    "h1_niche": [N("h1_niche_1", "Somebody left change in the niche for whoever comes down. Two bone charms, warm.", "誰かが、降りてくる者のために壁龕に小銭を置いていった。骨の護符が二つ、温かい。")],
    "h1_keeper_pre": [N("h1_keeper_1", "A woman in a grey hood sits on the landing with a lantern on her knee and a hand out, palm up.", "灰色の頭巾の女が踊り場に座り、膝にランタン、掌を上にして手を差し出している。"),
                      S("keeper", "h1_keeper_2", "Toll. Everyone pays going down. Not everyone pays coming up.", "通行税。降りる者はみな払う。上ってくる者がみな払うとは限らないけれど。")],
    "h1_keeper_post": [S("keeper", "h1_keeper_3", "Go on, then. Mind the eleventh step, it's somebody's divorce.", "行きなさい。十一段目に気をつけて。誰かの離婚だから。"), {"flag": "keeper_done"}],
    "h1_clerk_pre": [N("h1_clerk_1", "At the turn of the landing a desk that should not fit there, and behind it a clerk in a bowler hat with a face like a well-kept skull, which is what it is.", "踊り場の曲がり角に、入るはずのない机。その向こうに山高帽の書記。よく手入れされた頭蓋骨のような顔。というより、そのものだ。"),
                     S("clerk", "h1_clerk_2", "Quill. The night's first entry. You owe it a stamp, and I owe you nothing, and we are going to argue about which.", "クイル。今夜最初の記帳だ。君は判をひとつ借りている。私は君に何も借りていない。どちらがどちらか、議論しよう。"),
                     N("h1_clerk_3", "He opens a ledger the size of a door. The finial is already in it.", "扉ほどもある帳簿を開く。もう飾りが記されている。")],
    "h1_clerk_post": [V("v_win_1"), S("clerk", "h1_clerk_4", "Stamped. Received in good order. Go up; you have another name in the book at twenty past.", "押印済み。良好な状態で受領。上へ戻りたまえ。十二時二十分に次の名前がある。"),
                      N("h1_clerk_5", "The stamp is still wet on the receipt he gives her. It smells of the shop.", "渡された受領証の判はまだ濡れている。店の匂いがする。"),
                      {"flag": "h1_done"}, {"end_night": True, "next": "h2"}],
}
NIGHTS["h1"] = night("h1", "Midnight", "午前零時", "The finial, and the first landing", "真鍮の飾りと、最初の踊り場",
                     70, 23 * 60 + 58, 1, "shop", "h1_open", h1_rooms, h1_events)

# ================================================================== HOUR TWO: twenty past twelve
h2_rooms = {
    "shop": room("shop", [
        ev("counter", [0.42, 0.55], "h2_counter", "counter", "Open the counter", "カウンターを開ける"),
        search("case", [0.75, 0.4], "h2_case", "case", "The pocket-watch case", "懐中時計のケース", xp=5),
        door("to_cellar", "cellar", [0.5, 0.84]),
    ]),
    "cellar": room("cellar", [
        door("to_shop", "shop", [0.08, 0.84]),
        door("to_stair", "receipt_stair", [0.6, 0.84]),
    ]),
    "receipt_stair": room("receipt_stair", [
        enemy("pledge2", "pledge2", [0.5, 0.5], "h2_pledge_pre", "h2_pledge_post"),
        door("to_cellar", "cellar", [0.08, 0.84]),
        door("to_arcade", "bone_arcade", [0.9, 0.84], if_flag="pledge2_done"),
    ], enter="h2_stair"),
    "bone_arcade": room("bone_arcade", [
        enemy("haggler", "haggler", [0.5, 0.48], "h2_haggler_pre", "h2_haggler_post"),
        ev("stalls", [0.35, 0.7], "h2_stalls", "stalls", "Trade at the stalls", "屋台で取引", if_flag="haggler_done"),
        search("costume", [0.2, 0.5], "h2_costume", "costume", "The costume stall", "衣装の屋台", gives=["velvet"]),
        search("tickets", [0.82, 0.55], "h2_tickets", "tickets", "A basket of old tickets", "古い質札の籠", xp=10, if_flag="haggler_done"),
        door("to_stair", "receipt_stair", [0.08, 0.84]),
        door("to_reliquary", "reliquary", [0.92, 0.84], if_flag="haggler_done"),
    ], enter="h2_arcade"),
    "reliquary": room("reliquary", [
        search("jars", [0.25, 0.4], "h2_jars", "jars", "Jars", "瓶", gives=["peppermint", "curio_ring"]),
        search("loupe", [0.78, 0.6], "h2_loupe", "loupe", "A tray of loupes", "ルーペの盆", gives=["loupe"], xp=5),
        enemy("broker", "broker", [0.5, 0.48], "h2_broker_pre", "h2_broker_post"),
        door("to_arcade", "bone_arcade", [0.08, 0.84]),
    ], enter="h2_reliquary"),
}
h2_events = {
    "h2_open": [{"bg": "shop"}, {"music": "explore"}, {"show": "ivo", "x": 0.7}, L(339, 373),
                N("h2_talk_0", "He is watching your hands. You could give him something to watch instead.", "彼はあなたの手を見ている。代わりに見るものを与えることもできる。"),
                {"choice": [
                    opt("h2_talk_ink", "\"Twenty-two?\" (the tattoo)", "「二十二の時？」（刺青を見て）", [
                        S("ivo", "h2_ink_1", "Twenty-three. A swallow. It's meant to bring you home.", "二十三だ。燕。家に帰れるようにって意味だ。"),
                        S("nara", "h2_ink_2", "Did it?", "帰れた？"),
                        S("ivo", "h2_ink_3", "It brought me here. Close enough, some nights.", "ここに連れてきた。夜によっては、それで十分だ。"),
                        {"trust": 1, "track": "ivo"}], auto_rank=1),
                    opt("h2_talk_none", "Say nothing.", "何も言わない。", [], auto_rank=0)]},
                {"choice": [
                    opt("h2_take", "Take the reading anyway. (35 out of the till)", "それでも読み取る。（金庫から35）", [
                        {"take": "coin", "n": 35}, give_q("fees", 35), L(389, 391),
                        N("h2_duel_1", "The gold is not warm. It is shut, the way a mouth is shut. It knows it was asked about.", "金は温かくない。口を閉じるように閉ざされている。尋ねられたことを知っているのだ。"),
                        {"battle": "echo_ring"},
                        {"cg": "cg_ring"}, L(425, 431), {"hide_cg": True}, V("v_fail_0"), L(433, 451),
                        {"flag": "read_ring"}, give_q("n_read")], if_has="coin", n=35, auto_rank=0),
                    opt("h2_broke", "Take the reading anyway — but the drawer is short.", "それでも読み取る — だが引き出しの金が足りない。", [
                        L(401, 403), {"flag": "refused_ring"}, give_q("n_refused")], if_lacks="coin", n=35, auto_rank=0),
                    opt("h2_decline", "Don't. He asked.", "やめる。彼に頼まれたのだから。", [
                        L(411, 415), {"flag": "refused_ring"}, give_q("n_refused"), {"trust": 2, "track": "ivo"}], auto_rank=2)]},
                L(458)] + price("ring", None, {"low": 26, "fair": 40, "high": 60}, {
                    "low": [L(468, 472)], "fair": [L(476, 486)], "high": [L(490, 498)]}, "ivo", [
                    {"show": ""}, {"give": "ticket_ivo"}, {"flag": "ivo_done"},
                    N("h2_after_1", "Twelve forty. The knock again, from under the stock room, three times. The receipt in her apron pocket has a second line on it now, in a hand that is not hers: Arcade. Bring the ring's ticket.", "十二時四十分。また在庫部屋の下から三度のノック。エプロンのポケットの受領証に二行目が増えている。彼女のものではない字で。『アーケードへ。指輪の質札を持て』"),
                    S("nara", "h2_after_2", "I'm a pawnbroker, not a postman.", "私は質屋よ、郵便屋じゃない。")]),
    "h2_case": [V("v_stage_0"), N("h2_case_1", "Pocket watches, all stopped at different times, all of them right twice a day. Ivo looked at these for four seconds once and they still remember it.", "懐中時計。どれも違う時刻で止まり、どれも一日に二度だけ正しい。アイヴォが四秒だけ眺めたことを、まだ覚えている。")],
    "h2_stair": [{"if_has": "coin", "n": 25, "then": [{"take": "coin", "n": 25}, N("toll_paid", "The Toll-Keeper's lantern on the first landing: twenty-five out of the till, every descent. Till: {#coin}.", "最初の踊り場に通行税の番人のランタン。降りるたびに金庫から二十五。金庫：{#coin}。")], "else": [N("toll_short", "The Toll-Keeper looks at the drawer and lets her pass on credit, which she writes down.", "通行税の番人は引き出しを見て、つけで通す。しっかり書き留めて。")]}, N("h2_stair_1", "Lower than the first landing. The treads here are older: carbon copies, purple, the kind nobody has made since the eighties.", "最初の踊り場より下。ここの踏み板は古い。紫のカーボンコピー。八十年代から誰も作っていない類のものだ。")],
    "h2_pledge_pre": [N("h2_pledge_1", "A man sits on a step in a wet overcoat, which is a thing he pawned, and is still wearing, which is how you know where you are.", "濡れたオーバーコートの男が段に座っている。質入れしたはずのコートを、まだ着ている。それで、ここがどこかわかる。"),
                      S("nara", "h2_pledge_2", "That coat's ours. Thirty days, 1987. You never came back.", "そのコート、うちのよ。1987年、三十日。あなたは戻ってこなかった。")],
    "h2_pledge_post": [N("h2_pledge_3", "He takes the coat off, folds it over his arm, and is gone, and so is the coat. The shop has one fewer overcoat. It does not mind.", "彼はコートを脱ぎ、腕に掛け、消える。コートも一緒に。店のオーバーコートが一着減った。店は気にしない。"), {"flag": "pledge2_done"}],
    "h2_arcade": [N("h2_arcade_1", "The Bone Arcade: an avenue of stalls under arches of femur and rib, which sounds worse than it is and looks better than it should.", "骨のアーケード。大腿骨と肋骨のアーチの下に続く屋台の通り。聞こえほど悪くはなく、見た目は思ったより良い。")],
    "h2_costume": [N("h2_costume_1", "A velvet jacket, bottle-green, cut for a woman who talked for a living. Nobody is minding the stall. She leaves a charm's worth of thanks in her head and takes it.", "瓶緑のベルベットの上着。話すことを生業にしていた女のために仕立てられている。店番はいない。頭の中で護符ひとつ分の礼を置いて、もらっていく。")],
    "h2_tickets": [N("h2_tickets_1", "Old Ossian's basket: tickets from other shops, sold on when the shops closed. One from Hale & Daughter, three years ago. Ring, gold. Pledger: I. Glass. Never redeemed.", "オシアン爺の籠。閉店した他の店の質札が流れてきたもの。三年前、ヘイル＆ドーター商会の一枚。『指輪、金。質入れ人：I・グラス。請け出しなし』"),
                    S("nara", "h2_tickets_2", "Elsa's ring. The one he asked her not to read.", "エルサのときの指輪。読まないでと頼んだ、あの。"),
                    N("h2_tickets_3", "She buys it back for nothing, which Ossian allows because nobody else ever asks, and pins it into the book under Ivo's name. Some debts are only paperwork.", "オシアンはただで譲ってくれる。誰も欲しがらないからだ。彼女はそれを帳簿のアイヴォの名の下に留める。紙の上だけの借りもある。"),
                    {"trust": 1, "track": "ivo"}],
    "h2_haggler_pre": [N("h2_haggler_1", "Old Ossian, who sells doors and keys and never both to the same person, has bone on every finger and a grin with a gap in it you could post a ticket through.", "扉と鍵を売るが、同じ相手には決して両方を売らないオシアン爺。指という指に骨の指輪、質札が一枚通りそうな歯の隙間のある笑み。"),
                       S("haggler", "h2_haggler_2", "Elsa's girl! Come to sell? Come to buy? Come to be sold? Let's find out together.", "エルサの嬢ちゃん！売りに来たか？買いに来たか？売られに来たか？一緒に確かめようじゃないか。")],
    "h2_haggler_post": [S("haggler", "h2_haggler_3", "Ha! She drives Elsa's bargain. Fine, fine. The basket's yours to rummage. Mind the broker, she's in a mood.", "はっ！エルサ譲りの値切りだ。いいとも。籠は好きに漁りな。仲買人には気をつけな、機嫌が悪い。"), {"flag": "haggler_done"}],
    "h2_reliquary": [N("h2_reliquary_1", "Jars on shelves to the vault: a breath, a first word, the smell of a particular kitchen. Each one labelled, priced, and very slightly fogged from inside.", "天井まで瓶の並ぶ棚。吐息、最初の一言、ある台所の匂い。どれもラベルと値札がつき、内側からわずかに曇っている。")],
    "h2_jars": [N("h2_jars_1", "A jar labelled PEPPERMINT, 1952, which is peppermints. Sometimes a thing is only itself.", "『ハッカ、1952年』と書かれた瓶。中身はハッカ飴だ。物がただの物であることも、ときにはある。")],
    "h2_loupe": [N("h2_loupe_1", "A tray of jewellers' loupes, each one still focused on the last thing it looked at. She takes one that is focused on nothing at all.", "宝石鑑定用ルーペの盆。どれも最後に見たものに焦点が合ったままだ。何にも合っていないものをひとつ取る。")],
    "h2_broker_pre": [N("h2_broker_1", "The Hollow Broker wears a porcelain face with nothing behind the eyes and works an abacus with beads of teeth.", "虚ろな仲買人は、目の奥に何もない磁器の顔をつけ、歯の珠の算盤を弾く。"),
                      S("broker", "h2_broker_2", "You carry a ticket for a reading you did or did not take. Either way it has a price. I buy prices.", "あなたは、取ったか取らなかったかした読み取りの質札を持っている。どちらにせよ値がつく。私は値段を買うのよ。"),
                      S("nara", "h2_broker_3", "It isn't for sale.", "売り物じゃないわ。"),
                      S("broker", "h2_broker_4", "Everything is for sale. Some things are merely expensive.", "何だって売り物よ。ただ高いものがあるだけ。")],
    "h2_broker_post": [S("broker", "h2_broker_5", "Expensive, then. I'll write you down as expensive.", "では、高い、と。あなたを『高い』と書いておくわ。"),
                       N("h2_broker_6", "The receipt in Nara's pocket gets a third line: One o'clock. A widow.", "ナラのポケットの受領証に三行目が増える。『一時。未亡人』"),
                       {"flag": "h2_done"}, {"end_night": True, "next": "h3"}],
}
NIGHTS["h2"] = night("h2", "Twenty past twelve", "零時二十分", "The ring, and the Bone Arcade", "指輪と、骨のアーケード",
                     60, 20, 1, "shop", "h2_open", h2_rooms, h2_events)

# ================================================================== HOUR THREE: one o'clock
h3_rooms = {
    "shop": room("shop", [
        ev("counter", [0.42, 0.55], "h3_counter", "counter", "Open the counter", "カウンターを開ける"),
        door("to_cellar", "cellar", [0.5, 0.84]),
    ]),
    "cellar": room("cellar", [
        door("to_shop", "shop", [0.08, 0.84]),
        door("to_stair", "receipt_stair", [0.6, 0.84]),
    ]),
    "receipt_stair": room("receipt_stair", [
        door("to_cellar", "cellar", [0.08, 0.84]),
        door("to_row", "lantern_row", [0.9, 0.84]),
    ], enter="h3_stair"),
    "lantern_row": room("lantern_row", [
        enemy("moth", "moth", [0.35, 0.45], "h3_moth_pre", "h3_moth_post"),
        search("water", [0.7, 0.72], "h3_water", "water", "The canal", "運河", xp=10),
        enemy("bailiff", "bailiff", [0.62, 0.45], "h3_bailiff_pre", "h3_bailiff_post", if_flag="archivist_done"),
        door("to_stair", "receipt_stair", [0.08, 0.84]),
        door("to_archive", "archive", [0.92, 0.84], if_flag="moth_done"),
    ], enter="h3_row"),
    "archive": room("archive", [
        enemy("archivist", "archivist", [0.5, 0.48], "h3_arch_pre", "h3_arch_post"),
        search("shelves", [0.2, 0.4], "h3_shelves", "archshelves", "The N shelf", "Nの棚", gives=["ledger_page"], xp=10, if_flag="archivist_done"),
        search("ladder", [0.82, 0.5], "h3_ladder", "ladder", "The ladder", "梯子", gives=["oilskin", "curio_moon"]),
        door("to_row", "lantern_row", [0.08, 0.84]),
    ], enter="h3_archive"),
}
h3_events = {
    "h3_open": [{"bg": "shop"}, {"music": "explore"}, L(510),
                S("nara", "h3_till", "Till: {#coin}.", "金庫：{#coin}。"),
                N("h3_stock", "Stock on the shelf behind her: 62 of other people's brass and gold.", "背後の棚の在庫：他人の真鍮と金、62。"),
                N("h3_debt", "Against the estate, due in five hours: 200.", "遺産に対する負債、五時間後に期限：200。"),
                {"if_has": "fees", "n": 1,
                 "then": [N("h3_fees", "And in the fourth column, in Elsa's hand, in a ruled section Nara has never filled in and never had to explain: {#fees} spent on knowing.", "そして第四の欄。エルサの字で罫が引かれ、ナラが一度も埋めたことも説明する必要もなかった欄に、知るために払った額：{#fees}。"), L(518)],
                 "else": [L(522, 524)]},
                L(527, 533), V("v_fail_1"),
                {"if_flag": "read_ring", "then": [L(536), V("v_idle_0")], "else": [L(538)]},
                N("h3_hatch", "The hatch behind the stock room has been open since midnight. She has been down twice. There is one more name in the book first.", "在庫部屋の奥の跳ね上げ戸は、真夜中から開いたままだ。もう二度降りた。その前に、帳簿にもう一人の名前がある。"),
                {"show": "mara", "x": 0.7}, L(561, 579),
                N("h3_talk_0", "She is standing very straight. You could let her sit.", "彼女はとてもまっすぐ立っている。座らせてあげることもできる。"),
                {"choice": [
                    opt("h3_talk_chair", "Bring her the chair from behind the counter.", "カウンターの奥から椅子を持ってくる。", [
                        N("h3_chair_1", "Mara looks at the chair for a long moment, and then sits on it like a queen accepting a smaller country.", "マーラは長いあいだ椅子を見つめ、それから、小国を受け入れる女王のように腰を下ろした。"),
                        S("mara", "h3_chair_2", "Elsa never offered me a chair.", "エルサは一度も椅子を勧めなかったわ。"),
                        S("nara", "h3_chair_3", "Elsa never sat down. I've had a long night.", "エルサは座らなかったから。私は長い夜を過ごしてるの。"),
                        {"trust": 1, "track": "mara"}], auto_rank=1),
                    opt("h3_talk_none", "Leave her standing. She chose to.", "立たせておく。彼女がそう選んだのだから。", [], auto_rank=0)]},
                {"choice": [
                    opt("h3_take", "Read it. (20 out of the till)", "読み取る。（金庫から20）", [
                        {"take": "coin", "n": 20}, give_q("fees", 20), L(593, 599),
                        N("h3_duel_1", "Crepe does not hold heat. It holds shape. The pleats close under her hand like a fan being folded against her.", "クレープ地は熱を保たない。形を保つ。ひだが、扇を彼女に向けて畳むように、手の下で閉じていく。"),
                        V("v_near_1"), {"battle": "echo_veil"},
                        L(630, 634), {"cg": "cg_veil"}, L(635, 641), {"hide_cg": True}, V("v_win_big_0"), L(643, 664),
                        {"flag": "read_veil"}, give_q("n_read")], if_has="coin", n=20, auto_rank=2),
                    opt("h3_broke", "Read it — but the drawer is short.", "読み取る — だが引き出しの金が足りない。", [
                        L(608, 611), {"flag": "refused_veil"}, give_q("n_refused")], if_lacks="coin", n=20, auto_rank=0),
                    opt("h3_decline", "Don't. It's a widow's veil and she is standing right there.", "やめる。未亡人のヴェールで、本人が目の前に立っている。", [
                        L(618, 623), {"flag": "refused_veil"}, give_q("n_refused"), {"trust": 2, "track": "mara"}], auto_rank=1)]},
                L(670, 672)] + price("veil", None, {"low": 23, "fair": 35, "high": 52}, {
                    "low": [L(682, 686)], "fair": [L(690, 697)], "high": [L(701, 712)]}, "mara", [
                    {"show": ""}, {"give": "ticket_mara"}, {"flag": "mara_done"},
                    N("h3_after_1", "Half past one. The receipt's fourth line: Lantern Row. The Bailiff is asking after the shop.", "一時半。受領証の四行目。『灯籠通り。執達吏が店のことを尋ねている』"),
                    S("nara", "h3_after_2", "Elsa had a note about him.", "エルサのメモに彼のことがあった。")]),
    "h3_stair": [{"if_has": "coin", "n": 25, "then": [{"take": "coin", "n": 25}, N("toll_paid", "The Toll-Keeper's lantern on the first landing: twenty-five out of the till, every descent. Till: {#coin}.", "最初の踊り場に通行税の番人のランタン。降りるたびに金庫から二十五。金庫：{#coin}。")], "else": [N("toll_short", "The Toll-Keeper looks at the drawer and lets her pass on credit, which she writes down.", "通行税の番人は引き出しを見て、つけで通す。しっかり書き留めて。")]}, N("h3_stair_1", "The stair goes further tonight than it did at midnight. She counts forty-one and keeps going, and the paper underfoot turns damp.", "今夜の階段は真夜中より深い。四十一まで数えても続き、足元の紙が湿ってくる。")],
    "h3_row": [N("h3_row_1", "Lantern Row: a canal under the city that the city does not have, lanterns strung over black water, and everything the water has been given floating just under the surface.", "灯籠通り。街にはないはずの街の下の運河。黒い水の上に灯籠が連なり、水に託されたものがすべて、水面のすぐ下を漂っている。")],
    "h3_water": [N("h3_water_1", "Among the lost things: a brass castor off the foot of a bed. The same casting as the finial. The same catalogue, the same Sunday.", "失せ物の中に、ベッドの脚の真鍮のキャスター。あの飾りと同じ鋳物。同じカタログ、同じ日曜日。"),
                 S("nara", "h3_water_2", "She's losing the whole bed one piece at a time.", "彼女、ベッドを一つずつ失くしていってるのね。"),
                 N("h3_water_3", "She fishes it out and puts it in the book under Tamsin's name, with the finial. Four of anything is a set; this is a start.", "拾い上げ、帳簿のタムシンの名の下に、飾りと一緒に記す。四つ揃えば一組。これはその始まりだ。"),
                 {"trust": 1, "track": "tamsin"}],
    "h3_moth_pre": [N("h3_moth_1", "On a paper lantern too small to hold her sits a woman with moth wings the colour of old lace, and she is mending a veil that is not Mara's, and is.", "抱えきれないほど小さな紙灯籠に、古いレース色の蛾の羽を持つ女が座り、ヴェールを繕っている。マーラのものではなく、そしてマーラのものでもある。"),
                    S("moth", "h3_moth_2", "Every widow's veil comes down here eventually, pawnbroker. I keep them warm. What will you give me for the one you priced?", "未亡人のヴェールはいずれみんなここへ降りてくるのよ、質屋さん。私が温めておくの。あなたが値をつけたあれに、何をくれる？")],
    "h3_moth_post": [S("moth", "h3_moth_3", "You bargain like someone who has been kind tonight. It shows on you, like flour.", "今夜誰かに優しくした人の値切り方ね。小麦粉みたいに、あなたについてる。"),
                     {"choice": [
                         opt("h3_moth_look", "\"Show me the wings.\"", "「羽を見せて」", [
                             S("moth", "h3_moth_4", "Only because you asked properly.", "ちゃんと頼んだから、特別よ。"),
                             {"cg": "cg_moth"},
                             N("h3_moth_5", "She opens them. Lace and dust and lantern light, and under them a woman who has been keeping other people's grief warm for a very long time and has decided, tonight, to be looked at instead.", "彼女は羽を開く。レースと鱗粉と灯籠の光。その下には、他人の悲しみを長いあいだ温めてきて、今夜は見られる側になると決めた女がいる。"),
                             N("h3_moth_6", "Nara looks, because she was invited to, which is a rarer thing on her side of the counter than it should be.", "ナラは見る。招かれたからだ。カウンターのこちら側では、それは本来あるべきより稀なことだ。"),
                             {"hide_cg": True}], auto_rank=1),
                         opt("h3_moth_go", "Thank her and go on.", "礼を言って先へ進む。", [], auto_rank=0)]},
                     {"flag": "moth_done"}],
    "h3_archive": [N("h3_archive_1", "The unclaimed archive: every letter that was in a pocket of something pawned and never collected, filed by surname, forever.", "未請求の書庫。質入れされ、二度と取りに来られなかった品のポケットに入っていた手紙が、すべて姓ごとに、永遠に綴じられている。")],
    "h3_arch_pre": [N("h3_arch_1", "Miss Penrose has ink to the second knuckle and spectacles on a ribbon and has not been entirely alive since 1931, which she regards as a filing matter.", "ペンローズ嬢は第二関節までインクで汚れ、リボンつきの眼鏡をかけ、1931年からずっと完全には生きていない。彼女はそれを書類上の問題とみなしている。"),
                    S("archivist", "h3_arch_2", "You may not browse. Nobody browses. State a surname or leave.", "閲覧はできません。誰も閲覧はしないの。姓を言うか、出ていくか。")],
    "h3_arch_post": [S("archivist", "h3_arch_3", "Voss. V. One item. It was in the lining of a dress. Do try to give it to someone.", "ヴォス。V。一件。ドレスの裏地に入っていたわ。誰かに渡すよう努めて。"),
                     N("h3_arch_4", "A letter addressed to 'M.', never posted. Nara does not open it. She puts it in the book under Mara's name, sealed, where it can wait for her.", "「M」宛ての、投函されなかった手紙。ナラは開けない。封をしたまま帳簿のマーラの名の下に挟み、彼女を待たせておく。"),
                     {"trust": 1, "track": "mara"}, {"flag": "archivist_done"}],
    "h3_shelves": [N("h3_shelves_1", "Q. Quill. A file, thin, opened tonight. Inside, one torn ledger page with her own name on it, in a hand that is nearly hers.", "Q。クイル。薄いファイル、今夜開かれたばかり。中には破れた台帳の頁が一枚。彼女の名前が、ほとんど彼女のものの筆跡で。")],
    "h3_ladder": [N("h3_ladder_1", "On the archive ladder hangs an oilskin coat with ELSA Q. inked inside the collar. Of course it is down here. Of course it fits.", "書庫の梯子に、襟の内側に『ELSA Q.』とインクで書かれた油布のコートが掛かっている。もちろん、ここにある。もちろん、ぴったりだ。")],
    "h3_bailiff_pre": [N("h3_bailiff_1", "On the bridge, blocking it: a tall grey man in a greatcoat with a chain of office, and the chain is made of the little brass tags that hang off pawned keys.", "橋の上に、塞ぐように立つ灰色の長身の男。外套に職章の鎖。その鎖は、質入れされた鍵に下がる小さな真鍮の札でできている。"),
                       S("bailiff", "h3_bailiff_2", "Quill and premises. The estate's debt is two hundred. I am instructed to begin collecting it early, in whatever currency is to hand.", "クイルおよび店舗。遺産の負債は二百。手元にある通貨で、前倒しで取り立てを始めるよう指示されている。"),
                       S("nara", "h3_bailiff_3", "It's due at six.", "期限は六時よ。"),
                       S("bailiff", "h3_bailiff_4", "Everything is due. Six is merely when it is noticed.", "すべては期限を迎えている。六時とは、それに気づかれる時刻にすぎない。")],
    "h3_bailiff_post": [S("bailiff", "h3_bailiff_5", "Noted. Not collected. Noted.", "記録した。徴収はしていない。記録した。"),
                        N("h3_bailiff_6", "He steps aside. Past him, the water opens out into a vault the size of a swimming bath, and the noise of a market.", "彼は脇へ退く。その先で水は広がり、プールほどもある丸天井の空間へ、市場のざわめきへと続いている。"),
                        {"flag": "h3_done"}, {"end_night": True, "next": "h4"}],
}
NIGHTS["h3"] = night("h3", "One o'clock", "午前一時", "The veil, and Lantern Row", "ヴェールと、灯籠通り",
                     60, 60, 1, "shop", "h3_open", h3_rooms, h3_events)

# ================================================================== HOUR FOUR: two o'clock, the Market
SELLER = [("read_veil", "mara", "Mara Voss", "マーラ・ヴォス"), ("read_ring", "ivo", "Ivo Glass", "アイヴォ・グラス"),
          ("read_finial", "tamsin", "Tamsin Reed", "タムシン・リード")]


def newest(fn, i=0):
    """Branch on the newest client reading (veil, then ring, then finial), as the original's
    client_readings()[-1] did."""
    flag, who, en, ja = SELLER[i]
    then = fn(who, en, ja)
    if i == len(SELLER) - 1:
        return then
    return [{"if_flag": flag, "then": then, "else": newest(fn, i + 1)}]


h4_rooms = {
    "market": room("market", [
        search("teeth", [0.2, 0.55], "h4_teeth", "teeth", "The teeth stall", "歯の屋台", xp=5),
        enemy("door_man", "door_man", [0.45, 0.48], "h4_doors_pre", "h4_doors_post"),
        enemy("name_buyer", "name_buyer", [0.7, 0.48], "h4_name_pre", "h4_name_post"),
        ev("stalls", [0.3, 0.7], "h4_stalls", "stalls", "Trade at the stalls", "屋台で取引", if_flag="doors_done"),
        search("instruments", [0.85, 0.6], "h4_instruments", "instruments", "Unstrung instruments", "弦のない楽器", gives=["tea"]),
        door("to_gate", "toll_gate", [0.08, 0.84]),
        door("to_calder", "counting_house", [0.92, 0.84], if_flag="name_done"),
        door("to_vault", "heart_vault", [0.5, 0.84], needs="vault_key", locked_key=T("h4_vault_locked", "A door with nothing behind it. Locked.", "何もない場所に立つ扉。鍵がかかっている。")),
    ], enter="h4_market"),
    "toll_gate": room("toll_gate", [
        enemy("keeper2", "keeper2", [0.5, 0.48], "h4_keeper_pre", "h4_keeper_post"),
        search("booth", [0.8, 0.5], "h4_booth", "booth", "The toll booth", "料金所", gives=["brandy"], if_flag="keeper2_done"),
        door("to_market", "market", [0.92, 0.84]),
    ]),
    "counting_house": room("counting_house", [
        ev("calder", [0.5, 0.45], "h4_calder", "calder", "Calder's desk", "カルダーの机", if_not_flag="calder_done"),
        door("to_market", "market", [0.08, 0.84]),
        ev("upstairs", [0.9, 0.7], "h4_leave", "upstairs", "The stair up", "上り階段", if_flag="calder_done", sim_last=True),
    ]),
    "heart_vault": room("heart_vault", [
        ev("heart", [0.5, 0.45], "h4_heart", "heart", "The thing on the pedestal", "台座の上のもの", if_not_flag="heart_seen"),
        door("to_market", "market", [0.08, 0.84]),
    ]),
}
h4_events = {
    "h4_open": [{"bg": "receipt_stair"}, {"music": "explore"},
                N("h4_open_1", "Two o'clock. The book is empty until five and the drawer has {#coin} in it against a debt of 200, so she goes down.", "二時。五時まで帳簿に名前はなく、引き出しには{#coin}。負債は200。だから彼女は降りる。"),
                {"if_has": "coin", "n": 25, "then": [{"take": "coin", "n": 25}, N("toll_paid", "The Toll-Keeper's lantern on the first landing: twenty-five out of the till, every descent. Till: {#coin}.", "最初の踊り場に通行税の番人のランタン。降りるたびに金庫から二十五。金庫：{#coin}。")], "else": [N("toll_short", "The Toll-Keeper looks at the drawer and lets her pass on credit, which she writes down.", "通行税の番人は引き出しを見て、つけで通す。しっかり書き留めて。")]}, L(732, 739), {"bg": "market"}, {"cg": "cg_market_crowd"}, L(741, 753), {"hide_cg": True}, V("v_stage_2"), L(755, 756),
                {"give": "coin", "n": 30, "quiet": True},
                N("h4_haul", "The stalls take the lot for 30. Till: {#coin}.", "屋台は全部まとめて30で引き取った。金庫：{#coin}。"),
                N("h4_open_2", "Calder's stall is at the far end, past the Door Man and the woman who buys names. She has never once got there without being stopped.", "カルダーの店はいちばん奥、扉売りと名前買いの女の先にある。止められずにたどり着けたことは一度もない。")],
    "h4_market": [],
    "h4_teeth": [N("h4_teeth_1", "Human teeth sorted by decade. Somebody buys them. She has never asked, and tonight, with a hand that has read four things already, she decides not to start.", "年代ごとに仕分けられた人の歯。誰かが買っていく。訊いたことはない。もう四つも読んだ手で、今夜それを始めるのはやめておく。")],
    "h4_instruments": [N("h4_instruments_1", "Unstrung violins, a cello with no bridge, and on a stool, a flask of tea still hot. The Market looks after its regulars.", "弦のないヴァイオリン、駒のないチェロ。腰掛けの上に、まだ熱い紅茶の水筒。市場は常連の面倒を見る。")],
    "h4_doors_pre": [N("h4_doors_1", "Six freestanding doors and Old Ossian among them, grinning. He sells the doors. He does not sell the keys.", "自立する六枚の扉、その間でにやつくオシアン爺。扉は売る。鍵は売らない。"),
                     S("haggler", "h4_doors_2", "Twice in one night! You want a door, Elsa's girl. I can tell. Everybody who comes this far wants a door.", "一晩で二度目！扉が欲しいんだろう、嬢ちゃん。わかるとも。ここまで来た者はみんな扉が欲しくなる。")],
    "h4_doors_post": [S("haggler", "h4_doors_3", "Oh, you. Fine. One key, no door. The door's already there; it's been there since before the Market. Don't tell anyone I sold you both.", "まったく。いいとも。鍵ひとつ、扉なし。扉はもうある。市場より前からな。両方売ったって誰にも言うなよ。"),
                      {"give": "vault_key"}, {"flag": "doors_done"}],
    "h4_name_pre": [N("h4_name_1", "The woman who buys names, cash, no questions: the Hollow Broker again, at her own stall now, with her abacus and her empty eyes.", "名前を現金で、何も訊かずに買う女。また虚ろな仲買人だ。今度は自分の屋台で、算盤と空っぽの目を携えて。"),
                    S("broker", "h4_name_2", "Expensive Quill. I wrote you down. Now let me buy your name, and you'll never have to be expensive again.", "高いクイル。書いておいたわ。名前を売りなさい。そうすれば二度と高くいる必要はない。")],
    "h4_name_post": [S("broker", "h4_name_3", "Still expensive. Go and see the factor. He'll give you a number; he always does.", "まだ高いわね。仲買人のところへ行きなさい。数字をくれるわ。いつもそう。"), {"flag": "name_done"}],
    "h4_keeper_pre": [S("keeper", "h4_keeper_1", "Coming up already? No. Not past me, not till the hour's done. Pay or wait.", "もう上がるの？だめ。この刻が終わるまでは通さない。払うか、待つか。")],
    "h4_keeper_post": [S("keeper", "h4_keeper_2", "Paid in patience. That's the best coin. The booth's open; help yourself.", "忍耐で支払われた。それがいちばんの硬貨。料金所は開いてる。好きにして。"), {"flag": "keeper2_done"}],
    "h4_booth": [N("h4_booth_1", "The toll booth: a ledger of everyone who has gone up, and under the desk, a bottle of brandy with ELSA on the label in pencil.", "料金所。上っていった者すべての台帳。机の下に、ラベルに鉛筆で『ELSA』と書かれたブランデーの瓶。")],
    "h4_heart": [N("h4_heart_1", "Under the Market, behind a door that stood on its own in a crowd: a round room, and on a pedestal a heart of dark red glass, beating slowly, lighting the walls with each beat.", "市場の下、人混みに自立していた扉の向こう。円い部屋。台座の上に暗赤色のガラスの心臓が、ゆっくりと脈打ち、そのたびに壁を照らしている。"),
                 {"cg": "cg_heart"},
                 N("h4_heart_2", "The Heart of the Crypt. Elsa wrote about it once, in the back of a ledger: what the shop actually wants. Every reading, every fee, every instalment, goes here.", "地下聖堂の心臓。エルサが一度だけ、帳簿の裏に書いていた。『店が本当に欲しいもの』。読み取りも、手数料も、分割払いも、すべてここへ行く。"),
                 N("h4_heart_3", "She does not touch it. It is the only object in three years she has met and not wanted to know.", "触れない。この三年で出会った品のうち、知りたいと思わなかった唯一のものだ。"),
                 {"hide_cg": True}, {"give": "curio_heart"}, {"xp": 40}, {"flag": "heart_seen"}],
    "h4_calder": [{"show": "calder", "x": 0.7}, L(758, 788), {"cg": "cg_calder"},
                  N("h4_calder_test", "He puts both gloved hands on the desk. Before Calder deals with anybody, he finds out what they are made of.", "彼は手袋の両手を机に置く。カルダーは誰かと取引する前に、相手が何でできているかを確かめる。"),
                  {"hide_cg": True}, {"battle": "calder"},
                  {"if_count": ["read_finial", "read_ring", "read_veil"], "n": 2,
                   "then": [L(793, 797), {"cg": "cg_market"}, L(803, 809), {"hide_cg": True}],
                   "else": [L(813, 815)]},
                  {"if_count": ["read_finial", "read_ring", "read_veil"], "n": 1,
                   "then": [L(836, 837),
                            N("h4_ninety", "90 would clear the estate on its own and leave her with change and a shop.", "90あれば、それだけで遺産は片づき、釣り銭と店が残る。")]
                           + newest(lambda who, en, ja: [N("h4_newest_" + who, f"The newest one is {en}'s.", f"いちばん新しいのは{ja}のものだ。"),
                                                         {"choice": [
                                                             opt("h4_sell_" + who, f"Sell him {en}'s reading. (90)", f"{ja}の読み取りを彼に売る。（90）", [
                                                                 {"flag": "sold"}, {"flag": "sold_" + who}, L(854, 861),
                                                                 {"give": "coin", "n": 90, "quiet": True},
                                                                 N("h4_sold_till", "Till: {#coin}.", "金庫：{#coin}。")], auto_rank=0),
                                                             opt("h4_refuse_" + who, "Don't. Go back up the stairs.", "やめる。階段を上って戻る。", [L(869, 877)], auto_rank=1)]}]),
                   "else": [L(826, 828)]},
                  {"show": ""}, {"flag": "calder_done"}],
    "h4_leave": [V("v_streak_1"), L(885, 889), {"flag": "h4_done"}, {"end_night": True, "next": "h5"}],
}
NIGHTS["h4"] = night("h4", "Two o'clock", "午前二時", "The Ossuary Market", "骨の市場",
                     70, 120, 1, "market", "h4_open", h4_rooms, h4_events)

# ================================================================== HOUR FIVE: three forty, the last object
SECOND = {  # client -> (item flag, cg, echo, lines)
    "tamsin": ("cg_tamsin_bath", "echo_tamsin2", [
        N("h5_tam_1", "The finial on the shelf has gone warm again. Not the brass: the shelf under it, the way a chair stays warm.", "棚の飾りがまた温かい。真鍮ではなく、その下の棚が。椅子が温もりを残すように。"),
        N("h5_tam_2", "It was priced fairly, and it was found a castor, and it has decided it does not mind her. Objects keep score of the counter as well as the room.", "公正に値をつけられ、キャスターも見つけてもらい、彼女のことを嫌ではないと決めたのだ。品は部屋だけでなく、カウンターでの扱いも覚えている。")], [
        N("h5_tam_3", "The flat again, later. The boxes taped. The bath run in a bathroom with nothing left in it but the bath.", "あの部屋、もっと後。箱には封がされ、浴槽のほかは何も残っていない浴室で、湯が張られている。"),
        N("h5_tam_4", "Tamsin in it to the shoulders, freckles going on forever, looking back over one of them at the door as if somebody might come and say it was a joke.", "肩まで浸かったタムシン。果てしなく続くそばかす。片方の肩越しに扉を振り返る。誰かが来て、冗談だったと言ってくれるかのように。"),
        N("h5_tam_5", "Nobody does. She laughs anyway, once, at the ceiling, and sinks to the chin, and the steam takes the rest. It is the first time tonight Nara has seen her look like the bed was a good bed.", "誰も来ない。それでも彼女は一度、天井に向かって笑い、顎まで沈む。残りは湯気がさらう。あのベッドが良いベッドだったと思える顔を、ナラは今夜はじめて見た。")]),
    "ivo": ("cg_maya", "echo_ring2", [
        N("h5_ivo_1", "Ivo's ticket in the book has writing on the back that was not there at twenty past twelve. His hand: You can look now. I'm asking. Tell me she was happy after. — I.G.", "帳簿のアイヴォの質札に、零時二十分にはなかった書き込みがある。彼の字で。『もう見ていい。頼んでる。そのあと彼女が幸せだったか教えてくれ — I.G.』"),
        S("nara", "h5_ivo_2", "Asking is the part you get to do.", "頼むのは、あなたにできることだものね。")], [
        N("h5_ivo_3", "Not the night of the books and the lamp. A later night, and not his: Maya, alone, on a windowsill in somebody's shirt, rain behind her, the ring on her finger instead of a nightstand.", "本と灯りの夜ではない。もっと後の夜、そして彼のものではない。マヤが一人、誰かのシャツを羽織って窓辺に座り、背後には雨。指輪はナイトスタンドではなく、彼女の指に。"),
        N("h5_ivo_4", "She is turning it to the lamp the way Nara did. Reading the date. Smiling at it, not sadly. The ring was worn, after. That is the answer, and it is a good one.", "ナラがしたように、灯りに向けて回している。日付を読んでいる。悲しくはない微笑み。そのあとも、指輪は着けられていた。それが答えで、良い答えだ。")]),
    "mara": ("cg_mara_letters", "echo_veil2", [
        N("h5_mara_1", "The veil on the shelf, and the letter from the archive in the book under Mara's name, and between them something like permission.", "棚のヴェールと、帳簿のマーラの名の下に挟んだ書庫の手紙。その間に、許しのようなもの。")], [
        N("h5_mara_2", "Earlier than the mirror. The dressing table, two candles, a black slip, and a box of letters in his hand that she is reading for the first time since he wrote them.", "鏡よりも前。化粧台、二本の蝋燭、黒いスリップ。彼の筆跡の手紙の箱を、書かれて以来はじめて読んでいる。"),
        N("h5_mara_3", "Her shoulders are bare and set like a woman reading a contract, and every few lines one of them drops, very slightly. She does not cry. She laughs at the fourth letter, out loud, alone, and puts her hand over her mouth as if to keep it.", "裸の肩は契約書を読む女のように張り詰め、数行ごとにほんのわずか下がる。泣かない。四通目で声を立てて笑い、一人きりで、それを留めておくように口を手で覆う。")]),
}


def second_reading(who):
    cg, echo, pre, body = SECOND[who]
    return [{"if_trust": 5, "track": who,
             "then": pre + [V("v_idle_2"), N("h5_second_" + who, "A second reading. Deeper; it will push back harder.", "二度目の読み取り。より深く、より強く押し返してくる。"),
                            {"battle": echo}] + ([V("v_unlock_1")] if who == "ivo" else []) + [{"cg": cg}] + body + [{"hide_cg": True}, V("v_win_big_1"), {"flag": "second_" + who}, give_q("n_read")],
             "else": [N("h5_cold_" + who, "Cold. It has nothing more to give you yet. (Trust 5 with its owner.)", "冷たい。まだ何も渡すつもりはない。（持ち主の信頼5が必要）")]}]


ENDING_NAME = {"solvent": ("Solvent", "支払可能"), "factor": ("Factor", "仲買人"), "collateral": ("Collateral", "担保")}


def outro(name):
    en, ja = ENDING_NAME[name]
    return [{"bg": "dawn"}, {"music": "dawn"}, {"flag": "ending_" + name},
            N("end_name_" + name, f"[b]{en}.[/b]", f"[b]{ja}。[/b]"),
            N("end_count", "Readings taken: {#n_read}. Refused: {#n_refused}.", "読み取り：{#n_read}。見送り：{#n_refused}。"),
            N("credits_1", "LIEN — the adult fork of Midnight Pawn & Crypt. Thank you for keeping the shop open.", "LIEN — 『Midnight Pawn & Crypt』の成人向け分岐作品。店を開けていてくれて、ありがとう。"),
            {"end_night": True, "next": ""}]


def collateral_end():
    return [{"if_has": "coin", "n": 103, "then": [L(1072)],
             "else": [N("h5_short", "The estate is not settled. She is short, and she signs the extension at nine fifteen, which she is told is routine and which the man behind the glass does not look up for.", "遺産は片づかない。足りず、九時十五分に延長の書類に署名する。よくあることだと言われ、ガラスの向こうの男は顔も上げない。")]},
            {"cg": "cg_collateral", "unlock": False}, L(1076, 1085), {"hide_cg": True}] + outro("collateral")


h5_rooms = {
    "mirror_hall": room("mirror_hall", [
        enemy("auditor", "auditor", [0.5, 0.48], "h5_aud_pre", "h5_aud_post"),
        door("to_cellar", "cellar", [0.9, 0.84], if_flag="auditor_done"),
    ], enter="h5_landing"),
    "cellar": room("cellar", [
        door("to_shop", "shop", [0.5, 0.84]),
        door("to_landing", "mirror_hall", [0.08, 0.84]),
    ]),
    "shop": room("shop", [
        ev("shelf_finial", [0.72, 0.36], "h5_shelf_tamsin", "shelf_finial", "The finial on the shelf", "棚の飾り", if_not_flag="second_tamsin"),
        ev("shelf_ring", [0.82, 0.46], "h5_shelf_ivo", "shelf_ring", "The ring on the shelf", "棚の指輪", if_not_flag="second_ivo"),
        ev("shelf_veil", [0.62, 0.48], "h5_shelf_mara", "shelf_veil", "The veil on the shelf", "棚のヴェール", if_not_flag="second_mara"),
        ev("counter", [0.3, 0.55], "h5_counter", "counter", "Open the counter", "カウンターを開ける"),
        ev("ledger", [0.45, 0.6], "h5_ledger", "ledger", "The object on the counter", "カウンターの上の品", sim_last=True),
        door("to_cellar", "cellar", [0.08, 0.84]),
    ]),
}
h5_events = {
    "h5_open": [{"bg": "mirror_hall"}, {"music": "explore"},
                N("h5_open_1", "Three thirty. The stair is shorter going up, as it always is, except for the last landing, which tonight is a hall of mirrors with nobody in them.", "三時半。上りの階段はいつも短い。今夜は最後の踊り場だけが違う。誰も映っていない鏡の広間になっている。"),
                N("h5_open_2", "In every mirror, the shop's counter, empty, waiting.", "どの鏡にも、店のカウンター。空っぽで、待っている。"), V("v_stage_3")],
    "h5_landing": [],
    "h5_aud_pre": [N("h5_aud_1", "A thin man in sleeve garters and a green visor stands between her and the cellar with an abacus held like a hymn book. The Auditor. Elsa met him once, and wrote only: be exact.", "袖留めと緑のひさしをつけた痩せた男が、算盤を賛美歌集のように持って、彼女と地下室の間に立っている。監査人。エルサは一度だけ会い、こう書いた。『正確に』"),
                   S("auditor", "h5_aud_2", "The night's figures, Miss Quill. Every reading, every fee, every price. If they balance you may go up. If they do not, you are the difference.", "今夜の数字を、クイル嬢。すべての読み取り、手数料、値付け。釣り合えば上がってよろしい。釣り合わなければ、あなたが差額だ。")],
    "h5_aud_post": [S("auditor", "h5_aud_3", "They balance. Narrowly. Everything balances narrowly, at the end. Go up; there is one object left in the lamp.", "釣り合っている。かろうじて。最後にはすべて、かろうじて釣り合うものだ。上がりなさい。灯りの下に品がひとつ残っている。"),
                    {"flag": "auditor_done"}],
    "h5_shelf_tamsin": second_reading("tamsin"),
    "h5_shelf_ivo": second_reading("ivo"),
    "h5_shelf_mara": second_reading("mara"),
    "h5_ledger": [L(907, 908),
                  {"if_count": ["refused_finial", "refused_ring", "refused_veil"], "n": 2, "then": [L(914, 917)],
                   "else": [{"if_count": ["read_finial", "read_ring", "read_veil"], "n": 3, "then": [L(920, 923), V("v_streak_0")], "else": [L(926)]}]},
                  L(929, 946),
                  {"if_flag": "sold", "then": [L(948)],
                   "else": [{"if_has": "fees", "n": 1,
                             "then": [N("h5_fees", "{#fees} paid in tonight, out of a drawer she thought was hers.", "今夜、自分のものだと思っていた引き出しから払った額：{#fees}。")],
                             "else": [L(952)]}]},
                  L(955, 963),
                  N("h5_glass_1", "Her palm goes flat on the strap. For the first time tonight the object pushes back with her own hands.", "掌をベルトの上に平らに置く。今夜はじめて、品が彼女自身の手で押し返してくる。"),
                  {"battle": "glass"},
                  give_q("n_read"), {"cg": "cg_collateral"}, L(970, 987), {"hide_cg": True}, L(989),
                  {"bg": "dawn"}, {"music": "dawn"}, L(1007, 1008),
                  N("h5_count_1", "Till: {#coin}. On the shelf: 97 — a finial, a ring, a veil, none of them claimed, all of them thirty days from being the shop's.", "金庫：{#coin}。棚の上：97 — 飾り、指輪、ヴェール。どれも請け出されず、三十日後には店のものになる。"),
                  N("h5_count_2", "Against the estate: 200.", "遺産に対する負債：200。"),
                  {"if_flag": "sold",
                   "then": [{"cg": "cg_factor"}, L(1050, 1051)]
                           + newest(lambda who, en, ja: [N("h5_factor_" + who, f"She can still say the sentence. [i]{en} — the room, the light, what happened in it.[/i] She can tell you the facts in the flat voice of a ticket.", f"文章としては、まだ言える。[i]{ja} — 部屋、光、そこで起きたこと。[/i] 質札の平板な声で、事実を語ることはできる。")])
                           + [L(1053, 1064), {"hide_cg": True}] + outro("factor"),
                   "else": [{"if_count": ["read_finial", "read_ring", "read_veil"], "n": 3,
                             "then": collateral_end(),
                             "else": [{"if_has": "coin", "n": 103,
                                       "then": [{"cg": "cg_solvent"}, L(1024, 1025),
                                                {"if_count": ["refused_finial", "refused_ring", "refused_veil"], "n": 3,
                                                 "then": [L(1029, 1032)], "else": [L(1035)]},
                                                L(1037, 1041), {"hide_cg": True}] + outro("solvent"),
                                       "else": collateral_end()}]}]}],
}
NIGHTS["h5"] = night("h5", "Three forty", "三時四十分", "The last object in the lamp", "灯りの下の最後の品",
                     40, 3 * 60 + 30, 1, "mirror_hall", "h5_open", h5_rooms, h5_events)


# the counter / stall screens are shared: each hour carries its own copy of the events
SHARED = {k: v for k, v in NIGHTS["h1"]["events"].items() if k.endswith("_counter") or k.endswith("_stalls")}
for _n in NIGHTS.values():
    for k, v in SHARED.items():
        _n["events"].setdefault(k, v)


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
