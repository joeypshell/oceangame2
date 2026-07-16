extends "res://scripts/main/smoke/smoke_expansion_11_light_return_checks.gd"

const PRESSURE_PROJECT_ID := "pressure_suit_1_project"
const PRESSURE_CAPABILITY_ID := "pressure_suit_1"
const PRESSURE_ZONE_ID := "abyssal_basin_pressure_zone"
const ABYSSAL_TARGET_ID := "abyssal_basin_harmonic_source_survey"
const ABYSSAL_DISCOVERY_ID := "abyssal_basin_harmonic_source_discovery"

var _pressure_budget := {}
var _scout_exposure_seconds := 0.0
var _scout_oxygen_spent := 0.0
var _protected_margin_seconds := 0.0
var _pressure_route_distance_px := 0.0


func _smoke_expansion_12_pressure_return_and_quit() -> void:
	if not await run_to_committed_signal_reef():
		return
	if not await _prove_pre_light_scouting():
		return
	if not await _collect_and_bank_light_recipe():
		return
	if not _build_light_and_begin_next_day():
		return
	if not await _complete_harmonic_return():
		return
	if not _verify_profile_reload():
		return
	if not await _prove_pre_suit_pressure_scout():
		return
	if not await _collect_and_bank_pressure_recipe():
		return
	if not _build_pressure_suit_and_begin_next_day():
		return
	if not await _complete_abyssal_return():
		return
	if not _verify_pressure_profile_reload():
		return

	var target := _survey_by_id(ABYSSAL_TARGET_ID)
	var day: Dictionary = _main._expedition_day_state.report()
	var result_text: String = str(_main._anomaly_survey.result_text()).replace("\n", " | ")
	cleanup_profile_storage()
	print("Expansion 12 abyssal pressure-return smoke passed: prerequisite=%s project=%s recipe=Ti2+Rubber1+Gel1 capability=%s zone=%s warning=retreat grace=%.1fs multiplier=%.1f scout_exposure=%.2fs scout_oxygen=%.2f base_unprotected_fail=%s optional_unprotected_fail=%s unprotected_demand=%.1fs protected_demand=%.1fs protected_margin=%.1fs target=%s survey_seconds=%.1f failure_cleanup=hazard+reset failure_oxygen=%.1f pending_away=true committed_at_boat=true exact_once=true profile_reload=true distance=%.1fpx day=%d result=\"%s\"." % [
		ProfileState.DEEP_HARMONIC_DISCOVERY_ID,
		PRESSURE_PROJECT_ID,
		PRESSURE_CAPABILITY_ID,
		PRESSURE_ZONE_ID,
		float(_pressure_budget.get("grace_seconds", 0.0)),
		float(_pressure_budget.get("multiplier", 0.0)),
		_scout_exposure_seconds,
		_scout_oxygen_spent,
		str(bool(_pressure_budget.get("base_fails", false))).to_lower(),
		str(bool(_pressure_budget.get("optional_fails", false))).to_lower(),
		float(_pressure_budget.get("unprotected_seconds", 0.0)),
		float(_pressure_budget.get("protected_seconds", 0.0)),
		_protected_margin_seconds,
		ABYSSAL_TARGET_ID,
		float(target.get("interaction_seconds", 0.0)),
		_failure_oxygen_delta,
		_pressure_route_distance_px,
		int(day.get("day_number", 0)),
		result_text,
	])
	get_tree().quit(0)


