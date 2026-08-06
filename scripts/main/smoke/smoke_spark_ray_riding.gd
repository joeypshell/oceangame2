extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ActiveToolHud := preload("res://scripts/main/active_tool_hud.gd")
const CompanionClearance := preload("res://scripts/companion/companion_clearance.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const INDIVIDUAL_ID := "spark_ray_juvenile_01"
const SPECIES_ID := "spark_ray"
const POST_DISMOUNT_MIN_SEPARATION := 56.0

var _failures: Array[String] = []
var _status_notes: Array[String] = []
var _control_allowed := true
var _cancel_count := 0


class ClosedClearanceWorld:
	extends Node2D

	func find_open_path(_start: Vector2, _target: Vector2) -> Array:
		return []

	func has_clear_terrain_line(_start: Vector2, _target: Vector2) -> bool:
		return false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_time_scale := Engine.time_scale
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	player.global_position = world.spawn_position
	await physics_frame

	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	profile.commit_companion_rescue(INDIVIDUAL_ID, SPECIES_ID, "Kite", false)
	var profile_before := profile.companion_report()
	var runtime := CompanionSortieRuntime.new()
	get_root().add_child(runtime)
	var hud := ActiveToolHud.new()
	get_root().add_child(hud)
	hud.refresh({"selected_tool_id": "survey_scanner_1", "owned_tool_ids": ["survey_scanner_1"]})
	runtime.bind_interface(hud, Callable(self, "_record_status"), Callable(self, "_cancel_tool"), Callable(self, "_can_control"))
	var spawn_report: Dictionary = runtime.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), true)
	var ray = runtime.companion()
	var control = runtime.control_runtime()
	_expect(ray != null and bool(spawn_report.get("spawned", false)), "committed active Spark Ray did not create the riding fixture")
	if ray == null or control == null:
		_finish(world, player, runtime, hud, original_time_scale)
		return
	ray.set_physics_process(false)
	_test_input_contract()
	_test_command_slow_time(control, original_time_scale)
	_test_mount_and_hotbar(control, player, ray, hud)
	_test_mounted_movement_and_glide(world, control, player, ray)
	_test_gate_protection(world, control, player, ray)
	_test_clearance_denials(world, control, player, ray)
	_test_hostile_dismount(control, player, ray)
	_test_reset_and_inactive_restore(control, player, original_time_scale)
	_expect(profile.companion_report() == profile_before, "command or riding state mutated the persistent companion profile")
	_test_scene_exit_restore(runtime, control, original_time_scale)
	_finish(world, player, runtime, hud, original_time_scale)


func _test_input_contract() -> void:
	_expect(InputMap.has_action("companion_command"), "companion_command input action is missing")
	var events := InputMap.action_get_events("companion_command")
	var shift_bound := events.any(func(event): return event is InputEventKey and ((event as InputEventKey).keycode == KEY_SHIFT or (event as InputEventKey).physical_keycode == KEY_SHIFT))
	_expect(shift_bound, "companion_command is not bound to Shift/BOND")
	_expect(not events.any(func(event): return event is InputEventKey and (event as InputEventKey).keycode in [KEY_Q, KEY_E]), "companion_command reused Q or E")


func _test_command_slow_time(control, original_time_scale: float) -> void:
	var opened: Dictionary = control.begin_command_mode()
	_expect(bool(opened.get("command_mode", false)), "BOND did not open command mode")
	_expect(is_equal_approx(Engine.time_scale, 0.2), "BOND did not set complete simulation time scale to 20 percent")
	var commands: Array = opened.get("context_commands", [])
	_expect(commands.size() > 0 and commands.size() <= 3, "BOND palette did not expose one to three contextual commands")
	_expect(commands.map(func(command): return str(command.get("id", ""))).has("mount"), "near unmounted palette omitted Mount")
	_expect(bool(opened.get("palette", {}).get("visible", false)), "BOND palette was not visible")
	control.end_command_mode()
	_expect(is_equal_approx(Engine.time_scale, original_time_scale), "releasing BOND did not restore normal time")


