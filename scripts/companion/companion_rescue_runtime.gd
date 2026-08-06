extends Node

const SPARK_RAY_SCENE := preload("res://scenes/companion/SparkRayCompanion.tscn")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")

const RELEASE_SECONDS := 1.4
const DEFAULT_CALLSIGN := "Kite"
const AVAILABLE := "available"
const RELEASING := "releasing"
const PENDING := "pending"
const COMMITTED := "committed"

var _world
var _player
var _profile
var _has_upgrade := Callable()
var _has_capability := Callable()
var _interaction_radius := 34.0
var _active_rescue := {}
var _pending_rescue := {}
var _release_progress := 0.0
var _holding_use := false
var _pending_companion
var _gate_access := CurrentGateController.new()


func bind_map(
	world,
	player,
	profile,
	has_upgrade: Callable,
	has_capability: Callable,
	interaction_radius: float
) -> Dictionary:
	clear_map("map_changed")
	_world = world
	_player = player
	_profile = profile
	_has_upgrade = has_upgrade
	_has_capability = has_capability
	_interaction_radius = maxf(1.0, interaction_radius)
	var committed := _profile_has_committed_companion()
	for rescue in _source_rescues():
		_set_source_state(str(rescue.get("id", "")), COMMITTED if committed else AVAILABLE)
	return report()


func target_near() -> Dictionary:
	if not _dependencies_valid() or _profile_has_committed_companion() or not _pending_rescue.is_empty():
		return {}
	return _world.get_creature_rescue_near(_player.global_position, _interaction_radius)


func activate() -> Dictionary:
	if not _dependencies_valid():
		return _result("unavailable", "Rescue unavailable", false, "dependencies_unavailable")
	if _profile_has_committed_companion():
		return _result("unavailable", "Spark Ray bond already committed", false, "already_committed")
	if not _pending_rescue.is_empty():
		return _result("unavailable", _pending_note(), false, "pending_commit")
	var rescue := target_near()
	if rescue.is_empty():
		return _result("wrong_context", "No rescue cable in Cutter range", false, "wrong_context")
	var required_capability := str(rescue.get("required_capability_id", ""))
	if required_capability.is_empty() or not _capability_owned(required_capability):
		return _result("unavailable", "Trapped Spark Ray | Salvage Cutter required", false, "missing_capability")
	_active_rescue = rescue.duplicate(true)
	_holding_use = true
	_set_source_state(str(_active_rescue.get("id", "")), RELEASING)
	return _result("activated", _release_note(), true, "activated")


func update(delta: float) -> Dictionary:
	if not _pending_rescue.is_empty():
		return _result(PENDING, _pending_note(), false, "pending_commit")
	if not _holding_use or _active_rescue.is_empty():
		return {"state": "idle", "changed": false}
	var rescue_id := str(_active_rescue.get("id", ""))
	var nearby := target_near()
	if str(nearby.get("id", "")) != rescue_id:
		return cancel_interaction("out_of_range")
	var required_capability := str(_active_rescue.get("required_capability_id", ""))
	if not _capability_owned(required_capability):
		return cancel_interaction("missing_capability")
	_release_progress = minf(RELEASE_SECONDS, _release_progress + maxf(0.0, delta))
	if _release_progress < RELEASE_SECONDS:
		return _result(RELEASING, _release_note(), true, "progress")
	_pending_rescue = _active_rescue.duplicate(true)
	_active_rescue = {}
	_holding_use = false
	_release_progress = 0.0
	_set_source_state(rescue_id, PENDING)
	_spawn_pending_companion()
	return _result("complete", _pending_note(), true, "released")


func release_use() -> Dictionary:
	if not _holding_use or _active_rescue.is_empty():
		return {"state": "idle", "changed": false, "reason": "idle"}
	return cancel_interaction("released_early")


func cancel_interaction(reason := "canceled") -> Dictionary:
	if _active_rescue.is_empty():
		_holding_use = false
		_release_progress = 0.0
		return {"state": "idle", "changed": false, "reason": reason}
	var rescue_id := str(_active_rescue.get("id", ""))
	_active_rescue = {}
	_holding_use = false
	_release_progress = 0.0
	_set_source_state(rescue_id, AVAILABLE)
	return _result("canceled", "Cable release interrupted", true, reason)


func commit_at_boat() -> Dictionary:
	if _pending_rescue.is_empty() or not _dependencies_valid():
		return {"changed": false, "reason": "no_pending_rescue"}
	if str(_world.map_id) != str(_pending_rescue.get("commit_map_id", "")):
		return {"changed": false, "reason": "wrong_commit_map"}
	var commit_entry_id := str(_pending_rescue.get("commit_entry_id", ""))
	if commit_entry_id.is_empty():
		return {"changed": false, "reason": "missing_commit_entry"}
	if not _world.has_method("get_entry_position") or not _world.is_inside_boat(_world.get_entry_position(commit_entry_id)):
		return {"changed": false, "reason": "invalid_commit_entry"}
	if not _world.is_inside_boat(_player.global_position):
		return {"changed": false, "reason": "not_at_commit_destination"}
	var rescue_id := str(_pending_rescue.get("id", ""))
	var result: Dictionary = _profile.commit_companion_rescue(
		str(_pending_rescue.get("individual_id", "")),
		str(_pending_rescue.get("species_id", "")),
		str(_pending_rescue.get("callsign", DEFAULT_CALLSIGN)),
		true
	)
	if not bool(result.get("changed", false)):
		result["note"] = "Spark Ray bond could not be committed"
		return result
	_pending_rescue = {}
	_free_pending_companion()
	_set_source_state(rescue_id, COMMITTED)
	result["note"] = "PARTNER: %s bonded | Press N at the boat to end the day | %s joins next dive" % [DEFAULT_CALLSIGN, DEFAULT_CALLSIGN]
	result["commit_entry_id"] = commit_entry_id
	return result


