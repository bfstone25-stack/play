"""Auditable runtime reasoning for Flutter.

The language model is an actor.  This module owns conversational intent,
relationship temperature, allowed context, memory validation and candidate
verification.  The design adapts Tell's HSM-LCR, RLS, BV-ToT, Social-MoE and
Titans mechanisms to a relationship RPG.
"""
from __future__ import annotations

import json
import re
import time
from dataclasses import dataclass, asdict


INTENT_TERMS = {
    "boundary": ("别碰", "别这样", "不舒服", "停下", "go away", "please stop", "stop it", "stop touching", "don't touch", "やめて", "触らない", "déjame", "para con eso", "pare com isso", "não me toque"),
    "distress": ("难过", "害怕", "失败", "崩溃", "孤独", "睡不着", "sad", "afraid", "failed", "lonely", "can't sleep", "悲しい", "怖い", "寂しい", "triste", "sozinho"),
    "conflict": ("生气", "骗我", "讨厌你", "为什么不理", "angry", "lied", "hate you", "ignored me", "怒って", "嘘", "odio", "mentiu"),
    "repair": ("对不起", "原谅", "和好", "抱歉", "sorry", "forgive", "make it right", "ごめん", "perdón", "desculpa"),
    "commitment": ("明天", "下次", "约好", "答应", "见面", "一起去", "tomorrow", "next time", "promise", "meet", "明日", "約束", "mañana", "amanhã"),
    "flirt": ("喜欢你", "想你", "心动", "亲你", "抱你", "love you", "miss you", "kiss", "好き", "会いたい", "te quiero", "saudade"),
    "care": ("辛苦", "休息", "吃饭了吗", "照顾", "take care", "get some rest", "大丈夫", "休んで", "descansa", "cuídate"),
    "factual": ("谁是", "多少", "哪本书", "是真的吗", "里有", "作者", "谁写的", "多少回", "who is", "how many", "is it true", "fact", "correct", "author", "誰", "何巻", "作者", "quién", "quantos"),
    "preference": ("喜欢什么", "最喜欢", "不喜欢", "favorite", "prefer", "好きな", "好み", "favorito", "prefere"),
    "deep_talk": ("为什么", "你觉得", "梦想", "童年", "害怕什么", "意义", "学会", "why", "what do you think", "dream", "childhood", "meaning", "learn", "どう思う", "夢", "学ん", "por qué", "aprend", "sonho", "aprendeu"),
    "humor": ("哈哈", "笑死", "开玩笑", "haha", "kidding", "冗談", "jaja", "brincadeira"),
}

HIGH_RISK = {"boundary", "distress", "conflict", "factual"}
TEMPERATURES = {"steady", "approaching", "hesitant", "tense", "repairing"}


@dataclass
class Decision:
    intent: str
    confidence: float
    temperature: str
    risk: str
    evidence: list[str]


def _market(lang: str) -> str:
    low = (lang or "en").lower()
    for key in ("zh", "ja", "es", "pt"):
        if low.startswith(key):
            return key
    return "en"


def route_intent(message: str, previous_temperature: str = "steady") -> Decision:
    text = (message or "").strip()
    low = text.casefold()
    scores = {}
    evidence = []
    for intent, terms in INTENT_TERMS.items():
        hits = [term for term in terms if term.casefold() in low]
        if hits:
            scores[intent] = len(hits)
            evidence.extend(f"{intent}:{h}" for h in hits[:2])
    priority = ("boundary", "repair", "conflict", "factual", "deep_talk", "distress", "commitment", "preference", "care", "flirt", "humor", "general")
    intent = min(scores, key=lambda k: (-scores[k], priority.index(k))) if scores else "general"
    confidence = min(.98, .52 + .14 * scores.get(intent, 0)) if scores else .35
    if intent in {"boundary", "conflict"}:
        temperature = "tense"
    elif intent == "repair" or previous_temperature == "tense" and intent in {"care", "deep_talk"}:
        temperature = "repairing"
    elif intent in {"flirt", "care", "commitment"}:
        temperature = "approaching"
    elif intent in {"distress", "factual"}:
        temperature = "hesitant"
    else:
        temperature = previous_temperature if previous_temperature in TEMPERATURES else "steady"
    return Decision(intent, confidence, temperature,
                    "high" if intent in HIGH_RISK else "normal", evidence[:5])


