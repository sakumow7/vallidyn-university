class_name GameData
extends Resource
## Common base for every imported content resource. [member source] carries
## provenance (spec §0) so Paizo-derived data stays traceable and strippable, and
## [member traits] lets the engine key mechanics off data rather than proper names.
## Subclasses add their mechanical fields; the Foundry importer (spec §10, M13) fills
## and extends them. These schemas are intentionally lean at this milestone.

@export var id: StringName
@export var display_name: String
@export var source: StringName            ## e.g. &"pf2e-foundry@<version>"
@export var traits: Array[StringName] = []
@export var rarity: StringName = &"common"
