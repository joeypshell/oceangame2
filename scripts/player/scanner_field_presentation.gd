extends Node2D

const DEFAULT_RANGE_PIXELS := 192.0
const HALF_ANGLE_DEGREES := 30.0
const MISS_PULSE_SECONDS := 0.42
const TARGET_HALF_SIZE := Vector2(18.0, 13.0)
const TARGET_CORNER_LENGTH := 7.0
const PROGRESS_SIZE := Vector2(40.0, 4.0)
const CARD_SIZE := Vector2(244.0, 76.0)
const CARD_MARGIN := 8.0
const CARD_TITLE_SIZE := 15
const CARD_TEXT_SIZE := 12
const FIELD_COLOR := Color(0.50, 0.95, 0.96, 0.72)
const FIELD_INNER_COLOR := Color(0.50, 0.95, 0.96, 0.30)
const TARGET_COLOR := Color(1.0, 0.88, 0.36, 0.96)
const PROGRESS_BACK_COLOR := Color(0.02, 0.08, 0.11, 0.78)
const CARD_BACK_COLOR := Color(0.02, 0.08, 0.11, 0.90)
const CARD_TEXT_COLOR := Color(0.86, 0.96, 0.98, 0.96)

var _scanner_unlocked := false
var _active := false
var _held := false
var _pulse_remaining := 0.0
var _facing_sign := 1.0
var _range_pixels := DEFAULT_RANGE_PIXELS
var _target_id := ""
var _target_local_position := Vector2.ZERO
var _target_mode := ""
var _target_kind := ""
var _target_label := ""
var _target_description := ""
var _requires_hold := false
var _progress := 0.0


func _ready() -> void:
	visible = false
	set_process(true)


func _process(delta: float) -> void:
	if _pulse_remaining <= 0.0:
		return
	_pulse_remaining = maxf(0.0, _pulse_remaining - maxf(0.0, delta))
	if _pulse_remaining <= 0.0 and not _active and not _held:
		_clear_target()
	_refresh_visibility()


func show_scanner_action(action_result: Dictionary, runtime_report: Dictionary, facing_sign: float) -> void:
	sync(runtime_report, facing_sign)
	if not _scanner_unlocked:
		return
	var reason := str(action_result.get("reason", ""))
	if reason in ["blueprint_required", "project_required", "scanner_required", "already_identified"]:
		return
	if not _active and not _held:
		_pulse_remaining = MISS_PULSE_SECONDS
	if not _active:
		_apply_targeting(runtime_report.get("targeting", {}))
	_refresh_visibility()


func sync(runtime_report: Dictionary, facing_sign: float) -> void:
	_facing_sign = 1.0 if facing_sign >= 0.0 else -1.0
	_scanner_unlocked = bool(runtime_report.get("scanner_unlocked", false))
	if not _scanner_unlocked:
		clear()
		return

	var interaction: Dictionary = runtime_report.get("interaction", {})
	var was_active := _active
	var was_held := _held
	_active = bool(interaction.get("activated", false))
	_held = bool(runtime_report.get("scanner_use_held", false))
	if _active or _held:
		_progress = clampf(float(interaction.get("progress", 0.0)), 0.0, 1.0)
		_apply_targeting(runtime_report.get("targeting", {}))
	elif was_active or was_held:
		_pulse_remaining = 0.0
		_clear_target()
	elif _pulse_remaining <= 0.0:
		_clear_target()
	_refresh_visibility()


func clear() -> void:
	_scanner_unlocked = false
	_active = false
	_held = false
	_pulse_remaining = 0.0
	_clear_target()
	_refresh_visibility()


func get_test_report() -> Dictionary:
	return {
		"visible": visible,
		"active": _active,
		"held": _held,
		"pulse_remaining": _pulse_remaining,
		"facing_sign": _facing_sign,
		"range_pixels": _range_pixels,
		"half_angle_degrees": HALF_ANGLE_DEGREES,
		"target_visible": visible and not _target_id.is_empty(),
		"target_id": _target_id,
		"target_local_position": _target_local_position,
		"target_mode": _target_mode,
		"target_kind": _target_kind,
		"target_label": _target_label,
		"target_description": _target_description,
		"requires_hold": _requires_hold,
		"card_visible": visible and not _target_id.is_empty(),
		"card_size": CARD_SIZE,
		"progress": _progress,
		"progress_size": PROGRESS_SIZE,
	}


func _draw() -> void:
	if not visible:
		return
	_draw_field()
	if not _target_id.is_empty():
		_draw_target_bracket()
		_draw_target_card()


func _draw_field() -> void:
	var center_angle := 0.0 if _facing_sign > 0.0 else PI
	var half_angle := deg_to_rad(HALF_ANGLE_DEGREES)
	var start_angle := center_angle - half_angle
	var end_angle := center_angle + half_angle
	var start_point := Vector2.from_angle(start_angle) * _range_pixels
	var end_point := Vector2.from_angle(end_angle) * _range_pixels
	draw_line(Vector2.ZERO, start_point, FIELD_COLOR, 2.0, true)
	draw_line(Vector2.ZERO, end_point, FIELD_COLOR, 2.0, true)
	draw_arc(Vector2.ZERO, _range_pixels, start_angle, end_angle, 18, FIELD_COLOR, 2.0, true)
	draw_arc(Vector2.ZERO, _range_pixels * 0.5, start_angle, end_angle, 12, FIELD_INNER_COLOR, 1.0, true)


