extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const SessionProgression := preload("res://scripts/main/session_progression.gd")
const TEST_PATH := "user://oceangame2_pressure_suit_project_test.json"
const PRODUCTION_LEVEL := "res://maps/production_level_01.greybox.json"

var _failures: Array[String] = []


class FixtureWorld:
	extends RefCounted
	var map_id := "pressure_project_fixture"
	var projects: Array[Dictionary] = []

	func get_material_projects() -> Array[Dictionary]:
		return projects


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var world = WORLD_SCENE.instantiate()
	world.map_path = PRODUCTION_LEVEL
	get_root().add_child(world)
	world.load_greybox()

	var profile := ExpansionProfileState.new(TEST_PATH, true)
	_expect(profile.load_profile().get("status") == "missing", "fresh pressure profile did not start missing")
	var source_runtime := MaterialProjectRuntime.new(profile)
	var source_report: Dictionary = source_runtime.on_map_loaded(world)
	var project_ids: Array = source_report.get("project_ids", [])
	_expect(project_ids.count(ExpansionProfileState.PRESSURE_SUIT_PROJECT_ID) == 1, "pressure project was not authored exactly once")
	var light_project_index := project_ids.find(ExpansionProfileState.DIVE_LIGHT_PROJECT_ID)
	_expect(light_project_index >= 0 and project_ids.find(ExpansionProfileState.PRESSURE_SUIT_PROJECT_ID) == light_project_index + 1, "pressure project did not follow the light project")
	var project := source_runtime.project_definition_for(ExpansionProfileState.PRESSURE_SUIT_PROJECT_ID)
	_expect(project.get("required_discovery_id") == ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID, "deep harmonic knowledge did not reveal the pressure project")
	var recipe: Dictionary = project.get("required_materials", {})
	_expect(
		recipe.size() == 3
		and int(recipe.get(ExpansionProfileState.TITANIUM_MATERIAL_ID, 0)) == 2
		and int(recipe.get(ExpansionProfileState.RUBBER_MATERIAL_ID, 0)) == 1
		and int(recipe.get(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID, 0)) == 1,
		"pressure project recipe drifted"
	)

	var direct_unlock: Dictionary = profile.unlock_capability(ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID, false)
	_expect(direct_unlock.get("reason") == "project_transaction_required", "pressure suit unlocked outside its project transaction")
	var missing_knowledge: Dictionary = profile.complete_material_project(project, false)
	_expect(missing_knowledge.get("reason") == "missing_discovery", "deep harmonic knowledge did not gate the pressure project")

	var session := SessionProgression.new()
	session.grant_wallet_reward(SessionProgression.OXYGEN_TANK_UPGRADE_COST + 700)
	_expect(bool(session.purchase_oxygen_tank_upgrade().get("purchased", false)), "oxygen tank fixture purchase failed")
	_expect(not profile.has_capability(ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID), "oxygen tank purchase granted pressure protection")
	var wallet_before := session.wallet()

	profile.complete_discovery(ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID, true)
	profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 1,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
		ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1,
	}, true)
	var fixture_world := FixtureWorld.new()
	fixture_world.projects = [project]
	var project_runtime := MaterialProjectRuntime.new(profile)
	project_runtime.on_map_loaded(fixture_world)
	_expect(project_runtime.status() == "incomplete", "short titanium recipe was not incomplete")
	_expect(project_runtime.debrief_lines() == ["Pressure suit project: Ti 1/2 | Rubber 1/1 | Gel 1/1"], "pressure recipe progress text drifted")
	var inventory_before := profile.material_inventory()
	var insufficient: Dictionary = project_runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(insufficient.get("reason") == "insufficient_materials", "insufficient pressure recipe did not fail atomically")
	_expect(profile.material_inventory() == inventory_before, "insufficient pressure build partially consumed materials")
	_expect(not profile.has_capability(ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID), "insufficient pressure build granted capability")

	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1}, true)
	_expect(project_runtime.status() == "ready", "exact pressure recipe did not ready project")
	_expect(project_runtime.debrief_lines() == ["P: Build pressure suit"], "pressure ready text drifted")
	var day := ExpeditionDayState.new()
	var daytime: Dictionary = project_runtime.try_build(day.phase)
	_expect(daytime.get("reason") == "wrong_phase", "pressure suit built during active day")
	day.end_day("manual")
	var completed: Dictionary = project_runtime.try_build(day.phase)
	_expect(bool(completed.get("changed", false)), "night debrief did not build pressure suit")
	_expect(profile.has_completed_project(ExpansionProfileState.PRESSURE_SUIT_PROJECT_ID), "pressure project completion was not recorded")
	_expect(profile.has_capability(ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID), "pressure capability was not granted atomically")
	_expect(profile.material_inventory().is_empty(), "pressure build did not consume exact Ti2 + Rubber1 + Gel1 recipe")
	_expect(session.wallet() == wallet_before and session.has_oxygen_tank_upgrade(), "pressure build changed score or oxygen purchase state")
	var repeated: Dictionary = project_runtime.try_build(day.phase)
	_expect(repeated.get("reason") == "already_completed", "repeat pressure build was not exact-once")

	day.begin_next_day()
	_expect(day.day_number == 2 and profile.has_capability(ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID), "day transition lost pressure capability")
	var reloaded := ExpansionProfileState.new(TEST_PATH, true)
	_expect(reloaded.load_profile().get("status") == "loaded", "pressure profile did not reload")
	_expect(reloaded.has_completed_discovery(ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID), "reload lost deep harmonic knowledge")
	_expect(reloaded.has_completed_project(ExpansionProfileState.PRESSURE_SUIT_PROJECT_ID), "reload lost pressure project")
	_expect(reloaded.has_capability(ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID), "reload lost pressure capability")

	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Pressure suit project state smoke failed: %s" % failure)
		quit(1)
		return
	print("Pressure suit project state smoke passed: source=production_level_01 knowledge=deep_harmonic recipe=Ti2+Rubber1+Gel1 debrief_only=true exact_once=true day_transition=true reload=true insufficient_atomic=true score_oxygen_independent=true.")
	quit(0)


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
