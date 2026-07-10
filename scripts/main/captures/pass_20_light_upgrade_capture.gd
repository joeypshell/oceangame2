extends RefCounted

const CAPTURE_ZOOM := Vector2(1.45, 1.45)
const REVIEW_OFFSET := Vector2(0, 220)
const CAMERA_OFFSET := Vector2(96, -8)
const EXPECTED_UPGRADE_FEEDBACK := "Light +range upgraded"

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 20 light upgrade capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return
	if _main._world.map_id != "production_slice_01":
		push_error("Pass 20 light upgrade capture loaded unexpected map: %s." % _main._world.map_id)
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	var banked_target_ids := _bank_until_upgrade_affordable()
	if banked_target_ids.is_empty() or _main._session_wallet() < _light_upgrade_cost():
		push_error("Pass 20 light upgrade capture could not bank enough wallet: wallet=%d targets=%s." % [_main._session_wallet(), banked_target_ids])
		_main.get_tree().quit(1)
		return

	var wallet_before_purchase: int = _main._session_wallet()
	_main._player.global_position = _main._world.get_extraction_center()
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	if not _main._try_purchase_light_upgrade():
		push_error("Pass 20 light upgrade capture could not purchase light upgrade: wallet=%d." % wallet_before_purchase)
		_main.get_tree().quit(1)
		return
	var review_position: Vector2 = _main._world.spawn_position + REVIEW_OFFSET
	_main._player.global_position = review_position
	if _main._player.has_method("swim_in_direction"):
		_main._player.set_physics_process(false)
		_main._player.swim_in_direction(Vector2.RIGHT, 1.0 / 60.0)
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()

	_main._sortie_state.oxygen_seconds = _main._oxygen_capacity_seconds()
	_main._update_status_label()
	_main.set_process(false)

	var status_text: String = _main._status_label.text if _main._status_label != null else ""
	if status_text.find(EXPECTED_UPGRADE_FEEDBACK) == -1 or status_text.find("Light +range") == -1:
		push_error("Pass 20 light upgrade capture expected wallet and light upgrade feedback before saving: %s" % status_text)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "Pass20LightUpgradeCaptureCamera"
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
	var output_path := "%s/%s_pass_20_light_upgrade.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 20 light upgrade capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _bank_until_upgrade_affordable() -> PackedStringArray:
	var banked_ids := PackedStringArray()
	for salvage in _main._salvage_centers_for_full_collection():
		if _main._session_wallet() >= _light_upgrade_cost():
			break
		var salvage_id := str(salvage.get("id", "salvage"))
		_main._player.global_position = salvage["center"]
		if _main._player.has_method("reset_motion"):
			_main._player.reset_motion()
		_main._collect_salvage_for_review_state(salvage)
		if _main._world.is_salvage_collected(salvage_id) and not banked_ids.has(salvage_id):
			banked_ids.append(salvage_id)
		if _main._sortie_state.held_salvage >= _main._held_salvage_capacity():
			_main._player.global_position = _main._world.get_extraction_center()
			if _main._player.has_method("reset_motion"):
				_main._player.reset_motion()
			_main._process(0.0)

	if _main._sortie_state.held_salvage > 0 and _main._session_wallet() < _light_upgrade_cost():
		_main._player.global_position = _main._world.get_extraction_center()
		if _main._player.has_method("reset_motion"):
			_main._player.reset_motion()
		_main._process(0.0)
	return banked_ids


func _light_upgrade_cost() -> int:
	return _main.SessionProgression.LIGHT_UPGRADE_COST


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
