extends RefCounted

const ExpeditionDiscoveryState := preload("res://scripts/main/expedition_discovery_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const SurveyInteractionController := preload("res://scripts/main/survey_interaction_controller.gd")

const SCANNER_CAPABILITY_ID := ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID
const SCANNER_COST := 300
const CANONICAL_MAP_ID := "production_slice_01"
const CANONICAL_ENTRY_ID := "surface_boat_entry"
const COMMIT_NOTE := "Discovery committed at surface boat"
const COMMIT_RESULT := "Discovery logged: Lower-right anomaly\nNext lead: investigate territorial signal"

var _progression_runtime
var _profile
var _expedition
var _interaction
var _lead_available := false
var _last_note := ""
var _last_result := ""


func _init(progression_runtime, persist_profile := true, profile_state = null) -> void:
	_progression_runtime = progression_runtime
	_profile = profile_state
	if _profile == null:
		_profile = ExpansionProfileState.new(ExpansionProfileState.DEFAULT_STORAGE_PATH, persist_profile)
	_profile.load_profile()
	_expedition = ExpeditionDiscoveryState.new()
	_interaction = SurveyInteractionController.new()


func activate_lead() -> Dictionary:
	if _profile.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID):
		return {"changed": false, "reason": "discovery_complete"}
	var changed := not _lead_available
	_lead_available = true
	return {"changed": changed, "reason": "lead_available"}


func try_unlock_scanner(world, player) -> Dictionary:
	if _profile.has_capability(SCANNER_CAPABILITY_ID):
		return _note_result(false, "already_unlocked", "Scanner already unlocked")
	if not _lead_available:
		return _note_result(false, "lead_unavailable", "Scanner lead unavailable")
	if not _at_canonical_boat(world, player):
		return _note_result(false, "wrong_location", "Unlock scanner at surface boat")
	if _progression_runtime == null or not _progression_runtime.has_method("spend_wallet"):
		return _note_result(false, "wallet_unavailable", "Scanner purchase unavailable")

	var spend: Dictionary = _progression_runtime.spend_wallet(SCANNER_COST)
	if not bool(spend.get("spent", false)):
		return _note_result(
			false,
			str(spend.get("reason", "insufficient_funds")),
			"Need %d more for scanner" % int(spend.get("needed", SCANNER_COST))
		)
	var unlock: Dictionary = _profile.unlock_capability(SCANNER_CAPABILITY_ID, true)
	if not bool(unlock.get("changed", false)):
		_progression_runtime.grant_wallet_reward(SCANNER_COST)
		return _note_result(false, str(unlock.get("reason", "storage_error")), "Scanner unlock failed - wallet restored")
	return _note_result(true, "unlocked", "Scanner unlocked")


func update(world, player, delta: float) -> Dictionary:
	if world == null or player == null:
		return {}
	var commit_result := _try_commit(world, player)
	if bool(commit_result.get("committed", false)):
		return commit_result

	var target := _survey_target_at(world, player.global_position)
	if target.is_empty():
		var canceled: Dictionary = _interaction.update({}, delta)
		if str(canceled.get("state", "")) == "canceled":
			_last_note = str(canceled.get("note", "Survey interrupted"))
			_refresh_world_targets(world)
			return {"state": "canceled", "note": _last_note}
		return {}

	var target_id := str(target.get("id", ""))
	var discovery_id := str(target.get("discovery_id", ""))
	if _profile.has_completed_discovery(discovery_id):
		_interaction.reset()
		_set_target_state(world, target_id, "completed")
		return _note_result(false, "completed", "Anomaly already logged")
	if _expedition.has_pending():
		_interaction.reset()
		_set_target_state(world, target_id, "pending")
		return _note_result(false, "pending", "Discovery pending - return to surface boat")
	if not _lead_available:
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "lead_required", "Anomaly lead required")
	if not _profile.has_capability(str(target.get("required_capability_id", ""))):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "scanner_required", "Scanner required")

	_set_target_state(world, target_id, "active")
	var survey_result: Dictionary = _interaction.update(target, delta)
	if str(survey_result.get("state", "")) != "complete":
		_last_note = str(survey_result.get("note", "Survey anomaly"))
		return {"state": survey_result.get("state", "progress"), "note": _last_note, "survey": survey_result}

	var pending: Dictionary = _expedition.create_pending(
		discovery_id,
		str(world.map_id),
		target_id,
		str(target.get("commit_map_id", "")),
		str(target.get("commit_entry_id", ""))
	)
	if str(pending.get("status", "")) not in ["pending_created", "already_pending"]:
		_set_target_state(world, target_id, "available")
		return _note_result(false, str(pending.get("status", "pending_error")), "Survey could not be recorded")
	_set_target_state(world, target_id, "pending")
	return _note_result(true, "pending_created", "Survey complete - return to surface boat", {"pending": true})


