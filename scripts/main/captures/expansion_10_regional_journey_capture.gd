extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const MAP_ID := "production_level_01"
const PROMISE_GATE_ID := "upper_right_current_pocket_gate"
const REGIONAL_GATE_ID := "lower_right_west_current_gate"
const SURVEY_TARGET_ID := "lower_right_signal_reef_survey"
const CAMERA_IDS := {
	"pre_fins_current_promise": "expansion_10_current_promise",
	"post_fins_regional_entry": "expansion_10_lower_right_entry",
	"signal_reef_pending_return": "expansion_10_signal_reef",
}
const CAPTURE_SIZES := [
	{"suffix": "1280x720", "window_size": Vector2i(1280, 720), "canvas_size": Vector2i(1280, 720)},
	{"suffix": "mobile_844x390", "window_size": Vector2i(844, 390), "canvas_size": Vector2i(693, 390)},
]

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
		_fail("authored Expansion 10 camera tests are incomplete: %s" % str(camera_tests.keys()))
		return
	if not _prepare_pre_fins_state():
		return
	if not await _capture_pair(capture_dir, "pre_fins_current_promise", camera_tests[CAMERA_IDS["pre_fins_current_promise"]]):
		return
	if not _prepare_post_fins_state():
		return
	if not await _capture_pair(capture_dir, "post_fins_regional_entry", camera_tests[CAMERA_IDS["post_fins_regional_entry"]]):
		return
	if not _prepare_pending_survey_state():
		return
	if not await _capture_pair(capture_dir, "signal_reef_pending_return", camera_tests[CAMERA_IDS["signal_reef_pending_return"]]):
		return
	print("Saved Expansion 10 regional journey captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != MAP_ID:
		_fail("requires the contiguous production level")
		return false
	if not _main._world.get_world_connectors().is_empty():
		_fail("full level unexpectedly contains connectors")
		return false
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false
	return true


func _prepare_pre_fins_state() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var gate := _gate_by_id(PROMISE_GATE_ID)
	if gate.is_empty() or profile.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID):
		_fail("pre-fins promise state is unavailable")
		return false
	_main._current_gate.reset()
	_main._player.global_position = gate["center"]
	_main._player.reset_motion()
	_main._last_status_note = ""
	_main._process(0.0)
	var status := _status_text()
	if status.find("Strong east current - need propulsion fins | larger route beyond") == -1:
		_fail("pre-fins promise feedback is unclear: %s" % status)
		return false
	return true


func _prepare_post_fins_state() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var blueprint: Dictionary = profile.complete_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID, false)
	var deposit: Dictionary = profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	}, false)
	var project := _project_by_id(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID)
	var build: Dictionary = profile.complete_material_project(project, false)
	if not bool(blueprint.get("changed", false)) or not bool(deposit.get("changed", false)) or not bool(build.get("changed", false)):
		_fail("could not prepare recipe-built fins: %s %s %s" % [str(blueprint), str(deposit), str(build)])
		return false
	var gate := _gate_by_id(REGIONAL_GATE_ID)
	if gate.is_empty():
		_fail("missing regional current %s" % REGIONAL_GATE_ID)
		return false
	_main._material_project.on_map_loaded(_main._world)
	_main._current_gate.reset()
	_main._player.global_position = gate["center"]
	_main._player.reset_motion()
	_main._last_status_note = str(project.get("completion_label", "Fins installed - east current passable"))
	_main._update_status_label()
	var blocked: Dictionary = _main._current_gate.gate_blocks_position(
		_main._world,
		_main._player.global_position,
		Callable(_main, "_has_upgrade_id"),
		Callable(profile, "has_capability")
	)
	if not blocked.is_empty() or _status_text().find("Fins installed") == -1:
		_fail("post-fins regional entry is not readable: %s" % _status_text())
		return false
	return true


func _prepare_pending_survey_state() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var unlock: Dictionary = profile.unlock_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID, false)
	if not bool(unlock.get("changed", false)):
		_fail("could not prepare scanner capability: %s" % str(unlock))
		return false
	_main._anomaly_survey.on_map_loaded(_main._world)
	var target := _survey_by_id(SURVEY_TARGET_ID)
	if target.is_empty():
		_fail("missing Signal Reef target %s" % SURVEY_TARGET_ID)
		return false
	_main._player.global_position = target["center"]
	_main._player.reset_motion()
	_main._last_status_note = ""
	_main._process(0.0)
	_main._process(float(target.get("interaction_seconds", 0.0)) + 0.01)
	var status := _status_text()
	if not _main._anomaly_survey.has_pending_discovery() or status.to_lower().find("return to surface boat") == -1:
		_fail("Signal Reef payoff did not present pending return feedback: %s" % status)
		return false
	if profile.has_completed_discovery(str(target.get("discovery_id", ""))):
		_fail("capture setup committed the discovery away from the boat")
		return false
	return true


func _camera_tests_by_id() -> Dictionary:
	var values := {}
	for camera_test in _main._world.camera_tests:
		var camera_id := str(camera_test.get("id", ""))
		if CAMERA_IDS.values().has(camera_id):
			values[camera_id] = camera_test
	return values


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "Expansion10RegionalJourneyCaptureCamera"
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
	print("Saved Expansion 10 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _status_text() -> String:
	return _main._status_label.text if _main._status_label != null else ""


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _main._world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _main._world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _survey_by_id(target_id: String) -> Dictionary:
	for target in _main._world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _fail(message: String) -> void:
	push_error("Expansion 10 regional journey capture failed: %s." % message)
	_main.get_tree().quit(1)
