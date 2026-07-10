extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const TEST_PATH := "user://oceangame2_material_project_test.json"
const SLICE_01 := "res://maps/production_slice_01.greybox.json"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	_test_inconsistent_profiles()
	_write_profile({
		"schema_version": 1,
		"completed_discoveries": [],
		"unlocked_capabilities": [],
	})
	var profile := ExpansionProfileState.new(TEST_PATH)
	_expect(profile.load_profile().get("status") == "migrated_v1", "v1 project profile did not migrate")
	var world = WORLD_SCENE.instantiate()
	world.map_path = SLICE_01
	get_root().add_child(world)
	world.load_greybox()
	var runtime := MaterialProjectRuntime.new(profile)
	var source_report: Dictionary = runtime.on_map_loaded(world)
	_expect(source_report.get("project_id") == ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID, "source project was not loaded")
	_expect(runtime.status() == "knowledge_required", "fresh project did not require anomaly knowledge")
	_expect(runtime.debrief_lines() == ["Cutter project: anomaly knowledge required"], "knowledge gate text drifted")

	var direct_unlock: Dictionary = profile.unlock_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID, false)
	_expect(direct_unlock.get("reason") == "project_transaction_required", "cutter unlocked outside project transaction")
	var missing_knowledge: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(missing_knowledge.get("reason") == "missing_discovery", "missing knowledge did not block project")
	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, true)
	_expect(runtime.status() == "incomplete", "knowledge-only profile did not report incomplete materials")
	var insufficient: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(insufficient.get("reason") == "insufficient_materials", "insufficient materials did not block project")
	profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}, true)
	_expect(runtime.status() == "ready" and runtime.debrief_lines() == ["P: Build salvage cutter"], "complete recipe did not become ready")
	var debrief_day := ExpeditionDayState.new()
	debrief_day.end_day("voluntary")
	_expect(ExpeditionDayDebrief.build_text(debrief_day, runtime).find("P: Build salvage cutter") != -1, "ready project was absent from debrief text")
	var wrong_phase: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_ACTIVE)
	_expect(wrong_phase.get("reason") == "wrong_phase", "project built outside night debrief")

	var completed: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(completed.get("changed", false)) and completed.get("reason") == "completed", "ready project did not complete")
	_expect(profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 0, "project did not consume exact titanium")
	_expect(profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 0, "project did not consume exact coil")
	_expect(profile.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID), "completed project was not recorded")
	_expect(profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "cutter capability was not unlocked")
	_expect(runtime.debrief_lines() == ["Salvage cutter built"], "completed debrief text drifted")
	_expect(ExpeditionDayDebrief.build_text(debrief_day, runtime).find("Salvage cutter built") != -1, "completed project was absent from debrief text")
	var repeated: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(not bool(repeated.get("changed", true)) and repeated.get("reason") == "already_completed", "repeat build was not idempotent")
	_expect(profile.material_inventory().is_empty(), "repeat build changed material inventory")

	var reloaded := ExpansionProfileState.new(TEST_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	_expect(reload_report.get("status") == "loaded", "completed project profile did not reload")
	_expect(reloaded.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID), "profile reload lost completed project")
	_expect(reloaded.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "profile reload lost cutter")
	var day := ExpeditionDayState.new()
	day.begin_next_day()
	_expect(reloaded.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "next day lost durable cutter")

	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Material project state smoke failed: %s" % failure)
		quit(1)
		return
	print("Material project state smoke passed: project=%s recipe=2_titanium+1_coil knowledge_gate=true debrief_only=true exact_once=true cutter_persistent=true migration=v1_to_v3 inconsistent_pair_rejected=true." % ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID)
	quit(0)


func _test_inconsistent_profiles() -> void:
	for payload in [
		_profile_payload([], [ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID]),
		_profile_payload([ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID], []),
	]:
		_write_profile(payload)
		var profile := ExpansionProfileState.new(TEST_PATH)
		_expect(profile.load_profile().get("status") == "invalid_schema", "inconsistent cutter/project pair was accepted")


func _profile_payload(projects: Array, capabilities: Array) -> Dictionary:
	return {
		"schema_version": 2,
		"completed_discoveries": [ExpansionProfileState.ANOMALY_DISCOVERY_ID],
		"unlocked_capabilities": capabilities,
		"material_inventory": {},
		"completed_projects": projects,
	}


func _write_profile(payload: Dictionary) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write project profile fixture")
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
