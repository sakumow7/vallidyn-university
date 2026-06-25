extends Node
## Headless console entry point (spec §11.1: "a console test scene. Project runs").
## Links the rules core and runs a tiny DETERMINISTIC smoke check, then quits.
##
## This is NOT the test suite — the GUT suites in tests/ are the real coverage. Run
## the smoke check with:   godot --headless
## Run the full suite with: godot --headless -s addons/gut/gut_cmdln.gd \
##                            -gdir=res://tests -ginclude_subdirs -gexit

func _ready() -> void:
	print("── Vallidyn University · rules engine smoke test ──")

	# Deterministic RNG: same seed → same rolls (spec §2).
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260625

	# Modifier stacking: +2 and +1 circumstance → +2 (highest), plus a −1 status.
	var stack := ModifierStack.new()
	stack.add(Modifier.new(2, Ids.ModifierType.CIRCUMSTANCE, &"flanking"))
	stack.add(Modifier.new(1, Ids.ModifierType.CIRCUMSTANCE, &"higher ground"))
	stack.add(Modifier.new(-1, Ids.ModifierType.STATUS, &"frightened 1"))
	var net := stack.total()
	print("  modifier stack net = %+d  (expect +1)" % net)
	assert(net == 1, "modifier stacking smoke check failed")

	# Universal check: STR +4, trained at level 1 (+3), vs AC 18.
	var res := Check.roll(18, 4, 3, stack, rng)
	print("  check: %s" % res)
	assert(res.total == res.natural + 4 + 3 + net, "check composition smoke check failed")

	# Damage roll.
	var dmg := Dice.roll("2d6+4", rng)
	print("  damage 2d6+4 → %d  (faces %s)" % [dmg.total, str(dmg.faces)])
	assert(dmg.valid and dmg.faces.size() == 2, "dice smoke check failed")

	# Conditions: frightened 2 (−2 status to everything) + off-guard (−2 circ AC).
	# Against this creature's AC the two penalties are different types, so both apply.
	var cond := ConditionEngine.new()
	cond.apply(Ids.Condition.FRIGHTENED, 2, &"Demoralize")
	cond.apply(Ids.Condition.OFF_GUARD, 0, &"flanked")
	var ac_stack := ModifierStack.new()
	ac_stack.add_all(cond.modifiers_for([Ids.StatTag.AC, Ids.StatTag.DEX_BASED]))
	print("  AC under frightened 2 + off-guard → %+d  (expect -4)" % ac_stack.total())
	assert(ac_stack.total() == -4, "condition modifier emission smoke check failed")
	cond.tick_end_of_turn()
	print("  frightened after end of turn → %d  (expect 1)" % cond.value_of(Ids.Condition.FRIGHTENED))
	assert(cond.value_of(Ids.Condition.FRIGHTENED) == 1, "frightened decrement smoke check failed")

	# Strike: a +9 longsword (1d8+4 slashing) at an off-guard goblin (AC 16 → 14).
	var hero := Creature.new("Hero", 18, 30)
	var goblin := Creature.new("Goblin", 16, 24)
	goblin.conditions.apply(Ids.Condition.OFF_GUARD, 0, &"flanked")
	assert(goblin.effective_ac() == 14, "off-guard AC smoke check failed")
	var economy := ActionEconomy.new()
	var strike := Strike.new(WeaponProfile.melee(9, "1d8", 4, Ids.DAMAGE_SLASHING))
	var sr := strike.resolve(hero, goblin, economy, rng)
	print("  %s" % sr)
	print("  goblin %d/%d HP · actions left %d · next MAP %d" % [
		goblin.hp, goblin.max_hp, economy.actions_remaining, economy.map_penalty(false)])
	assert(sr.performed and economy.actions_remaining == 2, "strike action-economy smoke check failed")
	assert(economy.map_penalty(false) == -5, "MAP smoke check failed")

	# Grid + flanking (M7): two allies on opposite sides flank the target → off-guard.
	var west := Vector2i(0, 1)
	var foe_sq := Vector2i(1, 1)
	var east := Vector2i(2, 1)
	var flanked := Movement.is_flanked(foe_sq, [west, east])
	print("  allies %d ft apart, target between → flanked: %s" % [Grid.distance(west, east), str(flanked)])
	assert(Grid.distance(west, east) == 10 and flanked, "flanking smoke check failed")

	print("── smoke test OK ──")
	get_tree().quit(0)
