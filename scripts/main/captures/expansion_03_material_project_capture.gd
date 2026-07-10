extends RefCounted

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const CAPTURE_SIZES := [
	{"suffix": "1280x720", "size": Vector2i(1280, 720)},
	{"suffix": "1920x1080", "size": Vector2i(1920, 1080)},
]
const MATERIAL_CAMERA_ZOOM := Vector2(1.0, 1.0)
const TARGET_CAMERA_ZOOM := Vector2(1.12, 1.12)
const DEBRIEF_CAMERA_ZOOM := Vector2(0.9, 0.9)
const MATERIAL_CAMERA_OFFSET := Vector2(32, -24)
const TARGET_CAMERA_OFFSET := Vector2(-48, -24)
const DEBRIEF_CAMERA_OFFSET := Vector2(128, 148)
const CUTTER_PROGRESS_RATIO := 0.5

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_camera = _create_camera()
	var profile = _main._anomaly_survey.profile_state()
	var material := _selected_material(ExpansionProfileState.TITANIUM_MATERIAL_ID)
	if material.is_empty():
		_fail("missing selected titanium material")
		return

	_main._player.global_position = material["center"]
	_main._process(0.0)
	_main._update_status_label()
	if _main._material_runtime.held_count() != 1 or not _status_contains("Materials Ti 0 (+1)"):
		_fail("material-held overlay state was not readable")
		return
	if not await _capture_pair(capture_dir, "material_held", material["center"] + MATERIAL_CAMERA_OFFSET, MATERIAL_CAMERA_ZOOM):
		return

	var restored: Dictionary = _main._material_runtime.restore_unbanked(
		_main._world,
		_main._expedition_day_state,
		"capture_reset"
	)
	if int(restored.get("restored_count", 0)) != 1:
		_fail("material-held setup did not restore cleanly")
		return
	var target := _tool_target()
	if target.is_empty():
		_fail("missing source-authored sealed wreck")
		return
	_main._player.global_position = target["center"]
	_main._process(0.0)
	_main._update_status_label()
	if _main._last_status_note != "Sealed wreck | Cutter required":
		_fail("locked sealed-wreck prompt was not readable")
		return
	if not await _capture_pair(capture_dir, "sealed_wreck_locked", target["center"] + TARGET_CAMERA_OFFSET, TARGET_CAMERA_ZOOM):
		return

	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false)
	profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}, false)
	_main._player.global_position = _main._world.get_extraction_center()
	_main._expedition_day_state.request_end_day("voluntary")
	_main._process(0.0)
	_main._update_status_label()
	var debrief_text: String = _main._result_label.text if _main._result_label != null else ""
	if debrief_text.find("P: Build salvage cutter") == -1 or debrief_text.find("N: Start day 2") == -1:
		_fail("project-ready debrief omitted P/N actions")
		return
	if not await _capture_pair(
		capture_dir,
		"project_ready_debrief",
		_main._world.get_extraction_center() + DEBRIEF_CAMERA_OFFSET,
		DEBRIEF_CAMERA_ZOOM
	):
		return

	var build: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_P)
	if not bool(build.get("changed", false)):
		_fail("project-ready setup could not build cutter")
		return
	var next_day: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_N)
	if not bool(next_day.get("changed", false)):
		_fail("capture setup could not start next day")
		return
	_prepare_runtime_nodes()
	target = _tool_target()
	_main._player.global_position = target["center"]
	_main._process(float(target.get("interaction_seconds", 2.0)) * CUTTER_PROGRESS_RATIO)
	_main._update_status_label()
	var cutter_report: Dictionary = _main._cutter_salvage.report()
	var progress_ratio := float(cutter_report.get("progress_ratio", 0.0))
	if progress_ratio < 0.45 or progress_ratio > 0.55 or not _status_contains("Cutting sealed wreck"):
		_fail("cutter-active progress state was not readable: %.2f" % progress_ratio)
		return
	if not await _capture_pair(capture_dir, "sealed_wreck_cutter_active", target["center"] + TARGET_CAMERA_OFFSET, TARGET_CAMERA_ZOOM):
		return

	print("Saved Expansion 03 material-project review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_slice_01":
		_fail("requires the default production slice")
		return false
	_main.set_process(false)
	_prepare_runtime_nodes()
	return true


func _prepare_runtime_nodes() -> void:
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false


func _selected_material(material_id: String) -> Dictionary:
	var active_ids: Array = _main._world.get_material_candidate_report().get("active_ids", [])
	for candidate in _main._world.get_material_candidates():
		if active_ids.has(str(candidate.get("id", ""))) and str(candidate.get("material_id", "")) == material_id:
			return candidate
	return {}


func _tool_target() -> Dictionary:
	for target in _main._world.get_tool_targets():
		if str(target.get("id", "")) == ExpansionProfileState.SALVAGE_CUTTER_TARGET_ID:
			return target
	return {}


func _status_contains(text: String) -> bool:
	return _main._status_label != null and _main._status_label.text.find(text) != -1


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "Expansion03MaterialProjectCaptureCamera"
	camera.position_smoothing_enabled = false
	_main.add_child(camera)
	camera.make_current()
	return camera


func _capture_pair(capture_dir: String, state_id: String, camera_position: Vector2, camera_zoom: Vector2) -> bool:
	_frame_camera(camera_position, camera_zoom)
	for capture_spec in CAPTURE_SIZES:
		var expected_size: Vector2i = capture_spec["size"]
		_main.get_window().size = expected_size
		await _settle_frames()
		var image: Image = _main.get_viewport().get_texture().get_image()
		if image.get_size() != expected_size:
			_fail("capture %s rendered %s expected %s" % [state_id, str(image.get_size()), str(expected_size)])
			return false
		var filename := "production_slice_01_%s_%s.png" % [state_id, str(capture_spec["suffix"])]
		if not _save_capture(capture_dir, filename, image):
			return false
	return true


func _frame_camera(position: Vector2, zoom: Vector2) -> void:
	_camera.zoom = zoom
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_main._world.map_pixel_size.x)
	_camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_camera.position = position
	_camera.make_current()


func _settle_frames() -> void:
	RenderingServer.force_draw()
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await RenderingServer.frame_post_draw


func _save_capture(capture_dir: String, filename: String, image: Image) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s" % [capture_dir, filename]
	var error := image.save_png(output_path)
	if error != OK:
		_fail("could not save %s (error %d)" % [output_path, error])
		return false
	print("Saved Expansion 03 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Expansion 03 material-project capture failed: %s." % message)
	_main.get_tree().quit(1)
