extends RefCounted

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const ProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const LEGACY_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const CANONICAL_MAP_PATH := "res://maps/production_level_01.greybox.json"
const PROFILE_PATH := "user://oceangame2_expansion_14_legacy_profile_smoke.json"


func run(tree: SceneTree) -> Dictionary:
	_cleanup_profile()
	var failures: Array[String] = []
	var profile := ProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	var legacy_world = await _load_world(tree, LEGACY_MAP_PATH)
	var legacy_runtime := MaterialProjectRuntime.new(profile)
	legacy_runtime.on_map_loaded(legacy_world)
	_complete_project(profile, legacy_runtime, ProfileState.CURRENT_STABILIZER_PROJECT_ID, failures)
	if failures.is_empty() and not profile.save_profile():
		failures.append("legacy stabilizer profile did not save")
	legacy_world.free()

	var reloaded := ProfileState.new(PROFILE_PATH, true)
	var load_report: Dictionary = reloaded.load_profile()
	var canonical_world = await _load_world(tree, CANONICAL_MAP_PATH)
	var canonical_runtime := MaterialProjectRuntime.new(reloaded)
	canonical_runtime.on_map_loaded(canonical_world)
	var profile_report: Dictionary = reloaded.report()
	var canonical_count := _project_count(canonical_world, ProfileState.CURRENT_STABILIZER_PROJECT_ID)
	var legacy_project_count := _project_count_from_runtime(legacy_runtime, ProfileState.CURRENT_STABILIZER_PROJECT_ID)

	_expect(load_report.get("status") == "loaded", "legacy stabilizer profile did not reload", failures)
	_expect(reloaded.has_completed_project(ProfileState.CURRENT_STABILIZER_PROJECT_ID), "legacy project completion was lost", failures)
	_expect(reloaded.has_capability(ProfileState.CURRENT_STABILIZER_CAPABILITY_ID), "legacy capability was lost", failures)
	_expect(not reloaded.has_completed_discovery(ProfileState.SOUTHEAST_WRECK_DISCOVERY_ID), "legacy profile was forced to own the archive discovery", failures)
	_expect(canonical_runtime.status_for(ProfileState.CURRENT_STABILIZER_PROJECT_ID) == "completed", "canonical map downgraded the legacy completed profile", failures)
	_expect(legacy_project_count == 1 and canonical_count == 1, "project source ownership was duplicated", failures)
	_expect(profile_report.get("completed_projects", []).count(ProfileState.CURRENT_STABILIZER_PROJECT_ID) == 1, "profile duplicated the stabilizer project", failures)
	_expect(profile_report.get("unlocked_capabilities", []).count(ProfileState.CURRENT_STABILIZER_CAPABILITY_ID) == 1, "profile duplicated the stabilizer capability", failures)

	canonical_world.free()
	_cleanup_profile()
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"legacy_project_count": legacy_project_count,
		"canonical_project_count": canonical_count,
		"archive_required_for_legacy": reloaded.has_completed_discovery(ProfileState.SOUTHEAST_WRECK_DISCOVERY_ID),
	}


func _complete_project(profile, runtime, project_id: String, failures: Array[String]) -> void:
	if profile.has_completed_project(project_id) or not failures.is_empty():
		return
	var project: Dictionary = runtime.project_definition_for(project_id)
	if project.is_empty():
		failures.append("missing legacy project %s" % project_id)
		return
	var prerequisite_id := str(project.get("required_project_id", ""))
	if not prerequisite_id.is_empty():
		_complete_project(profile, runtime, prerequisite_id, failures)
	var discovery_id := str(project.get("required_discovery_id", ""))
	if not discovery_id.is_empty() and not profile.has_completed_discovery(discovery_id):
		var discovery: Dictionary = profile.complete_discovery(discovery_id, false)
		if not bool(discovery.get("changed", false)):
			failures.append("could not prepare legacy discovery %s" % discovery_id)
			return
	var missing := {}
	for material_id in project.get("required_materials", {}):
		var quantity: int = int(project.get("required_materials", {})[material_id]) - profile.material_quantity(str(material_id))
		if quantity > 0:
			missing[str(material_id)] = quantity
	if not missing.is_empty() and not bool(profile.deposit_materials(missing, false).get("changed", false)):
		failures.append("could not prepare legacy recipe for %s" % project_id)
		return
	var completion: Dictionary = profile.complete_material_project(project, false)
	if not bool(completion.get("changed", false)):
		failures.append("could not complete legacy project %s: %s" % [project_id, completion])


func _load_world(tree: SceneTree, map_path: String):
	var world = WORLD_SCENE.instantiate()
	world.map_path = map_path
	tree.root.add_child.call_deferred(world)
	await tree.process_frame
	world.load_greybox()
	return world


func _project_count(world, project_id: String) -> int:
	var count := 0
	for project in world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			count += 1
	return count


func _project_count_from_runtime(runtime, project_id: String) -> int:
	return 1 if not runtime.project_definition_for(project_id).is_empty() else 0


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
