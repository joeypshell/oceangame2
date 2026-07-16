extends RefCounted

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")

const CAPTURE_SIZES := [
	{"suffix": "1280x720", "size": Vector2i(1280, 720)},
	{"suffix": "1920x1080", "size": Vector2i(1920, 1080)},
]
const TARGET_ID := "upper_right_mineral_trace_survey"
const RESEARCHED_MATERIAL_ID := "material_coil_deep_cache"
const CLUE_TEXT := "Mineral trace | Composition unknown"
const FINDING_TEXT := "Research: coils favor deep-cache machinery"
const LEAD_TEXT := "Research lead | Coils near deep-cache machinery"
const PARTIAL_SECONDS := 1.5
const TARGET_CAMERA_ZOOM := Vector2(1.15, 1.15)
const TARGET_CAMERA_OFFSET := Vector2(-96, -48)
const BOAT_CAMERA_ZOOM := Vector2(0.9, 0.9)
const BOAT_CAMERA_OFFSET := Vector2(128, 148)
const MATERIAL_CAMERA_ZOOM := Vector2(1.05, 1.05)
const MATERIAL_CAMERA_OFFSET := Vector2(-112, -96)

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_camera = _create_camera()
	var target := _survey_target_by_id(TARGET_ID)
	if target.is_empty():
		_fail("missing source target %s" % TARGET_ID)
		return

	_main._last_status_note = ""
	_main._player.global_position = target["center"]
	_main._update_status_label()
	if not _status_contains(CLUE_TEXT) or _main._anomaly_survey.has_pending_discovery():
		_fail("incomplete mineral clue was not readable")
		return
	if not await _capture_pair(capture_dir, "mineral_clue", target["center"] + TARGET_CAMERA_OFFSET, TARGET_CAMERA_ZOOM):
		return

	_main._anomaly_survey.scanner_action(_main._world, _main._player)
	_main._process(PARTIAL_SECONDS)
	_main._update_status_label()
	var progress := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	if progress < 0.45 or progress > 0.55 or not _status_contains("Survey mineral trace 50%"):
		_fail("partial mineral survey was not readable: %.2f" % progress)
		return
	if not await _capture_pair(capture_dir, "mineral_survey_partial", target["center"] + TARGET_CAMERA_OFFSET, TARGET_CAMERA_ZOOM):
		return

	_main._process(float(target.get("interaction_seconds", 0.0)) - PARTIAL_SECONDS + 0.1)
	if not _main._anomaly_survey.has_pending_discovery():
		_fail("survey completion did not create pending research")
		return
	_main._player.global_position = _main._world.get_extraction_center()
	_main._process(0.0)
	_main._update_status_label()
	if _main._anomaly_survey.has_pending_discovery() or not _main._anomaly_survey.has_completed_research() or _main._anomaly_survey.result_text() != FINDING_TEXT:
		_fail("boat commit finding was not readable")
		return
	if not await _capture_pair(
		capture_dir,
		"research_committed",
		_main._world.get_extraction_center() + BOAT_CAMERA_OFFSET,
		BOAT_CAMERA_ZOOM
	):
		return

	if not _main._expedition_day_state.request_end_day("voluntary"):
		_fail("capture setup could not end the research day")
		return
	_main._process(0.0)
	var next_day: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_N)
	if not bool(next_day.get("changed", false)) or _main._expedition_day_state.day_number != 2:
		_fail("capture setup could not start the following day")
		return
	_prepare_runtime_nodes()
	var material := _material_by_id(RESEARCHED_MATERIAL_ID)
	if material.is_empty() or not _main._world.get_material_candidate_report().get("active_ids", []).has(RESEARCHED_MATERIAL_ID):
		_fail("following day did not select researched deep-cache coil")
		return
	_main._last_status_note = ""
	_main._player.global_position = material["center"] + Vector2(0, -40)
	_main._update_status_label()
	if not _status_contains(LEAD_TEXT) or not _status_contains("Materials Ti 0 (+0) | Coil 0 (+0)"):
		_fail("following-day material lead was not readable")
		return
	if not await _capture_pair(
		capture_dir,
		"research_habitat_lead",
		material["center"] + MATERIAL_CAMERA_OFFSET,
		MATERIAL_CAMERA_ZOOM
	):
		return

	print("Saved Expansion 05 practical-research review captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_slice_01":
		_fail("requires the default production slice")
		return false
	_main.set_process(false)
	_prepare_runtime_nodes()
	var profile = _main._anomaly_survey.profile_state()
	if not bool(ReviewProgressionFixture.complete_capability(_main, ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID).get("ready", false)):
		_fail("capture setup could not unlock scanner")
		return false
	if not bool(profile.complete_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID, false).get("changed", false)):
		_fail("capture setup could not seed fins blueprint")
		return false
	if not bool(profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	}, false).get("changed", false)):
		_fail("capture setup could not seed fins materials")
		return false
	var build: Dictionary = profile.complete_material_project(_project_by_id(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID), false)
	if not bool(build.get("changed", false)):
		_fail("capture setup could not build fins: %s" % str(build))
		return false
	_main._anomaly_survey.on_map_loaded(_main._world)
	_main._material_project.on_map_loaded(_main._world)
	_main._cutter_salvage.on_map_loaded(_main._world)
	return true


func _prepare_runtime_nodes() -> void:
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false


func _survey_target_by_id(target_id: String) -> Dictionary:
	for target in _main._world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _material_by_id(material_id: String) -> Dictionary:
	for candidate in _main._world.get_material_candidates():
		if str(candidate.get("id", "")) == material_id:
			return candidate
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
	camera.name = "Expansion05PracticalResearchCaptureCamera"
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
	print("Saved Expansion 05 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Expansion 05 practical-research capture failed: %s." % message)
	_main.get_tree().quit(1)
