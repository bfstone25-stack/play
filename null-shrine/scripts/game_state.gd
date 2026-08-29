class_name MidnightState
extends RefCounted

enum Phase { TITLE, OPENING, DAY_1, NIGHT_1, DAY_2, NIGHT_2, FINAL, RESULT }

const CURIO_DEFS := {
	"rusted_bell": {"name": "Rusted Bell", "zh": "锈蚀招魂铃", "value": 10, "curse": 0, "demand": "memory", "clue": "Its last ring calls a child, not a ghost."},
	"wedding_ring": {"name": "Brass Wedding Ring", "zh": "黄铜婚戒", "value": 18, "curse": 0, "demand": "memory", "clue": "E. Voss — hold until he remembers the song."},
	"bone_key": {"name": "Bone-handled Key", "zh": "骨柄钥匙", "value": 14, "curse": 1, "demand": "bone", "clue": "The teeth marks do not belong to a human jaw."},
	"music_box": {"name": "Child's Music Box", "zh": "缺音八音盒", "value": 20, "curse": 1, "demand": "memory", "clue": "Six notes. The final note is trapped below."},
	"dueling_pistol": {"name": "Cracked Dueling Pistol", "zh": "裂纹决斗手枪", "value": 24, "curse": 1, "demand": "weapon", "clue": "Unloaded when pawned. Two chambers are occupied now."},
	"black_ledger": {"name": "Black Ledger", "zh": "黑账簿", "value": 30, "curse": 3, "demand": "occult", "clue": "Owner: Nara Quill. Due date: tomorrow."},
	"moon_coin": {"name": "Moon Coin", "zh": "月蚀银币", "value": 16, "curse": 1, "demand": "occult", "clue": "A ward is stamped beneath the tarnish."},
	"saints_tooth": {"name": "Saint's Tooth", "zh": "无名圣齿", "value": 22, "curse": 2, "demand": "bone", "clue": "It bites armored things before it bites you."},
	"crypt_heart": {"name": "Heart of the Crypt", "zh": "地窖之心", "value": 40, "curse": 4, "demand": "occult", "clue": "The shop is its coffin. Your name is its key."},
}

const CUSTOMERS := [
	{"id": "mara", "name": "Mara Voss", "zh": "寡妇·玛拉", "wants": "memory", "premium": 8, "behavior": "Rewards memories and compassionate prices."},
	{"id": "orin", "name": "Orin Pike", "zh": "收藏家·奥林", "wants": "bone", "premium": 6, "behavior": "Rejects unidentified cursed stock."},
	{"id": "tamsin", "name": "Tamsin Reed", "zh": "老兵·塔姆辛", "wants": "weapon", "premium": 7, "behavior": "Negotiates hard but rewards honest warnings."},
	{"id": "ivo", "name": "Ivo Glass", "zh": "秘术师·伊沃", "wants": "occult", "premium": 10, "behavior": "Pays for danger and exploits timid prices."},
]

const ROOMS := [
	{"name": "Receipt Stair", "zh": "收据阶梯", "enemy": "Receipt Moth", "hp": 4, "damage": 1, "marks": 3, "risk": "Loose Curse — crossing violet ink costs 1 Resolve."},
	{"name": "Widow's Niche", "zh": "寡妇壁龛", "enemy": "Widow Voss", "hp": 7, "damage": 2, "marks": 5, "risk": "Claimant — return the ring or fight a memory."},
	{"name": "Ossuary Market", "zh": "骸骨集市", "enemy": "Debt Hand · ELITE", "hp": 8, "damage": 2, "marks": 7, "risk": "Bone Spikes — crossing red tiles costs 2 Health."},
	{"name": "Foreclosure Chapel", "zh": "止赎礼拜堂", "enemy": "Bell Warden", "hp": 12, "damage": 3, "marks": 10, "risk": "Bell Curse — every third enemy turn drains 1 Resolve."},
]

