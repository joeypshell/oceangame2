extends "res://scripts/main/smoke/smoke_check_base.gd"

const INTERACTION_PARTIAL_RATIO := 0.25
const EXPECTED_PRIORITIES := {
	"salvage_pickup": "normal",
	"material_pickup": "normal",
	"salvage_bank": "normal",
	"oxygen_low": "medium",
	"oxygen_critical": "high",
	"oxygen_failure": "high",
	"hazard_warning": "medium",
	"hazard_contact": "high",
	"upgrade_purchase": "normal",
}


func _smoke_feedback_cues_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("Feedback cue smoke loaded unexpected map: %s." % _world.map_id)
		return
	if _main._audio_cues == null or not _main._audio_cues.has_method("event_log"):
		_fail("Feedback cue smoke requires audio cue event logging.")
		return
	if not _verify_locked_web_contract() or not _verify_priorities():
		return

	_main._audio_cues.clear_event_log()
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false

	var materials := _active_materials()
	var instant_targets := _instant_salvage_targets()
	var timed_target := _first_salvage_with_interaction("timed_salvage")
	var pry_target := _first_salvage_with_interaction("pry_salvage")
	var hazard := _first_static_hazard()
	if materials.size() < 3 or instant_targets.size() < 2 or timed_target.is_empty() or pry_target.is_empty() or hazard.is_empty():
		_fail("Feedback cue smoke requires three materials, two instant salvage targets, timed/pry targets, and a static hazard.")
		return

	var starting_sorties: int = _main._expedition_day_state.sortie_count
	var proximity_probe := _outside_material_probe(materials[0])
	if proximity_probe.is_empty():
		_fail("Feedback cue smoke could not place a no-collection material proximity probe.")
		return
	_player.global_position = proximity_probe["position"]
	_process(0.0)
	if _main._held_cargo_count() != 0 or not _main._audio_cues.event_log().is_empty():
		_fail("Feedback cue smoke emitted pickup audio from proximity without collection.")
		return

	var first_material: Dictionary = materials[0]
	var first_material_id := str(first_material.get("id", "material"))
	_player.global_position = first_material["center"]
	_process(0.0)
	var first_events: Array[Dictionary] = _main._audio_cues.event_log()
	if _main._material_runtime.held_count() != 1 or first_events.size() != 1:
		_fail("Feedback cue smoke first material did not produce exactly one event; held=%d events=%s." % [_main._material_runtime.held_count(), first_events])
		return
	if str(first_events[0].get("cue_id", "")) != "material_pickup" or str(first_events[0].get("dedupe_key", "")) != first_material_id:
		_fail("Feedback cue smoke first event did not identify material %s: %s." % [first_material_id, first_events[0]])
		return
	_process(0.0)
	if _cue_count("material_pickup") != 1:
		_fail("Feedback cue smoke repeated the first material cue while remaining in range.")
		return

	var first_salvage: Dictionary = instant_targets[0]
	var first_salvage_id := str(first_salvage.get("id", "salvage"))
	_player.global_position = first_salvage["center"]
	_process(0.0)
	if _held_salvage != 1 or _cue_count("salvage_pickup") != 1:
		_fail("Feedback cue smoke could not collect first-sortie salvage %s exactly once." % first_salvage_id)
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _main._material_runtime.held_count() != 0 or _cue_count("salvage_bank") != 1:
		_fail("Feedback cue smoke first offload did not clear cargo and emit one bank cue.")
		return
	if _main._expedition_day_state.sortie_count != starting_sorties + 1:
		_fail("Feedback cue smoke first lifecycle did not count exactly one sortie.")
		return

	var second_material: Dictionary = materials[1]
	var second_material_id := str(second_material.get("id", "material"))
	_player.global_position = second_material["center"]
	_process(0.0)
	if _main._material_runtime.held_count() != 1 or _cue_count("material_pickup") != 2:
		_fail("Feedback cue smoke second sortie did not collect material %s exactly once." % second_material_id)
		return
	var second_salvage: Dictionary = instant_targets[1]
	var second_salvage_id := str(second_salvage.get("id", "salvage"))
	_player.global_position = second_salvage["center"]
	_process(0.0)
	if _held_salvage != 1 or _cue_count("salvage_pickup") != 2:
		_fail("Feedback cue smoke second sortie did not collect salvage %s exactly once." % second_salvage_id)
		return

	var blocked_material: Dictionary = materials[2]
	var blocked_material_id := str(blocked_material.get("id", "material"))
	_player.global_position = blocked_material["center"]
	_process(0.0)
	var blocked_source: Dictionary = _world.get_material_candidate_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
	if _cue_count("material_pickup") != 2 or str(blocked_source.get("id", "")) != blocked_material_id:
		_fail("Feedback cue smoke cargo-full attempt emitted audio or removed material %s." % blocked_material_id)
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _cue_count("salvage_bank") != 2 or _main._expedition_day_state.sortie_count != starting_sorties + 2:
		_fail("Feedback cue smoke second offload did not repeat the bank/sortie lifecycle exactly once.")
		return

	var pickup_count_before_cancel := _cue_count("salvage_pickup")
	if not _verify_canceled_interaction(timed_target, "timed_salvage", pickup_count_before_cancel):
		return
	if not _verify_canceled_interaction(pry_target, "pry_salvage", pickup_count_before_cancel):
		return

	_main._reset_oxygen_feedback_cues()
	_player.global_position = _hazard_warning_probe_position(hazard["center"])
	_process(0.0)
	_oxygen_seconds = _main.OXYGEN_LOW_WARNING_SECONDS + 1.0
	_process(2.0)
	_oxygen_seconds = _main.OXYGEN_CRITICAL_WARNING_SECONDS + 1.0
	_process(2.0)
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed:
		_fail("Feedback cue smoke did not trigger oxygen failure.")
		return

	_reset_run()
	_combat_interactions_enabled = false
	var warning_position := _hazard_warning_probe_position(hazard["center"])
	var warning_hazard: Dictionary = _world.get_nearest_hazard_within(warning_position, HAZARD_WARNING_RADIUS)
	if warning_hazard.is_empty() or not _world.get_hazard_near(warning_position, HAZARD_CONTACT_RADIUS).is_empty():
		_fail("Feedback cue smoke could not find a warning-only hazard probe.")
		return
	_player.global_position = warning_position
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _hazard_warning_id.is_empty():
		_fail("Feedback cue smoke did not enter hazard warning state.")
		return
	_player.global_position = warning_hazard["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _player.global_position.distance_to(_world.spawn_position) > 2.0:
		_fail("Feedback cue smoke hazard contact did not reset player to spawn.")
		return

	var expected_counts := {
		"material_pickup": 2,
		"salvage_pickup": 2,
		"salvage_bank": 2,
		"oxygen_low": 1,
		"oxygen_critical": 1,
		"oxygen_failure": 1,
		"hazard_warning": 1,
		"hazard_contact": 1,
	}
	var counts := _cue_counts()
	if counts != expected_counts:
		_fail("Feedback cue smoke event counts changed; expected=%s actual=%s." % [expected_counts, counts])
		return

	print("Feedback cue smoke passed: first_material=%s second_material=%s first_salvage=%s second_salvage=%s blocked=%s canceled=timed+pry cargo_sorties=2 web_lock=no_stale_replay cue_counts=%s priorities=stable." % [
		first_material_id,
		second_material_id,
		first_salvage_id,
		second_salvage_id,
		blocked_material_id,
		counts,
	])
	get_tree().quit()


func _verify_locked_web_contract() -> bool:
	var cues = _main._audio_cues
	var original_available = cues.get("_playback_available")
	var original_requires_unlock = cues.get("_requires_user_unlock")
	var original_unlocked = cues.get("_playback_unlocked")
	cues.clear_event_log()
	cues.set("_playback_available", true)
	cues.set("_requires_user_unlock", true)
	cues.set("_playback_unlocked", false)
	cues.play_cue("material_pickup", "web_lock_probe")
	var locked_events: Array[Dictionary] = cues.event_log()
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_SPACE
	cues.unlock_from_event(key_event)
	var unlocked := bool(cues.get("_playback_unlocked"))
	var event_count_after_unlock: int = cues.event_log().size()
	cues.set("_playback_available", original_available)
	cues.set("_requires_user_unlock", original_requires_unlock)
	cues.set("_playback_unlocked", original_unlocked)
	cues.clear_event_log()
	if locked_events.size() != 1 or str(locked_events[0].get("reason", "")) != "audio_locked":
		_fail("Feedback cue smoke Web-lock probe did not record one audio_locked event: %s." % locked_events)
		return false
	if not unlocked or event_count_after_unlock != 1:
		_fail("Feedback cue smoke Web unlock replayed or duplicated a stale cue; events=%d." % event_count_after_unlock)
		return false
	return true


func _verify_priorities() -> bool:
	for cue_id in EXPECTED_PRIORITIES:
		var actual := str(_main._audio_cues.priority_for(cue_id))
		var expected := str(EXPECTED_PRIORITIES[cue_id])
		if actual != expected:
			_fail("Feedback cue smoke priority changed for %s: expected=%s actual=%s." % [cue_id, expected, actual])
			return false
	return true


func _verify_canceled_interaction(target: Dictionary, interaction: String, pickup_count: int) -> bool:
	if interaction == "timed_salvage" and not _prepare_guarded_salvage_access(target):
		_fail("Feedback cue smoke could not prepare guarded timed target.")
		return false
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false
	var target_id := str(target.get("id", "salvage"))
	var target_center: Vector2 = target["center"]
	var partial_seconds := maxf(0.01, float(target.get("interaction_seconds", 0.0)) * INTERACTION_PARTIAL_RATIO)
	_player.global_position = target_center
	_process(0.0)
	_process(partial_seconds)
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _world.is_salvage_collected(target_id) or _held_salvage_ids.has(target_id) or _cue_count("salvage_pickup") != pickup_count:
		_fail("Feedback cue smoke canceled %s interaction emitted pickup audio or collected %s." % [interaction, target_id])
		return false
	return true


func _cue_count(cue_id: String) -> int:
	return int(_cue_counts().get(cue_id, 0))


func _cue_counts() -> Dictionary:
	var counts := {}
	for event in _main._audio_cues.event_log():
		var cue_id := str(event.get("cue_id", ""))
		if not cue_id.is_empty():
			counts[cue_id] = int(counts.get(cue_id, 0)) + 1
	return counts


func _active_materials() -> Array:
	var active_ids: Array = _world.get_material_candidate_report().get("active_ids", [])
	var values: Array = []
	for candidate in _world.get_material_candidates():
		if active_ids.has(str(candidate.get("id", ""))):
			values.append(candidate)
	return values


func _instant_salvage_targets() -> Array:
	var values: Array = []
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			values.append(salvage)
	return values


func _first_salvage_with_interaction(interaction: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == interaction:
			return salvage
	return {}


func _outside_material_probe(material: Dictionary) -> Dictionary:
	var center: Vector2 = material["center"]
	var distance := SALVAGE_COLLECTION_RADIUS + 4.0
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]
	for direction in directions:
		var position := center + direction * distance
		if not _world.get_material_candidate_near(position, SALVAGE_COLLECTION_RADIUS).is_empty():
			continue
		if not _world.get_available_salvage_near(position, SALVAGE_COLLECTION_RADIUS).is_empty():
			continue
		return {"position": position}
	return {}


func _first_static_hazard() -> Dictionary:
	for hazard in _world.get_hazard_centers():
		if str(hazard.get("id", "")) != "deep_route_jellyfish_patrol":
			return hazard
	return {}


func _hazard_warning_probe_position(hazard_center: Vector2) -> Vector2:
	var warning_distance := HAZARD_CONTACT_RADIUS + 8.0
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]
	for direction in directions:
		var candidate: Vector2 = hazard_center + direction * warning_distance
		if _world.get_hazard_near(candidate, HAZARD_CONTACT_RADIUS).is_empty() and not _world.get_nearest_hazard_within(candidate, HAZARD_WARNING_RADIUS).is_empty():
			return candidate
	return hazard_center + Vector2.RIGHT * warning_distance


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
