extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ActiveToolHud := preload("res://scripts/main/active_tool_hud.gd")
const CompanionAnchorFinsRuntime := preload("res://scripts/companion/companion_anchor_fins_runtime.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const PROFILE_PATH := "user://oceangame2_anchor_fins_smoke.json"
const TARGET_GATE_ID := "lower_right_east_current_gate"
const PAYOFF_ID := "spark_ray_anchor_current_01"
const ACTION_ID := "anchor_brace"

var _failures: Array[String] = []
var _status_notes: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var original_time_scale := Engine.time_scale
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	await process_frame
	var gate := _gate_by_id(world, TARGET_GATE_ID)
	_expect(not gate.is_empty(), "source-authored east current payoff target is missing")
	_expect(
		_payoff_by_id(world, PAYOFF_ID).get("target_id") == TARGET_GATE_ID,
		"runtime source accessor did not preserve the authored payoff target"
	)
	if gate.is_empty():
		_finish(world, null, null, null, original_time_scale)
		return

	var profile = _prepared_profile(world, "Kite", "anchor_fins", true, PROFILE_PATH, true)
	var player = PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	player.global_position = world.spawn_position
	var runtime := CompanionSortieRuntime.new()
	get_root().add_child(runtime)
	runtime.set_process(false)
	var hud := ActiveToolHud.new()
	get_root().add_child(hud)
	hud.refresh({"selected_tool_id": "survey_scanner_1", "owned_tool_ids": ["survey_scanner_1"]})
	runtime.bind_interface(hud, Callable(self, "_record_status"), Callable(self, "_cancel_tool"), Callable(self, "_can_control"))
	var spawn: Dictionary = runtime.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), true)
	var ray = runtime.companion()
	var control = runtime.control_runtime()
	var anchor = runtime.adaptation_runtime()
	_expect(bool(spawn.get("spawned", false)) and ray != null, "adapted Spark Ray did not spawn")
	if ray == null or control == null:
		_finish(world, player, runtime, hud, original_time_scale)
		return
	ray.set_physics_process(false)
	control.set_process(false)
	control.set_physics_process(false)
	_place_pair(player, ray, gate.get("center", Vector2.ZERO))
	_test_visible_variant(ray)
	_test_independent_brace(control, anchor, player, ray, gate)
	_test_retry_reset(runtime, control, anchor, player, ray, gate)
	_test_mounted_brace(control, anchor, player, ray, gate)
	_test_access_and_branch_boundaries(world, gate, player, ray)
	_test_profile_reload()
	_finish(world, player, runtime, hud, original_time_scale)


func _test_visible_variant(ray) -> void:
	var presentation: Dictionary = ray.report().get("presentation", {})
	_expect(presentation.get("adaptation_id") == "anchor_fins", "selected adaptation did not reach the Spark Ray presentation")
	_expect(str(presentation.get("variant_label", "")).find("Kite") != -1, "Anchor Fins variant lost the individual's callsign")
	_expect(not bool(ray.report().get("anchor_braced", true)), "adapted Spark Ray spawned in transient brace state")


func _test_independent_brace(control, anchor, player, ray, gate: Dictionary) -> void:
	var opened: Dictionary = control.begin_command_mode()
	var commands: Array = opened.get("context_commands", [])
	_expect(
		commands.map(func(command): return str(command.get("id", ""))).has(ACTION_ID),
		"independent BOND palette omitted Anchor brace at the authored current"
	)
	var engaged := _confirm_command(control, ACTION_ID)
	_expect(
		bool(engaged.get("changed", false)) and engaged.get("role") == "independent",
		"independent BOND command did not engage Anchor Fins"
	)
	anchor.advance(0.65, false)
	var progress: Dictionary = anchor.report()
	_expect(float(progress.get("progress", 0.0)) > 0.35, "independent brace did not report duration progress")
	_expect(bool(ray.report().get("anchor_braced", false)), "independent brace did not hold the Spark Ray")
	_expect(bool(ray.report().get("presentation", {}).get("stable_posture", false)), "independent brace omitted the low stable posture")
	player.global_position += Vector2.RIGHT * 32.0
	anchor.advance(0.05, false)
	_expect(str(anchor.report().get("last_result", "")).begins_with("cancelled:"), "moving away did not cancel independent brace")
	_expect(ray.report().get("presentation", {}).get("anchor_state") == "cancelled", "cancelled brace omitted its visual cue")

	_place_pair(player, ray, gate.get("center", Vector2.ZERO))
	var restarted: Dictionary = anchor.dispatch("independent", ACTION_ID)
	_expect(bool(restarted.get("changed", false)), "independent brace could not restart after cancellation")
	anchor.advance(1.6, false)
	var success: Dictionary = anchor.report()
	_expect(
		bool(success.get("completed_this_sortie", false)) and success.get("success_count") == 1,
		"independent brace did not complete exactly once"
	)
	_expect(success.get("follow_up") == "deeper_signal_reef_response", "current payoff ended as score/salvage instead of a route promise")
	_expect(
		_status_notes.any(func(note): return str(note).find("deeper Signal Reef response") != -1),
		"successful brace omitted its next-day route reason"
	)
	var cooldown: Dictionary = anchor.dispatch("independent", ACTION_ID)
	_expect(cooldown.get("reason") == "brace_cooling_down", "completed brace ignored cooldown")
	_expect(ray.report().get("presentation", {}).get("anchor_state") == "cooldown", "cooldown denial omitted its recovery cue")