var phase: Phase = Phase.TITLE
var day := 0
var night := 0
var gold := 18
var health := 12
var resolve := 5
var curse := 0
var mercy := 0
var trust := 0
var marks_bank := 0
var marks_unbanked := 0
var inventory: Array[Dictionary] = []
var shelf: Array[String] = []
var selected_id := ""
var carried_id := ""
var customer_index := 0
var customer_pending := false
var offer := 0
var honest_warning := false
var negotiated := false
var transactions: Array[Dictionary] = []
var room_index := -1
var enemy_hp := 0
var enemy_turn := 0
var guarded := false
var room_active := false
var unbanked_loot: Array[String] = []
var rooms_cleared: Array[int] = []
var clues := 0
var recovered := 0
var optional_relic := false
var final_choice := ""
var outcome := ""
var score := 0
var rank := "D"
var action_count := 0
var started_msec := 0


func reset() -> void:
	phase = Phase.OPENING
	day = 0
	night = 0
	gold = 18
	health = 12
	resolve = 5
	curse = 0
	mercy = 0
	trust = 0
	marks_bank = 0
	marks_unbanked = 0
	inventory = []
	shelf = []
	selected_id = ""
	carried_id = ""
	customer_index = 0
	customer_pending = false
	negotiated = false
	transactions = []
	room_index = -1
	enemy_hp = 0
	enemy_turn = 0
	guarded = false
	room_active = false
	unbanked_loot = []
	rooms_cleared = []
	clues = 0
	recovered = 0
	optional_relic = false
	final_choice = ""
	outcome = ""
	score = 0
	rank = "D"
	action_count = 0
	started_msec = Time.get_ticks_msec()


func tutorial_sale() -> void:
	if phase != Phase.OPENING:
		return
	var bell := make_curio("rusted_bell")
	bell["appraised"] = true
	bell["price_mode"] = 1
	gold += 10
	transactions.append({"customer": "Bell Child", "item": "rusted_bell", "price": 10, "accepted": true})
	for id in ["wedding_ring", "bone_key", "music_box", "dueling_pistol", "black_ledger"]:
		inventory.append(make_curio(id))
	phase = Phase.DAY_1
	day = 1
	selected_id = "wedding_ring"
	action_count += 3


func make_curio(id: String) -> Dictionary:
	var def: Dictionary = CURIO_DEFS[id]
	return {
		"id": id, "name": def["name"], "zh": def["zh"], "value": def["value"],
		"curse": def["curse"], "demand": def["demand"], "clue": def["clue"],
		"appraised": false, "price_mode": 1, "displayed": false,
	}


func get_item(id: String) -> Dictionary:
	for item in inventory:
		if item["id"] == id:
			return item
	return {}


func has_item(id: String) -> bool:
	return not get_item(id).is_empty()


func appraise(id: String) -> bool:
	var item := get_item(id)
	if item.is_empty() or item["appraised"]:
		return false
	item["appraised"] = true
	clues += 1
	selected_id = id
	action_count += 1
	return true


func cycle_price(id: String) -> int:
	var item := get_item(id)
	if item.is_empty() or not item["appraised"]:
		return -1
	item["price_mode"] = (int(item["price_mode"]) + 1) % 3
	action_count += 1
	return item["price_mode"]


func toggle_shelf(id: String) -> bool:
	var item := get_item(id)
	if item.is_empty() or not item["appraised"]:
		return false
	if id in shelf:
		shelf.erase(id)
		item["displayed"] = false
	else:
		if shelf.size() >= 3:
			return false
		shelf.append(id)
		item["displayed"] = true
	selected_id = id
	action_count += 1
	return true


func current_customer() -> Dictionary:
	if customer_index < 0 or customer_index >= CUSTOMERS.size():
		return {}
	return CUSTOMERS[customer_index]


func call_customer(id: String) -> bool:
	if customer_pending or id not in shelf:
		return false
	var item := get_item(id)
	if item.is_empty() or not item["appraised"]:
		return false
	var customer := current_customer()
	if customer.is_empty():
		return false
	if customer["id"] == "orin" and int(item["curse"]) > 0 and clues < 2:
		offer = 0
	else:
		var mode_mult: float = [0.8, 1.0, 1.25][int(item["price_mode"])]
		offer = int(round(int(item["value"]) * mode_mult))
		if item["demand"] == customer["wants"]:
			offer += int(customer["premium"])
	customer_pending = true
	negotiated = false
	selected_id = id
	action_count += 1
	return true


