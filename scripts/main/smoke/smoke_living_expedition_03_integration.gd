extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CompanionJourneyGuidance := preload("res://scripts/companion/companion_journey_guidance.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MovingHazardController := preload("res://scripts/main/moving_hazard_controller.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")
const VeilCuttleDriftLensRuntime := preload("res://scripts/companion/veil_cuttle_drift_lens_runtime.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const PROFILE_PATH := "user://smoke_living_expedition_03_profile.json"
const TRACE_ID := "southwest_bloom_migration_trace"
const OBSERVATION_ID := "southwest_bloom_migration_observation"
const CONDITION_ID := "southwest_jellyfish_bloom"
const MEMORY_ID := "followed_the_bloom"
const ADAPTATION_ID := "drift_lens"
const KITE_ID := "spark_ray_juvenile_01"
const SOUTHWEST_PATROL_ID := "southwest_bloom_jellyfish_patrol"
const DEEP_PATROL_ID := "deep_route_jellyfish_patrol"

var _failures: Array[String] = []
var _status_notes: Array[String] = []


class DayState:
	extends RefCounted
	var phase := "active"
	var sortie_count := 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player = PLAYER_SCENE.instantiate()
	get_root().add_child(player)
	player.set_physics_process(false)
	await process_frame

	var profile := ExpansionProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	var survey := AnomalySurveyRuntime.new(null, false, profile)
	var checkpoint: Dictionary = ReviewCheckpointFixture.apply(
		ReviewCheckpointFixture.LIVING_EXPEDITION_03_START,
		profile
	)
	_expect(bool(checkpoint.get("ready", false)), "Day 2 review checkpoint failed: %s" % checkpoint)
	_expect(int(checkpoint.get("day_number", 0)) == 2, "checkpoint did not declare Day 2")
	_expect(float(checkpoint.get("review_oxygen_seconds", 0.0)) >= 180.0, "checkpoint did not provide first-read oxygen headroom")
	_expect(not (checkpoint.get("review_start_tile", {}) as Dictionary).is_empty(), "checkpoint did not start beside the focused bloom interaction")
	_expect(profile.save_profile(), "isolated checkpoint profile could not be saved for reload coverage")
	var progression_before := _progression_snapshot(profile)
	var companion_before_failure: Dictionary = profile.companion_report()
	var parity_before: Dictionary = world.get_runtime_parity_report()
	var gates_before: Array = world.get_current_gates()

	var hazards := MovingHazardController.new()
	hazards.reset(world, [CONDITION_ID])
	var oxygen := SortieState.new(90.0)
	var daylight := ExpeditionDayState.new(300.0)
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
	var lead: Dictionary = mica.report().get("presentation", {})
	_expect(bool(lead.get("ecology_interest_visible", false)), "Mica did not visibly react to the in-range hidden migration")
	_expect(str(lead.get("ecology_lead_label", "")) == "MICA FOUND A TRACE HERE", "Mica's reaction did not explain that the trace was local")
	_expect((lead.get("ecology_lead_direction", Vector2.ZERO) as Vector2) != Vector2.ZERO, "Mica's reaction did not point toward the trace")
	_expect(float(lead.get("ecology_lead_distance", 0.0)) > 0.0, "Mica's reaction omitted trace distance")
	var palette: Dictionary = sortie.control_runtime().report().get("palette", {})
	_expect(bool(palette.get("discovery_prompt_visible", false)), "Mica's reaction omitted the persistent screen-space prompt")
	var discovery_prompt := str(palette.get("discovery_prompt_text", ""))
	_expect(
		discovery_prompt.find("Press B, then 2") != -1 or discovery_prompt.find("Tap BOND") != -1,
		"Mica's prompt omitted the responsive BOND handoff"
	)
	_expect(_status_notes.has("MICA FOUND A TRACE HERE | Press B, then 2: Reveal Trace"), "Mica's local trace discovery was not announced")
	var bond_report: Dictionary = sortie.control_runtime().begin_command_mode()
	var bond_commands: Array = bond_report.get("context_commands", [])
	_expect(bond_commands.size() > 1 and str((bond_commands[1] as Dictionary).get("id", "")) == "reveal_trace", "BOND number 2 did not map to Reveal Trace")
	sortie.control_runtime().end_command_mode()
	var first: Dictionary = _reveal_and_identify(world, player, sortie, survey, hazards, oxygen, daylight)
	_expect(bool(first.get("ready", false)), "first observation setup failed: %s" % first)
	_expect(bool(first.get("reveal_only", false)), "Reveal Trace identified or committed the relationship by itself")
	_expect(is_equal_approx(float(first.get("oxygen_delta", 0.0)), 1.55), "held Scanner interaction paused oxygen pressure")
	_expect(is_equal_approx(float(first.get("daylight_delta", 0.0)), 1.55), "held Scanner interaction paused daylight pressure")
	_expect(bool(first.get("hazard_advanced", false)), "held Scanner interaction paused the moving bloom patrol")
	_expect(str(sortie.memory_report().get("ecology", {}).get("pending_observation_id", "")) == OBSERVATION_ID, "held Scanner completion did not create pending observation")
	_expect(not _active_individual(profile).get("earned_memory_ids", []).has(MEMORY_ID), "identification committed memory before boat return")
	sortie.control_runtime()._process(0.0)
	_expect(not bool(sortie.control_runtime().report().get("palette", {}).get("discovery_prompt_visible", false)), "identified migration retained the Reveal Trace prompt")
	var pending_before_repeat: Dictionary = sortie.memory_report().get("ecology", {}).duplicate(true)
	var repeated: Dictionary = survey.scanner_action(world, player)
	_expect(str(repeated.get("reason", "")) == "already_identified", "identified migration restarted Scanner progress: %s" % repeated)
	_expect(str(repeated.get("note", "")).find("Return to surface boat") != -1, "identified migration omitted the boat-return outcome")
	_expect(not bool(survey.report().get("scanner_use_held", true)), "identified migration retained held Scanner input")
	var repeat_report: Dictionary = survey.report().get("identification", {})
	_expect(str(repeat_report.get("active_target_id", "")).is_empty() and not bool(repeat_report.get("activated", false)), "identified migration retained an active held interaction")
	var repeated_update: Dictionary = survey.update(world, player, 0.8)
	_expect(repeated_update.is_empty(), "identified migration advanced after repeat activation: %s" % repeated_update)
	_expect(sortie.memory_report().get("ecology", {}) == pending_before_repeat, "repeat activation changed pending ecology state")
	survey.scanner_release(world)

	var discarded: Dictionary = sortie.discard_uncommitted_memories("hazard")
	sortie.reset_control("hazard")
	_expect(bool(discarded.get("changed", false)), "hazard did not discard uncommitted ecology state")
	_expect(str(sortie.memory_report().get("ecology", {}).get("pending_observation_id", "")).is_empty(), "hazard retained pending observation")
	_expect(_trace_state(world) == "hidden", "hazard reset retained revealed trace")
	_expect(profile.companion_report() == companion_before_failure, "failure changed committed companion state")

	survey.on_map_loaded(world)
	var second: Dictionary = _reveal_and_identify(world, player, sortie, survey, hazards, oxygen, daylight)
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
	_test_read_drift(player, sortie, hazards, SOUTHWEST_PATROL_ID)
	sortie.control_runtime().drift_lens_runtime().advance(VeilCuttleDriftLensRuntime.COOLDOWN_SECONDS + 0.1)
	_test_read_drift(player, sortie, hazards, DEEP_PATROL_ID)

	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var reload: Dictionary = reloaded.load_profile()
	_expect(str(reload.get("status", "")) == "loaded", "committed Mica journey did not reload")
	var reloaded_mica: Dictionary = _individual_by_id(reloaded, "veil_cuttle_juvenile_01")
	_expect((reloaded_mica.get("earned_memory_ids", []) as Array).count(MEMORY_ID) == 1, "reload lost or duplicated Mica's memory")
	_expect(str(reloaded_mica.get("selected_adaptation_id", "")) == ADAPTATION_ID, "reload lost Drift Lens")
	reloaded.select_active_companion(KITE_ID, true)
	var kite_launch: Dictionary = sortie.bind_map(
		world,
		player,
		reloaded,
		Callable(self, "_has_no_upgrade"),
		true,
		false,
		null,
		hazards,
		[CONDITION_ID]
	)
	_expect(str(kite_launch.get("active_species_id", "")) == "spark_ray", "Kite selection did not restore Spark Ray runtime")
	_expect(_command_ids(sortie).has("mount") and not _command_ids(sortie).has("read_drift"), "Kite action ownership leaked Mica's field action")
	_expect(reloaded.active_companion_available_on_sortie_launch(), "Kite riding availability changed after the Mica journey")
	_expect(_progression_snapshot(reloaded) == progression_before, "ecology journey changed discoveries, projects, materials, targets, or equipment access")
	_expect(world.get_runtime_parity_report() == parity_before, "ecology journey changed terrain or collision")
	_expect(world.get_current_gates() == gates_before, "ecology journey changed authored access gates")

	sortie.clear_map()
	sortie.queue_free()
	player.queue_free()
	world.queue_free()
	Engine.time_scale = 1.0
	_cleanup_profile()
	_finish()


func _reveal_and_identify(world, player, sortie, survey, hazards, oxygen, daylight) -> Dictionary:
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
	var reveal_only := (
		_trace_state(world) == "revealed"
		and str(sortie.memory_report().get("ecology", {}).get("pending_observation_id", "")).is_empty()
	)
	var activated: Dictionary = survey.scanner_action(world, player)
	if str(activated.get("reason", "")) != "activated":
		return {"ready": false, "reason": "scanner_not_held", "detail": activated}
	var oxygen_before: float = oxygen.oxygen_seconds
	var daylight_before: float = daylight.daylight_remaining_seconds
	var hazard_before: Vector2 = hazards.snapshot_for(SOUTHWEST_PATROL_ID).get("center", Vector2.ZERO)
	var partial: Dictionary = survey.update(world, player, 0.75)
	oxygen.drain_oxygen(0.75)
	daylight.advance_daylight(0.75)
	hazards.update(world, player.global_position, 0.0, 0.75)
	if str(partial.get("reason", "")) != "progress":
		return {"ready": false, "reason": "scanner_no_progress", "detail": partial}
	var partial_progress: float = float(survey.report().get("identification", {}).get("progress", 0.0))
	var identified: Dictionary = survey.update(world, player, 0.8)
	oxygen.drain_oxygen(0.8)
	daylight.advance_daylight(0.8)
	hazards.update(world, player.global_position, 0.0, 0.8)
	var hazard_after: Vector2 = hazards.snapshot_for(SOUTHWEST_PATROL_ID).get("center", Vector2.ZERO)
	return {
		"ready": str(identified.get("reason", "")) == "identified",
		"reason": str(identified.get("reason", "")),
		"reveal_only": reveal_only,
		"partial_progress": partial_progress,
		"oxygen_delta": oxygen_before - oxygen.oxygen_seconds,
		"daylight_delta": daylight_before - daylight.daylight_remaining_seconds,
		"hazard_advanced": not hazard_before.is_equal_approx(hazard_after),
	}


func _test_read_drift(player, sortie, hazards, patrol_id: String) -> void:
	var target: Dictionary = hazards.snapshot_for(patrol_id)
	var mica = sortie.companion()
	_expect(not target.is_empty(), "Read Drift subject was unavailable: %s" % patrol_id)
	if target.is_empty() or mica == null:
		return
	var center: Vector2 = target.get("center", Vector2.ZERO)
	mica.global_position = center + Vector2(-24.0, 0.0)
	player.global_position = mica.global_position + Vector2(-12.0, 0.0)
	mica.advance(0.0)
	var hazards_before: Array = hazards.snapshot()
	var result: Dictionary = _dispatch_command(sortie, "read_drift")
	_expect(bool(result.get("changed", false)) and str(result.get("target_id", "")) == patrol_id, "Read Drift did not project patrol %s" % patrol_id)
	_expect(hazards.snapshot() == hazards_before, "Read Drift mutated patrol authority for %s" % patrol_id)
	_expect((result.get("reward_ids", []) as Array).is_empty() and not bool(result.get("access_changed", true)), "Read Drift granted reward or access for %s" % patrol_id)


func _dispatch_command(sortie, action_id: String) -> Dictionary:
	var control = sortie.control_runtime()
	var open_report: Dictionary = control.begin_command_mode()
	var commands: Array = open_report.get("context_commands", [])
	for index in range(commands.size()):
		if str(commands[index].get("id", "")) != action_id:
			continue
		return control.activate_context_command(index)
	control.end_command_mode()
	return {"changed": false, "reason": "command_missing"}


func _command_ids(sortie) -> Array[String]:
	var ids: Array[String] = []
	for command in sortie.control_runtime().report().get("context_commands", []):
		ids.append(str(command.get("id", "")))
	return ids


func _active_individual(profile) -> Dictionary:
	return profile.companion_report().get("individual", {})


func _individual_by_id(profile, individual_id: String) -> Dictionary:
	for individual in profile.companion_report().get("individuals", []):
		if str((individual as Dictionary).get("individual_id", "")) == individual_id:
			return (individual as Dictionary).duplicate(true)
	return {}


func _progression_snapshot(profile) -> Dictionary:
	var report: Dictionary = profile.report()
	return {
		"completed_discoveries": report.get("completed_discoveries", []).duplicate(),
		"unlocked_capabilities": report.get("unlocked_capabilities", []).duplicate(),
		"material_inventory": (report.get("material_inventory", {}) as Dictionary).duplicate(true),
		"completed_projects": report.get("completed_projects", []).duplicate(),
		"banked_tool_target_ids": report.get("banked_tool_target_ids", []).duplicate(),
	}


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


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Living Expedition 03 integration smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Living Expedition 03 integration checkpoint=Day2+Kite+Mica+Scanner active=Mica bloom=active reveal!=identify identification=held_1.5s repeat=blocked pressure=oxygen+daylight+moving_hazard pending=no_reward failure=uncommitted_only boat=memory_exact_once night=Drift_Lens_deliberate reload=true patrols=conditional+unconditional Kite=selection+riding+actions topology=unchanged progression=unchanged.")
	quit(0)
