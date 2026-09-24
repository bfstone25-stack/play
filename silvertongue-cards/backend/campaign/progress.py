"""Which stages are open: one rule, used by the server and by the pacing simulation.

  story stage       every earlier story stage cleared; the first stage of chapter k>1 also
                    needs STANDING >= gates["standing"][chapter] (total stars across the
                    whole campaign: your name in the Night Ledger); a boss also needs
                    BOND >= gates["bond"][chapter] with her
  Last Call stage   that chapter's story boss cleared and the Last Call stage before it
                    cleared
"""
from __future__ import annotations

from . import CHAPTERS, STAGES, STORY_COUNT


def story_frontier(stars: list) -> int:
    return next((i for i in range(STORY_COUNT) if not stars[i]), STORY_COUNT)


def standing(stars: list) -> int:
    return int(sum(stars))


def gate(stage: dict, stars: list, bond: dict, gates: dict) -> dict | None:
    """None if the stage is open, else what stands in the way."""
    i = stage["index"]
    if stage["mode"] == "story":
        f = story_frontier(stars)
        if i > f:
            return {"kind": "locked"}
        if stage["n_in_chapter"] == 1:
            need = int((gates.get("standing") or {}).get(stage["chapter"], 0))
            if standing(stars) < need and not stars[i]:
                return {"kind": "standing", "need": need, "have": standing(stars)}
        if stage["is_boss"]:
            need = int((gates.get("bond") or {}).get(stage["chapter"], 0))
            have = int(bond.get(stage["who"], 0))
            if have < need:
                return {"kind": "bond", "who": stage["who"], "need": need, "have": have}
        return None
    ch = CHAPTERS[stage["chapter_index"]]
    if not stars[ch["stages"][-1]["index"]]:
        return {"kind": "locked"}
    pos = ch["last_call"].index(stage)
    if pos and not stars[ch["last_call"][pos - 1]["index"]]:
        return {"kind": "locked"}
    return None


def finished(stars: list) -> bool:
    """The story is finished when the Long Night is won."""
    return bool(stars[STORY_COUNT - 1])
