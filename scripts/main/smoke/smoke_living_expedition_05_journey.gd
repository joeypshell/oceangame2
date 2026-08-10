extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const CompanionRescueRuntime := preload("res://scripts/companion/companion_rescue_runtime.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const ProfileMatrix := preload("res://scripts/main/smoke/living_expedition_05_profile_matrix.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")

const CHECKPOINT_ID := "living_expedition_05_start"
const MAP_PATH := "res://maps/production_level_01.greybox.json"
const RESCUE_ID := "silt_hound_rescue_01"
const MARL_ID := "silt_hound_juvenile_01"
const TARGET_ID := "silt_hound_buried_titanium_01"
const MATERIAL_ID := "titanium_scrap"
const STEP_SECONDS := 1.0 / 30.0
const COLLECTION_RADIUS_PX := 48.0

var _failures: Array[String] = []
var _notes: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var migration: Dictionary = ProfileMatrix.run()
	_expect(bool(migration.get("ready", false)), "profile migration matrix failed: %s" % [migration.get("failures", [])])
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player = PLAYER_SCENE.instantiate()
	get_root().add_child(player)
	player.set_physics_process(false)
	await physics_frame

	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var checkpoint: Dictionary = ReviewCheckpointFixture.apply(CHECKPOINT_ID, profile)
	_expect(bool(checkpoint.get("ready", false)) and str(checkpoint.get("checkpoint_id", "")) == CHECKPOINT_ID, "fresh journey checkpoint failed: %s" % checkpoint)
	_expect((profile.companion_report().get("individuals", []) as Array).size() == 2 and not _has_individual(profile, MARL_ID), "checkpoint silently committed Marl")
	var day := ExpeditionDayState.new(300.0)
	day.begin_day(int(checkpoint.get("day_number", 4)))
	day.on_map_loaded(str(world.map_id))
	var oxygen := SortieState.new(float(checkpoint.get("review_oxygen_seconds", 180.0)))
	oxygen.begin_map_leg(str(world.map_id), "surface_boat_entry", oxygen.oxygen_seconds)
	var materials := MaterialRuntimeController.new(profile)
	materials.on_map_loaded(world, day)
	var selected_ids: Array = world.get_material_candidate_report().get("active_ids", [])
	_expect(selected_ids.has(TARGET_ID), "authored excavation target was not active")
	_expect(_normal_titanium_quantity(world, selected_ids) >= 2 and _optional_pool_is_valid(world), "optional mound displaced required titanium supply")

	var rescue := CompanionRescueRuntime.new()
	get_root().add_child(rescue)
	rescue.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), Callable(profile, "has_capability"), COLLECTION_RADIUS_PX)
	player.global_position = _rescue_center(world)
	_expect(oxygen.update_offload_presence(false, 180.0), "rescue sortie did not begin")
	day.record_sortie_started()
	var oxygen_start := oxygen.oxygen_seconds
	var daylight_start := day.daylight_remaining_seconds
	_expect(_release_marl(rescue), "first Marl release did not reach pending")
	_pressure(oxygen, day, CompanionRescueRuntime.RELEASE_SECONDS)
	var retry: Dictionary = rescue.reset_for_failure("retry")
	_expect(retry.get("restored_rescue_id") == RESCUE_ID and not _has_individual(profile, MARL_ID), "Retry did not restore the uncommitted rescue")
	_expect(str(_rescue_by_id(world).get("state", "")) == "available", "Retry did not restore the physical rescue source")
	_expect(_release_marl(rescue), "second Marl release did not reach pending")
	_pressure(oxygen, day, CompanionRescueRuntime.RELEASE_SECONDS)
	player.global_position = world.get_extraction_center()
	var committed: Dictionary = rescue.commit_at_boat()
	_expect(bool(committed.get("changed", false)) and str(committed.get("commit_entry_id", "")) == "surface_boat_entry", "canonical boat did not commit Marl")
	_expect(str(_rescue_by_id(world).get("state", "")) == "committed" and _has_individual(profile, MARL_ID), "rescue source/profile did not agree on commitment")
	_expect((profile.companion_report().get("individuals", []) as Array).size() == 3 and str(profile.companion_report().get("active_individual_id", "")) == CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID, "Marl commitment changed Mica's active selection")
	_expect(str(rescue.commit_at_boat().get("reason", "")) == "no_pending_rescue", "Marl commitment duplicated")

	var sortie := CompanionSortieRuntime.new()
	get_root().add_child(sortie)
	await process_frame
	sortie.bind_interface(null, Callable(self, "_record_note"), Callable(), Callable(self, "_control_allowed"))
	sortie.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), false)
	var habitat: Dictionary = sortie.report().get("habitat", {})
	_expect(int(habitat.get("individual_count", 0)) == 3 and (habitat.get("panel", {}).get("rows", []) as Array).size() == 3, "canonical habitat did not expose three rows")
	_expect(sortie.handle_input(_action(&"companion_command")), "BOND did not open habitat selection")
	_expect(sortie.handle_input(_action(&"active_tool_cycle_next")), "TOOL did not reach Marl's habitat row")
	_expect(sortie.handle_input(_action(&"active_tool_use")), "USE did not confirm Marl")
	_expect(str(profile.companion_report().get("active_individual_id", "")) == MARL_ID, "habitat selection did not make Marl next-sortie active")

	var target := _target_center(world)
	var positions := _action_positions(world, target)
	player.global_position = positions.get("player", target)
	day.record_sortie_started()
	var launch: Dictionary = sortie.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), true)
	var companion = sortie.companion()
	var marl_launched := bool(launch.get("spawned", false)) and str(launch.get("active_species_id", "")) == "silt_hound" and companion != null and str(companion.report().get("species_id", "")) == "silt_hound"
	_expect(marl_launched, "selected Marl did not own the launched sortie: %s" % launch)
	if not marl_launched:
		_finish(world, player, rescue, sortie, migration, profile, oxygen, day, {})
		return
	companion.set_physics_process(false)
	companion.global_position = positions.get("companion", target)
	var control = sortie.control_runtime()
	_expect(not bool(control.report().get("mounted", true)) and _command_ids(control).has("excavate") and not _command_ids(control).has("mount"), "Marl inherited riding or omitted Excavate")

	if not _start_excavate(control):
		_expect(false, "first Excavate did not start: %s" % control.report())
		_finish(world, player, rescue, sortie, migration, profile, oxygen, day, {})
		return
	_advance_until(companion, control.excavate_runtime(), oxygen, day, "digging")
	sortie.reset_control("oxygen_failure")
	_expect(_deposit_is_closed(world) and not bool(control.report().get("excavate", {}).get("busy", true)), "oxygen failure did not close the interrupted mound")

	_set_action_positions(player, companion, positions)
	if not _start_excavate(control):
		_expect(false, "second Excavate did not start: %s" % control.report())
		_finish(world, player, rescue, sortie, migration, profile, oxygen, day, {})
		return
	var first_reveal: Dictionary = _advance_until(companion, control.excavate_runtime(), oxygen, day, "revealed")
	_expect((first_reveal.get("visited_states", []) as Array) == ["approaching", "anticipating", "digging", "impact", "revealed"], "Excavate omitted a physical phase: %s" % first_reveal)
	var blocked: Dictionary = materials.update_collection(world, target, COLLECTION_RADIUS_PX, day, 2, 2)
	_expect(bool(blocked.get("blocked", false)) and bool(world.get_material_candidate_state(TARGET_ID).get("available", false)), "cargo full deleted the revealed material")
	var first_pickup: Dictionary = materials.update_collection(world, target, COLLECTION_RADIUS_PX, day, 0, 2)
	_expect(bool(first_pickup.get("changed", false)) and materials.held_count() == 1, "revealed titanium did not enter normal cargo")
	_expect(materials.update_collection(world, target, COLLECTION_RADIUS_PX, day, 0, 2).is_empty(), "same reveal duplicated cargo")
	var reload_restore: Dictionary = materials.restore_unbanked(world, day, "reload")
	sortie.clear_map()
	await process_frame
	materials.on_map_loaded(world, day)
	var reload_launch: Dictionary = sortie.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), true)
	companion = sortie.companion()
	control = sortie.control_runtime()
	if companion != null:
		companion.set_physics_process(false)
	_expect(int(reload_restore.get("restored_count", 0)) == 1 and materials.held_count() == 0 and _deposit_is_closed(world), "reload did not restore held material to the closed mound")
	_expect(bool(reload_launch.get("spawned", false)) and str(reload_launch.get("active_species_id", "")) == "silt_hound", "reload did not restore Marl as the active companion")

	_set_action_positions(player, companion, positions)
	if not _start_excavate(control):
		_expect(false, "post-reload Excavate did not restart: %s" % control.report())
		_finish(world, player, rescue, sortie, migration, profile, oxygen, day, {})
		return
	var final_reveal: Dictionary = _advance_until(companion, control.excavate_runtime(), oxygen, day, "revealed")
	_expect(bool(materials.update_collection(world, target, COLLECTION_RADIUS_PX, day, 0, 2).get("changed", false)) and materials.held_count() == 1, "post-reload pickup did not collect exactly once")
	var titanium_before := profile.material_quantity(MATERIAL_ID)
	player.global_position = world.get_extraction_center()
	var banked: Dictionary = materials.try_commit_at_boat(world, player.global_position)
	_expect(bool(banked.get("changed", false)) and profile.material_quantity(MATERIAL_ID) == titanium_before + 1 and materials.held_count() == 0, "canonical boat did not bank exactly one excavated titanium")
	_expect(materials.try_commit_at_boat(world, player.global_position).is_empty() and bool(world.get_material_candidate_state(TARGET_ID).get("depleted", false)), "banking duplicated or respawned the deposit")
	_expect(not profile.has_completed_project(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID) and not profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID), "material pickup silently built or granted the Rebreather")
	_expect(_prior_companions_unchanged(profile), "Marl journey changed Kite or Mica history")
	_expect(oxygen.oxygen_seconds > 0.0 and oxygen.oxygen_seconds < oxygen_start and day.daylight_remaining_seconds > 0.0 and day.daylight_remaining_seconds < daylight_start, "oxygen/daylight pressure did not continue through the journey")
	_finish(world, player, rescue, sortie, migration, profile, oxygen, day, final_reveal)


