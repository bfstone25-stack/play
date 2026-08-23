#!/usr/bin/env python3
"""FOLD大盘候选池: 8x8x20+9x9x15+10x10x10, 逆向构造+replay自验."""
import sys, os, json, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fold_reverse_gen as g
rng = random.Random()
out, skip = [], 0
for R, C, n in [(8,8,20),(9,9,15),(10,10,10)]:
    for i in range(n):
        t = rng.choice([64,128,128,256]); st = rng.randint(8,18); w = rng.randint(0, R*C//8)
        try:
            out.append(g.generate(R, C, t, st, w, seed=rng.randint(0, 10**9)))
        except Exception as e:
            skip += 1; print(f"skip {R}x{C}#{i}: {str(e)[:50]}", flush=True)
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "big_levels_pool.json"), "w"))
print(f"POOL_DONE {len(out)}盘 skip{skip}", flush=True)