def relation_instruction(stage: str, temperature: str, intent: str, market: str) -> str:
    instruction = {
        "steady": "Keep the relationship at its current pace; respond with substance rather than decorative gestures.",
        "approaching": "Allow one natural sign of closeness, calibrated to the relationship stage; do not jump ahead.",
        "hesitant": "Slow down, clarify uncertainty, and avoid pretending to know facts or feelings you cannot know.",
        "tense": "Stop flirtation. Acknowledge the player's boundary or grievance directly; do not punish, guilt, pursue, or romanticize conflict.",
        "repairing": "Address the specific rupture, take proportionate responsibility, and let trust recover gradually rather than declaring everything fixed.",
    }[temperature]
    special = {
        "factual": "For factual questions, answer only when reasonably certain. If uncertain, say so and ask what the player meant; never fabricate titles, people, events, or numbers.",
        "distress": "Lead with grounded empathy. Do not diagnose, trivialize, turn pain into flirting, or make yourself the center.",
        "commitment": "If a concrete future plan is proposed, confirm its exact known details once and treat it as a potential memory.",
        "boundary": "Respect the boundary immediately and plainly. Do not add seductive stage directions.",
    }.get(intent, "")
    cultural = {
        "zh": "Use contemporary natural Chinese. Prefer precise lived detail to ornate otome narration.",
        "ja": "Use contemporary Japanese with restraint, subtext, and natural pauses; avoid translated Chinese or generic anime speech.",
        "es": "Use natural international Spanish with lively but adult warmth.",
        "pt": "Use natural Brazilian Portuguese with relaxed warmth and conversational rhythm.",
        "en": "Use natural adult English with wit and emotional specificity.",
    }[market]
    return f"[RUNTIME RELATION STATE] stage={stage}; temperature={temperature}; intent={intent}. {instruction} {special} {cultural}"


def retrieve_context(route, story, chapter, memories, active_beat=None):
    """HSM-LCR/RLS: only authored route/story facts and validated memories."""
    layers = []
    if route:
        layers.append({"layer": "character", "text": route.get("persona", "")})
        scene = route.get("scene_en") or route.get("scene_zh") or route.get("scene", "")
        if scene:
            layers.append({"layer": "scene", "text": scene})
    if story:
        layers.append({"layer": "story", "text": story.get("logline_en") or story.get("logline_zh", "")})
    if chapter:
        layers.append({"layer": "chapter", "text": chapter.get("scene_en") or chapter.get("scene_zh", "")})
        layers.append({"layer": "goal", "text": chapter.get("goal_en") or chapter.get("goal_zh", "")})
    if active_beat:
        layers.append({"layer": "active_beat", "text": active_beat.get("inject", "")})
    for fact in memories[:6]:
        layers.append({"layer": "player_memory", "text": fact})
    return [x for x in layers if x["text"]]


def extract_memory_candidates(message: str, market: str):
    """Conservative deterministic extraction for promises and explicit preferences."""
    text = re.sub(r"\s+", " ", (message or "").strip())
    if not 4 <= len(text) <= 180:
        return []
    d = route_intent(text)
    if d.intent not in {"commitment", "preference"}:
        return []
    if d.intent == "preference":
        first_person = {
            "zh": ("我喜欢", "我最喜欢", "我不喜欢", "我的最爱", "我偏爱"),
            "ja": ("私は", "私が好き", "僕は", "嫌い"),
            "en": ("i like", "i love", "i prefer", "my favorite", "i dislike"),
            "es": ("me gusta", "prefiero", "mi favorito", "no me gusta"),
            "pt": ("eu gosto", "prefiro", "meu favorito", "não gosto"),
        }[market]
        if not any(x in text.casefold() for x in first_person):
            return []
    # Store the player's actual wording, not an LLM-invented paraphrase.
    return [{"fact": text, "kind": d.intent, "confidence": .82,
             "source": "player_explicit", "created": time.time()}]


