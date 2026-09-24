"""SILVERTONGUE: AFTER HOURS — card battle. Backend :8929.

The parent (`play/silvertongue-x/backend/app.py`) keeps the premium typed duel with the
llama.cpp actor behind `/say`. This app never calls it: a turn is a card, the engine reads
the card's line, and her reply comes from `replies.py`. No GPU in the request path.

    cd play/silvertongue-cards && ./run.sh            # backend + static frontend on :8929

Identity: the parent's scheme. A `pid` (localStorage uuid) from the client, or an account
cookie (`stc_session`) which resolves to `acct:<uid>`; the account tables are the parent's
shape, copied, in this app's own database so the two products never share a row.
"""
from __future__ import annotations

import hashlib
import json
import os
import random
import re
import secrets
import sys
import time
from datetime import date

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)                                   # play/silvertongue-cards
PLAY = os.path.dirname(ROOT)                                   # play/
PRODUCTS = os.path.dirname(PLAY)
sys.path.insert(0, ROOT)

from backend import cards as C                                  # noqa: E402
from backend import replies as R                                # noqa: E402
from shared.economy import Economy, Insufficient, DUEL_COST     # noqa: E402

DATA = os.getenv("ST_CARDS_DATA", os.path.join(HERE, "data"))
os.makedirs(DATA, exist_ok=True)
DB = os.path.join(DATA, "silvertongue_cards.db")
ECO = Economy(os.path.join(DATA, "economy.db"))
SCEN = json.load(open(os.path.join(HERE, "scenarios.json")))
SCEN_BY_ID = {s["id"]: s for s in SCEN}
EPOCH = date(2026, 7, 8)
DEV = os.getenv("CARDS_PROD", "") != "1"       # /cards/dev/* exists only in the prototype
WIN_GOLD = {"gentle": 30, "silver": 45, "gold": 60}
LADDER = [(1, "cg1"), (3, "cg2"), (6, "cg3"), (10, "cg4")]      # cg4 = tier-4 placeholder, Blaze's own

PARENT_FRONT = os.path.join(PLAY, "silvertongue-x", "frontend")
REF_DIR = os.path.join(PRODUCTS, "ops", "silvertongue_art", "ref")
SHARED_JS = os.path.join(PLAY, "_shared")


def _is_zht(lang):
    n = (lang or "").lower().replace("_", "-")
    return n in ("zht", "zh-tw", "zh-hk", "zh-hant", "zh-mo") or n.endswith("-hant")

def _is_ja(lang):
    return (lang or "").lower().replace("_", "-").startswith("ja")

def _field(s, key, lang="en"):
    # ja first, and only when the row actually carries it: STANDARD §7's rule is that a
    # language is never offered over another language's prose, so the fallback here is
    # English and never zh.
    if _is_ja(lang) and s.get(f"{key}_ja"):
        return s[f"{key}_ja"]
    if _is_zht(lang) and s.get(f"{key}_zht"):
        return s[f"{key}_zht"]
    if (lang or "").lower().startswith("zh") and s.get(f"{key}_zh"):
        return s[f"{key}_zh"]
    return s.get(f"{key}_en") or s.get(key) or ""

def _scen_ui(s, lang="en"):
    who = C.SCENARIO_CHARACTER[s["id"]]
    return {"id": s["id"], "who": who, "name": C.CHARACTERS[who]["name"],
            "title": _field(s, "title", lang), "character": _field(s, "character", lang),
            "goal": _field(s, "goal", lang), "story": _field(s, "story", lang),
            "stars": s.get("difficulty", 3),
            "cg1_caption": _field(s, "cg1_caption", lang), "cg2_caption": _field(s, "cg2_caption", lang),
            "cg3_caption": _field(s, "cg3_caption", lang),
            "needs": {"paths": [sorted(p) for p in C.RULES[s["id"]]["paths"]],
                      "help": sorted(C.RULES[s["id"]]["help"])}}


app = FastAPI(title="SUASION: After Hours — Cards")

