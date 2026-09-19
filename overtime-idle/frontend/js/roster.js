/* roster.js — the staff roster is the gacha, and the gacha extends the catalogue.
 *
 * settleGrid() (landlord.js) is not forked. It reads a catalogue, and this file hands it a
 * longer one: the four launch people and four objects byte-for-byte, plus every gacha
 * character as a new row. Each gacha character brings ONE adjacency rule, expressed as a
 * new named event in settleIdle() below — a thin wrapper that calls settleGrid() first and
 * then adds its events on top of the same {payout, events, cellScore, links} shape. The
 * parent's vocabulary of board states grows; nothing in it changes.
 *
 * Rarity table (ops/adult_forks/overtime_idle.md §3):
 *   common 70   payout 1-2, no rule   (a body to fill a chain)
 *   rare   25   payout 2-3, one rule
 *   epic    5   payout 3, one rule and a floor effect
 * The launch four are grandfathered into the table with the rules they already have.
 */

const IDLE_ROSTER = [
  { id: "dan", rarity: "rare", slots: 2, age: 41, launch: true,
    en: { name: "Dan, 41", rule: "Coffee beside him triples. Headphones beside him +2.",
          bio: "The last engineer who never goes home. He says the build is green and the trains have stopped, and both are true. The coffee chain runs through him because he is the only one still drinking it at two in the morning." },
    zh: { name: "丹恩 41", rule: "邻格咖啡三倍。邻格耳机 +2。",
          bio: "最后一个从不回家的工程师。他说构建是绿的、末班车也没了，两句都是真的。咖啡链从他身上过，因为凌晨两点只有他还在喝。" } },
  { id: "priya", rarity: "common", slots: 3, age: 29, launch: true,
    en: { name: "Priya, 29", rule: "Copies the best base beside her.",
          bio: "Facilities contractor, three nights a week. Covers whoever she is standing next to — it is her mechanic and her joke. She has keys she is not supposed to have and a very good reason for each." },
    zh: { name: "普莉娅 29", rule: "复制邻格最高的基础值。",
          bio: "设施承包商，一周三个晚上。站在谁旁边就顶谁的班——这是她的机制，也是她的玩笑。她有几把不该有的钥匙，每一把都有很好的理由。" } },
  { id: "mara", rarity: "common", slots: 1, age: 34, launch: true,
    en: { name: "Mara, 34", rule: "Every neighbour +1.",
          bio: "Night-shift building manager. Keys to every floor, opinions about every tenant. Lifts everyone around her by one because she has already done their job once, quietly, before they got in." },
    zh: { name: "玛拉 34", rule: "所有邻格 +1。",
          bio: "夜班楼宇经理。每层都有钥匙，每个租户都有看法。她让周围每个人都高一分，因为在他们进门之前，她已经悄悄把他们的活干过一遍了。" } },
  { id: "wes", rarity: "rare", slots: 1, age: 36, launch: true,
    en: { name: "Wes, 36", rule: "Taxes unshielded Dan and Priya beside him. Tag: noise.",
          bio: "The tenant on 7 who sublets space he does not have. His meetings are a tax on anyone who cannot put headphones on. He is charming for exactly as long as it takes." },
    zh: { name: "韦斯 36", rule: "向邻格没戴耳机的丹恩和普莉娅抽税。标签：噪音。",
          bio: "七楼那个把没有的空间转租出去的租户。他的会议是对所有戴不上耳机的人的一道税。他的迷人恰好持续到得手为止。" } },
  // ---- gacha characters: one new catalogue row, one new named event each ----------
  { id: "nia", rarity: "rare", slots: 1, age: 33, payout: 2, tag: "staff",
    event: "nia-audit",
    en: { name: "Nia, 33", rule: "Audits Wes: each Wes beside her pays her his 2.",
          bio: "Forensic accountant, brought in by Mirei to find out what the tenant on 7 is actually paying for. Sits down next to him on purpose. Wes has never once finished a sentence in her presence." },
    zh: { name: "妮娅 33", rule: "审计韦斯：邻格每个韦斯把他的 2 交给她。",
          bio: "法务会计，美玲请来查七楼那位到底在为什么付钱。她故意坐在他旁边。韦斯在她面前从没把一句话说完过。" } },
  { id: "sol", rarity: "epic", slots: 1, age: 38, payout: 3, tag: "staff",
    event: "sol-late", floorEvent: "sol-floor",
    en: { name: "Sol, 38", rule: "Coffee beside her +2 to her. Floor: every other staff +1.",
          bio: "Night editor for a paper that stopped printing. Still files at four. The whole floor works later when she is on it, and nobody can say why, and nobody has asked her to leave." },
    zh: { name: "索尔 38", rule: "邻格咖啡给她 +2。全层：其他员工各 +1。",
          bio: "一份已经停印的报纸的夜班编辑。凌晨四点还在交稿。她在的楼层大家都走得更晚，没人说得出为什么，也没人请她离开。" } },
];

