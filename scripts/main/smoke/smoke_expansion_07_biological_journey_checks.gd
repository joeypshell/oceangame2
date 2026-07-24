extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const BiologicalResourceController := preload("res://scripts/main/biological_resource_controller.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")
const SmokeProfileProjectFixture := preload("res://scripts/main/smoke/smoke_profile_project_fixture.gd")

const TEST_PROFILE_PATH := "user://oceangame2_expansion_07_biological_smoke.json"
const PASSIVE_ID := "upper_right_glow_anemone_sample"
const HOSTILE_SOURCE_ID := "deep_cache_eel_electrocyte_harvest"
const HOSTILE_ID := ExpansionProfileState.SHOCK_PROD_TARGET_ID
const PROJECT_ID := ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID
const CAPABILITY_ID := ExpansionProfileState.SHOCK_PROD_CAPACITOR_CAPABILITY_ID
const STANDARD_RECIPE := {
	ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
	ExpansionProfileState.COIL_MATERIAL_ID: 1,
}


func _smoke_expansion_07_biological_progression_and_quit() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	_attach_profile(profile, false)
	_main._load_playable_map(_main.PRODUCTION_SLICE_MAP_PATH, false)
	_prepare_current_map()
	if not _seed_base_shock_prod(profile):
		return

	var passive := _biological_source(PASSIVE_ID)
	var harvest := _biological_source(HOSTILE_SOURCE_ID)
	var capacitor_project := _project_by_id(PROJECT_ID)
	if not _verify_source_contract(passive, harvest, capacitor_project):
		return

	var pressure := _exercise_passive_sample(profile, passive)
	if pressure.is_empty():
		return
	if not _exercise_base_weapon_harvest(profile, harvest):
		return
	var journey_banked_score: int = _banked_score
	var banked_before_build := profile.material_inventory()
	if not _build_and_reload_capacitor(profile):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(
		reload_report.get("status") == "loaded"
		and reloaded.has_completed_project(PROJECT_ID)
		and reloaded.has_capability(CAPABILITY_ID),
		"profile reload lost the capacitor project or capability"
	):
		return
	_press_key(KEY_N)
	_prepare_current_map()
	_attach_profile(reloaded, true)
	if not _require(
		_main._biological_resources.report().get("collected_ids", []).is_empty()
		and _hostile_phase() == "home",
		"fresh day did not replenish biological sources and hostile state"
	):
		return
	var interrupt := _exercise_capacitor_interrupt()
	if interrupt.is_empty():
		return

	var final_oxygen: float = _oxygen_seconds
	var final_daylight: float = _main._expedition_day_state.daylight_remaining_seconds
	var held_cargo: int = _main._held_cargo_count()
	_cleanup_profile()
	print("Expansion 07 biological-progression smoke passed: passive=%s gel=%d nonlethal=true progress=%.2f cancel_on_leave=true hostile=%s defeat_drop=none harvest=%s electrocyte=%d cargo_full_preserved=true failure_restored=true base_weapon=true project=%s capability=%s reload=%s interrupt_phase=%s hostile_health=%d damage=1 held_cargo=%d banked_score=%d oxygen=%.1f daylight=%.1f interaction_oxygen=%.1f->%.1f interaction_daylight=%.1f->%.1f." % [
		PASSIVE_ID,
		int(banked_before_build.get(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID, 0)),
		float(pressure.get("partial_progress", 0.0)),
		HOSTILE_ID,
		HOSTILE_SOURCE_ID,
		int(banked_before_build.get(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID, 0)),
		PROJECT_ID,
		CAPABILITY_ID,
		str(reload_report.get("status", "")),
		str(interrupt.get("phase", "")),
		int(interrupt.get("health", 0)),
		held_cargo,
		journey_banked_score,
		final_oxygen,
		final_daylight,
		float(pressure.get("oxygen_before", 0.0)),
		float(pressure.get("oxygen_after", 0.0)),
		float(pressure.get("daylight_before", 0.0)),
		float(pressure.get("daylight_after", 0.0)),
	])
	get_tree().quit(0)


func _verify_source_contract(passive: Dictionary, harvest: Dictionary, project: Dictionary) -> bool:
	if not _require(
		str(passive.get("id", "")) == PASSIVE_ID
		and str(passive.get("source_role", "")) == "passive_sample"
		and str(passive.get("material_id", "")) == ExpansionProfileState.INSULATING_GEL_MATERIAL_ID
		and is_equal_approx(float(passive.get("interaction_seconds", 0.0)), 1.5),
		"passive biological source contract drifted"
	):
		return false
	if not _require(
		str(harvest.get("id", "")) == HOSTILE_SOURCE_ID
		and str(harvest.get("source_role", "")) == "hostile_harvest"
		and str(harvest.get("hostile_id", "")) == HOSTILE_ID
		and str(harvest.get("material_id", "")) == ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID,
		"hostile harvest source contract drifted"
	):
		return false
	var recipe: Dictionary = project.get("required_materials", {})
	return _require(
		str(project.get("id", "")) == PROJECT_ID
		and str(project.get("required_project_id", "")) == ExpansionProfileState.SHOCK_PROD_PROJECT_ID
		and int(recipe.get(ExpansionProfileState.COIL_MATERIAL_ID, 0)) == 1
		and int(recipe.get(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID, 0)) == 1
		and int(recipe.get(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID, 0)) == 1
		and recipe.size() == 3,
		"capacitor project contract drifted"
	)


