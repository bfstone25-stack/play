# Mirei's voiced lines: the 21 Overtime barks (ops/barks/lines.json "overtime-idle", rendered by
# ops/barks/render_barks.py, shipped in the committed play/overtime-idle-godot/assets/voice/),
# each one placed where the RPG has her say exactly those words. EN voice; the JA text is the
# subtitle.
S = {
"v_greet_0": ("Evening. The office missed you.", "こんばんは。オフィスはあなたが恋しかったみたい。"),
"v_greet_1": ("Back again? Lights are still on.", "また来たの？ 灯りはまだついてるわ。"),
"v_stage_0": ("One desk, one dream.", "机ひとつ、夢ひとつ。"),
"v_stage_1": ("A whole floor now.", "もうワンフロアまるごとね。"),
"v_stage_2": ("Two floors. People are noticing.", "二フロア。気づく人が出てきた。"),
"v_stage_3": ("The building's yours.", "ビルはあなたのものよ。"),
"v_near_0": ("Almost there. One more.", "あと少し。もうひとつ。"),
"v_near_1": ("Nearly. Hold on.", "もうすぐ。踏ん張って。"),
"v_win_0": ("Signed and filed.", "署名して、綴じたわ。"),
"v_win_1": ("Good work.", "いい仕事ね。"),
"v_win_2": ("That's a win.", "これは勝ちね。"),
"v_win_big_0": ("Best quarter yet!", "過去最高の四半期！"),
"v_win_big_1": ("That is a record. Really.", "記録よ。本当に。"),
"v_fail_0": ("We'll get it next time.", "次は取れるわ。"),
"v_fail_1": ("Not this round.", "今回は駄目ね。"),
"v_idle_0": ("Still awake?", "まだ起きてるの？"),
"v_idle_1": ("Overtime waits for nobody.", "残業は誰も待ってくれない。"),
"v_streak_0": ("Three straight!", "三連続！"),
"v_streak_1": ("Somebody's on a roll.", "誰かさん、絶好調ね。"),
"v_unlock_0": ("New floor. Go see.", "新しいフロアよ。見てきて。"),
"v_unlock_1": ("Something opened up upstairs.", "上の階で何かが空いたわ。"),
}
CLIP = {k: k[2:] + ".ogg" for k in S}
