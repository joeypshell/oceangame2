extends RefCounted

const PHASE_DEBRIEF := "debrief"
const READINESS_READY := "ready"
const READINESS_PREPARE := "prepare"
const READINESS_INVALID := "invalid"
const WRECK_NETWORK_LEAD_IDS := {
	"western_chasm_wreck_fragment_journey": true,
	"abyssal_shelf_wreck_fragment_journey": true,
}
const REPORT_FIELDS := {
	"lead_id": true,
	"lead_type": true,
	"label": true,
	"summary": true,
	"active_guidance": true,
	"order": true,
	"route_context": true,
	"eligibility_context": true,
	"readiness_state": true,
	"readiness_label": true,
}


static func resolve(world, profile, project_runtime, day_state, daily_conditions) -> Dictionary:
	var candidates := _source_candidates(world)
	var eligible: Array[Dictionary] = []
	var invalid: Array[Dictionary] = []
	for candidate in candidates:
		var outcome := _resolve_candidate(
			candidate,
			world,
			profile,
			project_runtime,
			day_state,
			daily_conditions
		)
		var outcome_status := str(outcome.get("status", "hidden"))
		if outcome_status == "eligible":
			eligible.append(outcome["report"])
		elif outcome_status == "invalid":
			invalid.append(outcome["report"])
	eligible = _focus_main_investigation_pair(eligible)

	var eligible_ids: Array[String] = []
	for report in eligible:
		eligible_ids.append(str(report.get("lead_id", "")))
	var status := "inactive"
	if candidates.is_empty():
		status = "no_source_leads"
	elif eligible.size() == 2:
		status = "choice_ready"
	elif eligible.size() > 2:
		status = "invalid_choice_count"
	return {
		"status": status,
		"source_lead_count": candidates.size(),
		"eligible_count": eligible.size(),
		"eligible_ids": eligible_ids,
		"eligible_leads": eligible.duplicate(true),
		"invalid_leads": invalid.duplicate(true),
	}


static func _focus_main_investigation_pair(leads: Array[Dictionary]) -> Array[Dictionary]:
	var investigation: Array[Dictionary] = []
	for lead in leads:
		if WRECK_NETWORK_LEAD_IDS.has(str(lead.get("lead_id", ""))):
			investigation.append(lead)
	return investigation if investigation.size() == WRECK_NETWORK_LEAD_IDS.size() else leads


static func _source_candidates(world) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if world == null:
		return candidates
	var collections := [
		{"getter": "get_regional_journeys", "lead_type": "regional_journey"},
		{"getter": "get_daily_conditions", "lead_type": "daily_condition"},
	]
	for collection in collections:
		var getter := str(collection["getter"])
		if not world.has_method(getter):
			continue
		for value in world.call(getter):
			if typeof(value) != TYPE_DICTIONARY:
				continue
			var parent := value as Dictionary
			if typeof(parent.get("expedition_lead")) != TYPE_DICTIONARY:
				continue
			candidates.append({
				"parent": parent.duplicate(true),
				"expected_type": str(collection["lead_type"]),
			})
	candidates.sort_custom(func(left, right):
		var left_lead: Dictionary = left["parent"]["expedition_lead"]
		var right_lead: Dictionary = right["parent"]["expedition_lead"]
		var left_order := int(left_lead.get("order", -1))
		var right_order := int(right_lead.get("order", -1))
		if left_order == right_order:
			return str(left["parent"].get("id", "")) < str(right["parent"].get("id", ""))
		return left_order < right_order
	)
	return candidates


static func _resolve_candidate(
	candidate: Dictionary,
	world,
	profile,
	project_runtime,
	day_state,
	daily_conditions
) -> Dictionary:
	var parent: Dictionary = candidate["parent"]
	var lead: Dictionary = parent["expedition_lead"]
	var expected_type := str(candidate["expected_type"])
	var report := _base_report(parent, lead)
	if not _valid_source_report(report) or str(report["lead_type"]) != expected_type:
		return _invalid(report, "Source lead metadata is invalid")
	if expected_type == "regional_journey":
		return _resolve_regional(
			report,
			parent,
			world,
			profile,
			project_runtime
		)
	return _resolve_daily(report, parent, day_state, daily_conditions)


static func _resolve_regional(
	report: Dictionary,
	journey: Dictionary,
	world,
	profile,
	project_runtime
) -> Dictionary:
	if profile == null or world == null:
		return _invalid(report, "Regional source owners unavailable")
	var required_discovery_id := str(journey.get("required_discovery_id", ""))
	var survey_id := str(journey.get("survey_target_id", ""))
	var survey := _record_by_id(
		world.get_survey_targets() if world.has_method("get_survey_targets") else [],
		survey_id
	)
	var survey_discovery_id := str(survey.get("discovery_id", ""))
	if required_discovery_id.is_empty() or survey.is_empty() or survey_discovery_id.is_empty():
		return _invalid(report, "Regional source references are invalid")
	if not profile.has_completed_discovery(required_discovery_id):
		return {"status": "hidden"}
	if profile.has_completed_discovery(survey_discovery_id):
		return _invalid(report, "Relay survey already committed")

	var readiness := _regional_readiness(
		journey,
		survey,
		world,
		profile,
		project_runtime
	)
	if str(readiness.get("state", READINESS_INVALID)) == READINESS_INVALID:
		return _invalid(report, str(readiness.get("label", "Regional readiness is invalid")))
	report["eligibility_context"] = "Known relay, survey unresolved"
	report["readiness_state"] = str(readiness["state"])
	report["readiness_label"] = str(readiness["label"])
	return {"status": "eligible", "report": report}


