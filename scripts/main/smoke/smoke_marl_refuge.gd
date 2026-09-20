extends SceneTree

const WorldScene := preload("res://scenes/world/GreyboxWorld.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const Sortie := preload("res://scripts/companion/companion_sortie_runtime.gd")
const Profile := preload("res://scripts/main/expansion_profile_state.gd")
const Hostiles := preload("res://scripts/main/territorial_hostile_controller.gd")
const Materials := preload("res://scripts/main/material_runtime_controller.gd")
const DayState := preload("res://scripts/main/expedition_day_state.gd")
const STEP := 1.0 / 60.0
const MARL_ID := "silt_hound_juvenile_01"
const EEL_ID := "deep_cache_territorial_eel"

var _world
var _player
var _marl
var _sortie
var _control
var _action
var _refuge
var _profile
var _hostiles := Hostiles.new()
var _light := true
var _failures: Array[String] = []
var _notes: Array[String] = []
var _evidence := {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_world = WorldScene.instantiate()
	_world.map_path = "res://maps/production_level_01.greybox.json"
	root.add_child(_world)
	_player = PlayerScene.instantiate()
	root.add_child(_player)
	_player.set_physics_process(false)
	_profile = Profile.new("", false)
	_profile.load_profile()
	_profile.commit_companion_rescue(MARL_ID, "silt_hound", "Marl", false)
	_profile.select_active_companion(MARL_ID, false)
	_hostiles.on_map_loaded(_world)
	_sortie = Sortie.new()
	root.add_child(_sortie)
	_sortie.bind_interface(null, Callable(self, "_note"), Callable(), Callable())
	_sortie.bind_map(_world, _player, _profile, Callable(self, "_has_upgrade"), true, false, _hostiles)
	_marl = _sortie.companion()
	_control = _sortie.control_runtime()
	_marl.set_physics_process(false)
	_control.set_process(false)
	_action = _control.excavate_runtime()
	_refuge = _control.refuge_runtime()
	await physics_frame
	var source_before: Dictionary = _world._map_data.duplicate(true)
	var profile_before: Dictionary = _profile.companion_report()
	await _success_and_pause()
	await _quiet_and_defeated()
	await _invalid_and_canceled()
	_expect(_world._map_data == source_before, "runtime mutated source data")
	_expect(_profile.companion_report() == profile_before, "field event wrote permanent memory or adaptation")
	_sortie.clear_map()
	_expect(_refuge.report()["pending"].is_empty(), "teardown retained pending memory")
	_sortie.free()
	_player.free()
	_world.free()
	await process_frame
	if not _failures.is_empty():
		print("Marl refuge evidence: %s" % str(_evidence))
		for failure in _failures:
			push_error("Marl refuge smoke: %s" % failure)
		quit(1)
		return
	print("PASS: Marl refuge real_dig=true live_eel_cycle=true group_sheltered=true pending_only=true identity_bound=true no_farming=true pause_and_cleanup=true evidence=%s" % str(_evidence))
	quit(0)


func _fresh() -> void:
	_control.reset_transient("next_day")
	_hostiles.on_map_loaded(_world)
	_player.global_position = Vector2(122.5, 77.5) * _world.tile_size
	_marl.configure(_world, _player, Callable(), _profile.companion_report()["individual"])
	_marl.global_position = Vector2(119.5, 77.5) * _world.tile_size
	_light = true
	_world.set_visibility_upgrade_state("dive_light_1", true)


func _start() -> void:
	_control.begin_command_mode()
	_expect(paused, "BOND did not pause")
	var result: Dictionary = _control.activate_context_command(1)
	_expect(result.get("reason") == "started" and not paused, "refuge Excavate did not dispatch: %s" % str(result))


func _tick(threat := true, move_marl := true) -> Dictionary:
	await physics_frame
	var event := _hostiles.update(_world, _player.global_position if threat else Vector2.ZERO, STEP)
	if move_marl:
		_marl.advance(STEP)
	_action.advance(STEP)
	var collider = _marl.get_node("CollisionShape2D")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collider.shape
	query.transform = collider.global_transform
	query.collision_mask = 1
	query.exclude = [_marl.get_rid()]
	_expect(_world.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty(), "Marl overlaps terrain")
	return event


func _success_and_pause() -> void:
	_fresh()
	# Ordinary pickups respect a full two-slot cargo hold; the refuge has no loot
	# handoff and must still complete without consuming/deleting that pickup.
	_world.configure_material_candidates(["silt_hound_buried_titanium_01"], [])
	_world.reveal_buried_material_candidate("silt_hound_buried_titanium_01")
	var material: Dictionary = _world.get_material_candidate_state("silt_hound_buried_titanium_01")
	var materials := Materials.new(_profile)
	var blocked: Dictionary = materials.update_collection(_world, material["candidate"]["center"], 48, DayState.new(), 2, 2)
	_expect(blocked.get("blocked", false), "full-cargo fixture failed to block ordinary pickup")
	await _capture("closed")
	_start()
	var warnings := 0
	var lunges := 0
	var hits := 0
	var paused_during_dig := false
	for tick in range(420):
		# Dodge after the real eel locks onto the diver, without setting its state.
		if lunges > 0:
			_player.move_and_collide(Vector2.LEFT * STEP * 180 if _player.position.x > 118.5 * 32 else Vector2.ZERO)
		var event := await _tick()
		warnings += int(event.get("kind") == "warning")
		lunges += int(event.get("kind") == "lunge")
		hits += int(event.get("kind") == "contact")
		if _action.report()["state"] == "digging" and not paused_during_dig:
			paused_during_dig = true
			_control.begin_command_mode()
			var before: Dictionary = _action.report()
			var group_before: Dictionary = _refuge.report()
			var eel_before := _hostiles.state_for(EEL_ID)
			for index in range(5):
				await process_frame
				_control._process(0.5)
				_action.advance(0.5)
			_expect(_action.report() == before and _refuge.report() == group_before, "BOND advanced dig/group timers")
			_expect(_hostiles.state_for(EEL_ID) == eel_before, "BOND advanced eel")
			await _capture("digging")
			_control.end_command_mode()
		if not _refuge.report()["pending"].is_empty():
			break
	var report: Dictionary = _refuge.report()
	_expect(report["physical_dig_complete"] and report["live_warning_lunge"] and report["group"]["sheltered"], "event did not combine physical dig, live cycle and arrival: %s" % report)
	_expect(report["pending"].get("individual_id") == MARL_ID and report["pending"].get("memory_id") == "guarded_the_nest", "pending memory lost Marl identity")
	_expect(materials.held_count() == 0 and _world.get_material_candidate_state("silt_hound_buried_titanium_01")["available"], "refuge altered full-cargo material pickup")
	_expect(warnings > 0 and lunges > 0 and hits == 0, "event needed fabricated threat or required damage")
	_expect(_action.report()["visited_states"] == ["approaching", "anticipating", "digging", "impact", "revealed"], "refuge bypassed original physical phases")
	_evidence = {"warnings": warnings, "lunges": lunges, "diver_hits": hits, "pending": report["pending"], "phases": _action.report()["visited_states"]}
	await _capture("sheltered")
	var pending_before: Dictionary = report["pending"].duplicate(true)
	_expect(not _action.dispatch("excavate")["changed"], "repeat dig restarted opened refuge")
	_expect(not _refuge.complete_dig(), "replayed completion reopened refuge")
	for index in range(12):
		_refuge.advance(0.2)
	_expect(_refuge.report()["pending"] == pending_before, "replayed snapshots duplicated pending memory")
	var snapshot: Dictionary = _refuge.report()
	snapshot["pending"].clear()
	_expect(_refuge.report()["pending"] == pending_before, "report exposed mutable pending state")
	_sortie.discard_uncommitted_memories("oxygen_failure")
	_expect(_refuge.report()["pending"].is_empty() and not _refuge.report()["group"]["opened"], "oxygen failure retained field progress")
	for reason in ["hazard", "retry", "combat_defeat", "reload"]:
		await _qualify_again()
		_control.reset_transient(reason)
		_expect(not _action.report()["busy"] and _refuge.report()["pending"].is_empty(), "%s retained action or memory" % reason)
	await _qualify_again()
	_control.begin_command_mode()
	_control.activate_context_command(0)
	_expect(_refuge.report()["pending"].is_empty() and _refuge.report()["group"]["opened"], "Recall kept pending memory or reopened completed refuge")
	_sortie.release_to_habitat()
	_expect(_world.burrow_refuge_presentation().report()["opened"], "boat abandonment reset same-day opened shelter")
	_sortie.sync_spawn()
	_marl = _sortie.companion()
	_marl.set_physics_process(false)
	_refuge = _control.refuge_runtime()
	_expect(_world.burrow_refuge_presentation().report()["opened"], "second sortie reset same-day shelter")


func _qualify_again() -> void:
	_fresh()
	_start()
	var lunges := 0
	for tick in range(360):
		if lunges > 0 and _player.position.x > 118.5 * 32:
			_player.move_and_collide(Vector2.LEFT * STEP * 180)
		var event := await _tick()
		lunges += int(event.get("kind") == "lunge")
		if not _refuge.report()["pending"].is_empty():
			break
	_expect(not _refuge.report()["pending"].is_empty(), "reset fixture did not first earn actual pending memory")


func _quiet_and_defeated() -> void:
	for defeated in [false, true]:
		_fresh()
		if defeated:
			_hostiles.apply_weapon_hit(_world, EEL_ID, 3)
		_start()
		for tick in range(360):
			await _tick(false)
			if _refuge.report()["group"]["sheltered"]:
				break
		_expect(_refuge.report()["group"]["opened"] and _refuge.report()["group"]["sheltered"], "quiet/defeated visit could not open shelter")
		_expect(_refuge.report()["pending"].is_empty(), "quiet/defeated dig fabricated memory")
		_expect(not _action.dispatch("excavate")["changed"], "quiet shelter reset before next day")
		if defeated:
			_control.reset_transient("retry")
			_expect(_hostiles.state_for(EEL_ID)["phase"] == "defeated", "refuge retry resurrected eel early")
	_fresh()
	_expect(_hostiles.state_for(EEL_ID)["phase"] == "home" and not _refuge.report()["group"]["opened"], "normal next day did not restore opportunity")
	for tick in range(90):
		await _tick(true, false)
	_expect(_refuge.report()["pending"].is_empty() and not _refuge.report()["physical_dig_complete"], "threat or idle proximity alone earned memory")
	_fresh()
	_start()
	await _tick()
	_expect(_hostiles.state_for(EEL_ID)["phase"] == "warning", "interrupted-warning fixture lacks real warning")
	_hostiles.apply_weapon_hit(_world, EEL_ID, 1)
	for tick in range(360):
		await _tick(false)
		if _refuge.report()["group"]["sheltered"]:
			break
	_expect(_refuge.report()["group"]["sheltered"] and _refuge.report()["pending"].is_empty(), "interrupted warning without lunge qualified memory")


func _invalid_and_canceled() -> void:
	_fresh()
	_light = false
	_expect(_action.dispatch("excavate")["reason"] == "light_required", "refuge bypassed Dive Light")
	_light = true
	var identity: Dictionary = _profile.companion_report()["individual"].duplicate(true)
	identity["individual_id"] = "wrong_marl"
	_marl.configure(_world, _player, Callable(), identity)
	_expect(not _action.dispatch("excavate")["changed"], "wrong individual started refuge")
	identity["individual_id"] = MARL_ID
	identity["rescue_committed"] = false
	_marl.configure(_world, _player, Callable(), identity)
	_expect(not _action.dispatch("excavate")["changed"], "uncommitted rescue started refuge")
	_fresh()
	_start()
	_expect(not _action.dispatch("excavate")["changed"], "repeat dispatch stacked active attempt")
	for tick in range(45):
		await _tick()
	_control.begin_command_mode()
	_control.activate_context_command(0)
	_expect(not _action.report()["busy"] and not _refuge.report()["attempt_active"], "Recall did not cancel active attempt")
	_expect(not _refuge.complete_dig(), "replayed completion after Recall opened refuge")
	_fresh()
	_start()
	_player.position += Vector2(300, 0)
	_action.advance(STEP)
	_expect(not _action.report()["busy"] and _refuge.report()["pending"].is_empty(), "abandonment retained attempt")
	_fresh()
	_start()
	identity = _profile.companion_report()["individual"].duplicate(true)
	identity["individual_id"] = "wrong_marl"
	_marl.configure(_world, _player, Callable(), identity)
	_action.advance(STEP)
	_expect(not _action.report()["busy"] and not _refuge.report()["attempt_active"], "mid-action identity change retained attempt")
	_fresh()
	_start()
	_sortie.reset_control("retry")
	_expect(not _action.report()["busy"] and not _refuge.report()["group"]["opened"], "sortie Retry did not clear refuge")
	_sortie.release_to_habitat()
	_expect(_refuge.report()["pending"].is_empty(), "habitat abandonment retained pending")


func _capture(label: String) -> void:
	if not "--capture-marl-refuge" in OS.get_cmdline_args():
		return
	_expect(DisplayServer.get_name() != "headless", "capture requires rendering")
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.position = Vector2(121.5, 77) * 32
	camera.zoom = Vector2.ONE * 1.7
	camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("res://tmp/living_expedition_07/refuge")
	directory = directory.path_join("%dx%d" % [root.size.x, root.size.y])
	DirAccess.make_dir_recursive_absolute(directory)
	root.get_texture().get_image().save_png(directory.path_join(label + ".png"))
	camera.free()


func _has_upgrade(id: String) -> bool:
	return _light and id == "dive_light_1"


func _note(message: String) -> void:
	_notes.append(message)


func _expect(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
