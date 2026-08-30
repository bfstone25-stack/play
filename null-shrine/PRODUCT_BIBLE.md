# Midnight Pawn & Crypt — Executable Product Bible

## Product contract

- Standalone Godot 4.7 2D pixel micro-management + mini-dungeon RPG.
- One complete deterministic run: inheritance → Day 1 → Night 1 → Day 2 → Night 2 → final appraisal.
- Normal first-read target: 15–20 minutes without countdowns, energy gates, forced idle time, or random room order.
- Mouse, touch, and keyboard are all complete input routes. Dungeon movement supports tap destination, on-screen D-pad, and WASD/arrows.
- Internal viewport is 640×360, nearest-filtered, integer-scaled.

## Free slice and potential expansion

The free build is the complete run described here: five customer transactions including tutorial, eight principal curios plus the tutorial bell, four crypt rooms, loss recovery, score/rank, and three endings. Nothing interrupts play with monetization.

A potential paid expansion may add deeper floors, more curios and customers, claimant stories, and challenge modifiers. It does not remove, shorten, or gate this free run. Do not publish this build to itch.

## Player promise

At midnight, pawnbroker Nara Quill enters the crypt beneath her inherited shop to reclaim objects sold by the dead. Every object has two prices: what the living offer and what the dead demand.

The player reads exact integer value, curse, demand, and identity clues; chooses a price posture; decides whether to warn buyers; carries one synergistic curio into each night; risks only unbanked rewards; and finally decides who owns the Heart of the Crypt.

## Starting state and invariants

| Resource | Start | Invariant |
|---|---:|---|
| Gold | 18 | integer, never below 0 |
| Health | 12 | 0–12; defeat invokes recovery |
| Resolve | 5 | 0–8; powers Remember/negotiation |
| Curse | 0 | nonnegative; modifies score/result copy |
| Shelf | 0/3 | only identified inventory IDs |
| Marks | 0 | banked and unbanked tracked separately |

- Inventory IDs are unique.
- Sale removes the item from inventory and shelf exactly once, then adds the quoted integer offer.
- Rejection preserves item and gold.
- Extraction converts all unbanked loot to inventory and moves unbanked marks to the bank.
- Defeat deletes only unbanked loot/marks, preserves sales/inventory/trust/mercy, returns Nara with 3 health, and adds 5 emergency gold.
- Day 1 defeat continues to Day 2. Night 2 defeat continues to final appraisal with a cracked Heart. No dead-run state exists.

## Curated curios

| ID | Curio | Value | Curse | Demand | Dungeon / economy property |
|---|---|---:|---:|---|---|
| `wedding_ring` | Brass Wedding Ring / 黄铜婚戒 | 18 | 0 | memory | return to Widow Voss for peaceful Mercy route |
| `bone_key` | Bone-handled Key / 骨柄钥匙 | 14 | 1 | bone | opens Night 2 optional Saint's Tooth cache |
| `music_box` | Child's Music Box / 缺音八音盒 | 20 | 1 | memory | deals 4 to Bell Warden and interrupts its first action |
| `dueling_pistol` | Cracked Dueling Pistol / 裂纹决斗手枪 | 24 | 1 | weapon | carried item deals 3 deterministic damage |
| `black_ledger` | Black Ledger / 黑账簿 | 30 | 3 | occult | doubles room marks and adds curse |
| `moon_coin` | Moon Coin / 月蚀银币 | 16 | 1 | occult | Night 1 extracted loot and occult stock alternative |
| `saints_tooth` | Saint's Tooth / 无名圣齿 | 22 | 2 | bone | optional key cache; deals 4 to Debt Hand, worsens spikes |
| `crypt_heart` | Heart of the Crypt / 地窖之心 | 40 | 4 | occult | final sell/seal/keep decision |
| `rusted_bell` | Rusted Bell / 锈蚀招魂铃 | 10 | 0 | memory | scripted opening appraisal and fair tutorial sale |

Appraisal reveals identity, exact value, curse, demand, and one clue. Pricing rotates through:

- `LOW`: 80% of value; reliable but leaves money behind.
- `FAIR`: 100% of value.
- `HIGH`: 125% of value; strongest with matching demand.

Matching demand adds each customer's premium.

## Customers

1. **Bell Child** — scripted 10G tutorial transaction teaches appraisal, fair pricing, and sale.
2. **Mara Voss / 寡妇·玛拉** — memory demand, +8 premium, responds to compassionate pricing.
3. **Orin Pike / 收藏家·奥林** — bone demand, +6 premium, refuses cursed stock without enough identity evidence.
4. **Tamsin Reed / 老兵·塔姆辛** — weapon demand, +7 premium; one explicit negotiation spends 1 Resolve and adds 5G; honest warning adds trust/value.
5. **Ivo Glass / 秘术师·伊沃** — occult demand, +10 premium, values danger and exploits timid prices.

