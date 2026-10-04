#!/usr/bin/env python3
"""data/game.json + data/art_manifest.json for LIEN, and tools/strings_enemies.py.

Nara is a solo party (like Reyes in the Confession Room RPG). The standoff is a haggle across
a counter -- or, against an object's memory, a reading: the other side's Resolve, Nara's
Composure and Focus, and the other side's CLAIM on her (the core's Suspicion meter): at 100
her name goes into their book (a loss: reload the autosave taken at the door).

Weakness logic, so the strategy is learnable rather than guessed:
  echoes (an object's memory)   talk and proof: Patter, Show the ticket; resent force and lowballs
  stair people (clerks, keepers) want paper or payment; resist charm
  market traders                 lowballs and trade-in-kind; see through patter
  the Bailiff / the Auditor     proof only; everything else is noted against you
  Nara in the glass              herself: Lay a hand, Let it sit; nothing she would see through

    python3 tools/build_data.py
"""
import json
from pathlib import Path
HERE = Path(__file__).resolve().parent
D = HERE.parent / "data"
A = D.parent / "assets"

ACTIONS = {
    "deflect":  {"kind": "guard", "cost": 0, "susp": 4},                                   # Hold the counter
    "observe":  {"kind": "observe", "cost": 2, "susp": 2},                                 # Appraise
    "bluff":    {"cost": 3, "stat": "wit", "power": 7, "scale": 1.5, "susp": 3},          # Lowball
    "evidence": {"cost": 4, "stat": "wit", "power": 10, "scale": 2.0, "susp": -2, "needs_kind": "evidence"},
    "bribe":    {"cost": 2, "stat": "cha", "power": 9, "scale": 1.2, "susp": 1, "needs_kind": "cash"},   # Pay in kind
    "flirt":    {"cost": 3, "stat": "cha", "power": 7, "scale": 1.8, "susp": 2},          # Patter
    "threaten": {"cost": 4, "stat": "grt", "power": 13, "scale": 2.0, "susp": 12, "harm": True},  # Call the debt
    "stall":    {"kind": "stall", "cost": 1, "susp_down": 10, "heal": 3},                   # Let it sit
    "item":     {"kind": "item", "cost": 0},
    "touch":    {"cost": 5, "stat": "wit", "power": 14, "scale": 2.0, "susp": -3},          # Lay a hand (skill)
    "elsa":     {"cost": 4, "stat": "cha", "power": 11, "scale": 1.8, "susp": -4},          # Elsa's rule (skill)
}
SKILLS = {
    "tally":       {"branch": "broker", "req": 2, "mult": {"bluff": 0.3}},
    "patter":      {"branch": "broker", "req": 4, "mult": {"flirt": 0.3}},
    "ledger_mind": {"branch": "broker", "req": 6, "stat": {"wit": 2}},
    "elsa_sk":     {"branch": "broker", "req": 9, "grant": "elsa"},
    "house":       {"branch": "broker", "req": 12, "mult": {"elsa": 0.4, "bribe": 0.3}},
    "steady":      {"branch": "reader", "req": 2, "max_comp": 10},
    "open_hand":   {"branch": "reader", "req": 4, "stat": {"stl": 2}},
    "fingertips":  {"branch": "reader", "req": 6, "mult": {"evidence": 0.3}},
    "touch_sk":    {"branch": "reader", "req": 9, "grant": "touch"},
    "deep":        {"branch": "reader", "req": 12, "mult": {"touch": 0.4, "stall": 0.2}},
}
ITEMS = {
    # the story's own bookkeeping: hidden from the item list, read by {#...} and if_has
    "coin": {"kind": "money", "hidden": True}, "fees": {"kind": "tally", "hidden": True},
    "n_read": {"kind": "tally", "hidden": True}, "n_refused": {"kind": "tally", "hidden": True},
    "bone_charm": {"kind": "cash"},
    "tea": {"kind": "consumable", "heal_comp": 16}, "salts": {"kind": "consumable", "heal_nerve": 8},
    "brandy": {"kind": "consumable", "heal_comp": 28}, "peppermint": {"kind": "consumable", "heal_nerve": 14},
    "receipt": {"kind": "evidence"}, "ticket_tamsin": {"kind": "evidence"}, "ticket_ivo": {"kind": "evidence"},
    "ticket_mara": {"kind": "evidence"}, "elsa_note": {"kind": "evidence"}, "calder_card": {"kind": "evidence"},
    "ledger_page": {"kind": "evidence"},
    "vault_key": {"kind": "key"},
    "waistcoat": {"kind": "equip", "slot": "outfit", "for": "nara", "bonus": {"grt": 1}},
    "oilskin": {"kind": "equip", "slot": "outfit", "for": "nara", "bonus": {"grt": 2}},
    "velvet": {"kind": "equip", "slot": "outfit", "for": "nara", "bonus": {"cha": 2}, "mult": {"flirt": 0.2}},
    "monocle": {"kind": "equip", "slot": "accessory", "for": "nara", "bonus": {"wit": 1}},
    "loupe": {"kind": "equip", "slot": "accessory", "for": "nara", "bonus": {"wit": 2}, "mult": {"evidence": 0.2}},
    "brooch": {"kind": "equip", "slot": "accessory", "for": "nara", "bonus": {"cha": 1}},
    "lantern": {"kind": "equip", "slot": "tool", "for": "nara", "bonus": {"stl": 1}, "mult": {"stall": 0.2}},
    "scales": {"kind": "equip", "slot": "tool", "for": "nara", "bonus": {"wit": 1}, "mult": {"bluff": 0.3}},
    "gloves": {"kind": "equip", "slot": "tool", "for": "nara", "bonus": {"grt": 2}},
}
T = {}   # enemy strings: key -> (en, ja)


