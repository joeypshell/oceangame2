extends RefCounted

const Checkpoint := preload("res://scripts/main/review_checkpoint_living_expedition_07.gd")
const STEP := 1.0 / 60.0
const EEL := "deep_cache_territorial_eel"
var main
var failures: Array[String] = []
var capture := Callable()
var _touch_index := 50


func _init(main_node) -> void:
	main = main_node


func run() -> void:
	var id: String = main._review_checkpoint_id
	expect(Checkpoint.is_supported(id) and main._review_checkpoint_report.get("ready", false), "checkpoint rejected")
	if not failures.is_empty(): return
	var profile = main._anomaly_survey.profile_state()
	expect(not profile._persistence_enabled, "checkpoint can write the normal profile")
	expect(profile.companion_report().get("active_individual_id") == Checkpoint.MARL_ID, "wrong active individual")
	if id == Checkpoint.NIGHT_ID:
		await night()
		return
	var marl = main._companion_sortie.companion()
	expect(marl != null, "no field companion")
	if marl == null: return
	for body in [main._player, marl]:
		expect(body_clear(body), "%s spawn overlaps terrain" % body.name)
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			expect(not body.test_move(body.global_transform, direction * 8), "%s cannot move %s" % [body.name, direction])
	var adapted := id == Checkpoint.PIN_ID
	var camera := main._player.get_node("Camera2D") as Camera2D
	expect(camera.offset != Vector2.ZERO and camera.zoom == Vector2(0.7, 0.7), "review framing absent or gameplay zoom changed")
	expect(marl.get_node("Presentation").report()["root_claws_visible"] == adapted, "permanent fins do not match profile")
	expect(not control().hides_diver_hotbar(), "Marl stole diver hotbar")
	var tools: Array = main._active_tool_hud.get_test_report().get("owned_tool_ids", [])
	expect(tools.has("shock_prod") and tools.has("salvage_cutter"), "normal diver equipment absent")
	await pause_probe()
	freeze_live()
	await snap("adapted_ready" if adapted else "refuge_closed")
	if adapted:
		await ground_pin()
	else:
		await refuge()
	await recovery()


func pause_probe() -> void:
	key(KEY_B)
	expect(main.get_tree().paused, "B did not pause Main")
	var before := _simulation_snapshot()
	for frame in range(15): await main.get_tree().process_frame
	expect(_simulation_snapshot() == before, "BOND advanced world/survival timers")
	key(KEY_B)
	expect(not main.get_tree().paused, "B did not resume Main")


func _simulation_snapshot() -> Array:
	return [main._player.global_position, main._companion_sortie.companion().global_position,
		main._hostiles.report(), main._sortie_state.oxygen_seconds,
		main._expedition_day_state.report(), control().ground_pin_runtime().report()]


func freeze_live() -> void:
	main.set_process(false)
	main._player.set_physics_process(false)
	main._companion_sortie.set_process(false)
	if main._companion_sortie.companion() != null:
		main._companion_sortie.companion().set_physics_process(false)
		control().set_process(false)


func tick() -> Dictionary:
	await main.get_tree().physics_frame
	main._companion_sortie.companion().advance(STEP)
	control().excavate_runtime().advance(STEP)
	control().ground_pin_runtime().advance(STEP)
	return main._hostiles.update(main._world, main._player.global_position, STEP)


func refuge() -> void:
	expect(command_index("ground_pin") == -1, "unadapted Marl has Ground Pin")
	await snap("unadapted_ready")
	await lure_eel()
	await dispatch("excavate", false)
	var digging_captured := false
	var retreat_captured := false
	var lunge := false
	for frame in range(400):
		if lunge: move_player(Vector2(118.5, 77.5) * 32)
		var event := await tick()
		lunge = lunge or event.get("kind") == "lunge"
		var report: Dictionary = control().refuge_runtime().report()
		if control().excavate_runtime().report()["state"] == "digging" and not digging_captured:
			digging_captured = true
			await snap("refuge_digging")
		if report["group"]["opened"] and not retreat_captured:
			retreat_captured = true
			await snap("refuge_retreat")
		if not report["pending"].is_empty(): break
	expect(digging_captured and retreat_captured, "actual approach/dig/retreat was not observed")
	expect(not control().refuge_runtime().report()["pending"].is_empty(), "live threat did not produce pending memory")
	expect("surface boat" in guidance(), "pending guidance did not request boat return")
	await snap("pending_return")


