extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialCandidateSelector := preload("res://scripts/main/material_candidate_selector.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const SmokeProfileProjectFixture := preload("res://scripts/main/smoke/smoke_profile_project_fixture.gd")
const ScannerSmokePose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")

const TEST_PROFILE_PATH := "user://oceangame2_expansion_05_journey_smoke.json"
const MAP_ID := "production_slice_01"
const RELAY_MAP_ID := "production_slice_04"
const TARGET_ID := "upper_right_mineral_trace_survey"
const DISCOVERY_ID := ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID
const GATE_ID := ExpansionProfileState.PROPULSION_FINS_GATE_ID
const OUTBOUND_CONNECTOR_ID := "lower_left_loop_connector"
const RETURN_CONNECTOR_ID := "return_to_boat_hub_connector"
const COIL_POOL_ID := "conductive_coil_pool"
const RESEARCHED_COIL_ID := "material_coil_deep_cache"
const NORMAL_DAY_THREE_COIL_ID := "material_coil_scanner_floor"
const RESEARCH_LEAD := "Research lead | Coils near deep-cache machinery"


func _smoke_expansion_05_practical_research_and_quit() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	_main._expedition_day_state.begin_day(2)
	_attach_profile(profile)
	_prepare_current_map()
	if not _require(_world.map_id == MAP_ID, "loaded unexpected map %s" % _world.map_id):
		return

	var target := _survey_target_by_id(TARGET_ID)
	var gate := _gate_by_id(GATE_ID)
	if not _require(not target.is_empty() and not gate.is_empty(), "research target or current gate missing"):
		return
	var gate_rect: Rect2 = gate["rect"]
	if not _require(
		str(target.get("required_capability_id", "")) == ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID
		and target["center"].x > gate_rect.position.x + gate_rect.size.x,
		"research target is not scanner-gated beyond the current gate"
	):
		return

	if not _place_for_scan(target):
		return
	_process(0.0)
	if not _require(_last_status_note == "Scanner required" and not _main._anomaly_survey.has_pending_discovery(), "scanner-less survey was not blocked"):
		return
	if not _require(bool(SmokeProfileProjectFixture.complete_scanner(profile, _world).get("changed", false)), "scanner fixture could not build"):
		return

	_player.global_position = gate["center"]
	var blocked_x_before: float = _player.global_position.x
	var blocked_oxygen_before := _oxygen_seconds
	_process(0.25)
	var blocked_push: float = _player.global_position.x - blocked_x_before
	if not _require(blocked_push < -1.0 and _oxygen_seconds < blocked_oxygen_before, "locked current gate did not block while time advanced"):
		return
	if not _require(_prepare_propulsion_fins(), "could not seed recipe-built fins"):
		return
	_player.global_position = gate["center"]
	var unlocked_x_before: float = _player.global_position.x
	_process(0.25)
	if not _require(absf(_player.global_position.x - unlocked_x_before) < 0.01 and _main._current_gate.blocking_gate().is_empty(), "fins did not unlock target route"):
		return

	var before_ids := _active_material_ids()
	var oxygen_before := _oxygen_seconds
	if not _place_for_scan(target):
		return
	_press_key(KEY_SPACE)
	_process(1.0)
	var partial_progress := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	if not _require(partial_progress > 0.0 and partial_progress < 1.0 and _oxygen_seconds < oxygen_before, "partial survey progress or oxygen pressure drifted"):
		return
	_player.global_position = _world.spawn_position
	_process(0.0)
	if not _require(_last_status_note == "Survey interrupted" and not _main._anomaly_survey.has_pending_discovery(), "leave-range survey cancel failed"):
		return
	if not _complete_research(target):
		return
	var oxygen_after_survey := _oxygen_seconds
	if not _require(_held_salvage == 0 and _main._material_runtime.held_count() == 0 and _banked_score == 0, "survey changed cargo or score"):
		return

	_player.global_position = _world.get_extraction_center()
	if not _seed_current_stabilizer(profile):
		return
	if not _transition(OUTBOUND_CONNECTOR_ID, RELAY_MAP_ID):
		return
	if not _require(_main._anomaly_survey.has_pending_discovery(), "outbound connector cleared pending research"):
		return
	if not _transition(RETURN_CONNECTOR_ID, MAP_ID):
		return
	if not _require(_main._anomaly_survey.has_pending_discovery(), "return connector committed or cleared research early"):
		return

	_reset_run()
	_prepare_current_map()
	if not _require(not _main._anomaly_survey.has_pending_discovery(), "reset retained pending research"):
		return
	if not _complete_research(target):
		return
	_main._handle_hazard_hit("expansion_05_smoke_hazard")
	_prepare_current_map()
	if not _require(not _main._anomaly_survey.has_pending_discovery(), "hazard retained pending research"):
		return
	if not _complete_research(target):
		return
	_main._handle_oxygen_depleted()
	if not _require(_run_failed and not _main._anomaly_survey.has_pending_discovery(), "oxygen failure retained pending research"):
		return
	_reset_run()
	_prepare_current_map()
	if not _complete_research(target):
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(
		_main._anomaly_survey.has_completed_research()
		and not _main._anomaly_survey.has_pending_discovery()
		and _main._anomaly_survey.result_text() == str(target.get("finding_label", "")),
		"canonical boat did not commit source-derived research exactly once"
	):
		return
	var committed_count: int = _main._expedition_day_state.committed_discovery_ids.count(DISCOVERY_ID)
	_process(0.0)
	if not _require(
		committed_count == 1
		and _main._expedition_day_state.committed_discovery_ids.count(DISCOVERY_ID) == committed_count
		and _main._anomaly_survey.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID),
		"repeat boat update changed committed research or damaged legacy anomaly state"
	):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(
		reload_report.get("status") == "loaded"
		and reloaded.has_completed_discovery(DISCOVERY_ID)
		and reloaded.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID),
		"profile reload lost research or legacy discovery"
	):
		return

	_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state)
	var same_day_ids := _active_material_ids()
	if not _require(same_day_ids == before_ids and str(_main._material_runtime.report().get("research_lead_text", "")).is_empty(), "research rerolled or relabeled the current day"):
		return
	var next_day: int = _main._expedition_day_state.day_number + 1
	var pools: Array = _world.get_material_candidate_pools()
	var normal_next_ids := MaterialCandidateSelector.select_for_day(MAP_ID, pools, next_day, [])
	_main._expedition_day_state.begin_next_day()
	_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state)
	var researched_ids := _active_material_ids()
	var material_report: Dictionary = _main._material_runtime.report()
	if not _require(
		_coil_id(normal_next_ids) == NORMAL_DAY_THREE_COIL_ID
		and _coil_id(researched_ids) == RESEARCHED_COIL_ID
		and material_report.get("researched_pool_ids", []) == [COIL_POOL_ID]
		and material_report.get("research_lead_text", "") == RESEARCH_LEAD,
		"fresh-day practical research did not change coil planning"
	):
		return
	if not _require(
		researched_ids.size() == 4
		and _material_count(researched_ids, ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2
		and _material_count(researched_ids, ExpansionProfileState.RUBBER_MATERIAL_ID) == 1
		and _material_count(researched_ids, ExpansionProfileState.COIL_MATERIAL_ID) == 1,
		"research changed Ti2+Rubber1+Coil1 yield"
	):
		return
	if not _collect_and_bank_materials(researched_ids, profile):
		return

	var final_day: int = _main._expedition_day_state.day_number
	var final_profile: Dictionary = profile.report()
	_cleanup_profile()
	print("Expansion 05 practical-research smoke passed: target=%s discovery=%s gate=%s fins_passive=true scanner=true blocked_push=%.1f optional_connectors=%s>%s day=2 before=%s same_day=%s normal_day3=%s researched_day3=%s pool=%s pending=false committed=true oxygen=%.1f->%.1f cargo=0 banked=Ti2+Rubber1+Coil1 lead=\"%s\" next_day=%d reload=%s profile=%s." % [
		TARGET_ID,
		DISCOVERY_ID,
		GATE_ID,
		blocked_push,
		OUTBOUND_CONNECTOR_ID,
		RETURN_CONNECTOR_ID,
		str(before_ids),
		str(same_day_ids),
		str(normal_next_ids),
		str(researched_ids),
		COIL_POOL_ID,
		oxygen_before,
		oxygen_after_survey,
		RESEARCH_LEAD,
		final_day,
		str(reload_report.get("status", "")),
		str(final_profile),
	])
	get_tree().quit(0)


func _attach_profile(profile) -> void:
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, profile)
	_main._material_runtime = MaterialRuntimeController.new(profile)
	_main._material_project = MaterialProjectRuntime.new(profile)
	_main._cutter_salvage = CutterSalvageController.new(profile)
	_main._anomaly_survey.on_map_loaded(_world)
	_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state)
	_main._material_project.on_map_loaded(_world)
	_main._cutter_salvage.on_map_loaded(_world)


