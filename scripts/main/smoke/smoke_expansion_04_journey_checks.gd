extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")

const TEST_PROFILE_PATH := "user://oceangame2_expansion_04_journey_smoke.json"
const MAP_ID := "production_slice_01"
const GATE_ID := ExpansionProfileState.CURRENT_STABILIZER_GATE_ID
const PROJECT_ID := ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID
const CAPABILITY_ID := ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID
const PAYOFF_ID := "salvage_current_pocket_cache"
const PAYOFF_ROUTE := "current_stabilizer_payoff"
const RETURN_PROMPT := "Stabilizer ready | Return: upper-right current pocket"


func _smoke_expansion_04_current_pocket_and_quit() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	_attach_profile(profile, false)
	_main._load_playable_map(_main.PRODUCTION_SLICE_MAP_PATH, false)
	_prepare_current_map()
	if not _require(_world.map_id == MAP_ID, "loaded unexpected map %s" % _world.map_id):
		return
	if not _require(_prepare_propulsion_fins(), "could not seed the already-covered fins prerequisite"):
		return

	var parity_signature := _parity_signature()
	var gate := _gate_by_id(GATE_ID)
	var payoff := _salvage_by_id(PAYOFF_ID)
	if not _require(not gate.is_empty() and not payoff.is_empty(), "gate or payoff source missing"):
		return
	if not _require(str(gate.get("required_capability_id", "")) == CAPABILITY_ID and str(payoff.get("validation_route", "")) == PAYOFF_ROUTE, "gate/payoff metadata drifted"):
		return
	if not _require(not _world.is_salvage_collected(PAYOFF_ID), "payoff was not visible before capability"):
		return

	_player.global_position = gate["center"]
	var blocked_x_before: float = _player.global_position.x
	var blocked_oxygen_before := _oxygen_seconds
	var blocked_daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	_process(0.25)
	var blocked_push: float = _player.global_position.x - blocked_x_before
	if not _require(blocked_push < -1.0 and _status_text().find("Ripping current - need current stabilizer") != -1, "locked gate did not block with readable pushback"):
		return
	if not _require(_oxygen_seconds < blocked_oxygen_before and _main._expedition_day_state.daylight_remaining_seconds < blocked_daylight_before, "locked gate paused oxygen or daylight"):
		return

	var day_one_ids: Array = _active_material_ids()
	var day_one_recipe := _selected_recipe(day_one_ids)
	if not _require(_is_exact_recipe(day_one_recipe), "day one recipe selection drifted: %s" % str(day_one_ids)):
		return
	if not _collect_and_bank_recipe(day_one_recipe):
		return
	if not _require(_profile_has_exact_recipe(profile), "day one materials did not bank exact recipe"):
		return

	var cutter_project := _project_by_id(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID)
	var stabilizer_project := _project_by_id(PROJECT_ID)
	var missing_knowledge: Dictionary = profile.complete_material_project(cutter_project, false)
	if not _require(missing_knowledge.get("reason") == "missing_discovery", "cutter project bypassed knowledge prerequisite"):
		return
	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, true)
	var missing_cutter: Dictionary = profile.complete_material_project(stabilizer_project, false)
	if not _require(missing_cutter.get("reason") == "missing_project", "stabilizer bypassed cutter prerequisite"):
		return
	var wrong_phase: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_ACTIVE)
	if not _require(wrong_phase.get("reason") == "wrong_phase", "cutter built outside debrief"):
		return
	if not _end_day_and_build(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID, ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID):
		return
	var cutter_repeat: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	if not _require(cutter_repeat.get("reason") == "already_completed" and profile.material_inventory().is_empty(), "cutter repeat was not exact-once"):
		return

	_press_key(KEY_N)
	_prepare_current_map()
	var day_two_ids: Array = _active_material_ids()
	var day_two_recipe := _selected_recipe(day_two_ids)
	if not _require(_main._expedition_day_state.day_number == 2 and day_two_ids != day_one_ids and _is_exact_recipe(day_two_recipe), "day two recipe did not rotate deterministically"):
		return
	if not _collect_and_bank_recipe(day_two_recipe):
		return
	if not _require(_profile_has_exact_recipe(profile) and _main._material_project.status() == "ready", "stabilizer recipe did not become ready"):
		return
	wrong_phase = _main._material_project.try_build(ExpeditionDayState.PHASE_ACTIVE)
	if not _require(wrong_phase.get("reason") == "wrong_phase", "stabilizer built outside debrief"):
		return
	if not _end_day_and_build(PROJECT_ID, CAPABILITY_ID):
		return
	var stabilizer_repeat: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	if not _require(stabilizer_repeat.get("reason") == "already_completed" and profile.material_inventory().is_empty(), "stabilizer repeat was not exact-once"):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(reload_report.get("status") == "loaded" and reloaded.has_completed_project(PROJECT_ID) and reloaded.has_capability(CAPABILITY_ID), "profile reload lost stabilizer"):
		return
	_press_key(KEY_N)
	_prepare_current_map()
	_attach_profile(reloaded, true)
	_update_status_label()
	if not _require(_main._expedition_day_state.day_number == 3 and _status_text().find(RETURN_PROMPT) != -1, "next day did not present remembered return cue"):
		return
	if not _require(_parity_signature() == parity_signature, "journey changed terrain or collision parity"):
		return

	gate = _gate_by_id(GATE_ID)
	payoff = _salvage_by_id(PAYOFF_ID)
	_player.global_position = gate["center"]
	var unlocked_x_before: float = _player.global_position.x
	var unlocked_oxygen_before := _oxygen_seconds
	var unlocked_daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	_process(0.25)
	var unlocked_delta: float = _player.global_position.x - unlocked_x_before
	if not _require(absf(unlocked_delta) < 0.01 and _main._current_gate.blocking_gate().is_empty(), "stabilizer did not permit stable passage"):
		return
	if not _require(_oxygen_seconds < unlocked_oxygen_before and _main._expedition_day_state.daylight_remaining_seconds < unlocked_daylight_before, "unlocked crossing paused oxygen or daylight"):
		return

	for index in range(_main._held_salvage_capacity()):
		_main._sortie_state.collect_salvage("expansion_04_capacity_fixture_%d" % index, 0)
	_player.global_position = payoff["center"]
	_process(0.0)
	if not _require(not _world.is_salvage_collected(PAYOFF_ID) and not _held_salvage_ids.has(PAYOFF_ID) and _status_text().find("Cargo full") != -1, "cargo-full attempt deleted payoff"):
		return
	_main._sortie_state.clear_held()

	_player.global_position = payoff["center"]
	_process(0.0)
	if not _require(_held_salvage_ids.has(PAYOFF_ID) and _held_salvage_score == 300 and _last_status_note == "Upper-right current pocket +300", "payoff did not enter normal valuable cargo"):
		return
	_main._handle_hazard_hit("expansion_04_smoke_hazard")
	if not _require(not _held_salvage_ids.has(PAYOFF_ID) and not _world.is_salvage_collected(PAYOFF_ID) and reloaded.has_capability(CAPABILITY_ID), "failure did not restore payoff or preserve capability"):
		return
	_prepare_current_map()
	_player.global_position = payoff["center"]
	_process(0.0)
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(_held_salvage == 0 and _banked_salvage_ids.has(PAYOFF_ID) and _banked_score == 300, "boat did not bank current-pocket payoff"):
		return

	var final_oxygen := _oxygen_seconds
	var final_daylight: float = _main._expedition_day_state.daylight_remaining_seconds
	_cleanup_profile()
	print("Expansion 04 current-pocket smoke passed: gate=%s capability=%s project=%s recipe=Ti2+Coil1 day1=%s day2=%s blocked_push=%.1f unlocked_delta=%.1f payoff=%s cargo=%d score=%d oxygen=%.1f daylight=%.1f day=%d reload=%s parity=stable." % [
		GATE_ID,
		CAPABILITY_ID,
		PROJECT_ID,
		str(day_one_ids),
		str(day_two_ids),
		blocked_push,
		unlocked_delta,
		PAYOFF_ID,
		_held_salvage,
		_banked_score,
		final_oxygen,
		final_daylight,
		_main._expedition_day_state.day_number,
		str(reload_report.get("status", "")),
	])
	get_tree().quit(0)