def E(eid, name, sprite, comp, atk, rate, xp, weak, resist, intro, win, barks, drop=None, boss=False, track=None):
    T["e_" + eid] = name
    T["ei_" + eid] = intro
    T["ew_" + eid] = win
    for i, b in enumerate(barks, 1):
        T[f"bark_{eid}_{i}"] = b
    e = {"name_key": "e_" + eid, "sprite": sprite, "composure": comp, "atk": atk, "susp_rate": rate, "xp": xp,
         "weak": weak, "resist": resist, "intro_key": "ei_" + eid, "win_key": "ew_" + eid, "barks": len(barks)}
    if drop:
        e["drop"] = drop
    if boss:
        e["boss"] = True
    if track:
        e.update({"trust_win": 1, "trust_track": track, "trust_win_max_susp": 60})
    return e


ECHO_W, ECHO_R = ["flirt", "evidence"], ["threaten", "bluff"]   # talk it out of its hands; show it its ticket
ENEMIES = {
    # hour one: tutorial reading, two stair people, the Clerk
    "echo_finial": E("echo_finial", ("The finial's hour", "飾りの一時"), "echo", 60, 4, 5, 35, ECHO_W, ECHO_R,
                     ("The brass holds its morning shut, like a hand around a coin.", "真鍮はその朝を固く閉じている。硬貨を握る手のように。"),
                     ("It opens.", "開いた。"),
                     [("It is warm. It does not want to be warm in front of you.", "温かい。あなたの前で温かくありたくはないのだ。"),
                      ("A curtain, half up. Then nothing.", "半分だけ上がったカーテン。それから、何も。")], track="tamsin"),
    "pledge": E("pledge", ("A lapsed pledge", "期限切れの質入れ人"), "echo", 82, 5, 6, 40, ["evidence", "flirt"], ["bluff", "threaten"],
                ("It presses its hands to the glass and asks, without a mouth, whether it is too late.", "手を窓に押し当て、口もないのに、もう遅いのかと訊いてくる。"),
                ("It nods, the way you nod at a closing time.", "閉店時刻にうなずくように、それはうなずいた。"),
                [("Thirty days. It was only thirty days.", "三十日。たった三十日だった。"), ("Is it still here? Is it still mine?", "まだある？まだ私のもの？")], drop="tea"),
    "keeper": E("keeper", ("The Toll-Keeper", "通行税の番人"), "toll_keeper", 105, 6, 6, 50, ["bribe", "bluff"], ["flirt", "threaten"],
                ("She holds the lantern up between you, and the light is the toll.", "彼女は二人の間にランタンを掲げる。その光が通行税だ。"),
                ("She lowers the lantern. Paid.", "ランタンが下がる。支払い済み。"),
                [("Everyone pays going down.", "降りる者はみな払う。"), ("Your aunt paid in silence. Can you?", "あなたの叔母は沈黙で払った。あなたは？"),
                 ("Don't look at the eleventh step.", "十一段目を見ないで。")], drop="peppermint"),
    "clerk": E("clerk", ("The Stair Clerk", "階段の書記"), "stair_clerk", 172, 7, 7, 110, ["evidence", "bluff"], ["flirt", "bribe"],
               ("He dips his pen. Every word you say, he enters.", "彼はペンを浸す。あなたの言葉はすべて記帳される。"),
               ("He blots the page and, with some reluctance, stamps it.", "頁に吸い取り紙を当て、渋々ながら判を押した。"),
               [("Entered.", "記帳。"), ("Received, not accepted.", "受領、未承認。"), ("Your aunt's hand was neater.", "君の叔母の字はもっときれいだった。"),
                ("Shall I enter that as a threat or a joke?", "それは脅しとして記帳するか、冗談としてか？")], drop="receipt", boss=True),
    # hour two
    "echo_ring": E("echo_ring", ("The ring's hour", "指輪の一時"), "echo", 135, 6, 7, 60, ECHO_W, ECHO_R,
                   ("The gold remembers being asked about. It does not like you for it.", "金は尋ねられたことを覚えている。だからあなたを好いてはいない。"),
                   ("A lamp on the floor. It lets you in.", "床に置かれたランプ。中へ入れてくれた。"),
                   [("Don't do that.", "それはやめてくれ。"), ("Eleven centimetres of nightstand.", "ナイトスタンドの十一センチ。"),
                    ("Rain, further north.", "雨。もっと北の。")], track="ivo"),
    "pledge2": E("pledge2", ("The man in the overcoat", "オーバーコートの男"), "echo", 150, 6, 7, 60, ["evidence", "flirt"], ["bluff", "threaten"],
                 ("He wears the coat he pawned in 1987 and he is not giving it back.", "1987年に質入れしたコートを着て、返す気はない。"),
                 ("He folds the coat over his arm.", "彼はコートを腕に掛けた。"),
                 [("It was a cold winter.", "寒い冬だった。"), ("There's no version of it where I need it again.", "また要るようになる冬なんてない。")], drop="tea"),
    "haggler": E("haggler", ("Old Ossian", "オシアン爺"), "bone_haggler", 188, 7, 7, 75, ["bluff", "bribe"], ["flirt", "stall"],
                 ("He spreads his ringed hands. Everything on the trestle is for sale, including the trestle.", "指輪だらけの手を広げる。台の上のものは全部売り物、台もだ。"),
                 ("He laughs until the bones on his fingers rattle.", "指の骨が鳴るほど笑った。"),
                 [("For you? Double.", "お前さんには？倍だ。"), ("Elsa paid half. Elsa was cheating.", "エルサは半値だった。エルサはずるをしてた。"),
                  ("A door's a door. A key's a story.", "扉は扉。鍵は物語だ。")], drop="bone_charm"),
    "broker": E("broker", ("The Hollow Broker", "虚ろな仲買人"), "hollow_broker", 278, 8, 8, 140, ["evidence", "flirt"], ["bluff", "bribe", "threaten"],
                ("The beads of her abacus are teeth, and she counts with them.", "算盤の珠は歯で、彼女はそれで数える。"),
                ("She sets the abacus down with the teeth all on one side.", "彼女は珠をすべて片側に寄せて、算盤を置いた。"),
                [("Expensive.", "高い。"), ("Everything is for sale.", "何だって売り物よ。"), ("I'll buy that hesitation.", "そのためらい、買うわ。"),
                 ("Names are cheaper than you think.", "名前は思うより安いの。")], drop="scales", boss=True),
    # hour three
    "echo_veil": E("echo_veil", ("The veil's hour", "ヴェールの一時"), "echo", 210, 8, 8, 80, ECHO_W, ECHO_R,
                   ("The crepe folds itself against your palm, pleat by pleat.", "クレープ地が一ひだずつ、掌に向かって畳まれていく。"),
                   ("The night before, not the day of.", "当日ではなく、その前の夜。"),
                   [("A candle. A lily in a jug.", "蝋燭。水差しの百合。"), ("Not the church. Not yet.", "教会ではない。まだ。")], track="mara"),
    "moth": E("moth", ("The Moth Widow", "蛾の未亡人"), "moth_widow", 248, 8, 8, 85, ["flirt", "bluff"], ["threaten", "bribe"],
              ("She mends while she bargains. The needle never stops.", "彼女は値切りながら繕う。針は止まらない。"),
              ("She laughs, softly, and puts the needle down.", "柔らかく笑い、針を置いた。"),
              [("Grief keeps. I keep it warm.", "悲しみは日持ちする。私が温めておく。"), ("You smell of a kindness.", "優しさの匂いがする。"),
               ("Closer. I bite only lace.", "もっと近くへ。噛むのはレースだけ。")], drop="brooch"),
    "archivist": E("archivist", ("Miss Penrose", "ペンローズ嬢"), "archivist", 278, 9, 8, 90, ["evidence", "bluff"], ["flirt", "threaten"],
                   ("She opens a drawer marked Q and does not let you see into it.", "Qと記された引き出しを開け、中を見せない。"),
                   ("She closes the drawer, satisfied that the system works.", "仕組みが機能したことに満足して、引き出しを閉じた。"),
                   [("No browsing.", "閲覧不可。"), ("State a surname.", "姓を。"), ("That is not how filing works.", "整理はそういうものではありません。")], drop="salts"),
    "bailiff": E("bailiff", ("The Bailiff", "執達吏"), "bailiff", 390, 10, 9, 160, ["evidence", "bluff"], ["bribe", "flirt", "threaten"],
                 ("His chain of key-tags clinks once for every pound the estate owes.", "鍵札の鎖が、遺産の負債一ポンドごとに一度鳴る。"),
                 ("He steps aside, and writes something down that is not a debt.", "彼は脇へ退き、負債ではない何かを書き留めた。"),
                 [("Noted.", "記録。"), ("Everything is due.", "すべては期限を迎えている。"), ("Coin, Miss Quill? I'll take the coin AND the debt.", "硬貨かね、クイル嬢？硬貨も借りもいただこう。"),
                  ("Six is merely when it is noticed.", "六時とは、気づかれる時刻にすぎない。")], drop="gloves", boss=True),
    # hour four: the Market
    "door_man": E("door_man", ("Old Ossian, selling doors", "扉を売るオシアン爺"), "bone_haggler", 322, 9, 9, 100, ["bluff", "bribe"], ["flirt", "stall"],
                  ("Six doors and a grin. He will sell you any of them. Not the keys.", "六枚の扉と笑み。どれでも売る。鍵は売らない。"),
                  ("He presses a key into your hand and swears he never did.", "鍵を手に押しつけ、そんなことはしていないと誓った。"),
                  [("Twice in one night!", "一晩で二度目！"), ("Keys are extra. Keys are always extra.", "鍵は別料金。鍵はいつも別料金。"),
                   ("The door's older than the Market.", "その扉は市場より古い。")], drop="peppermint"),
    "name_buyer": E("name_buyer", ("The woman who buys names", "名前を買う女"), "hollow_broker", 352, 10, 9, 110, ["evidence", "flirt"], ["bluff", "bribe", "threaten"],
                    ("She wants your name, cash, no questions. Her abacus is already counting it.", "あなたの名前を、現金で、何も訊かずに。算盤はもう数え始めている。"),
                    ("She writes EXPENSIVE again, and underlines it.", "また『高い』と書き、下線を引いた。"),
                    [("Sell it and be light.", "売って身軽になりなさい。"), ("A name is just a ticket you never redeem.", "名前なんて、請け出さない質札よ。"),
                     ("Still expensive.", "まだ高い。")], drop="salts"),
    "keeper2": E("keeper2", ("The Toll-Keeper", "通行税の番人"), "toll_keeper", 330, 10, 9, 105, ["bribe", "bluff"], ["flirt", "threaten"],
                 ("Up is dearer than down. She raises the lantern higher.", "上りは下りより高くつく。彼女はランタンをさらに高く掲げる。"),
                 ("Paid in patience.", "忍耐で支払われた。"),
                 [("Not till the hour's done.", "この刻が終わるまでは。"), ("Pay or wait.", "払うか、待つか。")], drop="brandy"),
    "calder": E("calder", ("Calder, the factor", "仲買人カルダー"), "calder", 400, 11, 10, 180, ["bluff", "evidence"], ["flirt", "bribe", "stall"],
                ("He does not haggle. He waits for you to haggle, and charges you for the wait.", "彼は値切らない。あなたが値切るのを待ち、その待ち時間を請求する。"),
                ("He sits back. For the first time, he looks at her as a seller and not as stock.", "彼は背もたれに身を預けた。はじめて、彼女を在庫ではなく売り手として見ている。"),
                [("Quill.", "クイル。"), ("Everything has prices in it.", "すべてに値段がある。"), ("Elsa was better at this.", "エルサの方が上手だった。"),
                 ("Come back in March.", "三月にまた来い。")], drop="calder_card", boss=True),
    # hour five
    "auditor": E("auditor", ("The Auditor", "監査人"), "auditor", 510, 11, 10, 170, ["evidence", "elsa"], ["bluff", "flirt", "bribe"],
                 ("He holds the abacus like a hymn book and reads your night back to you, line by line.", "賛美歌集のように算盤を持ち、あなたの夜を一行ずつ読み上げる。"),
                 ("He closes the book. The figures balance, narrowly.", "帳簿を閉じた。数字はかろうじて釣り合った。"),
                 [("Be exact.", "正確に。"), ("A rounding error is a person.", "端数は人だ。"), ("Carry the one. Carry yourself.", "一を繰り上げて。自分も繰り上げて。")], drop="brandy", boss=True),
    "echo_tamsin2": E("echo_tamsin2", ("The finial, deeper", "飾り、さらに奥"), "echo", 390, 10, 9, 120, ECHO_W, ECHO_R,
                      ("It lets you in further, and then tests whether you meant it.", "さらに奥へ入れてくれる。それから、本気かどうか試してくる。"),
                      ("Steam, and a laugh at the ceiling.", "湯気と、天井への笑い声。"),
                      [("A good bed.", "良いベッドだった。"), ("Boxes, taped.", "封をされた箱。")]),
    "echo_ring2": E("echo_ring2", ("The ring, asked", "頼まれた指輪"), "echo", 390, 10, 9, 120, ECHO_W, ECHO_R,
                    ("This time it was asked for. It still makes you work.", "今度は頼まれた。それでも、骨を折らせる。"),
                    ("A windowsill, rain, a date read by lamplight.", "窓辺、雨、灯りで読む日付。"),
                    [("Was she happy.", "彼女は幸せだったか。"), ("After.", "そのあと。")]),
    "echo_veil2": E("echo_veil2", ("The veil, permitted", "許されたヴェール"), "echo", 390, 10, 9, 120, ECHO_W, ECHO_R,
                    ("The crepe opens a little, and waits to see what you will do with it.", "クレープ地がわずかに開き、あなたがどうするかを待つ。"),
                    ("Letters, in his hand.", "彼の筆跡の手紙。"),
                    [("The fourth letter.", "四通目。"), ("Do not read over my shoulder.", "肩越しに読まないで。")]),
    "glass": E("glass", ("Nara, in the glass", "鏡の中のナラ"), "nara", 380, 10, 10, 200, ["touch", "flirt", "elsa"], ["bluff", "threaten", "evidence"],
               ("She looks straight out of the mirror, at the place where the person watching a reading stands.", "鏡の中の彼女はまっすぐこちらを見る。読み取りを見る者が立つ場所を。"),
               ("She lets you have the last four hours. All of them.", "最後の四時間を、すべて渡してくれた。"),
               [("Thirty days on the ticket.", "質札は三十日。"), ("What the dead will demand.", "死者が求めるもの。"),
                ("You can't pawn this. You're the shop.", "これは質入れできない。あなたが店なのだから。"), ("I buy anything I can price.", "値がつくものなら何でも買う。")], boss=True),
}

