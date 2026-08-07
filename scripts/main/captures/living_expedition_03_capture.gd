extends RefCounted

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const LivingExpedition03CaptureRenderer := preload("res://scripts/main/captures/living_expedition_03_capture_renderer.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const BOAT_ENTRY_ID := "surface_boat_entry"
const TRACE_ID := "southwest_bloom_migration_trace"
const SCANNER_TARGET_ID := "identify_ecological_trace_southwest_bloom_migration_trace"
const OBSERVATION_ID := "southwest_bloom_migration_observation"
const MEMORY_ID := "followed_the_bloom"
const ADAPTATION_ID := "drift_lens"
const DEEP_PATROL_ID := "deep_route_jellyfish_patrol"
const BLOOM_CAMERA_ID := "living_expedition_03_bloom_review_01"
const BOAT_CAMERA_ID := "living_expedition_01_night_choice"
const DRIFT_CAMERA_ID := "living_expedition_01_guardian_payoff"
const CAPTURE_STATES := [
	{"id": "mica_reaction", "camera": BLOOM_CAMERA_ID},
	{"id": "reveal_trace_ready", "camera": BLOOM_CAMERA_ID},
	{"id": "migration_filament", "camera": BLOOM_CAMERA_ID},
	{"id": "held_scanner_identification", "camera": BLOOM_CAMERA_ID},
	{"id": "pending_return", "camera": BLOOM_CAMERA_ID},
	{"id": "night_consolidation", "camera": BOAT_CAMERA_ID},
	{"id": "read_drift", "camera": DRIFT_CAMERA_ID},
]

var _main
var _renderer


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_main():
		return
	_renderer = LivingExpedition03CaptureRenderer.new(_main)
	if not _prepare_mica_reaction() or not await _capture(capture_dir, "mica_reaction", {"kind": "mica_reaction"}):
		return
	if not _prepare_reveal_palette() or not await _capture(capture_dir, "reveal_trace_ready", {"kind": "bond_palette"}):
		return
	if not _reveal_migration() or not await _capture(capture_dir, "migration_filament", {"kind": "migration_filament"}):
		return
	if not _begin_scanner_identification() or not await _capture(capture_dir, "held_scanner_identification", {"kind": "scanner_card"}):
		return
	if not _complete_identification() or not await _capture(capture_dir, "pending_return"):
		return
	if not _prepare_night_consolidation() or not await _capture(capture_dir, "night_consolidation", {"kind": "result_panel"}):
		return
	if not _prepare_read_drift() or not await _capture(capture_dir, "read_drift", {"kind": "drift_projection"}):
		return
	if not _write_manifest(capture_dir):
		return
	print("Saved Living Expedition 03 captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	await _renderer.prepare_to_quit()
	_main.get_tree().quit(0)


func _prepare_main() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_level_01":
		return _fail("requires production_level_01")
	if (
		_main._review_checkpoint_id != ReviewCheckpointFixture.LIVING_EXPEDITION_03_START
		or not bool(_main._review_checkpoint_report.get("ready", false))
	):
		return _fail("requires the isolated living_expedition_03_start checkpoint")
	_disable_live_processing()
	var profile = _main._anomaly_survey.profile_state()
	var companion: Dictionary = profile.companion_report()
	return _expect(
		int(_main._expedition_day_state.day_number) == 2
		and str(companion.get("active_individual_id", "")) == "veil_cuttle_juvenile_01"
		and _main._anomaly_survey.has_scanner(),
		"checkpoint did not begin on Day 2 with Mica and Scanner"
	)


func _prepare_mica_reaction() -> bool:
	var trace := _record_by_id(_main._world.get_ecological_traces(), TRACE_ID)
	if trace.is_empty():
		return _fail("authored migration trace is unavailable")
	var focus: Vector2 = trace.get("center", Vector2.ZERO)
	_main._player.global_position = focus + Vector2(-64.0, 0.0)
	_main._sortie_state.update_offload_presence(false, _main._oxygen_capacity_seconds())
	_main._sortie_state.oxygen_seconds = maxf(
		_main._sortie_state.oxygen_seconds,
		float(_main._review_checkpoint_report.get("review_oxygen_seconds", 0.0))
	)
	_main._expedition_day_state.record_sortie_started()
	var launched: Dictionary = _main._companion_sortie.sync_spawn()
	var mica = _main._companion_sortie.companion()
	if str(launched.get("active_species_id", "")) != "veil_cuttle" or mica == null:
		return _fail("checkpoint did not launch Mica")
	_disable_companion(mica)
	mica.global_position = focus + Vector2(-40.0, 0.0)
	mica.advance(0.0)
	_main._companion_sortie.control_runtime()._process(0.0)
	_main._last_status_note = "MICA FOUND A TRACE HERE | Press B, then 2: Reveal Trace"
	_main._update_status_label()
	return _expect(
		bool(mica.report().get("presentation", {}).get("ecology_interest_visible", false)),
		"Mica did not visibly react to the hidden migration"
	)


func _reveal_migration() -> bool:
	var result := _dispatch_command("reveal_trace")
	var mica = _main._companion_sortie.companion()
	if mica == null:
		return _fail("Mica disappeared before Reveal Trace")
	var presentation: Dictionary = mica.report().get("presentation", {})
	_main._update_status_label()
	return _expect(
		bool(result.get("changed", false))
		and str(result.get("target_id", "")) == TRACE_ID
		and str(presentation.get("trace_state", "")) == "revealed"
		and int(presentation.get("trace_path_point_count", 0)) >= 2
		and (presentation.get("trace_movement_direction", Vector2.ZERO) as Vector2) != Vector2.ZERO,
		"Reveal Trace did not draw the source-derived migration filament"
	)


func _prepare_reveal_palette() -> bool:
	var report: Dictionary = _main._companion_sortie.control_runtime().begin_command_mode()
	var commands: Array = report.get("context_commands", [])
	_main._update_status_label()
	return _expect(
		commands.size() > 1
		and str((commands[1] as Dictionary).get("id", "")) == "reveal_trace"
		and bool(report.get("palette", {}).get("visible", false)),
		"BOND did not open with Reveal Trace on number 2"
	)


func _begin_scanner_identification() -> bool:
	if not _select_tool(_main.ActiveToolController.SCANNER_TOOL_ID):
		return false
	var activated: Dictionary = _main._active_tool_runtime.use()
	if str(activated.get("status", "")) != "used" or str(activated.get("reason", "")) != "activated":
		return _fail("Scanner did not begin held identification: %s" % str(activated))
	var progressed: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, 0.75)
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	var presentation: Dictionary = _main._player.get_scanner_presentation_report()
	_main._update_status_label()
	return _expect(
		str(progressed.get("reason", "")) == "progress"
		and bool(presentation.get("visible", false))
		and bool(presentation.get("held", false))
		and bool(presentation.get("card_visible", false))
		and str(presentation.get("target_id", "")) == SCANNER_TARGET_ID
		and float(presentation.get("progress", 0.0)) > 0.0
		and float(presentation.get("progress", 0.0)) < 1.0,
		"held Scanner capture omitted bounded partial identification"
	)


func _complete_identification() -> bool:
	var identified: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, 0.8)
	_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	_main._active_tool_runtime.release_use()
	_main._last_status_note = "Migration identified | Return to the surface boat with Mica"
	_main._update_status_label()
	var ecology: Dictionary = _main._companion_sortie.memory_report().get("ecology", {})
	return _expect(
		str(identified.get("reason", "")) == "identified"
		and str(ecology.get("pending_observation_id", "")) == OBSERVATION_ID
		and not (_main._anomaly_survey.profile_state().companion_report().get("individual", {}).get("earned_memory_ids", []) as Array).has(MEMORY_ID),
		"identification did not remain pending until the canonical boat return"
	)


