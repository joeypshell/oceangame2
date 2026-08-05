extends CanvasLayer

const CompanionActionIcon := preload("res://scripts/companion/companion_action_icon.gd")
const COMPACT_VIEWPORT_WIDTH := 1100.0
const DESKTOP_SLOT_SIZE := 56.0
const COMPACT_SLOT_SIZE := 44.0
const DESKTOP_BOTTOM_GAP := 18.0
const COMPACT_BOTTOM_GAP := 12.0

var _panel: PanelContainer
var _row: HBoxContainer
var _actions: Array = []
var _selected_action_id := ""
var _compact := false
var _last_viewport_size := Vector2(1280, 720)


func _ready() -> void:
	layer = 84
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()


func sync(actions: Array, selected_action_id: String, mounted: bool) -> void:
	var previous_ids := _actions.map(func(action): return str(action.get("id", "")))
	_actions = actions.duplicate(true)
	_selected_action_id = selected_action_id
	var next_ids := _actions.map(func(action): return str(action.get("id", "")))
	if previous_ids != next_ids:
		_rebuild_slots()
	else:
		_update_slots()
	_panel.visible = mounted and not _actions.is_empty()
	layout_for_size(_last_viewport_size)


func layout_for_size(viewport_size: Vector2) -> void:
	if _panel == null:
		return
	_last_viewport_size = viewport_size
	_compact = viewport_size.x <= COMPACT_VIEWPORT_WIDTH
	var slot_size := COMPACT_SLOT_SIZE if _compact else DESKTOP_SLOT_SIZE
	var margin := 5.0 if _compact else 6.0
	var gap := 5.0 if _compact else 6.0
	var target_size := Vector2(
		slot_size * _actions.size() + gap * maxi(0, _actions.size() - 1) + margin * 2.0,
		slot_size + margin * 2.0
	)
	_row.add_theme_constant_override("separation", int(gap))
	for slot in _row.get_children():
		(slot as Control).custom_minimum_size = Vector2(slot_size, slot_size)
	_panel.size = target_size
	_panel.position = Vector2(
		floor((viewport_size.x - target_size.x) * 0.5),
		floor(viewport_size.y - target_size.y - (COMPACT_BOTTOM_GAP if _compact else DESKTOP_BOTTOM_GAP))
	)


func get_test_report() -> Dictionary:
	var slots := []
	if _row != null:
		for index in range(_row.get_child_count()):
			var action: Dictionary = _actions[index]
			slots.append({
				"id": str(action.get("id", "")),
				"selected": str(action.get("id", "")) == _selected_action_id,
				"tooltip": (_row.get_child(index) as Control).tooltip_text,
				"cooldown_seconds": float(action.get("cooldown_seconds", 0.0)),
			})
	return {
		"visible": _panel != null and _panel.visible,
		"rect": Rect2(_panel.position, _panel.size) if _panel != null else Rect2(),
		"compact": _compact,
		"selected_action_id": _selected_action_id,
		"slots": slots,
	}


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "CompanionActionHotbar"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.055, 0.075, 0.9)
	style.border_color = Color(0.38, 0.88, 0.92, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 5.0
	style.content_margin_top = 5.0
	style.content_margin_right = 5.0
	style.content_margin_bottom = 5.0
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(_row)
	_panel.visible = false


func _rebuild_slots() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for action in _actions:
		var action_id := str(action.get("id", ""))
		var slot := PanelContainer.new()
		slot.tooltip_text = str(action.get("label", action_id.replace("_", " ")))
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.add_theme_stylebox_override("panel", _slot_style(action_id == _selected_action_id))
		var icon := CompanionActionIcon.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		_row.add_child(slot)
	_update_slots()


func _update_slots() -> void:
	for index in range(_actions.size()):
		var action: Dictionary = _actions[index]
		var action_id := str(action.get("id", ""))
		var slot := _row.get_child(index) as PanelContainer
		var icon := slot.get_child(0) as Control
		var selected := action_id == _selected_action_id
		var duration := maxf(0.01, float(action.get("cooldown_duration", 0.0)))
		slot.tooltip_text = str(action.get("label", action_id.replace("_", " ")))
		slot.add_theme_stylebox_override("panel", _slot_style(selected))
		icon.sync(action_id, selected, float(action.get("cooldown_seconds", 0.0)) / duration)


func _slot_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.16, 0.19, 0.98) if selected else Color(0.025, 0.085, 0.11, 0.84)
	style.border_color = Color(0.58, 0.96, 1.0, 1.0) if selected else Color(0.34, 0.66, 0.70, 0.62)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(5)
	return style


func _layout() -> void:
	if is_inside_tree():
		layout_for_size(get_viewport().get_visible_rect().size)
