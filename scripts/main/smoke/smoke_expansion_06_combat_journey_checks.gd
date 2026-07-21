extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const SmokeProfileProjectFixture := preload("res://scripts/main/smoke/smoke_profile_project_fixture.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")
const Expansion06GuardChecks := preload("res://scripts/main/smoke/smoke_expansion_06_guard_checks.gd")

const TEST_PROFILE_PATH := "user://oceangame2_expansion_06_combat_smoke.json"
const MAP_ID := "production_slice_01"
const HOSTILE_ID := ExpansionProfileState.SHOCK_PROD_TARGET_ID
const GUARDED_CACHE_ID := "salvage_deep_right_cache"
const PROJECT_ID := ExpansionProfileState.SHOCK_PROD_PROJECT_ID
const CAPABILITY_ID := ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID
const RECIPE := {
	ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
	ExpansionProfileState.COIL_MATERIAL_ID: 1,
}


func _smoke_expansion_06_combat_foundation_and_quit() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	_attach_profile(profile, false)
	_main._load_playable_map(_main.PRODUCTION_SLICE_MAP_PATH, false)
	_prepare_current_map()
	if not _require(_world.map_id == MAP_ID, "loaded unexpected map %s" % _world.map_id):
		return

	var encounter: Dictionary = _encounter_source()
	var project: Dictionary = _project_by_id(PROJECT_ID)
	var guard_checks := Expansion06GuardChecks.new(self, HOSTILE_ID, GUARDED_CACHE_ID, RECIPE)
	if not guard_checks.verify_source_contract(encounter, project):
		return
	if not guard_checks.verify_behavioral_cache_guard():
		return
	var home: Vector2 = encounter.get("home_center", Vector2.ZERO)
	_player.global_position = home + Vector2(-60, 0)
	_player.swim_in_direction(Vector2.RIGHT, 0.0)
	if not _require(not _main._try_combat_attack(), "locked weapon attack changed runtime state"):
		return
	if not _require(
		_hostile_state().get("health") == 3
		and _last_status_note.find("recover propulsion fins blueprint first") != -1
		and _last_status_note.find("Ti 0/2") == -1,
		"locked weapon feedback did not expose the blueprint-first action: %s" % _last_status_note
	):
		return

	var unarmed: Dictionary = _exercise_unarmed_encounter(encounter)
	if unarmed.is_empty():
		return
	_reset_run()
	_prepare_current_map()
	if not _seed_prerequisites_and_recipe(profile):
		return
	var wrong_phase: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_ACTIVE)
	if not _require(wrong_phase.get("reason") == "wrong_phase", "shock prod built outside debrief"):
		return
	_player.global_position = _world.get_extraction_center()
	if not _require(_main._expedition_day_state.request_end_day("voluntary"), "could not request project debrief"):
		return
	_process(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "project build did not enter debrief"):
		return
	_press_key(KEY_P)
	if not _require(profile.has_completed_project(PROJECT_ID) and profile.has_capability(CAPABILITY_ID), "debrief did not complete the shock prod transaction"):
		return
	if not _require(_main._result_label.text.find("Shock prod built") != -1 and _main._result_label.text.find("Tab select Shock prod") != -1 and _main._result_label.text.find("Q at short range") != -1 and _main._result_label.text.find("1 health damage") != -1, "debrief did not explain what P built or how the shock prod works"):
		return
	if not _require(profile.material_inventory().is_empty(), "shock prod transaction did not spend the exact recipe"):
		return
	var repeat: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	if not _require(repeat.get("reason") == "already_completed", "repeat shock prod build was not exact-once"):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(
		reload_report.get("status") == "loaded"
		and reloaded.has_completed_discovery(ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID)
		and reloaded.has_completed_project(PROJECT_ID)
		and reloaded.has_capability(CAPABILITY_ID),
		"profile reload lost the migrated cutter knowledge or shock prod"
	):
		return
	_press_key(KEY_N)
	_prepare_current_map()
	_attach_profile(reloaded, true)
	_update_status_label()
	if not _require(_status_text().find("Shock prod owned | select active tool") != -1, "armed next day did not distinguish owned from selected Shock Prod"):
		return
	if not guard_checks.verify_behavioral_cache_guard():
		return

	var fight: Dictionary = _exercise_armed_fight(reloaded)
	if fight.is_empty():
		return
	if not _exercise_defeat_and_restoration(reloaded):
		return

	var final_day: int = int(_main._expedition_day_state.day_number)
	var final_health: Dictionary = _main._player_health.report()
	var final_oxygen: float = _oxygen_seconds
	_cleanup_profile()
	print("Expansion 06 combat-foundation smoke passed: encounter=%s capability=%s territory=%s warning=%.2f lunge=%.2f recovery=%.2f unarmed_retreat=true guarded_cache_attemptable=true active_eel_interrupts=true hard_collection_lock=false contact_health=%d knockback=325 disruption=0.45 cooldown_blocked=true oxygen=%.1f->%.1f daylight_advanced=true project=%s guidance=actionable debrief_effect=explicit recipe=Ti2+Coil1 non_enemy_materials=true reload=%s armed_hits=3 hostile=%s guarded_cache_banked=true cargo_held=%d banked_score=%d rewards=salvage_only defeat_input_locked=true retry_restored=true combat_cleanup=true reset_health=%d day=%d final_oxygen=%.1f profile=durable." % [
		HOSTILE_ID,
		CAPABILITY_ID,
		str(encounter.get("territory_rect", Rect2())),
		float(encounter.get("warning_seconds", 0.0)),
		float(encounter.get("lunge_seconds", 0.0)),
		float(encounter.get("recovery_seconds", 0.0)),
		int(unarmed.get("contact_health", 0)),
		float(unarmed.get("oxygen_before", 0.0)),
		float(unarmed.get("oxygen_after", 0.0)),
		PROJECT_ID,
		str(reload_report.get("status", "")),
		str(fight.get("hostile_phase", "")),
		int(fight.get("held_after_fight", 0)),
		int(fight.get("banked_score", 0)),
		int(final_health.get("current_health", 0)),
		final_day,
		final_oxygen,
	])
	get_tree().quit(0)


