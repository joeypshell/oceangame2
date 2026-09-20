extends SceneTree

const WorldScene := preload("res://scenes/world/GreyboxWorld.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const Sortie := preload("res://scripts/companion/companion_sortie_runtime.gd")
const Profile := preload("res://scripts/main/expansion_profile_state.gd")
const Hostiles := preload("res://scripts/main/territorial_hostile_controller.gd")
const Geometry := preload("res://scripts/companion/silt_hound_pin_geometry.gd")
const Biological := preload("res://scripts/main/biological_resource_controller.gd")
const STEP := 1.0 / 60.0
const MARL := "silt_hound_juvenile_01"
const EEL := "deep_cache_territorial_eel"

var world
var player
var marl
var sortie
var control
var pin
var profile
var hostiles := Hostiles.new()
var equipment := true
var movement_allowed := true
var failures: Array[String] = []
var held_count := 0
var contacts := 0
var source_before: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	world = WorldScene.instantiate()
	world.map_path = "res://maps/production_level_01.greybox.json"
	root.add_child(world)
	player = PlayerScene.instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	profile = Profile.new("", false)
	profile.load_profile()
	profile.commit_companion_rescue(MARL, "silt_hound", "Marl", false)
	profile.select_active_companion(MARL, false)
	sortie = Sortie.new()
	root.add_child(sortie)
	sortie.bind_interface(null, Callable(), Callable(), Callable())
	sortie.bind_map(world, player, profile, Callable(self, "_access"), true, false, hostiles)
	marl = sortie.companion()
	control = sortie.control_runtime()
	pin = control.ground_pin_runtime()
	marl.set_physics_process(false)
	control.set_process(false)
	await physics_frame
	source_before = world._map_data.duplicate(true)
	_expect(pin.command().is_empty() and pin.dispatch()["reason"] == "root_claws_required", "unlearned action available")
	profile.earn_companion_memory("guarded_the_nest", false)
	_expect(profile.select_companion_adaptation("root_claws", false)["changed"], "fixture could not learn Root Claws")
	var profile_before: Dictionary = profile.companion_report()
	await _denials_and_whiff()
	await _timeout_and_pause()
	await _release_paths()
	_expect(world._map_data == source_before, "runtime mutated source map")
	_expect(profile.companion_report() == profile_before, "pin changed permanent profile")
	if await _acquire():
		world.free()
		pin.cancel("world_teardown")
		_expect(not pin.busy() and hostiles.state_for(EEL)["phase"] != "support_held", "world-first teardown retained hold")
	sortie.clear_map()
	sortie.free()
	player.free()
	if is_instance_valid(world):
		world.free()
	await process_frame
	for failure in failures:
		push_error("Marl Ground Pin: " + failure)
	if failures.is_empty():
		print("PASS: Marl Ground Pin physical_holds=%d max_hold=1.75 cooldown=8 no_damage=true no_snap=true pause=true all_release_paths=true source_unchanged=true" % held_count)
	quit(0 if failures.is_empty() else 1)


func _fresh() -> void:
	control.reset_transient("next_day")
	pin.advance(8.0)
	hostiles.on_map_loaded(world)
	equipment = true
	movement_allowed = true
	world.set_visibility_upgrade_state("dive_light_1", true)
	player.global_position = Vector2(122.5, 77.5) * 32
	marl.configure(world, player, Callable(self, "_position_allowed"), profile.companion_report()["individual"])
	marl.global_position = Vector2(119.5, 77.5) * 32


func _tick() -> Dictionary:
	await physics_frame
	var before: Vector2 = marl.global_position
	var was_pinning: bool = pin.busy()
	marl.advance(STEP)
	pin.advance(STEP)
	var event := hostiles.update(world, player.global_position, STEP)
	contacts += int(event.get("kind") == "contact")
	_expect(not was_pinning or before.distance_to(marl.global_position) <= 2.0, "Marl snapped instead of approaching")
	_expect(Geometry.body_clear(world, marl, marl.global_position, player), "Marl clipped terrain")
	return event


func _prepare_low_warning() -> void:
	_fresh()
	# Authored eel begins at home. Lure/dodge through its unchanged phase machine.
	var lunges := 0
	for tick in range(210):
		await physics_frame
		if tick >= 110:
			_move(player, Vector2(122.5, 78.5) * 32)
		var event := hostiles.update(world, player.global_position, STEP)
		contacts += int(event.get("kind") == "contact")
		lunges += int(event.get("kind") == "lunge")
		if lunges == 1 and hostiles.state_for(EEL)["phase"] == "warning":
			return
	_expect(false, "second low warning was unreachable")


func _acquire(mobile := false) -> bool:
	var contacts_before := contacts
	await _prepare_low_warning()
	control.begin_command_mode()
	var commands: Array = control.report()["context_commands"]
	_expect(commands.size() <= 3 and not control.hides_diver_hotbar(), "command budget/hotbar changed")
	var index := -1
	for i in range(commands.size()):
		if commands[i]["id"] == "ground_pin":
			index = i
	_expect(index >= 0, "learned command absent")
	if mobile:
		for i in range(index):
			control.handle_input(_input("active_tool_cycle_next"))
		control.handle_input(_input("active_tool_use"))
	else:
		control.handle_input(_input("companion_action_%d" % (index + 1)))
	_expect(pin.busy() and not paused, "BOND dispatch failed: %s" % str(pin.command()))
	var lunge_started := false
	for tick in range(110):
		if lunge_started:
			_move(player, Vector2(120.5, 78.5) * 32)
		var event := await _tick()
		lunge_started = lunge_started or event.get("kind") == "lunge"
		if pin.report()["state"] == "holding":
			held_count += 1
			_expect(contacts == contacts_before, "physical acquisition needed diver damage")
			_expect(hostiles.state_for(EEL)["health"] == 3, "pin damaged eel")
			_expect(Geometry.contact_clear(world, marl, hostiles.state_for(EEL)["position"], player), "hold acquired without physical contact")
			return true
		if not pin.busy():
			break
	_expect(false, "real acquisition failed: pin=%s eel=%s Marl=%s" % [str(pin.report()), str(hostiles.state_for(EEL)), str(marl.global_position)])
	return false


func _denials_and_whiff() -> void:
	_fresh()
	hostiles.update(world, player.global_position, 0.0)
	_expect(pin.dispatch()["reason"] == "target_high", "high eel accepted")
	equipment = false
	_expect(pin.dispatch()["reason"] == "equipment_required", "equipment bypass")
	await _prepare_low_warning()
	movement_allowed = false
	_expect(pin.dispatch()["reason"] == "path_blocked", "access segment bypass")
	movement_allowed = true
	var wall := _obstacle(Vector2(120.5, 77.5) * 32, Vector2(12, 90))
	await physics_frame
	_expect(pin.dispatch()["reason"] == "path_blocked", "full-body blocked sweep accepted")
	wall.free()
	await physics_frame
	_expect(pin.dispatch()["changed"], "valid approach denied")
	_expect(not pin.dispatch()["changed"], "approach refreshed")
	_expect(not marl.begin_excavate_approach(Vector2(121.5, 78.5) * 32), "Excavate ran with Pin")
	# Keep the lure high: a grounded attempt must whiff, not home up to the eel.
	player.global_position = Vector2(120.5, 77.5) * 32
	for tick in range(110):
		await _tick()
		if not pin.busy():
			break
	_expect(not pin.busy() and hostiles.state_for(EEL)["phase"] != "support_held", "whiff froze enemy")
	_expect(pin.report()["cooldown_seconds"] > 0, "whiff can be spammed")
	_fresh()
	_expect(marl.begin_excavate_approach(Vector2(121.5, 78.5) * 32), "dig fixture failed")
	_expect(pin.dispatch()["reason"] == "busy", "Pin interrupted Excavate")
	marl.cancel_excavate_action()
	await _prepare_low_warning()
	var contexts: Array = world._map_data["companion_contexts"]
	world._map_data["companion_contexts"] = []
	_expect(pin.dispatch()["reason"] == "source_invalid", "missing source accepted")
	world._map_data["companion_contexts"] = contexts
	_expect(pin.dispatch()["changed"], "cancel-approach fixture failed")
	equipment = false
	pin.advance(STEP)
	_expect(not pin.busy() and hostiles.state_for(EEL)["phase"] == "warning", "invalid approach touched hostile")
	_fresh()
	hostiles.apply_weapon_hit(world, EEL, 3)
	_expect(pin.dispatch()["reason"] == "not_threatening", "defeated target accepted")


func _timeout_and_pause() -> void:
	if not await _acquire(true):
		return
	var held_position: Vector2 = hostiles.state_for(EEL)["position"]
	var held_marl: Vector2 = marl.global_position
	var held_seconds: float = hostiles.state_for(EEL)["phase_seconds"]
	var biological := Biological.new(profile)
	biological.on_map_loaded(world, false)
	var harvest: Dictionary = biological.update(world, hostiles, null, held_position, 34.0, 2.0, 0, 2)
	_expect(harvest.get("reason") == "hostile_not_defeated" and not biological.is_collected("deep_cache_eel_electrocyte_harvest"), "pin exposed defeat-only harvest")
	_expect(not world.is_salvage_collected("salvage_deep_right_cache"), "pin collected cache")
	_expect(not hostiles.request_support_hold(world, EEL, pin), "hold refreshed/stacked")
	_expect(not hostiles.apply_support_interrupt(world, EEL, player.global_position)["changed"], "Guardian pulse stacked onto hold")
	await _capture("held")
	control.begin_command_mode()
	for tick in range(20):
		await process_frame
		marl.advance(1.0)
		pin.advance(1.0)
		hostiles.update(world, player.global_position, 1.0)
	_expect(marl.global_position == held_marl and hostiles.state_for(EEL)["position"] == held_position and hostiles.state_for(EEL)["phase_seconds"] == held_seconds, "BOND did not freeze hold/actors")
	control.end_command_mode()
	for tick in range(110):
		var event := await _tick()
		_expect(event.get("kind") != "contact", "held/released stale lunge contact")
		if not pin.busy():
			_expect(tick * STEP <= 1.75, "hold exceeded maximum")
			break
		_expect(hostiles.state_for(EEL)["position"] == held_position, "held eel moved")
	_expect(pin.report()["last_reason"] == "timeout", "hold did not time out")
	_expect(is_equal_approx(pin.report()["cooldown_seconds"], 8.0), "release did not start 8s cooldown")
	_expect(hostiles.state_for(EEL)["phase"] == "recovery", "release restored stale lunge")
	_expect(pin.dispatch()["reason"] == "cooldown", "cooldown bypass")
	control.begin_command_mode()
	pin.advance(10.0)
	_expect(pin.report()["cooldown_seconds"] == 8.0, "BOND advanced cooldown")
	control.end_command_mode()
	pin.advance(7.99)
	_expect(pin.dispatch()["reason"] == "cooldown", "cooldown expired early")
	pin.advance(0.01)
	_expect(is_zero_approx(pin.report()["cooldown_seconds"]), "cooldown failed to expire")
	for tick in range(25):
		_move(player, Vector2(119.5, 77.5) * 32)
		await _tick()
	_expect(marl.global_position != held_marl and marl.global_position.distance_to(player.global_position) > 20, "release stacked Marl or failed to resume follow")
	await _capture("released")


func _release_paths() -> void:
	for reason in ["recall", "separation", "forced_separation", "lost_contact", "anchor_loss", "line_loss", "weapon_hit", "lethal_hit", "oxygen_failure", "hazard", "retry", "combat_defeat", "reload", "next_day", "teardown", "equipment_loss", "source_loss", "control_exit"]:
		if not await _acquire():
			return
		var obstacle: StaticBody2D
		match reason:
			"recall":
				control.begin_command_mode()
				control.activate_context_command(0)
			"separation":
				player.position += Vector2(0, -200)
			"forced_separation":
				marl.force_readable_separation(Vector2.LEFT)
			"lost_contact":
				marl.move_and_collide(Vector2.UP * 30)
			"anchor_loss":
				obstacle = _obstacle(marl.global_position, Vector2(12, 12))
				await physics_frame
			"line_loss":
				player.position = marl.global_position + Vector2(0, -64)
				obstacle = _obstacle(player.global_position.lerp(marl.global_position, 0.5), Vector2(50, 4))
				await physics_frame
				_expect(Geometry.body_clear(world, marl, marl.global_position, player), "LOS fixture also blocked anchor")
			"weapon_hit":
				var hit := hostiles.apply_weapon_hit(world, EEL, 1, true, player.global_position)
				_expect(hit["hold_released_before_damage"] and hit["health"] == 2 and hit["recoil_distance"] > 0 and not pin.busy(), "weapon did not release before ordinary damage/recoil")
			"lethal_hit":
				var hit := hostiles.apply_weapon_hit(world, EEL, 3, true, player.global_position)
				_expect(hit["hold_released_before_damage"] and hit["defeated"] and not pin.busy(), "lethal hit retained hold")
			"reload", "next_day":
				hostiles.on_map_loaded(world)
			"teardown":
				control.clear_map()
			"control_exit":
				control.get_parent().remove_child(control)
			"source_loss":
				world._map_data["companion_contexts"] = []
			"equipment_loss":
				equipment = false
			_:
				sortie.reset_control(reason)
		hostiles.update(world, player.global_position, 0.0)
		pin.advance(0.0)
		_expect(not pin.busy() and hostiles.state_for(EEL)["phase"] != "support_held" and not marl.ground_pin_active(), reason + " retained hold")
		if obstacle != null:
			obstacle.free()
		if reason == "weapon_hit":
			_expect(hostiles.apply_weapon_hit(world, EEL, 2)["defeated"], "normal defeat lost")
		if reason == "source_loss":
			world._map_data["companion_contexts"] = source_before["companion_contexts"].duplicate(true)
		if reason == "control_exit":
			sortie.add_child(control)
		if reason in ["teardown", "control_exit"]:
			control.bind_map(world, player, marl, null, hostiles)
			control.bind_refuge_context(profile, Callable(self, "_access"))
		await physics_frame


func _obstacle(point: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = point
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	root.add_child(body)
	return body


func _move(body: CharacterBody2D, target: Vector2) -> void:
	body.move_and_collide(body.global_position.direction_to(target) * minf(180 * STEP, body.global_position.distance_to(target)))


func _input(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _access(_id: String) -> bool:
	return equipment


func _position_allowed(_point: Vector2) -> bool:
	return movement_allowed


func _expect(value: bool, message: String) -> void:
	if not value and not failures.has(message):
		failures.append(message)


func _capture(label: String) -> void:
	if not "--capture-marl-pin" in OS.get_cmdline_args():
		return
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.position = Vector2(122, 77) * 32
	camera.zoom = Vector2.ONE * 2.2
	camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://tmp/living_expedition_07/pin/%dx%d" % [root.size.x, root.size.y]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	_expect(root.get_texture().get_image().save_png(directory.path_join(label + ".png")) == OK, "capture failed")
	camera.free()
