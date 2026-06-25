class_name Modifier
extends RefCounted
## One modifier on a roll or statistic (spec §4.3). [member value] is signed:
## positive = bonus, negative = penalty. [member type] drives stacking (resolved by
## [ModifierStack]). [member source] is a human-readable id for the combat log
## ("Frightened 2", "Bless", "flanking"). [member enabled] lets a condition toggle a
## modifier on/off without removing it from the stack.

var value: int
var type: Ids.ModifierType
var source: StringName
var enabled: bool


func _init(
		p_value: int,
		p_type: Ids.ModifierType,
		p_source: StringName = &"",
		p_enabled: bool = true) -> void:
	value = p_value
	type = p_type
	source = p_source
	enabled = p_enabled


func is_bonus() -> bool:
	return value > 0


func is_penalty() -> bool:
	return value < 0


func _to_string() -> String:
	var sign_str := "+" if value >= 0 else ""
	var type_name: String = Ids.MODIFIER_TYPE_NAMES.get(type, "?")
	return "%s%d %s (%s)" % [sign_str, value, type_name, source]
