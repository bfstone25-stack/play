#!/usr/bin/env python3
"""FOLD 大盘 beam search 求解基线 (队列#69)

复用 fold_reverse_gen.forward_move (正向滑动语义唯一权威实现)。

启发式 h (越小越好, 加权和):
  1. 块数惩罚 3*(n-1): 归一必须把 n 块合到 1 块, 每次合并至少 1 步,
     每步最多合并 ~n/2 对 => 块数是最主要的进度信号, 权重最大。
  2. 价值离散度 sum(log2(target/v)): 每块 v 需要 log2(target/v) 次
     翻倍才能到 target; 该和 = 剩余合并事件总数的精确下界的代理
     (等价于 log2(target) * n - sum(log2 v)), 惩罚"碎小块"。
  3. 最大块比例奖励 -2*log2(vmax)/log2(target): 已有大块说明主干
     合并链在推进, 轻微奖励避免 beam 全被"块少但都很小"的状态占据。
score = depth + h (类 weighted A*), beam 按 score 取前 beam_width。
"""
import json
import math
import os
import sys
import time
import heapq

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fold_reverse_gen import (forward_move, tiles_of, walls_of, grid_from,
                              replay, generate, DIRS, fmt)


def _key(grid):
    return tuple(tuple(row) for row in grid)


def heuristic(grid, target):
    tiles = tiles_of(grid)
    n = len(tiles)
    if n == 0:
        return math.inf
    vals = list(tiles.values())
    if n == 1 and vals[0] == target:
        return 0.0
    lt = math.log2(target)
    disp = sum(lt - math.log2(v) for v in vals)  # 剩余翻倍事件数
    vmax = max(vals)
    return 3.0 * (n - 1) + disp - 2.0 * (math.log2(vmax) / lt)


def beam_solve(grid, target, beam_width=512, max_depth=40):
    """返回 (moves 列表 or None, 展开节点数)。"""
    start = _key(grid)
    tiles = tiles_of(grid)
    if len(tiles) == 1 and next(iter(tiles.values())) == target:
        return [], 0
    seen = {start}
    beam = [(heuristic(grid, target), grid, [])]
    nodes = 0
    for depth in range(1, max_depth + 1):
        cand = []
        for _, g, moves in beam:
            for d in DIRS:
                ng, moved = forward_move(g, d)
                if not moved:
                    continue
                nodes += 1
                k = _key(ng)
                if k in seen:
                    continue
                seen.add(k)
                t = tiles_of(ng)
                nm = moves + [d]
                if len(t) == 1 and next(iter(t.values())) == target:
                    return nm, nodes
                if len(t) == 0 or max(t.values()) > target:
                    continue  # 超过 target 的块永远无法归一, 剪枝
                cand.append((depth + heuristic(ng, target), ng, nm))
        if not cand:
            return None, nodes
        beam = heapq.nsmallest(beam_width, cand, key=lambda x: x[0])
    return None, nodes


def _width_for(grid):
    area = len(grid) * len(grid[0])
    return 512 if area <= 64 else (384 if area <= 81 else 256)


def _tier(par):
    return "master1" if par <= 8 else ("master2" if par <= 13 else "master3")


def solve_pool(pool_json, out_json):
    with open(pool_json) as f:
        pool = json.load(f)
    out = []
    for i, lv in enumerate(pool):
        grid, target = lv["grid"], lv["target"]
        pu = lv.get("par_upper")
        w = _width_for(grid)
        md = max(40, (pu or 20) + 10)
        t0 = time.time()
        moves, nodes = beam_solve(grid, target, beam_width=w, max_depth=md)
        dt = time.time() - t0
        rec = dict(lv)
        rec.update({"beam_width": w, "nodes": nodes, "time": round(dt, 2)})
        if moves is not None:
            assert replay(grid, target, moves), f"#{i} beam 解 replay 失败"
            rec.update({"beam_par": len(moves), "beam_solution": moves,
                        "gap": (pu - len(moves)) if pu else None,
                        "tier": _tier(len(moves))})
        else:
            # 构造已保证可解, 只是 beam 没找到; 用 par_upper 兜底分档
            rec.update({"beam_par": None, "unsolved_by_beam": True,
                        "gap": None,
                        "tier": _tier(pu) if pu else "master3"})
        print(f"  #{i} {len(grid)}x{len(grid[0])} target={target} "
              f"par_upper={pu} beam_par={rec['beam_par']} "
              f"nodes={nodes} {dt:.1f}s tier={rec['tier']}")
        out.append(rec)
    with open(out_json, "w") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    solved = sum(1 for r in out if r.get("beam_par") is not None)
    print(f"solved {solved}/{len(out)} -> {out_json}")
    return out


def selftest():
    print("== 自测: 3 个 8x8 盘 (fold_reverse_gen 生成) ==")
    for i, (tgt, steps) in enumerate([(64, 8), (128, 12), (128, 16)]):
        lv = generate(8, 8, target=tgt, n_steps=steps, n_walls=3, seed=4200 + i)
        t0 = time.time()
        moves, nodes = beam_solve(lv["grid"], tgt, beam_width=512)
        dt = time.time() - t0
        assert moves is not None, f"自测 #{i} beam 未解出"
        assert replay(lv["grid"], tgt, moves), f"自测 #{i} replay 失败"
        assert len(moves) <= lv["par_upper"], \
            f"自测 #{i} beam_par {len(moves)} > par_upper {lv['par_upper']}"
        print(f"  #{i} target={tgt} par_upper={lv['par_upper']} "
              f"beam_par={len(moves)} gap={lv['par_upper']-len(moves)} "
              f"nodes={nodes} {dt:.1f}s tier={_tier(len(moves))} PASS")
    print("自测通过\n")


def main():
    selftest()
    pool = "/home/frankstone/Play/fold/rl/big_levels_pool.json"
    if os.path.exists(pool):
        solve_pool(pool, pool.replace(".json", "_beam.json"))
    else:
        # 本地: 若生成器样本存在则顺手标定
        here = os.path.dirname(os.path.abspath(__file__))
        sample = os.path.join(here, "fold_big_levels_sample.json")
        if os.path.exists(sample):
            print("== 处理本地样本池 ==")
            solve_pool(sample, os.path.join(here, "fold_big_levels_beam.json"))
        else:
            print(f"池文件不存在: {pool} (部署到 pop-os 后自动处理)")


if __name__ == "__main__":
    main()
