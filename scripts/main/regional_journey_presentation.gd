extends RefCounted

const SOUTHEAST_WRECK_SURVEY_ID := "southeast_wreck_archive_survey"
const SOUTHEAST_WRECK_DISCOVERY_ID := "southeast_wreck_archive_discovery"
const SOUTHEAST_WRECK_PENDING := "Wreck archive charted | Return to surface boat"
const SOUTHEAST_WRECK_SCAN_PROMPT := "Archive exposed | Q/SCAN: Survey wreck archive"


func promise_text(world, profile) -> String:
	if world == null or profile == null or not world.has_method("get_regional_journeys") or not world.has_method("get_survey_targets"):
		return ""
	var survey_records := _survey_records(world.get_survey_targets())
	for journey in world.get_regional_journeys():
		var required_discovery_id := str(journey.get("required_discovery_id", "")).strip_edges()
		var survey_id := str(journey.get("survey_target_id", "")).strip_edges()
		var target: Dictionary = survey_records.get(survey_id, {})
		var prerequisite: Dictionary = survey_records.get(required_discovery_id, {})
		var discovery_id := str(target.get("discovery_id", ""))
		if required_discovery_id.is_empty() or survey_id.is_empty() or discovery_id.is_empty():
			continue
		if not profile.has_completed_discovery(required_discovery_id) or profile.has_completed_discovery(discovery_id):
			continue
		var promise := str(prerequisite.get("next_lead_label", "")).strip_edges()
		if not promise.is_empty():
			return promise
	return ""


func nearby_scan_text(target: Dictionary) -> String:
	return SOUTHEAST_WRECK_SCAN_PROMPT if _is_wreck_target(target) else ""


func survey_complete_note(target: Dictionary) -> String:
	return SOUTHEAST_WRECK_PENDING if _is_wreck_target(target) else ""


func pending_return_text(metadata: Dictionary) -> String:
	return SOUTHEAST_WRECK_PENDING if str(metadata.get("finding_label", "")).find("Southeast wreck archive") != -1 else ""


func is_feedback_note(status_note: String) -> bool:
	return status_note.begins_with("Wreck") or status_note.begins_with("Archive")


func _is_wreck_target(target: Dictionary) -> bool:
	return (
		str(target.get("id", "")) == SOUTHEAST_WRECK_SURVEY_ID
		or str(target.get("discovery_id", "")) == SOUTHEAST_WRECK_DISCOVERY_ID
	)


func _survey_records(targets: Array) -> Dictionary:
	var values := {}
	for target in targets:
		var target_id := str(target.get("id", "")).strip_edges()
		var discovery_id := str(target.get("discovery_id", "")).strip_edges()
		if not target_id.is_empty() and not discovery_id.is_empty():
			values[target_id] = target
			values[discovery_id] = target
	return values
