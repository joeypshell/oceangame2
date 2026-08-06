extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ReviewProfileMode := preload("res://scripts/main/review_profile_mode.gd")
const WreckNetworkInvestigationRuntime := preload("res://scripts/main/wreck_network_investigation_runtime.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_argument_contract()
	_test_expansion_14_boundary()
	_test_expansion_16_boundary()
	_test_expansion_17_boundary()
	_test_expansion_18_boundary()
	_test_living_expedition_01_boundary()
	_test_living_expedition_02_boundary()
	_test_living_expedition_03_boundary()
	_test_unknown_checkpoint_fallback()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Review checkpoint smoke failed: %s" % failure)
		quit(1)
		return
	print("Review checkpoint smoke passed: expansion14=Ti2+Coil1 expansion16=Ti1+Rubber1+Coil1+Gel1 expansion17=two_fragments_unresolved expansion18=triangulated_before_entry living_expedition_01=pre_rescue living_expedition_02=Kite_committed+Mica_unrescued living_expedition_03=Day2+Kite+Mica+Scanner+Mica_selected persistence=false unknown=fresh.")
	quit(0)


func _test_argument_contract() -> void:
	var local_args := PackedStringArray(["--review-checkpoint=expansion_14_start"])
	var split_args := PackedStringArray(["--review-checkpoint", "expansion_14_start"])
	_expect(ReviewProfileMode.checkpoint_id(local_args, PackedStringArray()) == ReviewCheckpointFixture.EXPANSION_14_START, "equals-form local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_id(split_args, PackedStringArray()) == ReviewCheckpointFixture.EXPANSION_14_START, "split-form local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_from_web_query("?review=abc&checkpoint=EXPANSION_14_START") == ReviewCheckpointFixture.EXPANSION_14_START, "Web checkpoint was not normalized")
	_expect(ReviewProfileMode.checkpoint_id(PackedStringArray(["--review-checkpoint=expansion_16_start"]), PackedStringArray()) == ReviewCheckpointFixture.EXPANSION_16_START, "Expansion 16 local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_from_web_query("?checkpoint=EXPANSION_16_START") == ReviewCheckpointFixture.EXPANSION_16_START, "Expansion 16 Web checkpoint was not normalized")
	_expect(ReviewProfileMode.checkpoint_id(PackedStringArray(["--review-checkpoint=expansion_17_start"]), PackedStringArray()) == ReviewCheckpointFixture.EXPANSION_17_START, "Expansion 17 local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_from_web_query("?checkpoint=EXPANSION_17_START") == ReviewCheckpointFixture.EXPANSION_17_START, "Expansion 17 Web checkpoint was not normalized")
	_expect(ReviewProfileMode.checkpoint_id(PackedStringArray(["--review-checkpoint=expansion_18_start"]), PackedStringArray()) == ReviewCheckpointFixture.EXPANSION_18_START, "Expansion 18 local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_from_web_query("?checkpoint=EXPANSION_18_START") == ReviewCheckpointFixture.EXPANSION_18_START, "Expansion 18 Web checkpoint was not normalized")
	_expect(ReviewProfileMode.checkpoint_id(PackedStringArray(["--review-checkpoint=living_expedition_01_start"]), PackedStringArray()) == ReviewCheckpointFixture.LIVING_EXPEDITION_01_START, "Living Expedition 01 local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_from_web_query("?checkpoint=LIVING_EXPEDITION_01_START") == ReviewCheckpointFixture.LIVING_EXPEDITION_01_START, "Living Expedition 01 Web checkpoint was not normalized")
	_expect(ReviewProfileMode.checkpoint_id(PackedStringArray(["--review-checkpoint=living_expedition_02_start"]), PackedStringArray()) == ReviewCheckpointFixture.LIVING_EXPEDITION_02_START, "Living Expedition 02 local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_from_web_query("?checkpoint=LIVING_EXPEDITION_02_START") == ReviewCheckpointFixture.LIVING_EXPEDITION_02_START, "Living Expedition 02 Web checkpoint was not normalized")
	_expect(ReviewProfileMode.checkpoint_id(PackedStringArray(["--review-checkpoint=living_expedition_03_start"]), PackedStringArray()) == ReviewCheckpointFixture.LIVING_EXPEDITION_03_START, "Living Expedition 03 local checkpoint was not parsed")
	_expect(ReviewProfileMode.checkpoint_from_web_query("?checkpoint=LIVING_EXPEDITION_03_START") == ReviewCheckpointFixture.LIVING_EXPEDITION_03_START, "Living Expedition 03 Web checkpoint was not normalized")
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


func _test_expansion_17_boundary() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.EXPANSION_17_START, profile)
	var report: Dictionary = profile.report()
	_expect(bool(applied.get("ready", false)), "Expansion 17 checkpoint did not apply: %s" % applied)
	_expect(applied.get("map_path") == ReviewCheckpointFixture.EXPANSION_17_MAP_PATH, "Expansion 17 checkpoint did not require the full production level")
	_expect(report.get("completed_projects", []).size() == ReviewCheckpointFixture.EXPANSION_17_PRIOR_PROJECT_IDS.size(), "Expansion 17 checkpoint did not complete exactly the prior project set")
	for project_id in ReviewCheckpointFixture.EXPANSION_17_PRIOR_PROJECT_IDS:
		_expect(profile.has_completed_project(project_id), "Expansion 17 checkpoint omitted prior project %s" % project_id)
	_expect(profile.has_completed_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID), "Expansion 17 checkpoint omitted its prerequisite discovery")
	_expect(profile.has_banked_tool_target(ExpansionProfileState.FAR_WEST_WRECK_RECORDER_ID), "Expansion 17 checkpoint omitted the banked far-west recorder")
	_expect(profile.material_inventory().is_empty(), "Expansion 17 checkpoint retained unrelated recipe materials")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID), "Expansion 17 checkpoint pre-completed the western fragment")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID), "Expansion 17 checkpoint pre-completed the abyssal fragment")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID), "Expansion 17 checkpoint pre-completed triangulation")
	_expect(ReviewProfileMode.startup_report(true, ReviewCheckpointFixture.EXPANSION_17_START, true).find("id=expansion_17_start persistence=false") != -1, "Expansion 17 startup report omitted its isolated marker")
	var world = WORLD_SCENE.instantiate()
	world.map_path = ReviewCheckpointFixture.EXPANSION_17_MAP_PATH
	get_root().add_child(world)
	world.load_greybox()
	var runtime := WreckNetworkInvestigationRuntime.new(profile)
	var investigation: Dictionary = runtime.on_map_loaded(world)
	_expect(investigation.get("status") == "fragments_required", "Expansion 17 checkpoint did not expose the fragment boundary: %s" % investigation)
	_expect(investigation.get("committed_fragment_ids", []).is_empty(), "Expansion 17 checkpoint pre-committed a fragment")
	_expect(investigation.get("remaining_fragment_ids", []).size() == 2, "Expansion 17 checkpoint did not expose both fragment leads")
	_expect(not bool(investigation.get("analysis_ready", true)), "Expansion 17 checkpoint pre-enabled night analysis")
	world.queue_free()


