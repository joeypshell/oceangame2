extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")
const ScannerPose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")

const MAP_ID := "production_level_01"
const RECORDER_ID := "southeast_wreck_recorder"
const SURVEY_ID := "southeast_wreck_archive_survey"
const CAMERA_IDS := {
	"wreck_promise": "expansion_13_wreck_promise",
	"wreck_arrival": "expansion_13_wreck_arrival",
	"recorder_cut": "expansion_13_recorder_cut",
	"archive_survey": "expansion_13_archive_survey",
	"pending_boat_return": "expansion_13_pending_boat_return",
}
const CAPTURE_SIZES := [
	{"suffix": "1280x720", "window_size": Vector2i(1280, 720), "canvas_size": Vector2i(1280, 720)},
	{"suffix": "mobile_844x390", "window_size": Vector2i(844, 390), "canvas_size": Vector2i(693, 390)},
]
const PARTIAL_SECONDS := 1.0
const SURVEY_PARTIAL_SECONDS := 1.5

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_camera = _create_camera()
	var camera_tests := _camera_tests_by_id()
	if camera_tests.size() != CAMERA_IDS.size():
		_fail("authored Expansion 13 camera tests are incomplete: %s" % str(camera_tests.keys()))
		return
	if not _prepare_prerequisite_profile():
		return
	if not _prepare_wreck_promise(camera_tests[CAMERA_IDS["wreck_promise"]]):
		return
	if not await _capture_pair(capture_dir, "wreck_promise", camera_tests[CAMERA_IDS["wreck_promise"]]):
		return
	if not _prepare_cutter_requirement():
		return
	if not await _capture_pair(capture_dir, "wreck_arrival_cutter_required", camera_tests[CAMERA_IDS["wreck_arrival"]]):
		return
	if not _prepare_partial_cut():
		return
	if not await _capture_pair(capture_dir, "recorder_cut_progress", camera_tests[CAMERA_IDS["recorder_cut"]]):
		return
	if not _prepare_partial_survey():
		return
	if not await _capture_pair(capture_dir, "archive_survey_progress", camera_tests[CAMERA_IDS["archive_survey"]]):
		return
	if not _prepare_pending_return(camera_tests[CAMERA_IDS["pending_boat_return"]]):
		return
	if not await _capture_pair(capture_dir, "pending_boat_return", camera_tests[CAMERA_IDS["pending_boat_return"]]):
		return
	print("Saved Expansion 13 southeast-wreck captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != MAP_ID:
		_fail("requires the contiguous production level")
		return false
	var connectors: Array = _main._world.get_world_connectors()
	if (
		connectors.size() != 1
		or str(connectors[0].get("id", "")) != "transfer_hub_exterior_entrance"
		or str(connectors[0].get("destination_map_id", "")) != "transfer_hub_interior_01"
		or str(connectors[0].get("connector_direction", "")) != "forward"
	):
		_fail("full-level exceptional-interior connector contract drifted")
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
	_prepare_runtime_nodes()
	return true


func _prepare_runtime_nodes() -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._player.reset_motion()
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false


func _prepare_prerequisite_profile() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	for capability_id in [
		ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID,
		ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID,
	]:
		var prepared: Dictionary = ReviewProgressionFixture.complete_capability(_main, capability_id)
		if not bool(prepared.get("ready", false)):
			_fail("could not prepare %s" % capability_id)
			return false
	var light: Dictionary = ReviewProgressionFixture.complete_dive_light(_main)
	if not bool(light.get("ready", false)):
		_fail("could not prepare the already-earned dive light")
		return false
	var prerequisite: Dictionary = profile.complete_discovery(
		ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID,
		false
	)
	if not bool(prerequisite.get("changed", false)):
		_fail("could not prepare the committed abyssal wreck lead")
		return false
	_refresh_runtime_sources()
	return _expect(
		profile.has_completed_discovery(ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID)
		and not profile.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID)
		and not profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID),
		"prerequisite setup unlocked the cutter or southeast finding early"
	)


