#!/usr/bin/env node
// Drive headless Chrome via CDP: load a Godot web build, wait for boot,
// optional extra settle time, then screenshot.
// Usage: node cdp_shot.js <url> <out.png> [settle_ms] [click_x click_y]
const { spawn, execSync } = require("child_process");
const http = require("http");

const [, , url, out, settleArg, clickX, clickY] = process.argv;
const settle = parseInt(settleArg || "12000", 10);
const PORT = 9333;

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function getWsUrl() {
  for (let i = 0; i < 50; i++) {
    try {
      const body = await new Promise((resolve, reject) => {
        http.get(`http://127.0.0.1:${PORT}/json/list`, (res) => {
          let d = "";
          res.on("data", (c) => (d += c));
          res.on("end", () => resolve(d));
        }).on("error", reject);
      });
      const list = JSON.parse(body);
      const page = list.find((t) => t.type === "page");
      if (page) return page.webSocketDebuggerUrl;
    } catch (e) { /* retry */ }
    await sleep(300);
  }
  throw new Error("no CDP page target");
}

async function main() {
  const chrome = spawn("google-chrome", [
    "--headless=new", "--no-sandbox", "--user-data-dir=/tmp/chrome-scratch",
    "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
    `--remote-debugging-port=${PORT}`, "--window-size=1280,800",
    "--mute-audio", "about:blank",
  ], { stdio: "ignore" });
  process.on("exit", () => { try { chrome.kill("SIGKILL"); } catch (e) {} });

  const wsUrl = await getWsUrl();
  const ws = new WebSocket(wsUrl);
  let id = 0;
  const pending = new Map();
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const mid = ++id;
    pending.set(mid, { resolve, reject });
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  const consoleLines = [];
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id).resolve(msg.result || msg.error);
      pending.delete(msg.id);
    } else if (msg.method === "Runtime.consoleAPICalled") {
      const text = (msg.params.args || []).map((a) => a.value ?? a.description ?? "").join(" ");
      consoleLines.push(text);
    }
  };
  await new Promise((r) => (ws.onopen = r));
  await send("Runtime.enable");
  await send("Page.enable");
  await send("Page.navigate", { url });

  // Wait for Godot boot: the engine logs "Godot Engine vX" at start; the game
  // prints its own first log lines after the main loop starts.
  const bootWait = parseInt(process.env.BOOT_WAIT_MS || "90000", 10);
  const t0 = Date.now();
  let booted = false;
  while (Date.now() - t0 < bootWait) {
    if (consoleLines.some((l) => /Godot Engine v4|OpenGL API|GLES3|WebGL/i.test(l))) { booted = true; break; }
    await sleep(500);
  }
  await sleep(settle);

  if (clickX !== undefined && clickY !== undefined) {
    const x = parseInt(clickX, 10), y = parseInt(clickY, 10);
    await send("Input.dispatchMouseEvent", { type: "mousePressed", x, y, button: "left", clickCount: 1 });
    await send("Input.dispatchMouseEvent", { type: "mouseReleased", x, y, button: "left", clickCount: 1 });
    await sleep(parseInt(process.env.POST_CLICK_MS || "4000", 10));
  }

  const shot = await send("Page.captureScreenshot", { format: "png" });
  require("fs").writeFileSync(out, Buffer.from(shot.data, "base64"));
  console.log("BOOTED", booted, "CONSOLE", consoleLines.length, "->", out);
  const interesting = consoleLines.filter((l) => /error|Error|GODOT|Godot|SCRIPT/i.test(l)).slice(0, 8);
  for (const l of interesting) console.log("LOG:", l.slice(0, 200));
  ws.close();
  chrome.kill("SIGKILL");
}

main().catch((e) => { console.error("FAIL", e.message); process.exit(1); });
