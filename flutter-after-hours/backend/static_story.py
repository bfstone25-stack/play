# -*- coding: utf-8 -*-
"""static_story — the no-LLM delivery path for Flutter: After Hours.

Flutter's SFW parent calls a live model every turn and lets `story_engine.py`
decide *what happens* while the model decides *how he says it*. For the adult
fork both halves are authored: `backend/stories_x/<route>.json` carries a
`text_*` on every beat and a `reply_*` on every choice option, so a turn is a
lookup rather than a generation. Zero GPU, deterministic, and it works in a
downloaded offline build, which a per-turn erotic generation never could.

The schema is `stories/*.json` plus four additions:

    story.static          true  -> this route is served from here, never from the model
    story.cg_heat         CG slot fired when affection crosses 60
    story.hold_en[]       lines used after a chapter's beats are spent
    chapter.cg            CG slot earned at this chapter's clear
    beat.text_*           his authored line (replaces the model reply)
    beat.lane{}           attachment-keyed variants: anxious / avoidant
                          (secure and unknown use beat.text_*)
    ending.cg             CG slot shown on the ending screen

Everything else — advance(), apply_choice(), continue_story(), match_ending() —
is the parent's engine, unchanged.
"""
import os

try:
    from . import story_engine as _se
except ImportError:  # direct script/tests
    import story_engine as _se


# ── beat selection ────────────────────────────────────────────────────────────

def is_static(route_id):
    st = _se.load_story(route_id)
    return bool(st and st.get("static"))


def _field(item, base, content_lang):
    """Same localized-field fallback the parent app uses."""
    return item.get(f"{base}_{content_lang}") or item.get(f"{base}_en") or item.get(f"{base}_zh") or ""


def lane_text(beat, lane, content_lang):
    """His line for this beat, in the attachment lane the player has earned.

    `secure` and `unknown` both read the base text: attachment.detect() needs
    four messages and a score of 2.5 before it commits, so the lane can only
    engage once the player has actually said things.
    """
    variants = beat.get("lane") or {}
    if lane in ("anxious", "avoidant") and variants.get(lane):
        return variants[lane]
    return _field(beat, "text", content_lang)


def next_beat(chapter, fired):
    """Beats are authored prose, so they are consumed in order, one per turn.

    The parent gates beats on turns/affection because the model fills the gaps
    between them. Here there are no gaps to fill: every turn is a beat until the
    chapter runs out of them.
    """
    for b in chapter.get("beats", []):
        if b["id"] not in fired:
            return b
    return None


def hold_line(story, chapter, fired_count, content_lang):
    """What he says once the chapter's beats are spent and affection is short.

    Not filler for its own sake — this is the window in which the player talks
    the affection up to `exit_aff`, so the lines have to invite more talking.
    """
    pool = (chapter.get(f"hold_{content_lang}") or chapter.get("hold_en")
            or story.get(f"hold_{content_lang}") or story.get("hold_en") or [])
    if not pool:
        return ""
    return pool[fired_count % len(pool)]


# ── one turn ──────────────────────────────────────────────────────────────────

def turn(story, state, aff, new_aff, lane, content_lang, turns):
    """Serve one authored turn.

    Returns (reply, event, chapter, choice, state, cg). The caller has already
    scored affection with the parent's zero-call `interaction_signals()`, which
    is why both the old and new affection come in: the heat CG fires on the
    *crossing* of 60, not on landing exactly on it.
    """
    st = dict(state or {})
    st.setdefault("chapter", story["chapters"][0]["id"])
    st.setdefault("fired", [])
    st.setdefault("flags", [])

    ch = _se.current_chapter(story, new_aff, st["chapter"])
    if not ch:
        return "", None, None, None, st, None

    # A cleared chapter waits for the player's explicit "next chapter" action,
    # exactly as the parent engine does, so the reward screen can never be skipped.
    if st.get("awaiting_continue"):
        return "", None, ch, None, st, None

    beat = next_beat(ch, st["fired"])
    event = None
    if beat:
        st["fired"].append(beat["id"])
        reply = lane_text(beat, lane, content_lang)
        event = _field(beat, "event", content_lang)
    else:
        reply = hold_line(story, ch, len(st["fired"]) + turns, content_lang)

    # No judge pass on a static route: there is no free-text conversation for a
    # model to grade, so chapter exit is affection + the chapter-end choice.
    # The goal clears itself once the authored beats are spent and the
    # affection gate is met.
    if beat is None and new_aff >= ch.get("exit_aff", 999):
        st = _se.mark_goal_cleared(st, ch["id"])

    choice = None
    ids = [c["id"] for c in story["chapters"]]
    is_final = ids.index(ch["id"]) == len(ids) - 1
    # Run-found, second pass: the final chapter has no judge goal, so it used to
    # offer its choice the moment the affection gate was met — which could fire
    # the ending screen while authored beats were still unread. On a static
    # route an unread beat is unread *prose*, not a skipped model call, so the
    # choice waits for the chapter's beats to be spent in every chapter.
    beats_spent = next_beat(ch, st["fired"]) is None
    goal_ready = (is_final and beats_spent) or ch["id"] in set(st.get("goal_cleared", []))
    if _se.chapter_complete(ch, new_aff) and goal_ready and not st.get("choice_done_" + ch["id"]):
        cs = ch.get("choices", [])
        if cs:
            choice = cs[0]

    # CG hook 2 of 3 — affection crosses 60 (app.py:634-637 in the parent).
    # The parent fires milestones on `new_aff in (10,30,60,100)`, which a +5 turn
    # can jump straight over; a CG that a player can miss by scoring too well is
    # a bug, so this one fires on the crossing instead.
    cg = story.get("cg_heat") if (aff < 60 <= new_aff) else None

    return reply, event, ch, choice, st, cg


def choice_reply(option, lane, content_lang):
    """The chapter-end choice reply, in the player's attachment lane."""
    variants = option.get("reply_lane") or {}
    if lane in ("anxious", "avoidant") and variants.get(lane):
        return variants[lane]
    return _field(option, "reply", content_lang)


def chapter_cg(story, chapter_id):
    """CG hook 1 of 3 — the chapter-clear reward (app.py:700-712 in the parent)."""
    ch = next((c for c in story.get("chapters", []) if c["id"] == chapter_id), None)
    return (ch or {}).get("cg")


def cg_slots(story):
    """Every CG this route can produce, for the gallery manifest."""
    out = [c.get("cg") for c in story.get("chapters", []) if c.get("cg")]
    if story.get("cg_heat"):
        out.append(story["cg_heat"])
    for e in story.get("endings", []):
        if e.get("cg") and e["cg"] not in out:
            out.append(e["cg"])
    return out
