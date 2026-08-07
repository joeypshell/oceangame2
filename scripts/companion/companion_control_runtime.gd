extends Node

const CompanionActionHud := preload("res://scripts/companion/companion_action_hud.gd")
const CompanionClearance := preload("res://scripts/companion/companion_clearance.gd")
const CompanionCommandPalette := preload("res://scripts/companion/companion_command_palette.gd")

const COMMAND_TIME_SCALE := 0.2
const MAX_CONTEXT_COMMANDS := 3
const MAX_MOUNTED_ACTIONS := 3
const GLIDE_SURGE_ACTION_ID := "glide_surge"
const GLIDE_SURGE_DURATION := 0.32
const GLIDE_SURGE_COOLDOWN := 1.6
const GLIDE_SURGE_SPEED_MULTIPLIER := 1.7

var _world
var _player
var _companion
var _position_allowed := Callable()
var _active_tool_hud
var _status_sink := Callable()
var _cancel_diver_tool := Callable()
var _control_allowed := Callable()
var _adaptation_action_provider := Callable()
var _adaptation_action_dispatch := Callable()
var _clearance := CompanionClearance.new()
var _palette
var _action_hud
var _command_mode := false
var _mounted := false
var _selected_command_index := 0
var _selected_action_index := 0
var _palette_feedback := ""
var _prior_time_scale := 1.0
var _owns_time_scale := false
var _glide_cooldown_seconds := 0.0
var _glide_surge_seconds := 0.0
var _glide_direction := Vector2.RIGHT
var _last_move_direction := Vector2.RIGHT
var _last_movement_result := {}
var _last_denial := ""
var _diver_hotbar_was_visible := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_palette = CompanionCommandPalette.new()
	add_child(_palette)
	_action_hud = CompanionActionHud.new()
	add_child(_action_hud)
	_refresh_presentation()


func _exit_tree() -> void:
	_command_mode = false
	_restore_time_scale()
	if _mounted and _player != null and is_instance_valid(_player) and _player.has_method("set_mounted_control_active"):
		_player.set_mounted_control_active(false)


func bind_interface(active_tool_hud, status_sink: Callable, cancel_diver_tool: Callable, control_allowed: Callable) -> void:
	_active_tool_hud = active_tool_hud
	_status_sink = status_sink
	_cancel_diver_tool = cancel_diver_tool
	_control_allowed = control_allowed
	_refresh_presentation()


func bind_map(world, player, companion, position_allowed: Callable) -> void:
	reset_control("map_change")
	_world = world
	_player = player
	_companion = companion
	_position_allowed = position_allowed
	_refresh_presentation()
func clear_map() -> void:
	reset_control("map_clear")
	_world = null
	_player = null
	_companion = null
	_position_allowed = Callable()
	_refresh_presentation()
func set_adaptation_hooks(action_provider: Callable, action_dispatch: Callable) -> void:
	_adaptation_action_provider = action_provider
	_adaptation_action_dispatch = action_dispatch
	_selected_action_index = 0
	_refresh_presentation()


func handle_input(event: InputEvent) -> bool:
	var repeated := event is InputEventKey and (event as InputEventKey).echo
	if event.is_action_pressed("companion_command") and not repeated:
		if _command_mode:
			end_command_mode()
		else:
			begin_command_mode()
		return true
	if event.is_action_released("companion_command"):
		return true
	if not _command_mode and not _mounted:
		return false
	if _command_mode:
		for index in range(MAX_CONTEXT_COMMANDS):
			if event.is_action_pressed("companion_action_%d" % (index + 1)) and not repeated:
				activate_context_command(index)
				return true
		if event is InputEventKey and event.pressed and not repeated and (event as InputEventKey).keycode == KEY_ESCAPE:
			end_command_mode()
			return true
	if event.is_action_pressed("active_tool_cycle_next") and not repeated:
		if _command_mode:
			cycle_context_command()
		else:
			cycle_mounted_action()
		return true
	if event.is_action_pressed("active_tool_use") and not repeated:
		if _command_mode:
			confirm_context_command()
		else:
			activate_mounted_action()
		return true
	if event.is_action_released("active_tool_use"):
		return true
	return false


func begin_command_mode() -> Dictionary:
	if _command_mode:
		return report()
	if not _control_is_allowed() or not _dependencies_valid():
		_last_denial = "companion_unavailable"
		_notify("BOND unavailable during this state")
		return report()
	_command_mode = true
	_selected_command_index = 0
	_palette_feedback = ""
	_prior_time_scale = Engine.time_scale
	_owns_time_scale = true
	Engine.time_scale = COMMAND_TIME_SCALE
	_refresh_presentation()
	return report()


