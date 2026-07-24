extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpeditionDiscoveryState := preload("res://scripts/main/expedition_discovery_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const RegionalJourneyPresentation := preload("res://scripts/main/regional_journey_presentation.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const TEST_PATH := "user://oceangame2_expansion_14_runtime_owners_test.json"
const CURRENT_GATE_ID := "upper_left_wreck_relay_current"
const SURVEY_ID := "upper_left_wreck_relay_survey"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	world.load_greybox()
	var profile := ExpansionProfileState.new(TEST_PATH)
	profile.load_profile()
	var project_runtime := MaterialProjectRuntime.new(profile)
	var source_report: Dictionary = project_runtime.on_map_loaded(world)
	_expect(source_report.get("project_id") != ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID, "canonical stabilizer appeared before archive commit")
	_expect(not project_runtime.request_project(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID), "manual request exposed canonical stabilizer before archive commit")

	var cutter := project_runtime.project_definition_for(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID)
	_complete_project(profile, cutter)
	source_report = project_runtime.on_map_loaded(world)
	_expect(source_report.get("project_id") != ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID, "cutter completion exposed canonical stabilizer before archive commit")
	var archive: Dictionary = profile.complete_discovery(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID, true)
	_expect(bool(archive.get("changed", false)), "archive discovery fixture did not commit")
	source_report = project_runtime.on_map_loaded(world)
	_expect(source_report.get("project_id") == ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID, "archive commit did not expose canonical stabilizer")
	_expect(project_runtime.status() == "incomplete", "canonical stabilizer was not waiting on its exact banked recipe")
	_expect(project_runtime.debrief_lines().has("Access: Northwest wreck relay | Swim through current"), "project feedback omitted the relay route")

	var gate := _record_by_id(world.get_current_gates(), CURRENT_GATE_ID)
	_expect(not gate.is_empty(), "canonical relay current was missing")
	var player := Node2D.new()
	get_root().add_child(player)
	player.global_position = gate.get("center", Vector2.ZERO)
	var blocked_x := player.global_position.x
	var gate_controller := CurrentGateController.new()
	var blocked: Dictionary = gate_controller.update(world, player, Callable(self, "_has_no_upgrade"), Callable(profile, "has_capability"), 0.1)
	_expect(bool(blocked.get("blocked", false)), "relay current did not block before stabilizer ownership")
	_expect(player.global_position.x < blocked_x, "relay current did not push left toward the central route")
	_expect(str(blocked.get("prompt", "")).begins_with("Ripping relay current"), "relay current feedback omitted its authored name")

	var recipe := {
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}
	profile.deposit_materials(recipe, true)
	var wrong_phase: Dictionary = project_runtime.try_build(ExpeditionDayState.PHASE_ACTIVE)
	_expect(wrong_phase.get("reason") == "wrong_phase", "canonical stabilizer built during the active day")
	_expect(profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2 and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 1, "active-day request spent banked materials")
	var completed: Dictionary = project_runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(completed.get("changed", false)), "exact Ti2/Coil1 night recipe did not build stabilizer")
	_expect(profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID), "night project did not grant stabilizer capability")
	_expect(profile.material_inventory().is_empty(), "night project did not consume exactly Ti2/Coil1")
	var repeated: Dictionary = project_runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(repeated.get("reason") == "already_completed" and not bool(repeated.get("changed", true)), "stabilizer project was not exact-once")

	gate_controller.reset()
	for offset_x in [-8.0, 8.0]:
		player.global_position = gate.get("center", Vector2.ZERO) + Vector2(offset_x, 0.0)
		var owned_position := player.global_position
		var owned: Dictionary = gate_controller.update(world, player, Callable(self, "_has_no_upgrade"), Callable(profile, "has_capability"), 0.25)
		_expect(bool(owned.get("inside", false)) and not bool(owned.get("blocked", true)), "owned relay current was not passive")
		_expect(player.global_position == owned_position, "owned relay current still moved the diver")

	var survey := _record_by_id(world.get_survey_targets(), SURVEY_ID)
	_expect(not survey.is_empty(), "canonical relay survey was missing")
	var presentation := RegionalJourneyPresentation.new()
	_expect(presentation.nearby_scan_text(survey) == "Relay signal | Hold Q/USE to scan wreck relay", "relay scan feedback omitted explicit held Q/USE")
	_expect(presentation.survey_complete_note(survey) == "Wreck relay charted | Return to surface boat", "relay pending feedback omitted boat return")
	var expedition := ExpeditionDiscoveryState.new()
	var metadata := _pending_metadata(survey)
	var pending: Dictionary = expedition.create_pending(
		ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID,
		str(world.map_id),
		SURVEY_ID,
		str(survey.get("commit_map_id", "")),
		str(survey.get("commit_entry_id", "")),
		metadata
	)
	_expect(pending.get("status") == "pending_created", "relay discovery was rejected by expedition state")
	_expect(presentation.pending_return_text(metadata) == "Wreck relay charted | Return to surface boat", "relay pending state was not named")
	var cleared: Dictionary = expedition.clear_pending("hazard")
	_expect(str(cleared.get("status", "")).begins_with("cleared_hazard") and not expedition.has_pending(), "failure did not clear pending relay discovery")
	expedition.create_pending(ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID, str(world.map_id), SURVEY_ID, str(survey.get("commit_map_id", "")), str(survey.get("commit_entry_id", "")), metadata)
	_expect(expedition.commit_at("production_slice_01", str(survey.get("commit_entry_id", "")), profile).get("status") == "wrong_commit_location", "relay discovery committed away from canonical map")
	var commit: Dictionary = expedition.commit_at(str(survey.get("commit_map_id", "")), str(survey.get("commit_entry_id", "")), profile)
	_expect(commit.get("status") == "committed", "canonical boat did not commit relay discovery")
	_expect(profile.has_completed_discovery(ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID), "relay discovery did not reach durable profile state")
	_expect(str(commit.get("metadata", {}).get("next_lead_label", "")) == "Next lead: deeper wreck relay still transmitting", "relay commit lost its next lead")

	var reloaded := ExpansionProfileState.new(TEST_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	_expect(reload_report.get("status") in ["loaded", "migrated_wreck_navigation"], "Expansion 14 profile did not reload: %s" % reload_report)
	_expect(reloaded.has_completed_project(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID), "reload lost stabilizer project")
	_expect(reloaded.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID), "reload lost stabilizer capability")
	_expect(reloaded.has_completed_discovery(ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID), "reload lost relay discovery")

	player.queue_free()
	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Expansion 14 runtime owner smoke failed: %s" % failure)
		quit(1)
		return
	print("Expansion 14 runtime owners passed: project=current_stabilizer_project recipe=Ti2+Coil1 night_only=true exact_once=true gate=upper_left_wreck_relay_current passive_owned=true survey=upper_left_wreck_relay_survey failure_clear=true boat_commit=surface_boat_entry discovery=upper_left_wreck_relay_discovery reload=true.")
	quit(0)


func _complete_project(profile, project: Dictionary) -> void:
	profile.complete_discovery(str(project.get("required_discovery_id", "")), true)
	var materials := {}
	for material_id in project.get("required_materials", {}):
		materials[str(material_id)] = int(project.get("required_materials", {})[material_id])
	profile.deposit_materials(materials, true)
	var completion: Dictionary = profile.complete_material_project(project, true)
	_expect(bool(completion.get("changed", false)), "could not prepare prerequisite project %s: %s" % [project.get("id", ""), completion])


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str(record.get("id", "")) == record_id:
			return record
	return {}


func _pending_metadata(target: Dictionary) -> Dictionary:
	var metadata := {}
	for field in ExpeditionDiscoveryState.METADATA_FIELDS:
		metadata[field] = str(target.get(field, ""))
	return metadata


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
