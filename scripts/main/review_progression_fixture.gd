extends RefCounted


static func prepare_guarded_salvage(main, salvage: Dictionary) -> Dictionary:
	if main == null or salvage.is_empty():
		return {"ready": false, "reason": "missing_fixture"}
	var required_capability := str(salvage.get("required_capability_id", ""))
	var profile = main._anomaly_survey.profile_state() if main._anomaly_survey != null else null
	if profile == null:
		return {"ready": false, "reason": "missing_profile"}
	if not required_capability.is_empty() and not profile.has_capability(required_capability):
		var project_result := _complete_capability_chain(main, profile, required_capability)
		if not bool(project_result.get("ready", false)):
			return project_result
		if main._material_project != null:
			main._material_project.on_map_loaded(main._world)

	var guard_id := str(salvage.get("guarded_by_hostile_id", ""))
	if not guard_id.is_empty():
		var guard_state: Dictionary = main._hostiles.state_for(guard_id)
		if guard_state.is_empty():
			return {"ready": false, "reason": "missing_guard", "guard_id": guard_id}
		for _hit in range(maxi(0, int(guard_state.get("health", 0)))):
			main._hostiles.apply_weapon_hit(main._world, guard_id, 1)
		guard_state = main._hostiles.state_for(guard_id)
		if str(guard_state.get("phase", "")) != "defeated":
			return {"ready": false, "reason": "guard_active", "guard_id": guard_id}
	return {"ready": true, "capability_id": required_capability, "guard_id": guard_id}


static func _complete_capability_chain(main, profile, capability_id: String) -> Dictionary:
	var projects: Array = main._world.get_material_projects()
	var target_project := _project_unlocking(projects, capability_id)
	if target_project.is_empty():
		return {"ready": false, "reason": "missing_project", "capability_id": capability_id}
	var completion := _complete_project(projects, profile, target_project)
	completion["ready"] = bool(completion.get("ready", false)) and profile.has_capability(capability_id)
	completion["capability_id"] = capability_id
	return completion


static func _complete_project(projects: Array, profile, project: Dictionary) -> Dictionary:
	var project_id := str(project.get("id", ""))
	if profile.has_completed_project(project_id):
		return {"ready": true, "reason": "already_completed", "project_id": project_id}
	var required_project_id := str(project.get("required_project_id", ""))
	if not required_project_id.is_empty():
		var prerequisite := _project_by_id(projects, required_project_id)
		if prerequisite.is_empty():
			return {"ready": false, "reason": "missing_prerequisite", "project_id": project_id, "required_project_id": required_project_id}
		var prerequisite_result := _complete_project(projects, profile, prerequisite)
		if not bool(prerequisite_result.get("ready", false)):
			return prerequisite_result
	var discovery_id := str(project.get("required_discovery_id", ""))
	if not discovery_id.is_empty() and not profile.has_completed_discovery(discovery_id):
		var discovery: Dictionary = profile.complete_discovery(discovery_id, false)
		if not bool(discovery.get("changed", false)):
			return {"ready": false, "reason": "discovery_failed", "project_id": project_id, "detail": discovery}
	var missing := {}
	var required: Dictionary = project.get("required_materials", {})
	for material_id in required:
		var quantity := maxi(0, int(required[material_id]) - profile.material_quantity(str(material_id)))
		if quantity > 0:
			missing[str(material_id)] = quantity
	if not missing.is_empty():
		var deposit: Dictionary = profile.deposit_materials(missing, false)
		if not bool(deposit.get("changed", false)):
			return {"ready": false, "reason": "material_fixture_failed", "project_id": project_id, "detail": deposit}
	var completion: Dictionary = profile.complete_material_project(project, false)
	if not bool(completion.get("changed", false)):
		return {"ready": false, "reason": "project_failed", "project_id": project_id, "detail": completion}
	return {"ready": true, "reason": "completed", "project_id": project_id}


static func _project_unlocking(projects: Array, capability_id: String) -> Dictionary:
	for project in projects:
		if str(project.get("unlocks_capability_id", "")) == capability_id:
			return project
	return {}


static func _project_by_id(projects: Array, project_id: String) -> Dictionary:
	for project in projects:
		if str(project.get("id", "")) == project_id:
			return project
	return {}
