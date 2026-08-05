extends Node2D

const STATE_NEAR := "near"
const STATE_FOLLOW := "follow"
const STATE_CATCH_UP := "catch_up"
const STATE_SEPARATED := "separated"
const STATE_RECOVERY := "recovery"
const STATE_EXTERNAL_CONTROL := "external_control"

const COLOR_BODY := Color("1f6174")
const COLOR_BODY_LIGHT := Color("42c7d8")
const COLOR_ELECTRIC := Color("8cf4ff")
const COLOR_WORRIED := Color("ffd166")
const COLOR_DANGER := Color("ff6b6b")
const COLOR_MEMORY := Color("b9f77c")
const COLOR_ANCHOR := Color("7de2ad")
const COLOR_ANCHOR_CANCEL := Color("ffd166")

var _state := STATE_NEAR
var _facing_sign := 1.0
var _path_points: Array = []
var _context_kind := ""
var _context_direction := Vector2.RIGHT
var _context_seconds := 0.0
var _pulse_seconds := 0.0
var _mounted := false
var _glide_direction := Vector2.RIGHT
var _glide_seconds := 0.0
var _glide_duration := 0.0
var _adaptation_id := ""
var _variant_label := "Spark Ray"
var _anchor_state := "idle"
var _anchor_direction := Vector2.UP
var _anchor_progress := 0.0
var _anchor_cue_seconds := 0.0


func sync(state: String, facing_sign: float, path_points: Array) -> void:
	_state = state
	_facing_sign = 1.0 if facing_sign >= 0.0 else -1.0
	_path_points = path_points.duplicate()
	queue_redraw()


func set_adaptation(adaptation_id: String, callsign: String) -> void:
	_adaptation_id = adaptation_id
	_variant_label = "%s | Anchor Fins" % callsign if adaptation_id == "anchor_fins" else callsign
	queue_redraw()


func show_context_response(context_kind: String, direction: Vector2, duration := 0.9) -> bool:
	if context_kind not in ["rescue_memory", "danger"]:
		return false
	_context_kind = context_kind
	_context_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	_context_seconds = maxf(0.1, duration)
	queue_redraw()
	return true


func set_mounted(active: bool) -> void:
	_mounted = active
	queue_redraw()


func show_glide_surge(direction: Vector2, duration: float) -> void:
	_glide_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT * _facing_sign
	_glide_duration = maxf(0.1, duration)
	_glide_seconds = _glide_duration
	queue_redraw()


func show_anchor_brace(direction: Vector2, progress: float, cue_state: String) -> void:
	_anchor_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	_anchor_progress = clampf(progress, 0.0, 1.0)
	_anchor_state = cue_state
	_anchor_cue_seconds = 0.0 if cue_state == "engaged" else 1.0
	queue_redraw()


func advance(delta: float) -> void:
	var safe_delta := maxf(0.0, delta)
	_pulse_seconds = fmod(_pulse_seconds + safe_delta, 1.0)
	if _context_seconds > 0.0:
		_context_seconds = maxf(0.0, _context_seconds - safe_delta)
		if _context_seconds == 0.0:
			_context_kind = ""
	_glide_seconds = maxf(0.0, _glide_seconds - safe_delta)
	if _anchor_state != "engaged" and _anchor_cue_seconds > 0.0:
		_anchor_cue_seconds = maxf(0.0, _anchor_cue_seconds - safe_delta)
		if _anchor_cue_seconds == 0.0:
			_anchor_state = "idle"
	queue_redraw()


func report() -> Dictionary:
	return {
		"state": _state,
		"facing_sign": _facing_sign,
		"recovery_path_visible": _state in [STATE_SEPARATED, STATE_RECOVERY] and not _path_points.is_empty(),
		"context_kind": _context_kind,
		"context_seconds": _context_seconds,
		"mounted": _mounted,
		"glide_visible": _glide_seconds > 0.0,
		"glide_direction": _glide_direction,
		"adaptation_id": _adaptation_id,
		"variant_label": _variant_label,
		"anchor_state": _anchor_state,
		"anchor_progress": _anchor_progress,
		"anchor_direction": _anchor_direction,
		"stable_posture": _anchor_state == "engaged",
	}


