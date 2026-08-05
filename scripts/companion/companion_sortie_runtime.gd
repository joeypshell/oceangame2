extends Node

const SPARK_RAY_SCENE := preload("res://scenes/companion/SparkRayCompanion.tscn")
const CompanionAdaptationDebrief := preload("res://scripts/companion/companion_adaptation_debrief.gd")
const CompanionControlRuntime := preload("res://scripts/companion/companion_control_runtime.gd")
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
var _memory_runtime := CompanionMemoryRuntime.new()
var _adaptation_debrief := CompanionAdaptationDebrief.new()


func _ready() -> void:
	_ensure_control()


func bind_interface(active_tool_hud, status_sink: Callable, cancel_diver_tool: Callable, control_allowed: Callable) -> void:
	_ensure_control()
	_control.bind_interface(active_tool_hud, status_sink, cancel_diver_tool, control_allowed)


func bind_map(
	world,
	player,
	profile,
	has_upgrade: Callable,
	sortie_active := false,
	preserve_sortie := false
) -> Dictionary:
	clear_map()
	_world = world
	_player = player
	_profile = profile
	_has_upgrade = has_upgrade
	var has_capability := Callable(profile, "has_capability") if profile != null and profile.has_method("has_capability") else Callable()
	_memory_runtime.bind_map(world, profile, has_upgrade, has_capability, preserve_sortie)
	_adaptation_debrief.bind_profile(profile)
	_adaptation_debrief.end()
	return sync_spawn() if sortie_active else {"spawned": false, "reason": "sortie_not_launched"}


func sync_spawn() -> Dictionary:
	if _companion != null and is_instance_valid(_companion):
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
	_bind_control_map()
	return report()


func clear_map() -> void:
	if _control != null:
		_control.clear_map()
	if _companion != null and is_instance_valid(_companion):
		if _companion.get_parent() != null:
			_companion.get_parent().remove_child(_companion)
		_companion.queue_free()
	_companion = null
	_world = null
	_player = null
	_profile = null
	_has_upgrade = Callable()


func recover_to_player() -> void:
	if _control != null:
		_control.reset_control("recovery")
	if _companion != null and is_instance_valid(_companion):
		_companion.recover_to_player()


func reset_control(reason := "reset") -> void:
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
	return _control != null and bool(_control.handle_input(event))


func hides_diver_hotbar() -> bool:
	return _control != null and bool(_control.hides_diver_hotbar())


func force_dismount_for_hit(source_position: Vector2) -> Dictionary:
	return _control.force_dismount_for_hit(source_position) if _control != null else {"changed": false, "reason": "control_unavailable"}


func set_adaptation_hooks(action_provider: Callable, action_dispatch: Callable) -> void:
	_ensure_control()
	_control.set_adaptation_hooks(action_provider, action_dispatch)


func control_runtime():
	return _control


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
		}
	var value: Dictionary = _companion.report()
	value["spawned"] = true
	value["control"] = _control.report() if _control != null else {}
	value["memory"] = memory_report()
	return value


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


func _bind_control_map() -> void:
	_ensure_control()
	_control.bind_map(_world, _player, _companion, Callable(self, "_position_allowed"))
