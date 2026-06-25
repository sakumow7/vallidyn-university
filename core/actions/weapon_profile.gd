class_name WeaponProfile
extends RefCounted
## Precomputed weapon math for a Strike (spec §4.5). [member attack_bonus] is the
## full to-hit bonus EXCLUDING MAP and conditions (ability + proficiency + item /
## runes); [member damage_bonus] is the flat add to damage before crit doubling
## (ability + specialization). [member attack_tags] is the stat-tag context used to
## match the attacker's conditions (a Str melee strike → STR_BASED, so enfeebled
## bites but clumsy doesn't). The M8 compile produces these from WeaponData + the
## wielder; for now they're built directly.

var attack_bonus: int
var damage_formula: String
var damage_bonus: int
var damage_type: StringName
var agile: bool                ## agile → MAP is −4/−8 instead of −5/−10
var is_ranged: bool
var attack_tags: Array         ## Array[Ids.StatTag]


func _init(
		p_attack_bonus: int = 0,
		p_damage_formula: String = "1d4",
		p_damage_bonus: int = 0,
		p_damage_type: StringName = &"bludgeoning",
		p_agile: bool = false,
		p_ranged: bool = false,
		p_attack_tags: Array = []) -> void:
	attack_bonus = p_attack_bonus
	damage_formula = p_damage_formula
	damage_bonus = p_damage_bonus
	damage_type = p_damage_type
	agile = p_agile
	is_ranged = p_ranged
	if p_attack_tags.is_empty():
		attack_tags = [Ids.StatTag.ATTACK, Ids.StatTag.MELEE, Ids.StatTag.STR_BASED]
	else:
		attack_tags = p_attack_tags


## Str-based melee weapon.
static func melee(
		attack_bonus: int, formula: String, damage_bonus: int,
		damage_type: StringName, agile: bool = false) -> WeaponProfile:
	return WeaponProfile.new(
		attack_bonus, formula, damage_bonus, damage_type, agile, false,
		[Ids.StatTag.ATTACK, Ids.StatTag.MELEE, Ids.StatTag.STR_BASED])


## Dex-based ranged weapon.
static func ranged(
		attack_bonus: int, formula: String, damage_bonus: int,
		damage_type: StringName, agile: bool = false) -> WeaponProfile:
	return WeaponProfile.new(
		attack_bonus, formula, damage_bonus, damage_type, agile, true,
		[Ids.StatTag.ATTACK, Ids.StatTag.RANGED, Ids.StatTag.DEX_BASED])
