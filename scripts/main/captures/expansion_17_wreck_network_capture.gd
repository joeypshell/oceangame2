extends RefCounted

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const Expansion16CaptureRenderer := preload("res://scripts/main/captures/expansion_16_capture_renderer.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ScannerPose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")

const MAP_ID := "production_level_01"
const WEST_JOURNEY_ID := "western_chasm_wreck_fragment_journey"
const WEST_SURVEY_ID := "western_chasm_wreck_fragment_survey"
const WEST_FRAGMENT_ID := "western_chasm_wreck_fragment_discovery"
const ABYSS_JOURNEY_ID := "abyssal_shelf_wreck_fragment_journey"
const ABYSS_SURVEY_ID := "abyssal_shelf_wreck_fragment_survey"
const ABYSS_FRAGMENT_ID := "abyssal_shelf_wreck_fragment_discovery"
const ANALYSIS_DISCOVERY_ID := "wreck_network_triangulation_discovery"
const CAMERA_IDS := {
	"parallel": "expansion_17_parallel_leads",
	"west_approach": "expansion_17_western_approach",
	"west_scan": "expansion_17_western_scan",
	"abyss_approach": "expansion_17_abyssal_approach",
	"abyss_scan": "expansion_17_abyssal_scan",
	"analysis": "expansion_17_analysis_ready",
}

var _main
var _renderer


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_renderer = Expansion16CaptureRenderer.new(_main, "Expansion 17 wreck-network")
	var camera_tests := _camera_tests_by_id()
	if camera_tests.size() != CAMERA_IDS.size():
		_fail("authored camera tests are incomplete: %s" % str(camera_tests.keys()))
		return
	if not _prepare_parallel_leads():
		return
	if not await _renderer.capture_pair(capture_dir, "night_parallel_leads", camera_tests[CAMERA_IDS["parallel"]]):
		return
	if not _prepare_alternate_pin():
		return
	if not await _renderer.capture_pair(capture_dir, "night_abyssal_pinned", camera_tests[CAMERA_IDS["parallel"]]):
		return
	if not await _start_selected_day():
		return
	if not _prepare_artifact_approach(WEST_SURVEY_ID):
		return
	if not await _renderer.capture_pair(capture_dir, "western_relay_approach", camera_tests[CAMERA_IDS["west_approach"]], true):
		return
	if not _prepare_scan_progress(WEST_SURVEY_ID):
		return
	if not await _renderer.capture_pair(capture_dir, "western_relay_scan_progress", camera_tests[CAMERA_IDS["west_scan"]], true):
		return
	if not _complete_and_commit(WEST_SURVEY_ID, WEST_FRAGMENT_ID):
		return
	if not _prepare_one_fragment_debrief():
		return
	if not await _renderer.capture_pair(capture_dir, "night_one_fragment_remaining", camera_tests[CAMERA_IDS["parallel"]]):
		return
	if not await _start_selected_day():
		return
	if not _prepare_artifact_approach(ABYSS_SURVEY_ID):
		return
	if not await _renderer.capture_pair(capture_dir, "abyssal_relay_approach", camera_tests[CAMERA_IDS["abyss_approach"]], true):
		return
	if not _prepare_scan_progress(ABYSS_SURVEY_ID):
		return
	if not await _renderer.capture_pair(capture_dir, "abyssal_relay_scan_progress", camera_tests[CAMERA_IDS["abyss_scan"]], true):
		return
	if not _complete_and_commit(ABYSS_SURVEY_ID, ABYSS_FRAGMENT_ID):
		return
	if not _prepare_automatic_analysis_debrief():
		return
	if not await _renderer.capture_pair(capture_dir, "night_analysis_result", camera_tests[CAMERA_IDS["analysis"]]):
		return
	print("Saved Expansion 17 wreck-network captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	await _renderer.prepare_to_quit()
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != MAP_ID:
		_fail("requires the contiguous production level")
		return false
	var profile = _main._anomaly_survey.profile_state()
	var report: Dictionary = profile.report()
	if (
		str(profile.last_storage_report().get("status", "")) != "memory"
		or not report.get("completed_discoveries", []).is_empty()
		or not report.get("unlocked_capabilities", []).is_empty()
		or not report.get("material_inventory", {}).is_empty()
		or not report.get("completed_projects", []).is_empty()
	):
		_fail("capture did not start from isolated fresh profile state")
		return false
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.EXPANSION_16_START, profile)
	var project := _record_by_id(
		_main._world.get_material_projects(),
		ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID
	)
	var built: Dictionary = profile.complete_material_project(project, false)
	var recorder: Dictionary = profile.bank_tool_target(ExpansionProfileState.FAR_WEST_WRECK_RECORDER_ID, false)
	var prerequisite: Dictionary = profile.complete_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID, false)
	if (
		not bool(applied.get("ready", false))
		or not bool(built.get("changed", false))
		or not bool(recorder.get("changed", false))
		or not bool(prerequisite.get("changed", false))
	):
		_fail("could not establish the Expansion 17 boundary")
		return false
	_prepare_runtime_nodes()
	_refresh_runtime_sources()
	return _expect(
		_main._wreck_network_investigation.report().get("status") == "fragments_required"
		and _main._refresh_expedition_plan().get("eligible_ids") == [WEST_JOURNEY_ID, ABYSS_JOURNEY_ID],
		"two source-authored leads were not ready"
	)


