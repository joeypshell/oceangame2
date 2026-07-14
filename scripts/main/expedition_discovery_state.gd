extends RefCounted

const ANOMALY_DISCOVERY_ID := "lower_right_anomaly_discovery"
const MINERAL_TRACE_RESEARCH_ID := "upper_right_mineral_trace_research"
const SIGNAL_REEF_DISCOVERY_ID := "lower_right_signal_reef_discovery"
const DEEP_HARMONIC_DISCOVERY_ID := "signal_reef_deep_harmonic_discovery"
const SUPPORTED_DISCOVERY_IDS := {ANOMALY_DISCOVERY_ID: true, MINERAL_TRACE_RESEARCH_ID: true, SIGNAL_REEF_DISCOVERY_ID: true, DEEP_HARMONIC_DISCOVERY_ID: true}
const METADATA_FIELDS := ["target_type", "finding_label", "next_lead_label"]

var _pending := {}
var _last_event := "idle"


func create_pending(
	discovery_id: String,
	source_map_id: String,
	target_id: String,
	commit_map_id: String,
	commit_entry_id: String,
	metadata := {}
) -> Dictionary:
	if not SUPPORTED_DISCOVERY_IDS.has(discovery_id):
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
		"metadata": _sanitize_metadata(metadata),
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
	var metadata: Dictionary = _pending.get("metadata", {}).duplicate(true)
	var completion: Dictionary = profile_state.complete_discovery(discovery_id, true)
	var reason := str(completion.get("reason", "storage_error"))
	if reason == "storage_error" or reason == "unsupported_discovery":
		return _result(reason)
	_pending = {}
	_last_event = "committed" if bool(completion.get("changed", false)) else "already_committed"
	return _result(_last_event, {"committed_discovery_id": discovery_id, "metadata": metadata})


func has_pending() -> bool:
	return not _pending.is_empty()


func pending_discovery_id() -> String:
	return str(_pending.get("discovery_id", ""))


func pending_metadata() -> Dictionary:
	return _pending.get("metadata", {}).duplicate(true)


func pending_commit_map_id() -> String:
	return str(_pending.get("commit_map_id", ""))


func pending_commit_entry_id() -> String:
	return str(_pending.get("commit_entry_id", ""))


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


func _sanitize_metadata(value) -> Dictionary:
	var result := {}
	if typeof(value) != TYPE_DICTIONARY:
		return result
	for field in METADATA_FIELDS:
		var text := str(value.get(field, "")).strip_edges()
		if not text.is_empty():
			result[field] = text
	return result
