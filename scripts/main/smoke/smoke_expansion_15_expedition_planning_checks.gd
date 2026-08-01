extends "res://scripts/main/smoke/smoke_check_base.gd"

const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayPresentation := preload("res://scripts/main/expedition_day_presentation.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const MAP_ID := "production_level_01"
const BOAT_ENTRY_ID := "surface_boat_entry"
const RELAY_ID := "upper_left_wreck_relay_route"
const BLOOM_ID := "southwest_jellyfish_bloom"
const SOURCE_LEAD_COUNT := 4
const RELAY_GUIDANCE := "Plan: Follow the archive signal northwest"
const BLOOM_GUIDANCE := "Plan: Search the southwest migration lane"

var _available_ids: Array = []
var _preservation_checkpoints: Array[String] = []
var _relay_source := {}
var _bloom_source := {}
var _bloom_guidance := ""
var _relay_guidance := ""
var _sortie_count := 0


func _smoke_expansion_15_expedition_planning_and_quit() -> void:
	if not _prepare_two_lead_fixture():
		return
	if not _verify_source_projection_and_context_guards():
		return
	if not _exercise_bloom_plan_and_preservation():
		return
	if not _restore_night_one_fixture():
		return
	if not _exercise_relay_plan_build_and_resolution():
		return
	if not _verify_final_owner_boundaries():
		return

	var final_report: Dictionary = _main._refresh_expedition_plan()
	var summary := (
		"Expansion 15 expedition-planning smoke passed: "
		+ "selected_ids=%s available_ids=%s day=%d context=debrief>active "
		+ "route_contexts=%s,%s guidance=\"%s | %s\" preservation=%s "
		+ "sorties=%d bloom_clear=invalidated relay_clear=resolved "
		+ "final_selected=\"%s\" remaining_ids=%s auto_pin=false "
		+ "unselected_mutation=false profile_schema=4."
	)
	print(summary % [
		",".join(PackedStringArray([BLOOM_ID, RELAY_ID])),
		str(_available_ids),
		int(_main._expedition_day_state.day_number),
		str(_relay_source.get("route_context", "")),
		str(_bloom_source.get("route_context", "")),
		_bloom_guidance,
		_relay_guidance,
		",".join(PackedStringArray(_preservation_checkpoints)),
		_sortie_count,
		_main._expedition_plan_state.selected_lead_id(),
		str(final_report.get("eligible_ids", [])),
	])
	get_tree().quit(0)


func _prepare_two_lead_fixture() -> bool:
	if not _require(_world.map_id == MAP_ID, "loaded unexpected map %s" % _world.map_id):
		return false
	_prepare_controlled_map()
	var profile = _main._anomaly_survey.profile_state()
	if not _require(
		not profile.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID)
		and not profile.has_completed_discovery(ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID)
		and not profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID),
		"automated fixture did not begin from a fresh profile"
	):
		return false
	var archive: Dictionary = profile.complete_discovery(
		ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID,
		false
	)
	_main._material_project.on_map_loaded(_world)
	_main._refresh_expedition_plan()
	_relay_source = _record_by_id(_world.get_regional_journeys(), RELAY_ID)
	_bloom_source = _record_by_id(_world.get_daily_conditions(), BLOOM_ID)
	return _require(
		bool(archive.get("changed", false))
		and not _relay_source.is_empty()
		and not _bloom_source.is_empty(),
		"source fixture did not expose the archive, relay, and bloom"
	)


