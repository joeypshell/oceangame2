extends "res://scripts/main/smoke/smoke_expansion_16_deeper_wreck_checks.gd"

const ExpeditionDayDebrief17 := preload("res://scripts/main/expedition_day_debrief.gd")

const PROFILE_PATH_17 := "user://oceangame2_expansion_17_journey_smoke.json"
const WEST_JOURNEY_ID_17 := "western_chasm_wreck_fragment_journey"
const WEST_SURVEY_ID_17 := "western_chasm_wreck_fragment_survey"
const WEST_FRAGMENT_ID_17 := "western_chasm_wreck_fragment_discovery"
const ABYSS_JOURNEY_ID_17 := "abyssal_shelf_wreck_fragment_journey"
const ABYSS_SURVEY_ID_17 := "abyssal_shelf_wreck_fragment_survey"
const ABYSS_FRAGMENT_ID_17 := "abyssal_shelf_wreck_fragment_discovery"
const ANALYSIS_DISCOVERY_ID_17 := "wreck_network_triangulation_discovery"
const ANALYSIS_PROMISE_17 := "Destination: transfer hub beyond mapped cave"
const PASSABLE_CAPABILITIES_17 := [
	ProfileState.PROPULSION_FINS_CAPABILITY_ID,
	ProfileState.CURRENT_STABILIZER_CAPABILITY_ID,
]

var _selected_lead_17 := ""
var _pending_ids_17: Array[String] = []
var _committed_ids_17: Array[String] = []
var _cancel_progress_17 := 0.0
var _failure_cleanup_17 := false
var _analysis_result_17 := ""


static func create_clean_profile():
	cleanup_profile_storage_17()
	return ProfileState.new(PROFILE_PATH_17, true)


static func cleanup_profile_storage_17() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH_17, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _smoke_expansion_17_wreck_network_and_quit() -> void:
	if not _prepare_expansion_17_boundary():
		return
	if not await _select_alternate_lead_and_start_day():
		return
	if not await _complete_western_fragment():
		return
	if not await _review_one_fragment_and_start_next_day():
		return
	if not await _complete_abyssal_fragment():
		return
	if not _analyze_and_verify_reload():
		return

	var profile = _main._anomaly_survey.profile_state()
	var profile_report: Dictionary = profile.report()
	var day_report: Dictionary = _main._expedition_day_state.report()
	var oxygen := _oxygen_seconds
	cleanup_profile_storage_17()
	print("Expansion 17 wreck-network smoke passed: artifacts=%s,%s selected=%s selection_independent=true cancel_progress=%.2f cancel_on_leave=true pending_cleanup=hazard pending_ids=%s committed_ids=%s exact_once=true night_payoff=automatic analysis=%s day=%d oxygen=%.1f score=%d materials=%s profile_discoveries=%d reload=true result=\"%s\"." % [
		WEST_SURVEY_ID_17,
		ABYSS_SURVEY_ID_17,
		_selected_lead_17,
		_cancel_progress_17,
		",".join(PackedStringArray(_pending_ids_17)),
		",".join(PackedStringArray(_committed_ids_17)),
		ANALYSIS_DISCOVERY_ID_17,
		int(day_report.get("day_number", 0)),
		oxygen,
		int(_main._banked_score),
		str(profile.material_inventory()),
		profile_report.get("completed_discoveries", []).size(),
		_analysis_result_17.replace("\n", " | "),
	])
	get_tree().quit(0)


func _prepare_expansion_17_boundary() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var applied: Dictionary = ReviewCheckpointFixture.apply(
		ReviewCheckpointFixture.EXPANSION_16_START,
		profile
	)
	var project := _record_by_id(
		_world.get_material_projects(),
		ProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID
	)
	var built: Dictionary = profile.complete_material_project(project, true)
	var recorder: Dictionary = profile.bank_tool_target(ProfileState.FAR_WEST_WRECK_RECORDER_ID, true)
	var prerequisite: Dictionary = profile.complete_discovery(ProfileState.FAR_WEST_WRECK_DISCOVERY_ID, true)
	_main._material_project.on_map_loaded(_world)
	_main._cutter_salvage.on_map_loaded(_world)
	_main._anomaly_survey.on_map_loaded(_world)
	_main._wreck_network_investigation.on_map_loaded(_world)
	_main._oxygen_consumption_zone.on_map_loaded(_world)
	_main._refresh_active_tools()
	var plan: Dictionary = _main._refresh_expedition_plan()
	return _require(
		bool(applied.get("ready", false))
		and bool(built.get("changed", false))
		and bool(recorder.get("changed", false))
		and bool(prerequisite.get("changed", false))
		and profile.has_capability(ProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID)
		and plan.get("eligible_ids") == [WEST_JOURNEY_ID_17, ABYSS_JOURNEY_ID_17]
		and _main._wreck_network_investigation.report().get("status") == "fragments_required",
		"Expansion 17 boundary fixture drifted: checkpoint=%s build=%s recorder=%s prerequisite=%s plan=%s" % [
			applied,
			built,
			recorder,
			prerequisite,
			plan,
		]
	)


