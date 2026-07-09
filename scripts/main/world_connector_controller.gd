extends RefCounted


func connector_at(world, player_position: Vector2) -> Dictionary:
	if world == null or not world.has_method("get_world_connector_at"):
		return {}
	return world.get_world_connector_at(player_position)


func prompt_for(world, player_position: Vector2) -> String:
	var connector := connector_at(world, player_position)
	if connector.is_empty():
		return ""
	return "E: Enter %s" % _connector_label(connector)


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
