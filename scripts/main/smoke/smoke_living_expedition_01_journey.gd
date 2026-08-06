extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const CompanionAnchorFinsRuntime := preload("res://scripts/companion/companion_anchor_fins_runtime.gd")
const CompanionGuardianPulseRuntime := preload("res://scripts/companion/companion_guardian_pulse_runtime.gd")
const CompanionRescueRuntime := preload("res://scripts/companion/companion_rescue_runtime.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const RESCUE_ID := "spark_ray_rescue_01"
const INDIVIDUAL_ID := "spark_ray_juvenile_01"
const BOAT_ENTRY_ID := "surface_boat_entry"
const FLOW_MEMORY_ID := "held_the_flow"
const GROUND_MEMORY_ID := "stood_ground"
const FLOW_GATE_ID := "lower_right_west_current_gate"
const ANCHOR_GATE_ID := "lower_right_east_current_gate"
const HOSTILE_ID := "deep_cache_territorial_eel"

var _failures: Array[String] = []


class HostileFixture:
	extends RefCounted
	var state := {}

	func state_for(_hostile_id: String) -> Dictionary:
		return state.duplicate(true)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_time_scale := Engine.time_scale
	var branch_reports: Array[String] = []
	for adaptation_id in ["anchor_fins", "guardian_pulse"]:
		var main = await _spawn_main()
		if main == null:
			break
		var report := await _run_branch(main, adaptation_id)
		branch_reports.append(report)
		Engine.time_scale = 1.0
		main.queue_free()
		await process_frame
		await process_frame
	Engine.time_scale = original_time_scale
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Living Expedition 01 journey smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Living Expedition 01 journey checkpoint=pre_rescue branches=[%s] isolation=true equipment_gates=domain_smokes." % "; ".join(branch_reports))
	quit(0)


func _spawn_main():
	var main = MAIN_SCENE.instantiate()
	get_root().add_child(main)
	await process_frame
	await physics_frame
	main.set_process(false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	main._combat_interactions_enabled = false
	_expect(main._world.map_id == "production_level_01", "checkpoint did not load the full production level")
	_expect(main._review_checkpoint_id == ReviewCheckpointFixture.LIVING_EXPEDITION_01_START, "journey did not start from the Living Expedition checkpoint")
	_expect(bool(main._review_checkpoint_report.get("ready", false)), "Living Expedition checkpoint was rejected")
	_expect(str(main._anomaly_survey.profile_state().last_storage_report().get("status", "")) == "memory", "checkpoint enabled profile persistence")
	_expect(not main._anomaly_survey.profile_state().has_committed_companion(), "checkpoint began after rescue commitment")
	return main


func _run_branch(main, adaptation_id: String) -> String:
	var profile = main._anomaly_survey.profile_state()
	var rescue := _rescue_by_id(main._world, RESCUE_ID)
	_expect(not rescue.is_empty(), "%s branch lost the physical rescue" % adaptation_id)
	if rescue.is_empty():
		return "branch=%s missing_rescue" % adaptation_id

	main._sortie_state.collect_salvage("journey_full_cargo_a", 0)
	main._sortie_state.collect_salvage("journey_full_cargo_b", 0)
	main._player.global_position = rescue.get("center", Vector2.ZERO)
	_expect(_select_tool(main, "salvage_cutter"), "%s branch could not select Cutter" % adaptation_id)
	var activated: Dictionary = main._active_tool_runtime.use()
	_expect(str(activated.get("status", "")) == "used", "%s full cargo blocked physical rescue" % adaptation_id)
	var partial: Dictionary = main._companion_rescue.update(CompanionRescueRuntime.RELEASE_SECONDS * 0.35)
	_expect(str(partial.get("state", "")) == "releasing" and not profile.has_committed_companion(), "%s rescue did not remain pending during Cutter hold" % adaptation_id)
	main._companion_rescue.update(CompanionRescueRuntime.RELEASE_SECONDS)
	main._active_tool_runtime.release_use()
	_expect(main._companion_rescue.pending_companion() != null, "%s rescue did not free a sortie-local juvenile" % adaptation_id)
	main._sortie_state.clear_held()
	main._player.global_position = main._world.get_entry_position(BOAT_ENTRY_ID)
	main._cargo_collection.update(0.0)
	_expect(profile.has_committed_companion(), "%s canonical boat did not commit the bond" % adaptation_id)
	_expect(main._companion_sortie.companion() == null, "%s riding unlocked on the rescue sortie" % adaptation_id)

	main._expedition_day_state.begin_next_day()
	main._expedition_day_state.record_sortie_started()
	var spawned: Dictionary = main._companion_sortie.sync_spawn()
	var ray = main._companion_sortie.companion()
	_expect(bool(spawned.get("spawned", false)) and ray != null, "%s next sortie did not spawn the bonded Spark Ray" % adaptation_id)
	if ray == null:
		return "branch=%s no_companion" % adaptation_id
	_disable_companion_processing(main, ray)
	_place_pair(main._player, ray, main._world.get_entry_position(BOAT_ENTRY_ID) + Vector2(100.0, 80.0))

	var control = main._companion_sortie.control_runtime()
	var command_opened: Dictionary = control.begin_command_mode()
	_expect(is_equal_approx(Engine.time_scale, 0.2), "%s BOND did not slow complete simulation to 20 percent" % adaptation_id)
	_expect((command_opened.get("context_commands", []) as Array).size() <= 3, "%s command palette exceeded three actions" % adaptation_id)
	control.end_command_mode()
	_expect(is_equal_approx(Engine.time_scale, 1.0), "%s command close did not restore simulation speed" % adaptation_id)
	_expect(bool(control.request_mount().get("changed", false)), "%s base riding did not unlock on Day 2" % adaptation_id)
	var hotbar: Array = control.report().get("mounted_actions", [])
	_expect(not hotbar.is_empty() and str(hotbar[0].get("id", "")) == "glide_surge", "%s mounted hotbar omitted Glide Surge" % adaptation_id)
	var before: Vector2 = ray.global_position
	control.activate_mounted_action()
	control.advance_mounted_movement(0.12, Vector2.RIGHT)
	_expect(ray.global_position.distance_to(before) > 1.0, "%s mounted movement did not transfer to the Spark Ray" % adaptation_id)
	control.request_dismount()

	var memory_id := FLOW_MEMORY_ID if adaptation_id == "anchor_fins" else GROUND_MEMORY_ID
	var memory_result := _qualify_memory(main, ray, memory_id)
	_expect(memory_result.get("memory_id") == memory_id, "%s branch did not qualify %s" % [adaptation_id, memory_id])
	main._player.global_position = main._world.get_entry_position(BOAT_ENTRY_ID)
	var committed: Dictionary = main._companion_sortie.commit_memories_at_boat()
	_expect(bool(committed.get("changed", false)), "%s memory did not commit at the canonical boat" % adaptation_id)
	_expect((profile.companion_report().get("individual", {}).get("earned_memory_ids", []) as Array).has(memory_id), "%s profile omitted committed memory" % adaptation_id)

	main._expedition_day_state.end_day("journey_smoke")
	main._companion_sortie.begin_debrief()
	_expect(main._companion_sortie.requires_adaptation_selection(), "%s night did not require a deliberate adaptation" % adaptation_id)
	var use := InputEventAction.new()
	use.action = "active_tool_use"
	use.pressed = true
	var selected: Dictionary = main._companion_sortie.handle_debrief_input(use)
	_expect(bool(selected.get("changed", false)) and selected.get("adaptation_id") == adaptation_id, "%s was not consolidated at night" % adaptation_id)
	main._companion_sortie.end_debrief()
	main._expedition_day_state.begin_next_day()
	main._expedition_day_state.record_sortie_started()
	_respawn_adapted_companion(main)
	ray = main._companion_sortie.companion()
	_disable_companion_processing(main, ray)
	var payoff := _prove_payoff(main, ray, adaptation_id)
	_expect(bool(payoff.get("independent", false)) and bool(payoff.get("mounted", false)), "%s did not work in both roles" % adaptation_id)

	main._companion_sortie.reset_control("retry")
	_expect(not main._companion_sortie.control_runtime().is_mounted() and is_equal_approx(Engine.time_scale, 1.0), "%s Retry retained mounted or slow-time state" % adaptation_id)
	var profile_report: Dictionary = profile.companion_report()
	var individual: Dictionary = profile_report.get("individual", {})
	var day: Dictionary = main._expedition_day_state.report()
	return (
		"branch=%s individual=%s active=%s mode=independent mounted=false memory=%s action=%s "
		+ "day=%d sortie=%d health=%d/%d oxygen=%.1f payoff=%s"
	) % [
		adaptation_id,
		str(individual.get("individual_id", "")),
		str(profile_report.get("active_individual_id", "")),
		memory_id,
		str(payoff.get("action_id", "")),
		int(day.get("day_number", 0)),
		int(day.get("sortie_count", 0)),
		int(main._player_health.current_health),
		int(main._player_health.max_health),
		float(main._sortie_state.oxygen_seconds),
		str(payoff.get("result", "")),
	]


func _qualify_memory(main, ray, memory_id: String) -> Dictionary:
	if memory_id == FLOW_MEMORY_ID:
		var gate := _gate_by_id(main._world, FLOW_GATE_ID)
		var rect: Rect2 = gate.get("rect", Rect2())
		var push := _direction_vector(str(gate.get("current_direction", "")))
		var half_span := rect.size.x * 0.5 if absf(push.x) > 0.0 else rect.size.y * 0.5
		var entry := rect.get_center() + push * (half_span + 12.0)
		var exit := rect.get_center() - push * (half_span + 12.0)
		_place_pair(main._player, ray, entry)
		main._companion_sortie.observe_current({})
		_place_pair(main._player, ray, rect.get_center())
		main._companion_sortie.observe_current({"inside": true, "blocked": false, "id": FLOW_GATE_ID})
		_place_pair(main._player, ray, exit)
		return main._companion_sortie.observe_current({})
	var hostiles := HostileFixture.new()
	var territory := Rect2(Vector2(3600.0, 2100.0), Vector2(240.0, 180.0))
	_place_pair(main._player, ray, territory.get_center())
	hostiles.state = {"id": HOSTILE_ID, "phase": "warning", "territory_rect": territory}
	main._companion_sortie.observe_hostiles(hostiles, {"id": HOSTILE_ID, "kind": "warning"})
	hostiles.state["phase"] = "lunge"
	main._companion_sortie.observe_hostiles(hostiles, {"id": HOSTILE_ID, "kind": "lunge"})
	return main._companion_sortie.observe_hostiles(hostiles, {"id": HOSTILE_ID, "kind": "contact"})


func _prove_payoff(main, ray, adaptation_id: String) -> Dictionary:
	if adaptation_id == "anchor_fins":
		var gate := _gate_by_id(main._world, ANCHOR_GATE_ID)
		_place_pair(main._player, ray, gate.get("center", Vector2.ZERO))
		var runtime = main._companion_sortie.adaptation_runtime()
		var independent: Dictionary = runtime.dispatch("independent", CompanionAnchorFinsRuntime.ACTION_ID)
		runtime.advance(1.6, false)
		var independent_ok: bool = bool(independent.get("changed", false)) and runtime.report().get("last_result") == "success"
		runtime.reset("mounted_journey")
		_place_pair(main._player, ray, gate.get("center", Vector2.ZERO))
		var control = main._companion_sortie.control_runtime()
		var mounted_ok: bool = bool(control.request_mount().get("changed", false))
		mounted_ok = mounted_ok and _select_mounted_action(control, CompanionAnchorFinsRuntime.ACTION_ID)
		mounted_ok = mounted_ok and bool(control.activate_mounted_action().get("changed", false))
		runtime.advance(1.6, true)
		mounted_ok = mounted_ok and runtime.report().get("last_result") == "success"
		return {"independent": independent_ok, "mounted": mounted_ok, "action_id": CompanionAnchorFinsRuntime.ACTION_ID, "result": runtime.report().get("follow_up", "")}
	var guardian = main._companion_sortie.guardian_pulse_runtime()
	var control = main._companion_sortie.control_runtime()
	var independent_ok: bool = _prepare_guardian_warning(main, ray) and bool(guardian.dispatch("independent", CompanionGuardianPulseRuntime.ACTION_ID).get("changed", false))
	guardian.advance(0.5, false)
	independent_ok = independent_ok and guardian.report().get("last_result") == "hit"
	guardian.reset("mounted_journey")
	var mounted_ok: bool = _prepare_guardian_warning(main, ray) and bool(control.request_mount().get("changed", false))
	mounted_ok = mounted_ok and _select_mounted_action(control, CompanionGuardianPulseRuntime.ACTION_ID)
	mounted_ok = mounted_ok and bool(control.activate_mounted_action().get("changed", false))
	guardian.advance(0.5, true)
	mounted_ok = mounted_ok and guardian.report().get("last_result") == "hit"
	return {"independent": independent_ok, "mounted": mounted_ok, "action_id": CompanionGuardianPulseRuntime.ACTION_ID, "result": guardian.report().get("last_result", "")}


func _prepare_guardian_warning(main, ray) -> bool:
	main._hostiles.reset_for_failure(main._world)
	var home: Vector2 = main._hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	_place_pair(main._player, ray, home + Vector2(-100.0, 0.0))
	main._hostiles.update(main._world, main._player.global_position, 0.0)
	return main._hostiles.state_for(HOSTILE_ID).get("phase") == "warning"


func _respawn_adapted_companion(main) -> void:
	main._companion_sortie.bind_map(
		main._world,
		main._player,
		main._anomaly_survey.profile_state(),
		Callable(main, "_has_upgrade_id"),
		true,
		false,
		main._hostiles
	)


func _disable_companion_processing(main, ray) -> void:
	if ray == null:
		return
	ray.set_physics_process(false)
	main._companion_sortie.set_process(false)
	var control = main._companion_sortie.control_runtime()
	control.set_process(false)
	control.set_physics_process(false)


func _place_pair(player, ray, position: Vector2) -> void:
	ray.set_external_control_active(true)
	ray.global_position = position
	player.global_position = position
	ray.set_external_control_active(false)
	ray.advance(0.0)


func _select_tool(main, tool_id: String) -> bool:
	main._refresh_active_tools()
	for _step in range(main.ActiveToolController.ordered_tool_ids().size()):
		if main._active_tools.selected_tool_id() == tool_id:
			return true
		main._active_tool_runtime.cycle()
	return false


func _select_mounted_action(control, action_id: String) -> bool:
	for _step in range(3):
		if control.report().get("selected_action_id") == action_id:
			return true
		control.cycle_mounted_action()
	return false


func _rescue_by_id(world, rescue_id: String) -> Dictionary:
	for rescue in world.get_creature_rescues():
		if str(rescue.get("id", "")) == rescue_id:
			return rescue
	return {}


func _gate_by_id(world, gate_id: String) -> Dictionary:
	for gate in world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _direction_vector(direction: String) -> Vector2:
	match direction:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
	return Vector2.ZERO


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
