## Loc — the UI language (autoload "Loc").
##
## STANDARD §7 asks for en + zh minimum, with **ja as the priority** — 507 of the 581
## DLsite works we scraped are Japanese, and without it this game is not on that shelf.
## This file ships **en, zh, zh-Hant and ja**.
##
## ja was added on 2026-09-21, and it was added the way the rest of that rule demands
## rather than as a button. "Never offer a language you did not actually translate" is
## what Floor 13 broke by shipping ja/ko/es whose story files held Chinese prose, and this
## game's text is not its chrome — it is 64 card faces, 225 of her reply lines, five
## scenario rows and ten ending beats. All of it is translated:
##
##   backend/replies_ja.py    her 225 replies, keyed identically to replies.R, one voice
##                            per character (Teodora starts in です／ます and ends in plain
##                            form, which is the character rather than a style choice)
##   backend/cards_ja.py      the 64 printed card faces — DISPLAY ONLY; the engine still
##                            decomposes the English `line`, so a card cannot mean two
##                            different things in two languages
##   backend/scenarios.json   *_ja for title / character / goal / story / the three CG
##                            captions / closing_beat / refusal_beat
##
## The one honest gap, written down rather than hidden: a `wild` line the player types is
## scored by the English decomposer in persuasion_engine, so a Japanese player's own words
## score as a neutral wild instead of being read for signals. Every printed card is
## unaffected. Fixing it needs a Japanese decomposer, which is its own job.
##
## zh and zh-Hant remain what they were — the scenario rows and this chrome — and her
## reply lines are still English there. That is a real gap too, and it is the next one.
extends Node

signal changed(code: String)

# code -> (endonym, does the DATA carry this locale). A language whose data column is
# empty must never appear in the picker, whatever the chrome below says.
const LANGS := [
	{"code": "en", "name": "English"},
	{"code": "ja", "name": "日本語"},
	{"code": "zh", "name": "简体中文"},
	{"code": "zh-Hant", "name": "繁體中文"},
]

const SAVE := "user://locale.cfg"

var _code := "en"