ECHO_SPRITES = ("echo", "toll_keeper", "stair_clerk", "bone_haggler", "hollow_broker", "moth_widow", "bailiff", "archivist", "auditor")
CAST = ("nara", "tamsin", "ivo", "mara", "calder")
ROOMS = ("shop", "stockroom", "street", "cellar", "receipt_stair", "toll_gate", "bone_arcade", "reliquary", "lantern_row",
         "archive", "market", "counting_house", "heart_vault", "mirror_hall", "dawn")
# (cg id, gallery trust gate shown on the locked tile, title EN, title JA)
GALLERY = [
    ("cg_tamsin", 0, "Tamsin — the morning", "タムシン — 朝"),
    ("cg_finial", 3, "Tamsin — further in", "タムシン — さらに奥"),
    ("cg_descent", 0, "The Receipt Stair", "受領の階段"),
    ("cg_ring", 0, "The ring — a lamp on the floor", "指輪 — 床のランプ"),
    ("cg_veil", 0, "Mara — the night before", "マーラ — 前夜"),
    ("cg_moth", 0, "The Moth Widow", "蛾の未亡人"),
    ("cg_market_crowd", 0, "The Ossuary Market", "骨の市場"),
    ("cg_calder", 0, "Calder's desk", "カルダーの机"),
    ("cg_market", 0, "Calder's demonstration", "カルダーの実演"),
    ("cg_heart", 0, "The Heart of the Crypt", "地下聖堂の心臓"),
    ("cg_tamsin_bath", 5, "Tamsin — the last bath", "タムシン — 最後の湯"),
    ("cg_maya", 5, "Maya — after", "マヤ — そのあと"),
    ("cg_mara_letters", 5, "Mara — the letters", "マーラ — 手紙"),
    ("cg_collateral", 0, "Collateral", "担保"),
    ("cg_solvent", 0, "Solvent — dawn", "支払可能 — 夜明け"),
    ("cg_factor", 0, "Factor — March", "仲買人 — 三月"),
]
for cid, _, en, ja in GALLERY:
    T["g_" + cid] = (en, ja)

