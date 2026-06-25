extends GutTest
## Reach, flanking, difficult terrain, and the reachable set (spec §4.6).


# ── flanking ─────────────────────────────────────────────────────────────────

func test_flanking_orthogonal() -> void:
	# (0,1) — (1,1) — (2,1): on opposite sides of the target.
	assert_true(Movement.are_flanking(Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 1)))


func test_flanking_diagonal() -> void:
	assert_true(Movement.are_flanking(Vector2i(0, 0), Vector2i(2, 2), Vector2i(1, 1)))


func test_not_flanking_when_not_opposite() -> void:
	# (0,1) and (1,0) are adjacent to the target but not on a line through it.
	assert_false(Movement.are_flanking(Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1)))


func test_flanking_requires_reach() -> void:
	# Colinear and opposite, but b is 20 ft away — out of 5 ft reach.
	assert_false(Movement.are_flanking(Vector2i(0, 1), Vector2i(5, 1), Vector2i(1, 1)))
	# With reach 20, it flanks.
	assert_true(Movement.are_flanking(Vector2i(0, 1), Vector2i(5, 1), Vector2i(1, 1), 5, 20))


func test_flanking_allows_unequal_distance() -> void:
	# a adjacent, b two squares out on the same line, both within reach 10.
	assert_true(Movement.are_flanking(Vector2i(0, 1), Vector2i(3, 1), Vector2i(1, 1), 10, 10))


func test_is_flanked_any_pair() -> void:
	var allies := [Vector2i(0, 1), Vector2i(2, 1), Vector2i(5, 5)]
	assert_true(Movement.is_flanked(Vector2i(1, 1), allies))
	assert_false(Movement.is_flanked(Vector2i(9, 9), allies))


# ── path cost ────────────────────────────────────────────────────────────────

func test_path_cost_orthogonal() -> void:
	var g := Grid.new()
	var path := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	assert_eq(Movement.path_cost(g, path), 15)


func test_path_cost_diagonal_alternation() -> void:
	var g := Grid.new()
	# two diagonal steps: 5 then 10 = 15.
	var path := [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
	assert_eq(Movement.path_cost(g, path), 15)


func test_path_cost_difficult_terrain_doubles() -> void:
	var g := Grid.new()
	g.set_difficult(Vector2i(1, 0))           # ×2
	var path := [Vector2i(0, 0), Vector2i(1, 0)]
	assert_eq(Movement.path_cost(g, path), 10, "5 ft × 2 for difficult terrain")


# ── reachable set ────────────────────────────────────────────────────────────

func test_reachable_orthogonal_budget() -> void:
	var g := Grid.new()
	var r := Movement.reachable(g, Vector2i(0, 0), 15)
	assert_true(r.has(Vector2i(3, 0)), "30 ft Speed... 15 reaches 3 squares")
	assert_false(r.has(Vector2i(4, 0)), "20 ft is out of a 15 ft budget")


func test_reachable_diagonal_costs() -> void:
	var g := Grid.new()
	var r := Movement.reachable(g, Vector2i(0, 0), 15)
	assert_eq(int(r[Vector2i(2, 2)]), 15, "two diagonals = 5 + 10")
	assert_false(r.has(Vector2i(3, 3)), "three diagonals = 20, out of budget")


func test_reachable_through_difficult_terrain() -> void:
	var g := Grid.new()
	g.set_difficult(Vector2i(1, 0))           # entering costs 10
	var r := Movement.reachable(g, Vector2i(0, 0), 10)
	assert_eq(int(r[Vector2i(1, 0)]), 10)
	assert_false(r.has(Vector2i(2, 0)), "no budget left to continue")


func test_can_reach() -> void:
	var g := Grid.new()
	assert_true(Movement.can_reach(g, Vector2i(0, 0), Vector2i(2, 2), 15))
	assert_false(Movement.can_reach(g, Vector2i(0, 0), Vector2i(3, 3), 15))
