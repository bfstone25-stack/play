#!/usr/bin/env node
// High-octave lead plus staged three-part harmony for "走向我".
const fs = require("fs");
const path = require("path");
const {PPQ, BPM, melody, vlq, chunk} = require("./compose_zh_theme_melody");

const BAR = PPQ * 4;
const THIRD_BELOW = new Map([
  [62,59], [64,61], [66,62], [67,64], [69,66], [71,67], [73,69], [74,71],
]);

function meta(type, text, tick=0) {
  const body = Buffer.from(text, "utf8");
  return {tick, order:0, data:Buffer.concat([Buffer.from([0xff,type]),vlq(body.length),body])};
}
function notePair(note, start, duration, velocity=84, channel=0) {
  return [
    {tick:start, order:2, data:Buffer.from([0x90|channel,note,velocity])},
    {tick:start+duration, order:1, data:Buffer.from([0x80|channel,note,36])},
  ];
}
function makeTrack(name, program, channel, notes, lyrics=false) {
  const ev=[meta(0x03,name),{tick:0,order:0,data:Buffer.from([0xc0|channel,program])}];
  let tick=0;
  for(const [note,duration,word] of melody){
    if(note!==null){
      const produced=notes(note,tick,duration);
      if(produced) ev.push(...notePair(produced.note,tick,produced.duration??duration,produced.velocity,channel));
      if(lyrics&&word) ev.push(meta(0x05,word,tick));
    }
    tick+=duration;
  }
  ev.sort((a,b)=>a.tick-b.tick||a.order-b.order);
  const parts=[];let last=0;
  for(const e of ev){parts.push(vlq(e.tick-last),e.data);last=e.tick;}
  parts.push(Buffer.from([0x00,0xff,0x2f,0x00]));
  return chunk("MTrk",Buffer.concat(parts));
}

// Track 0: tempo and meter.
const micros=Math.round(60000000/BPM);
const conductor=chunk("MTrk",Buffer.concat([
  Buffer.from([0x00,0xff,0x03,0x09]),Buffer.from("Conductor"),
  Buffer.from([0x00,0xff,0x51,0x03,(micros>>16)&255,(micros>>8)&255,micros&255]),
  Buffer.from([0x00,0xff,0x58,0x04,0x04,0x02,0x18,0x08]),
  Buffer.from([0x00,0xff,0x2f,0x00]),
]));

// Lead is deliberately one octave higher than V1.
const lead=makeTrack("Lead +8va",0,0,(n)=>({note:n+12,velocity:94}),true);

// Lower harmony enters sparsely after four bars, then becomes continuous after eight.
const lower=makeTrack("Lower 3rd/6th",48,1,(n,t,d)=>{
  const phraseEnd=d>=PPQ*2;
  if(t<4*BAR&&!phraseEnd)return null;
  const h=THIRD_BELOW.get(n);
  return h==null?null:{note:h+12,velocity:t>=8*BAR?76:64};
});

// The original octave joins only in the second half, adding weight without
// crowding the opening hook.
const octave=makeTrack("Low Octave Lift",52,2,(n,t)=>{
  if(t<8*BAR)return null;
  return{note:n,velocity:68};
});

const header=Buffer.alloc(6);
header.writeUInt16BE(1,0); // Format 1, simultaneous tracks.
header.writeUInt16BE(4,2);
header.writeUInt16BE(PPQ,4);
const output=path.join(__dirname,"zh-walk-to-me-chorus-v2-harmony.mid");
fs.writeFileSync(output,Buffer.concat([chunk("MThd",header),conductor,lead,lower,octave]));
console.log(output);
