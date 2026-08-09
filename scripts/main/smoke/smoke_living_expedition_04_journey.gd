extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const BiologicalResourceController := preload("res://scripts/main/biological_resource_controller.gd")
const CompanionGuardianPulseRuntime := preload("res://scripts/companion/companion_guardian_pulse_runtime.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ReviewProfileMode := preload("res://scripts/main/review_profile_mode.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")
const TerritorialHostileController := preload("res://scripts/main/territorial_hostile_controller.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const CONNECTOR_MAP_PATH := "res://maps/production_slice_04.greybox.json"
const PROFILE_PATH := "user://smoke_living_expedition_04_profile.json"
const CHECKPOINT_ID := ReviewCheckpointFixture.LIVING_EXPEDITION_04_START
const RELATIONSHIP_ID := "deep_cache_eel_companion_response"
const HOSTILE_ID := "deep_cache_territorial_eel"
const HARVEST_ID := "deep_cache_eel_electrocyte_harvest"
const CACHE_ID := "salvage_deep_right_cache"
const KITE_ID := CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID
const MICA_ID := CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID
const GUARDIAN_ACTION_ID := "guardian_pulse_action"

var _failures: Array[String] = []
var _status_notes: Array[String] = []


class AnchorProfileFixture:
	extends RefCounted

	func companion_report() -> Dictionary:
		var individual := {
			"individual_id": "spark_ray_juvenile_01",
			"species_id": "spark_ray",
			"callsign": "Anchor",
			"rescue_committed": true,
			"earned_memory_ids": ["held_the_flow"],
			"selected_adaptation_id": "anchor_fins",
		}
		return {"active_individual_id": individual["individual_id"], "individual": individual}

	func has_capability(capability_id: String) -> bool:
		return capability_id == "shock_prod"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var original_time_scale := Engine.time_scale
	var checkpoint_id := ReviewProfileMode.checkpoint_id(OS.get_cmdline_user_args(), OS.get_cmdline_args())
	_expect(checkpoint_id == CHECKPOINT_ID, "journey requires the isolated Living Expedition 04 checkpoint")

	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player = PLAYER_SCENE.instantiate()
	get_root().add_child(player)
	player.set_physics_process(false)
	await process_frame

	var profile := ExpansionProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	var checkpoint: Dictionary = ReviewCheckpointFixture.apply(checkpoint_id, profile)
	_expect(bool(checkpoint.get("ready", false)), "Living Expedition 04 checkpoint failed: %s" % checkpoint)
	_expect(profile.save_profile(), "checkpoint profile could not be saved")
	var companion_report: Dictionary = profile.companion_report()
	_expect(str(companion_report.get("active_individual_id", "")) == MICA_ID, "checkpoint did not begin with Mica active")
	_expect(_adaptation_for(profile, MICA_ID) == "drift_lens", "checkpoint omitted Drift Lens Mica")
	_expect(_adaptation_for(profile, KITE_ID) == "guardian_pulse", "checkpoint omitted Guardian-Pulse Kite")
	_expect(profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID), "checkpoint omitted Shock Prod")
	_expect(_record_by_id(world.get_companion_hostile_responses(), RELATIONSHIP_ID).get("hostile_id") == HOSTILE_ID, "authored companion/eel relationship was unavailable")

	var oxygen := SortieState.new(90.0)
	var day := ExpeditionDayState.new(300.0)
	day.begin_day(3)
	day.on_map_loaded(str(world.map_id))
	var hostiles := TerritorialHostileController.new()
	hostiles.on_map_loaded(world, false)
	var material_runtime := MaterialRuntimeController.new(profile)
	material_runtime.on_map_loaded(world, day)
	var biological := BiologicalResourceController.new(profile)
	biological.on_map_loaded(world, false)
	var access_before := _access_snapshot(world)
	var progression_before := _progression_snapshot(profile)

	var sortie := CompanionSortieRuntime.new()
	get_root().add_child(sortie)
	await process_frame
	sortie.set_process(false)
	sortie.bind_interface(null, Callable(self, "_record_status"), Callable(), Callable(self, "_control_allowed"))
	var mica_launch: Dictionary = sortie.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), true, false, hostiles)
	_expect(str(mica_launch.get("active_species_id", "")) == "veil_cuttle", "Mica did not launch from the checkpoint")
	var mica_evidence := _test_mica_path(world, player, profile, sortie, hostiles, biological, access_before, progression_before)
	_advance_pressure(oxygen, day, 0.25)

	var kite_selection: Dictionary = profile.select_active_companion(KITE_ID, true)
	_expect(bool(kite_selection.get("changed", false)), "boat selection did not choose Kite")
	var kite_launch: Dictionary = sortie.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), true, false, hostiles)
	_expect(str(kite_launch.get("active_species_id", "")) == "spark_ray", "Guardian-Pulse Kite did not launch")
	var guardian_evidence := _test_guardian_path(world, player, profile, sortie, hostiles, biological, material_runtime)
	_advance_pressure(oxygen, day, 0.5)
	_test_anchor_isolation(world, player, hostiles, sortie.companion())

	sortie.reset_control("retry")
	hostiles.reset_for_failure(world)
	biological.on_map_loaded(world, false)
	var shock := ShockProdController.new()
	var first_defeat := _defeat_with_shock(world, player, hostiles, shock, oxygen, day)
	var defeated_center: Vector2 = hostiles.state_for(HOSTILE_ID).get("position", Vector2.ZERO)
	var blocked: Dictionary = biological.update(world, hostiles, material_runtime, defeated_center, 34.0, 1.5, 2, 2)
	_advance_pressure(oxygen, day, 1.5)
	_expect(bool(blocked.get("blocked", false)) and not biological.is_collected(HARVEST_ID), "cargo-full harvest deleted the electrocyte")
	var cargo_full_evidence := {"held": 2, "capacity": 2, "blocked": bool(blocked.get("blocked", false))}
	var harvested: Dictionary = biological.update(world, hostiles, material_runtime, defeated_center, 34.0, 1.5, 0, 2)
	_advance_pressure(oxygen, day, 1.5)
	_expect(bool(harvested.get("collected", false)) and material_runtime.held_quantities().get(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID, 0) == 1, "explicit harvest did not enter held cargo")
	var held_after_harvest := material_runtime.held_count()

	var connector_world = _build_world(CONNECTOR_MAP_PATH)
	hostiles.on_map_loaded(connector_world, true)
	biological.on_map_loaded(connector_world, true)
	material_runtime.on_map_loaded(connector_world, day)
	day.on_map_transition(str(connector_world.map_id))
	_expect(material_runtime.held_count() == 1 and biological.is_collected(HARVEST_ID), "connector transition lost held harvest state")
	var connector_preserved: bool = material_runtime.held_count() == 1 and biological.is_collected(HARVEST_ID)
	hostiles.on_map_loaded(world, true)
	biological.on_map_loaded(world, true)
	material_runtime.on_map_loaded(world, day)
	day.on_map_transition(str(world.map_id))
	_expect(hostiles.state_for(HOSTILE_ID).get("phase") == "defeated" and biological.is_collected(HARVEST_ID), "same-day map reload lost defeat or harvest state")
	var map_reload_preserved: bool = hostiles.state_for(HOSTILE_ID).get("phase") == "defeated" and biological.is_collected(HARVEST_ID)

	sortie.reset_control("retry")
	hostiles.reset_for_failure(world)
	var restored: Dictionary = biological.restore_material_cargo(material_runtime, world, day, hostiles, "retry")
	_expect(int(restored.get("restored_count", 0)) == 1 and material_runtime.held_count() == 0, "Retry did not restore unbanked harvest cargo")
	_expect(hostiles.state_for(HOSTILE_ID).get("phase") == "home" and int(hostiles.state_for(HOSTILE_ID).get("health", 0)) == 3, "Retry did not restore the eel")
	_expect(not biological.is_collected(HARVEST_ID), "Retry retained electrocyte depletion")

	shock.reset()
	var bank_defeat := _defeat_with_shock(world, player, hostiles, shock, oxygen, day)
	defeated_center = hostiles.state_for(HOSTILE_ID).get("position", Vector2.ZERO)
	var reharvested: Dictionary = biological.update(world, hostiles, material_runtime, defeated_center, 34.0, 1.5, 0, 2)
	_advance_pressure(oxygen, day, 1.5)
	_expect(bool(reharvested.get("collected", false)), "post-Retry electrocyte could not be reharvested")
	var banked: Dictionary = material_runtime.try_commit_at_boat(world, world.get_extraction_center())
	_expect(bool(banked.get("changed", false)) and profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID) == 1, "canonical boat did not bank the electrocyte")
	_expect(not world.is_salvage_collected(CACHE_ID), "encounter evidence collected the guarded cache")
	_expect(_access_snapshot(world) == access_before, "encounter evidence changed terrain or equipment gates")
	_expect(_progression_except_materials(profile) == _progression_except_materials_from(progression_before), "encounter evidence changed unrelated progression")

	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var reload: Dictionary = reloaded.load_profile()
	_expect(str(reload.get("status", "")) == "loaded", "profile did not reload after banking")
	_expect(reloaded.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID) == 1, "profile reload lost banked electrocyte")
	_expect(_adaptation_for(reloaded, MICA_ID) == "drift_lens" and _adaptation_for(reloaded, KITE_ID) == "guardian_pulse", "profile reload changed companion adaptations")

	day.begin_next_day()
	hostiles.on_map_loaded(world, false)
	biological.on_map_loaded(world, false)
	material_runtime.on_map_loaded(world, day)
	var fresh_hostile: Dictionary = hostiles.state_for(HOSTILE_ID)
	_expect(fresh_hostile.get("phase") == "home" and int(fresh_hostile.get("health", 0)) == 3, "fresh day did not restore the eel")
	_expect(not biological.is_collected(HARVEST_ID), "fresh day did not replenish the harvest")
	_expect(profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID) == 1, "fresh day changed banked electrocyte")

	var final_report := {
		"mica": mica_evidence,
		"guardian": guardian_evidence,
		"shock_first": first_defeat,
		"shock_banked": bank_defeat,
		"hostile": fresh_hostile,
		"oxygen": oxygen.oxygen_seconds,
		"daylight": day.daylight_remaining_seconds,
		"day": day.day_number,
		"cargo_full": cargo_full_evidence,
		"held_after_harvest": held_after_harvest,
		"banked_electrocyte": profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID),
		"retry_restored_count": int(restored.get("restored_count", 0)),
		"connector_preserved": connector_preserved,
		"map_reload_preserved": map_reload_preserved,
		"cache_collected": world.is_salvage_collected(CACHE_ID),
	}
	_finish(world, connector_world, player, sortie, original_time_scale, final_report)


