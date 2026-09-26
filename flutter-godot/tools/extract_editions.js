// Pull the five Flutter editions out of the web build's own source into data/editions.json.
// PORT_PLAN.md step 3: "the strings come out of the existing source and into data once,
// mechanically. A second hand-typed copy of five languages in GDScript is how the two
// tracks drift." Re-run after editing frontend/editions.js or the T table in index.html:
//     node tools/extract_editions.js
const fs = require("fs"), path = require("path"), vm = require("vm");
const FRONT = path.join(__dirname, "..", "..", "flutter", "frontend");
const win = {}; const ctx = {window: win, localStorage: {getItem() { return null; }, setItem() {}},
  navigator: {language: "en", languages: ["en"]}, document: {documentElement: {style: {setProperty() {}}, setAttribute() {}}}};
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(FRONT, "editions.js"), "utf8"), ctx);
const E = win.FLUTTER_EDITIONS;
const html = fs.readFileSync(path.join(FRONT, "index.html"), "utf8");
const m = html.match(/const T=(\{[\s\S]*?\}\}\});\nfunction tr\(\)/);
if (!m) throw new Error("T table not found in index.html");
const T = vm.runInNewContext("(" + m[1] + ")");
const g = html.match(/const GAME_UI=(\{[\s\S]*?\n\});\nfunction gameUi\(\)/);
if (!g) throw new Error("GAME_UI not found in index.html");
const GAME_UI = vm.runInNewContext("(" + g[1] + ")");
const ai = html.match(/const ATTACH_ICON=(\{[^;]*\});/);
const ATTACH_ICON = ai ? vm.runInNewContext("(" + ai[1] + ")") : {};
const src = E && E.editions;
if (!src) throw new Error("editions.js exposed no editions: keys " + Object.keys(win));
const order = E.order || ["en", "es", "pt-BR", "zh", "ja"];
const out = {order: order, editions: {}, attach_icon: ATTACH_ICON};
for (const id of order) {
  const e = src[id] || (E.get && E.get(id));
  const t = T[id] || T.en;
  out.editions[id] = {id, label: e.label, contentSet: e.contentSet, title: e.title,
    localTitle: e.localTitle, tagline: e.tagline, palette: e.palette,
    ui: {sub: t.sub, aff: t.aff, ph: t.ph, send: t.send, back: t.back, enter: t.enter, chips: t.chips},
    story: GAME_UI[id] || GAME_UI.en};
}
// The opening (opening.js `const scripts` + `fieldRecordings`): per edition, the timed
// shots over one scene image, and the ambience bed. Assets are copied beside them.
const op = fs.readFileSync(path.join(FRONT, "opening.js"), "utf8");
const sm = op.match(/const scripts = (\{[\s\S]*?\n  \});\n/);
const am = op.match(/const fieldRecordings = (\{[\s\S]*?\});/);
if (!sm || !am) throw new Error("opening.js scripts/fieldRecordings not found");
const OPEN = vm.runInNewContext("(" + sm[1] + ")"), AMB = vm.runInNewContext("(" + am[1] + ")");
const OUTDIR = path.join(__dirname, "..", "assets", "opening");
fs.mkdirSync(OUTDIR, {recursive: true});
const opening = {};
for (const id of Object.keys(OPEN)) {
  const sc = OPEN[id];
  for (const sh of sc.shots) if (sh.scene) { const b = path.basename(sh.scene); fs.copyFileSync(path.join(FRONT, sh.scene), path.join(OUTDIR, b)); sh.scene = "res://assets/opening/" + b; }
  let amb = "";
  if (AMB[id]) { const b = path.basename(AMB[id]); fs.copyFileSync(path.join(FRONT, AMB[id]), path.join(OUTDIR, b)); amb = "res://assets/opening/" + b; }
  opening[id] = {duration: sc.duration, shots: sc.shots, ambience: amb};
}
const attr = path.join(FRONT, "audio", "ambience", "ATTRIBUTION.md");
if (fs.existsSync(attr)) fs.copyFileSync(attr, path.join(OUTDIR, "AMBIENCE-ATTRIBUTION.md"));
out.opening = opening;
fs.writeFileSync(path.join(__dirname, "..", "assets", "editions.json"), JSON.stringify(out, null, 1) + "\n");
console.log("editions:", order.join(" "));
