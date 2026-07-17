extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const ProgressionContract := preload("res://scripts/main/progression_contract.gd")
const ScannerSmokePose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")

const TEST_PROFILE_PATH := "user://oceangame2_anomaly_journey_smoke.json"
const MAP_ID := "production_slice_01"
const PAYOFF_TARGET_ID := "salvage_current_pocket_cache"
const SCANNER_CONTAINER_ID := "east_current_scanner_blueprint_chest"
const SURVEY_TARGET_ID := "lower_right_anomaly_survey"
const RESOURCE_TARGET_ID := "upper_right_mineral_trace_survey"
const DISCOVERY_ID := ExpansionProfileState.ANOMALY_DISCOVERY_ID


func _smoke_anomaly_survey_journey_and_quit() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	_attach_profile(profile)
	_main._load_playable_map(_main.PRODUCTION_SLICE_MAP_PATH, false)
	_prepare_current_map()
	if not _require(_world.map_id == MAP_ID, "loaded unexpected map %s" % _world.map_id):
		return

	var target := _survey_target_by_id(SURVEY_TARGET_ID)
	var resource_target := _survey_target_by_id(RESOURCE_TARGET_ID)
	if not _require(not target.is_empty() and str(target.get("target_type", "")) == "anomaly", "same-map anomaly target missing"):
		return
	if not _require(not resource_target.is_empty() and str(resource_target.get("target_type", "")) == "resource", "same-map resource target missing"):
		return
	if not _require(str(target.get("route_context", "")) == "upper_right_current_pocket", "anomaly target left the fins pocket"):
		return

	_player.global_position = _world.get_extraction_center()
	var blocked: Dictionary = _main._anomaly_survey.scanner_action(_world, _player)
	if not _require(blocked.get("reason") == "blueprint_required", "scanner bypassed its recovered plan"):
		return
	if not _prepare_propulsion_fins():
		_require(false, "could not seed recipe-built fins")
		return

	var scanner_container := _container_by_id(SCANNER_CONTAINER_ID)
	if not _require(not scanner_container.is_empty(), "missing scanner blueprint container"):
		return
	_player.global_position = scanner_container["center"]
	if not _require(_main._try_progression_container_interaction(), "could not recover scanner blueprint"):
		return
	if not _require(profile.has_completed_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID), "scanner blueprint did not reach profile"):
		return
	var payoff := _salvage_by_id(PAYOFF_TARGET_ID)
	if not _require(not payoff.is_empty(), "missing same-map scanner payoff"):
		return
	_player.global_position = payoff["center"]
	if not _require(_collect_salvage_for_smoke(payoff), "could not collect scanner payoff"):
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(
		_session_wallet() == int(ProgressionContract.SALVAGE_SCORE_BY_TIER["valuable"])
		and not _main._anomaly_survey.has_scanner(),
		"optional cache changed scanner ownership or score semantics"
	):
		return
	if not _require(_main._anomaly_survey.scanner_action(_world, _player).get("reason") == "project_required", "wallet bypassed scanner project"):
		return
	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1, ExpansionProfileState.COIL_MATERIAL_ID: 1}, false)
	var build: Dictionary = profile.complete_material_project(_project_by_id(ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID), true)
	if not _require(bool(build.get("changed", false)) and _main._anomaly_survey.has_scanner(), "scanner project transaction failed"):
		return
	var wallet_after_cache := _session_wallet()

	var oxygen_before: float = _oxygen_seconds
	var empty_held: int = _held_salvage
	_held_salvage = _held_salvage_capacity()
	_held_salvage_ids = ["scanner_full_cargo_a", "scanner_full_cargo_b"]
	if not _place_for_scan(target):
		return
	_process(0.0)
	var ready_status: String = _status_label.text
	if not _require(
		ready_status.find("Q/SCAN: Survey anomaly") != -1
		and ready_status.find("Cargo full") != -1,
		"full cargo hid the scanner activation prompt: %s" % ready_status
	):
		return
	_press_key(KEY_Q)
	_process(1.0)
	var partial: float = float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	var progress_status: String = _status_label.text
	if not _require(
		partial > 0.0
		and partial < 1.0
		and _oxygen_seconds < oxygen_before
		and progress_status.find("Survey anomaly 33%") != -1
		and progress_status.find("Cargo full") != -1,
		"full-cargo survey progress or oxygen pressure drifted: %s" % progress_status
	):
		return
	_player.global_position = Vector2.ZERO
	_process(0.0)
	if not _require(not _main._anomaly_survey.has_pending_discovery() and _main._anomaly_survey.report().get("last_note") == "Survey interrupted", "leave-range cancel failed"):
		return
	if not _complete_survey(target, _held_salvage_capacity(), wallet_after_cache):
		return
	if not _place_for_scan(resource_target):
		return
	_process(0.0)
	_press_key(KEY_Q)
	var pending_status: String = _status_label.text
	if not _require(
		pending_status.find("Return to surface boat before another scan") != -1
		and is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0))),
		"pending result did not explain why another scan was blocked: %s" % pending_status
	):
		return

	_reset_run()
	_prepare_current_map()
	if not _require(not _main._anomaly_survey.has_pending_discovery() and _held_salvage == empty_held, "retry retained pending discovery or full cargo"):
		return
	if not _complete_survey(target, empty_held, wallet_after_cache):
		return
	_main._handle_hazard_hit("anomaly_smoke_hazard")
	if not _require(not _main._anomaly_survey.has_pending_discovery(), "hazard retained pending discovery"):
		return
	_prepare_current_map()
	if not _complete_survey(target, empty_held, wallet_after_cache):
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(
		_main._anomaly_survey.has_completed_discovery()
		and not _main._anomaly_survey.has_pending_discovery()
		and _world.map_id == MAP_ID,
		"same-map boat did not commit discovery"
	):
		return
	var committed_result: String = _main._anomaly_survey.result_text()
	if not _require(committed_result.find("Cutter plan recovered:") != -1, "commit omitted cutter-plan result"):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(
		reload_report.get("status") == "loaded"
		and reloaded.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID)
		and reloaded.has_completed_discovery(DISCOVERY_ID),
		"profile reload lost scanner or discovery"
	):
		return

	_cleanup_profile()
	print("Anomaly survey journey smoke passed: map=%s contiguous=true connectors=none fins_gate=%s payoff=%s optional_score=%d scanner_blueprint=true recipe=ti1+coil1 score_bypass=false explicit_q=true full_cargo_scan=true pending_boat_guidance=true target=%s partial=%.2f cancel_on_leave=true failure_clears_pending=true committed_at_boat=true cutter_plan=true discovery=%s profile=%s." % [
		MAP_ID,
		ExpansionProfileState.PROPULSION_FINS_GATE_ID,
		PAYOFF_TARGET_ID,
		wallet_after_cache,
		SURVEY_TARGET_ID,
		partial,
		DISCOVERY_ID,
		str(reload_report.get("status", "")),
	])
	get_tree().quit(0)


