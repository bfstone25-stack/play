## RTStrings — UI copy, ported from play/rebound-tycoon/frontend/js/copy.js. en + zh-Hans
## ship together (play/catharsis/PLAN.md locale rule: zh-Hans first, then EN). The JS build
## also carried es/pt/ja; this rebuild ships the two the plan requires and the rest come
## back when the copy is re-cut for the new screens rather than machine-carried.
## Never hardcode a user-visible string in a scene.
class_name RTStrings

const EN := {
	"wordmark": "REBOUND", "local_title": "Rebound Tycoon",
	"tagline": "Hose the night. Bank the rent.",
	"kicker": "GATE 01 · NIGHT EMPIRE",
	"studio": "blazeCore Play",
	"pitch": "You are the night-shift guard. Pump the water hose to launch. Every rebound soaks a troublemaker and pays rent. Spend the coins on towers until the booth becomes an empire.",
	"start": "TAKE THE GATE", "cont": "BACK ON DUTY", "again": "NEW NIGHT",
	"spray": "PUMP HOSE", "launch_hint": "Hold Space, or tap PUMP HOSE", "space_hint": "HOLD SPACE",
	"left": "LEFT", "right": "RIGHT",
	"shop": "LEDGER", "prestige": "REBOUND", "settings": "BOOTH",
	"coins": "COINS", "rent": "RENT", "combo": "COMBO", "night": "NIGHT", "era": "ERA",
	"balls": "HOSES", "tokens": "TOKENS",
	"waiting": "ON DUTY", "live": "HOSE LIVE", "ringing": "PUMP", "nightover": "SHIFT OVER",
	"close": "CLOSE", "back": "BACK", "lang": "中文",
	"need": "Need more coins", "need_tokens": "Need more tokens",
	"prestige_hint": "Reset the table. Keep the tokens. Come back louder.",
	"prestige_locked": "Reach the lobby era, then earn a token.",
	"prestige_go": "REBOUND THE EMPIRE",
	"shop_hint": "Upgrade the table. Then the towers.",
	"perk_hint": "Spend tokens. The uniform remembers.",
	"sound": "Sound", "on": "ON", "off": "OFF",
	# Reduced motion. "Auto" follows the system switch; the other two override it.
	"motion": "Motion", "motion_auto": "Auto", "motion_calm": "Calm", "motion_full": "Full",
	# ---- the return screen (the offline gate, PLAN.md wave 4) ----
	"return_title": "THE GATE KEPT COLLECTING",
	"return_body": "You were away {t}. The booth banked {c} coins.",
	"return_capped": "Eight hours is the cap. The rest of {t} went to the landlord.",
	"return_rate": "{r} coins / second",
	"return_claim": "TAKE THE COINS",
	"away_h": "{h}h {m}m", "away_m": "{m}m {s}s", "away_s": "{s}s",
	# ---- the run-end board ----
	"more_games": "MORE FROM THE CABINET",
	"eras": {"booth": "Booth", "lobby": "Lobby", "towers": "Towers", "neon": "Neon Empire"},
	"groups": {"table": "Table", "staff": "Staff", "property": "Property", "amenity": "Amenities"},
	"upgrades": {
		"springs": "Plunger Springs", "flippers": "Gold Flippers", "bumpers": "Hot Bumpers",
		"slings": "Slingshots", "doorman": "Ball Save", "concierge": "Bonus Hold",
		"manager": "Extra Ball", "studio": "Studio", "loft": "Loft", "penthouse": "Penthouse",
		"cannon": "Water Cannon", "neon": "Neon Sign",
	},
	"hints": {
		"springs": "More pressure in the hose.",
		"flippers": "Faster gate arms. Meaner rebounds.",
		"bumpers": "Troublemakers pay more when soaked.",
		"slings": "The gate posts shove back.",
		"doorman": "Saves one missed shot each hose.",
		"concierge": "Every rebound pays louder rent.",
		"manager": "Start the night with an extra hose.",
		"studio": "A window. Then a skyline.",
		"loft": "Mid-rise rent multiplier.",
		"penthouse": "The reason the uniform went gold.",
		"cannon": "The center hose fires harder.",
		"neon": "The city admits you own the building.",
	},
	"perks": {
		"uniform": "Gold-Trim Uniform", "legend": "Legendary Cannon",
		"switchboard": "Ringing Switchboard", "empire": "Empire Fund",
	},
	"perk_hints": {
		"uniform": "+8% score per rank.", "legend": "Stronger saucer kick.",
		"switchboard": "Lights remember you.", "empire": "+12% score and +12% offline per rank.",
	},
	"hits": {
		"courier": "Courier soaked. Rent collected.",
		"party": "Floor 6 shut down. They paid.",
		"raccoon": "Raccoon bounced. Fine collected.",
		"booth": "Booth intercom. Tip jar.",
		"lobby": "Lobby intercom. Late fee.",
		"tower": "Penthouse intercom. Bonus.",
		"cannon": "Water cannon. Full pressure.",
		"sling": "Gate post. Another coin.",
		"gate": "All intercoms. Jackpot rent.",
	},
	"lines": {
		"booth": "Night shift. Pump the hose. Make them pay.",
		"lobby": "The gate is collecting rent now.",
		"towers": "The water cannon has a waiting list.",
		"neon": "The skyline finally learned your name.",
		"bumper": "Soaked. Coin in the till.",
		"drain": "Hose ran dry. Next burst.",
		"save": "The doorman caught the drip.",
		"nightover": "Shift over. Count the coins.",
		"launch": "Hose is live.",
		"buy": "The building noticed.",
		"prestige": "Leave the booth. Keep the gold.",
		"gate": "Every intercom lit. Jackpot rent.",
	},
}