func _exercise_unarmed_encounter(encounter: Dictionary) -> Dictionary:
	var home: Vector2 = encounter.get("home_center", Vector2.ZERO)
	var approach: Vector2 = home + Vector2(0, -96)
	var evade_lane: Vector2 = Vector2(60.5, 78.5) * float(_world.tile_size)
	var oxygen_before: float = _oxygen_seconds
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	_player.global_position = approach
	_process(0.0)
	if not _require(_hostile_phase() == "warning", "unarmed approach did not start the warning"):
		return {}
	_player.global_position = evade_lane
	_process(0.1)
	if not _require(_hostile_phase() == "returning" and _main._player_health.current_health == 3, "unarmed retreat did not survive cleanly"):
		return {}

	_main._hostiles.reset_for_failure(_world)
	_player.global_position = approach
	_process(0.0)
	_process(float(encounter.get("warning_seconds", 0.75)) + 0.01)
	if not _require(_hostile_phase() == "lunge", "warning timing did not enter lunge"):
		return {}
	_player.global_position = evade_lane
	_process(float(encounter.get("lunge_seconds", 0.45)) + 0.01)
	if not _require(_hostile_phase() == "recovery" and _main._player_health.current_health == 3, "evaded lunge did not enter recovery"):
		return {}
	_process(float(encounter.get("recovery_seconds", 1.25)) + 0.01)
	if not _require(_hostile_phase() == "returning", "recovery timing did not enter return"):
		return {}
	_process(1.0)
	if not _require(_hostile_phase() == "home", "hostile did not return home"):
		return {}

	_main._hostiles.reset_for_failure(_world)
	_main._player_health.reset()
	var contact_position: Vector2 = home + Vector2(0, -40)
	_player.global_position = contact_position
	_process(0.0)
	_process(float(encounter.get("warning_seconds", 0.75)) + 0.01)
	_player.global_position = contact_position + Vector2(-8, 0)
	_process(0.22)
	if not _require(_main._player_health.current_health == 2, "source lunge contact did not apply one health damage"):
		return {}
	var away_direction: Vector2 = _player.global_position - (_hostile_state().get("position", _player.global_position) as Vector2)
	if not _require(_player.velocity.length() > _player.swim_speed and _player.velocity.normalized().dot(away_direction.normalized()) > 0.99 and is_equal_approx(_player.movement_disruption_seconds(), 0.45), "source lunge contact did not knock the player away and disrupt steering"):
		return {}
	if not _require(_last_status_note.find("health 2/3 (-1)") != -1 and _last_status_note.find("knocked back") != -1, "contact feedback did not explain health loss and knockback"):
		return {}
	var oxygen_after_contact: float = _oxygen_seconds
	var blocked: Dictionary = _main._apply_combat_damage(1, HOSTILE_ID)
	if not _require(blocked.get("reason") == "invulnerable" and _main._player_health.current_health == 2 and is_equal_approx(_oxygen_seconds, oxygen_after_contact), "damage cooldown or health/oxygen separation drifted"):
		return {}
	if not _require(_oxygen_seconds < oxygen_before and _main._expedition_day_state.daylight_remaining_seconds < daylight_before, "unarmed encounter paused oxygen or daylight"):
		return {}
	return {"contact_health": 2, "oxygen_before": oxygen_before, "oxygen_after": _oxygen_seconds}


