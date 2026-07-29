extends "res://scripts/main/smoke/smoke_expansion_14_archive_current_return_checks.gd"

const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const RegionalJourneyPresentation16 := preload("res://scripts/main/regional_journey_presentation.gd")
const SessionProgression16 := preload("res://scripts/main/session_progression.gd")

const ROUTE_ID_16 := "far_west_deeper_wreck_route"
const ZONE_ID_16 := "far_west_confined_wreck_oxygen_zone"
const WARNING_ZONE_ID_16 := "far_west_confined_wreck_warning"
const RECORDER_ID_16 := "far_west_wreck_data_recorder"
const SURVEY_ID_16 := "far_west_deeper_wreck_survey"
const DISCOVERY_ID_16 := "far_west_deeper_wreck_discovery"
const RETURN_RESERVE_SECONDS := 12.0
const PASSABLE_CAPABILITIES_16 := [
	ProfileState.PROPULSION_FINS_CAPABILITY_ID,
	ProfileState.CURRENT_STABILIZER_CAPABILITY_ID,
]

var _protected_demand := 0.0
var _unprotected_demand := 0.0
var _scout_demand := 0.0
var _planned_margin := 0.0
var _optional_shortfall := 0.0
var _scout_minimum_oxygen := 0.0
var _actual_minimum_oxygen := 0.0
var _zone_multiplier := 1.0
var _actual_distance := 0.0
var _boat_result_16 := ""
var _route_guidance := ""


func _smoke_expansion_16_deeper_wreck_and_quit() -> void:
	if not _prepare_checkpoint():
		return
	var route := _route_contract()
	if route.is_empty():
		return
	if not await _prove_unprotected_scout(route):
		return
	if not _build_rebreather():
		return
	if not await _complete_protected_journey(route):
		return
	if not _verify_reload_and_exact_once():
		return

	var profile = _main._anomaly_survey.profile_state()
	var profile_report: Dictionary = profile.report()
	cleanup_profile_storage()
	print("Expansion 16 deeper-wreck smoke passed: route=%s zone=%s multiplier=%.1f base=%.1f optional=%.1f protected=%.1f planned_margin=%.1f unprotected=%.1f optional_shortfall=%.1f scout=%.1f scout_min=%.1f project=%s recipe=Ti1+Rubber1+Coil1+Gel1 capability=%s capability_count=%d night_only=true exact_once=true recorder=%s cutter=explicit survey=%s scanner=held pending=true discovery=%s discovery_count=%d actual_distance=%.1fpx actual_min=%.1f boat=surface_boat_entry result=\"%s\"." % [
		ROUTE_ID_16,
		ZONE_ID_16,
		_zone_multiplier,
		_main.OXYGEN_MAX_SECONDS,
		_main.OXYGEN_MAX_SECONDS + SessionProgression16.OXYGEN_TANK_UPGRADE_SECONDS,
		_protected_demand,
		_planned_margin,
		_unprotected_demand,
		_optional_shortfall,
		_scout_demand,
		_scout_minimum_oxygen,
		ProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID,
		ProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID,
		profile_report.get("unlocked_capabilities", []).count(ProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID),
		RECORDER_ID_16,
		SURVEY_ID_16,
		DISCOVERY_ID_16,
		profile_report.get("completed_discoveries", []).count(DISCOVERY_ID_16),
		_actual_distance,
		_actual_minimum_oxygen,
		_boat_result_16.replace("\n", " | "),
	])
	get_tree().quit(0)


