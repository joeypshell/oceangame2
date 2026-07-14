extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const BiologicalResourceController := preload("res://scripts/main/biological_resource_controller.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const SmokeProfileProjectFixture := preload("res://scripts/main/smoke/smoke_profile_project_fixture.gd")
const TerritorialHostileController := preload("res://scripts/main/territorial_hostile_controller.gd")

const SLICE_01 := "res://maps/production_slice_01.greybox.json"
const SLICE_04 := "res://maps/production_slice_04.greybox.json"
const PASSIVE_ID := "upper_right_glow_anemone_sample"
const HOSTILE_SOURCE_ID := "deep_cache_eel_electrocyte_harvest"
const HOSTILE_ID := ExpansionProfileState.SHOCK_PROD_TARGET_ID

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var world = _build_world(SLICE_01)
	_expect(bool(SmokeProfileProjectFixture.complete_scanner(profile, world).get("changed", false)), "scanner fixture did not build")
	var material_runtime := MaterialRuntimeController.new(profile)
	var biological := BiologicalResourceController.new(profile)
	var hostiles := TerritorialHostileController.new()
	var day := ExpeditionDayState.new()
	material_runtime.on_map_loaded(world, day)
	hostiles.on_map_loaded(world, false)
	biological.on_map_loaded(world, false)

	var sources: Array = world.get_biological_resource_sources()
	_expect(sources.size() == 2, "world did not expose the exact two biological sources")
	_expect(int(world.get_biological_resource_visual_report().get("rendered_count", 0)) == 2, "world did not render two biological sources")
	var passive := _source(sources, PASSIVE_ID)
	var passive_center: Vector2 = passive.get("center", Vector2.ZERO)
	var hostile_before: Dictionary = hostiles.state_for(HOSTILE_ID)

	var partial: Dictionary = biological.update(world, hostiles, material_runtime, passive_center, 34.0, 0.75, 0, 2)
	_expect(partial.get("state") == "progress" and material_runtime.held_count() == 0, "passive sample collected before its timer")
	biological.update(world, hostiles, material_runtime, Vector2.ZERO, 34.0, 0.1, 0, 2)
	_expect(is_zero_approx(float(biological.report().get("progress_seconds", -1.0))), "leaving range did not cancel passive progress")
	var sampled: Dictionary = biological.update(world, hostiles, material_runtime, passive_center, 34.0, 1.5, 0, 2)
	_expect(bool(sampled.get("collected", false)), "passive sample did not complete")
	_expect(material_runtime.held_quantities().get(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID, 0) == 1, "passive sample did not enter shared cargo")
	_expect(hostiles.state_for(HOSTILE_ID).get("health") == hostile_before.get("health"), "passive sample changed hostile health")
	_expect(world.get_biological_resource_visual_report().get("states", {}).get(PASSIVE_ID) == "depleted", "sampled passive organism did not remain as depleted nonlethal source")
	var passive_bank: Dictionary = material_runtime.try_commit_at_boat(world, world.get_extraction_center())
	_expect(bool(passive_bank.get("changed", false)) and profile.material_quantity(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID) == 1, "passive sample did not bank at canonical boat")

	var hostile_home: Vector2 = hostiles.state_for(HOSTILE_ID).get("position", Vector2.ZERO)
	var premature: Dictionary = biological.update(world, hostiles, material_runtime, hostile_home, 34.0, 2.0, 0, 2)
	_expect(not bool(premature.get("handled", false)) and material_runtime.held_count() == 0, "hostile material was available before defeat")
	for expected_health in [2, 1, 0]:
		var hit: Dictionary = hostiles.apply_weapon_hit(world, HOSTILE_ID, 1)
		_expect(int(hit.get("health", -1)) == expected_health, "base weapon fixture did not deal one damage")
	_expect(hostiles.state_for(HOSTILE_ID).get("phase") == "defeated", "hostile fixture did not reach defeated phase")
	_expect(profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID) == 0 and material_runtime.held_count() == 0, "hostile defeat granted an automatic material")

	var defeated_center: Vector2 = hostiles.state_for(HOSTILE_ID).get("position", Vector2.ZERO)
	var blocked: Dictionary = biological.update(world, hostiles, material_runtime, defeated_center, 34.0, 1.5, 2, 2)
	_expect(bool(blocked.get("blocked", false)) and not biological.is_collected(HOSTILE_SOURCE_ID), "cargo-full harvest depleted the hostile source")
	var harvested: Dictionary = biological.update(world, hostiles, material_runtime, defeated_center, 34.0, 1.5, 0, 2)
	_expect(bool(harvested.get("collected", false)), "explicit hostile harvest did not complete")
	_expect(material_runtime.held_quantities().get(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID, 0) == 1, "hostile harvest did not enter shared cargo")

	var relay = _build_world(SLICE_04)
	hostiles.on_map_loaded(relay, true)
	biological.on_map_loaded(relay, true)
	material_runtime.on_map_loaded(relay, day)
	_expect(material_runtime.held_count() == 1 and biological.report().get("collected_ids", []).has(HOSTILE_SOURCE_ID), "connector transition lost held harvest or day depletion")
	hostiles.on_map_loaded(world, true)
	biological.on_map_loaded(world, true)
	material_runtime.on_map_loaded(world, day)
	_expect(hostiles.state_for(HOSTILE_ID).get("phase") == "defeated" and biological.is_collected(HOSTILE_SOURCE_ID), "return connector lost hostile defeat or harvest depletion")

	hostiles.reset_for_failure(world)
	var restored: Dictionary = biological.restore_material_cargo(material_runtime, world, day, hostiles, "hazard")
	_expect(int(restored.get("restored_count", 0)) == 1 and material_runtime.held_count() == 0, "failure did not clear biological cargo")
	_expect(not biological.is_collected(HOSTILE_SOURCE_ID), "failure did not restore held hostile source")
	_expect(world.get_biological_resource_visual_report().get("states", {}).get(HOSTILE_SOURCE_ID) == "hidden", "restored hostile source appeared before re-defeat")

	for _index in range(3):
		hostiles.apply_weapon_hit(world, HOSTILE_ID, 1)
	defeated_center = hostiles.state_for(HOSTILE_ID).get("position", Vector2.ZERO)
	biological.update(world, hostiles, material_runtime, defeated_center, 34.0, 1.5, 0, 2)
	var hostile_bank: Dictionary = material_runtime.try_commit_at_boat(world, world.get_extraction_center())
	_expect(bool(hostile_bank.get("changed", false)) and profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID) == 1, "reharvested electrocyte did not bank")

	day.begin_next_day()
	hostiles.on_map_loaded(world, false)
	biological.on_map_loaded(world, false)
	material_runtime.on_map_loaded(world, day)
	_expect(biological.report().get("collected_ids", []).is_empty(), "fresh day did not replenish biological sources")
	_expect(hostiles.state_for(HOSTILE_ID).get("phase") == "home", "fresh day did not restore linked hostile")
	_expect(profile.material_quantity(ExpansionProfileState.INSULATING_GEL_MATERIAL_ID) == 1 and profile.material_quantity(ExpansionProfileState.EEL_ELECTROCYTE_MATERIAL_ID) == 1, "fresh day changed banked biological materials")

	world.queue_free()
	relay.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Biological resource state smoke failed: %s" % failure)
		quit(1)
		return
	print("Biological resource state smoke passed: passive=%s nonlethal=true timer=1.5 cancel_on_leave=true gel_banked=1 hostile=%s defeat_drop=none harvest=%s cargo_full_preserved=true connector_preserved=true failure_restored=true electrocyte_banked=1 new_day_replenished=true." % [PASSIVE_ID, HOSTILE_ID, HOSTILE_SOURCE_ID])
	quit(0)


func _build_world(path: String):
	var world = WORLD_SCENE.instantiate()
	world.map_path = path
	get_root().add_child(world)
	world.load_greybox()
	return world


func _source(sources: Array, source_id: String) -> Dictionary:
	for source in sources:
		if str(source.get("id", "")) == source_id:
			return source
	_failures.append("missing source %s" % source_id)
	return {"id": source_id, "center": Vector2.ZERO}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
