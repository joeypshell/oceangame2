extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CompanionRescueRuntime := preload("res://scripts/companion/companion_rescue_runtime.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const CompanionSpeciesRuntimeFactory := preload("res://scripts/companion/companion_species_runtime_factory.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const RESCUE_ID := "silt_hound_rescue_01"
const INDIVIDUAL_ID := "silt_hound_juvenile_01"
const SPECIES_ID := "silt_hound"
const CUTTER_ID := "salvage_cutter"
const BOAT_ENTRY_ID := "surface_boat_entry"
const STEP_SECONDS := 1.0 / 30.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	await physics_frame

	var rescue := _rescue_by_id(world, RESCUE_ID)
	_expect(not rescue.is_empty(), "source omitted Marl's rescue")
	if rescue.is_empty():
		_finish(world, player, null, null)
		return
	_test_source_and_factory(world, rescue)

	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var rescue_runtime := CompanionRescueRuntime.new()
	get_root().add_child(rescue_runtime)
	player.global_position = rescue.get("center", Vector2.ZERO)
	rescue_runtime.bind_map(
		world,
		player,
		profile,
		Callable(self, "_has_no_upgrade"),
		Callable(profile, "has_capability"),
		34.0
	)
	_expect(str(rescue_runtime.activate().get("reason", "")) == "missing_capability", "rescue bypassed its Cutter requirement")
	_seed_cutter_profile(profile, world)
	_test_cancel_and_failure(world, player, profile, rescue_runtime, rescue)

	player.global_position = rescue.get("center", Vector2.ZERO)
	_expect(bool(rescue_runtime.activate().get("changed", false)), "final Cutter hold did not activate")
	var completed: Dictionary = rescue_runtime.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	_expect(str(completed.get("state", "")) == "complete", "final Cutter hold did not free Marl")
	var pending = rescue_runtime.pending_companion()
	_expect(pending != null, "completed rescue did not spawn pending Marl")
	if pending != null:
		pending.set_physics_process(false)
		var pending_report: Dictionary = pending.report()
		_expect(str(pending_report.get("species_id", "")) == SPECIES_ID, "pending companion used the wrong species runtime")
		_expect(str(pending_report.get("presentation", {}).get("context_kind", "")) == "rescue_memory", "release did not show Marl's rescue response")
		_expect(int(pending_report.get("presentation", {}).get("six_fin_count", 0)) == 6, "Marl presentation did not expose six fins")
		player.global_position += Vector2(120.0, 0.0)
		pending.advance(0.0)
		_expect(str(pending.report().get("state", "")) == "follow", "freed Marl did not follow toward the boat")

	var sortie := CompanionSortieRuntime.new()
	get_root().add_child(sortie)
	sortie.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), false)
	player.global_position = world.get_entry_position(BOAT_ENTRY_ID)
	var committed: Dictionary = rescue_runtime.commit_at_boat()
	_expect(bool(committed.get("changed", false)), "canonical boat did not commit Marl")
	_expect(_profile_has_marl(profile), "boat commit omitted Marl from the profile")
	_expect(rescue_runtime.pending_companion() == null, "boat commit retained duplicate pending Marl")
	_expect(sortie.companion() == null, "boat commitment spawned Marl before the next sortie")
	var spawned: Dictionary = sortie.sync_spawn()
	var marl = sortie.companion()
	_expect(bool(spawned.get("spawned", false)) and marl != null, "next sortie did not spawn selected Marl")
	if marl != null:
		marl.set_physics_process(false)
		var profile_before_follow := profile.companion_report()
		_test_identity_and_control(sortie, marl)
		_test_follow_and_recovery(world, player, marl)
		_test_locked_gate(world, player, marl)
		_expect(profile.companion_report() == profile_before_follow, "follow and control mutated persistent companion state")
	_finish(world, player, rescue_runtime, sortie)


func _test_source_and_factory(world, rescue: Dictionary) -> void:
	_expect(str(rescue.get("species_id", "")) == SPECIES_ID, "rescue species id drifted")
	_expect(str(rescue.get("required_capability_id", "")) == CUTTER_ID, "rescue lost its Cutter requirement")
	_expect(str(rescue.get("commit_entry_id", "")) == BOAT_ENTRY_ID, "rescue lost canonical boat commitment")
	var marker: Node = world.get_node_or_null("Markers/%s" % RESCUE_ID)
	_expect(marker != null, "Marl rescue marker was not rendered")
	if marker != null:
		_expect(marker.get_node_or_null("SiltHoundBody") != null, "rescue marker reused another species body")
		_expect(marker.get_node_or_null("DredgeCable") != null, "rescue marker omitted dredge cable")
		_expect(marker.get_node_or_null("BroodStone") != null, "rescue marker omitted brood stone")
		var fin_count := 0
		for child in marker.get_children():
			if str(child.name).begins_with("SiltHoundFin"):
				fin_count += 1
		_expect(fin_count == 6, "rescue marker did not show the six-fin silhouette")
	var factory := CompanionSpeciesRuntimeFactory.new()
	_expect(factory.is_supported(SPECIES_ID), "species factory did not support Silt Hound")
	_expect(factory.default_callsign(SPECIES_ID) == "Marl", "species factory callsign drifted")
	_expect(factory.display_name(SPECIES_ID) == "Silt Hound", "species factory display name drifted")
	var factory_companion = factory.create_companion(SPECIES_ID)
	var factory_control = factory.create_control(SPECIES_ID)
	_expect(factory_companion != null and factory_control != null, "species factory omitted companion or control dispatch")
	if factory_companion != null:
		factory_companion.free()
	if factory_control != null:
		factory_control.free()


