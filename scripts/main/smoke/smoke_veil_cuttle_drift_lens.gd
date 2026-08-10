extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CUTTLE_SCENE := preload("res://scenes/companion/VeilCuttleCompanion.tscn")
const MovingHazardController := preload("res://scripts/main/moving_hazard_controller.gd")
const VeilCuttleControlRuntime := preload("res://scripts/companion/veil_cuttle_control_runtime.gd")
const VeilCuttleDriftLensRuntime := preload("res://scripts/companion/veil_cuttle_drift_lens_runtime.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const CONDITION_ID := "southwest_jellyfish_bloom"
const SOUTHWEST_ID := "southwest_bloom_jellyfish_patrol"
const DEEP_ID := "deep_route_jellyfish_patrol"

var _failures: Array[String] = []
var _status_notes: Array[String] = []


class EmptySnapshotFixture:
	extends RefCounted

	func snapshot() -> Array:
		return []


class OccludedWorldFixture:
	extends Node

	func has_clear_terrain_line(_start: Vector2, _finish: Vector2) -> bool:
		return false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	var cuttle := CUTTLE_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(cuttle)
	player.global_position = world.spawn_position
	cuttle.configure(world, player, Callable(), {
		"individual_id": "veil_cuttle_juvenile_01",
		"species_id": "veil_cuttle",
		"callsign": "Mica",
		"earned_memory_ids": ["followed_the_bloom"],
		"selected_adaptation_id": "drift_lens",
	})
	cuttle.set_physics_process(false)
	var moving_hazards := MovingHazardController.new()
	moving_hazards.reset(world, [CONDITION_ID])
	var control := VeilCuttleControlRuntime.new()
	get_root().add_child(control)
	control.bind_interface(Callable(self, "_record_status"), Callable(self, "_control_allowed"))
	control.bind_map(world, player, cuttle, moving_hazards)
	await physics_frame

	var snapshot_before := moving_hazards.snapshot()
	_expect(_snapshot_ids(snapshot_before).has(SOUTHWEST_ID), "conditional southwest jellyfish patrol was unavailable to Drift Lens")
	_expect(_snapshot_ids(snapshot_before).has(DEEP_ID), "unconditional deep-route jellyfish patrol was unavailable to Drift Lens")
	var commands: Array = control.report().get("context_commands", [])
	_expect(_command_ids(commands) == ["recall", "reveal_trace", "read_drift"], "adapted Mica BOND palette did not expose exactly three commands")
	_expect(not _command_ids(commands).has("mount") and not control.hides_diver_hotbar(), "Drift Lens changed Mica's independent role")

	_test_projection(control, moving_hazards, player, cuttle, SOUTHWEST_ID, true)
	control.drift_lens_runtime().advance(VeilCuttleDriftLensRuntime.COOLDOWN_SECONDS + 0.1)
	_test_projection(control, moving_hazards, player, cuttle, DEEP_ID, false)
	_test_denials(world, player, cuttle, moving_hazards, control)

	control.clear_map()
	paused = false
	control.queue_free()
	cuttle.queue_free()
	player.queue_free()
	world.queue_free()
	Engine.time_scale = 1.0
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Veil Cuttle Drift Lens smoke failed: %s" % failure)
		quit(1)
		return
	print(
		"PASS: Veil Cuttle Drift Lens action=read_drift role=independent timing=tactical_pause subjects=%s,%s path=true direction=true approach_warning=true bounded=%.1fs denials=no_subject,out_of_range,occluded,cooldown hazard_mutation=false access=false reward=false Kite_unchanged=existing_regression." % [
			SOUTHWEST_ID,
			DEEP_ID,
			VeilCuttleDriftLensRuntime.PROJECTION_SECONDS,
		]
	)
	quit(0)


func _test_projection(control, moving_hazards, player, cuttle, target_id: String, require_approach: bool) -> void:
	var target: Dictionary = moving_hazards.snapshot_for(target_id)
	var direction: Vector2 = target.get("movement_direction", Vector2.RIGHT)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var center: Vector2 = target.get("center", Vector2.ZERO)
	cuttle.global_position = center - direction * 36.0
	player.global_position = center + direction * 18.0 if require_approach else cuttle.global_position + Vector2(12.0, 0.0)
	cuttle.advance(0.0)
	var before: Array = moving_hazards.snapshot()
	_expect(control.drift_lens_runtime().action().get("label") == "Read Drift", "moving-hazard ecology lost the Read Drift label")
	var open: Dictionary = control.begin_command_mode()
	_expect(paused and bool(open.get("simulation_paused", false)), "Read Drift BOND mode did not use shared tactical pause")
	_expect(str(open.get("timing_policy", "")) == "tactical_pause", "Read Drift BOND mode reported the wrong timing policy")
	control.cycle_context_command()
	control.cycle_context_command()
	var result: Dictionary = control.confirm_context_command()
	_expect(bool(result.get("changed", false)) and result.get("target_id") == target_id, "Read Drift did not project expected patrol %s" % target_id)
	_expect(result.get("command_label") == "Read Drift", "moving-hazard result was mislabeled as an eel prediction")
	_expect((result.get("path", []) as Array).size() >= 2 and (result.get("movement_direction", Vector2.ZERO) as Vector2) != Vector2.ZERO, "Read Drift omitted path or live direction")
	if require_approach:
		_expect(bool(result.get("approaching", false)), "Read Drift omitted a deterministic approach warning")
	_expect(not bool(result.get("hazard_changed", true)) and not bool(result.get("access_changed", true)) and (result.get("reward_ids", []) as Array).is_empty(), "Read Drift changed hazard, access, or rewards")
	_expect(moving_hazards.snapshot() == before, "Read Drift mutated moving-hazard authority")
	var projection: Dictionary = cuttle.report().get("drift_projection", {})
	_expect(bool(projection.get("visible", false)) and int(projection.get("path_point_count", 0)) >= 2, "Read Drift projection was not visibly bounded to the patrol path")
	_expect(control.drift_lens_runtime().action().get("reason") == "cooldown", "Read Drift cooldown did not block immediate reuse")
	control.drift_lens_runtime().advance(VeilCuttleDriftLensRuntime.COOLDOWN_SECONDS + 0.1)
	_expect(not bool(cuttle.report().get("drift_projection", {}).get("visible", true)), "Read Drift projection outlived its bounded interval")


func _test_denials(world, player, cuttle, moving_hazards, control) -> void:
	var drift = control.drift_lens_runtime()
	drift.bind_map(world, player, cuttle, EmptySnapshotFixture.new())
	_expect(drift.action().get("reason") == "no_subject", "empty hazard snapshot did not report no subject")

	drift.bind_map(world, player, cuttle, moving_hazards)
	cuttle.global_position = world.spawn_position
	player.global_position = cuttle.global_position + Vector2(12.0, 0.0)
	_expect(drift.action().get("reason") == "out_of_range", "distant patrol did not report out of range")

	var occluded_world := OccludedWorldFixture.new()
	get_root().add_child(occluded_world)
	var target: Dictionary = moving_hazards.snapshot_for(DEEP_ID)
	cuttle.global_position = target.get("center", Vector2.ZERO)
	player.global_position = cuttle.global_position + Vector2(12.0, 0.0)
	drift.bind_map(occluded_world, player, cuttle, moving_hazards)
	_expect(drift.action().get("reason") == "occluded", "terrain-blocked patrol did not report occlusion")
	occluded_world.queue_free()
	drift.bind_map(world, player, cuttle, moving_hazards)


func _snapshot_ids(snapshots: Array) -> Array[String]:
	var ids: Array[String] = []
	for snapshot in snapshots:
		ids.append(str((snapshot as Dictionary).get("id", "")))
	return ids


func _command_ids(commands: Array) -> Array[String]:
	var ids: Array[String] = []
	for command in commands:
		ids.append(str((command as Dictionary).get("id", "")))
	return ids


func _record_status(note: String) -> void:
	_status_notes.append(note)


func _control_allowed() -> bool:
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
