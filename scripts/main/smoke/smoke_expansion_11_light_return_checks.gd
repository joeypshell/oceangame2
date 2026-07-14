extends "res://scripts/main/smoke/smoke_expansion_10_regional_journey_checks.gd"

const ProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const PROFILE_PATH := "user://oceangame2_expansion_11_journey_smoke.json"
const LIGHT_PROJECT_ID := "dive_light_1_project"
const LIGHT_CAPABILITY_ID := "dive_light_1"
const HARMONIC_TARGET_ID := "signal_reef_deep_harmonic_survey"
const HARMONIC_ZONE_ID := "signal_reef_deep_harmonic_dark_zone"
const HARMONIC_DISCOVERY_ID := "signal_reef_deep_harmonic_discovery"
const PASSIVE_GEL_SOURCE_ID := "upper_right_glow_anemone_sample"
const CAPACITY_PROBE_SALVAGE_ID := "salvage_right_branch"

var _pre_light_alpha := 0.0
var _upgraded_alpha := 0.0
var _harmonic_distance_px := 0.0
var _cargo_full_blocked := false
var _failure_oxygen_delta := 0.0


static func create_clean_profile():
	cleanup_profile_storage()
	return ProfileState.new(PROFILE_PATH, true)


static func cleanup_profile_storage() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _smoke_expansion_11_light_return_and_quit() -> void:
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

	var profile = _main._anomaly_survey.profile_state()
	var day: Dictionary = _main._expedition_day_state.report()
	var target := _survey_by_id(HARMONIC_TARGET_ID)
	var result_text: String = str(_main._anomaly_survey.result_text()).replace("\n", " | ")
	cleanup_profile_storage()
	print("Expansion 11 deep-harmonic light-return smoke passed: project=%s capability=%s prerequisite=%s recipe=Ti1+Coil1+Gel1 cargo_capacity=%d cargo_full_blocked=%s night_project=true exact_once=true map=%s target=%s survey_seconds=%.1f discovery=%s pre_light_blocked=true alpha=%.4f->%.4f failure_cleanup=hazard oxygen_penalty=%.1f pending_away=true committed_at_boat=true duplicate_prevented=true profile_reload=true route_distance=%.1fpx total_distance=%.1fpx elapsed=%.1fs oxygen=%.1f/%.1f daylight=%.1fs health=%d day=%d sorties=%d connectors=%d prompts=%d result=\"%s\"." % [
		LIGHT_PROJECT_ID,
		LIGHT_CAPABILITY_ID,
		DISCOVERY_ID,
		_held_salvage_capacity(),
		str(_cargo_full_blocked).to_lower(),
		_world.map_id,
		HARMONIC_TARGET_ID,
		float(target.get("interaction_seconds", 0.0)),
		HARMONIC_DISCOVERY_ID,
		_pre_light_alpha,
		_upgraded_alpha,
		_failure_oxygen_delta,
		_harmonic_distance_px,
		_distance_px,
		_simulation_seconds,
		_minimum_oxygen,
		_oxygen_seconds,
		float(day.get("daylight_remaining_seconds", 0.0)),
		int(_main._player_health.current_health),
		int(day.get("day_number", 0)),
		int(day.get("sortie_count", 0)),
		int(day.get("connector_transition_count", -1)),
		_connector_prompt_count,
		result_text,
	])
	get_tree().quit(0)