func _exercise_passive_sample(profile, passive: Dictionary) -> Dictionary:
	var center: Vector2 = passive.get("center", Vector2.ZERO)
	var hostile_health_before: int = int(_hostile_state().get("health", 0))
	var oxygen_before: float = _oxygen_seconds
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	_player.global_position = center
	_process(0.75)
	var partial: float = float(_main._biological_resources.report().get("progress_seconds", 0.0))
	if not _require(partial > 0.0 and partial < 1.5 and _main._material_runtime.held_count() == 0, "passive sample collected before its timer"):
		return {}
	_player.global_position = center + Vector2(160, 0)
	_process(0.1)
	if not _require(is_zero_approx(float(_main._biological_resources.report().get("progress_seconds", -1.0))), "leaving range did not cancel passive sample progress"):
		return {}
	_player.global_position = center
	_process(1.5)
	if not _require(
		_main._biological_resources.is_collected(PASSIVE_ID)
		and int(_main._material_runtime.held_quantities().get(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID, 0)) == 1,
		"completed passive sample did not enter shared cargo"
	):
		return {}
	if not _require(int(_hostile_state().get("health", 0)) == hostile_health_before, "nonlethal sample changed hostile health"):
		return {}
	var oxygen_after: float = _oxygen_seconds
	var daylight_after: float = _main._expedition_day_state.daylight_remaining_seconds
	if not _require(oxygen_after < oxygen_before and daylight_after < daylight_before, "sampling paused oxygen or daylight"):
		return {}
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(profile.material_quantity(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID) == 1 and _main._material_runtime.held_count() == 0, "boat did not bank passive sample"):
		return {}
	return {
		"partial_progress": partial,
		"oxygen_before": oxygen_before,
		"oxygen_after": oxygen_after,
		"daylight_before": daylight_before,
		"daylight_after": daylight_after,
	}


func _exercise_base_weapon_harvest(profile, harvest: Dictionary) -> bool:
	if not _require(_main._material_project.has_shock_prod() and not _main._material_project.has_shock_prod_capacitor(), "base shock-prod fixture has wrong capability state"):
		return false
	if not _defeat_with_runtime_weapon():
		return false
	if not _require(
		_hostile_phase() == "defeated"
		and profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID) == 0
		and _main._material_runtime.held_count() == 0,
		"eel defeat granted an automatic material"
	):
		return false

	var instant := _instant_salvage_targets()
	if not _require(instant.size() >= 2, "cargo-full fixture needs two instant salvage targets"):
		return false
	for index in range(2):
		_player.global_position = instant[index]["center"]
		_process(0.0)
	if not _require(_held_salvage == _held_salvage_capacity(), "cargo-full fixture did not fill shared capacity"):
		return false
	var harvest_center: Vector2 = _hostile_state().get("position", harvest.get("center", Vector2.ZERO))
	_player.global_position = harvest_center
	_process(float(harvest.get("interaction_seconds", 1.5)))
	if not _require(
		not _main._biological_resources.is_collected(HOSTILE_SOURCE_ID)
		and _main._material_runtime.held_count() == 0
		and _last_status_note.find("Cargo full") != -1,
		"cargo-full harvest depleted or hid the source"
	):
		return false
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	_player.global_position = harvest_center
	_process(float(harvest.get("interaction_seconds", 1.5)))
	if not _require(_main._biological_resources.is_collected(HOSTILE_SOURCE_ID) and _main._material_runtime.held_count() == 1, "explicit post-defeat harvest did not enter cargo"):
		return false

	_main._handle_hazard_hit("expansion_07_smoke_hazard")
	if not _require(
		_main._material_runtime.held_count() == 0
		and not _main._biological_resources.is_collected(HOSTILE_SOURCE_ID)
		and _hostile_phase() == "home",
		"failure did not restore unbanked harvest and hostile"
	):
		return false
	if not _defeat_with_runtime_weapon():
		return false
	harvest_center = _hostile_state().get("position", harvest_center)
	_player.global_position = harvest_center
	_process(float(harvest.get("interaction_seconds", 1.5)))
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	return _require(
		profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID) == 1
		and _main._material_runtime.held_count() == 0,
		"reharvested electrocyte did not bank at the boat"
	)


func _defeat_with_runtime_weapon() -> bool:
	var home: Vector2 = _hostile_state().get("home_center", Vector2.ZERO)
	_player.global_position = home + Vector2(-60, 0)
	_player.swim_in_direction(Vector2.RIGHT, 0.0)
	_process(0.0)
	for expected_health in [2, 1, 0]:
		_player.global_position = (_hostile_state().get("position", home) as Vector2) + Vector2(-60, 0)
		_player.swim_in_direction(Vector2.RIGHT, 0.0)
		if not _require(_main._try_combat_attack(), "base shock prod did not hit eel at health %d" % expected_health):
			return false
		if not _require(int(_hostile_state().get("health", -1)) == expected_health, "base shock prod damage drifted"):
			return false
		if expected_health > 0:
			_process(ShockProdController.ATTACK_COOLDOWN_SECONDS)
	return _require(_hostile_phase() == "defeated", "base shock prod did not defeat eel")


