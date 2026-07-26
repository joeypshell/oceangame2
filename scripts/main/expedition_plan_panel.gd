extends PanelContainer

const PHASE_DEBRIEF := "debrief"
const REQUIRED_CHOICE_COUNT := 2
const PANEL_POSITION := Vector2(288, 12)
const PANEL_WIDTH := 532.0
const CONTENT_WIDTH := 500.0

var _built := false
var _was_active := false
var _lead_ids: Array[String] = []
var _highlighted_index := 0
var _selected_lead_id := ""
var _choice_labels: Array[Label] = []
var _instruction_label: Label


func _ready() -> void:
	_ensure_built()


func refresh(resolution: Dictionary, selection: Dictionary, day_phase: String) -> Dictionary:
	_ensure_built()
	var leads := _eligible_leads(resolution)
	var active := (
		day_phase == PHASE_DEBRIEF
		and str(resolution.get("status", "")) == "choice_ready"
		and leads.size() == REQUIRED_CHOICE_COUNT
	)
	visible = active
	if not active:
		_was_active = false
		return get_test_report()

	var next_ids: Array[String] = []
	for lead in leads:
		next_ids.append(str(lead.get("lead_id", "")))
	var selected_id := str(selection.get("selected_lead_id", ""))
	var opening := not _was_active or next_ids != _lead_ids
	_lead_ids = next_ids
	_selected_lead_id = selected_id if next_ids.has(selected_id) else ""
	if opening:
		_highlighted_index = _lead_ids.find(_selected_lead_id)
		if _highlighted_index < 0:
			_highlighted_index = 0
	_highlighted_index = clampi(_highlighted_index, 0, REQUIRED_CHOICE_COUNT - 1)
	_was_active = true
	_render(leads)
	return get_test_report()


func cycle_highlight(
	resolution: Dictionary,
	selection: Dictionary,
	day_phase: String
) -> Dictionary:
	refresh(resolution, selection, day_phase)
	if not visible:
		return {
			"changed": false,
			"reason": "planner_inactive",
			"highlighted_lead_id": "",
		}
	_highlighted_index = (_highlighted_index + 1) % REQUIRED_CHOICE_COUNT
	_render(_eligible_leads(resolution))
	return {
		"changed": true,
		"reason": "highlight_changed",
		"highlighted_lead_id": highlighted_lead_id(),
	}


func highlighted_lead_id() -> String:
	if _highlighted_index < 0 or _highlighted_index >= _lead_ids.size():
		return ""
	return _lead_ids[_highlighted_index]


func get_test_report() -> Dictionary:
	var row_texts: Array[String] = []
	for label in _choice_labels:
		row_texts.append(label.text)
	return {
		"visible": visible,
		"lead_ids": _lead_ids.duplicate(),
		"highlighted_lead_id": highlighted_lead_id(),
		"selected_lead_id": _selected_lead_id,
		"row_texts": row_texts,
		"instruction_text": _instruction_label.text if _instruction_label != null else "",
		"rect": Rect2(position, size),
	}


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	name = "ExpeditionPlanPanel"
	position = PANEL_POSITION
	custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.08, 0.11, 0.92)
	style.border_color = Color(0.34, 0.78, 0.92, 0.56)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	margin.add_child(stack)

	var title := Label.new()
	title.text = "Plan next expedition"
	title.add_theme_color_override("font_color", Color(0.88, 0.97, 1.0, 1.0))
	title.add_theme_font_size_override("font_size", 16)
	stack.add_child(title)

	for index in range(REQUIRED_CHOICE_COUNT):
		if index > 0:
			stack.add_child(HSeparator.new())
		var choice := Label.new()
		choice.name = "PlanChoice%d" % (index + 1)
		choice.custom_minimum_size = Vector2(CONTENT_WIDTH, 68)
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		choice.add_theme_font_size_override("font_size", 14)
		stack.add_child(choice)
		_choice_labels.append(choice)

	_instruction_label = Label.new()
	_instruction_label.custom_minimum_size = Vector2(CONTENT_WIDTH, 36)
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instruction_label.add_theme_color_override(
		"font_color",
		Color(0.76, 0.90, 0.96, 0.92)
	)
	_instruction_label.add_theme_font_size_override("font_size", 12)
	stack.add_child(_instruction_label)


func _render(leads: Array[Dictionary]) -> void:
	for index in range(REQUIRED_CHOICE_COUNT):
		var lead: Dictionary = leads[index]
		var highlighted := index == _highlighted_index
		var pinned := str(lead.get("lead_id", "")) == _selected_lead_id
		var marker := ">" if highlighted else " "
		var pin_text := " [PINNED]" if pinned else ""
		_choice_labels[index].text = "%s%s %s\n%s\n%s" % [
			marker,
			pin_text,
			str(lead.get("label", "")),
			str(lead.get("summary", "")),
			str(lead.get("readiness_label", "")),
		]
		var color := Color(0.86, 0.94, 0.98, 0.94)
		if highlighted:
			color = Color(0.48, 0.92, 1.0, 1.0)
		if pinned:
			color = Color(1.0, 0.86, 0.38, 1.0)
		_choice_labels[index].add_theme_color_override("font_color", color)

	if _selected_lead_id.is_empty():
		_instruction_label.text = (
			"Tab/TOOL Highlight | E/ACT Pin | P/BUILD Project\n"
			+ "N/DAY requires a pinned plan"
		)
	else:
		_instruction_label.text = (
			"Tab/TOOL Highlight | E/ACT Pin | P/BUILD Project | N/DAY Start"
		)


func _eligible_leads(resolution: Dictionary) -> Array[Dictionary]:
	var leads: Array[Dictionary] = []
	for value in resolution.get("eligible_leads", []):
		if typeof(value) == TYPE_DICTIONARY:
			leads.append((value as Dictionary).duplicate(true))
	return leads
