#!/usr/bin/env python3
"""data/game.json + data/art_manifest.json for OCCUPANCY, and tools/strings_enemies.py.

OCCUPANCY is RPG x office management x staff gacha (ops/rpg_conversion/HYBRIDS.md): the
night-rpg-core floor (explore, standoffs, levels, skills, equipment, Trust) plus its own
second genre, the office board (scripts/office.gd): the 5x4 placement and settle economy of
Overtime Landlord (scripts/landlord.gd + scripts/roster.gd, copied byte for byte from the
committed play/overtime-idle-godot) and its named-staff gacha, paid for with the in-game rent
fund only. There is no real money anywhere: the DLsite build is a one-time purchase.

The party is the staff. Mara starts; Priya is the first hire (the first recruit is on the
house); Nia and Sol come out of the recruit pool -- or, if luck has not brought them, the
story brings them on night 3 and night 4, so the gacha widens the party but never gates it.
Dan and Wes are board staff only (they work the floor; they do not walk it).

The standoff is a RENT NEGOTIATION: the other side's Resolve, each staffer's Composure and
Focus, and the other side's PRESSURE (the core's Suspicion meter): at 100 the floor is
served notice (a loss: reload the autosave taken at the door).

Weakness logic, so the strategy is learnable rather than guessed:
  couriers, juniors, tenants   charm and spin; resent being threatened
  the Trust's agents           paperwork; resist charm and perks
  Wes (the sublet)              his own ledger and a straight look; resists spin and charm
  the Bailiff                   a headline and paperwork; anything else is noted against you
  Corinne Halvard               the keys, the headline, and nerve; resists perks and threats

Each floor's crisis has two rows: the agent you meet with the rent in hand, and the one you
meet short (more Resolve, Pressure already at 25). The office board is what decides which.

    python3 tools/build_data.py
"""
import json
from pathlib import Path
HERE = Path(__file__).resolve().parent
D = HERE.parent / "data"

