class_name Loc
extends Object

## Single-locale string table. The player picks one language; the UI never
## concatenates English and Chinese onto the same control.

const SETTINGS_PATH := "user://settings.cfg"
const ALLOWED := ["en", "zh"]

static var code: String = ""
static var _hooks: Array[Callable] = []

static func current() -> String:
	if code == "":
		_load()
	return code


static func is_zh() -> bool:
	return current() == "zh"


static func set_code(next: String) -> void:
	if next not in ALLOWED:
		next = "zh"
	if code == next:
		for hook in _hooks:
			if hook.is_valid():
				hook.call()
		return
	code = next
	_save()
	for hook in _hooks:
		if hook.is_valid():
			hook.call()


static func on_change(cb: Callable) -> void:
	_hooks.append(cb)


static func t(key: String, args: Array = []) -> String:
	var table: Dictionary = ZH if is_zh() else EN
	var text := str(table.get(key, EN.get(key, key)))
	if args.is_empty():
		return text
	return text % args


static func _load() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--locale="):
			var forced := arg.trim_prefix("--locale=")
			code = forced if forced in ALLOWED else "zh"
			return
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var saved := str(cfg.get_value("locale", "code", ""))
		if saved in ALLOWED:
			code = saved
			return
	code = "zh"


static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("locale", "code", current())
	cfg.save(SETTINGS_PATH)


