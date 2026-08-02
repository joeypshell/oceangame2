extends RefCounted

const ExpeditionDiscoveryState := preload("res://scripts/main/expedition_discovery_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ProgressionContract := preload("res://scripts/main/progression_contract.gd")
const SurveyInteractionController := preload("res://scripts/main/survey_interaction_controller.gd")
const SurveyDependencyState := preload("res://scripts/main/survey_dependency_state.gd")
const RegionalJourneyPresentation := preload("res://scripts/main/regional_journey_presentation.gd")
const ScannerConeTargeting := preload("res://scripts/main/scanner_cone_targeting.gd")
const ScannerCutterJourneyPresentation := preload("res://scripts/main/scanner_cutter_journey_presentation.gd")
const ScannerFeedbackText := preload("res://scripts/main/scanner_feedback_text.gd")
const ToolTargetRewardRuntime := preload("res://scripts/main/tool_target_reward_runtime.gd")

const SCANNER_CAPABILITY_ID := ProgressionContract.SCANNER_CAPABILITY_ID
const COMMIT_NOTE := "Discovery committed at surface boat"
const BLUEPRINT_COMMIT_NOTE := "Blueprint committed at surface boat"
const REGIONAL_TARGET_TYPE := "regional"
const RESOURCE_TARGET_TYPE := "resource"
const HELD_DISCOVERY_CARGO_TARGET_TYPE := "held_discovery_cargo"
const RESOURCE_COMMIT_NOTE := "Research committed at surface boat"

var _progression_runtime
var _profile
var _expedition
var _interaction
var _dependencies
var _regional_presentation
var _scanner_targeting
var _scanner_cutter_presentation
var _scanner_feedback
var _tool_target_rewards
var _last_targeting_report := {}
var _scanner_use_held := false
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
	_dependencies = SurveyDependencyState.new(_profile)
	_regional_presentation = RegionalJourneyPresentation.new()
	_scanner_targeting = ScannerConeTargeting.new()
	_scanner_cutter_presentation = ScannerCutterJourneyPresentation.new()
	_scanner_feedback = ScannerFeedbackText.new(_regional_presentation)
	_tool_target_rewards = ToolTargetRewardRuntime.new(_profile, _expedition)


func scanner_action(world, player) -> Dictionary:
	_scanner_use_held = false
	if not has_scanner():
		if _profile.has_completed_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID):
			return _note_result(false, "project_required", "Scanner project | Ti 1 + Coil 1 | Build at night")
		return _note_result(false, "blueprint_required", "Find scanner blueprint beyond east current")
	_scanner_use_held = true
	var target := _target_for_player(world, player)
	if target.is_empty():
		return _note_result(false, "ready", "Scanner ready | Approach a survey signal")
	var target_id := str(target.get("id", ""))
	if str(target.get("scanner_subject_mode", "")) == "identify":
		_interaction.reset()
		return _note_result(
			false,
			"identified",
			_scanner_feedback.identification_note(target),
			{"target_id": target_id, "identified": true}
		)
	var discovery_id := str(target.get("discovery_id", ""))
	if _profile.has_completed_discovery(discovery_id):
		_interaction.reset()
		_set_target_state(world, target_id, "completed")
		return _note_result(false, "completed", _scanner_feedback.completed_note(target))
	if _expedition.has_pending():
		_interaction.reset()
		var same_pending: bool = _expedition.pending_discovery_id() == discovery_id
		_set_target_state(world, target_id, "pending" if same_pending else "locked")
		return _note_result(false, "pending" if same_pending else "pending_exists", _scanner_feedback.pending_return_text(_expedition.pending_metadata()))
	if not _dependencies.is_survey_unlocked(target_id):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "tool_clearance_required", _dependencies.requirement_note(target_id))
	if not _profile.has_capability(str(target.get("required_capability_id", ""))):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "scanner_required", "Scanner required")
	if not _has_required_light(target):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "light_required", _light_required_note(target))
	if not _has_required_pressure_protection(target):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "pressure_required", _pressure_required_note(target))
	var activation: Dictionary = _interaction.activate(target)
	if str(activation.get("state", "")) != "activated":
		return _note_result(false, "invalid", "Survey signal unavailable")
	_scanner_use_held = true
	_set_target_state(world, target_id, "active")
	return _note_result(
		bool(activation.get("changed", false)),
		"activated",
		str(activation.get("note", "Scanner active | Hold Space/USE and position")),
		{"target_id": target_id}
	)


