extends GutTest
## Strike: attack via the universal check, MAP, hit/crit by degree, crit doubling,
## and the target's resistance — exercising conditions through the M3/M5 path
## (spec §4.1, §4.5). Damage formulas are flat ("10") so damage is deterministic and
## we can assert the doubling/mitigation exactly across random attack rolls.

const SLASHING := &"slashing"

var _rng: RandomNumberGenerator
var _attacker: Creature
var _defender: Creature


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 8675309
	_attacker = Creature.new("Hero", 18, 40)
	# Big HP so the defender survives long test loops without flooring at 0.
	_defender = Creature.new("Foe", 16, 1_000_000)


func _strike(attack_bonus: int, agile: bool = false) -> Strike:
	return Strike.new(WeaponProfile.melee(attack_bonus, "10", 0, SLASHING, agile))


func test_huge_bonus_always_hits_and_damages() -> void:
	var s := _strike(1000)
	var before := _defender.hp
	var r := s.resolve(_attacker, _defender, null, _rng)
	assert_true(r.performed)
	assert_true(r.hit)
	assert_gt(before, _defender.hp, "HP dropped")


func test_huge_penalty_always_misses() -> void:
	var s := _strike(-1000)
	var r := s.resolve(_attacker, _defender, null, _rng)
	assert_false(r.hit)
	assert_eq(r.damage, 0)
	assert_eq(_defender.hp, 1_000_000, "a miss deals no damage")


func test_damage_follows_degree_and_resistance() -> void:
	# Flat 10 damage, target resists 4. For every resolution: miss → 0; hit → 6
	# (10−4); crit → 16 (20−4). This pins crit-doubling-before-resistance exactly.
	_defender.resistances = {SLASHING: 4}
	var s := _strike(6)                       # +6 vs AC 16 → a healthy mix
	for _i: int in 300:
		var r := s.resolve(_attacker, _defender, null, _rng)
		if not r.hit:
			assert_eq(r.damage, 0)
		elif r.critical:
			assert_eq(r.damage, 16, "crit: (10×2) − 4")
		else:
			assert_eq(r.damage, 6, "hit: 10 − 4")


func test_crit_doubles_damage() -> void:
	# +1000 always lands a hit; it's a crit unless the die came up a natural 1.
	var s := _strike(1000)
	var r := s.resolve(_attacker, _defender, null, _rng)
	assert_true(r.hit)
	if r.critical:
		assert_eq(r.damage, 20, "flat 10 doubled")
	else:
		assert_eq(r.damage, 10, "natural 1 dropped the crit to a plain hit")


func test_defender_off_guard_lowers_target_ac() -> void:
	_defender.conditions.apply(Ids.Condition.OFF_GUARD)
	var r := _strike(5).resolve(_attacker, _defender, null, _rng)
	assert_eq(r.target_ac, 14, "AC 16 − 2 off-guard")


func test_attacker_conditions_apply_to_the_attack_roll() -> void:
	_attacker.conditions.apply(Ids.Condition.FRIGHTENED, 2)
	var s := _strike(9)
	var r := s.resolve(_attacker, _defender, null, _rng)
	# total = d20 + attack(+9) + MAP(0, first attack) + frightened(−2).
	assert_eq(r.attack.total, r.attack.natural + 9 - 2)


func test_enfeebled_hits_str_strike_but_clumsy_does_not() -> void:
	# A Str melee strike is STR_BASED: enfeebled applies, clumsy (Dex) doesn't.
	_attacker.conditions.apply(Ids.Condition.ENFEEBLED, 1)
	_attacker.conditions.apply(Ids.Condition.CLUMSY, 3)
	var r := _strike(9).resolve(_attacker, _defender, null, _rng)
	assert_eq(r.attack.total, r.attack.natural + 9 - 1, "only enfeebled −1 applies")


func test_map_advances_across_strikes() -> void:
	var eco := ActionEconomy.new()
	var s := _strike(5)
	var first := s.resolve(_attacker, _defender, eco, _rng)
	assert_eq(first.map_applied, 0)
	var second := s.resolve(_attacker, _defender, eco, _rng)
	assert_eq(second.map_applied, -5)
	assert_eq(eco.actions_remaining, 1, "two 1-action strikes spent")


func test_no_action_means_not_performed() -> void:
	var eco := ActionEconomy.new()
	eco.spend(3)
	var r := _strike(5).resolve(_attacker, _defender, eco, _rng)
	assert_false(r.performed)
	assert_eq(r.damage, 0)
	assert_eq(_defender.hp, 1_000_000)


func test_strike_is_a_one_action_attack() -> void:
	var s := _strike(5)
	assert_eq(s.cost_value(), 1)
	assert_true(s.has_trait(&"attack"))