try:
    # By file path: this package's own `shared/` would otherwise shadow Products/shared.
    import importlib.util as _ilu
    _tp = os.path.join(PRODUCTS, "shared", "telemetry.py")
    _ts = _ilu.spec_from_file_location("products_shared_telemetry", _tp)
    _tm = _ilu.module_from_spec(_ts); _ts.loader.exec_module(_tm)
    _tm.mount_telemetry(app, "silvertongue-cards")
except Exception as _e:   # pragma: no cover
    print("[telemetry]", _e)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://apps.blazecore.dev", "https://bfstone25-stack.itch.io", "https://itch.io",
                   "https://www.nutaku.net", "https://osapi.nutaku.com"],
    allow_origin_regex=r"https://([a-z0-9-]+\.)*(itch\.zone|itch\.io|nutaku\.net|nutaku\.com|workers\.dev)$",
    allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)


def _db():
    c = sqlite3_connect(DB)
    c.execute("""CREATE TABLE IF NOT EXISTS duels(player TEXT PRIMARY KEY, duel_json TEXT, updated REAL)""")
    c.execute("""CREATE TABLE IF NOT EXISTS decks(player TEXT, scen TEXT, deck_json TEXT, PRIMARY KEY(player, scen))""")
    c.execute("""CREATE TABLE IF NOT EXISTS completions(ts REAL, day INT, scen TEXT, turns INT, pid TEXT,
                 difficulty TEXT, daily INT, won INT)""")
    c.execute("""CREATE TABLE IF NOT EXISTS turn_log(ts REAL, player TEXT, scen TEXT, difficulty TEXT, card TEXT,
                 kind TEXT, phase_before TEXT, phase_after TEXT, wild INT)""")
    c.execute("""CREATE TABLE IF NOT EXISTS accounts(uid TEXT PRIMARY KEY, handle TEXT UNIQUE, display_name TEXT,
                 salt BLOB, pass_hash BLOB, created REAL, last_seen REAL)""")
    c.execute("""CREATE TABLE IF NOT EXISTS auth_sessions(token_hash TEXT PRIMARY KEY, uid TEXT, created REAL,
                 expires REAL, last_seen REAL)""")
    c.execute("""CREATE TABLE IF NOT EXISTS account_links(uid TEXT, pid TEXT, linked REAL, PRIMARY KEY(uid,pid))""")
    c.commit()
    return c

def sqlite3_connect(path):
    import sqlite3
    return sqlite3.connect(path, timeout=10)

def day_index():
    return (date.today() - EPOCH).days

def todays():
    """The parent's rotation, verbatim: day index over however many scenarios there are."""
    override = os.getenv("SILVERTONGUE_SCENARIO", "").strip().casefold()
    if override:
        chosen = next((s for s in SCEN if s["id"].casefold() == override), None)
        if chosen:
            return chosen
    return SCEN[day_index() % len(SCEN)]


# --- identity (parent scheme) ------------------------------------------------------------
def _password_hash(password, salt):
    return hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 240_000)

def _normalise_handle(handle):
    value = handle.strip()
    return value.casefold() if re.fullmatch(r"[A-Za-z0-9_\-]{3,24}", value) else ""

def _set_session(c, uid, response):
    token = secrets.token_urlsafe(32); now = time.time()
    c.execute("INSERT INTO auth_sessions VALUES(?,?,?,?,?)",
              (hashlib.sha256(token.encode()).hexdigest(), uid, now, now + 30 * 86400, now))
    response.set_cookie("stc_session", token, max_age=30 * 86400, httponly=True,
                        secure=not DEV, samesite="lax", path="/")

def _auth_uid(request):
    if request is None:
        return ""
    token = request.cookies.get("stc_session", "")
    if not token:
        return ""
    c = _db(); now = time.time(); h = hashlib.sha256(token.encode()).hexdigest()
    row = c.execute("SELECT uid FROM auth_sessions WHERE token_hash=? AND expires>?", (h, now)).fetchone()
    if row:
        c.execute("UPDATE auth_sessions SET last_seen=? WHERE token_hash=?", (now, h))
        c.execute("UPDATE accounts SET last_seen=? WHERE uid=?", (now, row[0])); c.commit()
    c.close()
    return row[0] if row else ""

def _player(request, pid: str) -> str:
    uid = _auth_uid(request)
    key = ("acct:" + uid) if uid else (pid or "")
    return key[:64]