func _test_mica_path(world, player, profile, sortie, hostiles, biological, access_before: Dictionary, progression_before: Dictionary) -> Dictionary:
	hostiles.reset_for_failure(world)
	var home: Vector2 = hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	_place_pair(player, sortie.companion(), home + Vector2(-64.0, 0.0))
	hostiles.update(world, player.global_position, 0.0)
	var hostile_before: Dictionary = hostiles.state_for(HOSTILE_ID)
	var biological_before: Dictionary = biological.report()
	var visual_before: Dictionary = world.get_biological_resource_visual_report()
	var cache_before: bool = world.is_salvage_collected(CACHE_ID)
	var result: Dictionary = _dispatch_command(sortie, "read_drift")
	_expect(bool(result.get("changed", false)) and result.get("target_id") == HOSTILE_ID, "Mica did not read the source-linked eel")
	_expect(result.get("command_label") == "Predict Lunge", "eel-context command did not identify Mica's prediction role")
	_expect(result.get("phase") == "warning" and (result.get("movement_direction", Vector2.ZERO) as Vector2) != Vector2.ZERO, "Mica projection omitted phase or direction")
	var projection: Dictionary = sortie.companion().report().get("drift_projection", {})
	_expect(
		projection.get("heading_text") == "MICA PREDICTION - NO DAMAGE"
		and str(projection.get("primary_text", "")).begins_with("LUNGE WEST IN ")
		and projection.get("response_text") == "MOVE ASIDE"
		and (projection.get("card_rect", Rect2()) as Rect2).has_area(),
		"Mica projection did not explain the predicted attack and player response"
	)
	_expect(hostiles.state_for(HOSTILE_ID) == hostile_before, "Mica read mutated hostile state")
	_expect(biological.report() == biological_before and world.get_biological_resource_visual_report() == visual_before, "Mica read mutated resource state")
	_expect(world.is_salvage_collected(CACHE_ID) == cache_before and _access_snapshot(world) == access_before, "Mica read changed cache or access state")
	_expect(_progression_snapshot(profile) == progression_before, "Mica read changed profile progression")
	player.global_position = home + Vector2(-1000.0, 0.0)
	var retreat: Dictionary = hostiles.update(world, player.global_position, 0.0)
	_expect(retreat.get("kind") == "retreat" and hostiles.state_for(HOSTILE_ID).get("phase") == "returning", "ordinary retreat did not evade the warning")
	sortie.reset_control("retry")
	_expect(not bool(sortie.companion().report().get("drift_projection", {}).get("visible", true)), "Retry retained Mica projection")
	return {"phase": result.get("phase"), "direction": result.get("movement_direction"), "evade": retreat.get("kind")}


