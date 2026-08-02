extends "res://scripts/main/smoke/smoke_check_base.gd"

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const InteriorExpeditionTransitionState := preload("res://scripts/main/interior_expedition_transition_state.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const PROFILE_PATH := "user://oceangame2_expansion_18_journey_smoke.json"
const EXTERIOR_MAP_ID := "production_level_01"
const INTERIOR_MAP_ID := "transfer_hub_interior_01"
const ENTRANCE_ID := "transfer_hub_exterior_entrance"
const RETURN_ID := "transfer_hub_interior_return"
const EXTERIOR_RETURN_ENTRY_ID := "transfer_hub_exterior_return"
const BOAT_ENTRY_ID := "surface_boat_entry"
const PREREQUISITE_ID := "wreck_network_triangulation_discovery"
const CORE_TARGET_ID := "transfer_hub_navigation_core_cradle"
const CORE_DISCOVERY_ID := "transfer_hub_navigation_core_discovery"
const CONTINUITY_SALVAGE_ID := "salvage_entry_shaft"
const CONTINUITY_MATERIAL_ID := "titanium_scrap"
const PLAN_ID := "transfer_hub_core_recovery"

var _snapshots: Array[Dictionary] = []
var _failure_restoration: Array[String] = []


static func create_clean_profile():
	cleanup_profile_storage()
	return ExpansionProfileState.new(PROFILE_PATH, true)


static func cleanup_profile_storage() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _smoke_expansion_18_transfer_hub_and_quit() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false
	if not _prepare_profile_and_gate():
		return
	if not _prepare_continuity_state(true):
		return

	var capacity_before := _snapshot("capacity_before_entry")
	if not _enter_hub():
		return
	var capacity_inside := _snapshot("capacity_inside")
	if not _expect_continuity(capacity_before, capacity_inside, "capacity entry"):
		return
	if not _prove_interior_pressure_and_boundaries():
		return
	if not _prove_full_cargo_and_hazard_restoration():
		return
	if not _recover_core() or not _prove_manual_reset():
		return
	if not _enter_hub() or not _recover_core() or not _prove_oxygen_retry():
		return
	if not _enter_hub() or not _recover_core() or not _prove_health_retry():
		return
	if not _prepare_continuity_state(false):
		return
	_snapshots.append(_snapshot("before_entry"))
	if not _enter_hub():
		return
	_snapshots.append(_snapshot("inside"))
	if not _expect_continuity(_snapshots[0], _snapshots[1], "final entry"):
		return
	if not _recover_core() or not _return_to_exterior():
		return

	_snapshots.append(_snapshot("after_return"))
	if not _expect_recovery_continuity(_snapshots[0], _snapshots[2]):
		return
	if not _commit_at_boat_and_reload():
		return
	_snapshots.append(_snapshot("at_boat"))
	if not _prove_legacy_connector_contract():
		return

	var profile = _main._anomaly_survey.profile_state()
	var commit_count: int = _main._expedition_day_state.committed_discovery_ids.count(CORE_DISCOVERY_ID)
	print("Expansion 18 Transfer Hub smoke passed: entrance=%s core=%s prerequisite=%s cutter=Space/USE full_cargo=retryable transitions=paired continuity=oxygen,daylight,health,cargo,materials,plan no_interior_bank_refill_night=true failures=%s commit_count=%d committed=%s reload=true legacy_connector=unchanged snapshots=%s result=\"%s\"." % [
		ENTRANCE_ID,
		CORE_TARGET_ID,
		PREREQUISITE_ID,
		",".join(PackedStringArray(_failure_restoration)),
		commit_count,
		str(profile.has_completed_discovery(CORE_DISCOVERY_ID)).to_lower(),
		JSON.stringify(_snapshots),
		_main._anomaly_survey.result_text().replace("\n", " | "),
	])
	cleanup_profile_storage()
	get_tree().quit(0)


func _prepare_profile_and_gate() -> bool:
	if _world.map_id != EXTERIOR_MAP_ID:
		return _abort("loaded unexpected exterior map %s" % _world.map_id)
	var profile = _main._anomaly_survey.profile_state()
	var checkpoint: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.EXPANSION_17_START, profile)
	if not bool(checkpoint.get("ready", false)):
		return _abort("could not prepare Expansion 17 boundary: %s" % str(checkpoint))
	_refresh_runtime_owners()
	var entrance := _connector_by_id(ENTRANCE_ID)
	if entrance.is_empty():
		return _abort("missing source-authored entrance %s" % ENTRANCE_ID)
	_player.global_position = entrance.get("center", Vector2.ZERO)
	_update_status_label()
	if _main._try_world_connector_transition() or _world.map_id != EXTERIOR_MAP_ID:
		return _abort("entrance opened before triangulation")
	if _status_label.text.find("Coordinates not triangulated") == -1:
		return _abort("locked entrance omitted triangulation feedback")
	var prerequisite: Dictionary = profile.complete_discovery(PREREQUISITE_ID, false)
	if not bool(prerequisite.get("changed", false)):
		return _abort("could not complete the triangulation prerequisite: %s" % str(prerequisite))
	return true


