extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	main.set_process(false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false

	var targets := _instant_salvage(main._world)
	_expect(targets.size() >= 3, "two-sortie smoke needs three instant salvage targets")
	if targets.size() < 3:
		_finish()
		return

	var daylight_start: float = main._expedition_day_state.daylight_remaining_seconds
	var expected_day_score := 0
	for index in range(2):
		var target: Dictionary = targets[index]
		main._player.global_position = target["center"]
		main._process(0.0)
		expected_day_score += int(target.get("score", 0))
		_expect(main._expedition_day_state.sortie_count == index + 1, "sortie count did not advance on departure")
		_expect(main._sortie_state.active, "departed sortie was not active")
		_expect(is_equal_approx(main._sortie_state.oxygen_seconds, main._oxygen_capacity_seconds()), "new sortie oxygen was not refreshed")
		_expect(main._sortie_state.held_salvage == 1, "sortie did not hold one target")
		main._process(1.0)
		var daylight_before_offload: float = main._expedition_day_state.daylight_remaining_seconds
		main._player.global_position = main._world.get_extraction_center()
		main._process(0.0)
		_expect(not main._sortie_state.active, "boat offload did not end sortie")
		_expect(main._sortie_state.held_salvage == 0, "boat offload retained held cargo")
		_expect(main._expedition_day_state.banked_salvage == index + 1, "day bank count did not accumulate")
		_expect(main._expedition_day_state.banked_score == expected_day_score, "day bank score did not accumulate")
		_expect(is_equal_approx(main._expedition_day_state.daylight_remaining_seconds, daylight_before_offload), "boat offload reset daylight")
		_expect(main._expedition_day_state.phase == main._expedition_day_state.PHASE_ACTIVE, "boat offload ended expedition day")

	var committed_wallet: int = main._session_wallet()
	var committed_day_score: int = main._expedition_day_state.banked_score
	var failed_target: Dictionary = targets[2]
	main._player.global_position = failed_target["center"]
	main._process(0.0)
	_expect(main._expedition_day_state.sortie_count == 3, "third departure did not start another sortie")
	main._sortie_state.oxygen_seconds = 0.1
	main._process(0.2)
	_expect(main._sortie_state.failed and not main._sortie_state.active, "oxygen failure did not end active sortie")
	_expect(main._sortie_state.held_salvage == 0, "oxygen failure retained unbanked cargo")
	_expect(not main._world.is_salvage_collected(str(failed_target.get("id", ""))), "oxygen failure did not restore unbanked target")
	_expect(main._expedition_day_state.banked_score == committed_day_score, "failure changed committed day score")
	_expect(main._session_wallet() == committed_wallet, "failure duplicated committed wallet rewards")
	_expect(main._world.is_salvage_collected(str(targets[0].get("id", ""))), "failure restored first banked target")
	_expect(main._world.is_salvage_collected(str(targets[1].get("id", ""))), "failure restored second banked target")
	_expect(main._expedition_day_state.daylight_remaining_seconds < daylight_start, "sorties did not share daylight countdown")
	_finish(main)


func _instant_salvage(world) -> Array:
	var targets := []
	for salvage in world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			targets.append(salvage)
	return targets


func _finish(main = null) -> void:
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Multiple-sortie smoke failed: %s" % failure)
		quit(1)
		return
	print("Multiple-sortie smoke passed: day=%d sorties=%d banked=%d score=%d daylight=%.1f oxygen_failure_restored=true rewards_exact_once=true." % [
		main._expedition_day_state.day_number,
		main._expedition_day_state.sortie_count,
		main._expedition_day_state.banked_salvage,
		main._expedition_day_state.banked_score,
		main._expedition_day_state.daylight_remaining_seconds,
	])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
