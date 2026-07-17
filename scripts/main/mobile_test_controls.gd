extends CanvasLayer

signal command_dispatched(command_id: StringName, input_event: InputEvent)

const FORCE_FLAG := "--show-mobile-controls"
const STICK_SIZE := 224.0
const STICK_KNOB_SIZE := 72.0
const STICK_DEADZONE := 0.18
const SIDE_MARGIN := 30.0
const BOTTOM_INTERACTION_INSET := 104.0
const BUTTON_SIZE := Vector2(128, 80)
const BUTTON_GAP := 10.0
const GRID_COLUMNS := 3
const COMMANDS := [
	{"id": &"oxygen", "label": "O2", "keycode": KEY_U},
	{"id": &"cargo", "label": "BAG", "keycode": KEY_C},
	{"id": &"tool", "label": "TOOL", "action": &"active_tool_cycle_next"},
	{"id": &"project", "label": "BUILD", "keycode": KEY_P},
	{"id": &"day", "label": "DAY", "keycode": KEY_N},
	{"id": &"reset", "label": "RESET", "keycode": KEY_R},
	{"id": &"interact", "label": "ACT", "keycode": KEY_E},
	{"id": &"use", "label": "USE", "action": &"active_tool_use"},
]

@export var force_visible := false

var _controls_enabled := false
var _mouse_enabled := false
var _root: Control
var _stick_panel: Panel
var _stick_knob: Panel
var _stick_label: Label
var _stick_rect := Rect2()
var _stick_touch_index := -1
var _touch_roles := {}
var _command_rects := {}
var _command_panels := {}


func _ready() -> void:
	layer = 90
	var touch_available := DisplayServer.is_touchscreen_available()
	var forced := force_visible or _has_arg(FORCE_FLAG)
	_controls_enabled = forced or (touch_available and not _is_automation_run())
	_mouse_enabled = forced and not touch_available
	visible = _controls_enabled
	set_process_input(_controls_enabled)
	if not _controls_enabled:
		return
	_build_visuals()
	get_viewport().size_changed.connect(_layout_controls)
	_layout_controls()


func _exit_tree() -> void:
	_release_stick()