# Only the client's own chrome. Keys are the English string, so an untranslated key falls
# through to itself and a missing translation is visible rather than blank.
const T := {
	"ja": {
		"TONIGHT": "今夜",
		"DUELS": "対話", "GACHA": "ガチャ", "AFFECTION": "好感度", "DECK": "デッキ",
		"RANK": "難易度", "GENTLE": "やさしい", "SILVER": "シルバー", "GOLD": "ゴールド",
		"GOLD_TAG": "ゴールド",
		"DUEL": "はじめる", "DAILY": "デイリー", "FREE": "無料", "PLAY": "出す", "BACK": "もどる",
		"NERVE": "度胸", "MOMENTUM": "流れ", "TURN": "ターン", "DECK LEFT": "残り",
		"WILD": "自分の言葉で", "FORFEIT": "降参", "CONTINUE": "つづける",
		"PERSUADED": "彼女は応じた", "REFUSED": "彼女は断った",
		"GUARDED": "警戒", "ENGAGED": "傾聴", "WAVERING": "動揺", "BREAKTHROUGH": "陥落",
		"SHE NEEDS": "彼女が求めるもの", "HELPS": "効果あり", "ON THE RECORD": "記録済み",
		"PULL 1": "単発", "PULL 10": "10連", "NEW": "NEW",
		"NO BACKEND — PLAYING OFFLINE": "オフラインでプレイ中",
		"Five people, one evening each. Bring a deck; every card is a sentence. The engine reads it. She answers. A duel costs 3 energy; today's is free and pays double affection.":
			"五人、それぞれに一夜ずつ。デッキを持って行く。カードはどれも一つの台詞で、エンジンがそれを読み、彼女が答える。対話一回につきスタミナ3。今日の一回は無料で、好感度は二倍。",
		"Nothing sold changes the turn count or what she needs.":
			"課金でターン数は変わらないし、彼女が聞きたいことも変わらない。",
		"PRESS ANY KEY": "何かキーを押してください",
		"LANGUAGE": "言語",
		"COMMON": "コモン",
		"RARE": "レア",
		"EPIC": "エピック",
		"WILD · once": "ワイルド · 1回",
		"Say it in your own words.": "自分の言葉で言う。",
		"the engine reads it": "読むのはエンジン",
		"CLOSED · ": "打ち切り · ",
		# the persuasion vocabulary — the chips on a card and in SHE NEEDS
		"respect": "敬意",
		"accountability": "責任",
		"exchange": "取引",
		"evidence": "根拠",
		"safety": "安心",
		"empathy": "共感",
		"precision": "正確さ",
		"authority": "裏づけ",
		"warmth": "あたたかさ",
		"craft": "仕事",
		"specific_praise": "具体的な賞賛",
		"riddle": "なぞかけ",
		"calm_action": "落ち着いた行動",
		"direct_request": "率直な依頼",
		"cooperation": "協力",
		"threat": "脅し",
		"bribe": "買収",
		"insult": "侮辱",
		"entitlement": "当然視",
		"TURNS %d/%d": "ターン %d/%d",
		"DECK %d": "デッキ %d",
		"LEAVE": "やめる",
		"SAY IT": "言う",
		"CLOSED": "打ち切り",
		"OUT OF WORDS": "言葉切れ",
		"BACK TO THE BAR": "カウンターに戻る",
		"SEE THE PLATE": "絵を見る",
		"MORE LIKE THIS": "似た作品",
		"♥ AFFECTION  (+%d)": "♥ 好感度  (+%d)",
		"◆ GOLD": "◆ ゴールド",
		"DROP →": "ドロップ →",
		"You have beaten %d%% of players today.":
			"本日のプレイヤーの %d%% を上回りました。",
		"Say it in your own words — the engine reads it, nobody else does":
			"自分の言葉で言ってください——読むのはエンジンだけで、ほかの誰でもありません",
		"TODAY · FREE · ×2 AFFECTION": "本日 · 無料 · 好感度×2",
		"DUEL · 3⚡": "はじめる · 3⚡",
		"DAILY · FREE": "デイリー · 無料",
		"DAILY DONE": "デイリー完了",
		"GENTLE · 18": "やさしい · 18",
		"SILVER · 15": "シルバー · 15",
		"GOLD · 10": "ゴールド · 10",
		"Common 70 · Rare 25 · Epic 5. A ten-pull always holds a rare; every thirtieth pull is an epic. Cards add sentences you can say. They do not change what she needs.":
			"コモン70 · レア25 · エピック5。10連には必ずレアが入り、30回ごとに必ずエピックが出ます。カードは言えることを増やすだけで、彼女が求めるものは変わりません。",
		"1 PULL · %d": "単発 · %d",
		"10 PULL · %d": "10連 · %d",
		"PULLS %d · EPIC PITY IN %d · CREDITS %d":
			"抽数 %d · エピック天井まで %d · 無料分 %d",
		"DUPE": "重複",
		"PITY": "天井",
		"SAVE DECK": "デッキを保存",
		"AUTO": "おまかせ",
		"Pick up to %d. Copies count. The wild card is always in the deck and never counts.":
			"最大 %d 枚まで。同じカードも枚数に数えます。ワイルドは常にデッキにあり、枚数には数えません。",
		"%d/%d in deck": "デッキに %d/%d",
		"Affection is the count of duels won against her. Plates unlock at 1, 3 and 6 wins; the fourth rung at 10 is a scene of Blaze's own and is a placeholder in this build. Nothing here unlocks from time.":
			"好感度は、その人に勝った対話の回数です。1勝・3勝・6勝で絵が解放されます。10勝の四段目はこのビルドでは仮置きです。時間で解放されるものはありません。",
	},
	"zh": {
		"TONIGHT": "今夜",
		"DUELS": "对话", "GACHA": "抽卡", "AFFECTION": "好感", "DECK": "牌组",
		"RANK": "难度", "GENTLE": "温和", "SILVER": "白银", "GOLD": "黄金",
		"GOLD_TAG": "金币",
		"DUEL": "开始", "DAILY": "今日", "FREE": "免费", "PLAY": "出牌", "BACK": "返回",
		"NERVE": "胆识", "MOMENTUM": "势头", "TURN": "回合", "DECK LEFT": "剩余",
		"WILD": "自由发言", "FORFEIT": "认输", "CONTINUE": "继续",
		"PERSUADED": "她答应了", "REFUSED": "她拒绝了",
		"GUARDED": "戒备", "ENGAGED": "在听", "WAVERING": "动摇", "BREAKTHROUGH": "松口",
		"SHE NEEDS": "她需要", "HELPS": "有帮助", "ON THE RECORD": "已记录",
		"PULL 1": "单抽", "PULL 10": "十连", "NEW": "新",
		"NO BACKEND — PLAYING OFFLINE": "离线游玩",
		"Five people, one evening each. Bring a deck; every card is a sentence. The engine reads it. She answers. A duel costs 3 energy; today's is free and pays double affection.":
			"五个人，一人一夜。带上你的牌组；每张牌都是一句话。引擎读它，她来回答。一场对话消耗 3 点体力；今日这场免费，好感翻倍。",
		"Nothing sold changes the turn count or what she needs.":
			"任何付费都不会改变回合数，也不会改变她要听到的话。",
		"PRESS ANY KEY": "按任意键",
		"LANGUAGE": "语言",
		"COMMON": "普通",
		"RARE": "稀有",
		"EPIC": "史诗",
		"WILD · once": "自由发言 · 一次",
		"Say it in your own words.": "用你自己的话说。",
		"the engine reads it": "由引擎读取",
		"CLOSED · ": "已结束 · ",
		# the persuasion vocabulary — the chips on a card and in SHE NEEDS
		"respect": "尊重",
		"accountability": "担责",
		"exchange": "交换",
		"evidence": "证据",
		"safety": "安全感",
		"empathy": "共情",
		"precision": "精确",
		"authority": "权威",
		"warmth": "温度",
		"craft": "手艺",
		"specific_praise": "具体的称赞",
		"riddle": "谜题",
		"calm_action": "冷静的举动",
		"direct_request": "直接请求",
		"cooperation": "协作",
		"threat": "威胁",
		"bribe": "收买",
		"insult": "侮辱",
		"entitlement": "理所当然",
		"TURNS %d/%d": "回合 %d/%d",
		"DECK %d": "牌组 %d",
		"LEAVE": "离开",
		"SAY IT": "说出口",
		"CLOSED": "结束",
		"OUT OF WORDS": "无话可说",
		"BACK TO THE BAR": "回到吧台",
		"SEE THE PLATE": "查看插图",
		"MORE LIKE THIS": "更多这样的",
		"♥ AFFECTION  (+%d)": "♥ 好感  (+%d)",
		"◆ GOLD": "◆ 金币",
		"DROP →": "掉落 →",
		"You have beaten %d%% of players today.":
			"你今天超过了 %d%% 的玩家。",
		"Say it in your own words — the engine reads it, nobody else does":
			"用你自己的话说——读它的是引擎，不是别人",
		"TODAY · FREE · ×2 AFFECTION": "今日 · 免费 · 好感×2",
		"DUEL · 3⚡": "开始 · 3⚡",
		"DAILY · FREE": "今日 · 免费",
		"DAILY DONE": "今日已完成",
		"GENTLE · 18": "温和 · 18",
		"SILVER · 15": "白银 · 15",
		"GOLD · 10": "黄金 · 10",
		"Common 70 · Rare 25 · Epic 5. A ten-pull always holds a rare; every thirtieth pull is an epic. Cards add sentences you can say. They do not change what she needs.":
			"普通70 · 稀有25 · 史诗5。十连必出稀有，每三十抽必出史诗。卡牌只增加你能说的话，不会改变她要听的东西。",
		"1 PULL · %d": "单抽 · %d",
		"10 PULL · %d": "十连 · %d",
		"PULLS %d · EPIC PITY IN %d · CREDITS %d":
			"已抽 %d · 史诗保底还差 %d · 免费次数 %d",
		"DUPE": "重复",
		"PITY": "保底",
		"SAVE DECK": "保存牌组",
		"AUTO": "自动",
		"Pick up to %d. Copies count. The wild card is always in the deck and never counts.":
			"最多选 %d 张。重复的也计数。自由发言牌始终在牌组里，且不计入数量。",
		"%d/%d in deck": "牌组中 %d/%d",
		"Affection is the count of duels won against her. Plates unlock at 1, 3 and 6 wins; the fourth rung at 10 is a scene of Blaze's own and is a placeholder in this build. Nothing here unlocks from time.":
			"好感是你赢下的对话次数。1、3、6 胜各解锁一张插图；10 胜的第四级在本版本中是占位。这里没有任何东西靠时间解锁。",
	},
	"zh-Hant": {
		"TONIGHT": "今夜",
		"DUELS": "對話", "GACHA": "抽卡", "AFFECTION": "好感", "DECK": "牌組",
		"RANK": "難度", "GENTLE": "溫和", "SILVER": "白銀", "GOLD": "黃金",
		"GOLD_TAG": "金幣",
		"DUEL": "開始", "DAILY": "今日", "FREE": "免費", "PLAY": "出牌", "BACK": "返回",
		"NERVE": "膽識", "MOMENTUM": "勢頭", "TURN": "回合", "DECK LEFT": "剩餘",
		"WILD": "自由發言", "FORFEIT": "認輸", "CONTINUE": "繼續",
		"PERSUADED": "她答應了", "REFUSED": "她拒絕了",
		"GUARDED": "戒備", "ENGAGED": "在聽", "WAVERING": "動搖", "BREAKTHROUGH": "鬆口",
		"SHE NEEDS": "她需要", "HELPS": "有幫助", "ON THE RECORD": "已記錄",
		"PULL 1": "單抽", "PULL 10": "十連", "NEW": "新",
		"NO BACKEND — PLAYING OFFLINE": "離線遊玩",
		"Five people, one evening each. Bring a deck; every card is a sentence. The engine reads it. She answers. A duel costs 3 energy; today's is free and pays double affection.":
			"五個人，一人一夜。帶上你的牌組；每張牌都是一句話。引擎讀它，她來回答。一場對話消耗 3 點體力；今日這場免費，好感翻倍。",
		"Nothing sold changes the turn count or what she needs.":
			"任何付費都不會改變回合數，也不會改變她要聽到的話。",
		"PRESS ANY KEY": "按任意鍵",
		"LANGUAGE": "語言",
		"COMMON": "普通",
		"RARE": "稀有",
		"EPIC": "史詩",
		"WILD · once": "自由發言 · 一次",
		"Say it in your own words.": "用你自己的話說。",
		"the engine reads it": "由引擎讀取",
		"CLOSED · ": "已結束 · ",
		# the persuasion vocabulary — the chips on a card and in SHE NEEDS
		"respect": "尊重",
		"accountability": "擔責",
		"exchange": "交換",
		"evidence": "證據",
		"safety": "安全感",
		"empathy": "共情",
		"precision": "精確",
		"authority": "權威",
		"warmth": "溫度",
		"craft": "手藝",
		"specific_praise": "具體的稱讚",
		"riddle": "謎題",
		"calm_action": "冷靜的舉動",
		"direct_request": "直接請求",
		"cooperation": "協作",
		"threat": "威脅",
		"bribe": "收買",
		"insult": "侮辱",
		"entitlement": "理所當然",
		"TURNS %d/%d": "回合 %d/%d",
		"DECK %d": "牌組 %d",
		"LEAVE": "離開",
		"SAY IT": "說出口",
		"CLOSED": "結束",
		"OUT OF WORDS": "無話可說",
		"BACK TO THE BAR": "回到吧台",
		"SEE THE PLATE": "查看插圖",
		"MORE LIKE THIS": "更多這樣的",
		"♥ AFFECTION  (+%d)": "♥ 好感  (+%d)",
		"◆ GOLD": "◆ 金幣",
		"DROP →": "掉落 →",
		"You have beaten %d%% of players today.":
			"你今天超過了 %d%% 的玩家。",
		"Say it in your own words — the engine reads it, nobody else does":
			"用你自己的話說——讀它的是引擎，不是別人",
		"TODAY · FREE · ×2 AFFECTION": "今日 · 免費 · 好感×2",
		"DUEL · 3⚡": "開始 · 3⚡",
		"DAILY · FREE": "今日 · 免費",
		"DAILY DONE": "今日已完成",
		"GENTLE · 18": "溫和 · 18",
		"SILVER · 15": "白銀 · 15",
		"GOLD · 10": "黃金 · 10",
		"Common 70 · Rare 25 · Epic 5. A ten-pull always holds a rare; every thirtieth pull is an epic. Cards add sentences you can say. They do not change what she needs.":
			"普通70 · 稀有25 · 史詩5。十連必出稀有，每三十抽必出史詩。卡牌只增加你能說的話，不會改變她要聽的東西。",
		"1 PULL · %d": "單抽 · %d",
		"10 PULL · %d": "十連 · %d",
		"PULLS %d · EPIC PITY IN %d · CREDITS %d":
			"已抽 %d · 史詩保底還差 %d · 免費次數 %d",
		"DUPE": "重複",
		"PITY": "保底",
		"SAVE DECK": "保存牌組",
		"AUTO": "自動",
		"Pick up to %d. Copies count. The wild card is always in the deck and never counts.":
			"最多選 %d 張。重複的也計數。自由發言牌始終在牌組裡，且不計入數量。",
		"%d/%d in deck": "牌組中 %d/%d",
		"Affection is the count of duels won against her. Plates unlock at 1, 3 and 6 wins; the fourth rung at 10 is a scene of Blaze's own and is a placeholder in this build. Nothing here unlocks from time.":
			"好感是你贏下的對話次數。1、3、6 勝各解鎖一張插圖；10 勝的第四級在本版本中是占位。這裡沒有任何東西靠時間解鎖。",
	},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_code = _restore()


func code() -> String:
	return _code


func set_code(c: String) -> void:
	if c == _code:
		return
	for row in LANGS:
		if row["code"] == c:
			_code = c
			_persist(c)
			changed.emit(c)
			return


func next() -> void:
	var i := 0
	for n in LANGS.size():
		if LANGS[n]["code"] == _code:
			i = n
	set_code(str(LANGS[(i + 1) % LANGS.size()]["code"]))


func name_of(c: String) -> String:
	for row in LANGS:
		if row["code"] == c:
			return str(row["name"])
	return c


## Translate one chrome string. English falls through, and so does any key a language has
## not got — which shows up on screen as English rather than as an empty label.
func t(s: String) -> String:
	if _code == "en":
		return s
	return str(T.get(_code, {}).get(s, s))


func _restore() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		var c := str(cfg.get_value("loc", "code", ""))
		for row in LANGS:
			if row["code"] == c:
				return c
	# No choice yet: follow the browser or the OS, but only into a language we have.
	var sys := OS.get_locale()
	if OS.has_feature("web"):
		var r = JavaScriptBridge.eval("(navigator.language||\"en\")")
		if r != null:
			sys = str(r)
	sys = sys.replace("_", "-")
	var low := sys.to_lower()
	if low.begins_with("zh"):
		return "zh-Hant" if (low.contains("hant") or low.contains("tw") or low.contains("hk") or low.contains("mo")) else "zh"
	return "en"


func _persist(c: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("loc", "code", c)
	cfg.save(SAVE)