const EN := {
	"brand": "MIDNIGHT PAWN & CRYPT",
	"title.name": "Midnight Pawn & Crypt",
	"title.tag": "A complete free run · 15–20 min",
	"title.blurb": "[color=#f1dfb0]Inherit a pawn shop that restocks only at midnight. By day you weigh prices. By night you weigh the cost.[/color]\n\nAppraise cursed curios, read customers, cross four crypt rooms, and decide what no pawnbroker should own.",
	"title.begin": "BEGIN INHERITANCE",
	"title.help": "HOW TO PLAY",
	"title.controls": "Click, tap, or use the keyboard.",
	"help.body": "[color=#e8b84a]SHOP[/color]\nAppraise → set LOW/FAIR/HIGH → display → read each customer → accept or reject.\n\n[color=#e8b84a]CRYPT[/color]\nWASD/arrows, tap a destination, or use the D-pad. Reach the marked encounter. Strike, guard, remember, or use your carried curio.\n\n[color=#e8b84a]LOSS[/color]\nDefeat loses only unbanked loot and marks. Nara recovers and the story continues.",
	"footer.play": "Click or tap the controls.",
	"pause.title": "PAUSED",
	"pause.resume": "RESUME",
	"pause.restart": "RESTART RUN",
	"pause.title_btn": "TITLE",
	"pause.tip": "Pause",
	"open.phase": "23:41 · INHERITANCE",
	"open.header": "18G  ♥12  ◆5",
	"open.title": "The Last Receipt",
	"open.sub": "Opening + tutorial transaction",
	"open.body": "[color=#f1dfb0]AUNT ELSA'S WILL:[/color]\n“Every object has two prices: what the living offer, and what the dead return for.”\n\nThe Bell Child waits at the counter with a rusted bell. Appraise the maker's mark, choose a fair 10G price, then complete your first sale.",
	"open.item": "Rusted Bell\n? → 10G",
	"open.appraise": "APPRAISE",
	"open.footer": "Tutorial: every transaction shows value, demand, and consequence.",
	"open.log": "The shop bell rings once, although the door never opened.",
	"open.identified": "[color=#e8b84a]IDENTIFIED[/color] · Rusted Bell\nValue 10G · Demand: MEMORY · Curse: none\nClue: Its last ring calls a child, not a ghost.\n\nThe Bell Child offers exactly 10G. This fair sale funds the lamps without exploiting a memory.",
	"open.fair": "PRICE: FAIR 10G",
	"open.sale": "SALE +10G · Bell Child: “Now it knows where home is.”",
	"shop.day1": "DAY 1 · 10:12",
	"shop.day2": "DAY 2 · 09:47",
	"shop.header": "%dG  HP%d  RES%d  CURSE%d  BANK%d",
	"shop.title": "Shop Floor",
	"shop.done": "Customers served. Choose what crosses midnight with you.",
	"shop.next": "NEXT: %s",
	"shop.footer": "Shelf %d/3 · Transactions %d/5 · Select a curio card",
	"shop.empty": "Select a curio. A run cannot softlock: unsold stock can always be carried.",
	"shop.mode.low": "LOW −20%",
	"shop.mode.fair": "FAIR",
	"shop.mode.high": "HIGH +25%",
	"shop.item.known": "Value %dG · Price %s · Curse %d · Demand %s\n%s\n",
	"shop.item.unknown": "Value ? · Curse ? · Demand ?\nAppraise to reveal exact identity and tradeoffs.\n",
	"shop.wants": "\n[color=#52b4a6]%s[/color] wants %s.\n%s",
	"btn.appraise": "APPRAISE",
	"btn.price": "PRICE: %s",
	"btn.remove": "REMOVE",
	"btn.display": "DISPLAY",
	"btn.call": "CALL CUSTOMER",
	"btn.descend": "CARRY & DESCEND",
	"log.identified": "IDENTIFIED · %s — %s",
	"log.shelf_full": "Shelf full: remove one of the three displayed curios.",
	"log.orin_refuse": "This customer refuses an unidentified cursed object.",
	"offer.refuse": "REFUSES: identity evidence is incomplete.",
	"offer.pays": "OFFERS %dG for %s.",
	"offer.body": "[color=#52b4a6]%s[/color]\n\nValue %dG · Listed posture %s · Demand match: %s\nCurse %d: revealing it earns trust; concealing it adds debt to the ending.",
	"yes": "YES",
	"no": "NO",
	"btn.negotiate": "NEGOTIATE −1 RES",
	"btn.accept_warn": "ACCEPT + WARN",
	"btn.accept_hide": "ACCEPT + HIDE",
	"btn.reject": "REJECT",
	"log.negotiated": "NEGOTIATED · Tamsin adds 5G after a direct warning.",
	"log.negotiate_fail": "Negotiation needs 1 Resolve and can only be attempted once.",
	"log.sale_warn": "SALE +%dG · %s buys %s with a truthful warning.",
	"log.sale_hide": "SALE +%dG · %s buys %s — curse concealed.",
	"log.reject": "%s leaves; %s remains in inventory.",
	"log.need_carry": "Serve two customers this day and select a carried curio.",
	"night.phase": "NIGHT %d · ROOM %d/4",
	"night.header": "%dG  HP%d  RES%d  CURSE%d  UNBANKED%d",
	"night.body": "Move Nara across the room to the pulsing encounter mark.\n\n[color=#d45b68]RISK:[/color] %s\n[color=#52b4a6]CARRIED:[/color] %s\n\nTap the floor, use WASD/arrows, or press the on-screen direction controls.",
	"night.none": "none",
	"btn.approach": "APPROACH",
	"night.footer": "Movement is required in normal play; APPROACH is an accessibility shortcut.",
	"log.floor": "FLOOR RISK triggered · Health %d · Resolve %d · Curse %d",
	"log.recover_day": "RECOVERY: unbanked loot lost; Nara returns with 3 health and emergency 5G.",
	"fight.title": "%s · HP %d/%d",
	"fight.sub": "Deterministic pattern: attacks for %d; guard reduces the next hit.",
	"fight.body": "[color=#d45b68]%s blocks extraction.[/color]\n\nSTRIKE deals 2. GUARD reduces damage and restores Resolve. REMEMBER costs 2 Resolve and reveals identity. CARRIED ITEM uses its room synergy or heals 2.",
	"btn.strike": "STRIKE",
	"btn.guard": "GUARD",
	"btn.remember": "REMEMBER −2◆",
	"btn.item": "USE CARRIED",
	"btn.ring": "RETURN RING",
	"log.mercy": "MERCY +3 · Widow Voss remembers the missing song. No combat.",
	"log.no_res": "Not enough Resolve for that action.",
	"log.defeat_day": "DEFEAT & RECOVERY · unbanked loot and marks lost; banked goods persist.",
	"log.defeat_final": "DEFEAT & RECOVERY · the cracked Heart still demands a decision.",
	"log.combat": "%s: dealt %d · received %d · enemy HP %d · Nara ♥%d",
	"clear.title": "ROOM CLEARED",
	"clear.sub": "%s cannot follow you.",
	"clear.loot0": "\nLoot: Moon Coin (unbanked).",
	"clear.loot2": "\nOPTIONAL CACHE: Saint's Tooth recovered.",
	"clear.loot3": "\nCORE CURIO: Heart of the Crypt recovered.",
	"clear.body": "Marks +%d%s\n\nUnbanked rewards are lost on defeat. Extraction after the second room banks everything.",
	"btn.continue": "CONTINUE",
	"log.extract": "EXTRACTED · Loot and %d marks banked. New identities surface at dawn.",
	"final.phase": "00:17 · FINAL APPRAISAL",
	"final.header": "%dG  HP%d  CURSE%d  MERCY%d",
	"final.title": "Heart of the Crypt",
	"final.sub": "Value 40G · Curse 4 · Demand: your own",
	"final.body": "[color=#f1dfb0]“The shop is its coffin. Your name is its key.”[/color]\n\n[color=#e8b84a]SELL[/color] gains its appraised value; gold and concealed debt shape the business.\n[color=#52b4a6]SEAL[/color] costs 12G; mercy, clues, and low curse strengthen the ward.\n[color=#d45b68]KEEP[/color] preserves power; survival, health, optional relic, and curse decide who owns whom.",
	"btn.sell": "SELL +%dG",
	"btn.seal": "SEAL −12G",
	"btn.keep": "KEEP",
	"final.footer": "Final decision node · economy + choices + survival determine the result.",
	"result.phase": "RUN COMPLETE",
	"result.header": "SCORE %d · RANK %s",
	"result.sell_clean": "The lamps stay lit. No hidden debt follows the buyer.",
	"result.sell_debt": "The lamps stay lit. Red ink appears beneath tomorrow's profits.",
	"result.seal_mercy": "The crypt falls quiet. Claimants find their names at dawn.",
	"result.seal_hold": "The crypt falls quiet. The seal holds, but nobody remembers why.",
	"result.keep_own": "Nara keeps the Heart. It beats when she commands.",
	"result.keep_owned": "Nara keeps the Heart. Some nights, it appraises her.",
	"result.body": "[color=#e8b84a]ECONOMY[/color] %dG · Banked marks %d\n[color=#52b4a6]CHOICES[/color] Mercy %d · Trust %d · Clues %d\n[color=#d45b68]SURVIVAL[/color] Health %d · Curse %d · Recoveries %d\nRooms %d/4 · Customers %d · Optional relic %s\n\nSCORE %d · RANK %s\nMeasured session %.1f min · Normal reading route %.1f min",
	"btn.replay": "REPLAY",
	"btn.title": "TITLE",
	"result.footer": "Replay with different pricing, truth, carried curio, relic route, and core choice.",
	"log.title": "[color=#9f94ac]LEDGER LOG[/color]\n",
	"demand.memory": "MEMORY",
	"demand.bone": "BONE",
	"demand.weapon": "WEAPON",
	"demand.occult": "OCCULT",
	"item.rusted_bell": "Rusted Bell",
	"item.wedding_ring": "Brass Wedding Ring",
	"item.bone_key": "Bone-handled Key",
	"item.music_box": "Child's Music Box",
	"item.dueling_pistol": "Cracked Dueling Pistol",
	"item.black_ledger": "Black Ledger",
	"item.moon_coin": "Moon Coin",
	"item.saints_tooth": "Saint's Tooth",
	"item.crypt_heart": "Heart of the Crypt",
	"item.crypt_heart_cracked": "Cracked Crypt Heart",
	"clue.rusted_bell": "Its last ring calls a child, not a ghost.",
	"clue.wedding_ring": "E. Voss — hold until he remembers the song.",
	"clue.bone_key": "The teeth marks do not belong to a human jaw.",
	"clue.music_box": "Six notes. The final note is trapped below.",
	"clue.dueling_pistol": "Unloaded when pawned. Two chambers are occupied now.",
	"clue.black_ledger": "Owner: Nara Quill. Due date: tomorrow.",
	"clue.moon_coin": "A ward is stamped beneath the tarnish.",
	"clue.saints_tooth": "It bites armored things before it bites you.",
	"clue.crypt_heart": "The shop is its coffin. Your name is its key.",
	"cust.mara": "Mara Voss",
	"cust.orin": "Orin Pike",
	"cust.tamsin": "Tamsin Reed",
	"cust.ivo": "Ivo Glass",
	"cust.bell": "Bell Child",
	"beh.mara": "Rewards memories and compassionate prices.",
	"beh.orin": "Rejects unidentified cursed stock.",
	"beh.tamsin": "Negotiates hard but rewards honest warnings.",
	"beh.ivo": "Pays for danger and exploits timid prices.",
	"room.0": "Receipt Stair",
	"room.1": "Widow's Niche",
	"room.2": "Ossuary Market",
	"room.3": "Foreclosure Chapel",
	"enemy.0": "Receipt Moth",
	"enemy.1": "Widow Voss",
	"enemy.2": "Debt Hand · ELITE",
	"enemy.3": "Bell Warden",
	"risk.0": "Loose Curse — crossing violet ink costs 1 Resolve.",
	"risk.1": "Claimant — return the ring or fight a memory.",
	"risk.2": "Bone Spikes — crossing red tiles costs 2 Health.",
	"risk.3": "Bell Curse — every third enemy turn drains 1 Resolve.",
	"ending.dawn_broker": "Dawn Broker",
	"ending.quiet_seal": "Quiet Seal",
	"ending.midnight_keeper": "Midnight Keeper",
}

