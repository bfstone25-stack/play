#!/usr/bin/env node
// Generic headless-Chrome page screenshot via CDP.
// Usage: node web_shot.js <url> <out.png> [settle_ms] [width] [height] [fullpage]
const { spawn } = require("child_process");
const http = require("http");

const [, , url, out, settleArg, wArg, hArg, fullArg] = process.argv;
const settle = parseInt(settleArg || "4000", 10);
const width = parseInt(wArg || "1280", 10);
const height = parseInt(hArg || "900", 10);
const fullPage = fullArg === "1";
const PORT = 9344;

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
    "--headless=new", "--no-sandbox", `--user-data-dir=/tmp/chrome-webshot-${PORT}`,
    "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
    `--remote-debugging-port=${PORT}`, `--window-size=${width},${height}`,
    "--mute-audio", "--hide-scrollbars", "about:blank",
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
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id).resolve(msg.result || msg.error);
      pending.delete(msg.id);
    }
  };
  await new Promise((r) => (ws.onopen = r));
  await send("Page.enable");
  await send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile: false });
  await send("Page.navigate", { url });
  await sleep(settle);
  const shot = await send("Page.captureScreenshot", fullPage
    ? { format: "png", captureBeyondViewport: true }
    : { format: "png" });
  require("fs").writeFileSync(out, Buffer.from(shot.data, "base64"));
  console.log("SHOT ->", out);
  ws.close();
  chrome.kill("SIGKILL");
}

main().catch((e) => { console.error("FAIL", e.message); process.exit(1); });