func _complete_survey(target: Dictionary, expected_held: int, expected_wallet: int) -> bool:
	if not _place_for_scan(target):
		return false
	_press_key(KEY_Q)
	_process(float(target.get("interaction_seconds", 0.0)) + 0.1)
	return _require(
		_main._anomaly_survey.has_pending_discovery()
		and _held_salvage == expected_held
		and _session_wallet() == expected_wallet,
		"survey completion changed cargo or wallet semantics"
	)


func _place_for_scan(target: Dictionary) -> bool:
	var pose: Dictionary = ScannerSmokePose.new().place(_world, _player, target)
	return _require(bool(pose.get("found", false)), "no clear scan pose for %s" % target.get("id", "target"))


func _attach_profile(profile) -> void:
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, profile)
	_main._material_runtime = MaterialRuntimeController.new(profile)
	_main._material_project = MaterialProjectRuntime.new(profile)
	_main._cutter_salvage = CutterSalvageController.new(profile)
	_main._anomaly_survey.on_map_loaded(_world)
	_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state)
	_main._material_project.on_map_loaded(_world)
	_main._cutter_salvage.on_map_loaded(_world)


func _survey_target_by_id(target_id: String) -> Dictionary:
	for target in _world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _container_by_id(container_id: String) -> Dictionary:
	for container in _world.get_progression_containers():
		if str(container.get("id", "")) == container_id:
			return container
	return {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	_main._unhandled_input(event)


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false
	_player.reset_motion()


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_cleanup_profile()
	push_error("Anomaly survey journey smoke failed: %s." % message)
	get_tree().quit(1)
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