func _prepare_runtime_nodes() -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._player.reset_motion()
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false


func _refresh_runtime_sources() -> void:
	_main._material_project.on_map_loaded(_main._world)
	_main._anomaly_survey.on_map_loaded(_main._world)
	_main._cutter_salvage.on_map_loaded(_main._world)
	_main._wreck_network_investigation.on_map_loaded(_main._world)
	_main._oxygen_consumption_zone.on_map_loaded(_main._world)
	_main._refresh_active_tools()


func _prepare_parallel_leads() -> bool:
	_place_at_boat()
	if not _main._expedition_day_state.request_end_day("voluntary"):
		_fail("could not request the planning debrief")
		return false
	ExpeditionDayDebrief.update(_main, 0.0)
	var plan: Dictionary = _main._refresh_expedition_plan()
	_main._update_status_label()
	var panel: Dictionary = _main._expedition_plan_panel.get_test_report()
	return _expect(
		_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF
		and plan.get("eligible_ids") == [WEST_JOURNEY_ID, ABYSS_JOURNEY_ID]
		and panel.get("lead_ids") == [WEST_JOURNEY_ID, ABYSS_JOURNEY_ID]
		and _rows_name_both_leads(panel.get("row_texts", [])),
		"night planning did not show both coordinate-transponder leads"
	)


func _prepare_alternate_pin() -> bool:
	var cycled: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_TAB)
	var pinned: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_E)
	_main._last_status_note = ""
	_main._update_status_label()
	var panel: Dictionary = _main._expedition_plan_panel.get_test_report()
	return _expect(
		bool(cycled.get("changed", false))
		and bool(pinned.get("changed", false))
		and _main._expedition_plan_state.selected_lead_id() == ABYSS_JOURNEY_ID
		and panel.get("selected_lead_id") == ABYSS_JOURNEY_ID,
		"alternate abyssal lead was not visibly pinned"
	)


func _start_selected_day() -> bool:
	var started: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_N)
	await _main.get_tree().process_frame
	if not bool(started.get("changed", false)):
		_fail("planned day did not start: %s" % str(started))
		return false
	_prepare_runtime_nodes()
	return _expect(
		_main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE
		and _main._expedition_plan_state.selected_lead_id() == ABYSS_JOURNEY_ID,
		"alternate selection did not survive the day transition"
	)


func _prepare_artifact_approach(survey_id: String) -> bool:
	var survey := _record_by_id(_main._world.get_survey_targets(), survey_id)
	var pose: Dictionary = ScannerPose.new().place(_main._world, _main._player, survey)
	if not bool(pose.get("found", false)):
		_fail("artifact %s has no scanner pose" % survey_id)
		return false
	_main._last_status_note = ""
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	_main._update_status_label()
	return _expect(
		_status_text().find(str(survey.get("clue_label", ""))) != -1,
		"artifact approach omitted its source clue"
	)


func _prepare_scan_progress(survey_id: String) -> bool:
	var survey := _record_by_id(_main._world.get_survey_targets(), survey_id)
	if not _select_tool(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID):
		return false
	var activated: Dictionary = _main._active_tool_runtime.use()
	var partial: Dictionary = _main._anomaly_survey.update(
		_main._world,
		_main._player,
		float(survey.get("interaction_seconds", 0.0)) * 0.5
	)
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	_main._last_status_note = str(partial.get("note", ""))
	_main._update_status_label()
	var progress := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	var presentation: Dictionary = _main._player.get_scanner_presentation_report()
	return _expect(
		activated.get("reason") == "activated"
		and progress >= 0.49 and progress <= 0.51
		and presentation.get("target_id") == survey_id
		and bool(presentation.get("card_visible", false)),
		"artifact %s did not present 50%% held-scanner progress" % survey_id
	)