func _test_guardian_path(world, player, profile, sortie, hostiles, biological, material_runtime) -> Dictionary:
	hostiles.reset_for_failure(world)
	biological.on_map_loaded(world, false)
	var home: Vector2 = hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	_place_pair(player, sortie.companion(), home + Vector2(-100.0, 0.0))
	hostiles.update(world, player.global_position, 0.0)
	var before: Dictionary = hostiles.state_for(HOSTILE_ID)
	var result: Dictionary = _dispatch_command(sortie, GUARDIAN_ACTION_ID)
	_expect(bool(result.get("changed", false)) and result.get("role") == "independent", "Guardian Pulse did not begin through the companion palette")
	var guardian = sortie.guardian_pulse_runtime()
	guardian.advance(0.5, false)
	var report: Dictionary = guardian.report()
	var after: Dictionary = hostiles.state_for(HOSTILE_ID)
	_expect(report.get("last_result") == "hit" and after.get("phase") == "recovery", "Guardian Pulse did not create a recovery opening")
	_expect(int(after.get("health", -1)) == int(before.get("health", -2)) and int(report.get("last_damage", -1)) == 0, "Guardian Pulse changed eel health")
	_expect((after.get("position", Vector2.ZERO) as Vector2).distance_to(before.get("position", Vector2.ZERO)) > 0.0, "Guardian Pulse did not recoil the eel")
	var harvest: Dictionary = biological.update(world, hostiles, material_runtime, after.get("position", Vector2.ZERO), 34.0, 2.0, 0, 2)
	_expect(harvest.get("reason") == "hostile_not_defeated" and not biological.is_collected(HARVEST_ID), "Guardian Pulse exposed the defeat-only harvest")
	_expect(not world.is_salvage_collected(CACHE_ID), "Guardian Pulse collected the guarded cache")
	return {"recoil": report.get("last_recoil_distance"), "opening": report.get("last_opening_seconds"), "damage": report.get("last_damage"), "health": after.get("health")}