func _test_expansion_18_boundary() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.EXPANSION_18_START, profile)
	var report: Dictionary = profile.report()
	_expect(bool(applied.get("ready", false)), "Expansion 18 checkpoint did not apply: %s" % applied)
	_expect(applied.get("map_path") == ReviewCheckpointFixture.EXPANSION_18_MAP_PATH, "Expansion 18 checkpoint did not require the full production level")
	_expect(report.get("completed_projects", []).size() == ReviewCheckpointFixture.EXPANSION_18_PRIOR_PROJECT_IDS.size(), "Expansion 18 checkpoint did not complete exactly the prior project set")
	_expect(profile.has_completed_discovery(ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID), "Expansion 18 checkpoint omitted the western fragment")
	_expect(profile.has_completed_discovery(ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID), "Expansion 18 checkpoint omitted the abyssal fragment")
	_expect(profile.has_completed_discovery(ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID), "Expansion 18 checkpoint omitted triangulation")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.TRANSFER_HUB_NAVIGATION_CORE_DISCOVERY_ID), "Expansion 18 checkpoint pre-completed the navigation core")
	_expect(applied.get("active_objective_id") == "transfer_hub_core_recovery", "Expansion 18 checkpoint omitted the active Transfer Hub objective")
	_expect(applied.get("active_objective_label") == "Transfer Hub", "Expansion 18 checkpoint omitted the active objective label")
	_expect(profile.material_inventory().is_empty(), "Expansion 18 checkpoint retained unrelated recipe materials")
	_expect(ReviewProfileMode.startup_report(true, ReviewCheckpointFixture.EXPANSION_18_START, true).find("id=expansion_18_start persistence=false") != -1, "Expansion 18 startup report omitted its isolated marker")
	var world = WORLD_SCENE.instantiate()
	world.map_path = ReviewCheckpointFixture.EXPANSION_18_MAP_PATH
	get_root().add_child(world)
	world.load_greybox()
	var runtime := WreckNetworkInvestigationRuntime.new(profile)
	var investigation: Dictionary = runtime.on_map_loaded(world)
	_expect(bool(investigation.get("completed", false)), "Expansion 18 checkpoint did not start after triangulation: %s" % investigation)
	world.queue_free()


