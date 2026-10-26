extends Control
signal selected(index: int)
var game
var inspected = -1
var boxes: Array[Rect2] = []
const COLORS = [Color("71baa0"), Color("e28271"), Color("72aee0"), Color("e1d4a6")]
const GROUP_COLORS = ["b8a568", "bca168", "649fb1", "b6756e", "598caa", "ac7b9b", "8e8cb3", "ad975e", "8ca8b3", "c4aa65", "689da2", "9282a1"]
var font = ThemeDB.fallback_font
var title_font = SystemFont.new()
var event: Dictionary = {}
var animation_left = 0.0
var animation_position = Vector2(995, 170)
var animation_duration = 1.0

var board_art = preload("res://art/gothic-background.png")

func animate(data: Dictionary, duration: float) -> void:
	event = data.duplicate(true)
	animation_left = duration
	animation_duration = duration
	queue_redraw()

func _ready() -> void:
	title_font.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	custom_minimum_size = Vector2(870, 740)
	mouse_filter = Control.MOUSE_FILTER_STOP

func rectangle(i: int) -> Rect2:
	return boxes[i]

func layout_board() -> void:
	boxes.clear()
	boxes.append(Rect2(16, 16, 100, 90))
	for i in range(8): boxes.append(Rect2(120 + i * 77, 16, 73, 90))
	boxes.append(Rect2(740, 16, 110, 90))
	for i in range(7): boxes.append(Rect2(740, 110 + i * 75, 110, 71))
	boxes.append(Rect2(740, 639, 110, 90))
	for i in range(8): boxes.append(Rect2(120 + (7 - i) * 77, 639, 73, 90))
	boxes.append(Rect2(16, 639, 100, 90))
	for i in range(7): boxes.append(Rect2(16, 110 + (6 - i) * 75, 100, 71))

func text_at(pos: Vector2, value: String, font_size: int, color: Color, width: float = -1) -> void:
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _draw() -> void:
	if game == null or game.s.is_empty(): return
	layout_board()
	#draw_style_box(panel(Color("101e23"), Color("3b4948"), 1), Rect2(0, 0, 867, 744))
	#adding in the board png
	draw_texture_rect(
		board_art,
		Rect2(0, 0, 870, 744),
		false
	)
	for i in range(game.s.tiles.size()):
		var t = game.s.tiles[i]
		var r = boxes[i]
		var owner: int = t.owner
		
		#var fill = Color("1d2b30") if t.division >= 0 else Color("28302c")
		#if owner >= 0: fill = COLORS[owner].darkened(0.76)
		
		var fill = Color(0.035, 0.042, 0.040, 0.93)
		
		if owner >= 0:
			fill = COLORS[owner].darkened(0.82)
		
		var border = Color("48585a") if owner < 0 else COLORS[owner].darkened(0.25)
		if i == game.player().pos: border = Color("ffe6a3")
		if i == inspected: border = Color.WHITE
		draw_style_box(panel(fill, border, 2 if i == game.player().pos or i == inspected else 1), r)
		if t.division >= 0:
			draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(GROUP_COLORS[t.division]))
			var words: Array = t.name.split(" ")
			var line = ""
			var y = r.position.y + 21
			for word in words:
				if (line + word).length() > 10:
					text_at(Vector2(r.position.x + 5, y), line, 12, Color("e1e1ce"))
					y += 14
					line = ""
				line += word + " "
			text_at(Vector2(r.position.x + 5, y), line, 12, Color("e1e1ce"))
			var tag = "%d G" % (game.size_of(t.division) * 10) if owner < 0 else "%d T" % t.troops
			if t.building != "": tag += " | " + ("M" if t.building == "market" else "B")
			text_at(r.position + Vector2(5, r.size.y - 21), tag, 12, Color("b6c6bf"))
			if owner >= 0 and game.full_division(t.division, owner):
				text_at(r.position + Vector2(r.size.x - 15, 18), "*", 18, Color("ffdc86"))
		elif t.division == -1:
			text_at(r.position + Vector2(7, 24), t.name.split(" / ")[0], 14, Color("dfc48a"))
			text_at(r.position + Vector2(7, 46), t.name.split(" / ")[1], 15, Color("f0dfba"))
		for p in range(4):
			if game.s.players[p].alive and game.s.players[p].pos == i:
				var pt = r.position + Vector2(10 + p * 14, r.size.y - 8)
				draw_circle(pt, 5, COLORS[p])
	draw_string(title_font, Vector2(309, 194), "Mitt Fued", HORIZONTAL_ALIGNMENT_CENTER, 253, 29, Color("382819"))
	if not event.is_empty():
		draw_set_transform(animation_position - Vector2(285, 285))
		draw_event()
		draw_set_transform(Vector2.ZERO)

