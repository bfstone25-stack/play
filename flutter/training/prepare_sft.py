#!/usr/bin/env python3
"""Convert verified teacher candidates into immutable train/eval artifacts."""
from pathlib import Path
import argparse, collections, hashlib, json

PACK = {'en':'west','es':'west','pt-BR':'west','zh':'zh','ja':'ja'}

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--input',default='candidates.jsonl'); ap.add_argument('--outdir',default='ready'); a=ap.parse_args()
    out=Path(a.outdir); out.mkdir(parents=True,exist_ok=True); rows=[json.loads(x) for x in Path(a.input).read_text().splitlines() if x.strip()]
    files={}
    stats=collections.Counter()
    try:
      for row in rows:
        pack=PACK[row['lang']]; split=row.get('split','train')
        if row.get('status')!='accepted': stats[f'{pack}:rejected']+=1; continue
        key=(pack,split); files.setdefault(key,(out/f'{pack}-{split}.jsonl').open('w'))
        runtime=(f"edition={row['lang']}; route={row['route']}; relationship_stage={row['stage']}; "
                 f"intent={row['intent']}; acceptance={row['acceptance']}")
        text=f"<|user|>\n[RUNTIME STATE] {runtime}\nPLAYER: {row['player']}\n<|assistant|>\n{row['assistant']}"
        files[key].write(json.dumps({'text':text,'source_id':row['id']},ensure_ascii=False)+'\n'); stats[f'{pack}:{split}']+=1
    finally:
      for f in files.values(): f.close()
    manifest={'counts':dict(stats),'source_sha256':hashlib.sha256(Path(a.input).read_bytes()).hexdigest()}
    (out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
    print(json.dumps(manifest,ensure_ascii=False))
if __name__=='__main__': main()
