extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const SCANNER_TOOL_ID := ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID
const CUTTER_TOOL_ID := ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID
const SHOCK_PROD_TOOL_ID := ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID
const USE_STATUSES := ["used", "unavailable", "wrong_context", "no_tool"]
const TOOL_CATALOG := [
	{"id": SCANNER_TOOL_ID, "label": "Scanner"},
	{"id": CUTTER_TOOL_ID, "label": "Cutter"},
	{"id": SHOCK_PROD_TOOL_ID, "label": "Shock prod"},
]

var _selected_tool_id := ""


func refresh_ownership(has_capability: Callable) -> Dictionary:
	var owned_ids := _owned_tool_ids(has_capability)
	if not owned_ids.has(_selected_tool_id):
		_selected_tool_id = owned_ids[0] if not owned_ids.is_empty() else ""
	return report(has_capability)


func cycle_next(has_capability: Callable) -> Dictionary:
	var owned_ids := _owned_tool_ids(has_capability)
	if owned_ids.is_empty():
		_selected_tool_id = ""
		return report(has_capability)
	var selected_index := owned_ids.find(_selected_tool_id)
	_selected_tool_id = owned_ids[(selected_index + 1) % owned_ids.size()] if selected_index >= 0 else owned_ids[0]
	return report(has_capability)


func use_selected(has_capability: Callable, dispatch_tool: Callable) -> Dictionary:
	refresh_ownership(has_capability)
	if _selected_tool_id.is_empty():
		return _use_result("no_tool", "")
	if not dispatch_tool.is_valid():
		return _use_result("unavailable", _selected_tool_id)

	var raw_result = dispatch_tool.call(_selected_tool_id)
	var result: Dictionary = raw_result.duplicate(true) if raw_result is Dictionary else {}
	var default_status := "used" if raw_result is Dictionary or raw_result == true else "unavailable"
	var status := str(result.get("status", default_status))
	if not USE_STATUSES.has(status):
		status = "unavailable"
	result["status"] = status
	result["tool_id"] = _selected_tool_id
	return result


func selected_tool_id() -> String:
	return _selected_tool_id


func selected_label() -> String:
	return tool_label(_selected_tool_id)


func report(has_capability: Callable) -> Dictionary:
	var owned_ids := _owned_tool_ids(has_capability)
	return {
		"selected_tool_id": _selected_tool_id,
		"selected_label": selected_label(),
		"owned_tool_ids": owned_ids,
		"tool_count": owned_ids.size(),
	}


static func ordered_tool_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for entry in TOOL_CATALOG:
		ids.append(str(entry["id"]))
	return ids


static func tool_label(tool_id: String) -> String:
	for entry in TOOL_CATALOG:
		if str(entry["id"]) == tool_id:
			return str(entry["label"])
	return ""


func _owned_tool_ids(has_capability: Callable) -> PackedStringArray:
	var ids := PackedStringArray()
	if not has_capability.is_valid():
		return ids
	for entry in TOOL_CATALOG:
		var tool_id := str(entry["id"])
		if bool(has_capability.call(tool_id)):
			ids.append(tool_id)
	return ids


func _use_result(status: String, tool_id: String) -> Dictionary:
	return {"status": status, "tool_id": tool_id}
