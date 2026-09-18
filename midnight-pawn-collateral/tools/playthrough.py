#!/usr/bin/env python3
"""Play the night, headless, against the real rules module.

An SDK is available (see README), but a full engine playthrough takes minutes and needs a
display; this runs in under a second and is where the rules get asserted. It imports game/python-packages/collateral_core.py —
the same file 00_init.rpy imports — and replays whole runs through it, asserting the things
that would otherwise only be caught by a human clicking.

What it proves:
  * all three endings are reachable;
  * every one of the six CGs is reachable, and each one from a *stated state condition*;
  * no CG unlocks from playtime — the condition table is a pure function of run state, and
    the harness demonstrates that by unlocking CGs in zero simulated time and by showing a
    long run with no unlocks;
  * an honest player can afford every reading (the stated mitigation for the fee gate);
  * the fee refund actually returns the till to where it was.

    python3 tools/playthrough.py
"""

import os
import sys

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "game", "python-packages"))

import collateral_core as core  # noqa: E402

FAILURES = []
CHECKS = [0]


def check(label, ok, detail=""):
    CHECKS[0] += 1
    print("  %s  %s%s" % ("PASS" if ok else "FAIL", label, ("  — " + detail) if detail else ""))
    if not ok:
        FAILURES.append(label)


def play(tiers, read, sell=None, ivo_refused=True, verbose=False):
    """Run one night.

    tiers: {item: 'low'|'fair'|'high'}   read: set of item keys to take a reading of.
    Mirrors the order the script actually calls things in: reading fee, then reading, then
    price. `collateral` is always read (unrefusable) and always free.
    """
    run = core.Run()
    run.ivo_refused = ivo_refused
    log = []
    for item in ("finial", "ring", "veil"):
        if item in read:
            if run.can_afford(core.ITEMS[item]["fee"]):
                run.charge_reading(item)
                run.record_reading(item)
                log.append("read %s (-%d)" % (item, core.ITEMS[item]["fee"]))
            else:
                run.record_refusal(item)
                log.append("read %s REFUSED: broke" % item)
        else:
            run.record_refusal(item)
        run.pay_client(item, tiers[item])
        log.append("pay %s %s (-%d) till=%d" % (item, tiers[item], run.paid[item], run.till))

    run.earn(core.MARKET_HAUL)
    if sell:
        client_readings = [k for k in run.readings_taken if k in ("finial", "ring", "veil")]
        if client_readings:
            run.sold_reading = client_readings[-1]
            run.earn(core.CALDER_READING_PRICE)
            log.append("sold %s to Calder (+%d)" % (run.sold_reading, core.CALDER_READING_PRICE))

    run.charge_reading("collateral")
    run.record_reading("collateral")
    if verbose:
        for line in log:
            print("      " + line)
    return run