ACTIONS = {
    "deflect":  {"kind": "guard", "cost": 0, "susp": 4},                                   # Hold the line
    "observe":  {"kind": "observe", "cost": 2, "susp": 2},                                 # Read them
    "bluff":    {"cost": 3, "stat": "wit", "power": 7, "scale": 1.5, "susp": 3},          # Spin it
    "evidence": {"cost": 4, "stat": "wit", "power": 10, "scale": 2.0, "susp": -2, "needs_kind": "evidence"},  # Paperwork
    "bribe":    {"cost": 2, "stat": "cha", "power": 9, "scale": 1.2, "susp": 1, "needs_kind": "cash"},       # Comp a perk
    "flirt":    {"cost": 3, "stat": "cha", "power": 7, "scale": 1.8, "susp": 2},          # Charm
    "threaten": {"cost": 4, "stat": "grt", "power": 13, "scale": 2.0, "susp": 12, "harm": True},  # Call security
    "stall":    {"kind": "stall", "cost": 1, "susp_down": 10, "heal": 3},                   # Coffee break
    "item":     {"kind": "item", "cost": 0},
    "keys":     {"cost": 5, "stat": "wit", "power": 14, "scale": 2.0, "susp": -3},          # Master keys (Mara)
    "fix":      {"cost": 4, "stat": "grt", "power": 13, "scale": 1.8, "susp": -2},          # Fix it on the spot (Priya)
    "audit":    {"cost": 5, "stat": "wit", "power": 16, "scale": 2.0, "susp": -4},          # Audit them (Nia)
    "headline": {"cost": 5, "stat": "cha", "power": 15, "scale": 2.0, "susp": -2},          # Headline (Sol)
}
SKILLS = {
    # Mara: keys / steel
    "m_ring":      {"branch": "keys", "req": 2, "mult": {"evidence": 0.3}},
    "m_plan":      {"branch": "keys", "req": 4, "stat": {"wit": 2}},
    "m_master":    {"branch": "keys", "req": 6, "grant": "keys"},
    "m_lockdown":  {"branch": "keys", "req": 10, "mult": {"keys": 0.4}},
    "m_steady":    {"branch": "steel", "req": 2, "max_comp": 10},
    "m_glare":     {"branch": "steel", "req": 5, "mult": {"threaten": 0.3}},
    "m_spine":     {"branch": "steel", "req": 8, "stat": {"grt": 2}},
    # Priya: tools / banter
    "p_wrench":    {"branch": "tools", "req": 2, "stat": {"grt": 2}},
    "p_fix":       {"branch": "tools", "req": 4, "grant": "fix"},
    "p_overtime":  {"branch": "tools", "req": 8, "mult": {"fix": 0.4}},
    "p_grin":      {"branch": "banter", "req": 2, "mult": {"flirt": 0.3}},
    "p_tease":     {"branch": "banter", "req": 5, "stat": {"cha": 2}},
    "p_wink":      {"branch": "banter", "req": 9, "mult": {"bluff": 0.3}},
    # Nia: audit / poise
    "n_columns":   {"branch": "ledger", "req": 2, "mult": {"evidence": 0.3}},
    "n_audit":     {"branch": "ledger", "req": 5, "grant": "audit"},
    "n_forensic":  {"branch": "ledger", "req": 9, "mult": {"audit": 0.4}},
    "n_glasses":   {"branch": "poise", "req": 3, "stat": {"wit": 2}},
    "n_dry":       {"branch": "poise", "req": 6, "mult": {"bluff": 0.3}},
    "n_cold":      {"branch": "poise", "req": 10, "max_comp": 12},
    # Sol: press / warmth
    "s_lede":      {"branch": "press", "req": 2, "mult": {"flirt": 0.3}},
    "s_headline":  {"branch": "press", "req": 6, "grant": "headline"},
    "s_front":     {"branch": "press", "req": 10, "mult": {"headline": 0.4}},
    "s_tea":       {"branch": "warmth", "req": 3, "mult": {"stall": 0.3}},
    "s_warm":      {"branch": "warmth", "req": 7, "stat": {"cha": 2}},
    "s_late":      {"branch": "warmth", "req": 11, "max_comp": 12},
}
ITEMS = {
    # the rent fund: hidden from the list, shown on the HUD (hud_counter), read by if_has
    "coin": {"kind": "money", "hidden": True},
    "voucher": {"kind": "cash"},
    "espresso": {"kind": "consumable", "heal_comp": 16}, "energy": {"kind": "consumable", "heal_nerve": 8},
    "pastry": {"kind": "consumable", "heal_comp": 28}, "mints": {"kind": "consumable", "heal_nerve": 14},
    "lease_copy": {"kind": "evidence"}, "sign_in_sheet": {"kind": "evidence"}, "sublet_ledger": {"kind": "evidence"},
    "audit_trail": {"kind": "evidence"}, "court_error": {"kind": "evidence"}, "trust_deed": {"kind": "evidence"},
    # the dress-up: two outfits each, the figure changes with the outfit (Equip tab, the stage)
    "mara_work": {"kind": "equip", "slot": "outfit", "for": "mara", "bonus": {"grt": 1}, "sprite": "mara_work"},
    "mara_after": {"kind": "equip", "slot": "outfit", "for": "mara", "bonus": {"cha": 2}, "mult": {"flirt": 0.2}, "sprite": "mara_after"},
    "priya_work": {"kind": "equip", "slot": "outfit", "for": "priya", "bonus": {"grt": 1}, "sprite": "priya_work"},
    "priya_after": {"kind": "equip", "slot": "outfit", "for": "priya", "bonus": {"cha": 2}, "mult": {"flirt": 0.2}, "sprite": "priya_after"},
    "nia_work": {"kind": "equip", "slot": "outfit", "for": "nia", "bonus": {"wit": 1}, "sprite": "nia_work"},
    "nia_after": {"kind": "equip", "slot": "outfit", "for": "nia", "bonus": {"cha": 2}, "mult": {"bluff": 0.2}, "sprite": "nia_after"},
    "sol_work": {"kind": "equip", "slot": "outfit", "for": "sol", "bonus": {"stl": 1}, "sprite": "sol_work"},
    "sol_after": {"kind": "equip", "slot": "outfit", "for": "sol", "bonus": {"cha": 2}, "mult": {"flirt": 0.2}, "sprite": "sol_after"},
    # accessories and tools: anyone can wear them unless "for" says otherwise
    "keyring": {"kind": "equip", "slot": "accessory", "for": "mara", "bonus": {"wit": 1}},
    "gold_lanyard": {"kind": "equip", "slot": "accessory", "bonus": {"cha": 1, "wit": 1}},
    "earpiece": {"kind": "equip", "slot": "accessory", "bonus": {"stl": 2}},
    "safety_glasses": {"kind": "equip", "slot": "accessory", "for": "priya", "bonus": {"grt": 1}},
    "fountain_pen": {"kind": "equip", "slot": "accessory", "bonus": {"wit": 2}, "mult": {"evidence": 0.2}},
    "press_pass": {"kind": "equip", "slot": "accessory", "bonus": {"cha": 2}},
    "clipboard": {"kind": "equip", "slot": "tool", "bonus": {"wit": 1}, "mult": {"bluff": 0.2}},
    "tablet": {"kind": "equip", "slot": "tool", "bonus": {"stl": 1}, "mult": {"stall": 0.2}},
    "thermos": {"kind": "equip", "slot": "tool", "bonus": {"grt": 2}},
    "toolbelt": {"kind": "equip", "slot": "tool", "for": "priya", "bonus": {"grt": 1}, "mult": {"fix": 0.2}},
    # gifts: bought once each from Supplies, given from the Items tab (+1 Trust)
    "orchid": {"kind": "gift", "gift": True, "gift_track": "mirei", "gift_trust": 1},
    "whisky": {"kind": "gift", "gift": True, "gift_track": "mara", "gift_trust": 1},
    "craft_beer": {"kind": "gift", "gift": True, "gift_track": "priya", "gift_trust": 1},
    "ink": {"kind": "gift", "gift": True, "gift_track": "nia", "gift_trust": 1},
    "first_edition": {"kind": "gift", "gift": True, "gift_track": "sol", "gift_trust": 1},
}
HARD = 2.5
T = {}   # enemy strings: key -> (en, ja)


