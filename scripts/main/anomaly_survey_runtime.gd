extends RefCounted

const ExpeditionDiscoveryState := preload("res://scripts/main/expedition_discovery_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ProgressionContract := preload("res://scripts/main/progression_contract.gd")
const SurveyInteractionController := preload("res://scripts/main/survey_interaction_controller.gd")

const SCANNER_CAPABILITY_ID := ProgressionContract.SCANNER_CAPABILITY_ID
const COMMIT_NOTE := "Discovery committed at surface boat"
const COMMIT_RESULT := "Cutter plan recovered: Lower-right anomaly\nProject unlocked: Salvage cutter"
const REGIONAL_TARGET_TYPE := "regional"
const RESOURCE_TARGET_TYPE := "resource"
const RESOURCE_COMMIT_NOTE := "Research committed at surface boat"

var _progression_runtime
var _profile
var _expedition
var _interaction
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


func scanner_action(world, player) -> Dictionary:
	if not has_scanner():
		if _profile.has_completed_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID):
			return _note_result(false, "project_required", "Scanner project | Ti 1 + Coil 1 | Build at night")
		return _note_result(false, "blueprint_required", "Find scanner blueprint beyond east current")
	var target := _survey_target_at(world, player.global_position) if world != null and player != null else {}
	if not target.is_empty() and not _profile.has_completed_discovery(str(target.get("discovery_id", ""))):
		return _note_result(false, "active", "Scanner active | Hold position")
	return _note_result(false, "ready", "Scanner ready | Approach a survey signal")


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
		return _note_result(false, "completed", _completed_note(target))
	if _expedition.has_pending():
		_interaction.reset()
		var same_pending: bool = _expedition.pending_discovery_id() == discovery_id
		_set_target_state(world, target_id, "pending" if same_pending else "locked")
		return _note_result(false, "pending" if same_pending else "pending_exists", _pending_status_note())
	if not _profile.has_capability(str(target.get("required_capability_id", ""))):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "scanner_required", "Scanner required")
	if not _has_required_light(target):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "light_required", _light_required_note(target))

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
		str(target.get("commit_entry_id", "")),
		_pending_metadata(target)
	)
	if str(pending.get("status", "")) not in ["pending_created", "already_pending"]:
		_set_target_state(world, target_id, "available")
		return _note_result(false, str(pending.get("status", "pending_error")), "Survey could not be recorded")
	_set_target_state(world, target_id, "pending")
	return _note_result(true, "pending_created", _survey_complete_note(target), {"pending": true})


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
		return _pending_overlay_text()
	var nearby_target := _survey_target_at(world, player.global_position) if world != null and player != null else {}
	if not nearby_target.is_empty():
		var discovery_id := str(nearby_target.get("discovery_id", ""))
		if _profile.has_completed_discovery(discovery_id):
			return _completed_overlay_text(nearby_target)
		if _is_finding_target(nearby_target):
			var clue := str(nearby_target.get("clue_label", "Mineral trace")).strip_edges()
			var light_capability_id := str(nearby_target.get("required_light_capability_id", "")).strip_edges()
			if has_scanner() and not light_capability_id.is_empty() and _profile.has_capability(light_capability_id):
				return ""
			return clue if has_scanner() else "%s | Scanner required" % clue
	if _profile.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID):
		return "Cutter plan recovered | Salvage cutter project"
	if not has_scanner():
		return "Scanner project | Ti 1 + Coil 1 | Build at night" if _profile.has_completed_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID) else ""
	return "Scanner ready | Survey lower-right anomaly"


func result_text() -> String:
	return _last_result


func is_status_note(status_note: String) -> bool:
	return (
		status_note.begins_with("Scanner")
		or status_note.begins_with("Find scanner")
		or status_note.begins_with("Cutter")
		or status_note.begins_with("Survey")
		or status_note.begins_with("Discovery")
		or status_note.begins_with("Anomaly")
		or status_note.begins_with("Research")
		or status_note.begins_with("Mineral")
		or status_note.find("light required") != -1
	)


func has_scanner() -> bool:
	return _profile.has_capability(SCANNER_CAPABILITY_ID)


func has_pending_discovery() -> bool:
	return _expedition.has_pending()


func has_completed_discovery(discovery_id := ExpansionProfileState.ANOMALY_DISCOVERY_ID) -> bool:
	return _profile.has_completed_discovery(str(discovery_id))


func has_completed_research() -> bool:
	return has_completed_discovery(ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID)


func profile_state():
	return _profile