func _release_marl(rescue) -> bool:
	var activated: Dictionary = rescue.activate()
	if not bool(activated.get("changed", false)):
		return false
	var completed: Dictionary = rescue.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	return str(completed.get("reason", "")) == "released" and str(rescue.report().get("pending_rescue_id", "")) == RESCUE_ID


func _start_excavate(control) -> bool:
	var opened: Dictionary = control.begin_command_mode()
	if not bool(opened.get("command_mode", false)) or not paused:
		return false
	var started: Dictionary = control.activate_context_command(_command_ids(control).find("excavate"))
	return bool(started.get("changed", false)) and str(started.get("reason", "")) == "started" and not paused


func _advance_until(companion, excavation, oxygen, day, target_state: String) -> Dictionary:
	for _index in range(420):
		companion.advance(STEP_SECONDS)
		excavation.advance(STEP_SECONDS)
		_pressure(oxygen, day, STEP_SECONDS)
		var report: Dictionary = excavation.report()
		if str(report.get("state", "")) == target_state:
			return report
	_failures.append("Excavate did not reach %s" % target_state)
	return excavation.report()


func _pressure(oxygen, day, seconds: float) -> void:
	oxygen.drain_oxygen(seconds)
	day.advance_daylight(seconds)


func _action_positions(world, target: Vector2) -> Dictionary:
	var points: Array[Vector2] = []
	for radius in [48.0, 64.0, 80.0, 96.0]:
		for index in range(16):
			var candidate := target + Vector2.from_angle(float(index) / 16.0 * TAU) * float(radius)
			if world.find_open_path(candidate, candidate).is_empty() or not world.has_clear_terrain_line(candidate, target):
				continue
			points.append(candidate)
			if points.size() >= 2:
				return {"player": points[0], "companion": points[1]}
	_failures.append("could not find deterministic open excavation positions")
	return {"player": target, "companion": target}