def _ensure_player(player: str):
    """First sight of a player: the starter collection."""
    if not player:
        return
    if not ECO.collection(player):
        ECO.give_cards(player, C.starter_collection())


class AuthReq(BaseModel):
    handle: str
    password: str
    pid: str = ""

@app.post("/cards/auth/register")
def auth_register(r: AuthReq, response: Response):
    handle = _normalise_handle(r.handle)
    if not handle:
        return {"ok": False, "error": "Handle must be 3–24 letters, numbers, _ or -."}
    if not 8 <= len(r.password) <= 128:
        return {"ok": False, "error": "Passphrase must be 8–128 characters."}
    c = _db()
    if c.execute("SELECT 1 FROM accounts WHERE handle=?", (handle,)).fetchone():
        c.close(); return {"ok": False, "error": "That name is already taken."}
    uid = secrets.token_hex(16); salt = secrets.token_bytes(16); now = time.time()
    c.execute("INSERT INTO accounts VALUES(?,?,?,?,?,?,?)",
              (uid, handle, r.handle.strip(), salt, _password_hash(r.password, salt), now, now))
    if r.pid:
        c.execute("INSERT OR IGNORE INTO account_links VALUES(?,?,?)", (uid, r.pid[:64], now))
    _set_session(c, uid, response); c.commit(); c.close()
    return {"ok": True, "user": {"handle": r.handle.strip()}}

@app.post("/cards/auth/login")
def auth_login(r: AuthReq, response: Response):
    handle = _normalise_handle(r.handle); c = _db()
    row = c.execute("SELECT uid,display_name,salt,pass_hash FROM accounts WHERE handle=?", (handle,)).fetchone()
    if not row or not secrets.compare_digest(_password_hash(r.password, row[2]), row[3]):
        c.close(); return {"ok": False, "error": "Name or passphrase is incorrect."}
    _set_session(c, row[0], response); c.commit(); c.close()
    return {"ok": True, "user": {"handle": row[1]}}

@app.get("/cards/auth/me")
def auth_me(request: Request):
    uid = _auth_uid(request)
    if not uid:
        return {"authenticated": False}
    c = _db(); row = c.execute("SELECT display_name FROM accounts WHERE uid=?", (uid,)).fetchone(); c.close()
    return {"authenticated": True, "user": {"handle": row[0]}}

@app.post("/cards/auth/logout")
def auth_logout(request: Request, response: Response):
    token = request.cookies.get("stc_session", "")
    if token:
        c = _db(); c.execute("DELETE FROM auth_sessions WHERE token_hash=?", (hashlib.sha256(token.encode()).hexdigest(),)); c.commit(); c.close()
    response.delete_cookie("stc_session", path="/")
    return {"ok": True}


# --- duel persistence ----------------------------------------------------------------------
def _load_duel(player: str):
    c = _db(); row = c.execute("SELECT duel_json FROM duels WHERE player=?", (player,)).fetchone(); c.close()
    return C.Duel.from_dict(json.loads(row[0])) if row else None

def _save_duel(player: str, d):
    c = _db()
    c.execute("INSERT INTO duels(player,duel_json,updated) VALUES(?,?,?) ON CONFLICT(player) DO UPDATE SET "
              "duel_json=excluded.duel_json, updated=excluded.updated", (player, json.dumps(d.to_dict()), time.time()))
    c.commit(); c.close()

def _clear_duel(player: str):
    c = _db(); c.execute("DELETE FROM duels WHERE player=?", (player,)); c.commit(); c.close()

def _saved_deck(player: str, scen: str):
    c = _db(); row = c.execute("SELECT deck_json FROM decks WHERE player=? AND scen=?", (player, scen)).fetchone(); c.close()
    return json.loads(row[0]) if row else None

def _deck_for(player: str, scen: str) -> list:
    coll = ECO.collection(player)
    saved = _saved_deck(player, scen)
    if saved:
        owned = dict(coll)
        ok = []
        for cid in saved:
            if owned.get(cid, 0) > 0:
                owned[cid] -= 1; ok.append(cid)
        if len(ok) >= min(C.HAND_SIZE, len(ok)) and ok:
            return ok[:C.DECK_SIZE]
    return C.auto_deck(coll, scen)