func _test_living_expedition_01_boundary() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.LIVING_EXPEDITION_01_START, profile)
	var report: Dictionary = profile.report()
	_expect(bool(applied.get("ready", false)), "Living Expedition 01 checkpoint did not apply: %s" % applied)
	_expect(applied.get("map_path") == ReviewCheckpointFixture.LIVING_EXPEDITION_01_MAP_PATH, "Living Expedition 01 checkpoint did not require the full production level")
	_expect(report.get("completed_projects", []).size() == ReviewCheckpointFixture.LIVING_EXPEDITION_01_PRIOR_PROJECT_IDS.size(), "Living Expedition 01 checkpoint omitted a foundation project")
	_expect(profile.has_completed_discovery(ExpansionProfileState.TRANSFER_HUB_NAVIGATION_CORE_DISCOVERY_ID), "Living Expedition 01 checkpoint left the prior Transfer Hub objective active")
	_expect(profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "Living Expedition 01 checkpoint omitted the rescue Cutter")
	_expect(profile.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID), "Living Expedition 01 checkpoint omitted the current-route fins")
	_expect(profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID), "Living Expedition 01 checkpoint omitted the territorial-route weapon")
	_expect(not profile.has_committed_companion(), "Living Expedition 01 checkpoint pre-committed the Spark Ray")
	_expect(profile.material_inventory().is_empty(), "Living Expedition 01 checkpoint retained unrelated materials")
	_expect(applied.get("active_objective_id") == "spark_ray_rescue", "Living Expedition 01 checkpoint omitted the rescue focus")
	_expect(ReviewProfileMode.startup_report(true, ReviewCheckpointFixture.LIVING_EXPEDITION_01_START, true).find("id=living_expedition_01_start persistence=false") != -1, "Living Expedition 01 startup report omitted isolation")


func _test_living_expedition_02_boundary() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.LIVING_EXPEDITION_02_START, profile)
	var companion: Dictionary = profile.companion_report()
	_expect(bool(applied.get("ready", false)), "Living Expedition 02 checkpoint did not apply: %s" % applied)
	_expect(applied.get("map_path") == ReviewCheckpointFixture.LIVING_EXPEDITION_02_MAP_PATH, "Living Expedition 02 checkpoint did not require the full production level")
	_expect((companion.get("individuals", []) as Array).size() == 1, "Living Expedition 02 checkpoint did not contain exactly one committed individual")
	_expect(str(companion.get("active_individual_id", "")) == "spark_ray_juvenile_01", "Living Expedition 02 checkpoint did not select Kite")
	_expect(str(companion.get("individual", {}).get("species_id", "")) == "spark_ray", "Living Expedition 02 checkpoint selected the wrong species")
	_expect(applied.get("active_objective_id") == "veil_cuttle_rescue", "Living Expedition 02 checkpoint omitted Mica's rescue focus")
	_expect(profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID), "Living Expedition 02 checkpoint omitted the rescue Cutter")
	_expect(profile.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "Living Expedition 02 checkpoint omitted the trace scanner")
	_expect(profile.material_inventory().is_empty(), "Living Expedition 02 checkpoint retained unrelated materials")
	_expect(ReviewProfileMode.startup_report(true, ReviewCheckpointFixture.LIVING_EXPEDITION_02_START, true).find("id=living_expedition_02_start persistence=false") != -1, "Living Expedition 02 startup report omitted isolation")


