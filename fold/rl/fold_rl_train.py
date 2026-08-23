#!/usr/bin/env python3
"""FOLD RL 求解器 (队列#70) — 环境 + PPO 训练 + 评估

滑动语义 100% 复用 fold_reverse_gen.forward_move / generate (import, 不重写)。

用途:
  1. 给 BFS 不可及的大盘估 par (rl_par)
  2. 作第②步 beam search 的对手盘策略

设计:
  - FoldEnv: gym 风格 (无 gym 依赖)。reset() 用 fold_reverse_gen.generate
    现产课程盘 (带 level pool 缓存摊薄生成开销)。
    obs = 2 通道 MAX x MAX (=10x10, 小盘 pad):
      ch0 = log2(v)/11 (空=0), ch1 = 墙 mask (盘外也记为墙)。
    reward: 归一成功 +10; 每步 -0.05; 块数每减少1块 +0.3;
            无效移动(盘面不变) -0.2。episode 上限 40 步。
  - 课程: 6x6/steps4-6 起步 → 6x6/8 → 7x7 → 8x8/13 → 8x8/16,
    近 300 ep 成功率 >= 0.65 自动升级。
  - 网络: 2conv(64) + FC256, 4 logits + value 头 (~90万参数, 1660Ti 轻松)。
  - 训练: PPO (GAE lambda=0.95, clip=0.2), 16 个环境简单 for 循环向量化,
    rollout T=128, 4 epoch, minibatch 4。
  - checkpoint: ~/models/fold_rl/policy.pt (model/optim/课程级/ep 计数),
    --resume 断点续训; --hours N 定时自停 (默认 6)。
  - --eval pool.json: 每盘 贪心 x8 + 采样 x8, 输出 rl_par 或 unsolved。
  - --smoke: 4x4 课程 200 episodes CPU 冒烟。
  - 启动即 os.nice(10), GPU 队列友好。
"""
import argparse
import json
import math
import os
import random
import sys
import time
from collections import deque

import torch
torch.backends.cudnn.enabled = False  # GTX 16xx cuDNN bug(CUDNN_STATUS_NOT_INITIALIZED), 同SD管线旧坑
import torch.nn as nn
import torch.nn.functional as F

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fold_reverse_gen import DIRS, forward_move, generate, tiles_of  # noqa: E402

ACTIONS = ["up", "down", "left", "right"]
MAX = 10          # 网络固定输入边长 (支持到 10x10 的评估盘)
EP_CAP = 40       # episode 步数上限
LOG2_NORM = 11.0  # 2^11=2048 归一上界

# ---------------- 课程表 ----------------
# (rows, cols, steps_lo, steps_hi, targets, walls_hi)
CURRICULUM = [
    (6, 6, 4, 6,  [16, 32],   2),
    (6, 6, 6, 8,  [32],       3),
    (7, 7, 8, 11, [32, 64],   3),
    (8, 8, 10, 13, [64, 128], 4),
    (8, 8, 13, 16, [64, 128], 5),
]
SMOKE_CURRICULUM = [(4, 4, 2, 4, [16], 1)]


class LevelPool:
    """按课程级缓存生成好的盘, 摊薄 generate 开销。"""

    def __init__(self, curriculum, pool_size=240, rng=None):
        self.curriculum = curriculum
        self.pool_size = pool_size
        self.pools = [[] for _ in curriculum]
        self.rng = rng or random.Random()

    def sample(self, lvl):
        pool = self.pools[lvl]
        # 池未满时倾向现产新盘, 满后随机复用
        if len(pool) < self.pool_size and (len(pool) < 16 or self.rng.random() < 0.3):
            r, c, lo, hi, tgts, wmax = self.curriculum[lvl]
            for _ in range(5):
                try:
                    lv = generate(r, c, target=self.rng.choice(tgts),
                                  n_steps=self.rng.randint(lo, hi),
                                  n_walls=self.rng.randint(0, wmax),
                                  seed=self.rng.randrange(1 << 30))
                    pool.append(lv)
                    break
                except RuntimeError:
                    continue
        return self.rng.choice(pool) if pool else self.sample(lvl)


