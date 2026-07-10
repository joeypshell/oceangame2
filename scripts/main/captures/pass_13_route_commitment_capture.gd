extends RefCounted

const LOWER_LOOP_ID := "salvage_lower_loop"
const DEEP_CACHE_ID := "salvage_deep_right_cache"
const PRESSURE_SEGMENT_ID := "lower_loop_to_deep_cache_pressure"
const EXPECTED_OBJECTIVE := "Objective: Deep cache 1/2"
const EXPECTED_PROGRESS := "Salvaging"
const CAPTURE_ZOOM := Vector2(0.78, 0.78)
const PROGRESS_RATIO := 0.52
const REVIEW_OXYGEN_SECONDS := 34.0

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 13 route commitment capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var lower_loop := _salvage_by_id(LOWER_LOOP_ID)
	var deep_cache := _salvage_by_id(DEEP_CACHE_ID)
	var pressure_segment: Dictionary = _main._world.get_marker_zone(PRESSURE_SEGMENT_ID)
	if lower_loop.is_empty() or deep_cache.is_empty() or pressure_segment.is_empty():
		push_error("Pass 13 route commitment capture requires lower-loop target, deep-cache target, and pressure segment source data.")
		_main.get_tree().quit(1)
		return
	if str(deep_cache.get("interaction", "instant")) != "timed_salvage":
		push_error("Pass 13 route commitment capture expects %s to remain timed_salvage." % DEEP_CACHE_ID)
		_main.get_tree().quit(1)
		return

	if not _main._world.collect_salvage_by_id(LOWER_LOOP_ID):
		push_error("Pass 13 route commitment capture could not collect %s for review state." % LOWER_LOOP_ID)
		_main.get_tree().quit(1)
		return
	_main._collect_salvage_into_cargo(LOWER_LOOP_ID)

	var deep_center: Vector2 = deep_cache["center"]
	_main._hazard_interactions_enabled = false
	_main._sortie_state.oxygen_seconds = REVIEW_OXYGEN_SECONDS
	_main._player.global_position = deep_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()

	var interaction_seconds := maxf(0.01, float(deep_cache.get("interaction_seconds", 0.0)))
	_main._process(interaction_seconds * PROGRESS_RATIO)
	_main._update_status_label()
	_main.set_process(false)

	var status_text: String = _main._status_label.text if _main._status_label != null else ""
	if status_text.find(EXPECTED_OBJECTIVE) == -1 or status_text.find(EXPECTED_PROGRESS) == -1:
		push_error("Pass 13 route commitment capture expected objective and timed progress text before saving: %s" % status_text)
		_main.get_tree().quit(1)
		return
	if _main._world.is_salvage_collected(DEEP_CACHE_ID):
		push_error("Pass 13 route commitment capture collected %s before review frame." % DEEP_CACHE_ID)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "Pass13RouteCommitmentCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = (_zone_center(pressure_segment) + lower_loop["center"] + deep_center) / 3.0 + Vector2(16, -16)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_route_commitment.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 13 route commitment capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _zone_center(zone: Dictionary) -> Vector2:
	return Vector2(
		(float(zone.get("x", 0.0)) + float(zone.get("w", 1.0)) * 0.5) * float(_main._world.tile_size),
		(float(zone.get("y", 0.0)) + float(zone.get("h", 1.0)) * 0.5) * float(_main._world.tile_size)
	)


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
