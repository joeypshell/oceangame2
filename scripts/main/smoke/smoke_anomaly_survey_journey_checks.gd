extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const TEST_PROFILE_PATH := "user://oceangame2_anomaly_journey_smoke.json"
const ORIGIN_MAP_ID := "production_slice_01"
const RELAY_MAP_ID := "production_slice_04"
const TARGET_MAP_ID := "production_slice_02"
const ORIGIN_CONNECTOR_ID := "lower_left_loop_connector"
const RELAY_RETURN_CONNECTOR_ID := "return_to_boat_hub_connector"
const ANOMALY_CONNECTOR_ID := "lower_right_anomaly_connector"
const TARGET_RETURN_CONNECTOR_ID := "return_to_lower_left_relay_connector"
const PAYOFF_TARGET_ID := "slice_04_destination_cache"
const SURVEY_TARGET_ID := "lower_right_anomaly_survey"
const DISCOVERY_ID := ExpansionProfileState.ANOMALY_DISCOVERY_ID
const PROPULSION_SEED_WALLET := 1000


func _smoke_anomaly_survey_journey_and_quit() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, profile)
	_main._anomaly_survey.on_map_loaded(_world)
	_prepare_current_map()

	if not _require(_world.map_id == ORIGIN_MAP_ID, "loaded unexpected origin %s" % _world.map_id):
		return
	if not _require(_world.get_survey_targets().is_empty(), "origin map unexpectedly owns survey source"):
		return
	_main._session_progression.grant_wallet_reward(PROPULSION_SEED_WALLET)
	if not _require(_main._try_purchase_propulsion_upgrade(), "could not purchase required propulsion upgrade"):
		return
	if not _require(_session_wallet() == 0, "propulsion setup left wallet=%d" % _session_wallet()):
		return

	if not _transition(ORIGIN_CONNECTOR_ID, RELAY_MAP_ID):
		return
	var payoff := _salvage_by_id(PAYOFF_TARGET_ID)
	if not _require(not payoff.is_empty(), "missing payoff target %s" % PAYOFF_TARGET_ID):
		return
	_player.global_position = payoff["center"]
	if not _require(_collect_salvage_for_smoke(payoff), "could not collect payoff %s" % PAYOFF_TARGET_ID):
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var lead_report: Dictionary = _main._anomaly_survey.report()
	if not _require(bool(lead_report.get("lead_available", false)), "final-dive payoff did not activate anomaly lead"):
		return
	if not _require(_session_wallet() == AnomalySurveyRuntime.SCANNER_COST, "payoff wallet=%d scanner_cost=%d" % [_session_wallet(), AnomalySurveyRuntime.SCANNER_COST]):
		return

	if not _transition(RELAY_RETURN_CONNECTOR_ID, ORIGIN_MAP_ID):
		return
	if not _require(_held_salvage == 0 and _banked_salvage == 0 and _banked_score == 0, "connector did not reset map-leg cargo/score"):
		return
	if not _require(is_equal_approx(_oxygen_seconds, _oxygen_capacity_seconds()), "connector did not reset oxygen"):
		return
	var scanner_report: Dictionary = _main._anomaly_survey.report()
	if not _require(bool(scanner_report.get("lead_available", false)) and not bool(scanner_report.get("scanner_unlocked", true)), "lead/scanner state changed across return"):
		return
	if not _verify_scanner_requirement():
		return
	var unlock: Dictionary = _main._anomaly_survey.try_unlock_scanner(_world, _player)
	if not _require(bool(unlock.get("changed", false)), "affordable scanner purchase failed: %s" % str(unlock)):
		return
	if not _require(_session_wallet() == 0 and _main._anomaly_survey.has_scanner(), "scanner transaction mismatch"):
		return
	var repeat_unlock: Dictionary = _main._anomaly_survey.try_unlock_scanner(_world, _player)
	if not _require(repeat_unlock.get("reason") == "already_unlocked" and _session_wallet() == 0, "repeat scanner purchase charged or changed state"):
		return

	if not _transition(ORIGIN_CONNECTOR_ID, RELAY_MAP_ID):
		return
	if not _require(_world.get_survey_targets().is_empty(), "relay map unexpectedly owns survey source"):
		return
	if not _transition(ANOMALY_CONNECTOR_ID, TARGET_MAP_ID):
		return
	var target := _survey_target_by_id(SURVEY_TARGET_ID)
	if not _require(not target.is_empty(), "missing survey target %s" % SURVEY_TARGET_ID):
		return
	if not _require(str(target.get("required_capability_id", "")) == ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID, "survey target scanner requirement mismatch"):
		return

	var oxygen_before := _oxygen_seconds
	var held_before := _held_salvage
	_player.global_position = target["center"]
	_process(0.0)
	if not _require(not _main._anomaly_survey.has_pending_discovery(), "survey completed instantly"):
		return
	_process(1.0)
	var partial_report: Dictionary = _main._anomaly_survey.report()
	var partial_progress := float(partial_report.get("interaction", {}).get("progress", 0.0))
	if not _require(partial_progress > 0.0 and partial_progress < 1.0, "survey partial progress invalid %.2f" % partial_progress):
		return
	if not _require(_oxygen_seconds < oxygen_before, "oxygen did not drain during survey"):
		return
	_player.global_position = _world.spawn_position
	_process(0.0)
	if not _require(not _main._anomaly_survey.has_pending_discovery() and _last_status_note == "Survey interrupted", "leave-range cancel failed"):
		return
	if not _complete_survey(target, held_before):
		return

	_reset_run()
	_prepare_current_map()
	if not _require(not _main._anomaly_survey.has_pending_discovery(), "R retained pending discovery"):
		return
	if not _complete_survey(target, held_before):
		return
	_main._handle_hazard_hit("anomaly_smoke_hazard")
	if not _require(not _main._anomaly_survey.has_pending_discovery(), "hazard retained pending discovery"):
		return
	_prepare_current_map()
	if not _complete_survey(target, held_before):
		return
	_main._handle_oxygen_depleted()
	if not _require(_run_failed and not _main._anomaly_survey.has_pending_discovery(), "oxygen failure retained pending discovery"):
		return
	_reset_run()
	_prepare_current_map()
	if not _complete_survey(target, held_before):
		return

	var oxygen_after_survey := _oxygen_seconds
	if not _transition(TARGET_RETURN_CONNECTOR_ID, RELAY_MAP_ID):
		return
	if not _require(_main._anomaly_survey.has_pending_discovery(), "target return cleared pending discovery"):
		return
	if not _transition(RELAY_RETURN_CONNECTOR_ID, ORIGIN_MAP_ID):
		return
	if not _require(_main._anomaly_survey.has_pending_discovery(), "relay return cleared pending discovery before commit"):
		return
	_process(0.0)
	if not _require(_main._anomaly_survey.has_completed_discovery() and not _main._anomaly_survey.has_pending_discovery(), "canonical boat did not commit discovery"):
		return
	var committed_result: String = _main._anomaly_survey.result_text()
	if not _require(committed_result.find("Next lead:") != -1, "commit omitted next-lead result"):
		return
	_process(0.0)
	if not _require(_main._anomaly_survey.has_completed_discovery(), "repeat boat process changed committed state"):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(reload_report.get("status") == "loaded" and reloaded.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID) and reloaded.has_completed_discovery(DISCOVERY_ID), "profile reload lost scanner/discovery"):
		return
	_reset_run()
	_main._handle_hazard_hit("committed_state_probe")
	_main._handle_oxygen_depleted()
	if not _require(_main._anomaly_survey.has_completed_discovery(), "failure cleanup deleted committed discovery"):
		return

	var final_report: Dictionary = _main._anomaly_survey.report()
	_cleanup_profile()
	print("Anomaly survey journey smoke passed: maps=%s>%s>%s>%s>%s connectors=%s,%s,%s,%s target=%s discovery=%s scanner=%s wallet=%d oxygen=%.1f->%.1f cargo=%d pending=false committed=true result=\"%s\" profile=%s." % [
		ORIGIN_MAP_ID,
		RELAY_MAP_ID,
		TARGET_MAP_ID,
		RELAY_MAP_ID,
		ORIGIN_MAP_ID,
		ORIGIN_CONNECTOR_ID,
		ANOMALY_CONNECTOR_ID,
		TARGET_RETURN_CONNECTOR_ID,
		RELAY_RETURN_CONNECTOR_ID,
		SURVEY_TARGET_ID,
		DISCOVERY_ID,
		str(final_report.get("scanner_unlocked", false)),
		_session_wallet(),
		oxygen_before,
		oxygen_after_survey,
		_held_salvage,
		committed_result.replace("\n", " | "),
		str(reload_report),
	])
	get_tree().quit(0)


