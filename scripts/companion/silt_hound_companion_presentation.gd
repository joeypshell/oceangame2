extends Node2D

const STATE_FLOOR_ATTENTION := "floor_attention"
const STATE_CATCH_UP := "catch_up"
const STATE_SEPARATED := "separated"
const STATE_RECOVERY := "recovery"

const COLOR_BODY := Color("5f5b43")
const COLOR_BODY_LIGHT := Color("98a879")
const COLOR_FIN := Color("c4a85a")
const COLOR_BELLY := Color("b9c59e")
const COLOR_WHISKER := Color("b8eff0")
const COLOR_EYE := Color("f7e27f")
const COLOR_SILT := Color("c5a875")
const COLOR_WORRIED := Color("ffd166")
const COLOR_RESCUE := Color("9de2a4")
const COLOR_DANGER := Color("ff6b6b")

var _state := STATE_FLOOR_ATTENTION
var _facing_sign := 1.0
var _path_points: Array = []
var _callsign := "Marl"
var _pulse_seconds := 0.0
var _floor_distance := 48.0
var _movement_speed := 0.0
var _context_kind := ""
var _context_direction := Vector2.RIGHT
var _context_seconds := 0.0


func sync(state: String, facing_sign: float, path_points: Array, floor_distance: float, movement_speed: float) -> void:
	_state = state
	_facing_sign = 1.0 if facing_sign >= 0.0 else -1.0
	_path_points = path_points.duplicate()
	_floor_distance = clampf(floor_distance, 8.0, 48.0)
	_movement_speed = maxf(0.0, movement_speed)
	queue_redraw()


func set_identity(callsign: String) -> void:
	_callsign = callsign.strip_edges() if not callsign.strip_edges().is_empty() else "Marl"
	queue_redraw()


func show_context_response(context_kind: String, direction: Vector2, duration := 1.0) -> bool:
	if context_kind not in ["rescue_memory", "danger"]:
		return false
	_context_kind = context_kind
	_context_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	_context_seconds = maxf(0.1, duration)
	queue_redraw()
	return true


func advance(delta: float) -> void:
	_pulse_seconds = fmod(_pulse_seconds + maxf(0.0, delta), 1.0)
	if _context_seconds > 0.0:
		_context_seconds = maxf(0.0, _context_seconds - maxf(0.0, delta))
		if _context_seconds == 0.0:
			_context_kind = ""
	queue_redraw()


func report() -> Dictionary:
	return {
		"species_id": "silt_hound",
		"callsign": _callsign,
		"state": _state,
		"facing_sign": _facing_sign,
		"six_fin_count": 6,
		"ground_swim_visible": _movement_speed > 8.0,
		"floor_attention_visible": _state == STATE_FLOOR_ATTENTION,
		"floor_probe_distance": _floor_distance,
		"recovery_path_visible": _state in [STATE_SEPARATED, STATE_RECOVERY] and not _path_points.is_empty(),
		"context_kind": _context_kind,
		"context_seconds": _context_seconds,
		"mounted": false,
	}


func _draw() -> void:
	_draw_recovery_path()
	_draw_silt_wake()
	_draw_hound()
	_draw_floor_attention()
	_draw_separation_cue()
	_draw_context_cue()


func _draw_hound() -> void:
	var direction := _facing_sign
	var gait := _pulse_seconds * TAU * (1.0 + minf(2.0, _movement_speed / 90.0))
	var body_y := sin(gait) * (0.7 if _movement_speed > 8.0 else 1.3)
	var body := PackedVector2Array([
		Vector2(24.0 * direction, -3.0 + body_y),
		Vector2(16.0 * direction, -11.0 + body_y),
		Vector2(-12.0 * direction, -12.0 + body_y),
		Vector2(-27.0 * direction, -5.0 + body_y),
		Vector2(-28.0 * direction, 5.0 + body_y),
		Vector2(-11.0 * direction, 12.0 + body_y),
		Vector2(16.0 * direction, 10.0 + body_y),
	])
	draw_colored_polygon(body, COLOR_BODY)
	draw_colored_polygon(PackedVector2Array([
		Vector2(23.0 * direction, -2.0 + body_y),
		Vector2(35.0 * direction, 1.0 + body_y),
		Vector2(24.0 * direction, 9.0 + body_y),
		Vector2(13.0 * direction, 8.0 + body_y),
	]), COLOR_BODY_LIGHT)
	for index in range(3):
		var root_x := (10.0 - float(index) * 13.0) * direction
		var kick := sin(gait + float(index) * 1.8) * 4.0
		var upper := PackedVector2Array([
			Vector2(root_x, -8.0 + body_y),
			Vector2((root_x - 7.0 * direction), -19.0 - kick + body_y),
			Vector2((root_x - 13.0 * direction), -9.0 + body_y),
		])
		var lower := PackedVector2Array([
			Vector2(root_x, 8.0 + body_y),
			Vector2((root_x - 7.0 * direction), 19.0 + kick + body_y),
			Vector2((root_x - 13.0 * direction), 9.0 + body_y),
		])
		draw_colored_polygon(upper, Color(COLOR_FIN, 0.9))
		draw_colored_polygon(lower, COLOR_FIN)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-25.0 * direction, -3.0 + body_y),
		Vector2(-43.0 * direction, -10.0 + body_y),
		Vector2(-37.0 * direction, 1.0 + body_y),
		Vector2(-45.0 * direction, 10.0 + body_y),
		Vector2(-24.0 * direction, 5.0 + body_y),
	]), COLOR_BODY_LIGHT)
	draw_arc(Vector2(-1.0 * direction, body_y + 2.0), 16.0, 0.2, 2.6, 18, Color(COLOR_BELLY, 0.7), 2.0, true)
	draw_circle(Vector2(25.0 * direction, -3.0 + body_y), 3.2, COLOR_EYE)
	draw_circle(Vector2(26.0 * direction, -3.0 + body_y), 1.4, Color("25343a"))
	_draw_whiskers(direction, body_y)


