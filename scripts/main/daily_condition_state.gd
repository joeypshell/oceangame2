extends RefCounted

const BASELINE_FORECAST_LABEL := "Tomorrow: Baseline waters"

var _definitions_by_id := {}
var _day_number := 1
var _current_ids: Array[String] = []
var _next_ids: Array[String] = []


func sync(definitions: Array, day_number: int) -> Dictionary:
	for value in definitions:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var definition := value as Dictionary
		var condition_id := str(definition.get("id", ""))
		if not condition_id.is_empty():
			_definitions_by_id[condition_id] = definition.duplicate(true)
	_day_number = maxi(1, day_number)
	_current_ids = _ids_for_day(_day_number)
	_next_ids = _ids_for_day(_day_number + 1)
	return report()


func current_ids() -> Array[String]:
	return _current_ids.duplicate()


func next_ids() -> Array[String]:
	return _next_ids.duplicate()


func active_label() -> String:
	return _first_label(_current_ids, "active_label")


func forecast_label() -> String:
	var label := _first_label(_next_ids, "forecast_label")
	return BASELINE_FORECAST_LABEL if label.is_empty() else label


func report() -> Dictionary:
	return {
		"day_number": _day_number,
		"current_condition_ids": current_ids(),
		"next_condition_ids": next_ids(),
		"active_label": active_label(),
		"forecast_label": forecast_label(),
	}


func _ids_for_day(day_number: int) -> Array[String]:
	var ids: Array[String] = []
	var definition_ids: Array = _definitions_by_id.keys()
	definition_ids.sort()
	for value in definition_ids:
		var condition_id := str(value)
		var definition: Dictionary = _definitions_by_id[condition_id]
		if _schedule_active(str(definition.get("schedule", "")), day_number):
			ids.append(condition_id)
	return ids


func _first_label(condition_ids: Array[String], field: String) -> String:
	for condition_id in condition_ids:
		var definition: Dictionary = _definitions_by_id.get(condition_id, {})
		var label := str(definition.get(field, "")).strip_edges()
		if not label.is_empty():
			return label
	return ""


func _schedule_active(schedule: String, day_number: int) -> bool:
	return schedule == "even_days_v1" and maxi(1, day_number) % 2 == 0
