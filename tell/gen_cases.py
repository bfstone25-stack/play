#!/usr/bin/env python3
"""TELL新案件批量生成器 — 核显serving. 每个案件:受害者+3嫌疑人persona+唯一凶手+未公开细节破绽."""
import json, os, urllib.request, re, sys

LANE = os.getenv("LANE_URL", "http://127.0.0.1:8903")  # gemma中文核显
CASES = os.path.expanduser("~/Play/tell/backend/cases.json")
N = int(sys.argv[1]) if len(sys.argv) > 1 else 8

SETTINGS = ["公寓楼顶花园","私人游艇","大学实验室","老剧院后台","高级餐厅包间","滑雪度假村","古董书店","医院病房","律师事务所","深夜电台直播间","美术拍卖行","封闭山庄晚宴"]

def chat(prompt, mx=900):
    body = json.dumps({"model":"tell","max_tokens":mx,"temperature":0.9,
        "messages":[{"role":"user","content":prompt}]}).encode()
    r = urllib.request.Request(f"{LANE}/v1/chat/completions", data=body, headers={"Content-Type":"application/json"})
    return json.loads(urllib.request.urlopen(r, timeout=300).read())["choices"][0]["message"]["content"].strip()

PROMPT = """你是一个推理游戏的案件设计师。设计一个"审讯找凶手"案件,严格输出JSON(不要markdown代码块,直接JSON):
场景:{setting}。要求:
- 一名受害者(有名字)
- 恰好3名嫌疑人,每人有id(英文小写)/name/角色/persona(第一人称,说明其当晚不在场证明或行为,凶手要能在审讯中露出"只有凶手才知道的未公开细节"的破绽,无辜者则老实)
- solution=凶手的id
- key_zh/key_en=破绽描述(凶手泄露的未公开细节,如凶器/作案手法/现场细节)
- setup_zh/setup_en=案情简介(不透露凶器)
- title_zh/title_en=案件标题
JSON字段:id(英文,场景相关),title_en,title_zh,setup_en,setup_zh,victim,budget(设12),solution,key_en,key_zh,suspects(3个,每个有id,name,role_en,role_zh,persona)
只输出JSON对象。"""

def extract_json(text):
    text = re.sub(r'```json|```', '', text)
    m = re.search(r'\{.*\}', text, re.S)
    return json.loads(m.group(0)) if m else None

existing = json.load(open(CASES))
existing_ids = {c["id"] for c in existing}
added = 0
import random
for i in range(N):
    setting = random.choice(SETTINGS)
    try:
        raw = chat(PROMPT.format(setting=setting))
        case = extract_json(raw)
        if not case: print(f"[{i}] 解析失败", flush=True); continue
        # 校验必需字段
        need = {"id","title_zh","setup_zh","victim","solution","key_zh","suspects"}
        if not need.issubset(case.keys()): print(f"[{i}] 缺字段", flush=True); continue
        if len(case.get("suspects",[])) != 3: print(f"[{i}] 嫌疑人数≠3", flush=True); continue
        if case["solution"] not in {s["id"] for s in case["suspects"]}: print(f"[{i}] 凶手id不在嫌疑人中", flush=True); continue
        # id去重
        base = case["id"]; k = 0
        while case["id"] in existing_ids: k += 1; case["id"] = f"{base}{k}"
        case.setdefault("budget", 12)
        existing.append(case); existing_ids.add(case["id"]); added += 1
        print(f"[{i}] ✓ {case.get('title_zh','?')[:20]} 凶手={case['solution']}", flush=True)
    except Exception as e:
        print(f"[{i}] 异常 {str(e)[:50]}", flush=True)

json.dump(existing, open(CASES,"w"), ensure_ascii=False, indent=1)
print(f"TELL_GEN_DONE +{added}新案件, 总计{len(existing)}", flush=True)
