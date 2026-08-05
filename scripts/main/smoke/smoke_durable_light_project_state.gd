extends SceneTree

const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const ProgressionRuntimeController := preload("res://scripts/main/progression_runtime_controller.gd")
const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")
const SessionProgression := preload("res://scripts/main/session_progression.gd")

const TEST_PATH := "user://oceangame2_durable_light_test.json"
const PAIR_PATH := "user://oceangame2_durable_light_pair_test.json"
const ROLLBACK_PATH := "user://oceangame2_durable_light_write_block"

var _failures: Array[String] = []


class FixtureWorld:
	extends RefCounted
	var map_id := "fixture_map"
	var projects: Array[Dictionary] = []
	var light_capability_id := ""
	var light_enabled := false

	func get_material_projects() -> Array[Dictionary]:
		return projects

	func is_inside_extraction(_position: Vector2) -> bool:
		return true

	func set_visibility_upgrade_state(capability_id: String, enabled: bool) -> void:
		light_capability_id = capability_id
		light_enabled = enabled


class FixturePlayer:
	extends RefCounted
	var global_position := Vector2.ZERO
	var light_range_scale := 0.0
	var light_alpha := 0.0

	func apply_light_profile(range_scale: float, alpha: float) -> void:
		light_range_scale = range_scale
		light_alpha = alpha


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_file(TEST_PATH)
	_cleanup_file(PAIR_PATH)
	_cleanup_rollback_path()
	var project := ReviewProgressionFixture.dive_light_project_definition()
	var profile := ExpansionProfileState.new(TEST_PATH, true)
	_expect(profile.load_profile().get("status") == "missing", "fresh durable-light profile did not start missing")
	_expect(not profile.has_capability(ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID), "fresh profile auto-granted dive light")
	var direct_unlock: Dictionary = profile.unlock_capability(ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID, false)
	_expect(direct_unlock.get("reason") == "project_transaction_required", "dive light unlocked outside its project transaction")
	var missing_knowledge: Dictionary = profile.complete_material_project(project, false)
	_expect(missing_knowledge.get("reason") == "missing_discovery", "Signal Reef knowledge did not gate dive light")

	var session := SessionProgression.new()
	session.grant_wallet_reward(900)
	var progression := ProgressionRuntimeController.new(session)
	progression.set_profile_state(profile)
	var world := FixtureWorld.new()
	var player := FixturePlayer.new()
	var blocked_purchase: Dictionary = progression.try_purchase(ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID, world, player)
	_expect(not bool(blocked_purchase.get("purchased", false)), "legacy score path purchased dive light")
	_expect(blocked_purchase.get("note") == "Build dive light at night", "legacy score path did not direct player to night project")
	_expect(session.wallet() == 900, "blocked light purchase changed session wallet")

	profile.complete_discovery(ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID, true)
	profile.deposit_materials(_light_recipe(), true)
	world.projects = [_blocked_fins_project(), project]
	var project_runtime := MaterialProjectRuntime.new(profile)
	var source_report: Dictionary = project_runtime.on_map_loaded(world)
	_expect(source_report.get("project_id") == ExpansionProfileState.DIVE_LIGHT_PROJECT_ID, "ready light project was hidden behind unrelated source order")
	_expect(project_runtime.status() == "ready", "exact light recipe did not ready project")
	var daytime: Dictionary = project_runtime.try_build(ExpeditionDayState.PHASE_ACTIVE)
	_expect(daytime.get("reason") == "wrong_phase", "daytime input built durable light")
	var completed: Dictionary = project_runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(completed.get("changed", false)), "night debrief did not build ready light project")
	_expect(profile.has_completed_project(ExpansionProfileState.DIVE_LIGHT_PROJECT_ID), "light project completion was not recorded")
	_expect(profile.has_capability(ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID), "light capability was not unlocked atomically")
	_expect(profile.material_inventory().is_empty(), "light build did not consume exact Ti1 + Coil1 + Gel1 recipe")
	_expect(session.wallet() == 900 and not session.has_oxygen_tank_upgrade() and not session.has_cargo_capacity_upgrade(), "light build changed unrelated session progression")
	var repeated: Dictionary = project_runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(repeated.get("reason") == "already_completed" and profile.material_inventory().is_empty(), "repeat light build was not idempotent")

	progression.apply_light_profile(world, player)
	_expect(progression.has_light_upgrade(), "profile-backed compatibility getter did not see durable light")
	_expect(world.light_capability_id == ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID and world.light_enabled, "world visibility did not receive durable light")
	_expect(is_equal_approx(player.light_range_scale, 1.25) and is_equal_approx(player.light_alpha, 0.48), "player light profile did not receive upgraded values")

	var reloaded := ExpansionProfileState.new(TEST_PATH, true)
	_expect(reloaded.load_profile().get("status") == "loaded", "durable light profile did not reload")
	_expect(reloaded.has_completed_project(ExpansionProfileState.DIVE_LIGHT_PROJECT_ID), "reload lost completed light project")
	_expect(reloaded.has_capability(ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID), "reload lost durable light capability")
	_test_pair_validation()
	_test_storage_rollback(project)

	_cleanup_file(TEST_PATH)
	_cleanup_file(PAIR_PATH)
	_cleanup_rollback_path()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Durable light project state smoke failed: %s" % failure)
		quit(1)
		return
	print("Durable light project state smoke passed: owner=profile project=dive_light_1_project knowledge=signal_reef recipe=Ti1+Coil1+Gel1 debrief_only=true exact_once=true reload=true rollback=true wallet_independent=true.")
	quit(0)


