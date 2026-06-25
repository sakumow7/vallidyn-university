class_name ConditionEngine
extends RefCounted
## Owns a creature's conditions (spec §4.4): application, take-highest-value
## stacking, implications, duration/expiry, and — the key job — emitting the
## [Modifier]s that conditions impose, filtered to whatever is being rolled.
##
## A creature owns one ConditionEngine. The class has two halves:
##   • STATIC rules registry — valued?, max, decrement, implications, and the
##     modifier each condition emits. This is rules data (fixed by PF2e), so it
##     lives in code, not in importable .tres.
##   • INSTANCE state — the set of active [ConditionInstance]s on this creature.
##
## Effects are emitted as plain [Modifier]s and resolved by [ModifierStack], so
## conditions interact for free: a frightened −2 status and a stupefied −1 status
## on the same Will save don't stack (the stack takes the worst), while a status
## penalty and a circumstance penalty both apply.


# ─────────────────────────────────────────────────────────────────────────────
# Instance state
# ─────────────────────────────────────────────────────────────────────────────

# Ids.Condition (int) -> ConditionInstance. At most one instance per condition.
var _conditions: Dictionary = {}


## Apply (or merge) a condition. Valued conditions clamp to ≥1 and to their max.
## Re-applying takes the highest value (spec §4.4) and the longer duration.
func apply(
		id: Ids.Condition,
		value: int = 0,
		source: StringName = &"",
		duration_rounds: int = -1) -> void:
	var v := 0
	if is_valued(id):
		v = maxi(value, 1)
		var mx := max_value(id)
		if mx > 0:
			v = mini(v, mx)
	if _conditions.has(id):
		var inst: ConditionInstance = _conditions[id]
		if v > inst.value:
			inst.value = v
			inst.source = source
		inst.duration_rounds = _longer(inst.duration_rounds, duration_rounds)
	else:
		_conditions[id] = ConditionInstance.new(id, v, source, duration_rounds)


## Remove a condition outright. Returns true if it was present.
func remove(id: Ids.Condition) -> bool:
	return _conditions.erase(id)


func clear() -> void:
	_conditions.clear()


## True if this condition is directly applied (ignoring implications).
func has(id: Ids.Condition) -> bool:
	return _conditions.has(id)


## True if directly applied OR implied by another active condition
## (e.g. grabbed makes is_affected_by(OFF_GUARD) true).
func is_affected_by(id: Ids.Condition) -> bool:
	return effective_conditions().has(id)


## Current value of a condition (0 if absent or binary).
func value_of(id: Ids.Condition) -> int:
	if _conditions.has(id):
		return (_conditions[id] as ConditionInstance).value
	return 0


func get_instance(id: Ids.Condition) -> ConditionInstance:
	return _conditions.get(id, null)


func size() -> int:
	return _conditions.size()


## Directly-applied condition ids (no implications).
func active_ids() -> Array:
	return _conditions.keys()


## Directly-applied instances (no implications).
func active() -> Array[ConditionInstance]:
	var out: Array[ConditionInstance] = []
	for id: int in _conditions:
		var inst: ConditionInstance = _conditions[id]
		out.append(inst)
	return out


## All conditions in effect: directly applied plus everything they imply,
## transitively, deduplicated (e.g. unconscious → blinded, off-guard, prone).
func effective_conditions() -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	var pending: Array = _conditions.keys()
	while not pending.is_empty():
		var id: int = pending.pop_back()
		if seen.has(id):
			continue
		seen[id] = true
		result.append(id)
		for implied: int in implies(id):
			if not seen.has(implied):
				pending.push_back(implied)
	return result


## The modifiers every active/implied condition imposes on a roll or statistic
## described by [param context] (a set of [enum Ids.StatTag]). Add these to a
## [ModifierStack] to resolve them against everything else.
func modifiers_for(context: Array) -> Array[Modifier]:
	var out: Array[Modifier] = []
	for id: int in effective_conditions():
		var spec := _mod_spec(id)
		if spec == null:
			continue
		if not _applies(spec.tags, context):
			continue
		var mod_value := spec.fixed if not spec.per_value else -value_of(id)
		if mod_value == 0:
			continue
		out.append(Modifier.new(mod_value, spec.type, slug(id)))
	return out


