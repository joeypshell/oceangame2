extends "res://scripts/main/smoke/smoke_expansion_10_regional_journey_checks.gd"

const CorrectionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ExpansionProfileMigrations := preload("res://scripts/main/expansion_profile_migrations.gd")
const ScannerPose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")
const ScannerTargetingContract := preload("res://scripts/main/smoke/scanner_targeting_contract.gd")

const PROFILE_PATH := "user://oceangame2_expansion_13_scanner_cutter_smoke.json"
const ARTIFACT_ID := "lower_right_anomaly_survey"
const BLUEPRINT_ID := "salvage_cutter_blueprint"
const CUTTER_PROJECT_ID := "salvage_cutter_project"
const CUTTER_CAPABILITY_ID := "salvage_cutter"
const PAYOFF_ID := "salvage_sealed_wreck_cache"
const OPENING_LEAD := "Maintenance signal | Beyond east current"
const RETURN_LEAD := "Cutter ready | Return beyond east current to sealed wreck"
const REWARD_PENDING := "Wreck navigation data secured | Return to surface boat"
const REWARD_COMMIT := "Navigation data logged: Southeast wreck coordinates"
const NEXT_LEAD := "Wreck coordinates | Signal continues deep southeast"
const REMEMBERED_PLACE_RADIUS_TILES := 9.0

var _cargo_full_scan := false
var _failure_cleanup := false
var _profile_reload := false
var _profile_migration := false
var _artifact_seconds := 0.0
var _payoff_score := 0


static func create_clean_profile():
	cleanup_profile_storage()
	return CorrectionProfileState.new(PROFILE_PATH, true)


static func cleanup_profile_storage() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _smoke_expansion_13_scanner_cutter_correction_and_quit() -> void:
	print("Scanner-cutter correction stage: targeting_contract")
	var targeting: Dictionary = ScannerTargetingContract.new().run()
	if not _require(bool(targeting.get("passed", false)), "scanner targeting contract failed: %s" % str(targeting.get("failures", []))):
		return
	if not _prepare_scanner_foundation():
		return
	print("Scanner-cutter correction stage: artifact_commit")
	if not _complete_artifact_commit():
		return
	print("Scanner-cutter correction stage: cutter_build")
	if not _collect_recipe_and_build_cutter():
		return
	print("Scanner-cutter correction stage: wreck_payoff")
	if not _open_remembered_wreck():
		return
	print("Scanner-cutter correction stage: reload_migration")
	if not _verify_reload_and_migration():
		return

	var profile = _main._anomaly_survey.profile_state()
	var day: Dictionary = _main._expedition_day_state.report()
	cleanup_profile_storage()
	print("Expansion 13 scanner-cutter correction smoke passed: targeting=range%d_angle%d_rank_%s_cancel_%s artifact=%s subject=artifact reward=%s seconds=%.1f held_q=true release_cancel=true proximity_auto=false oxygen_daylight_continue=true cargo_full_scan=%s pending_failure_cleanup=%s commit=canonical_boat_exact_once recipe=Ti2+Coil1 build=night project=%s capability=%s return_lead=remembered_wreck target=%s payoff=%d navigation_data=pending_then_committed next_lead=broad_southeast optional_preemption=false profile_reload=%s migration=%s discoveries=%d projects=%d day=%d sorties=%d oxygen=%.1f." % [
		int(targeting.get("range_tiles", 0)),
		int(targeting.get("half_angle_degrees", 0)),
		str(targeting.get("ranking", "")),
		str(targeting.get("cancellation", "")),
		ARTIFACT_ID,
		BLUEPRINT_ID,
		_artifact_seconds,
		str(_cargo_full_scan).to_lower(),
		str(_failure_cleanup).to_lower(),
		CUTTER_PROJECT_ID,
		CUTTER_CAPABILITY_ID,
		PAYOFF_ID,
		_payoff_score,
		str(_profile_reload).to_lower(),
		str(_profile_migration).to_lower(),
		profile.report().get("completed_discoveries", []).size(),
		profile.report().get("completed_projects", []).size(),
		int(day.get("day_number", 0)),
		int(day.get("sortie_count", 0)),
		_oxygen_seconds,
	])
	get_tree().quit(0)


