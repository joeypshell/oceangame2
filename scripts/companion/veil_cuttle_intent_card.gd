extends Control

const CARD_SIZE := Vector2(270.0, 92.0)
const DESKTOP_OFFSET := Vector2(24.0, -116.0)
const MOBILE_SAFE_RIGHT_RATIO := 0.65
const COLOR_BACKGROUND := Color("071c27")
const COLOR_BORDER := Color("72e6d1")
const COLOR_TEXT := Color("d9fff2")
const COLOR_WARNING := Color("ffd166")
const COLOR_LUNGE := Color("ff7a78")
const COLOR_RECOVERY := Color("99edba")

var _world_position := Vector2.ZERO
var _phase := ""
var _movement_direction := Vector2.ZERO
var _phase_seconds := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = CARD_SIZE
	visible = false
	set_process(true)


func _process(_delta: float) -> void:
	if visible:
		_layout_card()


func show_prediction(
	world_position: Vector2,
	phase: String,
	movement_direction: Vector2,
	phase_seconds: float
) -> void:
	_world_position = world_position
	_phase = phase
	_movement_direction = movement_direction.normalized()
	_phase_seconds = maxf(0.0, phase_seconds)
	visible = true
	_layout_card()
	queue_redraw()


func clear_prediction() -> void:
	visible = false
	_phase = ""
	_movement_direction = Vector2.ZERO
	_phase_seconds = 0.0
	queue_redraw()


func report() -> Dictionary:
	return {
		"visible": visible,
		"rect": Rect2(position, size) if visible else Rect2(),
		"heading_text": _heading_text() if visible else "",
		"primary_text": _primary_text() if visible else "",
		"response_text": _response_text() if visible else "",
	}


func _draw() -> void:
	if not visible:
		return
	var card := Rect2(Vector2.ZERO, size)
	draw_rect(card, Color(COLOR_BACKGROUND, 0.96), true)
	draw_rect(card, Color(COLOR_BORDER, 0.96), false, 2.0, true)
	var text_width := size.x - 24.0
	draw_string(
		ThemeDB.fallback_font,
		Vector2(12.0, 22.0),
		_heading_text(),
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		15,
		COLOR_BORDER
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(12.0, 54.0),
		_primary_text(),
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		19,
		_phase_color()
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(12.0, 79.0),
		_response_text(),
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		15,
		COLOR_TEXT
	)


func _layout_card() -> void:
	var viewport_size := get_viewport_rect().size
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * _world_position
	var desired := screen_position + DESKTOP_OFFSET
	if viewport_size.x < 900.0:
		var safe_right := viewport_size.x * MOBILE_SAFE_RIGHT_RATIO
		desired.x = minf(desired.x, safe_right - size.x)
	desired.x = clampf(desired.x, 8.0, maxf(8.0, viewport_size.x - size.x - 8.0))
	desired.y = clampf(desired.y, 8.0, maxf(8.0, viewport_size.y - size.y - 8.0))
	position = desired.round()


func _heading_text() -> String:
	return "MICA PREDICTION - NO DAMAGE"


func _primary_text() -> String:
	var direction := _direction_label(_movement_direction)
	match _phase:
		"warning":
			return "LUNGE %s IN %.1fs" % [direction, _phase_seconds]
		"lunge":
			return "LUNGING %s" % direction
		"recovery":
			return "SAFE OPENING %.1fs" % _phase_seconds
		"returning":
			return "EEL RETREATING"
	return "EEL PATROLLING"


func _response_text() -> String:
	match _phase:
		"warning":
			return "MOVE ASIDE"
		"lunge":
			return "EVADE NOW"
		"recovery":
			return "PASS OR RETREAT"
		"returning":
			return "YOU ARE CLEAR"
	return "ENTER RANGE TO BAIT LUNGE"


func _direction_label(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return "AHEAD"
	if absf(direction.x) >= absf(direction.y):
		return "EAST" if direction.x >= 0.0 else "WEST"
	return "SOUTH" if direction.y >= 0.0 else "NORTH"


func _phase_color() -> Color:
	match _phase:
		"warning":
			return COLOR_WARNING
		"lunge":
			return COLOR_LUNGE
		"recovery":
			return COLOR_RECOVERY
	return COLOR_BORDER
