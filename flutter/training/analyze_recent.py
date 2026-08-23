#!/usr/bin/env python3
"""Privacy-preserving operational audit for recent Flutter traffic."""
import argparse
import collections
import json
import sqlite3
import time


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default="../data/flutter.db")
    ap.add_argument("--days", type=int, default=7)
    args = ap.parse_args()
    db = sqlite3.connect(args.db); db.row_factory = sqlite3.Row
    since = time.time() - args.days * 86400
    rows = list(db.execute("SELECT route,pid,user_msg,reply FROM distill_log WHERE ts>=?", (since,)))
    signals = list(db.execute("SELECT lang,signals_json,affection_delta FROM interaction_signals WHERE ts>=?", (since,)))
    routes = collections.Counter(x["route"] for x in rows)
    intents = collections.Counter()
    for row in signals:
        try: intents[json.loads(row["signals_json"]).get("intent", "legacy_unlabelled")] += 1
        except Exception: intents["invalid"] += 1
    quality = {
        "english_stage_leaks": sum(bool(__import__('re').search(r"\*[A-Za-z][^*]*\*", x["reply"] or "")) for x in rows),
        "template_spam": sum(len(__import__('re').findall(r"轻轻|微微|目光|温柔", x["reply"] or "")) >= 3 for x in rows),
        "empty_replies": sum(not (x["reply"] or "").strip() for x in rows),
    }
    reason_rows = list(db.execute("SELECT intent,temperature,verifier FROM reasoning_log WHERE ts>=?", (since,))) if db.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='reasoning_log'").fetchone() else []
    print(json.dumps({"days": args.days, "turns": len(rows),
                      "anonymous_players": len({x['pid'] for x in rows if x['pid']}),
                      "routes": routes, "intents": intents, "quality": quality,
                      "runtime_decisions": {
                          "intents": collections.Counter(x['intent'] for x in reason_rows),
                          "temperatures": collections.Counter(x['temperature'] for x in reason_rows),
                          "verifiers": collections.Counter(x['verifier'] for x in reason_rows)}},
                     ensure_ascii=False, indent=2, default=dict))


if __name__ == "__main__": main()
