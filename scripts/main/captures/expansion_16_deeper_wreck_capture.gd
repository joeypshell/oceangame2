extends RefCounted

const Expansion16CaptureRenderer := preload("res://scripts/main/captures/expansion_16_capture_renderer.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ScannerPose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")

const MAP_ID := "production_level_01"
const ZONE_ID := "far_west_confined_wreck_oxygen_zone"
const RECORDER_ID := "far_west_wreck_data_recorder"
const SURVEY_ID := "far_west_deeper_wreck_survey"
const CAMERA_IDS := {
	"threshold": "expansion_16_oxygen_threshold",
	"cut": "expansion_16_recorder_cut",
	"survey": "expansion_16_recorder_survey",
}

var _main
var _renderer


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_renderer = Expansion16CaptureRenderer.new(_main)
	var camera_tests := _camera_tests_by_id()
	if camera_tests.size() != CAMERA_IDS.size():
		_fail("authored Expansion 16 camera tests are incomplete: %s" % str(camera_tests.keys()))
		return
	if not _prepare_unprotected_warning(camera_tests[CAMERA_IDS["threshold"]]):
		return
	if not await _renderer.capture_pair(capture_dir, "pre_rebreather_warning", camera_tests[CAMERA_IDS["threshold"]]):
		return
	if not _prepare_rebreather_active(camera_tests[CAMERA_IDS["threshold"]]):
		return
	if not await _renderer.capture_pair(capture_dir, "rebreather_active", camera_tests[CAMERA_IDS["threshold"]]):
		return
	if not _prepare_cutter_progress():
		return
	if not await _renderer.capture_pair(capture_dir, "recorder_cutter_progress", camera_tests[CAMERA_IDS["cut"]]):
		return
	if not _prepare_scanner_progress():
		return
	if not await _renderer.capture_pair(capture_dir, "recorder_scanner_progress", camera_tests[CAMERA_IDS["survey"]]):
		return
	print("Saved Expansion 16 deeper-wreck captures under: %s" % ProjectSettings.globalize_path(capture_dir))
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
	var applied: Dictionary = ReviewCheckpointFixture.apply(
		ReviewCheckpointFixture.EXPANSION_16_START,
		profile
	)
	if not bool(applied.get("ready", false)):
		_fail("Expansion 16 checkpoint did not apply: %s" % str(applied))
		return false
	_prepare_runtime_nodes()
	_refresh_runtime_sources()
	return true


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
	_main._oxygen_consumption_zone.on_map_loaded(_main._world)
	_main._refresh_active_tools()


func _prepare_unprotected_warning(camera_test: Dictionary) -> bool:
	_place_at_camera_center(camera_test)
	_main._sortie_state.oxygen_seconds = 55.0
	_main._last_status_note = ""
	var zone: Dictionary = _main._world.get_marker_zone(ZONE_ID)
	_main._oxygen_consumption_zone.update(
		_main._player.global_position,
		Callable(_main._anomaly_survey.profile_state(), "has_capability"),
		float(zone.get("warning_grace_seconds", 0.0))
	)
	_main._oxygen_consumption_zone.update(
		_main._player.global_position,
		Callable(_main._anomaly_survey.profile_state(), "has_capability"),
		0.25
	)
	_main._update_status_label()
	var report: Dictionary = _main._oxygen_consumption_zone.report()
	return _expect(
		bool(report.get("inside", false))
		and not bool(report.get("protected", true))
		and is_equal_approx(float(report.get("drain_multiplier", 0.0)), 8.0)
		and _status_text().find("Confined wreck air | Oxygen x8") != -1,
		"pre-rebreather warning drifted: report=%s status=%s" % [
			str(report),
			_status_text(),
		]
	)