func _draw_whiskers(direction: float, body_y: float) -> void:
	var nose := Vector2(34.0 * direction, 4.0 + body_y)
	var reach := minf(25.0, _floor_distance * 0.62)
	for index in range(3):
		var side_offset := float(index - 1) * 4.0
		var tip := nose + Vector2((11.0 + absf(side_offset)) * direction, reach + side_offset)
		var bend := nose.lerp(tip, 0.52) + Vector2(4.0 * direction, 2.0)
		draw_polyline(PackedVector2Array([nose, bend, tip]), Color(COLOR_WHISKER, 0.86), 1.5, true)


func _draw_floor_attention() -> void:
	if _state != STATE_FLOOR_ATTENTION:
		return
	var pulse := 4.0 + sin(_pulse_seconds * TAU) * 1.5
	var center := Vector2(24.0 * _facing_sign, minf(34.0, _floor_distance))
	draw_arc(center, pulse, 0.0, TAU, 18, Color(COLOR_WHISKER, 0.72), 1.5, true)
	draw_line(center + Vector2(-7.0, 0.0), center + Vector2(7.0, 0.0), Color(COLOR_SILT, 0.58), 2.0, true)


func _draw_silt_wake() -> void:
	if _movement_speed <= 8.0:
		return
	var direction := _facing_sign
	for index in range(4):
		var offset := Vector2((-27.0 - float(index) * 9.0) * direction, 13.0 + sin(_pulse_seconds * TAU + float(index)) * 2.0)
		draw_circle(offset, 2.2 - float(index) * 0.25, Color(COLOR_SILT, 0.45 - float(index) * 0.07))


func _draw_recovery_path() -> void:
	if _state not in [STATE_SEPARATED, STATE_RECOVERY] or _path_points.is_empty():
		return
	var color := Color(COLOR_WORRIED, 0.72) if _state == STATE_SEPARATED else Color(COLOR_WHISKER, 0.72)
	var previous := Vector2.ZERO
	var drawn_length := 0.0
	for index in range(mini(_path_points.size(), 8)):
		var point := _path_points[index] as Vector2
		var segment_length := previous.distance_to(point)
		if drawn_length + segment_length > 380.0:
			point = previous + previous.direction_to(point) * (380.0 - drawn_length)
			segment_length = previous.distance_to(point)
		var dots := maxi(1, int(segment_length / 18.0))
		for dot_index in range(1, dots + 1):
			draw_circle(previous.lerp(point, float(dot_index) / float(dots)), 1.8, color)
		drawn_length += segment_length
		previous = point
		if drawn_length >= 380.0:
			break


func _draw_separation_cue() -> void:
	if _state != STATE_SEPARATED:
		return
	var center := Vector2(0.0, -32.0)
	var radius := 6.0 + sin(_pulse_seconds * TAU)
	draw_arc(center, radius, 0.0, TAU, 18, COLOR_WORRIED, 2.0, true)
	draw_line(center + Vector2(0.0, -3.0), center + Vector2(0.0, 1.0), COLOR_WORRIED, 1.5, true)
	draw_circle(center + Vector2(0.0, 4.0), 1.0, COLOR_WORRIED)


func _draw_context_cue() -> void:
	if _context_kind.is_empty() or _context_seconds <= 0.0:
		return
	var color := COLOR_DANGER if _context_kind == "danger" else COLOR_RESCUE
	var center := _context_direction * 31.0
	draw_arc(center, 8.0 + sin(_pulse_seconds * TAU) * 1.5, 0.0, TAU, 20, color, 2.0, true)
	if _context_kind == "rescue_memory":
		for index in range(3):
			var offset := Vector2(float(index - 1) * 8.0, -7.0 + float(index % 2) * 4.0)
			draw_line(center + offset, center + offset + Vector2(5.0, 5.0), color, 2.0, true)
	else:
		draw_line(center + Vector2(-4.0, -4.0), center + Vector2(4.0, 4.0), color, 2.0, true)
		draw_line(center + Vector2(-4.0, 4.0), center + Vector2(4.0, -4.0), color, 2.0, true)
