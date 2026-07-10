extends RefCounted

const CAPTURE_ZOOM := Vector2(1.55, 1.55)
const REVIEW_CENTER_TILES := Vector2(42, 25)
const CAMERA_OFFSET := Vector2(92, -12)
const REVERSAL_DIRECTIONS := [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.RIGHT,
]

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 27 player-facing capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return
	if _main._world.map_id != "production_slice_01":
		push_error("Pass 27 player-facing capture loaded unexpected map: %s." % _main._world.map_id)
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	_main._run_complete = false
	_main._sortie_state.failed = false
	_main._sortie_state.oxygen_seconds = _main._oxygen_capacity_seconds()
	_main._last_status_note = "Facing review"

	var review_position: Vector2 = REVIEW_CENTER_TILES * float(_main._world.tile_size)
	_main._player.global_position = review_position
	_main._player.set_physics_process(false)
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()

	for direction in REVERSAL_DIRECTIONS:
		_main._player.swim_in_direction(direction, 1.0 / 30.0)
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()

	var facing_report: Dictionary = _main._player.get_facing_report()
	if absf(float(facing_report.get("root_scale_x", 0.0)) - 1.0) > 0.01:
		push_error("Pass 27 player-facing capture expected stable root scale, got %s." % str(facing_report))
		_main.get_tree().quit(1)
		return
	if bool(facing_report.get("body_flip_h", true)):
		push_error("Pass 27 player-facing capture expected final right-facing body, got %s." % str(facing_report))
		_main.get_tree().quit(1)
		return
	if not bool(facing_report.get("body_region_filter_clip_enabled", false)):
		push_error("Pass 27 player-facing capture expected clipped sprite region, got %s." % str(facing_report))
		_main.get_tree().quit(1)
		return
	if float(facing_report.get("light_cone_position_x", 0.0)) <= 0.0 or float(facing_report.get("light_cone_scale_x", 0.0)) <= 0.0:
		push_error("Pass 27 player-facing capture expected right-facing light cone, got %s." % str(facing_report))
		_main.get_tree().quit(1)
		return

	_main._update_status_label()
	_main.set_process(false)

	var camera := Camera2D.new()
	camera.name = "Pass27PlayerFacingCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = review_position + CAMERA_OFFSET

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_pass_27_player_facing.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 27 player-facing capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
