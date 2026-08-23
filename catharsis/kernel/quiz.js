const QUIZ_BANK = [
  { id: "cat", prompt: "cat", hint: "猫", answer: "cat", kind: "word" },
  { id: "sun", prompt: "sun", hint: "太阳", answer: "sun", kind: "word" },
  { id: "add", prompt: "7 + 5", hint: "口算", answer: "12", kind: "math" },
  { id: "sub", prompt: "9 - 4", hint: "口算", answer: "5", kind: "math" },
  { id: "dog", prompt: "dog", hint: "狗", answer: "dog", kind: "word" },
];

function normalizeQuiz(s) {
  return String(s || "").trim().toLowerCase();
}

function pickQuiz(bank, rng) {
  const b = bank && bank.length ? bank : QUIZ_BANK;
  rng = rng || Math.random;
  return b[Math.floor(rng() * b.length) % b.length];
}

function checkQuiz(item, input) {
  return normalizeQuiz(input) === normalizeQuiz(item && item.answer);
}

function chargeShot(charge, correct) {
  if (correct) return Math.min(1, (charge || 0) + 0.34);
  return Math.max(0, (charge || 0) * 0.5);
}

function parentReport(stats) {
  const s = stats || {};
  const attempts = s.attempts || 0;
  const correct = s.correct || 0;
  const pct = attempts ? Math.round(correct / attempts * 100) : 0;
  return {
    title: "今日学习报告",
    lines: [
      "答对 " + correct + " / " + attempts,
      "正确率 " + pct + "%",
      "承诺：无恶意广告",
    ],
    correct, attempts, pct,
  };
}
