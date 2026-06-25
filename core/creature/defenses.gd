class_name Defenses
extends RefCounted
## Derives a creature's AC, saves, Perception, DCs, and HP from ability modifiers,
## proficiency ranks, level, and equipment (spec §4.5). Everything here is COMPUTED —
## never authored. Pure static math; the runtime Creature calls it in
## derive_defenses().


## AC = 10 + (Dex mod, capped by armor) + armor proficiency + armor item bonus.
static func armor_class(
		level: int, dex_mod: int, armor_rank: Ids.ProficiencyRank,
		armor_item_bonus: int = 0, dex_cap: int = 99) -> int:
	return 10 + mini(dex_mod, dex_cap) + Proficiency.bonus(armor_rank, level) + armor_item_bonus


## A saving throw / Perception / skill total: ability mod + proficiency + item.
static func statistic(
		level: int, ability_mod: int, rank: Ids.ProficiencyRank, item_bonus: int = 0) -> int:
	return ability_mod + Proficiency.bonus(rank, level) + item_bonus


## A DC from a statistic: 10 + ability mod + proficiency (+ item).
static func dc(
		level: int, ability_mod: int, rank: Ids.ProficiencyRank, item_bonus: int = 0) -> int:
	return 10 + statistic(level, ability_mod, rank, item_bonus)


## Max HP = ancestry HP + (class HP/level + Con mod) × level.
static func max_hp(ancestry_hp: int, class_hp_per_level: int, con_mod: int, level: int) -> int:
	return ancestry_hp + (class_hp_per_level + con_mod) * level