func _attach_profile(profile, current_world_loaded: bool) -> void:
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, profile)
	_main._material_runtime = MaterialRuntimeController.new(profile)
	_main._material_project = MaterialProjectRuntime.new(profile)
	_main._cutter_salvage = CutterSalvageController.new(profile)
	if not current_world_loaded:
		return
	_main._anomaly_survey.on_map_loaded(_world)
	_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state)
	_main._material_project.on_map_loaded(_world)
	_main._cutter_salvage.on_map_loaded(_world)


func _end_day_and_build(project_id: String, capability_id: String) -> bool:
	_player.global_position = _world.get_extraction_center()
	if not _main._expedition_day_state.request_end_day("voluntary"):
		return _require(false, "day end request failed")
	_process(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "day did not enter debrief"):
		return false
	_press_key(KEY_P)
	var profile = _main._anomaly_survey.profile_state()
	return _require(profile.has_completed_project(project_id) and profile.has_capability(capability_id) and profile.material_inventory().is_empty(), "debrief did not complete %s" % project_id)


func _collect_and_bank_recipe(recipe: Dictionary) -> bool:
	var candidates: Array = recipe["titanium"] + recipe["coil"]
	for candidate in candidates:
		if _main._material_runtime.held_count() >= _main._held_salvage_capacity():
			if not _bank_held_materials():
				return false
		var held_before: int = _main._material_runtime.held_count()
		_player.global_position = candidate["center"]
		_process(0.0)
		if not _require(_main._material_runtime.held_count() == held_before + 1, "material %s did not enter cargo" % str(candidate.get("id", ""))):
			return false
	return _bank_held_materials()


func _bank_held_materials() -> bool:
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	return _require(_main._material_runtime.held_count() == 0, "boat did not bank held materials")


func _active_material_ids() -> Array:
	return _world.get_material_candidate_report().get("active_ids", [])


func _selected_recipe(active_ids: Array) -> Dictionary:
	var titanium := []
	var coil := []
	for candidate in _world.get_material_candidates():
		if not active_ids.has(str(candidate.get("id", ""))):
			continue
		if str(candidate.get("material_id", "")) == ExpansionProfileState.TITANIUM_MATERIAL_ID:
			titanium.append(candidate)
		elif str(candidate.get("material_id", "")) == ExpansionProfileState.COIL_MATERIAL_ID:
			coil.append(candidate)
	return {"titanium": titanium, "coil": coil}


func _is_exact_recipe(recipe: Dictionary) -> bool:
	return recipe["titanium"].size() == 2 and recipe["coil"].size() == 1


func _profile_has_exact_recipe(profile) -> bool:
	return (
		profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2
		and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 1
	)


func _project_by_id(project_id: String) -> Dictionary:
	for project in _world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _parity_signature() -> String:
	var report: Dictionary = _world.get_runtime_parity_report()
	return "%s|%s" % [JSON.stringify(report.get("terrain_cells", [])), JSON.stringify(report.get("collision_rects", []))]


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	_main._unhandled_input(event)


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false


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