def _ladder(wins: int, scen: str) -> list:
    return [f"{tier}_{scen}" for need, tier in LADDER if wins >= need]

def _affection_view(player: str) -> dict:
    aff = ECO.affection_all(player)
    out = {}
    for who, meta in C.CHARACTERS.items():
        scen = meta["scenario"]; w = aff.get(who, 0)
        out[who] = {"name": meta["name"], "scenario": scen, "wins": w,
                    "ladder": [{"at": need, "key": f"{tier}_{scen}", "tier": i + 1, "earned": w >= need,
                                "placeholder": tier == "cg4"} for i, (need, tier) in enumerate(LADDER)],
                    "unlocked": _ladder(w, scen)}
    return out


# --- endpoints ---------------------------------------------------------------------------
@app.get("/cards/health")
def health():
    return {"ok": True, "app": "silvertongue-cards", "day": day_index() + 1, "engine": C.__name__,
            "deck_size": C.DECK_SIZE, "hand_size": C.HAND_SIZE, "llm": False}

@app.get("/cards/state")
def state(request: Request, pid: str = "", lang: str = "en"):
    player = _player(request, pid)
    if not player:
        return {"error": "no identity"}
    _ensure_player(player)
    d = _load_duel(player)
    t = todays()
    return {"player": player, "economy": ECO.summary(player), "day": day_index() + 1,
            "daily": {"scenario": t["id"], "who": C.SCENARIO_CHARACTER[t["id"]],
                      "available": ECO.daily_available(player)},
            "scenarios": [_scen_ui(s, lang) for s in SCEN],
            "affection": _affection_view(player),
            "duel": d.view(lang) if d and not d.over else None,
            "tuning": {"deck_size": C.DECK_SIZE, "hand_size": C.HAND_SIZE, "max_turns": C.MAX_TURNS,
                       "duel_cost": DUEL_COST}}

@app.get("/cards/deck")
def deck_get(request: Request, pid: str = "", scenario: str = "closing_time", auto: int = 0):
    player = _player(request, pid)
    if not player:
        return {"error": "no identity"}
    _ensure_player(player)
    coll = ECO.collection(player)
    return {"collection": [{**C.card_public(cid), "n": n} for cid, n in sorted(coll.items()) if cid in C.BY_ID],
            "deck": C.auto_deck(coll, scenario) if auto else _deck_for(player, scenario),
            "deck_size": C.DECK_SIZE, "scenario": scenario,
            "wild": C.WILD.public()}

class DeckReq(BaseModel):
    pid: str = ""
    scenario: str
    deck: list

@app.post("/cards/deck")
def deck_set(r: DeckReq, request: Request):
    player = _player(request, r.pid)
    if not player:
        return {"error": "no identity"}
    coll = ECO.collection(player)
    owned = dict(coll); ok = []
    for cid in r.deck:
        if cid in C.BY_ID and cid != "wild" and owned.get(cid, 0) > 0:
            owned[cid] -= 1; ok.append(cid)
    ok = ok[:C.DECK_SIZE]
    if len(ok) < C.HAND_SIZE:
        return {"ok": False, "error": f"a deck needs at least {C.HAND_SIZE} owned cards"}
    c = _db()
    c.execute("INSERT INTO decks(player,scen,deck_json) VALUES(?,?,?) ON CONFLICT(player,scen) DO UPDATE SET deck_json=excluded.deck_json",
              (player, r.scenario, json.dumps(ok)))
    c.commit(); c.close()
    return {"ok": True, "deck": ok}

class StartReq(BaseModel):
    pid: str = ""
    scenario: str = ""
    difficulty: str = "silver"
    daily: bool = False
    lang: str = "en"

