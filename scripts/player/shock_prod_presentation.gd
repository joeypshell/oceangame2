extends Node2D

const EFFECT_SECONDS := 0.42
const DEFAULT_ARC_HALF_ANGLE_DEGREES := 35.0
const BOLT_COUNT := 3
const BOLT_SEGMENTS := 7
const BOLT_ORIGIN_OFFSET := 12.0
const RANGE_COLOR := Color(0.25, 0.93, 1.0, 0.72)
const RANGE_INNER_COLOR := Color(0.25, 0.93, 1.0, 0.30)
const BOLT_GLOW_COLOR := Color(0.12, 0.78, 1.0, 0.42)
const BOLT_COLOR := Color(0.82, 0.98, 1.0, 1.0)
const IMPACT_COLOR := Color(1.0, 0.83, 0.25, 1.0)
const MISS_COLOR := Color(1.0, 0.48, 0.20, 1.0)

var _remaining_seconds := 0.0
var _elapsed_seconds := 0.0
var _range_pixels := 0.0
var _arc_half_angle_degrees := DEFAULT_ARC_HALF_ANGLE_DEGREES
var _facing_sign := 1.0
var _endpoint_local := Vector2.ZERO
var _connected := false
var _reason := ""
var _target_id := ""
var _discharge_count := 0


func _ready() -> void:
	visible = false
	set_process(true)


func _process(delta: float) -> void:
	if _remaining_seconds <= 0.0:
		return
	var step := maxf(0.0, delta)
	_elapsed_seconds += step
	_remaining_seconds = maxf(0.0, _remaining_seconds - step)
	if _remaining_seconds <= 0.0:
		visible = false
	queue_redraw()


func show_discharge(action_result: Dictionary, facing_sign: float) -> bool:
	if not bool(action_result.get("discharged", false)):
		return false
	_range_pixels = maxf(1.0, float(action_result.get("attack_range_px", 0.0)))
	_arc_half_angle_degrees = clampf(
		float(action_result.get("attack_half_angle_degrees", DEFAULT_ARC_HALF_ANGLE_DEGREES)),
		1.0,
		90.0
	)
	_facing_sign = 1.0 if facing_sign >= 0.0 else -1.0
	_connected = bool(action_result.get("connected", false))
	_reason = str(action_result.get("reason", ""))
	_target_id = str(action_result.get("id", "")) if _connected else ""
	_endpoint_local = Vector2(_range_pixels * _facing_sign, 0.0)
	var target_position = action_result.get("target_position", null)
	if _connected and target_position is Vector2:
		_endpoint_local = to_local(target_position as Vector2)
		if _endpoint_local.length() > _range_pixels:
			_endpoint_local = _endpoint_local.normalized() * _range_pixels
	if _endpoint_local.length() < BOLT_ORIGIN_OFFSET + 2.0:
		_endpoint_local = Vector2(_range_pixels * _facing_sign, 0.0)
	_remaining_seconds = EFFECT_SECONDS
	_elapsed_seconds = 0.0
	_discharge_count += 1
	visible = true
	queue_redraw()
	return true


func clear() -> void:
	_remaining_seconds = 0.0
	_elapsed_seconds = 0.0
	_connected = false
	_reason = ""
	_target_id = ""
	visible = false
	queue_redraw()


func get_test_report() -> Dictionary:
	return {
		"visible": visible,
		"remaining_seconds": _remaining_seconds,
		"range_pixels": _range_pixels,
		"facing_sign": _facing_sign,
		"arc_half_angle_degrees": _arc_half_angle_degrees,
		"range_shape": "forward_cone",
		"miss_feedback": "directional_fizzle" if not _connected else "",
		"endpoint_local": _endpoint_local,
		"connected": _connected,
		"reason": _reason,
		"target_id": _target_id,
		"discharge_count": _discharge_count,
		"bolt_count": BOLT_COUNT,
		"bolt_segments": BOLT_SEGMENTS,
	}


func _draw() -> void:
	if not visible or _remaining_seconds <= 0.0:
		return
	var life := clampf(_remaining_seconds / EFFECT_SECONDS, 0.0, 1.0)
	var flash := clampf(sin((1.0 - life) * PI) * 1.35, 0.35, 1.0)
	_draw_range_flash(life * flash * (1.0 if _connected else 0.35))
	var origin := Vector2(BOLT_ORIGIN_OFFSET * _facing_sign, 0.0)
	var frame := int(floor(_elapsed_seconds * 48.0))
	for branch in range(BOLT_COUNT):
		var points := _bolt_points(origin, _endpoint_local, branch, frame)
		draw_polyline(points, _with_alpha(BOLT_GLOW_COLOR, life), 7.0, true)
		draw_polyline(points, _with_alpha(BOLT_COLOR, flash), 2.4 if branch == 1 else 1.5, true)
	_draw_impact(life, flash, frame)


func _draw_range_flash(alpha: float) -> void:
	var center_angle := 0.0 if _facing_sign > 0.0 else PI
	var half_angle := deg_to_rad(_arc_half_angle_degrees)
	var start_angle := center_angle - half_angle
	var end_angle := center_angle + half_angle
	var start_point := Vector2.from_angle(start_angle) * _range_pixels
	var end_point := Vector2.from_angle(end_angle) * _range_pixels
	draw_line(Vector2.ZERO, start_point, _with_alpha(RANGE_INNER_COLOR, alpha), 1.5, true)
	draw_line(Vector2.ZERO, end_point, _with_alpha(RANGE_INNER_COLOR, alpha), 1.5, true)
	draw_arc(Vector2.ZERO, _range_pixels, start_angle, end_angle, 24, _with_alpha(RANGE_COLOR, alpha), 3.0, true)


func _bolt_points(origin: Vector2, endpoint: Vector2, branch: int, frame: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var axis := endpoint - origin
	var normal := Vector2(-axis.y, axis.x).normalized()
	for index in range(BOLT_SEGMENTS + 1):
		var progress := float(index) / float(BOLT_SEGMENTS)
		var envelope := sin(PI * progress)
		var phase := float(index * 13 + branch * 19 + frame * 7) * 0.61
		var branch_offset := float(branch - 1) * 2.2
		var jitter := (sin(phase) * 5.5 + branch_offset) * envelope
		points.append(origin.lerp(endpoint, progress) + normal * jitter)
	return points


func _draw_impact(life: float, flash: float, frame: int) -> void:
	if _connected:
		var pulse_radius := 7.0 + (1.0 - life) * 12.0
		draw_arc(_endpoint_local, pulse_radius, 0.0, TAU, 20, _with_alpha(IMPACT_COLOR, life), 2.5, true)
		draw_circle(_endpoint_local, 3.5, _with_alpha(BOLT_COLOR, flash))
		return
	for index in range(3):
		var angle := float(frame + index * 2 - 2) * 0.45
		var direction := Vector2.from_angle(angle)
		draw_line(
			_endpoint_local - direction * 2.0,
			_endpoint_local + direction * (6.0 + float(index)),
			_with_alpha(MISS_COLOR, life),
			2.0,
			true
		)


func _with_alpha(color: Color, multiplier: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * clampf(multiplier, 0.0, 1.0))
