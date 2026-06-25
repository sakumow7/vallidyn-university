class_name Proficiency
extends RefCounted
## Proficiency math (spec §4.5): a trained-or-better statistic adds your level plus
## the rank bonus (+2/+4/+6/+8). UNTRAINED adds NOTHING — not even your level. That
## untrained-doesn't-add-level rule is the classic PF2e gotcha, isolated here so every
## derived statistic gets it right.
##
## (The class is Proficiency; the rank enum is Ids.ProficiencyRank.)


static func bonus(rank: Ids.ProficiencyRank, level: int) -> int:
	if rank == Ids.ProficiencyRank.UNTRAINED:
		return 0
	return level + Ids.proficiency_bonus(rank)


static func is_trained(rank: Ids.ProficiencyRank) -> bool:
	return rank != Ids.ProficiencyRank.UNTRAINED