func _refresh_runtime_sources() -> void:
	_main._material_project.on_map_loaded(_main._world)
	_main._anomaly_survey.on_map_loaded(_main._world)
	_main._cutter_salvage.on_map_loaded(_main._world)
	_main._pressure_zone.on_map_loaded(_main._world)
	_main._current_gate.reset()


func _prepare_wreck_promise(camera_test: Dictionary) -> bool:
	_set_player_to_camera_center(camera_test)
	_main._last_status_note = ""
	_main._update_status_label()
	return _expect(
		_status_text().find("Abyssal chart | Southeast wreck echo") != -1,
		"committed abyssal finding omitted the broad wreck promise"
	)


func _prepare_cutter_requirement() -> bool:
	var recorder := _tool_target_by_id(RECORDER_ID)
	if recorder.is_empty():
		_fail("source-authored wreck recorder is missing")
		return false
	_main._player.global_position = recorder.get("center", Vector2.ZERO)
	_main._player.reset_motion()
	_main._last_status_note = ""
	_main._cargo_collection.update(0.0)
	_main._update_status_label()
	return _expect(
		not _main._world.is_salvage_collected(RECORDER_ID)
		and _status_text().find("Wreck recorder | Cutter required") != -1,
		"arrival did not show the cutter requirement"
	)


func _prepare_partial_cut() -> bool:
	var cutter: Dictionary = ReviewProgressionFixture.complete_capability(
		_main,
		ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID
	)
	if not bool(cutter.get("ready", false)):
		_fail("could not prepare the salvage cutter")
		return false
	_main._material_project.on_map_loaded(_main._world)
	_main._cargo_collection.update(PARTIAL_SECONDS)
	_main._update_status_label()
	var report: Dictionary = _main._cutter_salvage.report()
	return _expect(
		float(report.get("progress_ratio", 0.0)) >= 0.49
		and float(report.get("progress_ratio", 0.0)) <= 0.51
		and _status_text().find("Cutting wreck recorder") != -1,
		"wreck recorder did not hold meaningful cutter progress"
	)


func _prepare_partial_survey() -> bool:
	var recorder := _tool_target_by_id(RECORDER_ID)
	var survey := _survey_by_id(SURVEY_ID)
	if recorder.is_empty() or survey.is_empty():
		_fail("wreck interaction records are missing")
		return false
	_main._cargo_collection.update(float(recorder.get("interaction_seconds", 0.0)))
	if not _main._world.is_salvage_collected(RECORDER_ID):
		_fail("cutter did not expose the wreck archive")
		return false
	var scanner_pose: Dictionary = ScannerPose.new().place(_main._world, _main._player, survey)
	if not bool(scanner_pose.get("found", false)):
		_fail("wreck archive has no collision-clear scanner pose")
		return false
	var activation: Dictionary = _main._anomaly_survey.scanner_action(_main._world, _main._player)
	if str(activation.get("reason", "")) != "activated":
		_fail("explicit scanner action did not activate the wreck survey")
		return false
	var partial: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, SURVEY_PARTIAL_SECONDS)
	_main._last_status_note = str(partial.get("note", ""))
	_main._update_status_label()
	var progress := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	return _expect(
		progress >= 0.49 and progress <= 0.51
		and _status_text().find("Survey wreck archive 50%") != -1
		and not _main._anomaly_survey.has_pending_discovery(),
		"wreck archive did not hold explicit scanner progress"
	)


