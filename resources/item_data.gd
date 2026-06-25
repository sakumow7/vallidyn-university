class_name ItemData
extends GameData
## Base for equipment (spec §5: items + invested runes → equipment modifiers).
## Weapons and armor extend this. Stub.

@export var level: int = 0
@export var price_cp: int = 0          ## price in copper pieces
@export var bulk: float = 0.0
