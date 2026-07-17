extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const ProgressionProjectTracker := preload("res://scripts/main/progression_project_tracker.gd")
const TEST_PATH := "user://oceangame2_material_project_test.json"
const SLICE_01 := "res://maps/production_slice_01.greybox.json"
const LEVEL_01 := "res://maps/production_level_01.greybox.json"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	_test_inconsistent_profiles()
	_test_cutter_blueprint_contract()
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
	_expect(source_report.get("project_id") == ExpansionProfileState.PROPULSION_FINS_PROJECT_ID and source_report.get("project_count") == 6, "fins were not the first source project")
	_expect(runtime.status() == "knowledge_required", "fresh fins project did not require its recovered blueprint")
	_expect(runtime.debrief_lines() == ["Propulsion fins project: fins blueprint required", "Access: east current pocket | Swim through"], "fins blueprint or access text drifted")
	var direct_fins: Dictionary = profile.unlock_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID, false)
	_expect(direct_fins.get("reason") == "project_transaction_required", "fins unlocked outside project transaction")
	var missing_fins_blueprint: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(missing_fins_blueprint.get("reason") == "missing_discovery", "missing fins blueprint did not block project")
	profile.complete_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID, true)
	_expect(runtime.status() == "incomplete", "blueprint-only fins project was not material-gated")
	var missing_fins_materials: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(missing_fins_materials.get("reason") == "insufficient_materials", "missing fins materials did not block project")
	profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	}, true)
	_expect(runtime.status() == "ready" and runtime.debrief_lines()[0] == "P: Build propulsion fins", "complete fins recipe did not become ready")
	var fins_wrong_phase: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_ACTIVE)
	_expect(fins_wrong_phase.get("reason") == "wrong_phase", "fins built outside night debrief")
	var fins_completed: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(fins_completed.get("changed", false)) and fins_completed.get("reason") == "completed", "ready fins project did not complete")
	_expect(profile.material_inventory().is_empty(), "fins did not consume the exact Ti2 + Rubber1 recipe")
	_expect(profile.has_completed_project(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID), "completed fins project was not recorded")
	_expect(profile.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID), "fins capability was not unlocked")
	_expect(runtime.debrief_lines() == ["Fins installed - east current passable", "Access: east current pocket | Swim through"], "completed fins debrief text drifted")
	var fins_repeated: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(fins_repeated.get("reason") == "already_completed" and profile.material_inventory().is_empty(), "repeat fins build was not idempotent")

	source_report = runtime.on_map_loaded(world)
	_expect(source_report.get("project_id") == ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID, "scanner was not the next source project after fins")
	_expect(runtime.status() == "knowledge_required", "fresh scanner project did not require its recovered blueprint")
	var direct_scanner: Dictionary = profile.unlock_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID, false)
	_expect(direct_scanner.get("reason") == "project_transaction_required", "scanner unlocked outside project transaction")
	profile.complete_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID, true)
	profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 1,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}, true)
	_expect(runtime.status() == "ready" and runtime.debrief_lines() == ["P: Build survey scanner", "Use: Q/SCAN near signal | Hold position to survey"], "scanner recipe did not become ready: %s" % str(runtime.debrief_lines()))
	var scanner_completed: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(scanner_completed.get("changed", false)) and scanner_completed.get("reason") == "completed", "ready scanner project did not complete")
	_expect(profile.material_inventory().is_empty(), "scanner did not consume the exact Ti1 + Coil1 recipe")
	_expect(profile.has_completed_project(ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID), "completed scanner project was not recorded")
	_expect(profile.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "scanner capability was not unlocked")

	source_report = runtime.on_map_loaded(world)
	_expect(source_report.get("project_id") == ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID, "source project was not loaded")
	_expect(runtime.status() == "knowledge_required", "fresh project did not require anomaly knowledge")
	_expect(runtime.debrief_lines() == ["Cutter project: salvage cutter plan required"], "knowledge gate text drifted")

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
	_test_shock_prod_project(profile, world)
	_test_capacitor_project(profile, world)

	var reloaded := ExpansionProfileState.new(TEST_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	_expect(reload_report.get("status") == "loaded", "legacy cutter profile did not reload cleanly")
	_expect(reloaded.has_completed_discovery(ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID), "legacy cutter migration omitted blueprint")
	_expect(reloaded.has_completed_project(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID), "profile reload lost fins project")
	_expect(reloaded.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID), "profile reload lost fins")
	_expect(reloaded.has_completed_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID), "profile reload lost fins blueprint")
	_expect(reloaded.has_completed_project(ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID), "profile reload lost scanner project")
	_expect(reloaded.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "profile reload lost scanner")
	_expect(reloaded.has_completed_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID), "profile reload lost scanner blueprint")
	_expect(reloaded.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID), "profile reload lost completed project")
	_expect(reloaded.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "profile reload lost cutter")
	_expect(reloaded.has_completed_project(ExpansionProfileState.SHOCK_PROD_PROJECT_ID), "profile reload lost shock prod project")
	_expect(reloaded.has_capability(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID), "profile reload lost shock prod")
	_expect(reloaded.has_completed_project(ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID), "profile reload lost capacitor project")
	_expect(reloaded.has_capability(ExpansionProfileState.SHOCK_PROD_CAPACITOR_CAPABILITY_ID), "profile reload lost capacitor")
	var day := ExpeditionDayState.new()
	day.begin_next_day()
	_expect(reloaded.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID), "next day lost durable fins")
	_expect(reloaded.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "next day lost durable scanner")
	_expect(reloaded.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "next day lost durable cutter")

	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Material project state smoke failed: %s" % failure)
		quit(1)
		return
	print("Material project state smoke passed: fins_blueprint_gate=true fins=Ti2+Rubber1 scanner_blueprint_gate=true scanner=Ti1+Coil1 scanner_persistent=true wallet_independent=true fins_persistent=true project=%s recipe=2_titanium+1_coil knowledge_gate=true debrief_only=true exact_once=true cutter_persistent=true shock_prod_non_enemy=true shock_prod_persistent=true capacitor_recipe=coil1+gel1+electrocyte1 capacitor_persistent=true migration=v1_to_v4 inconsistent_pair_rejected=true." % ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID)
	quit(0)