func _prepare_night_consolidation() -> bool:
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	var committed: Dictionary = _main._companion_sortie.commit_memories_at_boat()
	if not bool(committed.get("changed", false)) or str(committed.get("memory_id", "")) != MEMORY_ID:
		return _fail("boat did not commit Followed the Bloom")
	_main._expedition_day_state.request_end_day("voluntary")
	ExpeditionDayDebrief.update(_main, 0.0)
	return _expect(
		_main._companion_sortie.requires_adaptation_selection()
		and _main._result_panel.visible
		and _main._result_label.text.find("Followed the Bloom") != -1
		and _main._result_label.text.find("Drift Lens") != -1,
		"night did not present the deliberate Drift Lens consolidation"
	)


func _prepare_read_drift() -> bool:
	var selected: Dictionary = ExpeditionDayDebrief.handle_debrief_input(_main, _action_event(&"active_tool_use"))
	if str(selected.get("adaptation_id", "")) != ADAPTATION_ID:
		return _fail("night did not consolidate Drift Lens")
	_main._companion_sortie.end_debrief()
	_main._expedition_day_state.begin_next_day()
	_main._load_playable_map(_main.PRODUCTION_LEVEL_MAP_PATH, false, BOAT_ENTRY_ID, "Mica adapted")
	_disable_live_processing()
	var target: Dictionary = _main._moving_hazards.snapshot_for(DEEP_PATROL_ID)
	if target.is_empty():
		return _fail("deep patrol is unavailable for Read Drift")
	var center: Vector2 = target.get("center", Vector2.ZERO)
	_main._player.global_position = center + Vector2(-36.0, 0.0)
	_main._sortie_state.update_offload_presence(false, _main._oxygen_capacity_seconds())
	_main._expedition_day_state.record_sortie_started()
	var launched: Dictionary = _main._companion_sortie.sync_spawn()
	var mica = _main._companion_sortie.companion()
	if str(launched.get("active_species_id", "")) != "veil_cuttle" or mica == null:
		return _fail("Day 3 did not restore Mica")
	_disable_companion(mica)
	mica.global_position = center + Vector2(-24.0, 0.0)
	mica.advance(0.0)
	var hazards_before: Array = _main._moving_hazards.snapshot()
	var result := _dispatch_command("read_drift")
	_main._last_status_note = "Drift Lens | Read the patrol's living route"
	_main._update_status_label()
	return _expect(
		bool(result.get("changed", false))
		and str(result.get("target_id", "")) == DEEP_PATROL_ID
		and bool(mica.report().get("drift_projection", {}).get("visible", false))
		and _main._moving_hazards.snapshot() == hazards_before,
		"Read Drift did not project the unchanged patrol path"
	)


