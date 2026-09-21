"""Drive the built package into the Chinese edition and photograph what it shows.

The zh pack (tools/derive_zh.py) can be proved on disk -- ops/check_flutter_languages.py
--game flutter-after-hours reports 480 fields, all of them real Chinese. That proves the
DATA. It does not prove that a player can get there: the edition has to be offered by
editions.js, chosen in the picker, requested from the backend with the right `lang`, and
rendered. Every one of those is a separate place it can fail, and a fallback failure looks
like working software (ops memory, `verification-that-lies`).

So this picks 中文 the way a player does and then reads the DOM back, failing if the
visible text is not Chinese.

    ops/remote_playtest.sh play/flutter-after-hours/dist/free \\
        play/flutter-after-hours/tests/zh_edition.py
"""
import asyncio, os, re, sys
from playwright.async_api import async_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8790/"
OUT = "shots"
CJK = re.compile(r"[一-鿿]")


async def main():
    os.makedirs(OUT, exist_ok=True)
    fails, errs = [], []
    async with async_playwright() as p:
        b = await p.chromium.launch(args=["--use-gl=angle", "--enable-unsafe-swiftshader"])
        pg = await (await b.new_context(viewport={"width": 1280, "height": 720})).new_page()
        pg.on("pageerror", lambda e: errs.append(str(e)))
        await pg.goto(URL, wait_until="load", timeout=150000)
        await pg.wait_for_timeout(6000)

        # 18+ interstitial, then the launch gate.
        try:
            await pg.click(".adultYes", timeout=8000)
        except Exception:
            fails.append("the 18+ gate never appeared")
        await pg.wait_for_timeout(1500)
        await pg.mouse.click(640, 400)
        await pg.wait_for_timeout(2500)
        await pg.mouse.click(640, 400)
        await pg.wait_for_timeout(6000)
        await pg.screenshot(path=os.path.join(OUT, "z00_select_en.png"))

        # The edition picker is a <select>; zh must be an option at all.
        opts = await pg.eval_on_selector_all(
            "select#editionSelect option",
            "els => els.map(e => e.value)")
        if "zh" not in opts:
            fails.append("zh is not offered in the edition picker (options: %r)" % opts)
        else:
            await pg.select_option("select#editionSelect", "zh")
            # Switching edition replays the brand intro in the new language, so the
            # route grid is several screens away again. The first run of this test
            # photographed that intro and then failed to find a card, which looked like
            # "zh is broken" and was actually "zh is two clicks further on".
            # There is a SKIP control on the intro; use it rather than clicking through
            # eight timed lines, then wait out the grid's entry animation -- the cards
            # exist in the DOM before they are visible, and Playwright will not click
            # an invisible element.
            # The brand intro is 15 lines at 8s each behind a corner SKIP (#biSkip,
            # "跳过" in this edition); the opening video has its own (#opSkip). Guessing
            # at "[class*=skip]" did not match either, and the test then sat through the
            # intro and reported the route grid as broken. Press the real ones by id.
            for _ in range(3):
                for sel in ("#biSkip", "#opSkip", "#wishSkip"):
                    try:
                        await pg.click(sel, timeout=1500)
                    except Exception:
                        pass
                await pg.wait_for_timeout(2500)
                await pg.keyboard.press("Enter")
            try:
                await pg.wait_for_selector("#cards .card", state="visible", timeout=20000)
            except Exception:
                fails.append("the zh route grid never became visible")
            await pg.wait_for_timeout(2000)
            await pg.screenshot(path=os.path.join(OUT, "z01_select_zh.png"))

            cards = await pg.eval_on_selector_all(
                "#cards .card", "els => els.map(e => e.innerText)")
            if not cards:
                fails.append("no route cards rendered in the zh edition")
            for c in cards:
                if not CJK.search(c):
                    fails.append("a zh route card has no Chinese in it: %r" % c[:60])

            # ...and into a route, where the authored beats live.
            if cards:
                await pg.click("#cards .card")
                await pg.wait_for_timeout(9000)
                await pg.screenshot(path=os.path.join(OUT, "z02_chat_zh.png"))
                body = await pg.eval_on_selector(
                    "#game", "e => e.innerText")
                latin = re.findall(r"[A-Za-z]{5,}", body)
                if not CJK.search(body):
                    fails.append("the zh chat screen shows no Chinese at all")
                # Names stay Latin ("Ethan Cole"), prose must not.
                elif len(latin) > 12:
                    fails.append("the zh chat screen is mostly Latin: %r" % latin[:10])
        await b.close()

    print("  page errors:", errs[:3] if errs else "none")
    if fails:
        print("  FAIL")
        for f in fails:
            print("   -", f)
        return 1
    print("  zh edition: offered, selectable, and rendering Chinese")
    return 0


raise SystemExit(asyncio.run(main()))
