extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const OxygenConsumptionZoneController := preload("res://scripts/main/oxygen_consumption_zone_controller.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const TEST_PATH := "user://oceangame2_rebreather_runtime_test.json"
const ZONE_ID := "far_west_confined_wreck_oxygen_zone"
const PRESSURE_ZONE_ID := "abyssal_basin_pressure_zone"

var _failures: Array[String] = []


class FixtureWorld:
	extends RefCounted
	var map_id := "rebreather_project_fixture"
	var projects: Array[Dictionary] = []

	func get_material_projects() -> Array[Dictionary]:
		return projects


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	world.load_greybox()

	var zone: Dictionary = world.get_marker_zone(ZONE_ID)
	_expect(not zone.is_empty(), "source-authored oxygen zone was missing")
	if zone.is_empty():
		_finish(world, {})
		return
	var inside := _zone_center(zone, float(world.tile_size))
	var outside: Vector2 = world.spawn_position

	var project_profile := ExpansionProfileState.new(TEST_PATH, true)
	_expect(project_profile.load_profile().get("status") == "missing", "fresh profile did not start missing")
	var source_runtime := MaterialProjectRuntime.new(project_profile)
	var source_report: Dictionary = source_runtime.on_map_loaded(world)
	_expect(
		source_report.get("project_ids", []).count(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID) == 1,
		"rebreather project was not loaded exactly once"
	)
	var project := source_runtime.project_definition_for(
		ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID
	)
	_expect(not project.is_empty(), "rebreather project definition was unavailable")
	var direct_unlock: Dictionary = project_profile.unlock_capability(
		ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID,
		false
	)
	_expect(
		direct_unlock.get("reason") == "project_transaction_required",
		"rebreather unlocked outside its project transaction"
	)
	var missing_knowledge: Dictionary = project_profile.complete_material_project(project, false)
	_expect(
		missing_knowledge.get("reason") == "missing_discovery",
		"relay discovery did not gate the rebreather project"
	)

	project_profile.complete_discovery(
		ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID,
		true
	)
	project_profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 1,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
		ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1,
	}, true)
	var fixture_world := FixtureWorld.new()
	fixture_world.projects = [project]
	var project_runtime := MaterialProjectRuntime.new(project_profile)
	project_runtime.on_map_loaded(fixture_world)
	_expect(project_runtime.status() == "ready", "exact rebreather recipe was not ready")
	_expect(
		project_runtime.debrief_lines() == [
			"P: Build closed circuit rebreather",
			"Effect: normal oxygen drain in confined wreck air",
		],
		"rebreather debrief guidance drifted"
	)
	var day := ExpeditionDayState.new()
	_expect(
		project_runtime.try_build(day.phase).get("reason") == "wrong_phase",
		"rebreather built during active day"
	)
	day.end_day("manual")
	var completed: Dictionary = project_runtime.try_build(day.phase)
	_expect(bool(completed.get("changed", false)), "night debrief did not build rebreather")
	_expect(
		project_profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID),
		"project did not grant durable rebreather capability"
	)
	_expect(project_profile.material_inventory().is_empty(), "project did not spend the exact recipe")
	_expect(
		project_runtime.try_build(day.phase).get("reason") == "already_completed",
		"repeat rebreather build was not exact-once"
	)
	var reloaded_profile := ExpansionProfileState.new(TEST_PATH, true)
	_expect(reloaded_profile.load_profile().get("status") == "loaded", "rebreather profile did not reload")
	_expect(
		reloaded_profile.has_completed_project(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID)
		and reloaded_profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID),
		"reload lost the rebreather project transaction"
	)

	var unprotected_profile := ExpansionProfileState.new("", false)
	var controller := OxygenConsumptionZoneController.new()
	controller.on_map_loaded(world)
	var warning: Dictionary = controller.update(
		inside,
		Callable(unprotected_profile, "has_capability"),
		0.5
	)
	_expect(warning.get("note") == "Confined wreck air | Retreat", "zone warning drifted")
	_expect(
		is_equal_approx(float(warning.get("drain_multiplier", 0.0)), 1.0),
		"warning grace did not retain ordinary drain"
	)
	var oxygen := SortieState.new(10.0)
	oxygen.drain_oxygen(0.5, float(warning.get("drain_multiplier", 1.0)))
	var grace_boundary: Dictionary = controller.update(
		inside,
		Callable(unprotected_profile, "has_capability"),
		0.5
	)
	oxygen.drain_oxygen(0.5, float(grace_boundary.get("drain_multiplier", 1.0)))
	var critical: Dictionary = controller.update(
		inside,
		Callable(unprotected_profile, "has_capability"),
		0.1
	)
	var source_multiplier := float(zone.get("unprotected_oxygen_drain_multiplier", 0.0))
	oxygen.drain_oxygen(0.1, float(critical.get("drain_multiplier", 1.0)))
	_expect(critical.get("note") == "Confined wreck air | Oxygen x8", "critical feedback drifted")
	_expect(
		is_equal_approx(float(critical.get("drain_multiplier", 0.0)), source_multiplier),
		"controller ignored the source multiplier"
	)
	_expect(is_equal_approx(oxygen.oxygen_seconds, 8.2), "SortieState did not own multiplied drain")
	_expect(
		not critical.has("oxygen_seconds") and not critical.has("health"),
		"zone controller owned player resource state"
	)

	controller.update(outside, Callable(unprotected_profile, "has_capability"), 0.0)
	var reentered: Dictionary = controller.update(
		inside,
		Callable(unprotected_profile, "has_capability"),
		0.1
	)
	_expect(reentered.get("note") == "Confined wreck air | Retreat", "exit did not reset grace")
	controller.update(outside, Callable(reloaded_profile, "has_capability"), 0.0)
	var protected_entry: Dictionary = controller.update(
		inside,
		Callable(reloaded_profile, "has_capability"),
		0.0
	)
	_expect(protected_entry.get("note") == "Rebreather active", "protected entry feedback drifted")
	_expect(
		is_equal_approx(float(protected_entry.get("drain_multiplier", 0.0)), 1.0),
		"rebreather did not normalize the authored zone"
	)
	var protected_settled: Dictionary = controller.update(
		inside,
		Callable(reloaded_profile, "has_capability"),
		2.0
	)
	_expect(str(protected_settled.get("note", "")).is_empty(), "protected note did not clear")

	var pressure_zone: Dictionary = world.get_marker_zone(PRESSURE_ZONE_ID)
	controller.update(
		_zone_center(pressure_zone, float(world.tile_size)),
		Callable(unprotected_profile, "has_capability"),
		0.1
	)
	_expect(
		not bool(controller.report().get("inside", true))
		and is_equal_approx(controller.drain_multiplier(), 1.0),
		"rebreather controller changed the separate abyssal pressure zone"
	)
	controller.reset()
	_expect(
		not bool(controller.report().get("inside", true))
		and is_equal_approx(controller.drain_multiplier(), 1.0),
		"reset retained zone exposure"
	)

	_finish(world, {
		"project": ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID,
		"zone": ZONE_ID,
		"multiplier": source_multiplier,
		"warning": warning.get("note", ""),
		"protected": protected_entry.get("note", ""),
		"oxygen_after_sample": oxygen.oxygen_seconds,
	})


func _zone_center(zone: Dictionary, tile_size: float) -> Vector2:
	return Vector2(
		float(zone.get("x", 0)) + float(zone.get("w", 0)) * 0.5,
		float(zone.get("y", 0)) + float(zone.get("h", 0)) * 0.5
	) * tile_size


func _finish(world, report: Dictionary) -> void:
	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Oxygen consumption zone state smoke failed: %s" % failure)
		quit(1)
		return
	print("Oxygen consumption zone state smoke passed: %s." % str(report))
	quit(0)


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