func _seed_current_stabilizer(profile) -> bool:
	if not _require(bool(profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false).get("changed", false)), "legacy discovery fixture failed"):
		return false
	if not _require(bool(profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 4, ExpansionProfileState.COIL_MATERIAL_ID: 2}, false).get("changed", false)), "material fixture failed"):
		return false
	for project_id in [ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID, ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID]:
		var completed: Dictionary = profile.complete_material_project(_project_by_id(project_id), false)
		if not _require(bool(completed.get("changed", false)), "project fixture failed for %s: %s" % [project_id, str(completed)]):
			return false
	return _require(profile.save_profile() and profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID) and profile.material_inventory().is_empty(), "stabilizer fixture did not persist cleanly")


func _complete_research(target: Dictionary) -> bool:
	if not _place_for_scan(target):
		return false
	_press_key(KEY_SPACE)
	_process(float(target.get("interaction_seconds", 0.0)) + 0.1)
	return _require(_main._anomaly_survey.has_pending_discovery(), "resource survey did not create pending research")


func _place_for_scan(target: Dictionary) -> bool:
	var pose: Dictionary = ScannerSmokePose.new().place(_world, _player, target)
	return _require(bool(pose.get("found", false)), "no clear scan pose for %s" % target.get("id", "target"))


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	_main._unhandled_input(event)