func _test_cancel_and_failure(world, player, profile, runtime, rescue: Dictionary) -> void:
	_expect(bool(runtime.activate().get("changed", false)), "Cutter hold did not activate")
	var partial: Dictionary = runtime.update(CompanionRescueRuntime.RELEASE_SECONDS * 0.5)
	_expect(str(partial.get("state", "")) == "releasing", "partial hold did not advance")
	_expect(str(runtime.release_use().get("state", "")) == "canceled", "released USE did not cancel rescue")
	_expect(str(world.get_creature_rescue_report().get("states", {}).get(RESCUE_ID, "")) == "available", "cancel did not restore source marker")

	player.global_position = rescue.get("center", Vector2.ZERO)
	runtime.activate()
	runtime.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	_expect(runtime.pending_companion() != null and not profile.has_committed_companion(), "release skipped pending state")
	var restored: Dictionary = runtime.reset_for_failure("oxygen_failure")
	_expect(bool(restored.get("changed", false)), "failure did not clear pending rescue")
	_expect(runtime.pending_companion() == null and not profile.has_committed_companion(), "failure persisted transient rescue state")
	_expect(str(world.get_creature_rescue_report().get("states", {}).get(RESCUE_ID, "")) == "available", "failure did not restore authored opportunity")


func _test_identity_and_control(sortie, marl) -> void:
	marl.advance(0.0)
	var report: Dictionary = marl.report()
	_expect(str(report.get("species_id", "")) == SPECIES_ID, "sortie companion identity drifted")
	_expect(str(report.get("state", "")) == "floor_attention", "Marl did not begin in floor-attention idle")
	_expect(bool(report.get("presentation", {}).get("floor_attention_visible", false)), "floor attention lacked a presentation cue")
	_expect(not bool(report.get("mounted", true)), "Marl exposed mounted state")
	_expect(not marl.has_method("set_external_control_active"), "independent-only Marl exposed mount handoff")
	var control = sortie.control_runtime()
	var commands: Array = control.report().get("context_commands", [])
	_expect(commands.size() == 1 and str((commands[0] as Dictionary).get("id", "")) == "recall", "pre-Excavate controller exposed the wrong BOND actions")
	_expect(not bool(control.hides_diver_hotbar()) and not bool(control.is_mounted()), "Marl control stole diver tool ownership")
	var opened: Dictionary = control.begin_command_mode()
	_expect(bool(opened.get("command_mode", false)) and bool(opened.get("simulation_paused", false)), "BOND did not pause on Marl's recall palette")
	var recalled: Dictionary = control.confirm_context_command()
	_expect(bool(recalled.get("changed", false)) and str(recalled.get("reason", "")) == "recalled", "Marl recall command failed")
	_expect(not bool(control.report().get("command_mode", true)), "recall left BOND open")
	marl.recover_to_player()


func _test_follow_and_recovery(world, player, marl) -> void:
	var route := _find_representative_route(world, marl.global_position)
	_expect(not route.is_empty(), "full level had no long gate-free Marl route")
	if route.is_empty():
		return
	var origin: Vector2 = route["origin"]
	var follow_target := _path_point_in_distance_range(route["path"], origin, 100.0, 175.0)
	var catch_up_target := _path_point_in_distance_range(route["path"], origin, 250.0, 410.0)
	_expect(follow_target != Vector2.ZERO and catch_up_target != Vector2.ZERO, "route omitted Marl's follow envelopes")
	if follow_target != Vector2.ZERO:
		marl.global_position = origin
		player.global_position = follow_target
		marl.advance(0.0)
		_expect(str(marl.report().get("state", "")) == "follow", "mid-range target did not select follow")
	if catch_up_target != Vector2.ZERO:
		marl.global_position = origin
		player.global_position = catch_up_target
		marl.advance(0.0)
		_expect(str(marl.report().get("state", "")) == "catch_up", "distant target did not select catch-up")
	player.global_position = origin
	marl.recover_to_player()
	player.global_position = route["target"]
	var before: Vector2 = marl.global_position
	marl.advance(0.05)
	var worried: Dictionary = marl.report()
	_expect(str(worried.get("state", "")) == "separated", "long separation skipped Marl's worried hold")
	_expect(before.distance_to(marl.global_position) <= 0.01, "Marl moved before the readable separation hold")
	_expect(bool(worried.get("presentation", {}).get("recovery_path_visible", false)), "separation did not show recovery route")
	marl.request_recall()
	var recovery_seen := false
	var stayed_open := true
	for _index in range(1000):
		marl.advance(STEP_SECONDS)
		var report: Dictionary = marl.report()
		recovery_seen = recovery_seen or str(report.get("state", "")) == "recovery"
		stayed_open = stayed_open and not world.find_open_path(marl.global_position, marl.global_position).is_empty()
		if marl.global_position.distance_to(player.global_position) <= 88.0 and str(report.get("state", "")) == "floor_attention":
			break
	_expect(recovery_seen, "Recall never entered deterministic Marl recovery")
	_expect(marl.global_position.distance_to(player.global_position) <= 88.0, "Marl did not recover through full-level geometry")
	_expect(stayed_open, "Marl recovery entered solid terrain")
	_expect(float(marl.report().get("maximum_step_distance", 999.0)) <= 10.0, "Marl recovery used a teleport-sized step")
	_expect(int(marl.report().get("facing_change_count", 999)) <= 14, "Marl recovery produced unstable direction flipping")