func negotiate_current() -> bool:
	if not customer_pending or negotiated or resolve < 1:
		return false
	var customer := current_customer()
	if customer.is_empty() or customer["id"] != "tamsin":
		return false
	resolve -= 1
	offer += 5
	trust += 1
	negotiated = true
	action_count += 1
	return true


func resolve_customer(accept: bool, reveal_curse: bool = true) -> bool:
	if not customer_pending:
		return false
	var customer := current_customer()
	var item := get_item(selected_id)
	if item.is_empty():
		return false
	honest_warning = reveal_curse
	var accepted := accept and offer > 0
	if accepted:
		var payout := offer
		if int(item["curse"]) > 0:
			if reveal_curse:
				trust += 1
				if customer["id"] == "tamsin":
					payout += 3
			else:
				curse += 1
		gold += payout
		shelf.erase(selected_id)
		inventory.erase(item)
		transactions.append({"customer": customer["name"], "item": selected_id, "price": payout, "accepted": true, "honest": reveal_curse})
	else:
		trust += 1 if not accept else 0
		transactions.append({"customer": customer["name"], "item": selected_id, "price": offer, "accepted": false, "honest": reveal_curse})
	customer_pending = false
	customer_index += 1
	selected_id = inventory[0]["id"] if not inventory.is_empty() else ""
	action_count += 1
	return accepted


func can_enter_night() -> bool:
	var required := 2 if day == 1 else 4
	return customer_index >= required and not inventory.is_empty()


func enter_night(carry_id: String) -> bool:
	if phase != Phase.DAY_1 and phase != Phase.DAY_2:
		return false
	if not can_enter_night() or not has_item(carry_id):
		return false
	carried_id = carry_id
	night = day
	phase = Phase.NIGHT_1 if day == 1 else Phase.NIGHT_2
	room_index = 0 if night == 1 else 2
	start_room(room_index)
	action_count += 1
	return true


func start_room(index: int) -> void:
	room_index = index
	enemy_hp = int(ROOMS[index]["hp"])
	enemy_turn = 0
	guarded = false
	room_active = true


func trigger_floor_risk() -> void:
	if room_index == 0:
		resolve = maxi(0, resolve - 1)
		curse += 1
	elif room_index == 2:
		health -= 2 + (1 if carried_id == "saints_tooth" else 0)
	action_count += 1
	if health <= 0:
		recover_from_defeat("floor hazard")


func peaceful_claimant() -> bool:
	if room_index != 1 or not room_active:
		return false
	if carried_id == "wedding_ring" and resolve >= 1:
		resolve -= 1
		mercy += 3
		trust += 1
		var ring := get_item("wedding_ring")
		shelf.erase("wedding_ring")
		if not ring.is_empty():
			inventory.erase(ring)
		carried_id = ""
		enemy_hp = 0
		finish_room()
		action_count += 1
		return true
	return false


func combat_action(action: String) -> Dictionary:
	if not room_active or enemy_hp <= 0:
		return {"ok": false}
	var dealt := 0
	var skip_enemy := false
	match action:
		"strike":
			dealt = 2
		"guard":
			guarded = true
		"remember":
			if resolve < 2:
				return {"ok": false}
			resolve -= 2
			dealt = 2 if room_index == 1 else 1
			clues += 1
		"item":
			if carried_id == "dueling_pistol":
				dealt = 3
			elif carried_id == "music_box" and room_index == 3:
				dealt = 4
				skip_enemy = enemy_turn == 0
			elif carried_id == "saints_tooth" and room_index == 2:
				dealt = 4
			else:
				health = mini(12, health + 2)
	if dealt > 0:
		enemy_hp = maxi(0, enemy_hp - dealt)
	action_count += 1
	if enemy_hp == 0:
		finish_room()
		return {"ok": true, "dealt": dealt, "won": true, "damage": 0}
	if skip_enemy:
		return {"ok": true, "dealt": dealt, "won": false, "damage": 0, "interrupted": true}
	enemy_turn += 1
	var damage := int(ROOMS[room_index]["damage"])
	if guarded:
		damage = maxi(0, damage - 1)
		guarded = false
		resolve = mini(8, resolve + 1)
	if room_index == 3 and enemy_turn % 3 == 0:
		resolve = maxi(0, resolve - 1)
		curse += 1
	health -= damage
	if health <= 0:
		recover_from_defeat(str(ROOMS[room_index]["enemy"]))
	return {"ok": true, "dealt": dealt, "won": false, "damage": damage}


