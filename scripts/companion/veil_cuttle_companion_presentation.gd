extends Node2D

const STATE_INVESTIGATE := "investigate"
const STATE_SEPARATED := "separated"
const STATE_RECOVERY := "recovery"

const COLOR_MANTLE := Color("3f547e")
const COLOR_FIN := Color("7e79bd")
const COLOR_VEIL := Color("78d6d0")
const COLOR_EYE := Color("d9fff2")
const COLOR_TRACE := Color("a8f0c6")
const COLOR_MISS := Color("ffd166")
const COLOR_WORRIED := Color("ffd166")

var _state := "hover"
var _facing_sign := 1.0
var _path_points: Array = []
var _callsign := "Mica"
var _pulse_seconds := 0.0
var _trace_state := "idle"
var _trace_direction := Vector2.RIGHT
var _trace_range_px := 192.0
var _trace_target_distance := 192.0
var _trace_cue_seconds := 0.0


func sync(state: String, facing_sign: float, path_points: Array) -> void:
	_state = state
	_facing_sign = 1.0 if facing_sign >= 0.0 else -1.0
	_path_points = path_points.duplicate()
	queue_redraw()


func set_identity(callsign: String) -> void:
	_callsign = callsign.strip_edges() if not callsign.strip_edges().is_empty() else "Mica"
	queue_redraw()


func show_reveal_trace(
	direction: Vector2,
	range_px: float,
	target_distance: float,
	cue_state: String
) -> void:
	_trace_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT * _facing_sign
	_trace_range_px = maxf(1.0, range_px)
	_trace_target_distance = clampf(target_distance, 18.0, _trace_range_px)
	_trace_state = cue_state
	_trace_cue_seconds = 0.16 if cue_state == "aiming" else 1.15
	queue_redraw()


func clear_reveal_preview() -> void:
	if _trace_state == "aiming":
		_trace_state = "idle"
		_trace_cue_seconds = 0.0
		queue_redraw()


func advance(delta: float) -> void:
	var safe_delta := maxf(0.0, delta)
	_pulse_seconds = fmod(_pulse_seconds + safe_delta, 1.0)
	if _trace_cue_seconds > 0.0:
		_trace_cue_seconds = maxf(0.0, _trace_cue_seconds - safe_delta)
		if _trace_cue_seconds == 0.0:
			_trace_state = "idle"
	queue_redraw()


func report() -> Dictionary:
	return {
		"species_id": "veil_cuttle",
		"callsign": _callsign,
		"state": _state,
		"facing_sign": _facing_sign,
		"investigation_cue_visible": _state == STATE_INVESTIGATE,
		"recovery_path_visible": _state in [STATE_SEPARATED, STATE_RECOVERY] and not _path_points.is_empty(),
		"trace_state": _trace_state,
		"trace_direction": _trace_direction,
		"trace_range_px": _trace_range_px,
		"trace_target_distance": _trace_target_distance,
		"mounted": false,
	}


func _draw() -> void:
	_draw_recovery_path()
	_draw_cuttle()
	_draw_investigation_cue()
	_draw_trace_cue()
	_draw_separation_cue()


func _draw_cuttle() -> void:
	var direction := _facing_sign
	var hover := sin(_pulse_seconds * TAU) * 1.5
	var center := Vector2(0.0, hover)
	var mantle := PackedVector2Array([
		Vector2(20.0 * direction, 0.0),
		Vector2(11.0 * direction, -12.0),
		Vector2(-8.0 * direction, -13.0),
		Vector2(-19.0 * direction, -7.0),
		Vector2(-22.0 * direction, 0.0),
		Vector2(-18.0 * direction, 8.0),
		Vector2(-7.0 * direction, 13.0),
		Vector2(11.0 * direction, 11.0),
	])
	for index in range(mantle.size()):
		mantle[index] += center
	draw_colored_polygon(mantle, COLOR_MANTLE)
	var upper_fin := PackedVector2Array([
		Vector2(12.0 * direction, -8.0),
		Vector2(-4.0 * direction, -21.0),
		Vector2(-18.0 * direction, -10.0),
	])
	var lower_fin := PackedVector2Array([
		Vector2(12.0 * direction, 8.0),
		Vector2(-4.0 * direction, 21.0),
		Vector2(-18.0 * direction, 10.0),
	])
	for index in range(upper_fin.size()):
		upper_fin[index] += center
		lower_fin[index] += center
	draw_colored_polygon(upper_fin, Color(COLOR_FIN, 0.92))
	draw_colored_polygon(lower_fin, Color(COLOR_FIN, 0.92))
	for index in range(5):
		var root := center + Vector2(-18.0 * direction, -7.0 + float(index) * 3.5)
		var wave := sin(_pulse_seconds * TAU + float(index)) * 3.0
		var tip := root + Vector2((-20.0 - float(index % 2) * 5.0) * direction, wave + float(index - 2) * 2.0)
		draw_polyline(PackedVector2Array([root, root.lerp(tip, 0.55) + Vector2(0.0, wave), tip]), Color(COLOR_VEIL, 0.88), 2.0, true)
	for spot in [Vector2(3.0, -6.0), Vector2(-5.0, 2.0), Vector2(7.0, 6.0)]:
		draw_circle(center + Vector2(spot.x * direction, spot.y), 2.2, Color(COLOR_VEIL, 0.65))
	draw_circle(center + Vector2(13.0 * direction, -2.0), 3.4, COLOR_EYE)
	draw_circle(center + Vector2(14.0 * direction, -2.0), 1.4, Color("17364f"))
	draw_arc(center, 15.0, -0.7, 0.7, 12, Color(COLOR_VEIL, 0.8), 1.5, true)


