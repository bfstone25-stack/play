extends Node
## THE OTHER SIDE — en / zh / ja / zh-Hant.
##
## Autoloaded as "I18n". The shape is play/across-the-hall/scripts/i18n.gd's, which is
## play/fold-godot/scripts/i18n.gd's: one table keyed by language, `I18n.t(key)` to read
## it, a `changed` signal so a live screen can repaint, the choice saved to user://. Same
## shape on purpose, and specifically NOT a new one — a studio with four i18n
## architectures has none, and ops/subset_cjk.py reads this exact block layout to cut the
## fonts.
##
## WHY. The fork shipped English only, every line of prose a literal inside game.gd.
## STANDARD.md item 7: en + zh minimum, **ja the priority**, because 507 of the 581 DLsite
## works in ops/market/dlsite_data/ are Japanese and this title's whole plan is DLsite and
## Nutaku. A game without ja is not on that shelf at all.
##
## WHAT IS TRANSLATED. Everything the player reads: the fourteen notes, the eight
## interaction prompts, every objective and chapter card, the four-line exchange and its
## two choices, the ending, and the title screen. All four languages are actually written
## out by hand here. Floor 13 shipped ja/ko/es whose story files held Chinese prose and
## someone had to switch them off (memory: renpy-translation-blind-spots); nothing below is
## a passthrough or a copy of the English, and `ops/check_other_side_loc.py` fails the
## build if it becomes one. A fifth language that is not finished does not go in LANGS.
##
## THE PROSE IS THE PRODUCT. She is 33, rested, unhurried, and talking to you through a
## door at 02:17 — so the Japanese is plain and short rather than polite-formal, and the
## Chinese keeps the sentences short for the same reason. The English turns on one image:
## the door you did not open, and the life that has been living behind it. Both CJK columns
## keep that image as an image rather than explaining it.
##
## THE WORDMARK is the one thing that changes: unlike the parent, this title's name is
## short enough to set in every script, and DLsite's own shelf is Japanese-first, so the
## splash sets the name in the player's language and keeps the Latin as the footer mark.

signal changed(lang: String)

## Four, and no more than four, because these four are finished. Order is the cycle order
## of the title screen's language control.
const LANGS := ["en", "zh", "ja", "zh-Hant"]

## What each language calls itself. Never "Chinese"/"Japanese" in English — a language
## picker written in a language you cannot read is useless.
const ENDONYM := {"en": "English", "zh": "简体中文", "ja": "日本語", "zh-Hant": "繁體中文"}

var lang := "en"

