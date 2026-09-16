# Room 704

A one-night adult visual novel. Night auditor, a guest who pays cash, and a man in a car
across the street. Three routes, two uncensored scenes, three endings; about 25 minutes.

Built as the second product after Elena, with every Elena day-one mistake fixed up front:
AI disclosure inside the game, a title that is legible at thumbnail size, a motivated story,
and both monetisation tracks wired before release rather than after.

- `game/scripts/09_dist.rpy` — one build, four behaviours (paid / itch_web / ads_web / offline_ads)
- `web/room704_ads.js` — the timed sponsor overlay for the browser ad track
- art pipeline: `ops/room704_art/room704_gen.py`
- build: `APP=room704 DIST_VAR=ROOM704_DIST ADS_JS=room704_ads.js ADS_CFG=ops/room704_ads_config.js ops/renpy_web_build.sh play/room-704 <sdk> <out>`