func _test_living_expedition_03_boundary() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.LIVING_EXPEDITION_03_START, profile)
	var companion: Dictionary = profile.companion_report()
	var active: Dictionary = companion.get("individual", {})
	_expect(bool(applied.get("ready", false)), "Living Expedition 03 checkpoint did not apply: %s" % applied)
	_expect(int(applied.get("day_number", 0)) == 2, "Living Expedition 03 checkpoint did not select deterministic Day 2")
	_expect((companion.get("individuals", []) as Array).size() == 2, "Living Expedition 03 checkpoint did not commit exactly Kite and Mica")
	_expect(str(companion.get("active_individual_id", "")) == ReviewCheckpointFixture.MICA_INDIVIDUAL_ID, "Living Expedition 03 checkpoint did not select Mica")
	_expect(str(active.get("species_id", "")) == "veil_cuttle", "Living Expedition 03 checkpoint active species was not Mica")
	_expect((active.get("earned_memory_ids", []) as Array).is_empty() and str(active.get("selected_adaptation_id", "")).is_empty(), "Living Expedition 03 checkpoint pre-earned Mica progression")
	_expect(profile.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "Living Expedition 03 checkpoint omitted the Scanner")
	_expect(applied.get("active_objective_id") == "southwest_bloom_migration", "Living Expedition 03 checkpoint omitted the bloom objective")
	_expect(profile.material_inventory().is_empty(), "Living Expedition 03 checkpoint retained unrelated materials")


func _test_expansion_16_boundary() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.EXPANSION_16_START, profile)
	var report: Dictionary = profile.report()
	_expect(bool(applied.get("ready", false)), "Expansion 16 checkpoint did not apply: %s" % applied)
	_expect(applied.get("map_path") == ReviewCheckpointFixture.EXPANSION_16_MAP_PATH, "Expansion 16 checkpoint did not require the full production level")
	_expect(report.get("completed_projects", []).size() == ReviewCheckpointFixture.EXPANSION_16_PRIOR_PROJECT_IDS.size(), "Expansion 16 checkpoint did not complete exactly the prior project set")
	for project_id in ReviewCheckpointFixture.EXPANSION_16_PRIOR_PROJECT_IDS:
		_expect(profile.has_completed_project(project_id), "Expansion 16 checkpoint omitted prior project %s" % project_id)
	_expect(profile.has_completed_discovery(ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID), "Expansion 16 checkpoint omitted the relay discovery")
	_expect(profile.has_banked_tool_target(ExpansionProfileState.SOUTHEAST_WRECK_RECORDER_ID), "Expansion 16 checkpoint omitted the banked archive recorder")
	_expect(profile.material_inventory() == ReviewCheckpointFixture.REBREATHER_RECIPE, "Expansion 16 recipe was not exactly Ti1 + Rubber1 + Coil1 + Gel1")
	_expect(not profile.has_completed_project(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID), "Expansion 16 checkpoint prebuilt the rebreather")
	_expect(not profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID), "Expansion 16 checkpoint granted the rebreather capability")
	_expect(not profile.has_completed_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID), "Expansion 16 checkpoint pre-completed the far-west payoff")
	_expect(not profile.has_banked_tool_target(ExpansionProfileState.FAR_WEST_WRECK_RECORDER_ID), "Expansion 16 checkpoint pre-cleared the far-west recorder")
	var world = WORLD_SCENE.instantiate()
	world.map_path = ReviewCheckpointFixture.EXPANSION_16_MAP_PATH
	get_root().add_child(world)
	world.load_greybox()
	var project_runtime := MaterialProjectRuntime.new(profile)
	var project_report: Dictionary = project_runtime.on_map_loaded(world)
	_expect(project_report.get("project_id") == ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID, "checkpoint did not select the rebreather project")
	_expect(project_runtime.status() == "ready", "checkpoint did not make the exact rebreather recipe ready")
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
