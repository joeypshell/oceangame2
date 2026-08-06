extends Node

const SPARK_RAY_SCENE := preload("res://scenes/companion/SparkRayCompanion.tscn")
const CompanionAdaptationDebrief := preload("res://scripts/companion/companion_adaptation_debrief.gd")
const CompanionAnchorFinsRuntime := preload("res://scripts/companion/companion_anchor_fins_runtime.gd")
const CompanionControlRuntime := preload("res://scripts/companion/companion_control_runtime.gd")
const CompanionGuardianPulseRuntime := preload("res://scripts/companion/companion_guardian_pulse_runtime.gd")
const CompanionHabitatSelection := preload("res://scripts/companion/companion_habitat_selection.gd")
const CompanionMemoryRuntime := preload("res://scripts/companion/companion_memory_runtime.gd")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")
const SHARED_EVENT_DISTANCE_PX := 240.0

var _world
var _player
var _profile
var _has_upgrade := Callable()
var _companion
var _control
var _gate_access := CurrentGateController.new()
var _anchor_fins := CompanionAnchorFinsRuntime.new()
var _guardian_pulse := CompanionGuardianPulseRuntime.new()
var _habitat
var _memory_runtime := CompanionMemoryRuntime.new()
var _adaptation_debrief := CompanionAdaptationDebrief.new()


func _ready() -> void:
	_ensure_control()
	_habitat = CompanionHabitatSelection.new()
	add_child(_habitat)


func bind_interface(active_tool_hud, status_sink: Callable, cancel_diver_tool: Callable, control_allowed: Callable) -> void:
	_ensure_control()
	_control.bind_interface(active_tool_hud, status_sink, cancel_diver_tool, control_allowed)
	_anchor_fins.bind_status_sink(status_sink)
	_guardian_pulse.bind_status_sink(status_sink)
	_habitat.bind_interface(status_sink, control_allowed)


func bind_map(
	world,
	player,
	profile,
	has_upgrade: Callable,
	sortie_active := false,
	preserve_sortie := false,
	hostiles = null
) -> Dictionary:
	clear_map()
	_world = world
	_player = player
	_profile = profile
	_has_upgrade = has_upgrade
	_habitat.bind_map(world, player, profile, Callable(self, "release_to_habitat"))
	var has_capability := Callable(profile, "has_capability") if profile != null and profile.has_method("has_capability") else Callable()
	_memory_runtime.bind_map(world, profile, has_upgrade, has_capability, preserve_sortie)
	_anchor_fins.bind_map(world, player, profile, null, has_upgrade, has_capability)
	_guardian_pulse.bind_map(world, player, profile, null, hostiles, has_upgrade, has_capability)
	_adaptation_debrief.bind_profile(profile)
	_adaptation_debrief.end()
	return sync_spawn() if sortie_active else {"spawned": false, "reason": "sortie_not_launched"}


func sync_spawn() -> Dictionary:
	if _companion != null and is_instance_valid(_companion):
		_anchor_fins.bind_companion(_companion)
		_guardian_pulse.bind_companion(_companion)
		_bind_control_map()
		return report()
	if not _dependencies_valid() or not _profile.active_companion_available_on_sortie_launch():
		return {"spawned": false, "reason": "no_launchable_companion"}
	_companion = SPARK_RAY_SCENE.instantiate()
	get_parent().add_child(_companion)
	_companion.configure(
		_world,
		_player,
		Callable(self, "_position_allowed"),
		_profile.companion_report().get("individual", {})
	)
	_anchor_fins.bind_companion(_companion)
	_guardian_pulse.bind_companion(_companion)
	_bind_control_map()
	return report()


func clear_map() -> void:
	_anchor_fins.clear_map()
	_guardian_pulse.clear_map()
	if _control != null:
		_control.clear_map()
	if _habitat != null:
		_habitat.clear_map()
	_free_companion()
	_world = null
	_player = null
	_profile = null
	_has_upgrade = Callable()


func recover_to_player() -> void:
	_anchor_fins.reset("recovery")
	_guardian_pulse.reset("recovery")
	if _control != null:
		_control.reset_control("recovery")
	if _companion != null and is_instance_valid(_companion):
		_companion.recover_to_player()


