extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")

const TEST_PROFILE_PATH := "user://oceangame2_expansion_03_journey_smoke.json"
const ORIGIN_MAP_ID := "production_slice_01"
const RELAY_MAP_ID := "production_slice_04"
const ORIGIN_CONNECTOR_ID := "lower_left_loop_connector"
const RETURN_CONNECTOR_ID := "return_to_boat_hub_connector"
const TARGET_ID := ExpansionProfileState.SALVAGE_CUTTER_TARGET_ID


func _smoke_expansion_03_material_project_and_quit() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, profile)
	_main._material_runtime = MaterialRuntimeController.new(profile)
	_main._material_project = MaterialProjectRuntime.new(profile)
	_main._cutter_salvage = CutterSalvageController.new(profile)
	_main._load_playable_map(_main.PRODUCTION_SLICE_MAP_PATH, false)
	_prepare_current_map()
	if not _require(_world.map_id == ORIGIN_MAP_ID, "loaded unexpected origin %s" % _world.map_id):
		return

	var day_one_seed: int = _main._expedition_day_state.material_day_seed
	var day_one_report: Dictionary = _world.get_material_candidate_report()
	var day_one_ids: Array = day_one_report.get("active_ids", [])
	var recipe: Dictionary = _selected_recipe(day_one_ids)
	if not _require(day_one_ids.size() == 3 and recipe["titanium"].size() == 2 and recipe["coil"].size() == 1, "day one did not guarantee exact recipe: %s" % str(day_one_ids)):
		return
	_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state)
	if not _require(_world.get_material_candidate_report().get("active_ids", []) == day_one_ids, "same-day selection rerolled"):
		return

	var tool_target := _tool_target()
	if not _require(not tool_target.is_empty(), "missing sealed wreck target"):
		return
	_player.global_position = tool_target["center"]
	var locked_oxygen_before := _oxygen_seconds
	var locked_daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	_process(0.25)
	if not _require(_last_status_note == "Sealed wreck | Cutter required" and not _world.is_salvage_collected(TARGET_ID), "sealed wreck was not locked before cutter"):
		return
	if not _require(_oxygen_seconds < locked_oxygen_before and _main._expedition_day_state.daylight_remaining_seconds < locked_daylight_before, "locked target paused oxygen or daylight"):
		return

	var titanium: Array = recipe["titanium"]
	var coils: Array = recipe["coil"]
	_player.global_position = _world.get_extraction_center()
	_main._session_progression.grant_wallet_reward(1000)
	if not _require(_main._try_purchase_propulsion_upgrade(), "could not unlock connector for material preservation probe"):
		return
	if not _collect_material(titanium[0], 1):
		return
	if not _transition(ORIGIN_CONNECTOR_ID, RELAY_MAP_ID):
		return
	if not _require(_main._material_runtime.held_count() == 1, "connector cleared held material"):
		return
	if not _transition(RETURN_CONNECTOR_ID, ORIGIN_MAP_ID):
		return
	if not _require(_main._material_runtime.held_count() == 1, "return connector cleared held material"):
		return

	if not _collect_material(coils[0], 2):
		return
	_player.global_position = titanium[1]["center"]
	_process(0.0)
	if not _require(_main._material_runtime.held_count() == 2 and not _world.get_material_candidate_near(titanium[1]["center"], SALVAGE_COLLECTION_RADIUS).is_empty(), "cargo pressure deleted or collected blocked recipe material"):
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 1 and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 1, "first boat commit did not bank held recipe materials"):
		return
	if not _collect_material(titanium[1], 1):
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var banked_titanium_before_project := profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID)
	var banked_coil_before_project := profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID)
	if not _require(banked_titanium_before_project == 2 and banked_coil_before_project == 1 and _main._material_runtime.held_count() == 0, "canonical boat did not bank complete project recipe"):
		return
	var day_one_depleted: Array = _main._expedition_day_state.material_depleted_ids(ORIGIN_MAP_ID)
	day_one_depleted.sort()
	if not _require(day_one_depleted == day_one_ids, "banked recipe depletion drifted: active=%s depleted=%s" % [str(day_one_ids), str(day_one_depleted)]):
		return

	var knowledge_gate: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	if not _require(knowledge_gate.get("reason") == "missing_discovery", "project did not enforce anomaly knowledge"):
		return
	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, true)
	if not _require(_main._material_project.status() == "ready", "complete recipe and discovery did not ready project"):
		return
	_main._expedition_day_state.request_end_day("voluntary")
	_process(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "boat end request did not enter debrief"):
		return
	_press_key(KEY_P)
	if not _require(profile.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID) and profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "debrief P did not complete cutter project"):
		return
	if not _require(profile.material_inventory().is_empty(), "project did not consume exact banked recipe"):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(reload_report.get("status") == "loaded" and reloaded.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID) and reloaded.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "profile reload lost project or cutter"):
		return
	_press_key(KEY_N)
	_prepare_current_map()
	var day_two_report: Dictionary = _world.get_material_candidate_report()
	var day_two_ids: Array = day_two_report.get("active_ids", [])
	var day_two_recipe: Dictionary = _selected_recipe(day_two_ids)
	if not _require(_main._expedition_day_state.day_number == 2 and _main._expedition_day_state.material_day_seed == 2, "next day did not advance day/seed"):
		return
	if not _require(day_two_ids.size() == 3 and day_two_ids != day_one_ids and day_two_recipe["titanium"].size() == 2 and day_two_recipe["coil"].size() == 1, "next day did not rotate to a guaranteed recipe"):
		return
	_attach_profile(reloaded)
	if not _require(_main._cutter_salvage.has_cutter(), "reloaded runtime did not retain cutter"):
		return

	tool_target = _tool_target()
	_player.global_position = tool_target["center"]
	var cutter_oxygen_before := _oxygen_seconds
	_process(0.5)
	if not _require(str(_main._cutter_salvage.report().get("active_id", "")) == TARGET_ID and _oxygen_seconds < cutter_oxygen_before, "cutter progress or oxygen drain did not start"):
		return
	_player.global_position = tool_target["center"] + Vector2(200.0, 0.0)
	_process(0.0)
	if not _require(_last_status_note == "Cutter interrupted", "leaving target did not cancel cutter"):
		return
	_player.global_position = tool_target["center"]
	_process(1.6)
	if not _require(not _world.is_salvage_collected(TARGET_ID), "canceled cutter progress resumed"):
		return
	_process(0.5)
	if not _require(_world.is_salvage_collected(TARGET_ID) and _held_salvage == 1 and _held_salvage_score == 300, "cutter did not create valuable held payoff"):
		return
	_main._handle_hazard_hit("expansion_03_smoke_hazard")
	if not _require(_held_salvage == 0 and not _world.get_tool_target_near(tool_target["center"], SALVAGE_COLLECTION_RADIUS).is_empty(), "failure did not restore unbanked cutter payoff"):
		return
	if not _require(_main._cutter_salvage.has_cutter(), "failure removed durable cutter"):
		return
	_prepare_current_map()
	_player.global_position = tool_target["center"]
	_process(float(tool_target.get("interaction_seconds", 2.0)) + 0.1)
	if not _require(_held_salvage == 1 and _held_salvage_score == 300, "restored cutter payoff could not be recollected"):
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(_held_salvage == 0 and _banked_score == 300 and _main._cutter_salvage.is_target_banked(TARGET_ID), "final cutter payoff did not bank exactly once"):
		return

	var final_oxygen := _oxygen_seconds
	var final_cargo: int = _held_salvage + _main._material_runtime.held_count()
	var final_project_status: String = _main._material_project.status()
	_cleanup_profile()
	print("Expansion 03 material project smoke passed: day=%d seed=%d day1_seed=%d active=%s depleted=%s day2_active=%s held_material=%d banked_before_project=Ti%d+Coil%d banked_after_project=Ti%d+Coil%d project=%s cutter=%s target=banked cargo=%d banked_score=%d oxygen=%.1f final=sealed_wreck_banked profile_reload=%s." % [
		_main._expedition_day_state.day_number,
		_main._expedition_day_state.material_day_seed,
		day_one_seed,
		str(day_one_ids),
		str(day_one_depleted),
		str(day_two_ids),
		_main._material_runtime.held_count(),
		banked_titanium_before_project,
		banked_coil_before_project,
		reloaded.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID),
		reloaded.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID),
		final_project_status,
		str(_main._cutter_salvage.has_cutter()),
		final_cargo,
		_banked_score,
		final_oxygen,
		str(reload_report.get("status", "")),
	])
	get_tree().quit(0)


