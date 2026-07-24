extends VBoxContainer

const EQUIPMENT_ORDER := [
	"propulsion_fins",
	"dive_light_1",
	"pressure_suit_1",
	"current_stabilizer",
	"shock_prod_capacitor",
]
const EQUIPMENT_LABELS := {
	"propulsion_fins": "Propulsion fins",
	"dive_light_1": "Dive light",
	"pressure_suit_1": "Pressure suit",
	"current_stabilizer": "Current Stabilizer",
	"shock_prod_capacitor": "Shock Prod capacitor",
}
const EQUIPMENT_TEXTURES := {
	"propulsion_fins": preload("res://assets/ui/equipment_icons/propulsion_fins_01.svg"),
	"dive_light_1": preload("res://assets/ui/equipment_icons/dive_light_01.svg"),
	"pressure_suit_1": preload("res://assets/ui/equipment_icons/pressure_suit_01.svg"),
	"current_stabilizer": preload("res://assets/ui/equipment_icons/current_stabilizer_01.svg"),
	"shock_prod_capacitor": preload("res://assets/ui/equipment_icons/shock_prod_capacitor_01.svg"),
}
const DESKTOP_SLOT_SIZE := Vector2(28, 34)
const COMPACT_SLOT_SIZE := Vector2(24, 34)

var _title_label: Label
var _row: HBoxContainer
var _slot_panels: Array[PanelContainer] = []
var _slot_textures: Array[TextureRect] = []
var _slot_symbols: Array[Label] = []
var _slot_badges: Array[Label] = []
var _owned_items: Array[Dictionary] = []
var _displayed_items: Array[Dictionary] = []
var _compact := false


func _init() -> void:
	name = "PassiveEquipmentStrip"
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()


func refresh(owned_capability_ids) -> void:
	_owned_items = []
	for capability_id in EQUIPMENT_ORDER:
		if owned_capability_ids.has(capability_id):
			_owned_items.append(_item(capability_id))
	_render()


func layout_for_mode(compact: bool) -> void:
	_compact = compact
	_title_label.text = "EQ" if compact else "EQUIPPED"
	_title_label.add_theme_font_size_override("font_size", 9 if compact else 10)
	_row.add_theme_constant_override("separation", 0 if compact else 3)
	for index in range(_slot_panels.size()):
		_slot_panels[index].visible = index == 0 if compact else true
		_slot_panels[index].custom_minimum_size = COMPACT_SLOT_SIZE if compact else DESKTOP_SLOT_SIZE
		_slot_symbols[index].add_theme_font_size_override("font_size", 8 if compact else 9)
		_slot_badges[index].add_theme_font_size_override("font_size", 8)
	custom_minimum_size = Vector2(24, 0) if compact else Vector2(152, 0)
	_render()


func get_test_report() -> Dictionary:
	var slots := []
	for index in range(_slot_panels.size()):
		if not _slot_panels[index].visible:
			continue
		var texture := _slot_textures[index].texture
		slots.append({
			"tooltip": _slot_panels[index].tooltip_text,
			"has_texture": texture != null,
			"texture_path": texture.resource_path if texture != null else "",
			"badge": _slot_badges[index].text,
		})
	return {
		"title": _title_label.text,
		"compact": _compact,
		"owned_items": _owned_items.duplicate(true),
		"displayed_items": _displayed_items.duplicate(true),
		"slots": slots,
	}


func _item(capability_id: String) -> Dictionary:
	return {
		"id": capability_id,
		"label": str(EQUIPMENT_LABELS.get(capability_id, capability_id.replace("_", " ").capitalize())),
		"texture_id": capability_id,
		"has_texture": EQUIPMENT_TEXTURES.has(capability_id),
	}


func _render() -> void:
	if _slot_panels.is_empty():
		return
	_displayed_items = []
	if _compact and not _owned_items.is_empty():
		var names := PackedStringArray()
		for item in _owned_items:
			names.append(str(item.get("label", "")))
		_displayed_items.append({
			"id": "equipment_summary",
			"label": "Equipped: %s" % ", ".join(names),
			"texture_id": str(_owned_items[-1].get("texture_id", "")),
			"quantity": _owned_items.size(),
			"has_texture": true,
		})
	elif not _compact:
		_displayed_items = _owned_items.duplicate(true)

	for index in range(_slot_panels.size()):
		if _compact and index > 0:
			continue
		var item: Dictionary = _displayed_items[index] if index < _displayed_items.size() else {}
		_render_slot(index, item)


func _render_slot(index: int, item: Dictionary) -> void:
	var texture_id := str(item.get("texture_id", ""))
	var texture = EQUIPMENT_TEXTURES.get(texture_id)
	var has_item := not item.is_empty()
	_slot_textures[index].texture = texture if texture is Texture2D else null
	_slot_textures[index].visible = texture is Texture2D
	_slot_textures[index].modulate = Color.WHITE
	_slot_symbols[index].visible = not _slot_textures[index].visible
	_slot_symbols[index].text = "-" if not has_item else "EQ"
	_slot_symbols[index].modulate = Color(0.68, 0.90, 0.94, 0.24 if not has_item else 0.92)
	_slot_badges[index].text = str(item.get("quantity", ""))
	_slot_badges[index].visible = item.has("quantity")
	_slot_panels[index].tooltip_text = str(item.get("label", "Empty equipment slot"))
	_slot_panels[index].add_theme_stylebox_override("panel", _slot_style(has_item))


func _build_ui() -> void:
	add_theme_constant_override("separation", 1)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", Color(0.56, 0.92, 0.82, 1.0))
	add_child(_title_label)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_row)
	for _index in range(EQUIPMENT_ORDER.size()):
		_add_slot()
	layout_for_mode(false)
	refresh([])


func _add_slot() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_row.add_child(panel)
	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)
	var symbol := Label.new()
	symbol.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(symbol)
	var badge := Label.new()
	badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	badge.add_theme_color_override("font_color", Color(1.0, 0.87, 0.45, 1.0))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(badge)
	_slot_panels.append(panel)
	_slot_textures.append(icon)
	_slot_symbols.append(symbol)
	_slot_badges.append(badge)


func _slot_style(owned: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.14, 0.15, 0.92) if owned else Color(0.02, 0.07, 0.09, 0.55)
	style.border_color = Color(0.35, 0.82, 0.68, 0.72) if owned else Color(0.35, 0.58, 0.60, 0.24)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 3.0
	style.content_margin_top = 3.0
	style.content_margin_right = 3.0
	style.content_margin_bottom = 3.0
	return style
