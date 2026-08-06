extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CompanionJourneyGuidance := preload("res://scripts/companion/companion_journey_guidance.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const CompanionRescueRuntime := preload("res://scripts/companion/companion_rescue_runtime.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ReviewProfileMode := preload("res://scripts/main/review_profile_mode.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const PROFILE_PATH := "user://smoke_two_species_sortie_profile.json"
const KITE_ID := "spark_ray_juvenile_01"
const MICA_ID := "veil_cuttle_juvenile_01"
const MICA_RESCUE_ID := "veil_cuttle_rescue_01"
const TRACE_ID := "southwest_bloom_migration_trace"
const BLOOM_CONDITION_ID := "southwest_jellyfish_bloom"
const PROTECTED_GATE_ID := "upper_right_current_pocket_gate"

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
	var checkpoint_id := ReviewProfileMode.checkpoint_id(OS.get_cmdline_user_args(), OS.get_cmdline_args())
	_expect(checkpoint_id == ReviewCheckpointFixture.LIVING_EXPEDITION_02_START, "journey requires the isolated Living Expedition 02 checkpoint")
	_test_schema_v1_migration()
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	world.configure_moving_hazards([BLOOM_CONDITION_ID])
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	await physics_frame

	var profile := ExpansionProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	var checkpoint: Dictionary = ReviewCheckpointFixture.apply(checkpoint_id, profile)
	_expect(bool(checkpoint.get("ready", false)), "Living Expedition 02 checkpoint was rejected: %s" % checkpoint)
	_expect(profile.save_profile(), "checkpoint profile could not be persisted for reload coverage")
	var checkpoint_companion: Dictionary = profile.companion_report()
	_expect((checkpoint_companion.get("individuals", []) as Array).size() == 1, "checkpoint did not begin with exactly one committed partner")
	_expect(str(checkpoint_companion.get("active_individual_id", "")) == KITE_ID, "checkpoint did not begin with Kite selected")
	_test_gate_protection(world)
	var rescue := CompanionRescueRuntime.new()
	get_root().add_child(rescue)
	rescue.bind_map(
		world,
		player,
		profile,
		Callable(self, "_has_no_upgrade"),
		Callable(profile, "has_capability"),
		34.0
	)
	var mica_source := _record_by_id(world.get_creature_rescues(), MICA_RESCUE_ID)
	_expect(not mica_source.is_empty(), "Mica rescue source was unavailable")
	_expect(_rescue_state(world, "spark_ray_rescue_01") == "committed", "Kite rescue did not project its own committed state")
	_expect(_rescue_state(world, MICA_RESCUE_ID) == "available", "Kite commitment incorrectly consumed Mica's rescue")
	if mica_source.is_empty():
		_finish(world, player, rescue, null)
		return

	_test_pending_failure(world, player, profile, rescue, mica_source)
	await _test_commit_and_species_sorties(world, player, profile, rescue, mica_source)
	_finish(world, player, rescue, null)


func _test_pending_failure(world, player, profile, rescue, mica_source: Dictionary) -> void:
	player.global_position = mica_source.get("center", Vector2.ZERO)
	var full_cargo := SortieState.new(90.0)
	full_cargo.collect_salvage("full_a", 100)
	full_cargo.collect_salvage("full_b", 100)
	var cargo_snapshot := full_cargo.report()
	_expect(bool(rescue.activate().get("changed", false)), "Kite commitment blocked the Mica rescue")
	var released: Dictionary = rescue.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	_expect(str(released.get("state", "")) == "complete", "Mica Cutter rescue did not complete")
	var pending = rescue.pending_companion()
	_expect(pending != null and str(pending.report().get("species_id", "")) == "veil_cuttle", "Mica rescue spawned the wrong species")
	_expect(full_cargo.report() == cargo_snapshot, "Mica rescue changed full cargo")
	_expect((profile.companion_report().get("individuals", []) as Array).size() == 1, "pending Mica rescue wrote durable profile state")
	var reset: Dictionary = rescue.reset_for_failure("oxygen_failure")
	_expect(bool(reset.get("changed", false)), "failure did not discard pending Mica rescue")
	_expect(rescue.pending_companion() == null and _rescue_state(world, MICA_RESCUE_ID) == "available", "failure did not restore Mica's source opportunity")
	_expect(str(profile.companion_report().get("active_individual_id", "")) == KITE_ID, "failure changed active Kite selection")


func _test_commit_and_species_sorties(world, player, profile, rescue, mica_source: Dictionary) -> void:
	player.global_position = mica_source.get("center", Vector2.ZERO)
	rescue.activate()
	rescue.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	player.global_position = world.get_entry_position("surface_boat_entry")
	var committed: Dictionary = rescue.commit_at_boat()
	_expect(bool(committed.get("changed", false)), "canonical boat did not commit Mica")
	_expect(str(profile.companion_report().get("active_individual_id", "")) == KITE_ID, "second commitment silently replaced active Kite")
	_expect((profile.companion_report().get("individuals", []) as Array).size() == 2, "Mica commitment did not produce exactly two individuals")
	var duplicate: Dictionary = rescue.commit_at_boat()
	_expect(not bool(duplicate.get("changed", false)), "Mica commitment duplicated at the boat")

	var sortie := CompanionSortieRuntime.new()
	get_root().add_child(sortie)
	sortie.bind_interface(null, Callable(self, "_record_status"), Callable(), Callable(self, "_control_allowed"))
	sortie.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), false)
	var habitat: Dictionary = sortie.report().get("habitat", {})
	_expect(int(habitat.get("individual_count", 0)) == 2, "boat habitat did not project both committed individuals")
	_expect(sortie.handle_input(_action_event("companion_command")), "BOND did not open two-partner habitat selection")
	sortie.handle_input(_action_event("active_tool_cycle_next"))
	sortie.handle_input(_action_event("active_tool_use"))
	_expect(str(profile.companion_report().get("active_individual_id", "")) == MICA_ID, "boat selection did not choose Mica for the next sortie")

	var trace := _record_by_id(world.get_ecological_traces(), TRACE_ID)
	player.global_position = trace.get("center", Vector2.ZERO) + Vector2(-56.0, 0.0)
	await process_frame
	await process_frame
	var mica_launch: Dictionary = sortie.sync_spawn()
	var mica = sortie.companion()
	_expect(bool(mica_launch.get("spawned", false)) and mica != null, "selected Mica did not launch")
	_expect(str(mica_launch.get("active_species_id", "")) == "veil_cuttle", "Mica selection instantiated the wrong species")
	var mica_commands: Array = sortie.control_runtime().report().get("context_commands", [])
	_expect(_command_ids(mica_commands) == ["recall", "reveal_trace"], "Mica sortie projected the wrong BOND actions")
	_expect(not sortie.hides_diver_hotbar() and not sortie.control_runtime().is_mounted(), "Mica sortie inherited mounted hotbar ownership")
	var guidance := CompanionJourneyGuidance.new()
	var mica_guidance: String = guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(mica_guidance.find("Reveal Trace") != -1 and mica_guidance.find("Mount") == -1, "Mica field guidance did not explain her first action")

	var reveal: Dictionary = _reveal_trace(sortie, mica, player, trace)
	_expect(bool(reveal.get("changed", false)), "integrated Mica BOND action did not reveal the trace")
	_expect(str(profile.companion_report().get("active_individual_id", "")) == MICA_ID, "field command changed the selected companion mid-sortie")
	var revealed_guidance: String = guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(revealed_guidance.find("Scanner") != -1, "revealed trace guidance did not hand control back to the scanner")
	_test_scanner_identification(world, player, profile, guidance, sortie)

	var profile_before_failure: Dictionary = profile.companion_report()
	for reason in ["oxygen_failure", "combat_defeat", "hazard", "retry"]:
		var reset_reveal: Dictionary = _reveal_trace(sortie, mica, player, trace)
		_expect(bool(reset_reveal.get("changed", false)), "%s fixture could not prepare a revealed trace" % reason)
		if reason == "retry":
			sortie.reset_control(reason)
		else:
			sortie.recover_to_player(reason)
		var reset_report: Dictionary = sortie.control_runtime().report()
		_expect(_trace_state(world) == "hidden", "%s retained transient trace visibility" % reason)
		_expect(not reset_report.get("command_mode", true) and is_zero_approx(float(reset_report.get("trace", {}).get("cooldown_seconds", -1.0))) and is_equal_approx(Engine.time_scale, 1.0), "%s retained command, cooldown, or slow-time state" % reason)
		_expect(profile.companion_report() == profile_before_failure, "%s changed committed individuals or active selection" % reason)

	player.global_position = world.get_entry_position("surface_boat_entry")
	await process_frame
	await process_frame
	_expect(sortie.companion() == null, "returning Mica to the habitat retained a live sortie instance")
	sortie.handle_input(_action_event("companion_command"))
	sortie.handle_input(_action_event("active_tool_cycle_next"))
	sortie.handle_input(_action_event("active_tool_use"))
	_expect(str(profile.companion_report().get("active_individual_id", "")) == KITE_ID, "boat selection did not restore Kite")
	player.global_position = world.get_salvage_centers()[0].get("center", Vector2.ZERO)
	var kite_launch: Dictionary = sortie.sync_spawn()
	_expect(str(kite_launch.get("active_species_id", "")) == "spark_ray", "Kite selection did not restore the Spark Ray runtime")
	_expect(_command_ids(sortie.control_runtime().report().get("context_commands", [])).has("mount"), "Kite selection did not restore Mount")
	_expect(not _command_ids(sortie.control_runtime().report().get("context_commands", [])).has("reveal_trace"), "Kite inherited Mica's field action")

	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var reload_report: Dictionary = reloaded.load_profile()
	_expect(str(reload_report.get("status", "")) == "loaded", "two-companion profile did not reload")
	_expect((reloaded.companion_report().get("individuals", []) as Array).size() == 2, "reload duplicated or lost a companion")
	_expect(str(reloaded.companion_report().get("active_individual_id", "")) == KITE_ID, "reload lost the selected companion")
	sortie.clear_map()
	sortie.queue_free()


