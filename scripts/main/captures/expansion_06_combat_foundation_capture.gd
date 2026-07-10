extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")

const CAPTURE_SIZES := [
	{"suffix": "1280x720", "size": Vector2i(1280, 720)},
	{"suffix": "1920x1080", "size": Vector2i(1920, 1080)},
]
const HOSTILE_ID := ExpansionProfileState.SHOCK_PROD_TARGET_ID
const CAMERA_ZOOM := Vector2(1.05, 1.05)
const CAMERA_OFFSET := Vector2(-48, -112)
const RECIPE := {
	ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
	ExpansionProfileState.COIL_MATERIAL_ID: 1,
}

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	var encounter := _encounter()
	if encounter.is_empty():
		_fail("missing source encounter %s" % HOSTILE_ID)
		return
	_camera = _create_camera()
	var camera_position: Vector2 = (encounter.get("territory_rect", Rect2()) as Rect2).get_center() + CAMERA_OFFSET
	var home: Vector2 = encounter.get("home_center", Vector2.ZERO)
	var warning_position := home + Vector2(-80, 0)

	_main._player.global_position = warning_position
	_main._player.swim_in_direction(Vector2.RIGHT, 0.0)
	_main._process(0.0)
	_main._update_status_label()
	if _hostile_phase() != "warning" or not _status_contains("Territorial eel - watch the lunge") or not _status_contains("Shock prod locked"):
		_fail("unarmed warning state was not readable")
		return
	if not await _capture_pair(capture_dir, "unarmed_warning", camera_position):
		return

	_main._process(float(encounter.get("warning_seconds", 0.75)) + 0.01)
	_main._player.global_position = Vector2(60.5, 78.5) * float(_main._world.tile_size)
	_main._update_status_label()
	if _hostile_phase() != "lunge" or not _status_contains("Eel territory - retreat or evade"):
		_fail("unarmed lunge/evade state was not readable")
		return
	if not await _capture_pair(capture_dir, "unarmed_lunge", camera_position):
		return

	if not _unlock_shock_prod():
		return
	_main._hostiles.reset_for_failure(_main._world)
	_main._shock_prod.reset()
	_main._player_health.reset()
	_main._last_status_note = ""
	_main._player.global_position = home + Vector2(-60, 0)
	_main._player.swim_in_direction(Vector2.RIGHT, 0.0)
	_main._process(0.0)
	for expected_health in [2, 1]:
		if not _main._try_combat_attack() or int(_hostile_state().get("health", -1)) != expected_health:
			_fail("armed damage setup did not reach health %d" % expected_health)
			return
		if expected_health > 1:
			_main._shock_prod.update(ShockProdController.ATTACK_COOLDOWN_SECONDS)
	_main._update_status_label()
	if _hostile_phase() != "warning" or not _status_contains("Shock prod hit: eel health 1/3 (-1)") or not _status_contains("Health 3/3"):
		_fail("armed damage state was not readable")
		return
	if not await _capture_pair(capture_dir, "armed_damage", camera_position):
		return

	print("Saved Expansion 06 combat-foundation review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_slice_01":
		_fail("requires the default production slice")
		return false
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = true
	return true


func _unlock_shock_prod() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var discovery: Dictionary = profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false)
	if not bool(discovery.get("changed", false)) and not profile.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID):
		_fail("capture setup could not seed project discovery")
		return false
	for project_id in [
		ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID,
		ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID,
		ExpansionProfileState.SHOCK_PROD_PROJECT_ID,
	]:
		var deposit: Dictionary = profile.deposit_materials(RECIPE, false)
		if not bool(deposit.get("changed", false)):
			_fail("capture setup could not seed recipe for %s" % project_id)
			return false
		var build: Dictionary = profile.complete_material_project(_project_by_id(project_id), false)
		if not bool(build.get("changed", false)):
			_fail("capture setup could not build %s: %s" % [project_id, str(build)])
			return false
	_main._material_project.on_map_loaded(_main._world)
	_main._cutter_salvage.on_map_loaded(_main._world)
	_main._update_status_label()
	if not profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID):
		_fail("capture setup did not unlock shock prod")
		return false
	return true


func _encounter() -> Dictionary:
	for encounter in _main._world.get_hostile_encounters():
		if str(encounter.get("id", "")) == HOSTILE_ID:
			return encounter
	return {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _main._world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _hostile_state() -> Dictionary:
	return _main._hostiles.state_for(HOSTILE_ID)


func _hostile_phase() -> String:
	return str(_hostile_state().get("phase", "missing"))


func _status_contains(text: String) -> bool:
	return _main._status_label != null and _main._status_label.text.find(text) != -1


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "Expansion06CombatFoundationCaptureCamera"
	camera.position_smoothing_enabled = false
	_main.add_child(camera)
	camera.make_current()
	return camera


func _capture_pair(capture_dir: String, state_id: String, camera_position: Vector2) -> bool:
	_frame_camera(camera_position)
	for capture_spec in CAPTURE_SIZES:
		var expected_size: Vector2i = capture_spec["size"]
		_main.get_window().size = expected_size
		_camera.force_update_scroll()
		await _settle_frames()
		var image: Image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			await _settle_frames()
			image = _main.get_viewport().get_texture().get_image()
		if image.get_size() != expected_size:
			_fail("capture %s rendered %s expected %s" % [state_id, str(image.get_size()), str(expected_size)])
			return false
		if not _image_is_usable(image, expected_size):
			_fail("capture %s appears blank or contains black render regions" % state_id)
			return false
		var filename := "production_slice_01_%s_%s.png" % [state_id, str(capture_spec["suffix"])]
		if not _save_capture(capture_dir, filename, image):
			return false
	return true


func _frame_camera(position: Vector2) -> void:
	_camera.zoom = CAMERA_ZOOM
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


func _sampled_color_count(image: Image) -> int:
	var colors := {}
	for x_step in range(1, 8):
		for y_step in range(1, 8):
			var x := int(float(image.get_width() - 1) * float(x_step) / 8.0)
			var y := int(float(image.get_height() - 1) * float(y_step) / 8.0)
			colors[image.get_pixel(x, y).to_html(true)] = true
	return colors.size()


func _sampled_black_count(image: Image) -> int:
	var count := 0
	for x_step in range(1, 8):
		for y_step in range(1, 8):
			var x := int(float(image.get_width() - 1) * float(x_step) / 8.0)
			var y := int(float(image.get_height() - 1) * float(y_step) / 8.0)
			var color := image.get_pixel(x, y)
			if color.r < 0.01 and color.g < 0.01 and color.b < 0.01:
				count += 1
	return count


func _image_is_usable(image: Image, expected_size: Vector2i) -> bool:
	return image.get_size() == expected_size and _sampled_color_count(image) >= 4 and _sampled_black_count(image) <= 4


func _save_capture(capture_dir: String, filename: String, image: Image) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s" % [capture_dir, filename]
	var error := image.save_png(output_path)
	if error != OK:
		_fail("could not save %s (error %d)" % [output_path, error])
		return false
	print("Saved Expansion 06 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Expansion 06 combat-foundation capture failed: %s." % message)
	_main.get_tree().quit(1)
