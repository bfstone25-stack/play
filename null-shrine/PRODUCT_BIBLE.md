# Midnight Pawn & Crypt — Product Bible

## Production contract

- Standalone Godot 4.7 2D pixel shop-and-dungeon run.
- Products 1 and 2 passed verification; Product 3 production is authorized.
- Full run target: 15–20 minutes. Opening/tutorial, Day 1 shop, Night 1 rooms 1–2, Day 2 shop, Night 2 rooms 3–4, final appraisal, and score recap.
- The free slice is the entire two-day/two-night run with all three endings. A potential paid expansion may add deeper crypt floors, additional curios, customers, and challenge modifiers, but never removes or interrupts this complete run.
- No gacha, premium currency, energy timer, or randomized paid advantage.

## Player promise

At midnight, pawnbroker **Nara Quill** may enter the crypt beneath her shop to reclaim objects sold by the dead. Every item has two prices: cash value and memory cost. Gear sold before a run funds supplies; gear carried into the crypt can unlock a claimant’s memory and improve the ending score.

Core loop:

1. Appraise five fixed pawn lots.
2. Sell, keep, or restore each lot.
3. Buy supplies from exact table.
4. Descend through ordered rooms.
5. Spend tools/resources or fight encounters.
6. Extract at room 3 (free/full) or defeat room 6 boss (full).
7. Convert recovered marks and resolve customer memories.

## Starting state and economy

Starting resources:

| Resource | Amount | Rule |
|---|---:|---|
| Crowns | 18 | shop currency; unspent crowns add 1 score each |
| Health | 10 | zero ends run |
| Resolve | 5 | dialogue/ward resource; max 8 |
| Torch | 8 | lose 1 on entering each crypt room; zero adds +1 enemy damage |
| Pack slots | 6 | relics and consumables each occupy one slot |

### Opening pawn lots

| Lot | Sell | Keep effect | Restore cost/reward |
|---|---:|---|---|
| Brass wedding ring | 8 crowns | +1 Resolve at Widow encounter | pay 3 crowns; +2 Mercy score |
| Bone-handled key | 5 | opens Ossuary cache without lockpick | pay 2; reveals room-5 safe route |
| Child’s music box | 7 | cancels Bell Warden’s first attack | pay 4; +3 Mercy |
| Cracked dueling pistol | 10 | ranged attack: 3 damage, 2 shots | pay 5; claimant becomes boss ally |
| Black ledger | 12 | doubles marks from room 4–6 but +1 Dread per room | pay 6; exposes ending debt |

Choosing `restore` immediately deducts cost, keeps the item’s memory token but not its combat effect, and occupies no pack slot. A player cannot both sell and use an item.

### Supply table

| Supply | Price | Slot | Exact effect | Limit |
|---|---:|---:|---|---:|
| Tallow torch | 3 | 1 | +4 Torch, may exceed start to max 12 | 2 |
| Red tonic | 4 | 1 | heal 4, action does not consume combat turn | 2 |
| Salt packet | 3 | 1 | cancel one spirit attack or clear one curse | 2 |
| Iron lockpick | 2 | 1 | open one locked cache/shortcut | 2 |
| Grave chalk | 5 | 1 | create one room checkpoint; return there at 1 health once | 1 |
| Blank receipt | 4 | 1 | convert one relic’s memory cost to 0 | 1 |

Buyback: sold opening lots may be bought back before descent for `sell value + 3`; no buyback after entering the crypt.

## Combat arithmetic

- Nara base attack: 2 damage.
- Enemy attacks are deterministic patterns listed per encounter.
- Each combat turn: choose `Strike`, item, relic action, or `Guard`.
- Guard reduces next damage by 1 (minimum 0) and restores 1 Resolve, max 8.
- Resolve action `Remember` costs 2 and deals 1 damage plus bypasses armor; against claimants it also reveals one line of memory.
- Flee is available only where listed and costs 2 Torch.
- Victory grants exact Grave Marks. Every 4 Marks converts to 1 crown after extraction; remainder scores 1 point each.
- Death loses carried relics and Marks. Restored-lot Mercy score persists for recap but there is no metaprogression in the free build.

## Fixed run sequence

### Shop — 23:52 (4–6 minutes)

Tutorial copy:

NARA: “Five pledges. One midnight. Sell what keeps the lamps lit; carry what the dead still need.”

