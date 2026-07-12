extends RefCounted

const DEFAULT_PAYOFF_LABEL := "Destination cache"

var _payoffs_by_salvage_id := {}


func reset(salvage_list: Array, current_gates := []) -> void:
	_payoffs_by_salvage_id = {}
	var capability_gates_by_route := _capability_gates_by_route(current_gates)
	for salvage in salvage_list:
		var salvage_id := str(salvage.get("id", ""))
		var payoff_id := str(salvage.get("destination_payoff_id", ""))
		var route_context := str(salvage.get("route_context", "")).strip_edges()
		var capability_gate: Dictionary = capability_gates_by_route.get(route_context, {})
		if payoff_id.is_empty() and not capability_gate.is_empty():
			payoff_id = str(salvage.get("validation_route", "")).strip_edges()
		if salvage_id.is_empty() or payoff_id.is_empty():
			continue
		_payoffs_by_salvage_id[salvage_id] = {
			"id": payoff_id,
			"target_id": salvage_id,
			"label": _display_label(salvage, route_context),
			"connector_id": str(salvage.get("destination_payoff_connector_id", "")),
			"required_capability_id": str(capability_gate.get("required_capability_id", "")),
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


func return_prompt(world, position: Vector2, has_capability: Callable, held_ids: Array[String], banked_ids: Array[String]) -> String:
	if world == null or not world.has_method("is_inside_boat") or not world.is_inside_boat(position):
		return ""
	for payoff in _payoffs_by_salvage_id.values():
		var capability_id := str(payoff.get("required_capability_id", ""))
		var target_id := str(payoff.get("target_id", ""))
		if capability_id.is_empty() or target_id.is_empty():
			continue
		if not has_capability.is_valid() or not bool(has_capability.call(capability_id)):
			continue
		if held_ids.has(target_id) or banked_ids.has(target_id) or world.is_salvage_collected(target_id):
			continue
		return "%s ready | Return: %s" % [
			_capability_label(capability_id),
			str(payoff.get("label", DEFAULT_PAYOFF_LABEL)).to_lower(),
		]
	return ""


func _capability_gates_by_route(current_gates: Array) -> Dictionary:
	var gates := {}
	for gate in current_gates:
		var route_context := str(gate.get("route_context", "")).strip_edges()
		var capability_id := str(gate.get("required_capability_id", "")).strip_edges()
		if not route_context.is_empty() and not capability_id.is_empty():
			gates[route_context] = gate.duplicate(true)
	return gates


func _display_label(salvage: Dictionary, route_context := "") -> String:
	var label := str(salvage.get("destination_payoff_label", "")).strip_edges()
	if label.is_empty() and not route_context.is_empty():
		label = route_context.replace("upper_right", "upper-right").replace("lower_left", "lower-left").replace("_", " ")
	if label.is_empty():
		return DEFAULT_PAYOFF_LABEL
	return label.substr(0, 1).to_upper() + label.substr(1)


func _capability_label(capability_id: String) -> String:
	if capability_id == "propulsion_fins":
		return "Fins"
	return capability_id.replace("_", " ").capitalize()
