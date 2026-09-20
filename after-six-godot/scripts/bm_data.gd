## BMData — every number, ported row for row from play/beat-monday/frontend/rpg/data.js.
## Adding content = adding rows, never code. Key names are the JS ones on purpose: the
## conformance test (tests/run_tests.gd) compares state dictionaries with the JS core.
class_name BMData

const ROLES := [
	{"id": "ic", "base": {"hp": 100, "atk": 10, "rate": 2.2, "spd": 150}, "growth": {"hp": 8, "atk": 1.2}},
]

const FOES := {
	"ping":   {"hp": 14, "spd": 58, "r": 9,  "xp": 2, "dmg": 6,  "color": "#7fa8ff"},
	"invite": {"hp": 26, "spd": 44, "r": 11, "xp": 3, "dmg": 9,  "color": "#f5d031"},
	"thread": {"hp": 40, "spd": 36, "r": 13, "xp": 5, "dmg": 12, "color": "#e23b2f"},
	"cc":     {"hp": 20, "spd": 74, "r": 8,  "xp": 4, "dmg": 8,  "color": "#b98cff"},
	"metric": {"hp": 58, "spd": 30, "r": 15, "xp": 7, "dmg": 14, "color": "#5fd6a4"},
	"pager":  {"hp": 34, "spd": 92, "r": 9,  "xp": 6, "dmg": 11, "color": "#ff8a3d"},
}

const DAYS := [
	{"id": "mon", "boss": "standup",  "dur": 42, "mode": "horde", "foes": ["ping", "invite"],
	 "spawnEvery": 1.05, "perSpawn": 2, "bossHp": 420,  "bossDmg": 14, "bossShot": 1.5,  "drop": "stapler"},
	{"id": "tue", "boss": "inbox",    "dur": 48, "mode": "horde", "foes": ["ping", "cc", "thread"],
	 "spawnEvery": 0.92, "perSpawn": 2, "bossHp": 620,  "bossDmg": 16, "bossShot": 1.2,  "drop": "headphones"},
	{"id": "wed", "boss": "allhands", "dur": 52, "mode": "rant",  "foes": ["cc", "thread", "invite"],
	 "spawnEvery": 0.85, "perSpawn": 3, "bossHp": 820,  "bossDmg": 18, "bossShot": 0.85, "drop": "lanyard"},
	{"id": "thu", "boss": "review",   "dur": 56, "mode": "horde", "foes": ["metric", "thread", "cc"],
	 "spawnEvery": 0.88, "perSpawn": 2, "bossHp": 1050, "bossDmg": 20, "bossShot": 1.0,  "drop": "chair"},
	{"id": "fri", "boss": "deploy",   "dur": 62, "mode": "horde", "foes": ["pager", "metric", "ping"],
	 "spawnEvery": 0.72, "perSpawn": 3, "bossHp": 1400, "bossDmg": 24, "bossShot": 0.8,  "drop": "badge"},
]

const WEEKS := [
	{"id": "w1", "hpMul": 1.0, "dmgMul": 1.0},
	{"id": "w2", "hpMul": 1.6, "dmgMul": 1.25},
	{"id": "w3", "hpMul": 2.4, "dmgMul": 1.5},
]

const EQUIP := [
	{"id": "stapler",    "slot": "hand", "mods": {"atk": 4}},
	{"id": "headphones", "slot": "wear", "mods": {"hp": 20, "rate": 0.15}},
	{"id": "lanyard",    "slot": "wear", "mods": {"spd": 22}},
	{"id": "chair",      "slot": "desk", "mods": {"hp": 35}},
	{"id": "badge",      "slot": "desk", "mods": {"atk": 3, "rate": 0.25}},
	{"id": "coldbrew",   "slot": "hand", "mods": {"rate": 0.45, "hp": -10}},
]

const SKILLS := [
	{"id": "overtime", "mods": {"atk": 2}},
	{"id": "boundary", "mods": {"hp": 18}},
	{"id": "caffeine", "mods": {"rate": 0.2}},
	{"id": "sneakers", "mods": {"spd": 18}},
	{"id": "delegate", "mods": {}, "flag": "pierce"},
	{"id": "mute",     "mods": {}, "flag": "slowfoes"},
	{"id": "ccall",    "mods": {}, "flag": "multishot"},
]

const PARTY := [
	{"id": "intern", "after": "mon", "dps": 6,  "color": "#f4efe2"},
	{"id": "pm",     "after": "tue", "dps": 9,  "color": "#efeade"},
	{"id": "hr",     "after": "thu", "dps": 12, "color": "#f3eee3"},
]

const RANT := [
	{"id": "ok", "power": 10},
	{"id": "lie", "power": 25},
	{"id": "teach", "power": 40},
	{"id": "quit", "power": 60},
	{"id": "legend", "power": 90},
]


static func find(table: Array, id) -> Dictionary:
	for row in table:
		if row["id"] == id:
			return row
	return {}