const ZH := {
	"brand": "午夜典当行",
	"title.name": "午夜典当行与地下密室",
	"title.tag": "完整免费一局 · 15–20 分钟",
	"title.blurb": "[color=#f1dfb0]继承一间只在午夜进货的典当行。白天衡量价格，夜里衡量代价。[/color]\n\n鉴定受咒古物，读懂顾客，穿过四间地窖，并决定典当商不该拥有的东西。",
	"title.begin": "开始继承",
	"title.help": "玩法说明",
	"title.controls": "点击或触控即可游玩。",
	"help.body": "[color=#e8b84a]典当行[/color]\n鉴定 → 设低价/公道/高价 → 上架 → 接待顾客 → 成交或拒绝。\n\n[color=#e8b84a]地窖[/color]\n用方向键、点地，或屏幕方向键移动。抵达标记遭遇点。攻击、格挡、追忆，或使用携带的古物。\n\n[color=#e8b84a]失败[/color]\n战败只失去未入库的战利品与印记。娜拉会恢复，故事继续。",
	"footer.play": "点击即可游玩",
	"pause.title": "暂停",
	"pause.resume": "继续",
	"pause.restart": "重开本局",
	"pause.title_btn": "返回标题",
	"pause.tip": "暂停",
	"open.phase": "23:41 · 继承",
	"open.header": "18金  ♥12  ◆5",
	"open.title": "最后一张当票",
	"open.sub": "开场与教程交易",
	"open.body": "[color=#f1dfb0]艾尔莎姑妈的遗嘱：[/color]\n“每件东西都有两个价钱：活人肯出的，和死人要回来的。”\n\n铃铛孩站在柜台前，手里是一只锈蚀的招魂铃。鉴定匠记，选公道的10金，完成第一笔成交。",
	"open.item": "锈蚀招魂铃\n? → 10金",
	"open.appraise": "鉴定",
	"open.footer": "教程：每笔交易都会显示价值、需求与后果。",
	"open.log": "店铃响了一声，门却从未打开。",
	"open.identified": "[color=#e8b84a]已鉴定[/color] · 锈蚀招魂铃\n价值 10金 · 需求：记忆 · 诅咒：无\n线索：最后一声铃响呼唤的是孩子，不是鬼魂。\n\n铃铛孩正好出10金。这桩公道买卖点亮油灯，却不剥削一段记忆。",
	"open.fair": "定价：公道 10金",
	"open.sale": "成交 +10金 · 铃铛孩：「现在它知道家在哪儿了。」",
	"shop.day1": "第一日 · 10:12",
	"shop.day2": "第二日 · 09:47",
	"shop.header": "%d金  生命%d  意志%d  诅咒%d  已存%d",
	"shop.title": "典当营业",
	"shop.done": "顾客已接待完毕。选择午夜要带下去的东西。",
	"shop.next": "下一位：%s",
	"shop.footer": "货架 %d/3 · 交易 %d/5 · 选择一张古物卡",
	"shop.empty": "选择一件古物。流程不会卡死：未售出的存货随时可以带走。",
	"shop.mode.low": "低价 −20%",
	"shop.mode.fair": "公道",
	"shop.mode.high": "高价 +25%",
	"shop.item.known": "价值 %d金 · 定价 %s · 诅咒 %d · 需求 %s\n%s\n",
	"shop.item.unknown": "价值 ? · 诅咒 ? · 需求 ?\n先鉴定，才能看清身份与取舍。\n",
	"shop.wants": "\n[color=#52b4a6]%s[/color] 想要 %s。\n%s",
	"btn.appraise": "鉴定",
	"btn.price": "定价：%s",
	"btn.remove": "撤下货架",
	"btn.display": "上架",
	"btn.call": "接待顾客",
	"btn.descend": "携带并下楼",
	"log.identified": "已鉴定 · %s — %s",
	"log.shelf_full": "货架已满：先撤下一件展出的古物。",
	"log.orin_refuse": "这位顾客拒绝未鉴定的受咒之物。",
	"offer.refuse": "拒绝：身份证据不完整。",
	"offer.pays": "出价 %d金 购买 %s。",
	"offer.body": "[color=#52b4a6]%s[/color]\n\n价值 %d金 · 标价姿态 %s · 需求吻合：%s\n诅咒 %d：坦白能换信任；隐瞒会把债记进结局。",
	"yes": "是",
	"no": "否",
	"btn.negotiate": "议价 −1意志",
	"btn.accept_warn": "成交并告知诅咒",
	"btn.accept_hide": "隐瞒后成交",
	"btn.reject": "拒绝",
	"log.negotiated": "议价成功 · 塔姆辛在直接警告后加价5金。",
	"log.negotiate_fail": "议价需要1点意志，且每笔只能试一次。",
	"log.sale_warn": "成交 +%d金 · %s 买下 %s，并听到如实警告。",
	"log.sale_hide": "成交 +%d金 · %s 买下 %s —— 诅咒被隐瞒。",
	"log.reject": "%s 离开了；%s 仍在库存。",
	"log.need_carry": "当天先接待两位顾客，并选择要携带的古物。",
	"night.phase": "第%d夜 · 房间 %d/4",
	"night.header": "%d金  生命%d  意志%d  诅咒%d  未存%d",
	"night.body": "让娜拉穿过房间，抵达脉动的遭遇标记。\n\n[color=#d45b68]风险：[/color] %s\n[color=#52b4a6]携带：[/color] %s\n\n点地、用方向键，或按屏幕方向键。",
	"night.none": "无",
	"btn.approach": "接敌",
	"night.footer": "正常游玩需要移动；接敌是无障碍快捷方式。",
	"log.floor": "地面风险触发 · 生命 %d · 意志 %d · 诅咒 %d",
	"log.recover_day": "恢复：未入库战利品丢失；娜拉带着3点生命与应急5金回来。",
	"fight.title": "%s · 生命 %d/%d",
	"fight.sub": "固定模式：攻击造成 %d；格挡减轻下一次伤害。",
	"fight.body": "[color=#d45b68]%s 挡住了撤离。[/color]\n\n攻击造成2点。格挡减伤并恢复意志。追忆消耗2点意志并揭示身份。携带物使用房间协同，或治疗2点。",
	"btn.strike": "攻击",
	"btn.guard": "格挡",
	"btn.remember": "追忆 −2◆",
	"btn.item": "使用古物",
	"btn.ring": "归还婚戒",
	"log.mercy": "仁慈 +3 · 寡妇沃斯记起了失踪的歌。无需战斗。",
	"log.no_res": "意志不足，无法执行该动作。",
	"log.defeat_day": "战败并恢复 · 未入库战利品与印记丢失；已入库之物保留。",
	"log.defeat_final": "战败并恢复 · 破裂的核心仍要求你做决定。",
	"log.combat": "%s：造成 %d · 承受 %d · 敌人生命 %d · 娜拉 ♥%d",
	"clear.title": "房间已清理",
	"clear.sub": "%s 无法再跟上你。",
	"clear.loot0": "\n战利品：月蚀银币（未入库）。",
	"clear.loot2": "\n可选窖藏：无名圣齿已取回。",
	"clear.loot3": "\n核心古物：地窖之心已取回。",
	"clear.body": "印记 +%d%s\n\n战败会失去未入库奖励。第二间房后撤离会将一切入库。",
	"btn.continue": "继续",
	"log.extract": "撤离 · 战利品与 %d 印记已入库。黎明会浮出新的身份。",
	"final.phase": "00:17 · 最终估价",
	"final.header": "%d金  生命%d  诅咒%d  仁慈%d",
	"final.title": "地窖之心",
	"final.sub": "价值 40金 · 诅咒 4 · 需求：你自己",
	"final.body": "[color=#f1dfb0]“店铺是它的棺。你的名字是它的钥匙。”[/color]\n\n[color=#e8b84a]出售[/color] 获得估价；金币与隐瞒的债会塑造生意。\n[color=#52b4a6]封印[/color] 花费12金；仁慈、线索与低诅咒会加固结界。\n[color=#d45b68]保留[/color] 留下力量；存活、生命、可选圣物与诅咒决定谁属于谁。",
	"btn.sell": "出售 +%d金",
	"btn.seal": "封印 −12金",
	"btn.keep": "保留核心",
	"final.footer": "最终抉择 · 经济、选择与存活决定结果。",
	"result.phase": "本局结束",
	"result.header": "分数 %d · 评级 %s",
	"result.sell_clean": "油灯还亮着。没有暗债跟着买主。",
	"result.sell_debt": "油灯还亮着。明天的利润底下浮出红墨。",
	"result.seal_mercy": "地窖安静下来。索赔者在黎明找回自己的名字。",
	"result.seal_hold": "地窖安静下来。封印还在，却没人记得为什么。",
	"result.keep_own": "娜拉留下了心。它按她的命令跳动。",
	"result.keep_owned": "娜拉留下了心。有些夜里，它反过来鉴定她。",
	"result.body": "[color=#e8b84a]经济[/color] %d金 · 已存印记 %d\n[color=#52b4a6]选择[/color] 仁慈 %d · 信任 %d · 线索 %d\n[color=#d45b68]存活[/color] 生命 %d · 诅咒 %d · 恢复 %d\n房间 %d/4 · 顾客 %d · 可选圣物 %s\n\n分数 %d · 评级 %s\n实测时长 %.1f 分钟 · 正常阅读路线 %.1f 分钟",
	"btn.replay": "再来一局",
	"btn.title": "返回标题",
	"result.footer": "用不同定价、坦白、携带物、圣物路线与核心抉择再玩一局。",
	"log.title": "[color=#9f94ac]账本记录[/color]\n",
	"demand.memory": "记忆",
	"demand.bone": "骸骨",
	"demand.weapon": "兵器",
	"demand.occult": "秘术",
	"item.rusted_bell": "锈蚀招魂铃",
	"item.wedding_ring": "黄铜婚戒",
	"item.bone_key": "骨柄钥匙",
	"item.music_box": "缺音八音盒",
	"item.dueling_pistol": "裂纹决斗手枪",
	"item.black_ledger": "黑账簿",
	"item.moon_coin": "月蚀银币",
	"item.saints_tooth": "无名圣齿",
	"item.crypt_heart": "地窖之心",
	"item.crypt_heart_cracked": "破裂的地窖之心",
	"clue.rusted_bell": "最后一声铃响呼唤的是孩子，不是鬼魂。",
	"clue.wedding_ring": "E. 沃斯 —— 留到他记起那首歌。",
	"clue.bone_key": "齿痕不属于人类的颌。",
	"clue.music_box": "六个音。最后那个音被困在下面。",
	"clue.dueling_pistol": "典当时装着空膛。现在有两发上膛。",
	"clue.black_ledger": "物主：娜拉·奎尔。到期日：明天。",
	"clue.moon_coin": "锈迹下面印着一道结界。",
	"clue.saints_tooth": "它先咬穿甲之物，再咬你。",
	"clue.crypt_heart": "店铺是它的棺。你的名字是它的钥匙。",
	"cust.mara": "寡妇·玛拉",
	"cust.orin": "收藏家·奥林",
	"cust.tamsin": "老兵·塔姆辛",
	"cust.ivo": "秘术师·伊沃",
	"cust.bell": "铃铛孩",
	"beh.mara": "奖赏记忆与慈悲定价。",
	"beh.orin": "拒绝未鉴定的受咒存货。",
	"beh.tamsin": "议价很狠，但奖赏诚实警告。",
	"beh.ivo": "为危险付钱，也剥削胆怯的标价。",
	"room.0": "收据阶梯",
	"room.1": "寡妇壁龛",
	"room.2": "骸骨集市",
	"room.3": "止赎礼拜堂",
	"enemy.0": "收据蛾",
	"enemy.1": "寡妇沃斯",
	"enemy.2": "讨债手 · 精英",
	"enemy.3": "丧钟守卫",
	"risk.0": "散逸诅咒 —— 越过紫墨消耗1点意志。",
	"risk.1": "索赔者 —— 归还婚戒，或与一段记忆战斗。",
	"risk.2": "骨刺 —— 越过红砖消耗2点生命。",
	"risk.3": "丧钟诅咒 —— 敌人每第三个回合抽取1点意志。",
	"ending.dawn_broker": "晨曦掌柜",
	"ending.quiet_seal": "静默封印",
	"ending.midnight_keeper": "午夜守藏人",
}


static func item_name(id: String) -> String:
	if id == "crypt_heart" or id.begins_with("crypt_heart"):
		return t("item." + id) if t("item." + id) != ("item." + id) else t("item.crypt_heart")
	return t("item." + id)


static func customer_name(id: String) -> String:
	return t("cust." + id)


static func demand_name(demand: String) -> String:
	return t("demand." + str(demand))
