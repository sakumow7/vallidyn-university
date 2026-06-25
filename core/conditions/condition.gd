class_name ConditionInstance
extends RefCounted
## One runtime condition on a creature (spec §4.4): which condition it is, its value
## (for valued conditions like frightened N; 0 for binary ones), where it came from,
## and how long it lasts. The mechanical EFFECTS — emitted modifiers, implied
## conditions, decrement behavior — are defined by [ConditionEngine]'s rules
## registry; this object is just the per-creature instance state.
##
## (Named ConditionInstance, not Condition, to avoid clashing with the
## [enum Ids.Condition] identity enum.)

var id: Ids.Condition
var value: int               ## valued conditions; 0 for binary
var source: StringName       ## human-readable origin for the log ("Demoralize")
var duration_rounds: int     ## remaining rounds; -1 = indefinite (until removed)


func _init(
		p_id: Ids.Condition,
		p_value: int = 0,
		p_source: StringName = &"",
		p_duration_rounds: int = -1) -> void:
	id = p_id
	value = p_value
	source = p_source
	duration_rounds = p_duration_rounds


func is_indefinite() -> bool:
	return duration_rounds < 0


func _to_string() -> String:
	var label := ConditionEngine.display_name(id)
	if ConditionEngine.is_valued(id):
		label += " %d" % value
	return label
