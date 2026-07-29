extends RefCounted

const SHOCK_PROD_ID := "shock_prod"
const SHOCK_PROD_CAPACITOR_ID := "shock_prod_capacitor"


static func snapshot(
	world,
	player_position: Vector2,
	pressure_report: Dictionary,
	oxygen_report: Dictionary,
	selected_tool_id: String
) -> Dictionary:
	var active_ids: Array[String] = []
	_append_report_zone(active_ids, world, oxygen_report)
	_append_report_zone(active_ids, world, pressure_report)
	if world != null and world.has_method("get_current_gate_at"):
		_append_requirement(active_ids, world.get_current_gate_at(player_position))
	if world != null and world.has_method("get_visibility_zone_at"):
		_append_requirement(active_ids, world.get_visibility_zone_at(player_position))
	if selected_tool_id == SHOCK_PROD_ID:
		_append_unique(active_ids, SHOCK_PROD_CAPACITOR_ID)
	return {"active_capability_ids": active_ids}


static func _append_report_zone(active_ids: Array[String], world, report: Dictionary) -> void:
	if not bool(report.get("inside", false)) and not bool(report.get("near_threshold", false)):
		return
	if world == null or not world.has_method("get_marker_zone"):
		return
	_append_requirement(active_ids, world.get_marker_zone(str(report.get("zone_id", ""))))


static func _append_requirement(active_ids: Array[String], source: Dictionary) -> void:
	var capability_id := str(source.get("required_capability_id", "")).strip_edges()
	if capability_id.is_empty():
		capability_id = str(source.get("required_upgrade_id", "")).strip_edges()
	_append_unique(active_ids, capability_id)


static func _append_unique(active_ids: Array[String], capability_id: String) -> void:
	if not capability_id.is_empty() and not active_ids.has(capability_id):
		active_ids.append(capability_id)
