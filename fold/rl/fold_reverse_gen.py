#!/usr/bin/env python3
"""FOLD 大盘逆向生成器 (队列#68)

FOLD 正向语义 (严格对齐 apps-pages/fold/index.html 的 move()):
  - 方向 d=(dr,dc)。所有块按"沿 d 投影从远到近"排序依次处理。
  - 每块沿 d 滑动, 直到 边界/墙'x'/另一块 挡住。
  - 若挡住它的块 occ 与它同值, 且 occ 本回合未合并过(mergedIds),
    则 occ 翻倍(原地), 本块消失。每个接收块每回合只能合并一次。

逆向生成核心不变量:
  任何"正向滑动 d 的像"都沿 d 是 packed 的(每块沿 d 被挡)。
  reverse_step 只在当前盘面沿某方向 packed 时, 才对该方向反演:
    每个"段"(同一条线上被墙分隔的一节)里, 把贴在远端的值序列
    post_seq 逆展开成 pre_seq —— 每个值 v 以概率保留为 [v] 或
    (v>=4 时)拆成 [v/2, v/2](即正向合并的逆), 然后把 pre_seq 按
    顺序放进段内(可带随机空隙, 或压到近端以保证下一步有可反演
    方向)。最后用真正的正向模拟验证 forward(P,d)==G 且 P!=G。
  由此构造性保证: 生成盘执行 solution(正向方向序列)必归一 target。

墙: 反演完成后逐个撒在空格, 每放一个都重放 solution 验证仍可解,
失败则换位置。

自验证: generate 返回前 replay() 断言归一; 4x4 小盘对拍 —— 逆向
生成的盘用暴力 BFS 求真 par, 断言可解且 par_true <= par_upper。
"""
import json
import random
import sys
from collections import deque

DIRS = {"up": (-1, 0), "down": (1, 0), "left": (0, -1), "right": (0, 1)}
OPP = {"up": "down", "down": "up", "left": "right", "right": "left"}

# ---------- 基础 ----------

def grid_from(rows, cols, walls, tiles):
    g = [[0] * cols for _ in range(rows)]
    for (r, c) in walls:
        g[r][c] = 'x'
    for (r, c), v in tiles.items():
        g[r][c] = v
    return g


def tiles_of(grid):
    return {(r, c): v for r, row in enumerate(grid) for c, v in enumerate(row)
            if isinstance(v, int) and v > 0}


def walls_of(grid):
    return {(r, c) for r, row in enumerate(grid) for c, v in enumerate(row) if v == 'x'}


def forward_move(grid, dname):
    """严格复刻 index.html move(dr,dc)。返回 (新grid, moved)。"""
    dr, dc = DIRS[dname]
    R, C = len(grid), len(grid[0])
    walls = walls_of(grid)
    tiles = tiles_of(grid)  # pos -> v
    order = sorted(tiles.keys(), key=lambda p: -(p[0] * dr + p[1] * dc))
    merged = set()  # 本回合已作为接收方合并过的位置
    moved = False
    for pos in order:
        if pos not in tiles:
            continue
        v = tiles[pos]
        r, c = pos
        while True:
            nr, nc = r + dr, c + dc
            if nr < 0 or nr >= R or nc < 0 or nc >= C or (nr, nc) in walls:
                break
            if (nr, nc) in tiles:
                if tiles[(nr, nc)] == v and (nr, nc) not in merged:
                    tiles[(nr, nc)] = v * 2
                    merged.add((nr, nc))
                    del tiles[pos]
                    moved = True
                    r = c = None
                break
            r, c = nr, nc
        if r is not None and (r, c) != pos:
            del tiles[pos]
            tiles[(r, c)] = v
            moved = True
    return grid_from(R, C, walls, tiles), moved


def replay(grid, target, moves):
    """按正向语义重放 solution, 返回是否归一为单块 target。"""
    g = [row[:] for row in grid]
    for m in moves:
        g, _ = forward_move(g, m)
    t = tiles_of(g)
    return len(t) == 1 and next(iter(t.values())) == target


