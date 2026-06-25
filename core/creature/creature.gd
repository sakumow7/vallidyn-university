class_name Creature
extends RefCounted
## Runtime combatant stat block (spec §4.5). In the full pipeline a creature's
## defenses are DERIVED (M4: ability_scores → proficiency → defenses) and COMPILED
## from a CharacterBuild (M8). This milestone (M6, Strike) needs a target that has
## AC, HP, conditions, and damage resistances/weaknesses/immunities, so those fields
## are set directly here; M4 adds the derivation that fills them. Kept lean on
## purpose — it grows into the full stat block next.

var display_name: String
var level: int
var ability_mods: Dictionary           ## Ids.Ability -> int
var ac: int                            ## base AC, before conditions
var max_hp: int
var hp: int
var conditions: ConditionEngine
var resistances: Dictionary            ## StringName damage type -> int
var weaknesses: Dictionary             ## StringName damage type -> int
var immunities: Array                  ## Array[StringName]


func _init(p_name: String = "", p_ac: int = 10, p_max_hp: int = 1, p_level: int = 1) -> void:
	display_name = p_name
	ac = p_ac
	max_hp = p_max_hp
	hp = p_max_hp
	level = p_level
	ability_mods = {}
	conditions = ConditionEngine.new()
	resistances = {}
	weaknesses = {}
	immunities = []


func ability_mod(ability: Ids.Ability) -> int:
	return int(ability_mods.get(ability, 0))


func is_alive() -> bool:
	return hp > 0


## AC after the creature's own conditions (off-guard, frightened, clumsy…). This is
## the DC an attacker rolls against.
func effective_ac() -> int:
	var s := ModifierStack.new()
	s.add_all(conditions.modifiers_for([Ids.StatTag.AC, Ids.StatTag.DEX_BASED]))
	return ac + s.total()


## Apply incoming damage of a type, honoring immunity → weakness → resistance
## (Remastered order). Returns the actual damage taken; reduces HP, floored at 0.
func apply_damage(amount: int, type: StringName) -> int:
	if amount <= 0:
		return 0
	if immunities.has(type):
		return 0
	var final_amount := amount
	if weaknesses.has(type):
		final_amount += int(weaknesses[type])
	if resistances.has(type):
		final_amount -= int(resistances[type])
	final_amount = maxi(final_amount, 0)
	hp = maxi(hp - final_amount, 0)
	return final_amount


func heal(amount: int) -> void:
	hp = mini(hp + maxi(amount, 0), max_hp)
