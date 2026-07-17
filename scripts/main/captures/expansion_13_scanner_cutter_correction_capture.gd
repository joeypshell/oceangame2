extends "res://scripts/main/captures/expansion_13_southeast_wreck_capture.gd"

const ScannerCorrectionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ScannerConeTargeting := preload("res://scripts/main/scanner_cone_targeting.gd")

const ARTIFACT_ID := "lower_right_anomaly_survey"
const BLUEPRINT_ID := "salvage_cutter_blueprint"
const CUTTER_CAPABILITY_ID := "salvage_cutter"
const PAYOFF_ID := "salvage_sealed_wreck_cache"
const BOAT_ENTRY_ID := "surface_boat_entry"
const OPENING_LEAD := "Maintenance signal | Beyond east current"
const NEXT_MYSTERY := "Faint maintenance signal continues deeper southeast"
const ARTIFACT_ZOOM := 0.90
const BOAT_CAMERA_ID := "production_level_boat_entry"
const BOAT_APPROACH_CAMERA_ID := "expansion_13_pending_boat_return"
const ARTIFACT_PARTIAL_SECONDS := 1.5

var _artifact := {}
var _payoff := {}
var _scanner_pose := {}
var _artifact_frame := {}


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_camera = _create_camera()
	if not _prepare_correction_state():
		return
	if not await _capture_artifact_sequence(capture_dir):
		return
	if not await _capture_return_and_commit(capture_dir):
		return
	if not await _capture_payoff(capture_dir):
		return
	print("Saved Expansion 13 scanner-cutter correction captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_correction_state() -> bool:
	_artifact = _survey_by_id(ARTIFACT_ID)
	_payoff = _tool_target_by_id(PAYOFF_ID)
	if _artifact.is_empty() or _payoff.is_empty():
		_fail("physical blueprint artifact or remembered sealed target is missing")
		return false
	for capability_id in [
		ScannerCorrectionProfileState.PROPULSION_FINS_CAPABILITY_ID,
		ScannerCorrectionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
	]:
		var prepared: Dictionary = ReviewProgressionFixture.complete_capability(_main, capability_id)
		if not bool(prepared.get("ready", false)):
			_fail("could not prepare prerequisite %s: %s" % [capability_id, str(prepared)])
			return false
	_refresh_runtime_sources()
	_scanner_pose = ScannerPose.new().find_pose(_main._world, _artifact)
	if not bool(_scanner_pose.get("found", false)):
		_fail("physical artifact has no collision-clear scanner pose")
		return false
	var artifact_anchor: Vector2 = _artifact.get("scan_anchor_world", _artifact.get("center", Vector2.ZERO))
	var payoff_center: Vector2 = _payoff.get("center", artifact_anchor)
	_artifact_frame = _frame_for_world((artifact_anchor + payoff_center) * 0.5, ARTIFACT_ZOOM)
	_main._last_status_note = ""
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	_main._update_status_label()
	return _expect(
		_main._anomaly_survey.has_scanner()
		and not _main._anomaly_survey.profile_state().has_completed_discovery(BLUEPRINT_ID)
		and not _main._progression_project_tracker.visible,
		"fresh correction capture exposed cutter knowledge or recipe early"
	)


func _capture_artifact_sequence(capture_dir: String) -> bool:
	var off_axis := _off_axis_pose()
	if off_axis.is_empty():
		_fail("could not find an open off-axis scanner pose")
		return false
	_place_player(off_axis)
	_main._last_status_note = ""
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	_main._update_status_label()
	if not _expect(
		_main._anomaly_survey.overlay_text(_main._world, _main._player) == OPENING_LEAD
		and not bool(_main._player.get_scanner_presentation_report().get("visible", false)),
		"broad artifact clue was not readable before a deliberate pulse"
	):
		return false
	if not await _capture_pair(capture_dir, "broad_artifact_clue", _artifact_frame):
		return false

	var miss: Dictionary = _main._anomaly_survey.scanner_action(_main._world, _main._player)
	_main._player.show_scanner_action(miss, _main._anomaly_survey.report())
	_main._last_status_note = str(miss.get("note", ""))
	_main._update_status_label()
	var miss_presentation: Dictionary = _main._player.get_scanner_presentation_report()
	if not _expect(
		str(miss.get("reason", "")) == "ready"
		and bool(miss_presentation.get("visible", false))
		and not bool(miss_presentation.get("target_visible", false)),
		"off-axis pulse acquired a target or failed to show the scanner field"
	):
		return false
	if not await _capture_pair(capture_dir, "scanner_miss_off_axis", _artifact_frame):
		return false

	_place_player(_scanner_pose)
	var activation: Dictionary = _main._anomaly_survey.scanner_action(_main._world, _main._player)
	_main._player.show_scanner_action(activation, _main._anomaly_survey.report())
	_main._last_status_note = str(activation.get("note", ""))
	_main._update_status_label()
	var acquired: Dictionary = _main._player.get_scanner_presentation_report()
	if not _expect(
		str(activation.get("reason", "")) == "activated"
		and bool(acquired.get("visible", false))
		and bool(acquired.get("target_visible", false))
		and str(acquired.get("target_id", "")) == ARTIFACT_ID,
		"eligible artifact did not show the cone and target bracket"
	):
		return false
	if not await _capture_pair(capture_dir, "artifact_acquired", _artifact_frame):
		return false

	var partial: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, ARTIFACT_PARTIAL_SECONDS)
	_main._last_status_note = str(partial.get("note", ""))
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	_main._update_status_label()
	var progress := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	var progress_presentation: Dictionary = _main._player.get_scanner_presentation_report()
	if not _expect(
		progress >= 0.49 and progress <= 0.51
		and bool(progress_presentation.get("target_visible", false))
		and absf(float(progress_presentation.get("progress", 0.0)) - progress) <= 0.01,
		"artifact capture did not hold meaningful visible scan progress"
	):
		return false
	return await _capture_pair(capture_dir, "artifact_scan_progress", _artifact_frame)


