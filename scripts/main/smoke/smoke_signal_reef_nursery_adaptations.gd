extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ActiveToolHud := preload("res://scripts/main/active_tool_hud.gd")
const CompanionAnchorFinsRuntime := preload("res://scripts/companion/companion_anchor_fins_runtime.gd")
const CompanionGuardianPulseRuntime := preload("res://scripts/companion/companion_guardian_pulse_runtime.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const TerritorialHostileController := preload("res://scripts/main/territorial_hostile_controller.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const JOURNEY_ID := "signal_reef_nursery_journey_01"
const KITE_ID := "spark_ray_juvenile_01"
const ANCHOR_CONTEXT_ID := "spark_ray_anchor_nursery_context_01"
const GUARDIAN_CONTEXT_ID := "spark_ray_guardian_nursery_context_01"
const EAST_GATE_ID := "lower_right_east_current_gate"

var _failures: Array[String] = []
var _status_notes: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_time_scale := Engine.time_scale
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	await process_frame
	var presentation = world.get_node_or_null("Markers/SignalReefNursery")
	if presentation != null:
		presentation.set_process(false)
	_expect(world.get_signal_reef_nursery_report().get("journey_id") == JOURNEY_ID, "nursery source was not configured")
	_test_anchor_branch(world)
	_test_guardian_branch(world)
	_test_access_denials(world)
	_test_companion_and_adaptation_denials(world)
	Engine.time_scale = original_time_scale
	world.queue_free()
	await process_frame
	_finish()


func _test_anchor_branch(world) -> void:
	var profile = _prepared_profile(world, "spark_ray", "anchor_fins", true, true)
	var fixture := _fixture(world, profile)
	var player = fixture.player
	var ray = fixture.ray
	var sortie = fixture.sortie
	var control = fixture.control
	var anchor = sortie.adaptation_runtime()
	var coordinator = sortie.signal_reef_nursery_runtime()
	var gate := _record_by_id(world.get_current_gates(), EAST_GATE_ID)
	var profile_before: Dictionary = profile.report().duplicate(true)
	_place_pair(player, ray, gate.get("center", Vector2.ZERO))
	coordinator.advance()
	world.advance_signal_reef_nursery(1.0)
	_expect(_nursery_state(world) == "unresolved", "Anchor branch auto-fired without a BOND command")

	var opened: Dictionary = control.begin_command_mode()
	_expect(paused and opened.get("timing_policy") == "tactical_pause", "Anchor BOND did not pause the complete simulation")
	var engaged := _activate_numbered(control, CompanionAnchorFinsRuntime.ACTION_ID)
	_expect(bool(engaged.get("changed", false)) and engaged.get("role") == "independent" and not paused, "numbered/mobile-equivalent Anchor command did not dispatch independently")
	_expect(_nursery_state(world) == "unresolved", "Anchor branch completed instantly")
	anchor.advance(0.7, false)
	coordinator.advance()
	_expect(_nursery_state(world) == "unresolved", "partial Anchor brace completed the nursery response")
	anchor.advance(0.9, false)
	coordinator.advance()
	var pending: Dictionary = coordinator.report()
	_expect(_nursery_state(world) == "anchor_active" and pending.get("pending_adaptation_id") == "anchor_fins", "successful Anchor brace did not start its authored lee")
	_expect(anchor.report().get("payoff_id") == ANCHOR_CONTEXT_ID, "Anchor runtime reported the legacy context instead of the nursery context")
	world.advance_signal_reef_nursery(2.5)
	_expect(_nursery_state(world) == "sheltered_pending_return", "Anchor lee did not guide the school to shelter")
	_expect(profile.report() == profile_before and not bool(profile.signal_reef_journey_report().get("committed", false)), "field Anchor success wrote profile state")
	_expect(_status_notes.any(func(note): return str(note).contains("stable current lee")), "Anchor response omitted clear local feedback")

	sortie.reset_control("retry")
	_expect(_nursery_state(world) == "unresolved" and not bool(coordinator.report().get("pending", true)), "Retry retained Anchor nursery progress")
	_place_pair(player, ray, gate.get("center", Vector2.ZERO))
	_expect(bool(control.request_mount().get("changed", false)), "Anchor regional fixture could not mount")
	_expect(_select_mounted_action(control, CompanionAnchorFinsRuntime.ACTION_ID), "mounted hotbar omitted regional Anchor brace")
	_expect(bool(control.activate_mounted_action().get("changed", false)), "mounted Space/USE did not activate regional Anchor brace")
	anchor.advance(1.6, true)
	coordinator.advance()
	_expect(_nursery_state(world) == "anchor_active" and anchor.report().get("role") == "mounted", "mounted Anchor branch did not produce the same pending history")

	sortie.reset_control("retry")
	_place_pair(player, ray, gate.get("center", Vector2.ZERO))
	ray.set_external_control_active(true)
	ray.global_position += Vector2(400.0, 0.0)
	ray.set_external_control_active(false)
	var separated := _action_by_id(anchor.actions("independent_palette"), CompanionAnchorFinsRuntime.ACTION_ID)
	_expect(separated.get("reason") == "companion_not_in_current" and _nursery_state(world) == "unresolved", "separated Kite completed or hid the Anchor non-completion")
	_destroy_fixture(fixture)


func _test_guardian_branch(world) -> void:
	world.reset_signal_reef_nursery_uncommitted()
	var profile = _prepared_profile(world, "spark_ray", "guardian_pulse", true, true)
	var fixture := _fixture(world, profile)
	var player = fixture.player
	var ray = fixture.ray
	var sortie = fixture.sortie
	var control = fixture.control
	var guardian = sortie.guardian_pulse_runtime()
	var coordinator = sortie.signal_reef_nursery_runtime()
	var pressure_center: Vector2 = world.get_signal_reef_nursery_report().get("pressure_center", Vector2.ZERO)
	var profile_before: Dictionary = profile.report().duplicate(true)
	_place_guardian_pair(player, ray, pressure_center)
	coordinator.advance()
	_expect(_nursery_state(world) == "unresolved", "Guardian branch auto-fired without a BOND command")

	var opened: Dictionary = control.begin_command_mode()
	_expect(paused and (opened.get("context_commands", []) as Array).size() <= 3, "Guardian BOND did not use the bounded tactical palette")
	var engaged := _activate_numbered(control, CompanionGuardianPulseRuntime.ACTION_ID)
	_expect(bool(engaged.get("changed", false)) and engaged.get("role") == "independent" and not paused, "numbered/mobile-equivalent Guardian command did not dispatch independently")
	guardian.advance(0.2, false)
	coordinator.advance()
	_expect(_nursery_state(world) == "unresolved", "partial Guardian charge completed the nursery response")
	guardian.advance(0.3, false)
	coordinator.advance()
	var pending: Dictionary = coordinator.report()
	_expect(_nursery_state(world) == "guardian_active" and pending.get("pending_adaptation_id") == "guardian_pulse", "Guardian hit did not start the authored pressure response")
	_expect(guardian.report().get("payoff_id") == GUARDIAN_CONTEXT_ID and guardian.report().get("last_damage") == 0, "Guardian nursery response changed target ownership or dealt damage")
	var before_displacement: Vector2 = world.get_signal_reef_nursery_report().get("pressure_center", Vector2.ZERO)
	world.advance_signal_reef_nursery(0.8)
	var after_displacement: Vector2 = world.get_signal_reef_nursery_report().get("pressure_center", Vector2.ZERO)
	_expect(after_displacement.x < before_displacement.x - 20.0, "Guardian response did not visibly displace the jellyfish pressure")
	world.advance_signal_reef_nursery(2.0)
	var nursery: Dictionary = world.get_signal_reef_nursery_report()
	_expect(nursery.get("state") == "sheltered_pending_return" and not bool(nursery.get("damaging", true)) and (nursery.get("reward_ids", []) as Array).is_empty(), "Guardian branch damaged/rewarded wildlife or failed to shelter the school")
	_expect(profile.report() == profile_before and not bool(profile.signal_reef_journey_report().get("committed", false)), "field Guardian success wrote progression or journey history")

	sortie.reset_control("retry")
	pressure_center = world.get_signal_reef_nursery_report().get("pressure_center", Vector2.ZERO)
	_place_guardian_pair(player, ray, pressure_center)
	_expect(bool(control.request_mount().get("changed", false)), "Guardian regional fixture could not mount")
	_expect(_select_mounted_action(control, CompanionGuardianPulseRuntime.ACTION_ID), "mounted hotbar omitted regional Guardian Pulse")
	_expect(bool(control.activate_mounted_action().get("changed", false)), "mounted Space/USE did not activate regional Guardian Pulse")
	guardian.advance(0.5, true)
	coordinator.advance()
	_expect(_nursery_state(world) == "guardian_active" and guardian.report().get("role") == "mounted", "mounted Guardian branch did not produce the same pending history")

	sortie.reset_control("retry")
	pressure_center = world.get_signal_reef_nursery_report().get("pressure_center", Vector2.ZERO)
	_place_guardian_pair(player, ray, pressure_center)
	_expect(bool(guardian.dispatch("independent", CompanionGuardianPulseRuntime.ACTION_ID).get("changed", false)), "Guardian separation fixture did not start")
	ray.set_external_control_active(true)
	ray.global_position += Vector2(400.0, 0.0)
	ray.set_external_control_active(false)
	guardian.advance(0.1, false)
	coordinator.advance()
	_expect(guardian.report().get("last_result") == "cancelled:pair_separated" and _nursery_state(world) == "unresolved", "companion separation did not cancel Guardian nursery progress")
	_destroy_fixture(fixture)


func _test_access_denials(world) -> void:
	world.reset_signal_reef_nursery_uncommitted()
	var gate := _record_by_id(world.get_current_gates(), EAST_GATE_ID)
	var anchor_profile = _prepared_profile(world, "spark_ray", "anchor_fins", true, false)
	anchor_profile.complete_discovery("lower_right_signal_reef_discovery", false)
	var anchor_fixture := _fixture(world, anchor_profile)
	_place_pair(anchor_fixture.player, anchor_fixture.ray, gate.get("center", Vector2.ZERO))
	var anchor_action := _action_by_id(anchor_fixture.sortie.adaptation_runtime().actions("independent_palette"), CompanionAnchorFinsRuntime.ACTION_ID)
	_expect(not bool(anchor_action.get("enabled", true)) and anchor_action.get("reason") == "need_dive_light", "Anchor context did not retain the Dive Light gate")
	_destroy_fixture(anchor_fixture)

	var guardian_profile = _prepared_profile(world, "spark_ray", "guardian_pulse", false, true)
	var guardian_fixture := _fixture(world, guardian_profile)
	var pressure: Vector2 = world.get_signal_reef_nursery_report().get("pressure_center", Vector2.ZERO)
	_place_guardian_pair(guardian_fixture.player, guardian_fixture.ray, pressure)
	var guardian_action := _action_by_id(guardian_fixture.sortie.guardian_pulse_runtime().actions("independent_palette"), CompanionGuardianPulseRuntime.ACTION_ID)
	_expect(not bool(guardian_action.get("enabled", true)) and guardian_action.get("reason") == "need_propulsion_fins", "Guardian context did not retain the Propulsion Fins gate")
	var blocked := CurrentGateController.new().gate_blocks_position(world, gate.get("center", Vector2.ZERO), Callable(self, "_has_no_upgrade"), Callable(guardian_profile, "has_capability"))
	_expect(blocked.get("id") == EAST_GATE_ID, "riding or adaptation state bypassed the missing Fins gate")
	_destroy_fixture(guardian_fixture)


func _test_companion_and_adaptation_denials(world) -> void:
	world.reset_signal_reef_nursery_uncommitted()
	var pressure: Vector2 = world.get_signal_reef_nursery_report().get("pressure_center", Vector2.ZERO)
	for values in [
		["spark_ray", "", "unadapted Kite"],
		["spark_ray", "anchor_fins", "wrong-adaptation Kite"],
		["veil_cuttle", "", "Mica"],
		["silt_hound", "", "Marl"],
	]:
		var profile = _prepared_profile(world, values[0], values[1], true, true)
		var fixture := _fixture(world, profile)
		fixture.player.global_position = pressure
		var nursery_report: Dictionary = fixture.sortie.report().get("signal_reef_nursery", {})
		var adaptation_actions: Array = []
		if values[0] == "spark_ray":
			adaptation_actions = fixture.sortie.guardian_pulse_runtime().actions("mounted_hotbar")
		_expect(adaptation_actions.is_empty() and _nursery_state(world) == "unresolved", "%s received or completed the Guardian nursery branch" % values[2])
		_expect(not str(nursery_report.get("noncompletion_reason", "")).is_empty(), "%s omitted its explicit non-completion reason" % values[2])
		var gate := _record_by_id(world.get_current_gates(), EAST_GATE_ID)
		var blocked := CurrentGateController.new().gate_blocks_position(world, gate.get("center", Vector2.ZERO), Callable(self, "_has_no_upgrade"), Callable(profile, "has_capability"))
		_expect(blocked.is_empty(), "%s lost normal equipped region access" % values[2])
		_destroy_fixture(fixture)


func _fixture(world, profile) -> Dictionary:
	var player = PLAYER_SCENE.instantiate()
	get_root().add_child(player)
	player.set_physics_process(false)
	var sortie := CompanionSortieRuntime.new()
	get_root().add_child(sortie)
	sortie.set_process(false)
	var hud := ActiveToolHud.new()
	get_root().add_child(hud)
	hud.refresh({"selected_tool_id": "survey_scanner_1", "owned_tool_ids": ["survey_scanner_1"]})
	sortie.bind_interface(hud, Callable(self, "_record_status"), Callable(self, "_cancel_tool"), Callable(self, "_can_control"))
	var hostiles := TerritorialHostileController.new()
	hostiles.on_map_loaded(world, false)
	var spawn: Dictionary = sortie.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), true, false, hostiles)
	var ray = sortie.companion()
	_expect(bool(spawn.get("spawned", false)) and ray != null, "fixture companion did not spawn")
	if ray != null:
		ray.set_physics_process(false)
	var control = sortie.control_runtime()
	if control != null:
		control.set_process(false)
		control.set_physics_process(false)
	sortie.signal_reef_nursery_runtime().set_process(false)
	return {"player": player, "sortie": sortie, "hud": hud, "ray": ray, "control": control, "hostiles": hostiles}


