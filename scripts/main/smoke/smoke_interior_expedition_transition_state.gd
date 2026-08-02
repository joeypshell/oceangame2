extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")

const EXTERIOR_MAP_ID := "production_level_01"
const INTERIOR_MAP_ID := "transfer_hub_interior_01"
const ENTRANCE_ID := "transfer_hub_exterior_entrance"
const INTERIOR_RETURN_ID := "transfer_hub_interior_return"
const EXTERIOR_RETURN_ENTRY_ID := "transfer_hub_exterior_return"
const BOAT_ENTRY_ID := "surface_boat_entry"
const PREREQUISITE_ID := "wreck_network_triangulation_discovery"
const MATERIAL_ID := "titanium_scrap"
const BANKED_SALVAGE_ID := "salvage_entry_shaft"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Interior transition smoke stage: main_load")
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	print("Interior transition smoke stage: profile_setup")
	main.set_process(false)
	main._player.set_physics_process(false)
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	_attach_profile(main, profile)
	main._anomaly_survey.on_map_loaded(main._world)
	main._material_runtime.on_map_loaded(main._world, main._expedition_day_state, main._daily_conditions.current_ids())
	main._material_project.on_map_loaded(main._world)
	main._cutter_salvage.on_map_loaded(main._world)
	main._refresh_expedition_plan()
	main._refresh_active_tools()
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	main._combat_interactions_enabled = false

	var entrance := _connector_by_id(main, ENTRANCE_ID)
	_expect(not entrance.is_empty(), "source-authored exterior entrance was unavailable")
	if entrance.is_empty():
		_finish(main)
		return
	main._player.global_position = entrance.get("center", Vector2.ZERO)
	main._update_status_label()
	_expect(main._status_label.text.find("Coordinates not triangulated") != -1, "locked entrance omitted the triangulation requirement")
	_expect(not main._try_world_connector_transition() and main._world.map_id == EXTERIOR_MAP_ID, "locked entrance changed maps")
	print("Interior transition smoke stage: locked_gate_checked")

	var prerequisite: Dictionary = profile.complete_discovery(PREREQUISITE_ID, false)
	_expect(bool(prerequisite.get("changed", false)), "could not prepare triangulation prerequisite")
	var tool_targets: Array = main._world.get_tool_targets()
	_expect(not tool_targets.is_empty(), "no collectable source target was available for the continuity probe")
	if tool_targets.is_empty():
		_finish(main)
		return
	var salvage: Dictionary = tool_targets[0]
	var salvage_id := str(salvage.get("id", ""))
	var salvage_score: int = int(main._world.get_salvage_score(salvage_id))
	_expect(main._world.collect_tool_target(salvage_id), "could not prepare held exterior salvage")
	main._sortie_state.collect_salvage(salvage_id, salvage_score)
	main._sortie_state.active = true
	main._sortie_state.oxygen_seconds = 63.0
	main._player_health.current_health = 2
	main._expedition_day_state.begin_day(2)
	main._expedition_day_state.daylight_remaining_seconds = 211.0
	main._expedition_day_state.sortie_count = 2
	main._expedition_day_state.record_bank(3, 500)
	main._daily_conditions.sync(main._world.get_daily_conditions(), 2)
	main._banked_salvage = 3
	main._banked_salvage_ids.clear()
	main._banked_salvage_ids.append(BANKED_SALVAGE_ID)
	_expect(main._world.collect_salvage_by_id(BANKED_SALVAGE_ID), "could not prepare banked exterior salvage")
	main._banked_score = 500
	main._completion_oxygen_bonus = 17
	main._banked_validation_route_counts = {"transition_probe_route": 1}
	var material: Dictionary = main._material_runtime.collect_biological_source(
		{"id": "transition_probe_material", "material_id": MATERIAL_ID, "material_quantity": 1},
		EXTERIOR_MAP_ID,
		main._sortie_state.held_salvage,
		main._held_salvage_capacity()
	)
	_expect(bool(material.get("changed", false)), "could not prepare held material cargo")
	var selected_plan_id := "transition_probe_plan"
	var selected: Dictionary = main._expedition_plan_state.select(
		selected_plan_id,
		[selected_plan_id],
		"debrief"
	)
	_expect(bool(selected.get("changed", false)), "could not prepare selected expedition plan")

	var total_salvage_before: int = int(main._total_salvage)
	var condition_ids_before: Array[String] = main._daily_conditions.current_ids()
	main._player.global_position = entrance.get("center", Vector2.ZERO)
	main._update_status_label()
	_expect(main._status_label.text.find("E: Enter Transfer Hub") != -1, "unlocked entrance omitted the explicit ACT prompt")
	print("Interior transition smoke stage: entering")
	_expect(main._try_world_connector_transition(), "unlocked entrance did not transition")
	print("Interior transition smoke stage: entered")
	_expect(main._world.map_id == INTERIOR_MAP_ID, "forward transition loaded the wrong map")
	_expect(main._player.global_position == main._world.get_entry_position("transfer_hub_interior_entry"), "interior arrival ignored its source entry")
	_expect(_continuous_values_match(main, selected_plan_id, total_salvage_before, condition_ids_before), "forward transition reset live expedition state")
	_expect(not main._world.is_inside_extraction(main._player.global_position), "interior arrival acted as extraction")

	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	main._combat_interactions_enabled = false
	var oxygen_before_tick: float = main._sortie_state.oxygen_seconds
	var daylight_before_tick: float = main._expedition_day_state.daylight_remaining_seconds
	main._process(1.0)
	_expect(main._sortie_state.oxygen_seconds < oxygen_before_tick, "oxygen stopped advancing inside the hub")
	_expect(main._expedition_day_state.daylight_remaining_seconds < daylight_before_tick, "daylight stopped advancing inside the hub")

	var expected_oxygen: float = main._sortie_state.oxygen_seconds
	var expected_daylight: float = main._expedition_day_state.daylight_remaining_seconds
	var interior_return := _connector_by_id(main, INTERIOR_RETURN_ID)
	_expect(not interior_return.is_empty(), "paired interior return was unavailable")
	main._player.global_position = interior_return.get("center", Vector2.ZERO)
	print("Interior transition smoke stage: returning")
	_expect(main._try_world_connector_transition(), "paired return did not transition")
	print("Interior transition smoke stage: returned")
	_expect(main._world.map_id == EXTERIOR_MAP_ID, "paired return loaded the wrong map")
	_expect(main._player.global_position == main._world.get_entry_position(EXTERIOR_RETURN_ENTRY_ID), "paired return ignored the exterior return entry")
	_expect(is_equal_approx(main._sortie_state.oxygen_seconds, expected_oxygen), "paired return reset oxygen")
	_expect(is_equal_approx(main._expedition_day_state.daylight_remaining_seconds, expected_daylight), "paired return reset daylight")
	_expect(_continuous_values_match(main, selected_plan_id, total_salvage_before, condition_ids_before), "paired return reset live expedition state")
	_expect(main._world.is_salvage_collected(salvage_id), "paired return duplicated held exterior salvage")
	_expect(main._world.is_salvage_collected(BANKED_SALVAGE_ID), "paired return duplicated banked exterior salvage")
	_expect(profile.material_quantity(MATERIAL_ID) == 0, "interior round trip banked held material")

	entrance = _connector_by_id(main, ENTRANCE_ID)
	main._player.global_position = entrance.get("center", Vector2.ZERO)
	print("Interior transition smoke stage: reentering")
	_expect(main._try_world_connector_transition(), "second entry for failure probe did not transition")
	print("Interior transition smoke stage: reentered")
	main._player.set_physics_process(false)
	main._handle_oxygen_depleted()
	_expect(main._sortie_state.failed, "interior oxygen failure did not lock the run")
	_expect(main._interior_expedition_transition.report().get("phase") == "failed", "transition owner did not record failure")
	print("Interior transition smoke stage: retrying")
	main._reset_run()
	print("Interior transition smoke stage: retried")
	_expect(main._world.map_id == EXTERIOR_MAP_ID, "interior Retry did not return to the exterior map")
	_expect(main._player.global_position == main._world.get_entry_position(BOAT_ENTRY_ID), "interior Retry did not return to the canonical boat")
	_expect(not main._sortie_state.failed and main._sortie_state.held_salvage == 0, "interior Retry retained failed cargo state")
	_expect(main._material_runtime.held_count() == 0, "interior Retry retained held material cargo")
	_expect(not main._world.is_salvage_collected(salvage_id), "interior Retry did not restore exterior salvage")
	_expect(main._interior_expedition_transition.report().get("round_trip", {}).is_empty(), "interior Retry retained round-trip identity")
	_finish(main)


