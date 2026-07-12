extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")

const TEST_PROFILE_PATH := "user://oceangame2_expansion_04_journey_smoke.json"
const MAP_ID := "production_slice_01"
const GATE_ID := ExpansionProfileState.PROPULSION_FINS_GATE_ID
const PROJECT_ID := ExpansionProfileState.PROPULSION_FINS_PROJECT_ID
const CAPABILITY_ID := ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID
const PAYOFF_ID := "salvage_current_pocket_cache"
const PAYOFF_ROUTE := "propulsion_fins_payoff"


func _smoke_expansion_04_current_pocket_and_quit() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	_attach_profile(profile, false)
	_main._load_playable_map(_main.PRODUCTION_SLICE_MAP_PATH, false)
	_prepare_current_map()
	if not _require(_world.map_id == MAP_ID, "loaded unexpected map %s" % _world.map_id):
		return

	var gate := _gate_by_id(GATE_ID)
	var payoff := _salvage_by_id(PAYOFF_ID)
	var project := _project_by_id(PROJECT_ID)
	var advanced_project := _project_by_id(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID)
	var shock_project := _project_by_id(ExpansionProfileState.SHOCK_PROD_PROJECT_ID)
	if not _require(not gate.is_empty() and not payoff.is_empty() and not project.is_empty(), "fins gate, project, or payoff source missing"):
		return
	if not _require(
		str(gate.get("required_capability_id", "")) == CAPABILITY_ID
		and str(project.get("target_gate_id", "")) == GATE_ID
		and str(payoff.get("validation_route", "")) == PAYOFF_ROUTE,
		"same-map fins source contract drifted"
	):
		return
	if not _require(
		str(advanced_project.get("target_gate_id", "")) == ExpansionProfileState.CURRENT_STABILIZER_GATE_ID
		and str(shock_project.get("required_project_id", "")) == ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID,
		"advanced current remained in the mandatory weapon chain"
	):
		return

	_player.global_position = gate["center"]
	_player.reset_motion()
	var oxygen_before: float = _oxygen_seconds
	var x_before: float = _player.global_position.x
	_process(0.25)
	var blocked_push: float = _player.global_position.x - x_before
	if not _require(blocked_push < -1.0 and _status_text().find("need propulsion fins") != -1, "standard current did not block before fins"):
		return
	if not _require(_oxygen_seconds < oxygen_before, "blocked current paused oxygen"):
		return

	if not _require(bool(profile.complete_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID, false).get("changed", false)), "could not seed fins blueprint"):
		return
	if not _require(bool(profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	}, false).get("changed", false)), "could not seed fins recipe"):
		return
	var build: Dictionary = profile.complete_material_project(project, true)
	if not _require(bool(build.get("changed", false)) and profile.has_capability(CAPABILITY_ID), "recipe-backed fins did not build"):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(reload_report.get("status") == "loaded" and reloaded.has_capability(CAPABILITY_ID), "profile reload lost fins"):
		return
	_attach_profile(reloaded, true)
	_main._current_gate.reset()

	gate = _gate_by_id(GATE_ID)
	var gate_rect: Rect2 = gate["rect"]
	_player.global_position = Vector2(gate_rect.position.x + 8.0, gate_rect.get_center().y)
	_player.reset_motion()
	var map_before := str(_world.map_id)
	if _main._try_world_connector_transition() or str(_world.map_id) != map_before:
		_require(false, "E changed maps at the standard current")
		return
	var swim_motion := Vector2(gate_rect.size.x + 1.0, 0.0)
	if not _require(not _player.test_move(_player.global_transform, swim_motion), "player collision envelope cannot traverse the fins current"):
		return
	_player.global_position += swim_motion
	_process(1.0 / 60.0)
	if not _require(_player.global_position.x > gate_rect.end.x, "normal swimming did not cross the current after fins"):
		return

	payoff = _salvage_by_id(PAYOFF_ID)
	_player.global_position = payoff["center"]
	_process(0.0)
	if not _require(_held_salvage_ids.has(PAYOFF_ID) and _held_salvage_score == AnomalySurveyRuntime.SCANNER_COST, "same-map payoff did not enter normal valuable cargo"):
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(
		_banked_salvage_ids.has(PAYOFF_ID)
		and _banked_score == AnomalySurveyRuntime.SCANNER_COST
		and bool(_main._anomaly_survey.report().get("lead_available", false)),
		"same-map payoff did not fund and activate scanner lead"
	):
		return

	_cleanup_profile()
	print("Expansion 04 current-pocket smoke passed: gate=%s capability=%s blocked_before=true push=%.1f passive_after=true crossed_by_swimming=true e_required=false payoff=%s scanner_funding=%d scanner_lead=true shock_prerequisite=cutter advanced_current=optional reload=%s." % [
		GATE_ID,
		CAPABILITY_ID,
		blocked_push,
		PAYOFF_ID,
		_banked_score,
		str(reload_report.get("status", "")),
	])
	get_tree().quit(0)


func _attach_profile(profile, current_world_loaded: bool) -> void:
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, profile)
	_main._material_runtime = MaterialRuntimeController.new(profile)
	_main._material_project = MaterialProjectRuntime.new(profile)
	_main._cutter_salvage = CutterSalvageController.new(profile)
	if current_world_loaded:
		_main._anomaly_survey.on_map_loaded(_world)
		_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state)
		_main._material_project.on_map_loaded(_world)
		_main._cutter_salvage.on_map_loaded(_world)


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false
	_player.reset_motion()


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_cleanup_profile()
	push_error("Expansion 04 current-pocket smoke failed: %s." % message)
	get_tree().quit(1)
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
