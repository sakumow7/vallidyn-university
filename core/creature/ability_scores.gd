class_name AbilityScores
extends RefCounted
## The six ability scores and their modifiers (spec §4.5/§5). PF2e starts every
## ability at 10 (modifier 0); a boost raises a score by +2 (or +1 once it is 18+),
## a flaw lowers it by −2. The modifier is floor((score − 10) / 2). The character
## build (M8) drives the boosts; this is the math plus the runtime holder.

var scores: Dictionary = {}        ## Ids.Ability -> int score


func _init() -> void:
	for a: int in Ids.Ability.values():
		scores[a] = 10


## floor((score − 10) / 2) — correct for odd and negative scores.
static func modifier_for(score_value: int) -> int:
	return floori((score_value - 10) / 2.0)


func score(ability: Ids.Ability) -> int:
	return int(scores.get(ability, 10))


func set_score(ability: Ids.Ability, value: int) -> void:
	scores[ability] = value


func modifier(ability: Ids.Ability) -> int:
	return modifier_for(score(ability))


## Apply a boost: +2 below 18, +1 at 18 or higher (PF2e diminishing boosts).
func boost(ability: Ids.Ability) -> void:
	var s := score(ability)
	scores[ability] = s + (2 if s < 18 else 1)


## Apply a flaw: −2.
func flaw(ability: Ids.Ability) -> void:
	scores[ability] = score(ability) - 2


## Every ability's modifier as Ids.Ability -> int.
func mods() -> Dictionary:
	var out: Dictionary = {}
	for a: int in Ids.Ability.values():
		out[a] = modifier(a)
	return out
