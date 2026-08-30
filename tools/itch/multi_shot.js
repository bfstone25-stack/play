#!/usr/bin/env node
// Multi-shot CDP capture: load a page, then run a scripted sequence of
// waits/clicks/keys, capturing a screenshot at each marked step.
// Usage: node multi_shot.js <url> <outprefix> <width> <height> <script>
//   script = comma-separated steps: w<ms> (wait), c<x>,<y> (click), k<KEY> (key), s<name> (shot)
// Example: node multi_shot.js URL /tmp/game 1280 800 "w8000,stitle,c640,400,w3000,smenu"
const { spawn } = require("child_process");
const http = require("http");

const [, , url, outprefix, wArg, hArg, scriptArg] = process.argv;
const width = parseInt(wArg || "1280", 10);
const height = parseInt(hArg || "800", 10);
const PORT = 9355 + Math.floor(Math.random() * 40);

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
    "--headless=new", "--no-sandbox", `--user-data-dir=/tmp/chrome-multi-${PORT}`,
    "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
    `--remote-debugging-port=${PORT}`, `--window-size=${width},${height}`,
    "--mute-audio", "--hide-scrollbars", "--autoplay-policy=no-user-gesture-required",
    "about:blank",
  ], { stdio: "ignore" });
  process.on("exit", () => { try { chrome.kill("SIGKILL"); } catch (e) {} });

  const wsUrl = await getWsUrl();
  const ws = new WebSocket(wsUrl);
  let id = 0;
  const pending = new Map();
  const consoleLines = [];
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const mid = ++id;
    pending.set(mid, { resolve, reject });
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
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
  await send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile: false });
  await send("Page.navigate", { url });

  const steps = (scriptArg || "w8000,smain").split(/,(?=[wcksj][a-z0-9])/i);
  for (const step of steps) {
    const op = step[0];
    const rest = step.slice(1);
    if (op === "w") {
      await sleep(parseInt(rest, 10));
    } else if (op === "c") {
      const [x, y] = rest.split(",").map((v) => parseInt(v, 10));
      await send("Input.dispatchMouseEvent", { type: "mousePressed", x, y, button: "left", clickCount: 1 });
      await send("Input.dispatchMouseEvent", { type: "mouseReleased", x, y, button: "left", clickCount: 1 });
    } else if (op === "k") {
      await send("Input.dispatchKeyEvent", { type: "keyDown", key: rest, code: rest });
      await send("Input.dispatchKeyEvent", { type: "keyUp", key: rest, code: rest });
    } else if (op === "j") {
      const expr = Buffer.from(rest, "base64").toString("utf8");
      const r = await send("Runtime.evaluate", { expression: expr, returnByValue: true });
      console.log("JS:", JSON.stringify(r && r.result && r.result.value).slice(0, 200));
    } else if (op === "s") {
      const shot = await send("Page.captureScreenshot", { format: "png" });
      const out = `${outprefix}-${rest}.png`;
      require("fs").writeFileSync(out, Buffer.from(shot.data, "base64"));
      console.log("SHOT ->", out);
    }
  }
  const errs = consoleLines.filter((l) => /error|failed|404/i.test(l)).slice(0, 6);
  for (const l of errs) console.log("LOG:", l.slice(0, 180));
  ws.close();
  chrome.kill("SIGKILL");
}

main().catch((e) => { console.error("FAIL", e.message); process.exit(1); });
