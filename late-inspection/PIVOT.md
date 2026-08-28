# Late Inspection: Flat 404（深夜验房：404室）

**Status:** Product pivot from Catharsis cabinet 06 (Crazy Rant) → standalone itch-style **3D Horror VN**.  
**Working title pick:** Option A (Blaze may override).  
**Engine:** Godot 4.7.x (aligned with Across the Hall).  
**Scope v1:** ~30 min micro-script · first-person walk + explore · dialogue / two-hard-choice nodes · **3 endings**.

---

## Why this name (A)

**A — Late Inspection: Flat 404（深夜验房：404室）**

- **验房** gives an immediate job: you are alone in a rental after hours, checking what management will not say on the phone.
- **404** is brandable (itch slug, store art, memes) and doubles as “empty / not found / wrong unit.”
- Keeps the rental/apartment DNA from Crazy Rant’s landlord-adjacent humor without staying a bullet-hell rant cabinet.

Rejected for now:

- **B The Tenancy Clause** — strong legal-horror hook, colder brand recall.
- **C Quiet Hours: 2:00 AM** — atmospheric, overlaps Across the Hall’s 02:17 clock beat.

---

## Product exit from Catharsis

Crazy Rant (`crazy-rant/`) was Catharsis cabinet 06: Vanilla JS Canvas phrase auto-battler. That format gets almost no attention.

This pivot is an **intentional exit** from the Catharsis H5 cabinet contract (portrait Canvas, StarDust, “no new engines”):

| Was (Catharsis 06) | Becomes |
| --- | --- |
| H5 Canvas bullet-hell rant | Standalone Godot 4.7 FP + VN |
| Hub cabinet slug | itch-style title (do not publish until asked) |
| StarDust / gacha kernel | None — narrative flags + endings only |

`crazy-rant/` keeps a stub README pointing here so monorepo links do not go dark.  
Beat Monday and Null-shrine are **out of scope** until Blaze briefs them.

Across the Hall stays a separate product / PR. Patterns are **copy-adapted** into this folder; runtime does **not** depend on `across-hall/` paths.

---

## Positioning

**Tags:** 3D · Psychological Horror · First-Person · Visual Novel · Atmospheric  

**Refs:** Fears to Fathom · Chilla's Art (apartment / konbini) · The Mortuary Assistant  

**Loop:** FP walk → find notes / stains / pipes → interact → dialogue panel → **two hard choices** → flag → ambient pressure (knock, drip) → ending.

**Lighting direction:** Kill flat lighting. Dim warm yellow practicals + sickly green bathroom / pipe local lights. Long shadows, low ambient.

---

## Scene list (v1 · ~30 min)

| # | Scene | Player goal | Pressure beat |
| --- | --- | --- | --- |
| 0 | Title / click-to-enter | Capture mouse | Quiet radiator hum |
| 1 | Corridor outside 404 | Read door notice, enter | Distant knock (other floor) |
| 2 | Entry / shoes | Find landlord note | Warm yellow ceiling flicker |
| 3 | Living room | Phone message / calendar | Knock closer |
| 4 | Kitchen / wet wall | Inspect pipe stain | Bloody drip SFX + green underlight |
| 5 | Bathroom | Neighbor note under door | Knock at *your* door |
| 6 | Bedroom | Choice: sleep / keep inspecting | Clock stuck near 02:00 |
| 7 | Doorway (optional) | Choice: open door / ignore | Silhouette / nothing |
| 8 | Ending beat | One of three closings | Hard cut / credits stub |

Prototype scaffold covers **1–4 + one choice node + knock/drip stubs**. Full script later.

---

## Choice structure (two-hard-choices)

Flags are boolean / enum; no soft “maybe” branches.

```
NOTE_LANDLORD → CHOICE_A (stay overnight / leave and come back at dawn)
  stay → FLAG_NIGHT
  leave → ENDING_EARLY (Ending C soft exit) OR loop back if script wants retry

PIPE_INSPECT → CHOICE_B (wipe stain / follow drip into wall cavity)
  wipe → FLAG_DENY
  follow → FLAG_SEE

DOOR_KNOCK → CHOICE_C (open / ignore)
  open + FLAG_SEE → Ending A (witness)
  ignore + FLAG_DENY → Ending B (complicit tenant)
  open + FLAG_DENY OR ignore + FLAG_SEE → Ending C (404 / empty loop)
```

**Three endings (locked intent):**

1. **Witness** — You saw what leases hide; you cannot renew as yourself.
2. **Complicit** — You wiped the evidence; the knock stops; the calendar advances one day you did not live.
3. **404** — Unit not found. You are standing in the corridor with a key that fits nothing.

Exact copy TBD in script pass.

---

## Lighting / SFX beats

| Beat | Visual | Audio |
| --- | --- | --- |
| Enter 404 | Warm yellow omni ~1.2 energy, soft shadow | Low 40 Hz drone |
| Pipe | Sickly green under-cabinet / floor bounce | Periodic drip (hi tone) |
| Neighbor note | Paper emissive peek | Paper rustle one-shot |
| Knock | None (offscreen) | Sparse knock 3D at door |
| Choice UI | Mouse free, vignette up | Drone duck −4 dB |
| Ending | Exposure crush / green wash | Silence then one knock |

---

## Reuse vs rebuild (Across the Hall)

**Copy-adapt into `late-inspection/` (done / planned):**

- FP `player.gd` / `player.tscn` (walk, look, interact ray, bob)
- `game_materials.gd` procedural plaster / wood / metal / paper
- `flicker_light.gd`, grain shader, `ui_font.gd`
- Ambience tone synthesis pattern (knock / drip / hum)
- Dim fog + warm ambient Environment recipe

**Rebuild / do not couple:**

- World layout → Flat 404 inspection set (not Episode I 401/402 hall story)
- HUD → add **two-button choice panel** (VN), not only note toast
- Narrative → rental inspection script, not “door across the hall”
- No tenant chase AI in v1
- No runtime `res://` or filesystem dependency on `across-hall/`

---

## Prototype acceptance (this PR)

- [x] Godot 4.7 project boots `scenes/main.tscn`
- [x] Dark apartment lighting (warm + green locals)
- [x] First-person walk
- [x] Interactable neighbor note
- [x] One two-choice VN node
- [x] Knock + drip ambience stub
- [x] Headless / xvfb smoke screenshot

**Not in this PR:** full 30 min script, three polished endings, itch upload, Beat Monday / Null-shrine pivots.

---

## Next (for Blaze / follow-up agents)

1. Lock or override title (A/B/C).
2. Write full zh-Hans + EN micro-script (~30 min, 3 endings).
3. Expand rooms to scene list 5–8; wire flags → endings.
4. Store page art + itch draft when asked.
5. Await separate briefs for Beat Monday and Null-shrine.
