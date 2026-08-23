#!/usr/bin/env node
// Hand-composed monophonic chorus melody for Flutter ZH theme "走向我".
// No generative model is involved. Run with Node to emit a standard MIDI file.
const fs = require("fs");
const path = require("path");

const PPQ = 480;
const BPM = 76;
const Q = PPQ;
const E = PPQ / 2;
const H = PPQ * 2;

// MIDI note numbers: D4=62. The melody is in D major, 4/4.
// Each item: [note|null for rest, duration in ticks, lyric syllable].
const melody = [
  // Chorus A — 走向我 / 现在就走向我
  [66,Q,"走"], [69,E,"向"], [66,Q+E,"我"], [null,Q,""],
  [64,E,"现"], [66,E,"在"], [69,Q,"就"], [71,Q,"走"], [69,Q,"向我"],
  // 穿过人海 / 穿过沉默
  [66,Q,"穿过"], [64,Q,"人海"], [62,H,""], 
  [64,E,"穿"], [66,E,"过"], [69,Q,"沉"], [66,Q,"默"], [64,Q,""],
  // 如果你也曾 / 为我停留
  [62,E,"如"], [64,E,"果"], [66,Q,"你也"], [69,Q,"曾"], [71,Q,""],
  [73,Q,"为"], [71,E,"我"], [69,E,"停"], [66,H,"留"],
  // 别让我们 / 只剩错过
  [64,E,"别"], [66,E,"让"], [69,Q,"我"], [71,Q,"们"], [69,Q,""],
  [66,Q,"只剩"], [64,Q,"错"], [62,H,"过"],

  // Chorus B — title returns higher, then resolves.
  [69,Q,"走"], [73,E,"向"], [71,Q+E,"我"], [null,Q,""],
  [69,E,"像"], [71,E,"我"], [73,Q,"一"], [74,Q,"直"], [73,Q,"走向你"],
  // 不用永远 / 不用承诺
  [71,Q,"不用"], [69,Q,"永远"], [66,H,""],
  [69,E,"不"], [71,E,"用"], [73,Q,"承"], [71,Q,"诺"], [69,Q,""],
  // 这一刻请你 / 选择我
  [66,E,"这"], [69,E,"一"], [71,Q,"刻请"], [73,Q,"你"], [74,Q,""],
  [73,Q,"选"], [71,E,"择"], [69,E,"我"], [66,H,""],
  // Final hook tag
  [66,Q,"走"], [69,E,"向"], [73,Q+E,"我"], [null,Q,""],
  [71,Q,"我"], [69,Q,"走向"], [66,H,"你"],
];

function vlq(value) {
  const bytes = [value & 0x7f];
  while ((value >>= 7)) bytes.unshift((value & 0x7f) | 0x80);
  return Buffer.from(bytes);
}

function chunk(type, data) {
  const head = Buffer.alloc(8);
  head.write(type, 0, 4, "ascii");
  head.writeUInt32BE(data.length, 4);
  return Buffer.concat([head, data]);
}

const events = [];
const trackName = Buffer.from("走向我 · Chorus", "utf8");
events.push(Buffer.from([0x00, 0xff, 0x03]), vlq(trackName.length), trackName);
const micros = Math.round(60000000 / BPM);
events.push(Buffer.from([0x00, 0xff, 0x51, 0x03, (micros >> 16) & 255, (micros >> 8) & 255, micros & 255]));
events.push(Buffer.from([0x00, 0xff, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08]));
events.push(Buffer.from([0x00, 0xc0, 0x00])); // Acoustic grand piano.

let pending = 0;
for (const [note, duration, lyric] of melody) {
  if (note == null) {
    pending += duration;
    continue;
  }
  if (lyric) {
    const text = Buffer.from(lyric, "utf8");
    events.push(vlq(pending), Buffer.from([0xff, 0x05]), vlq(text.length), text);
    pending = 0;
  }
  events.push(vlq(pending), Buffer.from([0x90, note, 88]));
  events.push(vlq(duration), Buffer.from([0x80, note, 40]));
  pending = 0;
}
events.push(vlq(pending), Buffer.from([0xff, 0x2f, 0x00]));

const header = Buffer.alloc(6);
header.writeUInt16BE(0, 0); // Format 0.
header.writeUInt16BE(1, 2);
header.writeUInt16BE(PPQ, 4);
function writeV1() {
  const midi = Buffer.concat([chunk("MThd", header), chunk("MTrk", Buffer.concat(events))]);
  const output = path.join(__dirname, "zh-walk-to-me-chorus-v1.mid");
  fs.writeFileSync(output, midi);
  console.log(output);
}

if (require.main === module) writeV1();
module.exports = {PPQ, BPM, melody, vlq, chunk};
