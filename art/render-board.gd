extends SceneTree
const Board = preload("res://board.gd")
const Game = preload("res://game.gd")
var output = ""
var canvas

class Artwork:
	extends Node2D
	var boxes: Array = []
	var tiles: Array = []
	var background: Texture2D
	var labels = true
	var overlay = false
	var font = ThemeDB.fallback_font
	var serif = SystemFont.new()
	var colors = ["b8a568", "bca168", "649fb1", "b6756e", "598caa", "ac7b9b", "8e8cb3", "ad975e", "8ca8b3", "c4aa65", "689da2", "9282a1"]

	func _draw() -> void:
		serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
		draw_texture_rect(background, Rect2(0, 0, 870, 744), false)
		var ink = Color("c3a66e")
		draw_rect(Rect2(3, 3, 864, 738), ink.darkened(0.35), false, 1)
		draw_rect(Rect2(7, 7, 856, 730), ink.darkened(0.6), false, 1)
		for tr in range(4):
			var previous: Vector2 = boxes[[31, 6, 14, 23][tr]].get_center()
			for j in range(6):
				var current: Vector2 = boxes[34 + tr * 6 + j].get_center()
				draw_line(previous, current, Color("826f46"), 2, true)
				previous = current
			draw_line(previous, boxes[[2, 11, 19, 28][tr]].get_center(), Color("826f46"), 2, true)
		for i in range(boxes.size()):
			var r: Rect2 = boxes[i]
			var t: Dictionary = tiles[i]
			var group: int = t.division
			var col = Color(colors[group]) if group >= 0 else Color("c9ad72")
			# Geometry comes directly from the game's hitbox array. Borders sit inside it.
			draw_rect(r, Color(0.055, 0.045, 0.038, 0.94))
			draw_rect(Rect2(r.position + Vector2.ONE * 0.5, r.size - Vector2.ONE), ink, false, 1)
			draw_rect(r.grow(-3), ink.darkened(0.55), false, 0.7)
			draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, 3)), col.darkened(0.15))
			for corner in [r.position + Vector2(5, 10), r.position + Vector2(r.size.x - 5, 10), r.position + Vector2(5, r.size.y - 5), r.end - Vector2(5, 5)]:
				draw_circle(corner, 1.0, ink)
			if labels:
				var words: Array = t.name.split(" ") if i < 34 else ["LOT", str((i - 34) % 6 + 1)]
				if group == -1: words = [t.name.split(" / ")[0], t.name.split(" / ")[1]]
				var lines: Array[String] = []
				var line = ""
				for word in words:
					if (line + word).length() > (10 if i < 34 else 7):
						lines.append(line.strip_edges())
						line = ""
					line += word + " "
				if line != "": lines.append(line.strip_edges())
				for j in range(lines.size()):
					draw_string(font, r.position + Vector2(4, 22 + j * 13), lines[j], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 8, 11 if i < 34 else 10, Color("eadabb"))
			if overlay:
				draw_rect(r, Color.CYAN, false, 1)
				draw_string(font, r.position + Vector2(7, r.size.y - 7), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.CYAN)
		for j in range(4):
			var pos: Vector2 = [Vector2(135, 130), Vector2(566, 130), Vector2(566, 510), Vector2(135, 510)][j]
			draw_rect(Rect2(pos + Vector2(-3, -14), Vector2(170, 19)), Color(0.04, 0.035, 0.03, 0.9))
			draw_string(serif, pos, Game.TRAILS[j], HORIZONTAL_ALIGNMENT_CENTER, 165, 12, Color("e5cda0"))
		draw_string(serif, Vector2(309, 194), "Mitte Fehde", HORIZONTAL_ALIGNMENT_CENTER, 253, 29, Color("382819"))

func _initialize() -> void:
	call_deferred("render_board")

func render_board() -> void:
	output = ProjectSettings.globalize_path("res://../MitteFehde-Art/")
	root.size = Vector2i(1740, 1488)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	var board = Board.new()
	board.layout_board()
	var game = Game.new()
	game.new_game(0, 42)
	canvas = Artwork.new()
	canvas.boxes = board.boxes.duplicate()
	canvas.tiles = game.s.tiles.duplicate(true)
	canvas.scale = Vector2(2, 2)
	var img = Image.load_from_file(output + "gothic-background.png")
	if img == null:
		push_error("Missing background art")
		quit(1)
		return
	canvas.background = ImageTexture.create_from_image(img)
	root.add_child(canvas)
	for variant in ["board", "board-unlabelled", "alignment-proof"]:
		canvas.labels = variant != "board-unlabelled"
		canvas.overlay = variant == "alignment-proof"
		canvas.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var result = root.get_texture().get_image()
		assert(result.get_size() == Vector2i(1740, 1488))
		result.save_png(output + "MitteFehde-" + variant + ".png")
	var coordinates: Array = []
	for i in range(board.boxes.size()):
		var r: Rect2 = board.boxes[i]
		coordinates.append({"index": i, "name": game.s.tiles[i].name, "division": game.s.tiles[i].division, "x": r.position.x, "y": r.position.y, "width": r.size.x, "height": r.size.y})
	var file = FileAccess.open(output + "hitboxes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"logical_size": [870, 744], "png_size": [1740, 1488], "scale": 2, "hitboxes": coordinates}, "  "))
	board.free()
	print("Exported 3 PNGs at 1740x1488. 58 rectangles sourced directly from board.gd. Display at (0,0), size 870x744.")
	quit()
