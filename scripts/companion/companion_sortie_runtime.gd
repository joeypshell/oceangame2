extends Node

const SPARK_RAY_SCENE := preload("res://scenes/companion/SparkRayCompanion.tscn")
const CompanionControlRuntime := preload("res://scripts/companion/companion_control_runtime.gd")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")

var _world
var _player
var _profile
var _has_upgrade := Callable()
var _companion
var _control
var _gate_access := CurrentGateController.new()


func _ready() -> void:
	_ensure_control()


func bind_interface(active_tool_hud, status_sink: Callable, cancel_diver_tool: Callable, control_allowed: Callable) -> void:
	_ensure_control()
	_control.bind_interface(active_tool_hud, status_sink, cancel_diver_tool, control_allowed)


func bind_map(world, player, profile, has_upgrade: Callable, sortie_active := false) -> Dictionary:
	clear_map()
	_world = world
	_player = player
	_profile = profile
	_has_upgrade = has_upgrade
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
		return {"spawned": false, "control": _control.report() if _control != null else {}}
	var value: Dictionary = _companion.report()
	value["spawned"] = true
	value["control"] = _control.report() if _control != null else {}
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


func _ensure_control() -> void:
	if _control != null:
		return
	_control = CompanionControlRuntime.new()
	add_child(_control)


func _bind_control_map() -> void:
	_ensure_control()
	_control.bind_map(_world, _player, _companion, Callable(self, "_position_allowed"))
