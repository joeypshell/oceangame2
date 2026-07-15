extends SceneTree

const PressureZoneController := preload("res://scripts/main/pressure_zone_controller.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")
const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const ZONE_ID := "abyssal_basin_pressure_zone"
const TARGET_ID := "abyssal_basin_harmonic_source_survey"
const PRESSURE_SUIT_ID := "pressure_suit_1"
const BASE_OXYGEN_SECONDS := 90.0
const OPTIONAL_OXYGEN_SECONDS := 105.0
const PROTECTED_JOURNEY_SECONDS := 58.8
const PRESSURE_EXPOSURE_SECONDS := 11.0

var _failures: Array[String] = []


class CapabilityFixture:
	extends RefCounted
	var unlocked := {}

	func has_capability(capability_id: String) -> bool:
		return capability_id.is_empty() or bool(unlocked.get(capability_id, false))

	func unlock(capability_id: String) -> void:
		unlocked[capability_id] = true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	world.load_greybox()
	var zone: Dictionary = world.get_marker_zone(ZONE_ID)
	var target := _target_by_id(world, TARGET_ID)
	_expect(not zone.is_empty(), "source-authored pressure zone was missing")
	_expect(not target.is_empty(), "source-authored abyssal target was missing")
	if zone.is_empty() or target.is_empty():
		_finish(world, {})
		return

	var profile := CapabilityFixture.new()
	var controller := PressureZoneController.new()
	controller.on_map_loaded(world)
	var inside: Vector2 = target.get("center", Vector2.ZERO)
	var outside: Vector2 = world.spawn_position
	var warning: Dictionary = controller.update(inside, Callable(profile, "has_capability"), 0.5)
	_expect(warning.get("note") == "Abyssal pressure | Retreat", "pressure grace warning drifted")
	_expect(is_equal_approx(float(warning.get("drain_multiplier", 0.0)), 1.0), "grace did not retain normal drain")

	var oxygen := SortieState.new(10.0)
	_expect(not oxygen.drain_oxygen(0.5, float(warning.get("drain_multiplier", 1.0))), "warning drain exhausted oxygen")
	var grace_boundary: Dictionary = controller.update(inside, Callable(profile, "has_capability"), 0.5)
	_expect(grace_boundary.get("note") == "Abyssal pressure | Retreat", "grace ended before its authored second")
	_expect(not oxygen.drain_oxygen(0.5, float(grace_boundary.get("drain_multiplier", 1.0))), "grace-boundary drain exhausted oxygen")
	var critical: Dictionary = controller.update(inside, Callable(profile, "has_capability"), 0.1)
	var source_multiplier := float(zone.get("unprotected_oxygen_drain_multiplier", 0.0))
	_expect(critical.get("note") == "Pressure critical | Oxygen x8", "critical pressure feedback drifted")
	_expect(is_equal_approx(float(critical.get("drain_multiplier", 0.0)), source_multiplier), "controller ignored source drain multiplier")
	_expect(not oxygen.drain_oxygen(0.1, float(critical.get("drain_multiplier", 1.0))), "focused pressure drain exhausted fixture oxygen too early")
	_expect(is_equal_approx(oxygen.oxygen_seconds, 8.2), "SortieState did not own multiplied oxygen drain")
	_expect(not critical.has("oxygen_seconds") and not critical.has("health"), "pressure controller owned oxygen or health state")

	controller.update(outside, Callable(profile, "has_capability"), 0.0)
	var reentered: Dictionary = controller.update(inside, Callable(profile, "has_capability"), 0.1)
	_expect(reentered.get("note") == "Abyssal pressure | Retreat", "leaving pressure zone did not reset grace")
	_expect(float(reentered.get("exposure_seconds", 0.0)) < float(zone.get("warning_grace_seconds", 0.0)), "re-entry retained old exposure")

	profile.unlock(PRESSURE_SUIT_ID)
	controller.update(outside, Callable(profile, "has_capability"), 0.0)
	var protected_entry: Dictionary = controller.update(inside, Callable(profile, "has_capability"), 0.0)
	_expect(protected_entry.get("note") == "Pressure suit active", "protected entry feedback drifted")
	_expect(is_equal_approx(float(protected_entry.get("drain_multiplier", 0.0)), 1.0), "pressure suit did not restore normal drain")
	var protected_settled: Dictionary = controller.update(inside, Callable(profile, "has_capability"), 2.0)
	_expect(str(protected_settled.get("note", "")).is_empty(), "protected entry feedback did not clear contextually")

	var grace_seconds := float(zone.get("warning_grace_seconds", 0.0))
	var pressure_after_grace := maxf(0.0, PRESSURE_EXPOSURE_SECONDS - grace_seconds)
	var non_pressure_seconds := PROTECTED_JOURNEY_SECONDS - PRESSURE_EXPOSURE_SECONDS
	var unprotected := SortieState.new(OPTIONAL_OXYGEN_SECONDS)
	unprotected.drain_oxygen(non_pressure_seconds + grace_seconds)
	var unprotected_failed := unprotected.drain_oxygen(pressure_after_grace, source_multiplier)
	_expect(unprotected_failed, "optional O2 +15 completed the contracted unprotected journey")
	var protected := SortieState.new(BASE_OXYGEN_SECONDS)
	var protected_failed := protected.drain_oxygen(PROTECTED_JOURNEY_SECONDS)
	_expect(not protected_failed, "pressure suit failed the contracted base-tank journey")
	_expect(protected.oxygen_seconds >= 30.0, "protected journey lost useful return margin")

	_finish(world, {
		"warning": warning.get("note", ""),
		"multiplier": source_multiplier,
		"optional_failed": unprotected_failed,
		"protected_margin": protected.oxygen_seconds,
	})


func _target_by_id(world, target_id: String) -> Dictionary:
	for target in world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _finish(world, report: Dictionary) -> void:
	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Pressure zone state smoke failed: %s" % failure)
		quit(1)
		return
	print("Pressure zone state smoke passed: %s." % str(report))
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
