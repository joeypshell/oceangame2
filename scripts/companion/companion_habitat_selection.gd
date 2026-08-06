extends Node

const CompanionHabitatPanel := preload("res://scripts/companion/companion_habitat_panel.gd")

var _world
var _player
var _profile
var _release_active := Callable()
var _status_sink := Callable()
var _interaction_allowed := Callable()
var _panel
var _at_boat := false
var _selection_open := false
var _highlighted_index := 0
var _feedback := ""
var _player_was_processing := true


func _ready() -> void:
	_panel = CompanionHabitatPanel.new()
	add_child(_panel)


func bind_interface(status_sink: Callable, interaction_allowed: Callable) -> void:
	_status_sink = status_sink
	_interaction_allowed = interaction_allowed


func bind_map(world, player, profile, release_active: Callable) -> void:
	clear_map()
	_world = world
	_player = player
	_profile = profile
	_release_active = release_active
	sync_presence()


func clear_map() -> void:
	_close_selection(false)
	_world = null
	_player = null
	_profile = null
	_release_active = Callable()
	_at_boat = false
	_feedback = ""
	if _panel != null:
		_panel.hide_habitat()


func sync_presence() -> Dictionary:
	var was_at_boat := _at_boat
	_at_boat = _is_at_boat()
	if not _at_boat:
		_close_selection(false)
		if _panel != null:
			_panel.hide_habitat()
		return report()
	if not was_at_boat and _release_active.is_valid():
		_release_active.call()
	_refresh_panel()
	return report()


func handle_input(event: InputEvent) -> bool:
	if not _at_boat or _profile == null or not _interaction_is_allowed():
		return false
	var repeated := event is InputEventKey and (event as InputEventKey).echo
	if event.is_action_released("companion_command"):
		return _selection_open or _individuals().size() > 1
	if event.is_action_pressed("companion_command") and not repeated:
		if _selection_open:
			_close_selection(true)
		elif _individuals().size() > 1:
			_open_selection()
		else:
			_notify(_single_companion_note())
			_feedback = _single_companion_note()
			_refresh_panel()
		return true
	if not _selection_open:
		return false
	if event.is_action_pressed("active_tool_cycle_next") and not repeated:
		_cycle_selection()
		return true
	if event.is_action_pressed("active_tool_use") and not repeated:
		_confirm_selection()
		return true
	if event.is_action_released("active_tool_use"):
		return true
	return false


func report() -> Dictionary:
	return {
		"at_boat": _at_boat,
		"selection_open": _selection_open,
		"highlighted_index": _highlighted_index,
		"individual_count": _individuals().size(),
		"active_individual_id": _active_individual_id(),
		"feedback": _feedback,
		"panel": _panel.get_test_report() if _panel != null else {},
	}


func layout_for_size(viewport_size: Vector2) -> void:
	if _panel != null:
		_panel.layout_for_size(viewport_size)


func _process(_delta: float) -> void:
	if _world != null and _player != null:
		sync_presence()


func _open_selection() -> void:
	var values := _individuals()
	_highlighted_index = 0
	for index in range(values.size()):
		if str((values[index] as Dictionary).get("individual_id", "")) == _active_individual_id():
			_highlighted_index = index
			break
	_selection_open = true
	_feedback = ""
	_lock_player()
	_refresh_panel()


func _close_selection(show_feedback: bool) -> void:
	if not _selection_open:
		return
	_selection_open = false
	_feedback = "Selection closed" if show_feedback else ""
	_unlock_player()
	_refresh_panel()


func _cycle_selection() -> void:
	var values := _individuals()
	if values.is_empty():
		return
	_highlighted_index = (_highlighted_index + 1) % values.size()
	_feedback = "Next: %s" % str((values[_highlighted_index] as Dictionary).get("callsign", "Companion"))
	_refresh_panel()


func _confirm_selection() -> void:
	var values := _individuals()
	if values.is_empty() or not _profile.has_method("select_active_companion"):
		_feedback = "Companion selection unavailable"
		_refresh_panel()
		return
	_highlighted_index = clampi(_highlighted_index, 0, values.size() - 1)
	var individual: Dictionary = values[_highlighted_index]
	var individual_id := str(individual.get("individual_id", ""))
	var result: Dictionary = _profile.select_active_companion(individual_id, true)
	var accepted := bool(result.get("changed", false)) or str(result.get("reason", "")) == "already_active"
	if not accepted:
		_feedback = "Selection could not be saved"
		_notify(_feedback)
		_refresh_panel()
		return
	_feedback = "Next sortie: %s" % str(individual.get("callsign", "Companion"))
	_notify(_feedback)
	_selection_open = false
	_unlock_player()
	_refresh_panel()


func _refresh_panel() -> void:
	if _panel == null:
		return
	if not _at_boat:
		_panel.hide_habitat()
		return
	_panel.sync(_individuals(), _active_individual_id(), _selection_open, _highlighted_index, _feedback)


func _individuals() -> Array:
	if _profile == null or not _profile.has_method("companion_report"):
		return []
	return (_profile.companion_report().get("individuals", []) as Array).duplicate(true)


func _active_individual_id() -> String:
	if _profile == null or not _profile.has_method("companion_report"):
		return ""
	return str(_profile.companion_report().get("active_individual_id", ""))


func _is_at_boat() -> bool:
	return (
		_world != null
		and is_instance_valid(_world)
		and _player != null
		and is_instance_valid(_player)
		and _world.has_method("is_inside_boat")
		and bool(_world.is_inside_boat(_player.global_position))
	)


func _interaction_is_allowed() -> bool:
	return not _interaction_allowed.is_valid() or bool(_interaction_allowed.call())


func _single_companion_note() -> String:
	var values := _individuals()
	return "%s is ready for the next sortie" % str((values[0] as Dictionary).get("callsign", "Companion")) if not values.is_empty() else "No companion committed"


func _lock_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_player_was_processing = _player.is_physics_processing()
	_player.set_physics_process(false)
	if _player.has_method("reset_motion"):
		_player.reset_motion()


func _unlock_player() -> void:
	if _player != null and is_instance_valid(_player):
		_player.set_physics_process(_player_was_processing)


func _notify(note: String) -> void:
	if _status_sink.is_valid() and not note.is_empty():
		_status_sink.call(note)
