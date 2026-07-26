extends "res://scripts/main/smoke/smoke_expansion_13_southeast_wreck_return_checks.gd"

const Expansion14CompatibilityChecks := preload("res://scripts/main/smoke/smoke_expansion_14_compatibility_checks.gd")

const ROUTE_ID_14 := "upper_left_wreck_relay_route"
const CURRENT_GATE_ID_14 := "upper_left_wreck_relay_current"
const CORE_ID_14 := "upper_left_wreck_relay_core"
const SURVEY_ID_14 := "upper_left_wreck_relay_survey"
const DISCOVERY_ID_14 := "upper_left_wreck_relay_discovery"
const CAPACITY_PREFIX_14 := "expansion_14_capacity_"
const HELD_TITANIUM_ID_14 := "expansion_14_held_titanium"
const HELD_COIL_ID_14 := "expansion_14_held_coil"

var _blocked_push_px := 0.0
var _outbound_gate_passive := false
var _return_gate_passive := false
var _survey_partial_14 := 0.0
var _failure_oxygen := 0.0
var _full_cargo_report := {}
var _boat_result := ""


func _smoke_expansion_14_archive_current_return_and_quit() -> void:
	if not _prepare_archive_project_fixture():
		return
	if not _prove_pre_project_gate_and_held_denial():
		return
	if not _build_stabilizer_and_reload():
		return
	if not _prove_passive_two_way_traversal():
		return
	if not _prove_capacity_scanner_and_failure_cleanup():
		return
	if not _complete_relay_return():
		return
	var compatibility: Dictionary = await Expansion14CompatibilityChecks.new().run(get_tree())
	if not _require(bool(compatibility.get("ok", false)), "legacy compatibility failed: %s" % str(compatibility.get("failures", []))):
		return

	var profile = _main._anomaly_survey.profile_state()
	var profile_report: Dictionary = profile.report()
	var cargo_used := int(_full_cargo_report.get("used", -1))
	var cargo_capacity := int(_full_cargo_report.get("capacity", -1))
	var cargo_available := int(_full_cargo_report.get("available", -1))
	cleanup_profile_storage()
	print("Expansion 14 archive-current return smoke passed: route=%s archive=%s archive_committed=true project=%s recipe=Ti2+Coil1 held_recipe_denied=true night_only=true project_count=%d capability=%s capability_count=%d profile_reload=true gate=%s pre_blocked=true push=%.1fpx passive_owned=true outbound_passive=%s return_passive=%s core=%s cargo=%d/%d_free%d full_block=true failure_restore=true banked=true survey=%s explicit_q=true partial=%.2f cancel_on_leave=true full_cargo_scan=true pending=true failure_clear=true discovery=%s discovery_count=%d exact_once=true oxygen=%.1f boat_result=\"%s\" legacy_profile=true source_owners=%d+%d." % [
		ROUTE_ID_14,
		ProfileState.SOUTHEAST_WRECK_DISCOVERY_ID,
		ProfileState.CURRENT_STABILIZER_PROJECT_ID,
		profile_report.get("completed_projects", []).count(ProfileState.CURRENT_STABILIZER_PROJECT_ID),
		ProfileState.CURRENT_STABILIZER_CAPABILITY_ID,
		profile_report.get("unlocked_capabilities", []).count(ProfileState.CURRENT_STABILIZER_CAPABILITY_ID),
		CURRENT_GATE_ID_14,
		_blocked_push_px,
		str(_outbound_gate_passive).to_lower(),
		str(_return_gate_passive).to_lower(),
		CORE_ID_14,
		cargo_used,
		cargo_capacity,
		cargo_available,
		SURVEY_ID_14,
		_survey_partial_14,
		DISCOVERY_ID_14,
		profile_report.get("completed_discoveries", []).count(DISCOVERY_ID_14),
		_oxygen_seconds,
		_boat_result.replace("\n", " | "),
		int(compatibility.get("legacy_project_count", 0)),
		int(compatibility.get("canonical_project_count", 0)),
	])
	get_tree().quit(0)


