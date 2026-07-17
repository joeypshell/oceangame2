extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const RegionalJourneyPresentation := preload("res://scripts/main/regional_journey_presentation.gd")
const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")
const ScannerCutterJourneyPresentation := preload("res://scripts/main/scanner_cutter_journey_presentation.gd")

const TEST_PATH := "user://oceangame2_sealed_wreck_reward_test.json"
const TARGET_ID := "salvage_sealed_wreck_cache"
const PENDING_LABEL := "Wreck navigation data secured | Return to surface boat"
const COMMIT_LABEL := "Navigation data logged: Southeast wreck coordinates"
const NEXT_LEAD := "Wreck coordinates | Signal continues deep southeast"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_files()
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	main.set_process(false)
	var profile := ExpansionProfileState.new(TEST_PATH)
	_expect(profile.load_profile().get("status") == "missing", "reward profile did not start clean")
	main._anomaly_survey = AnomalySurveyRuntime.new(main._progression_runtime, true, profile)
	main._material_runtime = MaterialRuntimeController.new(profile)
	main._material_project = MaterialProjectRuntime.new(profile)
	main._cutter_salvage = CutterSalvageController.new(profile)
	main._load_playable_map(main.PRODUCTION_LEVEL_MAP_PATH, false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	main._combat_interactions_enabled = false

	var target := _target(main)
	if target.is_empty():
		_failures.append("production level omitted sealed-wreck reward target")
		_finish(main)
		return
	var target_id := str(target.get("id", ""))
	var target_center: Vector2 = target.get("center", Vector2.ZERO)
	_expect(target_id == TARGET_ID, "reward target id drifted")
	_expect(target.get("reward_id") == ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID, "reward discovery id drifted")
	_expect(ScannerCutterJourneyPresentation.new().completion_note(target, 300, false) == "Sealed wreck opened | Salvage value +300", "already-owned reward text falsely promised pending data")
	var prepared: Dictionary = ReviewProgressionFixture.complete_capability(main, ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID)
	_expect(bool(prepared.get("ready", false)), "could not prepare recipe-built cutter")
	main._material_project.on_map_loaded(main._world)
	main._refresh_active_tools()

	main._player.global_position = target_center
	for index in range(main._held_salvage_capacity()):
		main._sortie_state.collect_salvage("capacity_fixture_%d" % index, 0)
	var blocked: Dictionary = main._cutter_salvage.activate(target, main._held_cargo_count(), main._held_salvage_capacity())
	_expect(blocked.get("state") == "blocked", "full cargo did not block reward target")
	_expect(not main._world.is_salvage_collected(target_id), "full cargo deleted reward target")
	_expect(not main._anomaly_survey.has_pending_discovery(), "full cargo created pending navigation data")
	main._sortie_state.clear_held()

	var presentation := RegionalJourneyPresentation.new()
	_expect(presentation.promise_text(main._world, profile).is_empty(), "southeast lead appeared before reward commitment")
	var activated: Dictionary = main._cutter_salvage.activate(target, 0, main._held_salvage_capacity())
	_expect(activated.get("state") == "activated", "cutter did not activate reward target")
	main._process(float(target.get("interaction_seconds", 0.0)) + 0.1)
	var pending: Dictionary = main._anomaly_survey.report().get("expedition", {}).get("pending", {})
	_expect(main._world.is_salvage_collected(target_id), "completed reward target remained in world")
	_expect(main._sortie_state.held_salvage == 1 and main._sortie_state.held_salvage_score == 300, "valuable salvage cargo changed")
	_expect(pending.get("discovery_id") == ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID, "completion did not create pending navigation data")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID), "navigation data committed away from boat")
	_expect(main._last_status_note.find("Salvage value +300") != -1 and main._last_status_note.find(PENDING_LABEL) != -1, "completion did not distinguish salvage value from pending progression")

	main._handle_hazard_hit("sealed_wreck_reward_smoke")
	_expect(not main._anomaly_survey.has_pending_discovery(), "hazard retained pending navigation data")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID), "hazard committed navigation data")
	_expect(main._sortie_state.held_salvage == 0, "hazard retained valuable salvage")
	_expect(not main._world.get_tool_target_near(target_center, main.SALVAGE_COLLECTION_RADIUS).is_empty(), "hazard did not restore reward target")

	main._player.global_position = target_center
	target = _target(main)
	main._cutter_salvage.activate(target, 0, main._held_salvage_capacity())
	main._process(float(target.get("interaction_seconds", 0.0)) + 0.1)
	_expect(main._anomaly_survey.has_pending_discovery() and main._sortie_state.held_salvage == 1, "hazard retry did not restore pending reward and cargo")
	main._reset_run()
	_expect(not main._anomaly_survey.has_pending_discovery() and main._sortie_state.held_salvage == 0, "manual reset retained pending reward or cargo")
	_expect(not main._world.get_tool_target_near(target_center, main.SALVAGE_COLLECTION_RADIUS).is_empty(), "manual reset did not restore reward target")
	main._player.global_position = target_center
	target = _target(main)
	main._cutter_salvage.activate(target, 0, main._held_salvage_capacity())
	main._process(float(target.get("interaction_seconds", 0.0)) + 0.1)
	_expect(main._anomaly_survey.has_pending_discovery() and main._sortie_state.held_salvage == 1, "reset retry did not restore pending reward and cargo")
	main._player.global_position = main._world.get_entry_position("surface_boat_entry")
	_expect(main._world.is_inside_boat(main._player.global_position), "commit fixture missed canonical boat")
	main._process(0.0)
	var expected_result := "%s\n%s" % [COMMIT_LABEL, NEXT_LEAD]
	_expect(not main._anomaly_survey.has_pending_discovery(), "boat return retained pending navigation data")
	_expect(profile.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID), "boat return did not commit navigation data")
	_expect(main._sortie_state.held_salvage == 0 and main._banked_score == 300, "boat return did not bank valuable salvage once")
	_expect(main._anomaly_survey.result_text() == expected_result, "boat result lost source commit or southeast lead text")
	_expect(presentation.promise_text(main._world, profile) == NEXT_LEAD, "committed reward did not reveal southeast lead")
	_expect(main._expedition_day_state.committed_discovery_ids.count(ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID) == 1, "day state omitted committed navigation data")
	main._process(0.0)
	_expect(main._banked_score == 300 and main._expedition_day_state.committed_discovery_ids.count(ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID) == 1, "repeat boat update duplicated reward")

	var reloaded := ExpansionProfileState.new(TEST_PATH)
	_expect(reloaded.load_profile().get("status") == "loaded", "committed reward profile did not reload")
	_expect(reloaded.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID), "profile reload lost navigation data")
	_test_completed_archive_migration(reloaded)
	_finish(main)


