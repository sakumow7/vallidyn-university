class_name ClassData
extends GameData
## Class (spec §5): key ability, HP/level, proficiencies, class features and feats.
## Only the most certain fields are modeled now; the importer (M13) adds the rest.

@export var key_ability: Array[StringName] = []      ## one, or a player choice
@export var hp_per_level: int = 8
