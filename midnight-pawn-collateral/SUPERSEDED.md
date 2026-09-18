# This implementation is superseded

`midnight-pawn-collateral/` is the Ren'Py build of the fork. **The version that ships is
`midnight-pawn-collateral-godot/`**, and the reason is a rule rather than a preference:

> Every adult fork keeps the original game's form — engine, genre, dimensionality.
> Midnight Pawn is a Godot pixel game, so its fork is a Godot pixel game.
> (`ops/adult_forks/README.md`, "The form rule")

The Ren'Py choice was defensible when it was made: room-704's `09_dist.rpy` was 564 lines
and had shipped twice, while Godot's `gate.gd` was 71 lines and had never shipped a fork.
That gap closed the same night — `play/overnight-clause/scripts/{plates,unlock}.gd` is the
Godot side of the same machinery — so the reason for the trade no longer exists.

Nothing here was wasted. All 9,300 words, the psychometry frame, the fee-refund rule and
the single-charge fix were carried into the Godot port, which diffed 488 verbatim lines to
prove it.

Kept, not deleted, for two things it still holds:
- the pure-Python rules module and `tools/simulate.py`, a subset Ren'Py interpreter that
  caught two crash bugs before an engine ever saw them;
- the record of a bug worth remembering — `09_dist.rpy` referenced `route`, room-704's
  branch variable, which does not exist in this fork, so **every non-paid track died at
  the third appraisal**: the first gate a free browser player reaches. A static checker
  passed it because `ast.parse()` accepts an undefined name happily. Running the game in
  the engine found it.

Delete this directory once the Godot build has shipped once.