func _prepare_checkpoint() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var presentation := RegionalJourneyPresentation16.new()
	var empty_profile := ProfileState.new("", false)
	var hidden_before_prerequisite: String = presentation.promise_text(_world, empty_profile)
	presentation.sync_route_guidance(_world, empty_profile)
	var markers_hidden_before_prerequisite: bool = not _world.is_route_guidance_visible(ROUTE_ID_16)
	var applied: Dictionary = ReviewCheckpointFixture.apply(
		ReviewCheckpointFixture.EXPANSION_16_START,
		profile
	)
	_main._material_project.on_map_loaded(_world)
	_main._cutter_salvage.on_map_loaded(_world)
	_main._anomaly_survey.on_map_loaded(_world)
	_main._oxygen_consumption_zone.on_map_loaded(_world)
	_main._refresh_active_tools()
	var collision := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not _require(collision != null and collision.shape is RectangleShape2D, "player collision is unavailable"):
		return false
	_body_size = (collision.shape as RectangleShape2D).size
	_starting_health = int(_main._player_health.current_health)
	_prepare_controlled_movement()
	_minimum_oxygen = _oxygen_seconds
	_route_guidance = presentation.promise_text(_world, profile)
	presentation.sync_route_guidance(_world, profile)
	return _require(
		bool(applied.get("ready", false))
		and _world.map_id == MAP_ID
		and _world.is_inside_boat(_player.global_position)
		and profile.has_completed_discovery(ProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID)
		and profile.has_capability(ProfileState.CURRENT_STABILIZER_CAPABILITY_ID)
		and not profile.has_capability(ProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID)
		and _main._material_project.status_for(ProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID) == "ready",
		"Expansion 16 checkpoint boundary drifted: %s" % applied
	) and _require(
		hidden_before_prerequisite.is_empty()
		and markers_hidden_before_prerequisite
		and _route_guidance == "Far-west wreck | Follow cyan relay beacons west",
		"Expansion 16 route guidance was mistimed: before=%s after=%s" % [
			hidden_before_prerequisite,
			_route_guidance,
		]
	)


func _route_contract() -> Dictionary:
	var recorder := _tool_target_by_id(RECORDER_ID_16)
	var survey := _survey_by_id(SURVEY_ID_16)
	var zone: Dictionary = _world.get_marker_zone(ZONE_ID_16)
	var warning: Dictionary = _world.get_marker_zone(WARNING_ZONE_ID_16)
	if not _require(not recorder.is_empty() and not survey.is_empty() and not zone.is_empty() and not warning.is_empty(), "deeper-wreck route records are missing"):
		return {}
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES_16, RECORDER_ID_16)
	var boat: Vector2 = _world.get_entry_position(BOAT_ENTRY_ID)
	var outbound: PackedVector2Array = navigation.path_between(boat, survey.get("center", Vector2.ZERO))
	var return_path: PackedVector2Array = navigation.path_between(survey.get("center", Vector2.ZERO), boat)
	if not _require(outbound.size() > 1 and return_path.size() > 1, "deeper wreck lacks a collision-clear continuous return"):
		return {}
	var zone_rect := _source_rect(zone)
	var speed := maxf(1.0, float(_player.swim_speed))
	var outbound_exposure := _path_exposure(outbound, zone_rect, speed)
	var return_exposure := _path_exposure(return_path, zone_rect, speed)
	var entry_distance := float(outbound_exposure.get("distance_to_entry", INF))
	var grace := float(zone.get("warning_grace_seconds", 0.0))
	_zone_multiplier = float(zone.get("unprotected_oxygen_drain_multiplier", 1.0))
	var critical := maxf(0.0, float(outbound_exposure["seconds"]) - grace) + maxf(0.0, float(return_exposure["seconds"]) - grace)
	var normal_round_trip := (navigation.path_distance(outbound) + navigation.path_distance(return_path)) / speed
	_protected_demand = normal_round_trip + float(recorder.get("interaction_seconds", 0.0)) + float(survey.get("interaction_seconds", 0.0))
	_unprotected_demand = _protected_demand + critical * (_zone_multiplier - 1.0)
	_scout_demand = entry_distance * 2.0 / speed + minf(grace, float(outbound_exposure["seconds"]))
	var base := float(_main.OXYGEN_MAX_SECONDS)
	var optional := base + SessionProgression16.OXYGEN_TANK_UPGRADE_SECONDS
	_planned_margin = base - _protected_demand
	_optional_shortfall = _unprotected_demand + RETURN_RESERVE_SECONDS - optional
	var probe := _zone_probe_point(outbound, zone_rect)
	return {
		"navigation": navigation,
		"recorder": recorder,
		"survey": survey,
		"probe": probe,
		"warning": warning,
	} if _require(
		probe != Vector2.INF
		and _protected_demand + RETURN_RESERVE_SECONDS <= base + 0.01
		and _unprotected_demand + RETURN_RESERVE_SECONDS > optional
		and _scout_demand + RETURN_RESERVE_SECONDS <= base + 0.01,
		"route inequalities drifted: protected=%.1f unprotected=%.1f scout=%.1f" % [_protected_demand, _unprotected_demand, _scout_demand]
	) else {}


