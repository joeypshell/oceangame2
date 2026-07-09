extends RefCounted

const CHEST_ID := "lower_loop_upgrade_chest"
const EXPECTED_PROMPT := "Upgrade chest +400 wallet"
const CAPTURE_ZOOM := Vector2(1.1, 1.1)
const CAMERA_OFFSET := Vector2(64, -24)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Upgrade-chest capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var chest := _container_by_id(CHEST_ID)
	if chest.is_empty():
		push_error("Upgrade-chest capture requires container %s." % CHEST_ID)
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	_main._player.global_position = chest["center"]
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	var status: String = _main._status_label.text if _main._status_label != null else ""
	if status.find(EXPECTED_PROMPT) == -1:
		push_error("Upgrade-chest capture expected reward prompt before saving: %s" % status)
		_main.get_tree().quit(1)
		return
	_main.set_process(false)

	var camera := Camera2D.new()
	camera.name = "UpgradeChestCaptureCamera"
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
	var output_path := "%s/%s_upgrade_chest.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved upgrade-chest capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _container_by_id(container_id: String) -> Dictionary:
	for container in _main._world.get_progression_containers():
		if str(container.get("id", "")) == container_id:
			return container
	return {}


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
