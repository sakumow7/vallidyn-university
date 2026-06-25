extends GutTest
## Square grid + the PF2e 5/10/5/10 diagonal distance rule (spec §4.6).


func test_orthogonal_distance() -> void:
	assert_eq(Grid.distance(Vector2i(0, 0), Vector2i(3, 0)), 15)
	assert_eq(Grid.distance(Vector2i(0, 0), Vector2i(0, 4)), 20)


func test_diagonal_distance_alternates_5_10() -> void:
	assert_eq(Grid.distance(Vector2i(0, 0), Vector2i(1, 1)), 5, "first diagonal = 5")
	assert_eq(Grid.distance(Vector2i(0, 0), Vector2i(2, 2)), 15, "second adds 10")
	assert_eq(Grid.distance(Vector2i(0, 0), Vector2i(3, 3)), 20, "third adds 5")
	assert_eq(Grid.distance(Vector2i(0, 0), Vector2i(4, 4)), 30, "fourth adds 10")


func test_mixed_distance() -> void:
	# 3 across, 1 up: one diagonal (5) + two straight (10) = 15.
	assert_eq(Grid.distance(Vector2i(0, 0), Vector2i(3, 1)), 15)
	# 4 across, 2 up: two diagonals (5+10) + two straight (10) = 25.
	assert_eq(Grid.distance(Vector2i(0, 0), Vector2i(4, 2)), 25)


func test_distance_is_symmetric() -> void:
	assert_eq(
		Grid.distance(Vector2i(1, 2), Vector2i(5, 7)),
		Grid.distance(Vector2i(5, 7), Vector2i(1, 2)))


func test_steps_is_chebyshev() -> void:
	assert_eq(Grid.steps(Vector2i(0, 0), Vector2i(2, 3)), 3)


func test_adjacency() -> void:
	assert_true(Grid.is_adjacent(Vector2i(0, 0), Vector2i(1, 0)))
	assert_true(Grid.is_adjacent(Vector2i(0, 0), Vector2i(1, 1)), "diagonal is adjacent")
	assert_false(Grid.is_adjacent(Vector2i(0, 0), Vector2i(2, 0)))
	assert_false(Grid.is_adjacent(Vector2i(0, 0), Vector2i(0, 0)))


func test_bounds_and_neighbors() -> void:
	var g := Grid.new(3, 3)
	assert_true(g.in_bounds(Vector2i(2, 2)))
	assert_false(g.in_bounds(Vector2i(3, 0)))
	# corner (0,0) of a 3×3 has 3 neighbours.
	assert_eq(g.neighbors(Vector2i(0, 0)).size(), 3)


func test_blockers_excluded_from_neighbors() -> void:
	var g := Grid.new(3, 3)
	g.set_blocker(Vector2i(1, 0))
	assert_true(g.is_blocker(Vector2i(1, 0)))
	assert_false(g.neighbors(Vector2i(0, 0)).has(Vector2i(1, 0)))


func test_unbounded_grid_in_bounds_everywhere() -> void:
	var g := Grid.new()
	assert_true(g.in_bounds(Vector2i(-100, 9999)))
