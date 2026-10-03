# Per-route RPG strings (key: (EN, JA)): names, the route-select line, night cards (the
# parent's chapter titles and goals, translated here for the card), venue names, keepsakes,
# gifts, his hold lines (the fork's own, used as his standoff barks), the rivals, and the
# standoff names/intros/wins built from templates. The chapter prose itself is NOT here: it
# is the parent's, in data/story/, English (+ the parent's Chinese where real).
R = {
 "guyan": dict(name=("Gu Yan", "顧言"), pick=("Gu Yan, 33 — the bookshop owner who left the sign turned around", "顧言（33）— 閉店の札を裏返したままにした古書店の店主"),
   ch=[("Out of the Rain", "雨宿り", "Make him want to keep the lights on a little longer for you", "彼に「もう少し明かりを点けていたい」と思わせる", "The bookshop at dusk", "夕暮れの古書店"),
       ("The One Who Came Back", "戻ってきた人", "Find out why he keeps this shop all alone", "彼がひとりで店を守る理由を知る", "The bookshop, afternoon", "午後の古書店"),
       ("The Umbrella in the Rain", "雨の中の傘", "Read what he won't say out loud", "彼が口にしない言葉を読み取る", "The corner in the rain", "雨の街角"),
       ("The Shop That Almost Wasn't", "なくなりかけた店", "Decide whether to help him fight for this shop", "この店のために一緒に闘うか決める", "Behind the counter", "カウンターの奥"),
       ("The Line Written For You", "あなたに書かれた一行", "Hear him finish the sentence he never could", "彼が言えずにいた一文を最後まで聞く", "The shop, reopened", "再開した古書店")],
   ks=[("A bookmark from the counter", "カウンターのしおり"), ("Dango's favourite chair", "団子のお気に入りの椅子"), ("The umbrella he lent you", "彼が貸してくれた傘"),
       ("The poem on the flyleaf", "見返しの詩"), ("A key to the shop", "店の鍵")],
   gift=("A pressed-flower bookmark", "押し花のしおり"),
   hold=["彼はゆっくりと頷く。何かを覚えようとする時の仕草だ。", "「ゆっくりでいいよ」と彼は言う。「雨も急いでないから」",
         "団子が二人のあいだに落ち着く。彼はそれを、しばらく黙っていていい許しだと受け取る。", "「その続きを聞きたいな」と彼は言い、自分の大胆さに頬を染める。"]),
 "ethan": dict(name=("Ethan", "イーサン"), pick=("Ethan Cole, 38 — the man who finally put the phone face-down", "イーサン・コール（38）— ついにスマホを伏せて置いた男"),
   ch=[("Wrong Floor", "間違えた階", "Make him remember your name", "彼にあなたの名前を覚えさせる", "The top floor at midnight", "真夜中の最上階"),
       ("Not a Coincidence", "偶然じゃない", "Find out why he's here every night", "彼が毎晩ここにいる理由を知る", "His office lounge", "彼の執務ラウンジ"),
       ("Where He Shouldn't Be", "いるはずのない場所", "See who he is when he's not on the top floor", "最上階にいない時の彼を見る", "The noodle shop", "雨の夜の麺屋"),
       ("The Fracture", "亀裂", "Decide whether to stand on his side", "彼の側に立つか決める", "The gala", "祝賀パーティー"),
       ("The Light He'd Turn Off", "彼が消す明かり", "Get him to say what he actually wants", "彼が本当に望むことを言わせる", "The top floor, lights off", "灯りを消した最上階")],
   ks=[("A visitor badge for the wrong floor", "階を間違えた入館証"), ("His father's night-shift story", "父の夜勤の話"), ("A noodle-shop receipt", "麺屋のレシート"),
       ("His co-founder's name", "共同創業者の名前"), ("The top-floor light switch", "最上階のスイッチ")],
   gift=("A thermos of good coffee", "上等なコーヒーの魔法瓶"),
   hold=["彼は沈黙を埋めない。ただそこに置き、あなたがそれをどうするかを見ている。", "「続けて」と彼は言う。「今夜はどこにも行かない」",
         "彼はグラスを机の上で四分の一回転させ、口はつけない。", "「もう一度言って」と彼は言う。「ゆっくり。聞き間違いじゃないか確かめたい」"]),
 "luxingye": dict(name=("Lu Xingye", "陸星野"), pick=("Lu Xingye, 27 — the idol in an off-season nobody knows about", "陸星野（27）— 誰も知らないオフシーズンのアイドル"),
   ch=[("Backstage by Accident", "間違って舞台裏へ", "Make him drop the idol mask for one minute", "一分だけ、彼にアイドルの仮面を外させる", "Backstage", "舞台裏"),
       ("The Idol's Secret", "アイドルの秘密", "Find out what the 'perfect idol' is really carrying", "「完璧なアイドル」が本当に背負っているものを知る", "The rehearsal room", "深夜のリハーサル室"),
       ("The Confession to Row Seven", "七列目への告白", "In front of thousands, catch the words meant only for you", "何万人の前で、あなただけへの言葉を受け取る", "The arena, row seven", "アリーナ七列目"),
       ("The Storm", "嵐", "Decide which side to stand on — him, or the industry's rules", "彼か、業界のルールか、どちらに立つか決める", "Outside the boardroom", "役員会議室の前"),
       ("The Song Only For You", "あなただけの歌", "On the smallest stage, catch his truest words", "いちばん小さな舞台で、彼の本当の言葉を受け取る", "The little livehouse", "小さなライブハウス")],
   ks=[("Half a convenience-store rice ball", "コンビニおにぎりの半分"), ("The private account's first message", "非公開アカウントの最初のメッセージ"),
       ("Your row-seven ticket", "七列目のチケット"), ("The clip everyone saw", "皆が見た動画"), ("A handwritten setlist", "手書きのセットリスト")],
   gift=("A plain hoodie, his size", "彼のサイズの無地のパーカー"),
   hold=["彼は椅子の背にあごを乗せて、にっと見上げる。「どうぞ。聞いてるよ」", "「こんなふうに話しかけてくる人、いないんだ」と彼は言う。「俺のために止めないで」",
         "彼は二音だけ弾いて止め、弦ではなくあなたを見る。", "「もっと話して」と彼は言う。「この部屋より、君の声のほうが好きだ」"]),
 "liam": dict(name=("Liam", "リアム"), pick=("Liam, 34 — the firefighter next door", "リアム（34）— 隣に住む消防士"),
   ch=[("Moving-In Day", "引っ越しの日", "Make him remember you as more than 'the new neighbor'", "「新しいお隣さん」以上の存在として覚えてもらう", "His tailgate at sunset", "夕暮れの荷台"),
       ("Cookout and Old Scars", "バーベキューと古傷", "See the side this always-smiling man keeps tucked away", "いつも笑っている彼が隠している一面を見る", "The backyard cookout", "裏庭のバーベキュー"),
       ("The Watch in the Fire", "炎の中の腕時計", "On his most dangerous night, be the reason he wants to make it back", "彼のいちばん危険な夜に、帰ってきたい理由になる", "The fire on your street", "通りの火事"),
       ("The Transfer", "転属", "In the choice he'd shoulder alone, let him know he doesn't have to", "ひとりで背負おうとする決断を、ひとりで背負わなくていいと伝える", "The station garage", "消防署のガレージ"),
       ("The One Who Comes Home", "帰ってくる人", "Hear this man who always puts others first say what he wants for himself", "いつも人を優先する彼に、自分の望みを言わせる", "The new porch", "新しいポーチ")],
   ks=[("The couch he carried", "彼が運んだソファ"), ("Biscuit's chewed tennis ball", "ビスケットの噛んだテニスボール"), ("The watch from the fire", "火事から戻った腕時計"),
       ("The transfer letter", "転属の辞令"), ("Two root beers", "ルートビア二本")],
   gift=("A new chew toy for Biscuit", "ビスケットの新しいおもちゃ"),
   hold=["彼は荷台にもたれて、あなたに全部の注意を向ける。それはかなりの量の注意だ。", "「話してて」と彼は言う。「六時まで、どこにも行く用はないから」",
         "ビスケットがため息をついて二人の足の上に寝転び、あなたをそこに留める。", "「そこがいいとこなんだ」と彼は言う。「続きを言って」"]),
 "adrian": dict(name=("Adrian", "エイドリアン"), pick=("Adrian Vale, 31 — the rockstar who writes about you", "エイドリアン・ヴェイル（31）— あなたのことを歌うロックスター"),
   ch=[("The Stage After the Show", "終演後のステージ", "Make this man who's bored of everyone look at you twice", "誰にも飽きている彼に、二度見させる", "The empty stage", "誰もいないステージ"),
       ("The Late-Night Demo", "深夜のデモ", "Find out what the man who's untamed on stage is really writing about", "舞台では奔放な彼が本当は何を書いているのか知る", "The back of the tour bus", "ツアーバスの後部"),
       ("The Song He Wrote For You", "あなたのための歌", "On his most public stage, catch his most private confession", "いちばん公の舞台で、いちばん私的な告白を受け取る", "The arena encore", "アリーナのアンコール"),
       ("The Label's Price", "レーベルの代償", "Between his music and his heart, help him keep the one song he won't sell", "音楽と心のあいだで、彼が売らない一曲を守る手助けをする", "The label's boardroom", "レーベルの会議室"),
       ("The Song, Finished", "完成した歌", "Hear him sing the last line of the song he wrote for you", "あなたのための歌の最後の一行を聴く", "The underground livehouse", "地下のライブハウス")],
   ks=[("A guitar pick from the stage", "舞台のピック"), ("A crumpled lyric sheet", "くしゃくしゃの歌詞カード"), ("The line he sang to you", "あなたに歌った一行"),
       ("The clause he won't sign", "彼が署名しない条項"), ("The unreleased demo", "未発表のデモ")],
   gift=("A notebook of blank staff paper", "白紙の五線譜ノート"),
   hold=["彼は答えない。あなたを見ている。彼の場合、それが答えと同じだ。", "「止めるな」と彼は短く言う。「まだ飽きてない」",
         "彼は手のひらで弦を押さえて、あなたの声がよく聞こえるようにする。そして、そうしなかったふりをする。", "「もう一回」と彼は言う。「そこ。もう一回言って」"]),
 "fushen": dict(name=("Fu Shen", "傅深"), pick=("Fu Shen, 36 — the aloof heir the whole city looks up to", "傅深（36）— 街じゅうが仰ぎ見る、近寄りがたい御曹司"),
   ch=[("The Distance of One Glass of Wine", "ワイン一杯ぶんの距離", "Make this man who never explains himself say more than three sentences to you", "決して弁明しない彼に、三文以上話させる", "The penthouse study", "ペントハウスの書斎"),
       ("He Explains Himself to No One", "誰にも弁明しない人", "See what that coldness is really guarding against", "その冷たさが本当は何を守っているのかを見る", "The gala hall", "祝賀会のホール"),
       ("The Young Madam of the Old House", "旧家の若奥様", "Find your footing in the world he never brings anyone into", "誰も入れたことのない彼の世界で足場を見つける", "The Fu estate", "傅家の屋敷"),
       ("The Family's Price", "一族の代償", "Between the family's rules and him, take the heaviest blow for him", "一族の掟と彼のあいだで、いちばん重い一撃を彼の代わりに受ける", "The great hall", "屋敷の大広間"),
       ("The House He'd Let Warm", "温もりを許した家", "Get this man who never says 'I need' to say what he truly wants", "「必要だ」と言わない彼に、本当の望みを言わせる", "The terrace at dawn", "夜明けのテラス")],
   ks=[("His untouched glass of wine", "口をつけていないワイン"), ("The partner he walked away from", "彼が背を向けた取引相手"), ("The butler's quiet advice", "執事の静かな助言"),
       ("The arranged-marriage file", "縁談の書類"), ("How you take your coffee", "あなたのコーヒーの好み")],
   gift=("A tin of the tea his mother liked", "彼の母が好んだお茶の缶"),
   hold=["彼は何も言わない。今度の沈黙は壁ではなく招待で、あなたにはもうその違いが分かる。", "「続けろ」と彼は言う。彼にとって「お願い」に最も近い言葉だ。",
         "彼は音を立てずにグラスを置き、待つ。", "「聞いている」と彼は言う。そして本当に聞いている — 完全に。彼にしては珍しく。"]),
}
RIVALS = {
 "hale": dict(route="ethan", name=("Victor Hale, the board's man", "取締役会の男、ヴィクター・ヘイル"),
   pre=("The man with the document is still at your elbow, silver-haired and smiling like a closed door. \"You should know what he is before the cameras decide for you.\"", "書類を持った銀髪の男が、まだあなたの肘のそばにいる。閉じた扉のような笑み。「カメラが決める前に、彼が何者か知っておくべきだ」"),
   post=("Hale folds the document back into his jacket. \"He'll disappoint you,\" he says, without conviction now, and goes to find someone easier.", "ヘイルは書類を上着に戻す。「彼はきっと君を失望させる」もう確信のない声でそう言い、もっと扱いやすい相手を探しに行く。"),
   barks=["「数字は嘘をつかない。人はつく」", "彼は書類を指で軽く叩く。", "「君は彼にとって何なんだ？ 考えたことは？」", "「取締役会は感傷で動かない」"],
   barks_en=["\"Numbers don't lie. People do.\"", "He taps the document with one finger.", "\"What do you think you are to him? Have you asked?\"", "\"The board doesn't run on sentiment.\""]),
 "han": dict(route="luxingye", name=("Ms Han, his manager", "マネージャーのハン"),
   pre=("His manager steps out of the glass room and shuts the door behind her. Headset, tablet, ten years of keeping him on schedule. \"Whatever you are, you're a problem I have to solve tonight.\"", "マネージャーがガラスの部屋から出て、後ろ手に扉を閉める。ヘッドセット、タブレット、十年間彼のスケジュールを守ってきた女。「あなたが何者でも、今夜片づけなきゃいけない問題よ」"),
   post=("Han looks at the tablet, then at you, then turns the screen off. \"Go in,\" she says. \"He's been asking for you for an hour. I didn't tell him.\"", "ハンはタブレットを見て、あなたを見て、画面を消す。「入って。一時間前からあなたを呼んでる。私は伝えなかったけど」"),
   barks=["「契約書はファンより長生きするの」", "彼女はタブレットをスワイプする。止めずに。", "「あの子を守ってきたのは私よ」", "「感情はスケジュールに入ってない」"],
   barks_en=["\"Contracts outlive fans.\"", "She swipes the tablet without stopping.", "\"I'm the one who's kept him safe.\"", "\"Feelings are not on the schedule.\""]),
 "pratt": dict(route="guyan", name=("Mr Pratt, the developer's agent", "開発業者の代理人プラット"),
   pre=("A man in a navy suit is waiting by the door with a folder and a very reasonable smile. \"You must be the friend. Perhaps you can help him see sense.\"", "紺のスーツの男が、フォルダーととても感じのいい笑顔で扉のそばに待っている。「お友達ですね。彼に分別を持たせてあげてください」"),
   post=("Pratt closes the folder. \"The offer stands until Friday,\" he says, and it sounds like an apology. The chime rings him out.", "プラットはフォルダーを閉じる。「申し出は金曜まで有効です」謝罪のように聞こえる。ドアベルが彼を送り出す。"),
   barks=["「とても寛大な条件ですよ」", "彼はフォルダーを開いて、閉じる。", "「感傷で家賃は払えません」", "「この通りはもう変わるんです」"],
   barks_en=["\"It really is a generous offer.\"", "He opens the folder, and closes it.", "\"Sentiment doesn't pay rent.\"", "\"This street is changing either way.\""]),
 "morrow": dict(route="liam", name=("Chief Morrow, central command", "本部のモロー署長"),
   pre=("A man in dress uniform is standing by the engine with his cap under his arm. \"So you're the reason he hasn't signed. Let's talk about what he's turning down.\"", "礼装の男が帽子を脇に抱えて消防車のそばに立っている。「君が、彼が署名しない理由か。彼が何を断ろうとしているのか話そう」"),
   post=("Morrow puts his cap back on. \"Fine. If he wants the unit closer to home, he can write me the proposal himself.\" He almost smiles. \"Tell him I said so.\"", "モローは帽子をかぶり直す。「いいだろう。部隊を家の近くに置きたいなら、提案書を本人が書いてくればいい」ほとんど笑っている。「私がそう言ったと伝えてくれ」"),
   barks=["「十年に一度の機会だぞ」", "彼は辞令の封筒を指で叩く。", "「彼のような男は、そういう所でこそ役に立つ」", "「君は彼に、それを諦めろと言うのか？」"],
   barks_en=["\"This comes once in ten years.\"", "He taps the envelope.", "\"Men like him are wasted anywhere smaller.\"", "\"Would you ask him to give that up?\""]),
 "sterling": dict(route="adrian", name=("Sterling, from the label", "レーベルのスターリング"),
   pre=("The executive at the head of the glass table slides the contract an inch toward you instead. \"You're the 'she' in the song. Then you can tell him what's good for the song.\"", "ガラスのテーブルの上座の重役が、契約書をあなたのほうへ少し滑らせる。「君が歌の中の『彼女』か。なら、何が歌のためになるか彼に言えるだろう」"),
   post=("Sterling caps his pen. \"Keep your line, then,\" he says. \"Nobody will hear it.\" He doesn't look like he believes that either.", "スターリングはペンにキャップをする。「その一行は取っておけばいい。誰も聞かないさ」彼自身もそうは思っていない顔だ。"),
   barks=["「ヒットには理由がある。修正だ」", "彼はペンを回す。", "「感傷は売れない。コラボは売れる」", "「君の一行で、何百万を捨てるのか？」"],
   barks_en=["\"Hits have reasons. Revisions.\"", "He turns the pen in his fingers.", "\"Sentiment doesn't sell. Collabs sell.\"", "\"Millions, against one line about you?\""]),
 "fu_elder": dict(route="fushen", name=("The Fu patriarch", "傅家の当主"),
   pre=("At the head of the long table the patriarch sets down his chopsticks. The room goes quiet with him. \"Someone he brought in from outside,\" he says, to nobody, about you.", "長いテーブルの上座で、当主が箸を置く。部屋が彼と一緒に静まる。「外から連れてきた者か」誰にともなく、あなたについてそう言う。"),
   post=("The old man looks at you for a long moment, then at his grandson's hand on the table beside yours. He picks his chopsticks back up. Nobody mentions the other family again.", "老人は長いあいだあなたを見つめ、それから、あなたの手の隣にある孫の手を見る。彼は再び箸を取る。もう誰も、あの家の話をしない。"),
   barks=["「この家には百年の決まりがある」", "彼は杖の柄に両手を重ねる。", "「縁談は家と家のものだ」", "「お前に何が背負える」"],
   barks_en=["\"This house has a hundred years of rules.\"", "He folds both hands over the head of his cane.", "\"A match is between families.\"", "\"What could you carry?\""]),
}
DATE_NAME = [("{n} — first meeting", "{j} — 初めての夜"), ("{n} — the second evening", "{j} — 二度目の夜"),
             ("{n} — off guard", "{j} — 不意の素顔"), ("{n} — under pressure", "{j} — 試される夜"), ("{n} — the last wall", "{j} — 最後の壁")]
