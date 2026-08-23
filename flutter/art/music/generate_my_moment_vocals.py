#!/usr/bin/env python3
"""Generate the four localized My Moment vocal themes after the EN pilot."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

SONGS = {
    "zh-my-moment-vocal": {
        "language": "zh", "bpm": 72, "key": "A major", "duration": 132.0,
        "lyrics": """[Verse 1]
城市熄了灯以后
我还习惯一个人走
把没说出口的温柔
藏进每一次问候

[Pre-Chorus]
你却记得我的沉默
比我记得还要清楚
原来有人不问理由
也愿意陪我停留

[Chorus]
我的心终于有了归期
绕过多少人海 刚好是你
不用把永远 一次说尽
只要睁开眼 你还在这里
我的心终于有了归期
所有小心翼翼 都被你抱紧
明天会怎样 我不再逃避
因为走到最后 刚好是你

[Verse 2]
你把寻常的日子
变成我舍不得的故事
不是烟火多么华丽
是你看见真实的自己

[Pre-Chorus]
如果夜忘了天明
如果路忘了姓名
我会循着你的呼吸
回到最安心的风景

[Chorus]
我的心终于有了归期
绕过多少人海 刚好是你
不用把永远 一次说尽
只要睁开眼 你还在这里
我的心终于有了归期
所有小心翼翼 都被你抱紧
明天会怎样 我不再逃避
因为走到最后 刚好是你

[Bridge]
没有完美对白
只有你的手 向我伸来

[Final Chorus]
我的心终于有了归期
这一次我愿意 相信欢喜
世界再拥挤 我也认得你
因为走到最后 刚好是你""",
        "tags": (
            "original high-end contemporary Chinese urban pop love song for a prestige romance drama, intimate "
            "natural adult female Mandarin vocal with excellent diction, conversational restrained verses and a "
            "radiant instantly singable Mandopop chorus, memorable title hook, piano, acoustic guitar, warm bass, "
            "live brushed drums and cinematic strings supporting the singer, sweet feeling of finally being chosen "
            "and cared for, sophisticated radio production, no vocal acrobatics, no retro pastiche, no imitation"
        ),
    },
    "ja-my-moment-vocal": {
        "language": "ja", "bpm": 80, "key": "E major", "duration": 132.0,
        "lyrics": """[Verse 1]
終電を見送った
雨はまだ止まないまま
言えなかった言葉だけ
ポケットで温めてた

[Pre-Chorus]
君は急かさず隣で
同じ夜を見ていた
沈黙にも居場所があると
初めて知ったんだ

[Chorus]
君の隣が 帰る場所
名前のない未来でもいい
世界が少し遠くなっても
この手だけは 離さないで
君の隣が 帰る場所
強くなくても 笑える場所
明日のことは 明日話そう
今はただ 君といたい

[Verse 2]
遠回りした街も
今は愛しく見えるよ
偶然だと思っていた
すべてがここへ続いてた

[Pre-Chorus]
雨粒の向こう側
君が小さく笑った
その瞬間 胸の奥で
朝が始まった

[Chorus]
君の隣が 帰る場所
名前のない未来でもいい
世界が少し遠くなっても
この手だけは 離さないで
君の隣が 帰る場所
強くなくても 笑える場所
明日のことは 明日話そう
今はただ 君といたい

[Bridge]
完璧な言葉より
重なる歩幅を信じたい

[Final Chorus]
君の隣が 帰る場所
もう迷わずに ここにいるよ
長い雨が上がる頃には
同じ朝を 君と見たい""",
        "tags": (
            "original premium Japanese pop love song for a women-oriented television romance and otome game, "
            "emotionally intimate adult female Japanese vocal, natural phrasing, unmistakable modern J-drama "
            "songwriting, restrained conversational verse, lifting pre-chorus and unforgettable open-hearted chorus, "
            "singing piano motif, clean guitar, melodic bass, live drums and expressive chamber strings, add9 warmth "
            "and elegant Japanese harmonic turns, rain clearing at dawn, no anime caricature, no imitation"
        ),
    },
    "es-my-moment-vocal": {
        "language": "es", "bpm": 88, "key": "G major", "duration": 132.0,
        "lyrics": """[Verse 1]
Yo sabía defenderme
Con palabras y con prisa
Convertía cada miedo
En la excusa de una risa

[Pre-Chorus]
Pero tú no me pediste
Que fingiera una versión
Te quedaste en el silencio
Hasta oír mi corazón

