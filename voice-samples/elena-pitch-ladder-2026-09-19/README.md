# Elena pitch ladder -- 2026-09-19

The same four lines at three pitches. The direction pass is unchanged and
approved; the only thing that moves between rungs is where the voice sits.
Pick a rung and the full run of all three games follows from it.

**Listen across, not down.** Play `01` at each of the three pitches, then
`02` at each, and so on. A single rung on its own sounds like a voice; it is
the rung next to it that tells you whether it is the right one.

## The rungs

| rung | median f0 | per-line f0 | range (semitones) | centroid | >5 kHz |
|---|---|---|---|---|---|
| **260 Hz** | 261.8 Hz | 235.6-285.9 Hz | 8.61 median (4.17-12.88) | 2515 Hz | 0.119% |
| **300 Hz** | 293.1 Hz | 266.0-376.2 Hz | 9.29 median (3.75-26.68) | 2218 Hz | 0.144% |
| **317 Hz** | 316.4 Hz | 311.8-382.8 Hz | 5.89 median (4.66-7.22) | 2355 Hz | 0.289% |

**Does the range survive?** The direction pass took Elena from 3 semitones to
9-23 and that is not something a higher pitch is allowed to cost back. Against
the approved sample's 7.6-semitone median:

* 260 Hz -- 8.61 semitones (+1.02): holds -- wider than the approved take
* 300 Hz -- 9.29 semitones (+1.70): holds -- wider than the approved take
* 317 Hz -- 5.89 semitones (-1.70): **does not hold** -- flatter than the take this replaces

Every number is measured on the shipped `.ogg`, after loudness normalisation
and the vorbis encode -- not on the intermediate wav, and not on the pitch
that was asked for. The rung in the filename **is** its measured median.

Method: librosa `pyin`, fmin 80 Hz, fmax 600 Hz, voiced frames only; range is
`12*log2(p90/p10)` of the voiced f0, so it stays in semitones and a rung does
not score as more expressive merely for being higher.

## Chosen: the 260 Hz rung -- and what its name does not mean

Blaze picked this rung on 2026-09-19: "I think the 260 hertz version is the
best." The cast was re-aimed to it the same day, and `seed_260hz.wav` -- the
reference clip that produced these four takes -- is now checked in and copied
byte-for-byte into `ops/vn_voice_seeds/f_young_warm.wav` rather than re-derived,
because re-deriving it means hoping a second pitch shift lands on the same voice.

**The rung's name is the median of four lines, not a target for the corpus.**
Those four measure 285.9, 241.8, 281.8 and 235.6 Hz: a two-semitone spread, and
the two low readings are a two-word question and a breath-forward intimate line,
which are exactly the two lines chosen for being awkward. Cloned from the same
clip, the full corpus medians **285.5 Hz**, not 261.8 -- stable, 284.2 at 24
lines and 285.5 at 40, measured on shipped `.ogg` across the whole arc:

| stage | median f0 |
|---|---|
| pressure | 263 Hz |
| intimate | 267 Hz |
| tender | 282 Hz |
| rising | 289 Hz |
| opening | 295 Hz |

The arc is intact and nothing is chipmunked: range 9.05 semitones, wider than
this rung's own 8.61 and than the approved sample's 7.6, with the spectral
centroid at 2306 Hz against the rung's 2515.

So the thing that was approved is the *clip*, and the corpus that follows from
it sits about a semitone and a half above the number in the label. Do not read
"260 Hz" as a specification and re-aim a correct seed down to meet it -- that
would put the voice below what Blaze actually heard, in the direction of the
read he rejected. `ops/vn_voice_register.py` measures the real thing, stratified
by stage, which an unstratified sample gets wrong: the first ten lines off the
renderer are all openings and read 299 Hz.

## What it is being compared against

On this same measurement:

* the rejected first pass -- 30 Elena lines sampled -- **200 Hz**, 9.3 semitones
* the approved eight-line direction sample (2026-09-19) -- **222 Hz**, 7.6 semitones

These are lower than the 223 Hz and 256 Hz quoted earlier because those came
from the audit's `yin` pass, which scores unvoiced frames as pitch and reads
about 30 Hz high. Both sets of numbers agree on the direction and the gap;
only the scale differs. Everything on this page is one metric throughout.

## The lines

* **01 opening/wry** -- 'Professor Vance.'  
  directed: _Say this bright and young, wry._
* **02 rising/asking** -- 'And me?'  
  directed: _Say this bright and alert, rising at the end._
* **03 pressure/nervous** -- 'Maybe it was.'  
  directed: _Say this young and pressed, nervous._
* **04 intimate/breathless** -- "That's a very old-fashioned way to ask, Professor."  
  directed: _Say this close and breath-forward, breathless, slow, hushed._