func _prove_pre_suit_pressure_scout() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var target := _survey_by_id(ABYSSAL_TARGET_ID)
	var zone: Dictionary = _world.get_marker_zone(PRESSURE_ZONE_ID)
	if not _require(not target.is_empty() and not zone.is_empty(), "pressure zone or abyssal target is missing"):
		return false
	if not _require(profile.has_completed_discovery(ProfileState.DEEP_HARMONIC_DISCOVERY_ID) and not profile.has_capability(PRESSURE_CAPABILITY_ID), "pre-suit prerequisite state drifted"):
		return false
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	var path: PackedVector2Array = navigation.path_between(_player.global_position, target["center"])
	var zone_rect := _source_rect(zone)
	var scout_point := _first_inside_point(path, zone_rect.grow(-16.0))
	if not _require(not path.is_empty() and scout_point.x >= 0.0, "boat-to-abyss path did not cross the pressure zone"):
		return false
	_pressure_budget = _route_budget(path, zone_rect, zone, target)
	if not _require(bool(_pressure_budget.get("base_fails", false)) and bool(_pressure_budget.get("optional_fails", false)), "base or optional tank bypassed the unprotected journey budget"):
		return false
	if not _require(float(_pressure_budget.get("protected_seconds", 999.0)) < _oxygen_capacity_seconds(), "protected journey exceeded the base tank"):
		return false

	var oxygen_before := _oxygen_seconds
	var health_before := int(_main._player_health.current_health)
	if not await _drive_to("pre_suit_pressure_scout", scout_point, navigation):
		return false
	_advance(0.05)
	var pressure: Dictionary = _main._pressure_zone.report()
	_scout_exposure_seconds = float(pressure.get("exposure_seconds", 0.0))
	_scout_oxygen_spent = oxygen_before - _oxygen_seconds
	if not _require(
		pressure.get("note") == "Abyssal pressure | Retreat"
		and _scout_exposure_seconds > 0.0
		and _scout_exposure_seconds <= float(zone.get("warning_grace_seconds", 0.0))
		and is_equal_approx(float(pressure.get("drain_multiplier", 0.0)), 1.0),
		"pre-suit threshold did not expose its warning/grace state: %s" % str(pressure)
	):
		return false
	if not _require(_scout_oxygen_spent > 0.0 and int(_main._player_health.current_health) == health_before, "pressure scout did not cost oxygen-only travel"):
		return false
	if not await _return_to_boat("pre_suit_pressure_retreat", navigation):
		return false
	var cleared: Dictionary = _main._pressure_zone.report()
	return _require(
		not bool(cleared.get("inside", true))
		and is_zero_approx(float(cleared.get("exposure_seconds", -1.0)))
		and not _run_failed,
		"retreat did not clear pressure exposure at the boat"
	)


func _collect_and_bank_pressure_recipe() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var titanium := _active_materials_by_type(ProfileState.TITANIUM_MATERIAL_ID)
	var rubber := _active_materials_by_type(ProfileState.RUBBER_MATERIAL_ID)
	if not _require(titanium.size() >= 2 and rubber.size() >= 1, "active day did not supply Ti2 + Rubber1"):
		return false
	for candidate in [titanium[0], titanium[1], rubber[0]]:
		if not await _collect_material(candidate):
			return false
		if not await _return_to_boat("pressure_recipe_return_%s" % candidate.get("id", "material"), _navigation_for("", PASSABLE_CAPABILITIES)):
			return false

	var gel := _biological_source_by_id(PASSIVE_GEL_SOURCE_ID)
	if not _require(not gel.is_empty() and not _main._biological_resources.is_collected(PASSIVE_GEL_SOURCE_ID), "replenished gel source was unavailable"):
		return false
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	if not await _drive_to("pressure_recipe_gel", gel["center"], navigation):
		return false
	_advance(float(gel.get("interaction_seconds", 0.0)) + 0.1)
	if not _require(int(_main._material_runtime.held_quantities().get(ProfileState.INSULATING_GEL_MATERIAL_ID, 0)) == 1, "gel did not enter shared cargo"):
		return false
	if not await _return_to_boat("pressure_recipe_gel_return", navigation):
		return false
	return _require(
		profile.material_quantity(ProfileState.TITANIUM_MATERIAL_ID) == 2
		and profile.material_quantity(ProfileState.RUBBER_MATERIAL_ID) == 1
		and profile.material_quantity(ProfileState.INSULATING_GEL_MATERIAL_ID) == 1,
		"banked pressure recipe was not exactly Ti2 + Rubber1 + Gel1"
	)