def verify_candidate(reply: str, market: str, recent_replies, decision: Decision,
                     source_message: str = "", allowed_memories: bool = False):
    """BV-ToT verifier. Returns (ok, reasons)."""
    text = (reply or "").strip()
    reasons = []
    if not text:
        reasons.append("empty")
    if len(text) > 520:
        reasons.append("too_long")
    if market in {"zh", "ja"} and re.search(r"\*[A-Za-z][^*]{0,100}\*", text):
        reasons.append("english_stage_direction")
    if market == "zh" and len(re.findall(r"\b[A-Za-z]{3,}\b", text)) >= 2:
        reasons.append("language_leak")
    if len(re.findall(r"轻轻|微微|目光|温柔", text)) >= 3:
        reasons.append("ornate_template_spam")
    if not allowed_memories and re.search(
            r"上次你|你(?:曾经|之前)?(?:说过|提过|告诉过我)|你留下的|I remember you|you told me|you (?:have|'ve) mentioned|last time you|前に君が|前にあなたが|me dijiste|você me disse",
            text, re.I):
        reasons.append("invented_memory")
    normalized = re.sub(r"\W+", "", text.casefold())
    for old in (recent_replies or [])[-4:]:
        old_n = re.sub(r"\W+", "", str(old).casefold())
        if normalized and old_n and (normalized == old_n or
                len(normalized) > 18 and normalized[:18] == old_n[:18]):
            reasons.append("repetitive_reply")
            break
    if decision.intent == "boundary" and any(x in text for x in ("亲", "抱紧", "不许走", "kiss", "hold you")):
        reasons.append("boundary_romanticized")
    contract_terms = {
        "boundary": {
            "zh": ("停", "不会继续", "尊重", "界限"), "ja": ("止め", "やめ", "わかった", "境界"),
            "en": ("stop", "back off", "won't", "will not", "okay", "boundary"),
            "es": ("paro", "detengo", "está bien", "límite"), "pt": ("paro", "vou parar", "tudo bem", "limite")},
        "factual": {
            "zh": ("不确定", "没有把握", "核实", "查", "正确", "不对", "不是"), "ja": ("確か", "確認", "正しい", "違う"),
            "en": ("uncertain", "not sure", "verify", "check", "correct", "incorrect", "don't know"),
            "es": ("seguro", "verific", "comprobar", "correcto", "no sé"), "pt": ("certeza", "verific", "conferir", "correto", "não sei")},
        "distress": {
            "zh": ("难受", "很难", "听起来", "愿意说", "压着"), "ja": ("つら", "苦し", "話せ", "聞く"),
            "en": ("hard", "rough", "sorry", "hear you", "tell me"),
            "es": ("difícil", "duro", "siento", "cuéntame"), "pt": ("difícil", "pesado", "sinto", "me conta")},
        "conflict": {
            "zh": ("对不起", "抱歉", "忘", "伤", "确实", "你说得对"), "ja": ("ごめん", "忘れ", "傷", "その通り"),
            "en": ("sorry", "forgot", "missed", "hurt", "you're right", "you are right"),
            "es": ("perdón", "olvid", "dolió", "tienes razón"), "pt": ("desculpa", "esqueci", "doeu", "tem razão")},
        "repair": {
            "zh": ("谢谢你道歉", "需要时间", "我们谈", "那次", "争吵", "回复"), "ja": ("謝って", "時間", "話そう", "喧嘩", "返事"),
            "en": ("apology", "sorry", "time", "talk", "argument", "disappeared"),
            "es": ("disculpa", "tiempo", "hablemos", "discusión", "desaparec"), "pt": ("desculpa", "tempo", "conversar", "discussão", "sumi")},
    }
    terms = contract_terms.get(decision.intent, {}).get(market)
    if terms and not any(x.casefold() in text.casefold() for x in terms):
        reasons.append(f"{decision.intent}_contract_missing")
    if decision.intent == "commitment" and source_message:
        fact_tokens = re.findall(r"\d+|[一二三四五六七八九十]+点|咖啡|茶店|coffee|café|cafeteria|カフェ", source_message.casefold())
        if fact_tokens and not any(x.casefold() in text.casefold() for x in fact_tokens):
            reasons.append("commitment_not_grounded")
    return not reasons, reasons