func _verify_source_projection_and_context_guards() -> bool:
	var active_report: Dictionary = _main._refresh_expedition_plan()
	var tab_guard: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_TAB)
	var pin_guard: Dictionary = ExpeditionDayDebrief.handle_debrief_key(_main, KEY_E)
	var away_position := _first_ordinary_salvage().get("center", Vector2(640.0, 640.0)) as Vector2
	_player.global_position = away_position
	var boat_guard: Dictionary = ExpeditionDayDebrief.handle_day_key(_main)
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_player.reset_motion()
	if not _require(
		active_report.get("eligible_ids") == [RELAY_ID]
		and tab_guard.get("reason") == "wrong_phase"
		and pin_guard.get("reason") == "wrong_phase"
		and boat_guard.get("reason") == "boat_required"
		and not _main._expedition_plan_state.has_selection(),
		"planning input escaped the boat/debrief boundary"
	):
		return false
	if not _enter_debrief():
		return false
	var report: Dictionary = _main._refresh_expedition_plan()
	_available_ids = report.get("eligible_ids", []).duplicate()
	if not _require(
		report.get("status") == "choice_ready"
		and int(report.get("source_lead_count", 0)) == SOURCE_LEAD_COUNT
		and _available_ids == [RELAY_ID, BLOOM_ID],
		"night one did not isolate the relay and bloom from later source leads"
	):
		return false
	if not _verify_projected_lead(report, _relay_source, "regional_journey", "Known relay, survey unresolved"):
		return false
	if not _verify_projected_lead(report, _bloom_source, "daily_condition", "Forecast for next day"):
		return false
	var blocked: Dictionary = ExpeditionDayDebrief.handle_day_key(_main)
	return _require(
		blocked.get("reason") == "plan_required"
		and _main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF,
		"night one started without a deliberate plan"
	)


func _exercise_bloom_plan_and_preservation() -> bool:
	var owners_before := _owner_snapshot()
	_press_key(KEY_TAB)
	if not _require(
		_main._expedition_plan_panel.highlighted_lead_id() == BLOOM_ID,
		"Tab did not highlight the bloom lead"
	):
		return false
	_press_key(KEY_E)
	if not _require(
		_main._expedition_plan_state.selected_lead_id() == BLOOM_ID
		and _owner_snapshot() == owners_before
		and not _main._anomaly_survey.profile_state().has_completed_discovery(
			ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID
		),
		"pinning the bloom mutated source-owned progression or the relay"
	):
		return false
	var started: Dictionary = ExpeditionDayDebrief.handle_day_key(_main)
	if not _require(
		bool(started.get("changed", false))
		and _main._expedition_day_state.day_number == 2
		and _main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE,
		"pinned bloom did not start day two"
	):
		return false
	_prepare_controlled_map()
	if not _preserved(BLOOM_ID, "next_day"):
		return false
	_bloom_guidance = ExpeditionDayPresentation.selected_plan_line(_main)
	if not _require(_bloom_guidance == BLOOM_GUIDANCE, "bloom guidance did not come from source"):
		return false
	if not _exercise_sorties_offload_and_surface_refill():
		return false

	_main._load_playable_map(PRODUCTION_LEVEL_MAP_PATH, false)
	_prepare_controlled_map()
	if not _preserved(BLOOM_ID, "map_reload"):
		return false
	_main._handle_oxygen_depleted()
	if not _require(_main._sortie_state.failed, "oxygen failure fixture did not fail"):
		return false
	if not _preserved(BLOOM_ID, "failure"):
		return false
	_reset_run()
	_prepare_controlled_map()
	if not _preserved(BLOOM_ID, "reset"):
		return false

	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_process(0.0)
	if not _enter_debrief():
		return false
	var expired: Dictionary = _main._refresh_expedition_plan()
	return _require(
		not _main._expedition_plan_state.has_selection()
		and expired.get("eligible_ids") == [RELAY_ID]
		and not _main._anomaly_survey.profile_state().has_completed_discovery(
			ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID
		),
		"expired bloom did not clear cleanly or auto-selected/mutated the relay"
	)