func _complete_survey(target: Dictionary, expected_held: int) -> bool:
	_player.global_position = target["center"]
	_process(float(target.get("interaction_seconds", 0.0)) + 0.1)
	return _require(
		_main._anomaly_survey.has_pending_discovery() and _held_salvage == expected_held and _banked_score == 0,
		"survey completion did not preserve no-cargo/no-score semantics"
	)


func _verify_scanner_requirement() -> bool:
	_load_playable_map(PRODUCTION_SLICE_02_MAP_PATH, false)
	_prepare_current_map()
	var locked_target := _survey_target_by_id(SURVEY_TARGET_ID)
	if not _require(not locked_target.is_empty(), "scanner probe could not load survey target"):
		return false
	_player.global_position = locked_target["center"]
	_process(1.0)
	if not _require(
		_last_status_note == "Scanner required" and not _main._anomaly_survey.has_pending_discovery(),
		"target did not block survey without scanner"
	):
		return false
	_load_playable_map(PRODUCTION_SLICE_MAP_PATH, false)
	_prepare_current_map()
	return _require(
		_world.map_id == ORIGIN_MAP_ID
		and _session_wallet() == AnomalySurveyRuntime.SCANNER_COST
		and bool(_main._anomaly_survey.report().get("lead_available", false)),
		"scanner probe changed lead, wallet, or return map"
	)


func _transition(connector_id: String, expected_map_id: String) -> bool:
	var connector := _connector_by_id(connector_id)
	if not _require(not connector.is_empty(), "missing connector %s on %s" % [connector_id, _world.map_id]):
		return false
	_player.global_position = connector["center"]
	if not _require(_main._try_world_connector_transition(), "connector %s did not transition" % connector_id):
		return false
	_prepare_current_map()
	return _require(_world.map_id == expected_map_id, "connector %s loaded %s expected %s" % [connector_id, _world.map_id, expected_map_id])


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _survey_target_by_id(target_id: String) -> Dictionary:
	for target in _world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


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
