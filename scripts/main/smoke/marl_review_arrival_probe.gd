extends RefCounted

const Driver := preload("res://scripts/main/smoke/marl_review_driver.gd")
const READ_SECONDS := 12.0


static func run(main) -> Array[String]:
	var driver := Driver.new(main)
	var tree = main.get_tree()
	var start: Vector2 = main._player.global_position
	var oxygen: float = main._sortie_state.oxygen_seconds
	var daylight: float = main._expedition_day_state.daylight_remaining_seconds
	var source: Dictionary = main._world._map_data.duplicate(true)
	# Keep ALL normal process/physics owners running, including real damage and
	# knockback. The deterministic capture driver deliberately cannot test this.
	_check_menu(driver, "immediate")
	await tree.create_timer(READ_SECONDS).timeout
	driver.expect(main._player_health.current_health == 3, "reading directions caused an eel hit")
	driver.expect(main._player.global_position.distance_to(start) < 1.0, "idle arrival was displaced")
	driver.expect(main._hostiles.state_for(driver.EEL)["phase"] == "home", "arrival automatically provoked the eel")
	driver.expect(main._sortie_state.oxygen_seconds < oxygen - 10.0, "live arrival skipped oxygen")
	driver.expect(main._expedition_day_state.daylight_remaining_seconds < daylight - 10.0, "live arrival skipped daylight")
	driver.expect("Approach the eel" in driver.guidance(), "safe approach omitted threat guidance")
	_check_menu(driver, "after reading")
	await driver.touch("bond")
	driver.expect(tree.paused and driver.command_index("excavate") == 1, "delayed touch BOND omitted Excavate")
	await driver.touch("bond")
	driver.expect(not tree.paused, "touch BOND did not resume")
	if not driver.failures.is_empty(): return driver.failures
	# Ordinary movement input brings the pair into the unchanged warning range.
	Input.action_press("ui_right")
	for frame in range(120):
		await tree.physics_frame
		if main._hostiles.state_for(driver.EEL)["phase"] == "warning": break
	Input.action_release("ui_right")
	driver.expect(main._hostiles.state_for(driver.EEL)["phase"] == "warning", "rightward swim did not draw warning")
	await driver.dispatch("excavate", false)
	driver.expect(driver.control().excavate_runtime().report()["busy"], "number 2 did not start the real dig")
	var dodged := false
	for frame in range(600):
		await tree.physics_frame
		if not dodged and main._hostiles.state_for(driver.EEL)["phase"] == "lunge":
			dodged = true
			Input.action_press("ui_left")
		if dodged and main._player.global_position.x <= start.x - 24.0:
			Input.action_release("ui_left")
		if not driver.control().refuge_runtime().report()["pending"].is_empty(): break
	Input.action_release("ui_left")
	var refuge: Dictionary = driver.control().refuge_runtime().report()
	driver.expect(dodged and refuge["live_warning_lunge"], "live warning/lunge was not observed")
	driver.expect(refuge["physical_dig_complete"] and not refuge["pending"].is_empty(), "live play did not shelter group and earn pending memory: %s" % refuge)
	driver.expect(main._player_health.current_health == 3, "live dodge required absorbing an eel hit")
	driver.expect("surface boat" in driver.guidance(), "live result omitted return instruction")
	driver.expect(main._world._map_data == source, "arrival mutated map source")
	if driver.failures.is_empty():
		print("PASS: LE07 live arrival immediate/delayed BOND=Recall+Excavate keyboard+touch read_seconds=12 health=3 input_lure=true input_dig=true input_dodge=true pending_memory=true")
	return driver.failures


static func _check_menu(driver, stage: String) -> void:
	driver.key(KEY_B)
	driver.expect(driver.main.get_tree().paused, stage + " B did not open palette")
	var commands: Array = driver.control().report()["context_commands"]
	driver.expect(commands.size() == 2 and driver.command_index("excavate") == 1, stage + " menu did not offer number 2 Excavate")
	if commands.size() == 2:
		driver.expect(commands[1].get("enabled", false), stage + " Excavate disabled: %s" % commands[1])
	driver.key(KEY_B)
