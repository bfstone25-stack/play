extends Node2D
class_name OfficeBuilder

const W := 640
const H := 360
var area_id := "cubicle"
var phase := 0.0
var animated: Array[ColorRect] = []

func build(id: String) -> void:
	area_id = id
	for child in get_children():
		child.queue_free()
	animated.clear()
	_background()
	match id:
		"cubicle": _cubicle()
		"office": _office()
		"breakroom": _breakroom()
		"server": _server()
		"lobby": _lobby()
		"stairs": _stairs()
		"manager": _manager()
	_label(18, 328, "MERIDIAN LEDGER // NIGHT OPERATIONS", 10, Color("#65718f"))

func _process(delta: float) -> void:
	phase += delta
	for i in animated.size():
		if is_instance_valid(animated[i]):
			var alpha := 0.35 + 0.35 * sin(phase * (2.0 + i * 0.17))
			animated[i].modulate.a = alpha
	if area_id == "server" and animated.size() > 0 and is_instance_valid(animated[0]):
		animated[0].position.x = fmod(phase * 82.0, 680.0) - 20.0

func _rect(x: float, y: float, w: float, h: float, color: Color, z := 0) -> ColorRect:
	var node := ColorRect.new()
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = z
	add_child(node)
	return node

func _label(x: float, y: float, text: String, size := 12, color := Color.WHITE, width := 400.0) -> Label:
	var node := Label.new()
	node.position = Vector2(x, y)
	node.size = Vector2(width, 26)
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	UiFont.apply_label(node)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = 5
	add_child(node)
	return node

func _background() -> void:
	_rect(0, 0, W, H, Color("#070b16"), -20)
	for y in range(0, H, 8):
		_rect(0, y, W, 1, Color(0.15, 0.20, 0.31, 0.10), -19)

func _tiles(y0: int, c1: Color, c2: Color) -> void:
	for y in range(y0, H, 16):
		for x in range(0, W, 24):
			_rect(x, y, 24, 16, c1 if ((x / 24 + y / 16) as int) % 2 == 0 else c2, -8)

func _light(x: int, y: int, w: int, color: Color) -> void:
	_rect(x, y, w, 5, color, 1)
	var glow := _rect(x - 6, y + 5, w + 12, 26, Color(color, 0.10), 0)
	animated.append(glow)

func _person(x: int, y: int, coat: Color, face := Color("#b8a38d"), red_eye := false) -> void:
	_rect(x + 8, y, 18, 18, face, 2)
	_rect(x + 4, y + 18, 28, 44, coat, 1)
	_rect(x, y + 25, 6, 32, coat.darkened(0.2), 0)
	_rect(x + 32, y + 25, 6, 32, coat.darkened(0.2), 0)
	_rect(x + 8, y + 62, 8, 23, Color("#101526"), 0)
	_rect(x + 22, y + 62, 8, 23, Color("#101526"), 0)
	if red_eye:
		_rect(x + 11, y + 7, 4, 3, Color("#ff3535"), 4)
		_rect(x + 20, y + 7, 4, 3, Color("#ff3535"), 4)

func _cubicle() -> void:
	_rect(0, 0, W, 218, Color("#10182a"), -12)
	_tiles(218, Color("#141726"), Color("#10131f"))
	_light(48, 24, 226, Color("#e1d5a6"))
	_rect(36, 84, 300, 12, Color("#384054"), -2)
	_rect(36, 84, 12, 164, Color("#303748"), -2)
	_rect(324, 84, 12, 164, Color("#303748"), -2)
	for i in 9:
		_rect(55 + i * 29, 102, 20, 5, Color("#5d4b53"), -1)
	_rect(78, 192, 258, 20, Color("#513828"), 1)
	_rect(96, 212, 14, 76, Color("#2b201c"))
	_rect(298, 212, 14, 76, Color("#2b201c"))
	# CRT / ticket
	_rect(162, 122, 106, 72, Color("#252838"), 2)
	_rect(171, 131, 88, 52, Color("#061a17"), 3)
	for i in 5:
		_rect(180, 141 + i * 7, 62 - i * 5, 3, Color("#4ce69d"), 4)
	_rect(201, 194, 28, 8, Color("#202331"), 2)
	# phone, cup, drawer
	_rect(430, 146, 94, 34, Color("#202536"), 2)
	_rect(445, 136, 62, 15, Color("#30394c"), 3)
	_rect(56, 210, 36, 45, Color("#b7a267"), 2)
	_rect(405, 216, 116, 63, Color("#33251f"), 1)
	_rect(447, 235, 34, 7, Color("#a48d64"), 2)
	# rain window
	_rect(420, 45, 170, 75, Color("#050b1c"), -1)
	for i in 14:
		_rect(428 + (i * 31) % 150, 51 + (i * 17) % 57, 3, 15, Color("#3e6ab0"), 0)
	_label(169, 150, "013  MARA VALE", 9, Color("#70ffbb"), 92)

