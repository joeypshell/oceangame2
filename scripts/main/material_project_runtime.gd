extends RefCounted

const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

var _profile
var _project := {}
var _source_map_id := ""


func _init(profile_state) -> void:
	_profile = profile_state


func on_map_loaded(world) -> Dictionary:
	_project = {}
	_source_map_id = ""
	if world == null or not world.has_method("get_material_projects"):
		return report()
	for candidate in world.get_material_projects():
		if str(candidate.get("id", "")) == ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID:
			_project = candidate.duplicate(true)
			_source_map_id = str(world.map_id)
			break
	return report()


func try_build(day_phase: String) -> Dictionary:
	if day_phase != ExpeditionDayState.PHASE_DEBRIEF:
		return _result(false, "wrong_phase", "Build the cutter during the night debrief")
	if _profile == null or _project.is_empty():
		return _result(false, "unavailable", "Cutter project unavailable")
	var result: Dictionary = _profile.complete_material_project(_project, true)
	result["note"] = _note_for_reason(str(result.get("reason", "unavailable")))
	result["status"] = status()
	return result


func status() -> String:
	if _profile == null or _project.is_empty():
		return "unavailable"
	var project_complete: bool = _profile.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID)
	var cutter_unlocked: bool = _profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID)
	if project_complete != cutter_unlocked:
		return "inconsistent_profile"
	if project_complete:
		return "completed"
	if not _profile.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID):
		return "knowledge_required"
	if (
		_profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) < 2
		or _profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) < 1
	):
		return "incomplete"
	return "ready"


func debrief_lines() -> Array[String]:
	var current_status := status()
	if current_status == "unavailable":
		return []
	if current_status == "completed":
		return ["Salvage cutter built"]
	if current_status == "knowledge_required":
		return ["Cutter project: anomaly knowledge required"]
	if current_status == "inconsistent_profile":
		return ["Cutter project: profile repair required"]
	if current_status == "ready":
		return ["P: Build salvage cutter"]
	return ["Cutter project: Ti %d/2 | Coil %d/1" % [
		_profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID),
		_profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID),
	]]


func has_cutter() -> bool:
	return _profile != null and _profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID)


func project_definition() -> Dictionary:
	return _project.duplicate(true)


func report() -> Dictionary:
	return {
		"status": status(),
		"source_map_id": _source_map_id,
		"project_id": str(_project.get("id", "")),
		"required_discovery_id": str(_project.get("required_discovery_id", "")),
		"required_materials": _project.get("required_materials", {}).duplicate(true),
		"titanium_banked": _profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) if _profile != null else 0,
		"coil_banked": _profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) if _profile != null else 0,
		"project_completed": _profile.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID) if _profile != null else false,
		"cutter_unlocked": has_cutter(),
	}


func _note_for_reason(reason: String) -> String:
	if reason == "completed":
		return "Salvage cutter built"
	if reason == "already_completed":
		return "Salvage cutter already built"
	if reason == "missing_discovery":
		return "Cutter project needs anomaly knowledge"
	if reason == "insufficient_materials":
		return "Cutter project needs banked materials"
	if reason == "storage_error":
		return "Cutter project save failed - materials restored"
	if reason == "inconsistent_profile":
		return "Cutter project profile state is inconsistent"
	return "Cutter project unavailable"


func _result(changed: bool, reason: String, note: String) -> Dictionary:
	return {"changed": changed, "reason": reason, "note": note, "status": status()}
