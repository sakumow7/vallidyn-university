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

	print("── smoke test OK ──")
	get_tree().quit(0)