func _prepare_continuity_state(fill_capacity: bool) -> bool:
	_main._sortie_state.active = true
	_oxygen_seconds = 82.0
	_main._player_health.current_health = 2
	_main._expedition_day_state.begin_day(3)
	_main._expedition_day_state.daylight_remaining_seconds = 214.0
	_main._expedition_day_state.sortie_count = 2
	var selected: Dictionary = _main._expedition_plan_state.select(PLAN_ID, [PLAN_ID], "debrief")
	if not bool(selected.get("changed", false)) and _main._expedition_plan_state.selected_lead_id() != PLAN_ID:
		return _abort("could not prepare expedition plan continuity")
	if fill_capacity:
		if not _world.collect_salvage_by_id(CONTINUITY_SALVAGE_ID):
			return _abort("could not prepare source salvage continuity")
		_main._sortie_state.collect_salvage(CONTINUITY_SALVAGE_ID, _world.get_salvage_score(CONTINUITY_SALVAGE_ID))
	var material: Dictionary = _main._material_runtime.collect_biological_source(
		{"id": "transfer_hub_continuity_material", "material_id": CONTINUITY_MATERIAL_ID, "material_quantity": 1},
		EXTERIOR_MAP_ID,
		_main._sortie_state.held_salvage,
		_held_salvage_capacity()
	)
	if not bool(material.get("changed", false)):
		return _abort("could not prepare held material continuity: %s" % str(material))
	if fill_capacity:
		var probe_index := 0
		while _main._held_cargo_count() < _held_salvage_capacity():
			_main._sortie_state.collect_salvage("transfer_hub_capacity_probe_%d" % probe_index, 0)
			probe_index += 1
	return true


func _prove_interior_pressure_and_boundaries() -> bool:
	var oxygen_before := _oxygen_seconds
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	_process(0.5)
	if _oxygen_seconds >= oxygen_before or _main._expedition_day_state.daylight_remaining_seconds >= daylight_before:
		return _abort("oxygen or daylight stopped inside the Transfer Hub")
	var health_before: int = _main._player_health.current_health
	var material_before: Dictionary = _main._anomaly_survey.profile_state().material_inventory()
	var phase_before: String = _main._expedition_day_state.phase
	var night_event := InputEventKey.new()
	night_event.keycode = KEY_N
	night_event.pressed = true
	_main._unhandled_input(night_event)
	_process(0.0)
	if _main._player_health.current_health != health_before:
		return _abort("interior position refilled health")
	if _main._anomaly_survey.profile_state().material_inventory() != material_before:
		return _abort("interior position banked held materials")
	if _main._expedition_day_state.phase != phase_before:
		return _abort("interior position started night resolution")
	return true


func _prove_full_cargo_and_hazard_restoration() -> bool:
	var target := _core_target()
	if target.is_empty():
		return _abort("missing navigation core target")
	_player.global_position = target.get("center", Vector2.ZERO)
	if not _select_active_tool_for_smoke(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID):
		return _abort("could not select the existing Salvage Cutter")
	var blocked: Dictionary = _main._use_active_tool()
	if str(blocked.get("status", "")) != "wrong_context" or str(blocked.get("note", "")).find("Cargo full") == -1:
		return _abort("full cargo did not block the Cutter clearly: %s" % str(blocked))
	_main._cargo_collection.update(float(target.get("interaction_seconds", 0.0)) + 0.1)
	if _world.is_salvage_collected(CORE_TARGET_ID) or _main._navigation_core.held_count() != 0:
		return _abort("full cargo consumed or secured the navigation core")
	_main._material_runtime.discard_unbanked("capacity_probe_complete")
	if not _recover_core():
		return false
	_main._handle_hazard_hit("transfer_hub_hazard_probe")
	if _main._navigation_core.held_count() != 0 or _main._anomaly_survey.has_pending_discovery():
		return _abort("hazard retained unbanked navigation-core state")
	if _world.is_salvage_collected(CORE_TARGET_ID):
		return _abort("hazard did not restore the navigation core cradle")
	_failure_restoration.append("hazard")
	return true


