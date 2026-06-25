extends GutTest
## Dice parsing and rolling against an injected, seeded RNG (spec §2, §11.2).

var _rng: RandomNumberGenerator


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 12345


func test_parse_simple() -> void:
	var p := Dice.parse("2d6+3")
	assert_true(bool(p["valid"]), "2d6+3 should parse")
	assert_eq(int(p["flat"]), 3)
	var dice: Array[Vector2i] = p["dice"]
	assert_eq(dice.size(), 1)
	assert_eq(dice[0], Vector2i(2, 6))


func test_parse_implicit_count() -> void:
	var p := Dice.parse("d20")
	assert_true(bool(p["valid"]))
	var dice: Array[Vector2i] = p["dice"]
	assert_eq(dice[0], Vector2i(1, 20))
	assert_eq(int(p["flat"]), 0)


func test_parse_multi_term_and_negative() -> void:
	var p := Dice.parse("2d6+1d4-1")
	assert_true(bool(p["valid"]))
	assert_eq(int(p["flat"]), -1)
	var dice: Array[Vector2i] = p["dice"]
	assert_eq(dice.size(), 2)
	assert_eq(dice[0], Vector2i(2, 6))
	assert_eq(dice[1], Vector2i(1, 4))


func test_parse_whitespace_ignored() -> void:
	assert_true(bool(Dice.parse(" 1d8 + 2 ")["valid"]))


func test_parse_rejects_garbage() -> void:
	assert_false(bool(Dice.parse("2x6")["valid"]), "2x6 is not a dice expr")
	assert_false(bool(Dice.parse("")["valid"]), "empty is invalid")
	assert_false(bool(Dice.parse("d")["valid"]), "d with no sides is invalid")
	assert_false(bool(Dice.parse("2d6 junk")["valid"]), "trailing junk is invalid")


func test_die_in_range() -> void:
	for _i: int in 200:
		assert_between(Dice.die(6, _rng), 1, 6)


func test_d20_in_range() -> void:
	for _i: int in 200:
		assert_between(Dice.d20(_rng), 1, 20)


func test_roll_total_within_bounds() -> void:
	for _i: int in 50:
		var r := Dice.roll("3d6+2", _rng)
		assert_true(r.valid)
		assert_between(r.total, 5, 20)   # (3..18) + 2
		assert_eq(r.faces.size(), 3)


func test_roll_flat_only() -> void:
	var r := Dice.roll("5", _rng)
	assert_true(r.valid)
	assert_eq(r.total, 5)
	assert_eq(r.faces.size(), 0)


func test_roll_subtracted_dice() -> void:
	# 10 - 1d4 → between 6 and 9.
	for _i: int in 50:
		var r := Dice.roll("10-1d4", _rng)
		assert_between(r.total, 6, 9)


func test_roll_is_deterministic_for_seed() -> void:
	var a := RandomNumberGenerator.new()
	a.seed = 999
	var b := RandomNumberGenerator.new()
	b.seed = 999
	assert_eq(Dice.roll("4d8+1", a).total, Dice.roll("4d8+1", b).total)


func test_roll_invalid_expr_is_marked() -> void:
	var r := Dice.roll("nonsense", _rng)
	assert_false(r.valid)
	assert_eq(r.total, 0)
	# roll() pushes an error on bad data (so real content bugs are loud). Assert it
	# fired — this also marks the expected error handled so the test doesn't fail.
	assert_push_error("cannot parse")
