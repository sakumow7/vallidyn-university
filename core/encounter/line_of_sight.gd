class_name LineOfSight
extends RefCounted
## Line of sight and cover (spec §4.6). Geometry over the grid's blockers (walls) and,
## optionally, creature-occupied squares. Cover is a circumstance bonus to the
## DEFENDER's AC, so it's computed per attacker→target line.


## Squares a straight center-to-center line crosses, EXCLUDING both endpoints
## (integer Bresenham). Used for both sight and cover.
static func line_squares(a: Vector2i, b: Vector2i) -> Array:
	var points: Array = []
	var x := a.x
	var y := a.y
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	while true:
		points.append(Vector2i(x, y))
		if x == b.x and y == b.y:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
	if points.size() <= 2:
		return []
	return points.slice(1, points.size() - 1)


## True if nothing blocks sight between a and b (no wall in the intervening squares).
static func has_line_of_sight(grid: Grid, a: Vector2i, b: Vector2i) -> bool:
	for sq: Vector2i in line_squares(a, b):
		if grid.is_blocker(sq):
			return false
	return true


## Cover the target at b has from an attacker at a: a wall between → standard cover;
## only a creature between → lesser cover; otherwise none. [param occupied] lists
## creature-occupied squares (exclude a and b).
static func cover(grid: Grid, a: Vector2i, b: Vector2i, occupied: Array = []) -> Ids.Cover:
	var level := Ids.Cover.NONE
	for sq: Vector2i in line_squares(a, b):
		if grid.is_blocker(sq):
			return Ids.Cover.STANDARD
		if occupied.has(sq):
			level = Ids.Cover.LESSER
	return level