## End-of-turn upkeep: frightened (and any auto-decrementing condition) loses 1
## value; finite durations count down. Returns the ids removed this tick.
func tick_end_of_turn() -> Array:
	var removed: Array = []
	for id: int in _conditions.keys():
		var inst: ConditionInstance = _conditions[id]
		var expired := false
		if auto_decrements_at_end_of_turn(id):
			inst.value -= 1
			if inst.value <= 0:
				expired = true
		if not expired and inst.duration_rounds > 0:
			inst.duration_rounds -= 1
			if inst.duration_rounds == 0:
				expired = true
		if expired:
			_conditions.erase(id)
			removed.append(id)
	return removed


func _longer(a: int, b: int) -> int:
	if a < 0 or b < 0:    # indefinite (-1) outlasts any finite duration
		return -1
	return maxi(a, b)


# ─────────────────────────────────────────────────────────────────────────────
# Static rules registry (PF2e-fixed mechanics)
# ─────────────────────────────────────────────────────────────────────────────

## The modifier a condition emits, plus what it applies to. Returned by
## [method _mod_spec]; null when a condition imposes no flat roll modifier (its
## effects are structural — senses, action economy, death spiral — and realized
## by the consuming milestones).
class ModSpec:
	extends RefCounted
	var type: Ids.ModifierType
	var tags: Array            ## Array[Ids.StatTag]; empty = wildcard (all checks/DCs)
	var fixed: int             ## modifier value when per_value is false
	var per_value: bool        ## true → value is −(condition value), e.g. frightened N

	func _init(p_type: Ids.ModifierType, p_tags: Array, p_fixed: int, p_per_value: bool) -> void:
		type = p_type
		tags = p_tags
		fixed = p_fixed
		per_value = p_per_value


static func is_valued(id: Ids.Condition) -> bool:
	match id:
		Ids.Condition.CLUMSY, Ids.Condition.DOOMED, Ids.Condition.DRAINED, \
		Ids.Condition.DYING, Ids.Condition.ENFEEBLED, Ids.Condition.FRIGHTENED, \
		Ids.Condition.SICKENED, Ids.Condition.SLOWED, Ids.Condition.STUNNED, \
		Ids.Condition.STUPEFIED, Ids.Condition.WOUNDED:
			return true
	return false


## Upper bound on a valued condition (0 = uncapped). Dying maxes at 4 (death).
static func max_value(id: Ids.Condition) -> int:
	if id == Ids.Condition.DYING:
		return 4
	return 0


## Only frightened auto-decreases its value at the end of the bearer's turn by
## default. Sickened is reduced by retching, stunned by lost actions, etc. — those
## are driven elsewhere.
static func auto_decrements_at_end_of_turn(id: Ids.Condition) -> bool:
	return id == Ids.Condition.FRIGHTENED


## Conditions implied by a condition (it confers their effects too).
static func implies(id: Ids.Condition) -> Array:
	match id:
		Ids.Condition.PRONE:
			return [Ids.Condition.OFF_GUARD]
		Ids.Condition.GRABBED, Ids.Condition.RESTRAINED:
			return [Ids.Condition.OFF_GUARD, Ids.Condition.IMMOBILIZED]
		Ids.Condition.UNCONSCIOUS:
			return [Ids.Condition.BLINDED, Ids.Condition.OFF_GUARD, Ids.Condition.PRONE]
		Ids.Condition.PARALYZED, Ids.Condition.PETRIFIED, Ids.Condition.CONFUSED:
			return [Ids.Condition.OFF_GUARD]
	return []


## Stable lowercase-hyphen slug (matches Foundry: OFF_GUARD → "off-guard").
static func slug(id: Ids.Condition) -> StringName:
	return StringName((Ids.Condition.keys()[id] as String).to_lower().replace("_", "-"))


