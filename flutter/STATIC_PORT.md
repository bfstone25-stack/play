# Flutter 去后端化：静态剧情版进度

背景：`flutter/backend/app.py` 目前每一轮对话都实时调用远端 GPU 大模型（走
`llm_spot.sh` 调度器，抢共享 GPU），角色记忆/即时生成是卖点，但这意味着：
1. 没有那台 GPU 服务器，游戏就打不开；
2. 一些发布平台明确要求纯静态、不能有后端依赖。

2026-09-22 已与用户确认方向：改成**纯静态剧情**——不再有任何实时大模型调用，
把 `flutter/backend/stories/*.json` 里本来就已经写好的分支剧情（开场 + beats +
选项 + 结局）直接当成成品内容播放，前端本地状态机推进，零网络请求。

## 已完成

- `flutter/frontend/story_engine.js`：纯函数/小型状态机，从
  `flutter/backend/story_engine.py` 里"只跟静态播放相关"的部分移植过来
  （章节顺序、beat 顺序播放、每章一次选择、结局匹配 `match_ending`，逐字节对齐
  Python 版的优先级/aff_min/aff_max/flags_any/flags_all 逻辑）。
  - `turns`/`aff_min` 之类原本靠聊天轮数触发的门槛被去掉了：没有聊天，就没有
    "第几轮"。beats 直接按作者写好的顺序挨个展示。
  - 好感度改用 `affRange()` / `rescaleAff()`：把"这一路只靠每章那一次选择"能
    拿到的 aff 总和，线性映射回原作者按聊天轮数调好的 0–100 结局判定表，这样
    `endings` 表完全不用改，三档结局（最好/中等/遗憾）在纯选择制下依然都能走到。
  - 用 Node 跑过全部 9 条线（guyan/luxingye/fushen/ethan/liam/adrian/ren/mateo/
    caio）的"每章选最暖选项"和"每章选最冷选项"，确认每条线都能分别落到最好
    结局和最差结局，逻辑没问题。
- `flutter/frontend/stories/*.json`、`flutter/frontend/chars.json`：从
  `flutter/backend/` 复制过来，前端不再需要后端目录就能拿到剧情数据。
- `flutter/frontend/static-play.html`：一个独立的、完全离线可玩的新页面——
  选角色 → 开场 → beats 逐条展示 → 一次选择（三选一）→ 角色回应 → 下一章 →
  循环到最后一章 → 结局。用现有的 `portraits/v2/masters|variants` 立绘
  （master/smile/blush/love 四态），中英文本地切换（用剧情 JSON 里已有的
  `_zh`/`_en` 字段，不需要新翻译）。
  - 用 Playwright（Chromium headless，本容器内，没有开任何本机窗口）跑通了
    全部 9 条线的完整点击流程：无 404、无 JS 报错、全部正确落到各自结局。

## 还没做（下一步，按优先级）

1. **正式接入主入口**：`static-play.html` 目前是独立页面，还没接进
   `index.html` 的主菜单/多语言 edition 选择、音频系统（`audio.js`）、PWA
   离线缓存（`sw.js` 需要把 `stories/*.json` 和新用到的 `portraits/v2/variants`
   加进预缓存列表）、反馈与埋点（`tel_batch`/`game_feedback`，这两个本身就是
   纯前端到后端的分析上报，可以留着，跟游戏玩法解耦）。
2. **`index.html` 里的聊天路径**：`#inp` 自由输入 + `/say` `/say_stream` 那套
   还在，需要决定是整体删掉换成 `static-play.html` 的界面，还是先并存一段时间
   做 A/B。这是产品决定，不是技术决定，建议先问一句再动手。
3. **`flutter/backend/` 的去留**：`/choose` `/continue` 这两个端点其实只是把
   `story_engine.py` 的同一份逻辑包了一层 HTTP，静态版完全用不到了；`/say`
   `/say_stream` 还在被聊天路径用。如果聊天路径最终整体下线，后端和
   `ops/`（apps-suite 里那套 GPU 调度、`llm_spot.sh`）对 Flutter 这条产品线就
   可以完全解除依赖了——但这一步会影响 apps-suite 那边的部署脚本，需要跨仓库
   确认，这次没动。
4. `ren`/`mateo`/`caio` 只有 3 章（其余角色 5 章），`static-play.html` 对章节数
   量是自适应的，不需要额外处理，但值得留意这三条线的结局文本更短，可能需要
   补内容——这是内容问题，不是工程问题。
5. 没有找到 `ops/render_queue.py` / `ops/remote_playtest.sh` 或远端 GPU 盒子
   截图流水线（这两个脚本在 `play` 和 `apps-suite` 两个仓库里都不存在）。这次
   的验证改用本容器内 Playwright headless 跑通 9 条线 + 截图，没有连接
   `100.121.195.19`——纯静态剧情本来就不需要那台 GPU 盒子。如果确实需要建立
   截图/构建流水线，需要另外确认要不要新建这两个脚本。
