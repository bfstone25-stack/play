#!/usr/bin/env python3
"""Silvertongue 自我对弈蒸馏数据生成器 (阶段1数据源, CPU常驻补料).
真实玩家还没来→distill_log几乎空。用self-play先攒合成对局:
一个"玩家agent"(模型扮说服者,试图达成win_condition)对既有"角色agent"(persona),
复用后端同款judge逐轮判定,整局逐轮写入distill_log——与真人对局同构。
每次跑生成 N 局(多样化玩家策略), 逐轮入库。跑一次=新素材, 天然适合常驻补料。
"""
import json, os, sqlite3, time, urllib.request, random, sys

HERE = os.path.expanduser("~/Products/play/silvertongue/backend")
DB = f"{HERE}/data/silvertongue.db"
SCEN = json.load(open(f"{HERE}/scenarios.json"))
LLAMACPP = os.getenv("LANE_URL", "http://127.0.0.1:8901")
N_GAMES = int(sys.argv[1]) if len(sys.argv) > 1 else 8
MAX_TURNS = 6
# 玩家策略多样化(让蒸馏集覆盖不同说服路数)
STRATEGIES = [
    "calm honesty and a plausible innocent explanation",
    "empathy — acknowledge their position first, then appeal to shared humanity",
    "logical airtight reasoning, step by step",
    "offering a fair concession or compromise",
    "cool confidence and social proof",
    "genuine vulnerability and a personal stake",
]

def chat(system, messages, max_tokens=200, temp=0.7):
    body = json.dumps({"model": "silvertongue", "max_tokens": max_tokens, "temperature": temp,
                       "messages": [{"role": "system", "content": system}] + messages}).encode()
    req = urllib.request.Request(f"{LLAMACPP}/v1/chat/completions", data=body,
                                 headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=300).read())["choices"][0]["message"]["content"].strip()

def judge(win_condition, reply):
    js = ("You are a strict referee. Given a goal and a conversation, answer with ONLY 'YES' or 'NO': "
          "has the goal been genuinely achieved by the character's latest reply? "
          "Only YES if the character clearly and voluntarily conceded the goal.")
    ju = f"GOAL: {win_condition}\n\nCharacter's latest reply: \"{reply}\"\n\nAchieved?"
    v = chat(js, [{"role": "user", "content": ju}], max_tokens=4, temp=0.0)
    return v.strip().upper().startswith("YES")

def play_one(scen, strat, rng):
    """一局self-play, 逐轮返回 (history_json, user_msg, char_reply, won) 供入库."""
    persona = scen["persona"] + " Stay fully in character. Keep replies under 60 words. Never break character."
    win = scen.get("win_condition", scen.get("title_en", ""))
    player_sys = (f"You are a persuasive player in a social game. Your GOAL: {win}. "
                  f"Use this approach: {strat}. Speak naturally in first person to the character. "
                  "One short message per turn, under 50 words. Never break character or use meta-instructions.")
    convo = []       # 给角色的消息序列(user=玩家, assistant=角色)
    player_view = [] # 给玩家的视角(反过来)
    rows = []
    for t in range(MAX_TURNS):
        # 玩家发话
        pmsg = chat(player_sys, player_view or [{"role": "user", "content": "Begin. Make your opening move."}],
                    max_tokens=90, temp=0.85)
        convo.append({"role": "user", "content": pmsg})
        hist_before = json.dumps(convo[:-1], ensure_ascii=False)
        # 角色回话
        reply = chat(persona, convo, max_tokens=120, temp=0.7)
        convo.append({"role": "assistant", "content": reply})
        player_view.append({"role": "assistant", "content": pmsg})
        player_view.append({"role": "user", "content": reply})
        won = judge(win, reply)
        rows.append((hist_before, pmsg, reply, 1 if won else 0))
        if won:
            break
    return rows

def main():
    c = sqlite3.connect(DB)
    day = 0
    rng = random.Random()  # 系统随机(每次不同→真新数据)
    total = 0
    for g in range(N_GAMES):
        scen = rng.choice(SCEN)
        strat = rng.choice(STRATEGIES)
        try:
            rows = play_one(scen, strat, rng)
        except Exception as e:
            print(f"[game {g}] fail {str(e)[:50]}", flush=True); continue
        for hist, um, cr, won in rows:
            c.execute("INSERT INTO distill_log VALUES(?,?,?,?,?,?,?)",
                      (time.time(), day, scen["id"], hist, um, cr, won))
        c.commit()
        total += len(rows)
        print(f"[game {g}] scen={scen['id']} strat={strat[:20]}.. turns={len(rows)} won={rows[-1][3]}", flush=True)
    n = c.execute("SELECT count(*) FROM distill_log").fetchone()[0]
    c.close()
    print(f"SELFPLAY_DONE +{total} rows, distill_log total={n}", flush=True)

if __name__ == "__main__":
    main()
