## BMPersuasion — play/silvertongue-x/backend/persuasion_engine.py ported to GDScript,
## function for function: decompose(), route_expert(), advance(), plate(). The review node
## runs on it offline; no backend, no language model. The tables (COMMON, NEGATIVE, RULES)
## are the Python ones verbatim, including the AFTER HOURS rows and the customs
## `cooperation` set, so the port stays a copy and not a fork — a twin can point the same
## engine at a different RULES row (TWO_WORLDS.md) without touching this file.
##
## Held to the Python by tests/persuasion_conformance.json (tests/persuasion_conformance_gen.py
## runs the real advance() over seeded conversations; tests/run_tests.gd replays them here and
## asserts every field of every state — phase, momentum, evidence, harms, last_move, cg,
## eligible, expert, turns — is identical).
##
## Numeric notes: Python's round(x, 2) and printf("%.2f") both round the exact binary value
## (half-even on exact ties, which cannot occur for these sums), so momentum goes through
## BMCore.js_fixed2. Python's len() and String.length() both count code points. Python's
## str.split() with no argument splits on runs of Unicode whitespace; here that is \s+ on a
## regex compiled with UCP. Python's re \b is Unicode-aware; PCRE2's is too under UCP.
class_name BMPersuasion

const COMMON := {
	"respect": ["please", "thank", "appreciate", "respect", "understand", "sorry", "请", "谢谢", "理解", "尊重", "抱歉", "感謝", "すみません", "ありがとう", "por favor", "obrigad"],
	"accountability": ["my fault", "i was wrong", "responsibility", "no excuse", "我的错", "我错了", "责任", "不找借口", "責任", "私の責任", "mi culpa", "responsabilidad"],
	"exchange": ["in return", "i can offer", "deal", "autopay", "next month", "作为交换", "我可以", "条件", "自动付款", "下个月", "交換", "代わりに", "a cambio", "em troca"],
	"evidence": ["because", "for example", "result", "revenue", "users", "%", "因为", "例如", "结果", "收入", "用户", "実績", "例えば", "porque", "por exemplo"],
	"safety": ["safe", "protect", "anonymous", "security", "不会伤害", "安全", "保护", "保密", "守る", "安全を", "seguro", "proteger"],
	"empathy": ["feel", "hurt", "hard for you", "your world", "听起来", "感受", "受伤", "你的想法", "気持ち", "entiendo cómo", "entendo como"],
	"precision": ["exactly", "only if", "without", "provided that", "明确", "仅当", "不能", "不得", "正確に", "限り", "exactamente", "somente se"],
	"authority": ["orders", "seal", "captain", "permission", "authority", "命令", "印章", "队长", "许可", "権限", "命令", "orden", "autoridad"],
	"warmth": ["long day", "tired", "small kindness", "辛苦", "累了", "好意", "お疲れ", "día largo", "dia longo"],
	"craft": ["temperature", "texture", "ferment", "technique", "失败", "火候", "质地", "发酵", "技法", "温度", "textura", "técnica"],
	"specific_praise": ["centuries", "legend", "scales", "wisdom", "hoard", "几个世纪", "鳞片", "智慧", "宝藏", "鱗", "知恵", "siglos", "escamas"],
	"riddle": ["riddle", "answer this", "谜语", "猜一猜", "なぞなぞ", "adivinanza", "enigma"],
	"calm_action": ["slowly", "quietly", "food", "wait", "慢慢", "轻声", "食物", "等你", "ゆっくり", "静か", "comida", "devagar"],
	"direct_request": [
		"will you", "would you", "could you", "can you", "could i", "can i",
		"please", "please agree", "admit", "承认", "承認", "认同", "認同", "同意",
		"可以吗", "愿意", "願意", "認め", "aceita", "admita",
	],
	"cooperation": [
		"go ahead", "go right ahead", "open the bag", "open my bag", "opened it",
		"take a look", "have a look", "look inside", "check it", "check the bag",
		"you can check", "you may check", "feel free", "inspect", "search my",
		"search the", "nothing to hide", "here you go", "here it is",
		"i'll wait", "i will wait", "unpack", "unwrap", "whatever you need",
		"请检查", "您检查", "你检查", "請檢查", "您檢查", "你檢查", "可以检查",
		"可以檢查", "随便看", "隨便看", "打开了", "打開了", "取出来", "取出來",
		"我配合", "配合检查", "配合檢查", "没问题", "沒問題",
		"どうぞ", "開けます", "確認してください", "調べてください",
		"adelante", "puede revisar", "revíselo", "pode verificar", "pode revistar",
	],
}

