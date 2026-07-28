extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ScannerSmokePose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")

const RECORDER_ID := "far_west_wreck_data_recorder"
const SURVEY_ID := "far_west_deeper_wreck_survey"
const EXPECTED_RESULT := "Discovery logged: Far-west wreck network\nNext lead: deeper wreck network unresolved"

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
	var checkpoint: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.EXPANSION_16_START, profile)
	_expect(bool(checkpoint.get("ready", false)), "Expansion 16 checkpoint did not apply: %s" % checkpoint)
	main._load_playable_map(main.PRODUCTION_LEVEL_MAP_PATH, false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false

	_expect(main._material_project.status() == "ready", "checkpoint did not expose the ready rebreather project")
	var built: Dictionary = main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(built.get("changed", false)), "night transaction did not build the rebreather: %s" % built)
	_expect(profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID), "rebreather capability was not granted")

	var recorder := _record_by_id(main._world.get_tool_targets(), RECORDER_ID)
	var survey := _record_by_id(main._world.get_survey_targets(), SURVEY_ID)
	_expect(not recorder.is_empty() and not survey.is_empty(), "far-west source records were missing")
	if recorder.is_empty() or survey.is_empty():
		_finish(main)
		return

	_place_for_scan(main, survey)
	var blocked: Dictionary = main._active_tool_runtime.use()
	_expect(blocked.get("reason") == "tool_clearance_required", "survey was not cutter-locked before recorder clearance")

	main._player.global_position = recorder.get("center", Vector2.ZERO)
	main._cargo_collection.update(2.1)
	_expect(not main._world.is_salvage_collected(RECORDER_ID), "proximity completed the explicit cutter target")
	main._active_tool_runtime.cycle()
	var cutter_use: Dictionary = main._active_tool_runtime.use()
	_expect(cutter_use.get("status") == "used", "selected cutter did not activate on explicit Q/USE")
	main._cargo_collection.update(2.1)
	_expect(main._world.is_salvage_collected(RECORDER_ID), "explicit cutter hold did not clear recorder")
	_expect(main._sortie_state.held_salvage_ids.has(RECORDER_ID), "cleared recorder did not enter held cargo")

	_select_scanner(main)
	_place_for_scan(main, survey)
	var scanner_use: Dictionary = main._active_tool_runtime.use()
	_expect(scanner_use.get("reason") == "activated", "selected scanner did not activate on the exposed recorder")
	main._anomaly_survey.update(main._world, main._player, 0.8)
	var released: Dictionary = main._active_tool_runtime.release_use()
	_expect(bool(released.get("changed", false)), "scanner release did not cancel the held interaction")
	_expect(float(main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0)) == 0.0, "scanner release retained partial progress")

	main._active_tool_runtime.use()
	main._anomaly_survey.update(main._world, main._player, 0.8)
	main._handle_hazard_hit("expansion_16_integration")
	_expect(not profile.has_banked_tool_target(RECORDER_ID), "hazard made held recorder clearance durable")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID), "hazard committed the cave finding")
	_expect(not main._world.get_tool_target_near(recorder.get("center", Vector2.ZERO), main.SALVAGE_COLLECTION_RADIUS).is_empty(), "hazard did not restore the recorder")
	_place_for_scan(main, survey)
	blocked = main._active_tool_runtime.use()
	_expect(blocked.get("reason") == "tool_clearance_required", "hazard retained transient recorder clearance")

	main._player.global_position = recorder.get("center", Vector2.ZERO)
	main._active_tool_runtime.cycle()
	main._active_tool_runtime.use()
	main._cargo_collection.update(2.1)
	_select_scanner(main)
	_place_for_scan(main, survey)
	main._active_tool_runtime.use()
	var pending: Dictionary = main._anomaly_survey.update(main._world, main._player, 3.1)
	_expect(pending.get("reason") == "pending_created", "held scanner did not create the pending far-west finding")
	_expect(main._anomaly_survey.has_pending_discovery(), "survey completion did not retain a pending finding")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID), "survey committed durably inside the wreck")

	main._player.global_position = main._world.get_extraction_center()
	var committed: Dictionary = main._anomaly_survey.update(main._world, main._player, 0.0)
	main._cargo_collection.update(0.0)
	_expect(bool(committed.get("committed", false)), "canonical boat did not commit the far-west finding")
	_expect(profile.has_completed_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID), "boat commit did not persist the far-west discovery")
	_expect(profile.has_banked_tool_target(RECORDER_ID), "boat offload did not persist recorder clearance")
	_expect(main._anomaly_survey.result_text() == EXPECTED_RESULT, "boat payoff text drifted: %s" % main._anomaly_survey.result_text())
	var repeated: Dictionary = main._anomaly_survey.update(main._world, main._player, 0.0)
	main._cargo_collection.update(0.0)
	_expect(not bool(repeated.get("committed", false)), "far-west finding committed more than once")

	main._load_playable_map(main.PRODUCTION_LEVEL_MAP_PATH, false)
	main._player.set_physics_process(false)
	_expect(main._world.get_tool_target_near(recorder.get("center", Vector2.ZERO), main.SALVAGE_COLLECTION_RADIUS).is_empty(), "banked recorder returned after map reload")
	_finish(main)


func _attach_profile(main, profile) -> void:
	main._anomaly_survey = AnomalySurveyRuntime.new(main._progression_runtime, false, profile)
	main._material_runtime = MaterialRuntimeController.new(profile)
	main._material_project = MaterialProjectRuntime.new(profile)
	main._cutter_salvage = CutterSalvageController.new(profile)


func _select_scanner(main) -> void:
	for _index in range(3):
		if main._active_tools.selected_tool_id() == ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID:
			return
		main._active_tool_runtime.cycle()
	_expect(false, "scanner could not be selected")


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str(record.get("id", "")) == record_id:
			return record
	return {}


func _place_for_scan(main, target: Dictionary) -> void:
	var pose: Dictionary = ScannerSmokePose.new().place(main._world, main._player, target)
	_expect(bool(pose.get("found", false)), "no clear scan pose for %s" % target.get("id", "target"))


func _finish(main) -> void:
	main.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Expansion 16 integration smoke failed: %s" % failure)
		quit(1)
		return
	print("Expansion 16 integration passed: checkpoint=expansion_16_start project=closed_circuit_rebreather_project cutter=explicit scanner=held_cancel hazard_restore=true pending_in_cave=true boat_commit=exact_once recorder=durable result=far_west_next_lead.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
