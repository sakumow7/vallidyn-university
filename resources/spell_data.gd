class_name SpellData
extends GameData
## Spell (spec §4.7): rank, traditions, action cost. Heightening and effects are
## added by the importer / spellcasting milestone (M9). Stub.

@export var rank: int = 1
@export var traditions: Array[StringName] = []       ## arcane/divine/occult/primal
@export var actions: int = 2
@export var is_cantrip: bool = false
