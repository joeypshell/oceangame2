extends "res://scripts/main/smoke/smoke_check_base.gd"

const ZONE_ID := "deep_cache_dark_pocket"
const EXPECTED_LEVEL := "dark"
const STEP_SECONDS := 0.25


func _smoke_darkness_light_gate_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Darkness/light smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return
	if not _world.has_method("get_visibility_zones") or not _world.has_method("get_visibility_zone_at"):
		push_error("Darkness/light smoke requires visibility zone runtime queries.")
		get_tree().quit(1)
		return

	var zone := _visibility_zone_by_id(ZONE_ID)
	if zone.is_empty():
		push_error("Darkness/light smoke did not find %s." % ZONE_ID)
		get_tree().quit(1)
		return

	var upgrade_id := str(zone.get("required_upgrade_id", ""))
	var before_alpha := float(zone.get("overlay_alpha", 0.0))
	if _has_light_upgrade() or bool(zone.get("readability_upgraded", false)):
		push_error("Darkness/light smoke expected fresh base-light state: upgraded=%s zone=%s." % [
			str(_has_light_upgrade()),
			zone,
		])
		get_tree().quit(1)
		return
	if str(zone.get("visibility_level", "")) != EXPECTED_LEVEL or upgrade_id != _main.SessionProgression.LIGHT_UPGRADE_ID:
		push_error("Darkness/light smoke unexpected zone metadata: %s." % zone)
		get_tree().quit(1)
		return
	if before_alpha <= 0.0:
		push_error("Darkness/light smoke expected positive base overlay alpha, got %.3f." % before_alpha)
		get_tree().quit(1)
		return

	if not _enter_zone_or_fail(zone, "before-upgrade"):
		return
	var oxygen_before := _oxygen_seconds
	var held_before := _held_salvage
	var banked_before := _banked_salvage
	var position_before: Vector2 = _player.global_position
	_process(STEP_SECONDS)
	if _player.global_position.distance_to(position_before) > 0.5:
		push_error("Darkness/light smoke zone changed player position before upgrade.")
		get_tree().quit(1)
		return
	if _oxygen_seconds >= oxygen_before or _held_salvage != held_before or _banked_salvage != banked_before:
		push_error("Darkness/light smoke changed semantics before upgrade: oxygen %.1f->%.1f held %d->%d banked %d->%d." % [
			oxygen_before,
			_oxygen_seconds,
			held_before,
			_held_salvage,
			banked_before,
			_banked_salvage,
		])
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_main._session_progression.record_banked_salvage(_main.SessionProgression.LIGHT_UPGRADE_COST)
	if not _try_purchase_light_upgrade() or not _has_light_upgrade():
		push_error("Darkness/light smoke could not purchase light upgrade: wallet=%d status=%s." % [
			_session_wallet(),
			_status_text(),
		])
		get_tree().quit(1)
		return

	var upgraded_zone := _visibility_zone_by_id(ZONE_ID)
	var after_alpha := float(upgraded_zone.get("overlay_alpha", 0.0))
	if not bool(upgraded_zone.get("readability_upgraded", false)) or after_alpha >= before_alpha:
		push_error("Darkness/light smoke expected lower upgraded overlay alpha: before=%.3f after=%.3f zone=%s." % [
			before_alpha,
			after_alpha,
			upgraded_zone,
		])
		get_tree().quit(1)
		return

	if not _enter_zone_or_fail(upgraded_zone, "after-upgrade"):
		return
	oxygen_before = _oxygen_seconds
	held_before = _held_salvage
	banked_before = _banked_salvage
	position_before = _player.global_position
	_process(STEP_SECONDS)
	if _player.global_position.distance_to(position_before) > 0.5:
		push_error("Darkness/light smoke zone changed player position after upgrade.")
		get_tree().quit(1)
		return
	if _oxygen_seconds >= oxygen_before or _held_salvage != held_before or _banked_salvage != banked_before:
		push_error("Darkness/light smoke changed semantics after upgrade: oxygen %.1f->%.1f held %d->%d banked %d->%d." % [
			oxygen_before,
			_oxygen_seconds,
			held_before,
			_held_salvage,
			banked_before,
			_banked_salvage,
		])
		get_tree().quit(1)
		return

	print("Darkness/light smoke passed: zone=%s level=%s upgrade=%s alpha_before=%.3f alpha_after=%.3f position=%s oxygen_after=%.1f held=%d banked=%d." % [
		ZONE_ID,
		str(zone.get("visibility_level", "")),
		upgrade_id,
		before_alpha,
		after_alpha,
		str(_player.global_position),
		_oxygen_seconds,
		_held_salvage,
		_banked_salvage,
	])
	get_tree().quit()


func _enter_zone_or_fail(zone: Dictionary, phase: String) -> bool:
	var zone_center: Vector2 = zone["center"]
	_player.global_position = zone_center
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	_process(0.0)
	var current_zone: Dictionary = _world.get_visibility_zone_at(_player.global_position)
	if str(current_zone.get("id", "")) != ZONE_ID:
		push_error("Darkness/light smoke could not enter %s during %s: current=%s." % [ZONE_ID, phase, current_zone])
		get_tree().quit(1)
		return false
	return true


func _visibility_zone_by_id(zone_id: String) -> Dictionary:
	for zone in _world.get_visibility_zones():
		if str(zone.get("id", "")) == zone_id:
			return zone
	return {}


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
