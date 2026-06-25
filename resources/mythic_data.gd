class_name MythicData
extends GameData
## Mythic destiny/calling or mythic feat (spec §7). Kept in data/mythic so the whole
## layer stays swappable. Mythic abilities are modeled as feats/features with effect
## hooks, flowing through the same compile + modifier pipeline as everything else.
## A campaign Bond mechanic can later attach here as a mythic-adjacent resource. Stub.

@export var mythic_kind: StringName = &"feat"        ## destiny | calling | feat
@export var tier: int = 1
@export var prerequisites: Array[StringName] = []
