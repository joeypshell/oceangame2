extends RefCounted

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayPresentation := preload("res://scripts/main/expedition_day_presentation.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const Expansion15CaptureRenderer := preload("res://scripts/main/captures/expansion_15_capture_renderer.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")

const MAP_ID := "production_level_01"
const RELAY_ID := "upper_left_wreck_relay_route"
const BLOOM_ID := "southwest_jellyfish_bloom"
const BOAT_CAMERA_ID := "production_level_boat_entry"
const ACTIVE_CAMERA_ID := "production_level_opening_gameplay"
const RELAY_GUIDANCE := "Plan: Follow the archive signal northwest"

var _main
var _renderer


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	var camera_tests := _camera_tests_by_id()
	if camera_tests.size() != 2:
		_fail("required boat and active camera tests are missing: %s" % str(camera_tests.keys()))
		return
	if not _prepare_two_lead_debrief():
		return
	_renderer = Expansion15CaptureRenderer.new(_main)

	if not _prepare_alternate_highlight():
		return
	if not await _renderer.capture_pair(
		capture_dir,
		"night_alternate_highlighted",
		camera_tests[BOAT_CAMERA_ID],
		true
	):
		return
	if not _prepare_pinned_relay():
		return
	if not await _renderer.capture_pair(
		capture_dir,
		"night_relay_pinned",
		camera_tests[BOAT_CAMERA_ID],
		true
	):
		return
	if not _build_and_begin_selected_day(camera_tests[ACTIVE_CAMERA_ID]):
		return
	if not await _renderer.capture_pair(
		capture_dir,
		"next_day_relay_guidance",
		camera_tests[ACTIVE_CAMERA_ID],
		false
	):
		return

	print("Saved Expansion 15 expedition-planning captures under: %s" % (
		ProjectSettings.globalize_path(capture_dir)
	))
	await _renderer.prepare_to_quit()
	_main.get_tree().quit(0)


func _prepare_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != MAP_ID:
		_fail("requires the contiguous production level")
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


func _prepare_two_lead_debrief() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var cutter: Dictionary = ReviewProgressionFixture.complete_capability(
		_main,
		ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID
	)
	var archive: Dictionary = profile.complete_discovery(
		ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID,
		false
	)
	var deposit: Dictionary = profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}, false)
	_main._material_project.on_map_loaded(_main._world)
	var requested: bool = _main._material_project.request_project(
		ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID
	)
	if (
		not bool(cutter.get("ready", false))
		or not bool(archive.get("changed", false))
		or not bool(deposit.get("changed", false))
		or not requested
		or _main._material_project.status_for(
			ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID
		) != "ready"
	):
		_fail("could not establish build-ready relay planning context")
		return false

	_main._player.global_position = _main._world.spawn_position
	_main._player.reset_motion()
	if not _main._expedition_day_state.request_end_day("voluntary"):
		_fail("could not request night debrief at the boat")
		return false
	_main._process(0.0)
	var plan_report: Dictionary = _main._refresh_expedition_plan()
	_main._update_status_label()
	var relay := _lead_by_id(plan_report, RELAY_ID)
	return _expect(
		_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF
		and plan_report.get("eligible_ids") == [RELAY_ID, BLOOM_ID]
		and relay.get("readiness_state") == "prepare"
		and str(relay.get("readiness_label", "")).find("ready to build") != -1,
		"debrief did not derive the build-ready relay and forecast bloom"
	)


func _prepare_alternate_highlight() -> bool:
	_press_key(KEY_TAB)
	var panel: Dictionary = _main._expedition_plan_panel.get_test_report()
	return _expect(
		bool(panel.get("visible", false))
		and panel.get("lead_ids") == [RELAY_ID, BLOOM_ID]
		and panel.get("highlighted_lead_id") == BLOOM_ID
		and str(panel.get("selected_lead_id", "")).is_empty()
		and _rows_show_both_leads(panel.get("row_texts", [])),
		"alternate-highlight state did not show both unpinned choices"
	)


func _prepare_pinned_relay() -> bool:
	_press_key(KEY_TAB)
	_press_key(KEY_E)
	var panel: Dictionary = _main._expedition_plan_panel.get_test_report()
	var rows: Array = panel.get("row_texts", [])
	var debrief_text: String = _main._result_label.text if _main._result_label != null else ""
	return _expect(
		_main._expedition_plan_state.selected_lead_id() == RELAY_ID
		and panel.get("highlighted_lead_id") == RELAY_ID
		and panel.get("selected_lead_id") == RELAY_ID
		and rows.size() == 2
		and str(rows[0]).find("[PINNED]") != -1
		and str(rows[0]).find("ready to build") != -1
		and debrief_text.find("P: Build") != -1,
		"pinned relay state omitted selection or project readiness"
	)


func _build_and_begin_selected_day(camera_test: Dictionary) -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var build: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_P)
	if (
		not bool(build.get("changed", false))
		or not profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID)
		or _main._expedition_plan_state.selected_lead_id() != RELAY_ID
	):
		_fail("building the stabilizer did not preserve the pinned relay")
		return false
	var next_day: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_N)
	if not bool(next_day.get("changed", false)):
		_fail("pinned relay did not permit next-day start")
		return false
	_prepare_runtime_nodes()
	_main._player.global_position = Vector2(
		float(camera_test.get("center_x", 0.0)) * float(_main._world.tile_size),
		float(camera_test.get("center_y", 0.0)) * float(_main._world.tile_size)
	)
	_main._player.reset_motion()
	_main._refresh_expedition_plan()
	_main._update_status_label()
	var guidance := ExpeditionDayPresentation.selected_plan_line(_main)
	var status_text: String = _main._status_label.text if _main._status_label != null else ""
	return _expect(
		_main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE
		and _main._expedition_day_state.day_number == 2
		and guidance == RELAY_GUIDANCE
		and status_text.find(RELAY_GUIDANCE) != -1
		and not bool(_main._expedition_plan_panel.get_test_report().get("visible", true)),
		"next-day capture omitted compact relay guidance or retained the planner"
	)


func _prepare_runtime_nodes() -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._player.reset_motion()
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false


func _camera_tests_by_id() -> Dictionary:
	var values := {}
	for camera_test in _main._world.camera_tests:
		var camera_id := str(camera_test.get("id", ""))
		if camera_id in [BOAT_CAMERA_ID, ACTIVE_CAMERA_ID]:
			values[camera_id] = camera_test
	return values


func _lead_by_id(report: Dictionary, lead_id: String) -> Dictionary:
	for value in report.get("eligible_leads", []):
		if typeof(value) == TYPE_DICTIONARY and str(value.get("lead_id", "")) == lead_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _rows_show_both_leads(rows: Array) -> bool:
	return (
		rows.size() == 2
		and str(rows[0]).find("Northwest Wreck Relay") != -1
		and str(rows[0]).find("MAIN PROGRESSION") != -1
		and str(rows[0]).find("Stabilizer required") != -1
		and str(rows[0]).find("Deeper-wreck lead + valuable core") != -1
		and str(rows[0]).find("ready to build") != -1
		and str(rows[1]).find("Southwest Jellyfish Bloom") != -1
		and str(rows[1]).find("OPTIONAL RESOURCE") != -1
		and str(rows[1]).find("No build") != -1
		and str(rows[1]).find("Jellyfish patrol") != -1
		and str(rows[1]).find("1 conductive coil") != -1
		and str(rows[1]).find("Forecast opportunity") != -1
	)


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	_main._unhandled_input(event)


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("Expansion 15 expedition-planning capture failed: %s." % message)
	_main.get_tree().quit(1)
