## GCStrings — the prototype's GCi18n (play/ghost-channel/i18n.js) over the generated
## packs in gc_strings_data.gd. en and zh; anything missing in zh falls through to en,
## exactly as the JS did.
class_name GCStrings

const LANGS := ["en", "zh"]
const LANG_LABEL := {"en": "EN", "zh": "中文"}

## Keys this build needs that the prototype's packs do not have, because the prototype
## never had the thing they describe. Consulted before the generated packs, so regenerating
## gc_strings_data.gd from i18n.js never clobbers them.
const EXTRA := {
	"en": {
		"noVoiceNote": "No voice pack in this build — the five speak in text and call-sign tone only.",
		"voiceNote": "Voices: CosyVoice2, through the station's band-pass.",
		"logLabel": "NET LOG",
		"incoming": "INCOMING",
		"opsHint": "Operation 1 is free. 2 and 3 open with the full game.",
		"rating": "ALL AGES",
	},
	"zh": {
		"noVoiceNote": "此版本没有语音包——五个人只有文字和呼号音。",
		"voiceNote": "语音：CosyVoice2，经过电台带通处理。",
		"logLabel": "通话记录",
		"incoming": "来话",
		"opsHint": "第一场免费。第二、三场随完整版开启。",
		"rating": "全年龄",
	},
}

static var _re: RegEx


static func _bag(lang: String) -> Dictionary:
	return GCStringsData.T.get(lang, GCStringsData.T["en"])


## `{name}` placeholders filled from vars; an unknown placeholder becomes "" (i18n.js fill()).
static func fill(s: String, vars: Dictionary) -> String:
	if _re == null:
		_re = RegEx.new()
		_re.compile("\\{(\\w+)\\}")
	var out := ""
	var last := 0
	for m in _re.search_all(s):
		out += s.substr(last, m.get_start() - last)
		var k := m.get_string(1)
		out += str(vars[k]) if vars.has(k) and vars[k] != null else ""
		last = m.get_end()
	out += s.substr(last)
	return out


static func t(lang: String, key: String, vars: Dictionary = {}) -> String:
	var ex: Dictionary = EXTRA.get(lang, EXTRA["en"])
	if ex.has(key):
		return fill(str(ex[key]), vars)
	if EXTRA["en"].has(key):
		return fill(str(EXTRA["en"][key]), vars)
	var b := _bag(lang)
	var v = b.get(key)
	if v == null:
		v = GCStringsData.T["en"].get(key, key)
	return fill(str(v), vars)


static func agent(lang: String, id: String) -> Dictionary:
	var a: Dictionary = _bag(lang)["agents"]
	return a.get(id, GCStringsData.T["en"]["agents"][id])


static func op_meta(lang: String, i: int) -> Dictionary:
	var ops: Array = _bag(lang)["ops"]
	return ops[i] if i < ops.size() else GCStringsData.T["en"]["ops"][i]


static func type_name(lang: String, k: String) -> String:
	return str(_bag(lang)["type"].get(k, k))


static func lines(lang: String, k: String) -> Array:
	var l: Dictionary = _bag(lang)["lines"]
	return l.get(k, GCStringsData.T["en"]["lines"][k])
