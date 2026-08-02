extends RefCounted

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const Expansion14CaptureRenderer := preload("res://scripts/main/captures/expansion_14_capture_renderer.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")
const ScannerPose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")
const ScannerSubjectCatalog := preload("res://scripts/main/scanner_subject_catalog.gd")

const MAP_ID := "production_level_01"
const BOAT_ENTRY_ID := "surface_boat_entry"
const RECORDER_ID := "southeast_wreck_recorder"
const ARCHIVE_SURVEY_ID := "southeast_wreck_archive_survey"
const PROJECT_ID := "current_stabilizer_project"
const CAPABILITY_ID := "current_stabilizer"
const GATE_ID := "upper_left_wreck_relay_current"
const CORE_ID := "upper_left_wreck_relay_core"
const RELAY_SURVEY_ID := "upper_left_wreck_relay_survey"
const CAMERA_IDS := {
	"archive": "expansion_14_archive_project_promise",
	"pre_current": "expansion_14_pre_stabilizer_current",
	"post_current": "expansion_14_post_stabilizer_current",
	"arrival": "expansion_14_wreck_relay_arrival",
	"survey": "expansion_14_relay_survey",
	"pending": "expansion_14_pending_boat_return",
}
const PARTIAL_SECONDS := 1.5

var _main
var _renderer
var _build_note := ""


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_capture():
		return
	_renderer = Expansion14CaptureRenderer.new(_main)
	var camera_tests := _camera_tests_by_id()
	if camera_tests.size() != CAMERA_IDS.size():
		_fail("authored Expansion 14 camera tests are incomplete: %s" % str(camera_tests.keys()))
		return
	if not _prepare_prerequisite_profile():
		return
	if not _commit_archive_result():
		return
	if not await _renderer.capture_pair(capture_dir, "archive_result", camera_tests[CAMERA_IDS["archive"]]):
		return
	if not _prepare_blocked_current():
		return
	if not await _renderer.capture_pair(capture_dir, "pre_stabilizer_current", camera_tests[CAMERA_IDS["pre_current"]]):
		return
	if not _prepare_project_promise():
		return
	if not await _renderer.capture_pair(capture_dir, "stabilizer_project_promise", camera_tests[CAMERA_IDS["archive"]]):
		return
	if not _build_stabilizer_and_begin_next_day():
		return
	if not _prepare_traversable_current():
		return
	if not await _renderer.capture_pair(capture_dir, "post_stabilizer_current", camera_tests[CAMERA_IDS["post_current"]]):
		return
	if not _prepare_current_identification():
		return
	if not await _renderer.capture_pair(capture_dir, "current_identification", camera_tests[CAMERA_IDS["post_current"]]):
		return
	_main._player.sync_scanner_presentation({"scanner_unlocked": false})
	if not _prepare_relay_arrival():
		return
	if not await _renderer.capture_pair(capture_dir, "wreck_relay_arrival", camera_tests[CAMERA_IDS["arrival"]]):
		return
	if not _prepare_mixed_full_cargo():
		return
	if not await _renderer.capture_pair(capture_dir, "mixed_full_cargo", camera_tests[CAMERA_IDS["arrival"]]):
		return
	if not _prepare_partial_survey():
		return
	if not await _renderer.capture_pair(capture_dir, "relay_survey_progress", camera_tests[CAMERA_IDS["survey"]]):
		return
	if not _prepare_pending_return():
		return
	if not await _renderer.capture_pair(capture_dir, "pending_boat_return", camera_tests[CAMERA_IDS["pending"]]):
		return
	print("Saved Expansion 14 archive-current captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	await _renderer.prepare_to_quit()
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
	for capability_id in [
		ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID,
		ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID,
		ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID,
	]:
		var prepared: Dictionary = ReviewProgressionFixture.complete_capability(_main, capability_id)
		if not bool(prepared.get("ready", false)):
			_fail("could not prepare %s" % capability_id)
			return false
	var light: Dictionary = ReviewProgressionFixture.complete_dive_light(_main)
	var abyssal: Dictionary = profile.complete_discovery(ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID, false)
	var recorder: Dictionary = profile.bank_tool_target(RECORDER_ID, false)
	if not bool(light.get("ready", false)) or not bool(abyssal.get("changed", false)) or not bool(recorder.get("changed", false)):
		_fail("could not prepare light, abyssal lead, and banked wreck-recorder clearance")
		return false
	_refresh_runtime_sources()
	_main._refresh_active_tools()
	return _expect(
		not profile.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID)
		and not profile.has_capability(CAPABILITY_ID)
		and _main._material_project.status_for(PROJECT_ID) == "knowledge_required"
		and _main._active_tools.selected_tool_id() == ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		"prerequisites exposed the archive result or stabilizer early"
	)


