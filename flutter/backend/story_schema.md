# Flutter 故事引擎 · 架构设计

## 问题
现在只有 `persona`（人设描述）→ 自由聊天 → 没有推进感、没有期待、没有结局。
用户判断：**"这是调情瞎聊 app，不是游戏"**。

## 目标
让玩家体验**完整的爱恨情仇心路历程**：相遇 → 试探 → 心动 → 误会/危机 → 抉择 → 结局。
每个男主一条**完整故事线**，有章节、有事件、有分支、有多结局。

---

## 数据结构

```jsonc
{
  "id": "ethan",
  "persona": "...",            // 保留：说话风格与人格底色
  "story": {
    "title_zh": "顶楼的那盏灯",
    "title_en": "The Light on the Top Floor",
    "chapters": [
      {
        "id": "ch1",
        "title_zh": "误闯",
        "aff_gate": 0,               // 进入本章所需好感度
        "opening_zh": "你走错了楼层。这层只有一间办公室还亮着灯——",
        "scene_zh": "深夜的写字楼顶层",
        "goal": "让他记住你的名字",   // 本章目标（玩家可见，制造方向感）

        "beats": [                    // 章节内的关键事件节点
          {
            "id": "b1",
            "trigger": { "turns": 3 },        // 触发条件：对话3轮后
            "event_zh": "他的手机响了。他扫了一眼，按掉，然后第一次正眼看你。",
            "inject": "You just declined a call from the board chair. You are testing whether she notices you chose her over it."
          },
          {
            "id": "b2",
            "trigger": { "turns": 7, "aff_min": 4 },
            "event_zh": "电梯停电了。整栋楼只剩应急灯。",
            "inject": "The power just cut. You are calm, but you move slightly closer to her without saying why."
          }
        ],

        "choices": [                  // 章末抉择（真正的分支点）
          {
            "id": "c1",
            "prompt_zh": "他问：'你为什么还没走？'",
            "options": [
              { "text_zh": "我在等电梯修好。", "aff": 0,  "flag": "guarded",  "next": "ch2_slow" },
              { "text_zh": "因为你还没走。",   "aff": +3, "flag": "bold",     "next": "ch2_fast" },
              { "text_zh": "（沉默地看着他）", "aff": +1, "flag": "mystery",  "next": "ch2_slow" }
            ]
          }
        ],
        "exit_aff": 8                 // 达到此好感度可进入下一章
      }
    ],

    "endings": [
      { "id": "he",     "aff_min": 60, "flags_any": ["bold","trust"],
        "title_zh": "顶楼的灯为你亮着", "text_zh": "..." },
      { "id": "be",     "aff_max": 25,
        "title_zh": "他终究只是个陌生人", "text_zh": "..." },
      { "id": "secret", "aff_min": 80, "flags_all": ["trust","sacrifice"],
        "title_zh": "他辞掉了整个帝国", "text_zh": "..." }
    ]
  }
}
```

---

## 运行时逻辑

```
玩家发消息
  ↓
① 读取当前 chapter + 已触发的 beats + flags
  ↓
② 判断是否触发新 beat（turns / aff / flag 条件）
   → 若触发：把 event 文本推给玩家 + 把 inject 注入 system prompt
  ↓
③ 组装 system prompt =
     persona（人格底色）
   + 当前章节 scene + goal
   + 已发生的 beats 摘要（故事记忆）
   + 当前 beat 的 inject（让模型知道"此刻该演什么"）
   + stage_rule（好感度对应的亲密度）
  ↓
④ LLM 生成回复
  ↓
⑤ 达到 exit_aff → 弹出章末 choices（玩家真正做选择）
   → 记录 flag + aff 变化 → 进入下一章
  ↓
⑥ 最终章后按 aff + flags 匹配 ending
```

**关键**：LLM 依然负责"怎么说"（自然对话），
但**"发生什么"由故事结构决定**——这是从陪聊变成游戏的分界线。

---

## 与视频选题的对应（反向原则）

选题矩阵里写的名场面 **必须在故事里真实存在**，否则观众被视频吸引来却玩不到。

| 视频选题 | 对应故事 beat |
|---|---|
| "他把伞全部倾过来，自己半边身子湿透" | 顾言 ch2 · 雨夜送她回家 |
| "Liam冲进火场前把手表塞给你" | Liam ch4 · 火灾危机 |
| "凌晨2点他发来'睡了吗'" | 通用 beat · 深夜试探 |
| "傅深带你回老宅，佣人喊'少夫人'他没纠正" | 傅深 ch3 · 身份确认 |
| "陆星野把最后一句歌词唱给台下第七排" | 陆星野 ch5 · 公开告白 |

**每个男主 5-6 章 × 6 人 = 30-36 章**，是可控的工作量（我写，你审）。

---

## 分阶段落地

**P0（先验证）**：给 1 个男主（Ethan）写完整 5 章故事线 + 运行时逻辑，跑通体验。
**P1**：扩到 6 个男主。
**P2**：加入 CG 立绘（DreamShaper 生成关键场景图）+ 结局收藏册。
