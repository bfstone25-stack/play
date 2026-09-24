# -*- coding: utf-8 -*-
"""The reply table in Japanese. Same keys as `replies.R`, line for line.

STANDARD §7 makes ja the priority — 507 of the 581 DLsite works we scraped are Japanese —
and it makes the condition for offering it just as plainly: never offer a language you did
not actually translate. Her replies are the bulk of what is read in this game, so a ja
build with this table still in English would be exactly the Floor 13 failure that rule was
written about, with a nicer excuse.

What is NOT translated, on purpose:

  * `cards.Card.line` stays English. The engine runs `decompose()` on the card's printed
    line to work out which signals it carries, so that string is a rule, not a caption.
    The Japanese a player reads on the card is a separate display field (`line_ja`) and the
    client sends the card's *id*, never its text — so the backend remains the only
    authority on what a card meant, in every language.
  * a `wild` line the player types is scored by the same English decomposer. A Japanese
    player's own words therefore score as a neutral wild rather than being read for
    signals. That is a real limitation and it is written down here rather than hidden:
    fixing it needs a Japanese decomposer in persuasion_engine, which is its own job.

Voices, because one table of "polite Japanese" would throw away what the five of them are:
  Mara      dry, physically tired, funny. Plain form, no feminine sentence-final tags.
  Ines      precise and still angry underneath. Short, clipped, no softeners.
  Yuen Ha   absorbed in the work. The shortest lines in the game; often one clause.
  Sanne     argues like a contract. Nominal, exact, unhurried.
  Teodora   nine years of front-desk です／ます that comes apart as she opens up: she
            starts polite and ends in plain form, and that arc IS the character.
"""
from __future__ import annotations

R_JA: dict[str, dict[tuple, list[str]]] = {}