def E(eid, name, sprite, comp, atk, rate, xp, weak, resist, intro, win, barks, drop=None, boss=False, track=None, start=0):
    T["e_" + eid] = name
    T["ei_" + eid] = intro
    T["ew_" + eid] = win
    for i, b in enumerate(barks, 1):
        T[f"bark_{eid}_{i}"] = b
    comp, atk, rate = int(comp * HARD), atk + 3, rate + 2     # tuned by tests/sim.gd (a party of up to four)
    e = {"name_key": "e_" + eid, "sprite": sprite, "composure": comp, "atk": atk, "susp_rate": rate, "xp": xp,
         "weak": weak, "resist": resist, "intro_key": "ei_" + eid, "win_key": "ew_" + eid, "barks": len(barks)}
    if drop:
        e["drop"] = drop
    if boss:
        e["boss"] = True
    if start:
        e["suspicion_start"] = start
    if track:
        e.update({"trust_win": 1, "trust_track": track, "trust_win_max_susp": 60})
    return e


def crisis(eid, name, sprite, comp, atk, rate, xp, weak, resist, intro, win, barks, drop=None, track="mirei"):
    """A floor's rent crisis: the paid row and the short row (+60% Resolve, Pressure from 25)."""
    paid = E(eid, name, sprite, comp, atk, rate, xp, weak, resist, intro, win, barks, drop=drop, boss=True, track=track)
    short = E(eid + "_short", name, sprite, int(comp * 1.9), atk + 3, rate + 4, xp, weak, resist,
              (intro[0] + " The rent is short, and they know it.", intro[1] + "家賃が足りない。向こうもそれを知っている。"),
              win, barks, drop=drop, boss=True, start=38)
    short["name_key"] = "e_" + eid
    T.pop("e_" + eid + "_short")
    return {eid: paid, eid + "_short": short}


