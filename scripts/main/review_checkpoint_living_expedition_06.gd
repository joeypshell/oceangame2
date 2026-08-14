extends RefCounted

const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const ANCHOR_READY_ID := "living_expedition_06_anchor_ready"
const GUARDIAN_READY_ID := "living_expedition_06_guardian_ready"
const RESTORED_NURSERY_ID := "living_expedition_06_restored_nursery"
const ANCHOR_START_TILE := Vector2i(147, 76)
const GUARDIAN_START_TILE := Vector2i(130, 104)
const RESTORED_START_TILE := Vector2i(140, 111)
const KITE_ID := CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID
const ANCHOR_ADAPTATION_ID := "anchor_fins"
const GUARDIAN_ADAPTATION_ID := "guardian_pulse"
const ANCHOR_MEMORY_ID := "held_the_flow"
const GUARDIAN_MEMORY_ID := "stood_ground"
const REQUIRED_CAPABILITIES := [
	ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID,
	ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID,
]


static func is_supported(checkpoint_id: String) -> bool:
	return checkpoint_id in [ANCHOR_READY_ID, GUARDIAN_READY_ID, RESTORED_NURSERY_ID]


static func apply(checkpoint_id: String, profile, map_path: String) -> Dictionary:
	if not is_supported(checkpoint_id):
		return _result(false, checkpoint_id, "unsupported_checkpoint")
	var source := _load_source(map_path)
	if not bool(source.get("ready", false)):
		return _result(false, checkpoint_id, str(source.get("reason", "source_error")), source)
	for capability_id in REQUIRED_CAPABILITIES:
		var capability := _complete_capability(profile, source.get("projects", []), capability_id)
		if not bool(capability.get("ready", false)):
			return _result(false, checkpoint_id, "capability_fixture_failed", capability)
	var rescue: Dictionary = profile.commit_companion_rescue(KITE_ID, "spark_ray", "Kite", false)
	if not bool(rescue.get("changed", false)):
		return _result(false, checkpoint_id, "kite_fixture_failed", rescue)
	var adaptation_id := GUARDIAN_ADAPTATION_ID if checkpoint_id == GUARDIAN_READY_ID else ANCHOR_ADAPTATION_ID
	var memory_id := GUARDIAN_MEMORY_ID if adaptation_id == GUARDIAN_ADAPTATION_ID else ANCHOR_MEMORY_ID
	var memory: Dictionary = profile.earn_companion_memory(memory_id, false)
	var adaptation: Dictionary = profile.select_companion_adaptation(adaptation_id, false)
	if not bool(memory.get("changed", false)) or not bool(adaptation.get("changed", false)):
		return _result(false, checkpoint_id, "adaptation_fixture_failed", {"memory": memory, "adaptation": adaptation})
	if checkpoint_id == RESTORED_NURSERY_ID:
		var committed: Dictionary = profile.commit_signal_reef_journey(adaptation_id, "production_level_01", "surface_boat_entry", 4, false)
		var restored: Dictionary = profile.advance_signal_reef_journey_day(5, false)
		if not bool(committed.get("changed", false)) or not bool(restored.get("changed", false)):
			return _result(false, checkpoint_id, "journey_fixture_failed", {"commit": committed, "restore": restored})
	if not boundary_is_ready(checkpoint_id, profile):
		return _result(false, checkpoint_id, "checkpoint_boundary_drift", profile.report())
	return _result(true, checkpoint_id, "ready", _review_result(checkpoint_id, map_path, adaptation_id))


static func boundary_is_ready(checkpoint_id: String, profile) -> bool:
	if not is_supported(checkpoint_id):
		return false
	var companion: Dictionary = profile.companion_report()
	var active: Dictionary = companion.get("individual", {})
	var expected_adaptation := GUARDIAN_ADAPTATION_ID if checkpoint_id == GUARDIAN_READY_ID else ANCHOR_ADAPTATION_ID
	var expected_state := "restored" if checkpoint_id == RESTORED_NURSERY_ID else "unresolved"
	return (
		profile.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID)
		and profile.has_capability(ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID)
		and profile.material_inventory().is_empty()
		and (companion.get("individuals", []) as Array).size() == 1
		and str(companion.get("active_individual_id", "")) == KITE_ID
		and str(active.get("selected_adaptation_id", "")) == expected_adaptation
		and str(profile.signal_reef_journey_report().get("state", "")) == expected_state
	)


