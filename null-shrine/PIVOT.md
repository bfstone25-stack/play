# Midnight Pawn & Crypt（午夜典当行与地下密室）

**Status:** Product pivot from Null-shrine (`null-shrine/`) Catharsis-style H5 cabinet arcade → standalone **2D Pixel Hybrid RPG** (micro shop + mini dungeon).  
**Working title pick:** **Option A** (Blaze may override).  
**Engine:** Godot 4.7.x **2D** (portfolio-aligned with Across the Hall / Late Inspection; see Engine choice).  
**Scope v0:** Proof of day↔night hybrid loop · one closed ~15 min micro-run design · shop stock/appraise stub · one-room dungeon move/loot stub.

---

## Why this name (A)

**A — Midnight Pawn & Crypt（午夜典当行与地下密室）**

- **Pawn（典当）** = daytime micro-management (stock, appraise, price).  
- **Crypt（地下密室）** = night mini-dungeon dive for materials / curios.  
- One title carries both halves of the Moonlighter-style loop; bilingual itch slug is brandable (`midnight-pawn-crypt`).  
- Slightly eerie-cozy tone fits pixel shop + dungeon dopamine without locking into pure horror VN (siblings own that lane).

Rejected for now:

- **B The Lost Alchemist's Tavern（遗落炼金酒馆）** — strong cozy hook, but “tavern” undersells the dungeon half and drifts toward cooking/social sim.  
- **C Curio Shop: Night Shift（怪谈古董店）** — clear shop fantasy; “Night Shift” is softer than an explicit crypt dive and overlaps generic shop-sim naming.

Sibling pivots (out of scope here): Crazy Rant → 3D Horror VN; Beat Monday → 2D Pixel Horror VN.

---

## Engine choice

| Option | Fit | Decision |
| --- | --- | --- |
| Keep Vanilla JS Canvas H5 | Old Null-shrine stack; good for cabinets, weak for tiled dungeon + shop UI scenes | Reject for new product |
| Godot 4.7 2D | Native pixel scenes, input, day/night scene swap; matches monorepo Godot portfolio | **Chosen** |

Legacy H5 cabinet lives under `legacy-h5/` as archive only (not the playable product path).

---

## Positioning

**Tags:** Pixel Art · RPG · Management · Mini Dungeon · Roguelite  

**Refs (micro scale):** Moonlighter · Loop Hero · Dave the Diver  

**Fantasy:** You run a tiny midnight pawn shop. By day you stock and appraise curios. By night you descend a pocket crypt for materials. Each **run** is a closed 15-minute loop — high feedback, low long-term grind — designed for replay and a later paid full version.

---

## Core loop (15-minute closed single-run)

Target cadence (design, not hard timers in v0 scaffold):

| Phase | ~Time | Player job | Feedback |
| --- | --- | --- | --- |
| **Day — Shop** | ~2 min | Stock shelves, appraise 1–3 items, set/accept prices, decide what to hold overnight | Gold tick, rarity reveal, “customer” stub buy |
| **Night — Crypt** | ~3 min | Enter mini pixel dungeon, move, pick loot / materials, extract | Loot pops, risk stub, bag fill |
| **Repeat** | 2–3 day/night pairs | Improve stock quality; optional soft risk (overstock / cursed curio) | Run score climbing |
| **Settle** | ~1 min | Sell leftovers, score run, unlock cosmetic / next-run seed stub | End card → Restart |

**v0 prototype proves:** Day shop UI (stock + appraise) ↔ Night one-room dungeon (move + pick loot) ↔ one closed micro-run (Day → Night → Day settle → Complete).

Cut from scope intentionally: deep skill trees, multi-floor procedural megadungeons, long meta progression, live-ops economy.

---

## Shop actions (Day)

| Action | v0 stub | Full later |
| --- | --- | --- |
| **Stock** | Place inventory curios onto 3 shelf slots | Layout, display themes, limited shelf space |
| **Appraise** | Reveal hidden value / tag (mundane / curious / cursed) | Minigame or tool upgrades |
| **Price / Sell** | One-click sell at appraised value | Haggling customers, time-of-day demand |
| **Hold overnight** | Leave 1 item on shelf (risk/reward stub) | Cursed items mutate; theft / blessing events |
| **Close shop → Crypt** | Phase toggle | Animated shutter + loadout select |

---

## Dungeon beats (Night)

| Beat | v0 stub | Full later |
| --- | --- | --- |
| Enter crypt | Fade to dungeon room | Descending stairs vignette |
| Move | WASD / arrows · pixel CharacterBody2D | Dash, lantern cone |
| Loot | 3–5 pickups → bag | Materials, curios, traps, tiny elite |
| Extract | Reach exit / “Return” | Optional deeper room for high risk |
| Soft fail | Leave early with partial bag | Soft death → lose unsecured loot only |

No complex long-term leveling in the free slice — power is mostly **what you found tonight** and **what you dared to stock tomorrow**.

---

## Run structure (design target)

```
TITLE
  → RUN START (seed / starting gold + 2 junk curios)
  → DAY 1 shop (~2m) stock/appraise/sell
  → NIGHT 1 crypt (~3m) loot
  → DAY 2 shop (~2m) appraise night loot, sell, optional hold
  → NIGHT 2 crypt (~3m)
  → DAY 3 settle (~2m) final sales
  → RUN COMPLETE (score = gold + curios appraised + extracts)
  → Restart / Quit
```

Scaffold implements a **compressed** closed run: Day → Night → Day settle → Complete (same verbs; fewer cycles).

---

## Monetization note

| Slice | Contents | Goal |
| --- | --- | --- |
| **Free** | One closed 15-min run · tiny shop · 1–2 crypt rooms · short ending card | Prove loop dopamine; itch/demo traffic |
| **Paid full (later)** | More crypt biomes, customer personalities, cursed economy, cosmetics, daily seed, optional endless night | Wishlist → buy; no predatory gacha |

No StarDust / cabinet gacha in this product. Keep economy readable: gold + bag + shelf.

---

## Keep / kill from old Null-shrine

| Keep (spirit / assets) | Kill / archive |
| --- | --- |
| Collectible / “relic & curio” fantasy (`legacy-h5/.../collectibles.js` tone) | Galton / flipper / peg physics board |
| Short-session “cabinet dopamine” mindset → reframed as 15-min run | Focus / Overdrive / chain multiplier combat loop |
| Bilingual ZH/EN copy habit | 2.5D cabinet HUD, heat core, launch charge |
| Name memory: “Null-shrine” as folder / internal slug only | Publishing as NULL//SHRINE arcade cabinet |

Legacy playable H5 remains under `legacy-h5/` for reference; it is **not** the forward product.

---

## Prototype map (this PR)

```
null-shrine/
  PIVOT.md              ← this file
  README.md             ← run instructions
  project.godot         ← Godot 4.7 2D
  scenes/main.tscn      ← hybrid loop host
  scripts/*.gd          ← shop, dungeon, run, player, loot
  tests/smoke.gd        ← headless smoke
  legacy-h5/            ← archived NULL//SHRINE cabinet
```

**Controls (v0):**

- Shop: click Stock / Appraise / Sell / **Enter Crypt**
- Dungeon: **WASD** move · walk over loot · **E** or exit pad to return
- HUD: phase, gold, bag, run timer stub

---

## Out of scope / siblings

- Do not modify `crazy-rant/`, `beat-monday/`, or `across-hall/` beyond optional one-line cross-links.  
- Late Inspection / Across the Hall remain separate Godot products; patterns may be copy-adapted, never path-coupled.