ENEMIES = {
    # ---- night 1: the open plan (trial)
    "courier": E("courier", ("A night courier", "夜間の配達人"), "courier", 70, 4, 5, 35, ["flirt", "bribe"], ["threaten", "bluff"],
                 ("She has an envelope for 'whoever runs this building' and a bike on the kerb with the light still flashing.", "「このビルを仕切ってる人」宛ての封筒を持ち、歩道の自転車はライトが点滅したままだ。"),
                 ("She signs her own sheet, grins, and leaves the envelope and a parking pass she has no use for.", "彼女は自分で伝票にサインし、にやりと笑って、封筒と使い道のない駐車券を置いていった。"),
                 [("Sign or I leave it in the rain.", "サインして。じゃなきゃ雨の中に置いてく。"), ("I get paid per door, not per argument.", "報酬は一軒ごと。口論ごとじゃない。")],
                 drop="voucher"),
    "cleaner": E("cleaner", ("The agency's night supervisor", "清掃会社の夜間主任"), "junior", 95, 5, 6, 45, ["evidence", "flirt"], ["bluff", "threaten"],
                 ("She says the cleaning contract lapsed at midnight and her crew is walking unless someone signs for the month.", "清掃契約は零時で切れた、誰かが一か月分にサインしなければ班は引き上げる、と彼女は言う。"),
                 ("She countersigns, and the hoovers start up again two floors down.", "彼女が副署すると、二つ下の階で掃除機がまた唸り出した。"),
                 [("Contract says midnight.", "契約書には零時とある。"), ("My crew has homes too.", "うちの班にも家はあるの。")],
                 drop="espresso"),
    **crisis("pryce", ("Gideon Pryce, rent agent", "家賃代理人ギデオン・プライス"), "pryce", 170, 6, 6, 90, ["evidence", "bluff"], ["flirt", "bribe"],
             ("He opens the Halvard Trust's ledger on the reception desk and turns it to face you. Floor two. In red.", "彼はハルヴァード信託の台帳を受付台に開き、こちらに向けた。二階。赤字で。"),
             ("He blots the line, writes PAID in a hand like a scalpel, and wishes you, sincerely, a long night.", "彼は行に吸い取り紙を当て、メスのような字で『支払済』と書き、心から長い夜を祈った。"),
             [("The Trust is patient. I am not the Trust.", "信託は辛抱強い。私は信託ではない。"), ("Floor two owes. Floors are like people.", "二階は滞納している。階は人間と同じだ。"),
              ("Your predecessor said that too.", "前任者も同じことを言っていた。")], drop="lease_copy"),
    # ---- night 2: the sublet on seven
    "subletter": E("subletter", ("A man who rents a desk from Wes", "ウェスから机を借りている男"), "sublet", 120, 6, 6, 50, ["threaten", "evidence"], ["flirt", "bribe"],
                   ("He has paid Wes for a desk, a password and 'the energy of the space'. He would like all three, now.", "彼はウェスに机代とパスワードと「空間のエネルギー」代を払った。三つとも今すぐ欲しいと言う。"),
                   ("He packs his laptop. He thanks you, which is worse.", "彼はノートパソコンを畳む。礼まで言われるのが、かえってつらい。"),
                   [("I have a Zoom at nine.", "九時にZoomがあるんだ。"), ("The energy was the point.", "エネルギーが肝心だったのに。")], drop="energy"),
    "subletter2": E("subletter2", ("Two more of Wes's tenants", "ウェスの借り手、さらに二人"), "sublet", 150, 6, 7, 55, ["threaten", "evidence"], ["flirt", "bribe"],
                    ("They have the same receipt, for the same desk, from the same man.", "同じ机の、同じ男からの、同じ領収書を二人とも持っている。"),
                    ("They leave together, already planning a podcast about it.", "二人は連れ立って帰っていく。もうこの件のポッドキャストを企画している。"),
                    [("We were told it was a community.", "コミュニティだって聞いてた。"), ("Who even owns this building?", "このビル、そもそも誰のもの？")], drop="pastry"),
    **crisis("wes", ("Wes, tenant on seven", "七階の入居者ウェス"), "wes", 270, 7, 7, 120, ["evidence", "threaten"], ["bluff", "flirt"],
             ("Wes sits on the boardroom table with his tie loose and a smile he has used on better landlords than you.", "ウェスはネクタイを緩めて会議机に腰掛け、あなたよりましな家主たちにも使ってきた笑みを浮かべている。"),
             ("He laughs, once, and hands over the ledger. 'Fine. Fine. Put me on payroll, then. I'm good at people.'", "彼は一度だけ笑い、台帳を差し出した。「わかった、わかったよ。じゃあ給料を払ってくれ。人あしらいは得意なんだ」"),
             [("Everyone sublets. I just say it out loud.", "みんな又貸ししてる。俺は口に出すだけさ。"), ("Mirei likes me. Ask her.", "ミレイは俺を気に入ってる。聞いてみなよ。"),
              ("It's a community, technically.", "厳密にはコミュニティだよ。")], drop="sublet_ledger"),
    # ---- night 3: accounts on six
    "junior": E("junior", ("Ms. Ames, junior auditor", "下級監査人エイムズ"), "junior", 170, 7, 7, 60, ["flirt", "bluff"], ["threaten", "evidence"],
                ("She has a clipboard, a trench coat, and an expression of someone who was sent up alone on purpose.", "クリップボードとトレンチコート、それにわざと一人で寄越された人の表情。"),
                ("She ticks a box she was not told about and goes to find a vending machine.", "教わっていない欄にチェックを入れ、自販機を探しに行った。"),
                [("I'm just here to count.", "数えに来ただけです。"), ("Ms. Varga will ask me what you said.", "ヴァルガさんに何を言われたか聞かれます。")], drop="mints"),
    "records_clerk": E("records_clerk", ("The night archivist", "夜間記録係"), "junior", 200, 7, 7, 65, ["evidence", "flirt"], ["bluff", "bribe"],
                       ("The Trust has rented the records room for a week and left one woman in it with a stamp.", "信託は記録室を一週間借り、判子を持った女を一人そこに置いていった。"),
                       ("She stamps your box RETURNED, which is the nicest word she knows.", "彼女はあなたの箱に『返却』の判を押した。彼女の知る一番優しい言葉だ。"),
                       [("Box number?", "箱番号は？"), ("No originals leave this room.", "原本はこの部屋から出ません。")], drop="audit_trail"),
    **crisis("varga", ("Ilse Varga, the Trust's auditor", "信託の監査人イルゼ・ヴァルガ"), "varga", 370, 9, 8, 160, ["evidence", "audit"], ["bluff", "flirt", "bribe"],
             ("She has spread six years of the building's accounts across the conference table in the order in which they lie.", "彼女は六年分のビルの帳簿を、嘘をついている順に会議机に並べた。"),
             ("She closes the last binder. 'Clean. Irritatingly.' She almost smiles. Almost.", "最後のバインダーを閉じる。「きれいね。腹立たしいほど」ほとんど笑った。ほとんど。"),
             [("Every column has a person under it.", "どの列の下にも人がいる。"), ("Round that again.", "そこ、もう一度丸めて。"),
              ("I audit, I do not negotiate.", "私は監査する。交渉はしない。")], drop="fountain_pen"),
    # ---- night 4: the newsroom on eight
    "mover": E("mover", ("A repo crew foreman", "差し押さえ班の班長"), "mover", 250, 8, 8, 80, ["threaten", "keys"], ["flirt", "bluff"],
               ("He has a van, four men and a list of the newsroom's furniture, and the list has been signed by someone.", "バンと四人の男と、新聞部の家具の一覧。一覧には誰かの署名がある。"),
               ("He folds the list into his top pocket. 'Wrong date. My mistake.' It was not his mistake.", "彼は一覧を胸ポケットにしまった。「日付違いだ。俺のミスだ」彼のミスではない。"),
               [("Just doing the job.", "仕事してるだけだ。"), ("Desk, desk, chair, desk.", "机、机、椅子、机。")], drop="thermos"),
    "printer_rep": E("printer_rep", ("A lease-company rep", "リース会社の担当者"), "lawyer", 270, 8, 8, 85, ["evidence", "flirt"], ["threaten", "bribe"],
                     ("He has come at two in the morning to repossess a printing press, with a tablet and a lawyer's smile on loan.", "午前二時に、タブレットと借り物の弁護士の笑みを携えて、印刷機を引き取りに来た。"),
                     ("He photographs the press, for the file, and leaves it where it is.", "彼は記録用に印刷機を撮影し、そのまま置いて帰った。"),
                     [("It's on the schedule.", "予定表に載ってる。"), ("Nobody prints any more.", "今どき誰も印刷しない。")], drop="court_error"),
    **crisis("bailiff", ("The Bailiff", "執行官"), "bailiff", 540, 10, 9, 180, ["evidence", "headline"], ["bribe", "flirt", "threaten"],
             ("He reads the order aloud in the newsroom, slowly, so that everyone who still works there can hear it.", "彼は新聞部で命令書を読み上げる。まだここで働く全員に聞こえるよう、ゆっくりと。"),
             ("He folds the order. 'Not tonight, then.' He sounds, of all things, relieved.", "命令書を畳む。「では今夜ではない」よりによって、ほっとした声だ。"),
             [("Noted.", "記録した。"), ("Everything is due eventually.", "いずれはすべて期限が来る。"),
              ("I have done this to better buildings.", "もっと良いビルにもやってきた。")], drop="press_pass"),
    # ---- night 5: the penthouse
    "lawyer": E("lawyer", ("Mr. Sallow, the Trust's counsel", "信託の顧問弁護士サロウ"), "lawyer", 340, 9, 9, 100, ["audit", "evidence"], ["bluff", "flirt"],
                ("He offers you a pen before he offers you the paper. He has done this many times.", "紙より先にペンを差し出してくる。何度もやってきた手つきだ。"),
                ("He caps the pen. He will bill someone for the time; it will not be you.", "彼はペンにキャップをする。この時間は誰かに請求するだろう。あなたではない。"),
                [("Sign here, and here.", "ここと、ここに署名を。"), ("This is a courtesy.", "これは好意です。")], drop="trust_deed"),
    **crisis("halvard", ("Corinne Halvard", "コリンヌ・ハルヴァード"), "halvard", 760, 11, 10, 220, ["keys", "headline", "audit"], ["threaten", "bribe", "bluff"],
             ("The heir of the Trust takes Mirei's chair as if it had been kept warm for her, and asks what the building is worth to you.", "信託の相続人はミレイの椅子に、自分のために温められていたかのように座り、このビルがあなたにとっていくらの価値かと尋ねる。"),
             ("She stands, smooths the white suit, and holds out her hand to Mirei. 'Keep it, then. Make it worth something.'", "彼女は立ち上がり、白いスーツを撫でつけ、ミレイに手を差し出した。「では持っていなさい。価値のあるものにして」"),
             [("Everything in this city is rented.", "この街のものはすべて借り物よ。"), ("Mirei always did love a lost cause.", "ミレイは昔から負け戦が好きだった。"),
              ("Name a number.", "数字を言いなさい。"), ("I could buy your staff.", "あなたのスタッフを買うこともできる。")]),
}

