extends RefCounted

const SCREENSHOT_PATH := "res://visual_baselines/001_greybox_in_engine.png"
const CAPTURE_ZOOM := Vector2(0.7, 0.7)
const PLAYER_READABILITY_CAPTURE_ZOOM := Vector2(2.0, 2.0)
const PLAYER_READABILITY_ENTRY_OFFSET_TILES := Vector2(0, 5)
const BACKGROUND_DEPTH_CAPTURE_ZOOM := Vector2(0.52, 0.52)
const BACKGROUND_DEPTH_CENTER_TILES := Vector2(39, 24)
const BACKGROUND_DEPTH_PLAYER_OFFSET_TILES := Vector2(0, 8)
const TIMED_SALVAGE_CAPTURE_ZOOM := Vector2(1.15, 1.15)
const TIMED_SALVAGE_PROGRESS_RATIO := 0.52

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_screenshot_and_quit() -> void:
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://visual_baselines"))
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(SCREENSHOT_PATH)
	print("Saved screenshot: %s" % ProjectSettings.globalize_path(SCREENSHOT_PATH))
	_main.get_tree().quit()


func capture_camera_tests_and_quit(world: Node, capture_dir: String) -> void:
	var camera_tests: Array = world.camera_tests
	if camera_tests.is_empty():
		push_error("No camera_tests found in greybox map source.")
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "VisualCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.map_pixel_size.x)
	camera.limit_bottom = int(world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))

	for camera_test in camera_tests:
		var view_id := _safe_filename(str(camera_test.get("id", "camera_test")))
		var center := Vector2(
			float(camera_test.get("center_x", 0.0)) * world.tile_size,
			float(camera_test.get("center_y", 0.0)) * world.tile_size
		)
		var zoom := float(camera_test.get("zoom", CAPTURE_ZOOM.x))
		camera.zoom = Vector2(zoom, zoom)
		camera.position = center

		await _main.get_tree().process_frame
		await _main.get_tree().process_frame

		var output_path := "%s/%s.png" % [capture_dir, view_id]
		var image: Image = _main.get_viewport().get_texture().get_image()
		image.save_png(output_path)
		print("Saved camera test capture: %s" % ProjectSettings.globalize_path(output_path))

	_main.get_tree().quit()


func capture_player_readability_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Player readability capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var review_position: Vector2 = _main._world.spawn_position + PLAYER_READABILITY_ENTRY_OFFSET_TILES * float(_main._world.tile_size)
	_main._player.global_position = review_position
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()

	var camera := Camera2D.new()
	camera.name = "PlayerReadabilityCaptureCamera"
	camera.zoom = PLAYER_READABILITY_CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = review_position + Vector2(64, -16)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var view_id := "%s_player_start" % _safe_filename(_main._world.map_id)
	var output_path := "%s/%s.png" % [capture_dir, view_id]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved player readability capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func capture_background_depth_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Background depth capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var review_position: Vector2 = _main._world.spawn_position + BACKGROUND_DEPTH_PLAYER_OFFSET_TILES * float(_main._world.tile_size)
	_main._player.global_position = review_position
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()

	var camera := Camera2D.new()
	camera.name = "BackgroundDepthCaptureCamera"
	camera.zoom = BACKGROUND_DEPTH_CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = BACKGROUND_DEPTH_CENTER_TILES * float(_main._world.tile_size)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_background_depth.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved background depth capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func capture_feedback_overlay_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Feedback overlay capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var salvage_centers: Array = _main._world.get_salvage_centers()
	if salvage_centers.is_empty():
		push_error("Feedback overlay capture requires authored salvage.")
		_main.get_tree().quit(1)
		return

	_main._player.global_position = salvage_centers[0]["center"]
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._oxygen_seconds = 12.0
	_main._update_status_label()

	var camera := Camera2D.new()
	camera.name = "FeedbackOverlayCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = _main._world.spawn_position + Vector2(180, 180)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_feedback_overlay.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved feedback overlay capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func capture_route_outcome_result_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Route outcome result capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return
	if _main._total_salvage <= 0:
		push_error("Route outcome result capture requires authored salvage.")
		_main.get_tree().quit(1)
		return

	if not _main._complete_route_outcome_review_state():
		_main.get_tree().quit(1)
		return
	if _main._result_label == null or _main._result_label.text.find("Route:") == -1:
		push_error("Route outcome result capture expected result panel route text before saving: %s" % [_main._result_label.text if _main._result_label != null else ""])
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "RouteOutcomeResultCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = _main._world.spawn_position + Vector2(180, 180)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_route_outcome_result.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved route outcome result capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func capture_timed_salvage_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Timed salvage capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var target := _timed_salvage_target()
	if target.is_empty():
		push_error("Timed salvage capture requires an authored timed_salvage target.")
		_main.get_tree().quit(1)
		return

	var target_center: Vector2 = target["center"]
	var interaction_seconds := maxf(0.01, float(target.get("interaction_seconds", 0.0)))
	_main._player.global_position = target_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(interaction_seconds * TIMED_SALVAGE_PROGRESS_RATIO)
	_main._update_status_label()
	_main.set_process(false)

	var camera := Camera2D.new()
	camera.name = "TimedSalvageCaptureCamera"
	camera.zoom = TIMED_SALVAGE_CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = target_center + Vector2(-32, -24)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_timed_salvage.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved timed salvage capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _timed_salvage_target() -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "timed_salvage":
			return salvage
	return {}


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
