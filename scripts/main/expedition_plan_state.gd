extends RefCounted

const PHASE_DEBRIEF := "debrief"

var _selected_lead_id := ""


func select(lead_id: String, eligible_ids: Array, day_phase: String) -> Dictionary:
	return _set_selection(lead_id, eligible_ids, day_phase)


func replace(lead_id: String, eligible_ids: Array, day_phase: String) -> Dictionary:
	return _set_selection(lead_id, eligible_ids, day_phase)


func clear(reason := "cleared") -> Dictionary:
	var previous_id := _selected_lead_id
	_selected_lead_id = ""
	return _result(not previous_id.is_empty(), str(reason), previous_id)


func reconcile(eligible_ids: Array) -> Dictionary:
	if _selected_lead_id.is_empty():
		return _result(false, "no_selection")
	if _contains_id(eligible_ids, _selected_lead_id):
		return _result(false, "preserved")
	return clear("invalidated")


func has_selection() -> bool:
	return not _selected_lead_id.is_empty()


func selected_lead_id() -> String:
	return _selected_lead_id


func report() -> Dictionary:
	return {
		"selected_lead_id": _selected_lead_id,
		"has_selection": has_selection(),
	}


func _set_selection(lead_id: String, eligible_ids: Array, day_phase: String) -> Dictionary:
	var normalized_id := lead_id.strip_edges()
	if day_phase != PHASE_DEBRIEF:
		return _result(false, "wrong_phase")
	if normalized_id.is_empty() or not _contains_id(eligible_ids, normalized_id):
		return _result(false, "invalid_lead")
	var previous_id := _selected_lead_id
	if previous_id == normalized_id:
		return _result(false, "already_selected", previous_id)
	_selected_lead_id = normalized_id
	return _result(true, "selected" if previous_id.is_empty() else "replaced", previous_id)


func _contains_id(ids: Array, expected_id: String) -> bool:
	for value in ids:
		if str(value) == expected_id:
			return true
	return false


func _result(changed: bool, reason: String, previous_id := "") -> Dictionary:
	return {
		"changed": changed,
		"reason": reason,
		"previous_lead_id": str(previous_id),
		"selected_lead_id": _selected_lead_id,
		"has_selection": has_selection(),
	}
