"""F2P economy: Gold ledger, energy, affection, gacha with pity, idempotent SKU grants.

SQLite, one file, engine-agnostic: nothing in here knows what a card or a duel is. A
"user" is any string key the caller chooses (the game uses its player key), a "character"
is any string, a "card" is any string id. The gacha takes its pool from the caller.

    eco = Economy("/path/economy.db")               # clock=time.time by default
    eco.energy(user)                                 # -> {"energy": 15, "pool": 15, "next_in_s": 0}
    eco.spend_energy(user, 3)                        # False if short
    eco.add_gold(user, 50, "duel_win", ref="duel:…")
    eco.spend_gold(user, 100, "pull_1")              # raises Insufficient
    eco.pull(user, pool={"common":[…],"rare":[…],"epic":[…]}, n=10)
    eco.grant(user, "gold_m", payment_id="np_123")   # idempotent on payment_id
    eco.affection(user, "mara")                      # wins
    eco.add_win(user, "mara", double=False)

Energy: pool ENERGY_POOL, +1 per ENERGY_REFILL_S, stored as (value, timestamp) and
refilled lazily on read, so no timer runs anywhere. Refill stops at the pool; a paid
refill sets it to the pool and does not overflow.

Gacha: weights common 70 / rare 25 / epic 5. Pity: a 10-pull that has not produced a rare
or better by its tenth card gets one; every PITY_EPIC-th pull without an epic is an epic.
Pity counters live per user and persist across sessions.

Grants: `grant()` is keyed on payment_id. A second call with the same payment_id returns
the first result and changes nothing — the Nutaku PUT may be retried, and Gold was already
charged on their side before the PUT (gateway/nutaku.py header).

Every Gold movement is a ledger row; `balance()` is the sum of the ledger, never a
column that can drift from it.
"""
from __future__ import annotations

import json
import random
import sqlite3
import time
from datetime import date

ENERGY_POOL = 15
ENERGY_REFILL_S = 20 * 60
DUEL_COST = 3

GACHA_WEIGHTS = {"common": 70, "rare": 25, "epic": 5}
PITY_RARE_EVERY = 10     # within a 10-pull
PITY_EPIC_EVERY = 30     # cumulative

PULL_PRICE = {1: 100, 10: 900}

# sku -> what it grants. Prices live in ops/nutaku/config.json, not here.
SKUS = {
    "gold_s": {"gold": 500},
    "gold_m": {"gold": 1200},
    "gold_l": {"gold": 3000},
    "energy_refill": {"energy_full": True},
    "pull_1": {"pull_credits": 1},
    "pull_10": {"pull_credits": 10},
    # char_<name> and scene_skip_<name> are pattern SKUs: see grant().
}


class Insufficient(Exception):
    pass