func _seed_prerequisites_and_recipe(profile) -> bool:
	if not _require(bool(profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false).get("changed", false)), "could not seed project discovery"):
		return false
	if not _require(_prepare_profile_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID), "could not seed recipe-built propulsion fins"):
		return false
	var scanner: Dictionary = SmokeProfileProjectFixture.complete_scanner(profile, _world, false)
	if not _require(bool(scanner.get("changed", false)) or scanner.get("reason") == "already_completed", "could not seed recipe-built scanner"):
		return false
	var first_project_guidance: String = _main._material_project.shock_prod_guidance()
	if not _require(first_project_guidance.find("next Cutter project") != -1 and first_project_guidance.find("Ti 0/2") != -1 and first_project_guidance.find("bank at boat, then P at night") != -1, "locked guidance did not expose the current project, exact materials, and debrief action"):
		return false
	for project_id in [ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID]:
		if not _require(bool(profile.deposit_materials(RECIPE, false).get("changed", false)), "could not seed non-enemy recipe for %s" % project_id):
			return false
		var completed: Dictionary = profile.complete_material_project(_project_by_id(project_id), false)
		if not _require(bool(completed.get("changed", false)), "could not seed prerequisite %s: %s" % [project_id, str(completed)]):
			return false
	if not _require(bool(profile.deposit_materials(RECIPE, false).get("changed", false)), "could not seed shock prod recipe"):
		return false
	if not _require(_main._material_project.shock_prod_guidance().find("Shock prod project ready") != -1 and _main._material_project.shock_prod_guidance().find("press P") != -1, "ready project guidance omitted the exact next build action"):
		return false
	if not _require(profile.save_profile(), "could not persist pre-build profile fixture"):
		return false
	_main._material_project.on_map_loaded(_world)
	_main._material_project.shock_prod_guidance()
	return _require(_main._material_project.status() == "ready", "shock prod project did not become ready")


