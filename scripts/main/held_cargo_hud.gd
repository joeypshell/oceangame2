extends PanelContainer

const PassiveEquipmentStrip := preload("res://scripts/main/passive_equipment_strip.gd")

const COMPACT_VIEWPORT_WIDTH := 1259.0
const DESKTOP_SIZE := Vector2(520.0, 72.0)
const COMPACT_HEIGHT := 72.0
const COMPACT_LEFT := 372.0
const COMPACT_MIN_WIDTH := 148.0
const COMPACT_MAX_WIDTH := 220.0
const COMPACT_RIGHT_RESERVE := 696.0
const TOP_OFFSET := 12.0
const DESKTOP_SLOT_COUNT := 6
const COMPACT_SLOT_COUNT := 2
const MATERIAL_ORDER := [
	"titanium_scrap",
	"rubber_sheet",
	"conductive_coil",
	"insulating_gel",
	"eel_electrocyte",
]
const ITEM_LABELS := {
	"titanium_scrap": "Titanium",
	"rubber_sheet": "Rubber",
	"conductive_coil": "Coil",
	"insulating_gel": "Insulating gel",
	"eel_electrocyte": "Eel electrocyte",
	"held_salvage": "Valuable salvage",
}
const ITEM_SYMBOLS := {
	"titanium_scrap": "Ti",
	"rubber_sheet": "Ru",
	"conductive_coil": "Co",
	"insulating_gel": "Ge",
	"eel_electrocyte": "El",
	"held_salvage": "V",
}
const ITEM_TEXTURES := {
	"titanium_scrap": preload("res://assets/materials/titanium_scrap_01.png"),
	"rubber_sheet": preload("res://assets/materials/rubber_sheet_01.png"),
	"conductive_coil": preload("res://assets/materials/conductive_coil_01.png"),
	"held_salvage": preload("res://assets/props/relic_01.png"),
}

var _panel_style: StyleBoxFlat
var _title_label: Label
var _capacity_label: Label
var _slots_row: HBoxContainer
var _segments_row: HBoxContainer
var _equipment_strip
var _slot_roots: Array[Control] = []
var _slot_textures: Array[TextureRect] = []
var _slot_symbols: Array[Label] = []
var _slot_counts: Array[Label] = []
var _items: Array[Dictionary] = []
var _displayed_items: Array[Dictionary] = []
var _used := 0
var _capacity := 0
var _available := 0
var _compact := false


func _init() -> void:
	name = "HeldCargoHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()


func refresh(
	material_report: Dictionary,
	sortie_report: Dictionary,
	capacity: int,
	owned_capability_ids = [],
	equipment_context := {}
) -> void:
	_items = _snapshot_items(material_report, sortie_report)
	_equipment_strip.refresh(owned_capability_ids, equipment_context)
	_capacity = maxi(0, capacity)
	_used = maxi(0, int(material_report.get("held_count", 0))) + maxi(0, int(sortie_report.get("held_salvage", 0)))
	_available = maxi(0, _capacity - _used)
	_refresh_capacity_text()
	_capacity_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.60, 0.28, 1.0) if _capacity > 0 and _available == 0 else Color(0.72, 0.92, 1.0, 0.96)
	)
	_panel_style.border_color = Color(1.0, 0.60, 0.28, 0.66) if _capacity > 0 and _available == 0 else Color(0.72, 0.92, 1.0, 0.36)
	_render_slots()


func layout_for_size(viewport_size: Vector2) -> void:
	_compact = viewport_size.x <= COMPACT_VIEWPORT_WIDTH
	var target_size := DESKTOP_SIZE
	if _compact:
		target_size.x = clampf(viewport_size.x - COMPACT_RIGHT_RESERVE, COMPACT_MIN_WIDTH, COMPACT_MAX_WIDTH)
		target_size.y = COMPACT_HEIGHT
	_title_label.text = "BAG" if _compact else "CARGO"
	_title_label.visible = not _compact
	_title_label.add_theme_font_size_override("font_size", 10 if _compact else 12)
	_capacity_label.add_theme_font_size_override("font_size", 9 if _compact else 11)
	_slots_row.add_theme_constant_override("separation", 2 if _compact else 8)
	_segments_row.add_theme_constant_override("separation", 3 if _compact else 8)
	_equipment_strip.layout_for_mode(_compact)
	for index in range(_slot_roots.size()):
		_slot_roots[index].visible = index < (COMPACT_SLOT_COUNT if _compact else DESKTOP_SLOT_COUNT)
		_slot_roots[index].custom_minimum_size = Vector2(24, 34) if _compact else Vector2(44, 38)
		_slot_symbols[index].add_theme_font_size_override("font_size", 9 if _compact else 11)
		_slot_counts[index].add_theme_font_size_override("font_size", 9 if _compact else 10)
	_refresh_capacity_text()
	custom_minimum_size = target_size
	size = target_size
	position = Vector2(COMPACT_LEFT if _compact else floor((viewport_size.x - target_size.x) * 0.5), TOP_OFFSET)
	_render_slots()


