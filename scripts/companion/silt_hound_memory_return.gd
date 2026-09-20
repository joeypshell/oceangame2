extends RefCounted

const INDIVIDUAL_ID := "silt_hound_juvenile_01"
const MEMORY_ID := "guarded_the_nest"
const OPPORTUNITY_ID := "marl_guarded_nest_opportunity_01"
const REFUGE_ID := "deep_cache_burrow_refuge_01"

var _world
var _player
var _profile
var _pending := {}


func bind_map(world, player, profile) -> void:
	clear_map()
	_world = world
	_player = player
	_profile = profile
	project_secured(world, profile)


func clear_map() -> void:
	_pending.clear()
	_world = null
	_player = null
	_profile = null


func discard_uncommitted() -> void:
	_pending.clear()
	project_secured(_world, _profile)


func commit_at_boat(control) -> Dictionary:
	if not is_instance_valid(_world) or not is_instance_valid(_player) or _profile == null:
		return {"changed": false, "reason": "map_unavailable"}
	if not is_at_boat(_world, _player):
		return {"changed": false, "reason": "not_at_commit_destination"}
	var refuge = control.refuge_runtime() if control != null and control.has_method("refuge_runtime") else null
	var event: Dictionary = refuge.report()["pending"] if refuge != null else {}
	if _pending.is_empty() and event.is_empty():
		return {"changed": false, "reason": "nothing_pending"}
	var opportunity := _opportunity()
	if opportunity.is_empty() or str(_world.map_id) != str(opportunity.get("commit_map_id", "")):
		return {"changed": false, "reason": "wrong_commit_map"}
	var entry_id := str(opportunity.get("commit_entry_id", ""))
	if entry_id != "surface_boat_entry" or not _world.is_inside_boat(_world.get_entry_position(entry_id)):
		return {"changed": false, "reason": "invalid_commit_entry"}
	if _pending.is_empty():
		if event.get("individual_id") != INDIVIDUAL_ID or event.get("memory_id") != MEMORY_ID or event.get("opportunity_id") != OPPORTUNITY_ID or event.get("target_id") != REFUGE_ID:
			return {"changed": false, "reason": "invalid_pending_event"}
		# Transfer before habitat dismissal; a failed save must survive a selection
		# change or destruction of Marl's transient field controller.
		_pending = refuge.take_pending_memory()
	var result: Dictionary = _profile.earn_companion_memory_for(
		str(_pending["individual_id"]), str(_pending["memory_id"]), true
	)
	result["individual_id"] = INDIVIDUAL_ID
	result["memory_id"] = MEMORY_ID
	if bool(result.get("changed", false)) or result.get("reason") == "already_earned":
		_pending.clear()
		project_secured(_world, _profile)
		if bool(result.get("changed", false)):
			result["note"] = "Marl's Guarded the Nest memory secured | Root Claws can be chosen at night"
	else:
		result["note"] = "Marl's memory could not be saved | Return to the boat to retry"
	return result


func report() -> Dictionary:
	return {"pending": _pending.duplicate(true), "memory_secured": memory_secured(_profile)}


func _opportunity() -> Dictionary:
	for opportunity in _world.get_creature_memory_opportunities():
		if opportunity.get("id") == OPPORTUNITY_ID:
			return opportunity
	return {}


static func is_at_boat(world, player) -> bool:
	return is_instance_valid(world) and is_instance_valid(player) and world.has_method("is_inside_boat") and bool(world.is_inside_boat(player.global_position))


static func memory_secured(profile) -> bool:
	if profile == null or not profile.has_method("companion_report"):
		return false
	for individual in profile.companion_report().get("individuals", []):
		if individual.get("individual_id") == INDIVIDUAL_ID and individual.get("species_id") == "silt_hound":
			return bool(individual.get("rescue_committed", false)) and MEMORY_ID in individual.get("earned_memory_ids", [])
	return false


static func project_secured(world, profile) -> void:
	if not is_instance_valid(world) or not world.has_method("burrow_refuge_presentation") or not memory_secured(profile):
		return
	var visual = world.burrow_refuge_presentation()
	if is_instance_valid(visual):
		visual.project_secured()
