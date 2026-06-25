class_name Degrees
extends RefCounted
## Degree-of-success resolution (spec §4.2). Pure and deterministic — it takes an
## already-rolled total plus the raw natural d20 face and returns a [enum Ids.Degree].
## No RNG lives here; rolling happens in [Dice] / [Check].
##
## Remastered order of operations:
##   1. Band the total against the DC (≥DC+10 crit-succ, ≥DC succ, ≤DC−10 crit-fail).
##   2. THEN apply the natural-20 bump-up / natural-1 bump-down by one step.
## Doing it in this order means a nat-20 that only "succeeds" becomes a crit, and a
## nat-1 that would crit-succeed drops to a plain success — exactly the rules text.


## Resolve a check to a degree. [param natural] is the raw d20 face (1..20); pass 0
## to skip the nat-1/nat-20 adjustment (used by flat checks and non-d20 resolutions).
static func resolve(total: int, dc: int, natural: int = 0) -> Ids.Degree:
	var degree := band(total, dc)
	if natural == 20:
		degree = bump_up(degree)
	elif natural == 1:
		degree = bump_down(degree)
	return degree


## The DC comparison only — no natural-roll adjustment.
static func band(total: int, dc: int) -> Ids.Degree:
	if total >= dc + 10:
		return Ids.Degree.CRITICAL_SUCCESS
	if total >= dc:
		return Ids.Degree.SUCCESS
	if total <= dc - 10:
		return Ids.Degree.CRITICAL_FAILURE
	return Ids.Degree.FAILURE


## Raise a degree by one step, clamped at critical success. Explicit mapping (not
## enum arithmetic) keeps the return strictly typed with no int→enum cast.
static func bump_up(degree: Ids.Degree) -> Ids.Degree:
	match degree:
		Ids.Degree.CRITICAL_FAILURE:
			return Ids.Degree.FAILURE
		Ids.Degree.FAILURE:
			return Ids.Degree.SUCCESS
		_:
			return Ids.Degree.CRITICAL_SUCCESS


## Lower a degree by one step, clamped at critical failure.
static func bump_down(degree: Ids.Degree) -> Ids.Degree:
	match degree:
		Ids.Degree.CRITICAL_SUCCESS:
			return Ids.Degree.SUCCESS
		Ids.Degree.SUCCESS:
			return Ids.Degree.FAILURE
		_:
			return Ids.Degree.CRITICAL_FAILURE


## True if the degree is a success or critical success.
static func is_success(degree: Ids.Degree) -> bool:
	return degree >= Ids.Degree.SUCCESS
