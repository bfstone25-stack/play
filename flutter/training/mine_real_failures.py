#!/usr/bin/env python3
"""Turn production failures into anonymized correction specifications."""
from pathlib import Path
import argparse, json, sqlite3, sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'backend'))
import reasoning_engine as reason

LANG={'guyan':'zh','luxingye':'zh','fushen':'zh','ren':'ja','mateo':'es','caio':'pt-BR','ethan':'en','liam':'en','adrian':'en'}

def main():
  ap=argparse.ArgumentParser();ap.add_argument('--db',required=True);ap.add_argument('--out',default='real-failures.jsonl');a=ap.parse_args()
  db=sqlite3.connect(a.db);db.row_factory=sqlite3.Row; out=[]
  for i,row in enumerate(db.execute('SELECT ts,route,pid,user_msg,reply,affection FROM distill_log ORDER BY ts')):
    if any(x in (row['pid'] or '').casefold() for x in ('audit','test','smoke','e2e')): continue
    lang=LANG.get(row['route'],'en'); dec=reason.route_intent(row['user_msg'] or '')
    ok,why=reason.verify_candidate(row['reply'] or '',reason._market(lang),[],dec,row['user_msg'] or '')
    # Also mine factual turns: old replies can be fluent yet confidently wrong.
    if dec.intent=='factual' and 'requires_fact_review' not in why: why.append('requires_fact_review');ok=False
    if not ok:
      out.append({'id':f'real:{i}','split':'train','lang':lang,'route':row['route'],'stage':'UNKNOWN',
        'intent':dec.intent,'player':row['user_msg'],'rejected':row['reply'],'reject_reasons':why,
        'acceptance':'Correct the recorded failure while preserving character voice. Be factually cautious and grounded.',
        'status':'needs_chosen','source':'production_anonymized'})
  with Path(a.out).open('w') as f:
    for x in out:f.write(json.dumps(x,ensure_ascii=False)+'\n')
  print(json.dumps({'mined':len(out)},ensure_ascii=False))
if __name__=='__main__':main()