func _test_anchor_isolation(world, player, hostiles, ray) -> void:
	var anchor_profile := AnchorProfileFixture.new()
	var runtime := CompanionGuardianPulseRuntime.new()
	runtime.bind_map(world, player, anchor_profile, ray, hostiles, Callable(self, "_has_no_upgrade"), Callable(anchor_profile, "has_capability"))
	ray.apply_identity(anchor_profile.companion_report().get("individual", {}))
	_expect(runtime.actions("independent_palette").is_empty() and runtime.actions("mounted_hotbar").is_empty(), "Anchor-Fins Kite received a combat action")


func _defeat_with_shock(world, player, hostiles, shock, oxygen, day) -> Dictionary:
	var health_steps: Array[int] = []
	var last := {}
	for expected_health in [2, 1, 0]:
		var position: Vector2 = hostiles.state_for(HOSTILE_ID).get("position", Vector2.ZERO)
		player.global_position = position + Vector2(-60.0, 0.0)
		last = shock.try_attack(hostiles, world, player.global_position, 1.0, true, false)
		health_steps.append(int(last.get("health", -1)))
		_expect(bool(last.get("connected", false)) and int(last.get("health", -1)) == expected_health, "Shock Prod hit sequence drifted: %s" % last)
		_advance_pressure(oxygen, day, 0.7)
		shock.update(0.7)
	_expect(bool(last.get("defeated", false)) and hostiles.state_for(HOSTILE_ID).get("phase") == "defeated", "three Shock Prod hits did not defeat the eel")
	return {"health_steps": health_steps, "result": last.get("reason"), "defeated": last.get("defeated")}

func _dispatch_command(sortie, action_id: String) -> Dictionary:
	var control = sortie.control_runtime()
	var commands: Array = control.begin_command_mode().get("context_commands", [])
	for index in range(commands.size()):
		if str((commands[index] as Dictionary).get("id", "")) == action_id:
			return control.activate_context_command(index)
	control.end_command_mode()
	return {"changed": false, "reason": "command_missing", "action_id": action_id}