func _prepare_archive_project_fixture() -> bool:
	if not _prepare_prerequisite_fixture():
		return false
	var profile = _main._anomaly_survey.profile_state()
	var project_runtime = _main._material_project
	if not _require(
		not profile.has_completed_discovery(ProfileState.SOUTHEAST_WRECK_DISCOVERY_ID)
		and project_runtime.status_for(ProfileState.CURRENT_STABILIZER_PROJECT_ID) == "knowledge_required"
		and not project_runtime.request_project(ProfileState.CURRENT_STABILIZER_PROJECT_ID),
		"canonical stabilizer was visible before the archive commit"
	):
		return false
	var recorder: Dictionary = profile.bank_tool_target(RECORDER_ID, false)
	var archive: Dictionary = profile.complete_discovery(ProfileState.SOUTHEAST_WRECK_DISCOVERY_ID, true)
	project_runtime.on_map_loaded(_world)
	var requested: bool = project_runtime.request_project(ProfileState.CURRENT_STABILIZER_PROJECT_ID)
	return _require(
		bool(recorder.get("changed", false))
		and bool(archive.get("changed", false))
		and requested
		and project_runtime.status_for(ProfileState.CURRENT_STABILIZER_PROJECT_ID) == "incomplete"
		and str(project_runtime.report().get("project_id", "")) == ProfileState.CURRENT_STABILIZER_PROJECT_ID
		and project_runtime.debrief_lines().has("Access: Northwest wreck relay | Swim through current"),
		"archive commit did not expose the canonical stabilizer project"
	)


func _prove_pre_project_gate_and_held_denial() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var gate := _gate_by_id(CURRENT_GATE_ID_14)
	var core := _salvage_by_id(CORE_ID_14)
	if not _require(not gate.is_empty() and not core.is_empty(), "relay gate or core is missing"):
		return false

	_player.global_position = gate.get("center", Vector2.ZERO)
	var before_x: float = _player.global_position.x
	_main._current_gate.reset()
	var gate_report: Dictionary = _main._current_gate.update(
		_world,
		_player,
		Callable(_main, "_has_upgrade_id"),
		Callable(profile, "has_capability"),
		0.1
	)
	_blocked_push_px = before_x - _player.global_position.x
	if not _require(bool(gate_report.get("blocked", false)) and _blocked_push_px > 0.0, "relay current did not push the unequipped diver toward the central route"):
		return false
	_main._current_gate.reset()
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_player.reset_motion()

	var capacity := _held_salvage_capacity()
	var titanium: Dictionary = _main._material_runtime.collect_biological_source(
		{"id": HELD_TITANIUM_ID_14, "material_id": ProfileState.TITANIUM_MATERIAL_ID, "material_quantity": 1}, MAP_ID, 0, capacity
	)
	var coil: Dictionary = _main._material_runtime.collect_biological_source(
		{"id": HELD_COIL_ID_14, "material_id": ProfileState.COIL_MATERIAL_ID, "material_quantity": 1}, MAP_ID, 0, capacity
	)
	var held_before: Dictionary = _main._material_runtime.held_quantities()
	var denied: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_DEBRIEF)
	if not _require(
		bool(titanium.get("changed", false))
		and bool(coil.get("changed", false))
		and denied.get("reason") == "insufficient_materials"
		and profile.material_inventory().is_empty()
		and _main._material_runtime.held_quantities() == held_before
		and not profile.has_capability(ProfileState.CURRENT_STABILIZER_CAPABILITY_ID),
		"held current-sortie cargo paid or mutated the stabilizer recipe"
	):
		return false
	_main._material_runtime.discard_unbanked("smoke_fixture")
	var recipe := {ProfileState.TITANIUM_MATERIAL_ID: 2, ProfileState.COIL_MATERIAL_ID: 1}
	var deposit: Dictionary = profile.deposit_materials(recipe, true)
	var wrong_phase: Dictionary = _main._material_project.try_build(ExpeditionDayState.PHASE_ACTIVE)
	return _require(
		bool(deposit.get("changed", false))
		and wrong_phase.get("reason") == "wrong_phase"
		and profile.material_quantity(ProfileState.TITANIUM_MATERIAL_ID) == 2
		and profile.material_quantity(ProfileState.COIL_MATERIAL_ID) == 1,
		"active-day build changed the exact banked Ti2/Coil1 recipe"
	)


