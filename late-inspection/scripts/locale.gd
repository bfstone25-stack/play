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
	"splash.title": "Late Inspection: Flat 404",
	"splash.hint": "Click to enter  ·  WASD  mouse  E interact  Esc",
	"splash.start": "ENTER THE BUILDING",
	"pause.title": "INSPECTION PAUSED\nEsc resumes · Mouse recaptures on return",
	"pause.resume": "RESUME INSPECTION",
	"pause.restart": "RESTART FROM ARRIVAL",
	"doc.continue": "CONTINUE  ›",
	"doc.close": "CLOSE",
	"doc.page": "PAGE %d / %d",
	"vn.advance": "E / click",
	"vn.choose": "A / B",
	"vn.pressure": "PRESSURE",
	"spk.mara": "MARA",
	"spk.iris": "IRIS",
	"spk.dane": "DANE",
	"spk.pell": "PELL",
	"spk.harrow": "HARROW",
	"spk.inner": "INNER",
	"spk.system": "SYSTEM",
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
	"lang.caption": "语言",
	"splash.title": "深夜验房：404室",
	"splash.hint": "点击进入  ·  方向键  鼠标  互动键  暂停键",
	"splash.start": "进入大楼",
	"pause.title": "验房已暂停\n暂停键继续 · 返回时鼠标会重新锁定",
	"pause.resume": "继续验房",
	"pause.restart": "从抵达处重开",
	"doc.continue": "继续  ›",
	"doc.close": "关闭",
	"doc.page": "第 %d / %d 页",
	"vn.advance": "互动键 / 点击",
	"vn.choose": "甲 / 乙",
	"vn.pressure": "压迫",
	"spk.mara": "玛拉",
	"spk.iris": "艾里斯",
	"spk.dane": "戴恩",
	"spk.pell": "佩尔",
	"spk.harrow": "哈罗",
	"spk.inner": "内心",
	"spk.system": "系统",
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

