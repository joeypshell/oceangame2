extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ReviewProfileMode := preload("res://scripts/main/review_profile_mode.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_argument_contract()
	_test_expansion_14_boundary()
	_test_unknown_checkpoint_fallback()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Review checkpoint smoke failed: %s" % failure)
		quit(1)
		return
	print("Review checkpoint smoke passed: id=expansion_14_start persistence=false prior_projects=7 archive=true recipe=Ti2+Coil1 stabilizer=false relay=false unknown=fresh.")
	quit(0)


func _test_argument_contract() -> void:
	var local_args := PackedStringArray(["--review-checkpoint=expansion_14_start"])
	var split_args := PackedStringArray(["--review-checkpoint", "expansion_14_start"])
	_expect(ReviewProfileMode.checkpoint_id(local_args, PackedStringArray()) == ReviewCheckpointFixture.EXPANSION_14_START, "equals-form local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_id(split_args, PackedStringArray()) == ReviewCheckpointFixture.EXPANSION_14_START, "split-form local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_from_web_query("?review=abc&checkpoint=EXPANSION_14_START") == ReviewCheckpointFixture.EXPANSION_14_START, "Web checkpoint was not normalized")
	_expect(ReviewProfileMode.requested(local_args, PackedStringArray()), "checkpoint did not imply isolated review mode")
	_expect(not ReviewProfileMode.persistence_enabled(false, true), "isolated review mode enabled persistence")


func _test_expansion_14_boundary() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.EXPANSION_14_START, profile)
	var report: Dictionary = profile.report()
	_expect(bool(applied.get("ready", false)), "Expansion 14 checkpoint did not apply: %s" % applied)
	_expect(applied.get("map_path") == ReviewCheckpointFixture.EXPANSION_14_MAP_PATH, "checkpoint did not require the full production level")
	_expect(report.get("completed_projects", []).size() == ReviewCheckpointFixture.PRIOR_PROJECT_IDS.size(), "checkpoint did not complete exactly the prior project set")
	for project_id in ReviewCheckpointFixture.PRIOR_PROJECT_IDS:
		_expect(profile.has_completed_project(project_id), "checkpoint omitted prior project %s" % project_id)
	_expect(profile.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID), "checkpoint omitted the committed archive discovery")
	_expect(profile.has_banked_tool_target(ExpansionProfileState.SOUTHEAST_WRECK_RECORDER_ID), "checkpoint omitted the banked archive recorder")
	_expect(profile.material_inventory() == ReviewCheckpointFixture.STABILIZER_RECIPE, "checkpoint recipe was not exactly Ti2 + Coil1")
	_expect(not profile.has_completed_project(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID), "checkpoint prebuilt the stabilizer project")
	_expect(not profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID), "checkpoint granted the stabilizer capability")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID), "checkpoint pre-completed the relay payoff")
	_expect(ReviewProfileMode.startup_report(true, ReviewCheckpointFixture.EXPANSION_14_START, true).find("persistence=false") != -1, "checkpoint startup report omitted isolation")
	var world = WORLD_SCENE.instantiate()
	world.map_path = ReviewCheckpointFixture.EXPANSION_14_MAP_PATH
	get_root().add_child(world)
	world.load_greybox()
	var project_runtime := MaterialProjectRuntime.new(profile)
	var project_report: Dictionary = project_runtime.on_map_loaded(world)
	_expect(project_report.get("project_id") == ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID, "checkpoint did not select the Current Stabilizer project")
	_expect(project_runtime.status() == "ready", "checkpoint did not make the exact stabilizer recipe ready")
	world.queue_free()


func _test_unknown_checkpoint_fallback() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var rejected: Dictionary = ReviewCheckpointFixture.apply("unknown", profile)
	var report: Dictionary = profile.report()
	_expect(not bool(rejected.get("ready", true)) and rejected.get("reason") == "unsupported_checkpoint", "unknown checkpoint was not rejected")
	_expect(report.get("completed_projects", []).is_empty() and report.get("material_inventory", {}).is_empty(), "unknown checkpoint mutated the fresh profile")
	_expect(ReviewProfileMode.startup_report(false, "unknown", false).find("fallback=fresh") != -1, "unknown checkpoint report omitted fresh fallback")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
