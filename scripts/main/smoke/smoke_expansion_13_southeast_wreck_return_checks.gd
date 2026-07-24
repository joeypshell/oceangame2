extends "res://scripts/main/smoke/smoke_expansion_12_pressure_return_checks.gd"

const SessionProgression := preload("res://scripts/main/session_progression.gd")

const ROUTE_ID_13 := "southeast_wreck_archive_route"
const RECORDER_ID := "southeast_wreck_recorder"
const SURVEY_ID_13 := "southeast_wreck_archive_survey"
const DISCOVERY_ID_13 := "southeast_wreck_archive_discovery"
const CAPACITY_CUT_PREFIX := "expansion_13_cut_capacity_"
const CAPACITY_SCAN_ID := "expansion_13_scan_capacity"
const REQUIRED_CAPABILITIES := [
	"propulsion_fins",
	"survey_scanner_1",
	"salvage_cutter",
	"pressure_suit_1",
]

var _planned_route_distance_px := 0.0
var _actual_route_distance_px := 0.0
var _route_demand_seconds := 0.0
var _base_margin_seconds := 0.0
var _upgraded_margin_seconds := 0.0
var _actual_oxygen_margin := 0.0
var _cutter_partial := 0.0
var _survey_partial := 0.0
var _cargo_full_safe := false
var _scanner_full_cargo := false


func _smoke_expansion_13_southeast_wreck_return_and_quit() -> void:
	if not _prepare_prerequisite_fixture():
		return
	if not _verify_pre_recorder_scan_denial():
		return
	if not _verify_failure_restoration():
		return
	if not await _complete_real_wreck_return():
		return
	if not _verify_profile_reload():
		return

	var profile = _main._anomaly_survey.profile_state()
	var recorder := _tool_target_by_id(RECORDER_ID)
	var survey := _survey_by_id(SURVEY_ID_13)
	var result_text: String = _main._anomaly_survey.result_text().replace("\n", " | ")
	cleanup_profile_storage()
	print("Expansion 13 southeast-wreck return smoke passed: route=%s prerequisite=%s capabilities=%s pressure_crossing=true optional_tank_purchased=%s recorder=%s cutter_seconds=%.1f cutter_partial=%.2f cargo_full_safe=%s survey=%s survey_seconds=%.1f survey_partial=%.2f scanner_full_cargo=%s explicit_q=true cancel_on_leave=true failures=hazard+oxygen+combat planned_distance=%.1fpx actual_distance=%.1fpx demand=%.1fs base_margin=%.1fs upgraded_margin=%.1fs actual_oxygen_margin=%.1fs held=%d banked_recorder=%s pending_then_committed=true discovery=%s exact_once=true profile_reload=true result=\"%s\"." % [
		ROUTE_ID_13,
		ABYSSAL_DISCOVERY_ID,
		",".join(PackedStringArray(REQUIRED_CAPABILITIES)),
		str(_has_oxygen_tank_upgrade()).to_lower(),
		str(recorder.get("id", RECORDER_ID)),
		float(recorder.get("interaction_seconds", 0.0)),
		_cutter_partial,
		str(_cargo_full_safe).to_lower(),
		str(survey.get("id", SURVEY_ID_13)),
		float(survey.get("interaction_seconds", 0.0)),
		_survey_partial,
		str(_scanner_full_cargo).to_lower(),
		_planned_route_distance_px,
		_actual_route_distance_px,
		_route_demand_seconds,
		_base_margin_seconds,
		_upgraded_margin_seconds,
		_actual_oxygen_margin,
		int(_main._sortie_state.held_salvage),
		str(profile.has_banked_tool_target(RECORDER_ID)).to_lower(),
		DISCOVERY_ID_13,
		result_text,
	])
	get_tree().quit(0)


