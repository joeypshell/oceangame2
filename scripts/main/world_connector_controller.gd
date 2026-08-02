extends RefCounted


func connector_at(world, player_position: Vector2) -> Dictionary:
	if world == null or not world.has_method("get_world_connector_at"):
		return {}
	return world.get_world_connector_at(player_position)


func prompt_for(world, player_position: Vector2, has_discovery := Callable()) -> String:
	var connector := connector_at(world, player_position)
	if connector.is_empty():
		return ""
	var requirement := requirement_note(connector, has_discovery)
	if not requirement.is_empty():
		return requirement
	var exceptional_return := (
		str(connector.get("connector_kind", "")) == "exceptional_interior"
		and str(connector.get("connector_direction", "")) == "return"
	)
	var verb := "Return to" if exceptional_return else "Enter"
	return "E: %s %s" % [verb, _connector_label(connector)]


func requirement_note(connector: Dictionary, has_discovery := Callable()) -> String:
	var discovery_id := str(connector.get("required_discovery_id", "")).strip_edges()
	if discovery_id.is_empty():
		return ""
	if has_discovery.is_valid() and bool(has_discovery.call(discovery_id)):
		return ""
	return "%s | Coordinates not triangulated" % _connector_label(connector)


func arrival_note(connector: Dictionary) -> String:
	if connector.is_empty():
		return ""
	return "Arrived: %s" % _connector_label(connector)


func _connector_label(connector: Dictionary) -> String:
	var label := str(connector.get("connector_label", "")).strip_edges()
	if not label.is_empty():
		return label
	var destination := str(connector.get("destination_map_id", "")).strip_edges()
	if not destination.is_empty():
		return destination.replace("_", " ")
	return "connector"
