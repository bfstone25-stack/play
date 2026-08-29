class_name Loc
extends Object

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
	"splash.title": "Late Inspection: Flat 404",
	"splash.hint": "Click to enter  ·  WASD  mouse  E interact  Esc",
	"splash.start": "ENTER THE BUILDING",
	"pause.title": "INSPECTION PAUSED\nEsc resumes · Mouse recaptures on return",
	"pause.resume": "RESUME INSPECTION",
	"pause.restart": "RESTART FROM ARRIVAL",
	"doc.continue": "CONTINUE  ›",
	"doc.close": "CLOSE",
	"doc.page": "PAGE %d / %d",
	"btn.continue": "CONTINUE",
	"btn.credits": "CREDITS",
	"btn.restart": "RESTART",
	"ending.thanks": "FLAT 404\n\nThank you for witnessing.\n\nPress R to restart the inspection.",
	"evidence": "EVIDENCE %02d / 23",
	"prompt.prefix": "E / click  ",
	"title.card": "FLAT 404\nA late inspection",
	"ch.0": "CHAPTER I — AFTER HOURS",
	"ch.1": "CHAPTER II — PREMISES SURRENDERED",
	"ch.2": "CHAPTER III — STILL HERE",
	"ch.3": "CHAPTER IV — THE PIPE SPEAKS",
	"ch.4": "CHAPTER V — ONE MINUTE",
	"ch.5": "CHAPTER VI — TEMPORARY CUSTODIAN",
	"ch.6": "CHAPTER VII — THE FINAL KNOCK",
	"obj.0": "Read the after-hours inspection order in the lift lobby.",
	"obj.order": "Find Flat 404. Read the notice taped over its number.",
	"obj.dane": "Read the access notice on Flat 404.",
	"obj.notice": "Enter 404 and inspect the checklist in the living room.",
	"obj.checklist": "Search the living room. Play the answering machine when ready.",
	"obj.answering": "Investigate the kitchen and document the damp wall.",
	"obj.stain": "Follow the wet line into the bathroom. Read the service tag.",
	"obj.service": "The pipe is waiting. Answer it or close the valve.",
	"obj.pipe": "Wet footprints lead to the bedroom. Search before opening the wardrobe.",
	"obj.wardrobe": "Play the cassette hidden inside the wall cavity.",
	"obj.cassette": "Return to the living room. Pell is calling.",
	"obj.followup": "Read the overnight clause on the coffee table.",
	"obj.clause": "Inspect the changed key and look through the peephole.",
	"obj.final": "The final knock is waiting at the front door.",
	"note.stain_keep": "MARA: Evidence first. Pell can explain the impossible part.\nThe letters IRIS VALE remain visible inside the damp.",
	"note.stain_wipe": "MARA: A reflection. Bad compression. Finish the job.\nThe letters smear into a five-fingered handprint.",
	"note.pipe_yes": "MARA knocks three times.\nIRIS, through copper: Bedroom. Behind the coats. Record me.\nDANE: You heard her. Don't let Pell make it maintenance.",
	"note.pipe_no": "The valve resists like a held wrist, then turns.\nPELL: Good. A quiet building is a safe building.",
	"note.clause_yes": "MARA VENN. Temporary. Until morning.\nInk crawls from your signature toward the printed word 'contents.'",
	"note.clause_no": "MARA: No. This inspection is suspended.\nBoth torn halves now read UNIT 404: NOT FOUND.",
	"end.witness": "ENDING — WITNESS",
	"end.complicit": "ENDING — COMPLICIT",
	"end.404": "ERROR 404 — INSPECTOR NOT FOUND",
	"beat.witness.0": "The door opens onto the service cavity. Iris stands behind translucent pipework, one hand against the wall.",
	"beat.witness.1": "MARA: Iris Vale occupied this flat. I heard her. I recorded her. I am not certifying it vacant.\nIRIS: Then look at me.",
	"beat.witness.2": "Door 404 bears IRIS VALE. Dawn reaches the corridor.\nDANE: Did she come out?\nMARA: Her name did.",
	"beat.witness.3": "Vesper Court received seventeen inspection requests that morning.\nFlat 404 was never listed as vacant again.",
	"beat.complicit.0": "You turn off the standing lamp. The knocking stops halfway through a strike.",
	"beat.complicit.1": "Daylight. The flat is immaculate. Family photographs now show you with your face turned away.\nPELL: Inspection accepted. Your renewal begins today.",
	"beat.complicit.2": "OCCUPANT: MARA VENN\nMOVE-OUT INSPECTOR: [awaiting arrival]\nPlease keep the pipe quiet for the next guest.",
	"beat.complicit.3": "A new inspector's key enters from the corridor.\nYou made the building quiet. The building made you easy to replace.",
	"beat.404.0": "Every fourth-floor door now reads 403. Your key passes through the wall where 404 stood.",
	"beat.404.1": "MARA: I was inside. Kitchen, bath, bedroom—\nOPERATOR: Vesper Court has no fourth unit on any floor.",
	"beat.404.2": "Your inventory erases itself: cassette, photograph, clause, then MARA VENN.\nIRIS: A witness who will not choose is only another missing room.",
	"beat.404.3": "The lift opens on a brick wall.\nThe next appointment is at 01:47. Please bring identification.",
	"zone.0": "LIFT LOBBY",
	"zone.1": "FOURTH-FLOOR CORRIDOR",
	"zone.2": "LIVING ROOM",
	"zone.3": "KITCHEN",
	"zone.4": "BATHROOM",
	"zone.5": "BEDROOM",
	"world.tonight": "TONIGHT",
	"world.iris": "IRIS VALE",
}

