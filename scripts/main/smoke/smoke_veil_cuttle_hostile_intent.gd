extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CUTTLE_SCENE := preload("res://scenes/companion/VeilCuttleCompanion.tscn")
const TerritorialHostileController := preload("res://scripts/main/territorial_hostile_controller.gd")
const VeilCuttleControlRuntime := preload("res://scripts/companion/veil_cuttle_control_runtime.gd")
const VeilCuttleDriftLensRuntime := preload("res://scripts/companion/veil_cuttle_drift_lens_runtime.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const TARGET_ID := "deep_cache_territorial_eel"
const RELATIONSHIP_ID := "deep_cache_eel_companion_response"

var _failures: Array[String] = []
var _status_notes: Array[String] = []


class EmptySnapshotFixture:
	extends RefCounted

	func snapshot() -> Array:
		return []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_time_scale := Engine.time_scale
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	await process_frame
	_expect(_relationship_by_id(world, RELATIONSHIP_ID).get("hostile_id") == TARGET_ID, "source-linked Mica/eel relationship was unavailable")

	var hostiles := TerritorialHostileController.new()
	hostiles.on_map_loaded(world, false)
	var home: Vector2 = hostiles.state_for(TARGET_ID).get("home_center", Vector2.ZERO)
	var player = PLAYER_SCENE.instantiate()
	get_root().add_child(player)
	player.set_physics_process(false)
	player.global_position = home + Vector2(-64.0, 0.0)
	var cuttle = CUTTLE_SCENE.instantiate()
	get_root().add_child(cuttle)
	_configure_mica(cuttle, world, player, true)
	cuttle.set_physics_process(false)
	var control := VeilCuttleControlRuntime.new()
	get_root().add_child(control)
	control.set_process(false)
	control.bind_interface(Callable(self, "_record_status"), Callable(self, "_control_allowed"))
	control.bind_map(world, player, cuttle, EmptySnapshotFixture.new(), hostiles)
	hostiles.update(world, player.global_position, 0.0)

	_test_warning_projection(world, hostiles, player, cuttle, control)
	_test_lunge_projection(world, hostiles, player, control)
	_test_context_and_adaptation_boundaries(world, hostiles, player, cuttle, control)

	control.clear_map()
	control.queue_free()
	cuttle.queue_free()
	player.queue_free()
	world.queue_free()
	Engine.time_scale = original_time_scale
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Veil Cuttle hostile-intent smoke failed: %s" % failure)
		quit(1)
		return
	print(
		"PASS: Mica Read Drift target=%s relationship=%s phase=warning+lunge direction=true territory=true recovery=1.25s bounded_context=true mutation=false cooldown=true failure_reset=true unadapted=false jellyfish_regression=separate." % [
			TARGET_ID,
			RELATIONSHIP_ID,
		]
	)
	quit(0)


func _test_warning_projection(world, hostiles, player, cuttle, control) -> void:
	var drift = control.drift_lens_runtime()
	var warning: Dictionary = hostiles.state_for(TARGET_ID)
	_expect(warning.get("phase") == "warning", "eel fixture did not enter warning phase")
	var before := warning.duplicate(true)
	var commands: Array = control.begin_command_mode().get("context_commands", [])
	_expect(_command_ids(commands) == ["recall", "reveal_trace", "read_drift"], "adapted Mica palette changed while reading the eel")
	var result := _activate_command(control, "read_drift")
	_expect(bool(result.get("changed", false)) and result.get("target_id") == TARGET_ID, "Read Drift did not select the source-linked eel")
	_expect(result.get("subject_kind") == "territorial_hostile" and result.get("phase") == "warning", "Read Drift omitted the current hostile phase")
	_expect((result.get("movement_direction", Vector2.ZERO) as Vector2) != Vector2.ZERO, "warning read omitted projected lunge direction")
	_expect((result.get("projected_lunge_target", Vector2.ZERO) as Vector2).is_equal_approx(player.global_position), "warning read did not project the bounded lunge target")
	_expect((result.get("territory_rect", Rect2()) as Rect2).size != Vector2.ZERO, "warning read omitted the territory edge")
	_expect(is_equal_approx(float(result.get("recovery_seconds", 0.0)), 1.25), "warning read omitted the recovery interval")
	var note := str(result.get("note", ""))
	_expect(note.contains("WARNING") and note.contains("Lunge") and note.contains("Recovery"), "warning feedback did not explain phase, direction, and opening")
	_expect(not bool(result.get("hostile_changed", true)) and not bool(result.get("access_changed", true)) and (result.get("reward_ids", []) as Array).is_empty(), "Read Drift claimed hostile, access, or reward mutation")
	_expect(hostiles.state_for(TARGET_ID) == before, "Read Drift mutated hostile authority")
	_expect(not result.has("health") and not result.has("damage"), "read-only result leaked combat authority fields")
	var projection: Dictionary = cuttle.report().get("drift_projection", {})
	_expect(bool(projection.get("visible", false)) and projection.get("phase") == "warning", "world-local warning projection was not visible")
	_expect((projection.get("territory_rect", Rect2()) as Rect2).size != Vector2.ZERO, "world-local projection omitted the territory boundary")
	_expect(drift.action().get("reason") == "cooldown", "eel read ignored Drift Lens cooldown")
	control.reset_transient("failure")
	_expect(not bool(cuttle.report().get("drift_projection", {}).get("visible", true)), "failure reset retained eel projection")
	_expect(is_zero_approx(float(drift.report().get("cooldown_seconds", -1.0))) and drift.action().get("reason") == "ready", "failure reset retained cooldown or lost the target")
	_expect(hostiles.state_for(TARGET_ID) == before, "failure reset mutated hostile state")


func _test_lunge_projection(world, hostiles, player, control) -> void:
	var warning_seconds := float(hostiles.state_for(TARGET_ID).get("warning_seconds", 0.75))
	hostiles.update(world, player.global_position, warning_seconds + 0.01)
	var before: Dictionary = hostiles.state_for(TARGET_ID)
	_expect(before.get("phase") == "lunge", "eel fixture did not enter lunge phase")
	var result: Dictionary = control.drift_lens_runtime().dispatch(VeilCuttleDriftLensRuntime.ACTION_ID)
	_expect(bool(result.get("changed", false)) and result.get("phase") == "lunge", "Read Drift did not refresh to the live lunge phase")
	_expect((result.get("projected_lunge_target", Vector2.ZERO) as Vector2).is_equal_approx(before.get("lunge_target", Vector2.ZERO)), "lunge read did not use the hostile-owned target")
	_expect(hostiles.state_for(TARGET_ID) == before, "lunge read mutated hostile state")
	control.reset_transient("failure")


func _test_context_and_adaptation_boundaries(world, hostiles, player, cuttle, control) -> void:
	player.global_position = world.spawn_position
	cuttle.global_position = player.global_position
	cuttle.advance(0.0)
	_expect(control.drift_lens_runtime().action().get("reason") == "no_subject", "eel intent remained globally readable outside its bounded context")

	_configure_mica(cuttle, world, player, false)
	control.bind_map(world, player, cuttle, EmptySnapshotFixture.new(), hostiles)
	_expect(not _command_ids(control.report().get("context_commands", [])).has("read_drift"), "unadapted Mica received Read Drift")
	_expect(not bool(control.drift_lens_runtime().report().get("learned", true)), "unadapted Mica reported Drift Lens learned")


func _configure_mica(cuttle, world, player, adapted: bool) -> void:
	cuttle.configure(world, player, Callable(), {
		"individual_id": "veil_cuttle_juvenile_01",
		"species_id": "veil_cuttle",
		"callsign": "Mica",
		"earned_memory_ids": ["followed_the_bloom"] if adapted else [],
		"selected_adaptation_id": "drift_lens" if adapted else "",
	})


func _relationship_by_id(world, relationship_id: String) -> Dictionary:
	for relationship in world.get_companion_hostile_responses():
		if str(relationship.get("id", "")) == relationship_id:
			return relationship
	return {}


func _activate_command(control, command_id: String) -> Dictionary:
	var commands: Array = control.report().get("context_commands", [])
	for index in range(commands.size()):
		if str(commands[index].get("id", "")) == command_id:
			return control.activate_context_command(index)
	control.end_command_mode()
	return {"changed": false, "reason": "missing_command"}


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
