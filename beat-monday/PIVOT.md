# Floor 13: Night Shift（13楼夜班）

**Status:** Product pivot from Catharsis cabinet 03 (Beat Monday) → standalone itch-style **2D Pixel Horror VN**.  
**Working title pick:** Option **C** (Blaze may override).  
**Engine:** Godot 4.7.x 2D (aligned with portfolio horror direction; not Catharsis H5).  
**Scope v1:** ~25–35 min micro-script · cubicle / desk investigation · uncanny coworker dialogue · flee-vs-obey choices · **3 endings**.

---

## Why this name (C)

**C — Floor 13: Night Shift（13楼夜班）**

- **13楼** is instant horror brand recall (itch slug, store art, thumbnail) and matches the “haunted office tower escape” pitch.
- **夜班** keeps Beat Monday’s workplace DNA while flipping daytime grind → alone after hours.
- Distinct from sibling apartment titles (Across the Hall · Late Inspection) which own residential clocks / 验房.

Rejected for now:

- **A Overtime: 11:59 PM（深夜加班：11点59分）** — strongest desk-clock hook; overlaps Across the Hall’s stuck-time motif; keep as chapter / clock UI motif.
- **B Resignation Letter（辞职信的代价）** — strong ending-theme, weaker first-look brand and exploration fantasy.

Clock copy can still use **11:59** as an in-world pressure beat without making it the title.

---

## Product exit from Catharsis / old Beat Monday

Beat Monday shipped (and stalled) as an **office fighting game**: Vanilla JS + Canvas 2D, punch/kick/special, campaign ladder Intern → Director. Live path: `play.blazecore.dev/beat-monday/`. Assets under `frontend/assets/` (stage, fighter sprites, title art).

Catharsis plan (`catharsis/PLAN.md`) had locked Beat Monday as cabinet 03: portrait H5, StarDust, “Vanilla JS + Canvas 2D … No React, no Unity, no backend” — originally one-thumb survivor-like, later implemented as a fighter instead. That format is underperforming.

This pivot is an **intentional exit** from the shared Catharsis cabinet contract:

| Was (Catharsis 03 / fighter H5) | Becomes |
| --- | --- |
| Canvas 2D fighter / arcade Monday | Standalone Godot 4.7 **2D pixel horror VN** |
| Hub cabinet slug + StarDust adjacency | itch-style title (do not publish until asked) |
| Punch / kick / special typing-free combat | Point-click + pure choice UI (zero typing) |
| Daytime office ring | Late night Floor 13 · alone · flee vs obey |

`frontend/` is **legacy archive** (kept for art reuse + historical smoke). New playable surface is the Godot project at this folder root (`project.godot`).

Crazy Rant → 3D Horror VN is owned by a **sibling agent / separate PR**. Null-shrine still awaits Blaze’s brief. Do not merge those scopes into this branch.

---

## Positioning

**Tags:** Pixel Art · 2D · Horror · Interactive Fiction · Point & Click  

**Refs:** Dead Plate · Yuppie Psycho · The Supper  

**Loop:** Pixel desk / cubicle investigation → uncanny coworker dialogue → choose **flee** vs **obey** → flags → ending.

**Palette:** Blood-red + eerie-blue 2D pixel shaders over retained office chrome (desktop UI cues, cubicle geometry, fluorescent hum).

---

## Scene list (v1 · ~30 min)

| # | Scene | Player goal | Pressure beat |
| --- | --- | --- | --- |
| 0 | Title / click-to-enter | Enter Floor 13 | Fluorescent buzz · clock 23:47 |
| 1 | Cubicle desk | Click PC, sticky note, drawer | Cursor blinks alone |
| 2 | Slack / mail on CRT | Read overtime mandate | Coworker status: “active” but empty floor |
| 3 | Hall / water cooler | Optional inspect | Elevator ding with no doors |
| 4 | Coworker silhouette | Dialogue: stay late / leave | Face never fully loads |
| 5 | Manager voice (intercom) | Choice: obey overtime / flee stairs | Red emergency wash |
| 6 | Stairwell / elevator | Choice: stairs / elevator | Blue emergency wash |
| 7 | Ending beat | One of three closings | Hard cut / credits stub |

