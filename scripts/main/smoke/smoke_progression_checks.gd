extends "res://scripts/main/smoke/smoke_check_base.gd"


func _smoke_pass_18_progression_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pass 18 progression smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	var setup_target := _instant_salvage_target()
	if setup_target.is_empty():
		push_error("Pass 18 progression smoke requires an instant salvage setup target.")
		get_tree().quit(1)
		return

	if _session_wallet() != 0 or _session_payout_total() != 0 or _has_oxygen_tank_upgrade():
		push_error("Pass 18 progression smoke expected fresh progression state, wallet=%d payout=%d upgraded=%s." % [_session_wallet(), _session_payout_total(), str(_has_oxygen_tank_upgrade())])
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	if _try_purchase_oxygen_tank_upgrade() or _session_wallet() != 0 or _has_oxygen_tank_upgrade():
		push_error("Pass 18 progression smoke insufficient-funds purchase mutated state: wallet=%d upgraded=%s." % [_session_wallet(), str(_has_oxygen_tank_upgrade())])
		get_tree().quit(1)
		return
	if _status_label == null or _status_label.text.find("Need 500 more") == -1:
		push_error("Pass 18 progression smoke did not show compact insufficient-funds feedback: %s." % _status_text())
		get_tree().quit(1)
		return

	_player.global_position = setup_target["center"]
	_collect_salvage_for_smoke(setup_target)
	if _held_salvage <= 0 or _session_wallet() != 0:
		push_error("Pass 18 progression smoke held salvage created wallet before banking: held=%d wallet=%d." % [_held_salvage, _session_wallet()])
		get_tree().quit(1)
		return

	var restored_id := str(setup_target.get("id", ""))
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed or _held_salvage != 0 or _session_wallet() != 0 or _world.is_salvage_collected(restored_id):
		push_error("Pass 18 progression smoke oxygen failure payout/restoration mismatch: failed=%s held=%d wallet=%d collected=%s." % [
			str(_run_failed),
			_held_salvage,
			_session_wallet(),
			str(_world.is_salvage_collected(restored_id)),
		])
		get_tree().quit(1)
		return

	_reset_run()
	var banked_target_ids := _bank_until_upgrade_affordable()
	if _session_wallet() < _oxygen_upgrade_cost() or banked_target_ids.is_empty():
		push_error("Pass 18 progression smoke could not bank enough wallet for purchase: wallet=%d targets=%s." % [_session_wallet(), banked_target_ids])
		get_tree().quit(1)
		return

	var wallet_before_purchase := _session_wallet()
	var payout_before_purchase := _session_payout_total()
	_player.global_position = _world.get_extraction_center()
	if not _try_purchase_oxygen_tank_upgrade():
		push_error("Pass 18 progression smoke affordable purchase was blocked: wallet=%d status=%s." % [_session_wallet(), _status_text()])
		get_tree().quit(1)
		return
	if not _has_oxygen_tank_upgrade() or _session_wallet() != wallet_before_purchase - _oxygen_upgrade_cost() or _session_payout_total() != payout_before_purchase:
		push_error("Pass 18 progression smoke purchase state mismatch: wallet=%d before=%d payout=%d upgraded=%s." % [
			_session_wallet(),
			wallet_before_purchase,
			_session_payout_total(),
			str(_has_oxygen_tank_upgrade()),
		])
		get_tree().quit(1)
		return
	if not is_equal_approx(_oxygen_capacity_seconds(), OXYGEN_MAX_SECONDS + _oxygen_upgrade_seconds()):
		push_error("Pass 18 progression smoke expected upgraded capacity %.1f, got %.1f." % [OXYGEN_MAX_SECONDS + _oxygen_upgrade_seconds(), _oxygen_capacity_seconds()])
		get_tree().quit(1)
		return
	if _status_label == null or _status_label.text.find("O2 tank upgraded") == -1:
		push_error("Pass 18 progression smoke did not show purchase feedback: %s." % _status_text())
		get_tree().quit(1)
		return

	_reset_run()
	if not _has_oxygen_tank_upgrade() or not is_equal_approx(_oxygen_seconds, _oxygen_capacity_seconds()):
		push_error("Pass 18 progression smoke reset did not preserve upgraded tank state: upgraded=%s oxygen=%.1f capacity=%.1f." % [
			str(_has_oxygen_tank_upgrade()),
			_oxygen_seconds,
			_oxygen_capacity_seconds(),
		])
		get_tree().quit(1)
		return

	_oxygen_seconds = OXYGEN_MAX_SECONDS
	_player.global_position = _world.get_extraction_center()
	_process(10.0)
	if _oxygen_seconds <= OXYGEN_MAX_SECONDS or _oxygen_seconds > _oxygen_capacity_seconds():
		push_error("Pass 18 progression smoke extraction refill ignored upgraded cap: oxygen=%.1f capacity=%.1f." % [_oxygen_seconds, _oxygen_capacity_seconds()])
		get_tree().quit(1)
		return

	print("Pass 18 progression smoke passed: targets=%s wallet_before=%d wallet_after=%d payout=%d capacity=%.1f oxygen_after_refill=%.1f insufficient_blocked=true held_failure_no_payout=true." % [
		banked_target_ids,
		wallet_before_purchase,
		_session_wallet(),
		_session_payout_total(),
		_oxygen_capacity_seconds(),
		_oxygen_seconds,
	])
	get_tree().quit()


func _instant_salvage_target() -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			return salvage
	return {}


func _bank_until_upgrade_affordable() -> PackedStringArray:
	var banked_ids := PackedStringArray()
	for salvage in _salvage_centers_for_full_collection():
		if _session_wallet() >= _oxygen_upgrade_cost():
			break
		var salvage_id := str(salvage.get("id", "salvage"))
		_player.global_position = salvage["center"]
		if not _collect_salvage_for_smoke(salvage):
			continue
		if not banked_ids.has(salvage_id):
			banked_ids.append(salvage_id)
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			_player.global_position = _world.get_extraction_center()
			_process(0.0)

	if _held_salvage > 0 and _session_wallet() < _oxygen_upgrade_cost():
		_player.global_position = _world.get_extraction_center()
		_process(0.0)
	return banked_ids


func _oxygen_upgrade_cost() -> int:
	return _main.SessionProgression.OXYGEN_TANK_UPGRADE_COST


func _oxygen_upgrade_seconds() -> float:
	return _main.SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
