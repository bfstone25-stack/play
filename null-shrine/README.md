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

## Prototype controls

**Day (shop)**

- Stock — put bag curios on shelf slots  
- Appraise — reveal value / tag  
- Sell — cash out selected shelf item  
- Enter Crypt — day → night  

**Night (dungeon)**

- WASD / arrows — move  
- Walk over loot to pick up  
- E / Space or stand on Exit — return to shop  

**Run**

- Compressed closed loop: Day → Night → Day settle → Complete → Restart  

## Legacy

Archived NULL//SHRINE H5 cabinet: [`legacy-h5/`](legacy-h5/). Not the forward product.

Sibling pivots (other agents): Crazy Rant → 3D Horror VN; Beat Monday → 2D Pixel Horror VN.
