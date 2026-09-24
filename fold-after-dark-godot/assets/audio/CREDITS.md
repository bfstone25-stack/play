# FOLD: After Dark audio credits

Every sound effect and the music loop in this directory is **synthesised from code**
(sine partials, filtered noise) by `ops/nutaku/fold_f2p/make_sfx.py`. No sample, loop or
recording from anyone else is used. Our own work, released CC0.

| file | what | source | licence |
|---|---|---|---|
| `select.ogg` | pickup blip: a short upward chirp | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `move.ogg` | a slide: soft lowpassed whoosh with a tiny thump | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `merge.ogg` | bubbly pop: fast rising sine plus a bell glint | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `combo1.ogg` | combo step 1: bell on C6 with a fifth above, rising per step | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `combo2.ogg` | combo step 2: bell on D6 with a fifth above, rising per step | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `combo3.ogg` | combo step 3: bell on E6 with a fifth above, rising per step | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `combo4.ogg` | combo step 4: bell on G6 with a fifth above, rising per step | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `combo5.ogg` | combo step 5: bell on A6 with a fifth above, rising per step | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `star1.ogg` | star 1 lands: chime on G5 with shimmer | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `star2.ogg` | star 2 lands: chime on C6 with shimmer | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `star3.ogg` | star 3 lands: chime on E6 with shimmer | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `tick.ogg` | score count-up tick: a 15 ms click at 2.4 kHz | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `fly.ogg` | reward flying to the HUD: rising sparkle sweep | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `bump.ogg` | counter bump: two-note ding (B5 then E6) | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `win.ogg` | level win: marimba arpeggio up to a held bell chord | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `start.ogg` | level start: two-note 'ta-da' with a whoosh | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |
| `bgm.ogg` | background loop: 8 bars, 112 bpm, I-V-vi-IV marimba, pad, bell and shaker | synthesised by `ops/nutaku/fold_f2p/make_sfx.py` | CC0 (our own) |

The older cues in `scripts/sfx.gd` (slide, invalid, merge1-3, unity1-3, logo, ambience)
are synthesised at runtime by that script. They are our own port of the web game's Web
Audio oscillators, also CC0.

## Voice

`assets/voice/companion/*.ogg`: Coco, the companion. Rendered with CosyVoice2-0.5B
(Apache-2.0) on the RTX 3060 by `ops/nutaku/fold_f2p/companion_voice.py`, cloned
zero-shot from the reference clip `ops/vn_voice_seeds/f_young_sultry.wav`. That clip was
cut from LibriSpeech train-clean-100, speaker 2007 (Sheila Morton), chapter 132570: a
LibriVox public-domain recording, corpus licensed **CC BY 4.0** (attribution: Panayotov
et al., "LibriSpeech", OpenSLR SLR12). The lines are our own writing. The per-clip ASR
check is in `ops/nutaku/fold_f2p/companion_asr.json`.