func _target(main) -> Dictionary:
	for target in main._world.get_tool_targets():
		if str(target.get("id", "")) == TARGET_ID:
			return target
	return {}


func _test_completed_archive_migration(profile) -> void:
	var payload: Dictionary = profile.report()
	payload.erase("status")
	var discoveries: Array = payload["completed_discoveries"]
	discoveries.erase(ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID)
	if not discoveries.has(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID):
		discoveries.append(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID)
	_write_text(TEST_PATH, JSON.stringify(payload))
	var migrated := ExpansionProfileState.new(TEST_PATH)
	_expect(migrated.load_profile().get("status") == "migrated_wreck_navigation", "completed archive profile did not migrate navigation data")
	_expect(migrated.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID), "migration omitted navigation data")
	var repeat := ExpansionProfileState.new(TEST_PATH)
	_expect(repeat.load_profile().get("status") == "loaded", "navigation migration was not persisted exactly once")
	_expect(repeat.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID), "persisted migration lost navigation data")


func _finish(main) -> void:
	main.queue_free()
	_cleanup_files()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Sealed wreck reward state smoke failed: %s" % failure)
		quit(1)
		return
	print("Sealed wreck reward state smoke passed: target=%s cargo_full_block=true salvage_value=300 pending=true hazard_restore=true reset_restore=true canonical_commit=true exact_once=true southeast_lead=true profile_reload=true archive_migration=true." % TARGET_ID)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write profile migration fixture")
		return
	file.store_string(text)
	file.close()


func _cleanup_files() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
