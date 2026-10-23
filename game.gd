extends RefCounted
## Rules live here, independent of presentation. All actions validate their phase.
const VERSION = 2
const HOUSES = ["House Alder", "House Ember", "House Azure", "House Ivory"]
const DIVISIONS = [
	["Guildmarket", ["Wool Row", "Spice Stall", "Silver Hall", "Guild House"]],
	["Sunspire", ["Belfry", "Cloister", "Shrine Walk", "Pilgrim Rest"]],
	["Tidewatch", ["Salt Wharf", "Gull Haven", "Beacon"]],
	["Red Keep", ["Forge Yard", "Barracks", "Armory", "Ember Gate"]],
	["Riverhold", ["Blue Bridge", "Ferry", "Reedbank", "Watermill"]],
	["Rose Quarter", ["Rose Lane", "Weaver Court", "Maiden Well", "Lantern Row"]],
	["Unicorn Vale", ["Moonwell", "Silver Glade", "Lavender", "Dreamer's Rest"]],
	["Lion's Reach", ["Goldmane", "Banner Hill", "Lion's Rest"]],
	["Northwatch Pass", ["Tollgate", "Wolfstone", "Pine Bend", "Milestone", "High Bridge", "Frost Gate"]],
	["Sunroad", ["East Gate", "Chapel", "Gold Mile", "Vineway", "Wayside Well", "Pilgrim Stone"]],
	["Seaward Way", ["Harbor", "Salt Road", "Gullstone", "Windmill", "Beacon Bend", "Cliff Bridge"]],
	["Shadowfen Trail", ["Low Gate", "Ash Ford", "Willow Bend", "Blackwater", "Moorstone", "Raven Post"]]
]
const TRAILS = ["Northwatch Pass", "Sunroad", "Seaward Way", "Shadowfen Trail"]
const CARDS = [
	["SURPLUS", "Gain 20 gold.", 20, 0, 0],
	["SURPLUS", "Gain 30 gold.", 30, 0, 0],
	["SURPLUS", "Gain 40 gold.", 40, 0, 0],
	["SURPLUS", "Gain 3 troops.", 0, 3, 0],
	["SURPLUS", "Gain 5 troops.", 0, 5, 0],
	["SURPLUS", "Gain 7 troops.", 0, 7, 0],
	["SURPLUS", "Gain 15 gold and 2 troops.", 15, 2, 0],
	["SURPLUS", "Gain 30 gold and 4 troops.", 30, 4, 0],
	["SURPLUS", "Gain 40 gold and 6 troops.", 40, 6, 0],
	["FAMINE", "Lose 20 gold.", -20, 0, 0],
	["FAMINE", "Lose 30 gold.", -30, 0, 0],
	["FAMINE", "Lose 40 gold.", -40, 0, 0],
	["FAMINE", "Lose 3 troops.", 0, -3, 0],
	["FAMINE", "Lose 5 troops.", 0, -5, 0],
	["FAMINE", "Lose 7 troops.", 0, -7, 0],
	["FAMINE", "Lose 15 gold and 2 troops.", -15, -2, 0],
	["FAMINE", "Lose 30 gold and 4 troops.", -30, -4, 0],
	["FAMINE", "Lose 40 gold and 6 troops.", -40, -6, 0],
	["MARCH", "Forward 2 spaces.", 0, 0, 2],
	["MARCH", "Forward 3 spaces.", 0, 0, 3],
	["MARCH", "Forward 4 spaces.", 0, 0, 4],
	["MARCH", "Forward 5 spaces.", 0, 0, 5],
	["MARCH", "Forward 6 spaces.", 0, 0, 6],
	["MARCH", "Backward 2 spaces.", 0, 0, -2],
	["MARCH", "Backward 3 spaces.", 0, 0, -3],
	["MARCH", "Backward 4 spaces.", 0, 0, -4],
	["MARCH", "Backward 5 spaces.", 0, 0, -5],
	["MARCH", "Backward 6 spaces.", 0, 0, -6]
]
var s: Dictionary = {}
var rng = RandomNumberGenerator.new()