func _test_scanner_identification(world, player, profile, guidance, sortie) -> void:
	var survey := AnomalySurveyRuntime.new(null, false, profile)
	survey.on_map_loaded(world)
	var profile_before: Dictionary = profile.companion_report()
	var identified: Dictionary = survey.scanner_action(world, player)
	_expect(str(identified.get("reason", "")) == "identified", "scanner did not identify Mica's revealed trace: %s" % [identified])
	_expect(_trace_state(world) == "identified", "scanner result did not mark the transient trace identified")
	_expect(profile.companion_report() == profile_before, "optional trace identification changed companion progression")
	var text: String = guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(text.find("No cargo or access reward") != -1, "identified trace guidance implied a progression reward")


func _test_schema_v1_migration() -> void:
	var state := CompanionProfileState.new()
	var failures: Array[String] = state.load_payload({
		"schema_version": CompanionProfileState.LEGACY_PROFILE_SCHEMA_VERSION,
		"individual": {
			"individual_id": KITE_ID,
			"species_id": "spark_ray",
			"callsign": "Kite",
			"rescue_committed": true,
			"earned_memory_ids": [],
			"selected_adaptation_id": "",
		},
		"active_individual_id": KITE_ID,
	})
	var report: Dictionary = state.report()
	_expect(failures.is_empty(), "schema-v1 migration failed: %s" % [failures])
	_expect(int(report.get("schema_version", 0)) == CompanionProfileState.PROFILE_SCHEMA_VERSION, "schema-v1 migration did not produce profile schema v2")
	_expect((report.get("individuals", []) as Array).size() == 1 and str(report.get("active_individual_id", "")) == KITE_ID, "schema-v1 migration duplicated or deselected Kite")


