class_name AncestryData
extends GameData
## Ancestry (spec §5): ability boosts/flaws, HP, speed, size, granted ancestry feats.
## Stub — extended by the importer (M13).

@export var hp: int = 0
@export var size: StringName = &"medium"
@export var speed: int = 25
@export var ability_boosts: Array[StringName] = []   ## e.g. [&"str", &"free"]
@export var ability_flaws: Array[StringName] = []
@export var languages: Array[StringName] = []
