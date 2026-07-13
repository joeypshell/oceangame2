extends RefCounted

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayPresentation := preload("res://scripts/main/expedition_day_presentation.gd")

const CAPTURE_SIZES := [
	{"suffix": "1280x720", "size": Vector2i(1280, 720)},
	{"suffix": "1920x1080", "size": Vector2i(1920, 1080)},
]
const CONDITION_ID := "southwest_jellyfish_bloom"
const BONUS_ID := "material_coil_southwest_bloom"
const MIGRATION_ID := "southwest_bloom_jellyfish_patrol"
const FORECAST_ZOOM := Vector2(1.0, 1.0)
const BLOOM_ZOOM := Vector2(1.35, 1.35)

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_day_one():
		return
	_camera = _create_camera()
	if not await _capture_night_forecast(capture_dir):
		return
	if not await _capture_active_bloom(capture_dir):
		return
	print("Saved Expansion 08 daily-condition review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _capture_night_forecast(capture_dir: String) -> bool:
	_main._player.global_position = _main._world.get_extraction_center()
	var request: Dictionary = ExpeditionDayPresentation.try_request_voluntary_end(_main)
	if not bool(request.get("requested", false)):
		_fail("could not enter the day-one debrief")
		return false
	_main._process(0.0)
	_main._update_status_label()
	var debrief_text: String = _main._result_label.text if _main._result_label != null else ""
	if (
		debrief_text.find("Night 1") == -1
		or debrief_text.find("Tomorrow: Southwest jellyfish bloom") == -1
		or debrief_text.find("N: Start day 2") == -1
	):
		_fail("night debrief omitted the day, bloom forecast, or next-day action")
		return false
	var boat_center: Vector2 = _main._world.get_extraction_center()
	return await _capture_pair(capture_dir, "night_forecast", boat_center + Vector2(96, 128), FORECAST_ZOOM)


func _capture_active_bloom(capture_dir: String) -> bool:
	ExpeditionDayDebrief.handle_day_key(_main)
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false
	_main._last_status_note = ""
	var condition_report: Dictionary = _main._daily_conditions.report()
	var bonus := _material_candidate(BONUS_ID)
	var migration := _moving_hazard(MIGRATION_ID)
	if (
		condition_report.get("current_condition_ids", []) != [CONDITION_ID]
		or bonus.is_empty()
		or migration.is_empty()
		or not _main._world.get_material_candidate_report().get("active_ids", []).has(BONUS_ID)
	):
		_fail("day-two bloom records were not active")
		return false

	var path: Array = migration.get("path", [])
	if path.size() < 2:
		_fail("migration patrol path is missing")
		return false
	var path_start: Vector2 = path[0]
	var path_end: Vector2 = path[path.size() - 1]
	_main._player.global_position = path_start + Vector2(80, 0)
	_main._process(0.5)
	_main._update_status_label()
	var status: String = _main._status_label.text if _main._status_label != null else ""
	if (
		status.find("Southwest bloom: jellyfish + coil trace") == -1
		or not _main._world.get_material_candidate_report().get("active_ids", []).has(BONUS_ID)
		or _main._material_runtime.held_count() != 0
	):
		_fail("active bloom HUD or uncollected bonus state was not readable")
		return false
	var camera_position := path_start.lerp(path_end, 0.5) + Vector2(0, 32)
	return await _capture_pair(capture_dir, "active_bloom", camera_position, BLOOM_ZOOM)


func _prepare_day_one() -> bool:
	if _main._world == null or _main._player == null:
		_fail("requires a loaded playable map")
		return false
	_main._expedition_day_state.begin_day(1)
	_main._load_playable_map(_main.PRODUCTION_SLICE_MAP_PATH, false)
	if _main._world.map_id != "production_slice_01":
		_fail("requires the default production slice")
		return false
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false
	var condition_report: Dictionary = _main._daily_conditions.report()
	if (
		not condition_report.get("current_condition_ids", []).is_empty()
		or condition_report.get("next_condition_ids", []) != [CONDITION_ID]
	):
		_fail("day-one condition state is not baseline-to-bloom")
		return false
	return true


func _material_candidate(candidate_id: String) -> Dictionary:
	for candidate in _main._world.get_material_candidates():
		if str(candidate.get("id", "")) == candidate_id:
			return candidate
	return {}


func _moving_hazard(hazard_id: String) -> Dictionary:
	for hazard in _main._world.get_moving_hazards():
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "Expansion08DailyConditionCaptureCamera"
	camera.position_smoothing_enabled = false
	_main.add_child(camera)
	camera.make_current()
	return camera


func _capture_pair(capture_dir: String, state_id: String, camera_position: Vector2, camera_zoom: Vector2) -> bool:
	_frame_camera(camera_position, camera_zoom)
	for capture_spec in CAPTURE_SIZES:
		var expected_size: Vector2i = capture_spec["size"]
		_main.get_window().size = expected_size
		_camera.force_update_scroll()
		await _settle_frames()
		var image: Image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			await _settle_frames()
			image = _main.get_viewport().get_texture().get_image()
		if image.get_size() != expected_size:
			_fail("capture %s rendered %s expected %s" % [state_id, str(image.get_size()), str(expected_size)])
			return false
		if not _image_is_usable(image, expected_size):
			_fail("capture %s appears blank or contains black render regions" % state_id)
			return false
		var filename := "production_slice_01_%s_%s.png" % [state_id, str(capture_spec["suffix"])]
		if not _save_capture(capture_dir, filename, image):
			return false
	return true


func _frame_camera(position: Vector2, zoom: Vector2) -> void:
	_camera.zoom = zoom
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_main._world.map_pixel_size.x)
	_camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_camera.position = position
	_camera.make_current()


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
	print("Saved Expansion 08 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Expansion 08 daily-condition capture failed: %s." % message)
	_main.get_tree().quit(1)