ENEMY_SPRITES = ("courier", "pryce", "sublet", "wes", "junior", "varga", "mover", "bailiff", "lawyer", "halvard")
PARTY_SPRITES = ("mara_work", "mara_after", "priya_work", "priya_after", "nia_work", "nia_after", "sol_work", "sol_after", "mirei")
ROOMS = ("lobby", "open_plan", "copy_room", "break_room", "sublet", "meeting_room", "stairwell", "accounts", "records",
         "server_room", "newsroom", "print_room", "rooftop", "penthouse", "boardroom", "vault")
# (cg id, Trust gate shown on the locked tile, title EN, title JA)
GALLERY = [
    ("cg_mirei_lease", 0, "Mirei — the lease", "ミレイ — 契約"),
    ("cg_evicted", 0, "A floor short of rent", "家賃の足りない階"),
    ("cg_mara_sofa", 3, "Mara — the sofa on twelve", "マーラ — 十二階のソファ"),
    ("cg_mara_corners", 5, "Mara — the corner office", "マーラ — 角部屋"),
    ("cg_priya_rooftop", 3, "Priya — the roof at sunrise", "プリヤ — 夜明けの屋上"),
    ("cg_priya_x", 5, "Priya — the service corridor", "プリヤ — 業務用通路"),
    ("cg_nia_ledger", 3, "Nia — the ledger", "ニア — 帳簿"),
    ("cg_nia_after", 5, "Nia — after the audit", "ニア — 監査のあとで"),
    ("cg_sol_press", 3, "Sol — the last edition", "ソル — 最終版"),
    ("cg_sol_after", 5, "Sol — four in the morning", "ソル — 午前四時"),
    ("cg_mirei_window", 3, "Mirei — the penthouse window", "ミレイ — ペントハウスの窓"),
    ("cg_glass_office", 5, "Mirei — against the glass", "ミレイ — ガラス越しに"),
    ("cg_vault_x", 5, "Mirei — the vault", "ミレイ — 金庫室"),
    ("cg_keys", 0, "Full occupancy", "満室"),
    ("cg_floor9", 0, "Holding on — dawn", "持ちこたえて — 夜明け"),
]
# cg id -> (plate slot in ops/overtime_art/out/plates, picked file)
CG_SOURCES = {
    "cg_mirei_lease": "cg_mirei_lease/cg_mirei_lease_02", "cg_evicted": "cg_evicted/cg_evicted_01",
    "cg_mara_sofa": "f2p_mara_sofa/f2p_mara_sofa_03", "cg_mara_corners": "cg_mara_corners/cg_mara_corners_00",
    "cg_priya_rooftop": "f2p_priya_rooftop/f2p_priya_rooftop_02", "cg_priya_x": "cg_priya_x/cg_priya_x_02",
    "cg_nia_ledger": "f2p_nia_ledger/f2p_nia_ledger_01", "cg_nia_after": "f2p_nia_after/f2p_nia_after_00",
    "cg_sol_press": "f2p_sol_press/f2p_sol_press_03", "cg_sol_after": "f2p_sol_after/f2p_sol_after_02",
    "cg_mirei_window": "f2p_mirei_window/f2p_mirei_window_02", "cg_glass_office": "cg_glass_office/cg_glass_office_00",
    "cg_vault_x": "cg_vault_x/cg_vault_x_02",
    "cg_keys": "f2p_b5_keys/f2p_b5_keys_02", "cg_floor9": "cg_floor9/cg_floor9_01",
}
for cid, _, en, ja in GALLERY:
    T["g_" + cid] = (en, ja)