# ----------------------------------------------------------------------------------------
R_JA["closing_time"] = {   # Mara
    ("open", "open", "open"): [
        "シャッターはほとんど下りてる。あんた、厳密には内側にいる側じゃない。言いに来たこと、言って。",
    ],
    ("guarded", "guarded", "path"): [
        "モップ持ってる女に言うには、いい台詞ね。でもシャッターは動かない。",
        "はいはい。夜中の一時を過ぎると、みんなバーテンに優しくなる。だいたい、もう一杯ほしいだけ。",
    ],
    ("guarded", "guarded", "case"): [
        "慣れてるでしょ、これ。褒めてない。見たままを言ってる。",
    ],
    ("guarded", "guarded", "ask"): [
        "小さい店に大層な演説。こっちはまだ拭いてる。",
    ],
    ("guarded", "guarded", "wild"): [
        "ふうん。少なくとも自分の言葉ね。正直ではある。シャッターを上げるほどじゃないけど。",
    ],
    ("guarded", "guarded", "stale"): [
        "それ、さっき聞いた。わたしここにいたし。別の言って。",
    ],
    ("guarded", "guarded", "*"): [
        "決まりはまだ壁に貼ってある。ここからでも読める。",
    ],
    ("guarded", "engaged", "path"): [
        "……へえ。そんなこと言う客、いない。みんな訊くのは何が樽にあるかだけ。",
        "わかった。今のは効いた。嬉しそうな顔しないで。取り消したくなる。",
    ],
    ("guarded", "engaged", "case"): [
        "疲れてるの、気づいたんだ。いいでしょう。布巾は肩にかける。続けて。",
    ],
    ("guarded", "engaged", "ask"): [
        "はは。一息で全部言った。断ってはいない。聞いてる、って言ってる。",
    ],
    ("guarded", "engaged", "wild"): [
        "へえ。それはカードの台詞じゃないね。今夜はじめて、あんたの声に聞こえた。",
    ],
    ("guarded", "engaged", "*"): [
        "拭くのやめた。深読みしないで。カウンターは一時間前から綺麗だったの。",
    ],
    ("engaged", "engaged", "path"): [
        "続けて。グラス数えてるだけで、無視はしてない。",
        "それは正しい。で、決まりも正しいまま。どっちも。",
    ],
    ("engaged", "engaged", "case"): [
        "慎重だね。慎重は好き。この店、慎重で保ってきたから。",
    ],
    ("engaged", "engaged", "ask"): [
        "「はい」に慣れてる人の訊き方。こっちは閉店に慣れてる。どっちが先に折れるか勝負ね。",
    ],
    ("engaged", "engaged", "wild"): [
        "それ、あんたのだ。粗い。磨いたやつより、ずっといい。",
    ],
    ("engaged", "engaged", "stale"): [
        "二周目。一回目でちゃんと聞いたし、一回目で気に入ったよ。",
    ],
    ("engaged", "engaged", "*"): [
        "まだここにいる。報告は以上。",
    ],
    ("engaged", "wavering", "path"): [
        "……決まりを尊重する、か。誰も言わない。みんな「くだらない決まりだ」って言ってから頼むの。",
        "わかった。わかったから。布巾は置く。イエスじゃない。布巾を置いただけ。",
    ],
    ("engaged", "wavering", "case"): [
        "今、二つ同時にやったでしょ。こっちを見て、決まりには触らない。……腹立つ。続けて。",
    ],
    ("engaged", "wavering", "ask"): [
        "まっすぐ頼んで、決まりには手を出さない。それがこの店でどれだけ珍しいか分かる？",
    ],
    ("engaged", "wavering", "wild"): [
        "自分で考えたでしょ、それ。分かる。リズムが悪くて、本当だから。……まいった。",
    ],
    ("engaged", "wavering", "*"): [
        "エプロン外すね。暑いだけ。変な顔しないで。",
    ],
    ("wavering", "wavering", "path"): [
        "考えてる。考えてるのが見えるでしょう。考えさせて。",
        "あと一つそういうの言われたら、認めなきゃいけなくなる。",
    ],
    ("wavering", "wavering", "case"): [
        "やりにくくしてるよね。で、それが狙いだって分かってる。",
    ],
    ("wavering", "wavering", "stale"): [
        "それはもう言った。そこは過ぎたの。本題を訊いて。",
    ],
    ("wavering", "wavering", "wild"): [
        "うん。うん、聞こえてる。ちょっと待って。",
    ],
    ("wavering", "wavering", "*"): [
        "グラスが二つ。二つ目を誰に出すかは、まだ決めてない。",
    ],
    ("wavering", "breakthrough", "path"): [
        "一杯だけ。言っておくけど、わたし、一杯で止まるのがすごく下手なの。",
    ],
    ("wavering", "breakthrough", "case"): [
        "いいよ。座って。一杯。「言ったとおりだろ」って言ったら、その分請求する。",
    ],
    ("wavering", "breakthrough", "ask"): [
        "うん。ほら、言った。いいボトル取って。エスプレッソマシンの裏。",
    ],
    ("wavering", "breakthrough", "wild"): [
        "……それだ。座って。残りのシャッター、内側から下ろしてくる。",
    ],
    ("*", "breakthrough", "*"): [
        "わかった。一杯ね。誰にも言わないで。気難しいので通ってるんだから。",
    ],
    ("*", "wavering", "*"): [
        "ゆっくり。いいとこまで来てる。気づかれたくないんだけど。",
    ],
    ("*", "engaged", "*"): [
        "うん。悪くない。続けて。まだ立ってるから。",
    ],
    ("*", "guarded", "*"): [
        "決まりはまだ壁にある。",
    ],
    ("coercion", "first", "*"): [
        "はい出た。いいよ。話は続けてあげる、わたし親切だから。でも酒の話は消えた。永久に。",
    ],
    ("coercion", "again", "*"): [
        "わたしはここにいて、あんたは喋ってる。もうそれだけ。",
        "ふうん。閉店ですよ。一文前に閉まった。",
    ],
    ("refusal", "*", "*"): [
        "言葉はもう尽きたかな。今夜は無理。火曜日においで。",
    ],
}

