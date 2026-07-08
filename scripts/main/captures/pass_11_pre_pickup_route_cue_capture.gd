extends RefCounted

const CUE_MARKER_ID := "southwest_pocket_pre_pickup_cue"
const POCKET_SEGMENT_ID := "southwest_return_pocket_extension"
const TARGET_ID := "salvage_southwest_return_cache"
const EXPECTED_FEEDBACK := "Optional pocket ahead"
const CAPTURE_ZOOM := Vector2(0.84, 0.84)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 11 pre-pickup cue capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var cue_marker: Dictionary = _main._world.get_marker_zone(CUE_MARKER_ID)
	var pocket_segment: Dictionary = _main._world.get_marker_zone(POCKET_SEGMENT_ID)
	var target: Dictionary = _salvage_by_id(TARGET_ID)
	if cue_marker.is_empty() or pocket_segment.is_empty() or target.is_empty():
		push_error("Pass 11 pre-pickup cue capture requires cue marker, pocket segment, and target source data.")
		_main.get_tree().quit(1)
		return

	var cue_center := _zone_center(cue_marker)
	_main._hazard_interactions_enabled = false
	_main._player.global_position = cue_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	_main.set_process(false)

	if _main._world.is_salvage_collected(TARGET_ID):
		push_error("Pass 11 pre-pickup cue capture collected %s before review." % TARGET_ID)
		_main.get_tree().quit(1)
		return
	if _main._status_label == null or _main._status_label.text.find(EXPECTED_FEEDBACK) == -1:
		push_error("Pass 11 pre-pickup cue capture expected feedback before saving: %s." % EXPECTED_FEEDBACK)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "Pass11PrePickupRouteCueCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = (_zone_center(pocket_segment) + cue_center + target["center"]) / 3.0 + Vector2(0, -16)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_pre_pickup_route_cue.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 11 pre-pickup route cue capture: %s" % ProjectSettings.globalize_path(output_path))
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