static func _review_result(checkpoint_id: String, map_path: String, adaptation_id: String) -> Dictionary:
	var start_tile := ANCHOR_START_TILE
	var target_id := "lower_right_east_current_gate"
	var objective_label := "Signal Reef Anchor response"
	if checkpoint_id == GUARDIAN_READY_ID:
		start_tile = GUARDIAN_START_TILE
		target_id = "signal_reef_jellyfish_pressure_01"
		objective_label = "Signal Reef Guardian response"
	elif checkpoint_id == RESTORED_NURSERY_ID:
		start_tile = RESTORED_START_TILE
		target_id = "signal_reef_filter_skate_nursery_01"
		objective_label = "Restored Signal Reef nursery"
	return {
		"map_path": map_path,
		"day_number": 5 if checkpoint_id == RESTORED_NURSERY_ID else 4,
		"review_oxygen_seconds": 180.0,
		"review_start_tile": {"x": float(start_tile.x), "y": float(start_tile.y)},
		"review_target_id": target_id,
		"active_objective_id": "signal_reef_nursery_journey_01",
		"active_objective_label": objective_label,
		"selected_adaptation_id": adaptation_id,
	}


static func _complete_capability(profile, projects: Array, capability_id: String) -> Dictionary:
	if profile.has_capability(capability_id):
		return {"ready": true, "reason": "already_completed"}
	var project := _project_unlocking(projects, capability_id)
	if project.is_empty():
		return {"ready": false, "reason": "missing_project", "capability_id": capability_id}
	var prerequisite_id := str(project.get("required_project_id", ""))
	if not prerequisite_id.is_empty() and not profile.has_completed_project(prerequisite_id):
		var prerequisite := _project_by_id(projects, prerequisite_id)
		var prerequisite_result := _complete_capability(profile, projects, str(prerequisite.get("unlocks_capability_id", "")))
		if not bool(prerequisite_result.get("ready", false)):
			return prerequisite_result
	var discovery_id := str(project.get("required_discovery_id", ""))
	if not discovery_id.is_empty() and not profile.has_completed_discovery(discovery_id):
		var discovery: Dictionary = profile.complete_discovery(discovery_id, false)
		if not bool(discovery.get("changed", false)):
			return {"ready": false, "reason": "discovery_fixture_failed", "detail": discovery}
	var materials := {}
	for material_id in project.get("required_materials", {}):
		materials[str(material_id)] = int(project.get("required_materials", {})[material_id])
	if not materials.is_empty():
		var deposit: Dictionary = profile.deposit_materials(materials, false)
		if not bool(deposit.get("changed", false)):
			return {"ready": false, "reason": "material_fixture_failed", "detail": deposit}
	var completed: Dictionary = profile.complete_material_project(project, false)
	return {"ready": bool(completed.get("changed", false)), "reason": str(completed.get("reason", "project_failed")), "detail": completed}


static func _load_source(map_path: String) -> Dictionary:
	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		return {"ready": false, "reason": "map_open_failed", "map_path": map_path}
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"ready": false, "reason": "map_parse_failed", "map_path": map_path}
	var projects = json.data.get("material_projects", [])
	return {"ready": typeof(projects) == TYPE_ARRAY, "reason": "ready", "projects": projects}


static func _project_unlocking(projects: Array, capability_id: String) -> Dictionary:
	for project in projects:
		if typeof(project) == TYPE_DICTIONARY and str(project.get("unlocks_capability_id", "")) == capability_id:
			return project.duplicate(true)
	return {}


static func _project_by_id(projects: Array, project_id: String) -> Dictionary:
	for project in projects:
		if typeof(project) == TYPE_DICTIONARY and str(project.get("id", "")) == project_id:
			return project.duplicate(true)
	return {}


static func _result(ready: bool, checkpoint_id: String, reason: String, extra := {}) -> Dictionary:
	var result := {"ready": ready, "checkpoint_id": checkpoint_id, "reason": reason}
	for key in extra:
		result[key] = extra[key]
	return result
