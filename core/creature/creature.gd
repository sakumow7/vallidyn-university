class_name Creature
extends RefCounted
## Runtime combatant stat block (spec §4.5). Defenses are COMPUTED, not authored:
## [method derive_defenses] turns ability scores + proficiency ranks + level +
## equipment into AC, saves, Perception, and HP. (The M8 compile fills the structured
## inputs from a CharacterBuild; pre-statted monsters can also just set AC/HP directly
## via the constructor.) Conditions fold into the defenses that are rolled against —
## a frightened creature's saves all drop; clumsy hits its Reflex but not its Will.

var display_name: String
var level: int
var ability_scores: AbilityScores
var ac: int                            ## base AC, before conditions
var max_hp: int
var hp: int
var saves: Dictionary                  ## Ids.Save -> int
var perception: int
var conditions: ConditionEngine
var resistances: Dictionary            ## StringName damage type -> int
var weaknesses: Dictionary             ## StringName damage type -> int
var immunities: Array                  ## Array[StringName]

# Structured inputs for derive_defenses() (filled by the compile, or authored).
var proficiencies: Dictionary          ## StringName -> Ids.ProficiencyRank (&"ac", &"fortitude"…)
var dex_cap: int
var armor_item_bonus: int
var ancestry_hp: int
var class_hp_per_level: int

const _SAVE_CONTEXT := {
	Ids.Save.FORTITUDE: [Ids.StatTag.SAVE, Ids.StatTag.FORTITUDE, Ids.StatTag.CON_BASED],
	Ids.Save.REFLEX: [Ids.StatTag.SAVE, Ids.StatTag.REFLEX, Ids.StatTag.DEX_BASED],
	Ids.Save.WILL: [Ids.StatTag.SAVE, Ids.StatTag.WILL, Ids.StatTag.WIS_BASED],
}


func _init(p_name: String = "", p_ac: int = 10, p_max_hp: int = 1, p_level: int = 1) -> void:
	display_name = p_name
	ac = p_ac
	max_hp = p_max_hp
	hp = p_max_hp
	level = p_level
	ability_scores = AbilityScores.new()
	saves = {Ids.Save.FORTITUDE: 0, Ids.Save.REFLEX: 0, Ids.Save.WILL: 0}
	perception = 0
	conditions = ConditionEngine.new()
	resistances = {}
	weaknesses = {}
	immunities = []
	proficiencies = {}
	dex_cap = 99
	armor_item_bonus = 0
	ancestry_hp = 0
	class_hp_per_level = 0


func ability_mod(ability: Ids.Ability) -> int:
	return ability_scores.modifier(ability)


func proficiency(key: StringName) -> Ids.ProficiencyRank:
	return proficiencies.get(key, Ids.ProficiencyRank.UNTRAINED)


## Compute AC, saves, Perception, and max HP from ability scores + proficiencies +
## level + equipment. Sets HP to full (this is a compile, not mid-combat).
func derive_defenses() -> void:
	var dex := ability_mod(Ids.Ability.DEX)
	ac = Defenses.armor_class(level, dex, proficiency(&"ac"), armor_item_bonus, dex_cap)
	saves[Ids.Save.FORTITUDE] = Defenses.statistic(
		level, ability_mod(Ids.Ability.CON), proficiency(&"fortitude"))
	saves[Ids.Save.REFLEX] = Defenses.statistic(level, dex, proficiency(&"reflex"))
	saves[Ids.Save.WILL] = Defenses.statistic(
		level, ability_mod(Ids.Ability.WIS), proficiency(&"will"))
	perception = Defenses.statistic(
		level, ability_mod(Ids.Ability.WIS), proficiency(&"perception"))
	max_hp = Defenses.max_hp(
		ancestry_hp, class_hp_per_level, ability_mod(Ids.Ability.CON), level)
	hp = max_hp


func is_alive() -> bool:
	return hp > 0


## AC after the creature's own conditions (off-guard, frightened, clumsy…). This is
## the DC an attacker rolls against.
func effective_ac() -> int:
	var s := ModifierStack.new()
	s.add_all(conditions.modifiers_for([Ids.StatTag.AC, Ids.StatTag.DEX_BASED]))
	return ac + s.total()


## Total save bonus including conditions (frightened all, clumsy → Reflex, etc.).
func save_bonus(save: Ids.Save) -> int:
	var s := ModifierStack.new()
	s.add_all(conditions.modifiers_for(_SAVE_CONTEXT[save]))
	return int(saves.get(save, 0)) + s.total()


## Total Perception bonus including conditions (frightened, blinded, stupefied…).
func perception_bonus() -> int:
	var s := ModifierStack.new()
	s.add_all(conditions.modifiers_for([Ids.StatTag.PERCEPTION, Ids.StatTag.WIS_BASED]))
	return perception + s.total()


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
