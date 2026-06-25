class_name ActionData
extends GameData
## Authored shape for an action/activity (spec §4.1). [member cost]: 1/2/3 actions,
## 0 = free, -1 = reaction. Stub.

@export var cost: int = 1
@export var requirements: Array[StringName] = []
