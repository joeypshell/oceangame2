extends RefCounted

const MATERIAL_SCHEMA_VERSION := 2
const PROJECT_SCHEMA_VERSION := 3
const SCHEMA_VERSION := 4


static func apply(payload: Dictionary, ids: Dictionary) -> Dictionary:
	var scanner_migrated := _migrate_scanner_purchase_payload(payload, ids)
	var cutter_migrated := _migrate_cutter_blueprint_payload(payload, ids)
	return {
		"scanner_purchase": scanner_migrated,
		"cutter_blueprint": cutter_migrated,
	}


static func _migrate_scanner_purchase_payload(payload: Dictionary, ids: Dictionary) -> bool:
	if not _has_project_arrays(payload):
		return false
	var schema_version := int(payload.get("schema_version", 0))
	if schema_version not in [PROJECT_SCHEMA_VERSION, SCHEMA_VERSION]:
		return false
	if not payload.get("unlocked_capabilities", []).has(str(ids["survey_scanner_capability_id"])):
		return false
	if payload.get("completed_projects", []).has(str(ids["survey_scanner_project_id"])):
		return false
	if not payload["completed_discoveries"].has(str(ids["survey_scanner_blueprint_id"])):
		payload["completed_discoveries"].append(str(ids["survey_scanner_blueprint_id"]))
	payload["completed_projects"].append(str(ids["survey_scanner_project_id"]))
	return true


static func _migrate_cutter_blueprint_payload(payload: Dictionary, ids: Dictionary) -> bool:
	if not _has_project_arrays(payload):
		return false
	var schema_version := int(payload.get("schema_version", 0))
	if schema_version not in [MATERIAL_SCHEMA_VERSION, PROJECT_SCHEMA_VERSION, SCHEMA_VERSION]:
		return false
	var discoveries: Array = payload.get("completed_discoveries", [])
	var has_old_anomaly: bool = discoveries.has(str(ids["anomaly_discovery_id"]))
	var has_cutter_project: bool = payload.get("completed_projects", []).has(str(ids["salvage_cutter_project_id"]))
	var has_cutter_capability: bool = payload.get("unlocked_capabilities", []).has(str(ids["salvage_cutter_capability_id"]))
	var blueprint_id := str(ids["salvage_cutter_blueprint_id"])
	if discoveries.has(blueprint_id):
		return false
	if not has_old_anomaly and not has_cutter_project and not has_cutter_capability:
		return false
	discoveries.append(blueprint_id)
	return true


static func _has_project_arrays(payload: Dictionary) -> bool:
	return (
		typeof(payload.get("completed_discoveries")) == TYPE_ARRAY
		and typeof(payload.get("unlocked_capabilities")) == TYPE_ARRAY
		and typeof(payload.get("completed_projects")) == TYPE_ARRAY
	)