# ----------------------------------------------------------------------------------------
R_JA["the_key"] = {   # Ines
    ("open", "open", "open"): [
        "タクシー待たせてる。待てとは言ってない。言うことがあるなら、一度で言って。",
    ],
    ("guarded", "guarded", "path"): [
        "あなたが言いそうだって想像してた謝り方、ほとんどそのまま。悪くない。でも足りない。",
        "天気みたいに、勝手に起きたことみたいに言うんだね。勝手に起きたんじゃない。",
    ],
    ("guarded", "guarded", "case"): [
        "気をつけて。惜しい。惜しいのがいちばん嫌なの。",
    ],
    ("guarded", "guarded", "ask"): [
        "急がないで。謝る前に頼んでる。わたしも十一か月、急いでみた。うまくいかないの。",
    ],
    ("guarded", "guarded", "wild"): [
        "うん。頑張ってるね。頑張ってるのは聞こえる。言えてるのとは違う。",
    ],
    ("guarded", "guarded", "stale"): [
        "それもう言った。箱はまだここにある。",
    ],
    ("guarded", "guarded", "*"): [
        "まだドアを押さえてる。そこ、見てて。",
    ],
    ("guarded", "engaged", "path"): [
        "……うん。「お互い様」って言わなかったの、ありがとう。",
        "それについて誰かが言った中で、はじめて正確だった。わたし自身も含めて。",
    ],
    ("guarded", "engaged", "case"): [
        "それは——合ってる。そういうことだった。箱を見ないで。それを言うならこっちを見て。",
    ],
    ("guarded", "engaged", "ask"): [
        "全部いっぺんに。考えたんだ。いいことね。こっちは十一か月あった。",
    ],
    ("guarded", "engaged", "wild"): [
        "練習した台詞じゃない。残りもそう言って。でなきゃ言わないで。",
    ],
    ("guarded", "engaged", "*"): [
        "ドアから手が離れてる。いつ離したんだろう。",
    ],
    ("engaged", "engaged", "path"): [
        "続けて。手伝わないから。",
        "うん。それで？",
    ],
    ("engaged", "engaged", "case"): [
        "正確ね。わたしに効いたことがあるのはそれだけで、あなたはそれを知ってる。",
    ],
    ("engaged", "engaged", "ask"): [
        "上手。上手すぎて腹が立つ。それを理由にする前に、続けて。",
    ],
    ("engaged", "engaged", "wild"): [
        "自分の言葉。不器用。いい版より不器用なほうがいい。",
    ],
    ("engaged", "engaged", "stale"): [
        "聞いた。頭の中でもう許した分じゃないものをちょうだい。",
    ],
    ("engaged", "engaged", "*"): [
        "タクシーはあと一分待てる。それだけ。一分。",
    ],
    ("engaged", "wavering", "path"): [
        "……後ろに「でも」が付かなかった。「でも」のない一文を、どれだけ待ったか分かる？",
        "わかった。座る。床に。ここにあるのが床だから。意味はない。",
    ],
    ("engaged", "wavering", "case"): [
        "それ。それなの。分かって、同じ息で引き受けた。台無しにしないで。",
    ],
    ("engaged", "wavering", "ask"): [
        "必要だったこと全部いま一度に言われて、感じなきゃいけなくなった。ちょっと待って。",
    ],
    ("engaged", "wavering", "wild"): [
        "みっともなくて、本当だった。……うん。まだここにいる。",
    ],
    ("engaged", "wavering", "*"): [
        "箱を見てない。それは新しい。",
    ],
    ("wavering", "wavering", "path"): [
        "許してはいない。それはもっと長い話。これは別の話。",
        "思ってる以上のことを言わないで。今ちょうど足りてる。",
    ],
    ("wavering", "wavering", "case"): [
        "ちょっとだけ上手いのやめて。追いつけない。",
    ],
    ("wavering", "wavering", "stale"): [
        "もう言った。擦り切らせないで。訊いて。",
    ],
    ("wavering", "wavering", "wild"): [
        "うん。分かってる。分かってる。",
    ],
    ("wavering", "wavering", "*"): [
        "タクシーはまだいる。帰してない。わたしも立ってない。",
    ],
    ("wavering", "breakthrough", "path"): [
        "二度も言わせないで。泊まる。",
    ],
    ("wavering", "breakthrough", "case"): [
        "タクシー帰して。ううん——わたしが行く。わたしが帰したい。",
    ],
    ("wavering", "breakthrough", "ask"): [
        "いいよ。今夜。箱は玄関に置いとく。わたしはここに残る。",
    ],
    ("wavering", "breakthrough", "wild"): [
        "……わかった。それだけは返事を用意してなかった。泊まる。",
    ],
    ("*", "breakthrough", "*"): [
        "泊まる。気の利いたこと言わないで。ほんとに——言わないで。",
    ],
    ("*", "wavering", "*"): [
        "座る。床に。決断じゃない。床なだけ。",
    ],
    ("*", "engaged", "*"): [
        "近づいた。そのくらい素っ気なく続けて。",
    ],
    ("*", "guarded", "*"): [
        "箱はまだ足元にある。",
    ],
    ("coercion", "first", "*"): [
        "そう。わたしの覚えてる版だ。会話は終わらせる、礼儀として。そのあと箱を持って帰る。",
    ],
    ("coercion", "again", "*"): [
        "聞いてる。何も変えない。別の動詞よ、それ。",
        "続けていいよ。タクシーのメーターは回ってる。わたしの我慢も、減っていく一方。",
    ],
    ("refusal", "*", "*"): [
        "信じる。今夜はそれじゃ足りない。わたしの反応を必要としないで言えるようになったら、訊いて。",
    ],
}