const JA := {
	"lang.caption": "言語",
	"splash.title": "深夜検査：404号室",
	"splash.hint": "クリックで入る  ·  WASD  マウス  Eで調べる  Esc",
	"splash.start": "建物に入る",
	"pause.title": "検査は停止中\nEscで再開 · 戻るとマウスは再ロック",
	"pause.resume": "検査を続ける",
	"pause.restart": "到着からやり直す",
	"doc.continue": "続ける  ›",
	"doc.close": "閉じる",
	"doc.page": "%d / %d ページ",
	"vn.advance": "E / クリック",
	"vn.choose": "A / B",
	"vn.pressure": "圧迫",
	"spk.mara": "マラ",
	"spk.iris": "アイリス",
	"spk.dane": "デイン",
	"spk.pell": "ペル",
	"spk.harrow": "ハロー",
	"spk.inner": "内心",
	"spk.system": "システム",
	"btn.continue": "続ける",
	"btn.credits": "クレジット",
	"btn.restart": "やり直す",
	"ending.thanks": "404号室\n\n目撃してくれてありがとう。\n\nRで検査をやり直す。",
	"evidence": "証拠 %02d / 23",
	"prompt.prefix": "E / クリック  ",
	"title.card": "404号室\n深夜の検査",
	"ch.0": "第I章 — 時間外",
	"ch.1": "第II章 — 明け渡された部屋",
	"ch.2": "第III章 — まだいる",
	"ch.3": "第IV章 — 管が話す",
	"ch.4": "第V章 — 一分",
	"ch.5": "第VI章 — 臨時の保管人",
	"ch.6": "第VII章 — 最後のノック",
	"obj.0": "エレベーターホールで時間外検査命令を読む。",
	"obj.order": "404号室を見つけ、番号を覆う告示を読む。",
	"obj.dane": "404号室の入場告示を読む。",
	"obj.notice": "404に入り、居間のチェックリストを調べる。",
	"obj.checklist": "居間を捜索する。準備ができたら留守番電話を再生する。",
	"obj.answering": "台所を調べ、湿った壁を記録する。",
	"obj.stain": "湿った線を浴室まで辿り、点検札を読む。",
	"obj.service": "管が待っている。答えるか、バルブを閉じる。",
	"obj.pipe": "濡れた足跡は寝室へ続く。クローゼットを開ける前に探せ。",
	"obj.wardrobe": "壁の空洞に隠されたカセットを再生する。",
	"obj.cassette": "居間に戻る。ペルが電話している。",
	"obj.followup": "コーヒーテーブルの通宵条項を読む。",
	"obj.clause": "変えられた鍵を調べ、覗き穴から外を見る。",
	"obj.final": "最後のノックが玄関で待っている。",
	"note.stain_keep": "マラ：まず証拠。不可能な部分はペルに説明させろ。\n湿りの中にアイリス・ヴェイルの文字が残っている。",
	"note.stain_wipe": "マラ：反射だ。圧縮が悪い。仕事を終えろ。\n文字は五本指の掌紋ににじむ。",
	"note.pipe_yes": "マラは三度ノックする。\nアイリス、銅管から：寝室。コートの後ろ。私を録って。\nデイン：聞こえただろ。ペルに点検と書かせるな。",
	"note.pipe_no": "バルブは掴まれた手首のように抗い、それから回る。\nペル：いい。静かな建物は安全な建物だ。",
	"note.clause_yes": "マラ・ヴェン。臨時。朝まで。\nインクが署名から活字の「所持品」へ這う。",
	"note.clause_no": "マラ：いいえ。この検査は中止する。\n引き裂かれた両半は今、ユニット404：見つからず、と読む。",
	"end.witness": "結末 — 証人",
	"end.complicit": "結末 — 共犯",
	"end.404": "エラー 404 — 検査員が見つからない",
	"beat.witness.0": "扉は点検空洞へ開く。アイリスは半透明の配管の後ろに立ち、片手を壁に当てている。",
	"beat.witness.1": "マラ：アイリス・ヴェイルがこの部屋に住んでいた。私は聞いた。録った。空室とは証明しない。\nアイリス：なら、私を見て。",
	"beat.witness.2": "404の表札はアイリス・ヴェイルと書く。夜明けが廊下に届く。\nデイン：彼女は出てきたか？\nマラ：名前が出てきた。",
	"beat.witness.3": "その朝、ヴェスパーコートは十七件の検査依頼を受けた。\n404号室が空室として載ることは二度となかった。",
	"beat.complicit.0": "スタンドランプを消す。ノックは途中で止まる。",
	"beat.complicit.1": "日光。部屋は完璧にきれいだ。家族写真では、あなたの顔がそむけられている。\nペル：検査は受理された。更新は今日から。",
	"beat.complicit.2": "居住者：マラ・ヴェン\n退去検査員：[到着待ち]\n次の客のために管を静かに保つこと。",
	"beat.complicit.3": "新しい検査員の鍵が廊下から入る。\nあなたは建物を静かにした。建物はあなたを替えやすくした。",
	"beat.404.0": "四階のすべての扉が403と読む。鍵は404があった壁を通り抜ける。",
	"beat.404.1": "マラ：中にいた。台所、浴室、寝室——\nオペレーター：ヴェスパーコートのどの階にも四番目の住戸はない。",
	"beat.404.2": "所持品が自ら消える：カセット、写真、条項、それからマラ・ヴェン。\nアイリス：選ばない証人は、もう一つの行方不明の部屋でしかない。",
	"beat.404.3": "エレベーターは煉瓦の壁に開く。\n次の予約は01:47。身分証を持参すること。",
	"zone.0": "エレベーターホール",
	"zone.1": "四階廊下",
	"zone.2": "居間",
	"zone.3": "台所",
	"zone.4": "浴室",
	"zone.5": "寝室",
	"world.tonight": "今夜",
	"world.iris": "アイリス・ヴェイル",
}

