extends RefCounted

const DISCOVERY_REWARD_KIND := "discovery"
const REGIONAL_TARGET_TYPE := "regional"

var _profile
var _expedition


func _init(profile_state, expedition_state) -> void:
	_profile = profile_state
	_expedition = expedition_state


func record(target: Dictionary, source_map_id: String) -> Dictionary:
	var reward_kind := str(target.get("reward_kind", "")).strip_edges()
	if reward_kind.is_empty():
		return {"changed": false, "reason": "no_reward", "allow_collection": true}
	if reward_kind != DISCOVERY_REWARD_KIND:
		return _blocked("unsupported_reward", "Wreck data unavailable")
	var reward_id := str(target.get("reward_id", "")).strip_edges()
	if reward_id.is_empty() or _profile == null or _expedition == null:
		return _blocked("invalid_reward", "Wreck data unavailable")
	if _profile.has_completed_discovery(reward_id):
		return {"changed": false, "reason": "already_completed", "allow_collection": true}

	var pending: Dictionary = _expedition.create_pending(
		reward_id,
		source_map_id,
		str(target.get("id", "")),
		str(target.get("reward_commit_map_id", "")),
		str(target.get("reward_commit_entry_id", "")),
		{
			"target_type": REGIONAL_TARGET_TYPE,
			"pending_label": str(target.get("reward_pending_label", "")),
			"finding_label": str(target.get("reward_commit_label", "")),
			"next_lead_label": str(target.get("reward_next_lead_label", "")),
		}
	)
	var status := str(pending.get("status", "pending_error"))
	if status == "pending_created":
		return {
			"changed": true,
			"reason": status,
			"allow_collection": true,
			"pending": true,
			"discovery_id": reward_id,
			"note": _pending_note(target),
		}
	if status in ["already_pending", "pending_exists"]:
		return _blocked(status, _existing_pending_note())
	return _blocked(status, "Wreck data could not be secured")


func _blocked(reason: String, note: String) -> Dictionary:
	return {"changed": false, "reason": reason, "allow_collection": false, "note": note}


func _pending_note(target: Dictionary) -> String:
	var note := str(target.get("reward_pending_label", "")).strip_edges()
	return note if not note.is_empty() else "Wreck data secured | Return to surface boat"


func _existing_pending_note() -> String:
	var metadata: Dictionary = _expedition.pending_metadata()
	var note := str(metadata.get("pending_label", "")).strip_edges()
	return note if not note.is_empty() else "Return current discovery to surface boat"
