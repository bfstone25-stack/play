/* idle.js — the building keeps running when you leave.
 *
 * Pure state + a clock you hand in. Nothing here touches the DOM, so tests/idle.test.cjs
 * drives it with a mocked clock and the UI (game.js) drives it with the real one.
 *
 *   shift:   every SHIFT_MS, each built floor pays settleIdle(cells).payout × chainMult
 *            × building multiplier into the bank.
 *   day:     at each day boundary every floor owes rentForFloor(n) × RENT_SHIFTS. A floor
 *            whose shifts that day did not cover it is evicted — cells cleared; staff are
 *            not a resource that can be lost, so they are simply back in the roster.
 *   offline: shifts accrue for at most capMs after lastSeen; past the cap the building is
 *            frozen (no shifts, no rent checks) until the next visit.
 */
const Idle = (() => {
  const SHIFT_MS = 10 * 60e3;
  const DAY_MS = 86400e3;
  const OFFLINE_CAP_MS = 8 * 3600e3;
  const RENT_SHIFTS = 24;            // a floor's daily rent = 24 break-even shifts of the parent's rent
  const MAX_FLOORS = 9;
  const PRESTIGE_DAYS = 7;
  const PRESTIGE_MULT = 1.5;
  const SIZE = 20;

  function dayIndex(ms) { return Math.floor(ms / DAY_MS); }
  function emptyCells() { return new Array(SIZE).fill(null); }

  function newFloor(n, now) { return { n, cells: emptyCells(), builtAt: now, earnedToday: 0, shifts: 0, evictions: 0, best: 0 }; }
  function fresh(now) {
    return { v: 1, building: 1, mult: 1, floors: [newFloor(1, now)], relics: [], bank: 0, inventory: {},
             lastSeen: now, nextShift: now + SHIFT_MS, lastDay: dayIndex(now), solventDays: 0, totalShifts: 0, totalRent: 0,
             clockOffset: 0, daily: {} };
  }

  function floorCost(n) { return rentForFloor(n, []) * 6; }             // buy-in for a new floor, in rent
  function dailyRent(floor, relics) { return rentForFloor(floor.n, relics) * RENT_SHIFTS; }
  function rentDue(floor, relics, at) {
    const frac = Math.min(1, Math.max(0, (at - floor.builtAt) / DAY_MS));   // first day is prorated
    return Math.ceil(dailyRent(floor, relics) * frac);
  }
  function floorShift(state, floor, dupes) {
    const r = settleIdle(floor.cells, state.relics, dupes);
    const pay = Math.round(r.shift * state.mult);
    return { r, pay };
  }
  function ratePerHour(state, dupes) {
    return state.floors.reduce((a, f) => a + floorShift(state, f, dupes).pay, 0) * (3600e3 / SHIFT_MS);
  }

  /* tick(state, now, opts) — advance the building to `now`. Mutates state, returns a report.
   *   opts.capMs     offline cap (Economy.offlineCapMs())
   *   opts.dupes     {id: n} dupe map for the shift bonus
   *   opts.shields   () => boolean — consume a rent shield, if any
   *   opts.onSettle  (floor, r, chain) — the skill ladder hook, called on every shift
   *   opts.onEvict   (floor)
   */
  function tick(state, now, opts) {
    opts = opts || {};
    const capMs = opts.capMs || OFFLINE_CAP_MS;
    const report = { from: state.lastSeen, to: now, elapsed: now - state.lastSeen, shifts: 0, rent: 0, evictions: [], rentPaid: 0,
                     capped: false, frozenMs: 0, perFloor: {}, days: 0, shielded: 0 };
    if (now <= state.lastSeen) return report;
    const end = Math.min(now, state.lastSeen + capMs);
    const frozen = now > state.lastSeen + capMs;
    if (frozen) { report.frozenMs = now - end; report.capped = report.frozenMs >= SHIFT_MS; }

    function dailyCheck(at) {
      report.days += 1;
      let allSolvent = state.floors.length > 0;
      state.floors.forEach((f) => {
        const due = rentDue(f, state.relics, at);
        state.bank = Math.max(0, state.bank - due);
        report.rentPaid += due;
        if (f.earnedToday >= due) { f.earnedToday = 0; return; }
        if (opts.shields && opts.shields()) { report.shielded += 1; f.earnedToday = 0; return; }
        allSolvent = false;
        f.cells = emptyCells();           // staff go back to the roster; objects are gone
        f.evictions += 1;
        f.earnedToday = 0;
        f.builtAt = at;
        report.evictions.push(f.n);
        if (opts.onEvict) opts.onEvict(f);
      });
      state.solventDays = allSolvent ? state.solventDays + 1 : 0;
    }

    while (state.nextShift <= end) {
      const at = state.nextShift;
      while (dayIndex(at) > state.lastDay) { state.lastDay += 1; dailyCheck(state.lastDay * DAY_MS); }
      state.floors.forEach((f) => {
        const { r, pay } = floorShift(state, f, opts.dupes);
        if (pay <= 0 && !f.cells.some(Boolean)) return;
        state.bank += pay;
        f.earnedToday += pay;
        f.shifts += 1;
        f.best = Math.max(f.best, pay);
        state.totalShifts += 1;
        state.totalRent += pay;
        report.shifts += 1;
        report.rent += pay;
        report.perFloor[f.n] = (report.perFloor[f.n] || 0) + pay;
        f.cells.forEach((id) => { if (id && IDLE_STAFF.indexOf(id) >= 0 && opts.onShift) opts.onShift(id, f); });
        if (opts.onSettle) opts.onSettle(f, r, r.chain);
      });
      state.nextShift += SHIFT_MS;
    }
    while (dayIndex(end) > state.lastDay) { state.lastDay += 1; dailyCheck(state.lastDay * DAY_MS); }
    // Past the cap the building is frozen. The day the accrual window closed in still gets
    // its rent check (what was earned in the window is what covers it); every later frozen
    // day is skipped, or a three-day absence would evict every floor three times.
    if (dayIndex(now) > state.lastDay) { state.lastDay += 1; dailyCheck(state.lastDay * DAY_MS); state.lastDay = dayIndex(now); }

    if (frozen) state.nextShift = now + (state.nextShift - end);   // keep the phase, drop the frozen time
    state.lastSeen = now;
    return report;
  }

  /* timeskip(state, ms, opts) — collect `ms` of future shifts right now (the timeskip_4h SKU).
   * Implemented as: pretend the clock is `ms` ahead, then set lastSeen/nextShift back so
   * the real clock keeps ticking from where it was. */
  function timeskip(state, now, ms, opts) {
    const rep = tick(state, now + ms, Object.assign({}, opts, { capMs: ms + OFFLINE_CAP_MS }));
    state.lastSeen = now;
    state.nextShift -= ms;
    return rep;
  }

  function canPrestige(state) { return state.solventDays >= PRESTIGE_DAYS && state.floors.length >= 1; }
  function prestige(state, now) {
    state.building += 1;
    state.mult = +(state.mult * PRESTIGE_MULT).toFixed(3);
    state.floors = [newFloor(1, now)];
    state.relics = [];
    state.solventDays = 0;
    state.bank = 0;
    state.inventory = {};
    return state;
  }
  function buildFloor(state, now) {
    const n = state.floors.length + 1;
    if (n > MAX_FLOORS) return { ok: false, why: "max" };
    const cost = floorCost(n);
    if (state.bank < cost) return { ok: false, why: "bank", need: cost - state.bank };
    state.bank -= cost;
    state.floors.push(newFloor(n, now));
    return { ok: true, n };
  }

  return { SHIFT_MS, DAY_MS, OFFLINE_CAP_MS, RENT_SHIFTS, MAX_FLOORS, PRESTIGE_DAYS, PRESTIGE_MULT,
           fresh, newFloor, emptyCells, dayIndex, floorCost, dailyRent, rentDue, floorShift, ratePerHour,
           tick, timeskip, canPrestige, prestige, buildFloor };
})();
if (typeof module !== "undefined") module.exports = Idle;