func _test_cutter_blueprint_contract() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var world = WORLD_SCENE.instantiate()
	world.map_path = LEVEL_01
	get_root().add_child(world)
	world.load_greybox()
	var runtime := MaterialProjectRuntime.new(profile)
	runtime.on_map_loaded(world)
	for project_id in [ExpansionProfileState.PROPULSION_FINS_PROJECT_ID, ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID]:
		var project: Dictionary = runtime.project_definition_for(project_id)
		profile.complete_discovery(str(project.get("required_discovery_id", "")), false)
		var recipe := {}
		for material_id in project.get("required_materials", {}):
			recipe[str(material_id)] = int(project["required_materials"][material_id])
		profile.deposit_materials(recipe, false)
		var prerequisite: Dictionary = profile.complete_material_project(project, false)
		_expect(bool(prerequisite.get("changed", false)), "blueprint fixture could not complete prerequisite %s: %s" % [project_id, str(prerequisite)])
	runtime.on_map_loaded(world)
	_expect(runtime.status_for(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID) == "knowledge_required", "fresh cutter project did not require its blueprint")
	_expect(runtime.status() == "unavailable" and runtime.debrief_lines().is_empty(), "cutter project guidance appeared before blueprint commitment")
	_expect(runtime.active_day_build_feedback().find("Cutter") == -1, "daytime feedback named cutter before blueprint commitment")
	var tracker := ProgressionProjectTracker.new()
	get_root().add_child(tracker)
	tracker.refresh(runtime.report(), {}, false)
	_expect(not tracker.visible, "cutter recipe tracker appeared before blueprint commitment")
	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false)
	_expect(runtime.status() == "unavailable" and not runtime.has_cutter_blueprint(), "generic anomaly knowledge exposed the cutter project")
	_expect(runtime.shock_prod_guidance().find("survey lower-right anomaly first") != -1, "contextual shock guidance exposed the optional recipe before discovery")
	_expect(runtime.debrief_lines()[0].find("required") != -1 and runtime.debrief_lines()[0].find("Ti ") == -1, "optional project exposed cutter recipe before blueprint")
	var reward: Dictionary = profile.complete_discovery_reward(
		ExpansionProfileState.ANOMALY_DISCOVERY_ID,
		ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID,
		false
	)
	_expect(bool(reward.get("changed", false)) and runtime.has_cutter_blueprint(), "committed artifact did not grant cutter blueprint")
	_expect(runtime.project_definition().get("id") == ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID, "optional project preempted committed cutter blueprint")
	tracker.refresh(runtime.report(), {}, false)
	_expect(tracker.visible and tracker.snapshot_text().find("Titanium  0/2") != -1 and tracker.snapshot_text().find("Coil  0/1") != -1, "committed blueprint did not expose Ti2/Coil1 tracker")
	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 2, ExpansionProfileState.COIL_MATERIAL_ID: 1}, false)
	tracker.refresh(runtime.report(), {}, false)
	_expect(runtime.status() == "ready" and tracker.snapshot_text().find("Ready") != -1, "exact cutter recipe did not ready tracker")
	_expect(runtime.try_build(ExpeditionDayState.PHASE_ACTIVE).get("reason") == "wrong_phase", "cutter built during active day")
	var built: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(built.get("changed", false)) and runtime.has_cutter(), "blueprint-backed cutter did not build at night")
	tracker.refresh(runtime.report(), {}, false)
	_expect(not tracker.visible, "cutter tracker remained after exact-once build")
	_expect(runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF).get("reason") == "already_completed", "cutter repeat build was not exact-once")
	tracker.queue_free()
	world.queue_free()