class FoldEnv:
    """gym 风格 FOLD 环境 (不依赖 gym)。"""

    def __init__(self, pool: LevelPool):
        self.pool = pool
        self.grid = None
        self.target = None
        self.steps = 0
        self.level_idx = 0

    def _obs(self):
        o = torch.zeros(2, MAX, MAX)
        o[1].fill_(1.0)  # 盘外视为墙
        R, C = len(self.grid), len(self.grid[0])
        for r in range(R):
            for c in range(C):
                v = self.grid[r][c]
                if v == 'x':
                    o[1, r, c] = 1.0
                else:
                    o[1, r, c] = 0.0
                    if v:
                        o[0, r, c] = math.log2(v) / LOG2_NORM
        return o

    def reset(self, level_idx=None):
        if level_idx is not None:
            self.level_idx = level_idx
        lv = self.pool.sample(self.level_idx)
        self.grid = [row[:] for row in lv["grid"]]
        self.target = lv["target"]
        self.steps = 0
        return self._obs()

    def set_board(self, grid, target):
        """评估模式: 直接摆盘。"""
        self.grid = [row[:] for row in grid]
        self.target = target
        self.steps = 0
        return self._obs()

    def step(self, action):
        n_before = len(tiles_of(self.grid))
        new_grid, moved = forward_move(self.grid, ACTIONS[action])
        self.steps += 1
        reward = -0.05
        done = False
        if not moved:
            reward -= 0.2
        else:
            self.grid = new_grid
            n_after = len(tiles_of(self.grid))
            reward += 0.3 * (n_before - n_after)
            t = tiles_of(self.grid)
            if len(t) == 1 and next(iter(t.values())) == self.target:
                reward += 10.0
                done = True
        if self.steps >= EP_CAP:
            done = True
        return self._obs(), reward, done


class PolicyNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(2, 64, 3, padding=1)
        self.conv2 = nn.Conv2d(64, 64, 3, padding=1)
        self.fc = nn.Linear(64 * MAX * MAX, 256)
        self.pi = nn.Linear(256, 4)
        self.v = nn.Linear(256, 1)

    def forward(self, x):
        h = F.relu(self.conv1(x))
        h = F.relu(self.conv2(h))
        h = F.relu(self.fc(h.flatten(1)))
        return self.pi(h), self.v(h).squeeze(-1)


# ---------------- PPO ----------------

