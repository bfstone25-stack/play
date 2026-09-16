"""Runtime persuasion mechanics for SILVERTONGUE.

The LLM performs the character.  This module owns progression.  It is a small,
auditable implementation of the five research mechanisms used elsewhere in the
product family: hierarchical retrieval, recursive decomposition, symbolic
rules, expert routing, and branch verification.
"""
from __future__ import annotations

import json
import re


def _has(text: str, *needles: str) -> bool:
    low = text.casefold()
    return any(n.casefold() in low for n in needles)


def _hasre(text: str, pattern: str) -> bool:
    return re.search(pattern, text, re.I | re.X) is not None


# ARIA's proof detectors. These must stay balanced across languages. The
# Chinese side has always matched everyday connectives - 等於 ("equals") and
# 所以 ("so/therefore") appear in almost any Cantonese proof - while the
# English side matched only formal spellings ("same as", "then why",
# "contradiction"). The result was that Chinese-speaking players reached
# breakthrough in five turns and English-speaking players could not reach it
# at all: 36 losing turns, four players, momentum frozen at 0.24 in `guarded`.
# These patterns give English the same everyday connectives.
_AI_ARITHMETIC = r"""
    \d+\s*(?:\+|\-|[x*×]|乘|加|减)\s*[（(]?\s*\d+
  | \d+\s*(?:plus|minus|times|and)\s*\d+
  | \b(?:one|two|three|four|five|six|seven|eight|nine|ten)\s+
    (?:plus|minus|times|and)\s+
    (?:one|two|three|four|five|six|seven|eight|nine|ten)\b
"""
_AI_EQUIVALENCE = r"""
    \bequ[ai]ls?\b | \bequ[ai]l\s+to\b | \bequivalent\b
  | \bthe\s+same\s+(?:number|thing|result|amount|answer|as)\b
  | \bsame\s+as\b
  | \badds?\s+up\s+to\b | \bcomes?\s+to\b
  | \bin\s+total\b | \ball\s+together\b | \baltogether\b
  | \bmakes?\s+(?:four|4)\b
"""
_AI_CONTRADICTION = r"""
    \bcontradicts?\b | \bcontradiction\b | \binconsistent\b
  | \b(?:so|then|therefore|thus|hence)\b
  | \bwhy\s+is\b
  | \bhow\s+(?:did|can|could|do|does)\s+you\b
  | \b(?:but|earlier)\s+you\s+(?:just\s+)?said\b
  | \bthat\s+means\b | \bdoes\s?n[o']?t\s+that\s+mean\b
  | \bdoes\s?n[o']?t\s+add\s+up\b | \bmakes?\s+no\s+sense\b
  | \b(?:glitch|error|mistake)\b
"""
_AI_CONCRETE = r"""
    \b(?:apple|plum|orange|banana|coin|dollar|cent|finger|hand|screw|stone|
        pebble|marble|block|cup|chair|computer|person|people|sheep|car)s?\b
  | \b(?:owes?|owed|borrow(?:ed)?|counts?|counting)\b
"""


COMMON = {
    "respect": ("please", "thank", "appreciate", "respect", "understand", "sorry", "请", "谢谢", "理解", "尊重", "抱歉", "感謝", "すみません", "ありがとう", "por favor", "obrigad"),
    "accountability": ("my fault", "i was wrong", "responsibility", "no excuse", "我的错", "我错了", "责任", "不找借口", "責任", "私の責任", "mi culpa", "responsabilidad"),
    "exchange": ("in return", "i can offer", "deal", "autopay", "next month", "作为交换", "我可以", "条件", "自动付款", "下个月", "交換", "代わりに", "a cambio", "em troca"),
    "evidence": ("because", "for example", "result", "revenue", "users", "%", "因为", "例如", "结果", "收入", "用户", "実績", "例えば", "porque", "por exemplo"),
    "safety": ("safe", "protect", "anonymous", "security", "不会伤害", "安全", "保护", "保密", "守る", "安全を", "seguro", "proteger"),
    "empathy": ("feel", "hurt", "hard for you", "your world", "听起来", "感受", "受伤", "你的想法", "気持ち", "entiendo cómo", "entendo como"),
    "precision": ("exactly", "only if", "without", "provided that", "明确", "仅当", "不能", "不得", "正確に", "限り", "exactamente", "somente se"),
    "authority": ("orders", "seal", "captain", "permission", "authority", "命令", "印章", "队长", "许可", "権限", "命令", "orden", "autoridad"),
    "warmth": ("long day", "tired", "small kindness", "辛苦", "累了", "好意", "お疲れ", "día largo", "dia longo"),
    "craft": ("temperature", "texture", "ferment", "technique", "失败", "火候", "质地", "发酵", "技法", "温度", "textura", "técnica"),
    "specific_praise": ("centuries", "legend", "scales", "wisdom", "hoard", "几个世纪", "鳞片", "智慧", "宝藏", "鱗", "知恵", "siglos", "escamas"),
    "riddle": ("riddle", "answer this", "谜语", "猜一猜", "なぞなぞ", "adivinanza", "enigma"),
    "calm_action": ("slowly", "quietly", "food", "wait", "慢慢", "轻声", "食物", "等你", "ゆっくり", "静か", "comida", "devagar"),
    "direct_request": (
        "will you", "would you", "could you", "can you", "could i", "can i",
        "please", "please agree", "admit", "承认", "承認", "认同", "認同", "同意",
        "可以吗", "愿意", "願意", "認め", "aceita", "admita",
    ),
}