For every non-tutorial offer the player chooses honest acceptance, concealed acceptance, or rejection. Honest cursed sales add Trust; concealment adds Curse/debt. The player must resolve two customer offers before each descent.

## Required sequence

### Opening — inheritance and tutorial

Aunt Elsa's will establishes the two prices. Appraise and fairly sell the Rusted Bell to the Bell Child. Receive five starting curios and enter Day 1.

### Day 1 — first tradeoffs

Appraise, price, and display selected starting stock. Resolve Mara and Orin. Choose one remaining curio to carry. This is the first build decision.

### Night 1 — first extraction

#### Room 1: Receipt Stair / 收据阶梯

- Movement across a tiled room.
- Risk: loose violet receipt curse drains 1 Resolve and adds 1 Curse.
- Receipt Moth: 4 HP, 1 damage, 3 marks.
- Reward: unbanked Moon Coin.

#### Room 2: Widow's Niche / 寡妇壁龛

- Claimant risk: Widow Voss, 7 HP, 2 damage, 5 marks.
- Carrying the Wedding Ring enables return for 3 Mercy without combat.
- Otherwise Strike, Guard, Remember, or carried-curio action.
- Clearing the room extracts and banks both rooms.

### Day 2 — identity and negotiation

New loot persists into inventory. Resolve Tamsin and Ivo. Tamsin exposes the explicit Resolve-for-gold negotiation. Honest/concealed curse disclosure and the keep/sell/carry decision affect trust, curse, economy, and available Night 2 route.

### Night 2 — elite, hazard, and core

#### Room 3: Ossuary Market / 骸骨集市

- Hazard risk: visible bone spikes deal 2 health.
- Debt Hand Elite: 8 HP, 2 damage, 7 marks.
- Bone Key opens optional Saint's Tooth cache.

#### Room 4: Foreclosure Chapel / 止赎礼拜堂

- Curse risk: every third Bell Warden turn drains Resolve and adds Curse.
- Bell Warden: 12 HP, 3 damage, 10 marks.
- Music Box interrupts first action; carried curios create deterministic build differences.
- Reward: Heart of the Crypt; extraction enters final appraisal.

### Final appraisal

- `SELL`: +40G (or cracked 20G); outcome **Dawn Broker / 晨曦掌柜**. Gold and concealed debt alter the result.
- `SEAL`: costs up to 12G, adds 4 Mercy, clears 3 Curse; outcome **Quiet Seal / 静默封印**. Mercy and clues strengthen the result.
- `KEEP`: adds 2 Curse; outcome **Midnight Keeper / 午夜守藏人**. Health, curse, survival, and optional relic decide who is in control.

## Combat, score, and feedback

- Strike deals 2.
- Guard reduces the current incoming hit by 1 and restores 1 Resolve.
- Remember costs 2 Resolve, deals 1 (2 against claimant), and adds an identity clue.
- Carried action uses a listed synergy; otherwise heals 2.
- Enemies act deterministically after non-lethal player actions.

Score is exact integer arithmetic:

`gold + banked_marks×2 + mercy×12 + trust×8 + rooms_cleared×15 + clues×3 + survival + optional_relic − curse×4 − recoveries×10 + ending_bonus`

Ranks: S ≥190, A ≥145, B ≥100, C ≥60, otherwise D.

Feedback includes generated shop bell, appraisal, coin, hit, loot, UI tick, looping shop/crypt ambience, pulsing pixel effects, and restrained hit shake. Audio is generated at runtime and requires no licensed assets.

## UX and safety

- Main actions use ≥40 internal pixels, equivalent to ≥44 CSS pixels at supported landscape phone scaling.
- Text panels scroll when needed; progression actions remain outside the scroll area.
- Pause exposes Resume, Restart Run, and Title. Result exposes Replay and Title.
- Accessibility `APPROACH` bypasses precise room navigation without bypassing combat/risk systems.
- The ledger log records recent identity, sale, extraction, hazard, combat, and recovery consequences.

## Verification gate

- `tests/smoke.gd`: fresh-cache scene compile, shelf/economy guards, customer transactions and negotiation, full four-room completion, inventory persistence, loot loss/banking, recovery, and all three outcomes.
- `tests/timed_run.gd`: same deterministic full route at measured normal bilingual reading/movement cadence; must complete in 900–1200 seconds.
- `tests/visual_walkthrough.gd`: title, opening, both shops, all four rooms, final appraisal, and result screenshots.
- Godot 4.7.2 import/run and Web export must pass on blazeubuntu's RTX 3060 provider.
- Desktop 1280×720 and landscape-phone 640×360 renders must keep progression controls visible.
- HTTPS route must return HTML 200, `application/wasm`, and byte-range 206.
