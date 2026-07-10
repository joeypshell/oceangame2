extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const TEST_PATH := "user://oceangame2_material_runtime_test.json"
const SLICE_01 := "res://maps/production_slice_01.greybox.json"
const SLICE_04 := "res://maps/production_slice_04.greybox.json"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	_test_profile_migration()
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var runtime := MaterialRuntimeController.new(profile)
	var day := ExpeditionDayState.new()
	var world = _build_world(SLICE_01)
	runtime.on_map_loaded(world, day)
	var day_one: Dictionary = world.get_material_candidate_report()
	var day_one_ids: Array = day_one.get("active_ids", [])
	_expect(day_one_ids.size() == 3, "day one did not select the exact 2 titanium + 1 coil set")
	_expect(_selected_material_count(world, day_one_ids, ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2, "day one titanium guarantee failed")
	_expect(_selected_material_count(world, day_one_ids, ExpansionProfileState.COIL_MATERIAL_ID) == 1, "day one coil guarantee failed")
	runtime.on_map_loaded(world, day)
	_expect(world.get_material_candidate_report().get("active_ids", []) == day_one_ids, "same-day reload rerolled candidates")

	var first := _candidate(world, str(day_one_ids[0]))
	var second := _candidate(world, str(day_one_ids[1]))
	var third := _candidate(world, str(day_one_ids[2]))
	_expect(bool(runtime.update_collection(world, first["center"], 48.0, day, 0, 2).get("changed", false)), "first material did not collect")
	_expect(bool(runtime.update_collection(world, second["center"], 48.0, day, 0, 2).get("changed", false)), "second material did not collect")
	var blocked: Dictionary = runtime.update_collection(world, third["center"], 48.0, day, 0, 2)
	_expect(bool(blocked.get("blocked", false)) and runtime.held_count() == 2, "shared cargo capacity did not block third material")
	_expect(not world.get_material_candidate_near(third["center"], 48.0).is_empty(), "cargo-full block deleted the material target")
	var restored: Dictionary = runtime.restore_unbanked(world, day, "test_failure")
	_expect(restored.get("restored_count") == 2 and runtime.held_count() == 0, "failure did not clear and restore held materials")
	_expect(day.material_depleted_ids("production_slice_01").is_empty(), "failure retained same-day depletion")

	_expect(bool(runtime.update_collection(world, first["center"], 48.0, day, 0, 2).get("changed", false)), "material did not recollect after restoration")
	var relay = _build_world(SLICE_04)
	var relay_commit: Dictionary = runtime.try_commit_at_boat(relay, relay.get_extraction_center())
	_expect(relay_commit.is_empty() and runtime.held_count() == 1, "relay extraction committed typed material")
	runtime.on_map_loaded(world, day)
	_expect(runtime.held_count() == 1, "map reload or connector-style transition cleared held material")
	var boat_commit: Dictionary = runtime.try_commit_at_boat(world, world.get_extraction_center())
	_expect(bool(boat_commit.get("changed", false)) and runtime.held_count() == 0, "canonical boat did not commit material")
	var first_material := str(first.get("material_id", ""))
	_expect(profile.material_quantity(first_material) == 1, "canonical boat deposit did not reach profile inventory")
	runtime.on_map_loaded(world, day)
	_expect(day.material_depleted_ids("production_slice_01").has(str(first.get("id", ""))), "same-day reload respawned banked candidate")
	_expect(world.get_material_candidate_report().get("depleted_ids", []).has(str(first.get("id", ""))), "world did not hide same-day banked candidate")

	day.begin_next_day()
	runtime.on_map_loaded(world, day)
	var day_two_ids: Array = world.get_material_candidate_report().get("active_ids", [])
	_expect(day_two_ids.size() == 3 and day_two_ids != day_one_ids, "next day did not rotate to a different valid set")
	_expect(_selected_material_count(world, day_two_ids, ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2, "day two titanium guarantee failed")
	_expect(_selected_material_count(world, day_two_ids, ExpansionProfileState.COIL_MATERIAL_ID) == 1, "day two coil guarantee failed")

	world.queue_free()
	relay.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Material runtime state smoke failed: %s" % failure)
		quit(1)
		return
	print("Material runtime state smoke passed: day1=%s day2=%s held_capacity=2 failure_restored=2 relay_commit=false boat_commit=true profile_material=%s migration=v1_to_v2." % [
		str(day_one_ids),
		str(day_two_ids),
		first_material,
	])
	quit(0)


func _test_profile_migration() -> void:
	_write_profile({
		"schema_version": 2,
		"completed_discoveries": [],
		"unlocked_capabilities": [],
		"material_inventory": {ExpansionProfileState.TITANIUM_MATERIAL_ID: 1.5},
		"completed_projects": [],
	})
	var invalid := ExpansionProfileState.new(TEST_PATH)
	_expect(invalid.load_profile().get("status") == "invalid_schema", "fractional profile material was accepted")
	_write_profile({
		"schema_version": 1,
		"completed_discoveries": [ExpansionProfileState.ANOMALY_DISCOVERY_ID],
		"unlocked_capabilities": [ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID],
	})
	var migrated := ExpansionProfileState.new(TEST_PATH)
	var report: Dictionary = migrated.load_profile()
	_expect(report.get("status") == "migrated_v1", "valid v1 profile did not migrate in memory")
	_expect(migrated.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID), "migration lost discovery")
	_expect(migrated.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "migration lost scanner")
	var deposit: Dictionary = migrated.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1}, true)
	_expect(bool(deposit.get("changed", false)), "migrated profile could not deposit material")
	var reloaded := ExpansionProfileState.new(TEST_PATH)
	report = reloaded.load_profile()
	_expect(report.get("status") == "loaded" and report.get("schema_version") == 2, "migrated profile did not persist as v2: %s" % str(report))
	_expect(reloaded.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 1, "v2 reload lost material: %s" % str(report))


func _build_world(path: String):
	var world = WORLD_SCENE.instantiate()
	world.map_path = path
	get_root().add_child(world)
	world.load_greybox()
	return world


func _candidate(world, candidate_id: String) -> Dictionary:
	for candidate in world.get_material_candidates():
		if str(candidate.get("id", "")) == candidate_id:
			return candidate
	_failures.append("missing candidate %s" % candidate_id)
	return {"id": candidate_id, "center": Vector2.ZERO, "material_id": "missing"}


func _selected_material_count(world, selected_ids: Array, material_id: String) -> int:
	var count := 0
	for candidate in world.get_material_candidates():
		if selected_ids.has(str(candidate.get("id", ""))) and str(candidate.get("material_id", "")) == material_id:
			count += int(candidate.get("material_quantity", 0))
	return count


func _write_profile(payload: Dictionary) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write migration fixture")
		return
	file.store_string(JSON.stringify(payload))
	file.close()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