func _set_action_positions(player, companion, positions: Dictionary) -> void:
	player.global_position = positions.get("player", player.global_position)
	companion.global_position = positions.get("companion", companion.global_position)


func _command_ids(control) -> Array[String]:
	var ids: Array[String] = []
	for command in control.report().get("context_commands", []):
		ids.append(str((command as Dictionary).get("id", "")))
	return ids


func _rescue_center(world) -> Vector2:
	return _rescue_by_id(world).get("center", Vector2.ZERO)


func _rescue_by_id(world) -> Dictionary:
	for rescue in world.get_creature_rescues():
		if str((rescue as Dictionary).get("id", "")) == RESCUE_ID:
			return (rescue as Dictionary).duplicate(true)
	return {}


func _target_center(world) -> Vector2:
	return world.get_material_candidate_state(TARGET_ID).get("candidate", {}).get("center", Vector2.ZERO)


func _deposit_is_closed(world) -> bool:
	var state: Dictionary = world.get_material_candidate_state(TARGET_ID)
	return not bool(state.get("revealed", true)) and not bool(state.get("available", true)) and str(state.get("mound", {}).get("state", "")) == "closed"


func _normal_titanium_quantity(world, selected_ids: Array) -> int:
	var quantity := 0
	for candidate in world.get_material_candidates():
		if selected_ids.has(str(candidate.get("id", ""))) and str(candidate.get("id", "")) != TARGET_ID and str(candidate.get("material_id", "")) == MATERIAL_ID:
			quantity += int(candidate.get("material_quantity", 0))
	return quantity


