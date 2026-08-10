extends CanvasLayer

const COMPACT_VIEWPORT_WIDTH := 900.0

var _panel: PanelContainer
var _stack: VBoxContainer
var _header: Label
var _footer: Label
var _signature := ""
var _rows: Array[Dictionary] = []
var _active_individual_id := ""
var _selection_open := false
var _highlighted_index := 0
var _feedback := ""
var _last_viewport_size := Vector2(1280, 720)


func _ready() -> void:
	layer = 85
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()


func sync(
	individuals: Array,
	active_individual_id: String,
	selection_open: bool,
	highlighted_index: int,
	feedback := ""
) -> void:
	var signature := JSON.stringify([
		individuals,
		active_individual_id,
		selection_open,
		highlighted_index,
		feedback,
	])
	if signature != _signature:
		_signature = signature
		_rows = _snapshot_rows(individuals)
		_active_individual_id = active_individual_id
		_selection_open = selection_open
		_highlighted_index = clampi(highlighted_index, 0, maxi(0, _rows.size() - 1))
		_feedback = feedback
		_rebuild()
	_panel.visible = not _rows.is_empty()
	_layout()


func hide_habitat() -> void:
	if _panel != null:
		_panel.visible = false


func get_test_report() -> Dictionary:
	return {
		"visible": _panel != null and _panel.visible,
		"rect": Rect2(_panel.position, _panel.size) if _panel != null else Rect2(),
		"rows": _rows.duplicate(true),
		"active_individual_id": _active_individual_id,
		"selection_open": _selection_open,
		"highlighted_index": _highlighted_index,
		"feedback": _feedback,
	}


func layout_for_size(viewport_size: Vector2) -> void:
	_apply_layout(viewport_size)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "CompanionBoatHabitat"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.06, 0.08, 0.92)
	style.border_color = Color(0.42, 0.82, 0.86, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_top = 7.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 7.0
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 3)
	_panel.add_child(_stack)
	_header = _label("BOAT HABITAT", 12, Color(0.62, 0.95, 1.0, 1.0))
	_stack.add_child(_header)
	_panel.visible = false


func _rebuild() -> void:
	for child in _stack.get_children():
		if child != _header:
			_stack.remove_child(child)
			child.free()
	for index in range(_rows.size()):
		var row: Dictionary = _rows[index]
		var selected := str(row["individual_id"]) == _active_individual_id
		var highlighted := _selection_open and index == _highlighted_index
		var line := "%s%s | %s" % ["> " if highlighted else "  ", row["callsign"], row["species_label"]]
		if selected:
			line += " | NEXT"
		var label := _label(
			line,
			13,
			Color(1.0, 0.82, 0.38, 1.0) if highlighted else Color(0.88, 0.97, 1.0, 0.96)
		)
		label.custom_minimum_size = Vector2(216, 22)
		_stack.add_child(label)
		var detail := _label("    %s" % str(row["history_label"]), 10, Color(0.62, 0.78, 0.80, 0.94))
		_stack.add_child(detail)
	_footer = _label(_footer_text(), 11, Color(1.0, 0.78, 0.34, 0.98))
	_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stack.add_child(_footer)
	_panel.reset_size()


func _footer_text() -> String:
	if not _feedback.is_empty():
		return _feedback
	if _selection_open:
		return "TOOL choose | USE next sortie | BOND close"
	if _rows.size() > 1:
		return "BOND choose next companion"
	return "%s is ready for the next sortie" % str(_rows[0]["callsign"]) if not _rows.is_empty() else ""


func _snapshot_rows(individuals: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for value in individuals:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var individual := value as Dictionary
		var memory_count := (individual.get("earned_memory_ids", []) as Array).size()
		var adaptation_id := str(individual.get("selected_adaptation_id", ""))
		var history := "%d memories" % memory_count
		if not adaptation_id.is_empty():
			history += " | %s" % adaptation_id.replace("_", " ").capitalize()
		elif str(individual.get("species_id", "")) == "veil_cuttle":
			history += " | sensing partner"
		elif str(individual.get("species_id", "")) == "silt_hound":
			history += " | excavation partner"
		rows.append({
			"individual_id": str(individual.get("individual_id", "")),
			"callsign": str(individual.get("callsign", "Companion")),
			"species_label": _species_label(str(individual.get("species_id", ""))),
			"history_label": history,
		})
	return rows


func _species_label(species_id: String) -> String:
	match species_id:
		"spark_ray":
			return "Spark Ray"
		"veil_cuttle":
			return "Veil Cuttle"
		"silt_hound":
			return "Silt Hound"
	return species_id.replace("_", " ").capitalize()


func _layout() -> void:
	if _panel == null or not is_inside_tree():
		return
	_apply_layout(get_viewport().get_visible_rect().size)


func _apply_layout(viewport_size: Vector2) -> void:
	_last_viewport_size = viewport_size
	var compact := _last_viewport_size.x <= COMPACT_VIEWPORT_WIDTH
	var width := 236.0 if compact else 284.0
	_header.visible = not compact
	_panel.custom_minimum_size.x = width
	_panel.reset_size()
	var margin := 12.0 if compact else 18.0
	_panel.position = Vector2(maxf(0.0, _last_viewport_size.x - _panel.size.x - margin), 10.0 if compact else 16.0)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", font_size)
	return label
