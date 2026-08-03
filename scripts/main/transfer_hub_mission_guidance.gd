extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const MISSION_ID := "transfer_hub_core_recovery"


static func report(world, profile, navigation_core) -> Dictionary:
	var result := {
		"active": false,
		"mission_id": "",
		"source_id": "",
		"text": "",
	}
	if world == null or profile == null:
		return result
	if not profile.has_completed_discovery(ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID):
		return result
	if profile.has_completed_discovery(ExpansionProfileState.TRANSFER_HUB_NAVIGATION_CORE_DISCOVERY_ID):
		return result

	var source := _mission_source(world)
	if source.is_empty():
		return result
	var held: bool = navigation_core != null and navigation_core.held_count() > 0
	var field := "mission_return_guidance" if held else "mission_guidance"
	var text := str(source.get(field, "")).strip_edges()
	if text.is_empty():
		return result
	result["active"] = true
	result["mission_id"] = MISSION_ID
	result["source_id"] = str(source.get("id", ""))
	result["text"] = text
	return result


static func _mission_source(world) -> Dictionary:
	for getter in ["get_world_connectors", "get_tool_targets"]:
		if not world.has_method(getter):
			continue
		for value in world.call(getter):
			if (
				typeof(value) == TYPE_DICTIONARY
				and str(value.get("mission_id", "")) == MISSION_ID
			):
				return (value as Dictionary).duplicate(true)
	return {}
