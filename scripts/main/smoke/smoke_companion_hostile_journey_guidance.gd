extends SceneTree

const CompanionJourneyGuidance := preload("res://scripts/companion/companion_journey_guidance.gd")

var _failures: Array[String] = []


class FakeWorld:
	extends RefCounted
	var at_boat := false

	func is_inside_boat(_position: Vector2) -> bool:
		return at_boat

	func get_companion_hostile_responses() -> Array:
		return [{
			"id": "deep_cache_eel_companion_response",
			"hostile_id": "deep_cache_territorial_eel",
			"responses": [
				{
					"species_id": "spark_ray",
					"individual_id": "spark_ray_juvenile_01",
					"required_adaptation_id": "guardian_pulse",
				},
			],
		}]

	func get_ecological_traces() -> Array:
		return []


class FakeProfile:
	extends RefCounted
	var value := {}

	func companion_report() -> Dictionary:
		return value.duplicate(true)


class FakeSortie:
	extends RefCounted
	var live_companion
	var report_value := {}

	func companion():
		return live_companion

	func memory_report() -> Dictionary:
		return {"pending_memory_ids": [], "ecology": {}}

	func control_runtime():
		return self

	func report() -> Dictionary:
		return report_value.duplicate(true)


class DayState:
	extends RefCounted
	var phase := "active"
	var sortie_count := 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := FakeWorld.new()
	var profile := FakeProfile.new()
	var sortie := FakeSortie.new()
	var player := Node2D.new()
	var guidance := CompanionJourneyGuidance.new()
	var mica := _individual("veil_cuttle_juvenile_01", "veil_cuttle", "Mica", "drift_lens")
	var kite := _individual("spark_ray_juvenile_01", "spark_ray", "Kite", "guardian_pulse")

	profile.value = _profile_report(mica, [kite, mica])
	world.at_boat = true
	_expect(
		guidance.objective_text(world, player, profile, sortie, DayState.new()).contains("TOOL picks Kite for Guardian Pulse"),
		"boat guidance did not identify Kite as the active eel response"
	)

	world.at_boat = false
	sortie.live_companion = RefCounted.new()
	sortie.report_value = {"control": {"command_mode": false, "drift_lens": {"projection_seconds": 0.0}}}
	var mica_text := guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(
		mica_text.contains("Near moving jellyfish")
		and mica_text.contains("Read Drift")
		and not mica_text.contains("eel")
		and not mica_text.contains("Predict Lunge"),
		"Mica guidance still presented an eel solution instead of moving ecology"
	)

	profile.value = _profile_report(kite, [kite, mica])
	sortie.report_value = {
		"control": {"command_mode": false, "mounted": false},
		"presentation": {"guardian_opening": false},
	}
	var kite_text := guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(kite_text.contains("B, then 3 during WARNING/LUNGE") and kite_text.contains("No damage"), "Kite guidance did not explain the timed non-damaging action")

	sortie.report_value["presentation"] = {"guardian_opening": true, "guardian_opening_seconds": 1.1}
	var opening_text := guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(opening_text.contains("1.1s opening") and opening_text.contains("attempt cache"), "Kite opening did not present the player's immediate choices")

	sortie.report_value = {
		"control": {"command_mode": false, "mounted": true},
		"presentation": {"guardian_opening": false},
	}
	var mounted_text := guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(mounted_text.contains("Space/USE during WARNING/LUNGE") and not mounted_text.contains(" Q "), "mounted Kite guidance drifted from current controls")

	var anchor := _individual("spark_ray_juvenile_01", "spark_ray", "Kite", "anchor_fins")
	profile.value = _profile_report(anchor, [anchor, mica])
	sortie.report_value = {"control": {"command_mode": false, "mounted": false}}
	var anchor_text := guidance.objective_text(world, player, profile, sortie, DayState.new())
	_expect(anchor_text.contains("Anchor Fins ready") and not anchor_text.contains("Deep Cache Eel"), "Anchor Fins inherited the LE04 combat path")

	player.free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Companion-hostile journey guidance smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: companion-hostile journey guidance boat=Kite_Guardian_Pulse Mica=ecology_only+no_eel_solution Kite=warning_or_lunge+opening+no_damage mounted=Space_USE Anchor=isolated.")
	quit(0)


func _individual(individual_id: String, species_id: String, callsign: String, adaptation_id: String) -> Dictionary:
	return {
		"individual_id": individual_id,
		"species_id": species_id,
		"callsign": callsign,
		"selected_adaptation_id": adaptation_id,
		"earned_memory_ids": ["followed_the_bloom"] if species_id == "veil_cuttle" else ["stood_ground"],
	}


func _profile_report(active: Dictionary, individuals: Array) -> Dictionary:
	return {
		"rescue_committed": true,
		"active_individual_id": active.get("individual_id", ""),
		"individual": active.duplicate(true),
		"individuals": individuals.duplicate(true),
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
