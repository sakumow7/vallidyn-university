extends GutTest
## Proficiency = level + rank, EXCEPT untrained which adds nothing (spec §4.5).


func test_untrained_adds_nothing() -> void:
	assert_eq(Proficiency.bonus(Ids.ProficiencyRank.UNTRAINED, 5), 0, "not even level")
	assert_eq(Proficiency.bonus(Ids.ProficiencyRank.UNTRAINED, 20), 0)


func test_trained_adds_level_plus_two() -> void:
	assert_eq(Proficiency.bonus(Ids.ProficiencyRank.TRAINED, 5), 7)


func test_rank_bonuses() -> void:
	assert_eq(Proficiency.bonus(Ids.ProficiencyRank.TRAINED, 1), 3)     # 1 + 2
	assert_eq(Proficiency.bonus(Ids.ProficiencyRank.EXPERT, 1), 5)      # 1 + 4
	assert_eq(Proficiency.bonus(Ids.ProficiencyRank.MASTER, 1), 7)      # 1 + 6
	assert_eq(Proficiency.bonus(Ids.ProficiencyRank.LEGENDARY, 20), 28) # 20 + 8


func test_is_trained() -> void:
	assert_false(Proficiency.is_trained(Ids.ProficiencyRank.UNTRAINED))
	assert_true(Proficiency.is_trained(Ids.ProficiencyRank.TRAINED))
	assert_true(Proficiency.is_trained(Ids.ProficiencyRank.LEGENDARY))