func _exercise_armed_fight(profile) -> Dictionary:
	if not _require(_select_active_tool(CAPABILITY_ID), "could not select the built shock prod"):
		return {}
	var instant: Array = _instant_salvage_targets()
	if not _require(instant.size() >= 2, "armed fight needs two instant salvage fixtures"):
		return {}
	_player.global_position = instant[0]["center"]
	_process(0.0)
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var banked_before: int = _banked_score
	_player.global_position = instant[1]["center"]
	_process(0.0)
	var held_before: Array[String] = _held_salvage_ids.duplicate()
	var wallet_before: int = _session_wallet()
	var profile_before: Dictionary = profile.report()
	var oxygen_before: float = _oxygen_seconds
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds

	var home: Vector2 = _encounter_source().get("home_center", Vector2.ZERO)
	_player.global_position = home + Vector2(-60, 0)
	_player.swim_in_direction(Vector2.RIGHT, 0.0)
	var health_before_legacy_action := int(_hostile_state().get("health", -1))
	_press_legacy_attack()
	if not _require(int(_hostile_state().get("health", -1)) == health_before_legacy_action, "legacy combat action still bypassed active-tool use"):
		return {}
	for expected_health in [2, 1, 0]:
		_press_attack()
		if not _require(int(_hostile_state().get("health", -1)) == expected_health, "shock prod hit did not apply one damage"):
			return {}
		if expected_health > 0:
			_process(ShockProdController.ATTACK_COOLDOWN_SECONDS)
	if not _require(_hostile_phase() == "defeated" and _main._player_health.current_health == 3, "armed fight did not end in a clean three-hit victory"):
		return {}
	if not _require(_held_salvage_ids == held_before and _banked_score == banked_before and _session_wallet() == wallet_before, "hostile defeat changed cargo, banking, or wallet"):
		return {}
	if not _require(profile.material_inventory().is_empty() and profile.report().get("completed_discoveries") == profile_before.get("completed_discoveries") and profile.report().get("completed_projects") == profile_before.get("completed_projects"), "hostile defeat created materials or profile rewards"):
		return {}
	if not _require(_oxygen_seconds < oxygen_before and _main._expedition_day_state.daylight_remaining_seconds < daylight_before, "armed fight paused oxygen or daylight"):
		return {}
	var guarded_cache := _salvage_by_id(GUARDED_CACHE_ID)
	_player.global_position = guarded_cache["center"]
	if not _require(_collect_salvage_for_smoke(guarded_cache) and _held_salvage_ids.has(GUARDED_CACHE_ID), "defeated eel did not release the guarded cache"):
		return {}
	var held_after_guard: int = _held_salvage

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var banked_after: int = _banked_score
	if not _require(_held_salvage == 0 and _banked_salvage_ids.has(GUARDED_CACHE_ID) and banked_after > banked_before and _hostile_phase() == "defeated", "guarded cache did not use normal banking or changed defeated state"):
		return {}
	_player.global_position = _world.get_extraction_center()
	if not _require(_main._expedition_day_state.request_end_day("voluntary"), "could not request post-fight day end"):
		return {}
	_process(0.0)
	_press_key(KEY_N)
	_prepare_current_map()
	if not _require(_hostile_phase() == "home" and int(_hostile_state().get("health", 0)) == 3, "new day did not restore the hostile"):
		return {}
	return {"hostile_phase": "defeated", "held_after_fight": held_after_guard, "banked_score": banked_after}


