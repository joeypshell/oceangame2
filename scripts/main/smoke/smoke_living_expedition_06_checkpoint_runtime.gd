extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ReviewCheckpointLivingExpedition06 := preload("res://scripts/main/review_checkpoint_living_expedition_06.gd")
const ReviewProfileMode := preload("res://scripts/main/review_profile_mode.gd")

const CLEARANCE_STEP_PX := 8.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var checkpoint_id := ReviewProfileMode.checkpoint_id(OS.get_cmdline_user_args(), OS.get_cmdline_args())
	_expect(ReviewCheckpointLivingExpedition06.is_supported(checkpoint_id), "unsupported LE06 checkpoint argument: %s" % checkpoint_id)
	var main = MAIN_SCENE.instantiate()
	get_root().add_child(main)
	for _frame in range(4):
		await process_frame
		await physics_frame
	_expect(main._review_checkpoint_id == checkpoint_id, "Main selected the wrong checkpoint")
	_expect(bool(main._review_checkpoint_report.get("ready", false)), "checkpoint rejected: %s" % main._review_checkpoint_report)
	if not bool(main._review_checkpoint_report.get("ready", false)):
		_finish(main, checkpoint_id)
		return
	var world = main._world
	var player = main._player
	var companion = main._companion_sortie.companion()
	_expect(world != null and player != null and companion != null, "actual Main omitted world, diver, or Kite")
	if world == null or player == null or companion == null:
		_finish(main, checkpoint_id)
		return
	_expect(_body_is_clear(player), "diver began overlapped with terrain")
	_expect(_body_is_clear(companion), "Kite began overlapped with terrain")
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_expect(not player.test_move(player.global_transform, direction * CLEARANCE_STEP_PX), "diver could not move %s from the review start" % direction)
	var profile = main._anomaly_survey.profile_state()
	var adaptation_id := str(profile.companion_report().get("individual", {}).get("selected_adaptation_id", ""))
	var journey_state := str(profile.signal_reef_journey_report().get("state", ""))
	var nursery: Dictionary = world.get_signal_reef_nursery_report()
	var expected_adaptation := "guardian_pulse" if checkpoint_id == ReviewCheckpointLivingExpedition06.GUARDIAN_READY_ID else "anchor_fins"
	var expected_state := "restored" if checkpoint_id == ReviewCheckpointLivingExpedition06.RESTORED_NURSERY_ID else "unresolved"
	_expect(adaptation_id == expected_adaptation, "checkpoint selected %s instead of %s" % [adaptation_id, expected_adaptation])
	_expect(journey_state == expected_state and str(nursery.get("state", "")) == expected_state, "profile/world journey projection drifted")
	if checkpoint_id == ReviewCheckpointLivingExpedition06.RESTORED_NURSERY_ID:
		_expect(int(nursery.get("school_member_count", 0)) == 7, "restored checkpoint did not project the larger nursery")
		_expect(not _command_ids(main).has("anchor_brace") and not _command_ids(main).has("guardian_pulse_action"), "restored checkpoint retained a completed field action")
	else:
		var action_id := "guardian_pulse_action" if expected_adaptation == "guardian_pulse" else "anchor_brace"
		var commands := _commands(main)
		var index := _command_ids(main).find(action_id)
		_expect(index >= 0, "BOND palette omitted %s" % action_id)
		if index >= 0:
			_expect(bool((commands[index] as Dictionary).get("enabled", false)), "%s was present but disabled" % action_id)
	var guidance: String = str(main._companion_journey_guidance.objective_text(world, player, profile, main._companion_sortie, main._expedition_day_state))
	_expect(
		guidance.find("PARTNER") != -1
		and (guidance.find("Signal Reef") != -1 or guidance.find("filter skates") != -1 or guidance.find("school") != -1),
		"checkpoint omitted compact nursery guidance: %s" % guidance
	)
	_finish(main, checkpoint_id, {"adaptation": adaptation_id, "state": expected_state, "guidance": guidance, "commands": _command_ids(main)})


func _commands(main) -> Array:
	return main._companion_sortie.control_runtime().report().get("context_commands", [])


func _command_ids(main) -> Array[String]:
	var ids: Array[String] = []
	for command in _commands(main):
		ids.append(str((command as Dictionary).get("id", "")))
	return ids


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


func _finish(main, checkpoint_id: String, evidence := {}) -> void:
	paused = false
	main.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Living Expedition 06 checkpoint runtime smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Living Expedition 06 checkpoint=%s isolation=true spawn=clear movement=four_direction evidence=%s." % [checkpoint_id, str(evidence)])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
