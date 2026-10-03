# The 72 testimonies as hotspot labels: "Ask: <topic>" (EN from the VN's statement table,
# JA written here). Generated from data/story/cases_index.json so a renamed statement fails
# the build instead of silently losing its button.
import json
from pathlib import Path

TOPIC_JA = {
    "the keys": "鍵", "after two": "二時以降", "what you do here": "ここでの仕事", "Marek": "マレク", "the list": "リスト",
    "the safe": "金庫", "the back rooms": "奥の部屋", "the strip curtain": "ストリップカーテン",
    "closing up": "閉店作業", "the alarm": "警報装置", "who was left": "残っていた人", "the kitchen": "厨房", "Vee": "ヴィー",
    "the lease": "賃貸契約", "the cooler door": "冷蔵室の扉",
    "the delivery": "配達", "leaving": "退店", "the van": "バン", "whose name": "誰の名前", "past the bar": "バーの奥",
    "the cold": "寒さ", "eleven minutes": "十一分",
    "Iris": "アイリス", "the rain": "雨", "her car": "彼女の車", "the books": "帳簿", "the second set": "二冊目の帳簿",
    "Adaeze": "アダエゼ", "what Iris wanted": "アイリスの望み", "the bay light": "搬入口の灯り",
    "until four": "四時まで", "the loading bay": "搬入口", "your signature": "あなたの署名", "the audit": "監査",
    "that night": "あの夜", "clean water": "きれいな水", "the mop room": "モップ室",
    "where you were": "居場所", "the bail": "保釈", "why that mattered": "なぜ大事だったか", "who paid": "誰が払ったか",
    "the last case": "前の事件", "what you're afraid of": "何が怖いのか", "what you saw": "見たもの",
    "Bo Kestrel": "ボー・ケストレル", "the fire stairs": "非常階段", "the inspection": "査察", "the folder": "フォルダー",
    "the Paloma": "パロマ", "what was worth taking": "盗む価値があったもの", "why you keep coming back": "なぜ戻ってくるのか",
    "the lease, again": "また賃貸契約", "last night": "昨夜", "the report": "報告書", "since Iris": "アイリス以来",
    "Nikolai": "ニコライ", "what he is owed": "彼が受け取るべきもの", "the office light": "事務室の灯り",
    "why you came in": "なぜ来たのか", "the yard": "裏庭", "what you heard": "聞いたこと", "why you didn't say": "なぜ言わなかったか",
    "what you want": "望むこと", "going down slow": "ゆっくり降りる足音",
}

S = {}
_ix = json.loads((Path(__file__).resolve().parent.parent / "data/story/cases_index.json").read_text())
for case in _ix["cases"]:
    for st in case["statements"]:
        ja = TOPIC_JA.get(st["topic"])
        if ja is None:
            raise SystemExit(f"no JA for topic {st['topic']!r}")
        S["hs_ask_" + st["id"]] = ("Ask: " + st["topic"], "質問：" + ja)
