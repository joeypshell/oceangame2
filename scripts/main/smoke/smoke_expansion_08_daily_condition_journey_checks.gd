extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialCandidateSelector := preload("res://scripts/main/material_candidate_selector.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")

const TEST_PROFILE_PATH := "user://oceangame2_expansion_08_daily_condition_smoke.json"
const CONDITION_ID := "southwest_jellyfish_bloom"
const BONUS_ID := "material_coil_southwest_bloom"
const MIGRATION_ID := "southwest_bloom_jellyfish_patrol"
const UNCONDITIONAL_PATROL_ID := "deep_route_jellyfish_patrol"
const CURRENT_GATE_ID := "upper_right_current_pocket_gate"
const ROUTE_OBJECTIVE_ID := "deep_cache_route_objective"
const COIL_ID := ExpansionProfileState.COIL_MATERIAL_ID

var _profile


func _smoke_expansion_08_daily_condition_journey_and_quit() -> void:
	_cleanup_profile()
	_profile = ExpansionProfileState.new(TEST_PROFILE_PATH)
	_profile.load_profile()
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, _profile)
	_main._material_runtime = MaterialRuntimeController.new(_profile)
	_main._material_project = MaterialProjectRuntime.new(_profile)
	_main._load_playable_map(_main.PRODUCTION_SLICE_MAP_PATH, false)
	_prepare_current_map()

	var day_one_conditions: Dictionary = _main._daily_conditions.report()
	var day_one_patrols := _active_patrol_ids()
	if not _require(
		day_one_conditions["current_condition_ids"].is_empty()
		and day_one_conditions["next_condition_ids"] == [CONDITION_ID]
		and day_one_patrols == [UNCONDITIONAL_PATROL_ID]
		and not _active_material_ids().has(BONUS_ID),
		"day-one baseline or forecast drifted"
	):
		return
	if not _verify_required_progression(1, false):
		return
	if not _require(_prepare_propulsion_fins(), "baseline day could not complete the authored fins progression"):
		return
	if not _verify_required_progression(1, true):
		return

	if not _enter_debrief():
		return
	var night_one_text := ExpeditionDayDebrief.build_text(_main._expedition_day_state, _main._material_project, _main._daily_conditions)
	if not _require(night_one_text.find("Tomorrow: Southwest jellyfish bloom") != -1, "night one omitted the bloom forecast"):
		return
	ExpeditionDayDebrief.handle_day_key(_main)
	_prepare_current_map()

	var day_two_conditions: Dictionary = _main._daily_conditions.report()
	var day_two_patrols := _active_patrol_ids()
	var day_two_materials := _active_material_ids()
	var selected_bonus := [BONUS_ID] if day_two_materials.has(BONUS_ID) else []
	if not _require(
		_main._expedition_day_state.day_number == 2
		and day_two_conditions["current_condition_ids"] == [CONDITION_ID]
		and day_two_conditions["next_condition_ids"].is_empty()
		and day_two_patrols == [UNCONDITIONAL_PATROL_ID, MIGRATION_ID]
		and selected_bonus == [BONUS_ID]
		and _main._status_label.text.find("Southwest bloom: jellyfish + coil trace") != -1,
		"day-two bloom activation or presentation drifted"
	):
		return
	if not _verify_required_progression(2, true):
		return

	var bonus := _material_candidate(BONUS_ID)
	if not _require(not bonus.is_empty(), "missing authored bloom bonus candidate"):
		return
	if not _fill_cargo_and_verify_bonus_block(bonus):
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var coil_before: int = _profile.material_quantity(COIL_ID)
	var oxygen_before: float = _oxygen_seconds
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	_player.global_position = bonus["center"]
	_process(0.25)
	if not _require(
		_main._material_runtime.held_count() == 1
		and int(_main._material_runtime.held_quantities().get(COIL_ID, 0)) == 1
		and _oxygen_seconds < oxygen_before
		and _main._expedition_day_state.daylight_remaining_seconds < daylight_before,
		"bloom bonus collection bypassed cargo, oxygen, or daylight"
	):
		return
	var held_at_bloom: int = _main._material_runtime.held_count()
	var daylight_after_bloom: float = _main._expedition_day_state.daylight_remaining_seconds
	_main._handle_hazard_hit("expansion_08_smoke_hazard")
	var oxygen_after_hazard: float = _oxygen_seconds
	if not _require(
		_main._material_runtime.held_count() == 0
		and not _world.get_material_candidate_near(bonus["center"], SALVAGE_COLLECTION_RADIUS).is_empty()
		and _main._daily_conditions.current_ids() == [CONDITION_ID]
		and oxygen_after_hazard < oxygen_before,
		"hazard failure did not restore the unbanked bloom opportunity"
	):
		return

	_player.global_position = bonus["center"]
	_process(0.0)
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var banked_coil: int = _profile.material_quantity(COIL_ID)
	if not _require(
		_main._material_runtime.held_count() == 0
		and banked_coil == coil_before + 1,
		"boat banking did not persist the bloom coil exactly once"
	):
		return

	if not _enter_debrief():
		return
	var night_two_text := ExpeditionDayDebrief.build_text(_main._expedition_day_state, _main._material_project, _main._daily_conditions)
	if not _require(night_two_text.find("Tomorrow: Baseline waters") != -1, "night two omitted the baseline forecast"):
		return
	ExpeditionDayDebrief.handle_day_key(_main)
	_prepare_current_map()
	var day_three_conditions: Dictionary = _main._daily_conditions.report()
	var day_three_patrols := _active_patrol_ids()
	if not _require(
		_main._expedition_day_state.day_number == 3
		and day_three_conditions["current_condition_ids"].is_empty()
		and day_three_conditions["next_condition_ids"] == [CONDITION_ID]
		and day_three_patrols == [UNCONDITIONAL_PATROL_ID]
		and not _active_material_ids().has(BONUS_ID)
		and _profile.material_quantity(COIL_ID) == banked_coil,
		"day-three rotation removed baseline content or banked bloom material"
	):
		return
	if not _verify_required_progression(3, true):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(
		reload_report.get("status") == "loaded" and reloaded.material_quantity(COIL_ID) == banked_coil,
		"saved bloom material did not survive profile reload"
	):
		return
	_cleanup_profile()
	print("Expansion 08 daily-condition journey smoke passed: final_day=%d day1_current=%s day1_next=%s day2_current=%s day2_next=%s day3_current=%s patrols=%s>%s>%s selected_bonus=%s held=%d banked_coil=%d oxygen=%.1f->%.1f daylight=%.1f->%.1f progression=baseline,bloom cargo_full=true failure_restored=true reload=loaded." % [
		_main._expedition_day_state.day_number,
		str(day_one_conditions["current_condition_ids"]),
		str(day_one_conditions["next_condition_ids"]),
		str(day_two_conditions["current_condition_ids"]),
		str(day_two_conditions["next_condition_ids"]),
		str(day_three_conditions["current_condition_ids"]),
		str(day_one_patrols),
		str(day_two_patrols),
		str(day_three_patrols),
		str(selected_bonus),
		held_at_bloom,
		banked_coil,
		oxygen_before,
		oxygen_after_hazard,
		daylight_before,
		daylight_after_bloom,
	])
	get_tree().quit(0)