func reset_for_failure(reason := "failure") -> Dictionary:
	var canceled: Dictionary = cancel_interaction(reason)
	if _pending_rescue.is_empty():
		return canceled
	var rescue_id := str(_pending_rescue.get("id", ""))
	_pending_rescue = {}
	_free_pending_companion()
	_set_source_state(rescue_id, AVAILABLE)
	return {"changed": true, "reason": reason, "restored_rescue_id": rescue_id}


func clear_map(reason := "scene_exit") -> void:
	cancel_interaction(reason)
	if not _pending_rescue.is_empty():
		_set_source_state(str(_pending_rescue.get("id", "")), AVAILABLE)
	_pending_rescue = {}
	_free_pending_companion()
	_world = null
	_player = null
	_profile = null
	_has_upgrade = Callable()
	_has_capability = Callable()


func prompt() -> String:
	if not _pending_rescue.is_empty():
		return _pending_note()
	if _holding_use and not _active_rescue.is_empty():
		return _release_note()
	var rescue := target_near()
	if rescue.is_empty():
		return ""
	var required_capability := str(rescue.get("required_capability_id", ""))
	if not _capability_owned(required_capability):
		return "Trapped Spark Ray | Salvage Cutter required"
	return "Trapped Spark Ray | Tab Cutter | Hold Space/USE"


func pending_companion():
	return _pending_companion if _pending_companion != null and is_instance_valid(_pending_companion) else null


func report() -> Dictionary:
	return {
		"active_rescue_id": str(_active_rescue.get("id", "")),
		"pending_rescue_id": str(_pending_rescue.get("id", "")),
		"holding_use": _holding_use,
		"release_seconds": RELEASE_SECONDS,
		"release_progress_seconds": _release_progress,
		"release_progress": clampf(_release_progress / RELEASE_SECONDS, 0.0, 1.0),
		"pending_companion_spawned": pending_companion() != null,
		"profile_committed": _profile_has_committed_companion(),
	}


func _spawn_pending_companion() -> void:
	_free_pending_companion()
	if not _dependencies_valid():
		return
	_pending_companion = SPARK_RAY_SCENE.instantiate()
	get_parent().add_child(_pending_companion)
	_pending_companion.configure(
		_world,
		_player,
		Callable(self, "_position_allowed"),
		{
			"individual_id": str(_pending_rescue.get("individual_id", "")),
			"species_id": str(_pending_rescue.get("species_id", "")),
			"callsign": str(_pending_rescue.get("callsign", DEFAULT_CALLSIGN)),
			"rescue_committed": false,
			"earned_memory_ids": [],
			"selected_adaptation_id": "",
		}
	)
	_pending_companion.global_position = _pending_rescue.get("center", _player.global_position)
	_pending_companion.show_context_response("rescue_memory", _player.global_position)


func _free_pending_companion() -> void:
	if _pending_companion != null and is_instance_valid(_pending_companion):
		if _pending_companion.get_parent() != null:
			_pending_companion.get_parent().remove_child(_pending_companion)
		_pending_companion.queue_free()
	_pending_companion = null


func _position_allowed(position: Vector2) -> bool:
	if not _dependencies_valid():
		return false
	return _gate_access.gate_blocks_position(
		_world,
		position,
		_has_upgrade,
		_has_capability
	).is_empty()


func _source_rescues() -> Array:
	if _world == null or not _world.has_method("get_creature_rescues"):
		return []
	return _world.get_creature_rescues()


func _set_source_state(rescue_id: String, state: String) -> void:
	if not rescue_id.is_empty() and _world != null and _world.has_method("set_creature_rescue_state"):
		_world.set_creature_rescue_state(rescue_id, state)


func _capability_owned(capability_id: String) -> bool:
	return not capability_id.is_empty() and _has_capability.is_valid() and bool(_has_capability.call(capability_id))


func _profile_has_committed_companion() -> bool:
	return _profile != null and _profile.has_method("has_committed_companion") and bool(_profile.has_committed_companion())


func _dependencies_valid() -> bool:
	return (
		get_parent() != null
		and _world != null
		and is_instance_valid(_world)
		and _player != null
		and is_instance_valid(_player)
		and _profile != null
		and _profile.has_method("commit_companion_rescue")
	)


func _release_note() -> String:
	return "Freeing Spark Ray | Cable %d%% | hold Space/USE" % int(round(100.0 * clampf(_release_progress / RELEASE_SECONDS, 0.0, 1.0)))


func _pending_note() -> String:
	return "PARTNER: Kite is free | Return together to the yellow surface boat"


func _result(state: String, note: String, changed: bool, reason: String) -> Dictionary:
	return {
		"state": state,
		"status": "used" if state in ["activated", RELEASING, "complete"] else "wrong_context" if state == "wrong_context" else "unavailable",
		"note": note,
		"changed": changed,
		"reason": reason,
		"report": report(),
	}
