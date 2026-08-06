extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ActiveToolHud := preload("res://scripts/main/active_tool_hud.gd")
const CompanionGuardianPulseRuntime := preload("res://scripts/companion/companion_guardian_pulse_runtime.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const TerritorialHostileController := preload("res://scripts/main/territorial_hostile_controller.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const PROFILE_PATH := "user://oceangame2_guardian_pulse_smoke.json"
const TARGET_ID := "deep_cache_territorial_eel"
const PAYOFF_ID := "spark_ray_guardian_eel_01"
const ACTION_ID := "guardian_pulse_action"

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
	var payoff := _payoff_by_id(world, PAYOFF_ID)
	_expect(payoff.get("target_id") == TARGET_ID, "source-authored Guardian payoff target is missing")
	var hostiles := TerritorialHostileController.new()
	hostiles.on_map_loaded(world, false)
	var profile = _prepared_profile(world, "Kite", "guardian_pulse", true, PROFILE_PATH, true)
	var player = PLAYER_SCENE.instantiate()
	get_root().add_child(player)
	player.set_physics_process(false)
	var runtime := CompanionSortieRuntime.new()
	get_root().add_child(runtime)
	runtime.set_process(false)
	var hud := ActiveToolHud.new()
	get_root().add_child(hud)
	hud.refresh({"selected_tool_id": "shock_prod", "owned_tool_ids": ["shock_prod"]})
	runtime.bind_interface(hud, Callable(self, "_record_status"), Callable(self, "_cancel_tool"), Callable(self, "_can_control"))
	var spawn: Dictionary = runtime.bind_map(
		world,
		player,
		profile,
		Callable(self, "_has_no_upgrade"),
		true,
		false,
		hostiles
	)
	var ray = runtime.companion()
	var control = runtime.control_runtime()
	var guardian = runtime.guardian_pulse_runtime()
	_expect(bool(spawn.get("spawned", false)) and ray != null, "adapted Spark Ray did not spawn")
	if ray == null or control == null:
		_finish(world, player, runtime, hud, original_time_scale)
		return
	ray.set_physics_process(false)
	control.set_process(false)
	control.set_physics_process(false)
	_test_visible_variant(ray)
	_test_independent_hit(world, hostiles, control, guardian, player, ray)
	_test_miss_feedback(world, hostiles, guardian, player, ray)
	_test_retry_and_forced_dismount(world, hostiles, runtime, control, guardian, player, ray)
	_test_mounted_hit(world, hostiles, control, guardian, player, ray)
	_test_access_and_branch_boundaries(world, hostiles, player, ray)
	_test_profile_reload()
	_finish(world, player, runtime, hud, original_time_scale)


func _test_visible_variant(ray) -> void:
	var presentation: Dictionary = ray.report().get("presentation", {})
	_expect(presentation.get("adaptation_id") == "guardian_pulse", "selected adaptation did not reach presentation")
	_expect(str(presentation.get("variant_label", "")).find("Kite") != -1, "Guardian variant lost the callsign")
	_expect(bool(presentation.get("conductive_stripe", false)), "Guardian variant omitted its conductive stripe")
	_expect(not bool(ray.report().get("guardian_charging", true)), "Guardian Spark Ray spawned in transient charge state")


func _test_independent_hit(world, hostiles, control, guardian, player, ray) -> void:
	var home := _reset_warning_fixture(world, hostiles, player, ray, Vector2(-100.0, 0.0))
	var opened: Dictionary = control.begin_command_mode()
	var commands: Array = opened.get("context_commands", [])
	_expect(commands.map(func(command): return str(command.get("id", ""))).has(ACTION_ID), "independent BOND palette omitted Guardian Pulse")
	var engaged := _confirm_command(control, ACTION_ID)
	_expect(bool(engaged.get("changed", false)) and engaged.get("role") == "independent", "independent BOND command did not charge")
	guardian.advance(0.2, false)
	var charging: Dictionary = guardian.report()
	_expect(float(charging.get("progress", 0.0)) > 0.4, "Guardian charge did not report progress")
	_expect(bool(ray.report().get("guardian_charging", false)), "independent charge did not hold the Spark Ray")
	_expect(ray.report().get("presentation", {}).get("guardian_state") == "charging", "charge cue was not visible")
	guardian.advance(0.3, false)
	var hit: Dictionary = guardian.report()
	var hostile: Dictionary = hostiles.state_for(TARGET_ID)
	_expect(hit.get("last_result") == "hit" and hit.get("success_count") == 1, "independent pulse did not hit exactly once")
	_expect(hostile.get("phase") == "recovery", "Guardian Pulse did not interrupt the warning")
	_expect(int(hostile.get("health", -1)) == 3 and hit.get("last_health_before") == 3 and hit.get("last_health_after") == 3, "Guardian Pulse changed eel health")
	_expect(float(hit.get("last_recoil_distance", 0.0)) > 0.0, "Guardian Pulse did not separate the eel")
	_expect(ray.report().get("presentation", {}).get("guardian_state") == "hit", "hit discharge cue was missing")
	_expect(_status_notes.any(func(note): return str(note).find("health 3/3") != -1), "hit feedback did not disclose non-damaging health")
	_expect(not _contains_reward_key(hit), "Guardian Pulse produced a reward")
	var cooldown: Dictionary = guardian.dispatch("independent", ACTION_ID)
	_expect(cooldown.get("reason") == "pulse_cooling_down", "Guardian Pulse ignored cooldown")
	_expect(ray.report().get("presentation", {}).get("guardian_state") == "cooldown", "cooldown cue was missing")
	_expect(home != Vector2.ZERO, "warning fixture lost the authored hostile home")


func _test_miss_feedback(world, hostiles, guardian, player, ray) -> void:
	guardian.reset("miss_fixture")
	hostiles.reset_for_failure(world)
	var home: Vector2 = hostiles.state_for(TARGET_ID).get("home_center", Vector2.ZERO)
	_place_pair(player, ray, home + Vector2(-190.0, 0.0))
	_expect(bool(guardian.dispatch("independent", ACTION_ID).get("changed", false)), "out-of-range pulse did not discharge")
	guardian.advance(0.5, false)
	_expect(guardian.report().get("last_result") == "miss:out_of_range", "out-of-range pulse did not report a miss")
	_expect(int(hostiles.state_for(TARGET_ID).get("health", -1)) == 3, "out-of-range miss changed health")

	guardian.reset("direction_fixture")
	hostiles.reset_for_failure(world)
	_place_pair(player, ray, home + Vector2(100.0, 0.0))
	hostiles.update(world, player.global_position, 0.0)
	_expect(bool(guardian.dispatch("independent", ACTION_ID).get("changed", false)), "wrong-direction pulse did not discharge")
	guardian.advance(0.5, false)
	_expect(guardian.report().get("last_result") == "miss:wrong_direction", "wrong-direction pulse did not report aim failure")
	_expect(ray.report().get("presentation", {}).get("guardian_state") == "miss", "miss cue was not visible")

	guardian.reset("timing_fixture")
	hostiles.reset_for_failure(world)
	_place_pair(player, ray, home + Vector2(-100.0, 0.0))
	_expect(bool(guardian.dispatch("independent", ACTION_ID).get("changed", false)), "non-threat pulse did not begin")
	guardian.advance(0.5, false)
	_expect(guardian.report().get("last_result") == "miss:not_threatening", "non-threat pulse did not require warning/lunge timing")


func _test_retry_and_forced_dismount(world, hostiles, runtime, control, guardian, player, ray) -> void:
	guardian.reset("retry_fixture")
	_reset_warning_fixture(world, hostiles, player, ray, Vector2(-100.0, 0.0))
	_expect(bool(guardian.dispatch("independent", ACTION_ID).get("changed", false)), "retry fixture could not charge")
	runtime.reset_control("retry")
	_expect(not bool(guardian.report().get("active", true)) and is_zero_approx(float(guardian.report().get("cooldown_seconds", -1.0))), "Retry retained charge or cooldown")
	_expect(not bool(ray.report().get("guardian_charging", true)), "Retry left the Spark Ray charging")

	guardian.reset("forced_dismount_fixture")
	_reset_warning_fixture(world, hostiles, player, ray, Vector2(-100.0, 0.0))
	_expect(bool(control.request_mount().get("changed", false)), "forced-dismount fixture could not mount")
	if control.report().get("selected_action_id") != ACTION_ID:
		control.cycle_mounted_action()
	_expect(bool(control.activate_mounted_action().get("changed", false)), "forced-dismount fixture could not charge")
	var forced: Dictionary = runtime.force_dismount_for_hit(hostiles.state_for(TARGET_ID).get("position", player.global_position))
	_expect(bool(forced.get("changed", false)) and not control.is_mounted(), "hostile hit did not force dismount")
	_expect(not bool(guardian.report().get("active", true)) and not bool(ray.report().get("guardian_charging", true)), "forced dismount retained Guardian charge")


func _test_mounted_hit(world, hostiles, control, guardian, player, ray) -> void:
	guardian.reset("mounted_fixture")
	_reset_warning_fixture(world, hostiles, player, ray, Vector2(-100.0, 0.0))
	_expect(bool(control.request_mount().get("changed", false)), "mounted Guardian fixture could not mount")
	if control.report().get("selected_action_id") != ACTION_ID:
		control.cycle_mounted_action()
	_expect(control.report().get("selected_action_id") == ACTION_ID, "mounted hotbar omitted Guardian Pulse")
	var engaged: Dictionary = control.activate_mounted_action()
	_expect(bool(engaged.get("changed", false)) and engaged.get("role") == "mounted", "mounted Space/USE did not charge")
	var before: Vector2 = ray.global_position
	var movement: Dictionary = control.advance_mounted_movement(0.1, Vector2.RIGHT)
	_expect(movement.get("reason") == "guardian_charge" and ray.global_position.distance_to(before) <= 0.01, "mounted charge did not produce a stable charge state")
	guardian.advance(0.5, true)
	var hit: Dictionary = guardian.report()
	_expect(hit.get("last_result") == "hit" and hostiles.state_for(TARGET_ID).get("phase") == "recovery", "mounted pulse did not interrupt")
	_expect(int(hostiles.state_for(TARGET_ID).get("health", -1)) == 3, "mounted pulse damaged the eel")
	control.request_dismount()
	_expect(not control.is_mounted(), "mounted Guardian payoff prevented dismount")


func _test_access_and_branch_boundaries(world, hostiles, player, ray) -> void:
	var no_weapon = _prepared_profile(world, "Drift", "guardian_pulse", false)
	var denied := CompanionGuardianPulseRuntime.new()
	denied.bind_status_sink(Callable(self, "_record_status"))
	denied.bind_map(world, player, no_weapon, ray, hostiles, Callable(self, "_has_no_upgrade"), Callable(no_weapon, "has_capability"))
	ray.apply_identity(no_weapon.companion_report().get("individual", {}))
	var home: Vector2 = hostiles.state_for(TARGET_ID).get("home_center", Vector2.ZERO)
	_place_pair(player, ray, home + Vector2(-100.0, 0.0))
	var action: Dictionary = denied.actions("independent_palette")[0]
	_expect(not bool(action.get("enabled", true)) and action.get("reason") == "need_shock_prod", "Guardian Pulse did not retain the Shock Prod requirement")
	_expect(denied.dispatch("independent", ACTION_ID).get("reason") == "need_shock_prod", "Guardian Pulse replaced the Shock Prod gate")

	for branch in ["", "anchor_fins"]:
		var profile = _prepared_profile(world, "Other", branch, true)
		var branch_runtime := CompanionGuardianPulseRuntime.new()
		branch_runtime.bind_map(world, player, profile, ray, hostiles, Callable(self, "_has_no_upgrade"), Callable(profile, "has_capability"))
		ray.apply_identity(profile.companion_report().get("individual", {}))
		_expect(branch_runtime.actions("mounted_hotbar").is_empty(), "%s Spark Ray received Guardian Pulse" % ("base" if branch.is_empty() else "Anchor"))

	for _hit in range(3):
		hostiles.apply_weapon_hit(world, TARGET_ID, 1)
	var resolved := CompanionGuardianPulseRuntime.new()
	var guardian_profile = _prepared_profile(world, "Kite", "guardian_pulse", true)
	resolved.bind_map(world, player, guardian_profile, ray, hostiles, Callable(self, "_has_no_upgrade"), Callable(guardian_profile, "has_capability"))
	ray.apply_identity(guardian_profile.companion_report().get("individual", {}))
	_expect(resolved.dispatch("mounted", ACTION_ID).get("reason") == "target_defeated", "defeated target accepted another pulse")


func _test_profile_reload() -> void:
	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var load: Dictionary = reloaded.load_profile()
	var companion: Dictionary = reloaded.companion_report()
	_expect(load.get("status") == "loaded", "Guardian profile did not reload")
	_expect(companion.get("individual", {}).get("selected_adaptation_id") == "guardian_pulse", "profile reload lost Guardian Pulse")
	_expect(not companion.has("mounted") and not companion.has("cooldown_seconds"), "profile persisted transient combat state")


func _prepared_profile(world, callsign: String, adaptation_id: String, with_weapon: bool, path := "", persistence := false):
	var profile := ExpansionProfileState.new(path, persistence)
	profile.load_profile()
	profile.commit_companion_rescue(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "spark_ray", callsign, false)
	if with_weapon:
		_complete_capability(world, profile, ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID)
	if adaptation_id == "guardian_pulse":
		profile.earn_companion_memory("stood_ground", false)
		profile.select_companion_adaptation(adaptation_id, false)
	elif adaptation_id == "anchor_fins":
		profile.earn_companion_memory("held_the_flow", false)
		profile.select_companion_adaptation(adaptation_id, false)
	if persistence:
		profile.save_profile()
	return profile


func _complete_capability(world, profile, capability_id: String) -> void:
	var project := _project_unlocking(world.get_material_projects(), capability_id)
	if project.is_empty():
		_expect(false, "missing project for %s" % capability_id)
		return
	var prerequisite_id := str(project.get("required_project_id", ""))
	if not prerequisite_id.is_empty() and not profile.has_completed_project(prerequisite_id):
		var prerequisite := _project_by_id(world.get_material_projects(), prerequisite_id)
		_complete_capability(world, profile, str(prerequisite.get("unlocks_capability_id", "")))
	var discovery_id := str(project.get("required_discovery_id", ""))
	if not discovery_id.is_empty():
		profile.complete_discovery(discovery_id, false)
	var missing := {}
	for material_id in project.get("required_materials", {}):
		missing[str(material_id)] = int(project.get("required_materials", {})[material_id])
	profile.deposit_materials(missing, false)
	var result: Dictionary = profile.complete_material_project(project, false)
	_expect(bool(result.get("changed", false)) or result.get("reason") == "already_completed", "could not prepare %s: %s" % [capability_id, result])


func _reset_warning_fixture(world, hostiles, player, ray, offset: Vector2) -> Vector2:
	hostiles.reset_for_failure(world)
	var home: Vector2 = hostiles.state_for(TARGET_ID).get("home_center", Vector2.ZERO)
	_place_pair(player, ray, home + offset)
	hostiles.update(world, player.global_position, 0.0)
	_expect(hostiles.state_for(TARGET_ID).get("phase") == "warning", "fixture did not enter eel warning")
	return home


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
	ray.recover_to_player()
	ray.set_external_control_active(true)
	ray.global_position = position
	player.global_position = position
	ray.set_external_control_active(false)
	ray.advance(0.0)


func _payoff_by_id(world, payoff_id: String) -> Dictionary:
	for payoff in world.get_creature_adaptation_payoffs():
		if str(payoff.get("id", "")) == payoff_id:
			return payoff
	return {}


func _project_unlocking(projects: Array, capability_id: String) -> Dictionary:
	for project in projects:
		if str(project.get("unlocks_capability_id", "")) == capability_id:
			return project
	return {}


func _project_by_id(projects: Array, project_id: String) -> Dictionary:
	for project in projects:
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _contains_reward_key(value: Dictionary) -> bool:
	for key in value:
		var normalized := str(key).to_lower()
		if "reward" in normalized or "score" in normalized or "material" in normalized or "salvage" in normalized:
			return true
	return false


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
			push_error("Guardian Pulse smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Guardian Pulse individual=Kite persisted=true target=deep_cache_territorial_eel independent=aim+charge+hit mounted=aim+charge+hit damage=0 health=3/3 recoil=true miss=range+direction+timing cooldown=true shock_prod_required=true base_anchor_unavailable=true rewards=none reset=true.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