# ---- the office: OCCUPANCY's second genre (scripts/office.gd) ----------------------------
# The board is Overtime Landlord's 5x4 floor, settled by Roster.settle_idle() (the committed
# landlord.gd / roster.gd, unchanged). A night's shift settles the board SHIFTS times and pays
# the rent fund. Each floor's rent is due at its crisis. Recruits and supplies are paid for
# from the same fund -- every dollar here is in-game; nothing is sold for real money.
OFFICE = {
    "shifts": 8,
    "rent": {"n1": 1500, "n2": 1900, "n3": 2400, "n4": 3200, "n5": 4200},
    "pull_cost": 400, "pull10_cost": 3600,
    # rarity weights; the pity is generous because this is a game you have already paid for
    "rates": {"common": 70, "rare": 25, "epic": 5}, "pity": 10,
    "pool": {"common": ["priya", "mara", "dan"], "rare": ["nia", "wes"], "epic": ["sol"]},
    "pool_flags": {"wes": "wes_done"},
    "party": ["mara", "priya", "nia", "sol"],
    "start_owned": {"mara": 1, "dan": 1},
    "start_objects": {"coffee": 2, "mute": 1},
    "objects": {"coffee": 300, "mute": 600, "printer": 700, "corner": 500},
    "supplies": {"espresso": 240, "pastry": 500, "energy": 300, "mints": 500, "voucher": 400,
                 "clipboard": 1200, "tablet": 1400, "earpiece": 1600, "gold_lanyard": 1800,
                 "orchid": 1200, "whisky": 1200, "craft_beer": 800, "ink": 1200, "first_edition": 1400,
                 "mara_after": 1800, "priya_after": 1800, "nia_after": 1800, "sol_after": 1800},
    "once": ["mara_after", "priya_after", "nia_after", "sol_after", "clipboard", "tablet", "earpiece", "gold_lanyard", "orchid", "whisky", "craft_beer", "ink", "first_edition"],
    # a party woman placed on the board for a shift gets +1 Trust (once a night): she worked
    # the floor you built, and she noticed
    "trust_on_shift": 1,
}