func _prepared_profile(world, species_id: String, adaptation_id: String, with_fins: bool, with_light: bool):
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var individual_id := KITE_ID
	var callsign := "Kite"
	if species_id == "veil_cuttle":
		individual_id = CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID
		callsign = "Mica"
	elif species_id == "silt_hound":
		individual_id = CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID
		callsign = "Marl"
	profile.commit_companion_rescue(individual_id, species_id, callsign, false)
	if with_fins:
		_complete_capability(world, profile, "propulsion_fins")
	if with_light:
		_complete_capability(world, profile, "dive_light_1")
	if adaptation_id == "anchor_fins":
		profile.earn_companion_memory("held_the_flow", false)
		profile.select_companion_adaptation(adaptation_id, false)
	elif adaptation_id == "guardian_pulse":
		profile.earn_companion_memory("stood_ground", false)
		profile.select_companion_adaptation(adaptation_id, false)
	return profile


func _complete_capability(world, profile, capability_id: String) -> void:
	var project := _project_unlocking(world.get_material_projects(), capability_id)
	var prerequisite_id := str(project.get("required_project_id", ""))
	if not prerequisite_id.is_empty() and not profile.has_completed_project(prerequisite_id):
		var prerequisite := _record_by_id(world.get_material_projects(), prerequisite_id)
		_complete_capability(world, profile, str(prerequisite.get("unlocks_capability_id", "")))
	var discovery_id := str(project.get("required_discovery_id", ""))
	if not discovery_id.is_empty():
		profile.complete_discovery(discovery_id, false)
	var deposit := {}
	for material_id in project.get("required_materials", {}):
		deposit[str(material_id)] = int(project.get("required_materials", {})[material_id])
	profile.deposit_materials(deposit, false)
	var result: Dictionary = profile.complete_material_project(project, false)
	_expect(bool(result.get("changed", false)) or result.get("reason") == "already_completed", "could not prepare %s" % capability_id)


