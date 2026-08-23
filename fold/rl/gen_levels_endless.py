import json, random, sys, os
sys.path.insert(0, os.path.expanduser("~/Products/play/fold/rl"))
from gen_levels import solve_stats, tier
def random_board(rng):
    R=rng.choice([4,5,5,6]); C=rng.choice([4,5,5,6])
    v=rng.choice([2,2,4,4,8]); k=2**rng.choice([2,3,3,4])
    if k>R*C-3: k=8
    target=k*v
    cells=[(r,c) for r in range(R) for c in range(C)]; rng.shuffle(cells)
    tiles=cells[:k]; walls=cells[k:k+rng.randint(1,(R*C-k)//3)]
    g=[[0]*C for _ in range(R)]
    for (r,c) in tiles: g[r][c]=v
    for (r,c) in walls: g[r][c]='x'
    return g,target
rng=random.Random(88); got={"easy":[],"medium":[],"hard":[],"expert":[]}
per={"easy":25,"medium":50,"hard":50,"expert":25}; tries=0
while any(len(got[k])<per[k] for k in per) and tries<120000:
    tries+=1; g,t=random_board(rng)
    m,ex=solve_stats(g,t,max_depth=15,max_states=250000)
    if m is None or m<2: continue
    tr=tier(m)
    if len(got[tr])>=per[tr]: continue
    got[tr].append({"grid":g,"target":t,"par":m})
    if sum(len(v) for v in got.values())%25==0: print(tries, {k:len(v) for k,v in got.items()},flush=True)
out=os.path.expanduser("~/Products/play/fold/rl/levels_endless.json")
json.dump(got,open(out,"w"))
print("ENDLESS_DONE",{k:len(v) for k,v in got.items()},flush=True)