func update(world, player, delta: float) -> Dictionary:
	if world == null or player == null:
		return {}
	var commit_result := _try_commit(world, player)
	if bool(commit_result.get("committed", false)):
		return commit_result

	var active_target_id := str(_interaction.report().get("active_target_id", ""))
	if not active_target_id.is_empty() and not _scanner_use_held:
		cancel_active_interaction(world)
		return {"state": "canceled", "note": _last_note}
	var required_mode := "progression" if active_target_id.is_empty() and not _scanner_use_held else ""
	var target := _target_for_player(world, player, active_target_id, required_mode)
	if target.is_empty():
		var canceled: Dictionary = _interaction.update({}, delta)
		if str(canceled.get("state", "")) == "canceled":
			_last_note = str(canceled.get("note", "Survey interrupted"))
			_refresh_world_targets(world)
			return {"state": "canceled", "note": _last_note}
		return {}

	var target_id := str(target.get("id", ""))
	if str(target.get("scanner_subject_mode", "")) == "identify":
		return _note_result(
			false,
			"identified",
			_scanner_feedback.identification_note(target),
			{"target_id": target_id, "identified": true}
		)
	var discovery_id := str(target.get("discovery_id", ""))
	if _profile.has_completed_discovery(discovery_id):
		_interaction.reset()
		_set_target_state(world, target_id, "completed")
		return _note_result(false, "completed", _scanner_feedback.completed_note(target))
	if _expedition.has_pending():
		_interaction.reset()
		var same_pending: bool = _expedition.pending_discovery_id() == discovery_id
		_set_target_state(world, target_id, "pending" if same_pending else "locked")
		return _note_result(false, "pending" if same_pending else "pending_exists", _scanner_feedback.pending_return_text(_expedition.pending_metadata()))
	if not _dependencies.is_survey_unlocked(target_id):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "tool_clearance_required", _dependencies.requirement_note(target_id))
	if not _profile.has_capability(str(target.get("required_capability_id", ""))):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "scanner_required", "Scanner required")
	if not _has_required_light(target):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "light_required", _light_required_note(target))
	if not _has_required_pressure_protection(target):
		_interaction.reset()
		_set_target_state(world, target_id, "locked")
		return _note_result(false, "pressure_required", _pressure_required_note(target))

	var survey_result: Dictionary = _interaction.update(target, delta)
	var interaction_state := str(survey_result.get("state", ""))
	_set_target_state(world, target_id, "active" if interaction_state in ["progress", "complete"] else "available")
	if interaction_state != "complete":
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
	return _note_result(true, "pending_created", _scanner_feedback.survey_complete_note(target), {"pending": true})


func on_map_loaded(world) -> void:
	_scanner_use_held = false
	_interaction.reset()
	_dependencies.on_map_loaded(world)
	_refresh_world_targets(world)


func on_map_transition(destination_map_id: String) -> Dictionary:
	_scanner_use_held = false
	_interaction.reset()
	return _expedition.on_map_transition(destination_map_id)


func active_tool_target(world, player) -> Dictionary:
	return _target_for_player(world, player).duplicate(true)


func scanner_release(world) -> Dictionary:
	_scanner_use_held = false
	if not cancel_active_interaction(world):
		return {"changed": false, "reason": "idle"}
	return {"changed": true, "reason": "released", "note": _last_note}


func cancel_active_interaction(world) -> bool:
	_scanner_use_held = false
	var active_target_id := str(_interaction.report().get("active_target_id", ""))
	if active_target_id.is_empty():
		return false
	_interaction.reset()
	_last_note = "Scanner interrupted"
	_refresh_world_targets(world)
	return true


func clear_unbanked(reason: String, world = null) -> Dictionary:
	_scanner_use_held = false
	_interaction.reset()
	_dependencies.clear_unbanked()
	_last_result = ""
	var result: Dictionary = _expedition.clear_pending(reason)
	_refresh_world_targets(world)
	return result


func overlay_text(world, player, selected_lead_id := "") -> String:
	_regional_presentation.sync_route_guidance(world, _profile)
	if _expedition.has_pending():
		return _scanner_feedback.pending_return_text(_expedition.pending_metadata())
	var active_target_id := str(_interaction.report().get("active_target_id", ""))
	var nearby_target := _target_for_player(world, player, active_target_id, "progression")
	if not nearby_target.is_empty():
		var discovery_id := str(nearby_target.get("discovery_id", ""))
		if _profile.has_completed_discovery(discovery_id):
			return _scanner_feedback.completed_overlay_text(nearby_target)
		var clue := str(nearby_target.get("clue_label", "")).strip_edges()
		if not _dependencies.is_survey_unlocked(str(nearby_target.get("id", ""))):
			return _dependencies.requirement_note(str(nearby_target.get("id", "")))
		if not has_scanner():
			return "%s | Scanner required" % clue if not clue.is_empty() else "Scanner required"
		if not _has_required_light(nearby_target):
			return _light_required_note(nearby_target)
		if not _has_required_pressure_protection(nearby_target):
			return _pressure_required_note(nearby_target)
		return _scanner_feedback.nearby_scan_text(
			nearby_target,
			clue,
			active_target_id,
			_last_note
		)
	if not _last_result.is_empty() and not _scanner_cutter_presentation.result_is_superseded(world, _profile, _last_result):
		return _last_result
	var journey_promise: String = _regional_presentation.promise_text(world, _profile, selected_lead_id)
	if not journey_promise.is_empty():
		return journey_promise
	var scanner_cutter_lead: String = _scanner_cutter_presentation.objective_text(world, _profile)
	if not scanner_cutter_lead.is_empty():
		return scanner_cutter_lead
	if _profile.has_completed_discovery(ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID):
		return "Blueprint recovered | Salvage cutter project"
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
		or status_note.begins_with("Blueprint")
		or status_note.begins_with("Survey")
		or status_note.begins_with("Discovery")
		or status_note.begins_with("Anomaly")
		or status_note.begins_with("Research")
		or status_note.begins_with("Identified")
		or status_note.begins_with("Mineral")
		or status_note.begins_with("Pressure")
		or status_note.begins_with("Abyssal")
		or _regional_presentation.is_feedback_note(status_note)
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