game = {
    "title_key": "title", "logo": "res://assets/title/logo.png", "title_bg": "res://assets/title/keyvisual.png",
    "fonts": {"body": "res://assets/fonts/Nunito.ttf", "display": "res://assets/fonts/LilitaOne-Regular.ttf",
              "cjk": "res://assets/fonts/NotoSansCJKjp-subset.ttf"},
    "ui": {"dust": "res://assets/ui/dust.png", "vignette": "res://assets/ui/vignette.png", "scrim": "res://assets/ui/scrim.png",
           "dim": "res://assets/ui/scrim.png", **{k: f"res://assets/ui/{v}.png" for k, v in {
               "panel": "panel", "textbox": "textbox", "namebox": "namebox", "choice_idle": "choice_idle",
               "choice_hover": "choice_hover", "slot_idle": "slot_idle", "slot_hover": "slot_hover",
               "bar_under": "bar_under", "bar_fill": "bar_fill", "bar_fill_gold": "bar_fill_gold", "modal": "modal"}.items()}},
    "title_mood": {"ambient": "#fff4ea", "torch": False, "zoom": 1.04, "offset": [-120, 0]},
    "music": {k: f"res://assets/audio/{v}.ogg" for k, v in {
        "title": "suspense_theme", "explore": "explore", "battle": "standoff", "boss": "boss",
        "intimate": "intimate", "dawn": "dawn", "reading": "ecchi_theme"}.items()},
    "audio": {k: f"res://assets/audio/{v}.ogg" for k, v in {
        "ambience": "rain_ambience", "click": "ui_click", "page_flip": "page_flip", "heartbeat": "heartbeat",
        "sting": "title_sting", "camera": "ui_click"}.items()},
    "disclosure_key": "about_ai",
    "trial_last_night": "n1", "trial_locked_cgs": [],
    "store_url": "",          # DLsite build: no outbound link anywhere (他サイトへの誘導)
    "stats": ["wit", "cha", "grt", "stl"],
    "level_cap": 20, "trust_thresholds": [3, 5],
    "trust_tracks": ["mara", "priya", "nia", "sol", "mirei"],
    "hud_counter": "coin",
    "heroine_flag": "mara_on", "heroine_sprite": "mara_work",
    "party": [
        {"id": "mara", "join_flag": "mara_on", "base": {"wit": 4, "cha": 3, "grt": 4, "stl": 3}, "grow": ["wit", "grt", "cha", "stl"],
         "actions": ["deflect", "observe", "evidence", "threaten", "stall", "item"],
         "branches": {"keys": ["m_ring", "m_plan", "m_master", "m_lockdown"], "steel": ["m_steady", "m_glare", "m_spine"]},
         "start_equip": {"outfit": "mara_work", "accessory": "keyring"}},
        {"id": "priya", "join_flag": "hired_priya", "base": {"wit": 3, "cha": 4, "grt": 4, "stl": 2}, "grow": ["grt", "cha", "wit", "stl"],
         "actions": ["deflect", "bluff", "flirt", "stall", "item"],
         "branches": {"tools": ["p_wrench", "p_fix", "p_overtime"], "banter": ["p_grin", "p_tease", "p_wink"]},
         "start_equip": {"outfit": "priya_work", "accessory": "safety_glasses"}},
        {"id": "nia", "join_flag": "hired_nia", "base": {"wit": 6, "cha": 3, "grt": 3, "stl": 4}, "grow": ["wit", "stl", "cha", "grt"],
         "actions": ["deflect", "observe", "evidence", "bluff", "item"],
         "branches": {"ledger": ["n_columns", "n_audit", "n_forensic"], "poise": ["n_glasses", "n_dry", "n_cold"]},
         "start_equip": {"outfit": "nia_work"}},
        {"id": "sol", "join_flag": "hired_sol", "base": {"wit": 4, "cha": 6, "grt": 3, "stl": 4}, "grow": ["cha", "stl", "wit", "grt"],
         "actions": ["deflect", "flirt", "bribe", "stall", "item"],
         "branches": {"press": ["s_lede", "s_headline", "s_front"], "warmth": ["s_tea", "s_warm", "s_late"]},
         "start_equip": {"outfit": "sol_work"}},
    ],
    "start_items": {"coin": 600, "espresso": 2, "voucher": 1},
    "actions": ACTIONS, "skills": SKILLS, "items": ITEMS, "enemies": ENEMIES,
    "nights": ["n1", "n2", "n3", "n4", "n5"], "story": [],
    "office": OFFICE,
    "gallery": [{"id": c, "thumb": c + "_thumb", "locked": c + "_locked", "key": "g_" + c, "trust": t} for c, t, _, _ in GALLERY],
    "voice": {},
}

