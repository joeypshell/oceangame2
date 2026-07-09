extends RefCounted

const Pass08RouteExtensionCapture := preload("res://scripts/main/captures/pass_08_route_extension_capture.gd")
const Pass09SouthwestPocketDecisionCapture := preload("res://scripts/main/captures/pass_09_southwest_pocket_decision_capture.gd")
const Pass10ReturnPressureCapture := preload("res://scripts/main/captures/pass_10_return_pressure_capture.gd")
const Pass11PrePickupRouteCueCapture := preload("res://scripts/main/captures/pass_11_pre_pickup_route_cue_capture.gd")
const Pass12OxygenRestCapture := preload("res://scripts/main/captures/pass_12_oxygen_rest_capture.gd")
const Pass13RouteCommitmentCapture := preload("res://scripts/main/captures/pass_13_route_commitment_capture.gd")
const Pass14ObjectiveCueCapture := preload("res://scripts/main/captures/pass_14_objective_cue_capture.gd")
const Pass15ObjectiveFollowThroughCapture := preload("res://scripts/main/captures/pass_15_objective_follow_through_capture.gd")
const Pass18ProgressionCapture := preload("res://scripts/main/captures/pass_18_progression_capture.gd")
const Pass19CargoUpgradeCapture := preload("res://scripts/main/captures/pass_19_cargo_upgrade_capture.gd")
const PrimaryDiveCompletionCapture := preload("res://scripts/main/captures/primary_dive_completion_capture.gd")
const SCREENSHOT_PATH := "res://visual_baselines/001_greybox_in_engine.png"
const CAPTURE_ZOOM := Vector2(0.7, 0.7)
const PLAYER_READABILITY_CAPTURE_ZOOM := Vector2(2.0, 2.0)
const PLAYER_READABILITY_ENTRY_OFFSET_TILES := Vector2(0, 5)
const BACKGROUND_DEPTH_CAPTURE_ZOOM := Vector2(0.52, 0.52)
const BACKGROUND_DEPTH_CENTER_TILES := Vector2(39, 24)
const BACKGROUND_DEPTH_PLAYER_OFFSET_TILES := Vector2(0, 8)
const TIMED_SALVAGE_CAPTURE_ZOOM := Vector2(1.15, 1.15)
const TIMED_SALVAGE_PROGRESS_RATIO := 0.52
const PRY_SALVAGE_CAPTURE_ZOOM := Vector2(1.15, 1.15)
const PRY_SALVAGE_PROGRESS_RATIO := 0.45
const HAZARD_PRESSURE_CAPTURE_ZOOM := Vector2(0.68, 0.68)
const HAZARD_PRESSURE_WARNING_OFFSET_TILES := Vector2.DOWN
const HAZARD_PRESSURE_SETUP_SALVAGE_ID := "salvage_lower_loop"
const HAZARD_PRESSURE_PAYOFF_SALVAGE_ID := "salvage_deep_right_cache"
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