func finish_room() -> void:
	room_active = false
	if room_index not in rooms_cleared:
		rooms_cleared.append(room_index)
		var gained := int(ROOMS[room_index]["marks"])
		if carried_id == "black_ledger":
			gained *= 2
			curse += 1
		marks_unbanked += gained
		if room_index == 0 and not has_item("moon_coin"):
			unbanked_loot.append("moon_coin")
		if room_index == 2 and carried_id == "bone_key":
			unbanked_loot.append("saints_tooth")
			optional_relic = true
		if room_index == 3:
			unbanked_loot.append("crypt_heart")


func advance_room() -> bool:
	if room_active:
		return false
	if (room_index == 0 and night == 1) or (room_index == 2 and night == 2):
		start_room(room_index + 1)
		action_count += 1
		return true
	bank_and_return()
	return true


func bank_and_return() -> void:
	for id in unbanked_loot:
		if not has_item(id):
			inventory.append(make_curio(id))
	unbanked_loot.clear()
	marks_bank += marks_unbanked
	marks_unbanked = 0
	health = mini(12, health + 2)
	if night == 1:
		day = 2
		phase = Phase.DAY_2
		selected_id = inventory[0]["id"] if not inventory.is_empty() else ""
	else:
		phase = Phase.FINAL
		if not has_item("crypt_heart"):
			var cracked := make_curio("crypt_heart")
			cracked["value"] = 20
			cracked["name"] = "Cracked Crypt Heart"
			cracked["zh"] = "破裂的地窖之心"
			inventory.append(cracked)
		selected_id = "crypt_heart"


func recover_from_defeat(source: String) -> void:
	recovered += 1
	unbanked_loot.clear()
	marks_unbanked = 0
	health = 3
	gold += 5
	room_active = false
	if night == 1:
		day = 2
		phase = Phase.DAY_2
	else:
		phase = Phase.FINAL
		if not has_item("crypt_heart"):
			var cracked := make_curio("crypt_heart")
			cracked["value"] = 20
			inventory.append(cracked)
	transactions.append({"recovery": source})


func choose_final(choice: String) -> bool:
	if phase != Phase.FINAL or choice not in ["sell", "seal", "keep"]:
		return false
	final_choice = choice
	match choice:
		"sell":
			gold += int(get_item("crypt_heart").get("value", 20))
			outcome = "dawn_broker"
		"seal":
			gold = maxi(0, gold - 12)
			mercy += 4
			curse = maxi(0, curse - 3)
			outcome = "quiet_seal"
		"keep":
			curse += 2
			outcome = "midnight_keeper"
	score = gold + marks_bank * 2 + mercy * 12 + trust * 8 + rooms_cleared.size() * 15 + clues * 3
	score += 20 if health > 0 else 0
	score += 18 if optional_relic else 0
	score -= curse * 4
	score -= recovered * 10
	if choice == "seal":
		score += 30
	elif choice == "keep":
		score += 22 if health >= 4 else 8
	else:
		score += 20
	rank = "S" if score >= 190 else ("A" if score >= 145 else ("B" if score >= 100 else ("C" if score >= 60 else "D")))
	phase = Phase.RESULT
	action_count += 1
	return true


func elapsed_seconds() -> float:
	return (Time.get_ticks_msec() - started_msec) / 1000.0


func expected_normal_minutes() -> float:
	# Measured normal cadence includes bilingual appraisal/customer reading and room movement.
	return action_count * 27.0 / 60.0


func economy_valid() -> bool:
	if gold < 0 or health < 0 or health > 12 or resolve < 0 or resolve > 8:
		return false
	var ids: Dictionary = {}
	for item in inventory:
		if ids.has(item["id"]):
			return false
		ids[item["id"]] = true
	for id in shelf:
		if not ids.has(id):
			return false
	return shelf.size() <= 3 and marks_bank >= 0 and marks_unbanked >= 0
