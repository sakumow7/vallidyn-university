extends GutTest
## Runtime creature: damage mitigation (immunity → weakness → resistance) and the
## conditions-aware effective AC (spec §4.5).

const FIRE := &"fire"
const SLASHING := &"slashing"


func _foe(hp: int = 50, ac: int = 16) -> Creature:
	return Creature.new("Foe", ac, hp)


func test_basic_damage_reduces_hp() -> void:
	var c := _foe(50)
	assert_eq(c.apply_damage(12, SLASHING), 12)
	assert_eq(c.hp, 38)


func test_immunity_negates() -> void:
	var c := _foe(50)
	c.immunities = [FIRE]
	assert_eq(c.apply_damage(20, FIRE), 0)
	assert_eq(c.hp, 50)


func test_resistance_reduces() -> void:
	var c := _foe(50)
	c.resistances = {FIRE: 5}
	assert_eq(c.apply_damage(12, FIRE), 7)
	assert_eq(c.hp, 43)


func test_resistance_cannot_heal() -> void:
	var c := _foe(50)
	c.resistances = {FIRE: 100}
	assert_eq(c.apply_damage(12, FIRE), 0, "damage floored at 0")
	assert_eq(c.hp, 50)


func test_weakness_increases() -> void:
	var c := _foe(50)
	c.weaknesses = {FIRE: 5}
	assert_eq(c.apply_damage(12, FIRE), 17)
	assert_eq(c.hp, 33)


func test_weakness_and_resistance_combine() -> void:
	var c := _foe(50)
	c.weaknesses = {FIRE: 5}
	c.resistances = {FIRE: 2}
	# 12 + 5 − 2 = 15.
	assert_eq(c.apply_damage(12, FIRE), 15)


func test_hp_floored_at_zero() -> void:
	var c := _foe(10)
	assert_eq(c.apply_damage(999, SLASHING), 999, "returns full mitigated amount")
	assert_eq(c.hp, 0)
	assert_false(c.is_alive())


func test_heal_caps_at_max() -> void:
	var c := _foe(50)
	c.apply_damage(30, SLASHING)
	c.heal(100)
	assert_eq(c.hp, 50)


func test_effective_ac_drops_when_off_guard() -> void:
	var c := _foe(50, 18)
	assert_eq(c.effective_ac(), 18)
	c.conditions.apply(Ids.Condition.OFF_GUARD)
	assert_eq(c.effective_ac(), 16, "off-guard: −2 circumstance to AC")


func test_effective_ac_stacks_conditions() -> void:
	var c := _foe(50, 18)
	c.conditions.apply(Ids.Condition.OFF_GUARD)        # −2 circ
	c.conditions.apply(Ids.Condition.FRIGHTENED, 2)    # −2 status
	assert_eq(c.effective_ac(), 14, "different types both apply")