func _prove_pre_light_scouting() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var target := _survey_by_id(HARMONIC_TARGET_ID)
	var zone := _visibility_zone_by_id(HARMONIC_ZONE_ID)
	if not _require(not target.is_empty() and not zone.is_empty(), "harmonic target or dark zone is missing"):
		return false
	if not _require(profile.has_completed_discovery(DISCOVERY_ID) and not profile.has_capability(LIGHT_CAPABILITY_ID), "pre-light prerequisite state drifted"):
		return false
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	var oxygen_before := _oxygen_seconds
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	if not await _drive_to("pre_light_harmonic", target["center"], navigation):
		return false
	_pre_light_alpha = float(_visibility_zone_by_id(HARMONIC_ZONE_ID).get("overlay_alpha", 0.0))
	_advance(0.5)
	var interaction: Dictionary = _main._anomaly_survey.report().get("interaction", {})
	if not _require(
		str(_last_status_note) == str(target.get("clue_label", ""))
		and is_zero_approx(float(interaction.get("progress", -1.0)))
		and not _main._anomaly_survey.has_pending_discovery()
		and not profile.has_completed_discovery(HARMONIC_DISCOVERY_ID),
		"pre-light target advanced or lost its source clue"
	):
		return false
	if not _require(_oxygen_seconds < oxygen_before and _main._expedition_day_state.daylight_remaining_seconds < daylight_before, "pre-light scouting paused expedition pressure"):
		return false
	return await _return_to_boat("pre_light_return", navigation)


func _collect_and_bank_light_recipe() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var titanium := _active_material_by_type(ProfileState.TITANIUM_MATERIAL_ID)
	var gel := _biological_source_by_id(PASSIVE_GEL_SOURCE_ID)
	if not _require(not titanium.is_empty() and not gel.is_empty(), "post-scanner titanium or gel source is missing"):
		return false
	if not await _collect_material(titanium):
		return false
	var gel_navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	if not await _drive_to("gel_outbound", gel["center"], gel_navigation):
		return false
	_advance(float(gel.get("interaction_seconds", 0.0)) + 0.1)
	if not _require(_main._biological_resources.is_collected(PASSIVE_GEL_SOURCE_ID) and int(_main._material_runtime.held_quantities().get(ProfileState.INSULATING_GEL_MATERIAL_ID, 0)) == 1, "gel sample did not enter shared cargo"):
		return false
	if not _require(_main._held_cargo_count() == _held_salvage_capacity() and _held_salvage_capacity() == 2, "Ti1 + Gel1 did not fill base cargo capacity"):
		return false

	var probe := _salvage_by_id(CAPACITY_PROBE_SALVAGE_ID)
	if not _require(not probe.is_empty(), "cargo-capacity salvage probe is missing"):
		return false
	var probe_navigation = _navigation_for("", PASSABLE_CAPABILITIES, CAPACITY_PROBE_SALVAGE_ID)
	if not await _drive_to("light_recipe_capacity_probe", probe["center"], probe_navigation):
		return false
	_advance(0.0)
	_cargo_full_blocked = (
		not _world.is_salvage_collected(CAPACITY_PROBE_SALVAGE_ID)
		and _main._material_runtime.held_count() == 2
		and _last_status_note.find("Cargo full") != -1
	)
	if not _require(_cargo_full_blocked, "full cargo deleted or collected the salvage probe"):
		return false
	if not await _return_to_boat("light_partial_recipe_return", probe_navigation):
		return false
	if not _require(profile.material_quantity(ProfileState.TITANIUM_MATERIAL_ID) == 1 and profile.material_quantity(ProfileState.INSULATING_GEL_MATERIAL_ID) == 1 and profile.material_quantity(ProfileState.COIL_MATERIAL_ID) == 0, "boat did not bank the exact Ti1 + Gel1 partial recipe"):
		return false

	if not _begin_next_day_without_light():
		return false
	var coil := _active_material_by_type(ProfileState.COIL_MATERIAL_ID)
	if not _require(str(coil.get("id", "")) == "material_coil_scanner_floor", "day-four guaranteed scanner-floor coil source was not active"):
		return false
	if not await _collect_material(coil):
		return false
	var coil_navigation = _navigation_for(str(coil.get("id", "")), PASSABLE_CAPABILITIES)
	if not await _return_to_boat("light_coil_return", coil_navigation):
		return false
	return _require(
		profile.material_quantity(ProfileState.TITANIUM_MATERIAL_ID) == 1
		and profile.material_quantity(ProfileState.COIL_MATERIAL_ID) == 1
		and profile.material_quantity(ProfileState.INSULATING_GEL_MATERIAL_ID) == 1,
		"banked light recipe was not exactly Ti1 + Coil1 + Gel1"
	)