static func _regional_readiness(
	journey: Dictionary,
	survey: Dictionary,
	world,
	profile,
	project_runtime
) -> Dictionary:
	var capability_ids: Array[String] = []
	for value in [
		journey.get("required_capability_id", ""),
		survey.get("required_capability_id", ""),
	]:
		var capability_id := str(value)
		if capability_id.is_empty():
			return {"state": READINESS_INVALID, "label": "Required capability reference is missing"}
		if not capability_ids.has(capability_id):
			capability_ids.append(capability_id)

	var preparation: Array[String] = []
	var projects: Array = world.get_material_projects() if world.has_method("get_material_projects") else []
	for capability_id in capability_ids:
		if profile.has_capability(capability_id):
			continue
		var project := _project_for_capability(projects, capability_id)
		if project.is_empty() or project_runtime == null or not project_runtime.has_method("status_for"):
			return {"state": READINESS_INVALID, "label": "Capability project reference is invalid"}
		var project_status := str(project_runtime.status_for(str(project.get("id", ""))))
		if project_status not in [
			"ready",
			"incomplete",
			"prerequisite_required",
			"knowledge_required",
		]:
			return {
				"state": READINESS_INVALID,
				"label": "%s has invalid status" % _project_label(project),
			}
		preparation.append(_project_status_label(project, project_status))
	if preparation.is_empty():
		return {"state": READINESS_READY, "label": "Ready | Required equipment installed"}
	return {
		"state": READINESS_PREPARE,
		"label": "Prepare | %s" % " | ".join(preparation),
	}


static func _resolve_daily(
	report: Dictionary,
	condition: Dictionary,
	day_state,
	daily_conditions
) -> Dictionary:
	if day_state == null or daily_conditions == null:
		return _invalid(report, "Daily condition owners unavailable")
	var condition_id := str(condition.get("id", ""))
	var day_phase := str(day_state.phase)
	var active_ids: Array = (
		daily_conditions.next_ids()
		if day_phase == PHASE_DEBRIEF
		else daily_conditions.current_ids()
	)
	if not active_ids.has(condition_id):
		return _invalid(
			report,
			"Not forecast for next day" if day_phase == PHASE_DEBRIEF else "Not active today"
		)
	report["eligibility_context"] = (
		"Forecast for next day"
		if day_phase == PHASE_DEBRIEF
		else "Active today"
	)
	report["readiness_state"] = READINESS_READY
	report["readiness_label"] = "Ready | Forecast opportunity"
	return {"status": "eligible", "report": report}


static func _base_report(parent: Dictionary, lead: Dictionary) -> Dictionary:
	return {
		"lead_id": str(parent.get("id", "")),
		"lead_type": str(lead.get("lead_type", "")),
		"label": str(lead.get("label", "")),
		"summary": str(lead.get("summary", "")),
		"active_guidance": str(lead.get("active_guidance", "")),
		"order": int(lead.get("order", -1)),
		"route_context": str(parent.get("route_context", "")),
		"eligibility_context": "",
		"readiness_state": READINESS_INVALID,
		"readiness_label": "",
	}


static func _valid_source_report(report: Dictionary) -> bool:
	if report.size() != REPORT_FIELDS.size():
		return false
	for field in REPORT_FIELDS:
		if not report.has(field):
			return false
	return (
		not str(report["lead_id"]).is_empty()
		and not str(report["label"]).is_empty()
		and not str(report["summary"]).is_empty()
		and not str(report["active_guidance"]).is_empty()
		and not str(report["route_context"]).is_empty()
		and int(report["order"]) >= 0
	)


static func _invalid(report: Dictionary, context: String) -> Dictionary:
	report["eligibility_context"] = context
	report["readiness_state"] = READINESS_INVALID
	report["readiness_label"] = "Unavailable | %s" % context
	return {"status": "invalid", "report": report}


static func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for value in records:
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == record_id:
			return (value as Dictionary).duplicate(true)
	return {}


static func _project_for_capability(projects: Array, capability_id: String) -> Dictionary:
	for value in projects:
		if (
			typeof(value) == TYPE_DICTIONARY
			and str(value.get("unlocks_capability_id", "")) == capability_id
		):
			return (value as Dictionary).duplicate(true)
	return {}


static func _project_label(project: Dictionary) -> String:
	var label := str(project.get("project_label", "")).strip_edges()
	if not label.is_empty():
		return label
	return str(project.get("unlocks_capability_id", "Project")).replace("_", " ").capitalize()


static func _project_status_label(project: Dictionary, status: String) -> String:
	var label := _project_label(project)
	match status:
		"ready":
			return "%s ready to build" % label
		"incomplete":
			return "%s needs materials" % label
		"prerequisite_required":
			return "%s needs prerequisite" % label
		"knowledge_required":
			return "%s needs discovery" % label
	return "%s unavailable" % label