func _refresh_runtime_sources() -> void:
	_main._material_project.on_map_loaded(_main._world)
	_main._anomaly_survey.on_map_loaded(_main._world)
	_main._cutter_salvage.on_map_loaded(_main._world)
	_main._pressure_zone.on_map_loaded(_main._world)
	_main._current_gate.reset()


func _commit_archive_result() -> bool:
	var target := _survey_by_id(ARCHIVE_SURVEY_ID)
	if target.is_empty() or not bool(ScannerPose.new().place(_main._world, _main._player, target).get("found", false)):
		_fail("archive survey has no collision-clear scanner pose")
		return false
	var activation: Dictionary = _main._active_tool_runtime.use()
	if str(activation.get("status", "")) != "used":
		_fail("scanner did not activate the archive survey: %s" % str(activation))
		return false
	var pending: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, float(target.get("interaction_seconds", 0.0)) + 0.1)
	if str(pending.get("reason", "")) != "pending_created":
		_fail("archive survey did not create a pending result")
		return false
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	_main._player.reset_motion()
	var committed: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, 0.0)
	if not bool(committed.get("committed", false)):
		_fail("archive result did not commit at the canonical boat")
		return false
	_main._expedition_day_state.record_discovery(str(committed.get("discovery_id", "")))
	_main._material_project.on_map_loaded(_main._world)
	if not _main._material_project.request_project(PROJECT_ID):
		_fail("archive result did not expose the stabilizer project")
		return false
	_main._last_status_note = str(committed.get("note", "Discovery committed at boat"))
	_main._run_complete = true
	_main._update_status_label()
	_set_review_panel_visible(false)
	_main._result_panel.position = Vector2(12, 12)
	var result_text: String = _main._result_label.text if _main._result_label != null else ""
	return _expect(
		result_text.find(str(target.get("finding_label", ""))) != -1
		and result_text.find(str(target.get("next_lead_label", ""))) != -1
		and _main._material_project.status_for(PROJECT_ID) == "incomplete",
		"archive result omitted its finding, next lead, or new project"
	)


func _prepare_blocked_current() -> bool:
	_main._run_complete = false
	_set_review_panel_visible(true)
	var profile = _main._anomaly_survey.profile_state()
	var gate := _gate_by_id(GATE_ID)
	if gate.is_empty():
		_fail("source-authored relay current is missing")
		return false
	_main._current_gate.reset()
	_main._player.global_position = gate.get("center", Vector2.ZERO)
	_main._player.reset_motion()
	var before: Vector2 = _main._player.global_position
	var report: Dictionary = _main._current_gate.update(
		_main._world,
		_main._player,
		Callable(_main, "_has_upgrade_id"),
		Callable(profile, "has_capability"),
		0.1
	)
	_main._last_status_note = ""
	_main._update_status_label()
	return _expect(
		bool(report.get("blocked", false))
		and _main._player.global_position.x < before.x
		and _status_text().find("need current stabilizer") != -1,
		"unequipped relay current did not block, push, and explain itself"
	)