func _optional_pool_is_valid(world) -> bool:
	for pool in world.get_material_candidate_pools():
		if str((pool as Dictionary).get("id", "")) == "silt_hound_excavation_pool":
			return str(pool.get("pool_role", "")) == "optional_bonus" and (pool.get("guaranteed_candidate_ids", []) as Array).has(TARGET_ID)
	return false


func _prior_companions_unchanged(profile) -> bool:
	var kite := _individual(profile, CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID)
	var mica := _individual(profile, CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID)
	return str(kite.get("selected_adaptation_id", "")) == "guardian_pulse" and str(mica.get("selected_adaptation_id", "")) == "drift_lens"


func _individual(profile, individual_id: String) -> Dictionary:
	for value in profile.companion_report().get("individuals", []):
		if str((value as Dictionary).get("individual_id", "")) == individual_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _has_individual(profile, individual_id: String) -> bool:
	return not _individual(profile, individual_id).is_empty()


func _action(action_name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	return event


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _control_allowed() -> bool:
	return true


func _record_note(note: String) -> void:
	_notes.append(note)


func _finish(world, player, rescue, sortie, migration: Dictionary, profile, oxygen, day, excavation: Dictionary) -> void:
	paused = false
	Engine.time_scale = 1.0
	rescue.clear_map("smoke_complete")
	rescue.queue_free()
	sortie.clear_map()
	sortie.queue_free()
	player.queue_free()
	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Living Expedition 05 journey smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Living Expedition 05 checkpoint=%s outer_schema=%d companion_schema=%d migration=%s rescue=%s:pending>committed active=%s command=excavate phases=%s deposit=closed>opened>empty material=%s cargo=0>1>0 banked=%d oxygen=%.2f daylight=%.2f resets=retry+oxygen_failure+reload duplicate=false optional_supply=true gates=focused_guard." % [
		CHECKPOINT_ID,
		ExpansionProfileState.SCHEMA_VERSION,
		int(migration.get("profile_schema", 0)),
		str(migration.get("migrations", [])),
		RESCUE_ID,
		MARL_ID,
		str(excavation.get("visited_states", [])),
		MATERIAL_ID,
		profile.material_quantity(MATERIAL_ID),
		oxygen.oxygen_seconds,
		day.daylight_remaining_seconds,
	])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
