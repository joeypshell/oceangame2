extends RefCounted

const JOURNEY_ID := "scanner_cutter_first_return"
const ARTIFACT_ROLE := "blueprint_artifact"
const PAYOFF_ROLE := "sealed_payoff"


func objective_text(world, profile) -> String:
	var records := _journey_records(world)
	var artifact: Dictionary = records.get(ARTIFACT_ROLE, {})
	var payoff: Dictionary = records.get(PAYOFF_ROLE, {})
	if artifact.is_empty() or payoff.is_empty() or profile == null:
		return ""
	var scanner_id := str(artifact.get("required_capability_id", "")).strip_edges()
	var blueprint_id := str(artifact.get("scan_reward_id", "")).strip_edges()
	var cutter_id := str(payoff.get("required_tool_id", "")).strip_edges()
	if scanner_id.is_empty() or not profile.has_capability(scanner_id):
		return ""
	if blueprint_id.is_empty() or not profile.has_completed_discovery(blueprint_id):
		return str(artifact.get("journey_lead_label", "")).strip_edges()
	if cutter_id.is_empty() or not profile.has_capability(cutter_id):
		return ""
	var target_id := str(payoff.get("id", "")).strip_edges()
	if world.has_method("is_salvage_collected") and world.is_salvage_collected(target_id):
		return str(payoff.get("next_mystery_label", "")).strip_edges()
	return str(payoff.get("return_lead_label", "")).strip_edges()


func result_is_superseded(world, profile, result_text: String) -> bool:
	if result_text.is_empty() or profile == null:
		return false
	var records := _journey_records(world)
	var artifact: Dictionary = records.get(ARTIFACT_ROLE, {})
	var payoff: Dictionary = records.get(PAYOFF_ROLE, {})
	var cutter_id := str(payoff.get("required_tool_id", "")).strip_edges()
	var finding_label := str(artifact.get("finding_label", "")).strip_edges()
	return (
		not cutter_id.is_empty()
		and profile.has_capability(cutter_id)
		and not finding_label.is_empty()
		and result_text.begins_with(finding_label)
	)


func completion_note(target: Dictionary, score: int) -> String:
	if str(target.get("journey_id", "")) != JOURNEY_ID or str(target.get("journey_role", "")) != PAYOFF_ROLE:
		return ""
	var payoff := str(target.get("payoff_label", "")).strip_edges()
	if payoff.is_empty():
		return ""
	return "%s +%d" % [payoff, score]


func _journey_records(world) -> Dictionary:
	var records := {}
	if world == null or not world.has_method("get_survey_targets") or not world.has_method("get_tool_targets"):
		return records
	for target in world.get_survey_targets():
		_add_record(records, target)
	for target in world.get_tool_targets():
		_add_record(records, target)
	return records


func _add_record(records: Dictionary, target: Dictionary) -> void:
	if str(target.get("journey_id", "")) != JOURNEY_ID:
		return
	var role := str(target.get("journey_role", "")).strip_edges()
	if role in [ARTIFACT_ROLE, PAYOFF_ROLE]:
		records[role] = target
