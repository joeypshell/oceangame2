extends RefCounted

const REWARD_KIND := "held_discovery_cargo"

var _profile
var _held := {}
var _last_event := "idle"


func _init(profile_state) -> void:
	_profile = profile_state


func handles(target: Dictionary) -> bool:
	return str(target.get("reward_kind", "")) == REWARD_KIND


func secure(target: Dictionary, source_map_id: String, reward: Dictionary) -> Dictionary:
	if not handles(target):
		return _result(false, "unsupported_reward", "Navigation core unavailable")
	var target_id := str(target.get("id", "")).strip_edges()
	var discovery_id := str(target.get("reward_id", "")).strip_edges()
	if target_id.is_empty() or discovery_id.is_empty() or source_map_id.is_empty():
		return _result(false, "invalid_source", "Navigation core unavailable")
	if _profile != null and _profile.has_completed_discovery(discovery_id):
		return _result(false, "already_committed", "Navigation core already delivered")
	if not bool(reward.get("pending", false)):
		return _result(false, "pending_required", "Navigation core could not be secured")
	if not _held.is_empty():
		var reason := "already_held" if held_discovery_id() == discovery_id else "cargo_exists"
		return _result(false, reason, held_note())
	_held = {
		"target_id": target_id,
		"discovery_id": discovery_id,
		"source_map_id": source_map_id,
		"pending_label": str(target.get("reward_pending_label", "Navigation core secured | Return to the boat")),
	}
	_last_event = "secured"
	return _result(true, _last_event, held_note())


func on_map_loaded(world) -> Dictionary:
	if world == null or not world.has_method("get_tool_targets"):
		return report()
	for target in world.get_tool_targets():
		if not handles(target):
			continue
		var target_id := str(target.get("id", ""))
		var discovery_id := str(target.get("reward_id", ""))
		var committed: bool = _profile != null and _profile.has_completed_discovery(discovery_id)
		if committed or (not _held.is_empty() and target_id == held_target_id()):
			world.collect_tool_target(target_id)
	return report()


func on_discovery_committed(discovery_id: String) -> Dictionary:
	if _held.is_empty() or discovery_id != held_discovery_id():
		return _result(false, "unrelated_commit", "")
	var committed_id := held_discovery_id()
	_held = {}
	_last_event = "committed"
	return _result(true, _last_event, "Navigation core delivered", {"discovery_id": committed_id})


func clear_unbanked(world = null, reason := "reset") -> Dictionary:
	if _held.is_empty():
		_last_event = "cleared_%s" % reason
		return _result(false, _last_event, "")
	var cleared := _held.duplicate(true)
	if (
		world != null
		and str(world.map_id) == str(cleared.get("source_map_id", ""))
		and world.has_method("restore_salvage")
	):
		world.restore_salvage([str(cleared.get("target_id", ""))])
	_held = {}
	_last_event = "cleared_%s" % reason
	return _result(true, _last_event, "", {"cleared": cleared})


func held_count() -> int:
	return 0 if _held.is_empty() else 1


func held_target_id() -> String:
	return str(_held.get("target_id", ""))


func held_discovery_id() -> String:
	return str(_held.get("discovery_id", ""))


func held_note() -> String:
	return str(_held.get("pending_label", "Navigation core secured | Return to the boat"))


func report() -> Dictionary:
	return {
		"status": _last_event,
		"held_count": held_count(),
		"held": _held.duplicate(true),
	}


func _result(changed: bool, reason: String, note: String, extra := {}) -> Dictionary:
	var value := report()
	value["changed"] = changed
	value["reason"] = reason
	value["note"] = note
	for key in extra:
		value[key] = extra[key]
	return value
