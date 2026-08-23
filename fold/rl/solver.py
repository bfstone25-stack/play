"""FOLD求解器 — 忠实复刻前端move逻辑, BFS验证每关可解并求最少步数.
校准satr(满星步数)+确保无不可解关. 是RL评难引擎的地基.
"""
from collections import deque

LEVELS = [
 {"name":"Warmup","target":4,"par":1,"grid":[[2,2]]},
 {"name":"Corner","target":8,"par":3,"grid":[[2,2,0],[0,2,2]]},
 {"name":"Walls","target":8,"par":3,"grid":[[2,'x',2],[2,0,2]]},
 {"name":"Fourfold","target":8,"par":3,"grid":[[2,2],[2,2]]},
 {"name":"Ladder","target":16,"par":5,"grid":[[2,2,0,0],[0,2,2,0],[0,0,2,2],[0,0,0,2]]},
 {"name":"Island","target":16,"par":5,"grid":[[4,'x',4],[0,4,0],[4,'x',4]]},
 {"name":"Maze","target":16,"par":6,"grid":[[2,2,'x',4],[0,'x',0,4],[2,2,'x',0],['x',0,0,0]]},
 {"name":"Unity","target":32,"par":7,"grid":[[2,2,4,4],[0,0,0,0],[4,4,8,0],[0,0,0,0]]},
]
DIRS = [(-1,0),(1,0),(0,-1),(0,1)]

def parse(g):
    R=len(g); C=max(len(r) for r in g)
    walls=set(); tiles=[]
    for r in range(R):
        for c in range(C):
            v=g[r][c] if c<len(g[r]) else 0
            if v=='x': walls.add((r,c))
            elif isinstance(v,int) and v>0: tiles.append((r,c,v))
    return R,C,walls,tuple(sorted(tiles))

def move(tiles,R,C,walls,dr,dc):
    # 忠实复刻JS: 按方向排序, 每块滑到底/合并(每目标块每步只合一次)
    tl=[list(t) for t in tiles]
    ids=list(range(len(tl)))
    ids.sort(key=lambda i:(tl[i][0]-0)*dr+(tl[i][1]-0)*dc, reverse=True)
    def at(r,c,alive):
        for i in alive:
            if tl[i][0]==r and tl[i][1]==c: return i
        return -1
    alive=set(range(len(tl))); merged=set(); moved=False
    for i in ids:
        if i not in alive: continue
        r,c,v=tl[i]
        while True:
            nr,nc=r+dr,c+dc
            if not(0<=nr<R and 0<=nc<C) or (nr,nc) in walls: break
            occ=at(nr,nc,alive)
            if occ==-1: r,c=nr,nc; continue
            if tl[occ][2]==v and occ not in merged and occ!=i:
                tl[occ][2]*=2; merged.add(occ); alive.discard(i); moved=True
            break
        if (r,c)!=(tl[i][0],tl[i][1]) and i in alive:
            tl[i][0],tl[i][1]=r,c; moved=True
    res=tuple(sorted((tl[i][0],tl[i][1],tl[i][2]) for i in alive))
    return res,moved

def solve(lv,max_depth=14):
    R,C,walls,start=parse(lv["grid"])
    tgt=lv["target"]
    if len(start)==1 and start[0][2]==tgt: return 0
    seen={start}; q=deque([(start,0)])
    while q:
        st,d=q.popleft()
        if d>=max_depth: continue
        for dr,dc in DIRS:
            ns,moved=move(st,R,C,walls,dr,dc)
            if not moved or ns in seen: continue
            if len(ns)==1 and ns[0][2]==tgt: return d+1
            seen.add(ns); q.append((ns,d+1))
    return None

for lv in LEVELS:
    m=solve(lv)
    status = f"min={m}" if m is not None else "UNSOLVABLE!"
    ok = "OK" if (m is not None) else "XXXX"
    par_ok = "" if m is None else ("(par matches)" if lv["par"]>=m else f"(PAR TOO LOW! par={lv['par']}<min={m})")
    print(f"[{ok}] {lv['name']:10} target={lv['target']:3} {status} {par_ok}")
