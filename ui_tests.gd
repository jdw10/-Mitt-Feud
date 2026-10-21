extends SceneTree
var app
var failures = 0
var checks = 0

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)
	else: print("UI PASS: " + description)

func find_button(node: Node, prefix: String):
	if node is Button and node.text.begins_with(prefix): return node
	for c in node.get_children():
		var result = find_button(c, prefix)
		if result != null: return result
	return null

func click(prefix: String) -> void:
	var b = find_button(app.actions, prefix)
	verify(b != null and not b.disabled, "Button: " + prefix)
	if b != null and not b.disabled: b.pressed.emit()

func screenshot(filename: String) -> Image:
	await process_frame
	await process_frame
	var img = root.get_texture().get_image()
	img.save_png("res://../" + filename)
	return img

func run() -> void:
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.menu.hide()
	app.timer.stop()
	app.paused = true
	app.animations_enabled = false
	app.game.new_game(4, 42)
	app.game.s.turn = 0
	app.refresh()
	await screenshot("MitteFehde-board.png")
	click("Roll & march")
	while app.game.s.phase == "route": click("Follow the outer road")
	app.game.player().pos = 34
	app.game.arrive()
	app.refresh()
	click("Buy lot")
	click("Station troops")
	app.game.player().gold = 120
	app.refresh()
	click("Build market")
	verify(app.game.tile().building == "market", "Six-lot market constructed")
	click("Continue to cards")
	click("End turn")
	app.game.s.turn = 0
	app.game.player().pos = 2
	app.game.tile().owner = 1
	app.game.tile().troops = 5
	app.game.s.phase = "lot"
	app.refresh()
	click("Commit attacking force")
	verify(app.game.s.committed == 10, "Commit spinner supplies troops, not dice")
	click("Fight next round")
	verify(app.game.s.battle_dice[0].size() == 3 and app.game.s.battle_dice[1].size() == 3, "UI battle rolls three dice on each side")
	app.board.animate(app.game.s.event, 1.8)
	app.board.animation_left = 1.2
	var frame1 = await screenshot("MitteFehde-battle.png")
	app.board.animation_left = 0.4
	app.board.queue_redraw()
	var frame2 = await screenshot("MitteFehde-battle-motion.png")
	verify(frame1.get_data() != frame2.get_data(), "Battle figures actually animate across frames")
	click("Retreat")
	app.save_path = "res://ui-save.tmp"
	app.save_current()
	app.load_current()
	DirAccess.remove_absolute("res://ui-save.tmp")
	app.game.new_game(4, 42)
	app.game.s.turn = 0
	app.animations_enabled = true
	app.paused = false
	app.refresh()
	click("Roll & march")
	verify(app.animation_left > 0 and app.board.event.kind == "dice", "Roll starts central dice animation")
	var phase: String = app.game.s.phase
	app.act(app.game.pass_lot)
	verify(app.game.s.phase == phase, "Actions are gated during animation")
	app.game.player().human = false
	var before_ai: Dictionary = app.game.s.duplicate(true)
	app.ai_tick()
	verify(app.game.s == before_ai, "AI cannot advance while its animation is visible")
	app.game.player().human = true
	app.paused = true
	var frozen: float = app.animation_left
	await create_timer(0.15).timeout
	verify(app.animation_left == frozen, "Pause freezes animation timing")
	app.paused = false
	await screenshot("MitteFehde-dice.png")
	await create_timer(1.5).timeout
	verify(app.animation_left == 0, "Animation finishes and releases controls")
	app.game.player().pos = 1
	app.game.arrive()
	app.refresh()
	click("Buy lot")
	verify(app.board.event.kind == "lot", "Purchase starts central building animation")
	await screenshot("MitteFehde-building.png")
	app.show_rules()
	await process_frame
	for c in app.get_children():
		if c is Window: c.hide()
	app.show_menu()
	await process_frame
	print("UI RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
