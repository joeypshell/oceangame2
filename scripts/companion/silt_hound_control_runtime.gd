extends Node

const CompanionCommandPalette := preload("res://scripts/companion/companion_command_palette.gd")
const CompanionCommandPause := preload("res://scripts/companion/companion_command_pause.gd")

var _world
var _player
var _companion
var _status_sink := Callable()
var _control_allowed := Callable()
var _command_pause := CompanionCommandPause.new()
var _palette
var _command_mode := false
var _selected_command_index := 0
var _palette_feedback := ""
var _last_denial := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_palette = CompanionCommandPalette.new()
	add_child(_palette)
	_refresh_presentation()


func _exit_tree() -> void:
	_command_mode = false
	_command_pause.end()


func bind_interface(status_sink: Callable, control_allowed: Callable) -> void:
	_status_sink = status_sink
	_control_allowed = control_allowed


func bind_map(world, player, companion, _moving_hazards = null, _hostiles = null) -> void:
	clear_map()
	_world = world
	_player = player
	_companion = companion
	_refresh_presentation()


func clear_map() -> void:
	reset_control("map_clear")
	_world = null
	_player = null
	_companion = null
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
	if not _command_mode:
		return false
	if event.is_action_pressed("companion_action_1") and not repeated:
		activate_context_command(0)
		return true
	if event is InputEventKey and event.pressed and not repeated and (event as InputEventKey).keycode == KEY_ESCAPE:
		end_command_mode()
		return true
	if event.is_action_pressed("active_tool_cycle_next") and not repeated:
		cycle_context_command()
		return true
	if event.is_action_pressed("active_tool_use") and not repeated:
		confirm_context_command()
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
	_command_pause.begin(get_tree())
	_refresh_presentation()
	return report()


func end_command_mode() -> Dictionary:
	if not _command_mode:
		_command_pause.end()
		return report()
	_command_mode = false
	_palette_feedback = ""
	_command_pause.end()
	_refresh_presentation()
	return report()


func cycle_context_command() -> Dictionary:
	_selected_command_index = 0
	_palette_feedback = ""
	_refresh_presentation()
	return report()


func confirm_context_command() -> Dictionary:
	var commands := _context_commands()
	if commands.is_empty():
		return _deny("command_unavailable")
	var result := _execute_command(str((commands[0] as Dictionary).get("id", "")))
	end_command_mode()
	return result


func activate_context_command(index: int) -> Dictionary:
	if not _command_mode or index != 0:
		return {"changed": false, "reason": "command_unavailable", "mounted": false}
	return confirm_context_command()


func reset_control(_reason := "reset") -> void:
	end_command_mode()
	_selected_command_index = 0
	_palette_feedback = ""
	_refresh_presentation()


func reset_transient(reason := "reset") -> void:
	reset_control(reason)


func hides_diver_hotbar() -> bool:
	return false


func is_mounted() -> bool:
	return false


func report() -> Dictionary:
	return {
		"command_mode": _command_mode,
		"time_scale": Engine.time_scale,
		"timing_policy": CompanionCommandPause.POLICY_ID,
		"simulation_paused": _command_pause.is_active(),
		"mounted": false,
		"selected_command_index": _selected_command_index,
		"context_commands": _context_commands(),
		"last_denial": _last_denial,
		"palette": _palette.get_test_report() if _palette != null else {},
	}


func _process(_delta: float) -> void:
	if _command_mode and (not _control_is_allowed() or not _dependencies_valid()):
		reset_control("inactive")


func _execute_command(command_id: String) -> Dictionary:
	if command_id != "recall" or not _dependencies_valid():
		return _deny("command_unavailable")
	if _companion.has_method("request_recall"):
		_companion.request_recall()
	_notify("Marl recalled")
	return {"changed": true, "reason": "recalled", "mounted": false}


func _context_commands() -> Array:
	if not _dependencies_valid():
		return []
	return [{"id": "recall", "label": "Recall", "enabled": true, "reason": "ready"}]


func _refresh_presentation() -> void:
	if _palette == null:
		return
	if _command_mode:
		_palette.sync(_context_commands(), _selected_command_index, _palette_feedback)
	else:
		_palette.hide_palette()


func _deny(reason: String) -> Dictionary:
	_last_denial = reason
	_palette_feedback = "Unavailable"
	_notify("BOND denied | unavailable")
	_refresh_presentation()
	return {"changed": false, "reason": reason, "mounted": false}


func _notify(note: String) -> void:
	if _status_sink.is_valid() and not note.is_empty():
		_status_sink.call(note)


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