func _begin_next_day_without_light() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	_press_key(KEY_N)
	_advance(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "partial-recipe day did not reach debrief"):
		return false
	_press_key(KEY_P)
	if not _require(not profile.has_capability(LIGHT_CAPABILITY_ID) and profile.material_quantity(ProfileState.COIL_MATERIAL_ID) == 0, "incomplete night project built without its coil"):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	_refresh_controlled_world()
	return _require(_main._expedition_day_state.day_number == 4 and _world.map_id == MAP_ID and _world.is_inside_boat(_player.global_position), "day four did not resume at the full-level boat")


func _collect_material(candidate: Dictionary) -> bool:
	var material_id := str(candidate.get("material_id", ""))
	var before: int = int(_main._material_runtime.held_quantities().get(material_id, 0))
	var navigation = _navigation_for(str(candidate.get("id", "")), PASSABLE_CAPABILITIES)
	if not await _drive_to("light_recipe_%s" % candidate.get("id", "material"), candidate["center"], navigation):
		return false
	_advance(0.0)
	return _require(int(_main._material_runtime.held_quantities().get(material_id, 0)) == before + 1, "%s did not enter held cargo" % candidate.get("id", "material"))


func _build_light_and_begin_next_day() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var project: Dictionary = _main._material_project.project_definition_for(LIGHT_PROJECT_ID)
	if not _require(not project.is_empty() and _main._material_project.status_for(LIGHT_PROJECT_ID) == "ready", "exact light project was not ready"):
		return false
	_press_key(KEY_P)
	if not _require(not profile.has_capability(LIGHT_CAPABILITY_ID), "daytime P built the light"):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "boat N did not enter real night debrief"):
		return false
	_press_key(KEY_P)
	if not _require(profile.has_completed_project(LIGHT_PROJECT_ID) and profile.has_capability(LIGHT_CAPABILITY_ID), "night project did not atomically unlock durable light"):
		return false
	if not _require(profile.material_quantity(ProfileState.TITANIUM_MATERIAL_ID) == 0 and profile.material_quantity(ProfileState.COIL_MATERIAL_ID) == 0 and profile.material_quantity(ProfileState.INSULATING_GEL_MATERIAL_ID) == 0, "light project did not consume the exact recipe"):
		return false
	var completed_count: int = profile.report().get("completed_projects", []).count(LIGHT_PROJECT_ID)
	_press_key(KEY_P)
	if not _require(profile.report().get("completed_projects", []).count(LIGHT_PROJECT_ID) == completed_count and profile.material_inventory().is_empty(), "repeat P duplicated the project transaction"):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	_refresh_controlled_world()
	_upgraded_alpha = float(_visibility_zone_by_id(HARMONIC_ZONE_ID).get("overlay_alpha", 0.0))
	return (
		_require(_world.map_id == MAP_ID and _world.is_inside_boat(_player.global_position), "next day left the full-level boat")
		and _require(_main._expedition_day_state.day_number == 5 and _main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE, "light day did not begin as active day five")
		and _require(_main._progression_runtime.has_light_upgrade() and _upgraded_alpha > 0.0 and _upgraded_alpha < _pre_light_alpha, "next-day world did not apply durable light readability")
		and _require(str(_survey_by_id(HARMONIC_TARGET_ID).get("state", "")) == "available", "next-day harmonic target did not become available")
	)


