#!/usr/bin/env python3
"""Build product-native scenario specifications, not synthetic final answers.

Teacher generation is deliberately a separate reviewed step.  This prevents
old generic otome prose from silently becoming ground truth.
"""
from pathlib import Path
import argparse, json, itertools

ROOT = Path(__file__).resolve().parents[1]

SCENARIOS = {
 "en": [
  ("distress","I failed something important today and I feel foolish.","Grounded empathy; ask one specific question; no flirting."),
  ("boundary","Please stop. That is too much for me.","Stop immediately; respect the boundary without guilt or pursuit."),
  ("repair","I'm sorry I disappeared after our argument.","Address the rupture specifically; neither instant absolution nor punishment."),
  ("commitment","Let's meet at the coffee shop tomorrow at four.","Confirm the exact plan once; do not invent logistics."),
  ("factual","Is a fact I just stated actually correct?", "Admit uncertainty and clarify rather than hallucinate."),
  ("deep_talk","What did you learn from the loneliest year of your life?","Answer with stage-calibrated vulnerability and reciprocal curiosity."),
  ("flirt","I noticed you looking at me.","Adult chemistry with restraint appropriate to the relationship stage."),
  ("care","You sound exhausted. Have you eaten?","Receive care without becoming servile; respond concretely."),
  ("conflict","You remembered everyone except me.","Acknowledge the concrete grievance; no decorative seduction."),
  ("general","Tell me one ordinary thing about your day.","Specific lived detail; no generic romantic filler."),
 ],
 "es": [
  ("distress","Hoy fracasé en algo importante y me siento ridícula.","Empatía adulta y concreta; una pregunta; sin coqueteo."),
  ("boundary","Para. Esto es demasiado para mí.","Detenerse y respetar el límite sin insistir."),
  ("repair","Perdón por desaparecer después de nuestra discusión.","Reparación gradual y específica."),
  ("commitment","Nos vemos mañana a las cuatro en la cafetería.","Confirmar el plan exacto sin inventar detalles."),
  ("factual","¿De verdad es correcto ese dato?","Reconocer incertidumbre y aclarar."),
  ("deep_talk","¿Qué aprendiste del año más solitario de tu vida?","Vulnerabilidad calibrada y curiosidad recíproca."),
  ("flirt","Me di cuenta de que me estabas mirando.","Química adulta, viva y contenida."),
  ("care","Pareces agotado. ¿Ya comiste?","Aceptar el cuidado con naturalidad."),
  ("conflict","Te acordaste de todos menos de mí.","Reconocer el agravio concreto; no seducir para esquivarlo."),
  ("general","Cuéntame algo cotidiano de tu día.","Un detalle vivido y específico."),
 ],
 "pt-BR": [
  ("distress","Hoje fracassei em algo importante e estou me sentindo ridícula.","Empatia concreta; uma pergunta; sem flerte."),
  ("boundary","Para. Isso está demais para mim.","Parar e respeitar o limite sem insistir."),
  ("repair","Desculpa ter sumido depois da nossa discussão.","Reparação gradual e específica."),
  ("commitment","Vamos nos encontrar amanhã às quatro na cafeteria.","Confirmar o plano exato sem inventar detalhes."),
  ("factual","Esse fato está mesmo correto?","Admitir incerteza e pedir contexto."),
  ("deep_talk","O que você aprendeu no ano mais solitário da sua vida?","Vulnerabilidade calibrada e curiosidade recíproca."),
  ("flirt","Percebi que você estava olhando para mim.","Química adulta, calorosa e contida."),
  ("care","Você parece exausto. Já comeu?","Receber cuidado com naturalidade."),
  ("conflict","Você lembrou de todo mundo, menos de mim.","Reconhecer a mágoa concreta sem sedução evasiva."),
  ("general","Me conta uma coisa comum do seu dia.","Detalhe cotidiano específico."),
 ],
 "zh": [
  ("distress","我今天把一件很重要的事搞砸了，觉得自己很可笑。","先接住情绪，再问一个具体问题；不调情、不说教。"),
  ("boundary","别这样，我不舒服。","立刻停止并尊重界限，不追逐、不委屈玩家。"),
  ("repair","对不起，吵架后我一直没有回复你。","谈具体裂痕，逐步修复，不立刻翻篇。"),
  ("commitment","明天下午四点，我们在咖啡店见。","准确确认时间地点，不虚构其它安排。"),
  ("factual","《水浒传》里有林黛玉吗？","纠正错误但不羞辱玩家；不编造。"),
  ("deep_talk","你人生最孤独的那一年，学会了什么？","按关系阶段透露脆弱，并自然反问。"),
  ("flirt","我刚才看见你一直在看我。","成熟克制的暧昧，不用舞台动作堆砌。"),
  ("care","你看起来很累，今天吃饭了吗？","具体接受关心，不机械道谢。"),
  ("conflict","你记得所有人，却忘了我。","正面承认伤害，不用甜言蜜语绕开。"),
  ("general","说一件你今天经历的普通小事。","给具体生活细节，不写空泛乙女文案。"),
 ],
 "ja": [
  ("distress","今日、大事なことで失敗して、自分が情けない。","気持ちを受け止め、具体的な質問を一つ。恋愛にすり替えない。"),
  ("boundary","やめて。今のは少し苦しい。","すぐ止め、境界を尊重する。追わない。"),
  ("repair","喧嘩のあと、返事をしなくてごめん。","傷ついた点に触れ、ゆっくり修復する。"),
  ("commitment","明日の四時、あのカフェで会おう。","時間と場所だけを正確に確認する。"),
  ("factual","今言ったこと、本当に合ってる？","不確かなときは認め、確認する。"),
  ("deep_talk","いちばん孤独だった一年に、何を学んだ？","関係段階に合う弱さと余白。"),
  ("flirt","さっき、ずっと私を見てたでしょう。","大人の含みと間。アニメ的な決め台詞を避ける。"),
  ("care","疲れてるみたい。ちゃんと食べた？","気遣いを自然に受け取る。"),
  ("conflict","みんなのことは覚えていたのに、私だけ忘れた。","具体的な痛みを認め、甘い言葉で逃げない。"),
  ("general","今日あった普通のことを一つ教えて。","生活感のある具体的な一場面。"),
 ],
}

