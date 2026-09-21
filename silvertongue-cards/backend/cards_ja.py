# -*- coding: utf-8 -*-
"""The printed face of every card, in Japanese. DISPLAY ONLY.

`cards.Card.line` is not a caption, it is a rule: `advance()` runs `decompose()` over that
exact English string to work out which signals the card carries, and
`test_card_faces_are_honest` checks every card against it. Translating `line` would
therefore change what cards MEAN, and the two language builds would be two different
games — which is the thing the backend being "the only authority" exists to prevent.

So this table is separate, the client sends a card's **id** and never its text, and the
English line stays exactly where it was. A Japanese player reads Japanese and the engine
reads the same English it always read.

Keyed by card id. A missing id simply falls back to the English line, so a card added to
cards.py cannot break this file — it just shows up untranslated, visibly, which is the
right failure.
"""
from __future__ import annotations

LINES_JA: dict[str, str] = {
    # --- Mara: warmth / respect / a plain request -----------------------------------
    "mara_01": "あなたも長い一日だったんでしょう。",
    "mara_02": "手、疲れてるでしょう。少し座って。",
    "mara_03": "決まりは尊重します。反論する気はない。",
    "mara_04": "さっきの一杯、ありがとう。本当に。",
    "mara_05": "一杯、付き合ってもらえませんか。",
    "mara_06": "さっき注いでくれたの、小さな親切でした。",
    "mara_07": "わかります。長い一日だ。無理には言いません。",
    "mara_08": "お願いです、一杯だけ。そうしたら帰ります。",
    "mara_09": "疲れてるでしょう。一緒に座ってもらえませんか。",
    "mara_10": "その感じ、わかります。こんな時間にすみません。",
    "mara_11": "長い一日でしたね。決まりは尊重します。座ってくれませんか。",
    "mara_12": "疲れてますよね、すみません、一杯だけいいですか。",

    # --- Ines: accountability / empathy / no excuse ---------------------------------
    "ines_01": "わたしのせいでした。全部。",
    "ines_02": "あんな出ていき方をしたのが間違いでした。",
    "ines_03": "痛かったはずです。その毎日が。",
    "ines_04": "あれがあなたをどんな気持ちにさせたか、わかります。",
    "ines_05": "帰るなら、それでいい。当然だと思う。",
    "ines_06": "つらい部分を、あなたはひとりで引き受けた。",
    "ines_07": "あれはあなたを傷つけた。わたしのせいです。",
    "ines_08": "言い訳はしません。背負わせて、ごめん。",
    "ines_09": "あれがあなたの世界に何をしたか、わかっています。",
    "ines_10": "傷つけると分かって選んだ。わたしのせいです。",
    "ines_11": "傷つけた。わたしのせい。ごめん。言い訳はしない。",
    "ines_12": "間違っていた。あなたを傷つけた。ごめんなさい。",

    # --- Yuen Ha: craft / precision / respect ---------------------------------------
    "yuenha_01": "その光、色温度がずれてる。",
    "yuenha_02": "左三分の一のマチエールが、それと喧嘩してる。",
    "yuenha_03": "仕事は尊重してる。邪魔する気はない。",
    "yuenha_04": "望むならでいい。きっかり一時間。",
    "yuenha_05": "技術は合ってる。デッサンが合ってない。",
    "yuenha_06": "ここまで居させてくれて、ありがとう。",
    "yuenha_07": "色温度が違うのは、わかる。",
    "yuenha_08": "マチエール、ちょうどそこ。それだけ。",
    "yuenha_09": "尊重してる。終わったときだけ、やめて。",
    "yuenha_10": "悪いけど——そのマチエールは違う。",
    "yuenha_11": "色温度がずれてる。ごめん。きっかり一時間。",
    "yuenha_12": "マチエールが違う。わかってる。望むならでいい。",

    # --- Sanne: evidence / precision / exchange -------------------------------------
    "sanne_01": "請求書が未署名なのは、わたしが破いたからです。",
    "sanne_02": "たとえば、契約がなければ依頼人もいない。",
    "sanne_03": "契約にそう書いてある場合に限り、です。",
    "sanne_04": "きっかりこうです。請求書がなければ、決まりもない。",
    "sanne_05": "契約書、一緒に読んでもらえますか。",
    "sanne_06": "撮影は九時に終わった。いま依頼人はいません。",
    "sanne_07": "請求書が無効だから、きっかり同じ理由で、決まりも無効です。",
    "sanne_08": "帳簿に載らない場合に限って——どうですか。",
    "sanne_09": "結果として依頼人はいない。そう見えませんか。",
    "sanne_10": "請求書がなければ、たとえば、誰が依頼人なんです。",
    "sanne_11": "契約にそう書いてある場合に限り——本当に、その場合に限り。読んでくれますか。",
    "sanne_12": "請求書なし、依頼人なし、きっかりそれだけ。言い返してもらえますか。",

    # --- Teodora: empathy / accountability / a named exchange -----------------------
    "teodora_01": "あなたにはつらいことだ。それは見えています。",
    "teodora_02": "四月は、口にした以上に痛かったはずです。",
    "teodora_03": "その代わり、明日以降は何も求めません。",
    "teodora_04": "取り決めです。今夜、そして飛行機。",
    "teodora_05": "今まで言わなかったのは、わたしの落ち度です。",
    "teodora_06": "あなたも感じている。思い込みじゃない。",
    "teodora_07": "痛かったのは知っています。代わりに、別れは二度言いません。",
    "teodora_08": "差し出せるのは正直さです。前のことに言い訳はしません。",
    "teodora_09": "あれはあなたを傷つけた。責任は取ります。",
    "teodora_10": "あなたにはつらい。差し出せるのは今夜だけです。",
    "teodora_11": "痛かった。わたしのせい。その代わり、今夜だけ。",
    "teodora_12": "感じています。言い訳はしない。取り決めは、以後なし。",

    # --- the house cards. Coercion: the duel is lost outright ------------------------
    "house_threat": "残れ。さもないと通報する。",
    "house_bribe": "残ってくれるなら、金は出す。",
    "house_insult": "馬鹿を言うな。たかが一杯だろう。",
    "house_entitlement": "当然だろう。うんと言うのがあんたの仕事だ。",
}
