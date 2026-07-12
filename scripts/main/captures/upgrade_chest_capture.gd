extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const CHEST_ID := "lower_loop_upgrade_chest"
const CONNECTOR_ID := "lower_left_loop_connector"
const EAST_GATE_ID := "upper_right_current_pocket_gate"
const CAPTURE_SIZES := [
	{"suffix": "1280x720", "window_size": Vector2i(1280, 720), "canvas_size": Vector2i(1280, 720)},
	{"suffix": "mobile_844x390", "window_size": Vector2i(844, 390), "canvas_size": Vector2i(693, 390)},
]
const TRACKER_CAMERA_ZOOM := Vector2(1.08, 1.08)
const TRACKER_CAMERA_OFFSET := Vector2(80, -56)
const RELAY_CAMERA_ZOOM := Vector2(1.0, 1.0)
const RELAY_CAMERA_OFFSET := Vector2(176, -80)
const EAST_CAMERA_OFFSET := Vector2(-120, -64)

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_camera = _create_camera()
	var chest := _container_by_id(CHEST_ID)
	var connector := _connector_by_id(CONNECTOR_ID)
	var east_gate := _gate_by_id(EAST_GATE_ID)
	if chest.is_empty() or connector.is_empty() or east_gate.is_empty():
		_fail("missing blueprint chest, lower-left connector, or east current")
		return
	if not _prepare_blueprint_prompt_state(chest):
		return
	if not await _capture_pair(capture_dir, "blueprint_interaction_prompt", chest["center"] + TRACKER_CAMERA_OFFSET, TRACKER_CAMERA_ZOOM):
		return
	if not _prepare_tracker_state(chest):
		return
	if not await _capture_pair(capture_dir, "fins_project_tracker", chest["center"] + TRACKER_CAMERA_OFFSET, TRACKER_CAMERA_ZOOM):
		return
	if not _prepare_relay_state(connector):
		return
	if not await _capture_pair(capture_dir, "post_fins_relay_prompt", connector["center"] + RELAY_CAMERA_OFFSET, RELAY_CAMERA_ZOOM):
		return
	if not _prepare_east_barrier_state(east_gate):
		return
	if not await _capture_pair(capture_dir, "east_stabilizer_barrier", east_gate["center"] + EAST_CAMERA_OFFSET, RELAY_CAMERA_ZOOM):
		return
	print("Saved blueprint-fins journey review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_slice_01":
		_fail("requires the default production slice")
		return false
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false
	return true


func _prepare_tracker_state(chest: Dictionary) -> bool:
	_main._player.global_position = chest["center"]
	_main._process(0.0)
	var profile = _main._anomaly_survey.profile_state()
	if not _main._try_progression_container_interaction():
		_fail("E interaction path did not open the blueprint chest")
		return false
	if not profile.has_completed_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID):
		_fail("blueprint chest did not recover the fins plan")
		return false
	var deposit: Dictionary = profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1}, false)
	if not bool(deposit.get("changed", false)):
		_fail("could not seed one banked titanium")
		return false
	var rubber := _active_material(ExpansionProfileState.RUBBER_MATERIAL_ID)
	if rubber.is_empty():
		_fail("active day has no guaranteed rubber")
		return false
	_main._player.global_position = rubber["center"]
	_main._process(0.0)
	_main._player.global_position = chest["center"]
	_main._last_status_note = "Blueprint recovered: Propulsion fins"
	_main._update_status_label()
	var tracker = _main._progression_project_tracker
	var tracker_text: String = tracker.snapshot_text() if tracker != null else ""
	if tracker == null or not tracker.visible or tracker_text.find("Titanium  1/2 banked") == -1 or tracker_text.find("Rubber  0/1 banked  (+1 held)") == -1:
		_fail("project tracker did not show distinct banked/held recipe state: %s" % tracker_text)
		return false
	return true