func end_command_mode() -> Dictionary:
	if not _command_mode:
		_restore_time_scale()
		return report()
	_command_mode = false
	_palette_feedback = ""
	_restore_time_scale()
	_refresh_presentation()
	return report()


func cycle_context_command() -> Dictionary:
	var commands := _context_commands()
	if commands.is_empty():
		return report()
	_selected_command_index = (_selected_command_index + 1) % commands.size()
	_palette_feedback = ""
	_refresh_presentation()
	return report()


func confirm_context_command() -> Dictionary:
	var commands := _context_commands()
	if commands.is_empty():
		_palette_feedback = "No command available"
		end_command_mode()
		return report()
	_selected_command_index = clampi(_selected_command_index, 0, commands.size() - 1)
	var command: Dictionary = commands[_selected_command_index]
	var result := _execute_command(str(command.get("id", "")), command)
	end_command_mode()
	return result


func activate_context_command(index: int) -> Dictionary:
	var commands := _context_commands()
	if not _command_mode or index < 0 or index >= commands.size():
		return _result(false, "command_unavailable", "Command unavailable")
	_selected_command_index = index
	return confirm_context_command()


func request_mount() -> Dictionary:
	if _mounted:
		return _result(false, "already_mounted", "Already riding")
	var clearance: Dictionary = _clearance.mount_report(_world, _player, _companion, _position_allowed)
	if not bool(clearance.get("allowed", false)):
		return _deny(str(clearance.get("reason", "mount_denied")))
	_cancel_active_diver_tool()
	_mounted = true
	_glide_cooldown_seconds = 0.0
	_glide_surge_seconds = 0.0
	_diver_hotbar_was_visible = _active_tool_hud != null and bool(_active_tool_hud.visible)
	if _companion.has_method("set_external_control_active"):
		_companion.set_external_control_active(true)
	if _player.has_method("set_mounted_control_active"):
		_player.set_mounted_control_active(true)
	_sync_player_to_companion()
	_notify("Riding Spark Ray | creature actions active")
	_refresh_presentation()
	return _result(true, "mounted", "Riding Spark Ray")


func request_dismount() -> Dictionary:
	if not _mounted:
		return _result(false, "not_mounted", "Not mounted")
	var clearance: Dictionary = _clearance.dismount_report(_world, _player, _companion, _position_allowed)
	if not bool(clearance.get("allowed", false)):
		return _deny(str(clearance.get("reason", "dismount_denied")))
	_dismount_to(clearance.get("position", _companion.global_position), "dismounted")
	_notify("Dismounted | diver tools restored")
	return _result(true, "dismounted", "Diver control restored")


func force_dismount_for_hit(source_position: Vector2) -> Dictionary:
	if not _mounted:
		return _result(false, "not_mounted", "")
	var dismount_position := _clearance.emergency_dismount_position(_world, _player, _companion, _position_allowed)
	var separation_direction := source_position.direction_to(_companion.global_position)
	_dismount_to(dismount_position, "hostile_hit")
	if _companion.has_method("force_readable_separation"):
		_companion.force_readable_separation(separation_direction)
	_notify("Hostile impact forced dismount")
	return _result(true, "forced_dismount", "Hostile impact forced dismount")


func reset_control(reason := "reset") -> void:
	end_command_mode()
	if _mounted and _dependencies_valid():
		var position := _clearance.emergency_dismount_position(_world, _player, _companion, _position_allowed)
		_dismount_to(position, reason)
	_mounted = false
	_glide_cooldown_seconds = 0.0
	_glide_surge_seconds = 0.0
	_last_movement_result = {}
	_refresh_presentation()


func cycle_mounted_action() -> Dictionary:
	var actions := _mounted_actions()
	if not _mounted or actions.is_empty():
		return _result(false, "not_mounted", "Creature actions unavailable")
	_selected_action_index = (_selected_action_index + 1) % actions.size()
	_notify("Creature action: %s" % str(actions[_selected_action_index].get("label", "Action")))
	_refresh_presentation()
	return report()


func activate_mounted_action() -> Dictionary:
	var actions := _mounted_actions()
	if not _mounted or actions.is_empty():
		return _result(false, "not_mounted", "Creature actions unavailable")
	_selected_action_index = clampi(_selected_action_index, 0, actions.size() - 1)
	var action_id := str(actions[_selected_action_index].get("id", ""))
	if action_id == GLIDE_SURGE_ACTION_ID:
		return _activate_glide_surge()
	if _adaptation_action_dispatch.is_valid():
		var raw_result = _adaptation_action_dispatch.call("mounted", action_id)
		var result: Dictionary = raw_result if raw_result is Dictionary else {}
		_refresh_presentation()
		return result
	return _deny("action_unavailable")


