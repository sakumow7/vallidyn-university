extends GutTest
## Conditions engine (spec §4.4): effects, interaction through the M3 stack,
## implications, valued stacking, and end-of-turn decrement / expiry.

# Common roll/defense contexts (the tag sets M4/M6 will produce).
const AC := [Ids.StatTag.AC, Ids.StatTag.DEX_BASED]
const REFLEX := [Ids.StatTag.SAVE, Ids.StatTag.REFLEX, Ids.StatTag.DEX_BASED]
const WILL := [Ids.StatTag.SAVE, Ids.StatTag.WILL, Ids.StatTag.WIS_BASED]
const FORT := [Ids.StatTag.SAVE, Ids.StatTag.FORTITUDE, Ids.StatTag.CON_BASED]
const PERCEPTION := [Ids.StatTag.PERCEPTION, Ids.StatTag.WIS_BASED]
const MELEE_STR := [Ids.StatTag.ATTACK, Ids.StatTag.MELEE, Ids.StatTag.STR_BASED]
const ATHLETICS := [Ids.StatTag.SKILL, Ids.StatTag.STR_BASED]
const ACROBATICS := [Ids.StatTag.SKILL, Ids.StatTag.DEX_BASED]
const SPELL_DC := [Ids.StatTag.SPELL_DC]

var _c: ConditionEngine


func before_each() -> void:
	_c = ConditionEngine.new()


# Sum the condition modifiers for a context through a real ModifierStack, so we
# exercise the exact stacking path the engine uses in play.
func _total(context: Array) -> int:
	var s := ModifierStack.new()
	s.add_all(_c.modifiers_for(context))
	return s.total()


# ── application / stacking / values ──────────────────────────────────────────

func test_apply_and_has() -> void:
	_c.apply(Ids.Condition.PRONE)
	assert_true(_c.has(Ids.Condition.PRONE))
	assert_false(_c.has(Ids.Condition.BLINDED))


func test_valued_defaults_to_one() -> void:
	_c.apply(Ids.Condition.FRIGHTENED)        # no value given
	assert_eq(_c.value_of(Ids.Condition.FRIGHTENED), 1)


func test_stacking_takes_highest_value() -> void:
	_c.apply(Ids.Condition.FRIGHTENED, 1)
	_c.apply(Ids.Condition.FRIGHTENED, 3)
	_c.apply(Ids.Condition.FRIGHTENED, 2)
	assert_eq(_c.value_of(Ids.Condition.FRIGHTENED), 3, "re-apply keeps the highest")


func test_dying_capped_at_four() -> void:
	_c.apply(Ids.Condition.DYING, 99)
	assert_eq(_c.value_of(Ids.Condition.DYING), 4)


func test_remove_and_clear() -> void:
	_c.apply(Ids.Condition.OFF_GUARD)
	assert_true(_c.remove(Ids.Condition.OFF_GUARD))
	assert_false(_c.remove(Ids.Condition.OFF_GUARD), "removing absent → false")
	_c.apply(Ids.Condition.BLINDED)
	_c.clear()
	assert_eq(_c.size(), 0)


# ── individual effects ───────────────────────────────────────────────────────

func test_off_guard_is_circumstance_ac_only() -> void:
	_c.apply(Ids.Condition.OFF_GUARD)
	assert_eq(_total(AC), -2)
	assert_eq(_total(REFLEX), 0, "off-guard hits AC, not Reflex")


func test_frightened_hits_everything() -> void:
	_c.apply(Ids.Condition.FRIGHTENED, 2)
	assert_eq(_total(AC), -2)
	assert_eq(_total(WILL), -2)
	assert_eq(_total(MELEE_STR), -2)
	assert_eq(_total(PERCEPTION), -2)


func test_clumsy_only_dex_based() -> void:
	_c.apply(Ids.Condition.CLUMSY, 2)
	assert_eq(_total(AC), -2, "AC is Dex-based")
	assert_eq(_total(REFLEX), -2, "Reflex is Dex-based")
	assert_eq(_total(ACROBATICS), -2)
	assert_eq(_total(WILL), 0, "Will is not Dex-based")
	assert_eq(_total(FORT), 0)


func test_enfeebled_only_str_based() -> void:
	_c.apply(Ids.Condition.ENFEEBLED, 3)
	assert_eq(_total(MELEE_STR), -3)
	assert_eq(_total(ATHLETICS), -3)
	assert_eq(_total(ACROBATICS), 0, "Acrobatics is Dex-based, not Str")


func test_stupefied_mental_and_spellcasting() -> void:
	_c.apply(Ids.Condition.STUPEFIED, 2)
	assert_eq(_total(WILL), -2, "Will is Wis-based")
	assert_eq(_total(PERCEPTION), -2, "Perception is Wis-based")
	assert_eq(_total(SPELL_DC), -2)
	assert_eq(_total(REFLEX), 0, "Reflex is Dex-based, unaffected")
	assert_eq(_total(FORT), 0, "Fortitude is Con-based, unaffected")


func test_drained_con_only() -> void:
	_c.apply(Ids.Condition.DRAINED, 2)
	assert_eq(_total(FORT), -2)
	assert_eq(_total(REFLEX), 0)


func test_fatigued_ac_and_saves() -> void:
	_c.apply(Ids.Condition.FATIGUED)
	assert_eq(_total(AC), -1)
	assert_eq(_total(REFLEX), -1)
	assert_eq(_total(WILL), -1)
	assert_eq(_total(MELEE_STR), 0, "fatigued doesn't penalize attacks")