func _project_unlocking(projects: Array, capability_id: String) -> Dictionary:
	for project in projects:
		if str(project.get("unlocks_capability_id", "")) == capability_id:
			return project
	return {}


func _activate_numbered(control, action_id: String) -> Dictionary:
	var commands: Array = control.report().get("context_commands", [])
	for index in range(commands.size()):
		if str(commands[index].get("id", "")) == action_id:
			return control.activate_context_command(index)
	control.end_command_mode()
	return {"changed": false, "reason": "missing_command"}


func _select_mounted_action(control, action_id: String) -> bool:
	for _step in range(3):
		if control.report().get("selected_action_id") == action_id:
			return true
		control.cycle_mounted_action()
	return control.report().get("selected_action_id") == action_id


func _place_pair(player, ray, position: Vector2) -> void:
	ray.recover_to_player()
	ray.set_external_control_active(true)
	ray.global_position = position
	player.global_position = position
	ray.set_external_control_active(false)
	ray.advance(0.0)


func _place_guardian_pair(player, ray, pressure_center: Vector2) -> void:
	_place_pair(player, ray, pressure_center + Vector2(-100.0, 0.0))
	player.swim_in_direction(Vector2.RIGHT, 0.0)


func _action_by_id(actions: Array, action_id: String) -> Dictionary:
	for action in actions:
		if str(action.get("id", "")) == action_id:
			return action
	return {}


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str(record.get("id", "")) == record_id:
			return record
	return {}


func _nursery_state(world) -> String:
	return str(world.get_signal_reef_nursery_report().get("state", ""))


func _destroy_fixture(fixture: Dictionary) -> void:
	var sortie = fixture.get("sortie")
	if sortie != null:
		sortie.clear_map()
		sortie.queue_free()
	for key in ["hud", "player"]:
		var node = fixture.get(key)
		if node != null:
			node.queue_free()


func _record_status(note: String) -> void:
	_status_notes.append(note)


func _cancel_tool() -> Dictionary:
	return {"changed": true}


func _can_control() -> bool:
	return true


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _finish() -> void:
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Signal Reef nursery adaptations smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Signal Reef nursery adaptations journey=%s individual=%s anchor={context:%s independent:true mounted:true lee:true} guardian={context:%s independent:true mounted:true displacement:true damage:0} bond={pause:true numbered:true mobile_equivalent:true} access={fins:true light:true no_bypass:true} wrong_companions={Mica:true Marl:true} pending_profile_write=false rewards=none Retry=unresolved." % [JOURNEY_ID, KITE_ID, ANCHOR_CONTEXT_ID, GUARDIAN_CONTEXT_ID])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
