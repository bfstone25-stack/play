# Flutter edition music

## Compute routing

- Queue all training on the Windows GPU.
- Before light music or image inference, check free Windows/WSL VRAM and use
  that GPU when the job fits; it is materially faster than Pop.
- Keep Pop primarily available for its LLM inference services. Run lightweight
  generation there only when it can safely coexist or Windows is unavailable.
- ACE-Step music inference is lightweight (roughly 2–3 GB observed working
  allocation on Pop), but peak allocation must still be checked rather than
  assumed.

`generate_bgm_pop.py` uses Pop's existing ComfyUI-native ACE-Step 1.5 workflow
to render five instrumental, 72-second edition themes. It performs inference
only; it does not train or use the LLM services.

The shared identity is a restrained four-note romantic motif. Instrumentation,
tempo, space, and cultural mood are specified independently for EN, ZH, JA, ES,
and PT-BR. Prompts explicitly reject chiptune, 8-bit, bright synth leads, vocals,
and market clichés.

Generated Opus files appear under Pop's
`~/ComfyUI/output/flutter_bgm/`. Audition them before copying approved takes to
`frontend/audio/bgm/{edition}.ogg`. The web player remains silent when an
approved file is absent.

`generate_scene_bgm_pop.py` expands this into a regional × dramatic-scene
matrix. Every edition receives `main`, `conversation`, `intimate`, and
`tension` versions. The first EN take is retained separately as `melancholy`;
it is not the English market's main identity theme.

`tension` means romantic decision pressure—the inner approach/retreat before a
chapter-ending choice—not an argument. A future `conflict` cue should be used
for an actual rupture or confrontation.

`generate_ja_bgm_v2_pop.py` renders five non-destructive Japanese auditions
under `flutter_bgm/ja-v2-{scene}`. They use a more melodic Japanese
women-oriented drama language: a shared singable leitmotif, Japanese pop-drama
harmonic motion, piano/string narrative swells, and scene-specific pacing. V2
files must be auditioned before replacing the approved `ja-{scene}` matrix.

`generate_my_moment_pop.py` renders one original, hummable relationship theme
per edition as `{edition}-my-moment`. Unlike the scene underscore matrix, these
are complete instrumental pop-song forms whose memorable chorus melody can be
re-orchestrated throughout a route and fully revealed when the couple chooses
each other. They are not modeled on or melodically derived from an existing
song.

`generate_my_moment_vocal_pilot.py` contains the approved English Adult
Contemporary vocal pilot. `generate_my_moment_vocals.py` contains separately
authored Mandarin, Japanese, Spanish, and Brazilian Portuguese lyrics and
market-specific production briefs; these are localized songs, not
translations.