## Title-case display name for the log/UI (OFF_GUARD → "Off Guard").
static func display_name(id: Ids.Condition) -> String:
	return (Ids.Condition.keys()[id] as String).capitalize()


## Resolve a slug back to its enum id, or -1 if unknown (for the importer).
static func from_slug(s: StringName) -> int:
	var keys: Array = Ids.Condition.keys()
	for i: int in keys.size():
		if StringName((keys[i] as String).to_lower().replace("_", "-")) == s:
			return i
	return -1


## The flat roll modifier a condition imposes, or null if it imposes none.
## Penalty values are negative. See ModSpec for the tag/value model.
static func _mod_spec(id: Ids.Condition) -> ModSpec:
	match id:
		Ids.Condition.OFF_GUARD:
			return ModSpec.new(Ids.ModifierType.CIRCUMSTANCE, [Ids.StatTag.AC], -2, false)
		Ids.Condition.FRIGHTENED, Ids.Condition.SICKENED:
			# −N status to ALL checks and DCs (wildcard = empty tags).
			return ModSpec.new(Ids.ModifierType.STATUS, [], 0, true)
		Ids.Condition.CLUMSY:
			return ModSpec.new(Ids.ModifierType.STATUS, [Ids.StatTag.DEX_BASED], 0, true)
		Ids.Condition.ENFEEBLED:
			return ModSpec.new(Ids.ModifierType.STATUS, [Ids.StatTag.STR_BASED], 0, true)
		Ids.Condition.STUPEFIED:
			# Int/Wis/Cha-based checks & DCs, plus spell attacks and spell DCs.
			return ModSpec.new(Ids.ModifierType.STATUS, [
				Ids.StatTag.INT_BASED, Ids.StatTag.WIS_BASED, Ids.StatTag.CHA_BASED,
				Ids.StatTag.SPELL_ATTACK, Ids.StatTag.SPELL_DC,
			], 0, true)
		Ids.Condition.DRAINED:
			# Con-based checks (Fortitude). HP reduction is handled at M4 (needs level).
			return ModSpec.new(Ids.ModifierType.STATUS, [Ids.StatTag.CON_BASED], 0, true)
		Ids.Condition.FATIGUED:
			return ModSpec.new(Ids.ModifierType.STATUS, [Ids.StatTag.AC, Ids.StatTag.SAVE], -1, false)
		Ids.Condition.PRONE:
			# −2 circ to the prone creature's own attack rolls (off-guard, implied,
			# covers the AC side).
			return ModSpec.new(Ids.ModifierType.CIRCUMSTANCE, [Ids.StatTag.ATTACK], -2, false)
		Ids.Condition.UNCONSCIOUS:
			return ModSpec.new(Ids.ModifierType.STATUS, [
				Ids.StatTag.AC, Ids.StatTag.PERCEPTION, Ids.StatTag.REFLEX,
			], -4, false)
		Ids.Condition.BLINDED:
			return ModSpec.new(Ids.ModifierType.STATUS, [Ids.StatTag.PERCEPTION], -4, false)
		Ids.Condition.DEAFENED:
			return ModSpec.new(Ids.ModifierType.STATUS, [Ids.StatTag.PERCEPTION], -2, false)
		Ids.Condition.FASCINATED:
			return ModSpec.new(Ids.ModifierType.STATUS, [Ids.StatTag.PERCEPTION, Ids.StatTag.SKILL], -2, false)
		Ids.Condition.ENCUMBERED:
			# Encumbered grants clumsy 1 (−1 status to Dex-based). Speed hit is M7.
			return ModSpec.new(Ids.ModifierType.STATUS, [Ids.StatTag.DEX_BASED], -1, false)
	return null


## A condition applies to a context if it is a wildcard (empty tags) or shares at
## least one tag with the context.
static func _applies(tags: Array, context: Array) -> bool:
	if tags.is_empty():
		return true
	for t: int in tags:
		if context.has(t):
			return true
	return false