const ES := {
	"lang.caption": "Idioma",
	"splash.title": "Inspección tardía: Piso 404",
	"splash.hint": "Clic para entrar  ·  WASD  ratón  E interactuar  Esc",
	"splash.start": "ENTRAR AL EDIFICIO",
	"pause.title": "INSPECCIÓN EN PAUSA\nEsc reanuda · El ratón se recaptura al volver",
	"pause.resume": "REANUDAR INSPECCIÓN",
	"pause.restart": "REINICIAR DESDE LA LLEGADA",
	"doc.continue": "CONTINUAR  ›",
	"doc.close": "CERRAR",
	"doc.page": "PÁGINA %d / %d",
	"vn.advance": "E / clic",
	"vn.choose": "A / B",
	"vn.pressure": "PRESIÓN",
	"spk.mara": "MARA",
	"spk.iris": "IRIS",
	"spk.dane": "DANE",
	"spk.pell": "PELL",
	"spk.harrow": "HARROW",
	"spk.inner": "INTERIOR",
	"spk.system": "SISTEMA",
	"btn.continue": "CONTINUAR",
	"btn.credits": "CRÉDITOS",
	"btn.restart": "REINICIAR",
	"ending.thanks": "PISO 404\n\nGracias por ser testigo.\n\nPulsa R para reiniciar la inspección.",
	"evidence": "PRUEBAS %02d / 23",
	"prompt.prefix": "E / clic  ",
	"title.card": "PISO 404\nUna inspección tardía",
	"ch.0": "CAPÍTULO I — FUERA DE HORARIO",
	"ch.1": "CAPÍTULO II — LOCAL ENTREGADO",
	"ch.2": "CAPÍTULO III — SIGUE AQUÍ",
	"ch.3": "CAPÍTULO IV — LA TUBERÍA HABLA",
	"ch.4": "CAPÍTULO V — UN MINUTO",
	"ch.5": "CAPÍTULO VI — CUSTODIO TEMPORAL",
	"ch.6": "CAPÍTULO VII — EL ÚLTIMO GOLPE",
	"obj.0": "Lee la orden de inspección fuera de horario en el vestíbulo del ascensor.",
	"obj.order": "Encuentra el piso 404. Lee el aviso pegado sobre su número.",
	"obj.dane": "Lee el aviso de acceso del 404.",
	"obj.notice": "Entra al 404 e inspecciona la lista en el salón.",
	"obj.checklist": "Registra el salón. Reproduce el contestador cuando estés lista.",
	"obj.answering": "Investiga la cocina y documenta la pared húmeda.",
	"obj.stain": "Sigue la línea húmeda al baño. Lee la etiqueta de servicio.",
	"obj.service": "La tubería espera. Respóndele o cierra la válvula.",
	"obj.pipe": "Huellas mojadas llevan al dormitorio. Registra antes de abrir el armario.",
	"obj.wardrobe": "Reproduce el casete escondido en la cavidad del muro.",
	"obj.cassette": "Vuelve al salón. Pell está llamando.",
	"obj.followup": "Lee la cláusula de pernocta en la mesa de centro.",
	"obj.clause": "Inspecciona la llave cambiada y mira por la mirilla.",
	"obj.final": "El último golpe espera en la puerta principal.",
	"note.stain_keep": "MARA: Primero la prueba. Pell puede explicar lo imposible.\nLas letras IRIS VALE siguen visibles en la humedad.",
	"note.stain_wipe": "MARA: Un reflejo. Mala compresión. Termina el trabajo.\nLas letras se manchan en una huella de cinco dedos.",
	"note.pipe_yes": "MARA golpea tres veces.\nIRIS, a través del cobre: Dormitorio. Detrás de los abrigos. Grábame.\nDANE: La oíste. No dejes que Pell lo llame mantenimiento.",
	"note.pipe_no": "La válvula resiste como una muñeca sujetada y luego gira.\nPELL: Bien. Un edificio silencioso es un edificio seguro.",
	"note.clause_yes": "MARA VENN. Temporal. Hasta la mañana.\nLa tinta repta desde tu firma hacia la palabra impresa «contenido».",
	"note.clause_no": "MARA: No. Esta inspección queda suspendida.\nLas dos mitades rotas ahora dicen UNIDAD 404: NO ENCONTRADA.",
	"end.witness": "FINAL — TESTIGO",
	"end.complicit": "FINAL — CÓMPLICE",
	"end.404": "ERROR 404 — INSPECTORA NO ENCONTRADA",
	"beat.witness.0": "La puerta se abre a la cavidad de servicio. Iris está detrás de tuberías translúcidas, una mano contra el muro.",
	"beat.witness.1": "MARA: Iris Vale ocupó este piso. La oí. La grabé. No voy a certificarlo vacío.\nIRIS: Entonces mírame.",
	"beat.witness.2": "La puerta 404 lleva IRIS VALE. El alba llega al pasillo.\nDANE: ¿Salió ella?\nMARA: Salió su nombre.",
	"beat.witness.3": "Esa mañana, Vesper Court recibió diecisiete solicitudes de inspección.\nEl piso 404 no volvió a listarse como vacío.",
	"beat.complicit.0": "Apagas la lámpara de pie. El golpe se detiene a mitad de un impacto.",
	"beat.complicit.1": "Luz del día. El piso está inmaculado. En las fotos familiares, tu rostro mira hacia otro lado.\nPELL: Inspección aceptada. Tu renovación empieza hoy.",
	"beat.complicit.2": "OCUPANTE: MARA VENN\nINSPECTOR DE SALIDA: [en espera de llegada]\nMantén la tubería en silencio para el próximo huésped.",
	"beat.complicit.3": "Una llave de inspectora nueva entra desde el pasillo.\nTú silenciaste el edificio. El edificio te hizo fácil de reemplazar.",
	"beat.404.0": "Cada puerta del cuarto piso ahora dice 403. Tu llave atraviesa el muro donde estaba el 404.",
	"beat.404.1": "MARA: Estuve dentro. Cocina, baño, dormitorio—\nOPERADORA: Vesper Court no tiene una cuarta unidad en ningún piso.",
	"beat.404.2": "Tu inventario se borra solo: casete, fotografía, cláusula, luego MARA VENN.\nIRIS: Una testigo que no elige es solo otra habitación perdida.",
	"beat.404.3": "El ascensor se abre a un muro de ladrillo.\nLa próxima cita es a las 01:47. Traiga identificación.",
	"zone.0": "VESTÍBULO DEL ASCENSOR",
	"zone.1": "PASILLO DEL CUARTO PISO",
	"zone.2": "SALÓN",
	"zone.3": "COCINA",
	"zone.4": "BAÑO",
	"zone.5": "DORMITORIO",
	"world.tonight": "ESTA NOCHE",
	"world.iris": "IRIS VALE",
}