func _draw_target_bracket() -> void:
	var center := _target_local_position
	var left := center.x - TARGET_HALF_SIZE.x
	var right := center.x + TARGET_HALF_SIZE.x
	var top := center.y - TARGET_HALF_SIZE.y
	var bottom := center.y + TARGET_HALF_SIZE.y
	_draw_corner(Vector2(left, top), Vector2.RIGHT, Vector2.DOWN)
	_draw_corner(Vector2(right, top), Vector2.LEFT, Vector2.DOWN)
	_draw_corner(Vector2(left, bottom), Vector2.RIGHT, Vector2.UP)
	_draw_corner(Vector2(right, bottom), Vector2.LEFT, Vector2.UP)
	draw_circle(center, 2.0, TARGET_COLOR)
	if _active:
		var progress_position := center + Vector2(-PROGRESS_SIZE.x * 0.5, TARGET_HALF_SIZE.y + 8.0)
		draw_rect(Rect2(progress_position, PROGRESS_SIZE), PROGRESS_BACK_COLOR, true)
		draw_rect(Rect2(progress_position, Vector2(PROGRESS_SIZE.x * _progress, PROGRESS_SIZE.y)), TARGET_COLOR, true)


func _draw_corner(origin: Vector2, horizontal: Vector2, vertical: Vector2) -> void:
	draw_line(origin, origin + horizontal * TARGET_CORNER_LENGTH, TARGET_COLOR, 2.0, true)
	draw_line(origin, origin + vertical * TARGET_CORNER_LENGTH, TARGET_COLOR, 2.0, true)


func _draw_target_card() -> void:
	var card_position := _target_local_position + Vector2(-CARD_SIZE.x * 0.5, -TARGET_HALF_SIZE.y - CARD_SIZE.y - 10.0)
	var card_rect := Rect2(card_position, CARD_SIZE)
	draw_rect(card_rect, CARD_BACK_COLOR, true)
	draw_rect(card_rect, TARGET_COLOR, false, 1.0)
	var font := ThemeDB.fallback_font
	var text_width := CARD_SIZE.x - CARD_MARGIN * 2.0
	var title_position := card_position + Vector2(CARD_MARGIN, 20.0)
	draw_string(font, title_position, _fit_text(_target_label, 34), HORIZONTAL_ALIGNMENT_LEFT, text_width, CARD_TITLE_SIZE, TARGET_COLOR)
	var detail := _target_kind.capitalize()
	if not _target_description.is_empty():
		detail += " | %s" % _target_description
	draw_string(font, title_position + Vector2(0.0, 20.0), _fit_text(detail, 40), HORIZONTAL_ALIGNMENT_LEFT, text_width, CARD_TEXT_SIZE, CARD_TEXT_COLOR)
	var instruction := "Hold Space/USE | %d%%" % int(floor(_progress * 100.0)) if _requires_hold else "Identified"
	draw_string(font, title_position + Vector2(0.0, 40.0), instruction, HORIZONTAL_ALIGNMENT_LEFT, text_width, CARD_TEXT_SIZE, CARD_TEXT_COLOR)


func _apply_targeting(targeting_value) -> void:
	if typeof(targeting_value) != TYPE_DICTIONARY:
		_clear_target()
		return
	var targeting: Dictionary = targeting_value
	var report_range := float(targeting.get("range_pixels", 0.0))
	if report_range > 0.0:
		_range_pixels = report_range
	if not bool(targeting.get("eligible", false)):
		_clear_target()
		return
	var target_id := str(targeting.get("target_id", ""))
	var subject_id := str(targeting.get("scan_subject_id", ""))
	var anchor = targeting.get("anchor", Vector2.ZERO)
	if target_id.is_empty() or subject_id.is_empty() or not anchor is Vector2:
		_clear_target()
		return
	_target_id = target_id
	_target_local_position = to_local(anchor)
	_target_mode = str(targeting.get("scanner_subject_mode", "progression"))
	_target_kind = str(targeting.get("scan_subject_kind", "subject"))
	_target_label = str(targeting.get("scan_subject_label", "Unknown subject"))
	_target_description = str(targeting.get("scan_subject_description", ""))
	_requires_hold = bool(targeting.get("requires_hold", _target_mode == "progression"))


func _clear_target() -> void:
	_target_id = ""
	_target_local_position = Vector2.ZERO
	_target_mode = ""
	_target_kind = ""
	_target_label = ""
	_target_description = ""
	_requires_hold = false
	_progress = 0.0


func _fit_text(value: String, max_characters: int) -> String:
	var text := value.strip_edges()
	if text.length() <= max_characters:
		return text
	return "%s..." % text.left(max_characters - 3)


func _refresh_visibility() -> void:
	visible = _scanner_unlocked and (_active or _held or _pulse_remaining > 0.0)
	queue_redraw()