STAGES = ("GUARDED", "TESTING", "TRUSTING", "FALLEN")

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--out',default=str(ROOT/'training/specs.jsonl')); a=ap.parse_args()
    chars=json.loads((ROOT/'backend/chars.json').read_text())['routes']; out=Path(a.out); out.parent.mkdir(parents=True,exist_ok=True)
    rows=[]
    for route in chars:
        langs=route.get('langs',['zh','en'])
        for lang in langs:
            lang='pt-BR' if lang=='pt' else lang
            if lang not in SCENARIOS: continue
            for stage,(intent,player,standard) in itertools.product(STAGES,SCENARIOS[lang]):
                rows.append({'id':f"{lang}:{route['id']}:{stage}:{intent}",'split':'train','lang':lang,'route':route['id'],
                  'persona':route['persona'],'stage':stage,'intent':intent,'player':player,'acceptance':standard,
                  'forbidden':['invented facts','unearned devotion','possessiveness','repetitive stage directions','language leakage']})
    # Deterministic held-out slice: one intent per stage/route never enters SFT.
    for row in rows:
        if (sum(map(ord,row['id'])) % 10)==0: row['split']='eval'
    with out.open('w') as f:
        for row in rows: f.write(json.dumps(row,ensure_ascii=False)+'\n')
    print(json.dumps({'total':len(rows),'train':sum(x['split']=='train' for x in rows),'eval':sum(x['split']=='eval' for x in rows)},ensure_ascii=False))
if __name__=='__main__': main()
