extends GutTest
## Ability scores → modifiers, boosts, and flaws (spec §4.5/§5).


func test_modifier_for() -> void:
	assert_eq(AbilityScores.modifier_for(10), 0)
	assert_eq(AbilityScores.modifier_for(11), 0, "odd scores round down")
	assert_eq(AbilityScores.modifier_for(12), 1)
	assert_eq(AbilityScores.modifier_for(18), 4)
	assert_eq(AbilityScores.modifier_for(9), -1)
	assert_eq(AbilityScores.modifier_for(7), -2, "negative scores floor correctly")


func test_defaults_to_ten() -> void:
	var a := AbilityScores.new()
	assert_eq(a.score(Ids.Ability.STR), 10)
	assert_eq(a.modifier(Ids.Ability.STR), 0)


func test_boost_adds_two_below_18() -> void:
	var a := AbilityScores.new()
	a.boost(Ids.Ability.STR)
	assert_eq(a.score(Ids.Ability.STR), 12)
	assert_eq(a.modifier(Ids.Ability.STR), 1)


func test_boost_adds_one_at_18_or_more() -> void:
	var a := AbilityScores.new()
	a.set_score(Ids.Ability.DEX, 18)
	a.boost(Ids.Ability.DEX)
	assert_eq(a.score(Ids.Ability.DEX), 19, "diminishing boost: +1 at 18+")


func test_flaw_subtracts_two() -> void:
	var a := AbilityScores.new()
	a.flaw(Ids.Ability.CON)
	assert_eq(a.score(Ids.Ability.CON), 8)
	assert_eq(a.modifier(Ids.Ability.CON), -1)


func test_mods_dict_has_all_six() -> void:
	var a := AbilityScores.new()
	assert_eq(a.mods().size(), 6)
