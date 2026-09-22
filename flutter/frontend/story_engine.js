// Backend-free story engine for Flutter's static edition.
//
// Ported from flutter/backend/story_engine.py, but scoped to what a no-chat,
// choice-driven playthrough needs: each chapter is opening -> beats (read in
// order) -> one authored choice -> reply -> next chapter -> ending. There is
// no live LLM and no "turns" counter, so chapter/beat gating by turn count
// and affection midpoints is dropped; only the authored choice weights and
// the endings table survive, unchanged, from the source JSON.
//
// Every chapter's affection swing now comes from a single choice (chapters[i]
// .choices[0], matching what production actually served — see chapter_complete
// in story_engine.py, which always takes choices[0]). Summed across a story
// that lands in a small range (roughly 15-35), far below the aff_min/aff_max
// thresholds the endings table was tuned against when affection accrued over
// dozens of chat turns. affRange()/rescaleAff() remap that raw sum onto the
// same 0-100 scale the endings were authored for, so match_ending() below can
// stay a byte-for-byte port of the Python version.

export function affRange(story) {
  let min = 0, max = 0;
  for (const ch of story.chapters) {
    const choice = (ch.choices || [])[0];
    if (!choice) continue;
    const vals = choice.options.map(o => o.aff || 0);
    min += Math.min(...vals);
    max += Math.max(...vals);
  }
  return { min, max };
}

export function rescaleAff(totalAff, range) {
  if (range.max === range.min) return 50;
  const pct = (totalAff - range.min) / (range.max - range.min);
  return Math.round(Math.max(0, Math.min(1, pct)) * 100);
}

export function matchEnding(story, aff, flags) {
  const flagSet = new Set(flags || []);
  const endings = story.endings || [];
  const cands = endings.filter(e => {
    if (aff < (e.aff_min || 0)) return false;
    if ('aff_max' in e && aff > e.aff_max) return false;
    const needAny = e.flags_any || [];
    if (needAny.length && !needAny.some(f => flagSet.has(f))) return false;
    const needAll = e.flags_all || [];
    if (needAll.length && !needAll.every(f => flagSet.has(f))) return false;
    return true;
  });
  if (!cands.length) {
    const byPriority = [...endings].sort((a, b) => (a.priority ?? 99) - (b.priority ?? 99));
    return byPriority.length ? byPriority[byPriority.length - 1] : null;
  }
  return [...cands].sort((a, b) => (a.priority ?? 99) - (b.priority ?? 99))[0];
}

// stage machine: opening -> beat* -> choice -> reply -> (next chapter | ending)
export class StoryPlayer {
  constructor(story) {
    this.story = story;
    this.chapterIndex = 0;
    this.beatIndex = -1;
    this.stage = "opening";
    this.flags = [];
    this.totalAff = 0;
    this.lastReply = null;
    this.ending = null;
    this.range = affRange(story);
  }

  get chapter() { return this.story.chapters[this.chapterIndex]; }
  get isLastChapter() { return this.chapterIndex === this.story.chapters.length - 1; }

  current() {
    switch (this.stage) {
      case "opening": return { stage: "opening", chapter: this.chapter };
      case "beat": return { stage: "beat", chapter: this.chapter, beat: this.chapter.beats[this.beatIndex] };
      case "choice": return { stage: "choice", chapter: this.chapter, choice: this.chapter.choices[0] };
      case "reply": return { stage: "reply", chapter: this.chapter, reply: this.lastReply };
      case "ending": return {
        stage: "ending", ending: this.ending,
        aff: rescaleAff(this.totalAff, this.range), flags: this.flags,
      };
      default: throw new Error("unknown stage " + this.stage);
    }
  }

  next() {
    const beats = this.chapter.beats || [];
    if (this.stage === "opening") {
      this.stage = beats.length ? "beat" : "choice";
      this.beatIndex = beats.length ? 0 : -1;
      return this.current();
    }
    if (this.stage === "beat") {
      if (this.beatIndex < beats.length - 1) this.beatIndex++;
      else this.stage = "choice";
      return this.current();
    }
    if (this.stage === "reply") {
      if (this.isLastChapter) {
        this.stage = "ending";
        this.ending = matchEnding(this.story, rescaleAff(this.totalAff, this.range), this.flags);
      } else {
        this.chapterIndex++;
        this.beatIndex = -1;
        this.stage = "opening";
      }
      return this.current();
    }
    return this.current();
  }

  choose(optionIndex) {
    if (this.stage !== "choice") throw new Error("not at a choice");
    const opt = this.chapter.choices[0].options[optionIndex];
    this.totalAff += opt.aff || 0;
    if (opt.flag) this.flags.push(opt.flag);
    this.lastReply = opt;
    this.stage = "reply";
    return this.current();
  }
}

if (typeof module !== "undefined") module.exports = { affRange, rescaleAff, matchEnding, StoryPlayer };
