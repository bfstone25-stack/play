# -*- coding: utf-8 -*-
"""Flutter 故事引擎 — 让对话从"陪聊"变成"游戏"

核心分工:
  LLM 负责「怎么说」(自然对话、人格口吻)
  故事结构负责「发生什么」(章节推进、事件触发、分支抉择、结局判定)
"""
import json, os, glob

STORY_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stories")
_CACHE = {}


def load_story(route_id):
    """读取某角色的故事线，缓存"""
    if route_id in _CACHE:
        return _CACHE[route_id]
    p = os.path.join(STORY_DIR, f"{route_id}.json")
    if not os.path.exists(p):
        _CACHE[route_id] = None
        return None
    try:
        _CACHE[route_id] = json.load(open(p, encoding="utf-8"))
    except Exception:
        _CACHE[route_id] = None
    return _CACHE[route_id]


def has_story(route_id):
    return load_story(route_id) is not None


def current_chapter(story, aff, chapter_id=None):
    """按好感度定位当前章节（或按显式 id）"""
    chs = story.get("chapters", [])
    if chapter_id:
        for c in chs:
            if c["id"] == chapter_id:
                return c
    cur = chs[0] if chs else None
    for c in chs:
        if aff >= c.get("aff_gate", 0):
            cur = c
    return cur


def pending_beats(chapter, turns, aff, fired):
    """返回本轮该触发的 beats（尚未触发且条件已满足）"""
    out = []
    for b in chapter.get("beats", []):
        if b["id"] in fired:
            continue
        t = b.get("trigger", {})
        if turns < t.get("turns", 0):
            continue
        if aff < t.get("aff_min", 0):
            continue
        out.append(b)
    return out


def chapter_complete(chapter, aff):
    """是否达到章末抉择条件"""
    return aff >= chapter.get("exit_aff", 999)


def build_story_prompt(story, chapter, zh, fired_beats, active_beat=None):
    """生成注入 system prompt 的故事上下文"""
    if not story or not chapter:
        return ""
    L = "zh" if zh else "en"
    parts = []

    # 当前章节的场景与目标
    scene = chapter.get(f"scene_{L}", "")
    goal = chapter.get(f"goal_{L}", "")
    parts.append(f"[STORY CONTEXT] Chapter: {chapter.get('title_' + L, chapter['id'])}. Setting: {scene}.")
    if goal:
        parts.append(f"Her current objective in this chapter: {goal}. Do not state it — let it shape the scene.")

    # 已发生的剧情记忆（让模型知道故事走到哪了）
    happened = [b for b in chapter.get("beats", []) if b["id"] in fired_beats]
    if happened:
        recap = " ".join(b.get("event_en") or b.get("event_zh", "") for b in happened)
        parts.append(f"[ALREADY HAPPENED THIS CHAPTER] {recap}")

    # 本轮触发的事件 —— 这是"发生什么"的核心
    if active_beat:
        parts.append(f"[HAPPENING NOW] {active_beat.get('inject','')}")

    parts.append("Stay fully in character. Let the story move — do not just chat.")
    return "\n\n" + "\n".join(parts)


def advance(story, state, aff, turns):
    """推进故事状态。返回 (event_text, chapter, choice_or_None, new_state)

    state = {"chapter": "ch1", "fired": ["b1_call"], "flags": ["bold"], "choice_pending": False}
    """
    st = dict(state or {})
    st.setdefault("chapter", story["chapters"][0]["id"])
    st.setdefault("fired", [])
    st.setdefault("flags", [])

    ch = current_chapter(story, aff, st["chapter"])
    if not ch:
        return None, None, None, st
    # A cleared chapter waits for the player's explicit "next chapter" action.
    # This prevents a stray chat message from silently skipping the reward screen.
    if st.get("awaiting_continue"):
        return None, ch, None, st

    ids = [x["id"] for x in story["chapters"]]
    cleared = set(st.get("goal_cleared", []))

    # 触发 beat（一次只触发一个，避免信息过载）
    beats = pending_beats(ch, turns, aff, st["fired"])
    active = beats[0] if beats else None
    if active:
        st["fired"].append(active["id"])

    # 章末抉择
    choice = None
    is_final = ids.index(ch["id"]) == len(ids) - 1
    goal_ready = is_final or ch["id"] in cleared
    if chapter_complete(ch, aff) and goal_ready and not st.get("choice_done_" + ch["id"]):
        cs = ch.get("choices", [])
        if cs:
            choice = cs[0]

    return active, ch, choice, st


# ══════════════ 目标裁判层 (让"章节目标达成"才过关) ══════════════

def should_judge(story, state, aff):
    """是否该在本轮触发目标裁判：好感已达本章 exit_aff 门槛、但本章目标尚未判过关。
    返回 当前章对象(需裁判) 或 None。只在够格升级时才判，省LLM。"""
    st = state or {}
    cid = st.get("chapter", story["chapters"][0]["id"])
    ch = next((c for c in story["chapters"] if c["id"] == cid), None)
    if not ch:
        return None
    # 已是最后一章 → 不设过关闸（结局由 choice/flag 决定）
    ids = [x["id"] for x in story["chapters"]]
    if ids.index(cid) >= len(ids) - 1:
        return None
    if cid in set(st.get("goal_cleared", [])):
        return None                       # 已达成，不重复判
    if aff < ch.get("exit_aff", 999):
        return None                       # 好感还没到门槛，还不够格判
    return ch


