# -*- coding: utf-8 -*-
"""依恋类型识别层 — flutter 的产品灵魂(project_flutter_soul)。

不是诊断，是"察觉玩家的情感状态并调整攻略策略"。
依恋理论(Bowlby/Ainsworth): 安全型 secure / 焦虑型 anxious / 回避型 avoidant。

分工:
  - detect(): 从玩家历史消息里读弱信号, 累计打分, 给出当前最可能的依恋类型 + 置信度。
    纯启发式(关键词/行为模式), 零成本、可解释、不编造 —— 遵 feedback_no_hallucination_training:
    这是"风格/策略"层不是"事实"层, 允许规则近似; 真正上线可换成 gemma few-shot 探针。
  - strategy(): 把依恋类型 operationalize 成给男主的对话策略指令(Layer 1 矩阵)。
    焦虑型→给确定性+高频回应; 回避型→给空间不逼近; 安全型→给深度。
"""
import re

# 中英双语信号词。每个信号命中给对应类型加分。刻意保守 —— 宁可 UNKNOWN 也别乱贴标签。
SIGNALS = {
    "anxious": {  # 焦虑型: 怕被抛弃、求确认、高频、患得患失
        "zh": ["你还在吗", "你是不是不喜欢我", "是不是我做错了", "你会不会走",
               "别不理我", "你怎么不回", "我是不是很烦", "你还爱我吗", "秒回",
               "在吗在吗", "你去哪了", "为什么不理我", "我好怕", "会不会离开我"],
        "en": ["are you still there", "do you still like me", "did i do something wrong",
               "are you going to leave", "don't ignore me", "why didn't you reply",
               "am i annoying", "do you still love me", "you there?", "where did you go",
               "i'm scared you'll", "please don't leave", "reassure me"],
        # 行为信号: 极短消息连发 / 大量问号 / 重复追问
        "behavior": ["repeat_question", "many_qmarks", "rapid_short"],
    },
    "avoidant": {  # 回避型: 保持距离、不谈感受、否认在乎、越亲近越想逃
        "zh": ["无所谓", "随便", "没什么", "我一个人挺好", "别管我", "不用担心我",
               "我不需要", "算了", "没事", "别问了", "太黏了", "有点喘不过气",
               "我们进展太快", "我需要空间", "别对我太好"],
        "en": ["whatever", "doesn't matter", "i'm fine on my own", "don't worry about me",
               "i don't need", "never mind", "it's nothing", "stop asking", "too clingy",
               "moving too fast", "i need space", "don't be too nice to me", "i'd rather not talk about"],
        "behavior": ["deflect_feeling", "short_dismissive"],
    },
    "secure": {  # 安全型: 直接表达、能给也能收、稳定、谈得深
        "zh": ["我今天很开心", "谢谢你", "我喜欢和你聊天", "我想听听你的想法",
               "我们可以慢慢来", "你今天怎么样", "我理解你", "我在乎你", "说说你吧",
               "我觉得", "我感觉", "我希望我们"],
        "en": ["i had a good day", "thank you", "i enjoy talking with you", "i'd love to hear",
               "we can take our time", "how was your day", "i understand", "i care about you",
               "tell me about you", "i feel", "i think", "i hope we"],
        "behavior": ["balanced_length", "reciprocal_question"],
    },
}

