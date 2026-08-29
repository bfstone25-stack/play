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
	"title.eyebrow": "A MERIDIAN LEDGER NIGHT OPERATIONS FILE",
	"title.name": "FLOOR 13\nNIGHT SHIFT",
	"title.info": "A 25–35 MINUTE POINT-CLICK HORROR NARRATIVE\nHeadphones recommended · choices persist",
	"title.start": "BEGIN NIGHT SHIFT",
	"btn.continue": "CONTINUE  ▸",
	"vn.advance": "click",
	"vn.pressure": "PRESSURE",
	"btn.continue_n": "CONTINUE  ▸  %d",
	"btn.case_log": "CASE LOG",
	"btn.pause": "PAUSE",
	"btn.proceed": "PROCEED  ▸",
	"btn.return": "RETURN",
	"btn.restart": "RESTART FROM TITLE",
	"btn.restart_shift": "RESTART NIGHT SHIFT",
	"choice.banner": "DECISION RECORDED PERMANENTLY",
	"log.title": "CASE LOG // PERSISTENT RECORD",
	"log.empty": "No record.",
	"pause.title": "NIGHT SHIFT PAUSED",
	"pause.body": "The clock has stopped for you. The record has not.\n\nAll progress is held in this session. Resume to continue, or restart from the title using the button below.",
	"idle.chapter": "FILE 13",
	"idle.place": "NIGHT OPERATIONS",
	"idle.clock": "SUNDAY",
	"idle.objective": "Begin when ready. Choices persist until restart.",
	"route.next": "CONTINUE TO NEXT AREA  ▸",
	"route.decision": "CONTINUE WITH THIS DECISION  ▸",
	"log.objective": "OBJECTIVE\n%s\n",
	"log.decisions": "DECISIONS",
	"log.eli": "Eli: %s",
	"log.compliance": "Compliance: %s",
	"log.route": "Route: %s",
	"log.contract": "Contract: %s\n",
	"log.pending": "pending",
	"log.evidence": "EVIDENCE // %d OF 28",
	"log.decision": "DECISION — %s: %s",
	"log.ending": "ENDING — %s",
}

const ZH := {
	"title.eyebrow": "子午账本 · 夜间作业档案",
	"title.name": "13层\n夜班",
	"title.info": "25–35 分钟点击恐怖叙事\n建议戴耳机 · 选择会保留",
	"title.start": "开始夜班",
	"btn.continue": "继续  ▸",
	"vn.advance": "点击",
	"vn.pressure": "压迫",
	"btn.continue_n": "继续  ▸  %d",
	"btn.case_log": "案卷",
	"btn.pause": "暂停",
	"btn.proceed": "前进  ▸",
	"btn.return": "返回",
	"btn.restart": "回到标题重开",
	"btn.restart_shift": "重开夜班",
	"choice.banner": "此决定将被永久记录",
	"log.title": "案卷 // 持久记录",
	"log.empty": "尚无记录。",
	"pause.title": "夜班已暂停",
	"pause.body": "钟为你停了。记录没有。\n\n本局进度保存在这次会话里。继续，或用下方按钮回到标题重开。",
	"idle.chapter": "档案 13",
	"idle.place": "夜间作业",
	"idle.clock": "周日",
	"idle.objective": "准备好再开始。选择会保留到重开。",
	"route.next": "前往下一区域  ▸",
	"route.decision": "带着这个决定继续  ▸",
	"log.objective": "目标\n%s\n",
	"log.decisions": "决定",
	"log.eli": "伊莱：%s",
	"log.compliance": "合规：%s",
	"log.route": "路线：%s",
	"log.contract": "合同：%s\n",
	"log.pending": "未决",
	"log.evidence": "证据 // %d / 28",
	"log.decision": "决定 — %s：%s",
	"log.ending": "结局 — %s",
}