func _build_pressure_suit_and_begin_next_day() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	if not _require(_main._material_project.status_for(PRESSURE_PROJECT_ID) == "ready", "exact pressure project was not ready"):
		return false
	_press_key(KEY_P)
	if not _require(not profile.has_capability(PRESSURE_CAPABILITY_ID), "daytime P built the pressure suit"):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "boat N did not enter pressure-project debrief"):
		return false
	_press_key(KEY_P)
	if not _require(profile.has_completed_project(PRESSURE_PROJECT_ID) and profile.has_capability(PRESSURE_CAPABILITY_ID), "night project did not atomically unlock pressure protection"):
		return false
	if not _require(profile.material_inventory().is_empty(), "pressure project did not consume its exact recipe"):
		return false
	var completed_count: int = profile.report().get("completed_projects", []).count(PRESSURE_PROJECT_ID)
	_press_key(KEY_P)
	if not _require(profile.report().get("completed_projects", []).count(PRESSURE_PROJECT_ID) == completed_count, "repeat P duplicated the pressure project"):
		return false
	var reloaded := ProfileState.new(PROFILE_PATH, true)
	if not _require(reloaded.load_profile().get("status") == "loaded" and reloaded.has_capability(PRESSURE_CAPABILITY_ID), "night-built pressure suit did not reload before the next day"):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	_refresh_controlled_world()
	return (
		_require(_world.map_id == MAP_ID and _world.is_inside_boat(_player.global_position), "pressure-suit day did not begin at the full-level boat")
		and _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE, "pressure-suit day did not become active")
		and _require(str(_survey_by_id(ABYSSAL_TARGET_ID).get("state", "")) == "available", "pressure-owned abyssal target did not become available")
	)


func _complete_abyssal_return() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var target := _survey_by_id(ABYSSAL_TARGET_ID)
	if not _require(not target.is_empty(), "abyssal survey target disappeared before the protected return"):
		return false
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	if not await _drive_to("abyssal_failure_probe", target["center"], navigation):
		return false
	var survey_seconds := float(target.get("interaction_seconds", 0.0))
	_press_key(KEY_Q)
	_advance(survey_seconds * 0.5)
	var partial := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	if not _require(partial > 0.0 and partial < 1.0 and bool(_main._pressure_zone.report().get("protected", false)), "protected survey did not expose partial progress at normal drain"):
		return false
	var oxygen_before := _oxygen_seconds
	_main._handle_hazard_hit("expansion_12_smoke")
	_failure_oxygen_delta = oxygen_before - _oxygen_seconds
	if not _require(
		is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0)))
		and not _main._anomaly_survey.has_pending_discovery()
		and not profile.has_completed_discovery(ABYSSAL_DISCOVERY_ID)
		and profile.has_capability(PRESSURE_CAPABILITY_ID),
		"hazard cleanup retained abyssal state or removed the suit"
	):
		return false

	_advance(0.5)
	_main._reset_run()
	_refresh_controlled_world()
	if not _require(
		is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0)))
		and not _main._anomaly_survey.has_pending_discovery()
		and not bool(_main._pressure_zone.report().get("inside", true))
		and profile.has_capability(PRESSURE_CAPABILITY_ID),
		"manual reset retained abyssal exposure/progress or removed durable state"
	):
		return false

	navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	var route_start := _distance_px
	_minimum_oxygen = _oxygen_seconds
	if not await _drive_to("abyssal_outbound", target["center"], navigation):
		return false
	_press_key(KEY_Q)
	_advance(survey_seconds + 0.01)
	if not _require(
		_main._anomaly_survey.has_pending_discovery()
		and _main._anomaly_survey.overlay_text(_world, _player) == "Abyssal chart pending | Return to surface boat before another scan"
		and not profile.has_completed_discovery(ABYSSAL_DISCOVERY_ID),
		"abyssal survey did not remain pending away from the boat"
	):
		return false
	if not await _return_to_boat("abyssal_return", navigation):
		return false
	_protected_margin_seconds = _minimum_oxygen
	_pressure_route_distance_px = _distance_px - route_start
	var expected_result := "%s\n%s" % [target.get("finding_label", ""), target.get("next_lead_label", "")]
	if not _require(
		profile.has_completed_discovery(ABYSSAL_DISCOVERY_ID)
		and not _main._anomaly_survey.has_pending_discovery()
		and _main._anomaly_survey.result_text() == expected_result
		and _protected_margin_seconds > 20.0,
		"protected boat return lost payoff or useful oxygen margin"
	):
		return false

	var discovery_count: int = profile.report().get("completed_discoveries", []).count(ABYSSAL_DISCOVERY_ID)
	_main._anomaly_survey.on_map_loaded(_world)
	_player.global_position = target["center"]
	_advance(survey_seconds + 0.01)
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_advance(0.0)
	return _require(
		not _main._anomaly_survey.has_pending_discovery()
		and profile.report().get("completed_discoveries", []).count(ABYSSAL_DISCOVERY_ID) == discovery_count
		and _main._expedition_day_state.committed_discovery_ids.count(ABYSSAL_DISCOVERY_ID) == 1,
		"repeat abyssal survey or return duplicated the discovery"
	)


