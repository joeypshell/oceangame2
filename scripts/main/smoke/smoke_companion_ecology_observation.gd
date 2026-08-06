extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const CompanionAdaptationDebrief := preload("res://scripts/companion/companion_adaptation_debrief.gd")
const CompanionEcologyObservationState := preload("res://scripts/companion/companion_ecology_observation_state.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const PROFILE_PATH := "user://oceangame2_companion_ecology_observation_smoke.json"
const KITE_ID := CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID
const MICA_ID := "veil_cuttle_juvenile_01"
const TRACE_ID := "southwest_bloom_migration_trace"
const OBSERVATION_ID := "southwest_bloom_migration_observation"
const CONDITION_ID := "southwest_jellyfish_bloom"
const MEMORY_ID := "followed_the_bloom"
const ADAPTATION_ID := "drift_lens"
const KITE_MEMORY_ID := "held_the_flow"
const KITE_ADAPTATION_ID := "anchor_fins"
const FAILURE_REASONS := ["hazard", "oxygen_failure", "health_failure", "manual_reset", "retry"]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	await process_frame

	var profile := ExpansionProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	_build_two_companion_fixture(profile)
	var kite_before := _individual_by_id(profile, KITE_ID)
	var materials_before: Dictionary = profile.report().get("material_inventory", {}).duplicate(true)

	var observation := CompanionEcologyObservationState.new()
	observation.bind_map(world, profile, false)
	_test_source_and_eligibility(profile, observation)
	_test_failure_cleanup(observation)
	_test_commit_and_exact_once(profile, observation)
	_expect(profile.report().get("material_inventory", {}) == materials_before, "observation commitment changed materials")

	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var reload: Dictionary = reloaded.load_profile()
	_expect(reload.get("status") == "loaded", "profile did not reload after Mica memory commitment")
	_expect(_earned(reloaded).has(MEMORY_ID), "reload lost Mica's committed bloom memory")
	_test_night_consolidation(reloaded, materials_before)

	var final_reload := ExpansionProfileState.new(PROFILE_PATH, true)
	final_reload.load_profile()
	var mica_after := _individual_by_id(final_reload, MICA_ID)
	_expect(mica_after.get("selected_adaptation_id") == ADAPTATION_ID, "reload lost deliberate Drift Lens consolidation")
	_expect((mica_after.get("earned_memory_ids", []) as Array).count(MEMORY_ID) == 1, "Mica memory was not exact-once")
	var kite_after := _individual_by_id(final_reload, KITE_ID)
	_expect(kite_after == kite_before, "Mica observation or adaptation changed Kite's durable record")
	_expect(final_reload.select_active_companion(KITE_ID, true).get("reason") == "selected", "Kite could not be selected after Mica consolidation")
	var active_kite: Dictionary = final_reload.companion_report().get("individual", {})
	_expect(active_kite.get("selected_adaptation_id") == KITE_ADAPTATION_ID, "Kite selection lost its adaptation")
	_expect(bool(final_reload.companion_report().get("riding_available_on_sortie_launch", false)), "Kite riding derivation changed")

	world.queue_free()
	_cleanup()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Companion ecology observation smoke failed: %s" % failure)
		quit(1)
		return
	print(
		"Companion ecology observation smoke passed: trace=%s observation=%s condition=%s reveal_required=true scanner_reward=none failures_clear=%s canonical_boat=true memory=%s exact_once=true night_deliberate=true adaptation=%s no_cost=true reload=true kite_preserved=true." % [
			TRACE_ID,
			OBSERVATION_ID,
			CONDITION_ID,
			",".join(FAILURE_REASONS),
			MEMORY_ID,
			ADAPTATION_ID,
		]
	)
	quit(0)


func _build_two_companion_fixture(profile) -> void:
	var kite: Dictionary = profile.commit_companion_rescue(KITE_ID, "spark_ray", "Kite", true)
	_expect(bool(kite.get("changed", false)), "could not commit Kite fixture")
	_expect(bool(profile.earn_companion_memory(KITE_MEMORY_ID, true).get("changed", false)), "could not earn Kite control memory")
	_expect(bool(profile.select_companion_adaptation(KITE_ADAPTATION_ID, true).get("changed", false)), "could not select Kite control adaptation")
	var mica: Dictionary = profile.commit_companion_rescue(MICA_ID, "veil_cuttle", "Mica", true)
	_expect(bool(mica.get("changed", false)), "could not commit Mica fixture")
	_expect(bool(profile.select_active_companion(MICA_ID, true).get("changed", false)), "could not select Mica fixture")


func _test_source_and_eligibility(profile, observation) -> void:
	var early: Dictionary = observation.record_identification(TRACE_ID, OBSERVATION_ID, [CONDITION_ID])
	_expect(early.get("reason") == "relationship_not_revealed", "Scanner identification bypassed Mica reveal")
	_expect(observation.report().get("pending_observation_id", "").is_empty(), "early Scanner attempt created pending state")

	profile.select_active_companion(KITE_ID, true)
	var wrong_companion: Dictionary = observation.record_reveal(TRACE_ID)
	_expect(wrong_companion.get("reason") == "wrong_active_companion", "Kite could reveal Mica's relationship")
	profile.select_active_companion(MICA_ID, true)

	var reveal: Dictionary = observation.record_reveal(TRACE_ID)
	_expect(bool(reveal.get("changed", false)), "Mica reveal did not enter transient observation state")
	var inactive: Dictionary = observation.record_identification(TRACE_ID, OBSERVATION_ID, [])
	_expect(inactive.get("reason") == "linked_condition_inactive", "inactive bloom allowed migration identification")
	var identified: Dictionary = observation.record_identification(TRACE_ID, OBSERVATION_ID, [CONDITION_ID])
	_expect(bool(identified.get("changed", false)) and identified.get("memory_id") == MEMORY_ID, "valid Scanner identification did not create Mica's pending observation")
	_expect(_is_zero_reward(identified), "Scanner identification granted progression or reward output")
	var report: Dictionary = observation.report()
	_expect(report.get("revealed_trace_ids", []) == [TRACE_ID], "reveal state did not remain source-specific")
	_expect(report.get("identified_trace_ids", []) == [TRACE_ID], "identified state did not remain source-specific")
	_expect(report.get("pending_observation_id") == OBSERVATION_ID, "pending observation id drifted")
	var off_boat: Dictionary = observation.commit_at_boat(false)
	_expect(off_boat.get("reason") == "canonical_boat_required" and not _earned(profile).has(MEMORY_ID), "observation committed away from canonical boat")


func _test_failure_cleanup(observation) -> void:
	for reason in FAILURE_REASONS:
		if observation.report().get("pending_observation_id", "").is_empty():
			observation.record_reveal(TRACE_ID)
			observation.record_identification(TRACE_ID, OBSERVATION_ID, [CONDITION_ID])
		var discarded: Dictionary = observation.discard_uncommitted(reason)
		var report: Dictionary = observation.report()
		_expect(bool(discarded.get("changed", false)), "%s did not discard transient observation state" % reason)
		_expect(
			report.get("revealed_trace_ids", []).is_empty()
			and report.get("identified_trace_ids", []).is_empty()
			and str(report.get("pending_observation_id", "")).is_empty(),
			"%s retained reveal, identification, or pending state" % reason
		)


func _test_commit_and_exact_once(profile, observation) -> void:
	observation.record_reveal(TRACE_ID)
	observation.record_identification(TRACE_ID, OBSERVATION_ID, [CONDITION_ID])
	var commit: Dictionary = observation.commit_at_boat(true)
	_expect(bool(commit.get("changed", false)) and commit.get("memory_id") == MEMORY_ID, "canonical boat did not commit Mica memory")
	_expect((_earned(profile) as Array).count(MEMORY_ID) == 1, "canonical boat did not write Mica memory exactly once")
	var duplicate: Dictionary = observation.record_identification(TRACE_ID, OBSERVATION_ID, [CONDITION_ID])
	_expect(not bool(duplicate.get("changed", false)) and duplicate.get("reason") == "already_committed", "committed observation could be farmed")
	_expect(str(observation.report().get("pending_observation_id", "")).is_empty(), "duplicate observation recreated pending state")


func _test_night_consolidation(profile, materials_before: Dictionary) -> void:
	var debrief := CompanionAdaptationDebrief.new()
	debrief.bind_profile(profile)
	debrief.begin()
	var initial: Dictionary = debrief.report()
	_expect(initial.get("eligible_adaptation_ids", []) == [ADAPTATION_ID], "Mica night offered anything except earned Drift Lens")
	_expect(str(initial.get("selected_adaptation_id", "")).is_empty() and debrief.requires_selection(), "night automatically selected Drift Lens")
	var lines := "\n".join(debrief.debrief_lines())
	_expect(lines.find("Mica adaptation") != -1 and lines.find("Followed the Bloom") != -1, "Mica night copy omitted the individual or shared memory")
	_expect(lines.find("Drift Lens") != -1 and lines.find("hazard remains active") != -1, "Mica night copy omitted the bounded field payoff")
	_expect(lines.find("Exclusive with") == -1, "single Mica adaptation displayed false mutual exclusion")
	var use := InputEventAction.new()
	use.action = "active_tool_use"
	use.pressed = true
	var selected: Dictionary = debrief.handle_input(use)
	_expect(bool(selected.get("changed", false)) and selected.get("adaptation_id") == ADAPTATION_ID, "Space/USE did not deliberately consolidate Drift Lens")
	_expect(not debrief.requires_selection(), "Mica night still blocked the next day after consolidation")
	_expect(profile.report().get("material_inventory", {}) == materials_before, "Drift Lens consolidation spent materials")


func _is_zero_reward(result: Dictionary) -> bool:
	return (
		int(result.get("cargo_delta", -1)) == 0
		and int(result.get("score_delta", -1)) == 0
		and (result.get("material_deltas", {}) as Dictionary).is_empty()
		and (result.get("blueprint_ids", []) as Array).is_empty()
		and (result.get("access_ids", []) as Array).is_empty()
		and str(result.get("adaptation_id", "")).is_empty()
	)


func _earned(profile) -> Array:
	return profile.companion_report().get("individual", {}).get("earned_memory_ids", [])


func _individual_by_id(profile, individual_id: String) -> Dictionary:
	for individual in profile.companion_report().get("individuals", []):
		if str((individual as Dictionary).get("individual_id", "")) == individual_id:
			return (individual as Dictionary).duplicate(true)
	return {}


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