func _exercise_sorties_offload_and_surface_refill() -> bool:
	var target := _first_ordinary_salvage()
	if not _require(not target.is_empty(), "no ordinary salvage was available for offload coverage"):
		return false
	_player.global_position = target["center"]
	_process(0.0)
	if not _require(
		_main._sortie_state.held_salvage == 1
		and _main._expedition_day_state.sortie_count == 1,
		"first selected-plan sortie did not collect ordinary cargo"
	):
		return false
	if not _preserved(BLOOM_ID, "sortie_1"):
		return false
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_process(0.0)
	if not _require(
		_main._sortie_state.held_salvage == 0
		and _main._banked_salvage_ids.has(str(target.get("id", ""))),
		"boat did not offload selected-plan cargo"
	):
		return false
	if not _preserved(BLOOM_ID, "boat_offload"):
		return false

	_oxygen_seconds = maxf(1.0, _oxygen_capacity_seconds() - 10.0)
	var oxygen_before := _oxygen_seconds
	_process(0.25)
	if not _require(_oxygen_seconds > oxygen_before, "open-surface oxygen did not refill"):
		return false
	if not _preserved(BLOOM_ID, "surface_oxygen"):
		return false

	_player.global_position = target["center"]
	_process(0.0)
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_process(0.0)
	_sortie_count = int(_main._expedition_day_state.sortie_count)
	if not _require(_sortie_count == 2, "repeated sorties counted %d instead of 2" % _sortie_count):
		return false
	return _preserved(BLOOM_ID, "sortie_2")


func _restore_night_one_fixture() -> bool:
	_main._expedition_day_state.begin_day(1)
	_main._load_playable_map(PRODUCTION_LEVEL_MAP_PATH, false)
	_prepare_controlled_map()
	_main._expedition_plan_state.clear("alternate_fixture")
	_main._refresh_expedition_plan()
	if not _enter_debrief():
		return false
	var report: Dictionary = _main._refresh_expedition_plan()
	return _require(
		report.get("eligible_ids") == [RELAY_ID, BLOOM_ID]
		and _main._expedition_plan_panel.highlighted_lead_id() == RELAY_ID,
		"alternate night-one fixture did not restore both source choices"
	)


func _exercise_relay_plan_build_and_resolution() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	if not _prepare_profile_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID):
		return _require(false, "relay build fixture could not establish the cutter prerequisite")
	var project: Dictionary = _main._material_project.project_definition_for(
		ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID
	)
	var required_materials := {}
	for material_id in project.get("required_materials", {}):
		required_materials[str(material_id)] = int(project["required_materials"][material_id])
	var deposit: Dictionary = profile.deposit_materials(required_materials, false)
	_main._material_project.on_map_loaded(_world)
	var requested: bool = _main._material_project.request_project(
		ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID
	)
	_main._refresh_expedition_plan()
	if not _require(
		not project.is_empty()
		and not required_materials.is_empty()
		and bool(deposit.get("changed", false))
		and requested
		and _main._material_project.status_for(
			ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID
		) == "ready",
		"relay build fixture did not derive a ready stabilizer project: "
		+ "project=%s materials=%s deposit=%s requested=%s status=%s profile=%s"
		% [
			str(project),
			str(required_materials),
			str(deposit),
			str(requested),
			_main._material_project.status_for(
				ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID
			),
			str(profile.report()),
		]
	):
		return false
	_press_key(KEY_TAB)
	_press_key(KEY_TAB)
	if not _require(
		_main._expedition_plan_panel.highlighted_lead_id() == RELAY_ID,
		"planner did not cycle back to the relay lead"
	):
		return false
	var owners_before := _owner_snapshot()
	_press_physical_key(KEY_E)
	if not _require(
		_main._expedition_plan_state.selected_lead_id() == RELAY_ID
		and _owner_snapshot() == owners_before
		and _main._daily_conditions.next_ids() == [BLOOM_ID],
		"pinning the relay mutated progression or the unselected bloom"
	):
		return false
	_press_physical_key(KEY_P)
	if not _require(
		profile.has_completed_project(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID)
		and profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID),
		"physical-only P did not complete the source-owned stabilizer"
	):
		return false
	_press_logical_key(KEY_P)
	if not _require(
		_main._last_status_note.find("already built") != -1
		and _main._result_label.text.find("already built") != -1,
		"logical P did not reach visible debrief build feedback"
	):
		return false
	if not _preserved(RELAY_ID, "project_build"):
		return false
	var started: Dictionary = ExpeditionDayDebrief.handle_day_key(_main)
	if not _require(
		bool(started.get("changed", false))
		and _main._expedition_day_state.day_number == 2,
		"pinned relay did not start day two"
	):
		return false
	_prepare_controlled_map()
	_relay_guidance = ExpeditionDayPresentation.selected_plan_line(_main)
	if not _require(
		_relay_guidance == RELAY_GUIDANCE
		and _relay_guidance != _bloom_guidance,
		"relay and bloom did not produce distinct source guidance"
	):
		return false
	var resolution: Dictionary = profile.complete_discovery(
		ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID,
		false
	)
	var resolved_report: Dictionary = _main._refresh_expedition_plan()
	return _require(
		bool(resolution.get("changed", false))
		and not _main._expedition_plan_state.has_selection()
		and resolved_report.get("eligible_ids") == [BLOOM_ID]
		and _main._daily_conditions.current_ids() == [BLOOM_ID],
		"resolved relay did not clear without auto-pinning or mutating the bloom"
	)


