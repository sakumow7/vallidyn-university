class_name ModifierStack
extends RefCounted
## Resolves a list of [Modifier]s into a single net value following PF2e stacking
## (spec §4.3) — the part "everyone gets wrong", so it is resolved in one place and
## tested hard:
##
##   • circumstance / status / item / difficulty are TYPED: same-type bonuses don't
##     stack (take the single highest), same-type penalties don't stack (take the
##     single worst). The best bonus and worst penalty of a type BOTH apply.
##   • untyped modifiers all stack (sum everything, bonuses and penalties).
##   • disabled or zero-valued modifiers are ignored.
##
## [method applied] exposes exactly which modifiers survived stacking, so the combat
## log can show "+2 circumstance (flanking)" and not the suppressed "+1" — and so the
## tests can assert on the winners, not just the net total.

var _modifiers: Array[Modifier] = []


func add(m: Modifier) -> void:
	_modifiers.append(m)


func add_all(mods: Array[Modifier]) -> void:
	_modifiers.append_array(mods)


func clear() -> void:
	_modifiers.clear()


func size() -> int:
	return _modifiers.size()


## A copy of every modifier added (including suppressed/disabled ones).
func modifiers() -> Array[Modifier]:
	return _modifiers.duplicate()


## Net resolved value of all enabled modifiers after stacking.
func total() -> int:
	var sum := 0
	for m: Modifier in applied():
		sum += m.value
	return sum


## The modifiers that actually contribute, after stacking resolution. Untyped
## modifiers come first (insertion order), then the winning bonus/penalty of each
## typed bucket. Suppressed and disabled modifiers are excluded.
func applied() -> Array[Modifier]:
	var untyped: Array[Modifier] = []
	# ModifierType -> { "bonus": Modifier, "penalty": Modifier }
	var best: Dictionary = {}

	for m: Modifier in _modifiers:
		if not m.enabled or m.value == 0:
			continue
		if Ids.modifier_type_stacks(m.type):
			untyped.append(m)
			continue
		var bucket: Dictionary = best.get(m.type, {})
		if m.value > 0:
			var cur_bonus: Modifier = bucket.get("bonus", null)
			if cur_bonus == null or m.value > cur_bonus.value:
				bucket["bonus"] = m
		else:
			var cur_penalty: Modifier = bucket.get("penalty", null)
			if cur_penalty == null or m.value < cur_penalty.value:
				bucket["penalty"] = m
		best[m.type] = bucket

	var result: Array[Modifier] = []
	result.append_array(untyped)
	for mtype: Variant in best:
		var bucket: Dictionary = best[mtype]
		if bucket.has("bonus"):
			var b: Modifier = bucket["bonus"]
			result.append(b)
		if bucket.has("penalty"):
			var p: Modifier = bucket["penalty"]
			result.append(p)
	return result