def judge_prompt(ch, zh, history, message):
    """生成裁判 prompt：判玩家这一章的对话有没有达成本章目标。
    裁判只输出 YES / NO + 一句理由。"""
    goal = ch.get("goal_zh" if zh else "goal_en", "")
    convo = "\n".join(
        f"{'PLAYER' if m.get('role')=='user' else 'LOVE_INTEREST'}: {m.get('content','')}"
        for m in (history[-12:] + [{"role": "user", "content": message}])
    )
    if zh:
        sys = (f"你是乙女游戏的关卡裁判。本章目标：「{goal}」。\n"
               "阅读下面玩家(PLAYER)与男主(LOVE_INTEREST)的对话，判断玩家是否已经**真正达成了这个章节目标**"
               "（不是随便聊天，而是对话里确实发生了目标所描述的事）。\n"
               "只输出一行：先写 YES 或 NO，再用一句话说明理由。宁严勿松——没真正达成就 NO。")
    else:
        sys = (f"You are the level judge of an otome game. Chapter goal: \"{goal}\".\n"
               "Read the conversation between PLAYER and LOVE_INTEREST below and decide whether the player has "
               "**genuinely achieved this chapter's goal** (the thing the goal describes actually happened in the "
               "dialogue, not just idle chat).\n"
               "Output ONE line: start with YES or NO, then one sentence of reasoning. Be strict — if not truly achieved, say NO.")
    return sys, convo


def parse_judge(raw):
    """解析裁判输出 → (passed: bool, reason: str)"""
    t = (raw or "").strip()
    up = t.lstrip("\"'` ").upper()
    passed = up.startswith("YES")
    # 去掉开头的 YES/NO 留理由
    reason = t
    for p in ("YES", "NO", "Yes", "No", "yes", "no"):
        if t.strip().startswith(p):
            reason = t.strip()[len(p):].lstrip(" :：,-.。").strip()
            break
    return passed, reason


def mark_goal_cleared(state, chapter_id):
    st = dict(state or {})
    gc = list(st.get("goal_cleared", []))
    if chapter_id not in gc:
        gc.append(chapter_id)
    st["goal_cleared"] = gc
    return st


def apply_choice(story, state, chapter_id, choice_id, option_index, content_lang="zh"):
    """玩家做出选择后：记 flag、返回好感度增量与角色回应"""
    st = dict(state or {})
    ch = next((c for c in story["chapters"] if c["id"] == chapter_id), None)
    if not ch:
        return 0, "", st
    cs = next((c for c in ch.get("choices", []) if c["id"] == choice_id), None)
    if not cs or option_index >= len(cs.get("options", [])):
        return 0, "", st
    opt = cs["options"][option_index]
    flag = opt.get("flag")
    if flag:
        st.setdefault("flags", []).append(flag)
    st["choice_done_" + chapter_id] = True
    ids = [x["id"] for x in story.get("chapters", [])]
    if chapter_id in ids and ids.index(chapter_id) < len(ids) - 1:
        st["awaiting_continue"] = chapter_id
    reply = (opt.get(f"reply_{content_lang}") or opt.get("reply_en")
             or opt.get("reply_zh", ""))
    return opt.get("aff", 0), reply, st


def continue_story(story, state):
    """Advance exactly one chapter after the player claims the chapter reward."""
    st = dict(state or {})
    awaiting = st.get("awaiting_continue")
    ids = [x["id"] for x in story.get("chapters", [])]
    if awaiting not in ids:
        return st, None
    idx = ids.index(awaiting)
    if idx >= len(ids) - 1:
        st.pop("awaiting_continue", None)
        return st, None
    nxt = story["chapters"][idx + 1]
    st["chapter"] = nxt["id"]
    st["fired"] = []
    st.pop("awaiting_continue", None)
    return st, nxt


def match_ending(story, aff, flags):
    """按好感度与 flags 匹配结局（priority 小的优先）"""
    flags = set(flags or [])
    cands = []
    for e in story.get("endings", []):
        if aff < e.get("aff_min", 0):
            continue
        if "aff_max" in e and aff > e["aff_max"]:
            continue
        need_any = set(e.get("flags_any", []))
        if need_any and not (need_any & flags):
            continue
        need_all = set(e.get("flags_all", []))
        if need_all and not need_all.issubset(flags):
            continue
        cands.append(e)
    if not cands:
        # Every final choice must resolve. Authored low/bittersweet endings have
        # the largest priority and are the safe fallback for unmatched flags.
        endings = story.get("endings", [])
        return sorted(endings, key=lambda x: x.get("priority", 99))[-1] if endings else None
    return sorted(cands, key=lambda x: x.get("priority", 99))[0]


def story_progress(story, state, aff):
    """给前端的进度信息：第几章 / 共几章 / 章节名"""
    if not story:
        return None
    chs = story["chapters"]
    cid = (state or {}).get("chapter", chs[0]["id"])
    try:
        idx = [c["id"] for c in chs].index(cid)
    except ValueError:
        idx = 0
    ch = chs[idx]
    return {
        "chapter_index": idx + 1,
        "chapter_total": len(chs),
        "title_zh": ch.get("title_zh", ""),
        "title_en": ch.get("title_en", ""),
        "goal_zh": ch.get("goal_zh", ""),
        "goal_en": ch.get("goal_en", ""),
        "story_title_zh": story.get("title_zh", ""),
        "story_title_en": story.get("title_en", ""),
    }


def available_stories():
    return [os.path.basename(p)[:-5] for p in glob.glob(os.path.join(STORY_DIR, "*.json"))]