DATE_INTRO = [("He doesn't know you yet. Every answer he gives is the polite one. Bring his guard down before he decides you were never here.",
               "彼はまだあなたを知らない。どの答えも礼儀正しいだけ。あなたがいなかったことにされる前に、心の壁をほどいて。"),
              ("He remembers you, and that worries him more than it should. Get past the careful version of him.",
               "彼はあなたを覚えている。それが思った以上に彼を落ち着かなくさせている。用心深い彼の向こうへ。"),
              ("Caught somewhere he didn't plan to be seen, he is half a step from making a joke of it and leaving. Don't let him.",
               "見られるつもりのない場所で見つかって、彼は冗談にして立ち去る半歩手前。そうさせないで。"),
              ("Everything is pressing on him at once, and the easiest thing would be to shut everyone out — you included.",
               "すべてが一度に彼にのしかかり、いちばん楽なのは全員を締め出すこと — あなたも含めて。"),
              ("This is the last of the walls. Behind it is the thing he wants and has never once said out loud.",
               "これが最後の壁。その向こうに、彼が一度も口にしたことのない望みがある。")]
DATE_WIN = [("He laughs, once, surprised at himself. Something in his shoulders lets go.", "彼は一度だけ笑い、自分に驚く。肩の力がふっと抜ける。"),
            ("He stops performing the conversation and simply has it with you.", "彼は会話を演じるのをやめ、ただあなたと話し始める。"),
            ("He gives up on leaving. He pulls out the chair beside you instead.", "彼は立ち去るのをやめる。代わりに、あなたの隣の椅子を引く。"),
            ("He looks at you like the room has finally stopped shouting.", "部屋がようやく叫ぶのをやめたかのように、彼はあなたを見る。"),
            ("The last wall comes down without a sound. He is just a man, here, with you.", "最後の壁が音もなく崩れる。ここにいるのは、あなたと一緒の、ただのひとりの男。")]

