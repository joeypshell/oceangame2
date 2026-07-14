extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")


static func complete_scanner(profile, world, persist := false) -> Dictionary:
	if profile == null or world == null:
		return {"changed": false, "reason": "missing_fixture_owner"}
	if profile.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID):
		return {"changed": false, "reason": "already_completed"}
	var discovery: Dictionary = profile.complete_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID, false)
	if not bool(discovery.get("changed", false)) and discovery.get("reason") != "already_completed":
		return discovery
	var project := _project_by_id(world, ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID)
	if project.is_empty():
		return {"changed": false, "reason": "missing_scanner_project"}
	var deposit := {}
	for material_id in project.get("required_materials", {}):
		var missing: int = int(project["required_materials"][material_id]) - profile.material_quantity(str(material_id))
		if missing > 0:
			deposit[material_id] = missing
	if not deposit.is_empty():
		var deposited: Dictionary = profile.deposit_materials(deposit, false)
		if not bool(deposited.get("changed", false)):
			return deposited
	return profile.complete_material_project(project, persist)


static func _project_by_id(world, project_id: String) -> Dictionary:
	for project in world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}