func _office() -> void:
	_rect(0, 0, W, 205, Color("#0c1220"), -12)
	_tiles(205, Color("#111829"), Color("#0d1422"))
	_light(28, 18, 170, Color("#8db4cc"))
	_light(372, 18, 190, Color("#8db4cc"))
	for row in 2:
		for col in 5:
			var x := 22 + col * 118 + row * 22
			var y := 88 + row * 92
			_rect(x, y, 94, 9, Color("#343949"), 0)
			_rect(x + 29, y - 42, 48, 37, Color("#171d2c"), 1)
			_rect(x + 34, y - 37, 38, 25, Color("#173348"), 2)
			_rect(x + 49, y + 10, 28, 34, Color("#202637"), 0)
	# printer
	_rect(45, 162, 110, 103, Color("#89909a"), 2)
	_rect(60, 145, 78, 32, Color("#c3c7c8"), 3)
	_rect(64, 137, 70, 14, Color("#d8d7c8"), 1)
	# directory/camera
	_rect(473, 58, 122, 147, Color("#42382e"), 2)
	_rect(485, 70, 98, 119, Color("#0d121b"), 3)
	for i in 7:
		_label(496, 76 + i * 15, ("13  NIGHT" if i == 3 else str(8 + i)), 8, Color("#e0bd6d"), 70)
	_rect(352, 226, 210, 64, Color("#181e2d"), 2)
	_rect(362, 236, 190, 44, Color("#081728"), 3)
	# auditor
	_rect(296, 69, 35, 151, Color("#06080e"), 3)
	var scan := _rect(0, 174, 640, 3, Color("#ef3040"), 6)
	animated.append(scan)

func _breakroom() -> void:
	_rect(0, 0, W, 220, Color("#18221f"), -12)
	_tiles(220, Color("#1d2524"), Color("#18201f"))
	_light(205, 18, 228, Color("#b6c68b"))
	# rota
	_rect(47, 61, 151, 140, Color("#d0c9a8"), 1)
	for i in 6:
		_rect(58, 78 + i * 18, 128, 2, Color("#636250"), 2)
	for i in 3:
		_rect(89 + i * 40, 67, 2, 124, Color("#636250"), 2)
	_label(57, 47, "WEEKLY ROTATION", 10, Color("#cad8b7"))
	# fridge
	_rect(232, 54, 142, 192, Color("#9ca9a4"), 1)
	_rect(244, 66, 118, 72, Color("#303a3a"), 2)
	_rect(244, 146, 118, 86, Color("#333c3b"), 2)
	for i in 8:
		_rect(251 + (i % 4) * 27, 76 + (i / 4) * 45, 19, 30, Color("#927650"), 3)
	# vending + phone
	_rect(423, 48, 122, 202, Color("#26263b"), 1)
	_rect(437, 63, 94, 110, Color("#211445"), 2)
	for i in 12:
		_rect(444 + (i % 4) * 21, 72 + (i / 4) * 30, 13, 18, Color("#9456c2"), 3)
	_rect(287, 264, 143, 46, Color("#20292a"), 1)
	_rect(309, 272, 56, 28, Color("#10151a"), 2)
	_person(458, 163, Color("#323c53"), Color("#9f978c"))
	_rect(474, 196, 24, 13, Color("#ebe9dd"), 4)

func _server() -> void:
	_rect(0, 0, W, H, Color("#030817"), -12)
	for i in 7:
		var x := 20 + i * 88
		_rect(x, 35, 70, 253, Color("#0b152a"), -1)
		_rect(x + 7, 44, 56, 231, Color("#101f37"), 0)
		for j in 11:
			_rect(x + 13, 52 + j * 19, 42, 9, Color("#08111f"), 1)
			var led := _rect(x + 17, 55 + j * 19, 4, 3, Color("#35a8dc" if (i + j) % 3 else "#5ef2c4"), 2)
			animated.append(led)
	# terminal and vent
	_rect(228, 105, 178, 105, Color("#252a37"), 3)
	_rect(242, 117, 150, 72, Color("#071b2a"), 4)
	for i in 7:
		_rect(252, 128 + i * 7, 112 - i * 5, 3, Color("#54d9de"), 5)
	_rect(460, 234, 136, 61, Color("#121a2b"), 3)
	for i in 7:
		_rect(471, 244 + i * 6, 114, 2, Color("#3c5368"), 4)
	var scanner := _rect(-20, 304, 24, 4, Color("#ff2c42"), 8)
	animated.insert(0, scanner)
	_label(250, 143, "MARA // BEFORE", 9, Color("#75efff"), 130)

