extends CanvasLayer

const MAX_COMMANDS := 3
const COMPACT_VIEWPORT_WIDTH := 900.0

var _panel: PanelContainer
var _stack: VBoxContainer
var _header: Label
var _commands: Array = []
var _selected_index := 0
var _last_feedback := ""
var _last_viewport_size := Vector2(1280, 720)


func _ready() -> void:
	layer = 86
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()


func sync(commands: Array, selected_index: int, feedback := "") -> void:
	var next_commands: Array = commands.slice(0, MAX_COMMANDS).duplicate(true)
	var next_index := clampi(selected_index, 0, maxi(0, next_commands.size() - 1))
	if next_commands != _commands or next_index != _selected_index or feedback != _last_feedback:
		_commands = next_commands
		_selected_index = next_index
		_last_feedback = feedback
		_rebuild_rows()
	_panel.visible = true
	_layout()


func hide_palette() -> void:
	if _panel != null:
		_panel.visible = false


func get_test_report() -> Dictionary:
	return {
		"visible": _panel != null and _panel.visible,
		"rect": Rect2(_panel.position, _panel.size) if _panel != null else Rect2(),
		"command_count": _commands.size(),
		"commands": _commands.duplicate(true),
		"selected_index": _selected_index,
		"feedback": _last_feedback,
	}


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "CompanionCommandPalette"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.06, 0.08, 0.94)
	style.border_color = Color(0.55, 0.94, 0.98, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 5)
	_panel.add_child(_stack)
	_header = Label.new()
	_header.text = "BOND  20%"
	_header.add_theme_color_override("font_color", Color(0.62, 0.95, 1.0, 1.0))
	_header.add_theme_font_size_override("font_size", 13)
	_stack.add_child(_header)
	_panel.visible = false


func _rebuild_rows() -> void:
	for child in _stack.get_children():
		if child != _header:
			_stack.remove_child(child)
			child.queue_free()
	for index in range(_commands.size()):
		var command: Dictionary = _commands[index]
		var enabled := bool(command.get("enabled", true))
		var label := Label.new()
		label.custom_minimum_size = Vector2(210, 28)
		label.text = "%s  %s" % [">" if index == _selected_index else " ", str(command.get("label", "Command"))]
		if not enabled and command.has("denial"):
			label.text += " - %s" % str(command["denial"])
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", _row_color(index == _selected_index, enabled))
		label.add_theme_font_size_override("font_size", 14)
		_stack.add_child(label)
	if not _last_feedback.is_empty():
		var feedback := Label.new()
		feedback.custom_minimum_size = Vector2(210, 0)
		feedback.text = _last_feedback
		feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		feedback.add_theme_color_override("font_color", Color(1.0, 0.78, 0.34, 0.98))
		feedback.add_theme_font_size_override("font_size", 12)
		_stack.add_child(feedback)


func _row_color(selected: bool, enabled: bool) -> Color:
	if not enabled:
		return Color(0.58, 0.68, 0.70, 0.88)
	return Color(1.0, 0.82, 0.38, 1.0) if selected else Color(0.88, 0.97, 1.0, 0.96)


func _layout() -> void:
	if _panel == null or not is_inside_tree():
		return
	_last_viewport_size = get_viewport().get_visible_rect().size
	var compact := _last_viewport_size.x <= COMPACT_VIEWPORT_WIDTH
	var width := 230.0 if compact else 260.0
	_header.visible = not compact
	_stack.add_theme_constant_override("separation", 2 if compact else 5)
	for child in _stack.get_children():
		if child == _header:
			continue
		var label := child as Label
		label.custom_minimum_size = Vector2(210, 24 if compact else 28)
		label.add_theme_font_size_override("font_size", 12 if compact else 14)
	_panel.custom_minimum_size.x = width
	_panel.reset_size()
	if compact:
		_panel.position = Vector2(floor((_last_viewport_size.x - _panel.size.x) * 0.5), _last_viewport_size.y - _panel.size.y - 6.0)
	else:
		_panel.position = Vector2(_last_viewport_size.x - _panel.size.x - 24.0, 86.0)