func new_game(humans: int = 1, seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	s = {"version": VERSION, "players": [], "tiles": [], "turn": 0, "turn_number": 1, "phase": "roll", "log": [], "winner": -1, "dice": [], "extra": false, "extra_used": false, "remaining": 0, "movement_from_card": false, "built": false, "captured": false, "deck": [], "discard": [], "last_card": "", "battle": "", "visited": [], "direction": 1, "committed": 0, "battle_dice": [], "event_serial": 0, "event": {}}
	for i in range(4):
		s.players.append({"name": HOUSES[i], "gold": 100, "reserve": 20, "checks": 0, "alive": true, "pos": 0, "human": i < humans})
	add_tile("Muster / +10 T", -1, 10, 0)
	for d in range(8):
		for n in DIVISIONS[d][1]:
			add_tile(n, d)
		if d == 1: add_tile("Levy / -10 T", -1, -10, 0)
		if d == 3: add_tile("Treasury / +100 G", -1, 0, 100)
		if d == 5: add_tile("Tax / -100 G", -1, 0, -100)
	# Outer loop: 34 spaces. Four six-lot divisions form the inner routes.
	for t in range(4):
		for j in range(6):
			add_tile(DIVISIONS[8 + t][1][j], 8 + t)
	var contenders = [0, 1, 2, 3]
	while contenders.size() > 1:
		var best = 0
		var next: Array = []
		for i in contenders:
			var roll_value = die()
			log_event("%s rolls %d for initiative." % [s.players[i].name, roll_value])
			if roll_value > best:
				best = roll_value
				next = [i]
			elif roll_value == best:
				next.append(i)
		contenders = next
	s.turn = contenders[0]
	refill_deck()
	log_event("%s begins. Claim 16 lots to win." % player().name)

func add_tile(n: String, d: int, troops: int = 0, gold: int = 0) -> void:
	s.tiles.append({"name": n, "division": d, "owner": -1, "troops": 0, "building": "", "effect_t": troops, "effect_g": gold})

func player() -> Dictionary:
	return s.players[s.turn]

func tile() -> Dictionary:
	return s.tiles[player().pos]

func die() -> int:
	return rng.randi_range(1, 6)

func log_event(message: String) -> void:
	s.log.append(message)
	if s.log.size() > 120: s.log.pop_front()

func size_of(d: int) -> int:
	return DIVISIONS[d][1].size() if d >= 0 else 0

func count_lots(p: int) -> int:
	var count = 0
	for t in s.tiles:
		if t.owner == p: count += 1
	return count

func full_division(d: int, p: int) -> bool:
	if d < 0: return false
	for t in s.tiles:
		if t.division == d and t.owner != p: return false
	return true

func income(p: int) -> Array:
	var gold = 20
	var troops = 2
	for t in s.tiles:
		if t.owner != p: continue
		var n = size_of(t.division)
		var multiplier = 2 if full_division(t.division, p) else 1
		if t.building == "market": gold += {2: 5, 3: 10, 4: 20, 6: 40}[n] * multiplier
		elif t.building == "barracks": troops += n * multiplier
		else: troops += 1
	return [gold, troops]

func building_cost(kind: String, d: int) -> int:
	var n = size_of(d)
	if n < 2: return 999999
	return {2: 15, 3: 30, 4: 60, 6: 120}[n] if kind == "market" else {2: 20, 3: 40, 4: 60, 6: 100}[n]

func required_payment(gold: int, troops: int) -> bool:
	# Atomic: no partial payment, and no option to evade an affordable cost.
	var p = player()
	if p.gold >= gold and p.reserve >= troops:
		p.gold -= gold
		p.reserve -= troops
		log_event("%s pays %d G and %d T." % [p.name, gold, troops])
		return true
	p.checks += 1
	log_event("%s cannot fully pay: check %d/3. No resources lost." % [p.name, p.checks])
	if p.checks >= 3:
		p.alive = false
		p.reserve = 0
		for t in s.tiles:
			if t.owner == s.turn:
				t.owner = -1
				t.troops = 0
				t.building = ""
		log_event("%s is eliminated. Their lots return to the realm." % p.name)
		check_victory()
		if s.winner < 0: next_turn()
	return false

func check_victory() -> void:
	var alive: Array = []
	for i in range(4):
		if s.players[i].alive:
			alive.append(i)
			if count_lots(i) >= 16: s.winner = i
	if alive.size() == 1: s.winner = alive[0]
	if s.winner >= 0:
		s.phase = "finished"
		log_event("%s rules the realm!" % s.players[s.winner].name)

func roll_move(extra_roll: bool = false) -> bool:
	if extra_roll:
		if s.phase != "manage" or not s.extra or s.extra_used or player().gold < 20: return false
		player().gold -= 20
		s.extra_used = true
		s.extra = false
	else:
		if s.phase != "roll": return false
	s.dice = [die(), die()]
	if not extra_roll: s.extra = s.dice[0] == s.dice[1]
	log_event("%s rolls %d + %d." % [player().name, s.dice[0], s.dice[1]])
	var roller: int = s.turn
	var rolls: Array = s.dice.duplicate()
	start_move(rolls[0] + rolls[1], false)
	present("dice", "%s rolls %d + %d" % [s.players[roller].name, rolls[0], rolls[1]], -1, rolls)
	s.event.actor = roller
	return true

func start_move(steps: int, from_card: bool) -> void:
	s.remaining = absi(steps)
	s.direction = 1 if steps >= 0 else -1
	s.movement_from_card = from_card
	s.built = false
	s.captured = false
	s.visited = []
	s.phase = "moving"
	advance_move()

func trail_at(pos: int) -> int:
	# Entry/exit links are provisional; six-space paths bypass the corner.
	return ([31, 6, 14, 23] if s.direction > 0 else [2, 11, 19, 28]).find(pos)

func next_outer(pos: int) -> int:
	if pos < 34: return posmod(pos + s.direction, 34)
	var tr = int((pos - 34) / 6)
	if s.direction > 0 and (pos - 34) % 6 == 5: return [2, 11, 19, 28][tr]
	if s.direction < 0 and (pos - 34) % 6 == 0: return [31, 6, 14, 23][tr]
	return pos + s.direction

func advance_move() -> void:
	while s.remaining > 0:
		if trail_at(player().pos) >= 0:
			s.phase = "route"
			return
		step_to(next_outer(player().pos))
		if s.phase == "march_deposit": return
	arrive()

func step_to(pos: int) -> void:
	player().pos = pos
	s.remaining -= 1
	s.visited.append(pos)
	if s.remaining > 0 and tile().owner == s.turn and player().reserve > 0:
		s.phase = "march_deposit"

func choose_route(shortcut: bool) -> bool:
	if s.phase != "route": return false
	var tr = trail_at(player().pos)
	if tr < 0: return false
	s.phase = "moving"
	step_to(34 + tr * 6 + (0 if s.direction > 0 else 5) if shortcut else next_outer(player().pos))
	if s.phase != "march_deposit": advance_move()
	return true

func continue_march() -> bool:
	if s.phase != "march_deposit": return false
	s.phase = "moving"
	advance_move()
	return true

func arrive() -> void:
	s.phase = "lot"
	log_event("%s arrives at %s." % [player().name, tile().name])
	var t = tile()
	if t.division < 0:
		s.phase = "manage"
		if t.effect_g < 0 or t.effect_t < 0:
			required_payment(maxi(0, -t.effect_g), maxi(0, -t.effect_t))
		elif t.effect_g > 0 or t.effect_t > 0:
			player().gold += t.effect_g
			player().reserve += t.effect_t
			log_event("Corner benefit: +%d G, +%d T." % [t.effect_g, t.effect_t])
	elif t.owner == s.turn:
		s.phase = "manage"
	elif t.owner >= 0 and t.troops == 0:
		capture(0)

func buy_lot() -> bool:
	if s.phase != "lot" or tile().division < 0 or tile().owner >= 0: return false
	var cost = size_of(tile().division) * 10
	if player().gold < cost: return false
	player().gold -= cost
	tile().owner = s.turn
	s.phase = "manage"
	log_event("%s purchases %s for %d G." % [player().name, tile().name, cost])
	check_victory()
	return true

func pass_lot() -> bool:
	if s.phase != "lot" and s.phase != "combat": return false
	player().reserve += s.committed
	s.committed = 0
	s.phase = "manage"
	log_event("%s passes / retreats." % player().name)
	return true

func deposit(amount: int) -> bool:
	if not s.phase in ["manage", "march_deposit"] or tile().owner != s.turn: return false
	if amount <= 0 or amount > player().reserve: return false
	player().reserve -= amount
	tile().troops += amount
	log_event("%d troops stationed at %s." % [amount, tile().name])
	return true

func build(kind: String) -> bool:
	if s.phase not in ["manage", "march_deposit"] or s.built or tile().owner != s.turn or tile().building != "" or not kind in ["market", "barracks"]: return false
	var cost = building_cost(kind, tile().division)
	if player().gold < cost: return false
	player().gold -= cost
	tile().building = kind
	s.built = true
	log_event("%s builds a %s for %d G." % [player().name, kind, cost])
	return true

func demolish() -> bool:
	if s.phase != "manage" or not s.captured or tile().owner != s.turn or tile().building == "": return false
	log_event("Captured %s demolished; no refund." % tile().building)
	tile().building = ""
	s.captured = false
	return true

func attack(amount: int) -> bool:
	# One commitment per destination encounter. These troops leave reserve now.
	if s.phase != "lot" or tile().owner < 0 or tile().owner == s.turn or tile().troops <= 0: return false
	if amount < 1 or amount > player().reserve: return false
	player().reserve -= amount
	s.committed = amount
	s.battle_dice = []
	s.battle = "%d attackers committed against %d defenders. No reinforcements." % [amount, tile().troops]
	s.phase = "combat"
	log_event(s.battle)
	present("fight", s.battle, tile().owner)
	return true

func fight_round() -> bool:
	if s.phase != "combat" or s.committed <= 0: return false
	var a: Array = []
	var d: Array = []
	for i in range(mini(3, s.committed)): a.append(die())
	for i in range(mini(3, tile().troops)): d.append(die())
	resolve_battle(a, d)
	return true

func resolve_battle(a: Array, d: Array) -> void:
	var defender: int = tile().owner
	a.sort()
	a.reverse()
	d.sort()
	d.reverse()
	var lost_a = 0
	var lost_d = 0
	for i in range(mini(a.size(), d.size())):
		if a[i] > d[i]: lost_d += 1
		else: lost_a += 1
	s.committed -= lost_a
	tile().troops -= lost_d
	s.battle_dice = [a.duplicate(), d.duplicate()]
	s.battle = "Attack %s vs defense %s\nLosses: %d attacker / %d defender" % [str(a), str(d), lost_a, lost_d]
	log_event(s.battle.replace("\n", ". "))
	if tile().troops == 0:
		capture(s.committed)
	elif s.committed == 0:
		s.phase = "manage"
		log_event("The committed attacking force is defeated. Uncommitted reserves are safe.")
	present("fight", "Battle at %s\nLosses: %d attack / %d defense\n" % [tile().name, lost_a, lost_d] + ("Lot captured" if tile().owner == s.turn else "%d attackers / %d defenders remain" % [s.committed, tile().troops]), defender, s.battle_dice)

func capture(occupying: int) -> void:
	tile().owner = s.turn
	tile().troops = occupying
	s.committed = 0
	s.captured = true
	s.phase = "manage"
	log_event("%s captures %s; %d surviving troops occupy it." % [player().name, tile().name, occupying])
	check_victory()

func present(kind: String, caption: String, other: int = -1, dice_values: Array = []) -> void:
	s.event_serial += 1
	s.event = {"kind": kind, "caption": caption, "actor": s.turn, "other": other, "dice": dice_values.duplicate(true)}

func begin_cards() -> bool:
	if s.phase != "manage": return false
	s.phase = "cards"
	s.extra = false
	return true

func refill_deck() -> void:
	if s.discard.is_empty():
		for i in range(CARDS.size()): s.deck.append(i)
	else:
		s.deck = s.discard.duplicate()
		s.discard.clear()
	for i in range(s.deck.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = s.deck[i]
		s.deck[i] = s.deck[j]
		s.deck[j] = temp

func buy_card() -> bool:
	if s.phase != "cards" or player().gold < 20: return false
	player().gold -= 20
	if s.deck.is_empty(): refill_deck()
	var id = s.deck.pop_back()
	s.discard.append(id)
	var c = CARDS[id]
	s.last_card = "%s — %s" % [c[0], c[1]]
	log_event("Card (20 G): " + s.last_card)
	if c[2] < 0 or c[3] < 0:
		required_payment(maxi(0, -c[2]), maxi(0, -c[3]))
	else:
		player().gold += c[2]
		player().reserve += c[3]
		if c[4] != 0: start_move(c[4], true)
	return true

func end_turn() -> bool:
	if s.phase != "cards": return false
	var gain = income(s.turn)
	player().gold += gain[0]
	player().reserve += gain[1]
	log_event("%s collects %d G + %d T." % [player().name, gain[0], gain[1]])
	next_turn()
	return true

func next_turn() -> void:
	if s.winner >= 0: return
	for i in range(4):
		s.turn = (s.turn + 1) % 4
		if player().alive: break
	s.turn_number += 1
	s.phase = "roll"
	s.extra = false
	s.extra_used = false
	s.built = false
	s.captured = false
	s.remaining = 0
	s.dice = []
	s.battle = ""
	s.last_card = ""
	s.visited = []
	log_event("Turn %d: %s." % [s.turn_number, player().name])

func ai_step() -> void:
	match s.phase:
		"roll": roll_move()
		"route": choose_route(rng.randf() < 0.55)
		"march_deposit":
			ai_reinforce()
			continue_march()
		"lot":
			if tile().owner == -1:
				if not buy_lot(): pass_lot()
			elif player().reserve > tile().troops + 2:
				attack(mini(player().reserve, maxi(5, tile().troops * 2 + 3)))
			else: pass_lot()
		"combat":
			if s.committed >= tile().troops or s.committed >= 3: fight_round()
			else: pass_lot()
		"manage":
			if tile().owner == s.turn:
				ai_reinforce()
				if tile().building == "" and not s.built:
					build("barracks" if player().reserve < 12 else "market")
			if s.extra and not s.extra_used and player().gold >= 60: roll_move(true)
			else: begin_cards()
		"cards":
			if player().gold >= 100 and s.last_card == "": buy_card()
			else: end_turn()

func ai_reinforce() -> void:
	# Grow defenses with the treasury's army; prioritize complete divisions.
	var target = 4 + int(player().reserve / 5)
	if full_division(tile().division, s.turn): target += 5
	if tile().troops < target and player().reserve > 8:
		deposit(mini(target - tile().troops, player().reserve - 8))

func save_game(path: String) -> Error:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_var({"state": s, "rng_state": rng.state})
	return OK

func load_game(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null: return false
	var data = file.get_var(false)
	if not data is Dictionary or not data.has("state") or not data.has("rng_state"): return false
	var candidate = data.state
	if not candidate is Dictionary or candidate.get("version") != VERSION: return false
	for key in ["players", "tiles", "turn", "phase", "deck", "discard", "log", "winner"]:
		if not candidate.has(key): return false
	if candidate.players.size() != 4 or candidate.tiles.size() != 58 or candidate.turn < 0 or candidate.turn > 3: return false
	s = candidate
	rng.state = data.rng_state
	return true
