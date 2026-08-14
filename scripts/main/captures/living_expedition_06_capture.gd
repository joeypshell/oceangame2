extends RefCounted

const CompanionAnchorFinsRuntime := preload("res://scripts/companion/companion_anchor_fins_runtime.gd")
const CompanionGuardianPulseRuntime := preload("res://scripts/companion/companion_guardian_pulse_runtime.gd")
const LivingExpedition06CaptureRenderer := preload("res://scripts/main/captures/living_expedition_06_capture_renderer.gd")
const ReviewCheckpointLivingExpedition06 := preload("res://scripts/main/review_checkpoint_living_expedition_06.gd")

const KITE_ID := "spark_ray_juvenile_01"
const EAST_GATE_ID := "lower_right_east_current_gate"
const APPROACH_CAMERA_ID := "living_expedition_06_approach_review_01"
const ANCHOR_CAMERA_ID := "living_expedition_06_anchor_review_01"
const GUARDIAN_CAMERA_ID := "living_expedition_06_guardian_review_01"
const PENDING_CAMERA_ID := "living_expedition_06_pending_return_review_01"
const RESTORED_CAMERA_ID := "living_expedition_06_restored_review_01"
const CAPTURE_STATES := [
	{"id": "approach", "camera": APPROACH_CAMERA_ID},
	{"id": "anchor_action", "camera": ANCHOR_CAMERA_ID},
	{"id": "guardian_action", "camera": GUARDIAN_CAMERA_ID},
	{"id": "immediate_sheltering", "camera": APPROACH_CAMERA_ID},
	{"id": "pending_return", "camera": PENDING_CAMERA_ID},
	{"id": "restored_next_day", "camera": RESTORED_CAMERA_ID},
]