def train(args):
    dev = torch.device("cuda" if torch.cuda.is_available() and not args.smoke else "cpu")
    curriculum = SMOKE_CURRICULUM if args.smoke else CURRICULUM
    pool = LevelPool(curriculum, rng=random.Random(args.seed))
    torch.manual_seed(args.seed)
    random.seed(args.seed)

    net = PolicyNet().to(dev)
    opt = torch.optim.Adam(net.parameters(), lr=3e-4)
    lvl, total_ep = 0, 0
    ckpt_path = os.path.expanduser("~/models/fold_rl/policy.pt")

    if args.resume and os.path.exists(ckpt_path):
        ck = torch.load(ckpt_path, map_location=dev)
        net.load_state_dict(ck["model"])
        opt.load_state_dict(ck["optim"])
        lvl = min(ck.get("level", 0), len(curriculum) - 1)
        total_ep = ck.get("episodes", 0)
        print(f"[resume] level={lvl} episodes={total_ep}")

    N, T = args.n_envs, args.rollout
    envs = [FoldEnv(pool) for _ in range(N)]
    obs = torch.stack([e.reset(lvl) for e in envs]).to(dev)
    succ_win = deque(maxlen=300)
    steps_win = deque(maxlen=300)
    losses = []
    t_end = time.time() + args.hours * 3600
    gamma, lam, clip = 0.99, 0.95, 0.2
    last_log_ep = 0

    while time.time() < t_end and (not args.max_episodes or total_ep < args.max_episodes):
        # ---- 采样 rollout ----
        buf_obs = torch.zeros(T, N, 2, MAX, MAX, device=dev)
        buf_act = torch.zeros(T, N, dtype=torch.long, device=dev)
        buf_logp = torch.zeros(T, N, device=dev)
        buf_rew = torch.zeros(T, N, device=dev)
        buf_done = torch.zeros(T, N, device=dev)
        buf_val = torch.zeros(T, N, device=dev)
        for t in range(T):
            with torch.no_grad():
                logits, val = net(obs)
                dist = torch.distributions.Categorical(logits=logits)
                act = dist.sample()
                logp = dist.log_prob(act)
            buf_obs[t], buf_act[t], buf_logp[t], buf_val[t] = obs, act, logp, val
            nxt = []
            for i, e in enumerate(envs):
                o, r, d = e.step(act[i].item())
                buf_rew[t, i] = r
                buf_done[t, i] = float(d)
                if d:
                    total_ep += 1
                    win = (len(tiles_of(e.grid)) == 1
                           and next(iter(tiles_of(e.grid).values())) == e.target)
                    succ_win.append(1.0 if win else 0.0)
                    if win:
                        steps_win.append(e.steps)
                    o = e.reset(lvl)
                nxt.append(o)
            obs = torch.stack(nxt).to(dev)
        with torch.no_grad():
            _, last_val = net(obs)
        # ---- GAE ----
        adv = torch.zeros(T, N, device=dev)
        gae = torch.zeros(N, device=dev)
        nv = last_val
        for t in reversed(range(T)):
            mask = 1.0 - buf_done[t]
            delta = buf_rew[t] + gamma * nv * mask - buf_val[t]
            gae = delta + gamma * lam * mask * gae
            adv[t] = gae
            nv = buf_val[t]
        ret = adv + buf_val
        b_obs = buf_obs.reshape(T * N, 2, MAX, MAX)
        b_act, b_logp = buf_act.reshape(-1), buf_logp.reshape(-1)
        b_adv = adv.reshape(-1)
        b_adv = (b_adv - b_adv.mean()) / (b_adv.std() + 1e-8)
        b_ret = ret.reshape(-1)
        # ---- PPO update ----
        idx = torch.randperm(T * N, device=dev)
        mb = T * N // 4
        for _ in range(4):
            for s in range(0, T * N, mb):
                j = idx[s:s + mb]
                logits, val = net(b_obs[j])
                dist = torch.distributions.Categorical(logits=logits)
                logp = dist.log_prob(b_act[j])
                ratio = (logp - b_logp[j]).exp()
                pl = -torch.min(ratio * b_adv[j],
                                ratio.clamp(1 - clip, 1 + clip) * b_adv[j]).mean()
                vl = F.mse_loss(val, b_ret[j])
                loss = pl + 0.5 * vl - 0.01 * dist.entropy().mean()
                opt.zero_grad()
                loss.backward()
                nn.utils.clip_grad_norm_(net.parameters(), 0.5)
                opt.step()
                losses.append(loss.item())
        # ---- 日志 / 课程升级 / checkpoint ----
        if total_ep - last_log_ep >= (50 if args.smoke else 1000):
            last_log_ep = total_ep
            sr = sum(succ_win) / max(len(succ_win), 1)
            ms = sum(steps_win) / max(len(steps_win), 1)
            r_, c_ = curriculum[lvl][:2]
            print(f"ep={total_ep} lvl={lvl}({r_}x{c_}) succ={sr:.2f} "
                  f"avg_steps={ms:.1f} loss={sum(losses[-50:])/max(len(losses[-50:]),1):.3f}",
                  flush=True)
            if len(succ_win) >= 300 and sr >= 0.65 and lvl < len(curriculum) - 1:
                lvl += 1
                succ_win.clear()
                steps_win.clear()
                print(f"[curriculum] 升级到 level {lvl}: {curriculum[lvl]}", flush=True)
                obs = torch.stack([e.reset(lvl) for e in envs]).to(dev)
            if not args.smoke:
                os.makedirs(os.path.dirname(ckpt_path), exist_ok=True)
                torch.save({"model": net.state_dict(), "optim": opt.state_dict(),
                            "level": lvl, "episodes": total_ep}, ckpt_path)
    if not args.smoke:
        os.makedirs(os.path.dirname(ckpt_path), exist_ok=True)
        torch.save({"model": net.state_dict(), "optim": opt.state_dict(),
                    "level": lvl, "episodes": total_ep}, ckpt_path)
        print(f"[done] checkpoint -> {ckpt_path}")
    return net, losses, succ_win


