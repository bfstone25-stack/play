#!/usr/bin/env python3
"""Validate every authored Flutter route as a playable chapter-to-ending loop."""
from pathlib import Path
import json

import story_engine as engine


def validate_route(path):
    story = json.loads(path.read_text(encoding="utf-8"))
    route = path.stem
    chapters = story.get("chapters", [])
    assert chapters, f"{route}: no chapters"
    state = {}
    affection = 0
    reward_ids = set()

    for index, chapter in enumerate(chapters):
        chapter_id = chapter["id"]
        state["chapter"] = chapter_id
        affection = max(affection, chapter.get("exit_aff", 0))
        if index < len(chapters) - 1:
            state = engine.mark_goal_cleared(state, chapter_id)
        _, current, choice, state = engine.advance(story, state, affection, 99)
        assert current["id"] == chapter_id, f"{route}: wrong chapter"
        assert choice and choice.get("options"), f"{route}/{chapter_id}: unreachable choice"

        reward_id = f"{route}:{chapter_id}"
        assert reward_id not in reward_ids, f"{route}: duplicate reward"
        reward_ids.add(reward_id)

        # Every authored option must be selectable and every final option must end.
        for option_index in range(len(choice["options"])):
            delta, reply, option_state = engine.apply_choice(
                story, state, chapter_id, choice["id"], option_index, "en")
            assert isinstance(delta, (int, float)), f"{route}/{chapter_id}: bad affection"
            assert reply, f"{route}/{chapter_id}: empty option reply"
            if index == len(chapters) - 1:
                ending = engine.match_ending(
                    story, min(100, affection + delta), option_state.get("flags", []))
                assert ending, f"{route}/{chapter_id}: option {option_index} has no ending"

        _, _, state = engine.apply_choice(story, state, chapter_id, choice["id"], 0, "en")
        if index < len(chapters) - 1:
            assert state.get("awaiting_continue") == chapter_id
            state, nxt = engine.continue_story(story, state)
            assert nxt and nxt["id"] == chapters[index + 1]["id"], f"{route}: next chapter broken"
            assert not state.get("awaiting_continue")

    return len(chapters), len(story.get("endings", []))


def validate_scoring():
    try:
        from app import interaction_signals
    except ModuleNotFoundError:
        print("NOTE: API dependencies unavailable; interaction scoring check deferred to deployment runtime")
        return
    normal, gain = interaction_signals("I love the way you think.", "en", [], "ethan")
    assert normal["flirt"] > 0 and gain > 0, "positive English romance misclassified"
    negative, neg_gain = interaction_signals("I don't love you. Go away.", "en", [], "ethan")
    assert negative["flirt"] == 0 and neg_gain <= 0, "negated romance misclassified"
    repeated, repeat_gain = interaction_signals(
        "I love the way you think.", "en",
        [{"role": "user", "content": "I love the way you think."}], "ethan")
    assert repeated["repetition"] and repeat_gain < gain, "repeat farming not penalized"


def main():
    totals = [validate_route(path) for path in sorted((Path(__file__).parent / "stories").glob("*.json"))]
    validate_scoring()
    print(f"OK: {len(totals)} routes, {sum(x for x, _ in totals)} chapters, "
          f"{sum(x for _, x in totals)} endings")


if __name__ == "__main__":
    main()