func advance_mounted_movement(delta: float, direction_override := Vector2(INF, INF)) -> Dictionary:
	if not _mounted or not _dependencies_valid():
		return _result(false, "not_mounted", "")
	var direction: Vector2 = direction_override if (direction_override as Vector2).is_finite() else _input_direction()
	if _glide_surge_seconds > 0.0:
		direction = _glide_direction
	if direction.length() > 1.0:
		direction = direction.normalized()
	if direction != Vector2.ZERO:
		_last_move_direction = direction
	var speed_multiplier := GLIDE_SURGE_SPEED_MULTIPLIER if _glide_surge_seconds > 0.0 else 1.0
	_last_movement_result = _companion.move_under_external_control(direction, delta, speed_multiplier)
	_sync_player_to_companion()
	if bool(_last_movement_result.get("blocked_by_gate", false)):
		_glide_surge_seconds = 0.0
		if _last_denial != "equipment_gate":
			_last_denial = "equipment_gate"
			_notify("Route blocked | diver equipment still required")
	return _last_movement_result.duplicate(true)
func hides_diver_hotbar() -> bool:
	return _mounted
func is_mounted() -> bool:
	return _mounted


func report() -> Dictionary:
	var actions := _mounted_actions()
	var selected_action_id := ""
	if not actions.is_empty():
		selected_action_id = str(actions[clampi(_selected_action_index, 0, actions.size() - 1)].get("id", ""))
	return {
		"command_mode": _command_mode,
		"time_scale": Engine.time_scale,
		"mounted": _mounted,
		"selected_command_index": _selected_command_index,
		"context_commands": _context_commands(),
		"selected_action_id": selected_action_id,
		"mounted_actions": actions,
		"glide_cooldown_seconds": _glide_cooldown_seconds,
		"glide_surge_seconds": _glide_surge_seconds,
		"last_move_direction": _last_move_direction,
		"last_movement_result": _last_movement_result.duplicate(true),
		"last_denial": _last_denial,
		"palette": _palette.get_test_report() if _palette != null else {},
		"action_hud": _action_hud.get_test_report() if _action_hud != null else {},
		"adaptation_hooks_ready": true,
	}


func _process(delta: float) -> void:
	if (_command_mode or _mounted) and (not _control_is_allowed() or not _dependencies_valid()):
		reset_control("inactive")
		return
	_glide_cooldown_seconds = maxf(0.0, _glide_cooldown_seconds - maxf(0.0, delta))
	_glide_surge_seconds = maxf(0.0, _glide_surge_seconds - maxf(0.0, delta))
	if _mounted:
		_sync_player_to_companion()
	_refresh_presentation()


func _physics_process(delta: float) -> void:
	if _mounted:
		advance_mounted_movement(delta)


func _execute_command(command_id: String, command: Dictionary) -> Dictionary:
	if not bool(command.get("enabled", true)):
		return _deny(str(command.get("reason", "command_denied")))
	match command_id:
		"mount":
			return request_mount()
		"dismount":
			return request_dismount()
		"recall":
			if _companion.has_method("request_recall"):
				_companion.request_recall()
			_notify("Spark Ray recalled")
			return _result(true, "recalled", "Spark Ray recalled")
	if _adaptation_action_dispatch.is_valid():
		var raw_result = _adaptation_action_dispatch.call("independent", command_id)
		return raw_result if raw_result is Dictionary else _result(false, "action_unavailable", "Action unavailable")
	return _deny("command_unavailable")


func _context_commands() -> Array:
	if not _dependencies_valid():
		return []
	var commands: Array = []
	if _mounted:
		var clearance: Dictionary = _clearance.dismount_report(_world, _player, _companion, _position_allowed)
		commands.append(_command("dismount", "Dismount", clearance))
	else:
		var clearance: Dictionary = _clearance.mount_report(_world, _player, _companion, _position_allowed)
		commands.append(_command("mount", "Mount", clearance))
		commands.append({"id": "recall", "label": "Recall", "enabled": true, "reason": "ready"})
	for action in _adaptation_actions("mounted_palette" if _mounted else "independent_palette"):
		commands.append(action)
	return commands.slice(0, MAX_CONTEXT_COMMANDS)


