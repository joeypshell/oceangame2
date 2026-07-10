extends RefCounted

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const CAPTURE_SIZES := [
	{"suffix": "1280x720", "size": Vector2i(1280, 720)},
	{"suffix": "1920x1080", "size": Vector2i(1920, 1080)},
]
const GATE_ID := ExpansionProfileState.CURRENT_STABILIZER_GATE_ID
const PAYOFF_ID := "salvage_current_pocket_cache"
const POCKET_CAMERA_ZOOM := Vector2(1.25, 1.25)
const DEBRIEF_CAMERA_ZOOM := Vector2(0.9, 0.9)
const POCKET_CAMERA_OFFSET := Vector2(64, 0)
const DEBRIEF_CAMERA_OFFSET := Vector2(128, 148)

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_camera = _create_camera()
	var gate := _gate_by_id(GATE_ID)
	var payoff := _salvage_by_id(PAYOFF_ID)
	if gate.is_empty() or payoff.is_empty():
		_fail("missing source gate or payoff")
		return

	_main._player.global_position = gate["center"]
	_main._process(0.0)
	_main._update_status_label()
	if not _status_contains("Ripping current - need current stabilizer") or _main._world.is_salvage_collected(PAYOFF_ID):
		_fail("locked current state was not readable")
		return
	if not await _capture_pair(capture_dir, "current_locked", gate["center"] + POCKET_CAMERA_OFFSET, POCKET_CAMERA_ZOOM):
		return

	var profile = _main._anomaly_survey.profile_state()
	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false)
	profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 4,
		ExpansionProfileState.COIL_MATERIAL_ID: 2,
	}, false)
	var cutter_build: Dictionary = profile.complete_material_project(
		_project_by_id(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID),
		false
	)
	if not bool(cutter_build.get("changed", false)):
		_fail("capture setup could not build cutter")
		return
	_main._material_project.on_map_loaded(_main._world)
	_main._player.global_position = _main._world.get_extraction_center()
	_main._expedition_day_state.request_end_day("voluntary")
	_main._process(0.0)
	_main._update_status_label()
	var debrief_text: String = _main._result_label.text if _main._result_label != null else ""
	if debrief_text.find("P: Build current stabilizer") == -1 or debrief_text.find("N: Start day 2") == -1:
		_fail("stabilizer-ready debrief omitted P/N actions")
		return
	if not await _capture_pair(
		capture_dir,
		"project_ready_debrief",
		_main._world.get_extraction_center() + DEBRIEF_CAMERA_OFFSET,
		DEBRIEF_CAMERA_ZOOM
	):
		return

	var build: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_P)
	if not bool(build.get("changed", false)) or not profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID):
		_fail("project-ready setup could not build stabilizer")
		return
	var next_day: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_N)
	if not bool(next_day.get("changed", false)):
		_fail("capture setup could not start next day")
		return
	_prepare_runtime_nodes()
	gate = _gate_by_id(GATE_ID)
	payoff = _salvage_by_id(PAYOFF_ID)
	var gate_block: Dictionary = _main._current_gate.gate_blocks_position(
		_main._world,
		gate["center"],
		Callable(_main, "_has_upgrade_id"),
		Callable(profile, "has_capability")
	)
	if not gate_block.is_empty():
		_fail("stabilizer did not unlock capture crossing")
		return
	_main._last_status_note = ""
	_main._player.global_position = gate["center"] + Vector2(50, 0)
	_main._process(0.0)
	_main._update_status_label()
	if not await _capture_pair(capture_dir, "current_unlocked", gate["center"] + POCKET_CAMERA_OFFSET, POCKET_CAMERA_ZOOM):
		return

	_main._player.global_position = payoff["center"]
	_main._process(0.0)
	_main._update_status_label()
	if not _main._sortie_state.held_salvage_ids.has(PAYOFF_ID) or _main._last_status_note != "Upper-right current pocket +300":
		_fail("held payoff state was not readable")
		return
	if not await _capture_pair(capture_dir, "payoff_held", gate["center"] + POCKET_CAMERA_OFFSET, POCKET_CAMERA_ZOOM):
		return

	_main._player.global_position = _main._world.get_extraction_center()
	_main._process(0.0)
	_main._update_status_label()
	if _main._sortie_state.held_salvage != 0 or not _main._banked_salvage_ids.has(PAYOFF_ID) or _main._banked_score != 300:
		_fail("banked payoff state was not readable")
		return
	if not await _capture_pair(
		capture_dir,
		"payoff_banked",
		_main._world.get_extraction_center() + DEBRIEF_CAMERA_OFFSET,
		DEBRIEF_CAMERA_ZOOM
	):
		return

	print("Saved Expansion 04 current-pocket review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
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


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _main._world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _main._world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _status_contains(text: String) -> bool:
	return _main._status_label != null and _main._status_label.text.find(text) != -1


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "Expansion04CurrentPocketCaptureCamera"
	camera.position_smoothing_enabled = false
	_main.add_child(camera)
	camera.make_current()
	return camera


func _capture_pair(capture_dir: String, state_id: String, camera_position: Vector2, camera_zoom: Vector2) -> bool:
	_frame_camera(camera_position, camera_zoom)
	for capture_spec in CAPTURE_SIZES:
		var expected_size: Vector2i = capture_spec["size"]
		_main.get_window().size = expected_size
		_camera.force_update_scroll()
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
	print("Saved Expansion 04 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Expansion 04 current-pocket capture failed: %s." % message)
	_main.get_tree().quit(1)
