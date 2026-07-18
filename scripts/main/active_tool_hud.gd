extends PanelContainer

const COMPACT_VIEWPORT_WIDTH := 1100.0
const DESKTOP_SIZE := Vector2(224.0, 58.0)
const COMPACT_SIZE := Vector2(92.0, 62.0)
const COMPACT_LEFT := 314.0
const TOP_OFFSET := 90.0
const TOOL_SYMBOLS := {
	"survey_scanner_1": "[S]",
	"salvage_cutter": "[C]",
	"shock_prod": "[Z]",
}

var _symbol_label: Label
var _name_label: Label
var _prompt_label: Label
var _selected_tool_id := ""
var _compact := false
var _mobile_controls_visible := false


func _init() -> void:
	name = "ActiveToolHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()


func refresh(report: Dictionary) -> void:
	_selected_tool_id = str(report.get("selected_tool_id", ""))
	var selected_label := str(report.get("selected_label", ""))
	if _selected_tool_id.is_empty():
		_symbol_label.text = "[-]"
		_name_label.text = "No tool"
	else:
		_symbol_label.text = str(TOOL_SYMBOLS.get(_selected_tool_id, "[?]"))
		_name_label.text = selected_label if not selected_label.is_empty() else "Active tool"
	_refresh_prompt_visibility()


func set_mobile_controls_visible(value: bool) -> void:
	_mobile_controls_visible = value
	_refresh_prompt_visibility()


func layout_for_size(viewport_size: Vector2) -> void:
	_compact = viewport_size.x <= COMPACT_VIEWPORT_WIDTH
	var target_size := COMPACT_SIZE if _compact else DESKTOP_SIZE
	_refresh_prompt_visibility()
	custom_minimum_size = target_size
	size = target_size
	position = Vector2(
		COMPACT_LEFT if _compact else floor((viewport_size.x - target_size.x) * 0.5),
		TOP_OFFSET
	)


func get_test_report() -> Dictionary:
	return {
		"rect": Rect2(position, size),
		"compact": _compact,
		"selected_tool_id": _selected_tool_id,
		"symbol": _symbol_label.text,
		"label": _name_label.text,
		"prompt": _prompt_label.text if _prompt_label.visible else "",
	}


func _layout() -> void:
	layout_for_size(get_viewport_rect().size)


func _refresh_prompt_visibility() -> void:
	if _prompt_label != null:
		_prompt_label.visible = not _compact and not _mobile_controls_visible and not _selected_tool_id.is_empty()


func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.07, 0.10, 0.82)
	style.border_color = Color(0.72, 0.92, 1.0, 0.36)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	margin.add_child(row)

	_symbol_label = Label.new()
	_symbol_label.custom_minimum_size = Vector2(30, 0)
	_symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_symbol_label.add_theme_color_override("font_color", Color(0.48, 0.92, 1.0, 1.0))
	_symbol_label.add_theme_font_size_override("font_size", 15)
	row.add_child(_symbol_label)

	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 0)
	row.add_child(text_stack)

	_name_label = Label.new()
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	_name_label.add_theme_font_size_override("font_size", 13)
	text_stack.add_child(_name_label)

	_prompt_label = Label.new()
	_prompt_label.text = "Tab Tool | Q Use"
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42, 0.96))
	_prompt_label.add_theme_font_size_override("font_size", 11)
	text_stack.add_child(_prompt_label)

	refresh({})