const T := {
# =======================================================================================
"en": {
	# ---- the splash ----------------------------------------------------------
	"title": "THE OTHER SIDE",
	"tagline": "Someone else is awake on this floor.",
	"start": "CROSS THE HALL",
	"footer": "02:17   ·   18+   ·   Flat 404",
	"controls": "WASD move    mouse look    E interact    F light    Esc release",
	# ---- chapter cards and objectives ----------------------------------------
	"ch1_card": "I — You wake in 401. 02:17.",
	"ch1_obj": "I  Home. The bathroom light is on. Go and look in the mirror.",
	"ch2_obj": "II  The hall. Open your door. Cross. 402 opens this time.",
	"ch3_obj": "III  402. Your flat, mirrored. Find her.",
	"ch4_kept_obj": "IV  Kept. She stays in the glass. Go home and look.",
	"ch4_refused_obj": "IV  Refused. The glass empties. Go home and look.",
	"chapter_n": "Chapter %d",
	# ---- the notes -----------------------------------------------------------
	"n_wake": "02:17. You are on your own couch in your own coat.\nThe bathroom light is on. You did not leave it on.",
	"n_mirror1": "The glass has stopped showing you.\nThere is a woman standing in your bathroom, and she is not moving.\nShe only moves when you do not.",
	"n_mirror2": "She turned her head toward the door.\nShe is waiting for you to come across the hall.",
	"n_door402": "The door opens this time.\nInside, it smells of a kitchen someone actually cooked in tonight.",
	"n_flat402": "It is your flat, laid out backwards.\nEverything you own is here, and all of it has been used.\nShe is in the bathroom doorway. Walk to her.",
	"n_kept": "You go back to 401. The mirror still shows her.\nShe raises a hand when you do, half a second late.\nThere was never anyone across the hall. And now there is.",
	"n_refused": "You go back to 401. The mirror is glass again.\nIt shows the wall behind you and nothing in front of it.\nThe life you did not claim is across the hall, with the door shut.",
	"n_door401": "Your door. The hall is the colour of a bruise.\n402 is opposite. Knock.",
	"n_own_door": "It's your door. It is already open from this side.",
	"n_not_yet": "You are not going anywhere before you have looked.\nThe bathroom light is on. You did not leave it on.",
	"n_already_open": "It's open. It has been open since you looked.",
	"n_clock": "02:17. The second hand is not stuck.\nIt is waiting for you to catch up.",
	"n_lease": "A lease for 402 in your handwriting, dated six years ago.\nThe signature is steadier than yours is now.",
	"n_caught": "Someone covers your eyes from behind.\nThe hands are smaller than yours, and much warmer.",
	"n_letgo": "She let go. She is waiting where you were going anyway.",
	"n_kept_line": "\"Good.\" She does not touch you. She does not have to.\nThe bathroom light in 401 goes on by itself.",
	"n_refused_line": "\"All right.\" She steps back into the doorway.\nBehind you, across the hall, something in 401 goes quiet.",
	"n_glass_clears": "The glass clears.",
	"n_glass_fogged": "The glass stays fogged. Nothing was shown, so nothing is shown.",
	# ---- the exchange --------------------------------------------------------
	"c_line1": "She does not have your face. She has your hours — the ones you signed away — and she has spent every one of them. She is not wearing your coat.",
	"c_line2": "\"You came across. Six years, and you finally came across.\"",
	"c_line3": "\"I am not a stranger. I am the door you did not open, and I have been living behind it the whole time. Everything you wanted and did not take is in here, and it is warm.\"",
	"c_line4": "\"So. Do you want to stay on this side tonight, or do you want your mirror back?\"",
	"c_choice1": "Stay. Keep her in the mirror.",
	"c_choice2": "Go home. Make the glass empty.",
	# ---- prompts and the HUD -------------------------------------------------
	"p_mirror": "Look in the mirror",
	"p_door": "Open the door",
	"p_401": "Open 401",
	"p_402": "Knock at 402",
	"p_flashlight": "Take flashlight",
	"p_clock": "Check the clock",
	"p_lease": "Read the lease on the table",
	"hint_use": "E / click  ",
	"dlg_more": "click · E · Space  to continue",
	# ---- the ending ----------------------------------------------------------
	"end_kept_card": "She is in the mirror.",
	"end_refused_card": "The mirror is empty.",
	"end_kept_obj": "Episode I-X complete. Two of you live here now.",
	"end_refused_obj": "Episode I-X complete. One of you lives here now.",
	"restart": "R restart",
},
# =======================================================================================
"zh": {
	# ---- the splash ----------------------------------------------------------
	"title": "对门",
	"tagline": "这一层楼，醒着的不只你一个。",
	"start": "走过对面",
	"footer": "02:17   ·   18+   ·   Flat 404",
	"controls": "WASD 移动    鼠标 视角    E 互动    F 手电    Esc 释放指针",
	# ---- chapter cards and objectives ----------------------------------------
	"ch1_card": "I — 你在 401 醒来。02:17。",
	"ch1_obj": "I  家里。浴室的灯亮着。去照照镜子。",
	"ch2_obj": "II  走廊。打开你的门，走过去。这一次 402 是开的。",
	"ch3_obj": "III  402。你的房子，左右颠倒。找到她。",
	"ch4_kept_obj": "IV  留下了。她留在玻璃里。回家去看。",
	"ch4_refused_obj": "IV  拒绝了。玻璃空了。回家去看。",
	"chapter_n": "第 %d 章",
	# ---- the notes -----------------------------------------------------------
	"n_wake": "02:17。你躺在自己家的沙发上，外套还没脱。\n浴室的灯亮着。不是你开的。",
	"n_mirror1": "玻璃已经不再映出你。\n你的浴室里站着一个女人，她一动不动。\n只有你不动的时候，她才会动。",
	"n_mirror2": "她把头转向门口。\n她在等你走过这条走廊。",
	"n_door402": "这一次，门开了。\n里面有股味道——今晚真的有人在这厨房做过饭。",
	"n_flat402": "这是你的房子，左右整个颠倒过来。\n你拥有的东西都在这儿，而且每一样都被用过。\n她站在浴室门口。走过去。",
	"n_kept": "你回到 401。镜子里还是她。\n你抬手，她慢半秒也抬手。\n对门从来没有人。现在有了。",
	"n_refused": "你回到 401。镜子又只是玻璃了。\n它映出你身后的墙，墙前面什么也没有。\n你没有去认领的那种人生，在对门，门关着。",
	"n_door401": "你的门。走廊是淤青的颜色。\n402 就在对面。敲门。",
	"n_own_door": "这是你的门。从这边看，它已经开着了。",
	"n_not_yet": "在你看过之前，你哪儿也去不了。\n浴室的灯亮着。不是你开的。",
	"n_already_open": "开着。从你照镜子那一刻起就开着。",
	"n_clock": "02:17。秒针没有卡住。\n它在等你赶上来。",
	"n_lease": "一份 402 的租约，你的笔迹，日期是六年前。\n那个签名比你现在的手稳。",
	"n_caught": "有人从背后捂住你的眼睛。\n那双手比你的小，而且暖得多。",
	"n_letgo": "她松开了手。她在你本来就要去的地方等着。",
	"n_kept_line": "“很好。”她没有碰你。她不需要碰。\n401 的浴室灯自己亮了。",
	"n_refused_line": "“好吧。”她退回门框里。\n在你身后，走廊对面的 401 里，有什么安静了下来。",
	"n_glass_clears": "玻璃清了。",
	"n_glass_fogged": "玻璃还是雾的。什么都没给你看，所以什么都看不见。",
	# ---- the exchange --------------------------------------------------------
	"c_line1": "她没有你的脸。她有的是你的那些时间——你签字让出去的那些——而且她一小时不剩地花掉了。她身上没有你那件外套。",
	"c_line2": "“你走过来了。六年了，你终于走过来了。”",
	"c_line3": "“我不是陌生人。我就是你没有打开的那扇门，我一直住在它后面。你想要却没去拿的东西都在这里，而且这里是暖的。”",
	"c_line4": "“那么，今晚你是留在这一边，还是要把你的镜子要回去？”",
	"c_choice1": "留下。把她留在镜子里。",
	"c_choice2": "回家。让玻璃空掉。",
	# ---- prompts and the HUD -------------------------------------------------
	"p_mirror": "照镜子",
	"p_door": "开门",
	"p_401": "打开 401",
	"p_402": "敲 402 的门",
	"p_flashlight": "拿手电筒",
	"p_clock": "看钟",
	"p_lease": "读桌上的租约",
	"hint_use": "E / 点击  ",
	"dlg_more": "点击 · E · 空格　继续",
	# ---- the ending ----------------------------------------------------------
	"end_kept_card": "她在镜子里。",
	"end_refused_card": "镜子是空的。",
	"end_kept_obj": "第一章 完。现在这里住着两个你。",
	"end_refused_obj": "第一章 完。现在这里只住着一个你。",
	"restart": "R 重新开始",
},
# =======================================================================================
"ja": {
	# ---- the splash ----------------------------------------------------------
	"title": "向こう側",
	"tagline": "この階で、起きているのはあなただけではない。",
	"start": "廊下を渡る",
	"footer": "02:17   ·   18歳以上   ·   Flat 404",
	"controls": "WASD 移動    マウス 視点    E 調べる    F ライト    Esc 解除",
	# ---- chapter cards and objectives ----------------------------------------
	"ch1_card": "I — 401号室で目を覚ます。02:17。",
	"ch1_obj": "I  自宅。浴室の灯りがついている。鏡を見にいく。",
	"ch2_obj": "II  廊下。自分の扉を開けて渡る。今夜は402が開く。",
	"ch3_obj": "III  402号室。左右が逆のあなたの部屋。彼女を探す。",
	"ch4_kept_obj": "IV  留めた。彼女は鏡に残る。部屋に戻って見る。",
	"ch4_refused_obj": "IV  断った。鏡は空になる。部屋に戻って見る。",
	"chapter_n": "第%d章",
	# ---- the notes -----------------------------------------------------------
	"n_wake": "02:17。自分の部屋のソファで、コートも脱がずに。\n浴室の灯りがついている。つけた覚えはない。",
	"n_mirror1": "鏡はもうあなたを映していない。\n浴室に女が立っていて、動かない。\nあなたが動かないときだけ、彼女は動く。",
	"n_mirror2": "彼女は扉のほうへ顔を向けた。\nあなたが廊下を渡ってくるのを待っている。",
	"n_door402": "今夜は扉が開く。\n中からは、今晩ちゃんと使われた台所の匂いがする。",
	"n_flat402": "あなたの部屋だ。左右がそっくり逆になっている。\n持ち物は全部ここにあって、そのどれもが使い込まれている。\n彼女は浴室の戸口にいる。歩いていく。",
	"n_kept": "401号室に戻る。鏡にはまだ彼女がいる。\nあなたが手を上げると、半秒遅れて彼女も上げる。\n向かいには誰もいなかった。もう、いる。",
	"n_refused": "401号室に戻る。鏡はただの鏡に戻っている。\n背後の壁は映るが、その手前には何もない。\n受け取らなかった人生は、廊下の向こうで扉を閉めている。",
	"n_door401": "自分の扉。廊下は痣のような色をしている。\n402は向かい。ノックする。",
	"n_own_door": "自分の扉だ。こちら側からはもう開いている。",
	"n_not_yet": "見てからでなければ、どこにも行けない。\n浴室の灯りがついている。つけた覚えはない。",
	"n_already_open": "開いている。あなたが見たときから、ずっと。",
	"n_clock": "02:17。秒針は止まっていない。\nあなたが追いつくのを待っている。",
	"n_lease": "402号室の賃貸契約書。あなたの字で、六年前の日付。\n署名の手は、今のあなたより落ち着いている。",
	"n_caught": "背後から誰かが目をふさぐ。\nあなたより小さくて、ずっと温かい手だ。",
	"n_letgo": "手が離れた。彼女は、あなたが向かっていた場所で待っている。",
	"n_kept_line": "「よかった」。彼女は触れない。触れる必要がない。\n401号室の浴室の灯りが、ひとりでにつく。",
	"n_refused_line": "「わかった」。彼女は戸口の奥へ下がる。\n背後、廊下の向こうの401号室で、何かが静かになる。",
	"n_glass_clears": "曇りが晴れる。",
	"n_glass_fogged": "鏡は曇ったまま。何も見せられなかったのだから、何も見えない。",
	# ---- the exchange --------------------------------------------------------
	"c_line1": "彼女はあなたの顔をしていない。持っているのはあなたの時間だ——署名して手放したあの時間を、彼女は一つ残らず使ってきた。あなたのコートは着ていない。",
	"c_line2": "「渡ってきたのね。六年かかって、やっと渡ってきた」",
	"c_line3": "「私は他人じゃない。あなたが開けなかった扉そのもので、ずっとその裏で暮らしてきた。あなたが欲しくて手に取らなかったものは全部ここにあって、ここは温かい」",
	"c_line4": "「それで。今夜はこちら側にいる？　それとも、鏡を返してほしい？」",
	"c_choice1": "留まる。彼女を鏡に残す。",
	"c_choice2": "帰る。鏡を空にする。",
	# ---- prompts and the HUD -------------------------------------------------
	"p_mirror": "鏡を見る",
	"p_door": "扉を開ける",
	"p_401": "401を開ける",
	"p_402": "402をノックする",
	"p_flashlight": "懐中電灯を取る",
	"p_clock": "時計を見る",
	"p_lease": "テーブルの契約書を読む",
	"hint_use": "E / クリック  ",
	"dlg_more": "クリック・E・スペースで次へ",
	# ---- the ending ----------------------------------------------------------
	"end_kept_card": "彼女は鏡の中にいる。",
	"end_refused_card": "鏡は空っぽだ。",
	"end_kept_obj": "第一話 完。ここには今、二人が住んでいる。",
	"end_refused_obj": "第一話 完。ここには今、一人だけが住んでいる。",
	"restart": "R で最初から",
},
# =======================================================================================
"zh-Hant": {
	# ---- the splash ----------------------------------------------------------
	"title": "對門",
	"tagline": "這一層樓，醒著的不只你一個。",
	"start": "走過對面",
	"footer": "02:17   ·   18+   ·   Flat 404",
	"controls": "WASD 移動    滑鼠 視角    E 互動    F 手電    Esc 釋放指標",
	# ---- chapter cards and objectives ----------------------------------------
	"ch1_card": "I — 你在 401 醒來。02:17。",
	"ch1_obj": "I  家裡。浴室的燈亮著。去照照鏡子。",
	"ch2_obj": "II  走廊。打開你的門，走過去。這一次 402 是開的。",
	"ch3_obj": "III  402。你的房子，左右顛倒。找到她。",
	"ch4_kept_obj": "IV  留下了。她留在玻璃裡。回家去看。",
	"ch4_refused_obj": "IV  拒絕了。玻璃空了。回家去看。",
	"chapter_n": "第 %d 章",
	# ---- the notes -----------------------------------------------------------
	"n_wake": "02:17。你躺在自己家的沙發上，外套還沒脫。\n浴室的燈亮著。不是你開的。",
	"n_mirror1": "玻璃已經不再映出你。\n你的浴室裡站著一個女人，她一動不動。\n只有你不動的時候，她才會動。",
	"n_mirror2": "她把頭轉向門口。\n她在等你走過這條走廊。",
	"n_door402": "這一次，門開了。\n裡面有股味道——今晚真的有人在這廚房做過飯。",
	"n_flat402": "這是你的房子，左右整個顛倒過來。\n你擁有的東西都在這兒，而且每一樣都被用過。\n她站在浴室門口。走過去。",
	"n_kept": "你回到 401。鏡子裡還是她。\n你抬手，她慢半秒也抬手。\n對門從來沒有人。現在有了。",
	"n_refused": "你回到 401。鏡子又只是玻璃了。\n它映出你身後的牆，牆前面什麼也沒有。\n你沒有去認領的那種人生，在對門，門關著。",
	"n_door401": "你的門。走廊是瘀青的顏色。\n402 就在對面。敲門。",
	"n_own_door": "這是你的門。從這邊看，它已經開著了。",
	"n_not_yet": "在你看過之前，你哪兒也去不了。\n浴室的燈亮著。不是你開的。",
	"n_already_open": "開著。從你照鏡子那一刻起就開著。",
	"n_clock": "02:17。秒針沒有卡住。\n它在等你趕上來。",
	"n_lease": "一份 402 的租約，你的筆跡，日期是六年前。\n那個簽名比你現在的手穩。",
	"n_caught": "有人從背後摀住你的眼睛。\n那雙手比你的小，而且暖得多。",
	"n_letgo": "她鬆開了手。她在你本來就要去的地方等著。",
	"n_kept_line": "「很好。」她沒有碰你。她不需要碰。\n401 的浴室燈自己亮了。",
	"n_refused_line": "「好吧。」她退回門框裡。\n在你身後，走廊對面的 401 裡，有什麼安靜了下來。",
	"n_glass_clears": "玻璃清了。",
	"n_glass_fogged": "玻璃還是霧的。什麼都沒給你看，所以什麼都看不見。",
	# ---- the exchange --------------------------------------------------------
	"c_line1": "她沒有你的臉。她有的是你的那些時間——你簽字讓出去的那些——而且她一小時不剩地花掉了。她身上沒有你那件外套。",
	"c_line2": "「你走過來了。六年了，你終於走過來了。」",
	"c_line3": "「我不是陌生人。我就是你沒有打開的那扇門，我一直住在它後面。你想要卻沒去拿的東西都在這裡，而且這裡是暖的。」",
	"c_line4": "「那麼，今晚你是留在這一邊，還是要把你的鏡子要回去？」",
	"c_choice1": "留下。把她留在鏡子裡。",
	"c_choice2": "回家。讓玻璃空掉。",
	# ---- prompts and the HUD -------------------------------------------------
	"p_mirror": "照鏡子",
	"p_door": "開門",
	"p_401": "打開 401",
	"p_402": "敲 402 的門",
	"p_flashlight": "拿手電筒",
	"p_clock": "看鐘",
	"p_lease": "讀桌上的租約",
	"hint_use": "E / 點擊  ",
	"dlg_more": "點擊 · E · 空白鍵　繼續",
	# ---- the ending ----------------------------------------------------------
	"end_kept_card": "她在鏡子裡。",
	"end_refused_card": "鏡子是空的。",
	"end_kept_obj": "第一章 完。現在這裡住著兩個你。",
	"end_refused_obj": "第一章 完。現在這裡只住著一個你。",
	"restart": "R 重新開始",
},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	lang = _saved()
	if lang not in LANGS:
		lang = _from_url()
	if lang not in LANGS:
		lang = _from_os()


## An explicit ?lang= wins on the web: that is how a Japanese storefront link lands on a
## Japanese page without the player having to find the control first.
func _from_url() -> String:
	if not OS.has_feature("web"):
		return ""
	var q = JavaScriptBridge.eval(
		"(new URLSearchParams(location.search).get('lang')||'')", true)
	var want := str(q) if q != null else ""
	return _narrow(want)


## The OS / browser locale, narrowed to what is actually finished here.
##
## zh-TW / zh-HK / zh-Hant-* must land on zh-Hant and not on zh: serving a Taiwanese player
## simplified characters is the same failure as serving them English, only quieter.
func _from_os() -> String:
	return _narrow(OS.get_locale())


func _narrow(tag: String) -> String:
	var l := tag.to_lower().replace("_", "-")
	if l.begins_with("ja"):
		return "ja"
	if l.begins_with("zh"):
		for mark in ["tw", "hk", "mo", "hant"]:
			if mark in l:
				return "zh-Hant"
		return "zh"
	if l.begins_with("en"):
		return "en"
	return ""


const CFG := "user://lang.cfg"


func _saved() -> String:
	var c := ConfigFile.new()
	if c.load(CFG) != OK:
		return ""
	return str(c.get_value("i18n", "lang", ""))


func set_lang(next: String) -> void:
	if next not in LANGS or next == lang:
		return
	lang = next
	var c := ConfigFile.new()
	c.load(CFG)
	c.set_value("i18n", "lang", lang)
	c.save(CFG)
	changed.emit(lang)


func cycle() -> void:
	set_lang(LANGS[(LANGS.find(lang) + 1) % LANGS.size()])


## One string. Falls back to English, then to the key itself — a missing key shows up as a
## visible key on screen rather than as an empty label nobody notices.
func t(key: String) -> String:
	var table: Dictionary = T[lang]
	if table.has(key):
		return str(table[key])
	return str(T["en"].get(key, key))


func f(key: String, value: Variant) -> String:
	return t(key) % value


## True when the current language needs the CJK face. The Latin face has no CJK glyphs and
## Godot draws a missing glyph as a blank box, not as an error.
func needs_cjk() -> bool:
	return lang != "en"