[Chorus]
Aquí es donde quiero estar
Cuando el ruido de la calle deje de importar
No me jures para siempre, mírame una vez
Y sabré que entre tus brazos puedo ser quien soy
Aquí es donde quiero estar
Sin ganar ninguna guerra, sin tener que escapar
Que mañana diga aquello que nos quiera decir
Hoy te elijo, hoy te elijo junto a mí

[Verse 2]
Cada vuelta, cada duda
Nos trajo hasta esta esquina
Y lo simple de tu mano
Cambió toda la avenida

[Pre-Chorus]
Ya no busco la respuesta
Ni la última razón
Cuando acortas la distancia
Todo encuentra su canción

[Chorus]
Aquí es donde quiero estar
Cuando el ruido de la calle deje de importar
No me jures para siempre, mírame una vez
Y sabré que entre tus brazos puedo ser quien soy
Aquí es donde quiero estar
Sin ganar ninguna guerra, sin tener que escapar
Que mañana diga aquello que nos quiera decir
Hoy te elijo, hoy te elijo junto a mí

[Bridge]
Sin discurso, sin señal
Tu sonrisa y nada más

[Final Chorus]
Aquí es donde quiero estar
Con el mundo todavía girando alrededor
Que mañana diga aquello que nos quiera decir
Hoy te elijo, hoy te elijo junto a mí""",
        "tags": (
            "original sophisticated contemporary Spanish pop love song for a Madrid romance drama, warm expressive "
            "adult female Spanish vocal, witty conversational verse and bold emotionally direct singable chorus, "
            "close nylon guitar, piano, warm bass, delicate cajon brushes, live drums and cinematic strings, elegant "
            "Mediterranean rhythmic lift without tourist flamenco, equal passionate chemistry and mature belonging, "
            "premium radio production, no dance club sound, no vocal acrobatics, no imitation"
        ),
    },
    "pt-BR-my-moment-vocal": {
        "language": "pt", "bpm": 84, "key": "E major", "duration": 132.0,
        "lyrics": """[Verse 1]
Eu sabia ir embora
Antes mesmo de chegar
Transformava qualquer sonho
Numa história pra adiar

[Pre-Chorus]
Mas você ficou por perto
Sem tentar me convencer
Fez silêncio do meu lado
Até meu medo adormecer

[Chorus]
Meu lugar é com você
Onde a vida fica simples sem deixar de acontecer
Não precisa prometer o céu inteiro de uma vez
Só segura a minha mão como você sempre fez
Meu lugar é com você
No barulho dessa rua eu só escuto a gente ser
Deixa o dia terminar, deixa o sol reaparecer
Meu lugar, meu lugar é com você

[Verse 2]
Cada tarde sem roteiro
Cada riso sem posar
Fez do nosso cotidiano
O que eu quero recordar

[Pre-Chorus]
Não procuro mais respostas
Nem um jeito de prever
Quando o mundo perde o ritmo
Seu abraço faz caber

[Chorus]
Meu lugar é com você
Onde a vida fica simples sem deixar de acontecer
Não precisa prometer o céu inteiro de uma vez
Só segura a minha mão como você sempre fez
Meu lugar é com você
No barulho dessa rua eu só escuto a gente ser
Deixa o dia terminar, deixa o sol reaparecer
Meu lugar, meu lugar é com você

[Bridge]
Sem legenda, sem final
Só seu passo junto ao meu

[Final Chorus]
Meu lugar é com você
Se amanhã mudar o mapa eu ainda vou saber
Deixa o dia começar, deixa o sol nos reconhecer
Meu lugar, meu lugar é com você""",
        "tags": (
            "original sophisticated contemporary Brazilian MPB-pop love song, warm intimate adult female Brazilian "
            "Portuguese vocal with natural diction, conversational storytelling and an irresistible singable chorus, "
            "nylon guitar, piano, Rhodes, mellow bass, featherlight pandeiro brushes, subtle live drums and warm strings, "
            "gentle syncopation, golden-hour affection and choosing an ordinary shared life, premium organic production, "
            "no carnival cliché, no lounge bossa wallpaper, no vocal acrobatics, no imitation"
        ),
    },
}


def main():
    for name, job in SONGS.items():
        result = base.post("/prompt", {"prompt": base.workflow(name, job)})
        prompt_id = result["prompt_id"]
        print(f"{name}: queued {prompt_id}", flush=True)
        while True:
            history = base.get("/history/" + prompt_id)
            if prompt_id in history:
                status = history[prompt_id].get("status", {})
                if status.get("completed"):
                    print(f"{name}: complete", flush=True)
                    break
                if status.get("status_str") == "error":
                    raise RuntimeError(json.dumps(history[prompt_id], ensure_ascii=False))
            time.sleep(5)


if __name__ == "__main__":
    main()
