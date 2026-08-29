class_name Loc
extends Object

const SETTINGS_PATH := "user://settings.cfg"
const ALLOWED := ["en", "zh", "ja", "es", "ko"]
const NATIVE := {
	"en": "English",
	"zh": "简体中文",
	"ja": "日本語",
	"es": "Español",
	"ko": "한국어",
}

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
		next = "en"
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


static func table() -> Dictionary:
	match current():
		"zh":
			return ZH
		"ja":
			return JA
		"es":
			return ES
		"ko":
			return KO
		_:
			return EN


static func t(key: String, args: Array = []) -> String:
	var text := str(table().get(key, EN.get(key, key)))
	if args.is_empty():
		return text
	return text % args


static func _load() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--locale="):
			var forced := arg.trim_prefix("--locale=")
			code = forced if forced in ALLOWED else "en"
			return
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var saved := str(cfg.get_value("locale", "code", ""))
		if saved in ALLOWED:
			code = saved
			return
	code = _os_default()


static func _os_default() -> String:
	var lang := OS.get_locale_language().to_lower()
	if lang in ALLOWED:
		return lang
	if lang.begins_with("zh"):
		return "zh"
	return "en"


static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("locale", "code", current())
	cfg.save(SETTINGS_PATH)


const EN := {
	"lang.caption": "Language",
	"title.eyebrow": "A MERIDIAN LEDGER NIGHT OPERATIONS FILE",
	"title.name": "FLOOR 13\nNIGHT SHIFT",
	"title.info": "A 25–35 MINUTE POINT-CLICK HORROR NARRATIVE\nHeadphones recommended · choices persist",
	"title.start": "BEGIN NIGHT SHIFT",
	"btn.continue": "CONTINUE  ▸",
	"vn.advance": "click / E",
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
	"lang.caption": "语言",
	"title.eyebrow": "子午账本 · 夜间作业档案",
	"title.name": "13层\n夜班",
	"title.info": "25–35 分钟点击恐怖叙事\n建议戴耳机 · 选择会保留",
	"title.start": "开始夜班",
	"btn.continue": "继续  ▸",
	"vn.advance": "点击 / 互动键",
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

const JA := {
	"lang.caption": "言語",
	"title.eyebrow": "メリディアン台帳 · 夜間業務ファイル",
	"title.name": "13階\n夜勤",
	"title.info": "25–35分のクリック式ホラー\nヘッドホン推奨 · 選択は残る",
	"title.start": "夜勤を始める",
	"btn.continue": "続ける  ▸",
	"vn.advance": "クリック / E",
	"vn.pressure": "圧迫",
	"btn.continue_n": "続ける  ▸  %d",
	"btn.case_log": "記録",
	"btn.pause": "一時停止",
	"btn.proceed": "進む  ▸",
	"btn.return": "戻る",
	"btn.restart": "タイトルからやり直す",
	"btn.restart_shift": "夜勤をやり直す",
	"choice.banner": "この決定は永久に記録される",
	"log.title": "記録 // 永続ログ",
	"log.empty": "記録なし。",
	"pause.title": "夜勤は停止中",
	"pause.body": "時計はあなたのために止まった。記録は止まっていない。\n\n進行はこのセッションに保持される。再開するか、下のボタンでタイトルからやり直せる。",
	"idle.chapter": "ファイル 13",
	"idle.place": "夜間業務",
	"idle.clock": "日曜",
	"idle.objective": "準備ができたら始めてください。選択は再開まで残ります。",
	"route.next": "次の区域へ  ▸",
	"route.decision": "この決定のまま進む  ▸",
	"log.objective": "目標\n%s\n",
	"log.decisions": "決定",
	"log.eli": "イーライ：%s",
	"log.compliance": "コンプライアンス：%s",
	"log.route": "経路：%s",
	"log.contract": "契約：%s\n",
	"log.pending": "未決",
	"log.evidence": "証拠 // %d / 28",
	"log.decision": "決定 — %s：%s",
	"log.ending": "結末 — %s",
}

const ES := {
	"lang.caption": "Idioma",
	"title.eyebrow": "UN ARCHIVO DE OPERACIONES NOCTURNAS DE MERIDIAN",
	"title.name": "PISO 13\nTURNO NOCTURNO",
	"title.info": "NARRATIVA DE TERROR DE 25–35 MINUTOS\nAuriculares recomendados · las decisiones permanecen",
	"title.start": "EMPEZAR EL TURNO",
	"btn.continue": "CONTINUAR  ▸",
	"vn.advance": "clic / E",
	"vn.pressure": "PRESIÓN",
	"btn.continue_n": "CONTINUAR  ▸  %d",
	"btn.case_log": "EXPEDIENTE",
	"btn.pause": "PAUSA",
	"btn.proceed": "SEGUIR  ▸",
	"btn.return": "VOLVER",
	"btn.restart": "REINICIAR DESDE EL TÍTULO",
	"btn.restart_shift": "REINICIAR EL TURNO",
	"choice.banner": "DECISIÓN REGISTRADA PARA SIEMPRE",
	"log.title": "EXPEDIENTE // REGISTRO PERSISTENTE",
	"log.empty": "Sin registro.",
	"pause.title": "TURNO EN PAUSA",
	"pause.body": "El reloj se detuvo para ti. El registro, no.\n\nEl progreso se guarda en esta sesión. Continúa o vuelve al título con el botón de abajo.",
	"idle.chapter": "ARCHIVO 13",
	"idle.place": "OPERACIONES NOCTURNAS",
	"idle.clock": "DOMINGO",
	"idle.objective": "Empieza cuando quieras. Las decisiones permanecen hasta reiniciar.",
	"route.next": "CONTINUAR A LA SIGUIENTE ZONA  ▸",
	"route.decision": "CONTINUAR CON ESTA DECISIÓN  ▸",
	"log.objective": "OBJETIVO\n%s\n",
	"log.decisions": "DECISIONES",
	"log.eli": "Eli: %s",
	"log.compliance": "Cumplimiento: %s",
	"log.route": "Ruta: %s",
	"log.contract": "Contrato: %s\n",
	"log.pending": "pendiente",
	"log.evidence": "PRUEBAS // %d DE 28",
	"log.decision": "DECISIÓN — %s: %s",
	"log.ending": "FINAL — %s",
}

const KO := {
	"lang.caption": "언어",
	"title.eyebrow": "메리디안 장부 · 야간 업무 파일",
	"title.name": "13층\n야근",
	"title.info": "25–35분 클릭 호러 서사\n헤드폰 권장 · 선택은 유지됨",
	"title.start": "야근 시작",
	"btn.continue": "계속  ▸",
	"vn.advance": "클릭 / E",
	"vn.pressure": "압박",
	"btn.continue_n": "계속  ▸  %d",
	"btn.case_log": "사건 기록",
	"btn.pause": "일시정지",
	"btn.proceed": "진행  ▸",
	"btn.return": "돌아가기",
	"btn.restart": "타이틀부터 다시",
	"btn.restart_shift": "야근 다시 시작",
	"choice.banner": "이 결정은 영구히 기록됩니다",
	"log.title": "사건 기록 // 지속 로그",
	"log.empty": "기록 없음.",
	"pause.title": "야근이 멈춤",
	"pause.body": "시계는 당신을 위해 멈췄다. 기록은 멈추지 않았다.\n\n진행은 이 세션에 유지된다. 이어가거나 아래 버튼으로 타이틀부터 다시 시작하라.",
	"idle.chapter": "파일 13",
	"idle.place": "야간 업무",
	"idle.clock": "일요일",
	"idle.objective": "준비되면 시작하세요. 선택은 재시작까지 유지됩니다.",
	"route.next": "다음 구역으로  ▸",
	"route.decision": "이 결정으로 계속  ▸",
	"log.objective": "목표\n%s\n",
	"log.decisions": "결정",
	"log.eli": "엘리: %s",
	"log.compliance": "준수: %s",
	"log.route": "경로: %s",
	"log.contract": "계약: %s\n",
	"log.pending": "미결",
	"log.evidence": "증거 // %d / 28",
	"log.decision": "결정 — %s: %s",
	"log.ending": "결말 — %s",
}