func get_test_report() -> Dictionary:
	return {
		"rect": Rect2(position, size),
		"compact": _compact,
		"used": _used,
		"capacity": _capacity,
		"available": _available,
		"capacity_text": _capacity_label.text,
		"items": _items.duplicate(true),
		"displayed_items": _displayed_items.duplicate(true),
		"equipment": _equipment_strip.get_test_report(),
	}


func _layout() -> void:
	if not is_inside_tree():
		return
	layout_for_size(get_viewport_rect().size)


func _refresh_capacity_text() -> void:
	_capacity_label.text = "%d/%d %d free" % [_used, _capacity, _available] if _compact else "%d/%d | %d free" % [_used, _capacity, _available]


func _snapshot_items(material_report: Dictionary, sortie_report: Dictionary) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	var held: Dictionary = material_report.get("held_quantities", {})
	for material_id in MATERIAL_ORDER:
		var quantity := maxi(0, int(held.get(material_id, 0)))
		if quantity > 0:
			values.append(_item(material_id, quantity))
	var salvage_count := maxi(0, int(sortie_report.get("held_salvage", 0)))
	if salvage_count > 0:
		values.append(_item("held_salvage", salvage_count))
	return values


func _item(item_id: String, quantity: int) -> Dictionary:
	return {
		"id": item_id,
		"label": str(ITEM_LABELS.get(item_id, item_id.replace("_", " ").capitalize())),
		"symbol": str(ITEM_SYMBOLS.get(item_id, "?")),
		"quantity": quantity,
		"has_texture": ITEM_TEXTURES.has(item_id),
	}


func _render_slots() -> void:
	var slot_count := COMPACT_SLOT_COUNT if _compact else DESKTOP_SLOT_COUNT
	_displayed_items = []
	for item in _items:
		_displayed_items.append(item.duplicate(true))
	if _compact and _displayed_items.size() > COMPACT_SLOT_COUNT:
		var hidden_types := _displayed_items.size() - 1
		var compact_items: Array[Dictionary] = [_displayed_items[0], {
			"id": "overflow",
			"label": "%d more cargo types" % hidden_types,
			"symbol": "+",
			"quantity": hidden_types,
			"has_texture": false,
		}]
		_displayed_items = compact_items
	for index in range(DESKTOP_SLOT_COUNT):
		if index >= slot_count:
			continue
		var item: Dictionary = _displayed_items[index] if index < _displayed_items.size() else {}
		_render_slot(index, item)


func _render_slot(index: int, item: Dictionary) -> void:
	var item_id := str(item.get("id", ""))
	var texture = ITEM_TEXTURES.get(item_id)
	_slot_textures[index].texture = texture if texture is Texture2D else null
	_slot_textures[index].visible = texture is Texture2D
	_slot_symbols[index].visible = not _slot_textures[index].visible
	_slot_symbols[index].text = str(item.get("symbol", "·"))
	_slot_symbols[index].modulate = Color(0.70, 0.92, 1.0, 1.0) if not item.is_empty() else Color(0.70, 0.92, 1.0, 0.28)
	_slot_counts[index].text = str(item.get("quantity", ""))
	_slot_counts[index].modulate = Color(0.98, 0.99, 1.0, 0.96) if not item.is_empty() else Color.TRANSPARENT
	_slot_roots[index].tooltip_text = str(item.get("label", "Empty cargo slot"))


func _build_ui() -> void:
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.02, 0.07, 0.10, 0.84)
	_panel_style.border_color = Color(0.72, 0.92, 1.0, 0.36)
	_panel_style.set_border_width_all(1)
	_panel_style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", _panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)

	_segments_row = HBoxContainer.new()
	_segments_row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(_segments_row)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 1)
	_segments_row.add_child(stack)

	var header := HBoxContainer.new()
	stack.add_child(header)
	_title_label = Label.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_color_override("font_color", Color(0.80, 0.96, 1.0, 1.0))
	header.add_child(_title_label)
	_capacity_label = Label.new()
	_capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_capacity_label)

	_slots_row = HBoxContainer.new()
	_slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(_slots_row)
	for _index in range(DESKTOP_SLOT_COUNT):
		_add_slot()

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(1, 48)
	divider.color = Color(0.42, 0.76, 0.76, 0.34)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_segments_row.add_child(divider)

	_equipment_strip = PassiveEquipmentStrip.new()
	_segments_row.add_child(_equipment_strip)
	refresh({}, {}, 0, [])


func _add_slot() -> void:
	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", -2)
	_slots_row.add_child(root)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(24, 22)
	root.add_child(icon)
	var texture := TextureRect.new()
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(texture)
	var symbol := Label.new()
	symbol.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(symbol)
	var count := Label.new()
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(count)
	_slot_roots.append(root)
	_slot_textures.append(texture)
	_slot_symbols.append(symbol)
	_slot_counts.append(count)
