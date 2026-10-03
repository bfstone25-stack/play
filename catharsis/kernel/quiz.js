// Quiz bank for Word Pop. `hint` is what a zh player sees next to the prompt (the
// Chinese meaning — the original English-learning framing), `hint_en` what an English
// player sees. quizHint(item, lang) picks; callers that never pass a lang get zh.
const QUIZ_BANK = [
  { id: "cat", prompt: "cat", hint: "猫", hint_en: "a pet that says meow", answer: "cat", kind: "word" },
  { id: "sun", prompt: "sun", hint: "太阳", hint_en: "it rises every morning", answer: "sun", kind: "word" },
  { id: "add", prompt: "7 + 5", hint: "口算", hint_en: "mental math", answer: "12", kind: "math" },
  { id: "sub", prompt: "9 - 4", hint: "口算", hint_en: "mental math", answer: "5", kind: "math" },
  { id: "dog", prompt: "dog", hint: "狗", hint_en: "a pet that barks", answer: "dog", kind: "word" },
];

function normalizeQuiz(s) {
  return String(s || "").trim().toLowerCase();
}

function pickQuiz(bank, rng) {
  const b = bank && bank.length ? bank : QUIZ_BANK;
  rng = rng || Math.random;
  return b[Math.floor(rng() * b.length) % b.length];
}

function quizHint(item, lang) {
  if (!item) return "";
  return (lang === "en" && item.hint_en) ? item.hint_en : item.hint;
}

function checkQuiz(item, input) {
  return normalizeQuiz(input) === normalizeQuiz(item && item.answer);
}

function chargeShot(charge, correct) {
  if (correct) return Math.min(1, (charge || 0) + 0.34);
  return Math.max(0, (charge || 0) * 0.5);
}

function parentReport(stats, lang) {
  const s = stats || {};
  const attempts = s.attempts || 0;
  const correct = s.correct || 0;
  const pct = attempts ? Math.round(correct / attempts * 100) : 0;
  const en = lang === "en";
  return {
    title: en ? "Today's learning report" : "今日学习报告",
    lines: en ? [
      "Correct " + correct + " / " + attempts,
      "Accuracy " + pct + "%",
      "Our promise: no hostile ads",
    ] : [
      "答对 " + correct + " / " + attempts,
      "正确率 " + pct + "%",
      "承诺：无恶意广告",
    ],
    correct, attempts, pct,
  };
}