func on_map_loaded(world) -> void:
	_interaction.reset()
	_refresh_world_targets(world)


func on_map_transition(destination_map_id: String) -> Dictionary:
	_interaction.reset()
	return _expedition.on_map_transition(destination_map_id)


func clear_unbanked(reason: String, world = null) -> Dictionary:
	_interaction.reset()
	_last_result = ""
	var result: Dictionary = _expedition.clear_pending(reason)
	_refresh_world_targets(world)
	return result


func overlay_text(world, player) -> String:
	if not _last_result.is_empty():
		return _last_result
	if _expedition.has_pending():
		return "Discovery pending | Return to surface boat"
	if _profile.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID):
		return "Discovery logged | Lower-right anomaly"
	if not _lead_available:
		return ""
	if not _profile.has_capability(SCANNER_CAPABILITY_ID):
		return "Q: Scanner (%d)" % SCANNER_COST if _at_canonical_boat(world, player) else "Anomaly lead | Unlock scanner at boat"
	return "Scanner ready | Survey lower-right anomaly"


func result_text() -> String:
	return _last_result


func is_status_note(status_note: String) -> bool:
	return (
		status_note.begins_with("Scanner")
		or status_note.begins_with("Unlock scanner")
		or status_note.find(" for scanner") != -1
		or status_note.begins_with("Survey")
		or status_note.begins_with("Discovery")
		or status_note.begins_with("Anomaly")
	)


func has_scanner() -> bool:
	return _profile.has_capability(SCANNER_CAPABILITY_ID)


func has_pending_discovery() -> bool:
	return _expedition.has_pending()


func has_completed_discovery() -> bool:
	return _profile.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID)


func report() -> Dictionary:
	return {
		"lead_available": _lead_available,
		"scanner_unlocked": has_scanner(),
		"scanner_cost": SCANNER_COST,
		"wallet": _progression_runtime.wallet() if _progression_runtime != null else 0,
		"profile": _profile.report(),
		"expedition": _expedition.report(),
		"interaction": _interaction.report(),
		"last_note": _last_note,
		"result_text": _last_result,
	}


func _try_commit(world, player) -> Dictionary:
	if not _expedition.has_pending() or not _at_canonical_boat(world, player):
		return {}
	var commit: Dictionary = _expedition.commit_at(CANONICAL_MAP_ID, CANONICAL_ENTRY_ID, _profile)
	var status := str(commit.get("status", ""))
	if status not in ["committed", "already_committed"]:
		return _note_result(false, status, "Discovery commit failed")
	_lead_available = false
	_last_note = COMMIT_NOTE
	_last_result = COMMIT_RESULT
	return {
		"state": status,
		"committed": true,
		"discovery_id": str(commit.get("committed_discovery_id", "")),
		"note": _last_note,
		"result_text": _last_result,
	}


func _refresh_world_targets(world) -> void:
	if world == null or not world.has_method("get_survey_targets"):
		return
	for target in world.get_survey_targets():
		var state := "locked"
		var discovery_id := str(target.get("discovery_id", ""))
		if _profile.has_completed_discovery(discovery_id):
			state = "completed"
		elif _expedition.pending_discovery_id() == discovery_id:
			state = "pending"
		elif _lead_available and _profile.has_capability(str(target.get("required_capability_id", ""))):
			state = "available"
		_set_target_state(world, str(target.get("id", "")), state)


func _survey_target_at(world, position: Vector2) -> Dictionary:
	if world == null or not world.has_method("get_survey_target_at"):
		return {}
	return world.get_survey_target_at(position)


func _set_target_state(world, target_id: String, state: String) -> void:
	if world != null and world.has_method("set_survey_target_state"):
		world.set_survey_target_state(target_id, state)


func _at_canonical_boat(world, player) -> bool:
	return (
		world != null
		and player != null
		and str(world.map_id) == CANONICAL_MAP_ID
		and world.has_method("is_inside_extraction")
		and world.is_inside_extraction(player.global_position)
	)


func _note_result(changed: bool, reason: String, note: String, extra := {}) -> Dictionary:
	_last_note = note
	var result := {"changed": changed, "reason": reason, "note": note}
	for key in extra:
		result[key] = extra[key]
	return result
