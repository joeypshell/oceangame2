extends Node2D

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const DEFAULT_MAP_PATH := "res://maps/cave_salvage_test_01.greybox.json"
const TILESET_TEST_MAP_PATH := "res://maps/cave_tileset_test_01.greybox.json"
const ORGANIC_MAP_PATH := "res://maps/cave_salvage_organic_01.greybox.json"
const SCREENSHOT_PATH := "res://visual_baselines/001_greybox_in_engine.png"
const CAMERA_TEST_CAPTURE_DIR := "res://visual_captures/latest"
const TILESET_TEST_CAPTURE_DIR := "res://visual_captures/tileset_test"
const ORGANIC_CAPTURE_DIR := "res://visual_captures/organic_salvage"
const CAPTURE_ZOOM := Vector2(0.7, 0.7)


func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	var engine_args := OS.get_cmdline_args()
	var capture_tileset_test := _has_arg(user_args, engine_args, "--capture-tileset-test")
	var capture_organic_map := _has_arg(user_args, engine_args, "--capture-organic-map")
	var requested_map_path := _arg_value(user_args, engine_args, "--map-path")

	var world := WORLD_SCENE.instantiate()
	if capture_tileset_test:
		world.map_path = TILESET_TEST_MAP_PATH
	elif capture_organic_map:
		world.map_path = ORGANIC_MAP_PATH
	elif not requested_map_path.is_empty():
		world.map_path = requested_map_path
	else:
		world.map_path = DEFAULT_MAP_PATH
	world.show_debug_overlay = _has_arg(user_args, engine_args, "--show-debug-overlay")
	add_child(world)
	world.load_greybox()

	var player := PLAYER_SCENE.instantiate()
	player.position = world.spawn_position
	add_child(player)

	if player.has_method("set_camera_limits"):
		player.set_camera_limits(Rect2(Vector2.ZERO, world.map_pixel_size))

	if _has_arg(user_args, engine_args, "--capture-greybox-screenshot"):
		_capture_screenshot_and_quit()
	elif _has_arg(user_args, engine_args, "--capture-camera-tests"):
		_capture_camera_tests_and_quit(world, CAMERA_TEST_CAPTURE_DIR)
	elif capture_tileset_test:
		_capture_camera_tests_and_quit(world, TILESET_TEST_CAPTURE_DIR)
	elif capture_organic_map:
		_capture_camera_tests_and_quit(world, ORGANIC_CAPTURE_DIR)


func _capture_screenshot_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://visual_baselines"))
	var image := get_viewport().get_texture().get_image()
	image.save_png(SCREENSHOT_PATH)
	print("Saved screenshot: %s" % ProjectSettings.globalize_path(SCREENSHOT_PATH))
	get_tree().quit()


func _capture_camera_tests_and_quit(world: Node, capture_dir: String) -> void:
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

		await get_tree().process_frame
		await get_tree().process_frame

		var output_path := "%s/%s.png" % [capture_dir, view_id]
		var image := get_viewport().get_texture().get_image()
		image.save_png(output_path)
		print("Saved camera test capture: %s" % ProjectSettings.globalize_path(output_path))

	get_tree().quit()


func _has_arg(user_args: PackedStringArray, engine_args: PackedStringArray, value: String) -> bool:
	return value in user_args or value in engine_args


func _arg_value(user_args: PackedStringArray, engine_args: PackedStringArray, name: String) -> String:
	for args in [user_args, engine_args]:
		for index in range(args.size()):
			var arg: String = str(args[index])
			if arg == name and index + 1 < args.size():
				return str(args[index + 1])
			var prefix := "%s=" % name
			if arg.begins_with(prefix):
				return arg.substr(prefix.length())
	return ""


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
