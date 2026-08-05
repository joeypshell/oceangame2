extends RefCounted


static func validate_version(
	payload: Dictionary,
	allowed_keys: Dictionary,
	discovery_ids: Dictionary,
	capability_ids: Dictionary,
	material_ids: Dictionary,
	project_ids: Dictionary,
	project_rules: Dictionary,
	include_materials: bool
) -> Array[String]:
	var failures: Array[String] = []
	for required_key in allowed_keys:
		if not payload.has(required_key):
			failures.append("missing %s" % required_key)
	for key in payload:
		if not allowed_keys.has(str(key)):
			failures.append("unsupported field %s" % key)
	failures.append_array(validate_id_array(payload.get("completed_discoveries"), discovery_ids, "completed_discoveries"))
	failures.append_array(validate_id_array(payload.get("unlocked_capabilities"), capability_ids, "unlocked_capabilities"))
	if include_materials:
		failures.append_array(validate_material_inventory(payload.get("material_inventory"), material_ids))
		failures.append_array(validate_id_array(payload.get("completed_projects"), project_ids, "completed_projects"))
		failures.append_array(validate_project_capability_pairs(payload, project_ids, project_rules))
	return failures


static func validate_id_array(value, supported_ids: Dictionary, field: String) -> Array[String]:
	var failures: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return ["%s must be an array" % field]
	var seen := {}
	for item in value:
		if typeof(item) != TYPE_STRING or not supported_ids.has(str(item)):
			failures.append("%s contains unsupported id %s" % [field, str(item)])
		elif seen.has(str(item)):
			failures.append("%s contains duplicate id %s" % [field, str(item)])
		else:
			seen[str(item)] = true
	return failures


static func validate_material_inventory(value, supported_ids: Dictionary) -> Array[String]:
	if typeof(value) != TYPE_DICTIONARY:
		return ["material_inventory must be an object"]
	var failures: Array[String] = []
	for material_id in value:
		if not supported_ids.has(str(material_id)):
			failures.append("material_inventory contains unsupported id %s" % material_id)
		elif not _is_nonnegative_integer_value(value[material_id]):
			failures.append("material_inventory %s must be a non-negative integer" % material_id)
	return failures


static func validate_project_capability_pairs(
	payload: Dictionary,
	supported_projects: Dictionary,
	project_rules: Dictionary
) -> Array[String]:
	var capabilities = payload.get("unlocked_capabilities")
	var projects = payload.get("completed_projects")
	if typeof(capabilities) != TYPE_ARRAY or typeof(projects) != TYPE_ARRAY:
		return []
	var failures: Array[String] = []
	for project_id in supported_projects:
		var rules: Dictionary = project_rules[project_id]
		var capability_id := str(rules["capability_id"])
		if capabilities.has(capability_id) != projects.has(project_id):
			failures.append("%s capability and project must be completed together" % capability_id)
		var required_project_id := str(rules["required_project_id"])
		if projects.has(project_id) and not required_project_id.is_empty() and not projects.has(required_project_id):
			failures.append("%s requires completed %s" % [project_id, required_project_id])
	return failures


static func _is_nonnegative_integer_value(value) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return number >= 0.0 and is_equal_approx(number, float(int(number)))
