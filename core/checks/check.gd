class_name Check
extends RefCounted
## The universal d20 resolver (spec §4.2): one function behind attacks, skills,
## saves, perception, and (degenerately) flat checks. It composes [Dice] + the
## [ModifierStack] + [Degrees], rolling against an INJECTED RNG so every check is
## reproducible for tests and save-replay.
##
##   total  = d20 + ability + proficiency + Σ modifier_stack
##   degree = Degrees.resolve(total, dc, natural)
##
## Returns a fully-described [Check.Result] (natural face, total, degree, and an
## ordered component breakdown) so the combat log / ActionResult can show every
## number that fed the roll.


## A fully described check outcome. Lightweight (RefCounted) and self-printing.
class Result:
	extends RefCounted

	var natural: int = 0          ## raw d20 face, 1..20
	var total: int = 0            ## fully resolved total
	var dc: int = 0
	var degree: Ids.Degree = Ids.Degree.FAILURE
	var components: Array = []    ## ordered [{ "label": String, "value": int }]

	func is_critical_success() -> bool:
		return degree == Ids.Degree.CRITICAL_SUCCESS

	func is_success() -> bool:
		return degree >= Ids.Degree.SUCCESS

	func is_failure() -> bool:
		return degree <= Ids.Degree.FAILURE

	func is_critical_failure() -> bool:
		return degree == Ids.Degree.CRITICAL_FAILURE

	func _to_string() -> String:
		return "[d20=%d] total %d vs DC %d → %s" % [
			natural, total, dc, Ids.degree_name(degree),
		]


## Full degree-based check (attack / skill / save / perception). [param stack] may be
## null when there are no circumstance/status/item/untyped modifiers in play.
static func roll(
		dc: int,
		ability: int,
		proficiency: int,
		stack: ModifierStack,
		rng: RandomNumberGenerator) -> Result:
	var natural := Dice.d20(rng)
	var res := Result.new()
	res.natural = natural
	res.dc = dc
	res.components.append({"label": "d20", "value": natural})
	if ability != 0:
		res.components.append({"label": "ability", "value": ability})
	if proficiency != 0:
		res.components.append({"label": "proficiency", "value": proficiency})

	var stack_total := 0
	if stack != null:
		stack_total = stack.total()
		for m: Modifier in stack.applied():
			res.components.append({"label": String(m.source), "value": m.value})

	res.total = natural + ability + proficiency + stack_total
	res.degree = Degrees.resolve(res.total, dc, natural)
	return res


## Flat check (spec §4.2): roll d20 vs DC, success on ≥ DC. Flat checks have no
## degrees of success and no natural-1/20 swing — they can't crit. Returns true on
## success. [param bonus] covers the rare flat-check modifier (e.g. some feats).
static func flat(dc: int, rng: RandomNumberGenerator, bonus: int = 0) -> bool:
	return Dice.d20(rng) + bonus >= dc
