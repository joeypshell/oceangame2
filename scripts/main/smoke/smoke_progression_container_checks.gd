extends "res://scripts/main/smoke/smoke_check_base.gd"

const CHEST_ID := "lower_loop_upgrade_chest"
const EXPECTED_REWARD := 400
const EXPECTED_PROMPT := "Upgrade chest +400 wallet"


func _smoke_upgrade_chest_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Upgrade-chest smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return
	if not _world.has_method("get_progression_containers"):
		push_error("Upgrade-chest smoke requires progression container runtime queries.")
		get_tree().quit(1)
		return

	var chest := _container_by_id(CHEST_ID)
	if chest.is_empty():
		push_error("Upgrade-chest smoke did not find container %s." % CHEST_ID)
		get_tree().quit(1)
		return
	if _session_wallet() != 0 or _main._progression_containers.is_opened(CHEST_ID):
		push_error("Upgrade-chest smoke expected fresh state: wallet=%d opened=%s." % [_session_wallet(), str(_main._progression_containers.is_opened(CHEST_ID))])
		get_tree().quit(1)
		return

	_player.global_position = chest["center"]
	_process(0.0)
	if _session_wallet() != EXPECTED_REWARD or not _main._progression_containers.is_opened(CHEST_ID):
		push_error("Upgrade-chest smoke reward mismatch: wallet=%d opened=%s." % [_session_wallet(), str(_main._progression_containers.is_opened(CHEST_ID))])
		get_tree().quit(1)
		return
	if _held_salvage != 0 or _banked_salvage != 0 or _banked_score != 0:
		push_error("Upgrade-chest smoke mutated cargo/salvage: held=%d banked=%d score=%d." % [_held_salvage, _banked_salvage, _banked_score])
		get_tree().quit(1)
		return
	if _status_text().find(EXPECTED_PROMPT) == -1:
		push_error("Upgrade-chest smoke missing reward prompt: %s." % _status_text())
		get_tree().quit(1)
		return

	_reset_run()
	_player.global_position = chest["center"]
	_process(0.0)
	if _session_wallet() != EXPECTED_REWARD or _status_text().find(EXPECTED_PROMPT) != -1:
		push_error("Upgrade-chest smoke replay granted reward or stale prompt after reset: wallet=%d status=%s." % [_session_wallet(), _status_text()])
		get_tree().quit(1)
		return

	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed or _session_wallet() != EXPECTED_REWARD or not _main._progression_containers.is_opened(CHEST_ID):
		push_error("Upgrade-chest smoke failure persistence mismatch: failed=%s wallet=%d opened=%s." % [
			str(_run_failed),
			_session_wallet(),
			str(_main._progression_containers.is_opened(CHEST_ID)),
		])
		get_tree().quit(1)
		return

	print("Upgrade-chest smoke passed: chest=%s reward=%d wallet=%d opened_ids=%s cargo_unchanged=true failure_persisted=true." % [
		CHEST_ID,
		EXPECTED_REWARD,
		_session_wallet(),
		_main._progression_containers.opened_ids(),
	])
	get_tree().quit()


func _container_by_id(container_id: String) -> Dictionary:
	for container in _world.get_progression_containers():
		if str(container.get("id", "")) == container_id:
			return container
	return {}


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
