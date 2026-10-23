extends Control
const Game = preload("res://game.gd")
const Board = preload("res://board.gd")
var game = Game.new()
var board
var header: Label
var houses: HBoxContainer
var actions: VBoxContainer
var detail: Label
var chronicle: RichTextLabel
var status: Label
var menu: Window
var timer: Timer
var paused = false
var selected = -1
var humans = 1
var animations_enabled = true
var animation_left = 0.0
var save_path = "user://campaign.save"

func _ready() -> void:
	make_theme()
	build_ui()
	game.new_game()
	refresh()
	show_menu()
	timer = Timer.new()
	timer.wait_time = 0.7
	timer.timeout.connect(ai_tick)
	add_child(timer)
	timer.start()
	if "--smoke" in OS.get_cmdline_user_args():
		menu.hide()
		paused = true
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("user://smoke.png")
		get_tree().quit()

func make_theme() -> void:
	var th = Theme.new()
	th.default_font_size = 16
	th.set_color("font_color", "Label", Color("e3e5d9"))
	th.set_color("font_color", "Button", Color("f0e7ce"))
	th.set_color("font_disabled_color", "Button", Color("66736e"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("432d33") if state == "normal" else Color("60434a")
		if state == "disabled": style.bg_color = Color("172628")
		style.border_color = Color("c6ab6a") if state == "focus" else Color("7e6b4d")
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 9
		style.content_margin_bottom = 9
		th.set_stylebox(state, "Button", style)
	theme = th

func label(value: String, parent: Node, size_value: int = 16) -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size_value)
	parent.add_child(l)
	return l

func button(value: String, parent: Node, call: Callable, disabled: bool = false) -> Button:
	var b = Button.new()
	b.text = value
	b.disabled = disabled
	b.pressed.connect(call)
	parent.add_child(b)
	return b

func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var top = HBoxContainer.new()
	root.add_child(top)
	header = label("MITTE FEHDE", top, 26)
	var serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	header.add_theme_font_override("font", serif)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("Save", top, save_current)
	button("Load", top, load_current)
	button("Rules", top, show_rules)
	button("Menu / Pause", top, show_menu)
	houses = HBoxContainer.new()
	houses.add_theme_constant_override("separation", 12)
	root.add_child(houses)
	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)
	var left = VBoxContainer.new()
	body.add_child(left)
	board = Board.new()
	board.game = game
	board.selected.connect(inspect)
	left.add_child(board)
	status = label("", left, 14)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 860
	var right = VBoxContainer.new()
	right.custom_minimum_size.x = 500
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 430
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	actions = VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 7)
	scroll.add_child(actions)
	detail = label("", right, 14)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 90
	label("CHRONICLE", right, 15)
	chronicle = RichTextLabel.new()
	chronicle.custom_minimum_size = Vector2(480, 205)
	chronicle.scroll_following = true
	chronicle.add_theme_font_size_override("normal_font_size", 14)
	right.add_child(chronicle)

func act(call: Callable) -> void:
	if animation_left > 0: return
	var actor: int = game.s.turn
	var previous_event: int = game.s.event_serial
	var previous_log: String = game.s.log.back() if not game.s.log.is_empty() else ""
	call.call()
	if game.s.event_serial == previous_event:
		var caption: String = game.s.log.back() if not game.s.log.is_empty() else "Considering the lot"
		if caption == previous_log and game.s.phase == "manage": caption = "Considering " + game.tile().name
		game.present("lot", caption)
		game.s.event.actor = actor
	if animations_enabled:
		animation_left = 1.8 if game.s.event.kind == "fight" else 1.3
		board.animate(game.s.event, animation_left)
	selected = -1
	board.inspected = -1
	refresh()
	game.save_game("user://autosave.save")

func _process(delta: float) -> void:
	if animation_left > 0 and not paused:
		animation_left = maxf(0, animation_left - delta)
		board.animation_left = animation_left
		board.queue_redraw()
		if animation_left == 0: build_actions()

func refresh() -> void:
	clear(houses)
	for i in range(4):
		var p = game.s.players[i]
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", board.panel(Board.COLORS[i].darkened(0.85), Board.COLORS[i] if i == game.s.turn else Color("344641"), 2 if i == game.s.turn else 1))
		houses.add_child(panel)
		var box = VBoxContainer.new()
		panel.add_child(box)
		var title = label("  %s %s" % [p.name, "[YOU]" if p.human else "[AI]"], box, 16)
		title.modulate = Board.COLORS[i]
		label("  %d G   |   %d reserve T   |   %d/16 lots  " % [p.gold, p.reserve, game.count_lots(i)], box, 15)
		var gain = game.income(i)
		label("  Checks %d/3    EoT +%d G / +%d T" % [p.checks, gain[0], gain[1]] if p.alive else "  ELIMINATED", box, 13)
	header.text = "MITTE FEHDE   /   Turn %d" % game.s.turn_number
	board.queue_redraw()
	chronicle.text = "\n".join(game.s.log)
	inspect(selected if selected >= 0 else game.player().pos)
	build_actions()
	status.text = "Gold and reserve troops are tracked automatically. Income pays once at the end of your own turn."