func _prove_manual_reset() -> bool:
	_reset_run()
	if not _expect_canonical_retry("manual_reset"):
		return false
	_failure_restoration.append("manual_reset")
	return true


func _prove_oxygen_retry() -> bool:
	_handle_oxygen_depleted()
	if not _run_failed or _main._sortie_state.failure_reason != "oxygen_failure":
		return _abort("oxygen failure did not lock the interior expedition")
	_reset_run()
	if not _expect_canonical_retry("oxygen_retry"):
		return false
	_failure_restoration.append("oxygen_retry")
	return true


func _prove_health_retry() -> bool:
	_main._player_health.current_health = _main._player_health.max_health
	var damage: Dictionary = _main._apply_combat_damage(_main._player_health.max_health, "transfer_hub_health_probe")
	if not bool(damage.get("defeated", false)) or not _run_failed:
		return _abort("health defeat did not lock the interior expedition")
	_reset_run()
	if not _expect_canonical_retry("health_retry"):
		return false
	_failure_restoration.append("health_retry")
	return true


func _expect_canonical_retry(label: String) -> bool:
	if _world.map_id != EXTERIOR_MAP_ID:
		return _abort("%s did not return to the exterior" % label)
	if _player.global_position != _world.get_entry_position(BOAT_ENTRY_ID):
		return _abort("%s did not return to the canonical boat" % label)
	if _run_failed or _main._held_cargo_count() != 0 or _main._anomaly_survey.has_pending_discovery():
		return _abort("%s retained failed or unbanked state" % label)
	return true


func _recover_core() -> bool:
	var target := _core_target()
	if target.is_empty():
		return _abort("navigation core target was unavailable for recovery")
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false
	_player.global_position = target.get("center", Vector2.ZERO)
	if not _select_active_tool_for_smoke(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID):
		return _abort("Salvage Cutter was unavailable")
	_main._cargo_collection.update(0.1)
	if _world.is_salvage_collected(CORE_TARGET_ID):
		return _abort("navigation core collected without explicit Cutter use")
	var activated: Dictionary = _main._use_active_tool()
	if str(activated.get("status", "")) != "used":
		return _abort("Space/USE did not activate the Cutter: %s" % str(activated))
	_main._cargo_collection.update(float(target.get("interaction_seconds", 0.0)) + 0.1)
	if not _world.is_salvage_collected(CORE_TARGET_ID) or _main._navigation_core.held_count() != 1:
		return _abort("Cutter completion did not create held navigation-core cargo")
	if not _main._anomaly_survey.has_pending_discovery():
		return _abort("navigation core did not create pending boat commitment")
	if _main._anomaly_survey.profile_state().has_completed_discovery(CORE_DISCOVERY_ID):
		return _abort("navigation core committed before the canonical boat")
	return true


func _enter_hub() -> bool:
	if _world.map_id != EXTERIOR_MAP_ID:
		return _abort("entry attempted from %s" % _world.map_id)
	var entrance := _connector_by_id(ENTRANCE_ID)
	if entrance.is_empty():
		return _abort("exterior entrance unavailable")
	_player.global_position = entrance.get("center", Vector2.ZERO)
	if not _main._try_world_connector_transition() or _world.map_id != INTERIOR_MAP_ID:
		return _abort("unlocked authored entrance did not load the Transfer Hub")
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false
	return true


func _return_to_exterior() -> bool:
	var paired_return := _connector_by_id(RETURN_ID)
	if paired_return.is_empty():
		return _abort("paired interior return was unavailable")
	_player.global_position = paired_return.get("center", Vector2.ZERO)
	if not _main._try_world_connector_transition() or _world.map_id != EXTERIOR_MAP_ID:
		return _abort("paired return did not restore the exterior")
	if _player.global_position != _world.get_entry_position(EXTERIOR_RETURN_ENTRY_ID):
		return _abort("paired return ignored its source-authored exterior entry")
	if _main._navigation_core.held_count() != 1 or not _main._anomaly_survey.has_pending_discovery():
		return _abort("paired return lost navigation-core cargo")
	return true