func _test_mount_and_hotbar(control, player, ray, hud) -> void:
	control.begin_command_mode()
	var result: Dictionary = control.confirm_context_command()
	_expect(bool(result.get("changed", false)) and control.is_mounted(), "confirming Mount did not transfer control")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "confirming Mount left slow time active")
	_expect(player.mounted_control_active(), "mounted player controller retained movement authority")
	_expect(not hud.visible and control.hides_diver_hotbar(), "mounted mode did not hide the diver hotbar")
	var report: Dictionary = control.report()
	var action_hud: Dictionary = report.get("action_hud", {})
	_expect(bool(action_hud.get("visible", false)), "mounted creature hotbar was not visible")
	_expect(str(report.get("selected_action_id", "")) == "glide_surge", "base creature hotbar did not select Glide Surge")
	_expect(_cancel_count == 1, "mount did not cancel the active diver tool once")
	_expect(player.get_node("Camera2D") != null, "mounted control displaced the authoritative player camera")
	var dismount: Dictionary = control.request_dismount()
	_expect(bool(dismount.get("changed", false)), "clear normal dismount was denied")
	_expect(hud.visible and not control.hides_diver_hotbar(), "normal dismount did not restore the diver hotbar")
	_expect(not player.mounted_control_active(), "normal dismount did not restore diver movement authority")
	_expect_dismount_handoff(player, ray, "normal")
	for cycle in range(2):
		_place_pair(player, ray, player.global_position)
		_expect(bool(control.request_mount().get("changed", false)), "repeat dismount cycle %d could not mount" % (cycle + 1))
		_expect(bool(control.request_dismount().get("changed", false)), "repeat dismount cycle %d could not dismount" % (cycle + 1))
		_expect_dismount_handoff(player, ray, "repeat cycle %d" % (cycle + 1))
	_place_pair(player, ray, player.global_position)
	_expect(bool(control.request_mount().get("changed", false)), "movement fixture could not remount after normal dismount")


func _test_mounted_movement_and_glide(world, control, player, ray) -> void:
	var route := _find_open_route(world, ray.global_position)
	_expect(route.size() >= 2, "full level omitted an open mounted-movement fixture")
	if route.size() < 2:
		return
	var target := route[mini(2, route.size() - 1)] as Vector2
	var direction: Vector2 = ray.global_position.direction_to(target)
	var before: Vector2 = ray.global_position
	for _index in range(8):
		control.advance_mounted_movement(1.0 / 30.0, direction)
	_expect(ray.global_position.distance_to(before) > 8.0, "mounted input did not move the collision-active Spark Ray")
	_expect(player.global_position.distance_to(ray.global_position) <= 0.01, "player survival/camera position did not follow mounted movement")
	var glide_start: Vector2 = ray.global_position
	var glide: Dictionary = control.activate_mounted_action()
	_expect(bool(glide.get("changed", false)) and str(glide.get("reason", "")) == "glide_surge", "Space/USE did not activate Glide Surge")
	control.advance_mounted_movement(0.08, Vector2.ZERO)
	var glide_report: Dictionary = control.report()
	_expect(ray.global_position.distance_to(glide_start) > 4.0, "Glide Surge did not move visibly in its committed direction")
	_expect(float(glide_report.get("glide_cooldown_seconds", 0.0)) > 0.0, "Glide Surge did not enter cooldown")
	_expect(bool(ray.report().get("presentation", {}).get("glide_visible", false)), "Glide Surge omitted its directional presentation")
	var repeated: Dictionary = control.activate_mounted_action()
	_expect(not bool(repeated.get("changed", true)) and str(repeated.get("reason", "")) == "glide_cooling_down", "Glide Surge ignored cooldown")
	_expect(not ray.has_method("attack") and not ray.report().has("health"), "base riding added damage or creature health")


func _test_gate_protection(world, control, player, ray) -> void:
	control.reset_control("gate_fixture")
	var fixture := _find_gate_crossing(world)
	_expect(not fixture.is_empty(), "full level omitted a current-gate riding fixture")
	if fixture.is_empty():
		return
	_place_pair(player, ray, fixture["before"])
	var mount: Dictionary = control.request_mount()
	_expect(bool(mount.get("changed", false)), "gate fixture could not mount")
	if not bool(mount.get("changed", false)):
		return
	var rect: Rect2 = fixture["gate"].get("rect", Rect2())
	var blocked := false
	for _index in range(90):
		var movement: Dictionary = control.advance_mounted_movement(1.0 / 60.0, (fixture["before"] as Vector2).direction_to(fixture["after"] as Vector2))
		blocked = blocked or bool(movement.get("blocked_by_gate", false))
	_expect(blocked, "mounted movement did not report the locked equipment gate")
	_expect(not rect.has_point(ray.global_position), "mounted Spark Ray bypassed an equipment gate")
	_expect(player.global_position.distance_to(ray.global_position) <= 0.01, "gate denial desynchronized player and mount")
	control.reset_control("gate_complete")


func _test_clearance_denials(world, control, player, ray) -> void:
	_place_pair(player, ray, world.spawn_position)
	player.global_position += Vector2(220.0, 0.0)
	var distant: Dictionary = control.request_mount()
	_expect(not bool(distant.get("changed", true)) and str(distant.get("reason", "")) == "move_closer", "distant mount did not give an explicit proximity denial")
	var closed_world := ClosedClearanceWorld.new()
	get_root().add_child(closed_world)
	var closed: Dictionary = CompanionClearance.new().dismount_report(closed_world, player, ray, Callable(self, "_allow_position"))
	_expect(not bool(closed.get("allowed", true)) and str(closed.get("reason", "")) == "diver_clearance", "blocked dismount did not give an explicit diver-clearance denial")
	closed_world.queue_free()


