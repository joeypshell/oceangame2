extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	main.set_process(false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	main._anomaly_survey = AnomalySurveyRuntime.new(main._progression_runtime, false, profile)
	main._material_runtime = MaterialRuntimeController.new(profile)
	main._material_project = MaterialProjectRuntime.new(profile)
	main._cutter_salvage = CutterSalvageController.new(profile)
	main._load_playable_map(main.PRODUCTION_SLICE_MAP_PATH, false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false

	var targets: Array = main._world.get_tool_targets()
	_expect(targets.size() == 1, "slice 01 did not expose exactly one cutter target")
	if targets.is_empty():
		_finish(main)
		return
	var target: Dictionary = targets[0]
	var target_id := str(target.get("id", ""))
	var center: Vector2 = target.get("center", Vector2.ZERO)
	main._player.global_position = center
	var oxygen_before: float = main._sortie_state.oxygen_seconds
	var daylight_before: float = main._expedition_day_state.daylight_remaining_seconds
	main._process(0.25)
	_expect(main._last_status_note == "Sealed wreck | Cutter required", "locked target omitted cutter requirement")
	_expect(not main._world.is_salvage_collected(target_id) and main._sortie_state.held_salvage == 0, "locked target collected or advanced cargo")
	_expect(main._sortie_state.oxygen_seconds < oxygen_before, "oxygen paused at locked cutter target")
	_expect(main._expedition_day_state.daylight_remaining_seconds < daylight_before, "daylight paused at locked cutter target")

	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false)
	profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}, false)
	var built: Dictionary = profile.complete_material_project(main._material_project.project_definition(), false)
	_expect(bool(built.get("changed", false)) and main._cutter_salvage.has_cutter(), "project did not unlock cutter for target")

	main._sortie_state.collect_salvage("capacity_fixture_a", 0)
	main._sortie_state.collect_salvage("capacity_fixture_b", 0)
	main._process(3.0)
	_expect(main._last_status_note.find("Cargo full") != -1, "full cargo did not block cutter target")
	_expect(not main._world.is_salvage_collected(target_id), "cargo-full cutter attempt deleted target")
	main._sortie_state.clear_held()

	main._process(0.5)
	_expect(main._last_status_note.begins_with("Cutting "), "unlocked cutter did not show progress")
	main._player.global_position = center + Vector2(200.0, 0.0)
	main._process(0.0)
	_expect(main._last_status_note == "Cutter interrupted", "leaving range did not cancel cutter progress")
	main._player.global_position = center
	main._process(1.6)
	_expect(not main._world.is_salvage_collected(target_id), "canceled cutter progress resumed instead of restarting")
	main._process(0.5)
	_expect(main._world.is_salvage_collected(target_id), "completed cutter interaction did not collect target")
	_expect(main._sortie_state.held_salvage == 1 and main._sortie_state.held_salvage_score == 300, "cutter payoff did not enter valuable salvage cargo")
	_expect(main._world.get_salvage_tier(target_id) == "valuable", "cutter payoff tier drifted")

	main._handle_hazard_hit("cutter_smoke_hazard")
	_expect(main._sortie_state.held_salvage == 0, "hazard recovery retained cutter payoff cargo")
	_expect(not main._world.get_tool_target_near(center, main.SALVAGE_COLLECTION_RADIUS).is_empty(), "hazard recovery did not restore cutter target")
	_expect(main._cutter_salvage.has_cutter(), "hazard recovery removed durable cutter")
	main._player.global_position = center
	main._process(2.1)
	_expect(main._world.is_salvage_collected(target_id), "restored cutter target could not be recollected")
	_expect(not main._world.collect_tool_target(target_id), "collected cutter target duplicated")
	main._player.global_position = main._world.get_extraction_center()
	main._process(0.0)
	_expect(main._sortie_state.held_salvage == 0 and main._cutter_salvage.is_target_banked(target_id), "boat banking did not commit cutter target identity")
	main._load_playable_map(main.PRODUCTION_SLICE_MAP_PATH, false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	_expect(main._world.get_tool_target_near(center, main.SALVAGE_COLLECTION_RADIUS).is_empty(), "banked cutter target respawned after map reload")
	main._reset_run()
	_expect(main._world.get_tool_target_near(center, main.SALVAGE_COLLECTION_RADIUS).is_empty(), "banked cutter target respawned after manual reset")
	_expect(main._cutter_salvage.has_cutter(), "manual reset removed durable cutter")

	_finish(main)


func _finish(main) -> void:
	main.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Cutter salvage state smoke failed: %s" % failure)
		quit(1)
		return
	print("Cutter salvage state smoke passed: target=salvage_sealed_wreck_cache locked=true oxygen_daylight_continue=true cargo_blocked=true cancel_on_leave=true seconds=2.0 payoff=valuable:300 hazard_restore=true bank_reload_guard=true reset_guard=true duplicate=false cutter_durable=true.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
