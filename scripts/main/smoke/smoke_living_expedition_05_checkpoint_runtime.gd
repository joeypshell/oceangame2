extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const LivingExpedition05Checkpoint := preload("res://scripts/main/review_checkpoint_living_expedition_05.gd")

const CHECKPOINT_ID := LivingExpedition05Checkpoint.EXCAVATE_READY_ID
const TARGET_ID := "silt_hound_buried_titanium_01"
const ACTION_ID := "excavate"
const CLEARANCE_STEP_PX := 8.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	get_root().add_child(main)
	await process_frame
	await physics_frame
	await process_frame

	_expect(main._review_checkpoint_id == CHECKPOINT_ID, "Main did not load the excavation-ready checkpoint")
	_expect(bool(main._review_checkpoint_report.get("ready", false)), "checkpoint fixture was not ready")
	var world = main._world
	var player = main._player
	var companion = main._companion_sortie.companion()
	_expect(world != null and player != null and companion != null, "playable checkpoint omitted world, diver, or Marl")
	if world == null or player == null or companion == null:
		_finish(main)
		return

	var start_tile: Dictionary = main._review_checkpoint_report.get("review_start_tile", {})
	var expected_tile := LivingExpedition05Checkpoint.EXCAVATE_READY_START_TILE
	_expect(
		int(start_tile.get("x", -1)) == expected_tile.x and int(start_tile.get("y", -1)) == expected_tile.y,
		"Main did not apply the contracted open review start"
	)
	_expect(_body_is_clear(player), "diver began overlapped with terrain")
	_expect(_body_is_clear(companion), "Marl began overlapped with terrain")
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_expect(
			not player.test_move(player.global_transform, direction * CLEARANCE_STEP_PX),
			"diver could not move %s from the review start" % direction
		)

	var target: Vector2 = world.get_material_candidate_state(TARGET_ID).get("candidate", {}).get("center", Vector2.ZERO)
	_expect(target != Vector2.ZERO, "authored excavation target was unavailable")
	_expect(not world.find_open_path(player.global_position, target).is_empty(), "diver had no open route to the mound")
	_expect(world.has_clear_terrain_line(companion.global_position, target), "Marl had no clear line to the mound")

	var control = main._companion_sortie.control_runtime()
	var commands: Array = control.report().get("context_commands", [])
	var excavate_index := _command_index(commands, ACTION_ID)
	_expect(excavate_index >= 0, "BOND palette omitted Excavate at checkpoint startup")
	if excavate_index >= 0:
		_expect(bool((commands[excavate_index] as Dictionary).get("enabled", false)), "Excavate was present but disabled")
		var opened: Dictionary = control.begin_command_mode()
		_expect(bool(opened.get("command_mode", false)) and paused, "BOND did not open and pause the checkpoint")
		var started: Dictionary = control.activate_context_command(excavate_index)
		_expect(bool(started.get("changed", false)) and str(started.get("reason", "")) == "started", "Excavate did not dispatch from the checkpoint")
		_expect(not paused and str(control.excavate_runtime().report().get("state", "")) == "approaching", "Excavate did not resume into Marl's approach")

	_finish(main, {
		"player_position": player.global_position,
		"companion_position": companion.global_position,
		"target_position": target,
		"commands": commands.map(func(value): return str((value as Dictionary).get("id", ""))),
	})


func _body_is_clear(body: CharacterBody2D) -> bool:
	var collision_shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null or collision_shape.shape == null:
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = body.global_transform
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [body.get_rid()]
	return body.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _command_index(commands: Array, command_id: String) -> int:
	for index in range(commands.size()):
		if str((commands[index] as Dictionary).get("id", "")) == command_id:
			return index
	return -1


func _finish(main, evidence := {}) -> void:
	paused = false
	main.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Living Expedition 05 checkpoint runtime smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Living Expedition 05 checkpoint runtime spawn=clear movement=clear palette=recall+excavate dispatch=approaching evidence=%s." % str(evidence))
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