func inspect(index: int) -> void:
	selected = index
	var t = game.s.tiles[index]
	var text = t.name
	if t.division >= 0:
		text += "  /  " + Game.DIVISIONS[t.division][0]
		text += "\n" + ("Unowned — %d G" % (game.size_of(t.division) * 10) if t.owner < 0 else "%s | %d stationed troops" % [game.s.players[t.owner].name, t.troops])
		text += "\n" + ("Bare lot: +1 reserve troop / turn (never doubled)" if t.building == "" else t.building.capitalize() + (" | Full division: double output" if game.full_division(t.division, t.owner) else " | Normal output"))
	else:
		text += "\nTransit only; cannot be owned or built on."
		if t.division == -1: text += " Corner effects apply on landing only."
	detail.text = text

func action_button(text: String, call: Callable, disabled: bool = false) -> void:
	button(text, actions, func(): act(call), disabled)

func build_actions() -> void:
	clear(actions)
	var p = game.player()
	var t = game.tile()
	label(p.name.to_upper(), actions, 21).modulate = Board.COLORS[game.s.turn]
	var phase: String = game.s.phase
	label("Phase: " + phase.replace("_", " ").capitalize(), actions, 15)
	if game.s.winner >= 0:
		label("VICTORY — " + game.s.players[game.s.winner].name, actions, 22)
		label("The realm has a new ruler.", actions)
		button("Play again", actions, show_menu)
		return
	if animation_left > 0:
		label("Watch the action in the center…", actions)
		return
	if not p.human:
		label("The rival house is taking its turn…", actions)
		label("Watch the chronicle for its decisions.", actions, 14)
		return
	if game.s.dice.size() == 2: label("Movement dice:  %d  +  %d" % [game.s.dice[0], game.s.dice[1]], actions, 18)
	var hint = label("", actions, 14)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match phase:
		"roll":
			hint.text = "Roll two dice, then buy, reinforce or fight at your destination."
			action_button("Roll & march", func(): game.roll_move())
		"route":
			hint.text = "%d steps remain (%s). Choose the outer road or six-lot division." % [game.s.remaining, "forward" if game.s.direction > 0 else "backward"]
			action_button("Follow the outer road", func(): game.choose_route(false))
			action_button("Take " + Game.TRAILS[game.trail_at(p.pos)], func(): game.choose_route(true))
		"march_deposit":
			hint.text = "Passing your land: you may leave troops here. %d steps remain." % game.s.remaining
			deposit_controls()
			if t.building == "" and not game.s.built:
				for kind in ["market", "barracks"]:
					var cost = game.building_cost(kind, t.division)
					action_button("Build %s — %d G" % [kind, cost], func(): game.build(kind), p.gold < cost)
			elif t.building != "": label("Building: " + t.building.capitalize(), actions, 14)
			action_button("Continue march", game.continue_march)
		"lot":
			hint.text = "Destination: " + t.name
			if t.owner < 0:
				action_button("Buy lot — %d G" % (game.size_of(t.division) * 10), game.buy_lot, p.gold < game.size_of(t.division) * 10)
			else:
				label("Defended by %d troops." % t.troops, actions)
				attack_controls()
			action_button("Pass this lot", game.pass_lot)
		"combat":
			hint.text = game.s.battle
			label("Committed: %d T  |  Defenders: %d T" % [game.s.committed, t.troops], actions)
			label("Mandatory dice: %d attack / %d defense" % [mini(3, game.s.committed), mini(3, t.troops)], actions)
			action_button("Fight next round", game.fight_round)
			action_button("Retreat / stop attacking", game.pass_lot)
		"manage":
			hint.text = "Reinforce and build on your destination, then proceed to cards."
			if t.owner == game.s.turn:
				deposit_controls()
				if t.building == "" and not game.s.built:
					for kind in ["market", "barracks"]:
						var cost = game.building_cost(kind, t.division)
						action_button("Build %s — %d G" % [kind, cost], func(): game.build(kind), p.gold < cost)
				elif t.building != "": label("Building: " + t.building.capitalize(), actions, 14)
				if game.s.captured and t.building != "": action_button("Demolish captured building (no refund)", game.demolish)
			if game.s.extra and not game.s.extra_used: action_button("Doubles: extra roll — 20 G", func(): game.roll_move(true), p.gold < 20)
			action_button("Continue to cards", game.begin_cards)
		"cards":
			hint.text = "Buy and resolve cards one at a time. There is no purchase limit."
			if game.s.last_card != "":
				var card = label(game.s.last_card, actions, 16)
				card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			action_button("Buy event card — 20 G", game.buy_card, p.gold < 20)
			var gain = game.income(game.s.turn)
			action_button("End turn  /  collect %d G + %d T" % gain, game.end_turn)