func _verify_pressure_profile_reload() -> bool:
	var reloaded := ProfileState.new(PROFILE_PATH, true)
	var load: Dictionary = reloaded.load_profile()
	return _require(
		load.get("status") == "loaded"
		and reloaded.has_completed_discovery(ProfileState.DEEP_HARMONIC_DISCOVERY_ID)
		and reloaded.has_completed_project(PRESSURE_PROJECT_ID)
		and reloaded.has_capability(PRESSURE_CAPABILITY_ID)
		and reloaded.has_completed_discovery(ABYSSAL_DISCOVERY_ID),
		"profile reload lost pressure prerequisite, project, capability, or payoff"
	)


func _active_materials_by_type(material_id: String) -> Array:
	var active_ids: Array = _world.get_material_candidate_report().get("active_ids", [])
	var values := []
	for candidate in _world.get_material_candidates():
		if active_ids.has(str(candidate.get("id", ""))) and str(candidate.get("material_id", "")) == material_id:
			values.append(candidate)
	values.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	return values


func _route_budget(path: PackedVector2Array, zone_rect: Rect2, zone: Dictionary, target: Dictionary) -> Dictionary:
	var one_way_distance := 0.0
	var one_way_pressure_distance := 0.0
	for index in range(1, path.size()):
		var segment_distance := path[index - 1].distance_to(path[index])
		one_way_distance += segment_distance
		if zone_rect.has_point(path[index - 1].lerp(path[index], 0.5)):
			one_way_pressure_distance += segment_distance
	var swim_speed := maxf(1.0, float(_player.swim_speed))
	var survey_seconds := float(target.get("interaction_seconds", 0.0))
	var protected_seconds := one_way_distance * 2.0 / swim_speed + survey_seconds
	var pressure_seconds := one_way_pressure_distance * 2.0 / swim_speed + survey_seconds
	var normal_seconds := maxf(0.0, protected_seconds - pressure_seconds)
	var grace_seconds := float(zone.get("warning_grace_seconds", 0.0))
	var multiplier := float(zone.get("unprotected_oxygen_drain_multiplier", 1.0))
	var unprotected_seconds := normal_seconds + minf(grace_seconds, pressure_seconds) + maxf(0.0, pressure_seconds - grace_seconds) * multiplier
	return {
		"protected_seconds": protected_seconds,
		"unprotected_seconds": unprotected_seconds,
		"grace_seconds": grace_seconds,
		"multiplier": multiplier,
		"base_fails": unprotected_seconds > 90.0,
		"optional_fails": unprotected_seconds > 105.0,
	}


func _source_rect(source: Dictionary) -> Rect2:
	return Rect2(
		Vector2(float(source.get("x", 0)), float(source.get("y", 0))) * _world.tile_size,
		Vector2(float(source.get("w", 0)), float(source.get("h", 0))) * _world.tile_size
	)


func _first_inside_point(path: PackedVector2Array, rect: Rect2) -> Vector2:
	for point in path:
		if rect.has_point(point):
			return point
	return Vector2(-1.0, -1.0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	cleanup_profile_storage()
	push_error("Expansion 12 pressure-return smoke failed: %s." % message)
	get_tree().quit(1)
	return false
