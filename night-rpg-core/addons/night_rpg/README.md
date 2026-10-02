# night_rpg (shared core)

Shared Godot 4.7 RPG core for the night titles (Elena first, Room 704 next). Design:
`ops/rpg_conversion/DESIGN.md`. A game includes it by symlinking this folder to
`res://addons/night_rpg` and declaring the autoloads (see play/elena-rpg-godot/project.godot):

    RPG   = res://addons/night_rpg/state.gd
    Loc   = res://addons/night_rpg/loc.gd
    Sound = res://addons/night_rpg/sound.gd
    main scene: res://addons/night_rpg/ui/main.tscn

The core knows no game by name. It reads `res://data/game.json`, `data/nights/*.json`,
`data/story/*.json`, `data/strings.json` and `data/art_manifest.json`.

| file | what |
|---|---|
| rules.gd | standoff rules (pure functions) — the sim and the screen call the same code |
| policy.gd | the "normal player" used by the sim, tests and screenshot runs |
| state.gd | content + run state, stats/levels/skills/items/trust, saves (6 slots, 0 = autosave) |
| loc.gd | string tables, 7 language columns, EN fallback |
| sound.gd | music crossfade, ambience, sfx, per-language voice |
| art.gd | manifest lookup: first existing path wins, so new plates replace placeholders |
| skin.gd | Theme from the game's UI art + fonts (CJK fallback held) |
| ui/stage.gd | 2.5D room: parallax plate/figure/dust, CanvasModulate, Light2D torch + lamps |
| ui/main.gd | flow: title, nights, rooms, hotspots, event steps, battles, level-up, menus |