The four are chosen because pitch does not behave the same way in all of
them: a bright opening, a two-word question, a pressed nervous line, and one
breath-forward intimate line, which is where raising the pitch costs the most.

## Per-clip

| file | f0 | range | transcript |
|---|---|---|---|
| `260hz_01_opening_wry.ogg` | 285.9 Hz | 4.17 st | 'Professor Vance?' |
| `260hz_02_rising_asking.ogg` | 241.8 Hz | 12.88 st | 'And me?' |
| `260hz_03_pressure_nervous.ogg` | 281.8 Hz | 10.37 st | 'Maybe it was?' |
| `260hz_04_intimate_breathless.ogg` | 235.6 Hz | 6.84 st | "That's a very old-fashioned way to ask, Professor." |
| `300hz_01_opening_wry.ogg` | 376.2 Hz | 3.75 st | 'Professor Vance.' |
| `300hz_02_rising_asking.ogg` | 266.0 Hz | 7.44 st | 'and me?' |
| `300hz_03_pressure_nervous.ogg` | 275.4 Hz | 26.68 st | 'Maybe it was' |
| `300hz_04_intimate_breathless.ogg` | 310.9 Hz | 11.14 st | "That's a very old-fashioned way to ask professor." |
| `317hz_01_opening_wry.ogg` | 320.0 Hz | 7.22 st | 'Professor Vance' |
| `317hz_02_rising_asking.ogg` | 382.8 Hz | 4.66 st | 'and me.' |
| `317hz_03_pressure_nervous.ogg` | 311.8 Hz | 6.55 st | 'Maybe it was.' |
| `317hz_04_intimate_breathless.ogg` | 312.7 Hz | 5.24 st | "That's a very old-fashioned way to ask, Professor." |

## Instruct leak

Every clip above was transcribed with Whisper `small` and checked for the
direction vocabulary appearing in the speech. No direction words in any transcript.

The direction strings are what makes that true, and they are still short:
across all 1090 rows of `ops/vn_voice_direction/elena.tsv`, mean 8.92 words,
max 15, min 6. Nothing about raising the pitch touched them.

## Artefact

Raising pitch is where a cloned voice stops sounding like a person, so three
things are measured rather than hoped for. `centroid` and the share of energy
above 5 kHz catch chipmunk formants; `tonality` -- the share of a long window
held by one bin -- catches the fp16 drone; `jump` catches a pitch tracker
losing the octave. For scale, the checks were run against two deliberately
broken clips first: a naive 1.5x resample of the intimate line from the
approved 2026-09-19 sample moved its centroid from
2267 to 2624 Hz and the >5 kHz share from 0.05% to 0.39%, and a synthetic
400 Hz tone scored 0.667 tonality against under 0.04 for every real take.

| rung | tonality (max) | f0 jump (max) | verdict |
|---|---|---|---|
| 260 Hz | 0.0123 | 0.027 | |
| 300 Hz | 0.0253 | 0.076 | |
| 317 Hz | 0.0314 | 0.026 | |

The verdict column is for the listener. The numbers say only that nothing
is measurably broken; they cannot say which of these is a girl of nineteen.

## Why there is no 335 Hz rung

Pitch is set on the reference clip, because that is the only pitch
control CosyVoice2 has -- and the model does not copy its prompt, it
lands under it and then stops following. Measured on these four lines:

| seed, measured (Hz) | lines came back at (Hz) |
|---|---|
| 259 | 222 |
| 372 | 262 |
| 394 | 293 |
| 398 | 316 |
| 455 | 317 |
| 551 (asked for) | the run hung |

A second, independent attempt to reach the 335 Hz the brief suggested. The seed was pushed to 455 Hz measured (+9.1 st over the raw clone) and the takes still came back at a 317 Hz median -- and far less coherent than the 317 rung in the ladder proper. A third attempt, from a seed asked for at 551 Hz, hung: the model ran away mid-line and was killed after 26 minutes on one four-word line.

`ceiling-retake/` is that second attempt, so the instability can be heard
rather than taken on trust. It medians to the same 317 Hz as the top rung
and holds nothing steady inside it:

| file | f0 | range |
|---|---|---|
| `retake_01_opening_wry.ogg` | 376.2 Hz | 4.09 st |
| `retake_02_rising_asking.ogg` | 280.3 Hz | 13.54 st |
| `retake_03_pressure_nervous.ogg` | 347.0 Hz | 15.03 st |
| `retake_04_intimate_breathless.ogg` | 262.2 Hz | 11.05 st |

Four lines of one character spanning 262 to 376 Hz is not a register,
it is the model no longer holding one. The top rung is therefore a
ceiling marker as much as a choice: it is on the page so the middle can
be picked knowing what is just above it.
