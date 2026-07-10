extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const TEST_PATH := "user://oceangame2_current_stabilizer_project_test.json"
const SLICE_01 := "res://maps/production_slice_01.greybox.json"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	_test_invalid_schema_v3_profiles()
	_write_profile(_schema_v2_cutter_profile())
	var profile := ExpansionProfileState.new(TEST_PATH)
	var migration: Dictionary = profile.load_profile()
	_expect(migration.get("status") == "migrated_v2", "schema-v2 cutter profile did not migrate")
	_expect(profile.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID), "migration lost cutter project")
	_expect(profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "migration lost cutter capability")

	var world = WORLD_SCENE.instantiate()
	world.map_path = SLICE_01
	get_root().add_child(world)
	world.load_greybox()
	var runtime := MaterialProjectRuntime.new(profile)
	var source_report: Dictionary = runtime.on_map_loaded(world)
	_expect(source_report.get("project_ids") == [ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID, ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID, ExpansionProfileState.SHOCK_PROD_PROJECT_ID, ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID], "source catalog did not load four ordered projects")
	_expect(source_report.get("project_id") == ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID, "catalog did not select stabilizer after cutter")
	_expect(runtime.status() == "ready", "migrated cutter profile and exact recipe did not ready stabilizer")
	_expect(runtime.debrief_lines() == ["P: Build current stabilizer"], "stabilizer ready text drifted")
	var prerequisite_profile := ExpansionProfileState.new("", false)
	prerequisite_profile.load_profile()
	prerequisite_profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false)
	prerequisite_profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}, false)
	var missing_project: Dictionary = prerequisite_profile.complete_material_project(
		runtime.project_definition_for(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID),
		false
	)
	_expect(missing_project.get("reason") == "missing_project", "stabilizer did not enforce cutter project prerequisite")

	var direct_unlock: Dictionary = profile.unlock_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID, false)
	_expect(direct_unlock.get("reason") == "project_transaction_required", "stabilizer unlocked outside project transaction")
	var wrong_phase: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_ACTIVE)
	_expect(wrong_phase.get("reason") == "wrong_phase", "stabilizer built outside night debrief")

	var completed: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(completed.get("changed", false)) and completed.get("reason") == "completed", "ready stabilizer did not complete")
	_expect(profile.material_inventory().is_empty(), "stabilizer did not consume the exact recipe")
	_expect(profile.has_completed_project(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID), "stabilizer project was not recorded")
	_expect(profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID), "stabilizer capability was not recorded")
	_expect(runtime.debrief_lines() == ["Current stabilizer built"], "stabilizer completion text drifted")
	var repeated: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(not bool(repeated.get("changed", true)) and repeated.get("reason") == "already_completed", "repeat stabilizer build was not idempotent")

	var reloaded := ExpansionProfileState.new(TEST_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	_expect(reload_report.get("status") == "loaded", "schema-v3 stabilizer profile did not reload")
	_expect(reloaded.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID), "reload lost cutter prerequisite")
	_expect(reloaded.has_completed_project(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID), "reload lost stabilizer project")
	_expect(reloaded.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID), "reload lost stabilizer capability")
	var next_runtime := MaterialProjectRuntime.new(reloaded)
	var next_report: Dictionary = next_runtime.on_map_loaded(world)
	_expect(next_runtime.status_for(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID) == "completed", "next-day catalog did not retain completed stabilizer")
	_expect(next_report.get("project_id") == ExpansionProfileState.SHOCK_PROD_PROJECT_ID and next_runtime.status() == "incomplete", "next-day catalog did not advance to the unbuilt shock prod")

	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Current stabilizer project smoke failed: %s" % failure)
		quit(1)
		return
	print("Current stabilizer project state smoke passed: schema=v2_to_v3 projects=cutter>stabilizer>shock_prod>capacitor prerequisite=true recipe=2_titanium+1_coil night_only=true exact_once=true rollback_path=preserved profile_reload=true.")
	quit(0)


func _test_invalid_schema_v3_profiles() -> void:
	var invalid_payloads := [
		_profile_payload(
			[ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID],
			[ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID, ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID]
		),
		_profile_payload(
			[ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID],
			[ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID]
		),
	]
	for payload in invalid_payloads:
		_write_profile(payload)
		var profile := ExpansionProfileState.new(TEST_PATH)
		_expect(profile.load_profile().get("status") == "invalid_schema", "invalid stabilizer profile was accepted")


func _schema_v2_cutter_profile() -> Dictionary:
	return {
		"schema_version": 2,
		"completed_discoveries": [ExpansionProfileState.ANOMALY_DISCOVERY_ID],
		"unlocked_capabilities": [ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID],
		"material_inventory": {
			ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
			ExpansionProfileState.COIL_MATERIAL_ID: 1,
		},
		"completed_projects": [ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID],
	}


func _profile_payload(projects: Array, capabilities: Array) -> Dictionary:
	return {
		"schema_version": 3,
		"completed_discoveries": [ExpansionProfileState.ANOMALY_DISCOVERY_ID],
		"unlocked_capabilities": capabilities,
		"material_inventory": {},
		"completed_projects": projects,
	}


func _write_profile(payload: Dictionary) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write stabilizer profile fixture")
		return
	file.store_string(JSON.stringify(payload))
	file.close()


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
