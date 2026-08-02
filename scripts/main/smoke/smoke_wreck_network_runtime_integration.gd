extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const DailyConditionState := preload("res://scripts/main/daily_condition_state.gd")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpeditionLeadResolver := preload("res://scripts/main/expedition_lead_resolver.gd")
const ExpeditionPlanState := preload("res://scripts/main/expedition_plan_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const RegionalJourneyPresentation := preload("res://scripts/main/regional_journey_presentation.gd")
const WreckNetworkInvestigationRuntime := preload("res://scripts/main/wreck_network_investigation_runtime.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const TEST_PATH := "user://oceangame2_wreck_network_runtime.json"
const WEST_JOURNEY_ID := "western_chasm_wreck_fragment_journey"
const WEST_FRAGMENT_ID := "western_chasm_wreck_fragment_discovery"
const ABYSS_JOURNEY_ID := "abyssal_shelf_wreck_fragment_journey"
const ABYSS_FRAGMENT_ID := "abyssal_shelf_wreck_fragment_discovery"

var _failures: Array[String] = []


class DebriefMain:
	extends RefCounted

	var _expedition_day_state
	var _wreck_network_investigation
	var _last_status_note := ""
	var refresh_count := 0
	var status_update_count := 0

	func _refresh_expedition_plan() -> Dictionary:
		refresh_count += 1
		return {"status": "inactive", "eligible_ids": []}

	func _update_status_label() -> void:
		status_update_count += 1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	world.load_greybox()
	_expect(world.get_wreck_network_investigations().size() == 1, "world did not expose one immutable investigation")

	var profile := ExpansionProfileState.new(TEST_PATH, true)
	_expect(profile.load_profile().get("status") == "missing", "fresh integration profile was not empty")
	profile.complete_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID, true)
	var projects := MaterialProjectRuntime.new(profile)
	projects.on_map_loaded(world)
	var day := ExpeditionDayState.new()
	day.end_day("voluntary")
	var conditions := DailyConditionState.new()
	conditions.sync(world.get_daily_conditions(), day.day_number)

	var runtime := WreckNetworkInvestigationRuntime.new(profile)
	var initial: Dictionary = runtime.on_map_loaded(world)
	_expect(initial.get("status") == "fragments_required", "runtime did not derive the open investigation")
	var initial_text := ExpeditionDayDebrief.build_text(day, null, conditions, "", runtime)
	_expect(initial_text.find("Far-west recorder: transfer-hub coordinates split across two wreck transponders") != -1, "zero-fragment night omitted the recorder's causal lead")
	_expect(initial_text.find("Recover and return both coordinate halves") != -1, "zero-fragment night omitted the two-half objective")
	var plan: Dictionary = ExpeditionLeadResolver.resolve(world, profile, projects, day, conditions)
	_expect(plan.get("status") == "choice_ready", "two investigation leads were not planner-ready")
	_expect(plan.get("eligible_ids") == [WEST_JOURNEY_ID, ABYSS_JOURNEY_ID], "optional daily lead displaced the main investigation pair")
	var presentation := RegionalJourneyPresentation.new()
	_expect(presentation.promise_text(world, profile) == "Western chasm | Find the current-scoured transponder", "established west-first coordinate promise drifted")
	_expect(presentation.promise_text(world, profile, ABYSS_JOURNEY_ID) == "Abyssal shelf | Find the pressure-crushed transponder", "pinned abyss lead did not change guidance")

	var selection := ExpeditionPlanState.new()
	selection.select(WEST_JOURNEY_ID, plan.get("eligible_ids", []), ExpeditionDayState.PHASE_DEBRIEF)
	_expect(_record_by_id(world.get_survey_targets(), "abyssal_shelf_wreck_fragment_survey").get("discovery_id") == ABYSS_FRAGMENT_ID, "pinning west changed the abyssal source target")
	_expect(not runtime.report().has("selected_lead_id"), "selected guidance leaked into investigation state")

	profile.complete_discovery(WEST_FRAGMENT_ID, true)
	var west_commit: Dictionary = runtime.on_discovery_committed(WEST_FRAGMENT_ID)
	_expect(str(west_commit.get("note", "")).find("Abyssal Coordinate Transponder") != -1, "one-fragment feedback did not name the remaining lead")
	var one_fragment_plan: Dictionary = ExpeditionLeadResolver.resolve(world, profile, projects, day, conditions)
	_expect(one_fragment_plan.get("eligible_ids", []).has(ABYSS_JOURNEY_ID), "remaining lead disappeared after the first commit")
	_expect(not one_fragment_plan.get("eligible_ids", []).has(WEST_JOURNEY_ID), "committed west lead remained eligible")
	_expect(presentation.promise_text(world, profile) == "Abyssal shelf | Find the pressure-crushed transponder", "one-fragment guidance did not narrow to the remaining route")
	var one_fragment_text := ExpeditionDayDebrief.build_text(day, null, conditions, west_commit.get("note", ""), runtime)
	_expect(one_fragment_text.count("Coordinate half secured 1/2") == 1, "one-fragment debrief did not explain secured progress")
	_expect(one_fragment_text.count("Remaining: Abyssal Coordinate Transponder") == 1, "one-fragment debrief duplicated or lost the remaining lead")

	profile.complete_discovery(ABYSS_FRAGMENT_ID, true)
	var abyss_commit: Dictionary = runtime.on_discovery_committed(ABYSS_FRAGMENT_ID)
	_expect(str(abyss_commit.get("note", "")).find("Night will compare them") != -1, "second coordinate half did not explain the night payoff")
	_expect(runtime.requires_analysis(), "two coordinate halves did not become ready for night comparison")
	_expect(runtime.debrief_lines().has("Night comparison pending"), "ready debrief omitted automatic night-comparison readiness")
	var ready_text := ExpeditionDayDebrief.build_text(day, null, conditions, abyss_commit.get("note", ""), runtime)
	_expect(ready_text.count("Coordinate halves secured 2/2") == 1, "analysis-ready debrief duplicated or lost coordinate readiness: %s" % ready_text.replace("\n", " | "))
	_expect(ready_text.find("Space/USE") == -1, "analysis-ready debrief retained a mystery command")

	var main := DebriefMain.new()
	main._expedition_day_state = day
	main._wreck_network_investigation = runtime
	var use_event := InputEventAction.new()
	use_event.action = &"active_tool_use"
	use_event.pressed = true
	var ignored_use: Dictionary = ExpeditionDayDebrief.handle_debrief_input(main, use_event)
	_expect(ignored_use.get("reason") == "ignored", "debrief still routed Space/USE into coordinate analysis")
	var analyzed: Dictionary = ExpeditionDayDebrief.resolve_wreck_network_night_payoff(main)
	_expect(analyzed.get("status") == "analysis_completed" and bool(analyzed.get("changed", false)), "automatic night payoff did not compare the coordinates")
	_expect(profile.has_completed_discovery(ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID), "analysis did not persist the final discovery")
	_expect(day.committed_discovery_ids.has(ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID), "debrief summary did not record the analysis discovery")
	_expect(ExpeditionDayDebrief.resolve_wreck_network_night_payoff(main).get("status") == "not_ready", "completed analysis remained actionable")
	_expect(ExpeditionDayDebrief.handle_debrief_key(main, KEY_SPACE).get("reason") == "ignored", "Space remained a debrief analysis command")
	var debrief_text := ExpeditionDayDebrief.build_text(day, null, conditions, main._last_status_note, runtime)
	_expect(debrief_text.count("Transfer hub coordinates recovered") == 1, "debrief duplicated or omitted the analysis result")
	_expect(debrief_text.count("Destination: transfer hub beyond mapped cave") == 1, "debrief duplicated or omitted the broad destination promise")
	var unrelated_feedback := ExpeditionDayDebrief.build_text(day, null, conditions, "Unrelated debrief feedback", runtime)
	_expect(unrelated_feedback.find("Unrelated debrief feedback") != -1, "wreck feedback ownership suppressed unrelated debrief feedback")

	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Wreck-network runtime integration smoke failed: %s" % failure)
		quit(1)
		return
	print("Wreck-network runtime integration smoke passed: leads=west,abyss recorder_explains_split=true one_fragment_names_remaining=true night_analysis=automatic input_gate=none exact_once=true result=transfer_hub_promise.")
	quit(0)


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for value in records:
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == record_id:
			return value
	return {}


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
