class_name Dice
extends RefCounted
## Parse and roll PF2e dice expressions ("2d6+3", "1d20", "d8-1", "2d6+1d4+3")
## against an INJECTED [RandomNumberGenerator]. The core NEVER calls the global
## randi() (spec §2) — every roll is reproducible from a seed for tests and
## save-replay.


## The outcome of rolling an expression: the [member total], every individual die
## [member faces] (for the combat log), and the canonical [member formula].
class Roll:
	extends RefCounted

	var total: int = 0
	var faces: Array[int] = []
	var formula: String = ""
	var valid: bool = false

	func _to_string() -> String:
		return "%s = %d %s" % [formula, total, str(faces)]


## Roll a single die in [1..sides] with the injected RNG.
static func die(sides: int, rng: RandomNumberGenerator) -> int:
	assert(sides >= 1, "Dice.die: sides must be >= 1")
	return rng.randi_range(1, sides)


## Roll one d20 — convenience returning the raw face, for natural-1 / natural-20 checks.
static func d20(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, 20)


## Parse an expression into its dice terms and flat modifier. Returns
## { "dice": Array[Vector2i] (x = count, y = sides; count may be negative for a
## subtracted term), "flat": int, "valid": bool }. Whitespace is ignored; any
## unparseable input yields valid = false.
static func parse(expr: String) -> Dictionary:
	var clean := expr.strip_edges().replace(" ", "")
	var dice: Array[Vector2i] = []
	var flat := 0
	if clean.is_empty():
		return {"dice": dice, "flat": flat, "valid": false}

	var re := RegEx.new()
	# A term is an optional sign, then either NdM (count optional) or a bare integer.
	re.compile("([+-]?)(\\d*)d(\\d+)|([+-]?)(\\d+)")

	var pos := 0
	for m: RegExMatch in re.search_all(clean):
		if m.get_start() != pos:
			return {"dice": dice, "flat": flat, "valid": false}  # junk between terms
		pos = m.get_end()
		if m.get_string(3) != "":
			# Dice term: group 1 sign, 2 count (optional → 1), 3 sides.
			var term_sign := -1 if m.get_string(1) == "-" else 1
			var count_str := m.get_string(2)
			var count := 1 if count_str.is_empty() else count_str.to_int()
			var sides := m.get_string(3).to_int()
			if sides < 1:
				return {"dice": dice, "flat": flat, "valid": false}
			dice.append(Vector2i(term_sign * count, sides))
		else:
			# Flat term: group 4 sign, 5 value.
			var term_sign := -1 if m.get_string(4) == "-" else 1
			flat += term_sign * m.get_string(5).to_int()

	if pos != clean.length():
		return {"dice": dice, "flat": flat, "valid": false}  # trailing junk
	return {"dice": dice, "flat": flat, "valid": true}


## Roll a full expression against the injected RNG. On a parse failure, pushes an
## error and returns a Roll with valid = false and total 0.
static func roll(expr: String, rng: RandomNumberGenerator) -> Roll:
	var out := Roll.new()
	out.formula = expr.strip_edges()
	var parsed := parse(expr)
	if not bool(parsed["valid"]):
		push_error("Dice.roll: cannot parse '%s'" % expr)
		return out
	out.valid = true

	var dice: Array[Vector2i] = parsed["dice"]
	for term: Vector2i in dice:
		var count := term.x
		var sides := term.y
		var per_sign := signi(count)
		for _i: int in absi(count):
			var face := rng.randi_range(1, sides)
			out.faces.append(face)
			out.total += per_sign * face
	out.total += int(parsed["flat"])
	return out
