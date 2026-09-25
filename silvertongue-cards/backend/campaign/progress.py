"""Which stages are open: one rule, used by the server and by the pacing simulation.

  story stage       every earlier story stage cleared; the first stage of chapter k>1 also
                    needs STANDING >= gates["standing"][chapter] (total stars across the
                    whole campaign: your name in the Night Ledger); a boss also needs
                    BOND >= gates["bond"][chapter] with her
  Last Call stage   that chapter's story boss cleared and the Last Call stage before it
                    cleared
  pack stage        (update packs, packs/) the pack is released (gates["released"], set by
                    the server from its clock); nights 7-12 and its Last Call also need its
                    second half open (gates["second_half"], a week later); its first stage
                    needs the Long Night won
                    and the previous released pack's boss cleared; then story order, and
                    the boss needs BOND >= gates["bond"][pack] with her
  pack Last Call    her boss cleared and the stage before it cleared
"""
from __future__ import annotations

from . import CHAPTERS, PACK_CHAPTERS, STAGES, STORY_COUNT
from .packs import FIRST_HALF


def story_frontier(stars: list) -> int:
    return next((i for i in range(STORY_COUNT) if not stars[i]), STORY_COUNT)


def standing(stars: list) -> int:
    return int(sum(stars))


def gate(stage: dict, stars: list, bond: dict, gates: dict) -> dict | None:
    """None if the stage is open, else what stands in the way."""
    i = stage["index"]
    if stage["mode"] in ("pack", "pack_lc"):
        return _pack_gate(stage, stars, bond, gates)
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


def _pack_gate(stage: dict, stars: list, bond: dict, gates: dict) -> dict | None:
    rel = set(gates.get("released") or ())
    if stage["pack"] not in rel:
        return {"kind": "unreleased"}
    ch = PACK_CHAPTERS[stage["chapter_index"]]
    if stage["mode"] == "pack_lc":
        if stage["pack"] not in set(gates.get("second_half") or ()):
            return {"kind": "opens", "pack": stage["pack"]}
        if not stars[ch["stages"][-1]["index"]]:
            return {"kind": "locked"}
        pos = ch["last_call"].index(stage)
        if pos and not stars[ch["last_call"][pos - 1]["index"]]:
            return {"kind": "locked"}
        return None
    pos = stage["n_in_chapter"] - 1
    if pos >= FIRST_HALF and stage["pack"] not in set(gates.get("second_half") or ()):
        return {"kind": "opens", "pack": stage["pack"]}
    if pos:
        if not stars[ch["stages"][pos - 1]["index"]]:
            return {"kind": "locked"}
    else:
        if not finished(stars):
            return {"kind": "locked", "needs": "the Long Night"}
        for prev in PACK_CHAPTERS[:stage["chapter_index"]]:
            if prev["id"] in rel and not stars[prev["stages"][-1]["index"]]:
                return {"kind": "locked", "needs": prev["id"]}
    if stage["is_boss"]:
        need = int((gates.get("bond") or {}).get(stage["pack"], 0))
        have = int(bond.get(stage["who"], 0))
        if have < need:
            return {"kind": "bond", "who": stage["who"], "need": need, "have": have}
    return None


def event_gate(stage: dict, stars: list, event_stars: dict) -> dict | None:
    """An event stage: the base chapter 1 boss cleared (the duel has been taught), and the
    event's previous stage won. Whether the event is running is the server's check."""
    if not stars[CHAPTERS[0]["stages"][-1]["index"]]:
        return {"kind": "locked", "needs": "c1"}
    if stage.get("prev") and not event_stars.get(stage["prev"]):
        return {"kind": "locked"}
    return None
