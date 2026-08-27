extends StaticBody3D

@export var prompt := "听门缝"
@export var kind := "401"

func interact(game: Node) -> void:
	if kind == "401":
		if int(game.get("phase")) < 2:
			game.show_note("反锁着。钥匙孔里没有光。\n你摸口袋：没有钥匙，也没有口袋的缝。")
		else:
			game.show_note("里面有人用你的节奏在刷牙。\n二十下，停一下，再二十下。\n你数过自己，一模一样。")
		game.knock_behind_401()
	else:
		game.show_note("门开着。开着就不算闯空门。")