func _test_shock_prod_project(profile, world) -> void:
	var shock_runtime := MaterialProjectRuntime.new(profile)
	shock_runtime.on_map_loaded(world)
	shock_runtime.shock_prod_guidance()
	_expect(shock_runtime.project_definition().get("id") == ExpansionProfileState.SHOCK_PROD_PROJECT_ID, "shock prod was not next after cutter")
	var direct_unlock: Dictionary = profile.unlock_capability(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID, false)
	_expect(direct_unlock.get("reason") == "project_transaction_required", "shock prod unlocked outside project transaction")
	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 2, ExpansionProfileState.COIL_MATERIAL_ID: 1}, true)
	var shock_definition := {
		"id": ExpansionProfileState.SHOCK_PROD_PROJECT_ID,
		"required_project_id": ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID,
		"required_discovery_id": ExpansionProfileState.ANOMALY_DISCOVERY_ID,
		"required_materials": {ExpansionProfileState.TITANIUM_MATERIAL_ID: 2, ExpansionProfileState.COIL_MATERIAL_ID: 1},
		"unlocks_capability_id": ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID,
		"target_hostile_id": ExpansionProfileState.SHOCK_PROD_TARGET_ID,
		"build_phase": "night_debrief",
	}
	var shock_result: Dictionary = shock_runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(shock_result.get("changed", false)), "non-enemy shock prod project did not complete")
	_expect(profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID), "shock prod capability was not unlocked")
	_expect(profile.material_inventory().is_empty(), "shock prod recipe did not consume exact materials")
	var repeated: Dictionary = profile.complete_material_project(shock_definition, true)
	_expect(repeated.get("reason") == "already_completed", "shock prod repeat build was not idempotent")


func _test_capacitor_project(profile, world) -> void:
	var direct_unlock: Dictionary = profile.unlock_capability(ExpansionProfileState.SHOCK_PROD_CAPACITOR_CAPABILITY_ID, false)
	_expect(direct_unlock.get("reason") == "project_transaction_required", "capacitor unlocked outside project transaction")
	var runtime := MaterialProjectRuntime.new(profile)
	runtime.on_map_loaded(world)
	_expect(runtime.project_definition().get("id") == ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID, "capacitor was not the next source-ordered project")
	_expect(runtime.status() == "incomplete" and runtime.debrief_lines()[0].find("Gel 0/1") != -1, "capacitor did not report its biological recipe")
	var recipe := {
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
		ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1,
		ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID: 1,
	}
	profile.deposit_materials(recipe, true)
	_expect(runtime.status() == "ready", "banked biological recipe did not ready the capacitor")
	var completed: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(completed.get("changed", false)), "capacitor project did not complete")
	_expect(profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPACITOR_CAPABILITY_ID), "capacitor capability was not unlocked")
	_expect(profile.material_inventory().is_empty(), "capacitor project did not spend the exact recipe")
	var repeated: Dictionary = runtime.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	_expect(repeated.get("reason") == "already_completed", "capacitor repeat build was not idempotent")


func _test_inconsistent_profiles() -> void:
	for payload in [
		_profile_payload_v3([], [ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID]),
		_profile_payload_v3([ExpansionProfileState.PROPULSION_FINS_PROJECT_ID], []),
	]:
		_write_profile(payload)
		var fins_profile := ExpansionProfileState.new(TEST_PATH)
		_expect(fins_profile.load_profile().get("status") == "invalid_schema", "inconsistent fins/project pair was accepted")
	for payload in [
		_profile_payload([], [ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID]),
		_profile_payload([ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID], []),
	]:
		_write_profile(payload)
		var profile := ExpansionProfileState.new(TEST_PATH)
		_expect(profile.load_profile().get("status") == "invalid_schema", "inconsistent cutter/project pair was accepted")
	for payload in [
		_profile_payload_v3([ExpansionProfileState.SHOCK_PROD_PROJECT_ID], [ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID]),
		_profile_payload_v3([ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID, ExpansionProfileState.SHOCK_PROD_PROJECT_ID], [ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID]),
		_profile_payload_v3([ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID], [ExpansionProfileState.SHOCK_PROD_CAPACITOR_CAPABILITY_ID]),
	]:
		_write_profile(payload)
		var shock_profile := ExpansionProfileState.new(TEST_PATH)
		_expect(shock_profile.load_profile().get("status") == "invalid_schema", "invalid shock prod project chain/pair was accepted")


func _profile_payload(projects: Array, capabilities: Array) -> Dictionary:
	return {
		"schema_version": 2,
		"completed_discoveries": [ExpansionProfileState.ANOMALY_DISCOVERY_ID],
		"unlocked_capabilities": capabilities,
		"material_inventory": {},
		"completed_projects": projects,
	}


func _profile_payload_v3(projects: Array, capabilities: Array) -> Dictionary:
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
