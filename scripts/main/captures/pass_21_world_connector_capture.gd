extends RefCounted

const CONNECTOR_ID := "lower_left_loop_connector"
const EXPECTED_ORIGIN_PROMPT := "E: Enter Lower-left loop"
const EXPECTED_ARRIVAL := "Arrived: Lower-left loop"
const EXPECTED_RETURN_PROMPT := "E: Enter Boat hub"
const CAPTURE_ZOOM := Vector2(1.05, 1.05)
const CAMERA_OFFSET := Vector2(64, -18)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 21 world-connector capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return
	if _main._world.map_id != "production_slice_01":
		push_error("Pass 21 world-connector capture loaded unexpected map: %s." % _main._world.map_id)
		_main.get_tree().quit(1)
		return

	var connector := _connector_by_id(CONNECTOR_ID)
	if connector.is_empty():
		push_error("Pass 21 world-connector capture requires connector %s." % CONNECTOR_ID)
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	_main._player.global_position = connector["center"]
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._update_status_label()
	var origin_status: String = _main._status_label.text if _main._status_label != null else ""
	if origin_status.find(EXPECTED_ORIGIN_PROMPT) == -1:
		push_error("Pass 21 world-connector capture expected origin prompt before transition: %s" % origin_status)
		_main.get_tree().quit(1)
		return

	if not _main._try_world_connector_transition():
		push_error("Pass 21 world-connector capture could not trigger transition.")
		_main.get_tree().quit(1)
		return
	_main._update_status_label()
	var arrival_status: String = _main._status_label.text if _main._status_label != null else ""
	if arrival_status.find(EXPECTED_ARRIVAL) == -1 or arrival_status.find(EXPECTED_RETURN_PROMPT) == -1:
		push_error("Pass 21 world-connector capture expected arrival and return prompt before saving: %s" % arrival_status)
		_main.get_tree().quit(1)
		return
	_main.set_process(false)

	var camera := Camera2D.new()
	camera.name = "Pass21WorldConnectorCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = _main._player.global_position + CAMERA_OFFSET

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_world_connector_arrival.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 21 world-connector capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _main._world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