def is_packed(grid, dname):
    """每个块沿 d 都被 边界/墙/块 挡住 => 可能是正向 d 移动的像。"""
    dr, dc = DIRS[dname]
    R, C = len(grid), len(grid[0])
    walls = walls_of(grid)
    tiles = tiles_of(grid)
    for (r, c) in tiles:
        nr, nc = r + dr, c + dc
        if 0 <= nr < R and 0 <= nc < C and (nr, nc) not in walls and (nr, nc) not in tiles:
            return False
    return True


def segments(grid, dname):
    """沿方向 d 的所有段: 每段是 cell 列表, 顺序 = 从远端到近端。"""
    dr, dc = DIRS[dname]
    R, C = len(grid), len(grid[0])
    walls = walls_of(grid)
    segs = []
    lines = []
    if dr != 0:  # 竖直: 每列一条线, 远端 = dr方向尽头
        for c in range(C):
            cells = [(r, c) for r in range(R)]
            if dr > 0:
                cells.reverse()
            lines.append(cells)
    else:
        for r in range(R):
            cells = [(r, c) for c in range(C)]
            if dc > 0:
                cells.reverse()
            lines.append(cells)
    for line in lines:
        cur = []
        for cell in line:
            if cell in walls:
                if cur:
                    segs.append(cur)
                cur = []
            else:
                cur.append(cell)
        if cur:
            segs.append(cur)
    return segs


# ---------- 逆向一步 ----------

def _runs(seq):
    """把序列切成 (值, 连续个数) 的 run 列表。"""
    out = []
    for v in seq:
        if out and out[-1][0] == v:
            out[-1][1] += 1
        else:
            out.append([v, 1])
    return out


