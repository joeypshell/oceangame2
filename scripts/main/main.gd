extends Node2D

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const SCREENSHOT_PATH := "res://visual_baselines/001_greybox_in_engine.png"
const CAMERA_TEST_CAPTURE_DIR := "res://visual_captures/latest"
const CAPTURE_ZOOM := Vector2(0.7, 0.7)


func _ready() -> void:
	var world := WORLD_SCENE.instantiate()
	add_child(world)
	world.load_greybox()

	var player := PLAYER_SCENE.instantiate()
	player.position = world.spawn_position
	add_child(player)

	if player.has_method("set_camera_limits"):
		player.set_camera_limits(Rect2(Vector2.ZERO, world.map_pixel_size))

	var user_args := OS.get_cmdline_user_args()
	var engine_args := OS.get_cmdline_args()
	if "--capture-greybox-screenshot" in user_args or "--capture-greybox-screenshot" in engine_args:
		_capture_screenshot_and_quit()
	elif "--capture-camera-tests" in user_args or "--capture-camera-tests" in engine_args:
		_capture_camera_tests_and_quit(world)


func _capture_screenshot_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://visual_baselines"))
	var image := get_viewport().get_texture().get_image()
	image.save_png(SCREENSHOT_PATH)
	print("Saved screenshot: %s" % ProjectSettings.globalize_path(SCREENSHOT_PATH))
	get_tree().quit()


func _capture_camera_tests_and_quit(world: Node) -> void:
	var camera_tests: Array = world.camera_tests
	if camera_tests.is_empty():
		push_error("No camera_tests found in greybox map source.")
		get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "VisualCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.map_pixel_size.x)
	camera.limit_bottom = int(world.map_pixel_size.y)
	add_child(camera)
	camera.make_current()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAMERA_TEST_CAPTURE_DIR))

	for camera_test in camera_tests:
		var view_id := _safe_filename(str(camera_test.get("id", "camera_test")))
		var center := Vector2(
			float(camera_test.get("center_x", 0.0)) * world.tile_size,
			float(camera_test.get("center_y", 0.0)) * world.tile_size
		)
		camera.position = center

		await get_tree().process_frame
		await get_tree().process_frame

		var output_path := "%s/%s.png" % [CAMERA_TEST_CAPTURE_DIR, view_id]
		var image := get_viewport().get_texture().get_image()
		image.save_png(output_path)
		print("Saved camera test capture: %s" % ProjectSettings.globalize_path(output_path))

	get_tree().quit()


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