func _exercise_defeat_and_restoration(profile) -> bool:
	var instant: Array = _instant_salvage_targets()
	if not _require(instant.size() >= 2, "combat defeat needs two instant salvage fixtures"):
		return false
	_player.global_position = instant[0]["center"]
	_process(0.0)
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	_player.global_position = instant[1]["center"]
	_process(0.0)
	var held_salvage_id: String = str(instant[1].get("id", ""))
	var material: Dictionary = _first_active_material()
	if not _require(not material.is_empty(), "combat defeat needs one active material fixture"):
		return false
	_player.global_position = material["center"]
	_process(0.0)
	if not _require(_held_salvage == 1 and _main._material_runtime.held_count() == 1, "combat defeat cargo fixture did not fill"):
		return false
	var banked_before: int = _banked_score
	var oxygen_before: float = _oxygen_seconds
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	var day_before: int = _main._expedition_day_state.day_number
	var profile_before: Dictionary = profile.report()
	var approach: Vector2 = _encounter_source().get("home_center", Vector2.ZERO) + Vector2(0, -96)
	_player.global_position = approach
	_player.set_physics_process(true)
	_process(0.0)
	if not _require(_hostile_phase() == "warning", "combat defeat fixture did not freeze a warning state"):
		return false
	for hit_index in range(3):
		var damage: Dictionary = _main._apply_combat_damage(1, HOSTILE_ID)
		if not _require(bool(damage.get("changed", false)), "combat defeat hit %d was rejected" % (hit_index + 1)):
			return false
		if hit_index < 2:
			_main._player_health.update(1.01)
	if not _require(_main._sortie_state.failure_reason == "combat_defeat" and _main._player_health.current_health == 0 and _hostile_phase() == "warning", "combat defeat reason, health, or frozen hostile drifted"):
		return false
	var hostile_health_after_defeat: int = int(_hostile_state().get("health", 0))
	_press_attack()
	if not _require(not _player.is_physics_processing() and int(_hostile_state().get("health", 0)) == hostile_health_after_defeat, "combat defeat did not lock movement and combat input until retry"):
		return false
	if not _require(_held_salvage == 0 and _main._material_runtime.held_count() == 0 and not _world.is_salvage_collected(held_salvage_id), "combat defeat did not restore unbanked salvage/material cargo"):
		return false
	if not _require(not _world.get_material_candidate_near(material["center"], SALVAGE_COLLECTION_RADIUS).is_empty(), "combat defeat deleted the held material source"):
		return false
	if not _require(_banked_score == banked_before and is_equal_approx(_oxygen_seconds, oxygen_before) and is_equal_approx(_main._expedition_day_state.daylight_remaining_seconds, daylight_before) and _main._expedition_day_state.day_number == day_before, "combat defeat changed banked, oxygen, daylight, or day state"):
		return false
	if not _require(profile.has_capability(CAPABILITY_ID) and profile.report().get("completed_projects") == profile_before.get("completed_projects"), "combat defeat changed durable profile state"):
		return false

	_press_key(KEY_R)
	if not _require(_player.is_physics_processing(), "R did not restore player movement processing"):
		return false
	_prepare_current_map()
	if not _require(not _run_failed and _main._player_health.current_health == 3 and _hostile_phase() == "home", "combat retry did not restore health and hostile home state"):
		return false
	_defeat_hostile_direct()
	_main._handle_hazard_hit("expansion_06_smoke_hazard")
	if not _require(_hostile_phase() == "home" and profile.has_capability(CAPABILITY_ID), "hazard did not restore hostile or preserve weapon"):
		return false
	_defeat_hostile_direct()
	_main._handle_oxygen_depleted()
	if not _require(_main._sortie_state.failure_reason == "oxygen_failure" and _hostile_phase() == "home" and profile.has_capability(CAPABILITY_ID), "oxygen failure did not restore hostile independently"):
		return false
	_reset_run()
	_prepare_current_map()
	return true


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
	_main._refresh_active_tools()


func _defeat_hostile_direct() -> void:
	for _hit in range(3):
		_main._hostiles.apply_weapon_hit(_world, HOSTILE_ID, 1)


func _press_attack() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = "active_tool_use"
	event.pressed = true
	_main._unhandled_input(event)


func _press_legacy_attack() -> void:
	var event := InputEventAction.new()
	event.action = "combat_attack"
	event.pressed = true
	_main._unhandled_input(event)


func _select_active_tool(tool_id: String) -> bool:
	_main._refresh_active_tools()
	for _index in range(_main.ActiveToolController.ordered_tool_ids().size()):
		if _main._active_tools.selected_tool_id() == tool_id:
			return true
		var event := InputEventAction.new()
		event.action = "active_tool_cycle_next"
		event.pressed = true
		_main._unhandled_input(event)
	return _main._active_tools.selected_tool_id() == tool_id


func _press_key(keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	_main._unhandled_input(event)


func _encounter_source() -> Dictionary:
	for encounter in _world.get_hostile_encounters():
		if str(encounter.get("id", "")) == HOSTILE_ID:
			return encounter
	return {}


func _hostile_state() -> Dictionary:
	return _main._hostiles.state_for(HOSTILE_ID)


func _hostile_phase() -> String:
	return str(_hostile_state().get("phase", "missing"))


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


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _first_active_material() -> Dictionary:
	var active_ids: Array = _world.get_material_candidate_report().get("active_ids", [])
	for candidate in _world.get_material_candidates():
		if active_ids.has(str(candidate.get("id", ""))):
			return candidate
	return {}


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = true


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_cleanup_profile()
	push_error("Expansion 06 combat-foundation smoke failed: %s." % message)
	get_tree().quit(1)
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