func _prepare_scanner_foundation() -> bool:
	if not _require(_world.map_id == MAP_ID and _world.get_world_connectors().is_empty(), "correction smoke did not start in the continuous full level"):
		return false
	var collision := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not _require(collision != null and collision.shape is RectangleShape2D and not collision.disabled, "player collision is unavailable"):
		return false
	_body_size = (collision.shape as RectangleShape2D).size
	_starting_health = int(_main._player_health.current_health)
	_minimum_oxygen = _oxygen_seconds
	if not _verify_fresh_profile() or not _require(_world.is_inside_boat(_player.global_position), "journey did not begin at the canonical boat"):
		return false
	if not _prepare_profile_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID):
		return _require(false, "source-valid fixture could not prepare propulsion fins")
	if not _prepare_profile_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID):
		return _require(false, "source-valid fixture could not prepare the survey scanner")
	print("Scanner-cutter correction setup: fixtures_ready")
	_prepare_controlled_movement()
	return _require(
		_main._anomaly_survey.profile_state().has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID)
		and _main._anomaly_survey.has_scanner()
		and not _main._anomaly_survey.profile_state().has_completed_discovery(BLUEPRINT_ID)
		and _world.is_inside_boat(_player.global_position)
		and _main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE,
		"source-valid fixtures did not establish the pre-artifact scanner state"
	)


func _complete_artifact_commit() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var artifact := _survey_by_id(ARTIFACT_ID)
	var payoff := _tool_target_by_id(PAYOFF_ID)
	if not _require(
		not artifact.is_empty()
		and not payoff.is_empty()
		and artifact.get("scan_subject_kind") == "artifact"
		and artifact.get("scan_reward_kind") == "blueprint"
		and artifact.get("scan_reward_id") == BLUEPRINT_ID,
		"full-level source did not declare the physical cutter blueprint artifact"
	):
		return false
	_artifact_seconds = float(artifact.get("interaction_seconds", 0.0))
	var artifact_anchor: Vector2 = artifact.get("scan_anchor_world", artifact.get("center", Vector2.ZERO))
	var remembered_distance := artifact_anchor.distance_to(payoff.get("center", Vector2.ZERO))
	var remembered_limit := float(_world.tile_size) * REMEMBERED_PLACE_RADIUS_TILES
	var payoff_collected: bool = bool(_world.is_salvage_collected(PAYOFF_ID))
	if not _require(
		remembered_distance <= remembered_limit and not payoff_collected,
		"sealed wreck was not a visible remembered-place target near the artifact (distance=%.1f limit=%.1f collected=%s)" % [remembered_distance, remembered_limit, str(payoff_collected)]
	):
		return false
	_main._material_project.on_map_loaded(_world)
	_advance(0.0)
	var opening_text: String = _main._anomaly_survey.overlay_text(_world, _player)
	if not _require(
		opening_text == OPENING_LEAD
		and not profile.has_completed_discovery(BLUEPRINT_ID)
		and not _main._progression_project_tracker.visible
		and _main._material_project.status_for(CUTTER_PROJECT_ID) == "knowledge_required",
		"fresh scanner state exposed a recipe or lost the broad place-based lead: %s" % opening_text
	):
		return false

	var pose: Dictionary = ScannerPose.new().find_pose(_world, artifact)
	if not _require(bool(pose.get("found", false)), "artifact has no collision-clear scanner pose"):
		return false
	var boat_position: Vector2 = _world.get_entry_position(BOAT_ENTRY_ID)
	ScannerPose.new().place(_world, _player, artifact)
	print("Scanner-cutter correction artifact: first_pose")
	_advance(0.25)
	if not _require(not bool(_main._anomaly_survey.report().get("interaction", {}).get("activated", false)), "artifact auto-scanned from proximity"):
		return false

	var oxygen_before := _oxygen_seconds
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	_press_key(KEY_Q)
	_advance(_artifact_seconds / 3.0)
	var partial: Dictionary = _main._anomaly_survey.report().get("interaction", {})
	if not _require(
		float(partial.get("progress", 0.0)) > 0.0
		and float(partial.get("progress", 0.0)) < 1.0
		and _oxygen_seconds < oxygen_before
		and _main._expedition_day_state.daylight_remaining_seconds < daylight_before,
		"explicit artifact scan did not expose partial progress under oxygen/daylight pressure"
	):
		return false
	_release_action(&"active_tool_use")
	if not _require(
		_last_status_note == "Scanner interrupted"
		and not bool(_main._anomaly_survey.report().get("interaction", {}).get("activated", false))
		and is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0))),
		"releasing Q did not cancel and clear held scan progress"
	):
		return false
	ScannerPose.new().place(_world, _player, artifact)
	_press_key(KEY_Q)
	_advance(_artifact_seconds / 3.0)
	var scan_position: Vector2 = _player.global_position
	_player.swim_in_direction(Vector2(-float(pose.get("facing_sign", 1.0)), 0.0), 0.0)
	_player.global_position = scan_position
	_player.reset_motion()
	_advance(0.0)
	if not _require(_last_status_note == "Survey interrupted" and not bool(_main._anomaly_survey.report().get("interaction", {}).get("activated", false)), "turning away did not cancel and clear progress"):
		return false

	ScannerPose.new().place(_world, _player, artifact)
	for index in range(_main._held_salvage_capacity()):
		_main._sortie_state.collect_salvage("scanner_capacity_fixture_%d" % index, 0)
	_press_key(KEY_Q)
	_advance(_artifact_seconds + 0.01)
	_cargo_full_scan = _main._anomaly_survey.has_pending_discovery() and _main._held_cargo_count() == _main._held_salvage_capacity()
	if not _require(
		_cargo_full_scan
		and not profile.has_completed_discovery(BLUEPRINT_ID)
		and _main._anomaly_survey.overlay_text(_world, _player) == "Blueprint pending | Return to surface boat before another scan",
		"cargo-full scan did not remain pending for canonical-boat commitment"
	):
		return false
	_main._handle_oxygen_depleted()
	print("Scanner-cutter correction artifact: failure_reset")
	_failure_cleanup = _run_failed and not _main._anomaly_survey.has_pending_discovery() and not profile.has_completed_discovery(BLUEPRINT_ID)
	if not _require(_failure_cleanup, "oxygen failure retained unbanked blueprint knowledge"):
		return false
	_press_key(KEY_R)
	_advance(0.0)
	_prepare_controlled_movement()
	_starting_health = int(_main._player_health.current_health)

	ScannerPose.new().place(_world, _player, artifact)
	_press_key(KEY_Q)
	_advance(_artifact_seconds + 0.01)
	if not _require(_main._anomaly_survey.has_pending_discovery() and not profile.has_completed_discovery(BLUEPRINT_ID), "artifact retry did not recreate pending knowledge"):
		return false
	_player.global_position = boat_position
	_player.reset_motion()
	_advance(0.0)
	print("Scanner-cutter correction artifact: committed")
	if not _require(_world.is_inside_boat(_player.global_position), "artifact retry did not return to the canonical boat fixture"):
		return false
	var discoveries: Array = profile.report().get("completed_discoveries", [])
	var tracker_text: String = _main._progression_project_tracker.snapshot_text()
	return _require(
		profile.has_completed_discovery(BLUEPRINT_ID)
		and discoveries.count(BLUEPRINT_ID) == 1
		and not _main._anomaly_survey.has_pending_discovery()
		and _main._anomaly_survey.result_text() == str(artifact.get("finding_label", ""))
		and _main._material_project.project_definition().get("id") == CUTTER_PROJECT_ID
		and _main._progression_project_tracker.visible
		and tracker_text.find("Titanium  0/2") != -1
		and tracker_text.find("Coil  0/1") != -1,
		"boat commitment was not exact or did not hand preparation to the cutter tracker: %s" % tracker_text
	)


