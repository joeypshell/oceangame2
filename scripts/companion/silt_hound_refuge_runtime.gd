extends RefCounted

const INDIVIDUAL_ID := "silt_hound_juvenile_01"
const MEMORY_ID := "guarded_the_nest"
const REFUGE_ID := "deep_cache_burrow_refuge_01"
const CONTEXT_RADIUS := 104.0
const PAIR_RADIUS := 160.0

var _world
var _player
var _companion
var _hostiles
var _profile
var _has_upgrade := Callable()
var _status_sink := Callable()
var _visual
var _opportunity := {}
var _attempt := false
var _dug := false
var _saw_warning := false
var _live_cycle := false
var _previous_phase := ""
var _pending := {}
var _last_reason := "idle"


func bind_map(world, player, companion, hostiles, status_sink: Callable) -> void:
	_world = world
	_player = player
	_companion = companion
	_hostiles = hostiles
	_status_sink = status_sink
	_visual = world.burrow_refuge_presentation() if world.has_method("burrow_refuge_presentation") else null
	for opportunity in world.get_creature_memory_opportunities():
		if str(opportunity.get("target_id", "")) == REFUGE_ID and str(opportunity.get("memory_id", "")) == MEMORY_ID:
			_opportunity = opportunity.duplicate(true)


func bind_profile(profile, has_upgrade: Callable) -> void:
	_profile = profile
	_has_upgrade = has_upgrade


func in_context() -> bool:
	return _valid_nodes() and _player.global_position.distance_to(_visual.target) <= CONTEXT_RADIUS


func availability() -> Dictionary:
	if not _valid_nodes() or _opportunity.is_empty():
		return {"reason": "context_missing", "in_context": false}
	var reason := live_invalid_reason()
	if reason.is_empty():
		if bool(_visual.report()["opened"]):
			reason = "refuge_opened"
		elif _attempt:
			reason = "busy"
		elif not in_context():
			reason = "target_out_of_range"
		elif not _companion.can_receive_command(132.0):
			reason = "companion_unavailable"
		elif not _companion.excavate_path_allowed(_visual.target):
			reason = "path_blocked"
	return {"reason": "ready" if reason.is_empty() else reason,
		"in_context": in_context() and reason != "refuge_opened", "target": _visual.target}


func start() -> bool:
	if str(availability().get("reason", "")) != "ready":
		return false
	_attempt = true
	_dug = false
	_saw_warning = false
	_live_cycle = false
	_previous_phase = ""
	_last_reason = "attempt_started"
	return true


func complete_dig() -> bool:
	# Only the shared physical action owner calls this after its dig phase.
	if not _attempt or _dug or not live_invalid_reason().is_empty():
		return false
	if not _companion.excavate_target_reached() or not _visual.open_shelter():
		return false
	_dug = true
	_notify("Marl opened the refuge | The burrow group is moving inside")
	return true


func project_phase(phase: String, progress: float) -> void:
	if _valid_nodes():
		_visual.project_dig(phase, progress)


func advance(delta: float) -> void:
	if not _valid_nodes() or _world.get_tree().paused:
		return
	var hostile: Dictionary = _hostiles.state_for(str(_opportunity.get("hostile_id", ""))) if _hostiles != null else {}
	var phase := str(hostile.get("phase", ""))
	var threatening := int(hostile.get("health", 0)) > 0 and phase in ["warning", "lunge"]
	if _attempt:
		var invalid := live_invalid_reason()
		if not invalid.is_empty():
			cancel(invalid)
		else:
			# Read the bound authoritative controller, never caller-supplied flags.
			# A warning interrupted by recoil/defeat is not a completed cycle.
			if threatening and phase == "warning":
				_saw_warning = true
			if threatening and phase == "lunge" and _previous_phase == "warning" and _saw_warning:
				_live_cycle = true
			if phase not in ["warning", "lunge"]:
				_saw_warning = false
			_previous_phase = phase
	_visual.advance(delta, threatening)
	if _attempt and _dug and bool(_visual.report()["sheltered"]):
		_attempt = false
		if _live_cycle:
			_pending = {"individual_id": INDIVIDUAL_ID, "memory_id": MEMORY_ID,
				"opportunity_id": _opportunity["id"], "target_id": REFUGE_ID}
			_last_reason = "pending"
			_notify("Marl guarded the nest | Shared memory pending; not yet secured")
		else:
			_last_reason = "quiet_shelter"
			_notify("Burrow group sheltered | No shared threat this attempt")


func cancel(reason: String) -> void:
	_attempt = false
	_pending = {}
	_saw_warning = false
	_live_cycle = false
	_previous_phase = ""
	_last_reason = reason
	if _valid_nodes() and not bool(_visual.report()["opened"]):
		_visual.reset_closed()


func reset(reason: String) -> void:
	cancel(reason)
	_dug = false
	# A second sortie in the same world must not farm an already-open refuge.
	# A normal new-day/reload creates a fresh world; failure/retry explicitly reset.
	if _valid_nodes() and reason not in ["boat_habitat", "map_clear"]:
		_visual.reset_closed()


func live_invalid_reason() -> String:
	if not _valid_nodes():
		return "context_invalid"
	var identity: Dictionary = _companion.report().get("identity", {})
	var selected: Dictionary = _profile.companion_report().get("individual", {}) if _profile != null else {}
	for individual in [identity, selected]:
		if str(individual.get("individual_id", "")) != INDIVIDUAL_ID or str(individual.get("species_id", "")) != "silt_hound" or not bool(individual.get("rescue_committed", false)):
			return "wrong_companion"
	if (selected.get("earned_memory_ids", []) as Array).has(MEMORY_ID):
		return "memory_secured"
	for access_id in _opportunity.get("required_access_ids", []):
		if not _has_upgrade.is_valid() or not bool(_has_upgrade.call(str(access_id))):
			return "light_required"
	if _player.global_position.distance_to(_visual.target) > PAIR_RADIUS or _companion.global_position.distance_to(_visual.target) > PAIR_RADIUS:
		return "target_out_of_range"
	if str(_companion.report().get("state", "")) in ["separated", "recovery"]:
		return "companion_unavailable"
	return ""


func report() -> Dictionary:
	return {"target_id": REFUGE_ID, "attempt_active": _attempt, "physical_dig_complete": _dug,
		"live_warning_lunge": _live_cycle, "pending": _pending.duplicate(true),
		"last_reason": _last_reason, "group": _visual.report() if is_instance_valid(_visual) else {}}


func _valid_nodes() -> bool:
	return is_instance_valid(_world) and is_instance_valid(_player) and is_instance_valid(_companion) and is_instance_valid(_visual)


func _notify(message: String) -> void:
	if _status_sink.is_valid():
		_status_sink.call(message)