func _draw() -> void:
	_draw_recovery_path()
	_draw_wake()
	_draw_ray()
	_draw_rider()
	_draw_glide_surge()
	_draw_anchor_brace()
	_draw_state_cue()
	_draw_context_cue()


func _draw_ray() -> void:
	var direction := _facing_sign
	var offset := Vector2(0.0, 4.0) if _anchor_state == "engaged" else Vector2.ZERO
	var body := PackedVector2Array([
		Vector2(22.0 * direction, 0.0) + offset,
		Vector2(7.0 * direction, -7.0) + offset,
		Vector2(-12.0 * direction, -5.0) + offset,
		Vector2(-19.0 * direction, 0.0) + offset,
		Vector2(-12.0 * direction, 5.0) + offset,
		Vector2(7.0 * direction, 7.0) + offset,
	])
	var fin_depth := 25.0 if _adaptation_id == "anchor_fins" else 19.0
	var fin_reach := -17.0 if _adaptation_id == "anchor_fins" else -14.0
	var upper_fin := PackedVector2Array([
		Vector2(6.0 * direction, -4.0) + offset,
		Vector2(-8.0 * direction, -fin_depth) + offset,
		Vector2(fin_reach * direction, -7.0) + offset,
		Vector2(fin_reach * direction, -3.0) + offset,
	])
	var lower_fin := PackedVector2Array([
		Vector2(6.0 * direction, 4.0) + offset,
		Vector2(-8.0 * direction, fin_depth) + offset,
		Vector2(fin_reach * direction, 7.0) + offset,
		Vector2(fin_reach * direction, 3.0) + offset,
	])
	var fin_color := COLOR_ANCHOR if _adaptation_id == "anchor_fins" else COLOR_BODY_LIGHT
	draw_colored_polygon(upper_fin, fin_color)
	draw_colored_polygon(lower_fin, fin_color)
	draw_colored_polygon(body, COLOR_BODY)
	draw_polyline(PackedVector2Array([
		Vector2(-17.0 * direction, 0.0) + offset,
		Vector2(-28.0 * direction, 3.0) + offset,
		Vector2(-37.0 * direction, -2.0) + offset,
	]), COLOR_BODY_LIGHT, 3.0, true)
	draw_circle(Vector2(12.0 * direction, -1.5) + offset, 2.2, COLOR_ELECTRIC)
	draw_arc(offset, 11.0, -0.7, 0.7, 12, COLOR_ELECTRIC, 1.5, true)


func _draw_wake() -> void:
	if _state not in [STATE_CATCH_UP, STATE_RECOVERY]:
		return
	var direction := _facing_sign
	var color := Color(COLOR_ELECTRIC, 0.55 if _state == STATE_CATCH_UP else 0.8)
	for index in range(3):
		var x := (-31.0 - float(index) * 10.0) * direction
		draw_line(Vector2(x, -5.0), Vector2(x - 6.0 * direction, -5.0), color, 1.5, true)
		draw_line(Vector2(x, 5.0), Vector2(x - 6.0 * direction, 5.0), color, 1.5, true)


func _draw_rider() -> void:
	if not _mounted:
		return
	var direction := _facing_sign
	draw_circle(Vector2(-1.0 * direction, -12.0), 5.0, Color("f6c453"))
	draw_circle(Vector2(0.5 * direction, -12.0), 3.2, Color("72d9e8"))
	draw_line(Vector2(-6.0 * direction, -7.0), Vector2(7.0 * direction, -5.0), Color("df8d2f"), 4.0, true)


func _draw_glide_surge() -> void:
	if _glide_seconds <= 0.0:
		return
	var progress := 1.0 - (_glide_seconds / maxf(0.01, _glide_duration))
	var direction := _glide_direction.normalized()
	var side := direction.orthogonal()
	var tail := -direction * (34.0 + progress * 22.0)
	var color := Color(COLOR_ELECTRIC, 0.82 * (1.0 - progress))
	draw_line(tail + side * 10.0, -direction * 20.0 + side * 5.0, color, 3.0, true)
	draw_line(tail - side * 10.0, -direction * 20.0 - side * 5.0, color, 3.0, true)
	draw_arc(Vector2.ZERO, 25.0 + progress * 8.0, -0.8 + direction.angle(), 0.8 + direction.angle(), 16, color, 2.0, true)


