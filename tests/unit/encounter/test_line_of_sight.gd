extends GutTest
## Line of sight + cover (spec §4.6).

const A := Vector2i(0, 0)
const B := Vector2i(4, 0)


func test_line_squares_excludes_endpoints() -> void:
	assert_eq(
		LineOfSight.line_squares(Vector2i(0, 0), Vector2i(3, 0)),
		[Vector2i(1, 0), Vector2i(2, 0)])


func test_line_squares_adjacent_is_empty() -> void:
	assert_eq(LineOfSight.line_squares(Vector2i(0, 0), Vector2i(1, 0)), [])


func test_clear_line_of_sight() -> void:
	var g := Grid.new()
	assert_true(LineOfSight.has_line_of_sight(g, A, B))


func test_wall_blocks_line_of_sight() -> void:
	var g := Grid.new()
	g.set_blocker(Vector2i(2, 0))
	assert_false(LineOfSight.has_line_of_sight(g, A, B))


func test_no_cover_when_clear() -> void:
	var g := Grid.new()
	assert_eq(LineOfSight.cover(g, A, B), Ids.Cover.NONE)


func test_wall_gives_standard_cover() -> void:
	var g := Grid.new()
	g.set_blocker(Vector2i(2, 0))
	assert_eq(LineOfSight.cover(g, A, B), Ids.Cover.STANDARD)


func test_creature_gives_lesser_cover() -> void:
	var g := Grid.new()
	assert_eq(LineOfSight.cover(g, A, B, [Vector2i(2, 0)]), Ids.Cover.LESSER)


func test_wall_outranks_creature_for_cover() -> void:
	var g := Grid.new()
	g.set_blocker(Vector2i(3, 0))
	assert_eq(
		LineOfSight.cover(g, A, B, [Vector2i(1, 0)]),
		Ids.Cover.STANDARD, "a wall in the line is standard cover regardless")


func test_cover_ac_bonus_mapping() -> void:
	assert_eq(Ids.cover_ac_bonus(Ids.Cover.NONE), 0)
	assert_eq(Ids.cover_ac_bonus(Ids.Cover.LESSER), 1)
	assert_eq(Ids.cover_ac_bonus(Ids.Cover.STANDARD), 2)
	assert_eq(Ids.cover_ac_bonus(Ids.Cover.GREATER), 4)