game = {
    "title_key": "title", "logo": "res://assets/title/logo.png", "title_bg": "res://assets/title/keyvisual.png",
    "fonts": {"body": "res://assets/fonts/body.ttf", "display": "res://assets/fonts/display.ttf",
              "cjk": "res://assets/fonts/NotoSansCJKjp-Regular.otf"},
    "ui": {"dust": "res://assets/ui/dust.png", "vignette": "res://assets/ui/vignette.png", "scrim": "res://assets/ui/scrim.png",
           "dim": "res://assets/ui/scrim.png", **{k: f"res://assets/ui/{v}.png" for k, v in {
               "panel": "panel", "textbox": "textbox", "namebox": "namebox", "choice_idle": "choice_idle",
               "choice_hover": "choice_hover", "slot_idle": "slot_idle", "slot_hover": "slot_hover",
               "bar_under": "bar_under", "bar_fill": "bar_fill", "bar_fill_gold": "bar_fill_gold", "modal": "modal"}.items()}},
    "title_mood": {"ambient": "#e0d4cc", "torch": True, "zoom": 1.05, "offset": [200, 0]},
    "music": {k: f"res://assets/audio/{v}.ogg" for k, v in {
        "title": "suspense_theme", "explore": "explore", "battle": "standoff", "boss": "boss",
        "intimate": "intimate", "dawn": "dawn", "reading": "ecchi_theme"}.items()},
    "audio": {k: f"res://assets/audio/{v}.ogg" for k, v in {
        "ambience": "rain_ambience", "click": "ui_click", "page_flip": "page_flip", "heartbeat": "heartbeat",
        "sting": "title_sting", "camera": "ui_click"}.items()},
    "disclosure_key": "about_ai",
    # the trial is hour one: its two readings show (cg_tamsin is the opening, cg_finial is
    # earned there); nothing later ships in the trial pck at all (export_presets.cfg)
    "trial_last_night": "h1", "trial_locked_cgs": [],
    "store_url": "",          # DLsite build: no outbound link anywhere (他サイトへの誘導)
    "stats": ["wit", "cha", "grt", "stl"],
    "level_cap": 20, "trust_thresholds": [3, 5],
    "trust_tracks": ["tamsin", "ivo", "mara"],
    "hud_counter": "coin",
    "party": [
        {"id": "nara", "base": {"wit": 4, "cha": 3, "grt": 3, "stl": 3}, "grow": ["wit", "cha", "grt", "stl"],
         "actions": ["deflect", "observe", "bluff", "evidence", "bribe", "flirt", "threaten", "stall", "item"],
         "branches": {"broker": ["tally", "patter", "ledger_mind", "elsa_sk", "house"],
                      "reader": ["steady", "open_hand", "fingertips", "touch_sk", "deep"]},
         "start_equip": {"outfit": "waistcoat", "accessory": "monocle"}},
    ],
    "start_items": {"coin": 260, "tea": 1, "bone_charm": 1},
    "actions": ACTIONS, "skills": SKILLS, "items": ITEMS, "enemies": ENEMIES,
    "nights": ["h1", "h2", "h3", "h4", "h5"], "story": ["lien"],
    "gallery": [{"id": c, "thumb": c + "_thumb", "locked": c + "_locked", "key": "g_" + c, "trust": t} for c, t, _, _ in GALLERY],
    # Nara's voiced lines: the 21 LIEN barks (ops/barks/lines.json), attached to the RPG
    # strings that say exactly those words (tools/strings_voice.py)
    "voice": {},
}