func _prepare_project_promise() -> bool:
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	_main._player.reset_motion()
	_main._current_gate.reset()
	if not _main._expedition_day_state.request_end_day("voluntary"):
		_fail("could not request the stabilizer night debrief")
		return false
	_main._process(0.0)
	_main._update_status_label()
	var text: String = _main._result_label.text if _main._result_label != null else ""
	return _expect(
		_main._material_project.status_for(PROJECT_ID) == "incomplete"
		and text.find("Stabilizer project: Ti 0/2 | Coil 0/1") != -1
		and text.find("Access: Northwest wreck relay | Swim through current") != -1,
		"night debrief omitted the exact stabilizer recipe or relay promise"
	)


func _build_stabilizer_and_begin_next_day() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var deposit: Dictionary = profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}, false)
	_main._material_project.on_map_loaded(_main._world)
	_main._material_project.request_project(PROJECT_ID)
	if not bool(deposit.get("changed", false)) or _main._material_project.status_for(PROJECT_ID) != "ready":
		_fail("exact banked stabilizer recipe did not become ready")
		return false
	var build: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_P)
	_build_note = str(build.get("note", "Current stabilizer built"))
	if not bool(build.get("changed", false)) or not profile.has_capability(CAPABILITY_ID):
		_fail("night project input did not build the stabilizer")
		return false
	var next_day: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_N)
	if not bool(next_day.get("changed", false)) or _main._world.map_id != MAP_ID:
		_fail("next day did not reload the contiguous production level")
		return false
	_prepare_runtime_nodes()
	_main._refresh_active_tools()
	return _expect(
		profile.material_inventory().is_empty()
		and profile.has_completed_project(PROJECT_ID)
		and profile.has_capability(CAPABILITY_ID),
		"post-build profile lost the exact transaction"
	)


func _prepare_traversable_current() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var gate := _gate_by_id(GATE_ID)
	_main._current_gate.reset()
	_main._player.global_position = gate.get("center", Vector2.ZERO)
	_main._player.reset_motion()
	var before: Vector2 = _main._player.global_position
	var report: Dictionary = _main._current_gate.update(
		_main._world,
		_main._player,
		Callable(_main, "_has_upgrade_id"),
		Callable(profile, "has_capability"),
		0.25
	)
	_main._last_status_note = _build_note
	_main._update_status_label()
	return _expect(
		bool(report.get("inside", false))
		and not bool(report.get("blocked", true))
		and _main._player.global_position == before
		and _status_text().find("Current stabilizer built") != -1,
		"equipped relay current did not remain passive and readable"
	)


func _prepare_current_identification() -> bool:
	var subject := {}
	for candidate in ScannerSubjectCatalog.new().subjects(_main._world, "identify"):
		if str(candidate.get("source_type", "")) == "current" and str(candidate.get("source_id", "")) == GATE_ID:
			subject = candidate
			break
	if subject.is_empty() or not bool(ScannerPose.new().place(_main._world, _main._player, subject).get("found", false)):
		_fail("relay current has no ordinary scanner-identification pose")
		return false
	for _step in range(3):
		if _main._active_tools.selected_tool_id() == ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID:
			break
		_main._cycle_active_tool()
	var result: Dictionary = _main._active_tool_runtime.use()
	_main._last_status_note = str(result.get("note", ""))
	_main._update_status_label()
	var presentation: Dictionary = _main._player.get_scanner_presentation_report()
	return _expect(
		str(result.get("reason", "")) == "identified"
		and str(presentation.get("target_id", "")) == str(subject.get("id", ""))
		and str(presentation.get("target_mode", "")) == "identify"
		and str(presentation.get("target_label", "")) == "Ripping relay current"
		and _status_text().find("Identified: Ripping relay current") != -1,
		"ordinary relay-current identification was not readable"
	)


func _prepare_relay_arrival() -> bool:
	var target := _survey_by_id(RELAY_SURVEY_ID)
	if target.is_empty() or _salvage_by_id(CORE_ID).is_empty():
		_fail("relay landmark payoff records are incomplete")
		return false
	if not bool(ScannerPose.new().place(_main._world, _main._player, target).get("found", false)):
		_fail("relay survey has no collision-clear scanner pose")
		return false
	_main._last_status_note = ""
	_main._update_status_label()
	return _expect(
		not _main._world.is_salvage_collected(CORE_ID)
		and _status_text().find("Relay signal | Hold Space/USE to scan wreck relay") != -1,
		"relay arrival omitted its core or explicit scanner affordance"
	)


