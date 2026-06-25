extends GutTest
## Degree-of-success bands and natural-1 / natural-20 bumps (spec §4.2).


func test_bands() -> void:
	assert_eq(Degrees.band(28, 18), Ids.Degree.CRITICAL_SUCCESS, "≥ DC+10 crits")
	assert_eq(Degrees.band(18, 18), Ids.Degree.SUCCESS, "≥ DC succeeds")
	assert_eq(Degrees.band(17, 18), Ids.Degree.FAILURE, "< DC fails")
	assert_eq(Degrees.band(8, 18), Ids.Degree.CRITICAL_FAILURE, "≤ DC−10 crit-fails")


func test_exact_boundaries() -> void:
	assert_eq(Degrees.band(27, 18), Ids.Degree.SUCCESS, "DC+9 is still a success")
	assert_eq(Degrees.band(9, 18), Ids.Degree.FAILURE, "DC−9 is still a failure")


func test_nat20_bumps_up_one_step() -> void:
	# A total that only succeeds becomes a critical success.
	assert_eq(Degrees.resolve(18, 18, 20), Ids.Degree.CRITICAL_SUCCESS)
	# A total that fails becomes a success.
	assert_eq(Degrees.resolve(17, 18, 20), Ids.Degree.SUCCESS)
	# A total that would crit-fail only climbs one step → failure.
	assert_eq(Degrees.resolve(5, 18, 20), Ids.Degree.FAILURE)


func test_nat1_bumps_down_one_step() -> void:
	# A total that crit-succeeds drops to a plain success.
	assert_eq(Degrees.resolve(28, 18, 1), Ids.Degree.SUCCESS)
	# A total that succeeds drops to a failure.
	assert_eq(Degrees.resolve(18, 18, 1), Ids.Degree.FAILURE)
	# A huge total with a nat 1 → success (only one step down from crit-success).
	assert_eq(Degrees.resolve(40, 18, 1), Ids.Degree.SUCCESS)


func test_no_natural_means_no_bump() -> void:
	# natural = 0 (default) skips the swing — used by flat checks / non-d20 resolutions.
	assert_eq(Degrees.resolve(18, 18, 0), Ids.Degree.SUCCESS)


func test_bump_clamps_at_extremes() -> void:
	assert_eq(Degrees.bump_up(Ids.Degree.CRITICAL_SUCCESS), Ids.Degree.CRITICAL_SUCCESS)
	assert_eq(Degrees.bump_down(Ids.Degree.CRITICAL_FAILURE), Ids.Degree.CRITICAL_FAILURE)


func test_is_success_helper() -> void:
	assert_true(Degrees.is_success(Ids.Degree.SUCCESS))
	assert_true(Degrees.is_success(Ids.Degree.CRITICAL_SUCCESS))
	assert_false(Degrees.is_success(Ids.Degree.FAILURE))
	assert_false(Degrees.is_success(Ids.Degree.CRITICAL_FAILURE))