func _input(event: InputEvent) -> void:
	if not _controls_enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_pointer(touch.index, touch.position)
		else:
			_end_pointer(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_drag_pointer(drag.index, drag.position)
	elif _mouse_enabled and event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_begin_pointer(-1, button.position)
			else:
				_end_pointer(-1)
	elif _mouse_enabled and event is InputEventMouseMotion and _touch_roles.has(-1):
		_drag_pointer(-1, (event as InputEventMouseMotion).position)


func get_test_report() -> Dictionary:
	return {
		"enabled": _controls_enabled,
		"bottom_inset": BOTTOM_INTERACTION_INSET,
		"viewport_size": get_viewport().get_visible_rect().size,
		"stick_rect": _stick_rect,
		"commands": COMMANDS.duplicate(true),
		"command_rects": _command_rects.duplicate(true),
	}


func _build_visuals() -> void:
	_root = Control.new()
	_root.name = "MobileTestControlSurface"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_stick_panel = _make_panel(Color(0.02, 0.08, 0.11, 0.44), Color(0.72, 0.92, 1.0, 0.48), 112)
	_stick_panel.name = "MoveStick"
	_root.add_child(_stick_panel)
	_stick_label = _make_label("MOVE", 15)
	_stick_panel.add_child(_stick_label)
	_stick_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_stick_knob = _make_panel(Color(0.27, 0.73, 0.87, 0.72), Color(0.90, 0.98, 1.0, 0.72), 36)
	_stick_knob.name = "MoveStickKnob"
	_stick_panel.add_child(_stick_knob)

	for command in COMMANDS:
		var command_id := StringName(command["id"])
		var panel := _make_panel(Color(0.02, 0.08, 0.11, 0.68), Color(0.72, 0.92, 1.0, 0.52), 8)
		panel.name = "%sButton" % str(command_id).to_pascal_case()
		_root.add_child(panel)
		var label := _make_label(str(command["label"]), 20)
		panel.add_child(label)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_command_panels[command_id] = panel


func _layout_controls() -> void:
	if _root == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var stick_position := Vector2(SIDE_MARGIN, viewport_size.y - STICK_SIZE - BOTTOM_INTERACTION_INSET)
	_stick_rect = Rect2(stick_position, Vector2(STICK_SIZE, STICK_SIZE))
	_stick_panel.position = stick_position
	_stick_panel.size = _stick_rect.size
	_center_stick_knob(Vector2.ZERO)

	var rows := ceili(float(COMMANDS.size()) / float(GRID_COLUMNS))
	var grid_size := Vector2(
		BUTTON_SIZE.x * GRID_COLUMNS + BUTTON_GAP * (GRID_COLUMNS - 1),
		BUTTON_SIZE.y * rows + BUTTON_GAP * (rows - 1)
	)
	var grid_origin := Vector2(
		viewport_size.x - grid_size.x - SIDE_MARGIN,
		viewport_size.y - grid_size.y - BOTTOM_INTERACTION_INSET
	)
	_command_rects.clear()
	for index in range(COMMANDS.size()):
		var command_id := StringName(COMMANDS[index]["id"])
		var column := index % GRID_COLUMNS
		var row := index / GRID_COLUMNS
		var position := grid_origin + Vector2(
			column * (BUTTON_SIZE.x + BUTTON_GAP),
			row * (BUTTON_SIZE.y + BUTTON_GAP)
		)
		var rect := Rect2(position, BUTTON_SIZE)
		_command_rects[command_id] = rect
		var panel := _command_panels[command_id] as Panel
		panel.position = rect.position
		panel.size = rect.size


func _begin_pointer(index: int, position: Vector2) -> void:
	if _touch_roles.has(index):
		return
	if _stick_touch_index == -1 and _stick_rect.has_point(position):
		_stick_touch_index = index
		_touch_roles[index] = &"stick"
		_update_stick(position)
		get_viewport().set_input_as_handled()
		return
	for command in COMMANDS:
		var command_id := StringName(command["id"])
		var rect := _command_rects.get(command_id, Rect2()) as Rect2
		if not rect.has_point(position):
			continue
		_touch_roles[index] = command_id
		_set_command_pressed(command_id, true)
		_dispatch_command(command)
		get_viewport().set_input_as_handled()
		return


func _drag_pointer(index: int, position: Vector2) -> void:
	if index == _stick_touch_index:
		_update_stick(position)
		get_viewport().set_input_as_handled()


func _end_pointer(index: int) -> void:
	if not _touch_roles.has(index):
		return
	var role := StringName(_touch_roles[index])
	_touch_roles.erase(index)
	if role == &"stick":
		_stick_touch_index = -1
		_release_stick()
	else:
		_set_command_pressed(role, false)
	get_viewport().set_input_as_handled()


func _update_stick(position: Vector2) -> void:
	var center := _stick_rect.get_center()
	var radius := STICK_SIZE * 0.5
	var direction := (position - center) / radius
	if direction.length() > 1.0:
		direction = direction.normalized()
	if direction.length() < STICK_DEADZONE:
		direction = Vector2.ZERO
	_set_movement_actions(direction)
	_center_stick_knob(direction)


func _release_stick() -> void:
	_stick_touch_index = -1
	for action in [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]:
		Input.action_release(action)
	if _stick_knob != null:
		_center_stick_knob(Vector2.ZERO)


func _set_movement_actions(direction: Vector2) -> void:
	_set_action_strength(&"ui_left", maxf(0.0, -direction.x))
	_set_action_strength(&"ui_right", maxf(0.0, direction.x))
	_set_action_strength(&"ui_up", maxf(0.0, -direction.y))
	_set_action_strength(&"ui_down", maxf(0.0, direction.y))


func _set_action_strength(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _center_stick_knob(direction: Vector2) -> void:
	var travel := (STICK_SIZE - STICK_KNOB_SIZE) * 0.5
	_stick_knob.position = Vector2.ONE * travel + direction * travel
	_stick_knob.size = Vector2.ONE * STICK_KNOB_SIZE


func _dispatch_command(command: Dictionary) -> void:
	if command.has("action"):
		var action_event := InputEventAction.new()
		action_event.action = StringName(command["action"])
		action_event.pressed = true
		Input.parse_input_event(action_event)
		command_dispatched.emit(StringName(command["id"]), action_event)
		var release_event := action_event.duplicate() as InputEventAction
		release_event.pressed = false
		Input.parse_input_event(release_event)
		return

	var key_event := InputEventKey.new()
	key_event.keycode = int(command["keycode"])
	key_event.physical_keycode = int(command["keycode"])
	key_event.pressed = true
	Input.parse_input_event(key_event)
	command_dispatched.emit(StringName(command["id"]), key_event)
	var release_event := key_event.duplicate() as InputEventKey
	release_event.pressed = false
	Input.parse_input_event(release_event)


func _set_command_pressed(command_id: StringName, pressed: bool) -> void:
	if not _command_panels.has(command_id):
		return
	var panel := _command_panels[command_id] as Panel
	panel.modulate = Color(1.0, 0.82, 0.48, 1.0) if pressed else Color.WHITE


func _make_panel(fill: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.96))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _has_arg(flag: String) -> bool:
	return OS.get_cmdline_user_args().has(flag) or OS.get_cmdline_args().has(flag)


func _is_automation_run() -> bool:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for arg in args:
		var value := str(arg)
		if value.begins_with("--capture-") or value.begins_with("--smoke-") or value == "--parity-output":
			return true
	return false