art = {"rooms": {r: [f"res://assets/rooms/{r}.png"] for r in ROOMS},
       "rooms_locked": {r: [f"res://assets/rooms_locked/{r}.png"] for r in ROOMS},
       "enemies": {s: [f"res://assets/enemies/{s}.png"] for s in ECHO_SPRITES + CAST},
       "sprites": {s: [f"res://assets/sprites/{s}.png"] for s in CAST},
       "maps": {"ledger": ["res://assets/ui/map.png"]},
       "cg": {}}
for cid, _, _, _ in GALLERY:
    art["cg"][cid] = [f"res://assets/cg/{cid}.png"]
    for suf in ("_thumb", "_locked"):
        art["cg"][cid + suf] = [f"res://assets/cg/{cid}{suf}.png"]

# the voiced barks: key in strings_voice.py -> clip copied in by import_art.py
_voice = HERE / "strings_voice.py"
if _voice.exists():
    ns = {}
    exec(_voice.read_text(), ns)
    for k in ns["S"]:
        game["voice"][k] = {"v_en": f"res://assets/voice/{k}.ogg"}

D.mkdir(exist_ok=True)
(D / "game.json").write_text(json.dumps(game, indent=1, ensure_ascii=False))
(D / "art_manifest.json").write_text(json.dumps(art, indent=1))
body = "# GENERATED by tools/build_data.py (enemy names, intros, wins, barks; gallery titles)\nS = {\n"
for k, (en, ja) in T.items():
    body += f"{k!r}: ({en!r}, {ja!r}),\n"
(HERE / "strings_enemies.py").write_text(body + "}\n")
print(f"game.json ({len(ENEMIES)} enemies, {len(ITEMS)} items, {len(GALLERY)} CGs) + art_manifest.json + {len(T)} enemy strings")