func _test_locked_gate(world, player, marl) -> void:
	var fixture := _find_gate_crossing(world)
	_expect(not fixture.is_empty(), "full level had no equipment-gate fixture")
	if fixture.is_empty():
		return
	var rect: Rect2 = fixture["gate"].get("rect", Rect2())
	marl.global_position = fixture["before"]
	player.global_position = fixture["after"]
	var entered_gate := false
	for _index in range(180):
		marl.advance(STEP_SECONDS)
		entered_gate = entered_gate or rect.has_point(marl.global_position)
	var report: Dictionary = marl.report()
	_expect(not entered_gate, "Marl bypassed an equipment gate")
	_expect(bool(report.get("path_blocked_by_gate", false)), "Marl did not report a blocked access path")
	_expect(str(report.get("state", "")) == "separated", "blocked gate did not leave readable separation")


func _rescue_by_id(world, rescue_id: String) -> Dictionary:
	for rescue in world.get_creature_rescues():
		if str(rescue.get("id", "")) == rescue_id:
			return rescue
	return {}


func _find_representative_route(world, start: Vector2) -> Dictionary:
	for salvage in world.get_salvage_centers():
		var path: Array = world.find_open_path(start, salvage.get("center", Vector2.ZERO))
		for index in range(path.size() - 1, -1, -1):
			var candidate := path[index] as Vector2
			if start.distance_to(candidate) < 620.0:
				continue
			var prefix := path.slice(0, index + 1)
			if prefix.all(func(point): return world.get_current_gate_at(point as Vector2).is_empty()):
				return {"origin": start, "target": candidate, "path": prefix}
	return {}


func _path_point_in_distance_range(path: Array, origin: Vector2, minimum: float, maximum: float) -> Vector2:
	for point in path:
		var candidate := point as Vector2
		var distance := origin.distance_to(candidate)
		if distance >= minimum and distance <= maximum:
			return candidate
	return Vector2.ZERO


func _find_gate_crossing(world) -> Dictionary:
	var tile := float(world.tile_size)
	for gate in world.get_current_gates():
		var rect: Rect2 = gate.get("rect", Rect2())
		var center := rect.get_center()
		for pair in [
			[Vector2(rect.position.x - tile * 1.5, center.y), Vector2(rect.end.x + tile * 1.5, center.y)],
			[Vector2(center.x, rect.position.y - tile * 1.5), Vector2(center.x, rect.end.y + tile * 1.5)],
		]:
			var before := pair[0] as Vector2
			var after := pair[1] as Vector2
			if (
				not world.find_open_path(before, before).is_empty()
				and not world.find_open_path(after, after).is_empty()
				and world.has_clear_terrain_line(before, after)
			):
				return {"gate": gate, "before": before, "after": after}
	return {}


func _seed_cutter_profile(profile, world) -> void:
	profile.complete_discovery(ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID, false)
	for project in world.get_material_projects():
		if str(project.get("id", "")) != ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID:
			continue
		var required := {}
		for material_id in project.get("required_materials", {}):
			required[str(material_id)] = int(project["required_materials"][material_id])
		profile.deposit_materials(required, false)
		profile.complete_material_project(project, false)
		return
	_expect(false, "map source omitted Cutter project")


func _profile_has_marl(profile) -> bool:
	for individual in profile.companion_report().get("individuals", []):
		if str((individual as Dictionary).get("individual_id", "")) == INDIVIDUAL_ID:
			return true
	return false


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _finish(world, player, rescue_runtime, sortie_runtime) -> void:
	if sortie_runtime != null:
		sortie_runtime.clear_map()
		sortie_runtime.queue_free()
	if rescue_runtime != null:
		rescue_runtime.clear_map("smoke_complete")
		rescue_runtime.queue_free()
	player.queue_free()
	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Silt Hound companion smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Silt Hound rescue=true marker=distinct cutter_hold=true cancel_restore=true failure_restore=true boat_commit=true follow=true recovery=true collision_safe=true gate_blocked=true six_fins=true floor_attention=true mounted=false excavate=false.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