func _commit_at_boat_and_reload() -> bool:
	_player.global_position = _world.get_entry_position(BOAT_ENTRY_ID)
	_process(0.0)
	var profile = _main._anomaly_survey.profile_state()
	if not profile.has_completed_discovery(CORE_DISCOVERY_ID):
		return _abort("canonical boat did not commit the navigation core")
	if _main._navigation_core.held_count() != 0 or _main._anomaly_survey.has_pending_discovery():
		return _abort("boat commitment retained held or pending core state")
	_process(0.0)
	if _main._expedition_day_state.committed_discovery_ids.count(CORE_DISCOVERY_ID) != 1:
		return _abort("repeat boat contact duplicated navigation-core commitment")
	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var load_report: Dictionary = reloaded.load_profile()
	if str(load_report.get("status", "")) != "loaded" or not reloaded.has_completed_discovery(CORE_DISCOVERY_ID):
		return _abort("profile reload lost the navigation core: %s" % str(load_report))
	_main._load_playable_map("res://maps/transfer_hub_interior_01.greybox.json", false, "transfer_hub_interior_entry", "", true, true)
	if not _world.is_salvage_collected(CORE_TARGET_ID):
		return _abort("committed profile state respawned the navigation core")
	_main._load_playable_map(PRODUCTION_LEVEL_MAP_PATH, false, BOAT_ENTRY_ID, "", true, true)
	return true


func _prove_legacy_connector_contract() -> bool:
	var owner := InteriorExpeditionTransitionState.new()
	var legacy: Dictionary = owner.prepare_transition(
		{"connector_kind": "legacy", "id": "legacy_regression_probe"},
		EXTERIOR_MAP_ID,
		PRODUCTION_LEVEL_MAP_PATH,
		Callable()
	)
	return bool(legacy.get("allowed", false)) and not bool(legacy.get("continuous", true)) and str(legacy.get("reason", "")) == "legacy_connector" or _abort("legacy connector contract drifted: %s" % str(legacy))


func _refresh_runtime_owners() -> void:
	_main._anomaly_survey.on_map_loaded(_world)
	_main._material_runtime.on_map_loaded(_world, _main._expedition_day_state, _main._daily_conditions.current_ids())
	_main._material_project.on_map_loaded(_world)
	_main._cutter_salvage.on_map_loaded(_world)
	_main._navigation_core.on_map_loaded(_world)
	_main._refresh_active_tools()


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _core_target() -> Dictionary:
	for target in _world.get_tool_targets():
		if str(target.get("id", "")) == CORE_TARGET_ID:
			return target
	return {}


func _snapshot(stage: String) -> Dictionary:
	return {
		"stage": stage,
		"map": str(_world.map_id),
		"oxygen": snappedf(_oxygen_seconds, 0.01),
		"daylight": snappedf(_main._expedition_day_state.daylight_remaining_seconds, 0.01),
		"health": _main._player_health.current_health,
		"held_salvage": _main._sortie_state.held_salvage,
		"held_materials": _main._material_runtime.held_quantities(),
		"banked_materials": _main._anomaly_survey.profile_state().material_inventory(),
		"held_core": _main._navigation_core.held_count(),
		"plan": _main._expedition_plan_state.selected_lead_id(),
		"phase": _main._expedition_day_state.phase,
	}


func _expect_continuity(before: Dictionary, after: Dictionary, label: String) -> bool:
	for key in ["oxygen", "daylight", "health", "held_salvage", "held_materials", "banked_materials", "held_core", "plan", "phase"]:
		if before.get(key) != after.get(key):
			return _abort("%s transition changed %s: %s -> %s" % [label, key, str(before.get(key)), str(after.get(key))])
	return true


func _expect_recovery_continuity(before: Dictionary, after: Dictionary) -> bool:
	for key in ["health", "held_salvage", "held_materials", "banked_materials", "plan", "phase"]:
		if before.get(key) != after.get(key):
			return _abort("paired return changed %s: %s -> %s" % [key, str(before.get(key)), str(after.get(key))])
	if float(after.get("oxygen", 0.0)) > float(before.get("oxygen", 0.0)):
		return _abort("paired return refilled oxygen")
	if float(after.get("daylight", 0.0)) > float(before.get("daylight", 0.0)):
		return _abort("paired return restored daylight")
	if int(after.get("held_core", 0)) != 1:
		return _abort("paired return did not preserve the recovered core")
	return true


func _abort(message: String) -> bool:
	push_error("Expansion 18 Transfer Hub smoke failed: %s" % message)
	cleanup_profile_storage()
	get_tree().quit(1)
	return false
