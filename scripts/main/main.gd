extends Node2D

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const DEFAULT_MAP_PATH := "res://maps/cave_salvage_organic_01.greybox.json"
const ORIGINAL_MAP_PATH := "res://maps/cave_salvage_test_01.greybox.json"
const TILESET_TEST_MAP_PATH := "res://maps/cave_tileset_test_01.greybox.json"
const ORGANIC_MAP_PATH := "res://maps/cave_salvage_organic_01.greybox.json"
const FULL_SKETCH_MAP_PATH := "res://maps/full_cave_sketch_01.greybox.json"
const PRODUCTION_SLICE_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const SCREENSHOT_PATH := "res://visual_baselines/001_greybox_in_engine.png"
const CAMERA_TEST_CAPTURE_DIR := "res://visual_captures/latest"
const ORIGINAL_CAPTURE_DIR := "res://visual_captures/original_salvage"
const TILESET_TEST_CAPTURE_DIR := "res://visual_captures/tileset_test"
const ORGANIC_CAPTURE_DIR := "res://visual_captures/organic_salvage"
const FULL_SKETCH_CAPTURE_DIR := "res://visual_captures/full_cave_sketch"
const PRODUCTION_SLICE_CAPTURE_DIR := "res://visual_captures/production_slice_01"
const BUILD_INFO_PATH := "res://build_info.json"
const CAPTURE_ZOOM := Vector2(0.7, 0.7)
const SALVAGE_COLLECTION_RADIUS := 34.0

var _world
var _player
var _review_label: Label
var _status_label: Label
var _held_salvage := 0
var _banked_salvage := 0
var _total_salvage := 0
var _run_complete := false
var _last_status_note := ""


func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	var engine_args := OS.get_cmdline_args()
	var capture_original_map := _has_arg(user_args, engine_args, "--capture-original-map")
	var capture_tileset_test := _has_arg(user_args, engine_args, "--capture-tileset-test")
	var capture_organic_map := _has_arg(user_args, engine_args, "--capture-organic-map")
	var capture_full_sketch_map := _has_arg(user_args, engine_args, "--capture-full-sketch-map")
	var capture_production_slice_map := _has_arg(user_args, engine_args, "--capture-production-slice-map")
	var check_map_parity := _has_arg(user_args, engine_args, "--check-map-parity")
	var smoke_salvage_loop := _has_arg(user_args, engine_args, "--smoke-salvage-loop")
	var requested_map_path := _arg_value(user_args, engine_args, "--map-path")
	var parity_output_path := _arg_value(user_args, engine_args, "--parity-output")

	var world := WORLD_SCENE.instantiate()
	_world = world
	if capture_original_map:
		world.map_path = ORIGINAL_MAP_PATH
	elif capture_tileset_test:
		world.map_path = TILESET_TEST_MAP_PATH
	elif capture_organic_map:
		world.map_path = ORGANIC_MAP_PATH
	elif capture_full_sketch_map:
		world.map_path = FULL_SKETCH_MAP_PATH
	elif capture_production_slice_map:
		world.map_path = PRODUCTION_SLICE_MAP_PATH
	elif not requested_map_path.is_empty():
		world.map_path = requested_map_path
	else:
		world.map_path = DEFAULT_MAP_PATH
	world.show_debug_overlay = _has_arg(user_args, engine_args, "--show-debug-overlay")
	add_child(world)
	world.load_greybox()

	if check_map_parity:
		_write_parity_report_and_quit(world, parity_output_path)
		return

	var player := PLAYER_SCENE.instantiate()
	_player = player
	player.position = world.spawn_position
	add_child(player)

	if player.has_method("set_camera_limits"):
		player.set_camera_limits(Rect2(Vector2.ZERO, world.map_pixel_size))
	if player.has_method("snap_camera"):
		player.snap_camera()

	_total_salvage = world.get_total_salvage_count()
	_create_review_overlay(world)
	_update_status_label()

	if smoke_salvage_loop:
		_smoke_salvage_loop_and_quit()
		return

	if _has_arg(user_args, engine_args, "--capture-greybox-screenshot"):
		_capture_screenshot_and_quit()
	elif _has_arg(user_args, engine_args, "--capture-camera-tests"):
		_capture_camera_tests_and_quit(world, CAMERA_TEST_CAPTURE_DIR)
	elif capture_original_map:
		_capture_camera_tests_and_quit(world, ORIGINAL_CAPTURE_DIR)
	elif capture_tileset_test:
		_capture_camera_tests_and_quit(world, TILESET_TEST_CAPTURE_DIR)
	elif capture_organic_map:
		_capture_camera_tests_and_quit(world, ORGANIC_CAPTURE_DIR)
	elif capture_full_sketch_map:
		_capture_camera_tests_and_quit(world, FULL_SKETCH_CAPTURE_DIR)
	elif capture_production_slice_map:
		_capture_camera_tests_and_quit(world, PRODUCTION_SLICE_CAPTURE_DIR)