func _test_gate_protection(world) -> void:
	var gate_profile := ExpansionProfileState.new("", false)
	gate_profile.load_profile()
	gate_profile.commit_companion_rescue(MICA_ID, "veil_cuttle", "Mica", false)
	var gate := _record_by_id(world.get_current_gates(), PROTECTED_GATE_ID)
	_expect(not gate.is_empty(), "protected current gate fixture was missing")
	if gate.is_empty():
		return
	var blocked: Dictionary = CurrentGateController.new().gate_blocks_position(
		world,
		gate.get("center", Vector2.ZERO),
		Callable(self, "_has_no_upgrade"),
		Callable(gate_profile, "has_capability")
	)
	_expect(str(blocked.get("id", "")) == PROTECTED_GATE_ID, "committed Mica bypassed the propulsion-fins current gate")


func _reveal_trace(sortie, mica, player, trace: Dictionary) -> Dictionary:
	var control = sortie.control_runtime()
	control.reset_transient("smoke_prepare")
	mica.global_position = trace.get("center", Vector2.ZERO) + Vector2(-40.0, 0.0)
	player.global_position = mica.global_position + Vector2(-20.0, 0.0)
	mica.advance(0.0)
	control.begin_command_mode()
	var commands: Array = control.report().get("context_commands", [])
	for index in range(commands.size()):
		if str(commands[index].get("id", "")) != "reveal_trace":
			continue
		for _step in range(index):
			control.cycle_context_command()
		return control.confirm_context_command()
	control.end_command_mode()
	return {"changed": false, "reason": "missing_reveal_trace"}


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str(record.get("id", "")) == record_id:
			return record
	return {}


func _rescue_state(world, rescue_id: String) -> String:
	return str(world.get_creature_rescue_report().get("states", {}).get(rescue_id, ""))


func _trace_state(world) -> String:
	return str(world.get_ecological_trace_report().get("states", {}).get(TRACE_ID, ""))


func _command_ids(commands: Array) -> Array[String]:
	var ids: Array[String] = []
	for command in commands:
		ids.append(str(command.get("id", "")))
	return ids


func _action_event(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _record_status(note: String) -> void:
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


func _finish(world, player, rescue, sortie) -> void:
	if sortie != null:
		sortie.clear_map()
		sortie.queue_free()
	if rescue != null:
		rescue.clear_map("smoke_complete")
		rescue.queue_free()
	player.queue_free()
	world.queue_free()
	Engine.time_scale = 1.0
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Living Expedition 02 journey smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Living Expedition 02 journey checkpoint=living_expedition_02_start profile_schema=2 migration=v1_exact individuals=spark_ray_juvenile_01,veil_cuttle_juvenile_01 rescue=available>pending>committed selected=Kite>Mica>Kite active_species=spark_ray>veil_cuttle>spark_ray actions=Mica:recall+reveal_trace,Kite:mount full_cargo_safe=true mid_sortie_switch=false scanner_required=true trace_reward=false failures=oxygen+combat+hazard+retry reload=exact protected_gate=upper_right_current_pocket_gate.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