art = {"rooms": {r: [f"res://assets/rooms/{r}.png"] for r in ROOMS},
       "rooms_locked": {r: [f"res://assets/rooms_locked/{r}.png"] for r in ROOMS},
       "enemies": {s: [f"res://assets/enemies/{s}.png"] for s in ENEMY_SPRITES},
       "sprites": {s: [f"res://assets/sprites/{s}.png"] for s in PARTY_SPRITES},
       "maps": {"tower": ["res://assets/ui/map.png"]},
       "cg": {}}
for cid, _, _, _ in GALLERY:
    art["cg"][cid] = [f"res://assets/cg/{cid}.png"]
    for suf in ("_thumb", "_locked"):
        art["cg"][cid + suf] = [f"res://assets/cg/{cid}{suf}.png"]

_voice = HERE / "strings_voice.py"
if _voice.exists():
    ns = {}
    exec(_voice.read_text(), ns)
    for k in ns["S"]:
        game["voice"][k] = {"v_en": f"res://assets/voice/{k}.ogg"}

if __name__ == "__main__":
    D.mkdir(exist_ok=True)
    (D / "game.json").write_text(json.dumps(game, indent=1, ensure_ascii=False))
    (D / "art_manifest.json").write_text(json.dumps(art, indent=1))
    body = "# GENERATED by tools/build_data.py (enemy names, intros, wins, barks; gallery titles)\nS = {\n"
    for k, (en, ja) in T.items():
        body += f"{k!r}: ({en!r}, {ja!r}),\n"
    (HERE / "strings_enemies.py").write_text(body + "}\n")
    print(f"game.json ({len(ENEMIES)} enemies, {len(ITEMS)} items, {len(GALLERY)} CGs) + art_manifest.json + {len(T)} enemy strings")


def _wire_voice():
    """Voice packs (ops/dlsite/voice_bulk.py wire): point the heroine lines at assets/voice/<lang>/.
    Idempotent; re-applied after every rebuild so a regenerated file keeps the packs."""
    import subprocess as _sp
    _w = Path(__file__).resolve().parents[3] / "ops/dlsite/voice_bulk.py"
    if _w.exists():
        _sp.run(["python3", str(_w), "wire", "occupancy"], check=False)


_wire_voice()
