extends RefCounted

const RUNTIME_DEBRIEF_PHASE := "debrief"
const SOURCE_ANALYSIS_PHASE := "night_debrief"
const REQUIRED_FIELDS := [
	"id",
	"required_discovery_id",
	"fragment_discovery_ids",
	"analysis_discovery_id",
	"analysis_phase",
	"analysis_label",
	"analysis_result_label",
	"next_lead_label",
	"commit_map_id",
	"commit_entry_id",
]
const FORBIDDEN_FIELDS := [
	"active",
	"analysis_ready",
	"completed",
	"completed_fragment_ids",
	"materials",
	"pending",
	"progress",
	"score",
	"selected_lead_id",
	"wallet",
]

var _source := {}
var _profile_state
var _source_failures: Array[String] = []


func configure(source, profile_state) -> Dictionary:
	_source = source.duplicate(true) if typeof(source) == TYPE_DICTIONARY else {}
	_profile_state = profile_state
	_source_failures = _validate_source(_source, profile_state)
	return report()


func report() -> Dictionary:
	var value := _base_report()
	if not _source_failures.is_empty():
		value["status"] = "invalid_source"
		value["failures"] = _source_failures.duplicate()
		return value
	var prerequisite_id := str(_source["required_discovery_id"])
	var analysis_id := str(_source["analysis_discovery_id"])
	var prerequisite_completed: bool = _profile_state.has_completed_discovery(prerequisite_id)
	var completed: bool = _profile_state.has_completed_discovery(analysis_id)
	var committed: Array[String] = []
	var remaining: Array[String] = []
	for raw_id in _source["fragment_discovery_ids"]:
		var fragment_id := str(raw_id)
		if _profile_state.has_completed_discovery(fragment_id):
			committed.append(fragment_id)
		else:
			remaining.append(fragment_id)
	var ready := prerequisite_completed and remaining.is_empty() and not completed
	value.merge({
		"prerequisite_completed": prerequisite_completed,
		"committed_fragment_ids": committed,
		"remaining_fragment_ids": remaining,
		"analysis_ready": ready,
		"completed": completed,
	}, true)
	if completed:
		value["status"] = "completed"
	elif not prerequisite_completed:
		value["status"] = "prerequisite_required"
	elif ready:
		value["status"] = "analysis_ready"
	else:
		value["status"] = "fragments_required"
	return value


func try_analyze(runtime_phase: String, persist := true) -> Dictionary:
	var current := report()
	if not bool(current.get("source_valid", false)):
		return _action_result("invalid_source", current)
	if runtime_phase != RUNTIME_DEBRIEF_PHASE:
		return _action_result("wrong_phase", current)
	if bool(current.get("completed", false)):
		return _action_result("already_completed", current)
	if not bool(current.get("prerequisite_completed", false)):
		return _action_result("prerequisite_required", current)
	if not current.get("remaining_fragment_ids", []).is_empty():
		return _action_result("fragments_missing", current)
	var completion: Dictionary = _profile_state.complete_discovery(
		str(_source["analysis_discovery_id"]),
		persist
	)
	var reason := str(completion.get("reason", "storage_error"))
	if not bool(completion.get("changed", false)):
		return _action_result(reason, report(), {"completion": completion})
	return _action_result("analysis_completed", report(), {
		"changed": true,
		"completion": completion,
		"result_label": str(_source["analysis_result_label"]),
		"next_lead_label": str(_source["next_lead_label"]),
	})


func _base_report() -> Dictionary:
	return {
		"status": "unconfigured",
		"source_valid": _source_failures.is_empty() and not _source.is_empty(),
		"investigation_id": str(_source.get("id", "")),
		"required_discovery_id": str(_source.get("required_discovery_id", "")),
		"required_fragment_ids": _source.get("fragment_discovery_ids", []).duplicate(),
		"committed_fragment_ids": [],
		"remaining_fragment_ids": [],
		"analysis_discovery_id": str(_source.get("analysis_discovery_id", "")),
		"analysis_label": str(_source.get("analysis_label", "")),
		"analysis_result_label": str(_source.get("analysis_result_label", "")),
		"next_lead_label": str(_source.get("next_lead_label", "")),
		"prerequisite_completed": false,
		"analysis_ready": false,
		"completed": false,
	}


func _action_result(status: String, state: Dictionary, extra := {}) -> Dictionary:
	var value := {"status": status, "changed": false, "state": state.duplicate(true)}
	for key in extra:
		value[key] = extra[key]
	return value


func _validate_source(source: Dictionary, profile_state) -> Array[String]:
	var failures: Array[String] = []
	if source.is_empty():
		return ["investigation source must be a non-empty object"]
	if profile_state == null or not profile_state.has_method("has_completed_discovery") or not profile_state.has_method("complete_discovery"):
		failures.append("profile state does not support discovery transactions")
	for field in REQUIRED_FIELDS:
		if not source.has(field):
			failures.append("missing %s" % field)
	for field in FORBIDDEN_FIELDS:
		if source.has(field):
			failures.append("source contains mutable field %s" % field)
	if not failures.is_empty():
		return failures
	for field in ["id", "required_discovery_id", "analysis_discovery_id", "commit_map_id", "commit_entry_id"]:
		if str(source[field]).strip_edges().is_empty():
			failures.append("%s must be a non-empty id" % field)
	for field in ["analysis_label", "analysis_result_label", "next_lead_label"]:
		if str(source[field]).strip_edges().is_empty():
			failures.append("%s must be non-empty text" % field)
	if str(source["analysis_phase"]) != SOURCE_ANALYSIS_PHASE:
		failures.append("analysis_phase must be %s" % SOURCE_ANALYSIS_PHASE)
	var fragments = source["fragment_discovery_ids"]
	if typeof(fragments) != TYPE_ARRAY or fragments.size() != 2:
		failures.append("fragment_discovery_ids must contain exactly two ids")
	else:
		var seen := {}
		for value in fragments:
			var fragment_id := str(value).strip_edges()
			if fragment_id.is_empty() or seen.has(fragment_id):
				failures.append("fragment_discovery_ids must be unique non-empty ids")
			else:
				seen[fragment_id] = true
		if seen.has(str(source["required_discovery_id"])) or seen.has(str(source["analysis_discovery_id"])):
			failures.append("fragment ids must be distinct from prerequisite and analysis ids")
	return failures
