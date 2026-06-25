extends GutTest
## PF2e modifier stacking (spec §4.3) — "the part everyone gets wrong", so it gets
## the hardest tests.

const CIRCUMSTANCE := Ids.ModifierType.CIRCUMSTANCE
const STATUS := Ids.ModifierType.STATUS
const ITEM := Ids.ModifierType.ITEM
const UNTYPED := Ids.ModifierType.UNTYPED
const DIFFICULTY := Ids.ModifierType.DIFFICULTY


func _m(value: int, type: Ids.ModifierType, source: StringName = &"src") -> Modifier:
	return Modifier.new(value, type, source)


func test_same_type_bonuses_take_highest() -> void:
	var s := ModifierStack.new()
	s.add(_m(1, CIRCUMSTANCE))
	s.add(_m(2, CIRCUMSTANCE))
	assert_eq(s.total(), 2, "two circumstance bonuses → take the highest")


func test_same_type_penalties_take_worst() -> void:
	var s := ModifierStack.new()
	s.add(_m(-1, STATUS))
	s.add(_m(-2, STATUS))
	assert_eq(s.total(), -2, "two status penalties → take the worst")


func test_bonus_and_penalty_same_type_both_apply() -> void:
	var s := ModifierStack.new()
	s.add(_m(2, CIRCUMSTANCE))
	s.add(_m(-1, CIRCUMSTANCE))
	assert_eq(s.total(), 1, "best bonus and worst penalty of a type both apply")


func test_different_typed_bonuses_stack() -> void:
	var s := ModifierStack.new()
	s.add(_m(1, CIRCUMSTANCE))
	s.add(_m(1, STATUS))
	s.add(_m(1, ITEM))
	assert_eq(s.total(), 3, "different types stack with each other")


func test_untyped_penalties_stack() -> void:
	var s := ModifierStack.new()
	s.add(_m(-1, UNTYPED))
	s.add(_m(-1, UNTYPED))
	assert_eq(s.total(), -2, "untyped penalties DO stack")


func test_untyped_bonuses_stack() -> void:
	var s := ModifierStack.new()
	s.add(_m(1, UNTYPED))
	s.add(_m(2, UNTYPED))
	assert_eq(s.total(), 3, "untyped bonuses stack too")


func test_disabled_modifier_ignored() -> void:
	var s := ModifierStack.new()
	var m := _m(5, ITEM)
	m.enabled = false
	s.add(m)
	assert_eq(s.total(), 0, "disabled modifiers contribute nothing")


func test_zero_value_ignored() -> void:
	var s := ModifierStack.new()
	s.add(_m(0, ITEM))
	assert_eq(s.applied().size(), 0, "zero-valued modifiers are dropped")


func test_difficulty_is_typed_bucket() -> void:
	var s := ModifierStack.new()
	s.add(_m(2, DIFFICULTY))
	s.add(_m(1, DIFFICULTY))
	assert_eq(s.total(), 2, "difficulty modifiers take-highest like other typed bonuses")


func test_mixed_realistic_scenario() -> void:
	# bless (+1 status), flank (+2 circ) vs difficult terrain (−1 circ),
	# magic weapon (+1 item), two untyped penalties (−1, −1).
	var s := ModifierStack.new()
	s.add(_m(1, STATUS, &"bless"))
	s.add(_m(2, CIRCUMSTANCE, &"flank"))
	s.add(_m(-1, CIRCUMSTANCE, &"difficult terrain"))
	s.add(_m(1, ITEM, &"magic weapon"))
	s.add(_m(-1, UNTYPED, &"penalty a"))
	s.add(_m(-1, UNTYPED, &"penalty b"))
	# 1 + (2 − 1) + 1 + (−1 − 1) = 1
	assert_eq(s.total(), 1)


func test_applied_lists_winners_only() -> void:
	var s := ModifierStack.new()
	s.add(_m(1, CIRCUMSTANCE, &"low"))
	s.add(_m(2, CIRCUMSTANCE, &"high"))
	var applied := s.applied()
	assert_eq(applied.size(), 1, "only the winning circumstance bonus survives")
	assert_eq(applied[0].source, &"high")


func test_applied_keeps_both_bonus_and_penalty() -> void:
	var s := ModifierStack.new()
	s.add(_m(2, CIRCUMSTANCE, &"up"))
	s.add(_m(-1, CIRCUMSTANCE, &"down"))
	assert_eq(s.applied().size(), 2, "best bonus and worst penalty both appear in the log")


func test_clear_and_size() -> void:
	var s := ModifierStack.new()
	s.add(_m(1, ITEM))
	s.add(_m(1, STATUS))
	assert_eq(s.size(), 2)
	s.clear()
	assert_eq(s.size(), 0)
	assert_eq(s.total(), 0)
