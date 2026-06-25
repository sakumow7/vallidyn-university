class_name Action
extends RefCounted
## Base for an action a creature can take (spec §4.1): its action cost, traits, and a
## name. Concrete actions extend this and add resolution — [Strike] now; CastSpell
## and the basic actions (Stride, Step, Raise a Shield, Demoralize…) later. Cost uses
## [enum Ids.ActionCost] (1/2/3, free, reaction).

var action_name: String
var cost: Ids.ActionCost
var traits: Array              ## Array[StringName]


func _init(
		p_name: String = "",
		p_cost: Ids.ActionCost = Ids.ActionCost.ONE,
		p_traits: Array = []) -> void:
	action_name = p_name
	cost = p_cost
	traits = p_traits


## Numeric action cost: free = 0, reaction = −1 (sentinel), otherwise 1/2/3.
func cost_value() -> int:
	return int(cost)


func has_trait(t: StringName) -> bool:
	return traits.has(t)