func _prepare_prerequisite_fixture() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var initial: Dictionary = profile.report()
	if not _require(
		initial.get("completed_discoveries", []).is_empty()
		and initial.get("unlocked_capabilities", []).is_empty()
		and initial.get("completed_projects", []).is_empty()
		and initial.get("banked_tool_target_ids", []).is_empty(),
		"smoke did not begin from an empty profile"
	):
		return false
	for capability_id in REQUIRED_CAPABILITIES:
		var prepared: Dictionary = ReviewProgressionFixture.complete_capability(_main, capability_id)
		if not _require(bool(prepared.get("ready", false)), "could not prepare prerequisite %s: %s" % [capability_id, str(prepared)]):
			return false
	var prerequisite: Dictionary = profile.complete_discovery(ABYSSAL_DISCOVERY_ID, false)
	if not _require(bool(prerequisite.get("changed", false)), "could not prepare committed abyssal prerequisite"):
		return false

	_main._material_project.on_map_loaded(_world)
	_main._cutter_salvage.on_map_loaded(_world)
	_main._anomaly_survey.on_map_loaded(_world)
	_main._refresh_active_tools()
	_prepare_controlled_movement()
	var collision := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not _require(collision != null and collision.shape is RectangleShape2D and not collision.disabled, "player collision is unavailable"):
		return false
	_body_size = (collision.shape as RectangleShape2D).size
	_starting_health = int(_main._player_health.current_health)
	_minimum_oxygen = _oxygen_seconds
	return _require(
		_world.map_id == MAP_ID
		and _world.is_inside_boat(_player.global_position)
		and profile.has_completed_discovery(ABYSSAL_DISCOVERY_ID)
		and profile.has_capability(PRESSURE_CAPABILITY_ID)
		and profile.has_capability(ProfileState.SALVAGE_CUTTER_CAPABILITY_ID)
		and profile.has_capability(ProfileState.SURVEY_SCANNER_CAPABILITY_ID)
		and not profile.has_banked_tool_target(RECORDER_ID)
		and not profile.has_completed_discovery(DISCOVERY_ID_13)
		and not _has_oxygen_tank_upgrade(),
		"prepared prerequisite state drifted or bought the optional tank"
	)


func _verify_pre_recorder_scan_denial() -> bool:
	var survey := _survey_by_id(SURVEY_ID_13)
	if not _require(not survey.is_empty(), "missing southeast wreck survey"):
		return false
	if not _place_for_scan(survey):
		return false
	var denied: Dictionary = _main._anomaly_survey.scanner_action(_world, _player)
	var interaction: Dictionary = _main._anomaly_survey.report().get("interaction", {})
	var valid := _require(
		denied.get("reason") == "tool_clearance_required"
		and denied.get("note") == "Wreck recorder | Cutter required"
		and is_zero_approx(float(interaction.get("progress", -1.0))),
		"pre-recorder scan was not denied with cutter guidance"
	)
	_place_player(_world.get_entry_position(BOAT_ENTRY_ID))
	_advance(0.0)
	return valid