Customer receipts provide final copy:

> WEDDING RING / pledged by E. Voss / “Hold until he remembers the song.”

> BONE KEY / no claimant address / teeth marks do not match a human jaw.

> MUSIC BOX / pledged for fever medicine / tune: six notes, last note missing.

> DUELING PISTOL / unloaded when received / two chambers now occupied.

> BLACK LEDGER / owner listed as NARA QUILL / date: tomorrow.

After lot decisions, supply purchase, and pack confirmation:

NARA: “The gate takes a receipt or a name. Tonight it can have the receipt.”

### Room 1 — Receipt Stair

Torch −1. Tutorial enemy: **Receipt Moth**, HP 4.

Pattern: attack 1, attack 1, steal 1 random unprotected crown, repeat. `Remember` reveals: “It ate the ink, not the debt.”

Reward: 2 Marks; choose one:

- Wax Seal: next locked object opens free; one use.
- Moth Wing: +1 Torch now; worth 2 crowns on extraction.

Environmental interaction: wall receipt lists whichever opening lot the player sold for the highest value.

### Room 2 — Widow’s Niche

Claimant encounter, **Widow Voss**, HP 7, armor 1.

Opening:

WIDOW: “You priced the ring by weight. Did you weigh the promise?”

Routes:

- If carrying wedding ring: spend 1 Resolve, return ring; no combat, +3 Mercy, 4 Marks.
- If ring restored: memory token answers automatically; no combat, +2 Marks, +1 Health.
- Otherwise combat pattern: attack 2, mourn (Nara loses 1 Resolve), attack 2.

At 3 HP, `Remember` reveals husband’s tune. If music box is carried, it plays and ends fight peacefully for +2 Mercy.

Reward cache locked with bone key/lockpick: Red Tonic and 3 crowns.

### Room 3 — Bell Gate / Free boundary

Mini-boss **Bell Warden**, HP 12, armor 1.

Pattern:

1. Toll: 2 damage.
2. Echo: repeats damage actually dealt by previous Toll.
3. Silence: disables items next turn.
4. Repeat.

Music box cancels first Toll and breaks armor permanently. Salt cancels Echo. Pistol bypasses armor.

At victory: 8 Marks and **Gate Clapper** relic (slot 1; once per later fight, interrupt an enemy action).

Extraction choice:

- `Return to shop`: available in all editions; ends run as **Safe Ledger**.
- `Descend`: full edition only.

Free edition end card:

> THE LOWER CRYPT CONTINUES IN THE FULL GAME.  
> This free run is complete: appraisal, preparation, three rooms, mini-boss, extraction, and score are unrestricted.  
> Full game adds three rooms, five relics, final boss, and ascension rules. No progress timer or paid currency.

No purchase button interrupts gameplay. Store link appears only on recap.

### Room 4 — Ossuary Market

Three stalls; player can perform exactly one trade:

| Trade | Cost | Gain |
|---|---|---|
| Teeth broker | 3 Health | Ivory Knife: base attack +1 |
| Candle child | 4 Torch | Pale Flame: Remember costs 1 this room and next |
| Empty stall | 6 crowns | Extra pack slot and 4 Marks |

Ambush after trade: two **Debt Hands**, each HP 5. Pattern alternates 1 damage and bind. Bound player must Strike the binding (2 HP) or spend Salt; otherwise cannot use items.

Black Ledger doubles this room’s 6-mark reward to 12 and adds 1 Dread.

### Room 5 — Powder Magazine

Route split determined by bone key restoration:

- Memory-safe route: claimant **Captain Ro** asks for pistol. Return it or show restoration token; receive Captain’s Favor and no combat.
- Main route: three powder shades, shared HP 15. Every third player Strike risks blast: 3 damage to both sides. Pistol shot detonates for 6 enemy damage and 2 player damage.

Captain dialogue:

CAPTAIN: “A weapon remembers the hand that refused it last.”

NARA: “Then remember refusal.”

Rewards: 7 Marks, one Red Tonic, **Silver Trigger** (pistol gains one shot if carried).

### Room 6 — Foreclosure Chapel

Final boss **The Appraiser**, HP 24, armor 2. Nara’s own Black Ledger lies open on altar.

Phase 1, HP 24–13:

1. Valuation: 2 damage.
2. Depreciation: lowest-price carried item is disabled.
3. Compound: 1 damage plus current Dread.
4. Repeat.