func _collect_recipe_and_build_cutter() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var expected_recipe := {
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
	}
	var project: Dictionary = _main._material_project.project_definition()
	var source_recipe: Dictionary = project.get("required_materials", {})
	if not _require(
		project.get("id") == CUTTER_PROJECT_ID
		and int(source_recipe.get(ExpansionProfileState.TITANIUM_MATERIAL_ID, 0)) == 2
		and int(source_recipe.get(ExpansionProfileState.COIL_MATERIAL_ID, 0)) == 1
		and source_recipe.size() == 2,
		"active cutter source recipe drifted from Ti2/Coil1 (project=%s recipe=%s)" % [str(project.get("id", "")), str(source_recipe)]
	):
		return false
	profile.deposit_materials(expected_recipe, true)
	_advance(0.0)
	var tracker_text: String = _main._progression_project_tracker.snapshot_text()
	if not _require(
		profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2
		and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 1
		and tracker_text.find("Titanium  2/2") != -1
		and tracker_text.find("Coil  1/1") != -1,
		"source-valid cutter preparation was not exactly Ti2/Coil1: %s" % tracker_text
	):
		return false
	_press_key(KEY_P)
	if not _require(not profile.has_capability(CUTTER_CAPABILITY_ID), "cutter built during active day"):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "cutter recipe did not enter night debrief"):
		return false
	_press_key(KEY_P)
	if not _require(
		profile.has_completed_project(CUTTER_PROJECT_ID)
		and profile.has_capability(CUTTER_CAPABILITY_ID)
		and profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 0
		and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 0,
		"night transaction did not build the exact cutter recipe"
	):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	_prepare_controlled_movement()
	_body_size = ((_player.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size
	_starting_health = int(_main._player_health.current_health)
	var return_text: String = _main._anomaly_survey.overlay_text(_world, _player)
	return _require(
		return_text == RETURN_LEAD
		and not _main._progression_project_tracker.visible,
		"night build did not replace optional project order with the remembered wreck: %s" % return_text
	)


func _open_remembered_wreck() -> bool:
	if not _require(_select_active_tool_for_smoke(CUTTER_CAPABILITY_ID), "built cutter could not be selected"):
		return false
	var target := _tool_target_by_id(PAYOFF_ID)
	if not _require(not target.is_empty() and not _world.is_salvage_collected(PAYOFF_ID), "remembered sealed wreck is unavailable"):
		return false
	var boat_position: Vector2 = _world.get_entry_position(BOAT_ENTRY_ID)
	var target_position: Vector2 = target.get("center", Vector2.ZERO)
	_player.global_position = target_position
	_player.reset_motion()
	_advance(0.0)
	if not _require(str(_world.get_tool_target_near(target_position, SALVAGE_COLLECTION_RADIUS).get("id", "")) == PAYOFF_ID, "real world query could not resolve the remembered sealed wreck"):
		return false
	var oxygen_before := _oxygen_seconds
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	var interaction_seconds := float(target.get("interaction_seconds", 0.0))
	_advance(0.25)
	if not _require(is_zero_approx(float(_main._cutter_salvage.report().get("progress_ratio", -1.0))), "wreck proximity advanced cutter progress before Q use"):
		return false
	_use_active_tool_for_smoke()
	_advance(interaction_seconds * 0.5)
	if not _require(not _world.is_salvage_collected(PAYOFF_ID), "sealed wreck completed before its authored cutter duration"):
		return false
	_advance(interaction_seconds * 0.5 + 0.05)
	_payoff_score = int(_world.get_salvage_score(PAYOFF_ID))
	if not _require(
		_world.is_salvage_collected(PAYOFF_ID)
		and _main._sortie_state.held_salvage_ids.has(PAYOFF_ID)
		and _last_status_note == "Sealed wreck opened | Salvage value +%d\n%s" % [_payoff_score, REWARD_PENDING]
		and _main._anomaly_survey.overlay_text(_world, _player) == REWARD_PENDING
		and _main._anomaly_survey.has_pending_discovery()
		and not _main._anomaly_survey.profile_state().has_completed_discovery(CorrectionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID)
		and _oxygen_seconds < oxygen_before
		and _main._expedition_day_state.daylight_remaining_seconds < daylight_before,
		"cutter payoff did not separate concrete cargo from pending navigation data"
	):
		return false
	_player.global_position = boat_position
	_player.reset_motion()
	_advance(0.0)
	return _require(
		_banked_salvage_ids.has(PAYOFF_ID)
		and _banked_score >= _payoff_score
		and not _main._anomaly_survey.has_pending_discovery()
		and _main._anomaly_survey.profile_state().has_completed_discovery(CorrectionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID)
		and _main._anomaly_survey.overlay_text(_world, _player) == "%s\n%s" % [REWARD_COMMIT, NEXT_LEAD],
		"sealed-wreck payoff did not bank and commit its southeast lead"
	)


func _verify_reload_and_migration() -> bool:
	var reloaded := CorrectionProfileState.new(PROFILE_PATH, true)
	var reload: Dictionary = reloaded.load_profile()
	_profile_reload = (
		str(reload.get("status", "")) == "loaded"
		and reloaded.has_completed_discovery(BLUEPRINT_ID)
		and reloaded.has_completed_discovery(CorrectionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID)
		and reloaded.has_completed_project(CUTTER_PROJECT_ID)
		and reloaded.has_capability(CUTTER_CAPABILITY_ID)
	)
	if not _require(_profile_reload, "durable cutter blueprint/project/capability did not reload: %s" % str(reload)):
		return false
	var legacy_payload := {
		"schema_version": 3,
		"completed_discoveries": [ExpansionProfileState.ANOMALY_DISCOVERY_ID],
		"unlocked_capabilities": [CUTTER_CAPABILITY_ID],
		"material_inventory": {},
		"completed_projects": [CUTTER_PROJECT_ID],
	}
	var migration: Dictionary = ExpansionProfileMigrations.apply(legacy_payload, {
		"survey_scanner_capability_id": ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		"survey_scanner_project_id": ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID,
		"survey_scanner_blueprint_id": ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID,
		"anomaly_discovery_id": ExpansionProfileState.ANOMALY_DISCOVERY_ID,
		"salvage_cutter_project_id": CUTTER_PROJECT_ID,
		"salvage_cutter_capability_id": CUTTER_CAPABILITY_ID,
		"salvage_cutter_blueprint_id": BLUEPRINT_ID,
	})
	_profile_migration = bool(migration.get("cutter_blueprint", false)) and legacy_payload["completed_discoveries"].has(BLUEPRINT_ID)
	return _require(_profile_migration, "legacy cutter profile did not gain the blueprint compatibility record")


func _tool_target_by_id(target_id: String) -> Dictionary:
	for target in _world.get_tool_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _release_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.pressed = false
	event.action = action
	_main._unhandled_input(event)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Expansion 13 scanner-cutter correction smoke failed: %s." % message)
	get_tree().quit(1)
	return false
