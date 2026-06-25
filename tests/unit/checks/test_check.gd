extends GutTest
## The universal check composes Dice + ModifierStack + Degrees (spec §4.2). Because
## the d20 is random, we seed a real RNG and assert on composition + ranges rather
## than hard-coding the engine's RNG output.

var _rng: RandomNumberGenerator


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 424242


func test_total_is_sum_of_components() -> void:
	var stack := ModifierStack.new()
	stack.add(Modifier.new(2, Ids.ModifierType.CIRCUMSTANCE, &"flank"))
	var res := Check.roll(20, 4, 3, stack, _rng)
	assert_eq(res.total, res.natural + 4 + 3 + 2)
	assert_between(res.natural, 1, 20)


func test_degree_matches_resolver_over_many_rolls() -> void:
	for _i: int in 200:
		var res := Check.roll(18, 2, 5, null, _rng)
		assert_eq(res.degree, Degrees.resolve(res.total, 18, res.natural))


func test_null_stack_is_allowed() -> void:
	var res := Check.roll(15, 0, 0, null, _rng)
	assert_eq(res.total, res.natural, "no ability/prof/mods → total is just the d20")


func test_components_are_recorded() -> void:
	var stack := ModifierStack.new()
	stack.add(Modifier.new(1, Ids.ModifierType.STATUS, &"bless"))
	var res := Check.roll(15, 3, 2, stack, _rng)
	# d20 + ability + proficiency + bless = 4 components.
	assert_eq(res.components.size(), 4)


func test_zero_ability_and_prof_omitted_from_components() -> void:
	var res := Check.roll(15, 0, 0, null, _rng)
	assert_eq(res.components.size(), 1, "only the d20 component when nothing else applies")


func test_result_predicates() -> void:
	# Force a known band by choosing a tiny DC so any roll crit-succeeds, and a huge
	# DC so any roll crit-fails — independent of the RNG.
	var crit := Check.roll(-100, 0, 0, null, _rng)
	assert_true(crit.is_critical_success())
	assert_true(crit.is_success())
	var fumble := Check.roll(1000, 0, 0, null, _rng)
	assert_true(fumble.is_critical_failure())
	assert_true(fumble.is_failure())


func test_flat_check_distribution() -> void:
	var passes := 0
	for _i: int in 2000:
		if Check.flat(11, _rng):
			passes += 1
	# DC 11 on a d20 → 50% (rolls 11..20). Over 2000 trials, expect ~1000.
	assert_between(passes, 850, 1150)


func test_flat_check_bonus_applies() -> void:
	# With a +100 bonus, a DC 11 flat check always passes.
	for _i: int in 50:
		assert_true(Check.flat(11, _rng, 100))
