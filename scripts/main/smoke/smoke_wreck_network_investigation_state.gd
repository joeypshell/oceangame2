extends SceneTree

const ExpeditionDiscoveryState := preload("res://scripts/main/expedition_discovery_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const WreckNetworkInvestigationState := preload("res://scripts/main/wreck_network_investigation_state.gd")
const MAP_PATH := "res://maps/production_level_01.greybox.json"
const MAP_ID := "production_level_01"
const BOAT_ID := "surface_boat_entry"
const TEST_PATH := "user://oceangame2_wreck_network_state.json"

var _failures: Array[String] = []


class StorageFailingProfile:
	extends RefCounted

	func has_completed_discovery(discovery_id: String) -> bool:
		return discovery_id != ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID

	func complete_discovery(discovery_id: String, _persist := true) -> Dictionary:
		return {"changed": false, "reason": "storage_error", "discovery_id": discovery_id}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var source := _investigation_source()
	var profile := ExpansionProfileState.new(TEST_PATH, true)
	_expect(profile.load_profile().get("status") == "missing", "fresh profile fixture failed")
	var state := WreckNetworkInvestigationState.new()
	var initial: Dictionary = state.configure(source, profile)
	_expect(initial.get("status") == "prerequisite_required", "fresh state did not require the prerequisite")
	_expect(initial.get("remaining_fragment_ids", []).size() == 2, "fresh state did not derive two remaining fragments")

	_expect(bool(profile.complete_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID, true).get("changed", false)), "prerequisite did not persist")
	var collecting: Dictionary = state.report()
	_expect(collecting.get("status") == "fragments_required", "prerequisite did not reveal fragment collection")
	var pending := ExpeditionDiscoveryState.new()
	var west_created: Dictionary = _create_pending(pending, ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID, "western_chasm_wreck_fragment_survey")
	_expect(west_created.get("status") == "pending_created", "western fragment did not become pending")
	var competing: Dictionary = _create_pending(pending, ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID, "abyssal_shelf_wreck_fragment_survey")
	_expect(competing.get("status") == "pending_exists", "second fragment replaced the pending western fragment")
	_expect(pending.commit_at("wrong_map", BOAT_ID, profile).get("status") == "wrong_commit_location" and pending.has_pending(), "wrong location discarded or committed a fragment")
	_expect(pending.clear_pending("hazard").get("status") == "cleared_hazard" and not pending.has_pending(), "hazard cleanup retained a fragment")

	_create_pending(pending, ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID, "western_chasm_wreck_fragment_survey")
	_expect(pending.commit_at(MAP_ID, BOAT_ID, profile).get("status") == "committed", "canonical boat did not commit western fragment")
	var one_fragment: Dictionary = state.report()
	_expect(one_fragment.get("committed_fragment_ids", []) == [ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID], "one-fragment derivation drifted")
	_expect(one_fragment.get("remaining_fragment_ids", []) == [ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID], "remaining abyssal lead was not derived")

	_create_pending(pending, ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID, "abyssal_shelf_wreck_fragment_survey")
	_expect(pending.clear_pending("oxygen_failure").get("status") == "cleared_oxygen_failure", "oxygen failure retained abyssal fragment")
	_create_pending(pending, ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID, "abyssal_shelf_wreck_fragment_survey")
	_expect(pending.commit_at(MAP_ID, BOAT_ID, profile).get("status") == "committed", "canonical boat did not commit abyssal fragment")
	_expect(pending.commit_at(MAP_ID, BOAT_ID, profile).get("status") == "no_pending", "repeat boat contact duplicated a fragment")
	var ready: Dictionary = state.report()
	_expect(ready.get("status") == "analysis_ready" and bool(ready.get("analysis_ready", false)), "two fragments did not enable analysis")

	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 2}, true)
	var materials_before: Dictionary = profile.material_inventory()
	var projects_before: Array = profile.report().get("completed_projects", []).duplicate()
	_expect(state.try_analyze("active").get("status") == "wrong_phase", "analysis ran outside debrief")
	var analyzed: Dictionary = state.try_analyze("debrief", true)
	_expect(analyzed.get("status") == "analysis_completed" and bool(analyzed.get("changed", false)), "explicit debrief analysis did not complete")
	_expect(str(analyzed.get("result_label", "")) == str(source.get("analysis_result_label", "")), "analysis result label did not come from source")
	_expect(profile.material_inventory() == materials_before and profile.report().get("completed_projects", []) == projects_before, "analysis consumed materials or changed projects")
	_expect(state.try_analyze("debrief", true).get("status") == "already_completed", "repeat analysis was not exact-once")

	var reloaded := ExpansionProfileState.new(TEST_PATH, true)
	_expect(reloaded.load_profile().get("status") == "loaded", "investigation profile did not reload")
	for discovery_id in [
		ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID,
		ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID,
		ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID,
	]:
		_expect(reloaded.has_completed_discovery(discovery_id), "reload lost %s" % discovery_id)
	var reload_state := WreckNetworkInvestigationState.new()
	_expect(reload_state.configure(source, reloaded).get("status") == "completed", "reload did not derive completed investigation")

	var malformed := source.duplicate(true)
	malformed["fragment_discovery_ids"] = [ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID, ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID]
	_expect(WreckNetworkInvestigationState.new().configure(malformed, reloaded).get("status") == "invalid_source", "duplicate fragment source was accepted")
	_expect(WreckNetworkInvestigationState.new().configure({}, reloaded).get("status") == "invalid_source", "empty source was accepted")
	var failing_state := WreckNetworkInvestigationState.new()
	failing_state.configure(source, StorageFailingProfile.new())
	_expect(failing_state.try_analyze("debrief", true).get("status") == "storage_error", "analysis storage failure was not preserved")

	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Wreck-network investigation state smoke failed: %s" % failure)
		quit(1)
		return
	print("Wreck-network investigation state smoke passed: prerequisite=%s fragments=2 one_pending=true clears=hazard,oxygen canonical_boat=true exact_once=true phase=debrief cost=none reload=true malformed_source=blocked storage_failure=retained final=%s." % [
		ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID,
		ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID,
	])
	quit(0)


func _investigation_source() -> Dictionary:
	var file := FileAccess.open(MAP_PATH, FileAccess.READ)
	if file == null:
		_failures.append("production map could not be opened")
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_failures.append("production map did not parse")
		return {}
	var investigations = parsed.get("wreck_network_investigations", [])
	if typeof(investigations) != TYPE_ARRAY or investigations.size() != 1:
		_failures.append("production map omitted the investigation source")
		return {}
	return investigations[0].duplicate(true)


func _create_pending(owner, discovery_id: String, target_id: String) -> Dictionary:
	return owner.create_pending(
		discovery_id,
		MAP_ID,
		target_id,
		MAP_ID,
		BOAT_ID,
		{"scan_reward_id": discovery_id, "finding_label": "Wreck fragment logged"}
	)


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
