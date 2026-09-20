extends SceneTree

const WorldScene := preload("res://scenes/world/GreyboxWorld.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const Sortie := preload("res://scripts/companion/companion_sortie_runtime.gd")
const Profile := preload("res://scripts/main/expansion_profile_state.gd")
const Hostiles := preload("res://scripts/main/territorial_hostile_controller.gd")
const Materials := preload("res://scripts/main/material_runtime_controller.gd")
const DayState := preload("res://scripts/main/expedition_day_state.gd")
const PATH := "user://oceangame2_marl_memory_night_smoke.json"
const MARL := "silt_hound_juvenile_01"
const KITE := "spark_ray_juvenile_01"
const MICA := "veil_cuttle_juvenile_01"
const MEMORY := "guarded_the_nest"
const STEP := 1.0 / 60.0

class SaveProbe extends Profile:
	var fail_save := false
	var saves := 0
	func save_profile() -> bool:
		saves += 1
		return false if fail_save else super.save_profile()

var _profile := SaveProbe.new(PATH, true)
var _world
var _player
var _sortie
var _hostiles := Hostiles.new()
var _failures: Array[String] = []
var _notes: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_storage()
	_profile.load_profile()
	_profile.commit_companion_rescue(KITE, "spark_ray", "Kite", false)
	_profile.commit_companion_rescue(MICA, "veil_cuttle", "Mica", false)
	_profile.commit_companion_rescue(MARL, "silt_hound", "Marl", false)
	_profile.select_active_companion(MARL, false)
	_profile.save_profile()
	await _new_world()
	_expect(not _sortie.requires_adaptation_selection(), "unqualified Marl offered growth")
	_expect(_profile.select_companion_adaptation("root_claws", false).get("reason") == "missing_required_memory", "unearned Root Claws accepted")
	await _qualify()
	_expect(_sortie.commit_memories_at_boat()["marl_memory"]["reason"] == "not_at_commit_destination", "field event committed away from boat")
	_expect(_individual(MARL)["earned_memory_ids"].is_empty(), "field event saved itself")
	_sortie.discard_uncommitted_memories("oxygen_failure")
	_expect(_sortie.control_runtime().refuge_runtime().report()["pending"].is_empty(), "failure kept pending event")
	_expect(not _world.burrow_refuge_presentation().report()["opened"], "failure retained unsaved refuge")
	await _qualify()
	_profile.load_profile()
	await _new_world()
	_expect(_sortie.control_runtime().refuge_runtime().report()["pending"].is_empty(), "reload kept field event")
	_expect(not _world.burrow_refuge_presentation().report()["opened"], "reload fabricated shelter")
	await _qualify()
	await _boat_save_retry()
	await _night_choice()
	_sortie.clear_map()
	_sortie.free()
	_player.free()
	_world.free()
	_cleanup_storage()
	await process_frame
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Marl memory/night smoke: %s" % failure)
		quit(1)
		return
	print("PASS: Marl memory/night real_event=true canonical_boat=true full_cargo=true identity_bound=true save_retry=true defer=true root_claws_exact_once=true reload_sheltered=true ground_pin_available=true")
	quit(0)


func _new_world() -> void:
	if is_instance_valid(_sortie):
		_sortie.clear_map()
		_sortie.free()
		_player.free()
		_world.free()
	_world = WorldScene.instantiate()
	_world.map_path = "res://maps/production_level_01.greybox.json"
	root.add_child(_world)
	_player = PlayerScene.instantiate()
	root.add_child(_player)
	_player.set_physics_process(false)
	_player.position = Vector2(122.5, 77.5) * 32
	_hostiles.on_map_loaded(_world)
	_sortie = Sortie.new()
	root.add_child(_sortie)
	_sortie.bind_interface(null, func(note): _notes.append(note), Callable(), Callable())
	_sortie.bind_map(_world, _player, _profile, func(_id): return true, true, false, _hostiles)
	_sortie.companion().set_physics_process(false)
	_sortie.control_runtime().set_process(false)
	await physics_frame


func _qualify() -> void:
	var marl = _sortie.companion()
	var control = _sortie.control_runtime()
	var refuge = control.refuge_runtime()
	control.reset_transient("next_day")
	_hostiles.on_map_loaded(_world)
	_player.position = Vector2(122.5, 77.5) * 32
	marl.configure(_world, _player, Callable(), _individual(MARL))
	marl.position = Vector2(119.5, 77.5) * 32
	_world.set_visibility_upgrade_state("dive_light_1", true)
	control.begin_command_mode()
	_expect(control.activate_context_command(1).get("reason") == "started", "physical refuge dig did not start")
	var lunges := 0
	for tick in range(420):
		await physics_frame
		if lunges > 0 and _player.position.x > 118.5 * 32:
			_player.move_and_collide(Vector2.LEFT * STEP * 180)
		var event := _hostiles.update(_world, _player.position, STEP)
		lunges += int(event.get("kind") == "lunge")
		marl.advance(STEP)
		control.excavate_runtime().advance(STEP)
		if not refuge.report()["pending"].is_empty():
			break
	_expect(lunges > 0 and refuge.report()["pending"].get("individual_id") == MARL, "actual dig/live threat/shelter did not qualify")


func _boat_save_retry() -> void:
	# Ordinary cargo is full. Memory return must never enter collection/capacity logic.
	_world.configure_material_candidates(["silt_hound_buried_titanium_01"], [])
	_world.reveal_buried_material_candidate("silt_hound_buried_titanium_01")
	var material: Dictionary = _world.get_material_candidate_state("silt_hound_buried_titanium_01")
	var materials := Materials.new(_profile)
	var blocked: Dictionary = materials.update_collection(_world, material["candidate"]["center"], 48, DayState.new(), 2, 2)
	_expect(blocked.get("blocked", false), "full-cargo fixture did not block ordinary collection")
	_player.position = _world.get_entry_position("surface_boat_entry")
	_world.map_id = "production_slice_01"
	_expect(_sortie.commit_memories_at_boat()["marl_memory"]["reason"] == "wrong_commit_map", "other map accepted canonical boat memory")
	_world.map_id = "production_level_01"
	var before: Dictionary = _profile.companion_report()
	_profile.fail_save = true
	# Habitat may run before CargoCollectionController. Dismiss the actor first.
	_sortie.release_to_habitat()
	_expect(_sortie.companion() == null, "habitat did not dismiss Marl")
	_expect(_profile.companion_report() == before, "failed save leaked memory into profile")
	_expect(_sortie.memory_report()["marl"]["pending"].get("individual_id") == MARL, "failed save lost return transaction")
	_profile.select_active_companion(KITE, false)
	_profile.fail_save = false
	var saves := _profile.saves
	var committed: Dictionary = _sortie.commit_memories_at_boat()["marl_memory"]
	_expect(committed.get("changed", false), "retry did not save dismissed Marl memory")
	_expect(_profile.saves == saves + 1, "return did not perform one atomic save")
	_expect(_individual(MARL)["earned_memory_ids"] == [MEMORY], "Marl did not receive exactly one memory")
	_expect(_individual(KITE)["earned_memory_ids"].is_empty() and _individual(MICA)["earned_memory_ids"].is_empty(), "return awarded wrong individual")
	_expect(_profile.companion_report()["active_individual_id"] == KITE, "return silently changed selection")
	_expect(_individual(MARL)["selected_adaptation_id"] == "", "boat automatically adapted Marl")
	_expect(_profile.earn_companion_memory_for(KITE, MEMORY, true).get("reason") == "unsupported_memory", "wrong species accepted Marl memory")
	_expect(_profile.earn_companion_memory_for("unknown", MEMORY, true).get("reason") == "companion_not_committed", "unknown identity accepted memory")
	for index in range(3):
		_expect(not _sortie.commit_memories_at_boat()["marl_memory"].get("changed", false), "repeat return changed memory")
	_expect(_profile.saves == saves + 1, "repeat return saved again")
	_expect(not _world.get_material_candidate_state("silt_hound_buried_titanium_01")["depleted"] and materials.held_count() == 0, "memory consumed full-cargo pickup")
	_expect(_world.burrow_refuge_presentation().report()["sheltered"], "committed refuge not sheltered")
	_sortie.discard_uncommitted_memories("combat_defeat")
	_profile.load_profile()
	await _new_world()
	_expect(_world.burrow_refuge_presentation().report()["sheltered"], "Marl shelter lost on reload with Kite selected")
	_expect(not _sortie.requires_adaptation_selection(), "Marl memory offered Kite an adaptation")
	_profile.select_active_companion(MARL, true)
	await _new_world()
	for reason in ["oxygen_failure", "retry", "combat_defeat"]:
		_sortie.reset_control(reason)
		_expect(_world.burrow_refuge_presentation().report()["sheltered"], "committed refuge lost after %s" % reason)
	_expect(_sortie.control_runtime().refuge_runtime().availability()["reason"] == "memory_secured", "committed refuge remained farmable")


func _night_choice() -> void:
	var use := InputEventAction.new()
	use.action = "active_tool_use"
	use.pressed = true
	var bond := InputEventAction.new()
	bond.action = "companion_command"
	bond.pressed = true
	_expect(_sortie.handle_debrief_input(use).get("reason") == "inactive", "daytime USE consolidated adaptation")
	_sortie.begin_debrief()
	var report: Dictionary = _sortie.memory_report()["debrief"]
	_expect(report["eligible_adaptation_ids"] == ["root_claws"] and report["choice_count"] == 2, "night added fake branch or omitted deferral")
	var text := "\n".join(_sortie.debrief_lines())
	for phrase in ["Guarded the Nest", "hooked fin tips", "planted posture", "Ground Pin", "stop moving or digging", "not available"]:
		_expect(phrase in text, "night explanation omitted %s" % phrase)
	var before: Dictionary = _profile.companion_report()
	var saves := _profile.saves
	_sortie.handle_debrief_input(bond)
	_expect("Not tonight" in "\n".join(_sortie.debrief_lines()), "deferral choice invisible")
	_expect(_sortie.handle_debrief_input(use).get("reason") == "deferred_tonight", "explicit deferral not accepted")
	_expect(not _sortie.requires_adaptation_selection(), "deferral blocked next day")
	_expect(_profile.companion_report() == before and _profile.saves == saves, "deferral mutated saved growth")
	_sortie.handle_debrief_input(use)
	_expect(_profile.companion_report() == before, "repeat deferral consolidated")
	_sortie.end_debrief()
	_profile.load_profile()
	await _new_world()
	_expect(_individual(MARL)["selected_adaptation_id"] == "", "reload auto-adapted deferred memory")
	_sortie.begin_debrief()
	_expect(_sortie.requires_adaptation_selection(), "later night lost eligibility")
	_profile.fail_save = true
	_expect(_sortie.handle_debrief_input(use).get("reason") == "storage_error", "adaptation save failure not reported")
	_expect(_individual(MARL)["selected_adaptation_id"] == "" and _sortie.requires_adaptation_selection(), "failed consolidation leaked growth")
	_profile.fail_save = false
	_expect(_sortie.handle_debrief_input(use).get("changed", false), "deliberate Root Claws not saved")
	saves = _profile.saves
	_sortie.handle_debrief_input(use)
	_expect(_profile.saves == saves and not _sortie.requires_adaptation_selection(), "repeat confirmation wrote again")
	_expect(_profile.select_companion_adaptation("vein_whiskers", false).get("reason") == "unsupported_adaptation", "unimplemented second branch accepted")
	_sortie.end_debrief()
	_sortie.discard_uncommitted_memories("oxygen_failure")
	_profile.load_profile()
	await _new_world()
	_expect(_individual(MARL)["selected_adaptation_id"] == "root_claws", "confirmed adaptation lost on failure/reload")
	_expect(_sortie.report()["adaptation"] == {"adaptation_id": "root_claws", "ground_pin_available": true}, "learned Ground Pin projection missing")
	_expect(_world.burrow_refuge_presentation().report()["sheltered"], "grown Marl forgot refuge")
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var companion: Dictionary = payload["companion_profile"]
	_expect(companion["schema_version"] == 3 and companion.size() == 3, "introduced redundant companion save fields")
	_expect(_individual(MARL).size() == 6, "persisted transient Marl event state")


func _individual(id: String) -> Dictionary:
	for individual in _profile.companion_report()["individuals"]:
		if individual["individual_id"] == id:
			return individual
	return {}


func _cleanup_storage() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))


func _expect(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
