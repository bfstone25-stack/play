#!/usr/bin/env python3
"""Held-out behavioral evaluation for an OpenAI-compatible Flutter lane."""
from pathlib import Path
import argparse, collections, json, sys, urllib.request
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'backend'))
import reasoning_engine as reason

def ask(url,s):
    system=(s['persona']+'\nRelationship stage: '+s['stage']+'. Intent: '+s['intent']+'. '+s['acceptance']+
            '\nReply only in the player language. One concise reply. Never invent facts or jump relationship stages.')
    body=json.dumps({'model':'flutter','temperature':.2,'max_tokens':180,'messages':[{'role':'system','content':system},{'role':'user','content':s['player']}]}).encode()
    req=urllib.request.Request(url.rstrip('/')+'/v1/chat/completions',data=body,headers={'Content-Type':'application/json'})
    return json.loads(urllib.request.urlopen(req,timeout=240).read())['choices'][0]['message']['content'].strip()

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--specs',default='specs.jsonl'); ap.add_argument('--url',required=True); ap.add_argument('--langs',required=True); ap.add_argument('--out',required=True); a=ap.parse_args()
    langs=set(a.langs.split(',')); specs=[json.loads(x) for x in Path(a.specs).read_text().splitlines() if x.strip()]
    specs=[x for x in specs if x['split']=='eval' and x['lang'] in langs]
    counts=collections.Counter(); results=[]
    for s in specs:
      try:
        reply=ask(a.url,s); d=reason.route_intent(s['player']); ok,why=reason.verify_candidate(reply,reason._market(s['lang']),[],d,s['player'])
      except Exception as e: reply='';ok=False;why=['transport:'+str(e)]
      counts['pass' if ok else 'fail']+=1; results.append({'id':s['id'],'reply':reply,'pass':ok,'reasons':why})
    report={'summary':dict(counts),'pass_rate':counts['pass']/max(1,len(specs)),'results':results}
    Path(a.out).write_text(json.dumps(report,ensure_ascii=False,indent=2)); print(json.dumps(report['summary']))
    if report['pass_rate'] < .90: raise SystemExit(2)
if __name__=='__main__': main()
