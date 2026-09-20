extends RefCounted

const Geometry := preload("res://scripts/companion/silt_hound_pin_geometry.gd")
const CONTEXT_ID := "deep_cache_eel_marl_ground_pin"
const TARGET_ID := "deep_cache_territorial_eel"
const INDIVIDUAL_ID := "silt_hound_juvenile_01"
const ACTION_ID := "ground_pin"
const COOLDOWN_SECONDS := 8.0
const APPROACH_SECONDS := 1.5
const PLANT_SECONDS := 0.12
const SEPARATION_PX := 160.0

var _world
var _player
var _companion
var _hostiles
var _profile
var _has_upgrade := Callable()
var _status_sink := Callable()
var _context := {}
var _anchor := Vector2.ZERO
var _state := "idle"
var _elapsed := 0.0
var _planted_seconds := 0.0
var _cooldown := 0.0
var _last_reason := "ready"


func bind_map(world, player, companion, hostiles, status_sink: Callable) -> void:
	clear_map()
	_world = world
	_player = player
	_companion = companion
	_hostiles = hostiles
	_status_sink = status_sink
	_context = _source()


func bind_profile(profile, has_upgrade: Callable) -> void:
	_profile = profile
	_has_upgrade = has_upgrade


func clear_map() -> void:
	cancel("map_clear")
	_world = null
	_player = null
	_companion = null
	_hostiles = null
	_profile = null
	_context = {}
	_cooldown = 0.0


func command() -> Dictionary:
	if not learned():
		return {}
	var reason := _availability().get("reason", "unavailable") as String
	return {"id": ACTION_ID, "label": "Ground Pin", "enabled": reason == "ready", "reason": reason, "denial": _denial(reason)}


func dispatch() -> Dictionary:
	var available := _availability()
	var reason := str(available.get("reason"))
	if reason != "ready":
		_notify("Ground Pin | " + _denial(reason))
		return {"changed": false, "reason": reason}
	_anchor = available["anchor"]
	if not _companion.begin_ground_pin_approach(_anchor):
		return {"changed": false, "reason": "busy"}
	_state = "approaching"
	_elapsed = 0.0
	_planted_seconds = 0.0
	_notify("Marl plants at the floor - draw the eel low")
	return {"changed": true, "reason": "started"}


func advance(delta: float) -> void:
	if _valid() and _world.get_tree().paused:
		return
	_cooldown = maxf(0.0, _cooldown - maxf(0.0, delta))
	if not busy():
		return
	if not _live_valid():
		cancel("approach_invalid")
		return
	if _state == "holding":
		if not support_hold_valid():
			cancel("hold_invalid")
		return
	var target: Dictionary = _hostiles.state_for(TARGET_ID)
	if target.get("phase") not in ["warning", "lunge"]:
		cancel("whiff")
		return
	_elapsed += maxf(0.0, delta)
	if _elapsed >= APPROACH_SECONDS:
		cancel("whiff")
		return
	if _companion.global_position.distance_to(_anchor) <= 1.0:
		_state = "planted"
		_companion.set_ground_pin_phase("planted", target["position"])
		_planted_seconds += maxf(0.0, delta)
		if _planted_seconds >= PLANT_SECONDS and support_hold_valid():
			if _hostiles.request_support_hold(_world, TARGET_ID, self):
				_state = "holding"
				_companion.set_ground_pin_phase("holding", target["position"])
				_notify("Marl grips the eel - strike or retreat (1.75s)")


func support_hold_valid() -> bool:
	if not _live_valid() or _state not in ["planted", "holding"] or _planted_seconds < PLANT_SECONDS:
		return false
	var target: Dictionary = _hostiles.state_for(TARGET_ID)
	return target.get("phase") in ["warning", "lunge", "support_held"] and _companion.global_position.distance_to(_anchor) <= 1.0 and Geometry.contact_clear(_world, _companion, target.get("position", Vector2.INF), _player)


func cancel(reason: String) -> void:
	if _state == "holding" and _hostiles != null:
		if _hostiles.release_support_hold(_world, TARGET_ID, self, reason):
			return
	if busy():
		on_support_hold_released(reason)


func on_support_hold_released(reason: String) -> void:
	# Hostile owner calls this before normal weapon damage or reset; no cycle.
	_state = "idle"
	_last_reason = reason
	_cooldown = COOLDOWN_SECONDS
	if is_instance_valid(_companion):
		_companion.finish_ground_pin()
	_notify("Ground Pin ended - " + _denial(reason))


func reset_transient(reason: String) -> void:
	cancel(reason)
	_cooldown = 0.0