// The catalogue settleGrid() reads: the parent's eight rows, then the gacha rows.
const IDLE_CATALOG = LANDLORD_CATALOG.concat(
  IDLE_ROSTER.filter((p) => !p.launch).map((p) => ({ id: p.id, payout: p.payout, tag: p.tag }))
);
const IDLE_STAFF = IDLE_ROSTER.map((p) => p.id);
const IDLE_OBJECTS = ["coffee", "mute", "printer", "corner"];
const IDLE_RARITY = { common: 70, rare: 25, epic: 5 };
const IDLE_PITY = 30;                      // pulls without an epic before one is forced

function rosterBy(id) { return IDLE_ROSTER.find((p) => p.id === id); }
function rosterPool(rarity) { return IDLE_ROSTER.filter((p) => p.rarity === rarity).map((p) => p.id); }

// The chain multiplier: the lever §8 of the design says to tune before art. A chain event is
// any settle event that is not the tax; a six-link chain is the parent's cg_quiet_floor bar.
// See tests/kill_condition.cjs for the measurement that set CHAIN_K.
const CHAIN_K = 0.35;
function chainOf(r) { return r.events.filter((e) => e !== "wes-tax").length; }
function chainMult(chain) { return 1 + CHAIN_K * Math.max(0, chain | 0); }

const DUPE_STEP = 0.05, DUPE_CAP = 10;
function dupeBonus(dupes) { return 1 + DUPE_STEP * Math.min(DUPE_CAP, Math.max(0, dupes | 0)); }

/* The thin wrapper. `dupes` is {id: n} from the economy; omit it for a plain settle. */
function settleIdle(cells, relics, dupes) {
  const r = settleGrid(cells, IDLE_CATALOG, relics || []);
  const note = (kind, a, b) => { r.events.push(kind); if (a != null && b != null) r.links.push({ a, b, kind }); };

  // nia-audit: each Wes orthogonally beside Nia pays her his catalogue payout (2).
  cells.forEach((id, i) => {
    if (id !== "nia") return;
    neighborsOf(i).forEach((n) => {
      if (cells[n] === "wes") { r.cellScore[i] += 2; note("nia-audit", i, n); }
    });
  });
  // sol-late: coffee beside Sol gives her +2. sol-floor: while Sol is on the floor every
  // other staff member is +1 (once per floor, however many Sols).
  let solOn = false;
  cells.forEach((id, i) => {
    if (id !== "sol") return;
    solOn = true;
    neighborsOf(i).forEach((n) => {
      if (cells[n] === "coffee") { r.cellScore[i] += 2; note("sol-late", i, n); }
    });
  });
  if (solOn) {
    cells.forEach((id, i) => { if (id !== "sol" && IDLE_STAFF.indexOf(id) >= 0) r.cellScore[i] += 1; });
    note("sol-floor");
  }
  r.payout = r.cellScore.reduce((a, b) => a + b, 0);
  // Duplicate bonus: +5% per dupe on that character's own cells, capped at +50%. Applied to
  // the shift (after the chain multiplier) rather than per cell, so a +15% on a 3-point cell
  // does not round back to 3.
  let extra = 0;
  if (dupes) {
    cells.forEach((id, i) => {
      const d = dupes[id] | 0;
      if (d > 0 && IDLE_STAFF.indexOf(id) >= 0 && r.cellScore[i] > 0) extra += r.cellScore[i] * (dupeBonus(d) - 1);
    });
  }
  r.dupeExtra = extra;
  r.chain = chainOf(r);
  r.mult = chainMult(r.chain);
  r.shift = Math.round((r.payout + extra) * r.mult);
  return r;
}

if (typeof module !== "undefined") module.exports = { IDLE_ROSTER, IDLE_CATALOG, IDLE_STAFF, IDLE_OBJECTS, IDLE_RARITY, IDLE_PITY, rosterBy, rosterPool, CHAIN_K, chainOf, chainMult, dupeBonus, settleIdle };