func _verify_failure_restoration() -> bool:
	if not _require(_select_active_tool_for_smoke(ProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "failure probes could not select the cutter"):
		return false
	for failure_reason in ["hazard", "oxygen", "combat"]:
		var recorder := _tool_target_by_id(RECORDER_ID)
		if not _require(not recorder.is_empty(), "%s probe could not find recorder" % failure_reason):
			return false
		_place_player(recorder.get("center", Vector2.ZERO))
		_use_active_tool_for_smoke()
		_advance(float(recorder.get("interaction_seconds", 0.0)) + 0.1)
		if not _require(
			_world.is_salvage_collected(RECORDER_ID)
			and _main._sortie_state.held_salvage_ids.has(RECORDER_ID)
			and _survey_is_unlocked(),
			"%s probe did not create unbanked recorder clearance" % failure_reason
		):
			return false
		match failure_reason:
			"hazard":
				_main._handle_hazard_hit("expansion_13_smoke")
			"oxygen":
				_oxygen_seconds = 0.0
				_main._handle_oxygen_depleted()
			"combat":
				_main._handle_combat_defeat("expansion_13_smoke")
		var expected_failure_state: bool = (
			(not _run_failed and failure_reason == "hazard")
			or (_run_failed and _main._sortie_state.failure_reason == "oxygen_failure" and failure_reason == "oxygen")
			or (_run_failed and _main._sortie_state.failure_reason == "combat_defeat" and failure_reason == "combat")
		)
		if not _require(expected_failure_state, "%s handler entered the wrong failure state" % failure_reason):
			return false
		if not _require(_failure_restored_recorder(recorder), "%s failure retained unbanked wreck state" % failure_reason):
			return false
		_main._reset_run()
		_refresh_controlled_world()
	return true


func _complete_real_wreck_return() -> bool:
	if not _require(_world.is_inside_boat(_player.global_position), "real journey did not begin at the canonical boat"):
		return false
	if not _require(_select_active_tool_for_smoke(ProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "real journey could not select the cutter"):
		return false
	var recorder := _tool_target_by_id(RECORDER_ID)
	var survey := _survey_by_id(SURVEY_ID_13)
	var route: Dictionary = _plan_route(recorder, survey)
	if route.is_empty():
		return false
	var navigation = route.get("navigation")
	_minimum_oxygen = _oxygen_seconds
	var distance_start := _distance_px
	if not await _drive_to("southeast_wreck_outbound", recorder.get("center", Vector2.ZERO), navigation):
		return false

	for index in range(_held_salvage_capacity()):
		_main._sortie_state.collect_salvage("%s%d" % [CAPACITY_CUT_PREFIX, index], 0)
	_use_active_tool_for_smoke()
	_advance(float(recorder.get("interaction_seconds", 0.0)) + 0.1)
	_cargo_full_safe = (
		not _world.is_salvage_collected(RECORDER_ID)
		and _main._last_status_note.find("Cargo full") != -1
	)
	if not _require(_cargo_full_safe, "full cargo deleted or advanced the recorder"):
		return false
	_main._sortie_state.clear_held()

	_advance(float(recorder.get("interaction_seconds", 0.0)) * 0.5)
	if not _require(is_zero_approx(float(_main._cutter_salvage.report().get("progress_ratio", -1.0))), "recorder proximity advanced before explicit use"):
		return false
	_use_active_tool_for_smoke()
	_advance(float(recorder.get("interaction_seconds", 0.0)) * 0.5)
	_cutter_partial = float(_main._cutter_salvage.report().get("progress_ratio", 0.0))
	if not _require(_cutter_partial > 0.0 and _cutter_partial < 1.0, "recorder did not expose partial cutter progress"):
		return false
	_place_player(recorder.get("center", Vector2.ZERO) + Vector2(0.0, -48.0))
	_advance(0.0)
	if not _require(
		is_zero_approx(float(_main._cutter_salvage.report().get("progress_ratio", -1.0)))
		and not _world.is_salvage_collected(RECORDER_ID),
		"leaving recorder range did not cancel cutter progress"
	):
		return false
	_place_player(recorder.get("center", Vector2.ZERO))
	_use_active_tool_for_smoke()
	_advance(float(recorder.get("interaction_seconds", 0.0)) + 0.1)
	if not _require(
		_world.is_salvage_collected(RECORDER_ID)
		and _main._sortie_state.held_salvage_ids == [RECORDER_ID]
		and _survey_is_unlocked(),
		"completed recorder did not enter cargo or expose the survey"
	):
		return false
	if not _require(_select_active_tool_for_smoke(ProfileState.SURVEY_SCANNER_CAPABILITY_ID), "real journey could not reselect the scanner"):
		return false

	if not await _drive_to("southeast_wreck_recorder_to_survey", route.get("scan_origin", Vector2.ZERO), navigation):
		return false
	if not _place_for_scan(survey):
		return false
	_advance(0.25)
	if not _require(is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0))), "survey advanced before held Q/USE"):
		return false
	_main._sortie_state.collect_salvage(CAPACITY_SCAN_ID, 0)
	_scanner_full_cargo = _main._held_cargo_count() == _held_salvage_capacity()
	_press_key(KEY_Q)
	_advance(float(survey.get("interaction_seconds", 0.0)) / 3.0)
	_survey_partial = float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	if not _require(_scanner_full_cargo and _survey_partial > 0.0 and _survey_partial < 1.0, "explicit full-cargo scan did not expose partial progress"):
		return false
	var scan_position: Vector2 = _player.global_position
	_player.swim_in_direction(Vector2(-_player.get_facing_sign(), 0.0), 0.0)
	_player.global_position = scan_position
	_player.reset_motion()
	_advance(0.0)
	if not _require(is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0))), "leaving survey range did not cancel progress"):
		return false
	if not _place_for_scan(survey):
		return false
	_press_key(KEY_Q)
	_advance(float(survey.get("interaction_seconds", 0.0)) + 0.1)
	if not _require(
		_main._anomaly_survey.has_pending_discovery()
		and _main._anomaly_survey.overlay_text(_world, _player) == "Wreck archive charted | Return to surface boat"
		and not _main._anomaly_survey.profile_state().has_completed_discovery(DISCOVERY_ID_13),
		"wreck survey did not remain pending away from the boat"
	):
		return false
	_remove_scan_capacity_fixture()

	if not await _return_to_boat("southeast_wreck_return", navigation):
		return false
	_actual_route_distance_px = _distance_px - distance_start
	_actual_oxygen_margin = _minimum_oxygen
	var profile = _main._anomaly_survey.profile_state()
	var expected_result := "%s\n%s" % [survey.get("finding_label", ""), survey.get("next_lead_label", "")]
	if not _require(
		_main._sortie_state.held_salvage == 0
		and profile.has_banked_tool_target(RECORDER_ID)
		and profile.has_completed_discovery(DISCOVERY_ID_13)
		and not _main._anomaly_survey.has_pending_discovery()
		and _main._anomaly_survey.result_text() == expected_result
		and _actual_oxygen_margin > 0.0
		and not _has_oxygen_tank_upgrade(),
		"canonical boat did not bank and commit the viable base-tank journey"
	):
		return false
	var recorder_count: int = profile.report().get("banked_tool_target_ids", []).count(RECORDER_ID)
	var discovery_count: int = profile.report().get("completed_discoveries", []).count(DISCOVERY_ID_13)
	_advance(0.0)
	return _require(
		recorder_count == 1
		and discovery_count == 1
		and profile.report().get("banked_tool_target_ids", []).count(RECORDER_ID) == 1
		and profile.report().get("completed_discoveries", []).count(DISCOVERY_ID_13) == 1
		and _main._expedition_day_state.committed_discovery_ids.count(DISCOVERY_ID_13) == 1,
		"repeat boat update duplicated recorder or discovery commitment"
	)