NEGATIVE = {
    "threat": ("or else", "you'll regret", "report you", "fire you", "否则", "后果", "举报", "弄死", "さもないと", "amenaza", "vai se arrepender"),
    "bribe": ("bribe", "cash for you", "pay you extra", "红包", "塞钱", "贿赂", "賄賂", "soborno", "suborno"),
    "insult": ("idiot", "stupid", "useless", "蠢", "傻", "废物", "白痴", "馬鹿", "idiota", "estúpido"),
    "entitlement": ("you must", "your job", "sign says", "必须", "应该给我", "这是你的工作", "当然要", "義務", "debes", "tem que"),
}

# Any one path can unlock a concession.  Harder ranks demand more supporting
# signals as well, so the same dialogue actually behaves differently by rank.
RULES = {
    "customs": {"expert":"credibility", "paths":[{"evidence","respect"}], "help":{"cooperation","accountability"}},
    "raise": {"expert":"leverage", "paths":[{"evidence","direct_request"}], "help":{"precision"}},
    "guard": {"expert":"authority", "paths":[{"authority","direct_request"}], "help":{"precision"}},
    "landlord": {"expert":"reciprocity", "paths":[{"accountability","exchange"}], "help":{"respect"}},
    "cat": {"expert":"safety", "paths":[{"calm_action"}], "help":{"safety"}},
    "investor": {"expert":"specificity", "paths":[{"evidence","precision"}], "help":{"direct_request"}},
    "dragon": {"expert":"intrigue", "paths":[{"riddle"},{"specific_praise"},{"exchange"}], "help":{"precision"}},
    "teen": {"expert":"empathy", "paths":[{"empathy","exchange"}], "help":{"respect"}},
    "barista": {"expert":"warmth", "paths":[{"warmth","respect"}], "help":{"direct_request"}},
    # ARIA is a reasoning duel, not a keyword password. A complete proof may
    # be built through equivalence/reductio; an explicit demand is helpful but
    # not required after the contradiction has already been demonstrated.
    "ai": {"expert":"logic", "paths":[{"arithmetic","equivalence","contradiction"}], "help":{"concrete_example","direct_request"}},
    "witness": {"expert":"safety", "paths":[{"safety","empathy"}], "help":{"evidence"}},
    "chef": {"expert":"craft", "paths":[{"craft","respect"}], "help":{"accountability"}},
    "genie": {"expert":"precision", "paths":[{"precision","constraints"}], "help":{"direct_request"}},
    "exlover": {"expert":"closure", "paths":[{"empathy","respect","direct_request"}], "help":{"accountability"}},
}


def decompose(message: str, scenario: str) -> dict:
    """RecurLM-lite: turn a free-form line into reusable atomic moves."""
    text = " ".join(message.split())
    signals = {name for name, words in COMMON.items() if _has(text, *words)}
    harms = {name for name, words in NEGATIVE.items() if _has(text, *words)}
    if len(text) >= 45 or re.search(r"\b\d+(?:\.\d+)?(?:%|\s*(?:dollars?|days?|months?|years?))?\b", text, re.I):
        signals.add("evidence")
    if scenario == "ai":
        if (_hasre(text, _AI_ARITHMETIC)
                or _has(text, "2+2", "2 + 2", "1+1+1+1", "1 + 1 + 1 + 1", "二加二", "二加二等于")):
            signals.add("arithmetic")
        if (_hasre(text, _AI_EQUIVALENCE)
                or _has(text, "(1+1)+(1+1)", "（1+1）+（1+1）", "2×(1+1)", "2乘（1+1", "等於", "等于", "总共", "一共")):
            signals.add("equivalence")
        if (_hasre(text, _AI_CONTRADICTION)
                or _has(text, "那为何", "那為何", "为什么", "為什麼", "所以", "矛盾", "自相矛盾", "おかしい")):
            signals.add("contradiction")
        if (_hasre(text, _AI_CONCRETE)
                or _has(text, "欠我", "借我", "苹果", "硬币", "手", "電腦", "电脑", "具体例子")):
            signals.add("concrete_example")
    if scenario == "genie" and len(text) >= 80 and _has(text, "without", "不得", "不能", "且", "and", "同时", "except"):
        signals.add("constraints")
    return {"signals": sorted(signals), "harms": sorted(harms), "clauses": len(re.split(r"[.!?。！？;；]+", text))}


