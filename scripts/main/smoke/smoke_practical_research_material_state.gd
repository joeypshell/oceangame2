extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialCandidateSelector := preload("res://scripts/main/material_candidate_selector.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")

const MAP_PATH := "res://maps/production_slice_01.greybox.json"
const MAP_ID := "production_slice_01"
const COIL_POOL_ID := "conductive_coil_pool"
const RESEARCHED_CANDIDATE_ID := "material_coil_deep_cache"
const NORMAL_DAY_THREE_CANDIDATE_ID := "material_coil_deep_approach"
const LEAD_TEXT := "Research lead | Coils near deep-cache machinery"
const TEST_PROFILE_PATH := "user://oceangame2_practical_research_material.json"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	var runtime := MaterialRuntimeController.new(profile)
	var day := ExpeditionDayState.new()
	day.begin_day(2)
	var world: Node = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)

	runtime.on_map_loaded(world, day)
	var before_ids: Array = world.get_material_candidate_report().get("active_ids", [])
	_expect(_coil_id(before_ids) == RESEARCHED_CANDIDATE_ID, "day-two control coil selection drifted")
	_expect(str(runtime.report().get("research_lead_text", "")).is_empty(), "unresearched day showed habitat lead")
	profile.complete_discovery(ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID, true)
	var reloaded_profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	_expect(reloaded_profile.load_profile().get("status") == "loaded", "committed research did not reload")
	runtime = MaterialRuntimeController.new(reloaded_profile)
	runtime.on_map_loaded(world, day)
	var same_day_ids: Array = world.get_material_candidate_report().get("active_ids", [])
	_expect(same_day_ids == before_ids, "mid-day research commit rerolled cached candidates")
	_expect(str(runtime.report().get("research_lead_text", "")).is_empty(), "mid-day research commit activated lead")

	var pools: Array = world.get_material_candidate_pools()
	var normal_day_three := MaterialCandidateSelector.select_for_day(MAP_ID, pools, 3, [])
	_expect(_coil_id(normal_day_three) == NORMAL_DAY_THREE_CANDIDATE_ID, "day-three counterfactual coil selection drifted")
	day.begin_next_day()
	runtime.on_map_loaded(world, day)
	var researched_ids: Array = world.get_material_candidate_report().get("active_ids", [])
	var report: Dictionary = runtime.report()
	_expect(_coil_id(researched_ids) == RESEARCHED_CANDIDATE_ID, "fresh researched day did not select deep-cache coil")
	_expect(_material_ids(researched_ids, "material_titanium_") == _material_ids(normal_day_three, "material_titanium_"), "research changed unrelated titanium rotation")
	_expect(_material_ids(researched_ids, "material_rubber_") == _material_ids(normal_day_three, "material_rubber_"), "research changed unrelated rubber rotation")
	_expect(researched_ids.size() == 4, "research changed daily material yield")
	_expect(_material_count(world, researched_ids, ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2, "research changed titanium guarantee")
	_expect(_material_count(world, researched_ids, ExpansionProfileState.RUBBER_MATERIAL_ID) == 1, "research changed rubber guarantee")
	_expect(_material_count(world, researched_ids, ExpansionProfileState.COIL_MATERIAL_ID) == 1, "research changed coil guarantee")
	_expect(report.get("researched_pool_ids", []) == [COIL_POOL_ID], "day cache did not own researched pool")
	_expect(report.get("research_lead_text", "") == LEAD_TEXT, "research lead was not source-derived")
	_expect(runtime.overlay_text().find(LEAD_TEXT) != -1, "material overlay omitted research lead")

	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Practical research material state smoke failed: %s" % failure)
		quit(1)
		return
	print("Practical research material state smoke passed: day=2 before=%s same_day=%s normal_day3=%s researched_day3=%s pool=%s yield=Ti2+Rubber1+Coil1 lead=\"%s\"." % [
		str(before_ids),
		str(same_day_ids),
		str(normal_day_three),
		str(researched_ids),
		COIL_POOL_ID,
		LEAD_TEXT,
	])
	quit(0)


func _coil_id(selected_ids: Array) -> String:
	for candidate_id in selected_ids:
		if str(candidate_id).begins_with("material_coil_"):
			return str(candidate_id)
	return ""


func _material_count(world, selected_ids: Array, material_id: String) -> int:
	var count := 0
	for candidate in world.get_material_candidates():
		if selected_ids.has(str(candidate.get("id", ""))) and str(candidate.get("material_id", "")) == material_id:
			count += int(candidate.get("material_quantity", 0))
	return count


func _material_ids(selected_ids: Array, prefix: String) -> Array[String]:
	var values: Array[String] = []
	for candidate_id in selected_ids:
		if str(candidate_id).begins_with(prefix):
			values.append(str(candidate_id))
	values.sort()
	return values


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