@app.post("/cards/start")
def start(r: StartReq, request: Request):
    player = _player(request, r.pid)
    if not player:
        return {"error": "no identity"}
    _ensure_player(player)
    scen = todays()["id"] if r.daily else r.scenario
    if scen not in SCEN_BY_ID:
        return {"error": "unknown scenario"}
    difficulty = r.difficulty if r.difficulty in C.MAX_TURNS else "silver"
    existing = _load_duel(player)
    if existing and not existing.over:
        return {"ok": True, "resumed": True, "duel": existing.view(r.lang), "opening": R.opening(existing.scenario, r.lang),
                "scen": _scen_ui(SCEN_BY_ID[existing.scenario], r.lang), "economy": ECO.summary(player)}
    if r.daily:
        if not ECO.use_daily(player):
            return {"error": "daily already played today"}
    elif not ECO.spend_energy(player, DUEL_COST):
        return {"error": "not enough energy", "economy": ECO.summary(player)}
    d = C.new_duel(scen, difficulty, _deck_for(player, scen), daily=r.daily)
    _save_duel(player, d)
    return {"ok": True, "resumed": False, "duel": d.view(r.lang), "opening": R.opening(scen, r.lang),
            "scen": _scen_ui(SCEN_BY_ID[scen], r.lang), "economy": ECO.summary(player)}

class PlayReq(BaseModel):
    pid: str = ""
    card: str
    text: str = ""
    lang: str = "en"

@app.post("/cards/play")
def play(r: PlayReq, request: Request):
    player = _player(request, r.pid)
    if not player:
        return {"error": "no identity"}
    d = _load_duel(player)
    if not d or d.over:
        return {"error": "no duel in progress"}
    harmed_before = bool(d.state.get("harms"))
    try:
        read = C.play_card(d, r.card, r.text)
    except C.PlayError as e:
        return {"error": str(e), "duel": d.view(r.lang)}
    rng = random.Random(d.seed + d.turns * 31)
    line = R.reply(d.scenario, read["phase_before"], read["phase_after"], read["kind"], harmed_before, rng, r.lang)
    out = {"ok": True, "reply": line, "read": read, "duel": d.view(r.lang)}
    rows = [("INSERT INTO turn_log VALUES(?,?,?,?,?,?,?,?,?)",
             (time.time(), player, d.scenario, d.difficulty, read["card"], read["kind"],
              read["phase_before"], read["phase_after"], int(read["card"] == "wild")))]
    if d.over:
        who = C.SCENARIO_CHARACTER[d.scenario]
        s = SCEN_BY_ID[d.scenario]
        rows.append(("INSERT INTO completions VALUES(?,?,?,?,?,?,?,?)",
                     (time.time(), day_index(), d.scenario, d.turns, player, d.difficulty, int(d.daily), int(d.won))))
        reward = {}
        if d.won:
            before = ECO.affection(player, who)
            wins = ECO.add_win(player, who, double=d.daily)
            gold = WIN_GOLD[d.difficulty]
            ECO.add_gold(player, gold, "duel_win", ref=f"{d.scenario}:{d.difficulty}")
            drop = C.drop_for(d.scenario, rng)
            ECO.give_card(player, drop)
            fresh = [k for k in _ladder(wins, d.scenario) if k not in _ladder(before, d.scenario)]
            for k in fresh:
                ECO.unlock(player, k)
            reward = {"affection": wins, "affection_gain": wins - before, "gold": gold,
                      "drop": C.card_public(drop), "cg_unlocked": [k for k in fresh if not k.startswith("cg4")],
                      "tier4_reached": any(k.startswith("cg4") for k in fresh)}
        else:
            out["refusal_line"] = R.refusal_line(d.scenario, r.lang) if not read["harms"] else None
        out["end"] = {"won": d.won, "turns": d.turns, "beat": R.beat(s, d.won, r.lang), "reward": reward,
                      "harmed": bool(read["harms"]), "daily": d.daily}
        _clear_duel(player)
    else:
        _save_duel(player, d)
    c = _db()
    for sql, args in rows:
        c.execute(sql, args)
    c.commit(); c.close()
    out["economy"] = ECO.summary(player)
    return out

@app.post("/cards/forfeit")
def forfeit(r: StartReq, request: Request):
    player = _player(request, r.pid)
    if player:
        _clear_duel(player)
    return {"ok": True}