func report() -> Dictionary:
	return {
		"scanner_unlocked": has_scanner(),
		"wallet": _progression_runtime.wallet() if _progression_runtime != null else 0,
		"profile": _profile.report(),
		"expedition": _expedition.report(),
		"interaction": _interaction.report(),
		"last_note": _last_note,
		"result_text": _last_result,
	}


func _try_commit(world, player) -> Dictionary:
	if not _expedition.has_pending() or not _at_pending_commit_boat(world, player):
		return {}
	var commit: Dictionary = _expedition.commit_at(
		_expedition.pending_commit_map_id(),
		_expedition.pending_commit_entry_id(),
		_profile
	)
	var status := str(commit.get("status", ""))
	if status not in ["committed", "already_committed"]:
		return _note_result(false, status, "Discovery commit failed")
	var discovery_id := str(commit.get("committed_discovery_id", ""))
	var metadata: Dictionary = commit.get("metadata", {})
	if discovery_id == ExpansionProfileState.ANOMALY_DISCOVERY_ID:
		_last_note = COMMIT_NOTE
		_last_result = COMMIT_RESULT
	elif str(metadata.get("target_type", "")) == REGIONAL_TARGET_TYPE:
		_last_note = COMMIT_NOTE
		_last_result = str(metadata.get("finding_label", "Discovery logged"))
		var next_lead := str(metadata.get("next_lead_label", "")).strip_edges()
		if not next_lead.is_empty():
			_last_result += "\n%s" % next_lead
	else:
		_last_note = RESOURCE_COMMIT_NOTE
		_last_result = str(metadata.get("finding_label", "Research finding committed"))
	return {
		"state": status,
		"committed": true,
		"discovery_id": discovery_id,
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
		elif _target_available(target):
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
		and world.has_method("is_inside_boat")
		and world.is_inside_boat(player.global_position)
	)


func _at_pending_commit_boat(world, player) -> bool:
	return (
		world != null
		and player != null
		and str(world.map_id) == _expedition.pending_commit_map_id()
		and world.has_method("is_inside_boat")
		and world.is_inside_boat(player.global_position)
	)


func _note_result(changed: bool, reason: String, note: String, extra := {}) -> Dictionary:
	_last_note = note
	var result := {"changed": changed, "reason": reason, "note": note}
	for key in extra:
		result[key] = extra[key]
	return result


func _target_available(target: Dictionary) -> bool:
	return (
		_profile.has_capability(str(target.get("required_capability_id", "")))
		and _has_required_light(target)
	)


func _has_required_light(target: Dictionary) -> bool:
	var capability_id := str(target.get("required_light_capability_id", "")).strip_edges()
	return capability_id.is_empty() or _profile.has_capability(capability_id)


func _light_required_note(target: Dictionary) -> String:
	var clue := str(target.get("clue_label", "")).strip_edges()
	return clue if not clue.is_empty() else "Stronger light required"


func _is_resource_target(target: Dictionary) -> bool:
	return str(target.get("target_type", "")) == RESOURCE_TARGET_TYPE


func _is_regional_target(target: Dictionary) -> bool:
	return str(target.get("target_type", "")) == REGIONAL_TARGET_TYPE


func _is_finding_target(target: Dictionary) -> bool:
	return _is_resource_target(target) or _is_regional_target(target)


func _pending_metadata(target: Dictionary) -> Dictionary:
	return {
		"target_type": str(target.get("target_type", "")),
		"finding_label": str(target.get("finding_label", "")),
		"next_lead_label": str(target.get("next_lead_label", "")),
	}


func _survey_complete_note(target: Dictionary) -> String:
	return "Research complete - return to surface boat" if _is_resource_target(target) else "Survey complete - return to surface boat"


func _completed_note(target: Dictionary) -> String:
	return str(target.get("finding_label", "Finding already logged")) if _is_finding_target(target) else "Salvage cutter plan already recovered"


func _completed_overlay_text(target: Dictionary) -> String:
	return str(target.get("finding_label", "Finding logged")) if _is_finding_target(target) else "Cutter plan recovered | Salvage cutter project"


func _pending_overlay_text() -> String:
	var metadata: Dictionary = _expedition.pending_metadata()
	return "Research pending | Return to surface boat" if str(metadata.get("target_type", "")) == RESOURCE_TARGET_TYPE else "Discovery pending | Return to surface boat"


func _pending_status_note() -> String:
	var metadata: Dictionary = _expedition.pending_metadata()
	return "Research pending - return to surface boat" if str(metadata.get("target_type", "")) == RESOURCE_TARGET_TYPE else "Discovery pending - return to surface boat"
