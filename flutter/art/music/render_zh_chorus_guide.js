#!/usr/bin/env node
// Render the approved MIDI voices to a lightweight WAV guide on Pop CPU.
const fs = require("fs");
const path = require("path");
const {BPM, melody} = require("./compose_zh_theme_melody");

const SR=44100, beat=60/BPM;
const totalBeats=melody.reduce((n,x)=>n+x[1]/480,0);
const totalSamples=Math.ceil((totalBeats*beat+1)*SR);
const mix=new Float64Array(totalSamples);
const third=new Map([[62,59],[64,61],[66,62],[67,64],[69,66],[71,67],[73,69],[74,71]]);
const barSamples=4*beat*SR;

function tone(note,startSec,durSec,gain,brightness=.28){
  const f=440*Math.pow(2,(note-69)/12),a=Math.floor(startSec*SR),n=Math.floor(durSec*SR);
  const attack=Math.max(1,.025*SR),release=Math.max(1,.18*SR);
  for(let i=0;i<n&&a+i<mix.length;i++){
    const env=Math.min(1,i/attack,Math.max(0,(n-i)/release))*Math.exp(-1.15*i/n);
    const t=i/SR;
    mix[a+i]+=gain*env*(Math.sin(2*Math.PI*f*t)+brightness*Math.sin(4*Math.PI*f*t)+.1*Math.sin(6*Math.PI*f*t));
  }
}

let cursor=0;
for(const [note,ticks] of melody){
  const dur=ticks/480*beat,start=cursor;
  if(note!==null){
    tone(note+12,start,dur,.42); // approved +8va lead
    const h=third.get(note);
    const phraseEnd=ticks>=960;
    if(h!=null&&(start>=4*barSamples/SR||phraseEnd))tone(h+12,start,dur,start>=8*barSamples/SR?.24:.15,.18);
    if(start>=8*barSamples/SR)tone(note,start,dur,.18,.12);
  }
  cursor+=dur;
}

let peak=0;for(const x of mix)peak=Math.max(peak,Math.abs(x));
const data=Buffer.alloc(totalSamples*2);
for(let i=0;i<totalSamples;i++)data.writeInt16LE(Math.max(-32767,Math.min(32767,Math.round(mix[i]/peak*27500))),i*2);
const wav=Buffer.alloc(44+data.length);
wav.write("RIFF",0);wav.writeUInt32LE(36+data.length,4);wav.write("WAVEfmt ",8);
wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);wav.writeUInt32LE(SR,24);
wav.writeUInt32LE(SR*2,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write("data",36);wav.writeUInt32LE(data.length,40);
data.copy(wav,44);
const output=process.argv[2]||path.join(__dirname,"zh-walk-to-me-chorus-guide.wav");
fs.writeFileSync(output,wav);
console.log(JSON.stringify({output,duration:cursor.toFixed(3)}));