func _draw_investigation_cue() -> void:
	if _state != STATE_INVESTIGATE:
		return
	var center := Vector2(24.0 * _facing_sign, -18.0)
	draw_arc(center, 6.0 + sin(_pulse_seconds * TAU), 0.0, TAU, 18, COLOR_TRACE, 1.5, true)
	draw_circle(center, 1.5, COLOR_TRACE)


func _draw_trace_cue() -> void:
	if _trace_state == "idle":
		return
	var color := COLOR_TRACE if _trace_state in ["aiming", "revealed", "already_revealed"] else COLOR_MISS
	var direction := _trace_direction.normalized()
	var side := direction.orthogonal()
	var range_endpoint := direction * _trace_range_px
	var target_endpoint := direction * _trace_target_distance
	var half_width := tan(deg_to_rad(22.0)) * _trace_range_px
	draw_line(Vector2.ZERO, range_endpoint + side * half_width, Color(color, 0.32), 1.5, true)
	draw_line(Vector2.ZERO, range_endpoint - side * half_width, Color(color, 0.32), 1.5, true)
	draw_arc(Vector2.ZERO, _trace_range_px, direction.angle() - deg_to_rad(22.0), direction.angle() + deg_to_rad(22.0), 28, Color(color, 0.48), 1.5, true)
	draw_line(direction * 18.0, target_endpoint, color, 2.0, true)
	if _trace_state == "revealed":
		draw_arc(target_endpoint, 10.0 + sin(_pulse_seconds * TAU) * 2.0, 0.0, TAU, 20, color, 2.5, true)
		for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
			draw_line(target_endpoint + Vector2.from_angle(angle) * 13.0, target_endpoint + Vector2.from_angle(angle) * 19.0, color, 2.0, true)
	elif _trace_state in ["miss", "denied", "cooldown"]:
		draw_line(target_endpoint + Vector2(-5.0, -5.0), target_endpoint + Vector2(5.0, 5.0), color, 2.0, true)
		draw_line(target_endpoint + Vector2(-5.0, 5.0), target_endpoint + Vector2(5.0, -5.0), color, 2.0, true)


func _draw_recovery_path() -> void:
	if _state not in [STATE_SEPARATED, STATE_RECOVERY] or _path_points.is_empty():
		return
	var color := Color(COLOR_WORRIED, 0.72) if _state == STATE_SEPARATED else Color(COLOR_TRACE, 0.72)
	var previous := Vector2.ZERO
	var drawn_length := 0.0
	for index in range(mini(_path_points.size(), 8)):
		var point := _path_points[index] as Vector2
		var segment_length := previous.distance_to(point)
		if drawn_length + segment_length > 360.0:
			point = previous + previous.direction_to(point) * (360.0 - drawn_length)
			segment_length = previous.distance_to(point)
		var dots := maxi(1, int(segment_length / 18.0))
		for dot_index in range(1, dots + 1):
			draw_circle(previous.lerp(point, float(dot_index) / float(dots)), 1.8, color)
		drawn_length += segment_length
		previous = point
		if drawn_length >= 360.0:
			break


func _draw_separation_cue() -> void:
	if _state != STATE_SEPARATED:
		return
	var center := Vector2(0.0, -32.0)
	var radius := 6.0 + sin(_pulse_seconds * TAU)
	draw_arc(center, radius, 0.0, TAU, 18, COLOR_WORRIED, 2.0, true)
	draw_line(center + Vector2(0.0, -3.0), center + Vector2(0.0, 1.0), COLOR_WORRIED, 1.5, true)
	draw_circle(center + Vector2(0.0, 4.0), 1.0, COLOR_WORRIED)