func record_tool_target_clearance(target: Dictionary, world = null) -> Dictionary:
	var result: Dictionary = _dependencies.record_clearance(target)
	if bool(result.get("changed", false)):
		_refresh_world_targets(world)
	return result


func record_tool_target_reward(target: Dictionary, world) -> Dictionary:
	var map_id := str(world.map_id) if world != null else ""
	var result: Dictionary = _tool_target_rewards.record(target, map_id)
	if result.has("note"):
		_last_note = str(result["note"])
	return result


func report() -> Dictionary:
	return {
		"scanner_unlocked": has_scanner(),
		"wallet": _progression_runtime.wallet() if _progression_runtime != null else 0,
		"profile": _profile.report(),
		"expedition": _expedition.report(),
		"interaction": _interaction.report(),
		"scanner_use_held": _scanner_use_held,
		"dependencies": _dependencies.report(),
		"targeting": _last_targeting_report.duplicate(true),
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
	_last_note = BLUEPRINT_COMMIT_NOTE if str(metadata.get("scan_reward_kind", "")) == "blueprint" else COMMIT_NOTE
	_last_result = str(metadata.get("finding_label", "Discovery logged"))
	if str(metadata.get("target_type", "")) in [REGIONAL_TARGET_TYPE, HELD_DISCOVERY_CARGO_TARGET_TYPE]:
		var next_lead := str(metadata.get("next_lead_label", "")).strip_edges()
		if not next_lead.is_empty():
			_last_result += "\n%s" % next_lead
	elif str(metadata.get("target_type", "")) == RESOURCE_TARGET_TYPE:
		_last_note = RESOURCE_COMMIT_NOTE
		_last_result = str(metadata.get("finding_label", "Research finding committed"))
	return {
		"state": status,
		"committed": true,
		"discovery_id": discovery_id,
		"reward_id": str(commit.get("committed_reward_id", "")),
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


func _target_for_player(world, player, target_id := "", required_mode := "") -> Dictionary:
	if world == null or player == null:
		_last_targeting_report = _scanner_targeting.public_report({"eligible": false, "reason": "world_unavailable"})
		return {}
	var facing_sign := float(player.get_facing_sign()) if player.has_method("get_facing_sign") else 1.0
	var targeting: Dictionary
	if str(target_id).is_empty():
		targeting = _scanner_targeting.acquire(world, player.global_position, facing_sign, required_mode)
	else:
		var target: Dictionary = _scanner_targeting.target_by_id(world, str(target_id))
		targeting = _scanner_targeting.evaluate_target(world, player.global_position, facing_sign, target)
	_last_targeting_report = _scanner_targeting.public_report(targeting)
	return targeting.get("target", {}) if bool(targeting.get("eligible", false)) else {}


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
		_dependencies.is_survey_unlocked(str(target.get("id", "")))
		and _profile.has_capability(str(target.get("required_capability_id", "")))
		and _has_required_light(target)
		and _has_required_pressure_protection(target)
	)


func _has_required_light(target: Dictionary) -> bool:
	var capability_id := str(target.get("required_light_capability_id", "")).strip_edges()
	return capability_id.is_empty() or _profile.has_capability(capability_id)


func _light_required_note(target: Dictionary) -> String:
	var clue := str(target.get("clue_label", "")).strip_edges()
	return clue if not clue.is_empty() else "Stronger light required"


func _has_required_pressure_protection(target: Dictionary) -> bool:
	var capability_id := str(target.get("required_pressure_capability_id", "")).strip_edges()
	return capability_id.is_empty() or _profile.has_capability(capability_id)


func _pressure_required_note(target: Dictionary) -> String:
	var clue := str(target.get("clue_label", "")).strip_edges()
	return clue if not clue.is_empty() else "Abyssal signal | Pressure suit required"


func _is_resource_target(target: Dictionary) -> bool:
	return str(target.get("target_type", "")) == RESOURCE_TARGET_TYPE


func _is_regional_target(target: Dictionary) -> bool:
	return str(target.get("target_type", "")) == REGIONAL_TARGET_TYPE


func _is_finding_target(target: Dictionary) -> bool:
	return _is_resource_target(target) or _is_regional_target(target)


func _pending_metadata(target: Dictionary) -> Dictionary:
	var metadata := {}
	for field in ExpeditionDiscoveryState.METADATA_FIELDS:
		metadata[field] = str(target.get(field, ""))
	return metadata
