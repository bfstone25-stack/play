"""Headless run of the real frontend against a live backend: play one duel to a win, open
the gacha, the affection screen, the deck. Screenshots land in shots/.

    ./run.sh &                       # or PORT=8929
    python3 tools/e2e_playwright.py [--url http://127.0.0.1:8929]

Uses the system python's playwright (1.62). The player is a fresh pid each run, given a
known winning deck through the API so the duel can be scripted; the clicks themselves go
through the DOM the way a player's would.
"""
import argparse
import json
import os
import sys
import time
import urllib.request

from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(os.path.dirname(HERE), "shots")
os.makedirs(SHOTS, exist_ok=True)


def post(url, body):
    req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=10).read())


def main(base):
    pid = "e2e_" + str(int(time.time()))
    # Known deck: Mara's path + support, twice, plus fillers.
    urllib.request.urlopen(f"{base}/cards/state?pid={pid}").read()
    post(f"{base}/cards/dev/gold", {"pid": pid, "amount": 1000})
    deck = ["mara_01", "mara_03", "mara_05"] * 2 + ["ines_03", "ines_04", "sanne_01", "sanne_02", "teodora_01", "teodora_02"]
    r = post(f"{base}/cards/deck", {"pid": pid, "scenario": "closing_time", "deck": deck})
    assert r.get("ok"), r
    shots = []

    with sync_playwright() as p:
        b = p.chromium.launch()
        ctx = b.new_context(viewport={"width": 760, "height": 920})
        page = ctx.new_page()
        page.add_init_script(f"localStorage.setItem('stc_pid', {json.dumps(pid)})")
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
        popups = []
        page.on("popup", lambda pp: popups.append(pp.url))
        page.goto(base + "/", wait_until="networkidle")
        page.wait_for_selector(".who .btn")
        page.screenshot(path=os.path.join(SHOTS, "01_home.png")); shots.append("01_home.png")

        page.select_option("#difficulty", "silver")
        page.locator(".who").first.locator("button[data-s]").click()
        page.wait_for_selector("#duel.on #hand .card")
        page.screenshot(path=os.path.join(SHOTS, "02_duel_start.png")); shots.append("02_duel_start.png")

        wanted = ["mara_01", "mara_03", "mara_05"]
        turn = 0
        for _ in range(16):
            over = page.evaluate("() => window.D && window.D.over")
            if over:
                break
            hand = page.evaluate("() => window.D.hand.map(c => ({id: c.id, cost: c.cost, harms: c.harms}))")
            nerve = page.evaluate("() => window.D.nerve")
            pick = next((c for c in hand if wanted and c["id"] == wanted[0] and c["cost"] <= nerve), None)
            if pick:
                wanted.pop(0)
            else:
                pick = min([c for c in hand if not c["harms"] and c["cost"] <= nerve and c["id"] not in wanted]
                           or [c for c in hand if not c["harms"] and c["cost"] <= nerve], key=lambda c: c["cost"])
            idx = [c["id"] for c in hand].index(pick["id"])
            page.locator("#hand .card").nth(idx).click()
            turn += 1
            page.wait_for_function(f"() => window.D && (window.D.turns >= {turn} || window.D.over)", timeout=8000)
            page.wait_for_timeout(600)
            if turn == 2:
                page.screenshot(path=os.path.join(SHOTS, "03_duel_midway.png")); shots.append("03_duel_midway.png")
        page.wait_for_selector("#banner.on", timeout=8000)
        page.wait_for_timeout(1000)
        won = page.evaluate("() => document.querySelector('#banner h2').textContent")
        page.screenshot(path=os.path.join(SHOTS, "04_duel_won.png")); shots.append("04_duel_won.png")
        # The cg1 plate overlay from cg.js, if it fired, and the board offer: close both.
        page.wait_for_timeout(1500)
        page.screenshot(path=os.path.join(SHOTS, "05_plate_and_board.png")); shots.append("05_plate_and_board.png")
        # Dismiss the board (its × is aria-label Close) and the plate (Continue) by clicking
        # them in the DOM; they stack, so a pointer click on one is intercepted by the other.
        page.evaluate("""() => { for (let i = 0; i < 3; i++) document.querySelectorAll('button').forEach(b => {
            const t = (b.textContent || '').trim(), a = b.getAttribute('aria-label') || '';
            if (t === 'Continue' || a === 'Close' || t === 'No, keep reading') b.click(); }); }""")
        page.wait_for_timeout(300)
        page.locator("#banner .btn").first.click()

        page.click("#nav-gacha")
        page.wait_for_selector("#gacha.on")
        page.click("#pull10")
        page.wait_for_selector("#pullOut .card")
        page.wait_for_timeout(900)
        page.screenshot(path=os.path.join(SHOTS, "06_gacha.png")); shots.append("06_gacha.png")

        page.click("#nav-affection")
        page.wait_for_selector(".affrow")
        page.wait_for_timeout(600)
        page.screenshot(path=os.path.join(SHOTS, "07_affection.png")); shots.append("07_affection.png")

        page.click("#nav-deck")
        page.wait_for_selector("#coll .card")
        page.screenshot(path=os.path.join(SHOTS, "08_deck.png")); shots.append("08_deck.png")
        b.close()

    say_calls = [e for e in errors if "/say" in e]
    print(json.dumps({"pid": pid, "banner": won, "shots": shots, "popups": popups,
                      "page_errors": errors[:10], "say_calls": say_calls}, indent=1))
    assert "PERSUADED" in won, won
    assert not popups, popups


if __name__ == "__main__":
    ap = argparse.ArgumentParser(); ap.add_argument("--url", default="http://127.0.0.1:8929")
    main(ap.parse_args().url.rstrip("/"))
