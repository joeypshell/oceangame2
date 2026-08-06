extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CompanionJourneyGuidance := preload("res://scripts/companion/companion_journey_guidance.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MovingHazardController := preload("res://scripts/main/moving_hazard_controller.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const TRACE_ID := "southwest_bloom_migration_trace"
const OBSERVATION_ID := "southwest_bloom_migration_observation"
const CONDITION_ID := "southwest_jellyfish_bloom"
const MEMORY_ID := "followed_the_bloom"
const ADAPTATION_ID := "drift_lens"
const KITE_ID := "spark_ray_juvenile_01"

var _failures: Array[String] = []
var _status_notes: Array[String] = []


class DayState:
	extends RefCounted
	var phase := "active"
	var sortie_count := 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player = PLAYER_SCENE.instantiate()
	get_root().add_child(player)
	player.set_physics_process(false)
	await process_frame

	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var survey := AnomalySurveyRuntime.new(null, false, profile)
	var checkpoint: Dictionary = ReviewCheckpointFixture.apply(
		ReviewCheckpointFixture.LIVING_EXPEDITION_03_START,
		profile
	)
	_expect(bool(checkpoint.get("ready", false)), "Day 2 review checkpoint failed: %s" % checkpoint)
	_expect(int(checkpoint.get("day_number", 0)) == 2, "checkpoint did not declare Day 2")

	var hazards := MovingHazardController.new()
	hazards.reset(world, [CONDITION_ID])
	var sortie := CompanionSortieRuntime.new()
	get_root().add_child(sortie)
	await process_frame
	sortie.bind_interface(null, Callable(self, "_record_status"), Callable(), Callable(self, "_control_allowed"))
	var launch: Dictionary = sortie.bind_map(
		world,
		player,
		profile,
		Callable(self, "_has_no_upgrade"),
		true,
		false,
		null,
		hazards,
		[CONDITION_ID]
	)
	_expect(bool(launch.get("spawned", false)) and str(launch.get("active_species_id", "")) == "veil_cuttle", "checkpoint did not launch selected Mica")
	_expect(_command_ids(sortie).find("mount") == -1, "Mica inherited Kite Mount")
	var guidance := CompanionJourneyGuidance.new()
	var initial_guidance: String = guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(initial_guidance.find("Southwest Jellyfish Bloom") != -1, "guidance did not name the real bloom")

	survey.bind_ecological_identification_sink(Callable(sortie, "observe_ecological_identification"))
	survey.on_map_loaded(world)
	var trace := _record_by_id(world.get_ecological_traces(), TRACE_ID)
	var mica = sortie.companion()
	mica.global_position = trace.get("center", Vector2.ZERO) + Vector2(-40.0, 0.0)
	player.global_position = mica.global_position + Vector2(-20.0, 0.0)
	sortie.control_runtime()._process(0.0)
	_expect(bool(mica.report().get("presentation", {}).get("ecology_interest_visible", false)), "Mica did not visibly react to the in-range hidden migration")
	var first: Dictionary = _reveal_and_identify(world, player, sortie, survey)
	_expect(bool(first.get("ready", false)), "first observation setup failed: %s" % first)
	_expect(str(sortie.memory_report().get("ecology", {}).get("pending_observation_id", "")) == OBSERVATION_ID, "held Scanner completion did not create pending observation")
	_expect(not _active_individual(profile).get("earned_memory_ids", []).has(MEMORY_ID), "identification committed memory before boat return")

	var discarded: Dictionary = sortie.discard_uncommitted_memories("hazard")
	sortie.reset_control("hazard")
	_expect(bool(discarded.get("changed", false)), "hazard did not discard uncommitted ecology state")
	_expect(str(sortie.memory_report().get("ecology", {}).get("pending_observation_id", "")).is_empty(), "hazard retained pending observation")
	_expect(_trace_state(world) == "hidden", "hazard reset retained revealed trace")

	survey.on_map_loaded(world)
	var second: Dictionary = _reveal_and_identify(world, player, sortie, survey)
	_expect(bool(second.get("ready", false)), "second observation setup failed: %s" % second)
	player.global_position = world.get_entry_position("surface_boat_entry")
	var committed: Dictionary = sortie.commit_memories_at_boat()
	_expect(bool(committed.get("changed", false)) and committed.get("memory_id") == MEMORY_ID, "canonical boat did not commit Mica memory: %s" % committed)
	var duplicate: Dictionary = sortie.commit_memories_at_boat()
	_expect(not bool(duplicate.get("changed", false)), "boat return duplicated committed memory")

	sortie.begin_debrief()
	_expect(sortie.requires_adaptation_selection(), "committed memory did not expose deliberate night choice")
	var consolidated: Dictionary = sortie.handle_debrief_input(_action_event("active_tool_use"))
	_expect(bool(consolidated.get("changed", false)) and consolidated.get("adaptation_id") == ADAPTATION_ID, "night did not consolidate Drift Lens")
	sortie.end_debrief()
	var mica_next_launch: Dictionary = sortie.bind_map(
		world,
		player,
		profile,
		Callable(self, "_has_no_upgrade"),
		true,
		false,
		null,
		hazards,
		[CONDITION_ID]
	)
	_expect(str(mica_next_launch.get("active_species_id", "")) == "veil_cuttle", "next sortie did not restore Mica")
	_expect(_command_ids(sortie).has("read_drift"), "next-sortie Mica palette omitted Read Drift")

	var capability_snapshot: Array = profile.report().get("unlocked_capabilities", []).duplicate()
	profile.select_active_companion(KITE_ID, false)
	var kite_launch: Dictionary = sortie.bind_map(
		world,
		player,
		profile,
		Callable(self, "_has_no_upgrade"),
		true,
		false,
		null,
		hazards,
		[CONDITION_ID]
	)
	_expect(str(kite_launch.get("active_species_id", "")) == "spark_ray", "Kite selection did not restore Spark Ray runtime")
	_expect(_command_ids(sortie).has("mount") and not _command_ids(sortie).has("read_drift"), "Kite action ownership leaked Mica's field action")
	_expect(profile.report().get("unlocked_capabilities", []) == capability_snapshot, "ecology journey changed equipment access")
	_expect(profile.material_inventory().is_empty(), "ecology journey granted materials")

	sortie.clear_map()
	sortie.queue_free()
	player.queue_free()
	world.queue_free()
	Engine.time_scale = 1.0
	_finish()


func _reveal_and_identify(world, player, sortie, survey) -> Dictionary:
	var trace := _record_by_id(world.get_ecological_traces(), TRACE_ID)
	var mica = sortie.companion()
	if trace.is_empty() or mica == null:
		return {"ready": false, "reason": "fixture_missing"}
	mica.global_position = trace.get("center", Vector2.ZERO) + Vector2(-40.0, 0.0)
	player.global_position = mica.global_position + Vector2(-20.0, 0.0)
	mica.advance(0.0)
	var reveal: Dictionary = _dispatch_command(sortie, "reveal_trace")
	if not bool(reveal.get("changed", false)):
		return {"ready": false, "reason": "reveal_failed", "detail": reveal}
	var activated: Dictionary = survey.scanner_action(world, player)
	if str(activated.get("reason", "")) != "activated":
		return {"ready": false, "reason": "scanner_not_held", "detail": activated}
	var partial: Dictionary = survey.update(world, player, 0.75)
	if str(partial.get("reason", "")) != "progress":
		return {"ready": false, "reason": "scanner_no_progress", "detail": partial}
	var identified: Dictionary = survey.update(world, player, 0.8)
	return {
		"ready": str(identified.get("reason", "")) == "identified",
		"reason": str(identified.get("reason", "")),
		"partial_progress": float(survey.report().get("identification", {}).get("progress", 0.0)),
	}


func _dispatch_command(sortie, action_id: String) -> Dictionary:
	var control = sortie.control_runtime()
	control.begin_command_mode()
	var commands: Array = control.report().get("context_commands", [])
	for index in range(commands.size()):
		if str(commands[index].get("id", "")) != action_id:
			continue
		for _step in range(index):
			control.cycle_context_command()
		return control.confirm_context_command()
	control.end_command_mode()
	return {"changed": false, "reason": "command_missing"}


func _command_ids(sortie) -> Array[String]:
	var ids: Array[String] = []
	for command in sortie.control_runtime().report().get("context_commands", []):
		ids.append(str(command.get("id", "")))
	return ids


func _active_individual(profile) -> Dictionary:
	return profile.companion_report().get("individual", {})


func _trace_state(world) -> String:
	return str(world.get_ecological_trace_report().get("states", {}).get(TRACE_ID, ""))


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str(record.get("id", "")) == record_id:
			return record
	return {}


func _action_event(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _record_status(note: String) -> void:
	if not note.is_empty():
		_status_notes.append(note)


func _control_allowed() -> bool:
	return true


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Living Expedition 03 integration smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Living Expedition 03 integration checkpoint=Day2+Kite+Mica+Scanner active=Mica bloom=active reveal=BOND identification=held_1.5s pending=no_reward failure=cleared boat=memory_exact_once night=Drift_Lens_deliberate next_sortie=Read_Drift Kite=restored access_unchanged=true materials=none.")
	quit(0)
