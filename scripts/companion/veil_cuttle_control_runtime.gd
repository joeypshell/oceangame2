extends Node

const CompanionCommandPalette := preload("res://scripts/companion/companion_command_palette.gd")
const VeilCuttleTraceRuntime := preload("res://scripts/companion/veil_cuttle_trace_runtime.gd")

const COMMAND_TIME_SCALE := 0.2

var _world
var _player
var _companion
var _status_sink := Callable()
var _control_allowed := Callable()
var _palette
var _trace := VeilCuttleTraceRuntime.new()
var _command_mode := false
var _selected_command_index := 0
var _palette_feedback := ""
var _prior_time_scale := 1.0
var _owns_time_scale := false
var _last_denial := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_palette = CompanionCommandPalette.new()
	add_child(_palette)
	_refresh_presentation()


func _exit_tree() -> void:
	_command_mode = false
	_restore_time_scale()


func bind_interface(status_sink: Callable, control_allowed: Callable) -> void:
	_status_sink = status_sink
	_control_allowed = control_allowed
	_trace.bind_interface(status_sink)


func bind_map(world, player, companion) -> void:
	clear_map()
	_world = world
	_player = player
	_companion = companion
	_trace.bind_map(world, player, companion)
	_refresh_presentation()


func clear_map() -> void:
	reset_control("map_clear")
	_trace.clear_map()
	_world = null
	_player = null
	_companion = null
	_refresh_presentation()


func handle_input(event: InputEvent) -> bool:
	var repeated := event is InputEventKey and (event as InputEventKey).echo
	if event.is_action_pressed("companion_command") and not repeated:
		begin_command_mode()
		return true
	if event.is_action_released("companion_command"):
		end_command_mode()
		return true
	if not _command_mode:
		return false
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
	_prior_time_scale = Engine.time_scale
	_owns_time_scale = true
	Engine.time_scale = COMMAND_TIME_SCALE
	_trace.preview()
	_refresh_presentation()
	return report()


func end_command_mode() -> Dictionary:
	if not _command_mode:
		_restore_time_scale()
		return report()
	_command_mode = false
	_palette_feedback = ""
	_trace.end_preview()
	_restore_time_scale()
	_refresh_presentation()
	return report()


func cycle_context_command() -> Dictionary:
	var commands := _context_commands()
	if not commands.is_empty():
		_selected_command_index = (_selected_command_index + 1) % commands.size()
		_palette_feedback = ""
		_refresh_presentation()
	return report()


func confirm_context_command() -> Dictionary:
	var commands := _context_commands()
	if commands.is_empty():
		return _deny("command_unavailable")
	_selected_command_index = clampi(_selected_command_index, 0, commands.size() - 1)
	var command: Dictionary = commands[_selected_command_index]
	var result := _execute_command(str(command.get("id", "")), command)
	end_command_mode()
	return result


func reset_control(_reason := "reset") -> void:
	end_command_mode()
	_selected_command_index = 0
	_palette_feedback = ""
	_refresh_presentation()


func hides_diver_hotbar() -> bool:
	return false


func is_mounted() -> bool:
	return false


func trace_runtime():
	return _trace


func report() -> Dictionary:
	return {
		"command_mode": _command_mode,
		"time_scale": Engine.time_scale,
		"mounted": false,
		"selected_command_index": _selected_command_index,
		"context_commands": _context_commands(),
		"last_denial": _last_denial,
		"trace": _trace.report(),
		"palette": _palette.get_test_report() if _palette != null else {},
	}


func _process(delta: float) -> void:
	_trace.advance(delta)
	if _command_mode and (not _control_is_allowed() or not _dependencies_valid()):
		reset_control("inactive")
		return
	if _command_mode:
		_trace.preview()
	_refresh_presentation()


func _execute_command(command_id: String, command: Dictionary) -> Dictionary:
	if not bool(command.get("enabled", true)):
		return _deny(str(command.get("reason", "command_denied")))
	if command_id == "recall":
		if _companion.has_method("request_recall"):
			_companion.request_recall()
		_notify("Mica recalled")
		return {"changed": true, "reason": "recalled", "mounted": false}
	if command_id == VeilCuttleTraceRuntime.ACTION_ID:
		return _trace.dispatch(command_id)
	return _deny("command_unavailable")


func _context_commands() -> Array:
	if not _dependencies_valid():
		return []
	return [
		{"id": "recall", "label": "Recall", "enabled": true, "reason": "ready"},
		_trace.action(),
	]


func _refresh_presentation() -> void:
	if _palette == null:
		return
	if _command_mode:
		_palette.sync(_context_commands(), _selected_command_index, _palette_feedback)
	else:
		_palette.hide_palette()


func _deny(reason: String) -> Dictionary:
	_last_denial = reason
	var note := str(_trace.action().get("denial", "unavailable")) if reason != "command_unavailable" else "unavailable"
	_palette_feedback = note.capitalize()
	_notify("BOND denied | %s" % note)
	_refresh_presentation()
	return {"changed": false, "reason": reason, "mounted": false}


func _notify(note: String) -> void:
	if _status_sink.is_valid() and not note.is_empty():
		_status_sink.call(note)


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