func _complete_and_commit(survey_id: String, discovery_id: String) -> bool:
	var survey := _record_by_id(_main._world.get_survey_targets(), survey_id)
	var completed: Dictionary = _main._anomaly_survey.update(
		_main._world,
		_main._player,
		float(survey.get("interaction_seconds", 0.0))
	)
	_main._release_active_tool()
	if not bool(completed.get("pending", false)) or not _main._anomaly_survey.has_pending_discovery():
		_fail("artifact %s did not create pending discovery" % survey_id)
		return false
	_place_at_boat()
	var committed: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, 0.0)
	if not bool(committed.get("committed", false)) or str(committed.get("discovery_id", "")) != discovery_id:
		_fail("artifact %s did not commit at the canonical boat" % survey_id)
		return false
	_main._expedition_day_state.record_discovery(discovery_id)
	var investigation: Dictionary = _main._wreck_network_investigation.on_discovery_committed(discovery_id)
	_main._last_status_note = str(investigation.get("note", committed.get("note", "")))
	_main._refresh_expedition_plan()
	_main._update_status_label()
	return _expect(
		_main._anomaly_survey.profile_state().report().get("completed_discoveries", []).count(discovery_id) == 1,
		"artifact %s did not commit exactly once" % survey_id
	)


func _prepare_one_fragment_debrief() -> bool:
	if not _main._expedition_day_state.request_end_day("voluntary"):
		_fail("could not request the one-fragment debrief")
		return false
	ExpeditionDayDebrief.update(_main, 0.0)
	_main._update_status_label()
	var result_text: String = _main._result_label.text if _main._result_label != null else ""
	return _expect(
		_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF
		and result_text.find("Remaining: Abyssal Coordinate Transponder") != -1,
		"one-fragment boat feedback did not name the remaining lead"
	)


func _prepare_automatic_analysis_debrief() -> bool:
	if not _main._expedition_day_state.request_end_day("voluntary"):
		_fail("could not request the analysis debrief")
		return false
	ExpeditionDayDebrief.update(_main, 0.0)
	_main._update_status_label()
	var result_text: String = _main._result_label.text if _main._result_label != null else ""
	return _expect(
		not _main._wreck_network_investigation.requires_analysis()
		and _main._anomaly_survey.profile_state().has_completed_discovery(ANALYSIS_DISCOVERY_ID)
		and _main._expedition_day_state.committed_discovery_ids.has(ANALYSIS_DISCOVERY_ID)
		and result_text.find("Transfer hub coordinates recovered") != -1
		and result_text.find("Destination: transfer hub beyond mapped cave") != -1
		and result_text.find("Space/USE") == -1,
		"night did not automatically commit one readable coordinate result"
	)


func _select_tool(tool_id: String) -> bool:
	_main._refresh_active_tools()
	for _index in range(_main.ActiveToolController.ordered_tool_ids().size()):
		if _main._active_tools.selected_tool_id() == tool_id:
			return true
		_main._active_tool_runtime.cycle()
	_fail("could not select tool %s" % tool_id)
	return false


func _place_at_boat() -> void:
	_main._player.global_position = _main._world.get_entry_position("surface_boat_entry")
	_main._player.reset_motion()


func _camera_tests_by_id() -> Dictionary:
	var values := {}
	for camera_test in _main._world.camera_tests:
		var camera_id := str(camera_test.get("id", ""))
		if CAMERA_IDS.values().has(camera_id):
			values[camera_id] = camera_test
	return values


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for value in records:
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == record_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _rows_name_both_leads(rows: Array) -> bool:
	return (
		rows.size() == 2
		and str(rows[0]).find("Western Coordinate Transponder") != -1
		and str(rows[1]).find("Abyssal Coordinate Transponder") != -1
	)


func _status_text() -> String:
	return _main._status_label.text if _main._status_label != null else ""


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("Expansion 17 wreck-network capture failed: %s." % message)
	_main.get_tree().quit(1)