func test_blinded_and_deafened_perception() -> void:
	_c.apply(Ids.Condition.BLINDED)
	assert_eq(_total(PERCEPTION), -4)
	_c.clear()
	_c.apply(Ids.Condition.DEAFENED)
	assert_eq(_total(PERCEPTION), -2)


# ── interaction through the stack (the payoff of reusing M3) ──────────────────

func test_different_types_both_apply() -> void:
	# frightened (status) + off-guard (circumstance) on AC → −4, both apply.
	_c.apply(Ids.Condition.FRIGHTENED, 2)
	_c.apply(Ids.Condition.OFF_GUARD)
	assert_eq(_total(AC), -4)


func test_same_type_status_penalties_take_worst() -> void:
	# frightened 2 + stupefied 1, both status, on a Will save → worst is −2.
	_c.apply(Ids.Condition.FRIGHTENED, 2)
	_c.apply(Ids.Condition.STUPEFIED, 1)
	assert_eq(_total(WILL), -2, "status penalties don't stack — take the worst")


# ── implications ─────────────────────────────────────────────────────────────

func test_prone_implies_off_guard() -> void:
	_c.apply(Ids.Condition.PRONE)
	assert_true(_c.is_affected_by(Ids.Condition.OFF_GUARD))
	assert_false(_c.has(Ids.Condition.OFF_GUARD), "implied, not directly applied")
	# AC gets off-guard's −2 circ; the prone creature's own attacks get −2 circ.
	assert_eq(_total(AC), -2)
	assert_eq(_total(MELEE_STR), -2)


func test_unconscious_chains_implications() -> void:
	_c.apply(Ids.Condition.UNCONSCIOUS)
	assert_true(_c.is_affected_by(Ids.Condition.BLINDED))
	assert_true(_c.is_affected_by(Ids.Condition.OFF_GUARD))
	assert_true(_c.is_affected_by(Ids.Condition.PRONE))
	# AC: unconscious −4 status + off-guard −2 circ = −6.
	assert_eq(_total(AC), -6)


func test_grabbed_implies_off_guard_and_immobilized() -> void:
	_c.apply(Ids.Condition.GRABBED)
	assert_true(_c.is_affected_by(Ids.Condition.OFF_GUARD))
	assert_true(_c.is_affected_by(Ids.Condition.IMMOBILIZED))
	assert_eq(_total(AC), -2)


func test_effective_conditions_dedup() -> void:
	# unconscious → prone → off-guard; off-guard must appear once.
	_c.apply(Ids.Condition.UNCONSCIOUS)
	var eff := _c.effective_conditions()
	var off_guard_count := 0
	for id: int in eff:
		if id == Ids.Condition.OFF_GUARD:
			off_guard_count += 1
	assert_eq(off_guard_count, 1)


# ── expiry / upkeep ──────────────────────────────────────────────────────────

func test_frightened_decrements_each_turn() -> void:
	_c.apply(Ids.Condition.FRIGHTENED, 2)
	_c.tick_end_of_turn()
	assert_eq(_c.value_of(Ids.Condition.FRIGHTENED), 1)
	var removed := _c.tick_end_of_turn()
	assert_false(_c.has(Ids.Condition.FRIGHTENED), "removed when it hits 0")
	assert_true(removed.has(Ids.Condition.FRIGHTENED))


func test_sickened_does_not_auto_decrement() -> void:
	_c.apply(Ids.Condition.SICKENED, 2)
	_c.tick_end_of_turn()
	assert_eq(_c.value_of(Ids.Condition.SICKENED), 2, "sickened isn't reduced at end of turn")


func test_finite_duration_expires() -> void:
	_c.apply(Ids.Condition.OFF_GUARD, 0, &"feint", 1)   # 1 round
	var removed := _c.tick_end_of_turn()
	assert_false(_c.has(Ids.Condition.OFF_GUARD))
	assert_true(removed.has(Ids.Condition.OFF_GUARD))


func test_indefinite_duration_persists() -> void:
	_c.apply(Ids.Condition.OFF_GUARD)                   # default -1 = indefinite
	_c.tick_end_of_turn()
	_c.tick_end_of_turn()
	assert_true(_c.has(Ids.Condition.OFF_GUARD))


func test_longer_duration_wins_on_reapply() -> void:
	_c.apply(Ids.Condition.SLOWED, 1, &"a", 2)
	_c.apply(Ids.Condition.SLOWED, 1, &"b", -1)          # indefinite outlasts finite
	var inst := _c.get_instance(Ids.Condition.SLOWED)
	assert_true(inst.is_indefinite())


# ── identity helpers ─────────────────────────────────────────────────────────

func test_slug_and_display_name() -> void:
	assert_eq(ConditionEngine.slug(Ids.Condition.OFF_GUARD), &"off-guard")
	assert_eq(ConditionEngine.display_name(Ids.Condition.OFF_GUARD), "Off Guard")
	assert_eq(ConditionEngine.slug(Ids.Condition.FRIGHTENED), &"frightened")


func test_from_slug_roundtrips() -> void:
	assert_eq(ConditionEngine.from_slug(&"off-guard"), Ids.Condition.OFF_GUARD)
	assert_eq(ConditionEngine.from_slug(&"frightened"), Ids.Condition.FRIGHTENED)
	assert_eq(ConditionEngine.from_slug(&"not-a-condition"), -1)


func test_instance_to_string_shows_value() -> void:
	_c.apply(Ids.Condition.FRIGHTENED, 3)
	assert_eq(str(_c.get_instance(Ids.Condition.FRIGHTENED)), "Frightened 3")
	_c.apply(Ids.Condition.PRONE)
	assert_eq(str(_c.get_instance(Ids.Condition.PRONE)), "Prone", "binary → no value")
