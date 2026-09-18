"""collateral_core — the rules of Midnight Pawn: Collateral, as plain Python.

Ren'Py puts game/python-packages on sys.path, so 00_init.rpy imports this module and the
test harness in tools/ imports the *same* file. Nothing here touches Ren'Py, so the economy,
the reading fees, the CG unlock conditions and the ending resolution can all be replayed and
asserted without an SDK — which matters, because the CG conditions are the part of this fork
that must never quietly drift into "unlocks after enough clicking".

Canon carried over from the SFW Godot game (~/midnight-pawn-src/scripts/game_state.gd on
Blaze Ubuntu): Nara Quill owns the Black Ledger, the Heart of the Crypt is the thing the
shop actually wants, the Ossuary Market is a real room, and the economy is deterministic
integers. The fork keeps all four and throws away the combat.
"""

# ---------------------------------------------------------------------------
# Economy
# ---------------------------------------------------------------------------

TILL_START = 260
DEBT = 200          # what Elsa's estate still owes at dawn

#: Every object that crosses the counter. `value` is what it is honestly worth; `fee` is what
#: taking a reading costs out of the till. Deterministic — same numbers every run, like the
#: base game.
ITEMS = {
    "finial": dict(
        client="Tamsin Bell", label="Brass bed-frame finial", value=22, fee=0,
        clue="Unscrewed in a hurry. The thread is bright where the tool slipped.",
    ),
    "ring": dict(
        client="Ivo Lask", label="Wedding ring, not his wife's", value=40, fee=35,
        clue="Inside the band: a date eleven months after the divorce was final.",
    ),
    "veil": dict(
        client="Widow Merrow", label="Mourning veil, black crepe", value=35, fee=20,
        clue="Pressed once, worn once, and never washed.",
    ),
    "market": dict(
        client="Calder", label="A reading bought from another broker", value=0, fee=0,
        clue="Somebody else's night, resold. Proof the trade is real.",
    ),
    "collateral": dict(
        client="Nara Quill", label="The Black Ledger", value=0, fee=0,
        clue="Owner: Nara Quill. Due date: tomorrow.",
    ),
}

#: What the midnight run in the Ossuary Market pays for the ordinary crypt haul — bone
#: charms and unclaimed stock, nothing to do with readings. Calder pays this whether or not
#: you sell him anything of your clients'.
MARKET_HAUL = 30

#: What Calder pays for a client's reading. This is the Factor ending's price.
CALDER_READING_PRICE = 90

PRICE_TIERS = ("low", "fair", "high")


def price_of(item, tier):
    """What you hand the client. LOW cheats them, FAIR is the honest number, HIGH is mercy."""
    v = ITEMS[item]["value"]
    if tier == "low":
        return (v * 2) // 3
    if tier == "high":
        return (v * 3) // 2
    return v


# ---------------------------------------------------------------------------
# Run state
# ---------------------------------------------------------------------------

class Run(object):
    """One night. Mutated by the script; read by the ending and the Reading Ledger."""

    def __init__(self):
        self.till = TILL_START
        self.readings_taken = []      # item keys whose reading you paid for and received
        self.readings_refused = []    # item keys you deliberately priced blind
        self.prices = {}              # item key -> "low" / "fair" / "high"
        self.paid = {}                # item key -> cash actually handed over
        self.stock = []               # item keys now on the shelf (yours at dawn)
        self.sold_reading = None      # which client's reading you sold to Calder
        self.ivo_refused = False      # Ivo asked you not to look
        self.fees_paid = 0
        self.fees_refunded = 0

    # -- money -------------------------------------------------------------
    def can_afford(self, n):
        return self.till >= n

    def spend(self, n):
        self.till -= n
        return self.till

    def earn(self, n):
        self.till += n
        return self.till

    # -- appraisals --------------------------------------------------------
    def charge_reading(self, item):
        """Take the fee out of the till. Returns the fee charged."""
        fee = ITEMS[item]["fee"]
        self.till -= fee
        self.fees_paid += fee
        return fee

    def refund_reading(self, item):
        """Hand the fee back.

        This exists because of the second-paywall problem. On a free track the real
        distribution gate may leave the plate censored; charging shop cash for a censored
        plate is exactly the "paying customer feels cheated" failure mode the design flags.
        So the fee is conditional on delivery, and the game says so out loud.
        """
        fee = ITEMS[item]["fee"]
        self.till += fee
        self.fees_paid -= fee
        self.fees_refunded += fee
        return fee

    def record_reading(self, item):
        if item not in self.readings_taken:
            self.readings_taken.append(item)
        if item in self.readings_refused:
            self.readings_refused.remove(item)

    def record_refusal(self, item):
        if item not in self.readings_refused and item not in self.readings_taken:
            self.readings_refused.append(item)

    def pay_client(self, item, tier):
        cash = price_of(item, tier)
        self.prices[item] = tier
        self.paid[item] = cash
        self.till -= cash
        if item not in self.stock:
            self.stock.append(item)
        return cash

    # -- dawn --------------------------------------------------------------
    def stock_value(self):
        return sum(ITEMS[k]["value"] for k in self.stock)

    def net_worth(self):
        return self.till + self.stock_value()