func busy() -> bool:
	return _state in ["approaching", "planted", "holding"]


func learned() -> bool:
	if not _valid() or _profile == null:
		return false
	var identity: Dictionary = _profile.companion_report().get("individual", {})
	return identity.get("individual_id") == INDIVIDUAL_ID and identity.get("species_id") == "silt_hound" and identity.get("rescue_committed", false) and identity.get("selected_adaptation_id") == "root_claws" and _companion.report().get("identity", {}).get("individual_id") == INDIVIDUAL_ID


func report() -> Dictionary:
	return {"adaptation_id": "root_claws" if learned() else "", "ground_pin_available": learned(), "state": _state, "busy": busy(), "anchor": _anchor, "cooldown_seconds": _cooldown, "last_reason": _last_reason}


func _availability() -> Dictionary:
	if not learned():
		return {"reason": "root_claws_required"}
	if busy() or _companion.report()["excavate"]["active"]:
		return {"reason": "busy"}
	if _cooldown > 0.0:
		return {"reason": "cooldown"}
	if _context.is_empty() or _source() != _context:
		return {"reason": "source_invalid"}
	if not _access_allowed():
		return {"reason": "equipment_required"}
	if not _companion.can_receive_command(SEPARATION_PX):
		return {"reason": "separated"}
	var target: Dictionary = _hostiles.state_for(TARGET_ID)
	if target.get("phase") not in ["warning", "lunge"]:
		return {"reason": "not_threatening"}
	var nearest := Vector2.INF
	var best_distance := INF
	var low_target := false
	for cell in _context.get("ground_anchors", []):
		var point := Geometry.planted_point(_world, cell)
		var offset: Vector2 = target["position"] - point
		if absf(offset.y) > 48.0 or absf(offset.x) > 80.0:
			continue
		low_target = true
		if _player.global_position.distance_to(point) > SEPARATION_PX or not Geometry.anchor_valid(_world, _companion, point, _player) or not Geometry.approach_clear(_world, _companion, point, _player):
			continue
		var distance: float = _companion.global_position.distance_to(point)
		if distance < best_distance:
			nearest = point
			best_distance = distance
	if nearest == Vector2.INF:
		return {"reason": "path_blocked" if low_target else "target_high"}
	return {"reason": "ready", "anchor": nearest}


func _live_valid() -> bool:
	if not learned() or not _access_allowed() or _source() != _context:
		return false
	if not _companion.ground_pin_active() or _player.global_position.distance_to(_companion.global_position) > SEPARATION_PX:
		return false
	if not Geometry.clear_line(_world, _companion, _player, _player.global_position, _companion.global_position):
		return false
	return Geometry.anchor_valid(_world, _companion, _anchor, _player) and Geometry.approach_clear(_world, _companion, _anchor, _player)


func _access_allowed() -> bool:
	for id in _context.get("required_access_ids", []):
		# Main projects traversal upgrades separately from crafted tools. Match
		# Guardian Pulse's ownership lookup; neither callback alone covers both.
		var upgrade := _has_upgrade.is_valid() and bool(_has_upgrade.call(str(id)))
		var capability: bool = _profile != null and _profile.has_capability(str(id))
		if not upgrade and not capability:
			return false
	return true


func _source() -> Dictionary:
	if not is_instance_valid(_world):
		return {}
	for context in _world.get_companion_contexts():
		if context.get("id") == CONTEXT_ID and context.get("action_id") == ACTION_ID and context.get("target_id") == TARGET_ID and context.get("individual_id") == INDIVIDUAL_ID:
			return context
	return {}


func _valid() -> bool:
	return is_instance_valid(_world) and is_instance_valid(_player) and is_instance_valid(_companion) and _hostiles != null


func _notify(text: String) -> void:
	if _status_sink.is_valid():
		_status_sink.call(text)


func _denial(reason: String) -> String:
	match reason:
		"root_claws_required": return "learn Root Claws at night first"
		"cooldown": return "ready in %.1fs" % _cooldown
		"busy": return "Marl is already digging or pinning"
		"target_high": return "draw the eel down to the floor"
		"not_threatening": return "wait for the eel's warning or lunge"
		"path_blocked", "approach_invalid": return "Marl needs a clear, supported floor approach"
		"equipment_required": return "Dive Light and Shock Prod required here"
		"separated", "hold_invalid": return "stay near Marl with clear contact"
		"whiff": return "missed the eel; recovering 8s"
		"timeout": return "grip expired; recovering 8s"
		"weapon_hit": return "released for your strike; recovering 8s"
		_: return reason.replace("_", " ")