class Economy:
    def __init__(self, path: str, clock=None):
        self.path = path
        self.clock = clock or time.time
        with self._db() as c:
            c.executescript("""
            CREATE TABLE IF NOT EXISTS users(
                user TEXT PRIMARY KEY, energy INT NOT NULL, energy_ts REAL NOT NULL,
                pulls INT NOT NULL DEFAULT 0, since_epic INT NOT NULL DEFAULT 0,
                pull_credits INT NOT NULL DEFAULT 0, daily_used TEXT DEFAULT '', created REAL);
            CREATE TABLE IF NOT EXISTS ledger(
                id INTEGER PRIMARY KEY, user TEXT, delta INT, reason TEXT, ref TEXT, ts REAL);
            CREATE INDEX IF NOT EXISTS ledger_user ON ledger(user);
            CREATE TABLE IF NOT EXISTS affection(
                user TEXT, character TEXT, wins INT NOT NULL DEFAULT 0, PRIMARY KEY(user, character));
            CREATE TABLE IF NOT EXISTS collection(
                user TEXT, card TEXT, n INT NOT NULL DEFAULT 0, PRIMARY KEY(user, card));
            CREATE TABLE IF NOT EXISTS unlocks(
                user TEXT, key TEXT, ts REAL, PRIMARY KEY(user, key));
            CREATE TABLE IF NOT EXISTS grants(
                payment_id TEXT PRIMARY KEY, user TEXT, sku TEXT, result TEXT, ts REAL);
            CREATE TABLE IF NOT EXISTS pulls(
                id INTEGER PRIMARY KEY, user TEXT, rarity TEXT, card TEXT, pity TEXT, ts REAL);
            """)

    def _db(self):
        c = sqlite3.connect(self.path, timeout=10)
        c.row_factory = sqlite3.Row
        return c

    # --- users -------------------------------------------------------------------------
    def ensure(self, user: str, c=None) -> None:
        own = c is None
        c = c or self._db()
        c.execute("INSERT OR IGNORE INTO users(user,energy,energy_ts,created) VALUES(?,?,?,?)",
                  (user, ENERGY_POOL, self.clock(), self.clock()))
        if own:
            c.commit(); c.close()

    # --- gold --------------------------------------------------------------------------
    def balance(self, user: str) -> int:
        with self._db() as c:
            row = c.execute("SELECT COALESCE(SUM(delta),0) AS b FROM ledger WHERE user=?", (user,)).fetchone()
        return int(row["b"])

    def add_gold(self, user: str, delta: int, reason: str, ref: str = "") -> int:
        with self._db() as c:
            self.ensure(user, c)
            c.execute("INSERT INTO ledger(user,delta,reason,ref,ts) VALUES(?,?,?,?,?)",
                      (user, int(delta), reason, ref, self.clock()))
        return self.balance(user)

    def spend_gold(self, user: str, amount: int, reason: str, ref: str = "") -> int:
        amount = int(amount)
        if amount < 0:
            raise ValueError("negative spend")
        with self._db() as c:
            self.ensure(user, c)
            bal = int(c.execute("SELECT COALESCE(SUM(delta),0) AS b FROM ledger WHERE user=?", (user,)).fetchone()["b"])
            if bal < amount:
                raise Insufficient(f"need {amount} gold, have {bal}")
            c.execute("INSERT INTO ledger(user,delta,reason,ref,ts) VALUES(?,?,?,?,?)",
                      (user, -amount, reason, ref, self.clock()))
        return bal - amount

    def ledger(self, user: str, limit: int = 50) -> list:
        with self._db() as c:
            rows = c.execute("SELECT delta,reason,ref,ts FROM ledger WHERE user=? ORDER BY id DESC LIMIT ?",
                             (user, limit)).fetchall()
        return [dict(r) for r in rows]

    # --- energy ------------------------------------------------------------------------
    def _refill(self, c, user: str) -> tuple:
        self.ensure(user, c)
        row = c.execute("SELECT energy, energy_ts FROM users WHERE user=?", (user,)).fetchone()
        energy, ts = int(row["energy"]), float(row["energy_ts"])
        now = self.clock()
        if energy >= ENERGY_POOL:
            return ENERGY_POOL, now
        gained = int((now - ts) // ENERGY_REFILL_S)
        if gained > 0:
            energy = min(ENERGY_POOL, energy + gained)
            ts = now if energy >= ENERGY_POOL else ts + gained * ENERGY_REFILL_S
            c.execute("UPDATE users SET energy=?, energy_ts=? WHERE user=?", (energy, ts, user))
        return energy, ts

    def energy(self, user: str) -> dict:
        with self._db() as c:
            energy, ts = self._refill(c, user)
        now = self.clock()
        next_in = 0 if energy >= ENERGY_POOL else max(0, int(ts + ENERGY_REFILL_S - now))
        return {"energy": energy, "pool": ENERGY_POOL, "refill_s": ENERGY_REFILL_S,
                "duel_cost": DUEL_COST, "next_in_s": next_in}

    def spend_energy(self, user: str, amount: int = DUEL_COST) -> bool:
        with self._db() as c:
            energy, ts = self._refill(c, user)
            if energy < amount:
                return False
            # Leaving the pool starts the clock now; a partial pool keeps its clock.
            new_ts = self.clock() if energy >= ENERGY_POOL else ts
            c.execute("UPDATE users SET energy=?, energy_ts=? WHERE user=?", (energy - amount, new_ts, user))
        return True

    def refill_energy(self, user: str) -> int:
        with self._db() as c:
            self.ensure(user, c)
            c.execute("UPDATE users SET energy=?, energy_ts=? WHERE user=?", (ENERGY_POOL, self.clock(), user))
        return ENERGY_POOL

    # --- daily -------------------------------------------------------------------------
    def today(self) -> str:
        return date.fromtimestamp(self.clock()).isoformat()

    def daily_available(self, user: str) -> bool:
        with self._db() as c:
            self.ensure(user, c)
            row = c.execute("SELECT daily_used FROM users WHERE user=?", (user,)).fetchone()
        return (row["daily_used"] or "") != self.today()

    def use_daily(self, user: str) -> bool:
        if not self.daily_available(user):
            return False
        with self._db() as c:
            c.execute("UPDATE users SET daily_used=? WHERE user=?", (self.today(), user))
        return True

    # --- affection ---------------------------------------------------------------------
    def affection(self, user: str, character: str) -> int:
        with self._db() as c:
            row = c.execute("SELECT wins FROM affection WHERE user=? AND character=?", (user, character)).fetchone()
        return int(row["wins"]) if row else 0

    def affection_all(self, user: str) -> dict:
        with self._db() as c:
            rows = c.execute("SELECT character, wins FROM affection WHERE user=?", (user,)).fetchall()
        return {r["character"]: int(r["wins"]) for r in rows}

    def add_win(self, user: str, character: str, double: bool = False) -> int:
        inc = 2 if double else 1
        with self._db() as c:
            self.ensure(user, c)
            c.execute("""INSERT INTO affection(user,character,wins) VALUES(?,?,?)
                         ON CONFLICT(user,character) DO UPDATE SET wins=wins+excluded.wins""",
                      (user, character, inc))
            row = c.execute("SELECT wins FROM affection WHERE user=? AND character=?", (user, character)).fetchone()
        return int(row["wins"])

    # --- collection --------------------------------------------------------------------
    def collection(self, user: str) -> dict:
        with self._db() as c:
            rows = c.execute("SELECT card, n FROM collection WHERE user=? AND n>0", (user,)).fetchall()
        return {r["card"]: int(r["n"]) for r in rows}

    def give_card(self, user: str, card: str, n: int = 1) -> int:
        with self._db() as c:
            self.ensure(user, c)
            c.execute("""INSERT INTO collection(user,card,n) VALUES(?,?,?)
                         ON CONFLICT(user,card) DO UPDATE SET n=n+excluded.n""", (user, card, int(n)))
            row = c.execute("SELECT n FROM collection WHERE user=? AND card=?", (user, card)).fetchone()
        return int(row["n"])

    def give_cards(self, user: str, cards: dict) -> None:
        for cid, n in cards.items():
            self.give_card(user, cid, n)

    # --- unlocks (characters, scene skips) --------------------------------------------
    def has_unlock(self, user: str, key: str) -> bool:
        with self._db() as c:
            return c.execute("SELECT 1 FROM unlocks WHERE user=? AND key=?", (user, key)).fetchone() is not None

    def unlocks(self, user: str) -> list:
        with self._db() as c:
            return [r["key"] for r in c.execute("SELECT key FROM unlocks WHERE user=? ORDER BY ts", (user,))]

    def unlock(self, user: str, key: str) -> None:
        with self._db() as c:
            self.ensure(user, c)
            c.execute("INSERT OR IGNORE INTO unlocks(user,key,ts) VALUES(?,?,?)", (user, key, self.clock()))

    # --- gacha -------------------------------------------------------------------------
    def pity_state(self, user: str) -> dict:
        with self._db() as c:
            self.ensure(user, c)
            row = c.execute("SELECT pulls, since_epic, pull_credits FROM users WHERE user=?", (user,)).fetchone()
        return {"pulls": int(row["pulls"]), "since_epic": int(row["since_epic"]),
                "pull_credits": int(row["pull_credits"]),
                "epic_pity_in": PITY_EPIC_EVERY - int(row["since_epic"])}

    def pull(self, user: str, pool: dict, n: int = 1, rng: random.Random | None = None) -> list:
        """Draw n cards from `pool` ({rarity: [ids]}). Applies both pities. Does not charge:
        the caller decides whether Gold or a pull credit pays (see `pay_for_pull`)."""
        rng = rng or random.Random()
        if n not in (1, 10):
            raise ValueError("n must be 1 or 10")
        rarities = [r for r in ("common", "rare", "epic") if pool.get(r)]
        weights = [GACHA_WEIGHTS[r] for r in rarities]
        out = []
        with self._db() as c:
            self.ensure(user, c)
            row = c.execute("SELECT pulls, since_epic FROM users WHERE user=?", (user,)).fetchone()
            pulls, since_epic = int(row["pulls"]), int(row["since_epic"])
            got_rare_in_batch = False
            for i in range(n):
                pity = ""
                r = rng.choices(rarities, weights=weights)[0]
                since_epic += 1
                if since_epic >= PITY_EPIC_EVERY and "epic" in pool:
                    r, pity = "epic", "epic"
                elif n == 10 and i == n - 1 and not got_rare_in_batch and r == "common" and "rare" in pool:
                    r, pity = "rare", "rare"
                if r == "epic":
                    since_epic = 0
                if r in ("rare", "epic"):
                    got_rare_in_batch = True
                cid = rng.choice(pool[r])
                pulls += 1
                c.execute("INSERT INTO pulls(user,rarity,card,pity,ts) VALUES(?,?,?,?,?)",
                          (user, r, cid, pity, self.clock()))
                c.execute("""INSERT INTO collection(user,card,n) VALUES(?,?,1)
                             ON CONFLICT(user,card) DO UPDATE SET n=n+1""", (user, cid))
                out.append({"card": cid, "rarity": r, "pity": pity})
            c.execute("UPDATE users SET pulls=?, since_epic=? WHERE user=?", (pulls, since_epic, user))
        return out

    def pay_for_pull(self, user: str, n: int) -> str:
        """Pull credits first (from pull_1/pull_10 SKUs), then Gold. Returns how it was paid.
        Raises Insufficient."""
        with self._db() as c:
            self.ensure(user, c)
            credits = int(c.execute("SELECT pull_credits FROM users WHERE user=?", (user,)).fetchone()["pull_credits"])
            if credits >= n:
                c.execute("UPDATE users SET pull_credits=pull_credits-? WHERE user=?", (n, user))
                return "credits"
        self.spend_gold(user, PULL_PRICE[n], f"pull_{n}")
        return "gold"

    # --- SKU grants --------------------------------------------------------------------
    def grant(self, user: str, sku: str, payment_id: str) -> dict:
        """Fulfil a purchase. Idempotent on payment_id: the second call returns the stored
        result of the first and applies nothing. Unknown SKU -> {"ok": False}."""
        if not payment_id:
            raise ValueError("payment_id required")
        with self._db() as c:
            self.ensure(user, c)
            prior = c.execute("SELECT result FROM grants WHERE payment_id=?", (payment_id,)).fetchone()
            if prior:
                res = json.loads(prior["result"]); res["duplicate"] = True
                return res
            spec = SKUS.get(sku)
            if spec is None and sku.startswith("char_"):
                spec = {"unlock": sku}
            elif spec is None and sku.startswith("scene_skip_"):
                spec = {"unlock": sku}
            if spec is None:
                return {"ok": False, "error": "unknown sku", "sku": sku}
            applied = {}
            if spec.get("gold"):
                c.execute("INSERT INTO ledger(user,delta,reason,ref,ts) VALUES(?,?,?,?,?)",
                          (user, int(spec["gold"]), f"sku:{sku}", payment_id, self.clock()))
                applied["gold"] = int(spec["gold"])
            if spec.get("energy_full"):
                c.execute("UPDATE users SET energy=?, energy_ts=? WHERE user=?", (ENERGY_POOL, self.clock(), user))
                applied["energy"] = ENERGY_POOL
            if spec.get("pull_credits"):
                c.execute("UPDATE users SET pull_credits=pull_credits+? WHERE user=?", (int(spec["pull_credits"]), user))
                applied["pull_credits"] = int(spec["pull_credits"])
            if spec.get("unlock"):
                c.execute("INSERT OR IGNORE INTO unlocks(user,key,ts) VALUES(?,?,?)", (user, spec["unlock"], self.clock()))
                applied["unlock"] = spec["unlock"]
            res = {"ok": True, "sku": sku, "applied": applied, "duplicate": False}
            c.execute("INSERT INTO grants(payment_id,user,sku,result,ts) VALUES(?,?,?,?,?)",
                      (payment_id, user, sku, json.dumps(res), self.clock()))
        return res

    # --- summary -----------------------------------------------------------------------
    def summary(self, user: str) -> dict:
        e = self.energy(user)
        p = self.pity_state(user)
        return {"user": user, "gold": self.balance(user), "energy": e, "pity": p,
                "daily_available": self.daily_available(user), "affection": self.affection_all(user),
                "unlocks": self.unlocks(user), "pull_price": PULL_PRICE}
