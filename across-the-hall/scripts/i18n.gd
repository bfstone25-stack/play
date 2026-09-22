extends Node
## ACROSS THE HALL — en / zh-Hans / ja / zh-Hant.
##
## Autoloaded as "I18n". The shape is play/fold-godot/scripts/i18n.gd's: one table keyed by
## language, `I18n.t(key)` to read it, a `changed` signal so a live screen can repaint. Same
## shape on purpose — a studio with four i18n architectures has none.
##
## WHY THIS FILE EXISTS. The game shipped English only, with every line of its prose written
## as a literal inside game.gd. STANDARD.md item 7: en + zh minimum, ja the priority, since
## 507 of the 581 DLsite works on disk are Japanese and a game without ja is not on that
## shelf at all.
##
## WHAT IS AND IS NOT TRANSLATED. Everything the player reads: the seven notes, the eight
## interaction prompts, every objective line, the chapter cards, the ending, and the title
## screen. All four languages below are actually written out. STANDARD.md item 7 again, and
## the memory `renpy-translation-blind-spots`: Floor 13 shipped ja/ko/es whose story files
## held Chinese prose and someone had to switch them off. Nothing here is a passthrough, a
## machine round-trip or a copy of the English; if a fifth language is added and not
## finished, it does not go in LANGS.
##
## THE PROSE IS THE PRODUCT, so the translations are not literal. This game's English turns
## on one trick — every sentence about the neighbour is also a sentence about the player,
## and the last line collapses the two. A word-for-word Japanese rendering loses it, because
## Japanese can simply drop the subject and the ambiguity stops being a choice the sentence
## made. So the ja lines lean on 自分 / もう半分 ("the other half") where English leans on
## the pronoun, and the zh lines use 那半个自己. Same trick, said the way each language says
## it.
##
## THE WORDMARK STAYS LATIN in all four. ACROSS THE / HALL is the mark on the storefront and
## the itch page; what changes is the line under the rule, which is the title in the
## player's language. That is the pattern in fold-godot (WORDMARK / WORDMARK_SUB) and the
## reason is that a player who found the game as "Across the Hall" has to recognise it.

signal changed(lang: String)

## Four, and no more than four, because these four are finished. Order is the cycle order of
## the title screen's language control.
const LANGS := ["en", "zh", "ja", "zh-Hant"]

## What each language calls itself, for the switch. Never "Chinese"/"Japanese" in English —
## a language picker written in a language you cannot read is useless.
const ENDONYM := {"en": "English", "zh": "简体中文", "ja": "日本語", "zh-Hant": "繁體中文"}

## The line under the rule on the title screen. The mark itself is always ACROSS THE / HALL.
const SUBTITLE := {"en": "", "zh": "对门", "ja": "向かいの部屋", "zh-Hant": "對門"}

var lang := "en"