func _test_retry_reset(runtime, control, anchor, player, ray, gate: Dictionary) -> void:
	anchor.reset("retry_fixture")
	_place_pair(player, ray, gate.get("center", Vector2.ZERO))
	var started: Dictionary = anchor.dispatch("independent", ACTION_ID)
	_expect(bool(started.get("changed", false)), "retry fixture could not engage brace")
	runtime.reset_control("retry")
	_expect(
		not bool(anchor.report().get("active", true))
		and is_zero_approx(float(anchor.report().get("cooldown_seconds", -1.0))),
		"Retry retained transient brace or cooldown state"
	)
	_expect(not bool(ray.report().get("anchor_braced", true)), "Retry left the Spark Ray physically braced")
	_expect(not control.is_mounted(), "Retry reset unexpectedly mounted the companion")


func _test_mounted_brace(control, anchor, player, ray, gate: Dictionary) -> void:
	anchor.reset("mounted_fixture")
	_place_pair(player, ray, gate.get("center", Vector2.ZERO))
	var mounted: Dictionary = control.request_mount()
	_expect(bool(mounted.get("changed", false)), "mounted Anchor Fins fixture could not mount")
	control.cycle_mounted_action()
	var selected: Dictionary = control.report()
	_expect(selected.get("selected_action_id") == ACTION_ID, "mounted creature hotbar did not project Anchor brace")
	var engaged: Dictionary = control.activate_mounted_action()
	_expect(bool(engaged.get("changed", false)) and engaged.get("role") == "mounted", "mounted Space/USE did not engage Anchor brace")
	var before: Vector2 = ray.global_position
	var movement: Dictionary = control.advance_mounted_movement(0.2, Vector2.RIGHT)
	_expect(
		movement.get("reason") == "anchor_brace"
		and ray.global_position.distance_to(before) <= 0.01,
		"mounted brace did not hold position against movement"
	)
	var interrupted: Dictionary = control.request_dismount()
	_expect(bool(interrupted.get("changed", false)), "mounted brace could not be deliberately cancelled by dismount")
	anchor.advance(0.01, false)
	_expect(anchor.report().get("last_result") == "cancelled:mode_changed", "dismount did not cancel the mounted brace")

	anchor.reset("mounted_success_fixture")
	_place_pair(player, ray, gate.get("center", Vector2.ZERO))
	_expect(bool(control.request_mount().get("changed", false)), "mounted success fixture could not remount")
	if control.report().get("selected_action_id") != ACTION_ID:
		control.cycle_mounted_action()
	_expect(bool(control.activate_mounted_action().get("changed", false)), "mounted success fixture could not re-engage Anchor brace")
	anchor.advance(1.6, true)
	_expect(anchor.report().get("last_result") == "success", "mounted brace did not complete the authored payoff")
	_expect(ray.report().get("presentation", {}).get("anchor_state") == "success", "mounted payoff omitted its success cue")
	control.request_dismount()
	_expect(not control.is_mounted(), "mounted payoff prevented a clear dismount")


func _test_access_and_branch_boundaries(world, gate: Dictionary, player, ray) -> void:
	var no_fins = _prepared_profile(world, "Drift", "anchor_fins", false)
	var denied := CompanionAnchorFinsRuntime.new()
	denied.bind_status_sink(Callable(self, "_record_status"))
	denied.bind_map(world, player, no_fins, ray, Callable(self, "_has_no_upgrade"), Callable(no_fins, "has_capability"))
	ray.apply_identity(no_fins.companion_report().get("individual", {}))
	_place_pair(player, ray, gate.get("center", Vector2.ZERO))
	var action: Dictionary = denied.actions("independent_palette")[0]
	_expect(
		not bool(action.get("enabled", true))
		and action.get("reason") == "need_propulsion_fins",
		"Anchor Fins did not disclose the missing diver-equipment gate"
	)
	_expect(denied.dispatch("independent", ACTION_ID).get("reason") == "need_propulsion_fins", "Anchor Fins bypassed missing propulsion fins")
	var gate_block := CurrentGateController.new().gate_blocks_position(
		world,
		gate.get("center", Vector2.ZERO),
		Callable(self, "_has_no_upgrade"),
		Callable(no_fins, "has_capability")
	)
	_expect(gate_block.get("id") == TARGET_GATE_ID, "existing current authority stopped blocking a no-fins profile")

	for branch in ["", "guardian_pulse"]:
		var profile = _prepared_profile(world, "Other", branch, true)
		var branch_runtime := CompanionAnchorFinsRuntime.new()
		branch_runtime.bind_map(world, player, profile, ray, Callable(self, "_has_no_upgrade"), Callable(profile, "has_capability"))
		ray.apply_identity(profile.companion_report().get("individual", {}))
		_expect(
			branch_runtime.actions("mounted_hotbar").is_empty(),
			"%s Spark Ray received Anchor brace" % ("base" if branch.is_empty() else "Guardian")
		)