func _verify_final_owner_boundaries() -> bool:
	var profile_report: Dictionary = _main._anomaly_survey.profile_state().report()
	return _require(
		int(profile_report.get("schema_version", -1)) == 4
		and not profile_report.has("selected_lead_id")
		and _record_by_id(_world.get_regional_journeys(), RELAY_ID) == _relay_source
		and _record_by_id(_world.get_daily_conditions(), BLOOM_ID) == _bloom_source,
		"planner state leaked into profile/source ownership"
	)


func _verify_projected_lead(
	report: Dictionary,
	source: Dictionary,
	expected_type: String,
	expected_context: String
) -> bool:
	var projected := _lead_by_id(report, str(source.get("id", "")))
	var metadata: Dictionary = source.get("expedition_lead", {})
	return _require(
		not projected.is_empty()
		and projected.get("lead_type") == expected_type
		and projected.get("label") == metadata.get("label")
		and projected.get("summary") == metadata.get("summary")
		and projected.get("active_guidance") == metadata.get("active_guidance")
		and projected.get("order") == metadata.get("order")
		and projected.get("route_context") == source.get("route_context")
		and projected.get("eligibility_context") == expected_context,
		"lead projection drifted from source/state for %s" % source.get("id", "")
	)


func _enter_debrief() -> bool:
	var requested: Dictionary = ExpeditionDayDebrief.handle_day_key(_main)
	if not _require(requested.get("reason") == "requested", "boat did not request day end"):
		return false
	_process(0.0)
	return _require(
		_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF,
		"requested day end did not enter debrief"
	)


func _preserved(lead_id: String, checkpoint: String) -> bool:
	_main._refresh_expedition_plan()
	if not _require(
		_main._expedition_plan_state.selected_lead_id() == lead_id,
		"%s cleared selected lead %s" % [checkpoint, lead_id]
	):
		return false
	_preservation_checkpoints.append(checkpoint)
	return true


func _prepare_controlled_map() -> void:
	_player.set_physics_process(false)
	_main.set_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false
	_player.reset_motion()


func _owner_snapshot() -> Dictionary:
	var profile: Dictionary = _main._anomaly_survey.profile_state().report()
	return {
		"completed_discoveries": profile.get("completed_discoveries", []).duplicate(),
		"completed_projects": profile.get("completed_projects", []).duplicate(),
		"unlocked_capabilities": profile.get("unlocked_capabilities", []).duplicate(),
		"material_inventory": profile.get("material_inventory", {}).duplicate(true),
		"day": _main._expedition_day_state.report(),
		"conditions": _main._daily_conditions.report(),
	}


func _first_ordinary_salvage() -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if (
			str(salvage.get("interaction", "instant")) == "instant"
			and not _world.is_inside_boat(salvage.get("center", Vector2.ZERO))
		):
			return salvage
	return {}


func _lead_by_id(report: Dictionary, lead_id: String) -> Dictionary:
	for value in report.get("eligible_leads", []):
		if typeof(value) == TYPE_DICTIONARY and str(value.get("lead_id", "")) == lead_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for value in records:
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == record_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	_main._unhandled_input(event)


func _press_physical_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	_main._unhandled_input(event)


func _press_logical_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	_main._unhandled_input(event)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Expansion 15 expedition-planning smoke failed: %s." % message)
	get_tree().quit(1)
	return false