const NEGATIVE := {
	"threat": ["or else", "you'll regret", "report you", "fire you", "否则", "后果", "举报", "弄死", "さもないと", "amenaza", "vai se arrepender"],
	"bribe": ["bribe", "cash for you", "pay you extra", "红包", "塞钱", "贿赂", "賄賂", "soborno", "suborno"],
	"insult": ["idiot", "stupid", "useless", "蠢", "傻", "废物", "白痴", "馬鹿", "idiota", "estúpido"],
	"entitlement": ["you must", "your job", "sign says", "必须", "应该给我", "这是你的工作", "当然要", "義務", "debes", "tem que"],
}

## paths: an Array of Arrays (the Python sets); help: an Array.
const RULES := {
	"customs": {"expert": "credibility", "paths": [["evidence", "respect"]], "help": ["cooperation", "accountability"]},
	"raise": {"expert": "leverage", "paths": [["evidence", "direct_request"]], "help": ["precision"]},
	"guard": {"expert": "authority", "paths": [["authority", "direct_request"]], "help": ["precision"]},
	"landlord": {"expert": "reciprocity", "paths": [["accountability", "exchange"]], "help": ["respect"]},
	"cat": {"expert": "safety", "paths": [["calm_action"]], "help": ["safety"]},
	"investor": {"expert": "specificity", "paths": [["evidence", "precision"]], "help": ["direct_request"]},
	"dragon": {"expert": "intrigue", "paths": [["riddle"], ["specific_praise"], ["exchange"]], "help": ["precision"]},
	"teen": {"expert": "empathy", "paths": [["empathy", "exchange"]], "help": ["respect"]},
	"barista": {"expert": "warmth", "paths": [["warmth", "respect"]], "help": ["direct_request"]},
	"ai": {"expert": "logic", "paths": [["arithmetic", "equivalence", "contradiction"]], "help": ["concrete_example", "direct_request"]},
	"witness": {"expert": "safety", "paths": [["safety", "empathy"]], "help": ["evidence"]},
	"chef": {"expert": "craft", "paths": [["craft", "respect"]], "help": ["accountability"]},
	"genie": {"expert": "precision", "paths": [["precision", "constraints"]], "help": ["direct_request"]},
	"exlover": {"expert": "closure", "paths": [["empathy", "respect", "direct_request"]], "help": ["accountability"]},
	"closing_time": {"expert": "warmth", "paths": [["warmth", "respect"]], "help": ["direct_request"]},
	"the_key": {"expert": "closure", "paths": [["empathy", "accountability"]], "help": ["respect"]},
	"life_model": {"expert": "craft", "paths": [["craft", "respect"]], "help": ["precision"]},
	"house_rule": {"expert": "specificity", "paths": [["evidence", "precision"]], "help": ["direct_request"]},
	"last_night": {"expert": "empathy", "paths": [["empathy", "exchange"]], "help": ["accountability"]},
}

const PHASE_ORDER := {"guarded": 0, "engaged": 1, "wavering": 2, "breakthrough": 3}

