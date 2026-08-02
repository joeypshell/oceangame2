extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const BiologicalResourceController := preload("res://scripts/main/biological_resource_controller.gd")
const CargoCollectionController := preload("res://scripts/main/cargo_collection_controller.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpeditionDiscoveryState := preload("res://scripts/main/expedition_discovery_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const NavigationCoreRecoveryState := preload("res://scripts/main/navigation_core_recovery_state.gd")
const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")
const WreckNetworkInvestigationRuntime := preload("res://scripts/main/wreck_network_investigation_runtime.gd")

const EXTERIOR_MAP_PATH := "res://maps/production_level_01.greybox.json"
const INTERIOR_MAP_PATH := "res://maps/transfer_hub_interior_01.greybox.json"
const INTERIOR_ENTRY_ID := "transfer_hub_interior_entry"
const EXTERIOR_RETURN_ENTRY_ID := "transfer_hub_exterior_return"
const BOAT_ENTRY_ID := "surface_boat_entry"
const CORE_TARGET_ID := "transfer_hub_navigation_core_cradle"
const CORE_DISCOVERY_ID := "transfer_hub_navigation_core_discovery"
const TEST_PROFILE_PATH := "user://oceangame2_navigation_core_recovery_smoke.json"

var _failures: Array[String] = []


class StorageFailingProfile:
	extends RefCounted

	func has_completed_discovery(_discovery_id: String) -> bool:
		return false

	func complete_discovery(discovery_id: String, _persist := true) -> Dictionary:
		return {"changed": false, "reason": "storage_error", "discovery_id": discovery_id}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	main.set_process(false)
	main._player.set_physics_process(false)
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	_attach_profile(main, profile)

	var cutter: Dictionary = ReviewProgressionFixture.complete_capability(
		main,
		ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID
	)
	_expect(bool(cutter.get("ready", false)), "could not prepare the existing Salvage Cutter")
	main._material_project.on_map_loaded(main._world)
	main._refresh_active_tools()
	_expect(
		main._active_tools.selected_tool_id() == ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID,
		"Cutter was not the active Space/USE tool"
	)

	main._load_playable_map(INTERIOR_MAP_PATH, false, INTERIOR_ENTRY_ID, "", true, true)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	main._combat_interactions_enabled = false
	var target := _core_target(main)
	_expect(not target.is_empty(), "source-authored navigation core was unavailable")
	if target.is_empty():
		_finish(main)
		return
	var target_center: Vector2 = target.get("center", Vector2.ZERO)
	main._player.global_position = target_center

	for index in range(main._held_salvage_capacity()):
		main._sortie_state.collect_salvage("capacity_probe_%d" % index, 0)
	var blocked: Dictionary = main._use_active_tool()
	_expect(str(blocked.get("status", "")) == "wrong_context", "full cargo did not block Cutter activation")
	_expect(str(blocked.get("note", "")).find("Cargo full") != -1, "full-cargo feedback was unclear")
	main._cargo_collection.update(float(target.get("interaction_seconds", 0.0)) + 0.1)
	_expect(not main._world.is_salvage_collected(CORE_TARGET_ID), "full cargo consumed the navigation core")
	_expect(main._navigation_core.held_count() == 0 and not main._anomaly_survey.has_pending_discovery(), "full cargo created pending core success")
	main._sortie_state.clear_held()

	main._cargo_collection.update(float(target.get("interaction_seconds", 0.0)) + 0.1)
	_expect(not main._world.is_salvage_collected(CORE_TARGET_ID), "proximity collected the core before explicit use")
	_expect(main._last_status_note.find("Space/USE cutter") != -1, "ready feedback omitted the Space/USE action")
	var activated: Dictionary = main._use_active_tool()
	_expect(str(activated.get("status", "")) == "used", "Space/USE did not activate the Cutter")
	main._cargo_collection.update(float(target.get("interaction_seconds", 0.0)) + 0.1)
	_expect(main._world.is_salvage_collected(CORE_TARGET_ID), "completed Cutter interaction left the core in its cradle")
	_expect(main._navigation_core.held_count() == 1, "completed Cutter interaction did not create held core cargo")
	_expect(main._anomaly_survey.has_pending_discovery(), "completed Cutter interaction did not create pending discovery")
	_expect(not profile.has_completed_discovery(CORE_DISCOVERY_ID), "core committed inside the Transfer Hub")
	_expect(main._sortie_state.held_salvage == 0 and main._sortie_state.held_salvage_score == 0, "core became scored salvage")
	main._update_status_label()
	_expect(_hud_has_core(main), "cargo HUD omitted the held navigation core")
	var transition: Dictionary = main._interior_expedition_transition.prepare_transition(
		{
			"id": "transfer_hub_exterior_entrance",
			"connector_kind": "exceptional_interior",
			"connector_direction": "forward",
			"destination_map_id": "transfer_hub_interior_01",
			"destination_entry_id": INTERIOR_ENTRY_ID,
			"paired_connector_id": "transfer_hub_interior_return",
		},
		"production_level_01",
		EXTERIOR_MAP_PATH,
		Callable(self, "_has_discovery")
	)
	_expect(bool(transition.get("allowed", false)), "could not prepare anti-duplication failure probe")
	main._interior_expedition_transition.complete_arrival("transfer_hub_interior_01")
	main._interior_expedition_transition.capture_consumed(main._world, [CORE_TARGET_ID])

	main._handle_hazard_hit("core_hazard_probe")
	_expect(main._navigation_core.held_count() == 0 and not main._anomaly_survey.has_pending_discovery(), "hazard retained unbanked core state")
	_expect(not main._world.is_salvage_collected(CORE_TARGET_ID), "hazard did not restore the core cradle")
	var consumed_after_hazard: Dictionary = main._interior_expedition_transition.report().get("consumed_ids_by_map", {})
	_expect(not consumed_after_hazard.get("transfer_hub_interior_01", {}).has(CORE_TARGET_ID), "hazard retained the core in transition anti-duplication state")

	main._player.global_position = target_center
	main._use_active_tool()
	main._cargo_collection.update(float(target.get("interaction_seconds", 0.0)) + 0.1)
	_expect(main._navigation_core.held_count() == 1, "core could not be recovered after failure restoration")
	var score_before: int = main._banked_score
	var banked_before: int = main._banked_salvage
	var wallet_before: int = main._progression_runtime.wallet()

	main._anomaly_survey.on_map_transition("production_level_01")
	main._load_playable_map(EXTERIOR_MAP_PATH, false, EXTERIOR_RETURN_ENTRY_ID, "", true, true)
	_expect(main._navigation_core.held_count() == 1 and main._anomaly_survey.has_pending_discovery(), "paired return lost held core state")
	main._anomaly_survey.on_map_transition("transfer_hub_interior_01")
	main._load_playable_map(INTERIOR_MAP_PATH, false, INTERIOR_ENTRY_ID, "", true, true)
	_expect(main._world.is_salvage_collected(CORE_TARGET_ID), "re-entry duplicated the held navigation core")
	main._anomaly_survey.on_map_transition("production_level_01")
	main._load_playable_map(EXTERIOR_MAP_PATH, false, EXTERIOR_RETURN_ENTRY_ID, "", true, true)
	main._player.global_position = main._world.get_entry_position(BOAT_ENTRY_ID)
	main._process(0.0)
	_expect(profile.has_completed_discovery(CORE_DISCOVERY_ID), "canonical boat did not commit the navigation core")
	_expect(main._navigation_core.held_count() == 0 and not main._anomaly_survey.has_pending_discovery(), "boat commit retained held or pending core state")
	_expect(main._banked_score == score_before and main._banked_salvage == banked_before, "core commit changed salvage score or count")
	_expect(main._progression_runtime.wallet() == wallet_before, "core commit granted wallet value")
	_expect(main._anomaly_survey.result_text().find("Navigation core delivered") != -1, "commit result omitted the delivered payoff")
	_expect(main._anomaly_survey.result_text().find("night analysis") != -1, "commit result omitted the broad next lead")
	main._process(0.0)
	_expect(main._expedition_day_state.committed_discovery_ids.count(CORE_DISCOVERY_ID) == 1, "repeat boat contact duplicated the core commit")

	main._load_playable_map(INTERIOR_MAP_PATH, false, INTERIOR_ENTRY_ID, "", true, true)
	_expect(main._world.is_salvage_collected(CORE_TARGET_ID), "committed profile state respawned the core")
	_test_storage_failure_retention(target)
	_test_profile_migration_and_reload()
	_finish(main)


func _attach_profile(main, profile) -> void:
	main._anomaly_survey = AnomalySurveyRuntime.new(main._progression_runtime, false, profile)
	main._wreck_network_investigation = WreckNetworkInvestigationRuntime.new(profile)
	main._progression_runtime.set_profile_state(profile)
	main._material_runtime = MaterialRuntimeController.new(profile)
	main._material_project = MaterialProjectRuntime.new(profile)
	main._cutter_salvage = CutterSalvageController.new(profile)
	main._navigation_core = NavigationCoreRecoveryState.new(profile)
	main._biological_resources = BiologicalResourceController.new(profile)
	main._cargo_collection = CargoCollectionController.new(main)
	main._anomaly_survey.on_map_loaded(main._world)
	main._material_runtime.on_map_loaded(main._world, main._expedition_day_state, main._daily_conditions.current_ids())
	main._material_project.on_map_loaded(main._world)
	main._cutter_salvage.on_map_loaded(main._world)
	main._navigation_core.on_map_loaded(main._world)
	main._biological_resources.on_map_loaded(main._world)
	main._refresh_active_tools()


func _test_storage_failure_retention(target: Dictionary) -> void:
	var profile := StorageFailingProfile.new()
	var pending := ExpeditionDiscoveryState.new()
	var created: Dictionary = pending.create_pending(
		CORE_DISCOVERY_ID,
		"transfer_hub_interior_01",
		CORE_TARGET_ID,
		"production_level_01",
		BOAT_ENTRY_ID,
		{"target_type": "held_discovery_cargo"}
	)
	var owner := NavigationCoreRecoveryState.new(profile)
	var secured: Dictionary = owner.secure(target, "transfer_hub_interior_01", {"pending": true})
	var commit: Dictionary = pending.commit_at("production_level_01", BOAT_ENTRY_ID, profile)
	_expect(created.get("status") == "pending_created" and bool(secured.get("changed", false)), "save-failure fixture could not prepare held core")
	_expect(commit.get("status") == "storage_error", "forced profile save failure did not surface")
	_expect(pending.has_pending() and owner.held_count() == 1, "save failure discarded pending or held core state")


func _test_profile_migration_and_reload() -> void:
	var payload := {
		"schema_version": 3,
		"completed_discoveries": [CORE_DISCOVERY_ID],
		"unlocked_capabilities": [],
		"material_inventory": {},
		"completed_projects": [],
	}
	var file := FileAccess.open(TEST_PROFILE_PATH, FileAccess.WRITE)
	_expect(file != null, "could not create profile migration fixture")
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
	file.close()
	var migrated := ExpansionProfileState.new(TEST_PROFILE_PATH, true)
	var migration: Dictionary = migrated.load_profile()
	_expect(migration.get("status") == "migrated_v3" and migrated.has_completed_discovery(CORE_DISCOVERY_ID), "schema-v3 migration lost committed core state")
	_expect(migrated.save_profile(), "migrated core profile could not save as current schema")
	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH, true)
	_expect(reloaded.load_profile().get("status") == "loaded", "current core profile did not reload")
	_expect(reloaded.has_completed_discovery(CORE_DISCOVERY_ID), "profile reload lost committed core state")


func _core_target(main) -> Dictionary:
	for target in main._world.get_tool_targets():
		if str(target.get("id", "")) == CORE_TARGET_ID:
			return target
	return {}


func _hud_has_core(main) -> bool:
	for item in main._held_cargo_hud.get_test_report().get("items", []):
		if str(item.get("id", "")) == "navigation_core" and int(item.get("quantity", 0)) == 1:
			return true
	return false


func _has_discovery(_discovery_id: String) -> bool:
	return true


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish(main) -> void:
	_cleanup_profile()
	main.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Navigation core recovery smoke failed: %s" % failure)
		quit(1)
		return
	print("Navigation core recovery passed: cutter=Space/USE cargo=one_slot full=retryable score=zero return=continuous hazard=restored commit=canonical_boat exact_once=true reload=true save_failure=retained.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