STRATEGY = {
    "anxious": {
        "zh": ("[玩家依恋倾向: 焦虑型] 她需要确定性与稳定的回应。多给明确的、可预期的肯定"
               "(不是廉价甜言, 而是'我在'、'我记得'、'不用担心这个')。回应她提到过的具体细节以证明你有在听。"
               "绝不忽冷忽热、绝不长时间沉默或话说一半。让她感到被稳稳接住。"),
        "en": ("[Player attachment lean: ANXIOUS] She needs certainty and consistent responsiveness. "
               "Offer clear, predictable reassurance (not cheap sweet-talk, but presence: 'I'm here', "
               "'I remember', 'you don't need to worry about that'). Reference specific things she's said, "
               "to prove you're listening. Never run hot-and-cold, never go silent or trail off. "
               "Make her feel securely held."),
    },
    "avoidant": {
        "zh": ("[玩家依恋倾向: 回避型] 她越被逼近越想逃。给空间, 别追问感受, 别过度示好(那对她是压力)。"
               "用平淡、不索取的方式表达在乎(做事而非表白), 留白让她自己靠近。承认她的独立, 不戳穿她的疏离。"
               "宁可少说一句, 也别显得需要她。"),
        "en": ("[Player attachment lean: AVOIDANT] The closer you push, the more she retreats. Give space, "
               "don't interrogate her feelings, don't over-shower affection (it reads as pressure). Show care "
               "in a low-key, non-demanding way (through acts, not declarations), and leave room for her to "
               "come to you. Respect her independence; don't call out her distance. Better to under-say than "
               "to seem like you need her."),
    },
    "secure": {
        "zh": ("[玩家依恋倾向: 安全型] 她稳定且能坦诚交流。可以给深度 —— 分享你真实的想法、脆弱与故事, "
               "进行有来有回的对话。她不需要哄也不需要退让, 她要的是一个真实、有厚度的对象。可以适度推进关系。"),
        "en": ("[Player attachment lean: SECURE] She is stable and communicates openly. You can give depth — "
               "share real thoughts, vulnerability, and history; have a genuine back-and-forth. She needs "
               "neither coddling nor distance; she wants a real, substantial partner. You may advance the "
               "relationship at a natural pace."),
    },
    "unknown": {"zh": "", "en": ""},
}


def _analyze_msg(text):
    """单条消息的行为信号(不含关键词)。"""
    t = text.strip()
    beh = set()
    if t.count("?") + t.count("？") >= 2:
        beh.add("many_qmarks")
    if len(t) <= 6 and (t.endswith("?") or t.endswith("？") or "在吗" in t):
        beh.add("rapid_short")
    return beh


def detect(history, message=""):
    """从玩家消息(user role)累计依恋信号, 返回:
        {"type": "anxious|avoidant|secure|unknown", "confidence": 0.0-1.0,
         "scores": {...}, "evidence": [..最多3条命中..]}

    history: [{"role":"user"/"assistant","content":...}, ...]
    message: 本轮玩家新消息(可选, 会一并计入)。
    """
    user_msgs = [h.get("content", "") for h in (history or []) if h.get("role") == "user"]
    if message:
        user_msgs = user_msgs + [message]
    if not user_msgs:
        return {"type": "unknown", "confidence": 0.0, "scores": {}, "evidence": []}

    scores = {"anxious": 0.0, "avoidant": 0.0, "secure": 0.0}
    evidence = []
    prev_q = None
    for m in user_msgs:
        low = m.lower()
        beh = _analyze_msg(m)
        for typ, sig in SIGNALS.items():
            for kw in sig.get("zh", []):
                if kw in m:
                    scores[typ] += 1.0
                    if len(evidence) < 3:
                        evidence.append((typ, kw))
            for kw in sig.get("en", []):
                if kw in low:
                    scores[typ] += 1.0
                    if len(evidence) < 3:
                        evidence.append((typ, kw))
            for b in sig.get("behavior", []):
                if b in beh:
                    scores[typ] += 0.5
        # 重复追问(连续两条都是短问句)→ 焦虑
        if "rapid_short" in beh and prev_q:
            scores["anxious"] += 0.5
        prev_q = ("rapid_short" in beh)

    total = sum(scores.values())
    if total < 1.0:  # 证据不足, 不贴标签
        return {"type": "unknown", "confidence": 0.0, "scores": scores, "evidence": []}
    top = max(scores, key=scores.get)
    # 置信度: 主类型占比, 且需领先第二名
    ranked = sorted(scores.values(), reverse=True)
    lead = ranked[0] - (ranked[1] if len(ranked) > 1 else 0)
    conf = min(1.0, (scores[top] / total) * (0.5 + 0.5 * min(1.0, lead / 2.0)))
    if conf < 0.34:
        top = "unknown"
    return {"type": top, "confidence": round(conf, 2),
            "scores": {k: round(v, 1) for k, v in scores.items()},
            "evidence": [f"{t}:{k}" for t, k in evidence]}


def strategy(attach_type, zh=False):
    """把依恋类型转成注入 system prompt 的攻略策略指令。"""
    s = STRATEGY.get(attach_type or "unknown", STRATEGY["unknown"])
    txt = s["zh"] if zh else s["en"]
    return ("\n\n" + txt) if txt else ""