func _capture_return_and_commit(capture_dir: String) -> bool:
	var remaining := maxf(0.01, float(_artifact.get("interaction_seconds", 0.0)) - ARTIFACT_PARTIAL_SECONDS + 0.01)
	var pending: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, remaining)
	if str(pending.get("reason", "")) != "pending_created":
		_fail("completed artifact scan did not create pending blueprint knowledge")
		return false
	var approach_camera := _camera_test_by_id(BOAT_APPROACH_CAMERA_ID)
	if approach_camera.is_empty():
		_fail("pending-return camera is missing")
		return false
	_place_player({"origin": _camera_center(approach_camera), "facing_sign": 1.0})
	_main._last_status_note = str(pending.get("note", ""))
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	_main._update_status_label()
	if not _expect(
		_main._anomaly_survey.has_pending_discovery()
		and not _main._world.is_inside_boat(_main._player.global_position)
		and _main._status_label.text.find("Blueprint pending | Return to surface boat") != -1,
		"pending artifact knowledge did not point to the canonical boat"
	):
		return false
	if not await _capture_pair(capture_dir, "pending_boat_return", approach_camera):
		return false

	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	_main._player.reset_motion()
	var commit: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, 0.0)
	_main._last_status_note = str(commit.get("note", ""))
	_main._material_project.on_map_loaded(_main._world)
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	_main._update_status_label()
	var tracker_text: String = _main._progression_project_tracker.snapshot_text()
	if not _expect(
		bool(commit.get("committed", false))
		and _main._anomaly_survey.profile_state().has_completed_discovery(BLUEPRINT_ID)
		and _main._progression_project_tracker.visible
		and tracker_text.find("Titanium  0/2") != -1
		and tracker_text.find("Coil  0/1") != -1,
		"boat commitment did not reveal the exact cutter recipe tracker: %s" % tracker_text
	):
		return false
	var boat_camera := _camera_test_by_id(BOAT_CAMERA_ID)
	if boat_camera.is_empty():
		_fail("canonical boat camera is missing")
		return false
	return await _capture_pair(capture_dir, "cutter_blueprint_committed", boat_camera)


func _capture_payoff(capture_dir: String) -> bool:
	var built: Dictionary = ReviewProgressionFixture.complete_capability(_main, CUTTER_CAPABILITY_ID)
	if not bool(built.get("ready", false)):
		_fail("could not prepare the already-reviewed night cutter result: %s" % str(built))
		return false
	_main._material_project.on_map_loaded(_main._world)
	_main._cutter_salvage.on_map_loaded(_main._world)
	_main._player.global_position = _payoff.get("center", Vector2.ZERO)
	_main._player.reset_motion()
	_main._cargo_collection.update(float(_payoff.get("interaction_seconds", 0.0)) + 0.05)
	_main._update_status_label()
	if not _expect(
		_main._world.is_salvage_collected(PAYOFF_ID)
		and _main._sortie_state.held_salvage_ids.has(PAYOFF_ID)
		and _main._last_status_note == "Sealed wreck opened +300"
		and _main._anomaly_survey.overlay_text(_main._world, _main._player) == NEXT_MYSTERY,
		"post-build sealed target did not show its concrete payoff and next mystery"
	):
		return false
	return await _capture_pair(capture_dir, "sealed_target_payoff", _artifact_frame)


func _off_axis_pose() -> Dictionary:
	var anchor: Vector2 = _artifact.get("scan_anchor_world", _artifact.get("center", Vector2.ZERO))
	var base_origin: Vector2 = _scanner_pose.get("origin", Vector2.ZERO)
	var facing_sign := float(_scanner_pose.get("facing_sign", 1.0))
	var targeting := ScannerConeTargeting.new()
	for vertical_tiles in [-3.0, 3.0, -2.0, 2.0]:
		var origin := base_origin + Vector2(0.0, vertical_tiles * float(_main._world.tile_size))
		var report: Dictionary = targeting.evaluate_target(_main._world, origin, facing_sign, _artifact)
		if str(report.get("reason", "")) == "off_axis" and _main._world.has_clear_terrain_line(origin, origin):
			return {"origin": origin, "facing_sign": facing_sign, "anchor": anchor}
	return {}


func _place_player(pose: Dictionary) -> void:
	var origin: Vector2 = pose.get("origin", Vector2.ZERO)
	var facing_sign := float(pose.get("facing_sign", 1.0))
	_main._player.global_position = origin
	_main._player.swim_in_direction(Vector2(facing_sign, 0.0), 0.0)
	_main._player.global_position = origin
	_main._player.reset_motion()


func _frame_for_world(center: Vector2, zoom: float) -> Dictionary:
	return {
		"center_x": center.x / float(_main._world.tile_size),
		"center_y": center.y / float(_main._world.tile_size),
		"zoom": zoom,
	}


func _camera_test_by_id(camera_id: String) -> Dictionary:
	for camera_test in _main._world.camera_tests:
		if str(camera_test.get("id", "")) == camera_id:
			return camera_test
	return {}


func _camera_center(camera_test: Dictionary) -> Vector2:
	return Vector2(
		float(camera_test.get("center_x", 0.0)),
		float(camera_test.get("center_y", 0.0))
	) * float(_main._world.tile_size)


func _fail(message: String) -> void:
	push_error("Expansion 13 scanner-cutter correction capture failed: %s." % message)
	_main.get_tree().quit(1)