func _continuous_values_match(main, selected_plan_id: String, total_salvage: int, condition_ids: Array[String]) -> bool:
	return (
		main._sortie_state.held_salvage == 1
		and main._sortie_state.held_salvage_score > 0
		and main._material_runtime.held_count() == 1
		and main._player_health.current_health == 2
		and main._expedition_day_state.day_number == 2
		and main._expedition_day_state.sortie_count == 2
		and main._expedition_day_state.banked_salvage == 3
		and main._banked_salvage == 3
		and main._banked_score == 500
		and main._banked_salvage_ids == [BANKED_SALVAGE_ID]
		and main._completion_oxygen_bonus == 17
		and main._banked_validation_route_counts == {"transition_probe_route": 1}
		and main._total_salvage == total_salvage
		and main._daily_conditions.current_ids() == condition_ids
		and main._expedition_plan_state.selected_lead_id() == selected_plan_id
	)


func _attach_profile(main, profile) -> void:
	main._anomaly_survey = AnomalySurveyRuntime.new(main._progression_runtime, false, profile)
	main._material_runtime = MaterialRuntimeController.new(profile)
	main._material_project = MaterialProjectRuntime.new(profile)
	main._cutter_salvage = CutterSalvageController.new(profile)


func _connector_by_id(main, connector_id: String) -> Dictionary:
	for connector in main._world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _finish(main) -> void:
	main.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Interior expedition transition smoke failed: %s" % failure)
		quit(1)
		return
	print("Interior expedition transition passed: prerequisite=triangulation action=E/ACT entry=paired continuous=oxygen,daylight,health,cargo,plan return=source_entry banking=boat_only retry=canonical_boat legacy=separate.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
