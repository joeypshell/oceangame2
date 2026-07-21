extends PanelContainer

const ActiveToolController := preload("res://scripts/main/active_tool_controller.gd")
const SCANNER_ICON := preload("res://assets/ui/tool_icons/scanner_01.svg")
const CUTTER_ICON := preload("res://assets/ui/tool_icons/cutter_01.svg")
const SHOCK_PROD_ICON := preload("res://assets/ui/tool_icons/shock_prod_01.svg")

const COMPACT_VIEWPORT_WIDTH := 1100.0
const DESKTOP_SLOT_SIZE := 56.0
const COMPACT_SLOT_SIZE := 44.0
const DESKTOP_GAP := 6
const COMPACT_GAP := 5
const DESKTOP_MARGIN := 6
const COMPACT_MARGIN := 5
const DESKTOP_BOTTOM_GAP := 18.0
const COMPACT_BOTTOM_GAP := 12.0

var _row: HBoxContainer
var _margin: MarginContainer
var _slot_panels := {}
var _slot_icons := {}
var _selected_tool_id := ""
var _owned_tool_ids := PackedStringArray()
var _compact := false
var _mobile_controls_visible := false
var _last_viewport_size := Vector2(1280, 720)


func _init() -> void:
	name = "ActiveToolHotbar"
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	visible = false


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()


func refresh(report: Dictionary) -> void:
	_selected_tool_id = str(report.get("selected_tool_id", ""))
	_owned_tool_ids = _ordered_owned_ids(report.get("owned_tool_ids", []))
	for tool_id in ActiveToolController.ordered_tool_ids():
		var panel := _slot_panels.get(tool_id) as PanelContainer
		var icon := _slot_icons.get(tool_id) as TextureRect
		var owned := _owned_tool_ids.has(tool_id)
		var selected := owned and tool_id == _selected_tool_id
		panel.visible = owned
		panel.add_theme_stylebox_override("panel", _slot_style(selected))
		icon.modulate = Color.WHITE if selected else Color(0.60, 0.72, 0.76, 0.86)
	visible = not _owned_tool_ids.is_empty()
	layout_for_size(_last_viewport_size)


func set_mobile_controls_visible(value: bool) -> void:
	_mobile_controls_visible = value


func layout_for_size(viewport_size: Vector2) -> void:
	_last_viewport_size = viewport_size
	_compact = viewport_size.x <= COMPACT_VIEWPORT_WIDTH
	var slot_size := COMPACT_SLOT_SIZE if _compact else DESKTOP_SLOT_SIZE
	var gap := COMPACT_GAP if _compact else DESKTOP_GAP
	var margin_size := COMPACT_MARGIN if _compact else DESKTOP_MARGIN
	var bottom_gap := COMPACT_BOTTOM_GAP if _compact else DESKTOP_BOTTOM_GAP
	_row.add_theme_constant_override("separation", gap)
	_set_margin(margin_size)
	for tool_id in _slot_panels:
		var panel := _slot_panels[tool_id] as PanelContainer
		panel.custom_minimum_size = Vector2(slot_size, slot_size)

	var owned_count := _owned_tool_ids.size()
	var target_size := Vector2.ZERO
	if owned_count > 0:
		target_size = Vector2(
			slot_size * owned_count + gap * maxi(0, owned_count - 1) + margin_size * 2,
			slot_size + margin_size * 2
		)
	custom_minimum_size = target_size
	size = target_size
	position = Vector2(
		floor((viewport_size.x - target_size.x) * 0.5),
		floor(viewport_size.y - target_size.y - bottom_gap)
	)


func get_test_report() -> Dictionary:
	var slots := []
	for tool_id in ActiveToolController.ordered_tool_ids():
		if not _owned_tool_ids.has(tool_id):
			continue
		var icon := _slot_icons.get(tool_id) as TextureRect
		var panel := _slot_panels.get(tool_id) as PanelContainer
		slots.append({
			"id": tool_id,
			"label": ActiveToolController.tool_label(tool_id),
			"selected": tool_id == _selected_tool_id,
			"has_texture": icon.texture != null,
			"texture_path": icon.texture.resource_path if icon.texture != null else "",
			"tooltip": panel.tooltip_text,
		})
	return {
		"rect": Rect2(position, size),
		"visible": visible,
		"compact": _compact,
		"selected_tool_id": _selected_tool_id,
		"selected_label": ActiveToolController.tool_label(_selected_tool_id),
		"owned_tool_ids": _owned_tool_ids.duplicate(),
		"slots": slots,
		"prompt": "",
		"mobile_controls_visible": _mobile_controls_visible,
		"bottom_gap": _last_viewport_size.y - position.y - size.y,
	}


func _layout() -> void:
	if is_inside_tree():
		layout_for_size(get_viewport_rect().size)


func _ordered_owned_ids(raw_ids) -> PackedStringArray:
	var result := PackedStringArray()
	for tool_id in ActiveToolController.ordered_tool_ids():
		if raw_ids.has(tool_id):
			result.append(tool_id)
	return result


func _build_ui() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.055, 0.075, 0.88)
	panel_style.border_color = Color(0.48, 0.82, 0.88, 0.44)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 0.0
	panel_style.content_margin_top = 0.0
	panel_style.content_margin_right = 0.0
	panel_style.content_margin_bottom = 0.0
	add_theme_stylebox_override("panel", panel_style)

	_margin = MarginContainer.new()
	add_child(_margin)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_margin.add_child(_row)

	for tool_id in ActiveToolController.ordered_tool_ids():
		var slot := PanelContainer.new()
		slot.name = "%sSlot" % ActiveToolController.tool_label(tool_id).replace(" ", "")
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.tooltip_text = ActiveToolController.tool_label(tool_id)
		_row.add_child(slot)

		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon.texture = _icon_for(tool_id)
		slot.add_child(icon)
		_slot_panels[tool_id] = slot
		_slot_icons[tool_id] = icon


func _set_margin(value: int) -> void:
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		_margin.add_theme_constant_override(side, value)


func _slot_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.15, 0.19, 0.96) if selected else Color(0.025, 0.085, 0.11, 0.82)
	style.border_color = Color(1.0, 0.73, 0.24, 1.0) if selected else Color(0.38, 0.65, 0.70, 0.58)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 6.0
	style.content_margin_top = 6.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 6.0
	if selected:
		style.shadow_color = Color(1.0, 0.67, 0.18, 0.22)
		style.shadow_size = 3
	return style


func _icon_for(tool_id: String) -> Texture2D:
	match tool_id:
		ActiveToolController.SCANNER_TOOL_ID:
			return SCANNER_ICON
		ActiveToolController.CUTTER_TOOL_ID:
			return CUTTER_ICON
		ActiveToolController.SHOCK_PROD_TOOL_ID:
			return SHOCK_PROD_ICON
	return null
