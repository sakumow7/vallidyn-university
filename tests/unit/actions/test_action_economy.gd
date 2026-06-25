extends GutTest
## Action economy + MAP (spec §4.1).

var _e: ActionEconomy


func before_each() -> void:
	_e = ActionEconomy.new()


func test_starts_with_three_actions_and_a_reaction() -> void:
	assert_eq(_e.actions_remaining, 3)
	assert_true(_e.reaction_available)
	assert_eq(_e.attacks_made, 0)


func test_spend_reduces_actions() -> void:
	assert_true(_e.spend(2))
	assert_eq(_e.actions_remaining, 1)


func test_cannot_overspend() -> void:
	assert_false(_e.spend(4), "can't spend more than remaining")
	assert_eq(_e.actions_remaining, 3, "a failed spend changes nothing")


func test_free_action_always_affordable() -> void:
	_e.spend(3)
	assert_true(_e.can_spend(0))


func test_reaction_once_per_round() -> void:
	assert_true(_e.use_reaction())
	assert_false(_e.use_reaction(), "only one reaction")


func test_start_turn_resets_everything() -> void:
	_e.spend(3)
	_e.use_reaction()
	_e.note_attack()
	_e.start_turn()
	assert_eq(_e.actions_remaining, 3)
	assert_true(_e.reaction_available)
	assert_eq(_e.attacks_made, 0)


func test_map_progression_non_agile() -> void:
	assert_eq(_e.map_penalty(false), 0, "first attack: no MAP")
	_e.note_attack()
	assert_eq(_e.map_penalty(false), -5, "second attack: −5")
	_e.note_attack()
	assert_eq(_e.map_penalty(false), -10, "third attack: −10")
	_e.note_attack()
	assert_eq(_e.map_penalty(false), -10, "fourth+ stays −10")


func test_map_progression_agile() -> void:
	assert_eq(_e.map_penalty(true), 0)
	_e.note_attack()
	assert_eq(_e.map_penalty(true), -4, "agile second attack: −4")
	_e.note_attack()
	assert_eq(_e.map_penalty(true), -8, "agile third attack: −8")
