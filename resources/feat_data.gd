class_name FeatData
extends GameData
## Feat (spec §5): prerequisites + effect hooks. Mythic feats reuse this shape via
## MythicData (spec §7). [member action_cost] 0 = passive. Stub.

@export var level: int = 1
@export var action_cost: int = 0
@export var prerequisites: Array[StringName] = []