func capture_pry_salvage_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pry salvage capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var target := _pry_salvage_target()
	if target.is_empty():
		push_error("Pry salvage capture requires an authored pry_salvage target.")
		_main.get_tree().quit(1)
		return

	var target_center: Vector2 = target["center"]
	var interaction_seconds := maxf(0.01, float(target.get("interaction_seconds", 0.0)))
	_main._player.global_position = target_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(interaction_seconds * PRY_SALVAGE_PROGRESS_RATIO)
	_main._update_status_label()
	if _main._status_label == null or _main._status_label.text.find("Prying") == -1:
		push_error("Pry salvage capture expected visible pry progress before saving.")
		_main.get_tree().quit(1)
		return
	_main.set_process(false)

	var camera := Camera2D.new()
	camera.name = "PrySalvageCaptureCamera"
	camera.zoom = PRY_SALVAGE_CAPTURE_ZOOM
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
	var output_path := "%s/%s_pry_salvage.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved pry salvage capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func capture_hazard_pressure_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Hazard pressure capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var segment: Dictionary = _main._world.get_marker_zone(_main.PASS_07_PRESSURE_SEGMENT_ID)
	var setup_salvage: Dictionary = _salvage_by_id(HAZARD_PRESSURE_SETUP_SALVAGE_ID)
	var payoff_salvage: Dictionary = _salvage_by_id(HAZARD_PRESSURE_PAYOFF_SALVAGE_ID)
	var hazard: Dictionary = _hazard_by_id(_main.PASS_07_PRESSURE_HAZARD_ID)
	if segment.is_empty() or setup_salvage.is_empty() or payoff_salvage.is_empty() or hazard.is_empty():
		push_error("Hazard pressure capture requires Pass 07 segment, setup salvage, payoff salvage, and hazard source data.")
		_main.get_tree().quit(1)
		return

	_main._player.global_position = setup_salvage["center"]
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)

	var hazard_center: Vector2 = hazard["center"]
	var warning_position := hazard_center + HAZARD_PRESSURE_WARNING_OFFSET_TILES * float(_main._world.tile_size)
	var warning_hazard: Dictionary = _main._world.get_nearest_hazard_within(warning_position, _main.HAZARD_WARNING_RADIUS)
	if str(warning_hazard.get("id", "")) != _main.PASS_07_PRESSURE_HAZARD_ID or not _main._world.get_hazard_near(warning_position, _main.HAZARD_CONTACT_RADIUS).is_empty():
		push_error("Hazard pressure capture could not place player in warning-only range for %s." % _main.PASS_07_PRESSURE_HAZARD_ID)
		_main.get_tree().quit(1)
		return

	_main._player.global_position = warning_position
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._hazard_cooldown_seconds = 0.0
	_main._process(0.0)
	if _main._hazard_warning_id != _main.PASS_07_PRESSURE_HAZARD_ID or _main._status_label == null or _main._status_label.text.find(_main.PRESSURE_HAZARD_WARNING_PROMPT) == -1:
		push_error("Hazard pressure capture expected selected warning prompt before saving.")
		_main.get_tree().quit(1)
		return
	_main.set_process(false)

	var camera := Camera2D.new()
	camera.name = "HazardPressureCaptureCamera"
	camera.zoom = HAZARD_PRESSURE_CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = (setup_salvage["center"] + hazard_center + payoff_salvage["center"]) / 3.0 + Vector2(16, -8)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_hazard_pressure.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved hazard pressure capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func capture_route_extension_and_quit(capture_dir: String) -> void:
	var capture := Pass08RouteExtensionCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func capture_southwest_pocket_decision_and_quit(capture_dir: String) -> void:
	var capture := Pass09SouthwestPocketDecisionCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func capture_pass_10_return_pressure_and_quit(capture_dir: String) -> void:
	var capture := Pass10ReturnPressureCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func capture_pass_11_pre_pickup_route_cue_and_quit(capture_dir: String) -> void:
	var capture := Pass11PrePickupRouteCueCapture.new(_main)
	await capture.capture_and_quit(capture_dir)

func capture_pass_12_oxygen_rest_pressure_and_quit(capture_dir: String) -> void:
	var capture := Pass12OxygenRestCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func capture_pass_13_route_commitment_and_quit(capture_dir: String) -> void:
	var capture := Pass13RouteCommitmentCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func capture_pass_14_objective_cue_and_quit(capture_dir: String) -> void:
	var capture := Pass14ObjectiveCueCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func capture_pass_15_objective_follow_through_and_quit(capture_dir: String) -> void:
	var capture := Pass15ObjectiveFollowThroughCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func capture_pass_18_progression_and_quit(capture_dir: String) -> void:
	var capture := Pass18ProgressionCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func capture_pass_19_cargo_upgrade_and_quit(capture_dir: String) -> void:
	var capture := Pass19CargoUpgradeCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func capture_primary_dive_completion_and_quit(capture_dir: String) -> void:
	var capture := PrimaryDiveCompletionCapture.new(_main)
	await capture.capture_and_quit(capture_dir)


func _timed_salvage_target() -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "timed_salvage":
			return salvage
	return {}

func _pry_salvage_target() -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "pry_salvage":
			return salvage
	return {}

func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}

func _hazard_by_id(hazard_id: String) -> Dictionary:
	for hazard in _main._world.get_hazard_centers():
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}

func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