S = {}
for r, d in R.items():
    S[f"n_{r}"] = d["name"]
    S[f"pick_{r}"] = d["pick"]
    for c, (te, tj, ge, gj, ve, vj) in enumerate(d["ch"], 1):
        S[f"nt_{r}_{c}"] = (f"{d['name'][0]} · {c}. {te}", f"{d['name'][1]} · 第{c}章 {tj}")
        S[f"ns_{r}_{c}"] = (ge, gj)
        S[f"r_v_{r}_{c}"] = (ve, vj)
        en, ja = DATE_NAME[c - 1]
        S[f"e_date_{r}_{c}"] = (en.format(n=d["name"][0]), ja.format(j=d["name"][1]))
        S[f"ei_date_{r}_{c}"] = DATE_INTRO[c - 1]
        S[f"ew_date_{r}_{c}"] = DATE_WIN[c - 1]
        S[f"i_ks_{r}_{c}"] = d["ks"][c - 1]
        S[f"id_ks_{r}_{c}"] = ("A keepsake: bring it up with Remember.", "思い出の品：「思い出す」で話題にできる。")
    S[f"i_gift_{r}"] = d["gift"]
    S[f"id_gift_{r}"] = ("Give it to him from the Items menu: Trust +1.", "「アイテム」から彼に贈る：信頼 +1。")
    for g in ("doorman", "paparazzo", "columnist"):
        S[f"e_{g}_{r}"] = {"doorman": ("The doorman", "ドアマン"), "paparazzo": ("A paparazzo", "パパラッチ"), "columnist": ("The gossip columnist", "ゴシップ記者")}[g]
        S[f"ei_{g}_{r}"] = {"doorman": ("Between you and the door: a man who reads a list for a living.", "あなたと扉のあいだに、リストを読むのが仕事の男。"),
                            "paparazzo": ("He wants a name and a face. You can give him neither and still walk past.", "彼は名前と顔が欲しい。どちらも渡さずに通り過ぎることはできる。"),
                            "columnist": ("She is charming, curious and recording. Get her to stop without giving her a story.", "彼女は魅力的で、好奇心旺盛で、録音中。記事を渡さずに止めさせて。")}[g]
        S[f"ew_{g}_{r}"] = {"doorman": ("He steps aside.", "彼は道を空ける。"), "paparazzo": ("He lowers the camera.", "彼はカメラを下ろす。"),
                            "columnist": ("She stops recording.", "彼女は録音を止める。")}[g]
for rv, d in RIVALS.items():
    r = d["route"]
    S[f"e_rival_{r}"] = d["name"]
    S[f"ei_rival_{r}"] = d["pre"]
    S[f"ew_rival_{r}"] = d["post"]
    S[f"pre_{rv}"] = d["pre"]
    S[f"post_{rv}"] = d["post"]
    for i, (en, ja) in enumerate(zip(d["barks_en"], d["barks"]), 1):
        S[f"bark_{rv}_{i}"] = (en, ja)
for r, d in R.items():
    n, j = d["name"]
    S[f"g_cg_{r}_ch2"] = (f"{n} — {d['ch'][1][0]}", f"{j} — {d['ch'][1][1]}")
    S[f"g_cg_{r}_heat"] = (f"{n} — after hours", f"{j} — 夜更けに")
    S[f"g_cg_{r}_end"] = (f"{n} — the ending", f"{j} — エンディング")
