extends RefCounted

const LOWER_LOOP_ID := "salvage_lower_loop"
const RELAY_CACHE_ID := "salvage_southwest_return_cache"
const CUE_MARKER_ID := "southwest_pocket_pre_pickup_cue"
const EXPECTED_OBJECTIVE := "Objective: Relay trail 1/2"
const EXPECTED_CUE := "Relay trail cache ahead"
const CAPTURE_ZOOM := Vector2(0.78, 0.78)
const REVIEW_OXYGEN_SECONDS := 34.0

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		_fail("Pass 13 route commitment capture requires a loaded playable map.")
		return

	var lower_loop := _salvage_by_id(LOWER_LOOP_ID)
	var relay_cache := _salvage_by_id(RELAY_CACHE_ID)
	var cue_marker: Dictionary = _main._world.get_marker_zone(CUE_MARKER_ID)
	if lower_loop.is_empty() or relay_cache.is_empty() or cue_marker.is_empty():
		_fail("Pass 13 capture requires both relay-trail targets and the southwest cue marker.")
		return
	if not _main._world.collect_salvage_by_id(LOWER_LOOP_ID):
		_fail("Pass 13 capture could not collect %s for review state." % LOWER_LOOP_ID)
		return
	_main._collect_salvage_into_cargo(LOWER_LOOP_ID)

	var cue_center := _zone_center(cue_marker)
	_main._hazard_interactions_enabled = false
	_main._sortie_state.oxygen_seconds = REVIEW_OXYGEN_SECONDS
	_main._player.global_position = cue_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	_main.set_process(false)

	var status_text: String = _main._status_label.text if _main._status_label != null else ""
	if status_text.find(EXPECTED_OBJECTIVE) == -1 or status_text.find(EXPECTED_CUE) == -1:
		_fail("Pass 13 capture expected relay objective and cache cue before saving: %s" % status_text)
		return
	if _main._world.is_salvage_collected(RELAY_CACHE_ID):
		_fail("Pass 13 capture collected %s before the review frame." % RELAY_CACHE_ID)
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
	camera.position = (cue_center + lower_loop["center"] + relay_cache["center"]) / 3.0 + Vector2(16, -16)

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


func _fail(message: String) -> void:
	push_error(message)
	_main.get_tree().quit(1)