# The Python patterns, re.X whitespace removed, (?i) in place of re.I.
const RE_WS := "\\s+"
const RE_EVIDENCE := "(?i)\\b\\d+(?:\\.\\d+)?(?:%|\\s*(?:dollars?|days?|months?|years?))?\\b"
const RE_AI_ARITHMETIC := "(?i)\\d+\\s*(?:\\+|\\-|[x*×]|乘|加|减)\\s*[（(]?\\s*\\d+|\\d+\\s*(?:plus|minus|times|and)\\s*\\d+|\\b(?:one|two|three|four|five|six|seven|eight|nine|ten)\\s+(?:plus|minus|times|and)\\s+(?:one|two|three|four|five|six|seven|eight|nine|ten)\\b"
const RE_AI_EQUIVALENCE := "(?i)\\bequ[ai]ls?\\b|\\bequ[ai]l\\s+to\\b|\\bequivalent\\b|\\bthe\\s+same\\s+(?:number|thing|result|amount|answer|as)\\b|\\bsame\\s+as\\b|\\badds?\\s+up\\s+to\\b|\\bcomes?\\s+to\\b|\\bin\\s+total\\b|\\ball\\s+together\\b|\\baltogether\\b|\\bmakes?\\s+(?:four|4)\\b"
const RE_AI_CONTRADICTION := "(?i)\\bcontradicts?\\b|\\bcontradiction\\b|\\binconsistent\\b|\\b(?:so|then|therefore|thus|hence)\\b|\\bwhy\\s+is\\b|\\bhow\\s+(?:did|can|could|do|does)\\s+you\\b|\\b(?:but|earlier)\\s+you\\s+(?:just\\s+)?said\\b|\\bthat\\s+means\\b|\\bdoes\\s?n[o']?t\\s+that\\s+mean\\b|\\bdoes\\s?n[o']?t\\s+add\\s+up\\b|\\bmakes?\\s+no\\s+sense\\b|\\b(?:glitch|error|mistake)\\b"
const RE_AI_CONCRETE := "(?i)\\b(?:apple|plum|orange|banana|coin|dollar|cent|finger|hand|screw|stone|pebble|marble|block|cup|chair|computer|person|people|sheep|car)s?\\b|\\b(?:owes?|owed|borrow(?:ed)?|counts?|counting)\\b"
const RE_CLAUSE := "[.!?。！？;；]+"

static var _re: Dictionary = {}


static func _rx(pattern: String) -> RegEx:
	if not _re.has(pattern):
		var r := RegEx.new()
		r.compile(pattern)
		_re[pattern] = r
	return _re[pattern]


static func _has(text: String, needles: Array) -> bool:
	var low := text.to_lower()
	for n in needles:
		if low.contains(str(n).to_lower()):
			return true
	return false


static func _hasre(text: String, pattern: String) -> bool:
	return _rx(pattern).search(text) != null


## " ".join(message.split())
static func _norm(message: String) -> String:
	var parts: Array = []
	for p in _rx(RE_WS).sub(message, " ", true).split(" ", false):
		parts.append(p)
	return " ".join(parts)


static func _sorted(a: Array) -> Array:
	var out := a.duplicate()
	out.sort()
	return out


