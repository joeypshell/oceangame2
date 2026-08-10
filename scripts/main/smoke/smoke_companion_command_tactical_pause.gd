extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const HOSTILE_ID := "deep_cache_territorial_eel"
const PAUSED_FRAMES := 24
const RESUMED_FRAMES := 8

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_paused := paused
	var original_time_scale := Engine.time_scale
	var main = MAIN_SCENE.instantiate()
	get_root().add_child(main)
	await process_frame
	await physics_frame
	_expect(
		main._review_checkpoint_id == ReviewCheckpointFixture.LIVING_EXPEDITION_04_START
		and bool(main._review_checkpoint_report.get("ready", false)),
		"tactical-pause smoke requires the isolated Living Expedition 04 checkpoint"
	)
	main._hazard_interactions_enabled = false
	main._sortie_state.update_offload_presence(false, main._oxygen_capacity_seconds())
	main._expedition_day_state.record_sortie_started()
	var spawn: Dictionary = main._companion_sortie.sync_spawn()
	var companion = main._companion_sortie.companion()
	var control = main._companion_sortie.control_runtime()
	_expect(bool(spawn.get("spawned", false)) and companion != null and control != null, "checkpoint did not launch the active companion")
	if companion == null or control == null:
		_finish(main, original_paused, original_time_scale)
		return

	var hostile_home: Vector2 = main._hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	main._player.global_position = hostile_home + Vector2(-100.0, 0.0)
	_place_companion(companion, main._player.global_position + Vector2(-36.0, 0.0))
	main._hostiles.update(main._world, main._player.global_position, 0.0)
	var hostile_before: Dictionary = main._hostiles.state_for(HOSTILE_ID)
	_expect(str(hostile_before.get("phase", "")) == "warning", "eel fixture did not enter its real warning phase")

	_parse_action(&"companion_command", true)
	await process_frame
	_parse_action(&"companion_command", false)
	await process_frame
	var opened: Dictionary = control.report()
	_expect(bool(opened.get("command_mode", false)), "keyboard BOND press did not leave the command palette open")
	_expect(paused and bool(opened.get("simulation_paused", false)), "command palette did not pause the SceneTree")
	_expect(str(opened.get("timing_policy", "")) == "tactical_pause", "command palette reported the wrong timing policy")
	_expect(is_equal_approx(Engine.time_scale, original_time_scale), "tactical pause changed Engine.time_scale")

	var frozen := _snapshot(main, companion)
	for _index in range(PAUSED_FRAMES):
		await process_frame
	var after_wait := _snapshot(main, companion)
	_expect(after_wait == frozen, "simulation changed while BOND was open: before=%s after=%s" % [frozen, after_wait])

	var selected_before := int(control.report().get("selected_command_index", -1))
	_parse_action(&"active_tool_cycle_next", true)
	await process_frame
	_parse_action(&"active_tool_cycle_next", false)
	await process_frame
	_expect(int(control.report().get("selected_command_index", -1)) != selected_before, "TOOL could not move command selection during tactical pause")

	_parse_action(&"companion_command", true)
	await process_frame
	_parse_action(&"companion_command", false)
	await process_frame
	_expect(not paused and not bool(control.report().get("command_mode", true)), "keyboard BOND close did not resume simulation")
	var resume_start: Dictionary = main._hostiles.state_for(HOSTILE_ID)
	var oxygen_start := float(main._sortie_state.oxygen_seconds)
	var daylight_start := float(main._expedition_day_state.daylight_remaining_seconds)
	for _index in range(RESUMED_FRAMES):
		await process_frame
	var resume_end: Dictionary = main._hostiles.state_for(HOSTILE_ID)
	_expect(_hostile_advanced(resume_start, resume_end), "eel did not resume after command mode closed")
	_expect(float(main._sortie_state.oxygen_seconds) < oxygen_start, "oxygen did not resume after command mode closed")
	_expect(float(main._expedition_day_state.daylight_remaining_seconds) < daylight_start, "daylight did not resume after command mode closed")

	control.begin_command_mode()
	_parse_action(&"companion_action_1", true)
	await process_frame
	_parse_action(&"companion_action_1", false)
	await process_frame
	_expect(not paused and not bool(control.report().get("command_mode", true)), "numbered keyboard command could not confirm during tactical pause")

	control.begin_command_mode()
	main._companion_sortie.reset_control("retry")
	_expect(not paused, "Retry did not restore simulation")
	control.begin_command_mode()
	main._companion_sortie.begin_debrief()
	_expect(not paused, "debrief did not restore simulation")
	main._companion_sortie.end_debrief()
	control.begin_command_mode()
	control.reset_control("map_change")
	_expect(not paused, "map transition did not restore simulation")
	control.end_command_mode()
	_expect(not paused, "repeated command close changed the restored pause state")
	control.begin_command_mode()
	main.queue_free()
	await process_frame
	_expect(not paused, "scene exit did not restore simulation")

	_finish(null, original_paused, original_time_scale, {
		"phase": hostile_before.get("phase"),
		"phase_seconds": hostile_before.get("phase_seconds"),
		"paused_frames": PAUSED_FRAMES,
		"resumed_phase": resume_end.get("phase"),
		"resumed_position": resume_end.get("position"),
	})


func _snapshot(main, companion) -> Dictionary:
	var hostile: Dictionary = main._hostiles.state_for(HOSTILE_ID)
	return {
		"hostile_phase": hostile.get("phase"),
		"hostile_phase_seconds": hostile.get("phase_seconds"),
		"hostile_position": hostile.get("position"),
		"player_position": main._player.global_position,
		"companion_position": companion.global_position,
		"oxygen": main._sortie_state.oxygen_seconds,
		"daylight": main._expedition_day_state.daylight_remaining_seconds,
		"moving_hazards": main._moving_hazards.snapshot(),
		"control": {
			"selected_command_index": main._companion_sortie.control_runtime().report().get("selected_command_index"),
			"trace_cooldown": main._companion_sortie.control_runtime().report().get("trace", {}).get("cooldown_seconds", 0.0),
		},
	}


func _hostile_advanced(before: Dictionary, after: Dictionary) -> bool:
	return (
		str(after.get("phase", "")) != str(before.get("phase", ""))
		or float(after.get("phase_seconds", 0.0)) < float(before.get("phase_seconds", 0.0))
		or not (after.get("position", Vector2.ZERO) as Vector2).is_equal_approx(before.get("position", Vector2.ZERO))
	)


func _place_companion(companion, position: Vector2) -> void:
	if companion.has_method("set_external_control_active"):
		companion.set_external_control_active(true)
	companion.global_position = position
	if companion.has_method("set_external_control_active"):
		companion.set_external_control_active(false)


func _parse_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _finish(main, original_paused: bool, original_time_scale: float, evidence := {}) -> void:
	if main != null and is_instance_valid(main):
		main.queue_free()
	paused = original_paused
	Engine.time_scale = original_time_scale
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Companion tactical-pause smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Companion command timing policy=tactical_pause keyboard=BOND+TOOL hostile=%s player=frozen oxygen=frozen daylight=frozen hazards=frozen companion=frozen mobile=shared_action restoration=close+retry+debrief+map_change+scene_exit." % str(evidence))
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