# ---------------------------------------------------------------------------
# CG unlock conditions
# ---------------------------------------------------------------------------
#
# Every entry is a pure function of run state. There is deliberately no clock, no scene
# counter and no "seen enough dialogue" term anywhere in this table: a CG that unlocks from
# playtime is the thing this fork is specifically not allowed to do, and keeping the whole
# table in one testable place is how that stays true.

def cg_conditions(run):
    """item key -> (unlocked, one-line reason shown in the Reading Ledger)."""
    out = {}

    # 1. The tutorial reading, free on every track. Priced her honestly.
    out["tamsin"] = (
        run.prices.get("finial") == "fair" and "finial" in run.readings_taken,
        "Read the finial and paid Tamsin what it was worth.",
    )

    # 2. The same vision, further in — only if you overpaid her for a bed she is selling
    #    out from under herself. Mercy costs cash and buys the deeper plate.
    out["finial"] = (
        run.prices.get("finial") == "high" and "finial" in run.readings_taken,
        "Read the finial and paid Tamsin above its worth.",
    )

    # 3. Ivo asked you not to look. You paid the fee and looked anyway.
    out["ring"] = (
        "ring" in run.readings_taken and run.ivo_refused,
        "Took the ring's reading after Ivo asked you not to.",
    )

    # 4. Mercy, again, and it has to cost: the offer must clear the veil's true value.
    out["veil"] = (
        "veil" in run.readings_taken
        and run.paid.get("veil", 0) > ITEMS["veil"]["value"],
        "Read the veil and offered Merrow more than it was worth.",
    )

    # 5. Calder only demonstrates for a broker who is carrying something worth trading.
    out["market"] = (
        len([k for k in run.readings_taken if k in ("finial", "ring", "veil")]) >= 2,
        "Carried two client readings down to the Ossuary Market.",
    )

    # 6. The last object in the midnight restock is yours. No condition, no refusal.
    out["collateral"] = (
        "collateral" in run.readings_taken,
        "The shop put your own ledger on the counter.",
    )
    return out


def unlocked_cgs(run):
    return sorted(k for k, (ok, _) in cg_conditions(run).items() if ok)


# ---------------------------------------------------------------------------
# Endings
# ---------------------------------------------------------------------------

SOLVENT = "solvent"
FACTOR = "factor"
COLLATERAL = "collateral"

ENDING_NAMES = {
    SOLVENT: "Solvent",
    FACTOR: "Factor",
    COLLATERAL: "Collateral",
}


def ending_of(run):
    """Three endings, resolved in priority order.

    Factor first because selling a client's reading is a thing you did that cannot be
    outweighed by arithmetic. Then Collateral, which is what taking everything costs you.
    Solvent is the one you have to actually refuse things to reach.
    """
    if run.sold_reading:
        return FACTOR
    client_readings = [k for k in run.readings_taken if k in ("finial", "ring", "veil")]
    if len(client_readings) >= 3:
        return COLLATERAL
    if len(run.readings_refused) >= 3 and run.net_worth() >= DEBT:
        return SOLVENT
    return SOLVENT if run.net_worth() >= DEBT else COLLATERAL