func reset_control(reason := "reset") -> void:
	_anchor_fins.reset(reason)
	_guardian_pulse.reset(reason)
	if _control != null:
		_control.reset_control(reason)


func observe_current(gate_result: Dictionary) -> Dictionary:
	if _world == null or _player == null:
		return {"changed": false, "reason": "map_unavailable"}
	return _memory_runtime.observe_current(
		_world,
		_player.global_position,
		gate_result,
		_shared_event_context()
	)


func observe_hostiles(hostiles, event: Dictionary) -> Dictionary:
	if _player == null:
		return {"changed": false, "reason": "player_unavailable"}
	return _memory_runtime.observe_hostiles(
		hostiles,
		event,
		_player.global_position,
		_shared_event_context()
	)


func commit_memories_at_boat() -> Dictionary:
	var at_boat: bool = (
		_world != null
		and _player != null
		and _world.has_method("is_inside_boat")
		and _world.is_inside_boat(_player.global_position)
	)
	return _memory_runtime.commit_at_boat(at_boat)


func discard_uncommitted_memories(reason := "failure") -> Dictionary:
	return _memory_runtime.discard_uncommitted(reason)


func begin_debrief() -> void:
	reset_control("debrief")
	_adaptation_debrief.begin()


func end_debrief() -> void:
	_adaptation_debrief.end()


func handle_debrief_input(event: InputEvent) -> Dictionary:
	return _adaptation_debrief.handle_input(event)


func requires_adaptation_selection() -> bool:
	return _adaptation_debrief.requires_selection()


func debrief_lines() -> Array[String]:
	return _adaptation_debrief.debrief_lines()


func memory_report() -> Dictionary:
	var value := _memory_runtime.report()
	value["debrief"] = _adaptation_debrief.report()
	return value


func handle_input(event: InputEvent) -> bool:
	if _habitat != null and _habitat.handle_input(event):
		return true
	return _control != null and bool(_control.handle_input(event))


func release_to_habitat() -> bool:
	if _companion == null or not is_instance_valid(_companion):
		return false
	reset_control("boat_habitat")
	if _control != null:
		_control.clear_map()
	_anchor_fins.bind_companion(null)
	_guardian_pulse.bind_companion(null)
	_free_companion()
	return true


func hides_diver_hotbar() -> bool:
	return _control != null and bool(_control.hides_diver_hotbar())


func force_dismount_for_hit(source_position: Vector2) -> Dictionary:
	_anchor_fins.reset("hostile_hit")
	_guardian_pulse.reset("hostile_hit")
	return _control.force_dismount_for_hit(source_position) if _control != null else {"changed": false, "reason": "control_unavailable"}


func set_adaptation_hooks(action_provider: Callable, action_dispatch: Callable) -> void:
	_ensure_control()
	_control.set_adaptation_hooks(action_provider, action_dispatch)


func control_runtime():
	return _control


func adaptation_runtime():
	return _anchor_fins


func guardian_pulse_runtime():
	return _guardian_pulse


func set_external_control_active(active: bool) -> bool:
	if _companion == null or not is_instance_valid(_companion):
		return false
	_companion.set_external_control_active(active)
	return true


func show_context_response(context_kind: String, source_position: Vector2) -> bool:
	if _companion == null or not is_instance_valid(_companion):
		return false
	return bool(_companion.show_context_response(context_kind, source_position))


func companion():
	return _companion if _companion != null and is_instance_valid(_companion) else null


func report() -> Dictionary:
	if _companion == null or not is_instance_valid(_companion):
		return {
			"spawned": false,
			"control": _control.report() if _control != null else {},
			"memory": memory_report(),
			"adaptation": _selected_adaptation_report(),
			"adaptations": _adaptation_reports(),
			"habitat": _habitat.report() if _habitat != null else {},
		}
	var value: Dictionary = _companion.report()
	value["spawned"] = true
	value["control"] = _control.report() if _control != null else {}
	value["memory"] = memory_report()
	value["adaptation"] = _selected_adaptation_report()
	value["adaptations"] = _adaptation_reports()
	value["habitat"] = _habitat.report() if _habitat != null else {}
	return value


