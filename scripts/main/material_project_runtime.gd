extends RefCounted

const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

var _profile
var _projects: Array[Dictionary] = []
var _source_map_id := ""
var _last_completed_project_id := ""


func _init(profile_state) -> void:
	_profile = profile_state


func on_map_loaded(world) -> Dictionary:
	_projects = []
	_source_map_id = ""
	_last_completed_project_id = ""
	if world == null or not world.has_method("get_material_projects"):
		return report()
	for candidate in world.get_material_projects():
		var project_id := str(candidate.get("id", ""))
		if ExpansionProfileState.SUPPORTED_PROJECT_IDS.has(project_id):
			_projects.append(candidate.duplicate(true))
	if not _projects.is_empty():
		_source_map_id = str(world.map_id)
	return report()


func try_build(day_phase: String) -> Dictionary:
	if day_phase != ExpeditionDayState.PHASE_DEBRIEF:
		return _result(false, "wrong_phase", "Build projects during the night debrief")
	var project := _selected_project()
	if _profile == null or project.is_empty():
		return _result(false, "unavailable", "Project unavailable")
	var result: Dictionary = _profile.complete_material_project(project, true)
	if bool(result.get("changed", false)):
		_last_completed_project_id = str(project["id"])
	result["note"] = _note_for_reason(project, str(result.get("reason", "unavailable")))
	result["status"] = status()
	return result


func status() -> String:
	return _status_for(_selected_project())


func status_for(project_id: String) -> String:
	return _status_for(_project_by_id(project_id))


func debrief_lines() -> Array[String]:
	var project := _selected_project()
	var current_status := _status_for(project)
	if current_status == "unavailable":
		return []
	if current_status == "completed":
		return [_completed_text(project)]
	if current_status == "prerequisite_required":
		return ["%s: %s required" % [_project_prefix(project), _prerequisite_label(project)]]
	if current_status == "knowledge_required":
		return ["%s: anomaly knowledge required" % _project_prefix(project)]
	if current_status == "inconsistent_profile":
		return ["%s: profile repair required" % _project_prefix(project)]
	if current_status == "ready":
		return ["P: Build %s" % _project_action_label(project)]
	var required: Dictionary = project.get("required_materials", {})
	if str(project.get("id", "")) == ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID:
		return ["%s: Coil %d/%d | Gel %d/%d | Electro %d/%d" % [
			_project_prefix(project),
			_profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID),
			int(required.get(ExpansionProfileState.COIL_MATERIAL_ID, 0)),
			_profile.material_quantity(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID),
			int(required.get(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID, 0)),
			_profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID),
			int(required.get(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID, 0)),
		]]
	return ["%s: Ti %d/%d | Coil %d/%d" % [
		_project_prefix(project),
		_profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID),
		int(required.get(ExpansionProfileState.TITANIUM_MATERIAL_ID, 0)),
		_profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID),
		int(required.get(ExpansionProfileState.COIL_MATERIAL_ID, 0)),
	]]


func has_cutter() -> bool:
	return _profile != null and _profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID)


func has_current_stabilizer() -> bool:
	return _profile != null and _profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID)


func has_shock_prod() -> bool:
	return _profile != null and _profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID)


func has_shock_prod_capacitor() -> bool:
	return _profile != null and _profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPACITOR_CAPABILITY_ID)


func project_definition() -> Dictionary:
	return _selected_project().duplicate(true)


func project_definition_for(project_id: String) -> Dictionary:
	return _project_by_id(project_id).duplicate(true)