func _process(_delta: float) -> void:
	if _world == null or _player == null:
		return
	if _run_complete:
		_update_status_label()
		return

	var collected_salvage: String = _world.collect_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
	if not collected_salvage.is_empty():
		_held_salvage += 1
		_last_status_note = "Collected %s" % collected_salvage

	if _held_salvage > 0 and _world.is_inside_extraction(_player.global_position):
		_banked_salvage += _held_salvage
		_held_salvage = 0
		if _total_salvage > 0 and _banked_salvage >= _total_salvage:
			_run_complete = true
			_last_status_note = "Run complete"
		else:
			_last_status_note = "Banked salvage"

	_update_status_label()


func _smoke_salvage_loop_and_quit() -> void:
	if _total_salvage <= 0:
		push_error("Salvage loop smoke requires a map with authored salvage.")
		get_tree().quit(1)
		return

	for salvage in _world.get_salvage_centers():
		_player.global_position = salvage["center"]
		_process(0.0)

	_player.global_position = _world.get_extraction_center()
	_process(0.0)

	if not _run_complete:
		push_error("Salvage loop smoke did not complete after collecting and returning.")
		get_tree().quit(1)
		return

	var completed_total := _total_salvage
	_reset_run()
	if _held_salvage != 0 or _banked_salvage != 0 or _run_complete:
		push_error("Salvage loop smoke reset left stale run state.")
		get_tree().quit(1)
		return

	print("Salvage loop smoke passed: collected, banked, completed, and reset %d salvage." % completed_total)
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
		_reset_run()


func _reset_run() -> void:
	if _world == null or _player == null:
		return

	_world.reset_salvage()
	_held_salvage = 0
	_banked_salvage = 0
	_run_complete = false
	_last_status_note = "Reset"
	_player.position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	if _player.has_method("snap_camera"):
		_player.snap_camera()
	_update_status_label()


func _create_review_overlay(world: Node) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ReviewOverlay"
	add_child(canvas)

	var panel := PanelContainer.new()
	panel.name = "ReviewPanel"
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(260, 0)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.07, 0.10, 0.70)
	panel_style.border_color = Color(0.72, 0.92, 1.0, 0.22)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)

	_review_label = Label.new()
	_review_label.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0, 0.95))
	_review_label.add_theme_font_size_override("font_size", 13)
	_review_label.text = "Map %s\nBuild %s" % [world.get_map_label(), _build_label()]
	stack.add_child(_review_label)

	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45, 0.98))
	_status_label.add_theme_font_size_override("font_size", 14)
	stack.add_child(_status_label)


func _update_status_label() -> void:
	if _status_label == null:
		return

	if _total_salvage <= 0:
		_status_label.text = "Salvage 0/0"
		return

	var prompt := ""
	if _run_complete:
		prompt = "Complete - press R"
	elif _held_salvage > 0:
		prompt = "Return to extraction"
	elif not _last_status_note.is_empty():
		prompt = _last_status_note

	_status_label.text = "Salvage %d/%d  Held %d\n%s" % [
		_banked_salvage,
		_total_salvage,
		_held_salvage,
		prompt,
	]


func _build_label() -> String:
	var file := FileAccess.open(BUILD_INFO_PATH, FileAccess.READ)
	if file == null:
		return "local"

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "local"

	var git_sha := str(parsed.get("git_sha", ""))
	if git_sha.is_empty():
		return str(parsed.get("version", "local"))
	if git_sha.length() > 7:
		return git_sha.substr(0, 7)
	return git_sha


func _write_parity_report_and_quit(world: Node, output_path: String) -> void:
	var report_json := JSON.stringify(world.get_runtime_parity_report(), "\t")
	if output_path.is_empty():
		print(report_json)
	else:
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_error("Unable to write parity report: %s" % output_path)
			get_tree().quit(1)
			return
		file.store_string(report_json)
		print("Wrote map parity report: %s" % output_path)
	get_tree().quit()


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
