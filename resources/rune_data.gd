class_name RuneData
extends ItemData
## Rune (spec §5: invested runes → equipment modifiers). Stub.

@export var rune_kind: StringName = &"property"      ## fundamental | property
@export var potency: int = 0                         ## +1/+2/+3 for fundamental runes
