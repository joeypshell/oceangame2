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


func _smoke_pass_19_cargo_upgrade_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pass 19 cargo upgrade smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	var base_capacity := HELD_SALVAGE_CAPACITY
	if _session_wallet() != 0 or _session_payout_total() != 0 or _has_cargo_capacity_upgrade() or _held_salvage_capacity() != base_capacity:
		push_error("Pass 19 cargo upgrade smoke expected fresh state, wallet=%d payout=%d upgraded=%s capacity=%d." % [
			_session_wallet(),
			_session_payout_total(),
			str(_has_cargo_capacity_upgrade()),
			_held_salvage_capacity(),
		])
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	if _try_purchase_cargo_capacity_upgrade() or _session_wallet() != 0 or _has_cargo_capacity_upgrade() or _held_salvage_capacity() != base_capacity:
		push_error("Pass 19 cargo upgrade smoke insufficient-funds purchase mutated state: wallet=%d upgraded=%s capacity=%d." % [
			_session_wallet(),
			str(_has_cargo_capacity_upgrade()),
			_held_salvage_capacity(),
		])
		get_tree().quit(1)
		return
	if _status_label == null or _status_label.text.find("Need %d more" % _cargo_upgrade_cost()) == -1:
		push_error("Pass 19 cargo upgrade smoke did not show insufficient-funds feedback: %s." % _status_text())
		get_tree().quit(1)
		return

	var banked_target_ids := _bank_until_cargo_upgrade_affordable()
	if _session_wallet() < _cargo_upgrade_cost() or banked_target_ids.is_empty():
		push_error("Pass 19 cargo upgrade smoke could not bank enough wallet for purchase: wallet=%d targets=%s." % [_session_wallet(), banked_target_ids])
		get_tree().quit(1)
		return

	var wallet_before_purchase := _session_wallet()
	var payout_before_purchase := _session_payout_total()
	_player.global_position = _world.get_extraction_center()
	if not _try_purchase_cargo_capacity_upgrade():
		push_error("Pass 19 cargo upgrade smoke affordable purchase was blocked: wallet=%d status=%s." % [_session_wallet(), _status_text()])
		get_tree().quit(1)
		return
	if (
		not _has_cargo_capacity_upgrade()
		or _session_wallet() != wallet_before_purchase - _cargo_upgrade_cost()
		or _session_payout_total() != payout_before_purchase
		or _held_salvage_capacity() != base_capacity + _cargo_upgrade_bonus()
	):
		push_error("Pass 19 cargo upgrade smoke purchase state mismatch: wallet=%d before=%d payout=%d upgraded=%s capacity=%d." % [
			_session_wallet(),
			wallet_before_purchase,
			_session_payout_total(),
			str(_has_cargo_capacity_upgrade()),
			_held_salvage_capacity(),
		])
		get_tree().quit(1)
		return
	if _status_label == null or _status_label.text.find("Cargo +1 upgraded") == -1:
		push_error("Pass 19 cargo upgrade smoke did not show purchase feedback: %s." % _status_text())
		get_tree().quit(1)
		return
	var wallet_after_purchase := _session_wallet()

	_reset_run()
	if not _has_cargo_capacity_upgrade() or _held_salvage_capacity() != base_capacity + _cargo_upgrade_bonus() or _held_salvage != 0 or _banked_salvage != 0:
		push_error("Pass 19 cargo upgrade smoke reset did not preserve upgraded cargo state cleanly: upgraded=%s capacity=%d held=%d banked=%d." % [
			str(_has_cargo_capacity_upgrade()),
			_held_salvage_capacity(),
			_held_salvage,
			_banked_salvage,
		])
		get_tree().quit(1)
		return

	var cargo_targets := _salvage_centers_for_full_collection()
	if cargo_targets.size() <= _held_salvage_capacity():
		push_error("Pass 19 cargo upgrade smoke requires more salvage than upgraded capacity.")
		get_tree().quit(1)
		return

	var expected_held_score := 0
	for index in range(_held_salvage_capacity()):
		var cargo_target: Dictionary = cargo_targets[index]
		_player.global_position = cargo_target["center"]
		if not _collect_salvage_for_smoke(cargo_target):
			push_error("Pass 19 cargo upgrade smoke could not collect upgraded cargo target %s." % str(cargo_target.get("id", "salvage")))
			get_tree().quit(1)
			return
		expected_held_score += int(cargo_target.get("score", 0))

	if _held_salvage != _held_salvage_capacity() or _held_salvage_score != expected_held_score:
		push_error("Pass 19 cargo upgrade smoke expected held cargo %d score %d, got held=%d score=%d." % [
			_held_salvage_capacity(),
			expected_held_score,
			_held_salvage,
			_held_salvage_score,
		])
		get_tree().quit(1)
		return

	var blocked_target: Dictionary = cargo_targets[_held_salvage_capacity()]
	var blocked_id := str(blocked_target.get("id", "salvage"))
	_player.global_position = blocked_target["center"]
	_process(0.0)
	if _held_salvage != _held_salvage_capacity() or _held_salvage_ids.has(blocked_id):
		push_error("Pass 19 cargo upgrade smoke collected beyond upgraded capacity; held=%d ids=%s blocked=%s." % [_held_salvage, _held_salvage_ids, blocked_id])
		get_tree().quit(1)
		return
	if _world.is_salvage_collected(blocked_id) or not _world.has_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS):
		push_error("Pass 19 cargo upgrade smoke lost blocked salvage %s at upgraded capacity." % blocked_id)
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage != base_capacity + _cargo_upgrade_bonus() or _banked_score != expected_held_score:
		push_error("Pass 19 cargo upgrade smoke banking mismatch: held=%d banked=%d banked_score=%d expected_score=%d." % [
			_held_salvage,
			_banked_salvage,
			_banked_score,
			expected_held_score,
		])
		get_tree().quit(1)
		return

	_reset_run()
	var failure_target: Dictionary = _instant_salvage_target()
	if failure_target.is_empty():
		push_error("Pass 19 cargo upgrade smoke requires an instant salvage target for failure restore.")
		get_tree().quit(1)
		return
	var failure_target_id := str(failure_target.get("id", "salvage"))
	_player.global_position = failure_target["center"]
	_collect_salvage_for_smoke(failure_target)
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed or not _has_cargo_capacity_upgrade() or _held_salvage != 0 or _banked_salvage != 0 or _world.is_salvage_collected(failure_target_id):
		push_error("Pass 19 cargo upgrade smoke failure/reset mismatch: failed=%s upgraded=%s held=%d banked=%d collected=%s." % [
			str(_run_failed),
			str(_has_cargo_capacity_upgrade()),
			_held_salvage,
			_banked_salvage,
			str(_world.is_salvage_collected(failure_target_id)),
		])
		get_tree().quit(1)
		return

	print("Pass 19 cargo upgrade smoke passed: banked_targets=%s wallet_before_purchase=%d wallet_after_purchase=%d wallet_final=%d payout=%d capacity_before=%d capacity_after=%d held_after_upgrade=%d banked_score=%d blocked=%s failure_preserved_upgrade=true." % [
		banked_target_ids,
		wallet_before_purchase,
		wallet_after_purchase,
		_session_wallet(),
		_session_payout_total(),
		base_capacity,
		_held_salvage_capacity(),
		base_capacity + _cargo_upgrade_bonus(),
		expected_held_score,
		blocked_id,
	])
	get_tree().quit()