func _refresh_controlled_world() -> void:
	_prepare_controlled_movement()
	_body_size = ((_player.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size
	_starting_health = int(_main._player_health.current_health)
	_minimum_oxygen = minf(_minimum_oxygen, _oxygen_seconds)


func _complete_harmonic_return() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var target := _survey_by_id(HARMONIC_TARGET_ID)
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	var route_start := _distance_px
	if not await _drive_to("harmonic_failure_probe", target["center"], navigation):
		return false
	var seconds := float(target.get("interaction_seconds", 0.0))
	_advance(seconds * 0.5)
	var partial := float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	if not _require(partial > 0.0 and partial < 1.0, "light-owned survey did not expose partial progress"):
		return false
	var oxygen_before := _oxygen_seconds
	_main._handle_hazard_hit("expansion_11_smoke")
	_minimum_oxygen = minf(_minimum_oxygen, _oxygen_seconds)
	_failure_oxygen_delta = oxygen_before - _oxygen_seconds
	if not _require(is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0))) and not _main._anomaly_survey.has_pending_discovery() and not profile.has_completed_discovery(HARMONIC_DISCOVERY_ID), "hazard retained or committed harmonic state"):
		return false

	navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	if not await _drive_to("harmonic_outbound", target["center"], navigation):
		return false
	_advance(seconds + 0.01)
	if not _require(_main._anomaly_survey.has_pending_discovery() and not _world.is_inside_boat(_player.global_position) and not profile.has_completed_discovery(HARMONIC_DISCOVERY_ID), "harmonic completion did not remain pending away from boat"):
		return false
	if not await _return_to_boat("harmonic_return", navigation):
		return false
	var expected_result := "%s\n%s" % [target.get("finding_label", ""), target.get("next_lead_label", "")]
	if not _require(profile.has_completed_discovery(HARMONIC_DISCOVERY_ID) and not _main._anomaly_survey.has_pending_discovery() and _main._anomaly_survey.result_text() == expected_result, "canonical boat did not commit the source-authored harmonic payoff"):
		return false
	_harmonic_distance_px = _distance_px - route_start

	var discovery_count: int = profile.report().get("completed_discoveries", []).count(HARMONIC_DISCOVERY_ID)
	_main._anomaly_survey.on_map_loaded(_world)
	_player.global_position = target["center"]
	_advance(seconds + 0.01)
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_advance(0.0)
	return _require(
		not _main._anomaly_survey.has_pending_discovery()
		and profile.report().get("completed_discoveries", []).count(HARMONIC_DISCOVERY_ID) == discovery_count
		and _main._expedition_day_state.committed_discovery_ids.count(HARMONIC_DISCOVERY_ID) == 1,
		"repeat survey or return duplicated the committed discovery"
	)


func _verify_profile_reload() -> bool:
	var reloaded := ProfileState.new(PROFILE_PATH, true)
	var load: Dictionary = reloaded.load_profile()
	return _require(
		load.get("status") == "loaded"
		and reloaded.has_capability(ProfileState.PROPULSION_FINS_CAPABILITY_ID)
		and reloaded.has_capability(ProfileState.SURVEY_SCANNER_CAPABILITY_ID)
		and reloaded.has_capability(LIGHT_CAPABILITY_ID)
		and reloaded.has_completed_discovery(DISCOVERY_ID)
		and reloaded.has_completed_discovery(HARMONIC_DISCOVERY_ID)
		and reloaded.has_completed_project(LIGHT_PROJECT_ID),
		"profile reload lost the prerequisite, light, or harmonic payoff"
	)


func _active_material_by_type(material_id: String) -> Dictionary:
	var active_ids: Array = _world.get_material_candidate_report().get("active_ids", [])
	for candidate in _world.get_material_candidates():
		if active_ids.has(str(candidate.get("id", ""))) and str(candidate.get("material_id", "")) == material_id:
			return candidate
	return {}


func _biological_source_by_id(source_id: String) -> Dictionary:
	for source in _world.get_biological_resource_sources():
		if str(source.get("id", "")) == source_id:
			return source
	return {}


func _visibility_zone_by_id(zone_id: String) -> Dictionary:
	for zone in _world.get_visibility_zones():
		if str(zone.get("id", "")) == zone_id:
			return zone
	return {}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	cleanup_profile_storage()
	push_error("Expansion 11 light-return smoke failed: %s." % message)
	get_tree().quit(1)
	return false
