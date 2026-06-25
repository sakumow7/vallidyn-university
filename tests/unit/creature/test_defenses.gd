extends GutTest
## Derived AC, saves, DCs, and HP (spec §4.5).

const TRAINED := Ids.ProficiencyRank.TRAINED
const EXPERT := Ids.ProficiencyRank.EXPERT


func test_armor_class() -> void:
	# level 5, Dex +3, expert armor, +1 item, no dex cap.
	assert_eq(Defenses.armor_class(5, 3, EXPERT, 1), 23)   # 10 + 3 + (5+4) + 1


func test_armor_class_dex_cap() -> void:
	# Dex +4 but heavy armor caps Dex at 1.
	assert_eq(Defenses.armor_class(1, 4, TRAINED, 0, 1), 14)   # 10 + 1 + (1+2)


func test_saving_throw() -> void:
	assert_eq(Defenses.statistic(5, 2, EXPERT), 11)        # 2 + (5+4)


func test_untrained_save_is_just_ability() -> void:
	assert_eq(Defenses.statistic(10, 3, Ids.ProficiencyRank.UNTRAINED), 3, "no level when untrained")


func test_dc() -> void:
	assert_eq(Defenses.dc(5, 4, EXPERT), 23)               # 10 + 4 + (5+4)


func test_max_hp() -> void:
	# ancestry 8 + (class 10 + Con +2) × level 3.
	assert_eq(Defenses.max_hp(8, 10, 2, 3), 44)
