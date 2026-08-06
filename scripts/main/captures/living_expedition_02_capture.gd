extends RefCounted

const CompanionRescueRuntime := preload("res://scripts/companion/companion_rescue_runtime.gd")
const LivingExpedition02CaptureRenderer := preload("res://scripts/main/captures/living_expedition_02_capture_renderer.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const BOAT_ENTRY_ID := "surface_boat_entry"
const KITE_ID := "spark_ray_juvenile_01"
const MICA_ID := "veil_cuttle_juvenile_01"
const MICA_RESCUE_ID := "veil_cuttle_rescue_01"
const TRACE_ID := "veil_cuttle_trace_01"
const BOAT_CAMERA_ID := "living_expedition_01_night_choice"
const MICA_CAMERA_ID := "veil_cuttle_review_01"
const KITE_CAMERA_ID := "living_expedition_01_mounted_route"
const CAPTURE_STATES := [
	{"id": "habitat_before_commitment", "camera": BOAT_CAMERA_ID},
	{"id": "habitat_after_commitment", "camera": BOAT_CAMERA_ID},
	{"id": "mica_selected", "camera": BOAT_CAMERA_ID},
	{"id": "mica_following", "camera": MICA_CAMERA_ID},
	{"id": "reveal_trace_aim", "camera": MICA_CAMERA_ID},
	{"id": "reveal_trace_result", "camera": MICA_CAMERA_ID},
	{"id": "kite_selected", "camera": BOAT_CAMERA_ID},
	{"id": "kite_mounted_actions", "camera": KITE_CAMERA_ID},
]

var _main
var _renderer


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_main():
		return
	_renderer = LivingExpedition02CaptureRenderer.new(_main)
	if not await _capture(capture_dir, "habitat_before_commitment", _habitat_expectation(1, KITE_ID)):
		return
	if not _rescue_and_commit_mica():
		return
	if not await _capture(capture_dir, "habitat_after_commitment", _habitat_expectation(2, KITE_ID)):
		return
	if not _select_companion(MICA_ID):
		return
	if not await _capture(capture_dir, "mica_selected", _habitat_expectation(2, MICA_ID)):
		return
	if not _launch_mica():
		return
	if not _prepare_mica_follow() or not await _capture(capture_dir, "mica_following"):
		return
	if not _prepare_reveal_trace_aim() or not await _capture(capture_dir, "reveal_trace_aim", {"kind": "palette"}):
		return
	if not _complete_reveal_trace() or not await _capture(capture_dir, "reveal_trace_result"):
		return
	if not _return_to_habitat() or not _select_companion(KITE_ID):
		return
	if not await _capture(capture_dir, "kite_selected", _habitat_expectation(2, KITE_ID)):
		return
	if not _launch_and_mount_kite():
		return
	if not await _capture(capture_dir, "kite_mounted_actions", {"kind": "action_hud"}):
		return
	if not _write_manifest(capture_dir):
		return
	print("Saved Living Expedition 02 captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	await _renderer.prepare_to_quit()
	_main.get_tree().quit(0)


func _prepare_main() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_level_01":
		return _fail("requires production_level_01")
	if (
		_main._review_checkpoint_id != ReviewCheckpointFixture.LIVING_EXPEDITION_02_START
		or not bool(_main._review_checkpoint_report.get("ready", false))
	):
		return _fail("requires the isolated living_expedition_02_start checkpoint")
	_disable_live_processing()
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	_main._player.reset_motion()
	_main._companion_sortie._habitat.sync_presence()
	var report: Dictionary = _main._companion_sortie.report().get("habitat", {})
	return _expect(
		int(report.get("individual_count", 0)) == 1
		and str(report.get("active_individual_id", "")) == KITE_ID,
		"checkpoint habitat did not begin with Kite only"
	)


func _rescue_and_commit_mica() -> bool:
	var rescue := _record_by_id(_main._world.get_creature_rescues(), MICA_RESCUE_ID)
	if rescue.is_empty():
		return _fail("source-authored Mica rescue is unavailable")
	_main._player.global_position = rescue.get("center", Vector2.ZERO)
	_main._companion_sortie._habitat.sync_presence()
	if not _select_tool("salvage_cutter"):
		return false
	var used: Dictionary = _main._active_tool_runtime.use()
	if str(used.get("status", "")) != "used":
		return _fail("Cutter did not begin Mica's rescue: %s" % str(used))
	var released: Dictionary = _main._companion_rescue.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	_main._active_tool_runtime.release_use()
	if str(released.get("state", "")) != "complete":
		return _fail("Mica's rescue did not complete")
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	var committed: Dictionary = _main._companion_rescue.commit_at_boat()
	if not bool(committed.get("changed", false)):
		return _fail("canonical boat did not commit Mica: %s" % str(committed))
	_main._companion_sortie._habitat.sync_presence()
	_main._last_status_note = "Mica joined the boat habitat | Kite remains next"
	_main._update_status_label()
	var companion: Dictionary = _main._anomaly_survey.profile_state().companion_report()
	return _expect(
		(companion.get("individuals", []) as Array).size() == 2
		and str(companion.get("active_individual_id", "")) == KITE_ID,
		"Mica commitment replaced Kite or failed to produce two partners"
	)


func _select_companion(individual_id: String) -> bool:
	var habitat: Dictionary = _main._companion_sortie.report().get("habitat", {})
	if not bool(habitat.get("at_boat", false)):
		return _fail("companion selection was attempted away from the boat")
	if not _main._companion_sortie.handle_input(_action_event(&"companion_command")):
		return _fail("BOND did not open the boat habitat")
	var individuals: Array = _main._anomaly_survey.profile_state().companion_report().get("individuals", [])
	for _step in range(individuals.size()):
		var highlighted := int(_main._companion_sortie.report().get("habitat", {}).get("highlighted_index", 0))
		if str((individuals[highlighted] as Dictionary).get("individual_id", "")) == individual_id:
			break
		_main._companion_sortie.handle_input(_action_event(&"active_tool_cycle_next"))
	_main._companion_sortie.handle_input(_action_event(&"active_tool_use"))
	_main._update_status_label()
	return _expect(
		str(_main._anomaly_survey.profile_state().companion_report().get("active_individual_id", "")) == individual_id,
		"boat habitat did not select %s" % individual_id
	)


func _launch_mica() -> bool:
	var focus := _camera_world_position(MICA_CAMERA_ID)
	_main._player.global_position = focus + Vector2(-24.0, 0.0)
	_main._sortie_state.update_offload_presence(false, _main._oxygen_capacity_seconds())
	_main._expedition_day_state.record_sortie_started()
	var launched: Dictionary = _main._companion_sortie.sync_spawn()
	var mica = _main._companion_sortie.companion()
	if not bool(launched.get("spawned", false)) or mica == null:
		return _fail("selected Mica did not launch")
	_disable_companion(mica)
	return _expect(str(launched.get("active_species_id", "")) == "veil_cuttle", "Mica selection launched the wrong species")


func _prepare_mica_follow() -> bool:
	var mica = _main._companion_sortie.companion()
	var trace := _record_by_id(_main._world.get_ecological_traces(), TRACE_ID)
	if trace.is_empty():
		return _fail("Mica follow capture omitted the authored trace landmark")
	var focus: Vector2 = trace.get("center", Vector2.ZERO)
	mica.global_position = focus + Vector2(-42.0, 0.0)
	_main._player.global_position = focus + Vector2(20.0, 0.0)
	mica.advance(0.0)
	_main._last_status_note = "Mica active | Close sensing partner | Hold BOND for commands"
	_main._update_status_label()
	return _expect(
		str(mica.report().get("state", "")) in ["hover", "investigate"],
		"Mica follow capture entered an invalid state"
	)


func _prepare_reveal_trace_aim() -> bool:
	var trace := _record_by_id(_main._world.get_ecological_traces(), TRACE_ID)
	var mica = _main._companion_sortie.companion()
	if trace.is_empty() or mica == null:
		return _fail("Reveal Trace capture fixture is unavailable")
	mica.global_position = trace.get("center", Vector2.ZERO) + Vector2(-40.0, 0.0)
	_main._player.global_position = mica.global_position + Vector2(-20.0, 0.0)
	mica.advance(0.0)
	var control = _main._companion_sortie.control_runtime()
	control.begin_command_mode()
	control.cycle_context_command()
	_main._last_status_note = "BOND | Reveal Trace aimed at concealed evidence"
	_main._update_status_label()
	var report: Dictionary = control.report()
	return _expect(
		str((report.get("context_commands", []) as Array)[int(report.get("selected_command_index", 0))].get("id", "")) == "reveal_trace"
		and str(report.get("trace", {}).get("availability_reason", "")) == "ready",
		"Reveal Trace was not selected and ready"
	)


func _complete_reveal_trace() -> bool:
	var result: Dictionary = _main._companion_sortie.control_runtime().confirm_context_command()
	_main._update_status_label()
	var trace := _record_by_id(_main._world.get_ecological_traces(), TRACE_ID)
	return _expect(
		bool(result.get("changed", false)) and str(trace.get("state", "")) == "revealed",
		"Reveal Trace did not expose the authored evidence"
	)


func _return_to_habitat() -> bool:
	Engine.time_scale = 1.0
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	_main._companion_sortie.release_to_habitat()
	_main._companion_sortie._habitat.sync_presence()
	return _expect(
		_main._companion_sortie.companion() == null
		and int(_main._companion_sortie.report().get("habitat", {}).get("individual_count", 0)) == 2,
		"Mica did not return to the two-partner habitat"
	)


func _launch_and_mount_kite() -> bool:
	_main._player.global_position = _camera_world_position(KITE_CAMERA_ID)
	var launched: Dictionary = _main._companion_sortie.sync_spawn()
	var kite = _main._companion_sortie.companion()
	if str(launched.get("active_species_id", "")) != "spark_ray" or kite == null:
		return _fail("Kite selection did not restore the Spark Ray runtime")
	_disable_companion(kite)
	var control = _main._companion_sortie.control_runtime()
	if not bool(control.request_mount().get("changed", false)):
		return _fail("Kite could not mount after Mica's sortie")
	_main._last_status_note = "Kite active | Mounted actions restored"
	_main._update_status_label()
	return _expect(bool(control.report().get("action_hud", {}).get("visible", false)), "Kite's mounted action surface was not restored")


func _disable_live_processing() -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false


func _disable_companion(companion) -> void:
	companion.set_physics_process(false)
	_main._companion_sortie.set_process(false)
	var control = _main._companion_sortie.control_runtime()
	control.set_process(false)
	control.set_physics_process(false)


func _capture(capture_dir: String, state_id: String, ui_expectation := {}) -> bool:
	var camera_test := _camera_test(_state_camera(state_id))
	if camera_test.is_empty():
		return _fail("missing authored camera for %s" % state_id)
	return await _renderer.capture_pair(capture_dir, state_id, camera_test, ui_expectation)


func _habitat_expectation(rows: int, active_id: String) -> Dictionary:
	return {
		"kind": "habitat",
		"rows": rows,
		"active_id": active_id,
		"selection_open": false,
	}


func _state_camera(state_id: String) -> String:
	for state in CAPTURE_STATES:
		if str(state.get("id", "")) == state_id:
			return str(state.get("camera", ""))
	return ""


func _camera_test(camera_id: String) -> Dictionary:
	for camera_test in _main._world.camera_tests:
		if str(camera_test.get("id", "")) == camera_id:
			return camera_test
	return {}


func _camera_world_position(camera_id: String) -> Vector2:
	var camera := _camera_test(camera_id)
	return Vector2(float(camera.get("center_x", 0.0)), float(camera.get("center_y", 0.0))) * float(_main._world.tile_size)


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str(record.get("id", "")) == record_id:
			return record
	return {}


func _select_tool(tool_id: String) -> bool:
	_main._refresh_active_tools()
	for _step in range(_main.ActiveToolController.ordered_tool_ids().size()):
		if _main._active_tools.selected_tool_id() == tool_id:
			return true
		_main._active_tool_runtime.cycle()
	return _fail("could not select %s" % tool_id)


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _write_manifest(capture_dir: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var file := FileAccess.open("%s/capture_manifest.json" % capture_dir, FileAccess.WRITE)
	if file == null:
		return _fail("could not write capture manifest")
	file.store_string(JSON.stringify({
		"capture_runner": "res://scripts/main/captures/living_expedition_02_capture_runner.gd",
		"review_checkpoint": ReviewCheckpointFixture.LIVING_EXPEDITION_02_START,
		"baseline_accepted": false,
		"states": CAPTURE_STATES,
		"sizes": ["1280x720", "mobile_844x390"],
		"controls": "Shift/BOND + Tab/TOOL + Space/USE",
	}, "  ") + "\n")
	file.close()
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 02 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
