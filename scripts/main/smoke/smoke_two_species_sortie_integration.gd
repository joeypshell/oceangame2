extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const CompanionJourneyGuidance := preload("res://scripts/companion/companion_journey_guidance.gd")
const CompanionRescueRuntime := preload("res://scripts/companion/companion_rescue_runtime.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const PROFILE_PATH := "user://smoke_two_species_sortie_profile.json"
const KITE_ID := "spark_ray_juvenile_01"
const MICA_ID := "veil_cuttle_juvenile_01"
const MICA_RESCUE_ID := "veil_cuttle_rescue_01"
const TRACE_ID := "veil_cuttle_trace_01"

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
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	await physics_frame

	var profile := ExpansionProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	_seed_required_tools(profile, world)
	var kite_commit: Dictionary = profile.commit_companion_rescue(KITE_ID, "spark_ray", "Kite", true)
	_expect(bool(kite_commit.get("changed", false)), "fixture could not commit Kite")
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

	mica.global_position = trace.get("center", Vector2.ZERO) + Vector2(-40.0, 0.0)
	player.global_position = mica.global_position + Vector2(-20.0, 0.0)
	mica.advance(0.0)
	var control = sortie.control_runtime()
	control.begin_command_mode()
	control.cycle_context_command()
	var reveal: Dictionary = control.confirm_context_command()
	_expect(bool(reveal.get("changed", false)), "integrated Mica BOND action did not reveal the trace")
	var revealed_guidance: String = guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(revealed_guidance.find("Scanner") != -1, "revealed trace guidance did not hand control back to the scanner")
	_test_scanner_identification(world, player, profile, guidance, sortie)

	var profile_before_failure: Dictionary = profile.companion_report()
	sortie.recover_to_player("oxygen_failure")
	_expect(_trace_state(world) == "hidden", "failure recovery retained transient trace visibility")
	_expect(not sortie.control_runtime().report().get("command_mode", true) and is_equal_approx(Engine.time_scale, 1.0), "failure recovery retained BOND state or slow time")
	_expect(profile.companion_report() == profile_before_failure, "failure recovery changed committed individuals or active selection")

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


func _seed_required_tools(profile, world) -> void:
	_complete_project(profile, world, ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID, ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID)
	_complete_project(profile, world, ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID, ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID)


func _complete_project(profile, world, project_id: String, discovery_id: String) -> void:
	var discovery: Dictionary = profile.complete_discovery(discovery_id, false)
	_expect(
		bool(discovery.get("changed", false)) or discovery.get("reason") == "already_completed",
		"could not seed discovery %s: %s" % [discovery_id, discovery]
	)
	var project := _record_by_id(world.get_material_projects(), project_id)
	_expect(not project.is_empty(), "map omitted project %s" % project_id)
	if project.is_empty():
		return
	var deposit_quantities := {}
	for material_id in project.get("required_materials", {}):
		var missing: int = int(project["required_materials"][material_id]) - profile.material_quantity(str(material_id))
		if missing > 0:
			deposit_quantities[str(material_id)] = missing
	var deposit: Dictionary = {"changed": true, "reason": "already_sufficient"}
	if not deposit_quantities.is_empty():
		deposit = profile.deposit_materials(deposit_quantities, false)
	var built: Dictionary = profile.complete_material_project(project, false)
	_expect(
		bool(deposit.get("changed", false)) and (bool(built.get("changed", false)) or built.get("reason") == "already_completed"),
		"could not seed project %s: deposit=%s build=%s" % [project_id, deposit, built]
	)


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
			push_error("Two-species integration smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: two-species rescue=Kite+Mica full_cargo_safe=true failure_restore=true boat_commit=exact_once selection=boat_only active_instance=one Mica_actions=recall+reveal_trace scanner_required=true trace_reward=false transient_reset=true Kite_mount_restored=true reload=exact.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