const T := {
# =========================================================================================
"en": {
	"note1": "Management says 402 vacated three months ago.\nThe vacancy form is signed with my name.\nThe handwriting is steadier than mine is now.",
	"note2": "401's calendar is still on February 17.\nThe clock is frozen at 02:17.\nYou already came home. You just used the other door.",
	"note_tape": "No date. The cassette is still warm.\nThe spine is labeled 401 in your handwriting.",
	"note_key": "A key on a ring with a photo of this hallway.\nThe tag says HOME. The teeth match 401.",
	"note_clock": "The second hand is not stuck.\nIt is waiting for you to catch up.",
	"note_end": "The breathing on the tape matches your chest.\nThere was never anyone across the hall.\nYou only left the half of yourself you would not claim behind an open door.",

	"p_flashlight": "Take flashlight",
	"p_note": "Read vacancy notice",
	"p_tape": "Take cassette",
	"p_key": "Take 401 key",
	"p_calendar": "Read calendar",
	"p_clock": "Check the clock",
	"p_deck402": "Play cassette (402)",
	"p_deck401": "Play cassette (401)",
	"p_interact": "E / click  ",

	"obj_web": "Ch.1 Hall. Click to capture the mouse. Take the flashlight.",
	"obj_desk": "Ch.1 Hall. Take the flashlight. 401 is locked. 402 is open.",
	"obj_continue": "Episode I. Press C to continue at Episode %d, or take the flashlight.",
	"obj_ch1": "Ch.1 Hall. F flashlight. 402 is open. 401 is still locked.",
	"obj_ch2": "Ch.2 Apt 402. Bathroom tap is still running. Find the cassette.",
	"obj_ch3": "Ch.3 Bath. Take the 401 key. The 402 deck is only a copy.",
	"obj_ch4": "Ch.4 Home. Unlock 401 across the hall.",
	"obj_ch4_in": "Ch.4 Apt 401. Read the calendar. The clock is waiting.",
	"obj_ch4_walked": "Ch.4 Apt 401. This is the room you locked from the inside.",
	"obj_ch5": "Ch.5 Overlap. The plates have swapped. Play the tape in 401.",
	"obj_breath": "Ch.5 Overlap. The breathing matches.",
	"obj_done": "Episode I complete. The Fourth Floor stays free.",
	"obj_caught": "You're still on the fourth floor. The door is still open. That half already knows you.",

	"card_ch1": "Chapter 1 — The hall. 02:17, again.",
	"card_ch": "Chapter %d",
	"card_ch5": "Chapter 5 — The plates have swapped",
	"card_end": "Episode I complete\nYou are the door across the hall",

	"say_empty_deck": "The deck is empty. You can still hear a cassette turning.",
	"say_from_401": "The voice on the tape is coming from 401.\nThis deck is a copy. Play it in the room that is yours.",
	"say_wrong_room": "Wrong room. The breathing is louder through the other door.",
	"say_deadbolt": "The deadbolt yields. The air inside already knows your shampoo.",
	"say_caught": "Someone covers your eyes from behind.\nThe shampoo is the bottle you used this morning.\nThe hands are the same temperature.",

	"end_full": "N next floor · R replay Episode I",
	"end_web": "R restart · Follow bfstone25-stack on itch.io · More: /ghost-channel",

	"title_enter": "ENTER THE FOURTH FLOOR",
	"title_keys": "WASD move   ·   mouse look   ·   E interact   ·   F light   ·   Esc release",
	"title_marks": "ALL AGES   ·   blazeCore Play",
},
# =========================================================================================
"zh": {
	"note1": "物业说 402 三个月前就空了。\n空置登记表上签的是我的名字。\n那笔字比我现在写的还稳。",
	"note2": "401 的日历还停在 2 月 17 日。\n钟停在 02:17。\n你早就到家了。只不过走的是另一扇门。",
	"note_tape": "没有日期。磁带还是温的。\n带脊上写着「401」,是你的字。",
	"note_key": "钥匙串上挂着一张这条走廊的照片。\n吊牌上写着「家」。齿形对得上 401。",
	"note_clock": "秒针没有卡住。\n它在等你跟上来。",
	"note_end": "磁带里的呼吸和你胸口的节奏一样。\n对门从来就没有人。\n你只是把自己不肯认领的那半个,留在了一扇开着的门后面。",

	"p_flashlight": "拿起手电",
	"p_note": "读空置通知",
	"p_tape": "拿起磁带",
	"p_key": "拿起 401 的钥匙",
	"p_calendar": "读日历",
	"p_clock": "看钟",
	"p_deck402": "放磁带(402)",
	"p_deck401": "放磁带(401)",
	"p_interact": "E / 点击  ",

	"obj_web": "第一章 走廊。点一下锁定鼠标。拿走手电。",
	"obj_desk": "第一章 走廊。拿走手电。401 锁着,402 开着。",
	"obj_continue": "第一话。按 C 从第 %d 话继续,或者先拿手电。",
	"obj_ch1": "第一章 走廊。F 开手电。402 开着,401 还锁着。",
	"obj_ch2": "第二章 402 室。浴室的水还在流。找到那盘磁带。",
	"obj_ch3": "第三章 浴室。拿走 401 的钥匙。402 这台只是复制品。",
	"obj_ch4": "第四章 回家。打开对门的 401。",
	"obj_ch4_in": "第四章 401 室。读日历。钟一直在等。",
	"obj_ch4_walked": "第四章 401 室。这就是你从里面反锁上的那个房间。",
	"obj_ch5": "第五章 重叠。门牌换过来了。在 401 里放磁带。",
	"obj_breath": "第五章 重叠。呼吸对上了。",
	"obj_done": "第一话完。四楼永远免费。",
	"obj_caught": "你还在四楼。门还开着。那半个你早就认得你了。",

	"card_ch1": "第一章 —— 走廊。又是 02:17。",
	"card_ch": "第 %d 章",
	"card_ch5": "第五章 —— 门牌换过来了",
	"card_end": "第一话完\n对门那扇门,就是你",

	"say_empty_deck": "机子里是空的。可你还是听得见磁带在转。",
	"say_from_401": "磁带里的声音是从 401 传过来的。\n这台只是复制品。回你自己的房间放。",
	"say_wrong_room": "房间不对。那扇门后面的呼吸更响。",
	"say_deadbolt": "插销松开了。里面的空气已经认得你的洗发水味。",
	"say_caught": "有人从背后捂住了你的眼睛。\n那股洗发水味,是你今天早上用的那瓶。\n手的温度也和你一样。",

	"end_full": "N 上一层 · R 重玩第一话",
	"end_web": "R 重来 · 在 itch.io 关注 bfstone25-stack · 更多:/ghost-channel",

	"title_enter": "走进四楼",
	"title_keys": "WASD 移动   ·   鼠标转视角   ·   E 互动   ·   F 手电   ·   Esc 松开鼠标",
	"title_marks": "全年龄   ·   blazeCore Play",
},
# =========================================================================================
"ja": {
	"note1": "管理会社は、402号室は三か月前に空いたと言っている。\n退去届に署名してあるのは、私の名前だ。\n筆跡は、今の私よりも落ち着いている。",
	"note2": "401号室のカレンダーは、二月十七日のまま。\n時計は02:17で止まっている。\nもう帰ってきている。別の扉を使っただけだ。",
	"note_tape": "日付はない。カセットはまだ温かい。\n背に「401」と、自分の字で書いてある。",
	"note_key": "この廊下の写真がついたキーホルダー。\nタグには「家」。歯の形は401号室のものだ。",
	"note_clock": "秒針は止まっていない。\nこちらが追いつくのを待っている。",
	"note_end": "テープの息づかいが、自分の胸と重なる。\n向かいの部屋には、はじめから誰もいなかった。\n認めたくなかったもう半分を、開いた扉の向こうに置いてきただけだ。",

	"p_flashlight": "懐中電灯を取る",
	"p_note": "退去通知を読む",
	"p_tape": "カセットを取る",
	"p_key": "401号室の鍵を取る",
	"p_calendar": "カレンダーを読む",
	"p_clock": "時計を見る",
	"p_deck402": "カセットを再生(402)",
	"p_deck401": "カセットを再生(401)",
	"p_interact": "E / クリック  ",

	"obj_web": "第一章 廊下。クリックしてマウスを固定。懐中電灯を取る。",
	"obj_desk": "第一章 廊下。懐中電灯を取る。401は施錠、402は開いている。",
	"obj_continue": "エピソードI。Cキーで第%d話から再開、または懐中電灯を取る。",
	"obj_ch1": "第一章 廊下。Fで懐中電灯。402は開いている。401はまだ施錠。",
	"obj_ch2": "第二章 402号室。浴室の蛇口はまだ出ている。カセットを探す。",
	"obj_ch3": "第三章 浴室。401号室の鍵を取る。402のデッキは複製にすぎない。",
	"obj_ch4": "第四章 帰宅。向かいの401号室を開ける。",
	"obj_ch4_in": "第四章 401号室。カレンダーを読む。時計が待っている。",
	"obj_ch4_walked": "第四章 401号室。内側から鍵をかけた、あの部屋だ。",
	"obj_ch5": "第五章 重なり。表札が入れ替わった。401でテープを再生する。",
	"obj_breath": "第五章 重なり。息が重なる。",
	"obj_done": "エピソードI 完了。四階はこれからも無料。",
	"obj_caught": "まだ四階にいる。扉はまだ開いている。もう半分は、とうに気づいている。",

	"card_ch1": "第一章 —— 廊下。また02:17。",
	"card_ch": "第%d章",
	"card_ch5": "第五章 —— 表札が入れ替わった",
	"card_end": "エピソードI 完了\n向かいの扉は、あなただ",

	"say_empty_deck": "デッキは空だ。それでもテープの回る音が聞こえる。",
	"say_from_401": "テープの声は401号室から聞こえてくる。\nこのデッキは複製だ。自分の部屋で再生すること。",
	"say_wrong_room": "部屋が違う。息づかいは、もう一方の扉の向こうで大きい。",
	"say_deadbolt": "かんぬきが外れる。中の空気は、もうあなたのシャンプーを知っている。",
	"say_caught": "背後から、誰かが目をふさぐ。\nそのシャンプーは、今朝あなたが使ったものだ。\n手の温度も、同じだ。",

	"end_full": "N 次の階 · R エピソードIをもう一度",
	"end_web": "R 最初から · itch.ioで bfstone25-stack をフォロー · 他の作品:/ghost-channel",

	"title_enter": "四階へ入る",
	"title_keys": "WASD 移動   ·   マウスで視点   ·   E 調べる   ·   F ライト   ·   Esc 解除",
	"title_marks": "全年齢   ·   blazeCore Play",
},
# =========================================================================================
"zh-Hant": {
	"note1": "管理處說 402 三個月前就空了。\n空置登記表上簽的是我的名字。\n那筆字比我現在寫的還穩。",
	"note2": "401 的日曆還停在 2 月 17 日。\n鐘停在 02:17。\n你早就到家了。只不過走的是另一扇門。",
	"note_tape": "沒有日期。卡帶還是溫的。\n帶脊上寫著「401」,是你的字。",
	"note_key": "鑰匙圈上掛著一張這條走廊的照片。\n吊牌上寫著「家」。齒形對得上 401。",
	"note_clock": "秒針沒有卡住。\n它在等你跟上來。",
	"note_end": "卡帶裡的呼吸和你胸口的節奏一樣。\n對門從來就沒有人。\n你只是把自己不肯認領的那半個,留在了一扇開著的門後面。",

	"p_flashlight": "拿起手電筒",
	"p_note": "讀空置通知",
	"p_tape": "拿起卡帶",
	"p_key": "拿起 401 的鑰匙",
	"p_calendar": "讀日曆",
	"p_clock": "看鐘",
	"p_deck402": "播放卡帶(402)",
	"p_deck401": "播放卡帶(401)",
	"p_interact": "E / 點擊  ",

	"obj_web": "第一章 走廊。點一下鎖定滑鼠。拿走手電筒。",
	"obj_desk": "第一章 走廊。拿走手電筒。401 鎖著,402 開著。",
	"obj_continue": "第一話。按 C 從第 %d 話繼續,或者先拿手電筒。",
	"obj_ch1": "第一章 走廊。F 開手電筒。402 開著,401 還鎖著。",
	"obj_ch2": "第二章 402 室。浴室的水還在流。找到那捲卡帶。",
	"obj_ch3": "第三章 浴室。拿走 401 的鑰匙。402 這台只是複製品。",
	"obj_ch4": "第四章 回家。打開對門的 401。",
	"obj_ch4_in": "第四章 401 室。讀日曆。鐘一直在等。",
	"obj_ch4_walked": "第四章 401 室。這就是你從裡面反鎖上的那個房間。",
	"obj_ch5": "第五章 重疊。門牌換過來了。在 401 裡播卡帶。",
	"obj_breath": "第五章 重疊。呼吸對上了。",
	"obj_done": "第一話完。四樓永遠免費。",
	"obj_caught": "你還在四樓。門還開著。那半個你早就認得你了。",

	"card_ch1": "第一章 —— 走廊。又是 02:17。",
	"card_ch": "第 %d 章",
	"card_ch5": "第五章 —— 門牌換過來了",
	"card_end": "第一話完\n對門那扇門,就是你",

	"say_empty_deck": "機器裡是空的。可你還是聽得見卡帶在轉。",
	"say_from_401": "卡帶裡的聲音是從 401 傳過來的。\n這台只是複製品。回你自己的房間播。",
	"say_wrong_room": "房間不對。那扇門後面的呼吸更響。",
	"say_deadbolt": "插銷鬆開了。裡面的空氣已經認得你的洗髮精味。",
	"say_caught": "有人從背後摀住了你的眼睛。\n那股洗髮精味,是你今天早上用的那瓶。\n手的溫度也和你一樣。",

	"end_full": "N 上一層 · R 重玩第一話",
	"end_web": "R 重來 · 在 itch.io 關注 bfstone25-stack · 更多:/ghost-channel",

	"title_enter": "走進四樓",
	"title_keys": "WASD 移動   ·   滑鼠轉視角   ·   E 互動   ·   F 手電筒   ·   Esc 鬆開滑鼠",
	"title_marks": "全年齡   ·   blazeCore Play",
},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	lang = _saved()
	if lang not in LANGS:
		lang = _from_os()


## The OS locale, narrowed to what is actually finished here.
##
## zh-TW / zh-HK / zh-Hant-* must land on zh-Hant and not on zh: serving a Taiwanese player
## simplified characters is the same failure as serving them English, only quieter.
func _from_os() -> String:
	var l := OS.get_locale().to_lower().replace("_", "-")
	if l.begins_with("ja"):
		return "ja"
	if l.begins_with("zh"):
		for mark in ["tw", "hk", "mo", "hant"]:
			if mark in l:
				return "zh-Hant"
		return "zh"
	return "en"


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