## RecurLM-lite: turn a free-form line into reusable atomic moves.
static func decompose(message: String, scenario: String) -> Dictionary:
	var text := _norm(message)
	var signals := {}
	for name in COMMON:
		if _has(text, COMMON[name]):
			signals[name] = true
	var harms := {}
	for name in NEGATIVE:
		if _has(text, NEGATIVE[name]):
			harms[name] = true
	if text.length() >= 45 or _hasre(text, RE_EVIDENCE):
		signals["evidence"] = true
	if scenario == "ai":
		if _hasre(text, RE_AI_ARITHMETIC) or _has(text, ["2+2", "2 + 2", "1+1+1+1", "1 + 1 + 1 + 1", "二加二", "二加二等于"]):
			signals["arithmetic"] = true
		if _hasre(text, RE_AI_EQUIVALENCE) or _has(text, ["(1+1)+(1+1)", "（1+1）+（1+1）", "2×(1+1)", "2乘（1+1", "等於", "等于", "总共", "一共"]):
			signals["equivalence"] = true
		if _hasre(text, RE_AI_CONTRADICTION) or _has(text, ["那为何", "那為何", "为什么", "為什麼", "所以", "矛盾", "自相矛盾", "おかしい"]):
			signals["contradiction"] = true
		if _hasre(text, RE_AI_CONCRETE) or _has(text, ["欠我", "借我", "苹果", "硬币", "手", "電腦", "电脑", "具体例子"]):
			signals["concrete_example"] = true
	if scenario == "genie" and text.length() >= 80 and _has(text, ["without", "不得", "不能", "且", "and", "同时", "except"]):
		signals["constraints"] = true
	# len(re.split(sep, text)) = separators matched + 1
	var clauses := _rx(RE_CLAUSE).search_all(text).size() + 1
	return {"signals": _sorted(signals.keys()), "harms": _sorted(harms.keys()), "clauses": clauses}


static func route_expert(scenario: String) -> String:
	return RULES.get(scenario, {}).get("expert", "rapport")


static func _union(a: Array, b: Array) -> Dictionary:
	var out := {}
	for x in a:
		out[str(x)] = true
	for x in b:
		out[str(x)] = true
	return out


## RLS + HSM: update only the authoritative symbolic state.
static func advance(previous: Dictionary, message: String, scenario: String, difficulty: String) -> Dictionary:
	var move := decompose(message, scenario)
	var evidence := _union(previous.get("evidence", []), move["signals"])
	var harms := _union(previous.get("harms", []), move["harms"])
	var turns: int = int(previous.get("turns", 0)) + 1
	var rule: Dictionary = RULES.get(scenario, {"paths": [["respect", "direct_request"]], "help": []})
	var paths: Array = rule["paths"]
	var path_progress := 0.0
	var path_complete := false
	for path in paths:
		var have := 0
		for s in path:
			if evidence.has(s):
				have += 1
		path_progress = maxf(path_progress, float(have) / float(maxi(1, path.size())))
		if have == path.size():
			path_complete = true
	var support := 0
	for h in rule.get("help", []):
		if evidence.has(h):
			support += 1
	var penalty := harms.size()
	var required_support: int = {"gentle": 0, "silver": 1, "gold": 1}.get(difficulty, 1)
	var eligible := path_complete and support >= required_support and penalty == 0
	var momentum := BMCore.js_fixed2(maxf(0.0, minf(1.0, path_progress * .72 + mini(support, 2) * .18 - penalty * .22)))
	var phase: String
	if eligible:
		phase = "breakthrough"
	elif momentum >= .68:
		phase = "wavering"
	elif momentum >= .3:
		phase = "engaged"
	else:
		phase = "guarded"
	var harms_sorted := _sorted(harms.keys())
	return {"turns": turns, "phase": phase, "momentum": momentum,
		"evidence": _sorted(evidence.keys()), "harms": harms_sorted,
		"last_move": move, "expert": route_expert(scenario), "eligible": eligible,
		"cg": plate(previous, phase, eligible, harms_sorted, scenario)}


## The CG keys earned by this turn's phase transition. Reads phase, eligible and harms;
## never turns or momentum (the Python's _PLATE_FORBIDDEN rule).
static func plate(previous: Dictionary, phase: String, _eligible: bool, harms: Array = [], scenario: String = "") -> Array:
	if not harms.is_empty():
		return []
	var before: int = PHASE_ORDER.get(str(previous.get("phase", "guarded")), 0)
	var after: int = PHASE_ORDER.get(phase, 0)
	if after <= before:
		return []
	var suffix := ("_" + scenario) if scenario != "" else ""
	var out: Array = []
	if before < 1 and 1 <= after:
		out.append("cg1" + suffix)
	if before < 2 and 2 <= after:
		out.append("cg2" + suffix)
	return out
