extends PanelContainer

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const TITANIUM_COLOR := Color(0.52, 0.84, 0.92, 1.0)
const RUBBER_COLOR := Color(0.96, 0.72, 0.28, 1.0)
const READY_COLOR := Color(0.50, 0.94, 0.58, 1.0)
const HELD_COLOR := Color(1.0, 0.84, 0.42, 1.0)
const PENDING_COLOR := Color(0.86, 0.94, 0.98, 0.96)

var _titanium_label: Label
var _rubber_label: Label
var _footer_label: Label


func _init() -> void:
	name = "ProgressionProjectTracker"
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -304.0
	offset_top = 12.0
	offset_right = -12.0
	offset_bottom = 0.0
	custom_minimum_size = Vector2(292, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()


func refresh(project_report: Dictionary, held: Dictionary, in_debrief: bool) -> void:
	visible = (
		bool(project_report.get("propulsion_blueprint_recovered", false))
		and not bool(project_report.get("propulsion_fins_unlocked", false))
		and project_report.get("project_ids", []).has(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID)
		and not in_debrief
	)
	if not visible:
		return
	var required: Dictionary = project_report.get("propulsion_required_materials", {})
	var titanium_required := int(required.get("titanium_scrap", 2))
	var rubber_required := int(required.get("rubber_sheet", 1))
	var titanium_banked := int(project_report.get("titanium_banked", 0))
	var rubber_banked := int(project_report.get("rubber_banked", 0))
	var titanium_held := int(held.get("titanium_scrap", 0))
	var rubber_held := int(held.get("rubber_sheet", 0))
	_set_material_row(_titanium_label, "Titanium", titanium_banked, titanium_held, titanium_required)
	_set_material_row(_rubber_label, "Rubber", rubber_banked, rubber_held, rubber_required)
	if titanium_banked >= titanium_required and rubber_banked >= rubber_required:
		_footer_label.text = "Ready | End day at boat, then P"
		_footer_label.add_theme_color_override("font_color", READY_COLOR)
	elif titanium_banked + titanium_held >= titanium_required and rubber_banked + rubber_held >= rubber_required:
		_footer_label.text = "Bank held materials at boat"
		_footer_label.add_theme_color_override("font_color", HELD_COLOR)
	else:
		_footer_label.text = "Gather materials | Held cannot be spent"
		_footer_label.add_theme_color_override("font_color", PENDING_COLOR)


func snapshot_text() -> String:
	return "\n".join([_titanium_label.text, _rubber_label.text, _footer_label.text])


func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.07, 0.10, 0.82)
	style.border_color = Color(0.72, 0.92, 1.0, 0.26)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "PROPULSION FINS"
	title.add_theme_color_override("font_color", Color(0.80, 0.96, 1.0, 1.0))
	title.add_theme_font_size_override("font_size", 13)
	stack.add_child(title)
	_titanium_label = _add_material_row(stack, TITANIUM_COLOR)
	_rubber_label = _add_material_row(stack, RUBBER_COLOR)
	_footer_label = Label.new()
	_footer_label.add_theme_font_size_override("font_size", 12)
	stack.add_child(_footer_label)


func _add_material_row(parent: VBoxContainer, swatch_color: Color) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	parent.add_child(row)
	var swatch := ColorRect.new()
	swatch.color = swatch_color
	swatch.custom_minimum_size = Vector2(11, 11)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(swatch)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	return label


func _set_material_row(label: Label, display_name: String, banked: int, held: int, required: int) -> void:
	label.text = "%s  %d/%d banked  (+%d held)" % [display_name, banked, required, held]
	var color := READY_COLOR if banked >= required else HELD_COLOR if banked + held >= required else PENDING_COLOR
	label.add_theme_color_override("font_color", color)
