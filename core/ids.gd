class_name Ids
extends RefCounted
## Central registry for every enum and stable id used by the rules core (spec §2:
## "No magic strings — all ids in a central registry").
##
## Closed sets the engine reasons about directly are [b]enums[/b]. Open sets that
## grow from imported data (traits, conditions, damage types, skills) are
## [StringName] constants, so they stay stable across .tres files and Foundry
## mapping. New imported content adds string ids; it never edits an enum.
##
## This class is never instantiated — it is a namespace of consts/enums/helpers.


# ─────────────────────────────────────────────────────────────────────────────
# Degrees of success (spec §4.2)
# Ordered worst → best so a nat-20 "bump up" is +1 and a nat-1 "bump down" is −1.
# ─────────────────────────────────────────────────────────────────────────────
enum Degree {
	CRITICAL_FAILURE = 0,
	FAILURE = 1,
	SUCCESS = 2,
	CRITICAL_SUCCESS = 3,
}

const DEGREE_NAMES := {
	Degree.CRITICAL_FAILURE: "Critical Failure",
	Degree.FAILURE: "Failure",
	Degree.SUCCESS: "Success",
	Degree.CRITICAL_SUCCESS: "Critical Success",
}


# ─────────────────────────────────────────────────────────────────────────────
# Ability scores
# ─────────────────────────────────────────────────────────────────────────────
enum Ability { STR, DEX, CON, INT, WIS, CHA }

const ABILITY_NAMES := {
	Ability.STR: "Strength",
	Ability.DEX: "Dexterity",
	Ability.CON: "Constitution",
	Ability.INT: "Intelligence",
	Ability.WIS: "Wisdom",
	Ability.CHA: "Charisma",
}


# ─────────────────────────────────────────────────────────────────────────────
# Proficiency ranks (spec §4.5)
# Proficiency bonus = level + rank bonus, but ONLY when trained or better.
# Untrained contributes 0 and does NOT add level (enforced in proficiency.gd, M4).
# ─────────────────────────────────────────────────────────────────────────────
enum Proficiency { UNTRAINED, TRAINED, EXPERT, MASTER, LEGENDARY }

const PROFICIENCY_BONUS := {
	Proficiency.UNTRAINED: 0,
	Proficiency.TRAINED: 2,
	Proficiency.EXPERT: 4,
	Proficiency.MASTER: 6,
	Proficiency.LEGENDARY: 8,
}


# ─────────────────────────────────────────────────────────────────────────────
# Modifier types (spec §4.3, §8)
# CIRCUMSTANCE / STATUS / ITEM are the three "typed" bonuses: same-type bonuses
# don't stack (take highest), same-type penalties don't stack (take worst).
# UNTYPED penalties DO stack. DIFFICULTY is its own type (spec §8) so global
# ally/enemy sliders flow through the same stacking pipeline and stay traceable.
# ─────────────────────────────────────────────────────────────────────────────
enum ModifierType {
	UNTYPED,
	CIRCUMSTANCE,
	STATUS,
	ITEM,
	DIFFICULTY,
}

const MODIFIER_TYPE_NAMES := {
	ModifierType.UNTYPED: "untyped",
	ModifierType.CIRCUMSTANCE: "circumstance",
	ModifierType.STATUS: "status",
	ModifierType.ITEM: "item",
	ModifierType.DIFFICULTY: "difficulty",
}


# ─────────────────────────────────────────────────────────────────────────────
# Check kinds (spec §4.2) — every d20 resolution is one of these.
# ─────────────────────────────────────────────────────────────────────────────
enum CheckType { ATTACK, SKILL, SAVE, PERCEPTION, FLAT, SPELL_ATTACK }


# ─────────────────────────────────────────────────────────────────────────────
# Action economy (spec §4.1)
# ─────────────────────────────────────────────────────────────────────────────
enum ActionCost { FREE = 0, ONE = 1, TWO = 2, THREE = 3, REACTION = -1 }


# ─────────────────────────────────────────────────────────────────────────────
# Saving throws
# ─────────────────────────────────────────────────────────────────────────────
enum Save { FORTITUDE, REFLEX, WILL }


# ─────────────────────────────────────────────────────────────────────────────
# Open, data-driven id sets. Starter values only — extended by the importer
# (spec §10). Engine code references these consts; data files reuse the strings.
# ─────────────────────────────────────────────────────────────────────────────

# Damage types (a representative set; full list arrives with bulk import).
const DAMAGE_BLUDGEONING := &"bludgeoning"
const DAMAGE_PIERCING := &"piercing"
const DAMAGE_SLASHING := &"slashing"
const DAMAGE_FIRE := &"fire"
const DAMAGE_COLD := &"cold"
const DAMAGE_ACID := &"acid"
const DAMAGE_ELECTRICITY := &"electricity"
const DAMAGE_SONIC := &"sonic"
const DAMAGE_MENTAL := &"mental"
const DAMAGE_POISON := &"poison"
const DAMAGE_VITALITY := &"vitality"
const DAMAGE_VOID := &"void"          # Remastered: replaces "negative"
const DAMAGE_SPIRIT := &"spirit"
const DAMAGE_FORCE := &"force"
const DAMAGE_UNTYPED := &"untyped"

const PHYSICAL_DAMAGE_TYPES: Array[StringName] = [
	DAMAGE_BLUDGEONING, DAMAGE_PIERCING, DAMAGE_SLASHING,
]

# A few conditions referenced early (the full ~40 land in condition_engine.gd, M5).
const CONDITION_OFF_GUARD := &"off-guard"
const CONDITION_FRIGHTENED := &"frightened"
const CONDITION_PRONE := &"prone"
const CONDITION_CLUMSY := &"clumsy"
const CONDITION_DRAINED := &"drained"
const CONDITION_ENFEEBLED := &"enfeebled"

# A few traits referenced by mechanics (e.g. agile changes MAP). Extended on import.
const TRAIT_AGILE := &"agile"
const TRAIT_FINESSE := &"finesse"
const TRAIT_REACH := &"reach"


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

## Display label for a degree (combat log / UI).
static func degree_name(d: Degree) -> String:
	return DEGREE_NAMES.get(d, "Unknown")

## Rank bonus for a proficiency rank (the +2/+4/+6/+8 part, sans level).
static func proficiency_bonus(rank: Proficiency) -> int:
	return PROFICIENCY_BONUS.get(rank, 0)

## True for modifier types whose same-type instances DON'T stack (take
## highest bonus / worst penalty). UNTYPED is the only stacking type.
static func modifier_type_stacks(type: ModifierType) -> bool:
	return type == ModifierType.UNTYPED