func deposit_controls() -> void:
	var row = HBoxContainer.new()
	actions.add_child(row)
	var amount = SpinBox.new()
	amount.min_value = 1
	amount.max_value = maxi(1, game.player().reserve)
	amount.value = mini(3, maxi(1, game.player().reserve))
	amount.custom_minimum_size.x = 115
	row.add_child(amount)
	button("Station troops", row, func(): act(func(): game.deposit(int(amount.value))), game.player().reserve < 1)

func attack_controls() -> void:
	label("Choose troops now. No reinforcements during battle.", actions, 14)
	var row = HBoxContainer.new()
	actions.add_child(row)
	var amount = SpinBox.new()
	amount.min_value = 1
	amount.max_value = maxi(1, game.player().reserve)
	amount.value = mini(maxi(1, game.player().reserve), maxi(5, game.tile().troops * 2))
	amount.custom_minimum_size.x = 115
	row.add_child(amount)
	button("Commit attacking force", row, func(): act(func(): game.attack(int(amount.value))), game.player().reserve < 1)

func ai_tick() -> void:
	if paused or animation_left > 0 or game.s.is_empty() or game.s.winner >= 0: return
	if not game.player().human: act(game.ai_step)

func save_current() -> void:
	var result = game.save_game(save_path)
	status.text = "Campaign saved." if result == OK else "Could not save campaign: " + error_string(result)

func load_current() -> void:
	if animation_left > 0: return
	if game.load_game(save_path):
		board.event = {}
		selected = -1
		refresh()
		status.text = "Campaign loaded."
	else: status.text = "No compatible manual save found. Use Menu to resume an autosave."

func popup(title_value: String, dimensions: Vector2i) -> Window:
	paused = true
	var w = Window.new()
	w.title = title_value
	w.size = dimensions
	w.transient = true
	w.exclusive = true
	w.unresizable = true
	w.theme = theme
	add_child(w)
	w.close_requested.connect(func(): w.hide(); paused = false)
	w.popup_centered()
	return w

func show_menu() -> void:
	if menu != null:
		paused = true
		menu.popup_centered()
		return
	menu = popup("Mitte Fehde | Campaign", Vector2i(560, 470))
	var box = VBoxContainer.new()
	box.position = Vector2(30, 25)
	box.size = Vector2(500, 420)
	box.add_theme_constant_override("separation", 14)
	menu.add_child(box)
	label("MITTE FEHDE", box, 30)
	label("Mitteralteriche Fehde — offline playtest", box, 17)
	var intro = label("Build your treasury. Garrison your land. Claim 16 lots.\nFour houses take turns on one computer.", box, 16)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var mode = OptionButton.new()
	for text in ["Solo — you vs 3 computer houses", "2 local players + 2 computer houses", "3 local players + 1 computer house", "4 local players — hot seat"]: mode.add_item(text)
	box.add_child(mode)
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Start a new campaign? The current autosave will be replaced. Your manual save stays available."
	confirm.title = "New campaign"
	menu.add_child(confirm)
	confirm.confirmed.connect(func(): humans = mode.selected + 1; game.new_game(humans); menu.hide(); paused = false; animation_left = 0; board.event = {}; selected = -1; refresh(); game.save_game("user://autosave.save"))
	button("Start new campaign", box, func(): confirm.popup_centered())
	button("Continue current campaign", box, func(): menu.hide(); paused = false)
	button("Resume autosave", box, func():
		if game.load_game("user://autosave.save"):
			menu.hide(); paused = false; animation_left = 0; board.event = {}; selected = -1; refresh()
		else: status.text = "No compatible autosave found.")
	button("Quit", box, func(): get_tree().quit())

func show_rules() -> void:
	var w = popup("How to play / prototype rulings", Vector2i(800, 650))
	var text = RichTextLabel.new()
	text.position = Vector2(24, 20)
	text.size = Vector2(752, 600)
	text.text = FileAccess.get_file_as_string("res://RULES.txt")
	w.add_child(text)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		show_menu()