func _test_profile_reload() -> void:
	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var load: Dictionary = reloaded.load_profile()
	var companion: Dictionary = reloaded.companion_report()
	_expect(load.get("status") == "loaded", "Anchor Fins profile did not reload")
	_expect(companion.get("individual", {}).get("selected_adaptation_id") == "anchor_fins", "profile reload lost Anchor Fins")
	_expect(not companion.has("mounted") and not companion.has("cooldown_seconds"), "profile persisted transient mounted or cooldown state")


func _prepared_profile(world, callsign: String, adaptation_id: String, with_fins: bool, path := "", persistence := false):
	var profile := ExpansionProfileState.new(path, persistence)
	profile.load_profile()
	profile.commit_companion_rescue(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "spark_ray", callsign, false)
	if with_fins:
		_complete_fins_project(world, profile)
	if adaptation_id == "anchor_fins":
		profile.earn_companion_memory("held_the_flow", false)
		profile.select_companion_adaptation(adaptation_id, false)
	elif adaptation_id == "guardian_pulse":
		profile.earn_companion_memory("stood_ground", false)
		profile.select_companion_adaptation(adaptation_id, false)
	if persistence:
		profile.save_profile()
	return profile


func _complete_fins_project(world, profile) -> void:
	for project in world.get_material_projects():
		if str(project.get("unlocks_capability_id", "")) != "propulsion_fins":
			continue
		profile.complete_discovery(str(project.get("required_discovery_id", "")), false)
		var required: Dictionary = project.get("required_materials", {})
		var deposit := {}
		for material_id in required:
			deposit[str(material_id)] = int(required[material_id])
		var deposited: Dictionary = profile.deposit_materials(deposit, false)
		_expect(bool(deposited.get("changed", false)), "could not prepare propulsion-fins materials: %s" % deposited)
		var result: Dictionary = profile.complete_material_project(project, false)
		_expect(
			bool(result.get("changed", false)) or result.get("reason") == "already_completed",
			"could not prepare propulsion fins: %s" % result
		)
		return
	_expect(false, "production level omitted the propulsion-fins project")


func _confirm_command(control, action_id: String) -> Dictionary:
	var commands: Array = control.report().get("context_commands", [])
	for index in range(commands.size()):
		if str(commands[index].get("id", "")) != action_id:
			continue
		for _step in range(index):
			control.cycle_context_command()
		return control.confirm_context_command()
	control.end_command_mode()
	return {"changed": false, "reason": "missing_command"}


func _place_pair(player, ray, position: Vector2) -> void:
	ray.set_external_control_active(true)
	ray.global_position = position
	player.global_position = position
	ray.set_external_control_active(false)
	ray.advance(0.0)


func _gate_by_id(world, gate_id: String) -> Dictionary:
	if world == null:
		return {}
	for gate in world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _payoff_by_id(world, payoff_id: String) -> Dictionary:
	for payoff in world.get_creature_adaptation_payoffs():
		if str(payoff.get("id", "")) == payoff_id:
			return payoff
	return {}


func _record_status(note: String) -> void:
	_status_notes.append(note)


func _cancel_tool() -> Dictionary:
	return {"changed": true}


func _can_control() -> bool:
	return true


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish(world, player, runtime, hud, original_time_scale: float) -> void:
	Engine.time_scale = original_time_scale
	_cleanup()
	if runtime != null:
		runtime.clear_map()
		runtime.queue_free()
	if hud != null:
		hud.queue_free()
	if player != null:
		player.queue_free()
	if world != null:
		world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Anchor Fins smoke failed: %s" % failure)
		quit(1)
		return
	print(
		(
			"PASS: Anchor Fins individual=Kite persisted=true target=%s access=propulsion_fins "
			+ "independent=progress+cancel+success mounted=hold+success cooldown=true "
			+ "base_guardian_unavailable=true gate_bypass=false "
			+ "follow_up=deeper_signal_reef_response."
		) % TARGET_GATE_ID
	)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