func _plan_route(recorder: Dictionary, survey: Dictionary) -> Dictionary:
	if not _require(not recorder.is_empty() and not survey.is_empty(), "wreck route targets are missing"):
		return {}
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	var boat: Vector2 = _world.get_entry_position(BOAT_ENTRY_ID)
	var scan_pose: Dictionary = ScannerSmokePose.new().find_pose(_world, survey)
	if not _require(bool(scan_pose.get("found", false)), "wreck survey has no clear scan pose"):
		return {}
	var scan_origin: Vector2 = scan_pose.get("origin", Vector2.ZERO)
	var outbound: PackedVector2Array = navigation.path_between(boat, recorder.get("center", Vector2.ZERO))
	var interaction_leg: PackedVector2Array = navigation.path_between(recorder.get("center", Vector2.ZERO), scan_origin)
	var return_leg: PackedVector2Array = navigation.path_between(scan_origin, boat)
	if not _require(outbound.size() > 1 and interaction_leg.size() > 1 and return_leg.size() > 1, "wreck chain lacks a collision-active boat return route"):
		return {}
	var zone: Dictionary = _world.get_marker_zone(PRESSURE_ZONE_ID)
	var zone_rect := _source_rect(zone)
	if not _require(not zone.is_empty() and _path_crosses_rect(outbound, zone_rect) and _path_crosses_rect(return_leg, zone_rect), "wreck route bypassed the existing pressure crossing"):
		return {}
	_planned_route_distance_px = navigation.path_distance(outbound) + navigation.path_distance(interaction_leg) + navigation.path_distance(return_leg)
	_route_demand_seconds = _planned_route_distance_px / maxf(1.0, float(_player.swim_speed)) + float(recorder.get("interaction_seconds", 0.0)) + float(survey.get("interaction_seconds", 0.0))
	_base_margin_seconds = _oxygen_capacity_seconds() - _route_demand_seconds
	_upgraded_margin_seconds = _base_margin_seconds + SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS
	if not _require(
		not _has_oxygen_tank_upgrade()
		and _base_margin_seconds > 0.0
		and _base_margin_seconds <= 20.0
		and _upgraded_margin_seconds - _base_margin_seconds >= 14.0,
		"route budget lost tight base viability or useful optional margin"
	):
		return {}
	return {"navigation": navigation, "scan_origin": scan_origin}