def dir_feasible(grid, dname):
    """快速判定: 方向 d 是否可能存在合法 pre(剪枝, 充分性由模拟验证)。

    段内同值 run 长度 k 的约束: 相邻两个都"原样保留"必然被正向合并,
    所以 run 内至少 floor(k/2) 个须为拆分产物 => 最小 pre 长度
    k + floor(k/2); v==2 不可拆 => run(2) 长度>=2 直接不可行。"""
    for seg in segments(grid, dname):
        post = [grid[r][c] for (r, c) in seg
                if isinstance(grid[r][c], int) and grid[r][c] > 0]
        if not post:
            continue
        min_len = 0
        for v, k in _runs(post):
            if v == 2 and k >= 2:
                return False
            min_len += k + (k // 2 if v >= 4 else 0)
        if min_len > len(seg):
            return False
    return True

def reverse_step(grid, rng, tries=250, require_packed=True,
                 max_tiles=None, prefer_dirs=None):
    """返回 (pre_grid, dname) 使 forward_move(pre,d)[0]==grid 且 pre!=grid。

    require_packed=True 时额外要求 pre 至少沿一个方向 packed ——
    否则 pre 不可能是任何正向移动的像, 逆向链会在下一步死锁。
    (只有最终输出的初始盘 G0 允许不 packed。)
    max_tiles: 拆分产生的总块数上限, 防止某条线被填满后逆向链死锁。
    prefer_dirs: 优先尝试的方向(用于换轴, 避免一直在同一轴来回)。
    失败返回 None。"""
    dirs = [d for d in DIRS if is_packed(grid, d) and dir_feasible(grid, d)]
    rng.shuffle(dirs)
    if prefer_dirs:
        dirs.sort(key=lambda d: 0 if d in prefer_dirs else 1)
    R, C = len(grid), len(grid[0])
    walls = walls_of(grid)
    n_tiles = len(tiles_of(grid))
    for t in range(tries):
        if not dirs:
            return None
        # 前 1/3 尝试按偏好方向, 之后完全随机
        d = dirs[0] if (prefer_dirs and t < tries // 3) else rng.choice(dirs)
        segs = segments(grid, d)
        pre_tiles = {}
        ok = True
        # 压近端: pre 沿 OPP[d] 必 packed, 保证逆向链可延续; 少量随机空隙增加多样性
        pack_near = rng.random() < (0.5 if not require_packed else 0.7)
        budget = (max_tiles - n_tiles) if max_tiles else 10 ** 9  # 还允许拆几次
        for seg in segs:
            post = [grid[r][c] for (r, c) in seg
                    if isinstance(grid[r][c], int) and grid[r][c] > 0]
            if not post:
                continue
            room = max(len(seg) - 1, len(post))  # 不填满整段(除非本来已满)
            pre_seq = []
            prev_plain_same = False  # 上一个 post 元素是否"原样保留"且同值 run 内
            prev_v = None
            for i, v in enumerate(post):
                rem = len(post) - i - 1  # 后面还有几个值(每个至少占1格)
                can_split = v >= 4 and budget > 0 and len(pre_seq) + 2 + rem <= room
                # run 内两个连续"原样保留"会被正向合并 => 强制拆分
                must_split = (v == prev_v) and prev_plain_same
                if must_split and not can_split:
                    ok = False
                    break
                if can_split and (must_split or rng.random() < 0.6):
                    pre_seq += [v // 2, v // 2]  # 合并的逆: 拆半
                    budget -= 1
                    prev_plain_same = False
                else:
                    pre_seq.append(v)
                    prev_plain_same = True
                prev_v = v
            if not ok or len(pre_seq) > len(seg):
                ok = False
                break
            # 选位置(段内保持顺序: 远->近)
            if pack_near:
                idxs = list(range(len(seg) - len(pre_seq), len(seg)))
            else:
                idxs = sorted(rng.sample(range(len(seg)), len(pre_seq)))
            for i, v in zip(idxs, pre_seq):
                pre_tiles[seg[i]] = v
        if not ok:
            continue
        pre = grid_from(R, C, walls, pre_tiles)
        if pre == grid:
            continue
        fwd, _ = forward_move(pre, d)
        if fwd != grid:
            continue
        if require_packed and not any(is_packed(pre, dd) for dd in DIRS):
            continue
        return pre, d
    return None


# ---------- 生成器 ----------

def generate(rows, cols, target, n_steps, n_walls, seed):
    assert target & (target - 1) == 0 and target >= 4, "target 须为 2 的幂"
    rng = random.Random(seed)
    for attempt in range(500):
        # 终态: 单块 target 放角落(角落对两个方向天然 packed)
        corner = rng.choice([(0, 0), (0, cols - 1), (rows - 1, 0), (rows - 1, cols - 1)])
        g = grid_from(rows, cols, set(), {corner: target})
        # 块数上限: 既受面积限制, 也别远超步数所需(防线满死锁)
        max_tiles = min(rows * cols // 3, target // 2, 2 * n_steps)

        def extend(cur, steps_left, last_d, depth_budget=[3000]):
            """DFS+回溯: 反演 steps_left 次。返回 (G0, 正向方向序列) 或 None。
            单次 reverse_step 失败不整链重来, 只回退换分支。"""
            if steps_left == 0:
                return cur, []
            if depth_budget[0] <= 0:
                return None
            prefer = (("left", "right") if last_d in ("up", "down")
                      else ("up", "down") if last_d in ("left", "right") else None)
            for _branch in range(6):  # 每层最多试 6 个不同的反演分支
                depth_budget[0] -= 1
                res = reverse_step(cur, rng, tries=80,
                                   require_packed=(steps_left > 1),
                                   max_tiles=max_tiles, prefer_dirs=prefer)
                if res is None:
                    return None  # 本节点已无可反演方向, 回退上层换分支
                pre, d = res
                deeper = extend(pre, steps_left - 1, d, depth_budget)
                if deeper is not None:
                    g0, tail = deeper
                    return g0, tail + [d]  # 正向顺序: 越深越早
            return None

        got = extend(g, n_steps, None)
        if got is None:
            continue
        g, sol = got
        if not replay(g, target, sol):
            continue
        # 撒墙: 逐个放, 重放验证不破坏可解路径
        placed = 0
        wall_tries = 0
        while placed < n_walls and wall_tries < 300:
            wall_tries += 1
            empties = [(r, c) for r in range(rows) for c in range(cols) if g[r][c] == 0]
            if not empties:
                break
            r, c = rng.choice(empties)
            g[r][c] = 'x'
            if replay(g, target, sol):
                placed += 1
            else:
                g[r][c] = 0
        assert replay(g, target, sol), "自验证失败"
        return {"grid": g, "target": target, "par_upper": n_steps,
                "solution": sol, "walls_placed": placed, "seed": seed}
    raise RuntimeError(f"生成失败: {rows}x{cols} target={target} steps={n_steps} seed={seed}")


# ---------- 暴力 BFS(小盘对拍) ----------

def bfs_par(grid, target, max_states=400_000):
    start = frozenset(tiles_of(grid).items())
    R, C = len(grid), len(grid[0])
    walls = walls_of(grid)

    def to_grid(state):
        return grid_from(R, C, walls, dict(state))

    goal = lambda s: len(s) == 1 and next(iter(s))[1] == target
    if goal(start):
        return 0
    seen = {start}
    q = deque([(start, 0)])
    while q:
        state, depth = q.popleft()
        for d in DIRS:
            ng, moved = forward_move(to_grid(state), d)
            if not moved:
                continue
            ns = frozenset(tiles_of(ng).items())
            if ns in seen:
                continue
            if goal(ns):
                return depth + 1
            seen.add(ns)
            if len(seen) > max_states:
                return -2  # 状态爆炸
            q.append((ns, depth + 1))
    return -1  # 不可解


def selftest():
    """4x4 小盘对拍 x10: 逆向生成的盘 BFS 必可解且 par_true<=par_upper。"""
    print("== 4x4 对拍自测 ==")
    ok = 0
    for i in range(10):
        lv = generate(4, 4, target=rng_target(i), n_steps=3 + i % 4,
                      n_walls=i % 3, seed=1000 + i)
        p = bfs_par(lv["grid"], lv["target"])
        status = "PASS" if 0 < p <= lv["par_upper"] else "FAIL"
        if status == "PASS":
            ok += 1
        print(f"  #{i} target={lv['target']:>3} par_upper={lv['par_upper']} "
              f"bfs_par={p} walls={lv['walls_placed']} {status}")
        assert 0 < p <= lv["par_upper"], f"对拍失败 #{i}: bfs={p}"
    print(f"  {ok}/10 通过\n")


def rng_target(i):
    return [16, 32, 32, 64, 16, 32, 64, 16, 32, 64][i % 10]


def fmt(grid):
    return "\n".join(" ".join(f"{('#' if v=='x' else v if v else '.'):>4}"
                              for v in row) for row in grid)


def main():
    selftest()
    out = []
    specs = [(8, 8, 64, 8), (8, 8, 128, 12), (8, 8, 128, 16),
             (9, 9, 128, 10), (9, 9, 128, 14), (9, 9, 256, 18),
             (10, 10, 128, 12), (10, 10, 256, 16), (10, 10, 256, 20)]
    for k, (R, C, tgt, steps) in enumerate(specs):
        lv = generate(R, C, target=tgt, n_steps=steps, n_walls=4 + k % 4,
                      seed=7000 + k)
        ver = replay(lv["grid"], lv["target"], lv["solution"])
        print(f"== {R}x{C} target={tgt} par_upper={steps} "
              f"walls={lv['walls_placed']} replay={'OK' if ver else 'FAIL'} ==")
        print(fmt(lv["grid"]))
        print("solution:", " ".join(lv["solution"]), "\n")
        assert ver
        out.append(lv)
    path = __file__.rsplit("/", 1)[0] + "/fold_big_levels_sample.json"
    with open(path, "w") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print(f"已写出 {len(out)} 盘 -> {path}")


if __name__ == "__main__":
    sys.setrecursionlimit(10000)
    main()