func _smoke_pass_20_light_upgrade_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pass 20 light upgrade smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return
	if not _player.has_method("get_facing_report"):
		push_error("Pass 20 light upgrade smoke requires player facing report.")
		get_tree().quit(1)
		return

	var base_report: Dictionary = _player.get_facing_report()
	if _session_wallet() != 0 or _session_payout_total() != 0 or _has_light_upgrade():
		push_error("Pass 20 light upgrade smoke expected fresh state, wallet=%d payout=%d upgraded=%s." % [
			_session_wallet(),
			_session_payout_total(),
			str(_has_light_upgrade()),
		])
		get_tree().quit(1)
		return
	if not _light_report_matches(base_report, 1.0, 0.38):
		push_error("Pass 20 light upgrade smoke expected base light, got %s." % base_report)
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	if _try_purchase_light_upgrade() or _session_wallet() != 0 or _has_light_upgrade():
		push_error("Pass 20 light upgrade smoke insufficient-funds purchase mutated state: wallet=%d upgraded=%s." % [
			_session_wallet(),
			str(_has_light_upgrade()),
		])
		get_tree().quit(1)
		return
	if _status_label == null or _status_label.text.find("Need %d more" % _light_upgrade_cost()) == -1:
		push_error("Pass 20 light upgrade smoke did not show insufficient-funds feedback: %s." % _status_text())
		get_tree().quit(1)
		return

	var banked_target_ids := _bank_until_light_upgrade_affordable()
	if _session_wallet() < _light_upgrade_cost() or banked_target_ids.is_empty():
		push_error("Pass 20 light upgrade smoke could not bank enough wallet for purchase: wallet=%d targets=%s." % [_session_wallet(), banked_target_ids])
		get_tree().quit(1)
		return

	var wallet_before_purchase := _session_wallet()
	var payout_before_purchase := _session_payout_total()
	_player.global_position = _world.get_extraction_center()
	if not _try_purchase_light_upgrade():
		push_error("Pass 20 light upgrade smoke affordable purchase was blocked: wallet=%d status=%s." % [_session_wallet(), _status_text()])
		get_tree().quit(1)
		return
	var upgraded_report: Dictionary = _player.get_facing_report()
	if (
		not _has_light_upgrade()
		or _session_wallet() != wallet_before_purchase - _light_upgrade_cost()
		or _session_payout_total() != payout_before_purchase
		or _has_oxygen_tank_upgrade()
		or _has_cargo_capacity_upgrade()
		or not _light_report_matches(upgraded_report, _main.SessionProgression.LIGHT_UPGRADE_RANGE_SCALE, _main.SessionProgression.LIGHT_UPGRADE_ALPHA)
	):
		push_error("Pass 20 light upgrade smoke purchase state mismatch: wallet=%d before=%d payout=%d light=%s oxygen=%s cargo=%s report=%s." % [
			_session_wallet(),
			wallet_before_purchase,
			_session_payout_total(),
			str(_has_light_upgrade()),
			str(_has_oxygen_tank_upgrade()),
			str(_has_cargo_capacity_upgrade()),
			upgraded_report,
		])
		get_tree().quit(1)
		return
	if _status_label == null or _status_label.text.find("Light +range upgraded") == -1:
		push_error("Pass 20 light upgrade smoke did not show purchase feedback: %s." % _status_text())
		get_tree().quit(1)
		return
	var wallet_after_purchase := _session_wallet()

	_reset_run()
	var reset_report: Dictionary = _player.get_facing_report()
	if not _has_light_upgrade() or not _light_report_matches(reset_report, _main.SessionProgression.LIGHT_UPGRADE_RANGE_SCALE, _main.SessionProgression.LIGHT_UPGRADE_ALPHA):
		push_error("Pass 20 light upgrade smoke reset did not preserve upgraded light state: upgraded=%s report=%s." % [
			str(_has_light_upgrade()),
			reset_report,
		])
		get_tree().quit(1)
		return
	if _has_oxygen_tank_upgrade() or _has_cargo_capacity_upgrade():
		push_error("Pass 20 light upgrade smoke changed unrelated upgrades: oxygen=%s cargo=%s." % [
			str(_has_oxygen_tank_upgrade()),
			str(_has_cargo_capacity_upgrade()),
		])
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	if _try_purchase_light_upgrade() or _session_wallet() != wallet_after_purchase:
		push_error("Pass 20 light upgrade smoke repurchase mutated state: wallet=%d expected=%d status=%s." % [
			_session_wallet(),
			wallet_after_purchase,
			_status_text(),
		])
		get_tree().quit(1)
		return
	if _status_label == null or _status_label.text.find("Light +range already upgraded") == -1:
		push_error("Pass 20 light upgrade smoke did not show already-upgraded feedback: %s." % _status_text())
		get_tree().quit(1)
		return

	print("Pass 20 light upgrade smoke passed: id=%s cost=%d targets=%s wallet_before=%d wallet_after=%d payout=%d base_range=%.2f base_alpha=%.2f upgraded_range=%.2f upgraded_alpha=%.2f reset_persisted=true independent_upgrades=true." % [
		_main.SessionProgression.LIGHT_UPGRADE_ID,
		_light_upgrade_cost(),
		banked_target_ids,
		wallet_before_purchase,
		wallet_after_purchase,
		_session_payout_total(),
		float(base_report.get("light_cone_range_scale", 0.0)),
		float(base_report.get("light_cone_alpha", 0.0)),
		float(upgraded_report.get("light_cone_range_scale", 0.0)),
		float(upgraded_report.get("light_cone_alpha", 0.0)),
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


func _bank_until_cargo_upgrade_affordable() -> PackedStringArray:
	var banked_ids := PackedStringArray()
	for salvage in _salvage_centers_for_full_collection():
		if _session_wallet() >= _cargo_upgrade_cost():
			break
		var salvage_id := str(salvage.get("id", "salvage"))
		_player.global_position = salvage["center"]
		if not _collect_salvage_for_smoke(salvage):
			continue
		if not banked_ids.has(salvage_id):
			banked_ids.append(salvage_id)
		if _held_salvage >= _held_salvage_capacity():
			_player.global_position = _world.get_extraction_center()
			_process(0.0)

	if _held_salvage > 0 and _session_wallet() < _cargo_upgrade_cost():
		_player.global_position = _world.get_extraction_center()
		_process(0.0)
	return banked_ids


func _bank_until_light_upgrade_affordable() -> PackedStringArray:
	var banked_ids := PackedStringArray()
	for salvage in _salvage_centers_for_full_collection():
		if _session_wallet() >= _light_upgrade_cost():
			break
		var salvage_id := str(salvage.get("id", "salvage"))
		_player.global_position = salvage["center"]
		if not _collect_salvage_for_smoke(salvage):
			continue
		if not banked_ids.has(salvage_id):
			banked_ids.append(salvage_id)
		if _held_salvage >= _held_salvage_capacity():
			_player.global_position = _world.get_extraction_center()
			_process(0.0)

	if _held_salvage > 0 and _session_wallet() < _light_upgrade_cost():
		_player.global_position = _world.get_extraction_center()
		_process(0.0)
	return banked_ids


func _oxygen_upgrade_cost() -> int:
	return _main.SessionProgression.OXYGEN_TANK_UPGRADE_COST


func _oxygen_upgrade_seconds() -> float:
	return _main.SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS


func _cargo_upgrade_cost() -> int:
	return _main.SessionProgression.CARGO_CAPACITY_UPGRADE_COST


func _cargo_upgrade_bonus() -> int:
	return _main.SessionProgression.CARGO_CAPACITY_UPGRADE_BONUS


func _light_upgrade_cost() -> int:
	return _main.SessionProgression.LIGHT_UPGRADE_COST


func _light_report_matches(report: Dictionary, range_scale: float, alpha: float) -> bool:
	return (
		is_equal_approx(float(report.get("root_scale_x", 0.0)), 1.0)
		and is_equal_approx(float(report.get("light_cone_range_scale", 0.0)), range_scale)
		and is_equal_approx(float(report.get("light_cone_alpha", 0.0)), alpha)
	)


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
