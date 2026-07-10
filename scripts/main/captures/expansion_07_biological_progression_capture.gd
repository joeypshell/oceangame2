extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const CAPTURE_SIZES := [
	{"suffix": "1280x720", "size": Vector2i(1280, 720)},
	{"suffix": "1920x1080", "size": Vector2i(1920, 1080)},
]
const PASSIVE_ID := "upper_right_glow_anemone_sample"
const HOSTILE_SOURCE_ID := "deep_cache_eel_electrocyte_harvest"
const HOSTILE_ID := ExpansionProfileState.SHOCK_PROD_TARGET_ID
const CAPACITOR_PROJECT_ID := ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID
const PARTIAL_SECONDS := 0.75
const STANDARD_RECIPE := {
	ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
	ExpansionProfileState.COIL_MATERIAL_ID: 1,
}
const CAPACITOR_RECIPE := {
	ExpansionProfileState.COIL_MATERIAL_ID: 1,
	ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1,
	ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID: 1,
}
const PASSIVE_CAMERA_ZOOM := Vector2(1.15, 1.15)
const PASSIVE_CAMERA_OFFSET := Vector2(-112, -64)
const HOSTILE_CAMERA_ZOOM := Vector2(1.05, 1.05)
const HOSTILE_CAMERA_OFFSET := Vector2(-48, -112)

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_camera = _create_camera()
	var passive := _biological_source(PASSIVE_ID)
	var harvest := _biological_source(HOSTILE_SOURCE_ID)
	var encounter := _encounter()
	if passive.is_empty() or harvest.is_empty() or encounter.is_empty():
		_fail("missing Expansion 07 source state")
		return

	if not await _capture_passive_sample(capture_dir, passive):
		return
	if not await _capture_post_defeat_harvest(capture_dir, harvest, encounter):
		return
	if not await _capture_capacitor_interrupt(capture_dir, encounter):
		return

	print("Saved Expansion 07 biological-progression review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _capture_passive_sample(capture_dir: String, passive: Dictionary) -> bool:
	_main._last_status_note = ""
	_main._player.global_position = passive.get("center", Vector2.ZERO)
	_main._process(PARTIAL_SECONDS)
	_main._update_status_label()
	var progress := float(_main._biological_resources.report().get("progress_seconds", 0.0))
	if progress < 0.7 or progress > 0.8 or not _status_contains("Sampling glow anemone 0.8/1.5s"):
		_fail("passive sample progress was not readable: %.2f" % progress)
		return false
	return await _capture_pair(
		capture_dir,
		"passive_sample_partial",
		passive.get("center", Vector2.ZERO) + PASSIVE_CAMERA_OFFSET,
		PASSIVE_CAMERA_ZOOM
	)


func _capture_post_defeat_harvest(capture_dir: String, harvest: Dictionary, encounter: Dictionary) -> bool:
	_main._biological_resources.cancel_interaction("capture_transition")
	for _index in range(3):
		_main._hostiles.apply_weapon_hit(_main._world, HOSTILE_ID, 1)
	if _hostile_phase() != "defeated":
		_fail("post-defeat capture setup did not defeat the eel")
		return false
	_main._last_status_note = ""
	_main._player.global_position = _hostile_state().get("position", harvest.get("center", Vector2.ZERO))
	_main._process(PARTIAL_SECONDS)
	_main._update_status_label()
	var progress := float(_main._biological_resources.report().get("progress_seconds", 0.0))
	if progress < 0.7 or progress > 0.8 or not _status_contains("Harvesting electrocyte 0.8/1.5s"):
		_fail("post-defeat harvest progress was not readable: %.2f" % progress)
		return false
	var camera_position: Vector2 = (encounter.get("territory_rect", Rect2()) as Rect2).get_center() + HOSTILE_CAMERA_OFFSET
	return await _capture_pair(capture_dir, "post_defeat_harvest_partial", camera_position, HOSTILE_CAMERA_ZOOM)


func _capture_capacitor_interrupt(capture_dir: String, encounter: Dictionary) -> bool:
	_main._biological_resources.cancel_interaction("capture_transition")
	var profile = _main._anomaly_survey.profile_state()
	var deposit: Dictionary = profile.deposit_materials(CAPACITOR_RECIPE, false)
	if not bool(deposit.get("changed", false)):
		_fail("capture setup could not seed capacitor recipe")
		return false
	var build: Dictionary = profile.complete_material_project(_project_by_id(CAPACITOR_PROJECT_ID), false)
	if not bool(build.get("changed", false)):
		_fail("capture setup could not build capacitor: %s" % str(build))
		return false
	_main._material_project.on_map_loaded(_main._world)
	_main._hostiles.reset_for_failure(_main._world)
	_main._shock_prod.reset()
	_main._player_health.reset()
	_main._last_status_note = ""
	var home: Vector2 = encounter.get("home_center", Vector2.ZERO)
	_main._player.global_position = home + Vector2(-60, 0)
	_main._player.swim_in_direction(Vector2.RIGHT, 0.0)
	_main._process(0.0)
	if _hostile_phase() != "warning" or not _main._try_combat_attack():
		_fail("capacitor capture setup did not hit a warned eel")
		return false
	_main._update_status_label()
	if (
		_hostile_phase() != "recovery"
		or int(_hostile_state().get("health", 0)) != 2
		or not _status_contains("Shock prod capacitor hit: eel health 2/3 (-1), recovery")
		or not _status_contains("Shock prod +capacitor")
	):
		_fail("capacitor interrupt/recovery feedback was not readable")
		return false
	var camera_position: Vector2 = (encounter.get("territory_rect", Rect2()) as Rect2).get_center() + HOSTILE_CAMERA_OFFSET
	return await _capture_pair(capture_dir, "capacitor_interrupt_recovery", camera_position, HOSTILE_CAMERA_ZOOM)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_slice_01":
		_fail("requires the default production slice")
		return false
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = true
	var profile = _main._anomaly_survey.profile_state()
	if not bool(profile.unlock_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID, false).get("changed", false)):
		_fail("capture setup could not unlock scanner")
		return false
	if not bool(profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false).get("changed", false)):
		_fail("capture setup could not seed anomaly knowledge")
		return false
	for project_id in [
		ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID,
		ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID,
		ExpansionProfileState.SHOCK_PROD_PROJECT_ID,
	]:
		if not bool(profile.deposit_materials(STANDARD_RECIPE, false).get("changed", false)):
			_fail("capture setup could not seed recipe for %s" % project_id)
			return false
		var build: Dictionary = profile.complete_material_project(_project_by_id(project_id), false)
		if not bool(build.get("changed", false)):
			_fail("capture setup could not build %s: %s" % [project_id, str(build)])
			return false
	_main._anomaly_survey.on_map_loaded(_main._world)
	_main._material_project.on_map_loaded(_main._world)
	_main._cutter_salvage.on_map_loaded(_main._world)
	_main._biological_resources.on_map_loaded(_main._world, false)
	_main._update_status_label()
	return true


func _biological_source(source_id: String) -> Dictionary:
	for source in _main._world.get_biological_resource_sources():
		if str(source.get("id", "")) == source_id:
			return source
	return {}


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
	camera.name = "Expansion07BiologicalProgressionCaptureCamera"
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
	print("Saved Expansion 07 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Expansion 07 biological-progression capture failed: %s." % message)
	_main.get_tree().quit(1)