func _build_stabilizer_and_reload() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	if not _require(_world.is_inside_boat(_player.global_position) and _main._material_project.status_for(ProfileState.CURRENT_STABILIZER_PROJECT_ID) == "ready", "stabilizer recipe was not ready at the boat"):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "N did not enter the real night debrief"):
		return false
	_press_key(KEY_P)
	if not _require(
		profile.has_completed_project(ProfileState.CURRENT_STABILIZER_PROJECT_ID)
		and profile.has_capability(ProfileState.CURRENT_STABILIZER_CAPABILITY_ID)
		and profile.material_inventory().is_empty(),
		"night build did not atomically consume Ti2/Coil1 and grant the stabilizer"
	):
		return false
	var completed_count: int = profile.report().get("completed_projects", []).count(ProfileState.CURRENT_STABILIZER_PROJECT_ID)
	_press_key(KEY_P)
	if not _require(profile.report().get("completed_projects", []).count(ProfileState.CURRENT_STABILIZER_PROJECT_ID) == completed_count, "repeat night build duplicated the stabilizer"):
		return false
	var reloaded := ProfileState.new(PROFILE_PATH, true)
	var load_report: Dictionary = reloaded.load_profile()
	if not _require(
		load_report.get("status") in ["loaded", "migrated_wreck_navigation"]
		and reloaded.has_completed_project(ProfileState.CURRENT_STABILIZER_PROJECT_ID)
		and reloaded.has_capability(ProfileState.CURRENT_STABILIZER_CAPABILITY_ID)
		and reloaded.has_completed_discovery(ProfileState.SOUTHEAST_WRECK_DISCOVERY_ID),
		"profile reload lost archive-led stabilizer state"
	):
		return false
	var plan_report: Dictionary = _main._refresh_expedition_plan()
	if str(plan_report.get("status", "")) == "choice_ready":
		_press_key(KEY_E)
		if not _require(
			_main._expedition_plan_state.has_selection(),
			"night fixture did not pin an expedition plan before day start"
		):
			return false
	_press_key(KEY_N)
	_advance(0.0)
	_refresh_controlled_world()
	return _require(
		_main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE
		and _world.map_id == MAP_ID
		and _world.is_inside_boat(_player.global_position),
		"post-build day did not resume at the canonical boat"
	)


func _prove_passive_two_way_traversal() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var gate := _gate_by_id(CURRENT_GATE_ID_14)
	if not _require(not gate.is_empty(), "relay current disappeared after project completion"):
		return false
	var boat: Vector2 = _world.get_entry_position(BOAT_ENTRY_ID)
	for index in range(2):
		var offset_x := -8.0 if index == 0 else 8.0
		_main._current_gate.reset()
		_player.global_position = gate.get("center", Vector2.ZERO) + Vector2(offset_x, 0.0)
		var before: Vector2 = _player.global_position
		var owned: Dictionary = _main._current_gate.update(
			_world,
			_player,
			Callable(_main, "_has_upgrade_id"),
			Callable(profile, "has_capability"),
			0.25
		)
		if not _require(bool(owned.get("inside", false)) and not bool(owned.get("blocked", true)) and _player.global_position == before, "owned relay current was not passive from both directions"):
			return false
		if index == 0:
			_outbound_gate_passive = true
		else:
			_return_gate_passive = true
	_main._current_gate.reset()
	_player.global_position = boat
	_player.reset_motion()
	_advance(0.0)
	return _require(not _main._anomaly_survey.has_pending_discovery(), "passive gate probe advanced the survey without Q")


