class_name Grid
extends RefCounted
## Logical square grid for combat (spec §4.6). Coordinates are Vector2i squares; the
## iso rendering is presentation-only — the core reasons in plain squares. Distance
## uses the PF2e diagonal rule (5/10/5/10…: the first diagonal is 5 ft, the second
## 10 ft, alternating). The instance also tracks difficult terrain (a per-square cost
## multiplier) and blockers (walls that stop movement and sight).

const FEET_PER_SQUARE := 5

var width: int                  ## 0 = unbounded
var height: int
var _difficult: Dictionary = {}     ## Vector2i -> int cost multiplier (≥2)
var _blockers: Dictionary = {}      ## Vector2i -> true


func _init(p_width: int = 0, p_height: int = 0) -> void:
	width = p_width
	height = p_height


func in_bounds(pos: Vector2i) -> bool:
	if width <= 0 or height <= 0:
		return true
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height


func set_difficult(pos: Vector2i, multiplier: int = 2) -> void:
	if multiplier <= 1:
		_difficult.erase(pos)
	else:
		_difficult[pos] = multiplier


func terrain_multiplier(pos: Vector2i) -> int:
	return int(_difficult.get(pos, 1))


func set_blocker(pos: Vector2i, blocked: bool = true) -> void:
	if blocked:
		_blockers[pos] = true
	else:
		_blockers.erase(pos)


func is_blocker(pos: Vector2i) -> bool:
	return _blockers.has(pos)


## In-bounds, non-blocker 8-neighbours of a square.
func neighbors(pos: Vector2i) -> Array:
	var out: Array = []
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var n := pos + Vector2i(dx, dy)
			if in_bounds(n) and not is_blocker(n):
				out.append(n)
	return out


# ── pure geometry (static) ───────────────────────────────────────────────────

## Chebyshev step count: squares between a and b, diagonals counting as one step.
static func steps(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## PF2e distance in FEET using the 5/10/5/10 diagonal rule.
static func distance(a: Vector2i, b: Vector2i) -> int:
	var dx := absi(a.x - b.x)
	var dy := absi(a.y - b.y)
	var diag := mini(dx, dy)
	var straight := maxi(dx, dy) - diag
	var increments := straight + diag + (diag / 2)   # every 2nd diagonal is +1 square
	return increments * FEET_PER_SQUARE


static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return a != b and steps(a, b) == 1


static func is_diagonal_step(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) == 1 and absi(a.y - b.y) == 1