var _main
var _renderer


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_main():
		return
	_renderer = LivingExpedition06CaptureRenderer.new(_main)
	match _main._review_checkpoint_id:
		ReviewCheckpointLivingExpedition06.ANCHOR_READY_ID:
			_clear_generated_evidence(capture_dir)
			if not await _capture_anchor_sequence(capture_dir):
				return
		ReviewCheckpointLivingExpedition06.GUARDIAN_READY_ID:
			if not await _capture_guardian_sequence(capture_dir):
				return
		ReviewCheckpointLivingExpedition06.RESTORED_NURSERY_ID:
			if not await _capture_restored_sequence(capture_dir):
				return
	if not _write_manifest(capture_dir):
		return
	print("Saved Living Expedition 06 captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	await _renderer.prepare_to_quit()
	_main.get_tree().quit(0)


func _prepare_main() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_level_01":
		return _fail("requires production_level_01")
	if (
		not ReviewCheckpointLivingExpedition06.is_supported(_main._review_checkpoint_id)
		or not bool(_main._review_checkpoint_report.get("ready", false))
	):
		return _fail("requires an isolated Living Expedition 06 checkpoint")
	var companion = _main._companion_sortie.companion()
	if companion == null:
		return _fail("checkpoint did not launch Kite")
	_disable_live_processing(companion)
	var report: Dictionary = _main._companion_sortie.report()
	return _expect(
		str(report.get("active_species_id", "")) == "spark_ray"
		and str(report.get("identity", {}).get("individual_id", "")) == KITE_ID,
		"checkpoint launched the wrong companion"
	)


func _capture_anchor_sequence(capture_dir: String) -> bool:
	_main._world.advance_signal_reef_nursery(0.75)
	var nursery := _nursery()
	_place_pair(nursery.get("school_center", Vector2.ZERO), Vector2(-76.0, 38.0), Vector2(-24.0, 12.0))
	_set_note("Kite tracks the filter-skate school | jellyfish pressure ahead")
	if not await _capture(capture_dir, "approach", "approach"):
		return false

	_place_pair(_gate_center(), Vector2.ZERO, Vector2(-22.0, 0.0))
	var dispatched := _dispatch(CompanionAnchorFinsRuntime.ACTION_ID)
	if not bool(dispatched.get("changed", false)):
		return _fail("Anchor brace did not dispatch: %s" % str(dispatched))
	var anchor = _main._companion_sortie.adaptation_runtime()
	anchor.advance(0.7, false)
	_set_note("Kite braces the current | Anchor Fins 47%")
	if not await _capture(capture_dir, "anchor_action", "anchor_action"):
		return false

	anchor.advance(0.9, false)
	_main._companion_sortie.signal_reef_nursery_runtime().advance()
	_main._world.advance_signal_reef_nursery(0.8)
	nursery = _nursery()
	_place_pair(nursery.get("school_center", Vector2.ZERO), Vector2(-82.0, 42.0), Vector2(-30.0, 15.0))
	_set_note("Kite formed a stable lee | filter skates moving to shelter")
	if not await _capture(capture_dir, "immediate_sheltering", "immediate_sheltering"):
		return false

	_main._world.advance_signal_reef_nursery(2.0)
	nursery = _nursery()
	_place_pair(nursery.get("nursery_center", Vector2.ZERO), Vector2(-92.0, 34.0), Vector2(-40.0, 10.0))
	_set_note("Filter skates sheltered | return with Kite to the surface boat")
	return await _capture(capture_dir, "pending_return", "pending_return")


func _capture_guardian_sequence(capture_dir: String) -> bool:
	var pressure: Vector2 = _nursery().get("pressure_center", Vector2.ZERO)
	_place_pair(pressure, Vector2(-100.0, 0.0), Vector2(-78.0, 0.0))
	_main._player.swim_in_direction(Vector2.RIGHT, 0.0)
	var dispatched := _dispatch(CompanionGuardianPulseRuntime.ACTION_ID)
	if not bool(dispatched.get("changed", false)):
		return _fail("Guardian Pulse did not dispatch: %s" % str(dispatched))
	var guardian = _main._companion_sortie.guardian_pulse_runtime()
	guardian.advance(0.5, false)
	_main._companion_sortie.signal_reef_nursery_runtime().advance()
	_main._world.advance_signal_reef_nursery(0.8)
	_set_note("Kite displaced the jellyfish pressure | no damage | school moving")
	return await _capture(capture_dir, "guardian_action", "guardian_action")


func _capture_restored_sequence(capture_dir: String) -> bool:
	_main._world.advance_signal_reef_nursery(0.75)
	var nursery := _nursery()
	_place_pair(nursery.get("nursery_center", Vector2.ZERO), Vector2(-92.0, 34.0), Vector2(-40.0, 10.0))
	_set_note("Kite revisits the restored nursery | seven filter skates returned")
	return await _capture(capture_dir, "restored_next_day", "restored_next_day")


func _capture(capture_dir: String, state_id: String, kind: String) -> bool:
	var camera_test := _camera_test(_state_camera(state_id))
	if camera_test.is_empty():
		return _fail("missing authored camera for %s" % state_id)
	return await _renderer.capture_pair(capture_dir, state_id, camera_test, {"kind": kind})


func _dispatch(action_id: String) -> Dictionary:
	var control = _main._companion_sortie.control_runtime()
	var commands: Array = control.begin_command_mode().get("context_commands", [])
	for index in range(commands.size()):
		if str((commands[index] as Dictionary).get("id", "")) == action_id:
			return control.activate_context_command(index)
	control.end_command_mode()
	return {"changed": false, "reason": "command_missing", "action_id": action_id}


func _place_pair(center: Vector2, player_offset: Vector2, companion_offset: Vector2) -> void:
	var companion = _main._companion_sortie.companion()
	_main._player.global_position = center + player_offset
	_main._player.reset_motion()
	companion.recover_to_player()
	companion.set_external_control_active(true)
	companion.global_position = center + companion_offset
	companion.set_external_control_active(false)
	companion.advance(0.0)


func _set_note(note: String) -> void:
	_main._last_status_note = note
	_main._update_status_label()


func _gate_center() -> Vector2:
	for gate in _main._world.get_current_gates():
		if str((gate as Dictionary).get("id", "")) == EAST_GATE_ID:
			return (gate as Dictionary).get("center", Vector2.ZERO)
	return Vector2.ZERO


func _nursery() -> Dictionary:
	return _main._world.get_signal_reef_nursery_report()


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


func _disable_live_processing(companion) -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false
	companion.set_physics_process(false)
	_main._companion_sortie.set_process(false)
	var control = _main._companion_sortie.control_runtime()
	control.set_process(false)
	control.set_physics_process(false)
	_main._companion_sortie.signal_reef_nursery_runtime().set_process(false)
	var presentation = _main._world.get_node_or_null("Markers/SignalReefNursery")
	if presentation != null:
		presentation.set_process(false)


func _clear_generated_evidence(capture_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var directory := DirAccess.open(capture_dir)
	if directory == null:
		return
	for filename in directory.get_files():
		if filename.ends_with(".png") or filename.ends_with(".import") or filename == "capture_manifest.json":
			directory.remove(filename)


func _write_manifest(capture_dir: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var file := FileAccess.open("%s/capture_manifest.json" % capture_dir, FileAccess.WRITE)
	if file == null:
		return _fail("could not write capture manifest")
	file.store_string(JSON.stringify({
		"capture_runner": "res://scripts/main/captures/living_expedition_06_capture_runner.gd",
		"review_checkpoints": [
			ReviewCheckpointLivingExpedition06.ANCHOR_READY_ID,
			ReviewCheckpointLivingExpedition06.GUARDIAN_READY_ID,
			ReviewCheckpointLivingExpedition06.RESTORED_NURSERY_ID,
		],
		"baseline_accepted": false,
		"bounds_verified": true,
		"states": CAPTURE_STATES,
		"sizes": {"1280x720": [1280, 720], "mobile_844x390": [693, 390]},
		"subject": "Signal Reef adaptation branches and next-day nursery restoration",
	}, "  ") + "\n")
	file.close()
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 06 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
