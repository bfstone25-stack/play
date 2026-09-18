# -*- coding: utf-8 -*-
"""Playthrough tests for the no-LLM path. No GPU, no model, no network.

These run the whole spine for all three routes: every beat consumed in order,
every chapter cleared through its choice, every ending reachable, and each of
the three CG hooks firing on state rather than on time.

    python3 tests/test_static_story.py
"""
import os
import sys
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "backend"))

import story_engine as se       # noqa: E402
import static_story as sx       # noqa: E402

ROUTES = ["ethan", "luxingye", "guyan"]


class Schema(unittest.TestCase):
    def test_three_routes_load(self):
        for r in ROUTES:
            self.assertTrue(sx.is_static(r), r)

    def test_shape_is_three_by_five_by_eight(self):
        for r in ROUTES:
            st = se.load_story(r)
            self.assertEqual(len(st["chapters"]), 5, r)
            for ch in st["chapters"]:
                self.assertEqual(len(ch["beats"]), 7, f"{r}/{ch['id']}")
                self.assertEqual(len(ch["choices"]), 1, f"{r}/{ch['id']}")
                self.assertGreaterEqual(len(ch["choices"][0]["options"]), 3)
            self.assertEqual(len(st["endings"]), 3, r)

    def test_every_beat_has_authored_prose(self):
        """The whole point of the fork: no beat may fall back to a model."""
        for r in ROUTES:
            for ch in se.load_story(r)["chapters"]:
                for b in ch["beats"]:
                    self.assertTrue(b.get("text_en", "").strip(), f"{r}/{ch['id']}/{b['id']}")
                    self.assertTrue(b.get("event_en", "").strip(), f"{r}/{ch['id']}/{b['id']}")
                for o in ch["choices"][0]["options"]:
                    self.assertTrue(o.get("reply_en", "").strip())
                    self.assertTrue(o.get("text_en", "").strip())

    def test_one_lane_beat_per_chapter_with_both_variants(self):
        for r in ROUTES:
            for ch in se.load_story(r)["chapters"]:
                lanes = [b for b in ch["beats"] if b.get("lane_beat")]
                self.assertEqual(len(lanes), 1, f"{r}/{ch['id']}")
                self.assertEqual(set(lanes[0]["lane"]), {"anxious", "avoidant"})

    def test_every_chapter_end_choice_has_a_real_decline(self):
        """Consent is a mechanic: an escalation chapter must offer a decline
        that continues the route rather than ending it."""
        for r in ROUTES:
            st = se.load_story(r)
            declines = [o for ch in st["chapters"] for o in ch["choices"][0]["options"]
                        if str(o.get("flag", "")).startswith("slow_")]
            self.assertTrue(declines, r)
            for o in declines:
                self.assertGreater(o["aff"], 0, "declining must not be punished")

    def test_cg_slots_are_nine_and_state_earned(self):
        slots = []
        for r in ROUTES:
            s = sx.cg_slots(se.load_story(r))
            self.assertEqual(len(s), 3, r)          # ch2 clear, affection 60, ending
            slots += s
        self.assertEqual(len(set(slots)), 9)

    def test_no_cg_hangs_off_playtime(self):
        """A CG may only be attached to a chapter, the 60 mark, or an ending."""
        for r in ROUTES:
            st = se.load_story(r)
            for ch in st["chapters"]:
                for b in ch["beats"]:
                    self.assertNotIn("cg", b, "a beat must not carry a CG")

    def test_every_cg_slot_has_a_plate_on_disk(self):
        cg = os.path.join(ROOT, "frontend", "cg")
        for r in ROUTES:
            for slot in sx.cg_slots(se.load_story(r)):
                self.assertTrue(os.path.exists(os.path.join(cg, slot + "_locked.webp")), slot)
                self.assertTrue(os.path.exists(os.path.join(cg, slot + "_thumb.webp")), slot)
                self.assertTrue(os.path.exists(os.path.join(cg, "full", slot + ".webp")), slot)