func _prepare_rebreather_active(camera_test: Dictionary) -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var built: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	if not bool(built.get("changed", false)) or not profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID):
		_fail("exact night recipe did not prepare the protected capture")
		return false
	_main._oxygen_consumption_zone.reset()
	_place_at_camera_center(camera_test)
	_main._last_status_note = ""
	_main._oxygen_consumption_zone.update(
		_main._player.global_position,
		Callable(profile, "has_capability"),
		0.1
	)
	_main._update_status_label()
	var report: Dictionary = _main._oxygen_consumption_zone.report()
	return _expect(
		bool(report.get("protected", false))
		and is_equal_approx(float(report.get("drain_multiplier", 0.0)), 1.0)
		and _status_text().find("Rebreather active") != -1,
		"protected threshold did not show normalized oxygen state"
	)


func _prepare_cutter_progress() -> bool:
	var recorder := _record_by_id(_main._world.get_tool_targets(), RECORDER_ID)
	if recorder.is_empty():
		_fail("far-west recorder is missing")
		return false
	_main._player.global_position = recorder.get("center", Vector2.ZERO)
	_main._player.reset_motion()
	if not _select_tool(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID):
		return false
	var activated: Dictionary = _main._active_tool_runtime.use()
	_main._cargo_collection.update(float(recorder.get("interaction_seconds", 0.0)) * 0.5)
	_main._oxygen_consumption_zone.update(
		_main._player.global_position,
		Callable(_main._anomaly_survey.profile_state(), "has_capability"),
		2.0
	)
	_main._update_status_label()
	var ratio := float(_main._cutter_salvage.report().get("progress_ratio", 0.0))
	return _expect(
		activated.get("status") == "used"
		and ratio >= 0.49 and ratio <= 0.51
		and not _main._world.is_salvage_collected(RECORDER_ID)
		and _status_text().find("Cutting wreck data recorder") != -1,
		"recorder cutter state drifted: activation=%s report=%s nearby=%s status=%s" % [
			str(activated),
			str(_main._cutter_salvage.report()),
			str(_main._world.get_tool_target_near(
				_main._player.global_position,
				_main.SALVAGE_COLLECTION_RADIUS
			).get("id", "")),
			_status_text(),
		]
	)


func _prepare_scanner_progress() -> bool:
	var recorder := _record_by_id(_main._world.get_tool_targets(), RECORDER_ID)
	_main._cargo_collection.update(float(recorder.get("interaction_seconds", 0.0)))
	if not _main._world.is_salvage_collected(RECORDER_ID):
		_fail("recorder did not complete before scanner capture")
		return false
	var survey := _record_by_id(_main._world.get_survey_targets(), SURVEY_ID)
	var pose: Dictionary = ScannerPose.new().place(_main._world, _main._player, survey)
	if not bool(pose.get("found", false)) or not _select_tool(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID):
		_fail("far-west survey has no active scanner pose")
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
		and presentation.get("target_id") == SURVEY_ID
		and bool(presentation.get("card_visible", false))
		and _status_text().find("Survey deeper wreck recorder 50%") != -1,
		"recorder did not present 50% held-scanner progress"
	)


func _select_tool(tool_id: String) -> bool:
	_main._refresh_active_tools()
	for _index in range(_main.ActiveToolController.ordered_tool_ids().size()):
		if _main._active_tools.selected_tool_id() == tool_id:
			return true
		_main._active_tool_runtime.cycle()
	_fail("could not select tool %s" % tool_id)
	return false


func _camera_tests_by_id() -> Dictionary:
	var values := {}
	for camera_test in _main._world.camera_tests:
		var camera_id := str(camera_test.get("id", ""))
		if CAMERA_IDS.values().has(camera_id):
			values[camera_id] = camera_test
	return values


func _place_at_camera_center(camera_test: Dictionary) -> void:
	_main._player.global_position = Vector2(
		float(camera_test.get("center_x", 0.0)) * float(_main._world.tile_size),
		float(camera_test.get("center_y", 0.0)) * float(_main._world.tile_size)
	)
	_main._player.reset_motion()


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str(record.get("id", "")) == record_id:
			return record
	return {}


func _status_text() -> String:
	return _main._status_label.text if _main._status_label != null else ""


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("Expansion 16 deeper-wreck capture failed: %s." % message)
	_main.get_tree().quit(1)