func ground_pin() -> void:
	await lure_eel()
	var lunges := 0
	var low_warning := false
	for frame in range(240):
		if frame >= 110: move_player(Vector2(122.5, 78.5) * 32)
		var event := await tick()
		lunges += int(event.get("kind") == "lunge")
		if lunges == 1 and main._hostiles.state_for(EEL)["phase"] == "warning":
			low_warning = true
			break
	expect(low_warning, "normal eel lure did not reach low warning")
	if not low_warning: return
	await dispatch("ground_pin", true)
	var lunge := false
	for frame in range(110):
		if lunge: move_player(Vector2(120.5, 78.5) * 32)
		var event := await tick()
		lunge = lunge or event.get("kind") == "lunge"
		if control().ground_pin_runtime().report()["state"] == "holding": break
	expect(control().ground_pin_runtime().report()["state"] == "holding", "normal touch command failed to grip eel: %s eel=%s Marl=%s" % [control().report(), main._hostiles.state_for(EEL), main._companion_sortie.companion().global_position])
	if control().ground_pin_runtime().report()["state"] != "holding": return
	# Use part of the actual opening to retreat, leaving both bodies readable.
	for frame in range(20):
		move_player(Vector2(119.5, 78.5) * 32)
		await tick()
	await snap("pin_held")
	await pause_probe()
	for frame in range(110):
		await tick()
		if not control().ground_pin_runtime().busy(): break
	expect(main._hostiles.state_for(EEL)["phase"] == "recovery", "eel did not resume recovery")
	expect(main._companion_sortie.companion().get_node("Presentation").report()["release_visible"], "release lift absent")
	expect("recovering" in guidance(), "release has no cooldown guidance")
	await snap("pin_released")


func lure_eel() -> void:
	var refuge = main._world.burrow_refuge_presentation()
	var approach: Vector2 = refuge.target + Vector2(32, -32)
	for frame in range(90):
		move_player(approach)
		await tick()
		if main._player.global_position.distance_to(approach) < 1.0 and main._hostiles.state_for(EEL)["phase"] == "warning": return
	expect(false, "approaching the refuge did not draw a real eel warning")


func recovery() -> void:
	var marl = main._companion_sortie.companion()
	marl.force_readable_separation(Vector2.LEFT)
	expect(marl.report()["state"] == "separated", "forced separation unreadable")
	await dispatch("recall", false)
	for frame in range(100):
		await tick()
	expect(body_clear(marl), "recovery clipped Marl")
	expect(marl.global_position.distance_to(main._player.global_position) > 20, "recovery stacked Marl onto diver")
	expect(marl.report()["state"] not in ["separated", "recovery"], "Marl never resumed follow")
	expect(not control().hides_diver_hotbar(), "recovery changed hotbar ownership")


func night() -> void:
	expect(main._world.is_inside_boat(main._player.global_position), "night checkpoint not at canonical boat")
	expect("Root Claws" in guidance(), "secured memory omitted night direction")
	key(KEY_N)
	for frame in range(5): await main.get_tree().process_frame
	expect(main._expedition_day_state.phase == "debrief", "N did not open real night debrief")
	expect(main._companion_sortie.requires_adaptation_selection(), "night has no deliberate choice")
	freeze_live()
	await snap("night_choice")
	key(KEY_B)
	expect("Not tonight" in "\n".join(main._companion_sortie.debrief_lines()), "B omitted deferral")
	key(KEY_B)
	key(KEY_SPACE)
	expect(main._anomaly_survey.profile_state().companion_report()["individual"]["selected_adaptation_id"] == "root_claws", "Space did not confirm Root Claws")


func control():
	return main._companion_sortie.control_runtime()


func guidance() -> String:
	return main._companion_journey_guidance.objective_text(main._world, main._player, main._anomaly_survey.profile_state(), main._companion_sortie, main._expedition_day_state)


func command_index(id: String) -> int:
	var commands: Array = control().report()["context_commands"]
	for index in range(commands.size()):
		if commands[index]["id"] == id: return index
	return -1


func dispatch(id: String, mobile: bool) -> void:
	var index := command_index(id)
	expect(index >= 0, "command missing: " + id)
	if index < 0: return
	if mobile:
		await touch("bond")
		expect(main.get_tree().paused, "touch BOND did not pause")
		for step in range(index): await touch("tool")
		await touch("use")
	else:
		key(KEY_B)
		key(KEY_1 + index)
	expect(not main.get_tree().paused, "dispatch did not close BOND: " + id)


func touch(id: String) -> void:
	var mobile = main.get_node("MobileTestControls")
	var rects: Dictionary = mobile.get_test_report()["command_rects"]
	expect(rects.has(StringName(id)), "missing actual touch button: " + id)
	if not rects.has(StringName(id)): return
	_touch_index += 1
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = _touch_index
		event.position = (rects[StringName(id)] as Rect2).get_center()
		event.pressed = pressed
		main.get_viewport().push_input(event, true)
		await main.get_tree().process_frame


func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		main.get_viewport().push_input(event, true)


func move_player(target: Vector2) -> void:
	var player = main._player
	player.move_and_collide(player.global_position.direction_to(target) * minf(180 * STEP, player.global_position.distance_to(target)))


func body_clear(body: CharacterBody2D) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body.get_node("CollisionShape2D").shape
	query.transform = body.global_transform
	query.collision_mask = 1
	query.exclude = [body.get_rid(), main._player.get_rid()]
	return body.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func snap(state: String) -> void:
	main._update_status_label()
	if capture.is_valid(): await capture.call(state)


func expect(value: bool, message: String) -> void:
	if not value: failures.append(message)
