## BMStrings — UI copy, ported from play/beat-monday/frontend/rpg/strings.js. en + zh-Hans
## ship together (PLAN.md locale rule). Never hardcode a user-visible string in a scene.
class_name BMStrings

const EN := {
	"brand": "BEAT THE MONDAY", "sub": "A WORK WEEK RPG",
	"start": "CLOCK IN", "cont": "RESUME WEEK", "locker": "DESK", "how": "HOW IT WORKS",
	"week": "WEEK {n}", "day_mon": "MONDAY", "day_tue": "TUESDAY", "day_wed": "WEDNESDAY",
	"day_thu": "THURSDAY", "day_fri": "FRIDAY",
	"boss_standup": "THE STANDUP", "boss_inbox": "THE INBOX", "boss_allhands": "THE ALL-HANDS",
	"boss_review": "THE REVIEW", "boss_deploy": "THE FRIDAY DEPLOY",
	"brief_mon": "Nine minutes, nine people, no decisions. Stay alive until it ends.",
	"brief_tue": "It filled up overnight. It is still filling up.",
	"brief_wed": "You stop being polite. Every phrase you have ever swallowed comes back out as ammunition.",
	"brief_thu": "They have a document about you. You did not write it.",
	"brief_fri": "Someone shipped at 5pm. The pagers are yours now.",
	"go": "GO", "back": "BACK", "drag": "Drag to move. You attack on your own.",
	"lvup": "LEVEL {n}", "pick": "PICK ONE",
	"sk_overtime": "Spite", "skd_overtime": "+2 attack",
	"sk_boundary": "A Boundary", "skd_boundary": "+18 max HP",
	"sk_caffeine": "Cold Brew", "skd_caffeine": "attack faster",
	"sk_sneakers": "Sneakers", "skd_sneakers": "move faster",
	"sk_delegate": "Delegate", "skd_delegate": "attacks pierce",
	"sk_mute": "Mute Thread", "skd_mute": "everything slows",
	"sk_ccall": "CC Everyone", "skd_ccall": "one more projectile",
	"eq_stapler": "Stapler", "eq_headphones": "Noise-Cancelling Headphones",
	"eq_lanyard": "Lanyard", "eq_chair": "Ergonomic Chair", "eq_badge": "Door Badge",
	"eq_coldbrew": "Cold Brew",
	"slot_hand": "IN HAND", "slot_desk": "AT THE DESK", "slot_wear": "WORN",
	"pt_intern": "Riley, intern", "pt_pm": "Morgan, PM", "pt_hr": "Pat, HR",
	"cleared": "DAY CLEARED", "dead": "YOU WENT HOME EARLY", "retry": "TRY THE DAY AGAIN",
	"got": "Picked up: {item}", "joined": "{who} has your back now",
	"weekend": "IT IS SATURDAY", "weekend_body": "The week is over. Nothing is on fire. Next week starts harder.",
	"nextweek": "START WEEK {n}", "stats": "LV {lv} · HP {hp} · ATK {atk} · RATE {rate}",
	"rant_hint": "Your rant is the weapon. Pick up new lines.",
	"equipped": "WORN", "tap_equip": "tap to equip / remove", "party": "YOUR PEOPLE", "nobody": "Nobody yet. Clear a day.",
	"boss": "BOSS", "left": "{s}s", "kills": "{n} handled", "lang": "中文",
	"empty_desk": "Nothing on the desk yet. Bosses drop things.",
}

const ZH := {
	"brand": "打爆周一", "sub": "一周工作制 RPG",
	"start": "上班", "cont": "继续这一周", "locker": "工位", "how": "怎么玩",
	"week": "第 {n} 周", "day_mon": "周一", "day_tue": "周二", "day_wed": "周三",
	"day_thu": "周四", "day_fri": "周五",
	"boss_standup": "站会", "boss_inbox": "收件箱", "boss_allhands": "全员大会",
	"boss_review": "绩效面谈", "boss_deploy": "周五上线",
	"brief_mon": "九分钟，九个人，没有结论。活到散会。",
	"brief_tue": "一夜之间堆满了。现在还在堆。",
	"brief_wed": "你不再客气。咽下去的每一句话，这次都打出去。",
	"brief_thu": "关于你的文档已经写好了。不是你写的。",
	"brief_fri": "有人下午五点上线。告警归你了。",
	"go": "开始", "back": "返回", "drag": "拖动移动，攻击自动。",
	"lvup": "等级 {n}", "pick": "选一个",
	"sk_overtime": "怨气", "skd_overtime": "攻击 +2",
	"sk_boundary": "边界感", "skd_boundary": "血上限 +18",
	"sk_caffeine": "冰美式", "skd_caffeine": "攻速提升",
	"sk_sneakers": "球鞋", "skd_sneakers": "移速提升",
	"sk_delegate": "甩锅", "skd_delegate": "子弹穿透",
	"sk_mute": "免打扰", "skd_mute": "全场变慢",
	"sk_ccall": "全员抄送", "skd_ccall": "多一发",
	"eq_stapler": "订书机", "eq_headphones": "降噪耳机",
	"eq_lanyard": "工牌绳", "eq_chair": "人体工学椅", "eq_badge": "门禁卡",
	"eq_coldbrew": "冷萃",
	"slot_hand": "手上", "slot_desk": "桌上", "slot_wear": "身上",
	"pt_intern": "实习生 小瑞", "pt_pm": "产品 摩根", "pt_hr": "HR 小帕",
	"cleared": "今天挺过去了", "dead": "你提前下班了", "retry": "重来这一天",
	"got": "获得：{item}", "joined": "{who} 站你这边了",
	"weekend": "周六了", "weekend_body": "这一周结束了。没有起火。下周更难。",
	"nextweek": "开始第 {n} 周", "stats": "等级 {lv} · 血 {hp} · 攻 {atk} · 攻速 {rate}",
	"rant_hint": "发疯就是武器。捡起新句子。",
	"equipped": "已装备", "tap_equip": "点一下装备／卸下", "party": "你的人", "nobody": "还没有人。先挺过一天。",
	"boss": "BOSS", "left": "{s}秒", "kills": "处理了 {n} 个", "lang": "EN",
	"empty_desk": "桌上还什么都没有。BOSS 会掉东西。",
}


static func t(key: String, vars: Dictionary = {}) -> String:
	var bank: Dictionary = ZH if Game.lang == "zh" else EN
	var s: String = bank.get(key, EN.get(key, key))
	for k in vars:
		s = s.replace("{" + k + "}", str(vars[k]))
	return s