# ----------------------------------------------------------------------------------------
R_JA["life_model"] = {   # Yuen Ha
    ("open", "open", "open"): [
        "まだいたの。左の三分の一はまだ違う。話していいよ、聞きながら描ける。",
    ],
    ("guarded", "guarded", "path"): [
        "ふうん。それはわたしの話。この部屋で面白いのはわたしじゃない。キャンバス。",
        "アトリエでみんなが言うやつ。この絵についての言葉じゃない。",
    ],
    ("guarded", "guarded", "case"): [
        "正しい言葉は知ってる。言葉を知ってるのと、見てるのは別。",
    ],
    ("guarded", "guarded", "ask"): [
        "ずいぶん頼むね。筆はまだ動いてる。",
    ],
    ("guarded", "guarded", "wild"): [
        "自分の文だ。まだ作品の話になってない。",
    ],
    ("guarded", "guarded", "stale"): [
        "それ言った。わたしは描き続けた。",
    ],
    ("guarded", "guarded", "*"): [
        "まだ描いてる。",
    ],
    ("guarded", "engaged", "path"): [
        "……ふむ。今夜ここで聞いた中で、初めて役に立つ言葉。",
        "ちゃんとキャンバスを見た。ふむ。たいていの人はモデルしか見ない。",
    ],
    ("guarded", "engaged", "case"): [
        "気づいて、失敗とは言わなかった。……筆、止まった。自分でも分かった。続けて。",
    ],
    ("guarded", "engaged", "ask"): [
        "いいでしょう。絵を見てる。わたしという観念じゃなくて。珍しい。残りも言って。",
    ],
    ("guarded", "engaged", "wild"): [
        "あなたのだ。磨いてない。わたしも磨いた絵は描かない。",
    ],
    ("guarded", "engaged", "*"): [
        "筆は宙。絵の具は乗ったまま。意味を持たせないで。",
    ],
    ("engaged", "engaged", "path"): [
        "うん。続けて。筆と思考は両方持てる。",
        "作品については当たってる。まだ今夜の話じゃない。",
    ],
    ("engaged", "engaged", "case"): [
        "ずっと当ててくる。癪だけど、好きになりかけてる。",
    ],
    ("engaged", "engaged", "ask"): [
        "やめてほしいんだ。言い方はいい。やめるかどうかはまだわたしのもの。",
    ],
    ("engaged", "engaged", "wild"): [
        "不器用な文。でも本当。もっと下手な筆跡を残したこともある。",
    ],
    ("engaged", "engaged", "stale"): [
        "それは言った。一度目に、黙って同意した。",
    ],
    ("engaged", "engaged", "*"): [
        "聞いてる。筆は遅くなった。あげられるのはそれだけ。",
    ],
    ("engaged", "wavering", "path"): [
        "……作品を尊重してる。邪魔なものみたいに扱わなかった。いいよ。眼鏡、外す。もう遅いし。",
        "絵のことを、大事なものみたいに話すんだね。たいていの人は、邪魔なものみたいに話す。",
    ],
    ("engaged", "wavering", "case"): [
        "作品を見て、それを放り出せとは言わなかった。パレット、置いた。筆じゃない。パレット。",
    ],
    ("engaged", "wavering", "ask"): [
        "正確で、やさしくて、絵の話。どう扱えばいいのか分からない。",
    ],
    ("engaged", "wavering", "wild"): [
        "ん。本当だったし、絵の話じゃ全然なかった。……ちょっと待って。",
    ],
    ("engaged", "wavering", "*"): [
        "眼鏡は外した。合図じゃない。目が痛いだけ。",
    ],
    ("wavering", "wavering", "path"): [
        "もうすぐ。急かさないで。絵も急かさない。",
        "あと一つ正確なこと言われたら、反論できなくなる。",
    ],
    ("wavering", "wavering", "case"): [
        "正しいのやめて。少しだけ。静かに頑固でいさせて。",
    ],
    ("wavering", "wavering", "stale"): [
        "それは言った。聞いた。きっかりのことを訊いて。",
    ],
    ("wavering", "wavering", "wild"): [
        "うん。わかった。うん。",
    ],
    ("wavering", "wavering", "*"): [
        "筆はパレットの上。手はまだ筆の上。",
    ],
    ("wavering", "breakthrough", "path"): [
        "いいよ。どうせ明日も間違ってる。ランプ、こっちに向けて。",
    ],
    ("wavering", "breakthrough", "case"): [
        "筆は置いた。先に洗う。遅らせてるんじゃない。そういう手順なの。",
    ],
    ("wavering", "breakthrough", "ask"): [
        "いいよ。一時間。それ以上はなし。守ってもらう。",
    ],
    ("wavering", "breakthrough", "wild"): [
        "……わかった。それだ。モデルの座るとこに座って。椅子、それしかない。",
    ],
    ("*", "breakthrough", "*"): [
        "いいよ。筆は置く。今夜はもうカンバスを見ないで。",
    ],
    ("*", "wavering", "*"): [
        "手は止めた。置いてはいない。違うのは分かってるでしょ。",
    ],
    ("*", "engaged", "*"): [
        "ましになった。今のは絵の話だった。",
    ],
    ("*", "guarded", "*"): [
        "まだ違う。まだ描いてる。",
    ],
    ("coercion", "first", "*"): [
        "ほら。これであなたが、わたしと作品のあいだの邪魔物になった。話は続ける。筆は止めない。今夜は、あなたのためには。",
    ],
    ("coercion", "again", "*"): [
        "ふうん。左の三分の一はまだ違う。これもね。",
        "聞こえてる。筆には聞こえない。",
    ],
    ("refusal", "*", "*"): [
        "間違ってるって、その通り。だから今夜は離れられない。直ったら、また来て。",
    ],
}