# ---------------- 评估 ----------------

def rollout(net, env, grid, target, greedy, dev, cap=60):
    obs = env.set_board(grid, target).unsqueeze(0).to(dev)
    for step in range(1, cap + 1):
        with torch.no_grad():
            logits, _ = net(obs)
        a = (logits.argmax(-1) if greedy
             else torch.distributions.Categorical(logits=logits).sample()).item()
        o, _, done = env.step(a)
        t = tiles_of(env.grid)
        if len(t) == 1 and next(iter(t.values())) == target:
            return step
        if done or env.steps >= cap:
            return None
        obs = o.unsqueeze(0).to(dev)
    return None


def evaluate(args):
    dev = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    ckpt_path = os.path.expanduser("~/models/fold_rl/policy.pt")
    net = PolicyNet().to(dev)
    ck = torch.load(ckpt_path, map_location=dev)
    net.load_state_dict(ck["model"])
    net.eval()
    print(f"[eval] checkpoint level={ck.get('level')} episodes={ck.get('episodes')}")
    with open(args.eval) as f:
        levels = json.load(f)
    env = FoldEnv(LevelPool(CURRICULUM))
    results = []
    for k, lv in enumerate(levels):
        best = None
        for _ in range(8):
            s = rollout(net, env, lv["grid"], lv["target"], True, dev)
            if s and (best is None or s < best):
                best = s
        for _ in range(8):
            s = rollout(net, env, lv["grid"], lv["target"], False, dev)
            if s and (best is None or s < best):
                best = s
        results.append({"idx": k, "target": lv["target"],
                        "par_upper": lv.get("par_upper"),
                        "rl_par": best if best else "unsolved"})
        print(f"  #{k} target={lv['target']} par_upper={lv.get('par_upper')} "
              f"rl_par={best if best else 'unsolved'}")
    out = args.eval.rsplit(".", 1)[0] + "_rl_par.json"
    with open(out, "w") as f:
        json.dump(results, f, indent=1)
    print(f"[eval] 结果 -> {out}")


def main():
    try:
        os.nice(10)  # GPU 队列友好
    except OSError:
        pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--resume", action="store_true")
    ap.add_argument("--eval", type=str, default=None, help="pool.json 路径")
    ap.add_argument("--hours", type=float, default=6.0)
    ap.add_argument("--smoke", action="store_true", help="4x4 CPU 冒烟")
    ap.add_argument("--max-episodes", type=int, default=0)
    ap.add_argument("--n-envs", type=int, default=16)
    ap.add_argument("--rollout", type=int, default=128)
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()
    if args.eval:
        evaluate(args)
        return
    if args.smoke:
        args.max_episodes = args.max_episodes or 200
        args.rollout = 64
        args.hours = min(args.hours, 0.5)
    net, losses, succ = train(args)
    if args.smoke:
        half = len(losses) // 2
        l1 = sum(losses[:half]) / max(half, 1)
        l2 = sum(losses[half:]) / max(len(losses) - half, 1)
        sr = sum(succ) / max(len(succ), 1)
        print(f"[smoke] loss 前半={l1:.3f} 后半={l2:.3f} 成功率={sr:.2f}")


if __name__ == "__main__":
    main()
