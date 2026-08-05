extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const DailyConditionState := preload("res://scripts/main/daily_condition_state.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpeditionLeadResolver := preload("res://scripts/main/expedition_lead_resolver.gd")
const ExpeditionPlanState := preload("res://scripts/main/expedition_plan_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const RELAY_ID := "upper_left_wreck_relay_route"
const BLOOM_ID := "southwest_jellyfish_bloom"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	world.load_greybox()

	var profile = _fresh_profile()
	profile.complete_discovery(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID, false)
	var projects := MaterialProjectRuntime.new(profile)
	projects.on_map_loaded(world)
	var day := ExpeditionDayState.new()
	var conditions := DailyConditionState.new()
	conditions.sync(world.get_daily_conditions(), day.day_number)
	day.end_day("voluntary")

	var focused := ExpeditionLeadResolver.resolve(world, profile, projects, day, conditions)
	_expect(focused.get("status") == "choice_ready", "focused fixture did not expose a choice")
	_expect(focused.get("eligible_ids") == [RELAY_ID, BLOOM_ID], "lead source order drifted")
	_expect(_lead(focused, RELAY_ID).get("readiness_state") == "prepare", "relay did not expose preparation state")
	_expect(_lead(focused, BLOOM_ID).get("readiness_state") == "ready", "bloom was not ready")
	_expect(_reports_use_exact_fields(focused.get("eligible_leads", [])), "lead report fields drifted")

	var state := ExpeditionPlanState.new()
	_expect(not state.has_selection(), "new session auto-selected a lead")
	var wrong_phase := state.select(RELAY_ID, focused["eligible_ids"], ExpeditionDayState.PHASE_ACTIVE)
	_expect(wrong_phase.get("reason") == "wrong_phase", "active day accepted a plan selection")
	var unknown := state.select("unknown_lead", focused["eligible_ids"], ExpeditionDayState.PHASE_DEBRIEF)
	_expect(unknown.get("reason") == "invalid_lead", "unknown lead was accepted")
	var selected := state.select(RELAY_ID, focused["eligible_ids"], ExpeditionDayState.PHASE_DEBRIEF)
	_expect(bool(selected.get("changed", false)) and state.selected_lead_id() == RELAY_ID, "relay selection failed")
	var replaced := state.replace(BLOOM_ID, focused["eligible_ids"], ExpeditionDayState.PHASE_DEBRIEF)
	_expect(replaced.get("reason") == "replaced" and state.selected_lead_id() == BLOOM_ID, "lead replacement failed")

	day.begin_next_day()
	conditions.sync(world.get_daily_conditions(), day.day_number)
	projects.on_map_loaded(world)
	var active_day := ExpeditionLeadResolver.resolve(world, profile, projects, day, conditions)
	_expect(active_day.get("eligible_ids") == [RELAY_ID, BLOOM_ID], "selected bloom did not remain valid on its day")
	_expect(state.reconcile(active_day["eligible_ids"]).get("reason") == "preserved", "next day cleared selection")
	day.record_sortie_started()
	day.record_sortie_started()
	day.record_bank(2, 300)
	day.record_failure("oxygen_depleted")
	day.on_map_loaded("production_level_01")
	projects.on_map_loaded(world)
	var reloaded := ExpeditionLeadResolver.resolve(world, profile, projects, day, conditions)
	_expect(state.reconcile(reloaded["eligible_ids"]).get("reason") == "preserved", "sortie, offload, failure, or map reload cleared selection")

	day.end_day("voluntary")
	conditions.sync(world.get_daily_conditions(), day.day_number)
	var bloom_expired := ExpeditionLeadResolver.resolve(world, profile, projects, day, conditions)
	var expired := state.reconcile(bloom_expired["eligible_ids"])
	_expect(expired.get("reason") == "invalidated" and not state.has_selection(), "expired bloom selection survived debrief")
	_expect(not state.has_selection(), "state auto-selected the remaining relay")

	state.select(RELAY_ID, bloom_expired["eligible_ids"], ExpeditionDayState.PHASE_DEBRIEF)
	profile.complete_discovery(ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID, false)
	var relay_resolved := ExpeditionLeadResolver.resolve(world, profile, projects, day, conditions)
	_expect(not relay_resolved.get("eligible_ids", []).has(RELAY_ID), "committed relay remained eligible")
	_expect(state.reconcile(relay_resolved["eligible_ids"]).get("reason") == "invalidated", "resolved relay did not clear selection")
	_expect(not state.has_selection(), "relay invalidation auto-selected another lead")

	var ready_profile = _fresh_profile()
	ready_profile.complete_discovery(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID, false)
	var ready_projects := MaterialProjectRuntime.new(ready_profile)
	ready_projects.on_map_loaded(world)
	_complete_project(ready_profile, ready_projects.project_definition_for(ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID))
	_complete_project(ready_profile, ready_projects.project_definition_for(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID))
	_complete_project(ready_profile, ready_projects.project_definition_for(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID))
	ready_projects.on_map_loaded(world)
	day.begin_day(1)
	day.end_day("voluntary")
	conditions.sync(world.get_daily_conditions(), day.day_number)
	var equipped := ExpeditionLeadResolver.resolve(world, ready_profile, ready_projects, day, conditions)
	_expect(_lead(equipped, RELAY_ID).get("readiness_state") == "ready", "owned relay equipment did not resolve ready")

	var fresh_session := ExpeditionPlanState.new()
	_expect(not fresh_session.has_selection(), "new application session restored a selected lead")
	var profile_report: Dictionary = profile.report()
	_expect(profile_report.get("schema_version") == ExpansionProfileState.SCHEMA_VERSION, "profile schema changed")
	_expect(not profile_report.has("selected_lead_id"), "selected plan leaked into profile")

	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Expedition plan state smoke failed: %s" % failure)
		quit(1)
		return
	print("Expedition plan state passed: leads=relay,bloom order=10,20 prepare=true ready=true debrief_only=true replace=true next_day=true sorties=2 offload=true map_reload=true failure=true bloom_expiry=true relay_commit_clear=true auto_select=false profile_schema=%d." % ExpansionProfileState.SCHEMA_VERSION)
	quit(0)


func _fresh_profile():
	var profile := ExpansionProfileState.new("user://unused_expansion_15_profile.json", false)
	profile.load_profile()
	return profile


func _complete_project(profile, project: Dictionary) -> void:
	var discovery_id := str(project.get("required_discovery_id", ""))
	if not discovery_id.is_empty() and not profile.has_completed_discovery(discovery_id):
		profile.complete_discovery(discovery_id, false)
	var materials := {}
	for material_id in project.get("required_materials", {}):
		materials[str(material_id)] = int(project.get("required_materials", {})[material_id])
	if not materials.is_empty():
		var deposit: Dictionary = profile.deposit_materials(materials, false)
		_expect(bool(deposit.get("changed", false)), "could not deposit project materials: %s" % deposit)
	var result: Dictionary = profile.complete_material_project(project, false)
	_expect(bool(result.get("changed", false)), "could not complete project %s: %s" % [project.get("id", ""), result])


func _lead(resolution: Dictionary, lead_id: String) -> Dictionary:
	for value in resolution.get("eligible_leads", []):
		if str(value.get("lead_id", "")) == lead_id:
			return value
	return {}


func _reports_use_exact_fields(reports: Array) -> bool:
	var expected: Array = ExpeditionLeadResolver.REPORT_FIELDS.keys()
	expected.sort()
	for report in reports:
		var fields: Array = report.keys()
		fields.sort()
		if fields != expected:
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
