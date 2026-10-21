extends SceneTree
const Game = preload("res://game.gd")
var passed = 0
var failed = 0

func verify(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + message)
	else:
		failed += 1
		push_error("FAIL: " + message)

func fresh():
	var g = Game.new()
	g.new_game(0, 42)
	g.s.turn = 0
	return g

func _initialize() -> void:
	var g = fresh()
	verify(g.s.tiles.size() == 58, "54 ownable lots + 4 corners")
	verify(g.player().gold == 100 and g.player().reserve == 20, "Starting resources")
	g.player().gold = 20
	g.player().reserve = 8
	verify(not g.required_payment(30, 2), "Unaffordable mixed penalty gives a check")
	verify(g.player().gold == 20 and g.player().reserve == 8 and g.player().checks == 1, "No partial loss on check")
	g.player().gold = 30
	verify(g.required_payment(30, 2), "Affordable payment is mandatory")
	verify(g.player().gold == 0 and g.player().reserve == 6 and g.player().checks == 1, "Exact payment deducts both resources")
	g.player().gold = 100
	g.player().reserve = 1
	g.required_payment(30, 2)
	verify(g.player().gold == 100 and g.player().reserve == 1 and g.player().checks == 2, "Troop shortage also preserves gold")
	g.s.tiles[1].owner = 0
	g.s.tiles[1].troops = 10
	g.s.tiles[1].building = "market"
	g.required_payment(0, 2)
	verify(not g.s.players[0].alive and g.s.tiles[1].owner == -1 and g.s.tiles[1].troops == 0 and g.s.tiles[1].building == "", "Third check clears every holding and building")
	verify(g.s.turn == 1 and g.s.phase == "roll", "Elimination advances to next active house")
	g = fresh()
	for i in range(1, 5): g.s.tiles[i].owner = 0
	verify(g.income(0) == [20, 6], "Full division does not double bare lots or base")
	g.s.tiles[1].building = "market"
	g.s.tiles[2].building = "barracks"
	verify(g.income(0) == [60, 12], "Full division doubles buildings only")
	g.s.tiles[4].owner = 1
	verify(g.income(0) == [40, 7], "Losing a lot removes division building multiplier")
	verify(g.building_cost("market", 0) == 60 and g.building_cost("market", 2) == 30, "Updated market costs")
	g = fresh()
	g.player().pos = 1
	g.s.phase = "lot"
	g.player().gold = 1
	verify(not g.buy_lot() and g.player().checks == 0, "Optional unaffordable purchase gives no check")
	g.player().gold = 100
	verify(g.buy_lot() and g.player().gold == 60, "Lot purchase charges correct price")
	verify(g.build("market") and g.player().gold == 0, "New market purchase")
	verify(not g.build("barracks"), "One building per lot")
	g.begin_cards()
	g.end_turn()
	verify(g.s.players[0].gold == 40, "New market produces this turn")
	verify(not g.end_turn(), "End-of-turn income cannot be claimed twice")
	g = fresh()
	g.player().pos = 1
	g.s.tiles[1].owner = 1
	g.s.tiles[1].building = "barracks"
	g.arrive()
	verify(g.tile().owner == 0 and g.player().reserve == 20 and g.tile().building == "barracks", "Undefended capture is automatic, free, preserves building")
	verify(g.demolish() and g.tile().building == "", "Captured building demolition")
	g = fresh()
	g.player().pos = 1
	g.tile().owner = 1
	g.tile().troops = 5
	g.s.phase = "lot"
	verify(g.attack(5) and g.player().reserve == 15 and g.s.committed == 5, "Commit only selected troops, separated from reserve")
	verify(not g.attack(3) and not g.deposit(3), "Cannot recommit or reinforce during battle")
	g.fight_round()
	verify(g.s.battle_dice[0].size() == 3 and g.s.battle_dice[1].size() == 3, "Five troops on either side mandates three dice")
	verify(g.player().reserve == 15, "Battle casualties never consume uncommitted reserves")
	var survivors: int = g.s.committed
	g.pass_lot()
	verify(g.player().reserve == 15 + survivors and g.s.committed == 0, "Retreat returns survivors without recruiting more")
	verify(not g.attack(1), "Retreat closes this encounter")
	g = fresh()
	g.player().pos = 1
	g.tile().owner = 1
	g.tile().troops = 2
	g.s.phase = "lot"
	g.attack(4)
	g.resolve_battle([6, 3, 1], [6, 2])
	verify(g.s.committed == 3 and g.tile().troops == 1 and g.player().reserve == 16, "Sorted comparisons; defender ties; no +1 modifier")
	g.resolve_battle([6, 5, 4], [1])
	verify(g.tile().owner == 0 and g.tile().troops == 3 and g.player().reserve == 16 and g.s.committed == 0, "Surviving committed attackers occupy captured lot")
	g = fresh()
	for i in range(1, 5): g.s.tiles[i].owner = 1
	g.player().pos = 1
	g.tile().troops = 1
	g.s.phase = "lot"
	g.attack(20)
	verify(g.player().reserve == 0 and g.s.committed == 20, "Player may explicitly commit all reserve troops")
	g.resolve_battle([3, 2, 1], [2])
	verify(g.tile().owner == 0 and g.tile().troops == 20, "Full division gives NO defensive +1")
	g = fresh()
	g.player().pos = 1
	g.tile().owner = 1
	g.tile().troops = 3
	g.s.phase = "lot"
	g.attack(5)
	g.resolve_battle([6, 5, 4], [3, 2, 1])
	verify(g.tile().owner == 0 and g.tile().troops == 5, "All three paired dice count toward casualties")
	g = fresh()
	g.player().pos = 1
	g.tile().owner = 1
	g.tile().troops = 3
	g.s.phase = "lot"
	g.attack(1)
	g.resolve_battle([1], [6, 5, 4])
	verify(g.s.phase == "manage" and g.player().reserve == 19 and g.s.committed == 0, "Committed force can be defeated despite spare reserves")
	for troops in [1, 2, 3, 5]:
		g = fresh()
		g.player().pos = 1
		g.tile().owner = 1
		g.tile().troops = troops
		g.s.phase = "lot"
		g.attack(troops)
		g.fight_round()
		verify(g.s.battle_dice[0].size() == mini(3, troops) and g.s.battle_dice[1].size() == mini(3, troops), "Mandatory dice for %d troops" % troops)
	g = fresh()
	g.s.phase = "cards"
	g.s.deck = [16]
	g.player().gold = 40
	g.player().reserve = 1
	g.buy_card()
	verify(g.player().gold == 20 and g.player().reserve == 1 and g.player().checks == 1, "Card purchase paid; failed mixed Famine loses nothing further")
	g = fresh()
	g.s.phase = "cards"
	g.s.deck = [18]
	g.buy_card()
	verify(g.player().pos == 2 and g.s.phase == "lot", "Movement card reopens destination resolution")
	g.pass_lot()
	g.begin_cards()
	verify(g.player().gold == 80, "Card movement does not grant premature income")
	g.end_turn()
	verify(g.s.players[0].gold == 100, "Card movement receives only one EoT")
	verify(Game.CARDS.size() == 28, "Exactly 28 official cards")
	var effects = [[20, 0], [30, 0], [40, 0], [0, 3], [0, 5], [0, 7], [15, 2], [30, 4], [40, 6]]
	for id in range(18):
		g = fresh()
		g.player().gold = 200
		g.player().reserve = 30
		g.s.phase = "cards"
		g.s.deck = [id]
		g.buy_card()
		var sign_value = 1 if id < 9 else -1
		verify(g.player().gold == 180 + sign_value * effects[id % 9][0] and g.player().reserve == 30 + sign_value * effects[id % 9][1], "Exact resource card %d" % id)
	for id in range(18, 28):
		g = fresh()
		g.player().pos = 20
		g.s.phase = "cards"
		g.s.deck = [id]
		g.buy_card()
		while g.s.phase == "route": g.choose_route(false)
		var step_value = id - 16 if id < 23 else -(id - 21)
		verify(g.player().pos == posmod(20 + step_value, 34), "Exact March card %d" % id)
	g = fresh()
	g.player().pos = 11
	g.start_move(-7, true)
	g.choose_route(true)
	verify(g.player().pos == 6, "Backward traversal enters trail at exit and returns to entrance")
	g.player().pos = 42
	g.start_move(-2, true)
	verify(g.player().pos == 40, "Backward movement inside six-lot division")
	g = fresh()
	g.player().pos = 0
	g.start_move(-1, true)
	verify(g.player().pos == 33, "Backward outer road wraps around zero")
	g = fresh()
	g.player().pos = 34
	g.arrive()
	verify(g.buy_lot() and g.player().gold == 40, "Six-lot territory can be purchased for 60 G")
	verify(g.building_cost("market", 8) == 120 and g.building_cost("barracks", 8) == 100, "Six-lot building prices")
	for i in range(34, 40): g.s.tiles[i].owner = 0
	verify(g.income(0) == [20, 8], "Six bare lots give six troops without doubling")
	g.s.tiles[34].building = "market"
	g.s.tiles[35].building = "barracks"
	verify(g.income(0) == [100, 18], "Six-lot full division doubles 40 G market and 6 T barracks only")
	g.s.tiles[39].owner = 1
	verify(g.income(0) == [60, 11], "Losing a six-lot division removes multiplier")
	g = fresh()
	g.s.deck.clear()
	g.s.discard = range(28)
	g.refill_deck()
	verify(g.s.deck.size() == 28 and g.s.discard.is_empty(), "All 28 cards reshuffle without duplication")
	g = fresh()
	g.player().pos = 6
	g.start_move(7, false)
	verify(g.s.phase == "route", "Trail branch prompts for choice")
	g.choose_route(true)
	verify(g.player().pos == 11, "Six ownable spaces then correct trail exit")
	g = fresh()
	g.s.tiles[1].owner = 0
	g.start_move(2, false)
	verify(g.s.phase == "march_deposit" and g.player().pos == 1, "Passing owned land pauses for optional deposit")
	g.deposit(2)
	g.continue_march()
	verify(g.player().pos == 2 and g.s.tiles[1].troops == 2, "March resumes with no extra movement cost")
	g = fresh()
	g.s.phase = "manage"
	g.s.extra = true
	verify(g.roll_move(true) and g.player().gold == 80, "Doubles extra roll costs 20")
	g.s.phase = "manage"
	verify(not g.roll_move(true), "Extra rolls cannot chain")
	g = fresh()
	for t in g.s.tiles:
		if t.division >= 0 and g.count_lots(0) < 16: t.owner = 0
	g.check_victory()
	verify(g.s.winner == 0 and g.s.phase == "finished", "16 lots ends game immediately")
	g = fresh()
	g.s.players[1].alive = false
	g.s.players[2].alive = false
	g.s.players[3].checks = 2
	g.s.turn = 3
	g.player().gold = 0
	g.required_payment(10, 0)
	verify(g.s.winner == 0, "Last surviving house wins")
	g = fresh()
	verify(g.save_game("res://test-save.tmp") == OK, "Save writes successfully")
	var expected = g.die()
	var h = Game.new()
	verify(h.load_game("res://test-save.tmp") and h.die() == expected, "Load restores state and RNG exactly")
	DirAccess.remove_absolute("res://test-save.tmp")
	var wins = 0
	for seed_value in range(1, 21):
		g.new_game(0, seed_value)
		for step in range(15000):
			if g.s.winner >= 0: break
			g.ai_step()
			var valid = true
			for p in g.s.players:
				if p.gold < 0 or p.reserve < 0 or g.s.committed < 0: valid = false
			for t in g.s.tiles:
				if t.troops < 0 or (t.owner == -1 and (t.troops != 0 or t.building != "")): valid = false
			if not valid:
				verify(false, "Simulation resources stay nonnegative")
				break
		if g.s.winner >= 0: wins += 1
		else: print("UNFINISHED seed=%d turn=%d phase=%s lots=%s reserves=%s" % [seed_value, g.s.turn_number, g.s.phase, str([g.count_lots(0), g.count_lots(1), g.count_lots(2), g.count_lots(3)]), str(g.s.players)])
	verify(wins == 20, "20 seeded full AI campaigns terminate with a winner and valid resources")
	print("RESULT: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
