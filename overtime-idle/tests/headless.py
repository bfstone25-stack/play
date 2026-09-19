#!/usr/bin/env python3
"""Headless run of the prototype: open, build a floor, advance the mocked clock, see the
return screen, pull the gacha, play the daily floor. Screenshots land in shots/.

    python3 tests/headless.py

Serves play/ (the parent's plates and _shared/board.js are referenced by relative path)."""
import http.server, os, socketserver, subprocess, sys, threading, time
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent            # play/
SHOTS = HERE.parent / "shots"
SHOTS.mkdir(exist_ok=True)
PORT = 8765 + (os.getpid() % 200)

class Quiet(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k): super().__init__(*a, directory=str(ROOT), **k)
    def log_message(self, *a): pass

srv = socketserver.TCPServer(("127.0.0.1", PORT), Quiet)
threading.Thread(target=srv.serve_forever, daemon=True).start()
URL = f"http://127.0.0.1:{PORT}/overtime-idle/frontend/index.html"

fails = []
def check(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond: fails.append(msg)

CHAIN = [(0, "coffee"), (1, "dan"), (2, "coffee"), (5, "mute"), (6, "dan"), (7, "mara")]

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1180, "height": 820})
    errors, popups = [], []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("popup", lambda pp: popups.append(pp.url))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error" and "favicon" not in m.text and "free.blazecore.dev" not in m.text and "apps.blazecore.dev" not in m.text else None)
    n = [0]
    def shot(name):
        n[0] += 1
        page.screenshot(path=str(SHOTS / f"{n[0]:02d}-{name}.png"))

    page.goto(URL)
    page.evaluate("localStorage.clear()")
    page.goto(URL)
    page.wait_for_selector("#startBtn")
    shot("intro")
    page.click("#startBtn")
    page.wait_for_timeout(300)
    check(not page.is_visible("#return.show"), "no return screen on a fresh building")
    shot("empty-floor")

    # one placement through the real UI: pick the first offer, click a cell on the canvas
    first = page.evaluate("OI.st.offers[0]")
    check(bool(first), f"offers drawn from the roster: {page.evaluate('OI.st.offers')}")
    page.click("#offers .offer >> nth=0")
    xy = page.evaluate("OI.cellXY(12)")
    page.mouse.click(xy["x"], xy["y"])
    page.wait_for_timeout(120)
    check(page.evaluate("OI.st.cells[12]") == first, f"clicked offer '{first}' landed on cell 12")
    # tap it again: it goes back to the roster
    page.mouse.click(xy["x"], xy["y"])
    page.wait_for_timeout(120)
    check(page.evaluate("OI.st.cells[12]") is None, "tapping a placed piece sends it back")
    # the rest of the chain board deterministically (objects would need buying first)
    for i, sym in CHAIN:
        page.evaluate(f"OI.state().inventory['{sym}'] = (OI.state().inventory['{sym}']|0) + 1; OI.place({i}, '{sym}')")
    page.wait_for_timeout(200)
    rate = page.evaluate("parseInt(document.getElementById('rate').textContent.replace(/,/g,''))")
    chain = page.evaluate("parseInt(document.getElementById('chain').textContent)")
    check(rate > 0, f"HUD rent/hour is a function of the board: {rate}/h at chain {chain}")
    check(chain >= 6, f"the reference board lights a six-link chain ({chain})")
    shot("built-floor")

    page.click("#settleBtn")
    page.wait_for_timeout(300)
    cg = page.evaluate("JSON.parse(localStorage.getItem('overtime-idle.cabinet.v1')).cg")
    check(page.evaluate("OI.state().bank") == 0, "a manual settle commits the board and pays nothing")
    shot("committed")

    # advance the mocked clock 8 h: 48 shifts, then the return screen
    page.click("#devH8")
    page.wait_for_selector("#return.show")
    shifts = int(page.text_content("#retShifts"))
    rent = int(page.text_content("#retRent").replace(",", ""))
    say = page.text_content("#returnSay")
    check(shifts == 48, f"return screen: {shifts} shifts after 8 h")
    check(rent == shifts * page.evaluate("OI.idle.floorShift(OI.state(), OI.state().floors[0], OI.econ.dupeMap()).pay"), f"return screen rent {rent} = shifts x board pay")
    check(len(say) > 10, f"Mirei says: {say}")
    check("cg_mirei_lease" in page.evaluate("JSON.parse(localStorage.getItem('overtime-idle.cabinet.v1')).cg"), "skill ladder evaluated on automatic shifts (cg_mirei_lease)")
    shot("return-screen")
    page.click("#returnBtn")

    # 20 h away: capped at 8 h, the extend-cap SKU offered on the screen itself
    page.evaluate("OI.advance(20*3600e3)")
    page.wait_for_selector("#return.show")
    check(int(page.text_content("#retShifts")) == 48, "20 h away still pays 48 shifts (8 h cap)")
    check(page.evaluate("!document.getElementById('returnCap').hidden"), "cap-extension SKU offered on the capped return screen")
    shot("return-capped")
    page.click("#returnBtn")

    # persistence: reload, the building resumes and the return screen comes from the saved lastSeen
    page.evaluate("OI.state().clockOffset += 3*3600e3; localStorage.setItem('overtime-idle.building.v1', JSON.stringify(OI.state()))")
    page.reload()
    page.wait_for_selector("#startBtn")
    page.click("#startBtn")
    page.wait_for_selector("#return.show")
    check(int(page.text_content("#retShifts")) == 18, "after a reload the saved building pays the 3 h it missed (18 shifts)")
    check(page.evaluate("OI.state().floors[0].cells[1]") == "dan", "the placed board survived the reload")
    page.click("#returnBtn")
    shot("after-reload")

    # a day passes: floor 1's chain covers its rent, no eviction; affection climbed
    page.click("#devD1")
    page.wait_for_selector("#return.show")
    page.click("#returnBtn")
    check(page.evaluate("OI.state().floors[0].evictions") == 0, "chain floor survived the daily rent check")
    check(page.evaluate("OI.state().floors[0].cells.filter(Boolean).length") == 6, "board intact after the check")
    dan_aff = page.evaluate("OI.econ.affection('dan')")
    check(dan_aff >= 100, f"Dan's affection counted shifts on a solvent floor: {dan_aff}")
    check(page.evaluate("OI.econ.affectionTier('dan')") >= 2, "Dan reached affection tier 2 (cg2)")

    # eviction: an empty second floor cannot cover rent
    page.evaluate("OI.state().bank += 10000; OI.idle.buildFloor(OI.state(), Date.now() + OI.state().clockOffset)")
    page.evaluate("OI.view(); OI.hud()")
    page.evaluate("OI.state().floors[1].cells[7] = 'priya'; OI.state().floors[1].builtAt -= 86400e3")   # a full day's rent is due
    page.click("#devD1")
    page.wait_for_selector("#return.show")
    ev = page.text_content("#returnFloors")
    check("EVICTED" in ev, f"return screen lists the eviction: {ev.strip()}")
    check(page.evaluate("OI.state().floors[1].cells.every(c => !c)") and page.evaluate("OI.state().floors[1].evictions") == 1, "floor 2 cleared, floor 1 kept")
    shot("return-eviction")
    page.click("#returnBtn")

    # the gacha
    page.click("#devGold"); page.click("#devGold")
    page.click("#rosterBtn")
    page.wait_for_selector("#roster.show")
    shot("roster")
    gold0 = page.evaluate("OI.econ.gold()")
    page.click("#pull10")
    page.wait_for_timeout(200)
    chips = page.evaluate("document.querySelectorAll('#pullResult .pull-chip').length")
    check(chips == 10, f"ten-pull rendered {chips} results")
    check(page.evaluate("OI.econ.gold()") == gold0 - 270, "pull_10 cost 270 Gold")
    check(page.evaluate("OI.econ.pulls()") == 10, "economy counted 10 pulls")
    shot("gacha-pull")
    page.click("#rosterClose")

    page.click("#shopBtn"); page.wait_for_selector("#shop.show"); shot("shop"); page.click("#shopClose")
    page.click("#galleryBtn"); page.wait_for_selector("#gallery.show"); shot("gallery")
    check(page.evaluate("document.querySelectorAll('#affGrid .plate-tile.got').length") >= 2, "affection plates lit for Dan (tiers 1-2)")
    page.click("#galleryClose")

    # daily floor: same pieces for everyone today, score = one settle, percentile line
    page.click("#dailyBtn"); page.wait_for_selector("#daily.show"); page.click("#dailyStart")
    page.wait_for_timeout(200)
    seq = page.evaluate("OI.st.daily.seq")
    for i in range(6):
        page.click("#offers .offer >> nth=0")
        xy = page.evaluate(f"OI.cellXY({i})")
        page.mouse.click(xy["x"], xy["y"])
        page.wait_for_timeout(60)
    shot("daily-floor")
    page.click("#settleBtn")
    page.wait_for_selector("#dailyEnd.show")
    pct = page.text_content("#dailyPct")
    check("房东" in pct, f"percentile line: {pct}")
    shot("daily-result")
    page.click("#dailyEndBtn")
    page.wait_for_timeout(1500)     # board.js offers the casual board here, in the page
    check(page.evaluate("!!document.querySelector('.bd-wrap')"), "the casual board was offered in the page after the daily floor")
    shot("board-offer")
    check(page.evaluate("OI.st.mode") == "building", "back in the building after the daily floor")

    # prestige via the dev switch
    page.evaluate("document.querySelector('.bd-wrap') && document.querySelector('.bd-wrap').remove()")
    page.click("#devPrestige")
    page.wait_for_selector("#prestige.show")
    shot("prestige-offer")
    page.click("#prestigeBtn")
    page.wait_for_timeout(200)
    check(page.evaluate("OI.state().building") == 2 and page.evaluate("OI.state().mult") == 1.5, "second building at x1.5")
    shot("building-2")

    check(popups == [], f"no popups opened ({popups})")
    check(errors == [], f"no page errors ({errors[:3]})")
    browser.close()
srv.shutdown()
print()
print(f"{len(fails)} failures" if fails else "headless run clean")
sys.exit(1 if fails else 0)