const ZH := {
	"splash.title": "深夜验房：404室",
	"splash.hint": "点击进入  ·  方向键  鼠标  互动键  暂停键",
	"splash.start": "进入大楼",
	"pause.title": "验房已暂停\n暂停键继续 · 返回时鼠标会重新锁定",
	"pause.resume": "继续验房",
	"pause.restart": "从抵达处重开",
	"doc.continue": "继续  ›",
	"doc.close": "关闭",
	"doc.page": "第 %d / %d 页",
	"btn.continue": "继续",
	"btn.credits": "制作人员",
	"btn.restart": "重开",
	"ending.thanks": "404室\n\n感谢你作见证。\n\n按 R 重新开始这次验房。",
	"evidence": "证据 %02d / 23",
	"prompt.prefix": "互动键 / 点击  ",
	"title.card": "404室\n一次深夜验房",
	"ch.0": "第一章 — 下班之后",
	"ch.1": "第二章 — 房屋已交还",
	"ch.2": "第三章 — 人还在",
	"ch.3": "第四章 — 管道开口",
	"ch.4": "第五章 — 一分钟",
	"ch.5": "第六章 — 临时保管人",
	"ch.6": "第七章 — 最后那一声",
	"obj.0": "在电梯厅阅读下班后的验房指令。",
	"obj.order": "找到404室。阅读贴在门牌上的告示。",
	"obj.dane": "阅读404室的进入告示。",
	"obj.notice": "进入404，检查客厅里的清单。",
	"obj.checklist": "搜查客厅。准备好后播放答录机。",
	"obj.answering": "调查厨房，记录潮湿的墙。",
	"obj.stain": "顺着湿痕进入卫生间。阅读检修牌。",
	"obj.service": "管道在等。回应它，或关上阀门。",
	"obj.pipe": "湿脚印通向卧室。开衣柜前先搜查。",
	"obj.wardrobe": "播放藏在墙腔里的磁带。",
	"obj.cassette": "回到客厅。佩尔在打电话。",
	"obj.followup": "阅读茶几上的通宵条款。",
	"obj.clause": "检查被改过的钥匙，从猫眼向外看。",
	"obj.final": "最后那一声敲击在前门等着。",
	"note.stain_keep": "玛拉：先留证据。不可能的部分让佩尔解释。\n潮湿里，被涂掉的住户名几个字母还在。",
	"note.stain_wipe": "玛拉：反光。压缩坏了。做完这份工。\n字母糊成一只五指掌印。",
	"note.pipe_yes": "玛拉敲三下。\n艾里斯，从铜管里：卧室。大衣后面。录下我。\n戴恩：你听见了。别让佩尔把它写成检修。",
	"note.pipe_no": "阀门像被握住的手腕那样抗拒，然后转动。\n佩尔：很好。安静的楼才是安全的楼。",
	"note.clause_yes": "玛拉·文。临时。到早晨为止。\n墨水从你的签名爬向印刷体的“物品”。",
	"note.clause_no": "玛拉：不。这次验房中止。\n撕开的两半现在都写着：404单元：未找到。",
	"end.witness": "结局 — 证人",
	"end.complicit": "结局 — 共谋",
	"end.404": "错误 404 — 查无验房员",
	"beat.witness.0": "门开向检修腔。艾里斯站在半透明的管线后，一只手按着墙。",
	"beat.witness.1": "玛拉：艾里斯·维尔住在这间房。我听见她。我录下她。我不会证明它空置。\n艾里斯：那就看着我。",
	"beat.witness.2": "404的门牌写着艾里斯·维尔。黎明抵达走廊。\n戴恩：她出来了吗？\n玛拉：她的名字出来了。",
	"beat.witness.3": "那天早晨，晚祷庭收到十七份验房请求。\n404室再也没有被列为空置。",
	"beat.complicit.0": "你关掉落地灯。敲击停在半途。",
	"beat.complicit.1": "日光。公寓一尘不染。家庭照片里，你的脸转向一边。\n佩尔：验房已接受。你的续约从今天开始。",
	"beat.complicit.2": "住户：玛拉·文\n退房验房员：[等待抵达]\n请为下一位客人保持管道安静。",
	"beat.complicit.3": "一把新验房员的钥匙从走廊伸进来。\n你让这栋楼安静。这栋楼让你容易被替换。",
	"beat.404.0": "四层每扇门现在都写着403。你的钥匙穿过404曾经站立的墙。",
	"beat.404.1": "玛拉：我在里面。厨房、卫生间、卧室——\n接线员：晚祷庭任何一层都没有第四个单元。",
	"beat.404.2": "你的证物自行擦除：磁带、照片、条款，然后是玛拉·文。\n艾里斯：不肯选择的证人，只是另一间失踪的房间。",
	"beat.404.3": "电梯开向一堵砖墙。\n下一次预约在01:47。请携带身份证明。",
	"zone.0": "电梯厅",
	"zone.1": "四层走廊",
	"zone.2": "客厅",
	"zone.3": "厨房",
	"zone.4": "卫生间",
	"zone.5": "卧室",
	"world.tonight": "今夜",
	"world.iris": "艾里斯·维尔",
}
