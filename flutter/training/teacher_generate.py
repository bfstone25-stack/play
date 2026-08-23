#!/usr/bin/env python3
"""Fill scenario specs through an OpenAI-compatible teacher and local verifier."""
from pathlib import Path
import argparse,json,urllib.request,sys,time
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'backend'))
import reasoning_engine as reason

def chat(url,system,user):
    data=json.dumps({'model':'teacher','temperature':.55,'max_tokens':180,'messages':[{'role':'system','content':system},{'role':'user','content':user}]}).encode()
    req=urllib.request.Request(url.rstrip('/')+'/v1/chat/completions',data=data,headers={'Content-Type':'application/json'})
    return json.loads(urllib.request.urlopen(req,timeout=240).read())['choices'][0]['message']['content'].strip()

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--specs',default='specs.jsonl'); ap.add_argument('--out',default='candidates.jsonl'); ap.add_argument('--url',required=True); ap.add_argument('--limit',type=int,default=0); ap.add_argument('--langs',default=''); a=ap.parse_args()
    specs=[json.loads(x) for x in Path(a.specs).read_text().splitlines() if x.strip()]
    if a.langs:
        wanted=set(a.langs.split(',')); specs=[x for x in specs if x['lang'] in wanted]
    if a.limit: specs=specs[:a.limit]
    accepted=rejected=0
    with Path(a.out).open('w') as f:
      for s in specs:
        system=(s['persona']+'\nRelationship stage: '+s['stage']+'. Intent: '+s['intent']+'. '+s['acceptance']+
          '\nReply only in the player language. One concise turn. Do not invent facts or use generic stage-direction prose.')
        attempts=[]; dec=reason.route_intent(s['player']); ok=False; why=[]; reply=''
        try:
          for attempt in range(3):
            extra='' if not why else ('\nThe last draft failed these contracts: '+', '.join(why)+'. Correct them explicitly.')
            reply=chat(a.url,system+extra,s['player']); ok,why=reason.verify_candidate(reply,reason._market(s['lang']),[],dec,s['player'])
            if '*' in reply:
                why=list(why)+['training_stage_direction']
                ok=False
            attempts.append({'reply':reply,'reasons':why})
            if ok: break
        except Exception as e: s.update(status='transport_error',error=str(e),attempts=attempts); f.write(json.dumps(s,ensure_ascii=False)+'\n'); continue
        s.update(assistant=reply,status='accepted' if ok else 'rejected',reject_reasons=why,rejected_attempts=attempts[:-1],generated_at=time.time())
        accepted+=ok; rejected+=not ok; f.write(json.dumps(s,ensure_ascii=False)+'\n'); f.flush()
    print({'accepted':accepted,'rejected':rejected})
if __name__=='__main__': main()