func _select_alternate_lead_and_start_day() -> bool:
	var requested: Dictionary = ExpeditionDayDebrief17.handle_day_key(_main)
	_main._process(0.0)
	if not _require(bool(requested.get("requested", false)) and _main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "could not enter the initial planning debrief"):
		return false
	var cycled: Dictionary = ExpeditionDayDebrief17.handle_debrief_key(_main, KEY_TAB)
	var pinned: Dictionary = ExpeditionDayDebrief17.handle_debrief_key(_main, KEY_E)
	_selected_lead_17 = str(_main._expedition_plan_state.selected_lead_id())
	if not _require(bool(cycled.get("changed", false)) and bool(pinned.get("changed", false)) and _selected_lead_17 == ABYSS_JOURNEY_ID_17, "alternate abyssal lead was not pinned"):
		return false
	var started: Dictionary = ExpeditionDayDebrief17.handle_debrief_key(_main, KEY_N)
	await get_tree().physics_frame
	return _require(bool(started.get("changed", false)) and _main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE, "planned day did not start") and _prepare_route_motion()


func _complete_western_fragment() -> bool:
	var target := _survey_by_id(WEST_SURVEY_ID_17)
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES_17)
	var pose: Dictionary = ScannerSmokePose.new().find_pose(_world, target)
	if not _require(bool(pose.get("found", false)), "western artifact has no scanner pose"):
		return false
	if not await _drive_to("expansion_17_west_outbound", pose.get("origin", Vector2.ZERO), navigation):
		return false
	if not _scan_with_leave_cancel(target):
		return false
	if not _complete_scan(target):
		return false
	_pending_ids_17.append(_pending_discovery_id())
	_main._handle_hazard_hit("expansion_17_pending_cleanup")
	_failure_cleanup_17 = not _main._anomaly_survey.has_pending_discovery()
	if not _require(_failure_cleanup_17 and not _main._anomaly_survey.profile_state().has_completed_discovery(WEST_FRAGMENT_ID_17), "hazard retained or committed the pending western fragment"):
		return false

	_oxygen_seconds = _oxygen_capacity_seconds()
	if not _complete_scan(target):
		return false
	_pending_ids_17.append(_pending_discovery_id())
	if not await _return_to_boat("expansion_17_west_return", navigation):
		return false
	_committed_ids_17.append(WEST_FRAGMENT_ID_17)
	_advance(0.0)
	var profile = _main._anomaly_survey.profile_state()
	var investigation: Dictionary = _main._wreck_network_investigation.report()
	return _require(
		profile.report().get("completed_discoveries", []).count(WEST_FRAGMENT_ID_17) == 1
		and not _main._anomaly_survey.has_pending_discovery()
		and investigation.get("remaining_fragment_ids") == [ABYSS_FRAGMENT_ID_17]
		and _main._wreck_network_investigation.objective_line().find("Abyssal Coordinate Transponder") != -1
		and _main._expedition_plan_state.selected_lead_id() == ABYSS_JOURNEY_ID_17,
		"western commit lost exact-once, remaining-lead, or selection state"
	)


func _review_one_fragment_and_start_next_day() -> bool:
	var requested: Dictionary = ExpeditionDayDebrief17.handle_day_key(_main)
	_main._process(0.0)
	if not _require(bool(requested.get("requested", false)) and _main._result_label.text.find("Abyssal Coordinate Transponder") != -1, "one-fragment debrief did not name the remaining lead"):
		return false
	var started: Dictionary = ExpeditionDayDebrief17.handle_debrief_key(_main, KEY_N)
	await get_tree().physics_frame
	return _require(bool(started.get("changed", false)) and _main._expedition_plan_state.selected_lead_id() == ABYSS_JOURNEY_ID_17, "remaining lead did not survive the next-day transition") and _prepare_route_motion()


func _complete_abyssal_fragment() -> bool:
	var target := _survey_by_id(ABYSS_SURVEY_ID_17)
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES_17)
	var pose: Dictionary = ScannerSmokePose.new().find_pose(_world, target)
	if not _require(bool(pose.get("found", false)), "abyssal artifact has no scanner pose"):
		return false
	if not await _drive_to("expansion_17_abyss_outbound", pose.get("origin", Vector2.ZERO), navigation):
		return false
	if not _complete_scan(target):
		return false
	_pending_ids_17.append(_pending_discovery_id())
	if not await _return_to_boat("expansion_17_abyss_return", navigation):
		return false
	_committed_ids_17.append(ABYSS_FRAGMENT_ID_17)
	_advance(0.0)
	var profile = _main._anomaly_survey.profile_state()
	return _require(
		profile.report().get("completed_discoveries", []).count(ABYSS_FRAGMENT_ID_17) == 1
		and not _main._anomaly_survey.has_pending_discovery()
		and _main._wreck_network_investigation.requires_analysis(),
		"abyssal commit did not reach exact-once analysis readiness"
	)