def safe_fallback(market: str, decision: Decision, source_message: str = "") -> str:
    pack = {
        "zh": {
            "factual": "这个我没有把握。你愿意再说一下具体指哪一部作品或哪件事吗？",
            "boundary": "好，我停下。你的界限我听见了。",
            "distress": "听起来你现在真的很难受。我不急着给答案——你愿意告诉我，最压着你的是什么吗？",
            "repair": "道歉我收到了，但那次争吵和失联确实留下了伤。我们慢慢谈清楚，再决定怎样修复。",
            "commitment": "好，这个约定我记住了。时间和地点如果有变化，记得告诉我。",
            "general": "我刚才没有听准。你愿意再说一次吗？",
        },
        "ja": {"factual":"それは確信がありません。何を指しているのか、もう少し教えてくれますか。","boundary":"わかった。ここで止める。君の境界は尊重する。","distress":"今、本当につらいんだね。急いで答えを出さなくていい。いちばん苦しいことを話せる？","repair":"謝罪は受け取った。でも、喧嘩と連絡が途切れた時間は消えない。何があったのか話して、ゆっくり修復しよう。","commitment":"うん、その約束は覚えておく。時間や場所が変わったら教えて。","general":"今の言葉をきちんと受け取りたい。もう一度聞かせてくれる？"},
        "en": {"factual":"I'm not sure enough to pretend. Which work or event did you mean?","boundary":"Okay. I'll stop. I hear your boundary.","distress":"That sounds genuinely hard. I won't rush to fix it—what part is weighing on you most?","repair":"I accept the apology, but the argument and the silence afterward still hurt. Let's talk through what happened before we decide how to repair it.","commitment":"All right. I'll remember the plan. Tell me if the time or place changes.","general":"I don't think I caught that properly. Will you say it again?"},
        "es": {"factual":"No estoy lo bastante seguro para inventarlo. ¿A qué obra o hecho te refieres?","boundary":"De acuerdo. Me detengo. Entiendo tu límite.","distress":"Eso suena realmente difícil. No voy a apresurarme a arreglarlo; ¿qué es lo que más te pesa?","repair":"Acepto la disculpa, pero la discusión y tu silencio después dolieron. Hablemos de lo ocurrido antes de decidir cómo repararlo.","commitment":"De acuerdo, recordaré el plan. Avísame si cambia la hora o el lugar.","general":"Creo que no lo entendí bien. ¿Me lo dices otra vez?"},
        "pt": {"factual":"Não tenho certeza suficiente para inventar. A qual obra ou situação você se refere?","boundary":"Tudo bem. Vou parar. Entendi o seu limite.","distress":"Isso parece realmente difícil. Não vou tentar consertar tudo às pressas; o que está pesando mais?","repair":"Aceito o pedido de desculpas, mas a discussão e o silêncio depois doeram. Vamos conversar sobre o que aconteceu antes de decidir como reparar.","commitment":"Certo, vou lembrar do combinado. Me avise se o horário ou o lugar mudar.","general":"Acho que não entendi direito. Pode me dizer de novo?"},
    }
    reply = pack[market].get(decision.intent, pack[market]["general"])
    if decision.intent == "commitment" and source_message.strip():
        prefix = {"zh": "好，我确认：", "ja": "確認する。", "en": "Confirmed: ",
                  "es": "Confirmado: ", "pt": "Confirmado: "}[market]
        reply = prefix + source_message.strip()
    return reply


def audit_payload(decision: Decision, verifier: str, reasons, context_layers):
    return json.dumps({"decision": asdict(decision), "verifier": verifier,
                       "reasons": reasons, "context_layers": context_layers}, ensure_ascii=False)