Prototype scaffold covers **desk room + hotspots + one coworker dialogue + one flee/obey choice + red/blue shader stub**. Full script later.

---

## Choice structure (flee vs obey)

Flags are boolean / enum; no soft “maybe” branches. Zero typing — buttons only.

```
DESK_DONE → DIALOGUE_COWORKER
  listen → FLAG_TRUST
  dismiss → FLAG_SUSPECT

INTERCOM → CHOICE_OBEY (stay and finish the deck / leave now)
  obey → FLAG_OBEY
  flee → FLAG_FLEE

EXIT_ROUTE → CHOICE_ROUTE (stairs / elevator) [requires FLAG_FLEE]
  stairs + FLAG_SUSPECT → Ending A (Witness / out alive wrong)
  elevator + FLAG_TRUST → Ending B (Complicit / forever night shift)
  stairs + FLAG_TRUST OR elevator + FLAG_SUSPECT → Ending C (Floor 13 loop)
```

**Three endings (locked intent):**

1. **Witness** — You leave with the resignation draft; the building forgets your badge number.
2. **Complicit** — You finish the deck; Slack shows you “active” forever; clock stuck at 11:59.
3. **Loop** — Elevator opens on Floor 13 again. Same sticky note. Same blinking cursor.

Exact copy TBD in script pass (zh-Hans first, then EN).

---

## Shader / lighting plan

| Beat | Visual | Audio |
| --- | --- | --- |
| Desk calm | Cool fluorescent · slight grain · blue desk lamp | Hum 50–60 Hz |
| Mail read | CRT phosphor cyan | Soft key tick |
| Coworker | Palette crush toward blue; eyes red emissive pixels | Voice low-pass |
| Obey path | Blood-red full-screen wash (shader param) | Hum rises |
| Flee path | Eerie-blue strobe / exit signs | Elevator ding wrong pitch |
| Choice UI | Mouse free, vignette up | Hum duck −4 dB |
| Ending | Red or blue crush + scanlines | Silence → one Slack ping |

Shader stub: `shaders/horror_palette.gdshader` (red/blue mix + scanlines + vignette). Grain optional via `shaders/grain.gdshader`.

---

## Assets to reuse vs rebuild

**Reuse from `frontend/` (legacy):**

- `assets/sprites/stage-office.webp` — mood / bg reference; may downsample to pixel plate later
- Fighter portrait stills (`assets/fighters/*.webp`) — coworker silhouette / dialogue mug placeholders
- Title / promo color DNA (yellow accent → demote; keep office desk chrome cues)
- i18n language dock pattern (zh / en) — reimplement in Godot later

**Rebuild in Godot 2D:**

- Pixel cubicle room (procedural ColorRect tiles in prototype; replace with Aseprite later)
- Point-click `Hotspot` areas (desk PC, sticky, drawer, coworker)
- Dialogue panel + two-button choice UI
- Red/blue horror palette shader
- Clock HUD (can show 23:47 → 11:59 motif from option A without renaming)

**Do not keep as product surface:**

- Fighter combat loop (`game.js` punch/kick/special)
- Versus / campaign ladder UI
- Catharsis StarDust / gacha expectations

---

## Prototype acceptance (this PR)

- [x] Godot 4.7 project boots `scenes/main.tscn`
- [x] Dark pixel office desk room
- [x] Point-click hotspots (PC / sticky / coworker)
- [x] Dialogue + flee-vs-obey choice UI
- [x] Red/blue horror palette shader stub
- [x] Headless / xvfb smoke screenshot

**Not in this PR:** full 30 min script, three polished endings, itch upload, Crazy Rant / Null-shrine / Across the Hall work.

---

## Next (for Blaze / follow-up agents)

1. Lock or override title (C recommended; A clock motif retained in-world).
2. Write full zh-Hans + EN micro-script (~30 min, 3 endings).
3. Replace procedural tiles with true pixel art plates; wire flags → endings.
4. Store page art + itch draft when asked.
5. Null-shrine still awaits Blaze’s brief; Crazy Rant handled on sibling branch/PR.