func draw_cathedral() -> void:
	var stone = Color("485249")
	var trim = Color("ad9562")
	for x in [338, 490]:
		draw_rect(Rect2(x, 340, 40, 103), stone)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 340), Vector2(x + 20, 296), Vector2(x + 46, 340)]), Color("6a3038"))
		draw_line(Vector2(x + 20, 296), Vector2(x + 20, 281), trim, 2)
		draw_line(Vector2(x + 14, 288), Vector2(x + 26, 288), trim, 2)
		for y in [355, 391]:
			draw_colored_polygon(PackedVector2Array([Vector2(x + 12, y + 26), Vector2(x + 12, y + 7), Vector2(x + 20, y), Vector2(x + 28, y + 7), Vector2(x + 28, y + 26)]), Color("bea26c"))
	draw_rect(Rect2(378, 357, 112, 86), stone)
	draw_colored_polygon(PackedVector2Array([Vector2(375, 357), Vector2(434, 314), Vector2(493, 357)]), Color("63313a"))
	draw_circle(Vector2(434, 359), 16, trim)
	draw_circle(Vector2(434, 359), 12, Color("293c40"))
	for a in range(8): draw_line(Vector2(434, 359), Vector2(434, 359) + Vector2.from_angle(a * PI / 4) * 13, trim, 1)
	draw_colored_polygon(PackedVector2Array([Vector2(417, 443), Vector2(417, 407), Vector2(434, 390), Vector2(451, 407), Vector2(451, 443)]), Color("142021"))
	for y in [379, 400, 422]: draw_line(Vector2(380, y), Vector2(413, y), Color("64705e"), 1)
	# Pointed-arch frame and heraldic flourishes.
	draw_polyline(PackedVector2Array([Vector2(317, 448), Vector2(317, 341), Vector2(350, 298), Vector2(434, 280), Vector2(518, 298), Vector2(551, 341), Vector2(551, 448)]), Color("6c6249"), 1.5, true)

func draw_die(center: Vector2, value: int, color: Color, scale_value: float = 1.0) -> void:
	var edge = 42.0 * scale_value
	draw_style_box(panel(color.darkened(0.65), color, 2), Rect2(center - Vector2.ONE * edge / 2, Vector2.ONE * edge))
	var positions: Array = []
	if value % 2 == 1: positions.append(Vector2.ZERO)
	if value >= 2: positions.append_array([Vector2(-10, -10), Vector2(10, 10)])
	if value >= 4: positions.append_array([Vector2(10, -10), Vector2(-10, 10)])
	if value == 6: positions.append_array([Vector2(-10, 0), Vector2(10, 0)])
	for point in positions: draw_circle(center + point * scale_value, 3 * scale_value, color.lightened(0.35))

func draw_event() -> void:
	var c: Color = COLORS[event.actor]
	var progress = 1.0 - animation_left / animation_duration
	var moving = animation_left > 0
	#draw_style_box(panel(Color("151c1d"), Color("a68a51"), 2), Rect2(285, 285, 285, 242))
	draw_string(title_font, Vector2(298, 310), game.s.players[event.actor].name, HORIZONTAL_ALIGNMENT_CENTER, 260, 22, c)
	var wave = sin(progress * TAU * 2) * (1 - progress) if moving else 0.0
	if event.kind == "dice":
		for j in range(2):
			var value: int = event.dice[j] if event.dice.size() == 2 else 1
			if progress < 0.65 and moving: value = 1 + (int(progress * 25) + j * 3) % 6
			draw_die(Vector2(391 + j * 72, 370 + wave * 12), value, c)
	elif event.kind == "fight":
		var other: Color = COLORS[event.other] if event.other >= 0 else Color.WHITE
		if event.other >= 0: draw_string(font, Vector2(298, 332), "vs " + game.s.players[event.other].name, HORIZONTAL_ALIGNMENT_CENTER, 260, 13, other)
		var offset = absf(wave) * 22
		for side in range(2):
			var x = 356 + offset if side == 0 else 500 - offset
			var col = c if side == 0 else other
			draw_circle(Vector2(x, 349), 8, col)
			draw_line(Vector2(x, 357), Vector2(x, 382), col, 5)
			draw_line(Vector2(x, 382), Vector2(x - 10, 397), col, 3)
			draw_line(Vector2(x, 382), Vector2(x + 10, 397), col, 3)
			var sword_end = Vector2(x + (33 if side == 0 else -33), 348 + wave * 8)
			draw_line(Vector2(x, 368), sword_end, col.lightened(0.4), 3)
			draw_circle(Vector2(x + (-8 if side == 0 else 8), 370), 10, col.darkened(0.3))
		if event.dice.size() == 2:
			for side in range(2):
				for j in range(event.dice[side].size()):
					draw_die(Vector2(332 + side * 145 + j * 32, 423), event.dice[side][j], c if side == 0 else other, 0.6)
	else:
		var y = 356 + wave * 5
		draw_rect(Rect2(393, y, 68, 51), c.darkened(0.45))
		draw_colored_polygon(PackedVector2Array([Vector2(383, y), Vector2(427, y - 33), Vector2(471, y)]), c)
		draw_rect(Rect2(420, y + 24, 15, 27), Color("151c1d"))
		for x in [401, 444]: draw_rect(Rect2(x, y + 10, 9, 13), c.lightened(0.4))
	var caption: String = event.caption
	var lines: Array[String] = []
	for paragraph in caption.split("\n"):
		var line = ""
		for word in paragraph.split(" "):
			if (line + word).length() > 34:
				lines.append(line)
				line = ""
			line += word + " "
		if line != "": lines.append(line)
	for j in range(mini(4, lines.size())):
		text_at(Vector2(297, 459 + j * 16), lines[j], 12, Color("e6dfc8"))

func panel(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var b = StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(border_width)
	b.set_corner_radius_all(4)
	return b

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(boxes.size()):
			if boxes[i].has_point(event.position):
				inspected = i
				selected.emit(i)
				queue_redraw()
				break