func _lobby() -> void:
	_rect(0, 0, W, 221, Color("#1a1820"), -12)
	_tiles(221, Color("#24212a"), Color("#1e1b24"))
	_light(190, 18, 260, Color("#b4b4a8"))
	# fire map
	_rect(42, 64, 143, 149, Color("#bcb59e"), 1)
	_rect(53, 76, 121, 124, Color("#262c32"), 2)
	for i in 5:
		_rect(65 + i * 20, 91 + (i % 2) * 27, 9, 79, Color("#576372"), 3)
	_rect(115, 82, 4, 107, Color("#3985b7"), 4)
	# elevator
	_rect(406, 49, 176, 222, Color("#87714f"), 1)
	_rect(419, 63, 71, 194, Color("#23232c"), 2)
	_rect(498, 63, 71, 194, Color("#23232c"), 2)
	_rect(490, 63, 8, 194, Color("#bd9c64"), 3)
	_rect(469, 28, 49, 24, Color("#090c13"), 2)
	_label(486, 30, "13", 16, Color("#ef3546"), 32)
	# directory, phone
	_rect(225, 53, 112, 115, Color("#41382b"), 2)
	_rect(237, 65, 88, 90, Color("#090d13"), 3)
	for i in 6:
		_label(249, 69 + i * 13, str(14 - i), 8, Color("#e2be72"), 64)
	_rect(242, 202, 89, 69, Color("#27303d"), 2)
	_rect(260, 211, 53, 23, Color("#111720"), 3)
	_rect(256, 240, 60, 14, Color("#3d4a58"), 3)
	var blue := _rect(398, 61, 8, 196, Color("#3d89ff"), 4)
	animated.append(blue)

func _stairs() -> void:
	_rect(0, 0, W, H, Color("#111824"), -12)
	for i in 6:
		_rect(i * 112, 0, 4, H, Color("#26313b"), -4)
	# stair flights
	for i in 9:
		_rect(260 + i * 34, 269 - i * 20, 51, 16, Color("#343b43"), 0)
		_rect(260 + i * 34, 285 - i * 20, 51, 5, Color("#151b22"), 1)
	for i in 7:
		_rect(28 + i * 35, 74, 27, 126, Color("#171b24"), 1)
		_rect(33 + i * 35, 58, 17, 18, Color("#b9aa98"), 2)
		_rect(31 + i * 35, 104, 20, 7, Color("#475064"), 2)
	# alarm, gate
	_rect(283, 53, 72, 69, Color("#3c4551"), 2)
	var alarm := _rect(302, 67, 33, 31, Color("#e32a3c"), 3)
	animated.append(alarm)
	_rect(469, 38, 128, 139, Color("#10151c"), 1)
	for i in 6:
		_rect(478 + i * 19, 46, 4, 123, Color("#78828b"), 2)
	_light(390, 18, 109, Color("#458fff"))
	_label(382, 26, "EXIT 13", 11, Color("#83bdff"), 100)
	_label(44, 210, "MARA · ELI · ANIKA · TOM · LEANNE · HALIMA", 9, Color("#617da5"), 310)

func _manager() -> void:
	_rect(0, 0, W, 207, Color("#807454"), -12)
	_tiles(207, Color("#342b25"), Color("#2e2622"))
	# fake windows
	for i in 3:
		_rect(25 + i * 118, 36, 101, 103, Color("#d9c47d"), -1)
		_rect(33 + i * 118, 44, 85, 87, Color("#9ab7ad"), 0)
		_rect(74 + i * 118, 44, 4, 87, Color("#7b8d85"), 1)
		_rect(33 + i * 118, 84, 85, 4, Color("#7b8d85"), 1)
	# desk and contract
	_rect(121, 181, 379, 70, Color("#583b2a"), 2)
	_rect(145, 169, 331, 19, Color("#72503a"), 3)
	_rect(241, 189, 136, 51, Color("#d1c7a8"), 4)
	for i in 5:
		_rect(254, 199 + i * 7, 108 - i * 8, 2, Color("#706956"), 5)
	# outbox / photos
	_rect(50, 201, 115, 66, Color("#433329"), 3)
	for i in 4:
		_rect(60 + i * 20, 185 - i * 3, 76, 6, Color("#b8ad91"), 2)
	for i in 4:
		_rect(404 + i * 42, 76, 34, 49, Color("#564538"), 2)
		_rect(409 + i * 42, 82, 24, 31, Color("#b19c80"), 3)
	# auditor silhouette
	_rect(505, 126, 51, 142, Color("#07080c"), 6)
	_rect(494, 153, 73, 17, Color("#0a0b10"), 5)
	var eye := _rect(496, 161, 69, 4, Color("#ff293c"), 8)
	animated.append(eye)
	# rainy truth edge
	_rect(0, 0, 8, 320, Color("#3673bd"), 7)
	_label(246, 201, "NIGHT OPERATIONS", 8, Color("#712e2e"), 120)