Phase 2, HP 12–1:

1. Repossess: remove one unprotected relic until fight ends.
2. Red Ink: 3 damage.
3. Audit: if player has fewer than 2 Resolve, deal 2; otherwise lose 2 Resolve.
4. Repeat.

Exact modifiers:

- Restored Black Ledger: boss armor becomes 0.
- Carried Black Ledger: rewards double, Dread +2 on phase transition.
- Captain’s Favor: at phase transition, 5 boss damage.
- Gate Clapper: can interrupt one Repossess.
- Blank Receipt: cancels one Depreciation/Repossess.

At 1 HP boss offers final choice:

- `FORECLOSE`: take the ledger, gain 24 Marks and 20 crowns, Mercy score becomes 0.
- `FORGIVE`: spend 3 Resolve (or all remaining Health down to 1 if insufficient), destroy ledger, gain 12 Marks and +5 Mercy.

## Win, loss, and results

### Win: Safe Ledger

Extract at room 3. Nara reopens shop at 00:21. Returned/restored claimants appear as warm silhouettes outside. Score and exact carried inventory display.

### Win: Dawn Balance

Defeat Appraiser and return. With `FORGIVE`, pawn tickets become letters the claimants can retrieve. With `FORECLOSE`, the shop expands but Nara’s name appears in the next opening lot.

### Loss: Repossessed

At Health 0 without unused Grave Chalk:

> NARA QUILL / CONDITION: FAIR / RESALE VALUE: 18 CROWNS

The next pawnbroker appraises Nara’s key. Results show room reached, damage source, and one actionable tip based on failure.

## Score table

| Component | Points |
|---|---:|
| Each extracted crown | 1 |
| Each unconverted Mark remainder | 1 |
| Each Mercy | 10 |
| Each claimant resolved peacefully | 15 |
| Bell Warden defeated | 20 |
| Appraiser defeated | 50 |
| Forgive choice | 30 |
| Foreclose choice | 20 |
| No tonic used | 15 |
| Finish with Torch ≥ 3 | 10 |
| Death | no completion bonuses |

Ranks: D `0–39`, C `40–79`, B `80–119`, A `120–169`, S `170+`.

## Content inventory

- 1 shop with five appraisal decisions and six supply SKUs.
- 6 fixed rooms; 8 enemy/claimant types; 2 bosses.
- 10 relics/consumable types, six opening-lot effects.
- 3 result scenes: Repossessed, Safe Ledger, Dawn Balance (with Forgive/Foreclose variants).
- 24 mandatory dialogue lines, 18 conditional claimant/item lines, 12 inspectable environment lines.

## Two-day production amendment (authoritative)

The sections below override the original six-room route wherever they conflict. The original encounter arithmetic remains a source for names, flavor, and deterministic balancing.

### Curated curios

| Curio | Base | Curse / risk | Demand / synergy |
|---|---:|---|---|
| Brass wedding ring | 18 | none | Widow pays +8; peaceful Widow Voss route |
| Bone-handled key | 14 | −1 value if identity stays hidden | Collector pays +6; opens Ossuary cache |
| Child's music box | 20 | Bell Warden wakes if overpriced | Child pays +8; interrupts Bell Warden |
| Cracked dueling pistol | 24 | −1 health if kept overnight | Veteran pays +7; 3-damage dungeon shot |
| Black ledger | 30 | +1 curse after each crypt room | Scholar pays +10; doubles mark rewards |
| Moon coin | 16 | haggler discount pressure | Mystic pays +7; ward against first curse |
| Saint's tooth | 22 | hazard damage +1 while carried | Collector pays +8; elite armor −1 |
| Heart of the Crypt | 40 | core ending risk | final choice: sell, seal, or keep |

Appraisal reveals identity, exact value, curse, and demand. Pricing is `low`, `fair`, or `high`; low prices sell reliably for −20%, fair prices follow demand, and high prices need matching demand or successful negotiation.

### Customers and transaction behavior

1. Mara Voss, widow: pays a premium for memory objects and accepts a compassionate price.
2. Orin Pike, collector: wants keys/bones, rejects cursed goods unless fully identified.
3. Tamsin Reed, veteran: wants weapons, negotiates high prices, respects a truthful curse warning.
4. Ivo Glass, mystic: wants occult goods, pays more as curse rises, but exploits low prices.
5. The Bell Child, tutorial customer: buys the Rusted Bell at a scripted fair price and teaches appraisal, pricing, and sale.