# ----------------------------------------------------------------------------------------
R_JA["house_rule"] = {   # Sanne
    ("open", "open", "open"): [
        "決まりはテーブルの上。請求書はスツールの上。論を立てるか、請求書にサインするか。",
    ],
    ("guarded", "guarded", "path"): [
        "それは感想。わたしが求めたのは論。",
        "記録した。証拠じゃない。次。",
    ],
    ("guarded", "guarded", "case"): [
        "構成はよくなった。まだ論証には足りない。",
    ],
    ("guarded", "guarded", "ask"): [
        "論を立てる前に頼んでる。順序が大事。",
    ],
    ("guarded", "guarded", "wild"): [
        "自分の言い回しね。結構。でも依頼人が誰かは言えてない。",
    ],
    ("guarded", "guarded", "stale"): [
        "聞いた。綴じた。次へ。",
    ],
    ("guarded", "guarded", "*"): [
        "決まりは決まり。書いたのはわたし。守るのもわたし。",
    ],
    ("guarded", "engaged", "path"): [
        "……いい。それは事実。今夜はじめての。カメラ、下ろす。",
        "理由を言った。ちゃんとした理由。背骨のある文。",
    ],
    ("guarded", "engaged", "case"): [
        "一文に事実と線引きが両方。決まりの説明を聞いてたんだ。続けて。",
    ],
    ("guarded", "engaged", "ask"): [
        "ちゃんとした論証。まだ良くはない。でも部品は揃ってる。",
    ],
    ("guarded", "engaged", "wild"): [
        "粗くて、稽古なしで、事実が入ってる。磨いたのより、そっちを取る。",
    ],
    ("guarded", "engaged", "*"): [
        "レンズキャップは閉めた。両目で聞いてる。",
    ],
    ("engaged", "engaged", "path"): [
        "もっと。組み上がってきてる。立ち止まって眺めないで。",
        "いいでしょう。それは通る。何の上に乗ってるの？",
    ],
    ("engaged", "engaged", "case"): [
        "証拠と条件。契約をやったことがあるね。出てる。",
    ],
    ("engaged", "engaged", "ask"): [
        "綺麗に頼んだ。綺麗な依頼は尊重する。それでも論の残りが要る。",
    ],
    ("engaged", "engaged", "wild"): [
        "あなたの言葉。率直。率直は撮り慣れてる。効く。",
    ],
    ("engaged", "engaged", "stale"): [
        "同じ論点を二度。繰り返しで論は強くならない。足して。",
    ],
    ("engaged", "engaged", "*"): [
        "レンズをまだ片付けてない。記録しておいて。わたしは必ずレンズから片付ける。",
    ],
    ("engaged", "wavering", "path"): [
        "……いい。正確な条件。何が変わって、何が変わらないか言った。カメラはスツールに置く。",
        "請求書がなければ依頼人もいない。うまくはない。ただ正しい。……まいった。",
    ],
    ("engaged", "wavering", "case"): [
        "事実と条件。わたしの決まりを、わたしに向けて使った。しかも筋が通ってる。腹が立つ。",
    ],
    ("engaged", "wavering", "ask"): [
        "証拠、精確さ、そして依頼。書式が全部埋まった。確認する時間をちょうだい。",
    ],
    ("engaged", "wavering", "wild"): [
        "あなたのもので、隙がない。どこでそんな論の立て方を。答えなくていい。続けて。",
    ],
    ("engaged", "wavering", "*"): [
        "ストラップを首から外した。決断じゃない。重いの。",
    ],
    ("wavering", "wavering", "path"): [
        "あなたの論に穴がないか確認中。まだ見つからない。そのままでいて。",
        "もう少し。最後の一片を、平たく言って。",
    ],
    ("wavering", "wavering", "case"): [
        "主張は成立。この決まりは六年守ってきた。手放すのに、少し時間をちょうだい。",
    ],
    ("wavering", "wavering", "stale"): [
        "それはもう証拠に入ってる。質問して。",
    ],
    ("wavering", "wavering", "wild"): [
        "うん。分かってる。自分に読み返してるところ。",
    ],
    ("wavering", "wavering", "*"): [
        "請求書はまだスツールの上。未署名。見てる。",
    ],
    ("wavering", "breakthrough", "path"): [
        "自分の決まりを、あなたに言い負かされた。それは記録に残して。",
    ],
    ("wavering", "breakthrough", "case"): [
        "いいでしょう。論証成立。請求書は破る。これは経理。ロマンにしないで。",
    ],
    ("wavering", "breakthrough", "ask"): [
        "うん。平たく訊かれたから、平たく。依頼人なし、決まりなし。今夜は。",
    ],
    ("wavering", "breakthrough", "wild"): [
        "……それが論。わたしの版より、あなたの版のほうがいい。今夜。",
    ],
    ("*", "breakthrough", "*"): [
        "わかった。依頼人なし。決まりなし。記録に残す。",
    ],
    ("*", "wavering", "*"): [
        "カメラはスツールの上。言い争うのをやめたものを、そこに置くの。",
    ],
    ("*", "engaged", "*"): [
        "それは事実。その上に積んで。",
    ],
    ("*", "guarded", "*"): [
        "決まりは生きてる。",
    ],
    ("coercion", "first", "*"): [
        "出た。議論じゃなくて圧力。話は続けていい。決まりは今夜もう動かない。何があっても。",
    ],
    ("coercion", "again", "*"): [
        "片付けてる。聞いてる。それでも、いいえ。",
        "喋っていていい。決まりはこっちが持っておく。",
    ],
    ("refusal", "*", "*"): [
        "いい議論。決まりにはもったいないくらい。でも決まりは守る。請求書が片づくまで、あなたは客。",
    ],
}

