extends RefCounted

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")

const MAP_ID := "production_level_01"
const BOAT_ENTRY_ID := "surface_boat_entry"
const PROJECT_ID := "dive_light_1_project"
const LIGHT_CAPABILITY_ID := "dive_light_1"
const SIGNAL_DISCOVERY_ID := "lower_right_signal_reef_discovery"
const TARGET_ID := "signal_reef_deep_harmonic_survey"
const ZONE_ID := "signal_reef_deep_harmonic_dark_zone"
const CAMERA_IDS := {
	"pre_light_requirement": "expansion_11_pre_light_route_context",
	"light_project_incomplete": "expansion_11_pending_boat_return",
	"post_light_survey_progress": "expansion_11_upgraded_harmonic_survey",
	"harmonic_pending_return": "expansion_11_pending_boat_return",
}
const CAPTURE_SIZES := [
	{"suffix": "1280x720", "window_size": Vector2i(1280, 720), "canvas_size": Vector2i(1280, 720)},
	{"suffix": "mobile_844x390", "window_size": Vector2i(844, 390), "canvas_size": Vector2i(693, 390)},
]
const PARTIAL_PROGRESS_RATIO := 0.5

var _main
var _camera: Camera2D


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_camera = _create_camera()
	var camera_tests := _camera_tests_by_id()
	if camera_tests.size() != 3:
		_fail("authored Expansion 11 camera tests are incomplete: %s" % str(camera_tests.keys()))
		return
	if not _prepare_prerequisite_profile():
		return
	if not _prepare_pre_light_requirement():
		return
	if not await _capture_pair(capture_dir, "pre_light_requirement", camera_tests[CAMERA_IDS["pre_light_requirement"]]):
		return
	if not _prepare_incomplete_project_debrief():
		return
	if not await _capture_pair(capture_dir, "light_project_incomplete", camera_tests[CAMERA_IDS["light_project_incomplete"]]):
		return
	if not _build_light_and_begin_next_day():
		return
	if not _prepare_partial_survey():
		return
	if not await _capture_pair(capture_dir, "post_light_survey_progress", camera_tests[CAMERA_IDS["post_light_survey_progress"]]):
		return
	if not _prepare_pending_return(camera_tests[CAMERA_IDS["harmonic_pending_return"]]):
		return
	if not await _capture_pair(capture_dir, "harmonic_pending_return", camera_tests[CAMERA_IDS["harmonic_pending_return"]]):
		return
	print("Saved Expansion 11 light-return captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != MAP_ID:
		_fail("requires the contiguous production level")
		return false
	if not _main._world.get_world_connectors().is_empty():
		_fail("full level unexpectedly contains connectors")
		return false
	var profile = _main._anomaly_survey.profile_state()
	var report: Dictionary = profile.report()
	if (
		str(profile.last_storage_report().get("status", "")) != "memory"
		or not report.get("completed_discoveries", []).is_empty()
		or not report.get("unlocked_capabilities", []).is_empty()
		or not report.get("material_inventory", {}).is_empty()
		or not report.get("completed_projects", []).is_empty()
	):
		_fail("capture did not start from isolated fresh profile state")
		return false
	_prepare_runtime_nodes()
	return true


func _prepare_runtime_nodes() -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._player.reset_motion()
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false


func _prepare_prerequisite_profile() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var fins: Dictionary = ReviewProgressionFixture.complete_capability(
		_main,
		ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID
	)
	var scanner: Dictionary = ReviewProgressionFixture.complete_capability(_main, ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID)
	var signal_result: Dictionary = profile.complete_discovery(SIGNAL_DISCOVERY_ID, false)
	var materials: Dictionary = profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 1,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}, false)
	if not bool(fins.get("ready", false)) or not bool(scanner.get("ready", false)) or not bool(signal_result.get("changed", false)) or not bool(materials.get("changed", false)):
		_fail("could not prepare fins, scanner, Signal Reef knowledge, and partial light recipe")
		return false
	_main._material_project.on_map_loaded(_main._world)
	_main._anomaly_survey.on_map_loaded(_main._world)
	_main._current_gate.reset()
	return _expect(
		_main._material_project.status_for(PROJECT_ID) == "incomplete"
		and profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 1
		and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 1
		and profile.material_quantity(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID) == 0,
		"partial light project is not exactly Ti1 + Coil1 + Gel0"
	)


func _prepare_pre_light_requirement() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var target := _survey_by_id(TARGET_ID)
	var zone := _zone_by_id(ZONE_ID)
	if target.is_empty() or zone.is_empty():
		_fail("harmonic target or dark zone is missing")
		return false
	_main._player.global_position = target["center"]
	_main._player.reset_motion()
	_main._last_status_note = ""
	_main._process(0.5)
	_main._update_status_label()
	var progress := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0))
	return _expect(
		not profile.has_capability(LIGHT_CAPABILITY_ID)
		and not bool(zone.get("readability_upgraded", false))
		and is_zero_approx(progress)
		and _status_text().count(str(target.get("clue_label", ""))) == 1,
		"pre-light route did not show the source requirement without progress"
	)


