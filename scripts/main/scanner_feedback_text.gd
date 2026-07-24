extends RefCounted

const REGIONAL_TARGET_TYPE := "regional"
const RESOURCE_TARGET_TYPE := "resource"

var _regional_presentation


func _init(regional_presentation) -> void:
	_regional_presentation = regional_presentation


func identification_note(target: Dictionary) -> String:
	var label := str(target.get("scan_subject_label", "Unknown subject")).strip_edges()
	var description := str(target.get("scan_subject_description", "")).strip_edges()
	var note := "Identified: %s | %s" % [label, description] if not description.is_empty() else "Identified: %s" % label
	if str(target.get("source_type", "")) == "tool_target":
		note += " | Tab Cutter | Q/USE"
	return note


func survey_complete_note(target: Dictionary) -> String:
	var regional_note: String = _regional_presentation.survey_complete_note(target)
	if not regional_note.is_empty():
		return regional_note
	if not str(target.get("required_pressure_capability_id", "")).strip_edges().is_empty():
		return "Abyssal source charted | Return to boat"
	if str(target.get("scan_reward_kind", "")) == "blueprint":
		return "Blueprint identified | Return to surface boat"
	return "Research complete - return to surface boat" if _is_resource_target(target) else "Survey complete - return to surface boat"


func completed_note(target: Dictionary) -> String:
	return str(target.get("finding_label", "Finding already logged"))


func completed_overlay_text(target: Dictionary) -> String:
	return str(target.get("finding_label", "Finding logged"))


func pending_return_text(metadata: Dictionary) -> String:
	var pending_label := str(metadata.get("pending_label", "")).strip_edges()
	if not pending_label.is_empty():
		return pending_label
	var regional_note: String = _regional_presentation.pending_return_text(metadata)
	if not regional_note.is_empty():
		return regional_note
	if not str(metadata.get("required_pressure_capability_id", "")).is_empty():
		return "Abyssal chart pending | Return to surface boat before another scan"
	if str(metadata.get("scan_reward_kind", "")) == "blueprint":
		return "Blueprint pending | Return to surface boat before another scan"
	return "Research pending | Return to surface boat before another scan" if str(metadata.get("target_type", "")) == RESOURCE_TARGET_TYPE else "Discovery pending | Return to surface boat before another scan"


func nearby_scan_text(target: Dictionary, clue: String, active_target_id: String, active_note: String) -> String:
	if active_target_id == str(target.get("id", "")):
		return active_note
	var regional_prompt: String = _regional_presentation.nearby_scan_text(target)
	if not regional_prompt.is_empty():
		return regional_prompt
	var label := str(target.get("interaction_label", "Survey signal")).strip_edges()
	var prompt := "Hold Q/USE to scan: %s" % (label if not label.is_empty() else "Survey signal")
	return "%s\n%s" % [clue, prompt] if not clue.is_empty() else prompt


func _is_resource_target(target: Dictionary) -> bool:
	return str(target.get("target_type", "")) == RESOURCE_TARGET_TYPE
