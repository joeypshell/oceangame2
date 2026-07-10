extends RefCounted

const ExpeditionDayPresentation := preload("res://scripts/main/expedition_day_presentation.gd")

const SURFACE_OXYGEN_START := 20.0
const SURFACE_TICK_SECONDS := 1.0
const DUSK_REMAINING_SECONDS := 59.0
const CAMERA_ZOOM := Vector2(0.95, 0.95)
const SURFACE_CAMERA_OFFSET := Vector2(96, 112)
const BOAT_CAMERA_OFFSET := Vector2(112, 128)
const DEBRIEF_CAMERA_Y := 379.0

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_active_day():
		return
	var target := _first_instant_salvage()
	var surface_center := _surface_center_outside_boat()
	if target.is_empty() or surface_center == Vector2.ZERO:
		_fail("requires instant salvage and authored open surface outside the boat")
		return

	_main._player.global_position = target["center"]
	_main._process(0.0)
	_main._expedition_day_state.daylight_remaining_seconds = DUSK_REMAINING_SECONDS
	_main._sortie_state.oxygen_seconds = SURFACE_OXYGEN_START
	_main._player.global_position = surface_center
	_main._process(SURFACE_TICK_SECONDS)
	_main._update_status_label()
	if not _status_has_all(["DUSK", "Surface O2", "Held 1/"]):
		_fail("surface state omitted daylight, surface, or cargo context")
		return

	_camera = _create_camera()
	_frame_camera(surface_center + SURFACE_CAMERA_OFFSET)
	await _settle_frames()
	if not _save_capture(capture_dir, "production_slice_01_day_surface_refill.png"):
		return

	_main._player.global_position = _main._world.get_extraction_center()
	_main._process(0.0)
	_main._update_status_label()
	if _main._sortie_state.held_salvage != 0 or _main._expedition_day_state.banked_salvage != 1:
		_fail("boat state did not offload exactly one cargo")
		return
	if not _status_has_all(["DUSK", "Boat N End", "Salvage banked 1/"]):
		_fail("boat state omitted daylight, action, or banked-cargo context")
		return

	_frame_camera(_main._world.get_extraction_center() + BOAT_CAMERA_OFFSET)
	await _settle_frames()
	if not _save_capture(capture_dir, "production_slice_01_day_boat_offload.png"):
		return

	var request: Dictionary = ExpeditionDayPresentation.try_request_voluntary_end(_main)
	if not bool(request.get("requested", false)):
		_fail("could not request voluntary end at the safe boat")
		return
	_main._process(0.0)
	_main._update_status_label()
	_camera.make_current()
	var boat_center: Vector2 = _main._world.get_extraction_center()
	_frame_camera(Vector2(boat_center.x + BOAT_CAMERA_OFFSET.x, DEBRIEF_CAMERA_Y))
	var debrief_text: String = _main._result_label.text if _main._result_label != null else ""
	if debrief_text.find("Night 1") == -1 or debrief_text.find("Banked cargo 1") == -1 or debrief_text.find("N: Start day 2") == -1:
		_fail("night debrief omitted day summary or next-day action")
		return

	await _settle_frames()
	if not _save_capture(capture_dir, "production_slice_01_night_debrief.png"):
		return
	print("Saved Expedition Day review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.remove_child(_camera)
	_camera.queue_free()
	_camera = null
	await _main.get_tree().process_frame
	_main.get_tree().quit(0)


func _prepare_active_day() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_slice_01":
		_fail("requires the default production slice")
		return false
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	return true


func _first_instant_salvage() -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			return salvage
	return {}


func _surface_center_outside_boat() -> Vector2:
	for center in _main._world.get_open_surface_centers():
		if not _main._world.is_inside_boat(center):
			return center
	return Vector2.ZERO


func _status_has_all(values: Array[String]) -> bool:
	var status: String = _main._status_label.text if _main._status_label != null else ""
	for value in values:
		if status.find(value) == -1:
			return false
	return true


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "ExpeditionDayCaptureCamera"
	camera.zoom = CAMERA_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	return camera


func _frame_camera(position: Vector2) -> void:
	_camera.position = position


func _settle_frames() -> void:
	RenderingServer.force_draw()
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await RenderingServer.frame_post_draw


func _save_capture(capture_dir: String, filename: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s" % [capture_dir, filename]
	var image: Image = _main.get_viewport().get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		_fail("could not save %s (error %d)" % [output_path, error])
		return false
	print("Saved Expedition Day capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Expedition Day capture failed: %s." % message)
	_main.get_tree().quit(1)