@app.get("/cards/daily")
def daily(request: Request, pid: str = "", lang: str = "en"):
    player = _player(request, pid)
    t = todays()
    c = _db()
    solved = c.execute("SELECT count(*) FROM completions WHERE day=? AND scen=? AND won=1", (day_index(), t["id"])).fetchone()[0]
    mine = None
    if player:
        row = c.execute("SELECT turns FROM completions WHERE day=? AND scen=? AND pid=? AND won=1 AND daily=1 ORDER BY ts DESC LIMIT 1",
                        (day_index(), t["id"], player)).fetchone()
        mine = row[0] if row else None
    c.close()
    return {"day": day_index() + 1, "scen": _scen_ui(t, lang), "solved_today": solved,
            "available": ECO.daily_available(player) if player else True,
            "my_turns": mine, "percentile": _percentile(t["id"], mine)["percentile"] if mine else None,
            "line": {"en": "You have beaten {p}% of players.", "zh": "你已经打败了 {p}% 的玩家."}}

def _percentile(scen: str, turns):
    c = _db()
    all_t = [t for (t,) in c.execute("SELECT turns FROM completions WHERE day=? AND scen=? AND won=1", (day_index(), scen)).fetchall()]
    c.close()
    if not all_t or turns is None:
        return {"percentile": None, "solved": len(all_t)}
    better = sum(1 for t in all_t if t >= turns)     # fewer turns = better (parent's rule)
    return {"percentile": round(100 * better / len(all_t)), "solved": len(all_t)}

@app.get("/cards/percentile")
def percentile(turns: int, scenario: str = ""):
    return _percentile(scenario or todays()["id"], turns)

class PullReq(BaseModel):
    pid: str = ""
    n: int = 1

@app.post("/cards/pull")
def pull(r: PullReq, request: Request):
    player = _player(request, r.pid)
    if not player:
        return {"error": "no identity"}
    _ensure_player(player)
    if r.n not in (1, 10):
        return {"error": "n must be 1 or 10"}
    try:
        paid = ECO.pay_for_pull(player, r.n)
    except Insufficient as e:
        return {"error": str(e), "economy": ECO.summary(player)}
    got = ECO.pull(player, C.gacha_pool(), r.n)
    return {"ok": True, "paid": paid, "cards": [{**C.card_public(g["card"]), "pity": g["pity"]} for g in got],
            "economy": ECO.summary(player)}

@app.get("/cards/affection")
def affection(request: Request, pid: str = ""):
    player = _player(request, pid)
    if not player:
        return {"error": "no identity"}
    _ensure_player(player)
    return {"affection": _affection_view(player), "ladder": [{"at": n, "tier": t} for n, t in LADDER]}

@app.get("/cards/cards")
def all_cards():
    return {"cards": [C.card_public(c.id) for c in C.CARDS], "wild": C.WILD.public(), "characters": C.CHARACTERS}

class GoldReq(BaseModel):
    pid: str = ""
    amount: int = 1000

if DEV:
    @app.post("/cards/dev/gold")
    def dev_gold(r: GoldReq, request: Request):
        player = _player(request, r.pid)
        if not player:
            return {"error": "no identity"}
        _ensure_player(player)
        return {"ok": True, "gold": ECO.add_gold(player, max(0, min(r.amount, 100000)), "dev")}

    @app.post("/cards/dev/energy")
    def dev_energy(r: GoldReq, request: Request):
        player = _player(request, r.pid)
        return {"ok": True, "energy": ECO.refill_energy(player)} if player else {"error": "no identity"}


def fulfil(user: str, sku: str, payment_id: str) -> dict:
    """What gateway/nutaku.py's PUT handler calls. Idempotent on payment_id."""
    return ECO.grant(user, sku, payment_id)


# --- static: our frontend, the parent's art (by reference), the refs, the shared board ----
if os.path.isdir(os.path.join(PARENT_FRONT, "assets")):
    app.mount("/assets", StaticFiles(directory=os.path.join(PARENT_FRONT, "assets")), name="assets")
    app.mount("/x", StaticFiles(directory=PARENT_FRONT), name="parent")
if os.path.isdir(REF_DIR):
    app.mount("/ref", StaticFiles(directory=REF_DIR), name="ref")
if os.path.isdir(SHARED_JS):
    app.mount("/shared", StaticFiles(directory=SHARED_JS), name="shared")
app.mount("/", StaticFiles(directory=os.path.join(ROOT, "frontend"), html=True), name="frontend")