func _prepare_incomplete_project_debrief() -> bool:
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	_main._player.reset_motion()
	if not _main._expedition_day_state.request_end_day("voluntary"):
		_fail("could not request the light-project night debrief")
		return false
	_main._process(0.0)
	_main._update_status_label()
	var debrief_text: String = _main._result_label.text if _main._result_label != null else ""
	return _expect(
		_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF
		and debrief_text.find("Dive light project: Ti 1/1 | Coil 1/1 | Gel 0/1") != -1
		and debrief_text.find("Effect: improved visibility in dark water") != -1,
		"night debrief omitted the exact incomplete light recipe or effect"
	)


func _build_light_and_begin_next_day() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var gel: Dictionary = profile.deposit_materials({ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1}, false)
	_main._material_project.on_map_loaded(_main._world)
	if not bool(gel.get("changed", false)) or _main._material_project.status_for(PROJECT_ID) != "ready":
		_fail("final gel did not ready the exact light project")
		return false
	var build: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_P)
	if not bool(build.get("changed", false)) or not profile.has_capability(LIGHT_CAPABILITY_ID):
		_fail("night input did not build the durable light")
		return false
	var next_day: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_N)
	if not bool(next_day.get("changed", false)) or _main._world.map_id != MAP_ID:
		_fail("next day did not return to the contiguous production level")
		return false
	_prepare_runtime_nodes()
	var zone := _zone_by_id(ZONE_ID)
	return _expect(
		_main._expedition_day_state.day_number == 2
		and bool(zone.get("readability_upgraded", false))
		and profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 0
		and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 0
		and profile.material_quantity(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID) == 0,
		"next-day world did not apply the exact durable-light transaction"
	)


func _prepare_partial_survey() -> bool:
	var target := _survey_by_id(TARGET_ID)
	if target.is_empty() or str(target.get("state", "")) != "available":
		_fail("light-owned harmonic target is unavailable")
		return false
	_main._player.global_position = target["center"]
	_main._player.reset_motion()
	_main._last_status_note = ""
	_main._process(0.0)
	_main._anomaly_survey.scanner_action(_main._world, _main._player)
	_main._process(float(target.get("interaction_seconds", 0.0)) * PARTIAL_PROGRESS_RATIO)
	_main._update_status_label()
	var progress := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	return _expect(
		progress >= 0.49 and progress <= 0.51
		and _status_text().find("Survey deep harmonic 50%") != -1
		and _status_text().find("Stronger light required") == -1
		and not _main._anomaly_survey.has_pending_discovery(),
		"upgraded harmonic capture did not hold meaningful partial progress"
	)


func _prepare_pending_return(camera_test: Dictionary) -> bool:
	var target := _survey_by_id(TARGET_ID)
	_main._process(float(target.get("interaction_seconds", 0.0)))
	if not _main._anomaly_survey.has_pending_discovery():
		_fail("completed harmonic survey did not become pending")
		return false
	_main._player.global_position = Vector2(
		float(camera_test.get("center_x", 0.0)) * float(_main._world.tile_size),
		float(camera_test.get("center_y", 0.0)) * float(_main._world.tile_size)
	)
	_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	return _expect(
		_main._anomaly_survey.has_pending_discovery()
		and not _main._world.is_inside_boat(_main._player.global_position)
		and _status_text().find("Discovery pending | Return to surface boat") != -1,
		"pending discovery did not remain uncommitted on the boat approach"
	)


func _camera_tests_by_id() -> Dictionary:
	var values := {}
	var required_ids: Array = CAMERA_IDS.values()
	for camera_test in _main._world.camera_tests:
		var camera_id := str(camera_test.get("id", ""))
		if required_ids.has(camera_id):
			values[camera_id] = camera_test
	return values


func _create_camera() -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "Expansion11LightReturnCaptureCamera"
	camera.position_smoothing_enabled = false
	_main.add_child(camera)
	camera.make_current()
	return camera


func _capture_pair(capture_dir: String, state_id: String, camera_test: Dictionary) -> bool:
	for spec in CAPTURE_SIZES:
		var window_size: Vector2i = spec["window_size"]
		var expected_size: Vector2i = spec["canvas_size"]
		_main.get_window().size = window_size
		_frame_camera(camera_test)
		await _settle_frames()
		var image: Image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			await _settle_frames()
			image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			_fail("capture %s rendered blank or wrong-sized image %s" % [state_id, str(image.get_size())])
			return false
		var filename := "%s_%s_%s.png" % [MAP_ID, state_id, str(spec["suffix"])]
		if not _save_capture(capture_dir, filename, image):
			return false
	return true


func _frame_camera(camera_test: Dictionary) -> void:
	var tile_size: float = float(_main._world.tile_size)
	var zoom := float(camera_test.get("zoom", 0.5))
	_camera.zoom = Vector2(zoom, zoom)
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_main._world.map_pixel_size.x)
	_camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_camera.position = Vector2(
		float(camera_test.get("center_x", 0.0)) * tile_size,
		float(camera_test.get("center_y", 0.0)) * tile_size
	)
	_camera.make_current()
	_camera.force_update_scroll()


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
	print("Saved Expansion 11 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _survey_by_id(target_id: String) -> Dictionary:
	for target in _main._world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _zone_by_id(zone_id: String) -> Dictionary:
	for zone in _main._world.get_visibility_zones():
		if str(zone.get("id", "")) == zone_id:
			return zone
	return {}


func _status_text() -> String:
	return _main._status_label.text if _main._status_label != null else ""


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("Expansion 11 light-return capture failed: %s." % message)
	_main.get_tree().quit(1)