func _verify_required_progression(day_number: int, expect_gate_open: bool) -> bool:
	var active_ids := _active_material_ids()
	var normal_ids := active_ids.duplicate()
	normal_ids.erase(BONUS_ID)
	var completed: Array = _profile.report().get("completed_discoveries", [])
	var expected := MaterialCandidateSelector.select_for_day(
		str(_world.map_id),
		_world.get_material_candidate_pools(),
		day_number,
		completed
	)
	normal_ids.sort()
	expected.sort()
	if not _require(normal_ids == expected, "day %d changed unconditional material selection" % day_number):
		return false
	var quantities := {"titanium_scrap": 0, COIL_ID: 0}
	for candidate in _world.get_material_candidates():
		var candidate_id := str(candidate.get("id", ""))
		if normal_ids.has(candidate_id):
			var material_id := str(candidate.get("material_id", ""))
			quantities[material_id] = int(quantities.get(material_id, 0)) + int(candidate.get("material_quantity", 0))
	if not _require(int(quantities.get("titanium_scrap", 0)) >= 2 and int(quantities.get(COIL_ID, 0)) >= 1, "day %d lost the mandatory project recipe" % day_number):
		return false
	var objective := _route_objective(ROUTE_OBJECTIVE_ID)
	var salvage_ids := _salvage_ids()
	for required_id in objective.get("required_banked_targets", []):
		if not _require(salvage_ids.has(str(required_id)), "day %d lost required objective target %s" % [day_number, str(required_id)]):
			return false
	var gate := _current_gate(CURRENT_GATE_ID)
	if not _require(not objective.is_empty() and not gate.is_empty(), "day %d lost required progression source records" % day_number):
		return false
	var blocked: Dictionary = _main._current_gate.gate_blocks_position(
		_world,
		gate["center"],
		Callable(_main, "_has_upgrade_id"),
		Callable(_profile, "has_capability")
	)
	return _require(blocked.is_empty() == expect_gate_open, "day %d progression gate state was not executable" % day_number)