func _prove_capacity_scanner_and_failure_cleanup() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var core := _salvage_by_id(CORE_ID_14)
	var survey := _survey_by_id(SURVEY_ID_14)
	if not _require(not core.is_empty() and not survey.is_empty(), "relay payoff source is missing"):
		return false
	_fill_capacity()
	_player.global_position = core.get("center", Vector2.ZERO)
	_advance(0.0)
	if not _require(not _world.is_salvage_collected(CORE_ID_14) and _main._last_status_note.find("Cargo full") != -1, "full cargo deleted or collected the relay core"):
		return false
	_main._sortie_state.clear_held()
	_player.global_position = core.get("center", Vector2.ZERO)
	_advance(0.0)
	if not _require(_world.is_salvage_collected(CORE_ID_14) and _main._sortie_state.held_salvage_ids == [CORE_ID_14], "relay core did not enter ordinary held cargo"):
		return false
	_fill_capacity()
	_main._update_status_label()
	_full_cargo_report = _main._held_cargo_hud.get_test_report()
	if not _require(int(_full_cargo_report.get("used", 0)) == _held_salvage_capacity() and int(_full_cargo_report.get("available", -1)) == 0, "cargo strip did not mirror the full authoritative state"):
		return false
	if not _require(_select_active_tool_for_smoke(ProfileState.SURVEY_SCANNER_CAPABILITY_ID) and _place_for_scan(survey), "relay failure probe could not select or place the scanner"):
		return false
	_advance(0.25)
	if not _require(is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0))), "relay survey advanced without explicit Q"):
		return false
	_press_key(KEY_Q)
	_advance(float(survey.get("interaction_seconds", 0.0)) / 3.0)
	_survey_partial_14 = float(_main._anomaly_survey.report().get("interaction", {}).get("progress", 0.0))
	if not _require(_survey_partial_14 > 0.0 and _survey_partial_14 < 1.0, "full-cargo Q scan did not expose partial progress"):
		return false
	var scan_position: Vector2 = _player.global_position
	_player.swim_in_direction(Vector2(-_player.get_facing_sign(), 0.0), 0.0)
	_player.global_position = scan_position
	_player.reset_motion()
	_advance(0.0)
	if not _require(is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0))), "leaving relay scan range did not cancel progress"):
		return false
	if not _place_for_scan(survey):
		return false
	_press_key(KEY_Q)
	_advance(float(survey.get("interaction_seconds", 0.0)) + 0.1)
	if not _require(_main._anomaly_survey.has_pending_discovery() and not profile.has_completed_discovery(DISCOVERY_ID_14), "relay survey did not remain pending away from the boat"):
		return false
	var oxygen_before := _oxygen_seconds
	_main._handle_hazard_hit("expansion_14_smoke")
	_failure_oxygen = oxygen_before - _oxygen_seconds
	if not _require(
		not _main._anomaly_survey.has_pending_discovery()
		and not profile.has_completed_discovery(DISCOVERY_ID_14)
		and not _world.is_salvage_collected(CORE_ID_14)
		and _main._sortie_state.held_salvage == 0
		and profile.has_capability(ProfileState.CURRENT_STABILIZER_CAPABILITY_ID)
		and _failure_oxygen > 0.0,
		"hazard failure retained relay cargo/finding or removed the durable project"
	):
		return false
	_main._reset_run()
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_player.reset_motion()
	_advance(0.0)
	_refresh_controlled_world()
	return true


func _complete_relay_return() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var core := _salvage_by_id(CORE_ID_14)
	var survey := _survey_by_id(SURVEY_ID_14)
	_player.global_position = core.get("center", Vector2.ZERO)
	_player.reset_motion()
	_advance(0.0)
	if not _require(_main._sortie_state.held_salvage_ids == [CORE_ID_14], "real relay return did not secure the core"):
		return false
	var pose: Dictionary = ScannerSmokePose.new().find_pose(_world, survey)
	if not _require(bool(pose.get("found", false)), "real relay survey has no scan pose"):
		return false
	if not _require(_select_active_tool_for_smoke(ProfileState.SURVEY_SCANNER_CAPABILITY_ID) and _place_for_scan(survey), "real relay return could not use the scanner"):
		return false
	_press_key(KEY_Q)
	_advance(float(survey.get("interaction_seconds", 0.0)) + 0.1)
	if not _require(_main._anomaly_survey.has_pending_discovery(), "real relay survey did not create a pending finding"):
		return false
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_player.reset_motion()
	_advance(0.0)
	_boat_result = _main._anomaly_survey.result_text()
	var expected_result := "%s\n%s" % [survey.get("finding_label", ""), survey.get("next_lead_label", "")]
	if not _require(
		_main._sortie_state.held_salvage == 0
		and _main._banked_salvage_ids.has(CORE_ID_14)
		and profile.has_completed_discovery(DISCOVERY_ID_14)
		and not _main._anomaly_survey.has_pending_discovery()
		and _boat_result == expected_result
		and _oxygen_seconds > 0.0,
		"canonical boat did not bank the core and commit the source-authored relay result"
	):
		return false
	var discovery_count: int = profile.report().get("completed_discoveries", []).count(DISCOVERY_ID_14)
	var project_count: int = profile.report().get("completed_projects", []).count(ProfileState.CURRENT_STABILIZER_PROJECT_ID)
	var capability_count: int = profile.report().get("unlocked_capabilities", []).count(ProfileState.CURRENT_STABILIZER_CAPABILITY_ID)
	_advance(0.0)
	return _require(
		discovery_count == 1
		and project_count == 1
		and capability_count == 1
		and profile.report().get("completed_discoveries", []).count(DISCOVERY_ID_14) == 1
		and _main._expedition_day_state.committed_discovery_ids.count(DISCOVERY_ID_14) == 1,
		"repeat boat update duplicated project, capability, or relay discovery ownership"
	)


func _fill_capacity() -> void:
	var missing: int = _held_salvage_capacity() - _main._held_cargo_count()
	for index in range(maxi(0, missing)):
		_main._sortie_state.collect_salvage("%s%d" % [CAPACITY_PREFIX_14, index], 0)