func _transition(connector_id: String, expected_map_id: String) -> bool:
	var connector := _connector_by_id(connector_id)
	if not _require(not connector.is_empty(), "missing connector %s on %s" % [connector_id, _world.map_id]):
		return false
	_player.global_position = connector["center"]
	if not _require(_main._try_world_connector_transition(), "connector %s did not transition" % connector_id):
		return false
	_prepare_current_map()
	return _require(_world.map_id == expected_map_id, "connector %s loaded %s" % [connector_id, _world.map_id])


func _collect_and_bank_materials(active_ids: Array, profile) -> bool:
	var reached_capacity := false
	for candidate in _world.get_material_candidates():
		if not active_ids.has(str(candidate.get("id", ""))):
			continue
		if _main._material_runtime.held_count() >= _main._held_salvage_capacity():
			reached_capacity = true
			if not _bank_held_materials():
				return false
		var held_before: int = _main._material_runtime.held_count()
		_player.global_position = candidate["center"]
		_process(0.0)
		if not _require(_main._material_runtime.held_count() == held_before + 1, "material %s did not enter cargo" % str(candidate.get("id", ""))):
			return false
	if not _require(reached_capacity and _main._held_salvage_capacity() == HELD_SALVAGE_CAPACITY, "daily materials did not preserve normal cargo capacity"):
		return false
	if not _bank_held_materials():
		return false
	return _require(
		profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2
		and profile.material_quantity(ExpansionProfileState.RUBBER_MATERIAL_ID) == 1
		and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 1,
		"boat did not bank unchanged material yield"
	)


func _bank_held_materials() -> bool:
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	return _require(_main._material_runtime.held_count() == 0, "boat did not bank held materials")


func _active_material_ids() -> Array:
	return _world.get_material_candidate_report().get("active_ids", [])


func _material_count(active_ids: Array, material_id: String) -> int:
	var count := 0
	for candidate in _world.get_material_candidates():
		if active_ids.has(str(candidate.get("id", ""))) and str(candidate.get("material_id", "")) == material_id:
			count += int(candidate.get("material_quantity", 0))
	return count


func _coil_id(active_ids: Array) -> String:
	for candidate_id in active_ids:
		if str(candidate_id).begins_with("material_coil_"):
			return str(candidate_id)
	return ""


func _project_by_id(project_id: String) -> Dictionary:
	for project in _world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _survey_target_by_id(target_id: String) -> Dictionary:
	for target in _world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_cleanup_profile()
	push_error("Expansion 05 practical-research smoke failed: %s." % message)
	get_tree().quit(1)
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