func _verify_profile_reload() -> bool:
	var reloaded := ProfileState.new(PROFILE_PATH, true)
	var load: Dictionary = reloaded.load_profile()
	return _require(
		load.get("status") in ["loaded", "migrated_wreck_navigation"]
		and reloaded.has_completed_discovery(ABYSSAL_DISCOVERY_ID)
		and reloaded.has_completed_discovery(ProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID)
		and reloaded.has_capability(PRESSURE_CAPABILITY_ID)
		and reloaded.has_capability(ProfileState.SALVAGE_CUTTER_CAPABILITY_ID)
		and reloaded.has_capability(ProfileState.SURVEY_SCANNER_CAPABILITY_ID)
		and reloaded.has_banked_tool_target(RECORDER_ID)
		and reloaded.has_completed_discovery(DISCOVERY_ID_13),
		"profile reload lost wreck prerequisites, clearance, or discovery"
	)


func _failure_restored_recorder(recorder: Dictionary) -> bool:
	var profile = _main._anomaly_survey.profile_state()
	return (
		not _world.get_tool_target_near(recorder.get("center", Vector2.ZERO), SALVAGE_COLLECTION_RADIUS).is_empty()
		and not _main._sortie_state.held_salvage_ids.has(RECORDER_ID)
		and not profile.has_banked_tool_target(RECORDER_ID)
		and not _survey_is_unlocked()
		and not _main._anomaly_survey.has_pending_discovery()
		and is_zero_approx(float(_main._cutter_salvage.report().get("progress_ratio", -1.0)))
	)


func _survey_is_unlocked() -> bool:
	var dependencies: Dictionary = _main._anomaly_survey.report().get("dependencies", {}).get("dependencies", {})
	return bool(dependencies.get(SURVEY_ID_13, {}).get("unlocked", false))


func _tool_target_by_id(target_id: String) -> Dictionary:
	for target in _world.get_tool_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _path_crosses_rect(path: PackedVector2Array, rect: Rect2) -> bool:
	var expanded := rect.grow(8.0)
	for index in range(1, path.size()):
		if expanded.has_point(path[index - 1]) or expanded.has_point(path[index]) or expanded.has_point(path[index - 1].lerp(path[index], 0.5)):
			return true
	return false


func _remove_scan_capacity_fixture() -> void:
	if _main._sortie_state.held_salvage_ids.has(CAPACITY_SCAN_ID):
		_main._sortie_state.held_salvage_ids.erase(CAPACITY_SCAN_ID)
		_main._sortie_state.held_salvage = maxi(0, _main._sortie_state.held_salvage - 1)


func _place_player(position: Vector2) -> void:
	_player.global_position = position
	_player.reset_motion()


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	cleanup_profile_storage()
	push_error("Expansion 13 southeast-wreck return smoke failed: %s." % message)
	get_tree().quit(1)
	return false
