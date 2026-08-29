# Midnight Pawn & Crypt（午夜典当行与地下密室）

Standalone **2D Pixel Hybrid RPG** (Godot 4.7): daytime micro pawn shop + night mini crypt dungeon.

See [`PIVOT.md`](PIVOT.md) for naming (Option A), 15-min run loop, keep/kill, and monetization.

## Run

```bash
/tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --path null-shrine
```

Smoke (headless):

```bash
xvfb-run -a /tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path null-shrine -s res://tests/smoke.gd
```

## Controls

**Day (shop)**

- Select a curio, appraise its exact value/curse/demand, set low/fair/high pricing, and display up to three items.
- Call each customer, compare demand and offer, then accept honestly, conceal the curse, or reject.
- After two customers per day, select one curio and descend.

**Night (dungeon)**

- WASD / arrows, tap-to-move, or on-screen D-pad — cross each room.
- Reach the encounter mark, then Strike, Guard, Remember, or use the carried curio.
- Clear two rooms per night to bank marks and loot. Defeat loses only unbanked rewards and activates recovery.

**Run**

- Complete loop: inheritance/tutorial → Day 1 → Night 1 (2 rooms) → Day 2 → Night 2 (2 rooms) → final appraisal.
- Final Heart decision: Sell, Seal, or Keep. Economy, trust, mercy, curse, health, and optional loot shape three outcomes.
- Pause, restart, and title controls are always clickable/touchable.

## Legacy

Archived NULL//SHRINE H5 cabinet: [`legacy-h5/`](legacy-h5/). Not the forward product.

Sibling pivots (other agents): Crazy Rant → 3D Horror VN; Beat Monday → 2D Pixel Horror VN.

## Product boundary

The free build is a complete scored 15–20 minute run with both shop days, both crypt nights, four rooms, recovery, and all three endings. A possible paid expansion may add deeper floors, more curios/customers, and challenge modifiers; it does not gate or interrupt this run.