func _prove_unprotected_scout(route: Dictionary) -> bool:
	var navigation = route["navigation"]
	var probe: Vector2 = route["probe"]
	_minimum_oxygen = _oxygen_seconds
	var warning: Dictionary = route["warning"]
	if not await _drive_to("expansion_16_approach_warning", _source_rect(warning).get_center(), navigation):
		return false
	var warning_report: Dictionary = _main._oxygen_consumption_zone.report()
	if not _require(
		bool(warning_report.get("near_threshold", false))
		and not bool(warning_report.get("inside", true))
		and is_equal_approx(float(warning_report.get("drain_multiplier", 0.0)), 1.0)
		and str(warning_report.get("note", "")).find("Oxygen x8") != -1,
		"approach did not warn before accelerated oxygen began"
	):
		return false
	if not await _drive_to("expansion_16_unprotected_scout", probe, navigation):
		return false
	var grace := float(_world.get_marker_zone(ZONE_ID_16).get("warning_grace_seconds", 0.0))
	_advance(grace + 0.25)
	var zone_report: Dictionary = _main._oxygen_consumption_zone.report()
	if not _require(
		bool(zone_report.get("inside", false))
		and not bool(zone_report.get("protected", true))
		and float(zone_report.get("drain_multiplier", 1.0)) > 1.0,
		"pre-rebreather entry did not apply accelerated oxygen drain"
	):
		return false
	if not await _return_to_boat("expansion_16_scout_retreat", navigation):
		return false
	_scout_minimum_oxygen = _minimum_oxygen
	return _require(
		_scout_minimum_oxygen >= RETURN_RESERVE_SECONDS
		and not _run_failed,
		"oxygen threshold could not be scouted and retreated from"
	)


func _build_rebreather() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var recipe_before: Dictionary = profile.material_inventory()
	var wrong_phase: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_ACTIVE)
	var recipe_after_wrong_phase: Dictionary = profile.material_inventory()
	var built: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	var repeated: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	var warning: Dictionary = _world.get_marker_zone(WARNING_ZONE_ID_16)
	_main._oxygen_consumption_zone.reset()
	var threshold_report: Dictionary = _main._oxygen_consumption_zone.update(
		_source_rect(warning).get_center(),
		Callable(profile, "has_capability"),
		0.0
	)
	return _require(
		wrong_phase.get("reason") == "wrong_phase"
		and recipe_after_wrong_phase == recipe_before
		and profile.material_inventory().is_empty()
		and bool(built.get("changed", false))
		and repeated.get("reason") == "already_completed"
		and profile.has_completed_project(ProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID)
		and profile.has_capability(ProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID)
		and profile.report().get("completed_projects", []).count(ProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID) == 1,
		"night project did not consume the exact recipe and grant one durable rebreather"
	) and _require(
		bool(threshold_report.get("near_threshold", false))
		and bool(threshold_report.get("protected", false))
		and str(threshold_report.get("note", "")).begins_with("Rebreather ready"),
		"protected threshold did not confirm the rebreather"
	)


