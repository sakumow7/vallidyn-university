class_name CreatureData
extends GameData
## A pre-statted NPC / monster. For player characters the runtime Creature is
## COMPILED from a CharacterBuild (spec §5) rather than authored; this is the
## authored shape for bestiary entries. Stub — expanded by the importer (M13).

@export var level: int = 0
@export var size: StringName = &"medium"
@export var ability_mods: Dictionary = {}            ## { &"str": 4, &"dex": 2, ... }
@export var ac: int = 10
@export var hp: int = 0
@export var saves: Dictionary = {}                   ## { &"fort": 5, &"ref": 7, ... }
@export var speed: int = 25
