class_name Movement
extends RefCounted
## Reach, flanking, and movement cost on the grid (spec §4.6). Reach/flanking are pure
## geometry; path cost and the reachable set honor difficult terrain (×2) and the
## alternating diagonal rule — tracked as a parity state so Dijkstra stays correct.


## Two attackers flank a target when both are within melee reach and the target lies
## on a straight line strictly between them (colinear, opposite sides). Flanking makes
## the target off-guard, which feeds straight into Strike (M6).
static func are_flanking(
		a: Vector2i, b: Vector2i, target: Vector2i,
		reach_a: int = 5, reach_b: int = 5) -> bool:
	if a == target or b == target or a == b:
		return false
	if Grid.distance(a, target) > reach_a or Grid.distance(b, target) > reach_b:
		return false
	var d1 := target - a        # a → target
	var d2 := b - target        # target → b
	var colinear := d1.x * d2.y - d1.y * d2.x == 0
	var same_direction := d1.x * d2.x + d1.y * d2.y > 0   # Vector2i has no dot()
	return colinear and same_direction


## True if any pair of the allied positions flanks the target.
static func is_flanked(target: Vector2i, allies: Array, reach: int = 5) -> bool:
	for i: int in allies.size():
		var ai: Vector2i = allies[i]
		for j: int in range(i + 1, allies.size()):
			var aj: Vector2i = allies[j]
			if are_flanking(ai, aj, target, reach, reach):
				return true
	return false


## Cost in feet to walk an explicit path (adjacent squares incl. the start), applying
## difficult terrain and the alternating diagonal rule across the whole path.
static func path_cost(grid: Grid, path: Array) -> int:
	var total := 0
	var diag_count := 0
	for i: int in range(1, path.size()):
		var from: Vector2i = path[i - 1]
		var to: Vector2i = path[i]
		var base := Grid.FEET_PER_SQUARE
		if Grid.is_diagonal_step(from, to):
			base = Grid.FEET_PER_SQUARE * (1 if diag_count % 2 == 0 else 2)
			diag_count += 1
		total += base * grid.terrain_multiplier(to)
	return total


## Minimum cost (feet) from start to every square reachable within [param speed],
## honoring terrain and the alternating diagonal rule. Dijkstra over (square, diagonal
## parity); returns Vector2i -> min cost (start included at 0).
static func reachable(grid: Grid, start: Vector2i, speed: int) -> Dictionary:
	var best: Dictionary = {}                  # Vector3i(x, y, parity) -> cost
	var result: Dictionary = {start: 0}        # Vector2i -> min cost
	var start_key := Vector3i(start.x, start.y, 0)
	best[start_key] = 0
	var frontier: Array = [start_key]

	while not frontier.is_empty():
		var bi := 0
		for k: int in range(1, frontier.size()):
			if int(best[frontier[k]]) < int(best[frontier[bi]]):
				bi = k
		var cur: Vector3i = frontier[bi]
		frontier.remove_at(bi)
		var cur_cost := int(best[cur])
		var cur_pos := Vector2i(cur.x, cur.y)
		var parity := cur.z

		for n: Vector2i in grid.neighbors(cur_pos):
			var step := Grid.FEET_PER_SQUARE
			var new_parity := parity
			if Grid.is_diagonal_step(cur_pos, n):
				step = Grid.FEET_PER_SQUARE * (1 if parity == 0 else 2)
				new_parity = 1 - parity
			var cost := cur_cost + step * grid.terrain_multiplier(n)
			if cost > speed:
				continue
			var nkey := Vector3i(n.x, n.y, new_parity)
			if not best.has(nkey) or cost < int(best[nkey]):
				best[nkey] = cost
				frontier.append(nkey)
				if not result.has(n) or cost < int(result[n]):
					result[n] = cost
	return result


static func can_reach(grid: Grid, start: Vector2i, dest: Vector2i, speed: int) -> bool:
	if start == dest:
		return true
	return reachable(grid, start, speed).has(dest)