func _prepare_blueprint_prompt_state(chest: Dictionary) -> bool:
	_main._player.global_position = chest["center"]
	_main._process(0.0)
	var profile = _main._anomaly_survey.profile_state()
	var status: String = _main._status_label.text if _main._status_label != null else ""
	var chest_node: Node = _main._world.find_child(CHEST_ID, true, false)
	if profile.has_completed_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID) or _main._progression_containers.is_opened(CHEST_ID):
		_fail("blueprint auto-recovered before explicit interaction")
		return false
	if status.find("E: Recover propulsion fins blueprint") == -1:
		_fail("explicit blueprint prompt was not visible: %s" % status)
		return false
	if chest_node == null or str(chest_node.get_meta("cue_kind", "")) != "blueprint":
		_fail("blueprint-specific chest cue is missing")
		return false
	return true


func _prepare_relay_state(connector: Dictionary) -> bool:
	var profile = _main._anomaly_survey.profile_state()
	_main._material_runtime.discard_unbanked("capture_transition")
	var deposit: Dictionary = profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 1,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	}, false)
	if not bool(deposit.get("changed", false)):
		_fail("could not seed remaining fins recipe")
		return false
	var project := _project_by_id(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID)
	var build: Dictionary = profile.complete_material_project(project, false)
	if not bool(build.get("changed", false)):
		_fail("could not build fins for relay state: %s" % str(build))
		return false
	_main._material_project.on_map_loaded(_main._world)
	_main._player.global_position = connector["center"]
	_main._last_status_note = ""
	_main._update_status_label()
	var status: String = _main._status_label.text if _main._status_label != null else ""
	if status.find("E: Enter Lower-left relay") == -1 or status.find("Shock prod locked") != -1:
		_fail("post-fins relay prompt was not readable: %s" % status)
		return false
	return true


func _prepare_east_barrier_state(gate: Dictionary) -> bool:
	_main._player.global_position = gate["center"]
	_main._last_status_note = ""
	_main._process(0.0)
	var status: String = _main._status_label.text if _main._status_label != null else ""
	if status.find("propulsion fins do not work here") == -1:
		_fail("east current did not distinguish its stabilizer requirement: %s" % status)
		return false
	return true


func _active_material(material_id: String) -> Dictionary:
	var active_ids: Array = _main._world.get_material_candidate_report().get("active_ids", [])
	for candidate in _main._world.get_material_candidates():
		if str(candidate.get("material_id", "")) == material_id and active_ids.has(str(candidate.get("id", ""))):
			return candidate
	return {}


func _container_by_id(container_id: String) -> Dictionary:
	for container in _main._world.get_progression_containers():
		if str(container.get("id", "")) == container_id:
			return container
	return {}


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _main._world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _main._world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _main._world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "BlueprintFinsJourneyCaptureCamera"
	camera.position_smoothing_enabled = false
	_main.add_child(camera)
	camera.make_current()
	return camera


func _capture_pair(capture_dir: String, state_id: String, camera_position: Vector2, camera_zoom: Vector2) -> bool:
	_frame_camera(camera_position, camera_zoom)
	for spec in CAPTURE_SIZES:
		var window_size: Vector2i = spec["window_size"]
		var expected_size: Vector2i = spec["canvas_size"]
		_main.get_window().size = window_size
		_camera.force_update_scroll()
		await _settle_frames()
		var image: Image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			await _settle_frames()
			image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			_fail("capture %s rendered blank or wrong-sized image %s" % [state_id, str(image.get_size())])
			return false
		var filename := "production_slice_01_%s_%s.png" % [state_id, str(spec["suffix"])]
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


func _image_is_usable(image: Image, expected_size: Vector2i) -> bool:
	if image.get_size() != expected_size:
		return false
	var colors := {}
	var black_count := 0
	for x_step in range(1, 8):
		for y_step in range(1, 8):
			var x := int(float(image.get_width() - 1) * float(x_step) / 8.0)
			var y := int(float(image.get_height() - 1) * float(y_step) / 8.0)
			var color := image.get_pixel(x, y)
			colors[color.to_html(true)] = true
			if color.r < 0.01 and color.g < 0.01 and color.b < 0.01:
				black_count += 1
	return colors.size() >= 4 and black_count <= 4


func _save_capture(capture_dir: String, filename: String, image: Image) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s" % [capture_dir, filename]
	var error := image.save_png(output_path)
	if error != OK:
		_fail("could not save %s (error %d)" % [output_path, error])
		return false
	print("Saved blueprint-fins capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Blueprint-fins journey capture failed: %s." % message)
	_main.get_tree().quit(1)
