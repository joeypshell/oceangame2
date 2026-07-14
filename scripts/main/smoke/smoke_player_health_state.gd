extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const PlayerHealthState := preload("res://scripts/main/player_health_state.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_focused_state()
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	main._load_playable_map(main.PRODUCTION_SLICE_MAP_PATH, false)
	main.set_process(false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false

	var oxygen_start: float = main._sortie_state.oxygen_seconds
	var first_hit: Dictionary = main._apply_combat_damage(1, "health_smoke")
	_expect(bool(first_hit.get("changed", false)) and main._player_health.current_health == 2, "first combat hit did not reduce health")
	_expect(is_equal_approx(main._sortie_state.oxygen_seconds, oxygen_start), "combat hit changed oxygen")
	var blocked_hit: Dictionary = main._apply_combat_damage(1, "health_smoke")
	_expect(blocked_hit.get("reason") == "invulnerable", "hit invulnerability did not block immediate repeat")

	var surface := _surface_center_outside_boat(main._world)
	_expect(surface != Vector2.ZERO, "no open surface outside the boat")
	main._player.global_position = surface
	main._process(0.0)
	_expect(main._player_health.current_health == 2, "open surface refilled health")
	main._player.global_position = main._world.get_extraction_center()
	main._process(0.0)
	_expect(main._player_health.current_health == 3, "canonical boat did not refill health")

	var banked_target := _instant_salvage(main._world, [])
	main._player.global_position = banked_target.get("center", Vector2.ZERO)
	main._process(0.0)
	main._player.global_position = main._world.get_extraction_center()
	main._process(0.0)
	var banked_score: int = main._banked_score
	_expect(banked_score > 0 and main._banked_salvage == 1, "banked setup did not commit salvage")

	var held_target := _instant_salvage(main._world, [str(banked_target.get("id", ""))])
	main._player.global_position = held_target.get("center", Vector2.ZERO)
	main._process(0.0)
	_expect(main._sortie_state.held_salvage == 1, "combat-defeat setup did not hold salvage")
	var material := _first_active_material(main._world)
	var material_result: Dictionary = main._material_runtime.update_collection(
		main._world,
		material.get("center", Vector2.ZERO),
		main.SALVAGE_COLLECTION_RADIUS,
		main._expedition_day_state,
		main._sortie_state.held_salvage,
		main._held_salvage_capacity()
	)
	_expect(bool(material_result.get("changed", false)) and main._material_runtime.held_count() == 1, "combat-defeat setup did not hold material")
	_seed_pending_survey(main)

	for hit_index in range(3):
		main._player_health.update(1.0)
		main._apply_combat_damage(1, "deep_cache_territorial_eel")
	_expect(main._sortie_state.failed and main._sortie_state.failure_reason == "combat_defeat", "zero health did not create combat defeat")
	_expect(main._player_health.current_health == 0, "combat defeat did not retain zero health until retry")
	_expect(main._sortie_state.held_salvage == 0 and not main._world.is_salvage_collected(str(held_target.get("id", ""))), "combat defeat did not restore held salvage")
	var depleted: Array = main._world.get_material_candidate_report().get("depleted_ids", [])
	_expect(main._material_runtime.held_count() == 0 and not depleted.has(str(material.get("id", ""))), "combat defeat did not restore held material")
	_expect(not main._anomaly_survey.has_pending_discovery(), "combat defeat did not clear pending survey")
	_expect(main._banked_score == banked_score and main._banked_salvage == 1, "combat defeat changed banked salvage state")
	_expect(main._status_label.text.find("Health 0/3") != -1 and main._result_label.text.find("Combat defeat") != -1, "combat defeat feedback omitted health/failure text")
	_expect(main._player.global_position == main._world.spawn_position, "combat defeat did not return player to spawn")

	main._reset_run()
	_expect(main._player_health.current_health == 3 and not main._sortie_state.failed, "manual retry did not restore full health")
	var hazard_oxygen: float = main._sortie_state.oxygen_seconds
	main._handle_hazard_hit("hazard_health_regression")
	_expect(main._player_health.current_health == 3, "legacy hazard changed combat health")
	_expect(main._sortie_state.oxygen_seconds < hazard_oxygen, "legacy hazard stopped applying oxygen pressure")

	main._reset_run()
	var oxygen_target := _instant_salvage(main._world, [])
	main._player.global_position = oxygen_target.get("center", Vector2.ZERO)
	main._process(0.0)
	main._apply_combat_damage(1, "health_smoke")
	main._sortie_state.oxygen_seconds = 0.1
	main._process(0.2)
	_expect(main._sortie_state.failure_reason == "oxygen_failure", "oxygen depletion drifted: reason=%s phase=%s active=%s oxygen=%.2f surface=%s boat=%s" % [main._sortie_state.failure_reason, main._expedition_day_state.phase, str(main._sortie_state.active), main._sortie_state.oxygen_seconds, str(main._world.is_at_open_surface(main._player.global_position)), str(main._world.is_inside_boat(main._player.global_position))])
	_expect(main._player_health.current_health == 2, "oxygen failure changed combat health")

	if not _failures.is_empty():
		for failure in _failures:
			push_error("Player health state smoke failed: %s" % failure)
		quit(1)
		return
	print("Player health state smoke passed: health=3 separate_oxygen=true invulnerability=1.0 connector_preserved=true surface_refill=false boat_refill=true combat_defeat_restored=true banked_preserved=true hazard_health_unchanged=true oxygen_reason_unchanged=true.")
	quit(0)


func _test_focused_state() -> void:
	var health := PlayerHealthState.new()
	health.apply_damage(1, "fixture")
	health.begin_map_leg(true)
	_expect(health.current_health == 2, "connector-preserved leg reset health")
	health.begin_map_leg(false)
	_expect(health.current_health == 3, "new non-preserved leg did not refill health")
	health.apply_damage(1, "fixture")
	_expect(health.refill_at_boat() and health.current_health == 3, "focused boat refill failed")


func _seed_pending_survey(main) -> void:
	var profile = main._anomaly_survey.profile_state()
	profile.complete_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID, false)
	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1, ExpansionProfileState.COIL_MATERIAL_ID: 1}, false)
	profile.complete_material_project(_project_by_id(main._world, ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID), false)
	var target: Dictionary = main._world.get_survey_targets()[0]
	main._player.global_position = target.get("center", Vector2.ZERO)
	main._anomaly_survey.update(main._world, main._player, float(target.get("interaction_seconds", 1.0)) + 0.1)
	_expect(main._anomaly_survey.has_pending_discovery(), "survey setup did not create pending state")


func _project_by_id(world, project_id: String) -> Dictionary:
	for project in world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _surface_center_outside_boat(world) -> Vector2:
	for center in world.get_open_surface_centers():
		if not world.is_inside_boat(center):
			return center
	return Vector2.ZERO


func _instant_salvage(world, excluded_ids: Array[String]) -> Dictionary:
	for salvage in world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant" and not excluded_ids.has(str(salvage.get("id", ""))):
			return salvage
	return {}


func _first_active_material(world) -> Dictionary:
	var active_ids: Array = world.get_material_candidate_report().get("active_ids", [])
	for candidate in world.get_material_candidates():
		if active_ids.has(str(candidate.get("id", ""))):
			return candidate
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
