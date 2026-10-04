# Audio credits — night_rpg core foley

Every file in `addons/night_rpg/foley/` (shared by all six RPGs through the addon symlink). Machine-readable copy: `addons/night_rpg/foley/manifest.json`. Rebuild: `ops/foley/synth_ambience.py` then `ops/foley/build_foley.py` (in ~/Products).

Licences in use: **CC0 1.0** only (Kenney packs, downloaded 2026-10-04 from kenney.nl; and our own procedural DSP, dedicated CC0). Kenney credit is optional; we give it anyway: *Sound effects by Kenney (www.kenney.nl), CC0.*

Loudness: one-shots >=0.6 s loudnorm I=-20 LUFS (soft/cloth -26, UI -24), shorter one-shots peak-normalised (-3 / -9 soft / -8 UI dBFS) because loudnorm cannot gate under ~0.6 s; ambience beds I=-30 LUFS, 32 s seamless loops. All Vorbis q6, 48 kHz stereo.

Voice tracks are dialogue only: no foley is ever mixed into a voice take; all SFX play on the SFX bus.

| file | source | original file(s) | author | licence | processing |
|---|---|---|---|---|---|
| amb_boiler.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_cafe.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_cellar.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_club.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_hotel_hall.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_library.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_office.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_rain_street.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_rain_window.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_room_tone.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_server.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_street_night.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| amb_wind.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-30 LUFS, TP=-6, LRA=7, Vorbis q6, seamless loop |
| belt.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | clothBelt.ogg | Kenney (kenney.nl) | CC0 1.0 | I=-26 LUFS, TP=-3, LRA=11, Vorbis q6 |
| book_close.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | bookClose.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| cloth_1.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | cloth1.ogg | Kenney (kenney.nl) | CC0 1.0 | I=-26 LUFS, TP=-3, LRA=11, Vorbis q6 |
| cloth_2.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | cloth2.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -9 dBFS, Vorbis q6 |
| cloth_3.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | cloth3.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -9 dBFS, Vorbis q6 |
| cloth_soft_1.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | cloth4.ogg | Kenney (kenney.nl) | CC0 1.0 | low-passed, quieter; peak-normalised to -9 dBFS, Vorbis q6 |
| cloth_soft_2.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | cloth2.ogg | Kenney (kenney.nl) | CC0 1.0 | low-passed, slowed; peak-normalised to -9 dBFS, Vorbis q6 |
| coins.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | handleCoins.ogg | Kenney (kenney.nl) | CC0 1.0 | I=-20 LUFS, TP=-1.5, LRA=11, Vorbis q6 |
| desk_slam.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | impactWood_heavy_001.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| door_close_1.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | doorClose_1.ogg | Kenney (kenney.nl) | CC0 1.0 | I=-20 LUFS, TP=-1.5, LRA=11, Vorbis q6 |
| door_close_2.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | doorClose_2.ogg | Kenney (kenney.nl) | CC0 1.0 | I=-20 LUFS, TP=-1.5, LRA=11, Vorbis q6 |
| door_close_3.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | doorClose_3.ogg | Kenney (kenney.nl) | CC0 1.0 | I=-20 LUFS, TP=-1.5, LRA=11, Vorbis q6 |
| door_metal.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | metalLatch.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| door_open_1.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | doorOpen_1.ogg | Kenney (kenney.nl) | CC0 1.0 | I=-20 LUFS, TP=-1.5, LRA=11, Vorbis q6 |
| door_open_2.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | doorOpen_2.ogg | Kenney (kenney.nl) | CC0 1.0 | I=-20 LUFS, TP=-1.5, LRA=11, Vorbis q6 |
| embrace_1.ogg | Kenney — RPG Audio + Impact Sounds (1.0) (https://kenney.nl/assets/rpg-audio) | cloth1.ogg, impactSoft_medium_000.ogg | Kenney (kenney.nl) | CC0 1.0 | cloth rustle + soft body impact, low-passed; I=-26 LUFS, TP=-3, LRA=11, Vorbis q6 |
| embrace_2.ogg | Kenney — RPG Audio + Impact Sounds (1.0) (https://kenney.nl/assets/rpg-audio) | cloth3.ogg, impactSoft_medium_002.ogg | Kenney (kenney.nl) | CC0 1.0 | cloth rustle + soft body impact, low-passed; peak-normalised to -9 dBFS, Vorbis q6 |
| hit_1.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | impactPunch_medium_000.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| hit_2.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | impactPunch_medium_001.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| hit_3.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | impactPunch_medium_002.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| hit_heavy_1.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | impactWood_heavy_000.ogg, impactPunch_heavy_000.ogg | Kenney (kenney.nl) | CC0 1.0 | desk slam + heavy thud; I=-20 LUFS, TP=-1.5, LRA=11, Vorbis q6 |
| hit_heavy_2.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | impactWood_heavy_002.ogg, impactPunch_heavy_001.ogg | Kenney (kenney.nl) | CC0 1.0 | desk slam + heavy thud; peak-normalised to -3 dBFS, Vorbis q6 |
| hit_soft_1.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | impactSoft_medium_001.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -9 dBFS, Vorbis q6 |
| hit_soft_2.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | impactSoft_medium_003.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -9 dBFS, Vorbis q6 |
| paper_1.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | bookFlip1.ogg | Kenney (kenney.nl) | CC0 1.0 | I=-20 LUFS, TP=-1.5, LRA=11, Vorbis q6 |
| paper_2.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | bookFlip2.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| paper_3.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | bookFlip3.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| paper_place_1.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | bookPlace1.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| paper_place_2.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | bookPlace2.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| search_1.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | handleSmallLeather.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| search_2.ogg | Kenney — RPG Audio (1.0) (https://kenney.nl/assets/rpg-audio) | handleSmallLeather2.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| steps_carpet_1.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | footstep_carpet_000.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -9 dBFS, Vorbis q6 |
| steps_carpet_2.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | footstep_carpet_001.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -9 dBFS, Vorbis q6 |
| steps_stone_1.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | footstep_concrete_000.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| steps_stone_2.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | footstep_concrete_001.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| steps_stone_3.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | footstep_concrete_002.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| steps_wood_1.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | footstep_wood_000.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| steps_wood_2.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | footstep_wood_001.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| steps_wood_3.ogg | Kenney — Impact Sounds (1.0) (https://kenney.nl/assets/impact-sounds) | footstep_wood_002.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -3 dBFS, Vorbis q6 |
| ui_click.ogg | Kenney — Interface Sounds (1.0) (https://kenney.nl/assets/interface-sounds) | click_002.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -8 dBFS, Vorbis q6 |
| ui_close.ogg | Kenney — Interface Sounds (1.0) (https://kenney.nl/assets/interface-sounds) | close_001.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -8 dBFS, Vorbis q6 |
| ui_confirm.ogg | Kenney — Interface Sounds (1.0) (https://kenney.nl/assets/interface-sounds) | confirmation_001.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -8 dBFS, Vorbis q6 |
| ui_open.ogg | Kenney — Interface Sounds (1.0) (https://kenney.nl/assets/interface-sounds) | open_001.ogg | Kenney (kenney.nl) | CC0 1.0 | peak-normalised to -8 dBFS, Vorbis q6 |
| writing_1.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-26 LUFS, TP=-3, LRA=11, Vorbis q6 |
| writing_2.ogg | procedural DSP, ops/foley/synth_ambience.py | — | BlazeCore (own work) | CC0 1.0 (own work, dedicated) | I=-26 LUFS, TP=-3, LRA=11, Vorbis q6 |

## Japanese adult-RPG practice (DLsite) — note, 2026-10-04

- Top DLsite RPG/ADV titles credit SE in the readme/store page as 「効果音：効果音ラボ」, 「On-Jin ～音人～」, 「ポケットサウンド」, 「魔王魂」 etc. — Japanese royalty-free libraries, credit usually requested or customary.
- 効果音ラボ terms (https://soundeffect-lab.info/agreement/, FAQ): bundling as in-app sounds is allowed (even as loose files), but selling/distributing the sounds themselves or content where the SFX is the main point counts as redistribution. Our per-title SFX demo montages would sit close to that line, so we did **not** use those libraries; CC0 avoids the question entirely (and DLsite's English shelf readers do not expect JP credits).
- Practice we followed from those titles: per-location ambience beds, footsteps + door on room change, page/paper on documents, soft hits in battle, and restrained cloth/rustle cues in intimate scenes (no explicit body sounds).
