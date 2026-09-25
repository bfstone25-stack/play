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

## The Night Ledger's words (Nutaku F2P): everything the title server sends a player --
## story, stages, her replies, card lines, bond scenes, store items, missions, refusals --
## keyed on the exact English string the server sends, built by
## tools/campaign_i18n.py and checked by ops/nutaku/suasion_f2p/check_i18n.py. The server
## stays English on purpose (card lines are rules the engine reads; replies are picked by
## the replay's seeded rng), so translating on arrival is the only place this can live.
const CAMPAIGN := "res://assets/i18n/campaign.json"
var _campaign := {}
var _num := RegEx.create_from_string("\\d+(?:\\.\\d+)?")

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
		# --- Nutaku F2P (SUASION: The Night Ledger) ---
		" — tickets are in the store": "——チケットはストアで",
		"%d CHIPS": "チップ %d",
		"%d DUPES — already in your collection": "%d 枚重複——すでに所持しています",
		"1 DUPE — already in your collection": "1 枚重複——すでに所持しています",
		"%d GOLD": "%d ゴールド",
		"%d TICKETS": "チケット %d 枚",
		"1 TICKET": "チケット 1 枚",
		"%d TURNS": "%d ターン",
		"(She is still waiting.)": "（彼女はまだ待っている。）",
		"(You say nothing.)": "（何も言わない。）",
		"+1 in %d:%02d": "あと %d:%02d で +1",
		"1 PULL · %d CHIPS": "単発 · チップ %d",
		"1 PULL · 1 TICKET": "単発 · チケット 1 枚",
		"10 PULL · %d CHIPS": "10連 · チップ %d",
		"10 PULL · 10 TICKETS": "10連 · チケット 10 枚",
		"A card that adds nothing new costs two turns.": "新しいものを何も足さないカードは2ターンかかる。",
		"AFTER HOURS · CARDS": "アフターアワーズ · カード",
		"BOND": "絆",
		"BOSS": "ボス",
		"RIVAL": "ライバル",
		"BUILD THE DECK FOR THIS NIGHT": "この夜のデッキを組む",
		"Backend unreachable: ": "サーバーに接続できません：",
		"Bond is the count of nights won against her. Her plates open at 3 and 10 bond; the rung at 30 is a scene still being written. Nothing here unlocks from time.": "絆は、彼女に勝った夜の数。絆3と10で絵が開く。30の段はまだ書いている途中の一場面。時間で開くものはここにはない。",
		"CHARM %d (refills to %d)": "チャーム %d（自然回復は %d まで）",
		"CHARM %d/%d": "チャーム %d/%d",
		"CHIPS · %d TICKETS": "チップ · チケット %d 枚",
		"CHIPS · 1 TICKET": "チップ · チケット 1 枚",
		"CLAIM TODAY'S REWARD": "今日の報酬を受け取る",
		"Cancelled.": "キャンセルしました。",
		"Celeste's cut: she took your costliest card.": "セレストの横やり：いちばん重いカードを持っていかれた。",
		"Claimed.": "受け取りました。",
		"Could not save the deck.": "デッキを保存できませんでした。",
		"DAILY DUEL FREE": "今日の対話は無料",
		"Deck saved": "デッキを保存しました",
		"Delivered.": "お届けしました。",
		"Every %d turns she takes your costliest card.": "%d ターンごとに、手札でいちばん重いカードを彼女が取っていく。",
		"HOLD YOUR TONGUE": "黙る",
		"LAST CALL": "ラストコール",
		"LAST CALL (after the boss)": "ラストコール（ボスのあとで）",
		"NIGHT PASS · CLAIM": "ナイトパス · 受け取る",
		"PLAY AGAIN · 1 CHARM": "もう一度 · チャーム 1",
		"PLAY · 1 CHARM": "はじめる · チャーム 1",
		"Paid in Nutaku gold (100 gold = $1). Everything in the story can be won without it; gold only makes it sooner.": "Nutakuゴールドで支払い（100ゴールド＝1ドル）。物語のすべてはゴールドなしで手に入る。ゴールドは早めるだけ。",
		"Plate not available offline.": "オフラインでは絵を表示できません。",
		"Plate not available.": "絵を表示できません。",
		"Purchase failed.": "購入できませんでした。",
		"RESOLVE": "決意",
		"RESOLVE %d": "決意 %d",
		"RESOLVE %d/%d": "決意 %d/%d",
		"SIT DOWN ACROSS FROM HER": "彼女の向かいに座る",
		"WHO YOU HAVE PERSUADED": "口説き落とした人たち",
		"STANDING ★%d": "格 ★%d",
		"STORE": "ストア",
		"STORY SO FAR": "これまでの話",
		"THE STORY SO FAR": "これまでの話",
		"Say nothing: spend a turn, refill your nerve, draw a fresh hand.": "何も言わない：1ターン使い、度胸を戻し、手札を引き直す。",
		"She has every reason to say no.": "断る理由なら、彼女にはいくらでもある。",
		"She talked straight over it.": "彼女はそのまま話をかぶせてきた。",
		"She talks over your first card.": "最初のカードには、彼女が話をかぶせてくる。",
		"THE NIGHT LEDGER": "夜の台帳",
		"THE NIGHTS": "夜ごとの対話",
		"TONIGHT'S REMATCH · FREE": "今夜の再戦 · 無料",
		"The purchase did not go through; Nutaku has refunded the gold.": "購入は完了しませんでした。ゴールドはNutakuが返金済みです。",
		"The server did not accept this duel: ": "サーバーがこの対話を認めませんでした：",
		"VELL, AFTER TWO": "ヴェル、午前二時過ぎ",
		"Wrong order — she closed the door.": "順番が違う——彼女はドアを閉めた。",
		"You": "あなた",
		"You hold %d cards.": "手札は %d 枚。",
		"at %d bond": "絆 %d で",
		"at %d wins": "%d 勝で",
		"locked": "ロック中",
		"needs bond %d with %s (%d)": "絆 %d が必要（%s、現在 %d）",
		"needs standing ★%d (%d)": "格 ★%d が必要（現在 %d）",
		"still to come": "準備中",
		"tap to close": "タップで閉じる",
		"tier %d": "第 %d 段",
		"tier %d · at %d": "第 %d 段 · %d",
		"◆ CHIPS": "◆ チップ",
		"♥ BOND  (+%d)": "♥ 絆  (+%d)",
		"FOR %s (%s) · SHE HEARS: %s · %d OF YOUR CARDS CAN ACT TONIGHT": "今夜：%s（%s）· 彼女に届くもの：%s · 今夜使えるカードは %d 枚",
		"not tonight": "今夜は使えない",
		"She will not hear this card tonight: it carries none of what she wants.": "今夜このカードは彼女に届かない。彼女が求めるものを何も持っていない。",
		"LEDGER": "台帳",
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
		# --- Nutaku F2P (SUASION: The Night Ledger) ---
		" — tickets are in the store": "——抽卡券在商店里",
		"%d CHIPS": "%d 筹码",
		"%d DUPES — already in your collection": "%d 张重复——你已经有了",
		"1 DUPE — already in your collection": "1 张重复——你已经有了",
		"%d GOLD": "%d 金币",
		"%d TICKETS": "%d 张抽卡券",
		"1 TICKET": "1 张抽卡券",
		"%d TURNS": "%d 回合",
		"(She is still waiting.)": "（她还在等。）",
		"(You say nothing.)": "（你什么也没说。）",
		"+1 in %d:%02d": "%d:%02d 后 +1",
		"1 PULL · %d CHIPS": "单抽 · %d 筹码",
		"1 PULL · 1 TICKET": "单抽 · 1 张抽卡券",
		"10 PULL · %d CHIPS": "十连 · %d 筹码",
		"10 PULL · 10 TICKETS": "十连 · 10 张抽卡券",
		"A card that adds nothing new costs two turns.": "没有新意的牌要花两个回合。",
		"AFTER HOURS · CARDS": "打烊之后 · 卡牌",
		"BOND": "羁绊",
		"BOSS": "首领",
		"RIVAL": "对手",
		"BUILD THE DECK FOR THIS NIGHT": "为这一夜组牌",
		"Backend unreachable: ": "连不上服务器：",
		"Bond is the count of nights won against her. Her plates open at 3 and 10 bond; the rung at 30 is a scene still being written. Nothing here unlocks from time.": "羁绊就是你赢下她的夜数。羁绊 3 和 10 时各解锁一张插图；30 那一级是一场还在写的场景。这里没有任何东西靠时间解锁。",
		"CHARM %d (refills to %d)": "魅力 %d（回复上限 %d）",
		"CHARM %d/%d": "魅力 %d/%d",
		"CHIPS · %d TICKETS": "筹码 · %d 张抽卡券",
		"CHIPS · 1 TICKET": "筹码 · 1 张抽卡券",
		"CLAIM TODAY'S REWARD": "领取今日奖励",
		"Cancelled.": "已取消。",
		"Celeste's cut: she took your costliest card.": "赛莱斯特插话：她拿走了你最贵的那张牌。",
		"Claimed.": "已领取。",
		"Could not save the deck.": "牌组没能保存。",
		"DAILY DUEL FREE": "今日对决免费",
		"Deck saved": "牌组已保存",
		"Delivered.": "已到账。",
		"Every %d turns she takes your costliest card.": "每 %d 回合，她会拿走你手里最贵的牌。",
		"HOLD YOUR TONGUE": "沉默",
		"LAST CALL": "最后一轮",
		"LAST CALL (after the boss)": "最后一轮（击败首领后开放）",
		"NIGHT PASS · CLAIM": "夜间通行证 · 领取",
		"PLAY AGAIN · 1 CHARM": "再来一次 · 1 魅力",
		"PLAY · 1 CHARM": "开始 · 1 魅力",
		"Paid in Nutaku gold (100 gold = $1). Everything in the story can be won without it; gold only makes it sooner.": "用 Nutaku 金币支付（100 金币 = 1 美元）。故事里的一切不花钱也能赢到；金币只是让它来得更快。",
		"Plate not available offline.": "离线时看不到插图。",
		"Plate not available.": "插图暂时无法显示。",
		"Purchase failed.": "购买失败。",
		"RESOLVE": "决心",
		"RESOLVE %d": "决心 %d",
		"RESOLVE %d/%d": "决心 %d/%d",
		"SIT DOWN ACROSS FROM HER": "在她对面坐下",
		"WHO YOU HAVE PERSUADED": "你说服过的人",
		"STANDING ★%d": "声望 ★%d",
		"STORE": "商店",
		"STORY SO FAR": "前情",
		"THE STORY SO FAR": "前情回顾",
		"Say nothing: spend a turn, refill your nerve, draw a fresh hand.": "什么也不说：用掉一个回合，胆识回满，换一手新牌。",
		"She has every reason to say no.": "她有一万个理由拒绝。",
		"She talked straight over it.": "她直接把你的话盖了过去。",
		"She talks over your first card.": "你的第一张牌，她会直接盖过去。",
		"THE NIGHT LEDGER": "夜之账簿",
		"THE NIGHTS": "夜晚",
		"TONIGHT'S REMATCH · FREE": "今晚重赛 · 免费",
		"The purchase did not go through; Nutaku has refunded the gold.": "购买没有完成；Nutaku 已退还金币。",
		"The server did not accept this duel: ": "服务器没有认可这场对决：",
		"VELL, AFTER TWO": "维尔，凌晨两点后",
		"Wrong order — she closed the door.": "顺序错了——她关上了门。",
		"You": "你",
		"You hold %d cards.": "你手里只有 %d 张牌。",
		"at %d bond": "羁绊 %d",
		"at %d wins": "%d 胜时",
		"locked": "未解锁",
		"needs bond %d with %s (%d)": "需要羁绊 %d（与%s，现有 %d）",
		"needs standing ★%d (%d)": "需要声望 ★%d（现有 %d）",
		"still to come": "敬请期待",
		"tap to close": "点按关闭",
		"tier %d": "第 %d 级",
		"tier %d · at %d": "第 %d 级 · %d",
		"◆ CHIPS": "◆ 筹码",
		"♥ BOND  (+%d)": "♥ 羁绊  (+%d)",
		"FOR %s (%s) · SHE HEARS: %s · %d OF YOUR CARDS CAN ACT TONIGHT": "今夜：%s（%s）· 她听得进：%s · 你有 %d 张牌今晚能起作用",
		"not tonight": "今晚用不上",
		"She will not hear this card tonight: it carries none of what she wants.": "今晚她听不进这张牌：它不带她想要的任何东西。",
		"LEDGER": "账簿",
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
		# --- Nutaku F2P (SUASION: The Night Ledger) ---
		" — tickets are in the store": "——抽卡券在商店裡",
		"%d CHIPS": "%d 籌碼",
		"%d DUPES — already in your collection": "%d 張重複——你已經有了",
		"1 DUPE — already in your collection": "1 張重複——你已經有了",
		"%d GOLD": "%d 金幣",
		"%d TICKETS": "%d 張抽卡券",
		"1 TICKET": "1 張抽卡券",
		"%d TURNS": "%d 回合",
		"(She is still waiting.)": "（她還在等。）",
		"(You say nothing.)": "（你什麼也沒說。）",
		"+1 in %d:%02d": "%d:%02d 後 +1",
		"1 PULL · %d CHIPS": "單抽 · %d 籌碼",
		"1 PULL · 1 TICKET": "單抽 · 1 張抽卡券",
		"10 PULL · %d CHIPS": "十連 · %d 籌碼",
		"10 PULL · 10 TICKETS": "十連 · 10 張抽卡券",
		"A card that adds nothing new costs two turns.": "沒有新意的牌要花兩個回合。",
		"AFTER HOURS · CARDS": "打烊之後 · 卡牌",
		"BOND": "羈絆",
		"BOSS": "首領",
		"RIVAL": "對手",
		"BUILD THE DECK FOR THIS NIGHT": "為這一夜組牌",
		"Backend unreachable: ": "連不上伺服器：",
		"Bond is the count of nights won against her. Her plates open at 3 and 10 bond; the rung at 30 is a scene still being written. Nothing here unlocks from time.": "羈絆就是你贏下她的夜數。羈絆 3 和 10 時各解鎖一張插圖；30 那一級是一場還在寫的場景。這裡沒有任何東西靠時間解鎖。",
		"CHARM %d (refills to %d)": "魅力 %d（回覆上限 %d）",
		"CHARM %d/%d": "魅力 %d/%d",
		"CHIPS · %d TICKETS": "籌碼 · %d 張抽卡券",
		"CHIPS · 1 TICKET": "籌碼 · 1 張抽卡券",
		"CLAIM TODAY'S REWARD": "領取今日獎勵",
		"Cancelled.": "已取消。",
		"Celeste's cut: she took your costliest card.": "賽萊斯特插話：她拿走了你最貴的那張牌。",
		"Claimed.": "已領取。",
		"Could not save the deck.": "牌組沒能儲存。",
		"DAILY DUEL FREE": "今日對決免費",
		"Deck saved": "牌組已儲存",
		"Delivered.": "已到賬。",
		"Every %d turns she takes your costliest card.": "每 %d 回合，她會拿走你手裡最貴的牌。",
		"HOLD YOUR TONGUE": "沉默",
		"LAST CALL": "最後一輪",
		"LAST CALL (after the boss)": "最後一輪（擊敗首領後開放）",
		"NIGHT PASS · CLAIM": "夜間通行證 · 領取",
		"PLAY AGAIN · 1 CHARM": "再來一次 · 1 魅力",
		"PLAY · 1 CHARM": "開始 · 1 魅力",
		"Paid in Nutaku gold (100 gold = $1). Everything in the story can be won without it; gold only makes it sooner.": "用 Nutaku 金幣支付（100 金幣 = 1 美元）。故事裡的一切不花錢也能贏到；金幣只是讓它來得更快。",
		"Plate not available offline.": "離線時看不到插圖。",
		"Plate not available.": "插圖暫時無法顯示。",
		"Purchase failed.": "購買失敗。",
		"RESOLVE": "決心",
		"RESOLVE %d": "決心 %d",
		"RESOLVE %d/%d": "決心 %d/%d",
		"SIT DOWN ACROSS FROM HER": "在她對面坐下",
		"WHO YOU HAVE PERSUADED": "你說服過的人",
		"STANDING ★%d": "聲望 ★%d",
		"STORE": "商店",
		"STORY SO FAR": "前情",
		"THE STORY SO FAR": "前情回顧",
		"Say nothing: spend a turn, refill your nerve, draw a fresh hand.": "什麼也不說：用掉一個回合，膽識回滿，換一手新牌。",
		"She has every reason to say no.": "她有一萬個理由拒絕。",
		"She talked straight over it.": "她直接把你的話蓋了過去。",
		"She talks over your first card.": "你的第一張牌，她會直接蓋過去。",
		"THE NIGHT LEDGER": "夜之賬簿",
		"THE NIGHTS": "夜晚",
		"TONIGHT'S REMATCH · FREE": "今晚重賽 · 免費",
		"The purchase did not go through; Nutaku has refunded the gold.": "購買沒有完成；Nutaku 已退還金幣。",
		"The server did not accept this duel: ": "伺服器沒有認可這場對決：",
		"VELL, AFTER TWO": "維爾，凌晨兩點後",
		"Wrong order — she closed the door.": "順序錯了——她關上了門。",
		"You": "你",
		"You hold %d cards.": "你手裡只有 %d 張牌。",
		"at %d bond": "羈絆 %d",
		"at %d wins": "%d 勝時",
		"locked": "未解鎖",
		"needs bond %d with %s (%d)": "需要羈絆 %d（與%s，現有 %d）",
		"needs standing ★%d (%d)": "需要聲望 ★%d（現有 %d）",
		"still to come": "敬請期待",
		"tap to close": "點按關閉",
		"tier %d": "第 %d 級",
		"tier %d · at %d": "第 %d 級 · %d",
		"◆ CHIPS": "◆ 籌碼",
		"♥ BOND  (+%d)": "♥ 羈絆  (+%d)",
		"FOR %s (%s) · SHE HEARS: %s · %d OF YOUR CARDS CAN ACT TONIGHT": "今夜：%s（%s）· 她聽得進：%s · 你有 %d 張牌今晚能起作用",
		"not tonight": "今晚用不上",
		"She will not hear this card tonight: it carries none of what she wants.": "今晚她聽不進這張牌：它不帶她想要的任何東西。",
		"LEDGER": "賬簿",
	},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_code = _restore()
	if FileAccess.file_exists(CAMPAIGN):
		var f := FileAccess.open(CAMPAIGN, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			_campaign = d


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
	if _code == "en" or s == "":
		return s
	var chrome: Dictionary = T.get(_code, {})
	if chrome.has(s):
		return str(chrome[s])
	var camp: Dictionary = _campaign.get(_code, _campaign.get("zh", {}) if _code == "zh-Hant" else {})
	if camp.has(s):
		return str(camp[s])
	# a server line with numbers in it ("too fast (0.4s for 6 plays)"): its template
	var nums := _num.search_all(s)
	if not nums.is_empty():
		var tmpl := _num.sub(s, "%s", true)
		var tr = chrome.get(tmpl, camp.get(tmpl, null))
		if tr != null:
			var args := []
			for m in nums:
				args.append(m.get_string())
			return str(tr) % args
	return s


## Server text (anything the title server sent): the same table. A separate name only so
## the call sites say what they are translating.
func s(text) -> String:
	return t(str(text))


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
