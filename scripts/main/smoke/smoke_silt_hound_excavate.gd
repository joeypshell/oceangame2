extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const SILT_HOUND_SCENE := preload("res://scenes/companion/SiltHoundCompanion.tscn")
const SiltHoundControlRuntime := preload("res://scripts/companion/silt_hound_control_runtime.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const TARGET_ID := "silt_hound_buried_titanium_01"
const CONTEXT_ID := "silt_hound_excavate_context_01"
const MATERIAL_ID := "titanium_scrap"
const STEP_SECONDS := 1.0 / 30.0

var _failures: Array[String] = []
var _notes: Array[String] = []
var _blocked_rect := Rect2()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	await physics_frame

	var source := _source_candidate(world)
	_expect(not source.is_empty(), "authored buried candidate is missing")
	_expect(_context_matches(world), "authored excavation context is missing or mismatched")
	if source.is_empty():
		_finish(world, player, null, null)
		return
	world.configure_material_candidates([TARGET_ID], [])
	var target: Vector2 = source.get("center", Vector2.ZERO)
	var positions := _action_positions(world, target)
	player.global_position = positions["player"]
	var companion = SILT_HOUND_SCENE.instantiate()
	get_root().add_child(companion)
	companion.configure(world, player, Callable(self, "_position_allowed"), _marl_identity())
	companion.set_physics_process(false)
	companion.global_position = positions["companion"]
	var control := SiltHoundControlRuntime.new()
	get_root().add_child(control)
	control.bind_interface(Callable(self, "_record_note"), Callable(self, "_control_allowed"))
	control.bind_map(world, player, companion)

	_test_closed_source(world, target)
	var commands: Array = control.report().get("context_commands", [])
	_expect(commands.size() == 2 and str((commands[1] as Dictionary).get("id", "")) == "excavate", "BOND omitted contextual Excavate")
	var opened: Dictionary = control.begin_command_mode()
	_expect(bool(opened.get("command_mode", false)) and paused, "BOND did not pause before excavation")
	var started: Dictionary = control.activate_context_command(1)
	_expect(bool(started.get("changed", false)) and str(started.get("reason", "")) == "started", "Excavate did not dispatch")
	_expect(not paused and not bool(control.report().get("command_mode", true)), "Excavate selection did not resume the simulation")

	var excavation = control.excavate_runtime()
	for _index in range(360):
		companion.advance(STEP_SECONDS)
		excavation.advance(STEP_SECONDS)
		if str(excavation.report().get("state", "")) == "revealed":
			break
	var action_report: Dictionary = excavation.report()
	var visited: Array = action_report.get("visited_states", [])
	for required_state in ["approaching", "anticipating", "digging", "impact", "revealed"]:
		_expect(visited.has(required_state), "physical sequence omitted %s" % required_state)
	_expect(int(action_report.get("reveal_count", 0)) == 1, "excavation did not reveal exactly once")
	var revealed: Dictionary = world.get_material_candidate_state(TARGET_ID)
	_expect(bool(revealed.get("revealed", false)) and bool(revealed.get("available", false)), "completed dig did not expose normal material")
	_expect(str(revealed.get("mound", {}).get("state", "")) == "opened", "mound did not retain opened presentation")
	_expect(control.report().get("context_commands", []).size() == 1, "Excavate remained available after reveal")
	_expect(str(excavation.dispatch("excavate").get("reason", "")) == "target_revealed", "revealed source did not return concise denial")

	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var materials := MaterialRuntimeController.new(profile)
	var day := ExpeditionDayState.new()
	var blocked: Dictionary = materials.update_collection(world, target, 48.0, day, 2, 2)
	_expect(bool(blocked.get("blocked", false)), "cargo full did not block the exposed pickup")
	_expect(not world.get_material_candidate_near(target, 48.0).is_empty(), "cargo-full block deleted the exposed pickup")
	var collected: Dictionary = materials.update_collection(world, target, 48.0, day, 0, 2)
	_expect(bool(collected.get("changed", false)) and materials.held_count() == 1, "normal material owner did not collect exposed titanium")
	var depleted: Dictionary = world.get_material_candidate_state(TARGET_ID)
	_expect(bool(depleted.get("depleted", false)) and str(depleted.get("mound", {}).get("state", "")) == "empty", "collection did not leave an empty mound")
	_expect(materials.update_collection(world, target, 48.0, day, 0, 2).is_empty(), "depleted excavation duplicated material")
	var before_bank := profile.material_quantity(MATERIAL_ID)
	var banked: Dictionary = materials.try_commit_at_boat(world, world.get_extraction_center())
	_expect(bool(banked.get("changed", false)) and profile.material_quantity(MATERIAL_ID) == before_bank + 1, "canonical boat did not bank exactly one titanium")

	world.configure_material_candidates([TARGET_ID], [])
	excavation.reset_transient("fresh_day")
	companion.global_position = positions["companion"]
	player.global_position = positions["player"]
	_expect(bool(excavation.dispatch("excavate").get("changed", false)), "fresh-day excavation did not restart")
	_expect(str(excavation.dispatch("excavate").get("reason", "")) == "busy", "busy action did not return concise denial")
	for _index in range(160):
		companion.advance(STEP_SECONDS)
		excavation.advance(STEP_SECONDS)
		if str(excavation.report().get("state", "")) == "digging":
			break
	excavation.reset_transient("oxygen_failure")
	var restored: Dictionary = world.get_material_candidate_state(TARGET_ID)
	_expect(str(excavation.report().get("state", "")) == "idle", "failure did not clear action-local state")
	_expect(not bool(restored.get("revealed", true)) and not bool(restored.get("available", true)), "failure did not restore the closed mound")
	_expect(str(restored.get("mound", {}).get("state", "")) == "closed", "failure left transient mound presentation")
	_expect(not bool(companion.report().get("excavate", {}).get("active", true)), "failure left companion action ownership active")
	for reset_reason in ["hazard", "retry", "reload", "next_day", "active_companion_changed"]:
		world.configure_material_candidates([TARGET_ID], [])
		_expect(world.reveal_buried_material_candidate(TARGET_ID), "%s fixture could not reveal source" % reset_reason)
		excavation.reset_transient(reset_reason)
		_expect_closed(world, reset_reason)

	world.configure_material_candidates([], [])
	excavation.reset_transient("inactive_fixture")
	_expect(str(excavation.dispatch("excavate").get("reason", "")) == "target_inactive", "inactive source did not return concise denial")
	world.configure_material_candidates([TARGET_ID], [])
	excavation.reset_transient("range_fixture")
	player.global_position = target + Vector2(220.0, 0.0)
	_expect(str(excavation.dispatch("excavate").get("reason", "")) == "target_out_of_range", "range failure did not return concise denial")
	player.global_position = positions["player"]

	_blocked_rect = Rect2(target - Vector2(14.0, 14.0), Vector2(28.0, 28.0))
	var denied: Dictionary = excavation.dispatch("excavate")
	_expect(not bool(denied.get("changed", true)) and str(denied.get("reason", "")) == "path_blocked", "equipment/access callback did not deny excavation path")
	_blocked_rect = Rect2()
	_expect(_notes.any(func(note): return "uncovered titanium" in note), "completion lacked concise feedback")
	_finish(world, player, companion, control, {
		"visited": visited,
		"notes": _notes,
		"banked_material": profile.material_quantity(MATERIAL_ID),
		"reveal_count": action_report.get("reveal_count"),
	})


func _test_closed_source(world, target: Vector2) -> void:
	var state: Dictionary = world.get_material_candidate_state(TARGET_ID)
	_expect(bool(state.get("active", false)) and bool(state.get("buried", false)), "selected buried source did not activate")
	_expect(not bool(state.get("revealed", true)) and not bool(state.get("available", true)), "selected source exposed pickup before Excavate")
	_expect(str(state.get("mound", {}).get("state", "")) == "closed", "selected source omitted closed mound presentation")
	_expect(world.get_material_candidate_near(target, 48.0).is_empty(), "concealed material entered proximity collection")


func _expect_closed(world, reason: String) -> void:
	var state: Dictionary = world.get_material_candidate_state(TARGET_ID)
	_expect(not bool(state.get("revealed", true)), "%s retained reveal state" % reason)
	_expect(not bool(state.get("available", true)), "%s retained collectible pickup" % reason)
	_expect(str(state.get("mound", {}).get("state", "")) == "closed", "%s did not close mound" % reason)


func _source_candidate(world) -> Dictionary:
	for candidate in world.get_material_candidates():
		if str((candidate as Dictionary).get("id", "")) == TARGET_ID:
			return (candidate as Dictionary).duplicate(true)
	return {}


func _context_matches(world) -> bool:
	for context in world.get_companion_contexts():
		if str((context as Dictionary).get("id", "")) != CONTEXT_ID:
			continue
		return (
			str(context.get("species_id", "")) == "silt_hound"
			and str(context.get("individual_id", "")) == "silt_hound_juvenile_01"
			and str(context.get("action_id", "")) == "excavate"
			and str(context.get("target_id", "")) == TARGET_ID
		)
	return false


func _action_positions(world, target: Vector2) -> Dictionary:
	var open_points: Array[Vector2] = []
	for radius in [48.0, 64.0, 80.0, 96.0]:
		for index in range(16):
			var angle := float(index) / 16.0 * TAU
			var candidate: Vector2 = target + Vector2(cos(angle), sin(angle)) * float(radius)
			if world.find_open_path(candidate, candidate).is_empty() or not world.has_clear_terrain_line(candidate, target):
				continue
			open_points.append(candidate)
			if open_points.size() >= 2:
				return {"player": open_points[0], "companion": open_points[1]}
	_failures.append("could not find two open excavation setup points")
	return {"player": target, "companion": target}


func _marl_identity() -> Dictionary:
	return {
		"individual_id": "silt_hound_juvenile_01",
		"species_id": "silt_hound",
		"callsign": "Marl",
		"rescue_committed": true,
		"earned_memory_ids": [],
		"selected_adaptation_id": "",
	}


func _position_allowed(position: Vector2) -> bool:
	return not (_blocked_rect.size != Vector2.ZERO and _blocked_rect.has_point(position))


func _control_allowed() -> bool:
	return true


func _record_note(note: String) -> void:
	_notes.append(note)


func _finish(world, player, companion, control, evidence := {}) -> void:
	paused = false
	if control != null:
		control.clear_map()
		control.queue_free()
	if companion != null:
		companion.queue_free()
	player.queue_free()
	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Silt Hound Excavate smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Silt Hound Excavate deliberate=true sequence=approach+anticipate+dig+impact reveal=exact_once cargo_full=preserved pickup=typed_material bank=canonical_boat reset=closed gate_bypass=false evidence=%s." % str(evidence))
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
