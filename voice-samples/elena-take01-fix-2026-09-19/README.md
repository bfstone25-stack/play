# Take 01 -- "Professor Vance." -- before and after

The one take of the eight Blaze turned down: *still too mature*.

* `before_223hz.ogg` / `.mp3` -- what he heard. 223.0 Hz median, 5.40 semitones of range.
* `after_243hz.ogg` / `.mp3` -- what replaces it. 243.2 Hz, 22.63 semitones.

Same line, same direction, same reference clip. **Nothing about the direction changed.**

## What the measurement said

The theory was that a two-word line has no room to develop pitch movement, lands on the
reference clip's baseline, and so reads older -- and that the cure is a stronger
instruction for short lines. Measured over six renders each of a two-word and a
twelve-word line:

| | median f0 | range |
|---|---|---|
| short (2 words) | 243 Hz | 6.2-7.6 st |
| long (12 words) | 227 Hz | 15.6 st |

So short lines are **flatter** -- about half the pitch movement, exactly as predicted.
They are **not lower**. A length-stratified sample of 60 lines off the old corpus does
show them lower (190.3 Hz under 4 words against 198.1 over), which is what made the
story look right at first, but that corpus is the rejected register and the effect does
not survive into the approved one.

And directing harder does nothing. Six renders of `Say this bright and young, wry.`
against six of `Say this bright and young, wry, pitch moving, light.`:

| | median f0 | median range |
|---|---|---|
| as directed | 242.8 Hz | 7.58 st |
| directed harder | 244.8 Hz | 6.24 st |

Indistinguishable. That wording is kept in `ops/vn_voice_direct.py` as `SHORT_LIFT`, a
record of the negative result, and is deliberately not wired into anything.

## What was actually wrong

Those six renders of the unchanged direction span **222-299 Hz**, standard deviation 31.
The take Blaze heard measures 223.0 -- the lowest of the six. The synthesiser is
stochastic, a short line has few syllables for its median to average over (sd 31 against
21 on long lines), and the pipeline shipped whichever take came out first. Roughly one
short line in six lands at the bottom of that spread and sounds like an older woman than
the lines either side of it.

## The fix

The leads' short lines are now rendered three times and the best-measured take is kept
(`BEST_OF` in `ops/vn_voice.py`). "Best" is not "highest": each seed clip is already
pitch-placed to a target -- Elena's is 245 Hz -- and the score is pitch range minus a
lopsided penalty for sitting off that target, three points a semitone under and one
over. Under is the failure Blaze heard; an unpunished overshoot is its own bug, and
scored one-sided it picked a 298.8 Hz take, four and a half semitones sharp, which is
not the approved register sounding younger but a different woman.

Scored against the six known takes, the rule ranks the rejected one second-worst and
picks 243.2 Hz at 22.6 semitones. The register itself is untouched: this changes which
take of a short lead line ships, and nothing else.

242 lines across the three games qualify.