func _draw_anchor_brace() -> void:
	if _anchor_state == "idle" or _adaptation_id != "anchor_fins":
		return
	var color := COLOR_ANCHOR
	if _anchor_state == "cancelled" or _anchor_state == "cooldown":
		color = COLOR_ANCHOR_CANCEL
	elif _anchor_state == "denied":
		color = COLOR_DANGER
	var flow_side := _anchor_direction.orthogonal()
	for index in range(3):
		var along := -_anchor_direction * (30.0 + float(index) * 10.0)
		draw_line(along - flow_side * 14.0, along + flow_side * 14.0, Color(color, 0.7), 2.0, true)
	var brace_direction := -_anchor_direction
	draw_line(brace_direction * 13.0, brace_direction * 34.0, color, 3.0, true)
	draw_line(brace_direction * 34.0, brace_direction * 27.0 + flow_side * 5.0, color, 2.0, true)
	draw_line(brace_direction * 34.0, brace_direction * 27.0 - flow_side * 5.0, color, 2.0, true)
	draw_arc(Vector2.ZERO, 31.0, -PI * 0.5, -PI * 0.5 + TAU * _anchor_progress, 28, color, 3.0, true)
	if _anchor_state == "success":
		draw_circle(Vector2.ZERO, 5.0 + sin(_pulse_seconds * TAU), Color(color, 0.55))


func _draw_recovery_path() -> void:
	if _state not in [STATE_SEPARATED, STATE_RECOVERY] or _path_points.is_empty():
		return
	var color := Color(COLOR_WORRIED, 0.72) if _state == STATE_SEPARATED else Color(COLOR_ELECTRIC, 0.72)
	var previous := Vector2.ZERO
	var drawn_length := 0.0
	var point_limit := mini(_path_points.size(), 8)
	for index in range(point_limit):
		var point := _path_points[index] as Vector2
		var segment_length := previous.distance_to(point)
		var remaining := 420.0 - drawn_length
		if remaining <= 0.0:
			break
		var draw_point := point
		if segment_length > remaining:
			draw_point = previous + previous.direction_to(point) * remaining
			segment_length = remaining
		var dots := maxi(1, int(segment_length / 18.0))
		for dot_index in range(1, dots + 1):
			var dot := previous.lerp(draw_point, float(dot_index) / float(dots))
			draw_circle(dot, 1.8, color)
		drawn_length += segment_length
		previous = draw_point


func _draw_state_cue() -> void:
	if _state != STATE_SEPARATED:
		return
	var pulse := 1.0 + 0.12 * sin(_pulse_seconds * TAU)
	var center := Vector2(0.0, -31.0)
	var radius := 6.0 * pulse
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
		center + Vector2(0.0, -radius),
	])
	draw_polyline(diamond, COLOR_WORRIED, 2.0, true)
	draw_line(center + Vector2(0.0, -2.5), center + Vector2(0.0, 1.0), COLOR_WORRIED, 1.5, true)
	draw_circle(center + Vector2(0.0, 3.5), 1.0, COLOR_WORRIED)


func _draw_context_cue() -> void:
	if _context_kind.is_empty() or _context_seconds <= 0.0:
		return
	var color := COLOR_DANGER if _context_kind == "danger" else COLOR_MEMORY
	var center := _context_direction * 28.0
	var radius := 7.0 + 1.5 * sin(_pulse_seconds * TAU)
	draw_arc(center, radius, 0.0, TAU, 20, color, 2.0, true)
	if _context_kind == "danger":
		draw_line(center + Vector2(-3.0, 0.0), center + Vector2(3.0, 0.0), color, 2.0, true)
	else:
		draw_line(center + Vector2(-4.0, 0.0), center + Vector2(4.0, 0.0), color, 1.5, true)
		draw_line(center + Vector2(0.0, -4.0), center + Vector2(0.0, 4.0), color, 1.5, true)
