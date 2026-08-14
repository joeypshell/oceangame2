extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const CompanionAnchorFinsRuntime := preload("res://scripts/companion/companion_anchor_fins_runtime.gd")
const CompanionGuardianPulseRuntime := preload("res://scripts/companion/companion_guardian_pulse_runtime.gd")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ReviewCheckpointLivingExpedition06 := preload("res://scripts/main/review_checkpoint_living_expedition_06.gd")
const ReviewProfileMode := preload("res://scripts/main/review_profile_mode.gd")

const SMOKE_FLAG := "--smoke-living-expedition-06"
const JOURNEY_ID := "signal_reef_nursery_journey_01"
const KITE_ID := "spark_ray_juvenile_01"
const SHELTERED_PENDING_RETURN := "sheltered_pending_return"
const COMMITTED_WAITING_NEXT_DAY := "committed_waiting_next_day"
const RESTORED := "restored"
const FIELD_STEP_SECONDS := 0.1

var _failures: Array[String] = []
var _evidence := {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_expect(args.has(SMOKE_FLAG), "missing %s" % SMOKE_FLAG)
	var checkpoint_id := ReviewProfileMode.checkpoint_id(OS.get_cmdline_user_args(), OS.get_cmdline_args())
	var branch := _branch_for_checkpoint(checkpoint_id)
	_expect(not branch.is_empty(), "expected an LE06 Anchor or Guardian checkpoint")
	if branch.is_empty():
		_finish(null)
		return

	var main = MAIN_SCENE.instantiate()
	get_root().add_child(main)
	for _frame in range(4):
		await process_frame
		await physics_frame
	_expect(main._review_checkpoint_id == checkpoint_id and bool(main._review_checkpoint_report.get("ready", false)), "actual Main rejected %s" % checkpoint_id)
	if not bool(main._review_checkpoint_report.get("ready", false)):
		_finish(main)
		return
	_freeze_runtime(main)
	var profile = main._anomaly_survey.profile_state()
	var journey_before: Dictionary = profile.signal_reef_journey_report()
	_expect(str(journey_before.get("state", "")) == "unresolved", "branch checkpoint pre-completed the journey")
	_expect(str(profile.companion_report().get("active_individual_id", "")) == KITE_ID, "branch checkpoint did not make Kite active")

	var cargo_ids := _fill_cargo(main)
	var full_count: int = main._held_salvage_capacity()
	_expect(cargo_ids.size() == full_count and main._sortie_state.held_salvage == full_count, "could not establish full-cargo field pressure")
	var oxygen_start: float = main._sortie_state.oxygen_seconds
	var health_start := int(main._player_health.report().get("current_health", 0))
	var first_field := _perform_field_action(main, branch, true)
	_expect(bool(first_field.get("ready", false)), "first field response failed: %s" % first_field)
	_expect(main._sortie_state.held_salvage_ids == cargo_ids, "nursery response mutated full cargo")
	_expect(int(main._player_health.report().get("current_health", 0)) == health_start, "nursery response damaged the diver")
	_expect(str(profile.signal_reef_journey_report().get("state", "")) == "unresolved", "field response wrote durable history")

	var retried := false
	if str(branch.get("adaptation_id", "")) == "anchor_fins":
		main._sortie_state.oxygen_seconds = 0.0
		main._handle_oxygen_depleted()
		_expect(main._sortie_state.failed, "oxygen depletion did not enter failure state")
		_expect(_nursery_state(main) == "unresolved" and str(profile.signal_reef_journey_report().get("state", "")) == "unresolved", "oxygen failure retained field history")
		_expect(main._sortie_state.held_salvage == 0, "oxygen failure retained full cargo")
		main._reset_run()
		_freeze_runtime(main)
		_place_for_branch(main, branch)
		_expect(not main._sortie_state.failed, "Retry did not restore the sortie")
		var retry_field := _perform_field_action(main, branch, false)
		_expect(bool(retry_field.get("ready", false)), "Retry field response failed: %s" % retry_field)
		retried = true

	var old_world_id: int = main._world.get_instance_id()
	main._player.global_position = main._world.get_extraction_center()
	main._cargo_collection.update(0.0)
	var committed: Dictionary = profile.signal_reef_journey_report()
	_expect(str(committed.get("state", "")) == COMMITTED_WAITING_NEXT_DAY, "canonical boat did not commit the journey")
	_expect(str(committed.get("adaptation_id", "")) == str(branch.get("adaptation_id", "")), "boat committed the wrong adaptation")
	_expect(main._sortie_state.held_salvage == 0, "canonical boat did not offload full cargo")
	var duplicate: Dictionary = main._companion_sortie.commit_memories_at_boat(main._expedition_day_state.day_number)
	_expect(str((duplicate.get("signal_reef_nursery", {}) as Dictionary).get("reason", "")) == "already_committed", "duplicate boat check rewrote history")

	var day_before: int = main._expedition_day_state.day_number
	var next_day: Dictionary = _start_next_day(main)
	for _frame in range(3):
		await process_frame
		await physics_frame
	_freeze_runtime(main)
	var restored: Dictionary = profile.signal_reef_journey_report()
	var nursery: Dictionary = main._world.get_signal_reef_nursery_report()
	_expect(bool(next_day.get("changed", false)) and str(next_day.get("reason", "")) == "next_day_started", "authoritative day owner did not begin the next day: %s" % next_day)
	_expect(main._expedition_day_state.day_number == day_before + 1 and main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE, "next-day state did not advance exactly once")
	_expect(main._world.get_instance_id() != old_world_id, "next-day transition did not reload the authored map")
	_expect(str(restored.get("state", "")) == RESTORED and str(nursery.get("state", "")) == RESTORED, "profile/world restoration projection drifted")
	_expect(int(nursery.get("school_member_count", 0)) == 7, "restored nursery did not contain seven filter skates")
	_expect(_command_ids(main).find(str(branch.get("action_id", ""))) == -1, "restored nursery retained a repeat field action")
	var repeated_day: Dictionary = main._companion_sortie.advance_signal_reef_journey_day(main._expedition_day_state.day_number + 1)
	_expect(str(repeated_day.get("reason", "")) == "already_restored" and int(main._world.get_signal_reef_nursery_report().get("school_member_count", 0)) == 7, "duplicate day advance changed the restored habitat")

	_evidence = {
		"journey": JOURNEY_ID,
		"individual": KITE_ID,
		"branch": branch.get("adaptation_id", ""),
		"context": first_field.get("context_id", ""),
		"field": SHELTERED_PENDING_RETURN,
		"boat": COMMITTED_WAITING_NEXT_DAY,
		"day": RESTORED,
		"cargo_full": full_count,
		"retry": retried,
		"oxygen_start": oxygen_start,
		"oxygen_after": main._sortie_state.oxygen_seconds,
		"map_reloaded": true,
	}
	_finish(main)


func _perform_field_action(main, branch: Dictionary, preserve_cargo: bool) -> Dictionary:
	_place_for_branch(main, branch)
	var coordinator = main._companion_sortie.signal_reef_nursery_runtime()
	coordinator.advance()
	main._world.advance_signal_reef_nursery(0.5)
	_expect(_nursery_state(main) == "unresolved", "%s auto-fired before BOND" % branch.get("adaptation_id", ""))
	var control = main._companion_sortie.control_runtime()
	var opened: Dictionary = control.begin_command_mode()
	_expect(paused and str(opened.get("timing_policy", "")) == "tactical_pause", "BOND did not pause the full simulation")
	var action_id := str(branch.get("action_id", ""))
	var command_index := _command_ids(main).find(action_id)
	_expect(command_index >= 0, "BOND palette omitted %s" % action_id)
	if command_index < 0:
		control.end_command_mode()
		return {"ready": false, "reason": "missing_command"}
	var dispatched: Dictionary = control.activate_context_command(command_index)
	_expect(bool(dispatched.get("changed", false)) and not paused, "numbered/mobile-equivalent command dispatch failed")
	_expect(_nursery_state(main) == "unresolved", "%s completed instantly" % action_id)
	var runtime = main._companion_sortie.adaptation_runtime() if action_id == CompanionAnchorFinsRuntime.ACTION_ID else main._companion_sortie.guardian_pulse_runtime()
	var partial := 0.7 if action_id == CompanionAnchorFinsRuntime.ACTION_ID else 0.2
	var remainder := 0.9 if action_id == CompanionAnchorFinsRuntime.ACTION_ID else 0.3
	runtime.advance(partial, false)
	main._sortie_state.drain_oxygen(partial)
	coordinator.advance()
	_expect(_nursery_state(main) == "unresolved", "%s partial hold completed the response" % action_id)
	runtime.advance(remainder, false)
	main._sortie_state.drain_oxygen(remainder)
	coordinator.advance()
	var active_state := "anchor_active" if action_id == CompanionAnchorFinsRuntime.ACTION_ID else "guardian_active"
	_expect(_nursery_state(main) == active_state, "%s did not start its authored response" % action_id)
	for _step in range(40):
		if _nursery_state(main) == SHELTERED_PENDING_RETURN:
			break
		main._world.advance_signal_reef_nursery(FIELD_STEP_SECONDS)
		main._sortie_state.drain_oxygen(FIELD_STEP_SECONDS)
	var nursery: Dictionary = main._world.get_signal_reef_nursery_report()
	_expect(str(nursery.get("state", "")) == SHELTERED_PENDING_RETURN, "%s did not shelter the school" % action_id)
	_expect(not bool(nursery.get("damaging", true)) and (nursery.get("reward_ids", []) as Array).is_empty(), "field response damaged wildlife or granted a reward")
	if preserve_cargo:
		_expect(main._sortie_state.held_salvage == main._held_salvage_capacity(), "field response consumed full cargo")
	return {
		"ready": _nursery_state(main) == SHELTERED_PENDING_RETURN,
		"context_id": str(runtime.report().get("payoff_id", "")),
	}


func _start_next_day(main) -> Dictionary:
	_expect(main._expedition_day_state.request_end_day("signal_reef_smoke"), "could not request night at the canonical boat")
	ExpeditionDayDebrief.update(main, 0.0)
	_expect(main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "night request did not enter debrief")
	var result: Dictionary = ExpeditionDayDebrief.handle_day_key(main)
	if str(result.get("reason", "")) == "plan_required":
		var plan: Dictionary = main._refresh_expedition_plan()
		var eligible: Array = plan.get("eligible_ids", [])
		if not eligible.is_empty():
			main._expedition_plan_state.select(str(eligible[0]), eligible, ExpeditionDayState.PHASE_DEBRIEF)
		result = ExpeditionDayDebrief.handle_day_key(main)
	return result


func _fill_cargo(main) -> Array[String]:
	var ids: Array[String] = []
	for value in main._world.get_salvage_centers():
		var salvage: Dictionary = value
		var salvage_id := str(salvage.get("id", ""))
		if salvage_id.is_empty() or not main._world.collect_salvage_by_id(salvage_id):
			continue
		main._sortie_state.collect_salvage(salvage_id, main._world.get_salvage_score(salvage_id))
		ids.append(salvage_id)
		if ids.size() >= main._held_salvage_capacity():
			break
	return ids


func _place_for_branch(main, branch: Dictionary) -> void:
	var companion = main._companion_sortie.companion()
	var target := Vector2.ZERO
	if str(branch.get("adaptation_id", "")) == "anchor_fins":
		for gate in main._world.get_current_gates():
			if str((gate as Dictionary).get("id", "")) == "lower_right_east_current_gate":
				target = (gate as Dictionary).get("center", Vector2.ZERO)
	else:
		target = main._world.get_signal_reef_nursery_report().get("pressure_center", Vector2.ZERO) + Vector2(-100.0, 0.0)
	companion.recover_to_player()
	companion.set_external_control_active(true)
	companion.global_position = target
	main._player.global_position = target
	companion.set_external_control_active(false)
	companion.advance(0.0)
	if str(branch.get("adaptation_id", "")) == "guardian_pulse":
		main._player.swim_in_direction(Vector2.RIGHT, 0.0)


func _freeze_runtime(main) -> void:
	main.set_process(false)
	main._player.set_physics_process(false)
	var companion = main._companion_sortie.companion()
	if companion != null:
		companion.set_physics_process(false)
	var control = main._companion_sortie.control_runtime()
	if control != null:
		control.set_process(false)
		control.set_physics_process(false)
	main._companion_sortie.signal_reef_nursery_runtime().set_process(false)
	var presentation = main._world.get_node_or_null("Markers/SignalReefNursery")
	if presentation != null:
		presentation.set_process(false)


func _branch_for_checkpoint(checkpoint_id: String) -> Dictionary:
	if checkpoint_id == ReviewCheckpointLivingExpedition06.ANCHOR_READY_ID:
		return {"adaptation_id": "anchor_fins", "action_id": CompanionAnchorFinsRuntime.ACTION_ID}
	if checkpoint_id == ReviewCheckpointLivingExpedition06.GUARDIAN_READY_ID:
		return {"adaptation_id": "guardian_pulse", "action_id": CompanionGuardianPulseRuntime.ACTION_ID}
	return {}


func _command_ids(main) -> Array[String]:
	var ids: Array[String] = []
	for command in main._companion_sortie.control_runtime().report().get("context_commands", []):
		ids.append(str((command as Dictionary).get("id", "")))
	return ids


func _nursery_state(main) -> String:
	return str(main._world.get_signal_reef_nursery_report().get("state", ""))


func _finish(main) -> void:
	paused = false
	Engine.time_scale = 1.0
	if main != null:
		main.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Living Expedition 06 journey smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Living Expedition 06 journey evidence=%s gates={auto_fire:false instant:false damage:false rewards:none equipment:preserved wrong_companion:separate_matrix mounted:separate_matrix mobile:shared_dispatch}." % str(_evidence))
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
