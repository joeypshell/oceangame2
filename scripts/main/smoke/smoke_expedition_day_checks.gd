extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const SmokeProfileProjectFixture := preload("res://scripts/main/smoke/smoke_profile_project_fixture.gd")

const TEST_PROFILE_PATH := "user://oceangame2_expedition_day_smoke.json"
const OUTBOUND_CONNECTOR_ID := "lower_left_loop_connector"
const RETURN_CONNECTOR_ID := "return_to_boat_hub_connector"


func _smoke_expedition_day_and_quit() -> void:
	_cleanup_profile()
	_prepare_profile()
	_prepare_map()
	var initial_daylight: float = _main._expedition_day_state.daylight_remaining_seconds
	if not _require(_main._expedition_day_state.day_number == 1, "day did not start at one"):
		return
	if not _require(is_equal_approx(initial_daylight, _main._expedition_day_state.DEFAULT_DAYLIGHT_SECONDS), "daylight did not start at capacity"):
		return

	var origin_targets := _instant_salvage(_world)
	if not _require(origin_targets.size() >= 2, "origin needs two instant salvage targets"):
		return
	_player.global_position = origin_targets[0]["center"]
	_process(0.0)
	if not _require(_main._expedition_day_state.sortie_count == 1 and _held_salvage == 1, "first sortie did not collect cargo"):
		return

	var surface_center := _surface_center_outside_boat(_world)
	if not _require(surface_center != Vector2.ZERO, "missing open surface outside boat"):
		return
	_oxygen_seconds = 20.0
	_player.global_position = surface_center
	_process(1.0)
	if not _require(is_equal_approx(_oxygen_seconds, 45.0), "open surface oxygen refill mismatch"):
		return
	if not _require(_held_salvage == 1 and _banked_salvage == 0, "open surface banked cargo"):
		return
	var after_surface_daylight: float = _main._expedition_day_state.daylight_remaining_seconds
	if not _require(is_equal_approx(after_surface_daylight, initial_daylight - 1.0), "surface time did not consume shared daylight"):
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _require(_held_salvage == 0 and _main._expedition_day_state.banked_salvage == 1, "boat did not offload first sortie"):
		return
	if not _require(_main._expedition_day_state.phase == _main._expedition_day_state.PHASE_ACTIVE, "boat offload ended day"):
		return

	_main._session_progression.record_banked_salvage(1200)
	if not _prepare_propulsion_fins() or not _prepare_profile_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID):
		return
	if not _transition(OUTBOUND_CONNECTOR_ID, "production_slice_04"):
		return
	if not _require(_main._expedition_day_state.sortie_count == 2, "connector departure did not start second sortie"):
		return
	if not _require(is_equal_approx(_main._expedition_day_state.daylight_remaining_seconds, after_surface_daylight), "outbound connector reset daylight"):
		return
	if not _transition(RETURN_CONNECTOR_ID, "production_slice_01"):
		return
	if not _require(is_equal_approx(_main._expedition_day_state.daylight_remaining_seconds, after_surface_daylight), "return connector reset daylight"):
		return
	_process(0.0)

	origin_targets = _instant_salvage(_world)
	_player.global_position = origin_targets[1]["center"]
	_process(0.0)
	if not _require(_main._expedition_day_state.sortie_count == 3 and _held_salvage == 1, "post-connector sortie did not start"):
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var completed_sorties: int = _main._expedition_day_state.sortie_count
	var completed_banked: int = _main._expedition_day_state.banked_salvage
	var completed_oxygen: float = _oxygen_seconds
	if not _require(completed_banked == 2 and _main._expedition_day_state.phase == _main._expedition_day_state.PHASE_ACTIVE, "second boat offload ended or miscounted day"):
		return

	_main._expedition_day_state.record_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID)
	_main._expedition_day_state.request_end_day("voluntary")
	_process(0.0)
	if not _require(_main._expedition_day_state.phase == _main._expedition_day_state.PHASE_DEBRIEF, "voluntary request did not reach debrief"):
		return
	var voluntary_text := ExpeditionDayDebrief.build_text(_main._expedition_day_state)
	if not _require(voluntary_text.find("Dives %d" % completed_sorties) != -1 and voluntary_text.find("Banked cargo 2") != -1, "voluntary debrief omitted journey totals"):
		return

	ExpeditionDayDebrief.handle_day_key(_main)
	_prepare_map()
	if not _require(_main._expedition_day_state.day_number == 2 and _main._expedition_day_state.sortie_count == 0, "next day did not reset day scope"):
		return
	if not _require(_main._anomaly_survey.has_scanner() and _main._anomaly_survey.has_completed_discovery(), "next day lost profile progression"):
		return

	var failure_target: Dictionary = _instant_salvage(_world)[0]
	_player.global_position = failure_target["center"]
	_process(0.0)
	_main._expedition_day_state.daylight_remaining_seconds = 0.1
	_process(0.2)
	var nightfall_events: int = _main._expedition_day_state.nightfall_event_count
	var forced_transition := str(_main._expedition_day_state.end_reason)
	if not _require(nightfall_events == 1 and forced_transition == "nightfall_forced_recovery", "nightfall did not resolve exactly once"):
		return
	if not _require(_held_salvage == 0 and _main._expedition_day_state.notable_failure_reason == "nightfall_forced_recovery", "nightfall retained unbanked state"):
		return
	if not _require(_world.map_id == "production_slice_01" and _world.is_inside_boat(_player.global_position), "nightfall recovery did not return to boat"):
		return

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	if not _require(reload_report.get("status") == "loaded" and reloaded.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "profile reload lost scanner"):
		return
	if not _require(reloaded.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID), "profile reload lost discovery"):
		return
	ExpeditionDayDebrief.handle_day_key(_main)
	var final_report: Dictionary = _main._expedition_day_state.report()
	_cleanup_profile()
	print("Expedition day smoke passed: day=%d remaining=%.1f sorties=%d oxygen=%.1f held=0 banked=%d discovery=true connector=%s>%s nightfall_events=%d transition=%s next_day=%d profile_reloaded=true." % [
		1,
		after_surface_daylight,
		completed_sorties,
		completed_oxygen,
		completed_banked,
		OUTBOUND_CONNECTOR_ID,
		RETURN_CONNECTOR_ID,
		nightfall_events,
		forced_transition,
		int(final_report.get("day_number", 0)),
	])
	get_tree().quit(0)


func _prepare_profile() -> void:
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	SmokeProfileProjectFixture.complete_scanner(profile, _world, true)
	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, true)
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, true, profile)
	_main._anomaly_survey.on_map_loaded(_world)


func _prepare_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false


func _transition(connector_id: String, expected_map_id: String) -> bool:
	var connector := _connector_by_id(connector_id)
	if not _require(not connector.is_empty(), "missing connector %s" % connector_id):
		return false
	_player.global_position = connector["center"]
	_process(0.0)
	if not _require(_main._try_world_connector_transition(), "connector %s did not transition" % connector_id):
		return false
	_prepare_map()
	return _require(_world.map_id == expected_map_id, "connector %s loaded %s" % [connector_id, _world.map_id])


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _surface_center_outside_boat(world) -> Vector2:
	for center in world.get_open_surface_centers():
		if not world.is_inside_boat(center):
			return center
	return Vector2.ZERO


func _instant_salvage(world) -> Array:
	var targets := []
	for salvage in world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			targets.append(salvage)
	return targets


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_cleanup_profile()
	push_error("Expedition day smoke failed: %s." % message)
	get_tree().quit(1)
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
