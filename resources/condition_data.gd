class_name ConditionData
extends GameData
## Authored shape for a condition (spec §4.4). The condition_engine (M5) turns these
## into runtime effects/modifiers. [member valued] distinguishes frightened N /
## clumsy N (valued) from prone / off-guard (binary). Stub.

@export var valued: bool = false
@export var max_value: int = 0                       ## 0 = unbounded / not applicable
@export var overridable: bool = true                 ## higher value replaces lower