func _test_pair_validation() -> void:
	for payload in [
		_profile_payload([], [ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID]),
		_profile_payload([ExpansionProfileState.DIVE_LIGHT_PROJECT_ID], []),
	]:
		_write_payload(PAIR_PATH, payload)
		var profile := ExpansionProfileState.new(PAIR_PATH, true)
		_expect(profile.load_profile().get("status") == "invalid_schema", "inconsistent light project/capability pair was accepted")


func _test_storage_rollback(project: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROLLBACK_PATH))
	var profile := ExpansionProfileState.new(ROLLBACK_PATH, true)
	profile.complete_discovery(ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID, false)
	profile.deposit_materials(_light_recipe(), false)
	var before := profile.material_inventory()
	var result: Dictionary = profile.complete_material_project(project, true)
	_expect(result.get("reason") == "storage_error", "forced light save failure did not report storage_error")
	_expect(profile.material_inventory() == before, "failed light save did not restore materials")
	_expect(not profile.has_completed_project(ExpansionProfileState.DIVE_LIGHT_PROJECT_ID), "failed light save retained completed project")
	_expect(not profile.has_capability(ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID), "failed light save retained capability")


func _light_recipe() -> Dictionary:
	return {
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 1,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
		ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1,
	}


func _blocked_fins_project() -> Dictionary:
	return {
		"id": ExpansionProfileState.PROPULSION_FINS_PROJECT_ID,
		"required_discovery_id": ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID,
		"required_materials": {ExpansionProfileState.TITANIUM_MATERIAL_ID: 2, ExpansionProfileState.RUBBER_MATERIAL_ID: 1},
		"unlocks_capability_id": ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID,
		"target_gate_id": ExpansionProfileState.PROPULSION_FINS_GATE_ID,
		"build_phase": "night_debrief",
	}


func _profile_payload(projects: Array, capabilities: Array) -> Dictionary:
	return {
		"schema_version": ExpansionProfileState.SCHEMA_VERSION,
		"completed_discoveries": [ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID],
		"unlocked_capabilities": capabilities,
		"material_inventory": {},
		"completed_projects": projects,
		"banked_tool_target_ids": [],
		"companion_profile": CompanionProfileState.new().payload(),
	}


func _write_payload(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write profile fixture %s" % path)
		return
	file.store_string(JSON.stringify(payload))
	file.close()


func _cleanup_file(path: String) -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var candidate := "%s%s" % [path, suffix]
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _cleanup_rollback_path() -> void:
	_cleanup_file(ROLLBACK_PATH)
	var absolute := ProjectSettings.globalize_path(ROLLBACK_PATH)
	if DirAccess.dir_exists_absolute(absolute):
		DirAccess.remove_absolute(absolute)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
