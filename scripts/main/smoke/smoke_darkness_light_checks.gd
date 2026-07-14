extends "res://scripts/main/smoke/smoke_check_base.gd"

const ZONE_ID := "deep_cache_dark_pocket"
const EXPECTED_LEVEL := "dark"
const STEP_SECONDS := 0.25
const LIGHT_ID := "dive_light_1"
const LIGHT_PROJECT_ID := "dive_light_1_project"
const BASE_RANGE_SCALE := 1.0
const BASE_ALPHA := 0.38
const UPGRADED_RANGE_SCALE := 1.25
const UPGRADED_ALPHA := 0.48


func _smoke_pass_20_durable_light_and_quit() -> void:
	if _world.map_id != "production_slice_01" or not _player.has_method("get_facing_report"):
		push_error("Pass 20 compatibility smoke requires production_slice_01 player light reporting.")
		get_tree().quit(1)
		return
	var base_report: Dictionary = _player.get_facing_report()
	if _session_wallet() != 0 or _session_payout_total() != 0 or _has_light_upgrade():
		push_error("Pass 20 compatibility smoke expected a fresh wallet and durable profile.")
		get_tree().quit(1)
		return
	if not _light_report_matches(base_report, BASE_RANGE_SCALE, BASE_ALPHA):
		push_error("Pass 20 compatibility smoke expected base light, got %s." % base_report)
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	var blocked: Dictionary = _main._progression_runtime.try_purchase(LIGHT_ID, _world, _player)
	if bool(blocked.get("purchased", false)) or str(blocked.get("note", "")) != "Build dive light at night" or _session_wallet() != 0:
		push_error("Pass 20 compatibility smoke found an active score purchase path: %s." % blocked)
		get_tree().quit(1)
		return
	if not _prepare_durable_light():
		get_tree().quit(1)
		return
	var upgraded_report: Dictionary = _player.get_facing_report()
	var profile = _main._anomaly_survey.profile_state()
	if (
		not profile.has_completed_project(LIGHT_PROJECT_ID)
		or not _has_light_upgrade()
		or _session_wallet() != 0
		or _has_oxygen_tank_upgrade()
		or _has_cargo_capacity_upgrade()
		or not _light_report_matches(upgraded_report, UPGRADED_RANGE_SCALE, UPGRADED_ALPHA)
	):
		push_error("Pass 20 compatibility smoke durable state mismatch: profile=%s report=%s." % [profile.report(), upgraded_report])
		get_tree().quit(1)
		return

	_reset_run()
	_main._progression_runtime.apply_light_profile(_world, _player)
	var reset_report: Dictionary = _player.get_facing_report()
	if not _has_light_upgrade() or not _light_report_matches(reset_report, UPGRADED_RANGE_SCALE, UPGRADED_ALPHA):
		push_error("Pass 20 compatibility smoke reset lost durable light: %s." % reset_report)
		get_tree().quit(1)
		return
	print("Pass 20 light compatibility smoke passed: id=%s owner=profile_project wallet_cost=none recipe=Ti1+Coil1+Gel1 base_range=%.2f base_alpha=%.2f upgraded_range=%.2f upgraded_alpha=%.2f reset_persisted=true independent_upgrades=true." % [
		LIGHT_ID,
		float(base_report.get("light_cone_range_scale", 0.0)),
		float(base_report.get("light_cone_alpha", 0.0)),
		float(upgraded_report.get("light_cone_range_scale", 0.0)),
		float(upgraded_report.get("light_cone_alpha", 0.0)),
	])
	get_tree().quit()


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
	if str(zone.get("visibility_level", "")) != EXPECTED_LEVEL or upgrade_id != LIGHT_ID:
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

	if not _prepare_durable_light() or not _has_light_upgrade():
		push_error("Darkness/light smoke could not prepare durable light profile: status=%s." % _status_text())
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


func _light_report_matches(report: Dictionary, range_scale: float, alpha: float) -> bool:
	return (
		is_equal_approx(float(report.get("root_scale_x", 0.0)), 1.0)
		and is_equal_approx(float(report.get("light_cone_range_scale", 0.0)), range_scale)
		and is_equal_approx(float(report.get("light_cone_alpha", 0.0)), alpha)
	)