func _dispatch_command(action_id: String) -> Dictionary:
	var control = _main._companion_sortie.control_runtime()
	var open_report: Dictionary = control.begin_command_mode()
	var commands: Array = open_report.get("context_commands", [])
	for index in range(commands.size()):
		if str((commands[index] as Dictionary).get("id", "")) != action_id:
			continue
		return control.activate_context_command(index)
	control.end_command_mode()
	return {"changed": false, "reason": "command_missing", "action_id": action_id}


func _select_tool(tool_id: String) -> bool:
	_main._refresh_active_tools()
	for _step in range(_main.ActiveToolController.ordered_tool_ids().size()):
		if _main._active_tools.selected_tool_id() == tool_id:
			return true
		_main._active_tool_runtime.cycle()
	return _fail("could not select %s" % tool_id)


func _capture(capture_dir: String, state_id: String, expectation := {}) -> bool:
	var camera_test := _camera_test(_state_camera(state_id))
	if camera_test.is_empty():
		return _fail("missing authored camera for %s" % state_id)
	return await _renderer.capture_pair(capture_dir, state_id, camera_test, expectation)


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


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str(record.get("id", "")) == record_id:
			return record
	return {}


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
		"capture_runner": "res://scripts/main/captures/living_expedition_03_capture_runner.gd",
		"review_checkpoint": ReviewCheckpointFixture.LIVING_EXPEDITION_03_START,
		"baseline_accepted": false,
		"bounds_verified": true,
		"states": CAPTURE_STATES,
		"sizes": {
			"1280x720": [1280, 720],
			"mobile_844x390": [693, 390],
		},
		"subject": "source-derived moving-hazard migration filament",
	}, "  ") + "\n")
	file.close()
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 03 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