func report() -> Dictionary:
	var project := _selected_project()
	var project_id := str(project.get("id", ""))
	return {
		"status": _status_for(project),
		"source_map_id": _source_map_id,
		"project_id": project_id,
		"project_count": _projects.size(),
		"project_ids": _project_ids(),
		"required_discovery_id": str(project.get("required_discovery_id", "")),
		"required_project_id": str(project.get("required_project_id", "")),
		"required_materials": project.get("required_materials", {}).duplicate(true),
		"titanium_banked": _profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) if _profile != null else 0,
		"coil_banked": _profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) if _profile != null else 0,
		"project_completed": _profile.has_completed_project(project_id) if _profile != null and not project_id.is_empty() else false,
		"cutter_unlocked": has_cutter(),
		"current_stabilizer_unlocked": has_current_stabilizer(),
		"shock_prod_unlocked": has_shock_prod(),
		"shock_prod_capacitor_unlocked": has_shock_prod_capacitor(),
	}


func _selected_project() -> Dictionary:
	if not _last_completed_project_id.is_empty():
		return _project_by_id(_last_completed_project_id)
	for project in _projects:
		if _profile == null or not _profile.has_completed_project(str(project.get("id", ""))):
			return project
	return _projects[-1] if not _projects.is_empty() else {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _projects:
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _project_ids() -> Array[String]:
	var ids: Array[String] = []
	for project in _projects:
		ids.append(str(project.get("id", "")))
	return ids


func _status_for(project: Dictionary) -> String:
	if _profile == null or project.is_empty():
		return "unavailable"
	var project_id := str(project.get("id", ""))
	var capability_id := str(project.get("unlocks_capability_id", ""))
	var project_complete: bool = _profile.has_completed_project(project_id)
	var capability_unlocked: bool = _profile.has_capability(capability_id)
	if project_complete != capability_unlocked:
		return "inconsistent_profile"
	if project_complete:
		return "completed"
	var required_project_id := str(project.get("required_project_id", ""))
	if not required_project_id.is_empty() and not _profile.has_completed_project(required_project_id):
		return "prerequisite_required"
	if not _profile.has_completed_discovery(str(project.get("required_discovery_id", ""))):
		return "knowledge_required"
	var required: Dictionary = project.get("required_materials", {})
	for material_id in required:
		if _profile.material_quantity(str(material_id)) < int(required[material_id]):
			return "incomplete"
	return "ready"


func _note_for_reason(project: Dictionary, reason: String) -> String:
	if reason == "completed":
		return _completed_text(project)
	if reason == "already_completed":
		return "%s already built" % _project_action_label(project).capitalize()
	if reason == "missing_project":
		return "%s needs the %s" % [_project_prefix(project), _prerequisite_project_label(project)]
	if reason == "missing_discovery":
		return "%s needs anomaly knowledge" % _project_prefix(project)
	if reason == "insufficient_materials":
		return "%s needs banked materials" % _project_prefix(project)
	if reason == "storage_error":
		return "%s save failed - materials restored" % _project_prefix(project)
	if reason == "inconsistent_profile":
		return "%s profile state is inconsistent" % _project_prefix(project)
	return "%s unavailable" % _project_prefix(project)


func _project_prefix(project: Dictionary) -> String:
	var source_label := str(project.get("project_label", "")).strip_edges()
	if not source_label.is_empty():
		return source_label
	return "Stabilizer project" if str(project.get("id", "")) == ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID else "Cutter project"


func _project_action_label(project: Dictionary) -> String:
	return str(project.get("unlocks_capability_id", "project")).replace("_", " ")


func _completed_text(project: Dictionary) -> String:
	var source_label := str(project.get("completion_label", "")).strip_edges()
	if not source_label.is_empty():
		return source_label
	return "Current stabilizer built" if str(project.get("id", "")) == ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID else "Salvage cutter built"


func _prerequisite_label(project: Dictionary) -> String:
	if str(project.get("id", "")) == ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID:
		return "shock prod"
	return "cutter" if str(project.get("id", "")) == ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID else "current stabilizer"


func _prerequisite_project_label(project: Dictionary) -> String:
	if str(project.get("id", "")) == ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID:
		return "shock prod project"
	return "salvage cutter project" if str(project.get("id", "")) == ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID else "current stabilizer project"


func _result(changed: bool, reason: String, note: String) -> Dictionary:
	return {"changed": changed, "reason": reason, "note": note, "status": status()}