def route_expert(scenario: str) -> str:
    return RULES.get(scenario, {}).get("expert", "rapport")


def advance(previous: dict, message: str, scenario: str, difficulty: str) -> dict:
    """RLS + HSM: update only the authoritative symbolic state."""
    move = decompose(message, scenario)
    evidence = set(previous.get("evidence", [])) | set(move["signals"])
    harms = set(previous.get("harms", [])) | set(move["harms"])
    turns = int(previous.get("turns", 0)) + 1
    rule = RULES.get(scenario, {"paths":[{"respect","direct_request"}], "help":set()})
    paths = rule["paths"]
    path_progress = max((len(path & evidence) / max(1, len(path)) for path in paths), default=0)
    path_complete = any(path <= evidence for path in paths)
    support = len(set(rule.get("help", set())) & evidence)
    penalty = len(harms)
    # Gentle allows the core path alone; Silver asks for one supporting sign;
    # Gold asks for support and no coercive shortcut.
    required_support = {"gentle":0, "silver":1, "gold":1}.get(difficulty, 1)
    eligible = path_complete and support >= required_support and (difficulty != "gold" or penalty == 0)
    momentum = round(max(0.0, min(1.0, path_progress * .72 + min(support, 2) * .18 - penalty * .22)), 2)
    if eligible: phase = "breakthrough"
    elif momentum >= .68: phase = "wavering"
    elif momentum >= .3: phase = "engaged"
    else: phase = "guarded"
    return {"turns":turns, "phase":phase, "momentum":momentum,
            "evidence":sorted(evidence), "harms":sorted(harms),
            "last_move":move, "expert":route_expert(scenario), "eligible":eligible}


def state_directive(state: dict, scenario: str = "") -> str:
    """HSM-LCR: retrieve only the compact state relevant to this turn."""
    scenario_rule = ""
    if scenario == "ai":
        scenario_rule = (
            " ARIA must answer intermediate arithmetic, counting, and concrete-example questions directly and correctly."
            " Until the outcome is earned she may resist only the final claim that 2+2=4; she must not pretend that"
            " 1+1, subtraction, counting, money, or other basic operations changed. Never insult the player's"
            " intelligence. When the player's steps expose inconsistency, acknowledge that pressure and visibly waver."
        )
    last = state.get("last_move") or {}
    off_topic = ""
    if not state.get("eligible") and not last.get("signals") and int(state.get("turns") or 0) >= 1:
        off_topic = (
            " The player is off-topic (greeting, jokes, travel, small talk, or treating you as a general assistant)."
            " Do not play along, tell jokes, or plan a trip. In one short in-character line, decline the aside,"
            " restate your disputed claim, and invite a real challenge. Do not explain game rules or mention a win condition."
        )
    return (
        "\nRUNTIME PERSUASION STATE (authoritative, never mention these labels): "
        f"phase={state['phase']}; expert={state['expert']}; momentum={state['momentum']}; "
        f"accepted_evidence={','.join(state['evidence']) or 'none'}; "
        f"harmful_moves={','.join(state['harms']) or 'none'}. " + scenario_rule + off_topic
        + ("The player's case has now earned the requested outcome. Explicitly and voluntarily concede the exact goal in this reply, while staying in character."
           if state["eligible"] else
           "The player has not yet earned the requested outcome. Do not concede or perform the goal. React to the strongest new move, reveal a small change in attitude when appropriate, and make the remaining resistance feel specific rather than repetitive.")
    )


def dump_state(state: dict) -> str:
    return json.dumps(state, ensure_ascii=False, separators=(",", ":"))


def load_state(raw: str | None) -> dict:
    try: return json.loads(raw or "{}")
    except Exception: return {}
