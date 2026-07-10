extends RefCounted

const ANOMALY_DISCOVERY_ID := "lower_right_anomaly_discovery"

var _pending := {}
var _last_event := "idle"


func create_pending(
	discovery_id: String,
	source_map_id: String,
	target_id: String,
	commit_map_id: String,
	commit_entry_id: String
) -> Dictionary:
	if discovery_id != ANOMALY_DISCOVERY_ID:
		return _result("unsupported_discovery")
	if source_map_id.is_empty() or target_id.is_empty() or commit_map_id.is_empty() or commit_entry_id.is_empty():
		return _result("invalid_source")
	if not _pending.is_empty():
		if str(_pending.get("discovery_id", "")) == discovery_id:
			return _result("already_pending")
		return _result("pending_exists")
	_pending = {
		"discovery_id": discovery_id,
		"source_map_id": source_map_id,
		"target_id": target_id,
		"commit_map_id": commit_map_id,
		"commit_entry_id": commit_entry_id,
	}
	_last_event = "pending_created"
	return _result("pending_created")


func on_map_transition(destination_map_id: String) -> Dictionary:
	_last_event = "transition_preserved" if not _pending.is_empty() else "transition_empty"
	return _result(_last_event, {"destination_map_id": destination_map_id})


func clear_pending(reason: String) -> Dictionary:
	var cleared_id := str(_pending.get("discovery_id", ""))
	_pending = {}
	_last_event = "cleared_%s" % reason if not reason.is_empty() else "cleared"
	return _result(_last_event, {"cleared_discovery_id": cleared_id})


func commit_at(map_id: String, entry_id: String, profile_state) -> Dictionary:
	if _pending.is_empty():
		return _result("no_pending")
	if map_id != str(_pending.get("commit_map_id", "")) or entry_id != str(_pending.get("commit_entry_id", "")):
		return _result("wrong_commit_location")
	if profile_state == null or not profile_state.has_method("complete_discovery"):
		return _result("profile_unavailable")

	var discovery_id := str(_pending["discovery_id"])
	var completion: Dictionary = profile_state.complete_discovery(discovery_id, true)
	var reason := str(completion.get("reason", "storage_error"))
	if reason == "storage_error" or reason == "unsupported_discovery":
		return _result(reason)
	_pending = {}
	_last_event = "committed" if bool(completion.get("changed", false)) else "already_committed"
	return _result(_last_event, {"committed_discovery_id": discovery_id})


func has_pending() -> bool:
	return not _pending.is_empty()


func pending_discovery_id() -> String:
	return str(_pending.get("discovery_id", ""))


func report() -> Dictionary:
	return _result(_last_event)


func _result(status: String, extra := {}) -> Dictionary:
	var value := {
		"status": status,
		"has_pending": has_pending(),
		"pending": _pending.duplicate(true),
	}
	for key in extra:
		value[key] = extra[key]
	return value
