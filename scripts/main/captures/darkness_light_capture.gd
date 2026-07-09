extends RefCounted

const ZONE_ID := "deep_cache_dark_pocket"
const EXPECTED_LEVEL := "dark"
const CAPTURE_ZOOM := Vector2(0.82, 0.82)
const CAMERA_OFFSET := Vector2(48, -24)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Darkness/light capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return
	if _main._world.map_id != "production_slice_01":
		push_error("Darkness/light capture loaded unexpected map: %s." % _main._world.map_id)
		_main.get_tree().quit(1)
		return
	if not _main._world.has_method("get_visibility_zones"):
		push_error("Darkness/light capture requires visibility zone runtime data.")
		_main.get_tree().quit(1)
		return

	var zone := _visibility_zone_by_id(ZONE_ID)
	if zone.is_empty():
		push_error("Darkness/light capture requires visibility zone %s." % ZONE_ID)
		_main.get_tree().quit(1)
		return
	if str(zone.get("visibility_level", "")) != EXPECTED_LEVEL:
		push_error("Darkness/light capture expected dark visibility zone, got %s." % zone)
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	if not _place_player_in_zone(zone):
		return
	_main._update_status_label()
	_main.set_process(false)

	var camera := _create_camera(zone["center"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	await _save_capture(camera, capture_dir, "before_light")

	_main.set_process(true)
	if not _purchase_light_upgrade():
		return
	zone = _visibility_zone_by_id(ZONE_ID)
	if not bool(zone.get("readability_upgraded", false)):
		push_error("Darkness/light capture expected upgraded zone readability before after-light capture: %s." % zone)
		_main.get_tree().quit(1)
		return
	if not _place_player_in_zone(zone):
		return
	_main._update_status_label()
	_main.set_process(false)
	camera.position = zone["center"] + CAMERA_OFFSET
	await _save_capture(camera, capture_dir, "after_light")

	print("Saved darkness/light captures: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit()


func _purchase_light_upgrade() -> bool:
	_main._player.global_position = _main._world.get_extraction_center()
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._session_progression.record_banked_salvage(_main.SessionProgression.LIGHT_UPGRADE_COST)
	if not _main._try_purchase_light_upgrade():
		push_error("Darkness/light capture could not purchase light upgrade: wallet=%d." % _main._session_wallet())
		_main.get_tree().quit(1)
		return false
	return true


func _place_player_in_zone(zone: Dictionary) -> bool:
	var zone_center: Vector2 = zone["center"]
	_main._player.global_position = zone_center
	if _main._player.has_method("set_physics_process"):
		_main._player.set_physics_process(false)
	if _main._player.has_method("swim_in_direction"):
		_main._player.swim_in_direction(Vector2.RIGHT, 1.0 / 60.0)
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	var current_zone: Dictionary = _main._world.get_visibility_zone_at(_main._player.global_position)
	if str(current_zone.get("id", "")) != ZONE_ID:
		push_error("Darkness/light capture could not place player inside %s: current=%s." % [ZONE_ID, current_zone])
		_main.get_tree().quit(1)
		return false
	return true


func _create_camera(center: Vector2) -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "DarknessLightCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = center + CAMERA_OFFSET
	return camera


func _save_capture(camera: Camera2D, capture_dir: String, suffix: String) -> void:
	camera.force_update_scroll()
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	var output_path := "%s/%s_darkness_light_%s.png" % [capture_dir, _safe_filename(_main._world.map_id), suffix]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved darkness/light capture: %s" % ProjectSettings.globalize_path(output_path))


func _visibility_zone_by_id(zone_id: String) -> Dictionary:
	for zone in _main._world.get_visibility_zones():
		if str(zone.get("id", "")) == zone_id:
			return zone
	return {}


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