func _complete_protected_journey(route: Dictionary) -> bool:
	var navigation = route["navigation"]
	var recorder: Dictionary = route["recorder"]
	var survey: Dictionary = route["survey"]
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_player.reset_motion()
	_oxygen_seconds = _oxygen_capacity_seconds()
	_minimum_oxygen = _oxygen_seconds
	_main._oxygen_consumption_zone.reset()
	var distance_start := _distance_px
	if not _require(_select_active_tool_for_smoke(ProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "protected journey could not select cutter"):
		return false
	if not await _drive_to("expansion_16_protected_outbound", recorder.get("center", Vector2.ZERO), navigation):
		return false
	_advance(0.0)
	var protected_report: Dictionary = _main._oxygen_consumption_zone.report()
	if not _require(bool(protected_report.get("protected", false)) and is_equal_approx(float(protected_report.get("drain_multiplier", 0.0)), 1.0), "rebreather did not normalize the authored zone"):
		return false
	_use_active_tool_for_smoke()
	_advance(float(recorder.get("interaction_seconds", 0.0)))
	if not _require(_main._sortie_state.held_salvage_ids == [RECORDER_ID_16], "explicit cutter did not secure the far-west recorder"):
		return false
	var pose: Dictionary = ScannerSmokePose.new().find_pose(_world, survey)
	if not _require(bool(pose.get("found", false)), "deeper-wreck survey has no scanner pose"):
		return false
	if not await _drive_to("expansion_16_recorder_to_survey", pose.get("origin", Vector2.ZERO), navigation):
		return false
	if not _require(_select_active_tool_for_smoke(ProfileState.SURVEY_SCANNER_CAPABILITY_ID) and _place_for_scan(survey), "protected journey could not select scanner"):
		return false
	_use_active_tool_for_smoke()
	_advance(float(survey.get("interaction_seconds", 0.0)))
	if not _require(_main._anomaly_survey.has_pending_discovery() and not _main._anomaly_survey.profile_state().has_completed_discovery(DISCOVERY_ID_16), "wreck finding did not remain pending in the cave"):
		return false
	if not await _return_to_boat("expansion_16_protected_return", navigation):
		return false
	_actual_distance = _distance_px - distance_start
	_actual_minimum_oxygen = _minimum_oxygen
	_boat_result_16 = _main._anomaly_survey.result_text()
	var profile = _main._anomaly_survey.profile_state()
	var presentation := RegionalJourneyPresentation16.new()
	var guidance_after_finding: String = presentation.promise_text(_world, profile)
	presentation.sync_route_guidance(_world, profile)
	return _require(
		_actual_minimum_oxygen > 0.0
		and profile.has_banked_tool_target(RECORDER_ID_16)
		and profile.has_completed_discovery(DISCOVERY_ID_16)
		and not _main._anomaly_survey.has_pending_discovery()
		and _boat_result_16 == "%s\n%s" % [survey.get("finding_label", ""), survey.get("next_lead_label", "")]
		and guidance_after_finding.is_empty()
		and _world.is_route_guidance_visible(ROUTE_ID_16),
		"protected operation did not return and commit at the canonical boat"
	)


func _verify_reload_and_exact_once() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	_advance(0.0)
	var reloaded := ProfileState.new(PROFILE_PATH, true)
	var load: Dictionary = reloaded.load_profile()
	return _require(
		profile.report().get("completed_discoveries", []).count(DISCOVERY_ID_16) == 1
		and profile.report().get("banked_tool_target_ids", []).count(RECORDER_ID_16) == 1
		and load.get("status") in ["loaded", "migrated_wreck_navigation"]
		and reloaded.has_capability(ProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID)
		and reloaded.has_banked_tool_target(RECORDER_ID_16)
		and reloaded.has_completed_discovery(DISCOVERY_ID_16),
		"reload or repeat boat update lost or duplicated Expansion 16 state"
	)


func _path_exposure(path: PackedVector2Array, rect: Rect2, speed: float) -> Dictionary:
	var exposure := 0.0
	var distance_to_entry := INF
	var distance := 0.0
	for index in range(1, path.size()):
		var start := path[index - 1]
		var end := path[index]
		var segment := start.distance_to(end)
		if rect.has_point(start.lerp(end, 0.5)):
			if is_inf(distance_to_entry):
				distance_to_entry = distance
			exposure += segment / speed
		distance += segment
	return {"seconds": exposure, "distance_to_entry": distance_to_entry}


func _zone_probe_point(path: PackedVector2Array, rect: Rect2) -> Vector2:
	var inner := rect.grow(-16.0)
	for point in path:
		if inner.has_point(point):
			return point
	return Vector2.INF


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	cleanup_profile_storage()
	push_error("Expansion 16 deeper-wreck smoke failed: %s." % message)
	get_tree().quit(1)
	return false