const ZH := {
	"wordmark": "REBOUND", "local_title": "老王逆袭记",
	"tagline": "弹球值夜，再买下天际线。",
	"kicker": "一号球台 · 夜帝国",
	"studio": "blazeCore Play",
	"pitch": "你是夜班保安老王。压水炮发球，每一次回弹都浇醒一个麻烦、收到一笔租金。把硬币花成塔楼，直到岗亭变成帝国。",
	"start": "上岗", "cont": "回到岗位", "again": "再值一晚",
	"spray": "压水炮", "launch_hint": "按住空格，或点压水炮", "space_hint": "按住空格",
	"left": "左挡", "right": "右挡",
	"shop": "账本", "prestige": "翻身", "settings": "岗亭",
	"coins": "硬币", "rent": "租金", "combo": "连击", "night": "夜班", "era": "时代",
	"balls": "球数", "tokens": "翻身币",
	"waiting": "就绪", "live": "球在台上", "ringing": "待发", "nightover": "夜班结束",
	"close": "关闭", "back": "返回", "lang": "EN",
	"need": "硬币不够", "need_tokens": "翻身币不够",
	"prestige_hint": "重置球台，留下代币。",
	"prestige_locked": "先进入大堂时代，再赚到一枚翻身币。",
	"prestige_go": "弹回整个帝国",
	"shop_hint": "先改球台，再买塔楼。",
	"perk_hint": "花掉代币。制服记得你。",
	"sound": "声音", "on": "开", "off": "关",
	"motion": "动效", "motion_auto": "自动", "motion_calm": "平缓", "motion_full": "全开",
	"return_title": "岗亭替你收了一夜",
	"return_body": "你离开了 {t}。岗亭收进 {c} 枚硬币。",
	"return_capped": "上限是八小时。{t} 里剩下的都归了房东。",
	"return_rate": "每秒 {r} 枚硬币",
	"return_claim": "收下硬币",
	"away_h": "{h} 小时 {m} 分", "away_m": "{m} 分 {s} 秒", "away_s": "{s} 秒",
	"more_games": "同一台机器上的其他游戏",
	"eras": {"booth": "岗亭", "lobby": "大堂", "towers": "塔楼", "neon": "霓虹帝国"},
	"groups": {"table": "球台", "staff": "人手", "property": "物业", "amenity": "配套"},
	"upgrades": {
		"springs": "发射簧", "flippers": "金挡板", "bumpers": "热碰柱", "slings": "弹板",
		"doorman": "救球", "concierge": "加成", "manager": "加一球", "studio": "开间",
		"loft": "复式", "penthouse": "顶层", "cannon": "水炮穴", "neon": "霓虹",
	},
	"hints": {
		"springs": "发射更狠。", "flippers": "挡板更快。", "bumpers": "踢得更响。",
		"slings": "下沿往回推。", "doorman": "漏球时救一次。", "concierge": "每次命中更肥。",
		"manager": "开局多一球。", "studio": "背板上多一扇窗。", "loft": "中层倍率。",
		"penthouse": "挡板镀金的理由。", "cannon": "球穴像水管一样喷。",
		"neon": "这座城承认这张台是你的。",
	},
	"perks": {
		"uniform": "金边制服", "legend": "传说水炮", "switchboard": "总机", "empire": "帝国基金",
	},
	"perk_hints": {
		"uniform": "每级分数 +8%。", "legend": "球穴更猛。", "switchboard": "灯会记得你。",
		"empire": "每级分数 +12%，离线收益 +12%。",
	},
	"hits": {
		"courier": "快递被浇透了，租金到手。",
		"party": "六楼的派对散了，他们付了钱。",
		"raccoon": "浣熊被弹开，罚款入账。",
		"booth": "岗亭对讲机，小费罐。",
		"lobby": "大堂对讲机，滞纳金。",
		"tower": "顶层对讲机，奖金。",
		"cannon": "水炮全压。",
		"sling": "门柱，又一枚硬币。",
		"gate": "对讲机全亮，彩金租。",
	},
	"lines": {
		"booth": "三颗球。一座岗亭。打回去。",
		"lobby": "挡板开始交租了。",
		"towers": "这张台已经有候补。",
		"neon": "天际线学会了你的名字。",
		"bumper": "回弹。硬币入柜。",
		"drain": "漏了。下一球。",
		"save": "门童接住了。",
		"nightover": "夜班结束。数硬币。",
		"launch": "球活了。",
		"buy": "球台看见了。",
		"prestige": "离开岗亭，带走金子。",
		"gate": "门岗点亮。彩金。",
	},
}


static func bank() -> Dictionary:
	return ZH if Game.lang == "zh" else EN


static func t(key: String, vars: Dictionary = {}) -> String:
	var b := bank()
	var s: String = str(b.get(key, EN.get(key, key)))
	for k in vars:
		s = s.replace("{" + k + "}", str(vars[k]))
	return s


## A key inside one of the nested maps ("upgrades", "hints", "eras", "lines", "hits", ...).
static func tm(group: String, key: String) -> String:
	var b := bank()
	var g = b.get(group, {})
	if typeof(g) == TYPE_DICTIONARY and g.has(key):
		return str(g[key])
	var e = EN.get(group, {})
	return str(e.get(key, key)) if typeof(e) == TYPE_DICTIONARY else key


## "1h 12m" / "12m 30s" / "30s" — the return screen's elapsed time, localised.
static func away(seconds: float) -> String:
	var s := int(maxf(0.0, seconds))
	if s >= 3600:
		return t("away_h", {"h": s / 3600, "m": (s % 3600) / 60})
	if s >= 60:
		return t("away_m", {"m": s / 60, "s": s % 60})
	return t("away_s", {"s": s})