func _build_and_reload_capacitor(profile) -> bool:
	if not _require(
		profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 1
		and profile.material_quantity(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID) == 1
		and profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID) == 1,
		"capacitor recipe was not banked exactly"
	):
		return false
	_player.global_position = _world.get_extraction_center()
	if not _require(_main._expedition_day_state.request_end_day("voluntary"), "could not request capacitor debrief"):
		return false
	_process(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF and _main._material_project.status() == "ready", "capacitor was not ready in debrief"):
		return false
	_press_key(KEY_P)
	if not _require(profile.has_completed_project(PROJECT_ID) and profile.has_capability(CAPABILITY_ID), "debrief did not complete capacitor transaction"):
		return false
	if not _require(_main._result_label.text.find("Shock-prod capacitor built") != -1 and _main._result_label.text.find("force RECOVERY") != -1 and _main._result_label.text.find("damage stays 1") != -1, "debrief did not explain the capacitor build effect"):
		return false
	if not _require(profile.material_inventory().is_empty(), "capacitor transaction did not spend exact recipe"):
		return false
	var repeat: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	return _require(repeat.get("reason") == "already_completed", "capacitor transaction was not exact-once")


func _exercise_capacitor_interrupt() -> Dictionary:
	if not _require(_main._material_project.has_shock_prod_capacitor(), "reloaded runtime omitted capacitor capability"):
		return {}
	var home: Vector2 = _hostile_state().get("home_center", Vector2.ZERO)
	_player.global_position = home + Vector2(-60, 0)
	_player.swim_in_direction(Vector2.RIGHT, 0.0)
	_process(0.0)
	if not _require(_hostile_phase() == "warning", "capacitor fixture did not enter warning"):
		return {}
	if not _require(_main._try_combat_attack(), "capacitor attack did not hit"):
		return {}
	var state := _hostile_state()
	if not _require(
		state.get("phase") == "recovery"
		and int(state.get("health", 0)) == 2
		and _last_status_note.begins_with("Shock prod capacitor hit")
		and _last_status_note.find("recovery") != -1,
		"capacitor did not interrupt warning with unchanged one-hit damage"
	):
		return {}
	return {"phase": state.get("phase", ""), "health": state.get("health", 0)}


func _seed_base_shock_prod(profile) -> bool:
	if not _require(bool(SmokeProfileProjectFixture.complete_scanner(profile, _world).get("changed", false)), "could not seed scanner"):
		return false
	if not _require(bool(profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false).get("changed", false)), "could not seed anomaly knowledge"):
		return false
	if not _require(_prepare_propulsion_fins(), "could not seed recipe-built fins prerequisite"):
		return false
	for project_id in [
		ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID,
		ExpansionProfileState.SHOCK_PROD_PROJECT_ID,
	]:
		if not _require(bool(profile.deposit_materials(STANDARD_RECIPE, false).get("changed", false)), "could not seed recipe for %s" % project_id):
			return false
		if not _require(bool(profile.complete_material_project(_project_by_id(project_id), false).get("changed", false)), "could not seed prerequisite %s" % project_id):
			return false
	if not _require(bool(profile.deposit_materials({ExpansionProfileState.COIL_MATERIAL_ID: 1}, false).get("changed", false)), "could not seed capacitor coil"):
		return false
	if not _require(profile.save_profile(), "could not persist base shock-prod fixture"):
		return false
	_attach_profile(profile, true)
	return _require(_main._material_project.has_shock_prod() and not _main._material_project.has_shock_prod_capacitor(), "base shock-prod fixture did not load")


func _attach_profile(profile, current_world_loaded: bool) -> void:
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, profile)
	_main._material_runtime = MaterialRuntimeController.new(profile)
	_main._material_project = MaterialProjectRuntime.new(profile)
	_main._cutter_salvage = CutterSalvageController.new(profile)
	_main._biological_resources = BiologicalResourceController.new(profile)
	if current_world_loaded:
		_main._anomaly_survey.on_map_loaded(_world)
		_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state)
		_main._material_project.on_map_loaded(_world)
		_main._cutter_salvage.on_map_loaded(_world)
		_main._biological_resources.on_map_loaded(_world, false)


func _biological_source(source_id: String) -> Dictionary:
	for source in _world.get_biological_resource_sources():
		if str(source.get("id", "")) == source_id:
			return source
	return {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _instant_salvage_targets() -> Array:
	var values: Array = []
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			values.append(salvage)
	return values


func _hostile_state() -> Dictionary:
	return _main._hostiles.state_for(HOSTILE_ID)


func _hostile_phase() -> String:
	return str(_hostile_state().get("phase", "missing"))


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	_main._unhandled_input(event)


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = true


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_cleanup_profile()
	push_error("Expansion 07 biological-progression smoke failed: %s." % message)
	get_tree().quit(1)
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
