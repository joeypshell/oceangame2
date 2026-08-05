extends RefCounted

const CURRENT_EVENT := "current_cycle_completed"
const TERRITORIAL_EVENT := "territorial_threat_cycle_resolved"
const PHASE_WARNING := "warning"
const PHASE_LUNGE := "lunge"
const PHASE_RECOVERY := "recovery"
const PHASE_RETURNING := "returning"
const PHASE_DEFEATED := "defeated"

var _profile
var _has_upgrade := Callable()
var _has_capability := Callable()
var _opportunities: Array = []
var _pending_memory_ids: Array[String] = []
var _current_trace := {}
var _hostile_traces := {}
var _last_player_position := Vector2.ZERO
var _has_last_player_position := false


func bind_map(
	world,
	profile,
	has_upgrade: Callable,
	has_capability: Callable,
	preserve_sortie := false
) -> void:
	_profile = profile
	_has_upgrade = has_upgrade
	_has_capability = has_capability
	if not preserve_sortie:
		discard_uncommitted("map_reload")
	else:
		_reset_observation()
	var source_records: Array = (
		world.get_creature_memory_opportunities()
		if world != null and world.has_method("get_creature_memory_opportunities")
		else []
	)
	if not source_records.is_empty() or not preserve_sortie:
		_opportunities = source_records


func observe_current(
	world,
	player_position: Vector2,
	gate_result: Dictionary,
	context: Dictionary
) -> Dictionary:
	var previous_position := _last_player_position
	var had_previous := _has_last_player_position
	_last_player_position = player_position
	_has_last_player_position = true
	if not _context_is_shared(context):
		_current_trace = {}
		return _result(false, "companion_not_together")

	if bool(gate_result.get("inside", false)):
		var gate_id := str(gate_result.get("id", ""))
		var opportunity := _opportunity(CURRENT_EVENT, gate_id)
		if opportunity.is_empty() or bool(gate_result.get("blocked", false)) or not _has_required_access(opportunity):
			_current_trace = {}
			return _result(false, "ineligible_current")
		var gate: Dictionary = world.get_current_gate_at(player_position) if world != null else {}
		var gate_rect: Rect2 = gate.get("rect", Rect2())
		if (
			_current_trace.is_empty()
			and had_previous
			and gate_rect.has_area()
			and not gate_rect.has_point(previous_position)
		):
			_current_trace = {
				"opportunity": opportunity,
				"gate": gate,
				"entry_position": previous_position,
				"mode": str(context.get("mode", "independent")),
			}
		return _result(false, "current_in_progress")

	if _current_trace.is_empty():
		return _result(false, "outside_current")
	var trace: Dictionary = _current_trace
	_current_trace = {}
	if not _crossed_against_current(trace, player_position):
		return _result(false, "incomplete_current_crossing")
	return _qualify(trace.get("opportunity", {}), context, str(trace.get("mode", "independent")))


func observe_hostiles(
	hostiles,
	event: Dictionary,
	player_position: Vector2,
	context: Dictionary
) -> Dictionary:
	for opportunity in _opportunities:
		if typeof(opportunity) != TYPE_DICTIONARY or str(opportunity.get("event_kind", "")) != TERRITORIAL_EVENT:
			continue
		var target_id := str(opportunity.get("target_id", ""))
		var state: Dictionary = hostiles.state_for(target_id) if hostiles != null and hostiles.has_method("state_for") else {}
		var result := _observe_hostile_opportunity(opportunity, state, event, player_position, context)
		if bool(result.get("changed", false)):
			return result
	return _result(false, "no_territorial_memory")


func commit_at_boat(at_canonical_boat: bool) -> Dictionary:
	if _pending_memory_ids.is_empty():
		return _result(false, "nothing_pending")
	if not at_canonical_boat:
		return _result(false, "canonical_boat_required")
	if _profile == null or not _profile.has_method("earn_companion_memory"):
		return _result(false, "profile_unavailable")

	var committed: Array[String] = []
	var failures: Array[String] = []
	for memory_id in _pending_memory_ids.duplicate():
		var result: Dictionary = _profile.earn_companion_memory(memory_id, true)
		var reason := str(result.get("reason", ""))
		if bool(result.get("changed", false)) or reason == "already_earned":
			_pending_memory_ids.erase(memory_id)
			if reason != "already_earned":
				committed.append(memory_id)
		else:
			failures.append("%s:%s" % [memory_id, reason])
	if not failures.is_empty():
		return {
			"changed": not committed.is_empty(),
			"reason": "storage_error",
			"committed_memory_ids": committed,
			"failures": failures,
			"note": "Spark Ray memory could not be secured",
		}
	return {
		"changed": not committed.is_empty(),
		"reason": "committed" if not committed.is_empty() else "already_committed",
		"committed_memory_ids": committed,
		"note": "Spark Ray memory secured at the boat" if not committed.is_empty() else "",
	}


func discard_uncommitted(_reason := "failure") -> Dictionary:
	var discarded := _pending_memory_ids.duplicate()
	_pending_memory_ids.clear()
	_reset_observation()
	return {
		"changed": not discarded.is_empty(),
		"reason": "discarded" if not discarded.is_empty() else "nothing_pending",
		"discarded_memory_ids": discarded,
	}


func report() -> Dictionary:
	return {
		"pending_memory_ids": _pending_memory_ids.duplicate(),
		"current_in_progress": not _current_trace.is_empty(),
		"hostile_trace_ids": _hostile_traces.keys(),
	}