func _fill_cargo_and_verify_bonus_block(bonus: Dictionary) -> bool:
	var targets := []
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant" and not _world.is_inside_boat(salvage["center"]):
			targets.append(salvage)
	if not _require(targets.size() >= _held_salvage_capacity(), "cargo-full fixture lacks instant salvage"):
		return false
	for index in range(_held_salvage_capacity()):
		_player.global_position = targets[index]["center"]
		_process(0.0)
	if not _require(_held_salvage == _held_salvage_capacity(), "cargo-full fixture did not fill capacity"):
		return false
	_player.global_position = bonus["center"]
	_process(0.0)
	return _require(
		_main._material_runtime.held_count() == 0
		and not _world.get_material_candidate_near(bonus["center"], SALVAGE_COLLECTION_RADIUS).is_empty()
		and _last_status_note.find("Cargo full") != -1,
		"cargo-full attempt depleted or collected the bloom bonus"
	)


func _enter_debrief() -> bool:
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(_main._expedition_day_state.request_end_day("voluntary"), "could not request end day at boat"):
		return false
	_process(0.0)
	return _require(_main._expedition_day_state.phase == _main._expedition_day_state.PHASE_DEBRIEF, "day did not enter debrief")


func _material_candidate(candidate_id: String) -> Dictionary:
	for candidate in _world.get_material_candidates():
		if str(candidate.get("id", "")) == candidate_id:
			return candidate
	return {}


func _active_material_ids() -> Array:
	var ids: Array = _world.get_material_candidate_report().get("active_ids", [])
	ids.sort()
	return ids


func _active_patrol_ids() -> Array:
	var ids := []
	for hazard in _world.get_moving_hazards():
		ids.append(str(hazard.get("id", "")))
	ids.sort()
	return ids


func _route_objective(objective_id: String) -> Dictionary:
	for objective in _world.get_route_objectives():
		if str(objective.get("id", "")) == objective_id:
			return objective
	return {}


func _current_gate(gate_id: String) -> Dictionary:
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _salvage_ids() -> Array:
	var ids := []
	for salvage in _world.get_salvage_centers():
		ids.append(str(salvage.get("id", "")))
	return ids


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_cleanup_profile()
	push_error("Expansion 08 daily-condition journey smoke failed: %s." % message)
	get_tree().quit(1)
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
