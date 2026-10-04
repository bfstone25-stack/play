# Nara's voiced lines: the 21 LIEN barks (ops/barks/lines.json "midnight-pawn-collateral",
# rendered by ops/barks/render_barks.py, every clip transcribed clean, git f158001), each one
# placed where the RPG says exactly those words. EN voice; the JA text is the subtitle.
S = {
"v_greet_0": ("Shutters down, lamp on. Who needs a reading tonight?", "シャッターを下ろして、灯りをつけて。今夜、読んでほしいのは誰？"),
"v_greet_1": ("Put it on the counter. No — in my hand.", "カウンターに置いて。いえ — 私の手に。"),
"v_stage_0": ("The counter. Everything here was held by someone.", "カウンター。ここにあるものは全部、誰かが握っていた。"),
"v_stage_1": ("The stair down. Receipts in the walls, still warm.", "下りの階段。壁の受領証が、まだ温かい。"),
"v_stage_2": ("The Ossuary Market. They trade in memories down here. I brought mine.", "骨の市場。ここでは記憶を売り買いする。私は自分のを持ってきた。"),
"v_stage_3": ("The last room. Whatever I touch here, touches back.", "最後の部屋。ここで触れるものは、触れ返してくる。"),
"v_near_0": ("Almost. I can nearly see whose hand it was.", "もう少し。誰の手だったか、ほとんど見える。"),
"v_near_1": ("Close. Don't let go yet.", "近い。まだ離さないで。"),
"v_win_0": ("There. Now I know what you were for.", "ほら。あなたが何のためにあったのか、わかった。"),
"v_win_1": ("Priced, and I'll remember the price.", "値はついた。その値段は覚えておく。"),
"v_win_2": ("Fair ticket. My hands say so.", "公正な札。私の手がそう言ってる。"),
"v_win_big_0": ("Oh. Oh, that one I felt all the way down.", "ああ。ああ、今のは奥まで届いた。"),
"v_win_big_1": ("That's a lien I'm happy to hold.", "これなら喜んで抱えておく担保だわ。"),
"v_fail_0": ("Too much. I let go too late.", "多すぎた。手を離すのが遅すぎた。"),
"v_fail_1": ("It kept something of mine. That's how they get you.", "私の何かを取っていった。そうやって捕まるのよ。"),
"v_idle_0": ("The ring's still warm. I keep checking.", "指輪がまだ温かい。何度も確かめてしまう。"),
"v_idle_1": ("Quiet shop. Loud hands.", "静かな店。騒がしい手。"),
"v_idle_2": ("I shouldn't pick it up again. I'm going to pick it up again.", "もう手に取るべきじゃない。でも、取ってしまう。"),
"v_streak_0": ("Three clean readings. I'm getting good at this. Too good.", "三回きれいに読めた。上手くなってる。上手くなりすぎ。"),
"v_streak_1": ("They keep coming back. So do I.", "あれは何度でも戻ってくる。私もね。"),
"v_unlock_0": ("A reading. Close the door, this one's private.", "読み取りよ。扉を閉めて、これは内緒。"),
"v_unlock_1": ("There it is — the last time somebody loved it.", "あった — 誰かがこれを最後に愛した時。"),
}
CLIP = {k: k[2:] + ".ogg" for k in S}