func _mounted_actions() -> Array:
	var actions: Array = [{
		"id": GLIDE_SURGE_ACTION_ID,
		"label": "Glide surge",
		"cooldown_seconds": _glide_cooldown_seconds,
		"cooldown_duration": GLIDE_SURGE_COOLDOWN,
	}]
	for action in _adaptation_actions("mounted_hotbar"):
		actions.append(action)
	return actions.slice(0, MAX_MOUNTED_ACTIONS)


func _adaptation_actions(context: String) -> Array:
	if not _adaptation_action_provider.is_valid():
		return []
	var raw_actions = _adaptation_action_provider.call(context)
	return raw_actions.duplicate(true) if raw_actions is Array else []


func _activate_glide_surge() -> Dictionary:
	if _glide_cooldown_seconds > 0.0:
		return _deny("glide_cooling_down")
	_glide_direction = _last_move_direction
	if _glide_direction == Vector2.ZERO:
		_glide_direction = Vector2(float(_companion.report().get("facing_sign", 1.0)), 0.0)
	_glide_surge_seconds = GLIDE_SURGE_DURATION
	_glide_cooldown_seconds = GLIDE_SURGE_COOLDOWN
	if _companion.has_method("show_glide_surge"):
		_companion.show_glide_surge(_glide_direction, GLIDE_SURGE_DURATION)
	_notify("Glide surge")
	_refresh_presentation()
	return _result(true, "glide_surge", "Glide surge")


func _dismount_to(position: Vector2, _reason: String) -> void:
	_mounted = false
	_glide_surge_seconds = 0.0
	if _companion.has_method("set_external_control_active"):
		_companion.set_external_control_active(false)
	_player.global_position = position
	if _player.has_method("set_mounted_control_active"):
		_player.set_mounted_control_active(false)
	if _active_tool_hud != null:
		_active_tool_hud.visible = _diver_hotbar_was_visible
	_refresh_presentation()


func _sync_player_to_companion() -> void:
	if not _mounted or not _dependencies_valid():
		return
	_player.global_position = _companion.global_position
	if _player.has_method("sync_mounted_pose"):
		_player.sync_mounted_pose(_companion.global_position, float(_companion.report().get("facing_sign", 1.0)))


func _refresh_presentation() -> void:
	if _palette != null:
		if _command_mode:
			_palette.sync(_context_commands(), _selected_command_index, _palette_feedback)
		else:
			_palette.hide_palette()
	var actions := _mounted_actions()
	if not actions.is_empty():
		_selected_action_index = clampi(_selected_action_index, 0, actions.size() - 1)
	var selected_action_id := str(actions[_selected_action_index].get("id", "")) if not actions.is_empty() else ""
	if _action_hud != null:
		_action_hud.sync(actions, selected_action_id, _mounted and not _command_mode)
	if _active_tool_hud != null and _mounted:
		_active_tool_hud.visible = false


func _command(command_id: String, label: String, clearance: Dictionary) -> Dictionary:
	var reason := str(clearance.get("reason", "denied"))
	return {
		"id": command_id,
		"label": label,
		"enabled": bool(clearance.get("allowed", false)),
		"reason": reason,
		"denial": _denial_label(reason),
	}


func _denial_label(reason: String) -> String:
	match reason:
		"move_closer":
			return "move closer"
		"companion_separated":
			return "recall first"
		"rider_clearance":
			return "no rider room"
		"diver_clearance":
			return "no diver room"
		"equipment_gate":
			return "route locked"
		"glide_cooling_down":
			return "cooling down"
	return "unavailable"


func _deny(reason: String) -> Dictionary:
	_last_denial = reason
	var note := _denial_label(reason)
	_palette_feedback = note.capitalize()
	_notify("BOND denied | %s" % note)
	_refresh_presentation()
	return _result(false, reason, note)


func _result(changed: bool, reason: String, note: String) -> Dictionary:
	return {"changed": changed, "reason": reason, "note": note, "mounted": _mounted}


func _notify(note: String) -> void:
	if _status_sink.is_valid() and not note.is_empty():
		_status_sink.call(note)


func _cancel_active_diver_tool() -> void:
	if _cancel_diver_tool.is_valid():
		_cancel_diver_tool.call()


func _restore_time_scale() -> void:
	if _command_mode or not _owns_time_scale:
		return
	Engine.time_scale = _prior_time_scale
	_owns_time_scale = false
func _control_is_allowed() -> bool:
	return not _control_allowed.is_valid() or bool(_control_allowed.call())
func _dependencies_valid() -> bool:
	return (
		_world != null
		and is_instance_valid(_world)
		and _player != null
		and is_instance_valid(_player)
		and _companion != null
		and is_instance_valid(_companion)
	)


func _input_direction() -> Vector2:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	return direction.normalized() if direction.length() > 1.0 else direction