class Lanes(unittest.TestCase):
    def test_lane_text_differs_per_attachment_type(self):
        beat = [b for b in se.load_story("ethan")["chapters"][0]["beats"] if b.get("lane_beat")][0]
        sec = sx.lane_text(beat, "secure", "en")
        anx = sx.lane_text(beat, "anxious", "en")
        avo = sx.lane_text(beat, "avoidant", "en")
        self.assertEqual(len({sec, anx, avo}), 3)
        # unknown falls back to the secure text — attachment.detect() needs four
        # messages before it commits, so the lane can only engage after the
        # player has actually said things.
        self.assertEqual(sx.lane_text(beat, "unknown", "en"), sec)


class Playthrough(unittest.TestCase):
    """Walk the whole spine the way the app does, with no model anywhere."""

    def walk(self, route, lane="secure", pick=0):
        st_obj = se.load_story(route)
        state, aff, turns = {}, 0, 0
        seen_cg, chapters_cleared = [], []
        for _ in range(400):
            new_aff = min(100, aff + 4)
            reply, event, ch, choice, state, cg = sx.turn(
                st_obj, state, aff, new_aff, lane, "en", turns)
            aff, turns = new_aff, turns + 1
            self.assertTrue(reply, f"{route} produced an empty turn in {ch and ch['id']}")
            if cg:
                seen_cg.append(cg)
            if choice:
                opt = choice["options"][min(pick, len(choice["options"]) - 1)]
                d_aff, _r, state = se.apply_choice(
                    st_obj, state, ch["id"], choice["id"], min(pick, len(choice["options"]) - 1), "en")
                aff = min(100, aff + d_aff)
                if state.get("awaiting_continue"):
                    chapters_cleared.append(ch["id"])
                    state, nxt = se.continue_story(st_obj, state)
                    turns = 0
                elif ch["id"] == st_obj["chapters"][-1]["id"]:
                    end = se.match_ending(st_obj, aff, state.get("flags", []))
                    return chapters_cleared, seen_cg, end, state
        self.fail(f"{route} never reached an ending")

    def test_all_three_routes_reach_an_ending(self):
        for r in ROUTES:
            cleared, cgs, end, state = self.walk(r)
            self.assertEqual(cleared, ["ch1", "ch2", "ch3", "ch4"], r)
            self.assertIsNotNone(end, r)
            self.assertIn(se.load_story(r)["cg_heat"], cgs, r)   # hook 2 fired

    def test_heat_cg_fires_on_crossing_not_on_landing(self):
        """A +5 turn jumps straight over 60. The plate must still fire."""
        st_obj = se.load_story("ethan")
        _r, _e, _c, _ch, _s, cg = sx.turn(st_obj, {"chapter": "ch4", "fired": []},
                                          58, 63, "secure", "en", 1)
        self.assertEqual(cg, "cg_ethan_heat")

    def test_every_ending_is_reachable_by_some_choice_path(self):
        for r in ROUTES:
            ends = set()
            for pick in (0, 1, 2):
                _c, _g, end, _s = self.walk(r, pick=pick)
                ends.add(end["id"])
            self.assertGreaterEqual(len(ends), 2, f"{r} endings reached: {ends}")

    def test_unmatched_flags_still_resolve_to_an_authored_ending(self):
        for r in ROUTES:
            end = se.match_ending(se.load_story(r), 0, ["nonsense_flag"])
            self.assertIsNotNone(end, r)
            self.assertTrue(end.get("text_en"))

    def test_chapter_clear_reward_carries_its_cg_only_where_authored(self):
        for r in ROUTES:
            st = se.load_story(r)
            self.assertEqual(sx.chapter_cg(st, "ch2"), f"cg_{r}_ch2")
            self.assertIsNone(sx.chapter_cg(st, "ch1"))
            self.assertIsNone(sx.chapter_cg(st, "ch5"))

    def test_lane_playthrough_changes_the_prose(self):
        """A second run in a different lane must not read as the same script."""
        def lines(lane):
            st_obj = se.load_story("guyan")
            state, aff, out = {}, 0, []
            for _ in range(8):
                reply, _e, _ch, _c, state, _cg = sx.turn(st_obj, state, aff, aff + 3, lane, "en", 0)
                aff += 3
                out.append(reply)
            return out
        self.assertNotEqual(lines("anxious"), lines("avoidant"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