func _observe_hostile_opportunity(
	opportunity: Dictionary,
	state: Dictionary,
	event: Dictionary,
	player_position: Vector2,
	context: Dictionary
) -> Dictionary:
	var target_id := str(opportunity.get("target_id", ""))
	if state.is_empty() or not _context_is_shared(context) or not _has_required_access(opportunity):
		_hostile_traces.erase(target_id)
		return _result(false, "ineligible_territorial_event")
	var phase := str(state.get("phase", ""))
	var event_kind := str(event.get("kind", "")) if str(event.get("id", "")) == target_id else ""
	if event_kind == "retreat":
		_hostile_traces.erase(target_id)
		return _result(false, "territory_retreated")
	if phase == PHASE_WARNING and not _hostile_traces.has(target_id):
		_hostile_traces[target_id] = {
			"warning_seen": true,
			"lunge_seen": false,
			"mode": str(context.get("mode", "independent")),
		}
	if not _hostile_traces.has(target_id):
		return _result(false, "warning_not_seen")
	var trace: Dictionary = _hostile_traces[target_id]
	if phase == PHASE_LUNGE or event_kind in ["lunge", "contact"]:
		trace["lunge_seen"] = true
	_hostile_traces[target_id] = trace
	var territory: Rect2 = state.get("territory_rect", Rect2())
	var resolved := event_kind == "contact" or phase in [PHASE_RECOVERY, PHASE_DEFEATED]
	if bool(trace.get("warning_seen", false)) and bool(trace.get("lunge_seen", false)) and resolved and territory.has_point(player_position):
		_hostile_traces.erase(target_id)
		return _qualify(opportunity, context, str(trace.get("mode", "independent")))
	if phase == PHASE_RETURNING:
		_hostile_traces.erase(target_id)
	return _result(false, "territorial_event_in_progress")


func _qualify(opportunity: Dictionary, context: Dictionary, mode: String) -> Dictionary:
	if opportunity.is_empty() or not _opportunity_matches_active(opportunity):
		return _result(false, "wrong_individual")
	var memory_id := str(opportunity.get("memory_id", ""))
	if memory_id.is_empty() or _pending_memory_ids.has(memory_id) or _is_committed(memory_id):
		return _result(false, "already_qualified")
	_pending_memory_ids.append(memory_id)
	_pending_memory_ids.sort()
	var callsign := str(context.get("callsign", "Spark Ray"))
	var memory_label := "holding the flow" if memory_id == "held_the_flow" else "standing ground"
	return {
		"changed": true,
		"reason": "memory_qualified",
		"memory_id": memory_id,
		"mode": mode,
		"note": "%s remembers %s | Return to the boat" % [callsign, memory_label],
	}


func _crossed_against_current(trace: Dictionary, exit_position: Vector2) -> bool:
	var gate: Dictionary = trace.get("gate", {})
	var rect: Rect2 = gate.get("rect", Rect2())
	var push := _direction_vector(str(gate.get("current_direction", "")))
	if not rect.has_area() or push == Vector2.ZERO:
		return false
	var center := rect.get_center()
	var half_span := rect.size.x * 0.5 if absf(push.x) > 0.0 else rect.size.y * 0.5
	var entry_position: Vector2 = trace.get("entry_position", center)
	var entry_projection := (entry_position - center).dot(push)
	var exit_projection := (exit_position - center).dot(push)
	return entry_projection >= half_span and exit_projection <= -half_span


func _opportunity(event_kind: String, target_id: String) -> Dictionary:
	for opportunity in _opportunities:
		if (
			typeof(opportunity) == TYPE_DICTIONARY
			and str(opportunity.get("event_kind", "")) == event_kind
			and str(opportunity.get("target_id", "")) == target_id
		):
			return opportunity
	return {}


func _context_is_shared(context: Dictionary) -> bool:
	return bool(context.get("active", false)) and bool(context.get("together", false))


func _opportunity_matches_active(opportunity: Dictionary) -> bool:
	if _profile == null or not _profile.has_method("companion_report"):
		return false
	var companion: Dictionary = _profile.companion_report()
	var individual: Dictionary = companion.get("individual", {})
	return (
		str(companion.get("active_individual_id", "")) == str(individual.get("individual_id", ""))
		and str(individual.get("individual_id", "")) == str(opportunity.get("individual_id", ""))
		and str(individual.get("species_id", "")) == str(opportunity.get("species_id", ""))
	)


func _has_required_access(opportunity: Dictionary) -> bool:
	for access_id_value in opportunity.get("required_access_ids", []):
		var access_id := str(access_id_value)
		var has_access := (
			(_has_upgrade.is_valid() and bool(_has_upgrade.call(access_id)))
			or (_has_capability.is_valid() and bool(_has_capability.call(access_id)))
		)
		if not has_access:
			return false
	return true


func _is_committed(memory_id: String) -> bool:
	if _profile == null or not _profile.has_method("companion_report"):
		return false
	var individual: Dictionary = _profile.companion_report().get("individual", {})
	return (individual.get("earned_memory_ids", []) as Array).has(memory_id)


func _reset_observation() -> void:
	_current_trace = {}
	_hostile_traces = {}
	_last_player_position = Vector2.ZERO
	_has_last_player_position = false


func _direction_vector(direction: String) -> Vector2:
	match direction:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
	return Vector2.ZERO


func _result(changed: bool, reason: String) -> Dictionary:
	return {"changed": changed, "reason": reason}
