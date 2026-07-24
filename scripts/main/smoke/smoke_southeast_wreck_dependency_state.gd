extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")
const ScannerSmokePose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")

const RECORDER_ID := "southeast_wreck_recorder"
const SURVEY_ID := "southeast_wreck_archive_survey"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	main.set_process(false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	_attach_profile(main, profile)
	main._load_playable_map(main.PRODUCTION_LEVEL_MAP_PATH, false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	for capability_id in [
		ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID,
		ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID,
	]:
		var prepared: Dictionary = ReviewProgressionFixture.complete_capability(main, capability_id)
		_expect(bool(prepared.get("ready", false)), "could not prepare %s" % capability_id)
	var prerequisite: Dictionary = profile.complete_discovery(ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID, false)
	_expect(bool(prerequisite.get("changed", false)), "could not prepare abyssal wreck lead")
	main._material_project.on_map_loaded(main._world)
	main._player.global_position = main._world.get_extraction_center()
	_expect(main._anomaly_survey.overlay_text(main._world, main._player) == "Abyssal chart | Southeast wreck echo", "committed abyssal finding omitted broad wreck promise")

	var recorder := _tool_target(main, RECORDER_ID)
	var survey := _survey_target(main, SURVEY_ID)
	_expect(not recorder.is_empty() and not survey.is_empty(), "wreck source records were missing")
	if recorder.is_empty() or survey.is_empty():
		_finish(main)
		return
	_place_for_scan(main, survey)
	var blocked: Dictionary = main._anomaly_survey.scanner_action(main._world, main._player)
	_expect(blocked.get("reason") == "tool_clearance_required", "survey was not dependency-locked")
	_expect(str(blocked.get("note", "")) == "Wreck recorder | Cutter required", "blocked survey omitted cutter guidance")
	_expect(float(main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0)) == 0.0, "blocked survey gained progress")

	main._sortie_state.collect_salvage("capacity_a", 0)
	main._sortie_state.collect_salvage("capacity_b", 0)
	main._player.global_position = recorder.get("center", Vector2.ZERO)
	main._cargo_collection.update(3.0)
	_expect(not main._world.is_salvage_collected(RECORDER_ID), "full cargo deleted recorder")
	main._sortie_state.clear_held()
	main._cargo_collection.update(2.1)
	_expect(main._world.is_salvage_collected(RECORDER_ID), "cutter did not clear recorder")
	_expect(main._sortie_state.held_salvage_ids.has(RECORDER_ID), "recorder did not enter held cargo")
	_place_for_scan(main, survey)
	_expect(main._anomaly_survey.overlay_text(main._world, main._player) == "Archive exposed | Hold Q/USE to scan wreck archive", "exposed archive prompt was unclear")
	main._sortie_state.collect_salvage("capacity_after_recorder", 0)
	var activated: Dictionary = main._anomaly_survey.scanner_action(main._world, main._player)
	_expect(activated.get("reason") == "activated", "full cargo blocked current-sortie archive survey")
	var partial: Dictionary = main._anomaly_survey.update(main._world, main._player, 1.0)
	_expect(str(partial.get("note", "")).begins_with("Survey wreck archive "), "archive partial progress was unclear")
	_expect(float(main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0)) > 0.0, "exposed survey did not gain progress")
	main._player.global_position = survey.get("center", Vector2.ZERO) + Vector2(200.0, 0.0)
	var canceled: Dictionary = main._anomaly_survey.update(main._world, main._player, 0.0)
	_expect(canceled.get("state") == "canceled", "leaving archive range did not cancel progress")
	_expect(float(main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0)) == 0.0, "canceled archive survey retained progress")
	_place_for_scan(main, survey)
	main._anomaly_survey.scanner_action(main._world, main._player)
	main._anomaly_survey.update(main._world, main._player, 1.0)

	main._handle_hazard_hit("wreck_dependency_test")
	_expect(not main._world.get_tool_target_near(recorder.get("center", Vector2.ZERO), main.SALVAGE_COLLECTION_RADIUS).is_empty(), "failure did not restore recorder")
	_place_for_scan(main, survey)
	blocked = main._anomaly_survey.scanner_action(main._world, main._player)
	_expect(blocked.get("reason") == "tool_clearance_required", "failure retained transient recorder clearance")
	_expect(float(main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0)) == 0.0, "failure retained survey progress")

	main._sortie_state.failed = false
	main._player.global_position = recorder.get("center", Vector2.ZERO)
	main._cargo_collection.update(2.1)
	main._player.global_position = main._world.get_extraction_center()
	main._cargo_collection.update(0.0)
	_expect(profile.has_banked_tool_target(RECORDER_ID), "boat offload did not bank durable recorder clearance")
	main._load_playable_map(main.PRODUCTION_LEVEL_MAP_PATH, false)
	main._player.set_physics_process(false)
	_expect(main._world.get_tool_target_near(recorder.get("center", Vector2.ZERO), main.SALVAGE_COLLECTION_RADIUS).is_empty(), "durable recorder respawned on map reload")
	_place_for_scan(main, survey)
	activated = main._anomaly_survey.scanner_action(main._world, main._player)
	_expect(activated.get("reason") == "activated", "banked recorder did not expose survey after map reload")
	var completed: Dictionary = main._anomaly_survey.update(main._world, main._player, 3.1)
	_expect(completed.get("reason") == "pending_created", "archive survey did not create one pending finding")
	_expect(completed.get("note") == "Wreck archive charted | Return to surface boat", "archive pending return guidance drifted")
	var repeated_scan: Dictionary = main._anomaly_survey.scanner_action(main._world, main._player)
	_expect(repeated_scan.get("reason") == "pending", "pending archive allowed a second result")
	main._player.global_position = main._world.get_extraction_center()
	var committed: Dictionary = main._anomaly_survey.update(main._world, main._player, 0.0)
	var result_text: String = main._anomaly_survey.result_text()
	_expect(bool(committed.get("committed", false)), "canonical boat did not commit archive finding")
	_expect(profile.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID), "archive discovery did not reach profile")
	_expect(result_text == "Discovery logged: Southeast wreck archive\nNext lead: distant wreck network unresolved", "archive result text drifted: %s" % result_text)
	_expect(result_text.find("Expansion 14") == -1, "archive result selected the next expansion")
	var repeat_commit: Dictionary = main._anomaly_survey.update(main._world, main._player, 0.0)
	_expect(not bool(repeat_commit.get("committed", false)) and main._anomaly_survey.result_text() == result_text, "archive discovery committed more than once")
	main._anomaly_survey.clear_unbanked("reset", main._world)
	_expect(not main._anomaly_survey.has_pending_discovery() and main._anomaly_survey.result_text().is_empty(), "reset retained stale archive success or pending text")
	_finish(main)


func _attach_profile(main, profile) -> void:
	main._anomaly_survey = AnomalySurveyRuntime.new(main._progression_runtime, false, profile)
	main._material_runtime = MaterialRuntimeController.new(profile)
	main._material_project = MaterialProjectRuntime.new(profile)
	main._cutter_salvage = CutterSalvageController.new(profile)


func _tool_target(main, target_id: String) -> Dictionary:
	for target in main._world.get_tool_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _survey_target(main, target_id: String) -> Dictionary:
	for target in main._world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _place_for_scan(main, target: Dictionary) -> void:
	var pose: Dictionary = ScannerSmokePose.new().place(main._world, main._player, target)
	_expect(bool(pose.get("found", false)), "no clear scan pose for %s" % target.get("id", "target"))


func _finish(main) -> void:
	main.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Southeast wreck dependency smoke failed: %s" % failure)
		quit(1)
		return
	print("Southeast wreck dependency smoke passed: recorder=%s survey=%s promise=broad cutter_guidance=true full_cargo_safe=true transient_unlock=true explicit_scan=true cancel_on_leave=true failure_restore=true durable_bank_reload=true pending_return=true canonical_commit=true exact_once=true result=broad_next_lead." % [RECORDER_ID, SURVEY_ID])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
