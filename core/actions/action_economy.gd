class_name ActionEconomy
extends RefCounted
## Per-turn action tracking (spec §4.1): 3 actions + 1 reaction + free actions, plus
## the Multiple Attack Penalty. Actions and MAP reset at the start of each turn, and
## the reaction refreshes then too. One ActionEconomy per creature per encounter.

const ACTIONS_PER_TURN := 3

var actions_remaining: int
var reaction_available: bool
var attacks_made: int          ## attacks this turn, for MAP


func _init() -> void:
	start_turn()


## Reset for the start of this creature's turn.
func start_turn() -> void:
	actions_remaining = ACTIONS_PER_TURN
	reaction_available = true
	attacks_made = 0


## Can this many actions be afforded? (free = 0 always can; reaction = −1 cannot.)
func can_spend(cost: int) -> bool:
	return cost >= 0 and cost <= actions_remaining


## Spend [param cost] actions. Returns false and spends nothing if unaffordable.
func spend(cost: int) -> bool:
	if not can_spend(cost):
		return false
	actions_remaining -= cost
	return true


## Use the reaction for this round. Returns false if it's already spent.
func use_reaction() -> bool:
	if not reaction_available:
		return false
	reaction_available = false
	return true


## MAP penalty for the NEXT attack this turn, given the weapon's agile trait: 0 on
## the first attack, then −5/−10 (or −4/−8 agile).
func map_penalty(agile: bool) -> int:
	var step := mini(attacks_made, 2)
	if step == 0:
		return 0
	return (-4 * step) if agile else (-5 * step)


## Record that an attack-trait action was made (advances MAP).
func note_attack() -> void:
	attacks_made += 1