func _test_hostile_dismount(control, player, ray) -> void:
	_place_pair(player, ray, player.global_position)
	var mount: Dictionary = control.request_mount()
	_expect(bool(mount.get("changed", false)), "hostile fixture could not mount")
	if not bool(mount.get("changed", false)):
		return
	var forced: Dictionary = control.force_dismount_for_hit(ray.global_position - Vector2.RIGHT * 20.0)
	_expect(bool(forced.get("changed", false)) and not control.is_mounted(), "major hostile hit did not force dismount")
	_expect(not player.mounted_control_active(), "major hostile hit left diver movement suppressed")
	var ray_report: Dictionary = ray.report()
	_expect(float(ray_report.get("forced_separation_seconds", 0.0)) > 0.0, "major hostile hit omitted readable separation")
	_expect(str(ray_report.get("presentation", {}).get("context_kind", "")) == "danger", "major hostile hit omitted the danger cue")


func _test_reset_and_inactive_restore(control, player, original_time_scale: float) -> void:
	control.begin_command_mode()
	control.reset_control("retry")
	_expect(is_equal_approx(Engine.time_scale, original_time_scale), "Retry reset did not restore normal time")
	_expect(not control.is_mounted() and not player.mounted_control_active(), "Retry reset retained mounted state")
	control.begin_command_mode()
	_control_allowed = false
	control._process(0.0)
	_expect(not bool(control.report().get("command_mode", true)), "failure/debrief transition retained BOND control")
	_expect(is_equal_approx(Engine.time_scale, original_time_scale), "failure/debrief transition did not restore normal time")
	_control_allowed = true


func _test_scene_exit_restore(runtime, control, original_time_scale: float) -> void:
	control.begin_command_mode()
	runtime.clear_map()
	_expect(is_equal_approx(Engine.time_scale, original_time_scale), "scene exit did not restore normal time")


func _find_open_route(world, start: Vector2) -> Array:
	for salvage in world.get_salvage_centers():
		var path: Array = world.find_open_path(start, salvage.get("center", Vector2.ZERO))
		if path.size() >= 3 and path.all(func(point): return world.get_current_gate_at(point as Vector2).is_empty()):
			return path
	return []


func _find_gate_crossing(world) -> Dictionary:
	var tile := float(world.tile_size)
	for gate in world.get_current_gates():
		var rect: Rect2 = gate.get("rect", Rect2())
		var center := rect.get_center()
		for pair in [
			[Vector2(rect.position.x - tile * 0.5, center.y), Vector2(rect.end.x + tile * 0.5, center.y)],
			[Vector2(center.x, rect.position.y - tile * 0.5), Vector2(center.x, rect.end.y + tile * 0.5)],
		]:
			var before := pair[0] as Vector2
			var after := pair[1] as Vector2
			if not world.find_open_path(before, before).is_empty() and not world.find_open_path(after, after).is_empty():
				return {"gate": gate, "before": before, "after": after}
	return {}


func _place_pair(player, ray, position: Vector2) -> void:
	ray.set_external_control_active(true)
	ray.global_position = position
	player.global_position = position
	ray.set_external_control_active(false)
	ray.advance(0.0)


func _expect_dismount_handoff(player, ray, label: String) -> void:
	var report: Dictionary = ray.report()
	_expect(not bool(report.get("external_control_active", true)), "%s dismount retained external control" % label)
	_expect(not bool(report.get("presentation", {}).get("mounted", true)), "%s dismount retained mounted presentation" % label)
	_expect(str(report.get("state", "")) == "near", "%s dismount did not restore independent near-follow state" % label)
	_expect(player.global_position.distance_to(ray.global_position) >= POST_DISMOUNT_MIN_SEPARATION, "%s dismount left Kite overlapping the diver" % label)


func _record_status(note: String) -> void:
	_status_notes.append(note)


func _cancel_tool() -> Dictionary:
	_cancel_count += 1
	return {"changed": true}


func _can_control() -> bool:
	return _control_allowed


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _allow_position(_position: Vector2) -> bool:
	return true


func _finish(world, player, runtime, hud, original_time_scale: float) -> void:
	Engine.time_scale = original_time_scale
	runtime.clear_map()
	runtime.queue_free()
	hud.queue_free()
	player.queue_free()
	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Spark Ray riding smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Spark Ray riding shift_bond=true slow_time=0.2 restored=release+selection+retry+failure+scene_exit commands<=3 mount_clearance=true dismount_handoff=independent+separated+repeatable movement_owner=ray camera_owner=diver hotbar=creature glide_surge=directional+cooldown+no_damage gate_bypass=false forced_dismount=true mobile_action=companion_command profile_unchanged=true.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
