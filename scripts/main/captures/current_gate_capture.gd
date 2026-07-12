extends RefCounted

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")

const GATE_ID := "upper_right_current_pocket_gate"
const EXPECTED_PROMPT := "Strong east current - need propulsion fins"
const CAPTURE_ZOOM := Vector2(1.1, 1.1)
const CAMERA_OFFSET := Vector2(96, -24)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_slice_01":
		_fail("requires the default production slice")
		return
	var gate := _gate_by_id(GATE_ID)
	if gate.is_empty():
		_fail("requires gate %s" % GATE_ID)
		return

	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	_main._anomaly_survey = AnomalySurveyRuntime.new(_main._progression_runtime, false, profile)
	_main._material_project = MaterialProjectRuntime.new(profile)
	_main._anomaly_survey.on_map_loaded(_main._world)
	_main._material_project.on_map_loaded(_main._world)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false
	_main._player.set_physics_process(false)

	var camera := Camera2D.new()
	camera.name = "CurrentGateCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = gate["center"] + CAMERA_OFFSET

	_main._player.global_position = gate["center"]
	_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	if _status_text().find(EXPECTED_PROMPT) == -1:
		_fail("blocked current prompt missing: %s" % _status_text())
		return
	if not await _save_capture(capture_dir, "east_current_before_fins"):
		return

	profile.complete_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID, false)
	profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	}, false)
	var build: Dictionary = profile.complete_material_project(
		_project_by_id(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID),
		false
	)
	if not bool(build.get("changed", false)):
		_fail("could not build capture fins fixture: %s" % str(build))
		return
	_main._material_project.on_map_loaded(_main._world)
	_main._current_gate.reset()
	_main._last_status_note = "Fins installed - east current passable"
	_main._player.global_position = gate["center"] + Vector2(40, 0)
	_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	if not _main._current_gate.blocking_gate().is_empty():
		_fail("after-fins capture remained blocked")
		return
	if not _main._world.get_world_connector_at(gate["center"]).is_empty():
		_fail("standard current capture overlaps an E connector")
		return
	if not await _save_capture(capture_dir, "east_current_after_fins"):
		return

	print("Saved passive current captures: before_fins + after_fins under %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _save_capture(capture_dir: String, suffix: String) -> bool:
	await _settle_frames()
	var image: Image = _main.get_viewport().get_texture().get_image()
	if not _image_is_usable(image):
		await _settle_frames()
		image = _main.get_viewport().get_texture().get_image()
	if not _image_is_usable(image):
		_fail("capture %s appears blank or contains black render regions" % suffix)
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_%s.png" % [capture_dir, _safe_filename(_main._world.map_id), suffix]
	var save_error: int = image.save_png(output_path)
	if save_error != OK:
		_fail("could not save %s" % output_path)
		return false
	print("Saved current-gate capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _settle_frames() -> void:
	RenderingServer.force_draw()
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await RenderingServer.frame_post_draw


func _image_is_usable(image: Image) -> bool:
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


func _status_text() -> String:
	return _main._status_label.text if _main._status_label != null else ""


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output


func _fail(message: String) -> void:
	push_error("Current-gate capture failed: %s." % message)
	_main.get_tree().quit(1)
