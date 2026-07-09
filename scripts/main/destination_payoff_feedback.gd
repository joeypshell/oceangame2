extends RefCounted

const DEFAULT_PAYOFF_LABEL := "Destination cache"

var _payoffs_by_salvage_id := {}


func reset(salvage_list: Array) -> void:
	_payoffs_by_salvage_id = {}
	for salvage in salvage_list:
		var salvage_id := str(salvage.get("id", ""))
		var payoff_id := str(salvage.get("destination_payoff_id", ""))
		if salvage_id.is_empty() or payoff_id.is_empty():
			continue
		_payoffs_by_salvage_id[salvage_id] = {
			"id": payoff_id,
			"label": _display_label(salvage),
			"connector_id": str(salvage.get("destination_payoff_connector_id", "")),
		}


func collection_feedback(salvage_id: String, score: int) -> String:
	var payoff: Dictionary = _payoffs_by_salvage_id.get(salvage_id, {})
	if payoff.is_empty():
		return ""
	return "%s +%d" % [str(payoff.get("label", DEFAULT_PAYOFF_LABEL)), score]


func route_label(validation_route: String) -> String:
	for payoff in _payoffs_by_salvage_id.values():
		if str(payoff.get("id", "")) == validation_route:
			return str(payoff.get("label", DEFAULT_PAYOFF_LABEL))
	return ""


func is_collection_note(status_note: String) -> bool:
	if status_note.is_empty():
		return false
	for payoff in _payoffs_by_salvage_id.values():
		var label := str(payoff.get("label", DEFAULT_PAYOFF_LABEL))
		if status_note.begins_with("%s +" % label):
			return true
	return false


func _display_label(salvage: Dictionary) -> String:
	var label := str(salvage.get("destination_payoff_label", "")).strip_edges()
	if label.is_empty():
		return DEFAULT_PAYOFF_LABEL
	return label
