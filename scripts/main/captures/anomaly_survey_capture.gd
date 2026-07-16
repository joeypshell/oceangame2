extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const SURVEY_TARGET_ID := "lower_right_anomaly_survey"
const SURVEY_MAP_PATH := "res://maps/production_slice_02.greybox.json"
const ORIGIN_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const PARTIAL_SECONDS := 1.5
const SURVEY_CAMERA_ZOOM := Vector2(1.15, 1.15)
const SURVEY_CAMERA_OFFSET := Vector2(120, -100)
const COMMIT_CAMERA_ZOOM := Vector2(0.9, 0.9)
const COMMIT_CAMERA_OFFSET := Vector2(160, 160)

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_scanner_and_target():
		return
	var target := _survey_target_by_id(SURVEY_TARGET_ID)
	if target.is_empty():
		_fail("missing source target %s" % SURVEY_TARGET_ID)
		return

	_main._player.global_position = target["center"]
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._anomaly_survey.scanner_action(_main._world, _main._player)
	_main._process(PARTIAL_SECONDS)
	_main.set_process(false)
	_main._update_status_label()
	var partial_progress := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	if partial_progress < 0.45 or partial_progress > 0.55 or not _main._last_status_note.begins_with("Survey anomaly"):
		_fail("expected readable partial survey state, progress=%.2f note='%s'" % [partial_progress, _main._last_status_note])
		return

	_camera = _create_camera("AnomalySurveyProgressCaptureCamera")
	_frame_camera(target["center"] + SURVEY_CAMERA_OFFSET, SURVEY_CAMERA_ZOOM)
	await _settle_frames()
	if not _save_capture(capture_dir, "production_slice_02_anomaly_survey_progress.png"):
		return

	var remaining_seconds := maxf(0.1, float(target.get("interaction_seconds", 0.0)) - PARTIAL_SECONDS + 0.1)
	_main._process(remaining_seconds)
	if not _main._anomaly_survey.has_pending_discovery():
		_fail("survey completion did not create pending discovery")
		return
	_main._anomaly_survey.on_map_transition("production_slice_01")
	_main._load_playable_map(ORIGIN_MAP_PATH, false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._process(0.0)
	_main._update_status_label()
	var result_text: String = _main._anomaly_survey.result_text()
	if result_text.find("Cutter plan recovered:") == -1 or result_text.find("Project unlocked:") == -1:
		_fail("commit feedback missing from result: %s" % result_text)
		return

	_frame_camera(_main._world.get_extraction_center() + COMMIT_CAMERA_OFFSET, COMMIT_CAMERA_ZOOM)
	await _settle_frames()
	if not _save_capture(capture_dir, "production_slice_01_anomaly_discovery_commit.png"):
		return
	print("Saved anomaly survey review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_scanner_and_target() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_slice_01":
		_fail("capture requires the default production slice")
		return false
	var profile = _main._anomaly_survey.profile_state()
	profile.complete_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID, false)
	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1, ExpansionProfileState.COIL_MATERIAL_ID: 1}, false)
	var unlock: Dictionary = profile.complete_material_project(_project_by_id(ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID), false)
	if not bool(unlock.get("changed", false)):
		_fail("could not prepare scanner: %s" % str(unlock))
		return false
	_main._load_playable_map(SURVEY_MAP_PATH, false)
	return _main._world.map_id == "production_slice_02"


func _project_by_id(project_id: String) -> Dictionary:
	for project in _main._world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _survey_target_by_id(target_id: String) -> Dictionary:
	for target in _main._world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _create_camera(camera_name: String) -> Camera2D:
	var camera := Camera2D.new()
	camera.name = camera_name
	camera.position_smoothing_enabled = false
	_main.add_child(camera)
	camera.make_current()
	return camera


func _frame_camera(position: Vector2, zoom: Vector2) -> void:
	_camera.zoom = zoom
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_main._world.map_pixel_size.x)
	_camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_camera.position = position


func _settle_frames() -> void:
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame


func _save_capture(capture_dir: String, filename: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s" % [capture_dir, filename]
	var image: Image = _main.get_viewport().get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		_fail("could not save %s (error %d)" % [output_path, error])
		return false
	print("Saved anomaly survey capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Anomaly survey capture failed: %s." % message)
	_main.get_tree().quit(1)
