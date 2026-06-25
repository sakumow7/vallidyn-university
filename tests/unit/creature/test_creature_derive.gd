extends GutTest
## Creature.derive_defenses() end-to-end, plus conditions folding into saves and
## Perception (spec §4.5 meeting §4.4).

var _c: Creature


func before_each() -> void:
	# A level-5 heavy-armor fighter.
	_c = Creature.new("Fighter")
	_c.level = 5
	_c.ability_scores.set_score(Ids.Ability.STR, 18)   # +4
	_c.ability_scores.set_score(Ids.Ability.DEX, 14)   # +2
	_c.ability_scores.set_score(Ids.Ability.CON, 16)   # +3
	_c.ability_scores.set_score(Ids.Ability.WIS, 12)   # +1
	_c.proficiencies = {
		&"ac": Ids.ProficiencyRank.EXPERT,
		&"fortitude": Ids.ProficiencyRank.EXPERT,
		&"reflex": Ids.ProficiencyRank.TRAINED,
		&"will": Ids.ProficiencyRank.TRAINED,
		&"perception": Ids.ProficiencyRank.EXPERT,
	}
	_c.dex_cap = 1                # heavy armor
	_c.armor_item_bonus = 4
	_c.ancestry_hp = 8
	_c.class_hp_per_level = 10
	_c.derive_defenses()


func test_derived_ac() -> void:
	# 10 + min(2,1) + (5+4 expert) + 4 item = 24.
	assert_eq(_c.ac, 24)


func test_derived_saves() -> void:
	assert_eq(_c.saves[Ids.Save.FORTITUDE], 12, "Con +3 + (5+4)")
	assert_eq(_c.saves[Ids.Save.REFLEX], 9, "Dex +2 + (5+2)")
	assert_eq(_c.saves[Ids.Save.WILL], 8, "Wis +1 + (5+2)")


func test_derived_perception_and_hp() -> void:
	assert_eq(_c.perception, 10, "Wis +1 + (5+4)")
	assert_eq(_c.max_hp, 73, "8 + (10+3)×5")
	assert_eq(_c.hp, 73, "derive fills to full")


func test_frightened_drops_every_save() -> void:
	_c.conditions.apply(Ids.Condition.FRIGHTENED, 2)
	assert_eq(_c.save_bonus(Ids.Save.FORTITUDE), 10, "12 − 2")
	assert_eq(_c.save_bonus(Ids.Save.WILL), 6, "8 − 2")
	assert_eq(_c.perception_bonus(), 8, "10 − 2, frightened hits everything")


func test_clumsy_hits_reflex_not_will() -> void:
	_c.conditions.apply(Ids.Condition.CLUMSY, 1)
	assert_eq(_c.save_bonus(Ids.Save.REFLEX), 8, "Reflex is Dex-based: 9 − 1")
	assert_eq(_c.save_bonus(Ids.Save.WILL), 8, "Will is unaffected by clumsy")


func test_drained_hits_fortitude_only() -> void:
	_c.conditions.apply(Ids.Condition.DRAINED, 2)
	assert_eq(_c.save_bonus(Ids.Save.FORTITUDE), 10, "Fort is Con-based: 12 − 2")
	assert_eq(_c.save_bonus(Ids.Save.REFLEX), 9, "Reflex unaffected")
