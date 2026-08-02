extends RefCounted

const MAP_ID := "production_level_01"
const CAMERA_ID_PREFIX := "production_level_"
const ENTRY_TARGET_ID := "salvage_entry_shaft"
const BOAT_ENTRY_ID := "surface_boat_entry"
const EXPECTED_CONTEXT_IDS := [
	"production_level_overview",
	"production_level_boat_entry",
	"production_level_opening_gameplay",
	"production_level_upper_left",
	"production_level_lower_left",
	"production_level_lower_right",
	"production_level_return_to_boat",
]
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
	var camera_tests := _candidate_camera_tests()
	if not _camera_tests_are_complete(camera_tests):
		return
	for camera_test in camera_tests:
		var view_id := str(camera_test.get("id", ""))
		if not _prepare_context(view_id, camera_test):
			return
		if not await _capture_sizes(capture_dir, view_id, camera_test):
			return
	print("Saved Expansion 09 full-level review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != MAP_ID:
		_fail("requires the contiguous production-level candidate")
		return false
	var connectors: Array = _main._world.get_world_connectors()
	if (
		connectors.size() != 1
		or str(connectors[0].get("id", "")) != "transfer_hub_exterior_entrance"
		or str(connectors[0].get("destination_map_id", "")) != "transfer_hub_interior_01"
		or str(connectors[0].get("connector_direction", "")) != "forward"
	):
		_fail("candidate exceptional-interior connector contract drifted")
		return false
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false
	_main._last_status_note = ""
	_main._update_status_label()
	return true


func _candidate_camera_tests() -> Array:
	var candidate_tests := []
	for camera_test in _main._world.camera_tests:
		if str(camera_test.get("id", "")).begins_with(CAMERA_ID_PREFIX):
			candidate_tests.append(camera_test)
	return candidate_tests


func _camera_tests_are_complete(camera_tests: Array) -> bool:
	var actual_ids := []
	for camera_test in camera_tests:
		actual_ids.append(str(camera_test.get("id", "")))
	if actual_ids != EXPECTED_CONTEXT_IDS:
		_fail("authored camera contexts drifted: %s" % str(actual_ids))
		return false
	return true


func _prepare_context(view_id: String, camera_test: Dictionary) -> bool:
	var tile_size: float = float(_main._world.tile_size)
	var camera_center := Vector2(
		float(camera_test.get("center_x", 0.0)) * tile_size,
		float(camera_test.get("center_y", 0.0)) * tile_size
	)
	match view_id:
		"production_level_overview", "production_level_boat_entry":
			_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
		"production_level_return_to_boat":
			if not _prepare_return_cargo():
				return false
			_main._player.global_position = camera_center
		_:
			_main._player.global_position = camera_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	if _main._player.has_method("snap_camera"):
		_main._player.snap_camera()
	_main._update_status_label()
	return true


func _prepare_return_cargo() -> bool:
	if _main._world.is_salvage_collected(ENTRY_TARGET_ID):
		return true
	if not _main._world.collect_salvage_by_id(ENTRY_TARGET_ID):
		_fail("could not collect the transformed entry target for return context")
		return false
	_main._collect_salvage_into_cargo(ENTRY_TARGET_ID)
	return true


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "Expansion09FullLevelCaptureCamera"
	camera.position_smoothing_enabled = false
	_main.add_child(camera)
	camera.make_current()
	return camera


func _capture_sizes(capture_dir: String, view_id: String, camera_test: Dictionary) -> bool:
	for spec in CAPTURE_SIZES:
		var window_size: Vector2i = spec["window_size"]
		var expected_size: Vector2i = spec["canvas_size"]
		_main.get_window().size = window_size
		_frame_camera(camera_test, expected_size)
		await _settle_frames()
		var image: Image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			await _settle_frames()
			image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			_fail("capture %s rendered blank or wrong-sized image %s" % [view_id, str(image.get_size())])
			return false
		var filename := "%s_%s.png" % [view_id, str(spec["suffix"])]
		if not _save_capture(capture_dir, filename, image):
			return false
	return true


func _frame_camera(camera_test: Dictionary, viewport_size: Vector2i) -> void:
	var tile_size: float = float(_main._world.tile_size)
	var zoom := float(camera_test.get("zoom", 0.5))
	if str(camera_test.get("id", "")) == "production_level_overview":
		var fit_zoom := minf(
			float(viewport_size.x) / _main._world.map_pixel_size.x,
			float(viewport_size.y) / _main._world.map_pixel_size.y
		) * 0.94
		zoom = minf(zoom, fit_zoom)
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
	print("Saved Expansion 09 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Expansion 09 full-level capture failed: %s." % message)
	_main.get_tree().quit(1)
