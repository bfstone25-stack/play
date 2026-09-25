## Every request that drops a piece ("the headphones") into a template must read as the
## language writes it: French "à côté du casque", never "de le casque"; Spanish "del café".
## Run: godot --headless --path . -s res://tests/contractions.gd   (exit 1 on a bad join)
extends SceneTree

const BAD := {"fr": [" de le ", " de les ", " à le ", " à les ", " de un ", " de une "],
	"es": [" de el ", " a el "]}


func _init() -> void:
	var I = load("res://scripts/i18n.gd").new()
	var bad := 0
	var n := 0
	var en: Dictionary = I.T["en"]
	for l in BAD.keys():
		I.lang = l
		for key in en.keys():
			if not str(en[key]).contains("{piece}"):
				continue
			for pk in en.keys():
				if not str(pk).begins_with("f2p_pc_"):
					continue
				var s: String = I.fmt(key, {"name": "X", "piece": I.t(pk), "n": 3})
				n += 1
				for w in BAD[l]:
					if s.contains(w):
						bad += 1
						print("BAD %s %s + %s: %s" % [l, key, pk, s])
	print("contractions: %d joins, %d bad" % [n, bad])
	I.free()
	quit(1 if bad or n == 0 else 0)
