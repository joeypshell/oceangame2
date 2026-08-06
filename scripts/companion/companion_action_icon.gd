extends Control

const COLOR_ACTIVE := Color("8cf4ff")
const COLOR_INACTIVE := Color("5f7e88")

var _action_id := ""
var _selected := false
var _cooldown_ratio := 0.0


func sync(action_id: String, selected: bool, cooldown_ratio: float) -> void:
	_action_id = action_id
	_selected = selected
	_cooldown_ratio = clampf(cooldown_ratio, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var color := COLOR_ACTIVE if _selected else COLOR_INACTIVE
	var center := size * 0.5
	if _action_id == "glide_surge":
		_draw_glide(center, color)
	elif _action_id == "anchor_brace":
		_draw_anchor(center, color)
	elif _action_id == "guardian_pulse_action":
		_draw_guardian_pulse(center, color)
	else:
		draw_circle(center, minf(size.x, size.y) * 0.18, color)
	if _cooldown_ratio > 0.0:
		draw_arc(center, minf(size.x, size.y) * 0.35, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - _cooldown_ratio), 24, Color(1.0, 0.78, 0.28, 0.92), 3.0, true)


func _draw_glide(center: Vector2, color: Color) -> void:
	var scale_factor := minf(size.x, size.y) / 56.0
	var points := PackedVector2Array([
		center + Vector2(-16.0, -10.0) * scale_factor,
		center + Vector2(-2.0, 0.0) * scale_factor,
		center + Vector2(-16.0, 10.0) * scale_factor,
		center + Vector2(4.0, 0.0) * scale_factor,
		center + Vector2(16.0, 0.0) * scale_factor,
	])
	draw_polyline(points, color, 3.0, true)
	draw_line(center + Vector2(-20.0, -13.0) * scale_factor, center + Vector2(-9.0, -13.0) * scale_factor, Color(color, 0.58), 2.0, true)
	draw_line(center + Vector2(-20.0, 13.0) * scale_factor, center + Vector2(-9.0, 13.0) * scale_factor, Color(color, 0.58), 2.0, true)


func _draw_anchor(center: Vector2, color: Color) -> void:
	var scale_factor := minf(size.x, size.y) / 56.0
	draw_line(center + Vector2(0.0, -17.0) * scale_factor, center + Vector2(0.0, 13.0) * scale_factor, color, 3.0, true)
	draw_arc(center + Vector2(0.0, 9.0) * scale_factor, 10.0 * scale_factor, 0.0, PI, 18, color, 3.0, true)
	draw_line(center + Vector2(-15.0, -7.0) * scale_factor, center + Vector2(15.0, -7.0) * scale_factor, Color(color, 0.58), 2.0, true)


func _draw_guardian_pulse(center: Vector2, color: Color) -> void:
	var scale_factor := minf(size.x, size.y) / 56.0
	for radius in [7.0, 13.0, 19.0]:
		draw_arc(center, radius * scale_factor, -0.85, 0.85, 14, Color(color, 0.82), 2.0, true)
	draw_circle(center + Vector2(5.0, 0.0) * scale_factor, 3.0 * scale_factor, color)