func _prepare_pending_return(camera_test: Dictionary) -> bool:
	var survey := _survey_by_id(SURVEY_ID)
	var completed: Dictionary = _main._anomaly_survey.update(
		_main._world,
		_main._player,
		float(survey.get("interaction_seconds", 0.0))
	)
	if str(completed.get("reason", "")) != "pending_created":
		_fail("completed wreck survey did not become pending")
		return false
	_set_player_to_camera_center(camera_test)
	_main._last_status_note = str(completed.get("note", ""))
	_main._update_status_label()
	return _expect(
		_main._anomaly_survey.has_pending_discovery()
		and not _main._world.is_inside_boat(_main._player.global_position)
		and _status_text().find("Wreck archive charted | Return to surface boat") != -1,
		"wreck discovery did not remain pending on the canonical-boat approach"
	)


func _camera_tests_by_id() -> Dictionary:
	var values := {}
	var required_ids: Array = CAMERA_IDS.values()
	for camera_test in _main._world.camera_tests:
		var camera_id := str(camera_test.get("id", ""))
		if required_ids.has(camera_id):
			values[camera_id] = camera_test
	return values


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "Expansion13SoutheastWreckCaptureCamera"
	camera.position_smoothing_enabled = false
	_main.add_child(camera)
	camera.make_current()
	return camera


func _capture_pair(capture_dir: String, state_id: String, camera_test: Dictionary) -> bool:
	for spec in CAPTURE_SIZES:
		var window_size: Vector2i = spec["window_size"]
		var expected_size: Vector2i = spec["canvas_size"]
		_main.get_window().size = window_size
		_frame_camera(camera_test)
		await _settle_frames()
		var image: Image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			await _settle_frames()
			image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			_fail("capture %s rendered blank or wrong-sized image %s" % [state_id, str(image.get_size())])
			return false
		var filename := "%s_%s_%s.png" % [MAP_ID, state_id, str(spec["suffix"])]
		if not _save_capture(capture_dir, filename, image):
			return false
	return true


func _frame_camera(camera_test: Dictionary) -> void:
	var tile_size: float = float(_main._world.tile_size)
	var zoom := float(camera_test.get("zoom", 0.5))
	_camera.zoom = Vector2(zoom, zoom)
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_main._world.map_pixel_size.x)
	_camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_camera.position = Vector2(
		float(camera_test.get("center_x", 0.0)) * tile_size,
		float(camera_test.get("center_y", 0.0)) * tile_size
	)
	_camera.make_current()
	_camera.force_update_scroll()


func _set_player_to_camera_center(camera_test: Dictionary) -> void:
	_main._player.global_position = Vector2(
		float(camera_test.get("center_x", 0.0)) * float(_main._world.tile_size),
		float(camera_test.get("center_y", 0.0)) * float(_main._world.tile_size)
	)
	_main._player.reset_motion()


func _settle_frames() -> void:
	RenderingServer.force_draw()
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await RenderingServer.frame_post_draw


func _image_is_usable(image: Image, expected_size: Vector2i) -> bool:
	if image.get_size() != expected_size:
		return false
	var colors := {}
	var black_count := 0
	for x_step in range(1, 8):
		for y_step in range(1, 8):
			var x := int(float(image.get_width() - 1) * float(x_step) / 8.0)
			var y := int(float(image.get_height() - 1) * float(y_step) / 8.0)
			var color := image.get_pixel(x, y)
			colors[color.to_html(true)] = true
			if color.r < 0.01 and color.g < 0.01 and color.b < 0.01:
				black_count += 1
	return colors.size() >= 4 and black_count <= 4


func _save_capture(capture_dir: String, filename: String, image: Image) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s" % [capture_dir, filename]
	var error := image.save_png(output_path)
	if error != OK:
		_fail("could not save %s (error %d)" % [output_path, error])
		return false
	print("Saved Expansion 13 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _tool_target_by_id(target_id: String) -> Dictionary:
	for target in _main._world.get_tool_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _survey_by_id(target_id: String) -> Dictionary:
	for target in _main._world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _status_text() -> String:
	return _main._status_label.text if _main._status_label != null else ""


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("Expansion 13 southeast-wreck capture failed: %s." % message)
	_main.get_tree().quit(1)