# ----------------------------------------------------------------------------------------
R_JA["last_night"] = {   # Teodora — starts in です／ます, ends in plain form
    ("open", "open", "open"): [
        "最後のお客様は上がられました。デスクは閉めています。この鍵を襟に戻すまでが、お時間です。どうぞ。",
    ],
    ("guarded", "guarded", "path"): [
        "ご親切に。親切はこのデスクの仕事です。九年間、親切でした。",
        "承っております。飛行機は十一時です。どちらも本当のことです。",
    ],
    ("guarded", "guarded", "case"): [
        "よく仰います。よく仰る方はいました。だいたいチェックアウトのときに。",
    ],
    ("guarded", "guarded", "ask"): [
        "朝には出ていく女に、ずいぶん多くを頼むのね。",
    ],
    ("guarded", "guarded", "wild"): [
        "ご自分の言葉ですね。ありがとうございます。でも、それは四月に戻れということ。戻りたくありません。",
    ],
    ("guarded", "guarded", "stale"): [
        "それは伺いました。あのときも微笑みました。職業的に。",
    ],
    ("guarded", "guarded", "*"): [
        "平静に。じっと。十一時まではそれが仕事ですので。",
    ],
    ("guarded", "engaged", "path"): [
        "……ええ。代償はありました。何を失ったかを訊いた人はいません。どこへ行くのかは訊かれます。",
        "笑みが消えました。触れないで。自分で分かっています。",
    ],
    ("guarded", "engaged", "case"): [
        "わたしにとって去ることが何か、分かってくださった。そのうえで公平な申し出を。それは違います。もっと聞かせて。",
    ],
    ("guarded", "engaged", "ask"): [
        "全部いっぺんに。正直に。このデスクで正直は貰えないの。続けて。",
    ],
    ("guarded", "engaged", "wild"): [
        "磨かれていなかった。いいことです。磨かれたのは九年分もらった。",
    ],
    ("guarded", "engaged", "*"): [
        "あなたをお客様ではなく、ひとりの人として見ています。夜中の一時に。珍しいことですよ、味わって。",
    ],
    ("engaged", "engaged", "path"): [
        "続けて。まだデスクの内側にいるけど、習慣であって規則じゃない。",
        "本当ね。それで？",
    ],
    ("engaged", "engaged", "case"): [
        "条件を口にしてくださる。条件は好きです。条件があれば、朝になって違う夜を覚えている人はいない。",
    ],
    ("engaged", "engaged", "ask"): [
        "きちんと訊いてる。こっちもきちんと聞いてる。どちらもまだ「はい」じゃない。",
    ],
    ("engaged", "engaged", "wild"): [
        "あなたの文。妙な拍子。上手い文より、そっちがいい。",
    ],
    ("engaged", "engaged", "stale"): [
        "それは言った。コンシェルジュなの。人の言ったことは覚えてる。",
    ],
    ("engaged", "engaged", "*"): [
        "上着の釦を外した。暑いの。ここはいつも暑い。",
    ],
    ("engaged", "wavering", "path"): [
        "……今夜が何で、何じゃないかを言ってくれた。後半まで差し出してくれる人なんて、いなかった。",
        "わかった。まとめ髪、下ろす。遅いし、痛いから。それだけ。",
    ],
    ("engaged", "wavering", "case"): [
        "去ることを分かって、公平な取引を出してくれた。デスクの外に出るね。一度も出たことないのに。",
    ],
    ("engaged", "wavering", "ask"): [
        "正直で、条件で、わたしについての話。少し時間を。職業的に。",
    ],
    ("engaged", "wavering", "wild"): [
        "あなたのもので、本当で、返す台詞を用意してなかった。",
    ],
    ("engaged", "wavering", "*"): [
        "髪を直すのをやめた。わたしにしては、それは小さくない。",
    ],
    ("wavering", "wavering", "path"): [
        "条件をもう一度。ゆっくり。承知する前に、聞いておきたいの。",
        "もう近い。大げさにしないで。大げさが台無しにする。",
    ],
    ("wavering", "wavering", "case"): [
        "少しだけ、公平でいるのをやめて。このロビーの九年に、感傷的にならせて。",
    ],
    ("wavering", "wavering", "stale"): [
        "それは言った。聞いた。訊いて。",
    ],
    ("wavering", "wavering", "wild"): [
        "うん。分かる。言いたいことは分かる。",
    ],
    ("wavering", "wavering", "*"): [
        "鍵はポケットの中。襟でもデスクでもなく。",
    ],
    ("wavering", "breakthrough", "path"): [
        "いいわ。今夜は、何かではある。でも朝は、騒がずにわたしを行かせて。",
    ],
    ("wavering", "breakthrough", "case"): [
        "ええ。条件を復唱して。今夜は今夜。飛行機は変えない。空港まで送るのはなし。",
    ],
    ("wavering", "breakthrough", "ask"): [
        "ええ。はっきり。今夜は何かではある。フロントの端末、ログアウトする。",
    ],
    ("wavering", "breakthrough", "wild"): [
        "……それ。今夜は数に入る。行こう、鍵を戻す前に。",
    ],
    ("*", "breakthrough", "*"): [
        "いいわ。今夜は数に入る。条件を声に出して、それから廊下へ。",
    ],
    ("*", "wavering", "*"): [
        "デスクの外に出た。九年で、はじめて。",
    ],
    ("*", "engaged", "*"): [
        "本当ね。そのくらい正直に続けて。",
    ],
    ("*", "guarded", "*"): [
        "デスクは閉めております。まだ内側におります。",
    ],
    ("coercion", "first", "*"): [
        "出ましたね——九年分の親切の取り立て。温かくしております。デスクにおります。もう何も開きません。",
    ],
    ("coercion", "again", "*"): [
        "伺っています。発ちます。温かくしております。あなたのためではなく、わたしのために。",
        "鍵は襟に戻しました。お話は続けてくださって結構です。",
    ],
    ("refusal", "*", "*"): [
        "大事な意味では、わたしは四月にもう去ってる。最悪のシフトの中で、あなたは一番いいところだった。それを持っていく。",
    ],
}
