extends RefCounted

const CAPTURE_ZOOM := Vector2(0.7, 0.7)
const CAMERA_OFFSET := Vector2(180, 180)
const EXPECTED_UPGRADE_FEEDBACK := "O2 tank upgraded"

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 18 progression capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return
	if _main._world.map_id != "production_slice_01":
		push_error("Pass 18 progression capture loaded unexpected map: %s." % _main._world.map_id)
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	var banked_target_ids := _bank_until_upgrade_affordable()
	if banked_target_ids.is_empty() or _main._session_wallet() < _oxygen_upgrade_cost():
		push_error("Pass 18 progression capture could not bank enough wallet: wallet=%d targets=%s." % [_main._session_wallet(), banked_target_ids])
		_main.get_tree().quit(1)
		return

	var wallet_before_purchase: int = _main._session_wallet()
	_main._player.global_position = _main._world.get_extraction_center()
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	if not _main._try_purchase_oxygen_tank_upgrade():
		push_error("Pass 18 progression capture could not purchase oxygen upgrade: wallet=%d." % wallet_before_purchase)
		_main.get_tree().quit(1)
		return

	_main._oxygen_seconds = _main._oxygen_capacity_seconds()
	_main._update_status_label()
	_main.set_process(false)

	var status_text: String = _main._status_label.text if _main._status_label != null else ""
	if status_text.find(EXPECTED_UPGRADE_FEEDBACK) == -1 or status_text.find("Wallet") == -1 or status_text.find("O2 tank +") == -1:
		push_error("Pass 18 progression capture expected wallet and upgrade feedback before saving: %s" % status_text)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "Pass18ProgressionCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = _main._world.spawn_position + CAMERA_OFFSET

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_pass_18_progression.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 18 progression capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _bank_until_upgrade_affordable() -> PackedStringArray:
	var banked_ids := PackedStringArray()
	for salvage in _main._salvage_centers_for_full_collection():
		if _main._session_wallet() >= _oxygen_upgrade_cost():
			break
		var salvage_id := str(salvage.get("id", "salvage"))
		_main._player.global_position = salvage["center"]
		if _main._player.has_method("reset_motion"):
			_main._player.reset_motion()
		_main._collect_salvage_for_review_state(salvage)
		if _main._world.is_salvage_collected(salvage_id) and not banked_ids.has(salvage_id):
			banked_ids.append(salvage_id)
		if _main._held_salvage >= _main.HELD_SALVAGE_CAPACITY:
			_main._player.global_position = _main._world.get_extraction_center()
			if _main._player.has_method("reset_motion"):
				_main._player.reset_motion()
			_main._process(0.0)

	if _main._held_salvage > 0 and _main._session_wallet() < _oxygen_upgrade_cost():
		_main._player.global_position = _main._world.get_extraction_center()
		if _main._player.has_method("reset_motion"):
			_main._player.reset_motion()
		_main._process(0.0)
	return banked_ids


func _oxygen_upgrade_cost() -> int:
	return _main.SessionProgression.OXYGEN_TANK_UPGRADE_COST


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