func _prepare_mixed_full_cargo() -> bool:
	var material: Dictionary = _main._material_runtime.collect_biological_source(
		{"id": "expansion_14_capture_titanium", "material_id": ExpansionProfileState.TITANIUM_MATERIAL_ID, "material_quantity": 1},
		MAP_ID,
		_main._sortie_state.held_salvage,
		_main._held_salvage_capacity()
	)
	if not bool(material.get("changed", false)) or not _main._world.collect_salvage_by_id(CORE_ID):
		_fail("could not prepare mixed relay cargo")
		return false
	_main._collect_salvage_into_cargo(CORE_ID)
	_main._update_status_label()
	var report: Dictionary = _main._held_cargo_hud.get_test_report()
	return _expect(
		int(report.get("used", -1)) == _main._held_salvage_capacity()
		and int(report.get("available", -1)) == 0
		and report.get("items", []).size() == 2,
		"mixed full cargo strip did not mirror material plus relay core"
	)


func _prepare_partial_survey() -> bool:
	var target := _survey_by_id(RELAY_SURVEY_ID)
	if not bool(ScannerPose.new().place(_main._world, _main._player, target).get("found", false)):
		_fail("could not place the scanner for relay progress")
		return false
	var activation: Dictionary = _main._active_tool_runtime.use()
	if str(activation.get("status", "")) != "used":
		_fail("explicit tool use did not activate the relay survey")
		return false
	var partial: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, PARTIAL_SECONDS)
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	_main._last_status_note = str(partial.get("note", ""))
	_main._update_status_label()
	var progress := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	return _expect(
		progress >= 0.49 and progress <= 0.51
		and _status_text().find("Survey wreck relay 50%") != -1
		and _main._held_cargo_count() == _main._held_salvage_capacity(),
		"relay survey did not hold 50% progress with full cargo"
	)


func _prepare_pending_return() -> bool:
	var target := _survey_by_id(RELAY_SURVEY_ID)
	var result: Dictionary = _main._anomaly_survey.update(
		_main._world,
		_main._player,
		float(target.get("interaction_seconds", 0.0))
	)
	if str(result.get("reason", "")) != "pending_created":
		_fail("completed relay survey did not become pending")
		return false
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	var camera_test: Dictionary = _camera_tests_by_id().get(CAMERA_IDS["pending"], {})
	_set_player_to_camera_center(camera_test)
	_main._last_status_note = str(result.get("note", ""))
	_main._update_status_label()
	return _expect(
		_main._anomaly_survey.has_pending_discovery()
		and not _main._world.is_inside_boat(_main._player.global_position)
		and _main._held_cargo_count() == _main._held_salvage_capacity()
		and _status_text().find("Wreck relay charted | Return to surface boat") != -1,
		"relay result or mixed cargo did not remain pending on the boat approach"
	)


func _camera_tests_by_id() -> Dictionary:
	var values := {}
	for camera_test in _main._world.camera_tests:
		var camera_id := str(camera_test.get("id", ""))
		if CAMERA_IDS.values().has(camera_id):
			values[camera_id] = camera_test
	return values


func _set_player_to_camera_center(camera_test: Dictionary) -> void:
	_main._player.global_position = Vector2(
		float(camera_test.get("center_x", 0.0)) * float(_main._world.tile_size),
		float(camera_test.get("center_y", 0.0)) * float(_main._world.tile_size)
	)
	_main._player.reset_motion()


func _set_review_panel_visible(value: bool) -> void:
	var panel: Control = _main._review_canvas.get_node_or_null("ReviewPanel") as Control
	if panel != null:
		panel.visible = value


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


func _survey_by_id(target_id: String) -> Dictionary:
	for target in _main._world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _status_text() -> String:
	return _main._status_label.text if _main._status_label != null else ""


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("Expansion 14 archive-current capture failed: %s." % message)
	_main.get_tree().quit(1)
