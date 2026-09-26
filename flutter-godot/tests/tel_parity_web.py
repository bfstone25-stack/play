# Drive flutter-godot's web build and record every window.TEL call by name.
import asyncio, os, json
from playwright.async_api import async_playwright
import sys
URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8790/"
WRAP = """() => { if (!window.TEL || window.__telwrapped) return !!window.TEL;
  window.__tel = []; const t = window.TEL;
  const ev = t.ev, chat = t.chat;
  t.ev = function(n, v){ window.__tel.push(['ev', n, v]); return ev.apply(this, arguments); };
  t.chat = function(u, r, m){ window.__tel.push(['chat', m]); return chat.apply(this, arguments); };
  window.__telwrapped = true; return true; }"""
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(args=["--use-gl=angle", "--enable-unsafe-swiftshader"])
        pg = await (await b.new_context(viewport={"width": 1280, "height": 720})).new_page()
        await pg.goto(URL, wait_until="load", timeout=180000)
        for _ in range(60):
            if await pg.evaluate(WRAP): break
            await pg.wait_for_timeout(1000)
        await pg.wait_for_timeout(15000)
        await pg.mouse.click(215, 634)          # BEGIN
        await pg.wait_for_timeout(8000)
        await pg.mouse.click(360, 170)          # first route card
        await pg.wait_for_timeout(5000)
        await pg.mouse.click(900, 680)          # input
        await pg.keyboard.type("hello")
        await pg.keyboard.press("Enter")
        await pg.wait_for_timeout(40000)
        await pg.screenshot(path="shots/s01_after_chat.png")
        print("TEL CALLS:", json.dumps(await pg.evaluate("window.__tel || null")))
        await b.close()
os.makedirs("shots", exist_ok=True)
asyncio.run(main())