func _process(delta: float) -> void:
	_anchor_fins.advance(delta, _control != null and _control.is_mounted())
	_guardian_pulse.advance(delta, _control != null and _control.is_mounted())


func _position_allowed(position: Vector2) -> bool:
	if not _dependencies_valid():
		return false
	var has_capability := Callable(_profile, "has_capability") if _profile.has_method("has_capability") else Callable()
	return _gate_access.gate_blocks_position(
		_world,
		position,
		_has_upgrade,
		has_capability
	).is_empty()


func _dependencies_valid() -> bool:
	return (
		get_parent() != null
		and _world != null
		and is_instance_valid(_world)
		and _player != null
		and is_instance_valid(_player)
		and _profile != null
		and _profile.has_method("active_companion_available_on_sortie_launch")
	)


func _shared_event_context() -> Dictionary:
	if _companion == null or not is_instance_valid(_companion) or _player == null or not is_instance_valid(_player):
		return {"active": false, "together": false, "mode": "independent"}
	var companion_report: Dictionary = _companion.report()
	var state := str(companion_report.get("state", ""))
	var mounted: bool = _control != null and _control.is_mounted()
	var distance: float = _companion.global_position.distance_to(_player.global_position)
	var together: bool = mounted or (
		state not in ["separated", "recovery"]
		and distance <= SHARED_EVENT_DISTANCE_PX
	)
	var callsign := "Spark Ray"
	if _profile != null and _profile.has_method("companion_report"):
		callsign = str(_profile.companion_report().get("individual", {}).get("callsign", callsign))
	return {
		"active": true,
		"together": together,
		"mode": "mounted" if mounted else "independent",
		"distance_px": distance,
		"callsign": callsign,
	}


func _ensure_control() -> void:
	if _control != null:
		return
	_control = CompanionControlRuntime.new()
	add_child(_control)
	_guardian_pulse.bind_aim_provider(Callable(self, "_guardian_aim_direction"))
	_control.set_adaptation_hooks(Callable(self, "_adaptation_actions"), Callable(self, "_dispatch_adaptation_action"))


func _free_companion() -> void:
	if _companion != null and is_instance_valid(_companion):
		if _companion.get_parent() != null:
			_companion.get_parent().remove_child(_companion)
		_companion.queue_free()
	_companion = null


func _bind_control_map() -> void:
	_ensure_control()
	_control.bind_map(_world, _player, _companion, Callable(self, "_position_allowed"))


func _adaptation_actions(context: String) -> Array:
	var actions: Array = []
	actions.append_array(_anchor_fins.actions(context))
	actions.append_array(_guardian_pulse.actions(context))
	return actions


func _dispatch_adaptation_action(role: String, action_id: String) -> Dictionary:
	if action_id == CompanionAnchorFinsRuntime.ACTION_ID:
		return _anchor_fins.dispatch(role, action_id)
	if action_id == CompanionGuardianPulseRuntime.ACTION_ID:
		return _guardian_pulse.dispatch(role, action_id)
	return {"changed": false, "reason": "action_unavailable"}


func _guardian_aim_direction(role: String) -> Vector2:
	if role == "mounted" and _control != null:
		var mounted_direction: Vector2 = _control.report().get("last_move_direction", Vector2.ZERO)
		if mounted_direction != Vector2.ZERO:
			return mounted_direction.normalized()
	if _player != null and is_instance_valid(_player) and _player.has_method("get_facing_sign"):
		return Vector2(1.0 if float(_player.get_facing_sign()) >= 0.0 else -1.0, 0.0)
	return Vector2.RIGHT


func _adaptation_reports() -> Dictionary:
	return {
		"anchor_fins": _anchor_fins.report(),
		"guardian_pulse": _guardian_pulse.report(),
	}


func _selected_adaptation_report() -> Dictionary:
	var guardian := _guardian_pulse.report()
	return guardian if not str(guardian.get("adaptation_id", "")).is_empty() else _anchor_fins.report()