func _attach_profile(profile) -> void:
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, profile)
	_main._anomaly_survey.on_map_loaded(_world)
	_main._material_runtime = MaterialRuntimeController.new(profile)
	_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state)
	_main._material_project = MaterialProjectRuntime.new(profile)
	_main._material_project.on_map_loaded(_world)
	_main._cutter_salvage = CutterSalvageController.new(profile)
	_main._cutter_salvage.on_map_loaded(_world)


func _selected_recipe(active_ids: Array) -> Dictionary:
	var titanium := []
	var coils := []
	for candidate in _world.get_material_candidates():
		if not active_ids.has(str(candidate.get("id", ""))):
			continue
		if str(candidate.get("material_id", "")) == ExpansionProfileState.TITANIUM_MATERIAL_ID:
			titanium.append(candidate)
		elif str(candidate.get("material_id", "")) == ExpansionProfileState.COIL_MATERIAL_ID:
			coils.append(candidate)
	return {"titanium": titanium, "coil": coils}


func _collect_material(candidate: Dictionary, expected_held: int) -> bool:
	_player.global_position = candidate.get("center", Vector2.ZERO)
	_process(0.0)
	return _require(_main._material_runtime.held_count() == expected_held, "material %s did not enter held cargo" % str(candidate.get("id", "")))


func _transition(connector_id: String, expected_map_id: String) -> bool:
	var connector := _connector_by_id(connector_id)
	if not _require(not connector.is_empty(), "missing connector %s on %s" % [connector_id, _world.map_id]):
		return false
	_player.global_position = connector["center"]
	if not _require(_main._try_world_connector_transition(), "connector %s did not transition" % connector_id):
		return false
	_prepare_current_map()
	return _require(_world.map_id == expected_map_id, "connector %s loaded %s expected %s" % [connector_id, _world.map_id, expected_map_id])


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _tool_target() -> Dictionary:
	for target in _world.get_tool_targets():
		if str(target.get("id", "")) == TARGET_ID:
			return target
	return {}


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	_main._unhandled_input(event)


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_cleanup_profile()
	push_error("Expansion 03 material project smoke failed: %s." % message)
	get_tree().quit(1)
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