func _analyze_and_verify_reload() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var score_before := int(_main._banked_score)
	var materials_before: Dictionary = profile.material_inventory()
	var requested: Dictionary = ExpeditionDayDebrief17.handle_day_key(_main)
	_main._process(0.0)
	_analysis_result_17 = _main._wreck_network_investigation.result_text()
	var debrief_text: String = _main._result_label.text
	if not _require(
		bool(requested.get("requested", false))
		and not _main._wreck_network_investigation.requires_analysis()
		and profile.has_completed_discovery(ANALYSIS_DISCOVERY_ID_17)
		and _main._expedition_day_state.committed_discovery_ids.has(ANALYSIS_DISCOVERY_ID_17)
		and debrief_text.find("Transfer hub coordinates recovered") != -1
		and debrief_text.find(ANALYSIS_PROMISE_17) != -1
		and debrief_text.find("Space/USE") == -1,
		"night did not automatically present the coordinate payoff"
	):
		return false
	var ignored_use: Dictionary = ExpeditionDayDebrief17.handle_debrief_key(_main, KEY_SPACE)
	if not _require(ignored_use.get("reason") == "ignored", "Space remained a separate night-analysis command"):
		return false
	var next_day: Dictionary = ExpeditionDayDebrief17.handle_debrief_key(_main, KEY_N)
	var reloaded := ProfileState.new(PROFILE_PATH_17, true)
	var load: Dictionary = reloaded.load_profile()
	return _require(
		profile.report().get("completed_discoveries", []).count(ANALYSIS_DISCOVERY_ID_17) == 1
		and _analysis_result_17.find("Transfer hub coordinates recovered") != -1
		and _analysis_result_17.find(ANALYSIS_PROMISE_17) != -1
		and bool(next_day.get("changed", false))
		and int(_main._banked_score) == score_before
		and profile.material_inventory() == materials_before
		and load.get("status") == "loaded"
		and reloaded.has_completed_discovery(WEST_FRAGMENT_ID_17)
		and reloaded.has_completed_discovery(ABYSS_FRAGMENT_ID_17)
		and reloaded.has_completed_discovery(ANALYSIS_DISCOVERY_ID_17),
		"automatic analysis result, next-day flow, cost, exact-once state, or profile reload drifted"
	)


func _scan_with_leave_cancel(target: Dictionary) -> bool:
	if not _select_active_tool_for_smoke(ProfileState.SURVEY_SCANNER_CAPABILITY_ID) or not _place_for_scan(target):
		return _require(false, "western artifact could not activate the scanner")
	_use_active_tool_for_smoke()
	_advance(float(target.get("interaction_seconds", 0.0)) * 0.4)
	_cancel_progress_17 = float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_player.reset_motion()
	_advance(0.0)
	return _require(
		_cancel_progress_17 > 0.0
		and _cancel_progress_17 < 1.0
		and str(_main._anomaly_survey.report().get("interaction", {}).get("active_target_id", "")).is_empty()
		and not _main._anomaly_survey.has_pending_discovery(),
		"leaving the western artifact did not cancel partial scan progress"
	)


func _complete_scan(target: Dictionary) -> bool:
	if not _select_active_tool_for_smoke(ProfileState.SURVEY_SCANNER_CAPABILITY_ID) or not _place_for_scan(target):
		return _require(false, "could not place scanner at %s" % target.get("id", "target"))
	_use_active_tool_for_smoke()
	_advance(float(target.get("interaction_seconds", 0.0)))
	_main._release_active_tool()
	return _require(
		_main._anomaly_survey.has_pending_discovery()
		and _pending_discovery_id() == str(target.get("discovery_id", "")),
		"%s did not create its source-authored pending fragment" % target.get("id", "target")
	)


func _prepare_route_motion() -> bool:
	var collision := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not _require(collision != null and collision.shape is RectangleShape2D and not collision.disabled, "player collision is unavailable"):
		return false
	_body_size = (collision.shape as RectangleShape2D).size
	_starting_health = int(_main._player_health.current_health)
	_oxygen_seconds = _oxygen_capacity_seconds()
	_minimum_oxygen = _oxygen_seconds
	_prepare_controlled_movement()
	return true


func _pending_discovery_id() -> String:
	return str(_main._anomaly_survey.report().get("expedition", {}).get("pending", {}).get("discovery_id", ""))


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for value in records:
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == record_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	cleanup_profile_storage_17()
	push_error("Expansion 17 wreck-network smoke failed: %s." % message)
	get_tree().quit(1)
	return false
