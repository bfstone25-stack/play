"""FOLD关卡生成器 v1(RL引擎地基, 纯CPU) — 随机铸盘+求解器验证+难度分档.
约束: 块值和=目标(2的幂,守恒不变量); 求解器BFS给出min_moves与探索状态数.
难度分: easy(min 2-3) / medium(4-6) / hard(7-9) / expert(10+)
输出: ~/Products/play/fold/rl/levels_gen.json (按档位各N关)
"""
import json, random, sys, os
sys.path.insert(0, os.path.expanduser("~/Products/play/fold/rl"))
from solver import move, parse
from collections import deque

DIRS = [(-1,0),(1,0),(0,-1),(0,1)]

def solve_stats(grid, target, max_depth=16, max_states=400000):
    R,C,walls,start = parse(grid)
    if len(start)==1 and start[0][2]==target: return 0, 1
    seen={start}; q=deque([(start,0)]); explored=0
    while q:
        st,d=q.popleft(); explored+=1
        if explored>max_states: return None, explored
        if d>=max_depth: continue
        for dr,dc in DIRS:
            ns,moved=move(st,R,C,walls,dr,dc)
            if not moved or ns in seen: continue
            if len(ns)==1 and ns[0][2]==target: return d+1, explored
            seen.add(ns); q.append((ns,d+1))
    return None, explored

def random_board(rng):
    R = rng.choice([3,3,4,4,5]); C = rng.choice([3,4,4,5])
    n_tiles = rng.randint(4, min(10, R*C-2))
    n_walls = rng.randint(0, max(0, (R*C - n_tiles)//3))
    # 值: 全部同值v0, 或两档混合(和须为2的幂)
    # 简洁法: 取k=2^m个同值块v → sum=k*v=2^(m+log2 v) 必为2的幂
    v = rng.choice([2,2,2,4,4,8])
    k_pow = rng.choice([2,3])  # 4或8块
    k = 2**k_pow
    if k > n_tiles: k = 4
    target = k * v
    cells = [(r,c) for r in range(R) for c in range(C)]
    rng.shuffle(cells)
    tiles = cells[:k]; walls = cells[k:k+n_walls]
    grid = [[0]*C for _ in range(R)]
    for (r,c) in tiles: grid[r][c] = v
    for (r,c) in walls: grid[r][c] = 'x'
    return grid, target

def tier(m):
    if m<=3: return "easy"
    if m<=6: return "medium"
    if m<=9: return "hard"
    return "expert"

def main(per_tier=12, seed=20260710):
    rng = random.Random(seed)
    got = {"easy":[], "medium":[], "hard":[], "expert":[]}
    tries = 0
    while any(len(v)<per_tier for v in got.values()) and tries < 30000:
        tries += 1
        grid, target = random_board(rng)
        m, explored = solve_stats(grid, target)
        if m is None or m < 2: continue
        t = tier(m)
        if len(got[t]) >= per_tier: continue
        got[t].append({"grid": grid, "target": target, "par": m,
                       "difficulty": t, "search_states": explored})
        if tries % 2000 == 0 or sum(len(v) for v in got.values()) % 10 == 0:
            print(f"tries={tries} " + " ".join(f"{k}:{len(v)}" for k,v in got.items()), flush=True)
    out = os.path.expanduser("~/Products/play/fold/rl/levels_gen.json")
    json.dump(got, open(out,"w"))
    print("GEN_LEVELS_DONE tries=%d " % tries + " ".join(f"{k}:{len(v)}" for k,v in got.items()), flush=True)
    # 难度分布样本
    for k in ("easy","medium","hard","expert"):
        if got[k]:
            pars = [l["par"] for l in got[k]]
            print(f"  {k}: par范围{min(pars)}-{max(pars)}", flush=True)

if __name__ == "__main__":
    main()