func _place_pair(player, companion, position: Vector2) -> void:
	if companion == null:
		_expect(false, "active companion was unavailable")
		return
	companion.set_physics_process(false)
	if companion.has_method("set_external_control_active"):
		companion.set_external_control_active(true)
	companion.global_position = position
	player.global_position = position
	if companion.has_method("set_external_control_active"):
		companion.set_external_control_active(false)
	if companion.has_method("advance"):
		companion.advance(0.0)


func _advance_pressure(oxygen, day, seconds: float) -> void:
	oxygen.drain_oxygen(seconds)
	day.advance_daylight(seconds)


func _adaptation_for(profile, individual_id: String) -> String:
	for individual in profile.companion_report().get("individuals", []):
		if str((individual as Dictionary).get("individual_id", "")) == individual_id:
			return str((individual as Dictionary).get("selected_adaptation_id", ""))
	return ""


func _access_snapshot(world) -> Dictionary:
	return {"parity": world.get_runtime_parity_report(), "gates": world.get_current_gates()}


func _progression_snapshot(profile) -> Dictionary:
	var report: Dictionary = profile.report()
	return {
		"discoveries": report.get("completed_discoveries", []).duplicate(),
		"capabilities": report.get("unlocked_capabilities", []).duplicate(),
		"projects": report.get("completed_projects", []).duplicate(),
		"targets": report.get("banked_tool_target_ids", []).duplicate(),
		"materials": (report.get("material_inventory", {}) as Dictionary).duplicate(true),
		"companions": profile.companion_report(),
	}


func _progression_except_materials(profile) -> Dictionary:
	var snapshot := _progression_snapshot(profile)
	snapshot.erase("materials")
	snapshot.erase("companions")
	return snapshot


func _progression_except_materials_from(snapshot: Dictionary) -> Dictionary:
	var value := snapshot.duplicate(true)
	value.erase("materials")
	value.erase("companions")
	return value


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str((record as Dictionary).get("id", "")) == record_id:
			return (record as Dictionary).duplicate(true)
	return {}


func _build_world(path: String):
	var world = WORLD_SCENE.instantiate()
	world.map_path = path
	get_root().add_child(world)
	world.load_greybox()
	return world


func _record_status(note: String) -> void:
	if not note.is_empty():
		_status_notes.append(note)


func _control_allowed() -> bool:
	return true


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish(world, connector_world, player, sortie, original_time_scale: float, evidence: Dictionary) -> void:
	Engine.time_scale = original_time_scale
	if sortie != null:
		sortie.clear_map()
		sortie.queue_free()
	if player != null:
		player.queue_free()
	if connector_world != null:
		connector_world.queue_free()
	if world != null:
		world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Living Expedition 04 journey smoke failed: %s" % failure)
		quit(1)
		return
	var hostile: Dictionary = evidence.get("hostile", {})
	print("PASS: Living Expedition 04 journey checkpoint=%s relationship=%s active=%s:drift_lens>%s:guardian_pulse hostile=%s phase=%s position=%s health=%d/3 mica=%s guardian=%s shock=%s cargo={full:%s held_after_harvest:%d banked_electrocyte:%d} failure={retry_restored:%d connector_preserved:%s map_reload_preserved:%s fresh_day:restored} cache_collected=%s anchor_combat=false oxygen=%.2f daylight=%.2f day=%d." % [
		CHECKPOINT_ID,
		RELATIONSHIP_ID,
		MICA_ID,
		KITE_ID,
		HOSTILE_ID,
		str(hostile.get("phase", "")),
		str(hostile.get("position", Vector2.ZERO)),
		int(hostile.get("health", 0)),
		str(evidence.get("mica", {})),
		str(evidence.get("guardian", {})),
		str(evidence.get("shock_banked", {})),
		str(evidence.get("cargo_full", {})),
		int(evidence.get("held_after_harvest", 0)),
		int(evidence.get("banked_electrocyte", 0)),
		int(evidence.get("retry_restored_count", 0)),
		str(evidence.get("connector_preserved", false)),
		str(evidence.get("map_reload_preserved", false)),
		str(evidence.get("cache_collected", true)),
		float(evidence.get("oxygen", 0.0)),
		float(evidence.get("daylight", 0.0)),
		int(evidence.get("day", 0)),
	])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