At least four customer offers occur in each normal run. Rejected or failed offers preserve the item; every offer shows demand, quoted price, and consequence.

### Required sequence and decisions

1. Opening inheritance and Bell Child tutorial sale.
2. Day 1: appraise starting stock, set shelf prices, serve Mara and Orin, then choose one curio to carry.
3. Night 1, Receipt Stair: movement tutorial, Receipt Moth combat, loose floor curse.
4. Night 1, Widow's Niche: Widow Voss claimant; ring/Resolve or combat; extraction banks loot and marks.
5. Day 2: identities and curses become legible, serve Tamsin and Ivo, negotiate one offer, choose keep/sell stock.
6. Night 2, Ossuary Market: spike hazard plus Debt Hand elite; Bone Key opens optional Saint's Tooth cache.
7. Night 2, Foreclosure Chapel: Bell Warden encounter, optional Moon Seal, Heart of the Crypt extraction.
8. Final appraisal: `SELL` the Heart, `SEAL` it, or `KEEP` it.

Meaningful decisions are: price posture, truthfully reveal a curse or conceal it, claimant mercy or force, optional relic risk, and final Heart disposition. Gold, mercy, curse, health, debt, survival, and those choices determine outcome text and score.

### Loss and recovery

- Health at zero loses all unbanked loot and unbanked marks and returns Nara to the shop with 3 health and 5 emergency crowns.
- Night 1 defeat continues to Day 2; Night 2 defeat proceeds to final appraisal with a cracked Heart worth less. There is no dead-run trap.
- Banked inventory, gold, prior sales, customer trust, and mercy never disappear on defeat.

### Three complete outcomes

- **Dawn Broker / 晨曦掌柜**: sell the Heart. High gold improves the business result; concealed curses add debt.
- **Quiet Seal / 静默封印**: seal the Heart. Requires sacrifice of gold and rewards mercy, identity clues, and low curse.
- **Midnight Keeper / 午夜守藏人**: keep the Heart. Survival, health, optional relic, and managed curse determine whether Nara controls it.

Every outcome is reachable on a deterministic route and includes an economy/inventory/survival breakdown, score, rank, and replay prompt.

### Timing and presentation contract

- A first normal read-and-play route contains 55–70 deliberate interactions, four movement rooms, four encounters, four customer offers, appraisal copy, and ending recap; measured target is 15–20 minutes without timers or forced waiting.
- Internal viewport is 480×270, nearest filtered, integer scaled. Shop and crypt use procedural pixel tiles, silhouettes, object icons, particles, and short restrained screen shake rather than placeholder ColorRects.
- Every action has a minimum 44 CSS-pixel-equivalent touch target. Dungeon supports keyboard, click/tap destination movement, and an on-screen directional pad plus action button.
- Pause, title, restart, tutorial/log history, and guarded progression are available without keyboard input.
- Audio cues include bell, appraisal shimmer, coin sale, hit, loot, and distinct shop/crypt ambience.

## Implementation checklist — PRODUCTION

- [x] Product 1 and Product 2 accepted; Product 3 authorized.
- [ ] Implement exact integer economy in one tested data resource.
- [ ] Build shop decisions, pack capacity, and buyback.
- [ ] Implement deterministic turn engine and enemy pattern display.
- [ ] Implement rooms in the fixed order and extraction gate.
- [ ] Implement free/full feature flag exactly at room 3.
- [ ] Implement score/rank and three result scenes.
- [ ] Test every item effect, economy invariant, room clear, death, extraction, and boss route.

## Acceptance criteria

1. Full run lasts 15–20 minutes and never depends on random room order.
2. Every number in runtime data matches the authoritative amendment.
3. A player can finish all four rooms with at least three distinct shop builds.
4. Night 2 can be completed with no pistol and with no Black Ledger.
5. Free build contains both days, both nights, all four rooms, all three outcomes, and complete scoring.
6. No monetization interrupts the shop, combat, death, or extraction loop.
7. Automated tests exhaustively validate purchases, pack capacity, enemy patterns, item effects, extraction, death, and score thresholds.
8. Loss recovery continues the run while removing only unbanked loot and marks.
