extends RefCounted

const ExpansionProfileValidator := preload("res://scripts/main/expansion_profile_validator.gd")

const SCHEMA_VERSION := 6
const COMPANION_SCHEMA_VERSION := 5
const TOOL_TARGET_SCHEMA_VERSION := 4
const PROJECT_SCHEMA_VERSION := 3
const MATERIAL_SCHEMA_VERSION := 2
const LEGACY_SCHEMA_VERSION := 1
const LEGACY_PROFILE_KEYS := {
	"schema_version": true,
	"completed_discoveries": true,
	"unlocked_capabilities": true,
}
const PROJECT_PROFILE_KEYS := {
	"schema_version": true,
	"completed_discoveries": true,
	"unlocked_capabilities": true,
	"material_inventory": true,
	"completed_projects": true,
}
const TOOL_TARGET_PROFILE_KEYS := {
	"schema_version": true,
	"completed_discoveries": true,
	"unlocked_capabilities": true,
	"material_inventory": true,
	"completed_projects": true,
	"banked_tool_target_ids": true,
}
const PROFILE_KEYS := {
	"schema_version": true,
	"completed_discoveries": true,
	"unlocked_capabilities": true,
	"material_inventory": true,
	"completed_projects": true,
	"banked_tool_target_ids": true,
	"companion_profile": true,
	"regional_journey_profile": true,
}


static func validate_payload(
	payload: Dictionary,
	supported: Dictionary,
	companion_profile,
	regional_journey_profile
) -> Array[String]:
	var schema = payload.get("schema_version")
	if schema == LEGACY_SCHEMA_VERSION:
		return _validate_version(payload, LEGACY_PROFILE_KEYS, supported, "legacy_capabilities", "empty_projects", false)
	if schema == MATERIAL_SCHEMA_VERSION:
		return _validate_version(payload, PROJECT_PROFILE_KEYS, supported, "material_capabilities", "material_projects", true)
	if schema == PROJECT_SCHEMA_VERSION:
		return _validate_version(payload, PROJECT_PROFILE_KEYS, supported, "capabilities", "projects", true)
	if schema != TOOL_TARGET_SCHEMA_VERSION and schema != COMPANION_SCHEMA_VERSION and schema != SCHEMA_VERSION:
		return ["unsupported schema_version"]
	var allowed_keys := PROFILE_KEYS.duplicate() if schema >= COMPANION_SCHEMA_VERSION else TOOL_TARGET_PROFILE_KEYS
	if schema == COMPANION_SCHEMA_VERSION:
		allowed_keys.erase("regional_journey_profile")
	var failures := _validate_version(payload, allowed_keys, supported, "capabilities", "projects", true)
	failures.append_array(ExpansionProfileValidator.validate_id_array(
		payload.get("banked_tool_target_ids"), supported["banked_targets"], "banked_tool_target_ids"
	))
	if schema >= COMPANION_SCHEMA_VERSION:
		if typeof(payload.get("companion_profile")) != TYPE_DICTIONARY:
			failures.append("companion_profile must be an object")
		else:
			failures.append_array(companion_profile.validate_payload(payload["companion_profile"]))
	if schema == SCHEMA_VERSION:
		if typeof(payload.get("regional_journey_profile")) != TYPE_DICTIONARY:
			failures.append("regional_journey_profile must be an object")
		else:
			failures.append_array(regional_journey_profile.validate_payload(payload["regional_journey_profile"]))
			if typeof(payload.get("companion_profile")) == TYPE_DICTIONARY:
				failures.append_array(regional_journey_profile.validate_companion_reference(
					payload["regional_journey_profile"], payload["companion_profile"]
				))
	return failures


static func _validate_version(
	payload: Dictionary,
	allowed_keys: Dictionary,
	supported: Dictionary,
	capability_key: String,
	project_key: String,
	include_materials: bool
) -> Array[String]:
	return ExpansionProfileValidator.validate_version(
		payload,
		allowed_keys,
		supported["discoveries"],
		supported[capability_key],
		supported["materials"],
		supported[project_key],
		supported["project_rules"],
		include_materials
	)