def main():
    print("Midnight Pawn: Collateral — headless playthrough\n")

    # ---- 1. the honest run is affordable. This is mitigation (3) for the fee gate. -----
    print("1. The honest run — FAIR everywhere, every optional reading taken")
    fair = play({"finial": "fair", "ring": "fair", "veil": "fair"},
                {"finial", "ring", "veil"}, verbose=True)
    check("every optional reading was actually delivered, not refused for lack of cash",
          set(fair.readings_taken) >= {"finial", "ring", "veil"},
          "taken=%s refused=%s" % (fair.readings_taken, fair.readings_refused))
    check("till never went negative", fair.till >= 0, "till=%d" % fair.till)
    check("net worth still clears the debt after paying every fee",
          fair.net_worth() >= core.DEBT,
          "net=%d debt=%d" % (fair.net_worth(), core.DEBT))

    # ---- 2. the three endings ----------------------------------------------------------
    print("\n2. Endings")
    ruthless = play({"finial": "low", "ring": "low", "veil": "low"}, set())
    check("Solvent — refuse three readings, price LOW",
          core.ending_of(ruthless) == core.SOLVENT,
          "net=%d refused=%d" % (ruthless.net_worth(), len(ruthless.readings_refused)))

    kind = play({"finial": "high", "ring": "high", "veil": "high"},
                {"finial", "ring", "veil"})
    check("Collateral — take every reading, pay HIGH",
          core.ending_of(kind) == core.COLLATERAL,
          "net=%d taken=%d" % (kind.net_worth(), len(kind.readings_taken)))

    factor = play({"finial": "fair", "ring": "fair", "veil": "fair"},
                  {"finial", "ring"}, sell=True)
    check("Factor — sell a client's reading to Calder",
          core.ending_of(factor) == core.FACTOR,
          "sold=%s net=%d" % (factor.sold_reading, factor.net_worth()))
    check("all three endings distinct",
          len({core.ending_of(ruthless), core.ending_of(kind), core.ending_of(factor)}) == 3)

    # ---- 3. every CG reachable, each from a stated condition ---------------------------
    print("\n3. CG reachability (six slots)")
    seen = {}
    runs = {
        "FAIR + read finial": play({"finial": "fair", "ring": "fair", "veil": "fair"},
                                   {"finial"}),
        "HIGH + read everything": kind,
        "FAIR + read ring (Ivo said no)": play(
            {"finial": "fair", "ring": "fair", "veil": "fair"}, {"ring"}),
        "HIGH veil + read veil": play({"finial": "low", "ring": "low", "veil": "high"},
                                      {"veil"}),
        "two client readings (Calder demo)": play(
            {"finial": "fair", "ring": "fair", "veil": "fair"}, {"finial", "ring"}),
    }
    for label, r in runs.items():
        for cg in core.unlocked_cgs(r):
            seen.setdefault(cg, label)
    for cg in ("tamsin", "finial", "ring", "veil", "market", "collateral"):
        check("cg_%s reachable" % cg, cg in seen, "via: %s" % seen.get(cg, "NOTHING"))

    # ---- 4. no CG unlocks from playtime ------------------------------------------------
    print("\n4. No CG unlocks from playtime")
    blank = core.Run()
    check("a run with no actions unlocks nothing", core.unlocked_cgs(blank) == [],
          "unlocked=%s" % core.unlocked_cgs(blank))
    # The strongest available statement: the condition table is a pure function of Run, and
    # Run has no clock. If someone ever adds one, this fails.
    check("Run carries no time/counter field a condition could drift onto",
          not any(k for k in vars(blank)
                  if any(w in k.lower() for w in ("time", "clock", "seconds", "elapsed", "tick"))),
          "fields=%s" % sorted(vars(blank)))
    long_run = play({"finial": "low", "ring": "low", "veil": "low"}, set())
    check("a long, thorough, careful run that refuses every reading unlocks nothing but the "
          "unrefusable one",
          core.unlocked_cgs(long_run) == ["collateral"],
          "unlocked=%s" % core.unlocked_cgs(long_run))
    check("the ivo_refused term is load-bearing — no refusal, no cg_ring",
          "ring" not in core.unlocked_cgs(
              play({"finial": "fair", "ring": "fair", "veil": "fair"}, {"ring"},
                   ivo_refused=False)))
    check("cg_veil needs mercy, not just the reading",
          "veil" not in core.unlocked_cgs(
              play({"finial": "fair", "ring": "fair", "veil": "fair"}, {"veil"})))

    # ---- 5. the refund ------------------------------------------------------------------
    print("\n5. The fee refund (what keeps the reading gate off 'second paywall')")
    r = core.Run()
    before = r.till
    r.charge_reading("ring")
    mid = r.till
    r.refund_reading("ring")
    check("charge then refund returns the till exactly", r.till == before,
          "%d -> %d -> %d" % (before, mid, r.till))
    check("refund is recorded so the ending screen can say so",
          r.fees_refunded == core.ITEMS["ring"]["fee"] and r.fees_paid == 0,
          "paid=%d refunded=%d" % (r.fees_paid, r.fees_refunded))

    # ---- 6. determinism -----------------------------------------------------------------
    print("\n6. Determinism (base game promise: same prices, same visions, every run)")
    a = play({"finial": "fair", "ring": "fair", "veil": "high"}, {"finial", "veil"})
    b = play({"finial": "fair", "ring": "fair", "veil": "high"}, {"finial", "veil"})
    check("two identical runs produce identical state",
          (a.till, a.paid, core.unlocked_cgs(a), core.ending_of(a))
          == (b.till, b.paid, core.unlocked_cgs(b), core.ending_of(b)))

    print("\n%d checks, %d failure(s)" % (CHECKS[0], len(FAILURES)))
    for f in FAILURES:
        print("  FAILED: %s" % f)
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
