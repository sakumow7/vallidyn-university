class_name WeaponData
extends ItemData
## Weapon (spec §4.5 damage, §4.1 MAP via the agile trait). Weapon traits live in the
## inherited [member GameData.traits] (agile/finesse/reach…). Stub.

@export var damage_dice: String = "1d4"
@export var damage_type: StringName = &"bludgeoning"
@export var weapon_group: StringName
@export var hands: int = 1