const KO := {
	"lang.caption": "언어",
	"splash.title": "심야 점검: 404호",
	"splash.hint": "클릭해서 들어가기  ·  WASD  마우스  E 조사  Esc",
	"splash.start": "건물 들어가기",
	"pause.title": "점검이 멈춤\nEsc로 계속 · 돌아오면 마우스가 다시 잠김",
	"pause.resume": "점검 계속",
	"pause.restart": "도착부터 다시",
	"doc.continue": "계속  ›",
	"doc.close": "닫기",
	"doc.page": "%d / %d 쪽",
	"vn.advance": "E / 클릭",
	"vn.choose": "A / B",
	"vn.pressure": "압박",
	"spk.mara": "마라",
	"spk.iris": "아이리스",
	"spk.dane": "데인",
	"spk.pell": "펠",
	"spk.harrow": "해로우",
	"spk.inner": "속마음",
	"spk.system": "시스템",
	"btn.continue": "계속",
	"btn.credits": "제작진",
	"btn.restart": "다시 시작",
	"ending.thanks": "404호\n\n증인이 되어 주어 고맙다.\n\nR을 눌러 점검을 다시 시작한다.",
	"evidence": "증거 %02d / 23",
	"prompt.prefix": "E / 클릭  ",
	"title.card": "404호\n한밤의 점검",
	"ch.0": "제I장 — 퇴근 이후",
	"ch.1": "제II장 — 인도된 집",
	"ch.2": "제III장 — 아직 있다",
	"ch.3": "제IV장 — 파이프가 말한다",
	"ch.4": "제V장 — 일 분",
	"ch.5": "제VI장 — 임시 보관인",
	"ch.6": "제VII장 — 마지막 노크",
	"obj.0": "엘리베이터 홀에서 시간 외 점검 명령을 읽으라.",
	"obj.order": "404호를 찾고, 문패를 가린 공고를 읽으라.",
	"obj.dane": "404호의 출입 공고를 읽으라.",
	"obj.notice": "404에 들어가 거실의 점검표를 조사하라.",
	"obj.checklist": "거실을 수색하라. 준비되면 자동응답기를 재생하라.",
	"obj.answering": "주방을 조사하고 젖은 벽을 기록하라.",
	"obj.stain": "젖은 선을 따라 욕실로 가라. 정비 태그를 읽으라.",
	"obj.service": "파이프가 기다린다. 응답하거나 밸브를 닫으라.",
	"obj.pipe": "젖은 발자국이 침실로 이어진다. 옷장을 열기 전에 수색하라.",
	"obj.wardrobe": "벽 공동에 숨긴 카세트를 재생하라.",
	"obj.cassette": "거실로 돌아가라. 펠이 전화한다.",
	"obj.followup": "커피 테이블의 야간 조항을 읽으라.",
	"obj.clause": "바뀐 열쇠를 조사하고 문구멍으로 밖을 보라.",
	"obj.final": "마지막 노크가 현관에서 기다린다.",
	"note.stain_keep": "마라: 증거 먼저. 불가능한 부분은 펠이 설명하게 하라.\n습기 안에 아이리스 베일의 글자가 남아 있다.",
	"note.stain_wipe": "마라: 반사다. 압축이 나쁘다. 일을 끝내라.\n글자가 다섯 손가락 손자국으로 번진다.",
	"note.pipe_yes": "마라가 세 번 두드린다.\n아이리스, 구리관 너머로: 침실. 코트 뒤. 나를 녹음해.\n데인: 들었잖아. 펠이 정비라고 쓰게 두지 마.",
	"note.pipe_no": "밸브는 붙잡힌 손목처럼 버티다가 돌아간다.\n펠: 좋아. 조용한 건물이 안전한 건물이다.",
	"note.clause_yes": "마라 벤. 임시. 아침까지.\n잉크가 서명에서 인쇄된 ‘물품’으로 기어간다.",
	"note.clause_no": "마라: 안 된다. 이 점검은 중단한다.\n찢긴 두 조각은 이제 유닛 404: 찾을 수 없음, 이라고 읽힌다.",
	"end.witness": "결말 — 증인",
	"end.complicit": "결말 — 공모",
	"end.404": "오류 404 — 점검원을 찾을 수 없음",
	"beat.witness.0": "문이 정비 공동으로 열린다. 아이리스가 반투명한 배관 뒤에 서서 한 손을 벽에 댄다.",
	"beat.witness.1": "마라: 아이리스 베일이 이 집에 살았다. 나는 들었다. 녹음했다. 공실이라고 증명하지 않겠다.\n아이리스: 그럼 나를 봐.",
	"beat.witness.2": "404 문패는 아이리스 베일이라고 쓴다. 새벽이 복도에 닿는다.\n데인: 그녀가 나왔나?\n마라: 이름이 나왔다.",
	"beat.witness.3": "그날 아침 베스퍼 코트는 열일곱 건의 점검 요청을 받았다.\n404호는 다시는 공실로 올라가지 않았다.",
	"beat.complicit.0": "스탠드 램프를 끈다. 노크가 중간에 멈춘다.",
	"beat.complicit.1": "햇빛. 집은 흠 없다. 가족사진에서 당신의 얼굴은 고개를 돌린다.\n펠: 점검이 수리되었다. 갱신은 오늘부터다.",
	"beat.complicit.2": "거주자: 마라 벤\n퇴실 점검원: [도착 대기]\n다음 손님을 위해 파이프를 조용히 유지할 것.",
	"beat.complicit.3": "새 점검원의 열쇠가 복도에서 들어온다.\n당신은 건물을 조용히 만들었다. 건물은 당신을 바꾸기 쉽게 만들었다.",
	"beat.404.0": "4층의 모든 문이 이제 403이다. 열쇠는 404가 서 있던 벽을 통과한다.",
	"beat.404.1": "마라: 안에 있었다. 주방, 욕실, 침실——\n교환원: 베스퍼 코트는 어느 층에도 네 번째 세대가 없다.",
	"beat.404.2": "소지품이 스스로 지워진다: 카세트, 사진, 조항, 그리고 마라 벤.\n아이리스: 선택하지 않는 증인은 또 하나의 실종된 방일 뿐이다.",
	"beat.404.3": "엘리베이터가 벽돌 벽에 열린다.\n다음 예약은 01:47. 신분증을 지참하라.",
	"zone.0": "엘리베이터 홀",
	"zone.1": "4층 복도",
	"zone.2": "거실",
	"zone.3": "주방",
	"zone.4": "욕실",
	"zone.5": "침실",
	"world.tonight": "오늘 밤",
	"world.iris": "아이리스 베일",
}
