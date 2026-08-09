extends Node2D

const COLOR_PATH := Color("72e6d1")
const COLOR_DIRECTION := Color("d9fff2")
const COLOR_APPROACH := Color("ffd166")
const COLOR_HOSTILE_HOME := Color("8ce8db")
const COLOR_HOSTILE_WARNING := Color("ffd166")
const COLOR_HOSTILE_LUNGE := Color("ff7a78")
const COLOR_HOSTILE_RECOVERY := Color("99edba")

var _path_points := PackedVector2Array()
var _current_center := Vector2.ZERO
var _movement_direction := Vector2.ZERO
var _approaching := false
var _subject_kind := ""
var _phase := ""
var _territory_rect := Rect2()
var _projected_lunge_target := Vector2.ZERO
var _phase_seconds := 0.0
var _recovery_seconds := 0.0
var _visible := false


func show_projection(
	path_points: Array,
	current_center: Vector2,
	movement_direction: Vector2,
	approaching: bool,
	details: Dictionary = {}
) -> void:
	_path_points = PackedVector2Array()
	for point in path_points:
		_path_points.append(point as Vector2)
	_current_center = current_center
	_movement_direction = movement_direction.normalized()
	_approaching = approaching
	_subject_kind = str(details.get("subject_kind", "moving_hazard"))
	_phase = str(details.get("phase", ""))
	_territory_rect = details.get("territory_rect", Rect2())
	_projected_lunge_target = details.get("projected_lunge_target", current_center)
	_phase_seconds = float(details.get("phase_seconds", 0.0))
	_recovery_seconds = float(details.get("recovery_seconds", 0.0))
	_visible = _path_points.size() >= 2 or _subject_kind == "territorial_hostile"
	queue_redraw()


func clear_projection() -> void:
	_path_points = PackedVector2Array()
	_current_center = Vector2.ZERO
	_movement_direction = Vector2.ZERO
	_approaching = false
	_subject_kind = ""
	_phase = ""
	_territory_rect = Rect2()
	_projected_lunge_target = Vector2.ZERO
	_phase_seconds = 0.0
	_recovery_seconds = 0.0
	_visible = false
	queue_redraw()


func report() -> Dictionary:
	return {
		"visible": _visible,
		"path_point_count": _path_points.size(),
		"current_center": _current_center,
		"movement_direction": _movement_direction,
		"approaching": _approaching,
		"subject_kind": _subject_kind,
		"phase": _phase,
		"territory_rect": _territory_rect,
		"projected_lunge_target": _projected_lunge_target,
		"phase_seconds": _phase_seconds,
		"recovery_seconds": _recovery_seconds,
	}


func _draw() -> void:
	if not _visible:
		return
	if _path_points.size() >= 2:
		draw_polyline(_path_points, Color(COLOR_PATH, 0.24), 8.0, true)
		draw_polyline(_path_points, Color(COLOR_PATH, 0.88), 2.5, true)
		_draw_path_ticks()
	if _subject_kind == "territorial_hostile":
		_draw_hostile_intent()
	var subject_color := COLOR_APPROACH if _approaching else COLOR_DIRECTION
	if _subject_kind == "territorial_hostile":
		subject_color = _phase_color()
	draw_arc(_current_center, 15.0, 0.0, TAU, 24, subject_color, 2.5, true)
	if _movement_direction != Vector2.ZERO:
		var tip := _current_center + _movement_direction * 30.0
		var side := _movement_direction.orthogonal()
		draw_line(_current_center, tip, subject_color, 3.0, true)
		draw_colored_polygon(PackedVector2Array([
			tip,
			tip - _movement_direction * 10.0 + side * 6.0,
			tip - _movement_direction * 10.0 - side * 6.0,
		]), subject_color)
	if _approaching:
		draw_arc(_current_center, 23.0, 0.0, TAU, 28, Color(COLOR_APPROACH, 0.62), 2.0, true)


func _draw_hostile_intent() -> void:
	var color := _phase_color()
	if _territory_rect.size != Vector2.ZERO:
		draw_rect(_territory_rect, Color(color, 0.12), true)
		draw_rect(_territory_rect, Color(color, 0.78), false, 2.5, true)
	if _projected_lunge_target.distance_to(_current_center) > 0.01:
		draw_line(_current_center, _projected_lunge_target, Color(color, 0.86), 2.5, true)
		draw_arc(_projected_lunge_target, 10.0, 0.0, TAU, 20, color, 2.0, true)
		draw_line(_projected_lunge_target - Vector2(6.0, 0.0), _projected_lunge_target + Vector2(6.0, 0.0), color, 1.5, true)
		draw_line(_projected_lunge_target - Vector2(0.0, 6.0), _projected_lunge_target + Vector2(0.0, 6.0), color, 1.5, true)
	var label_origin := _current_center + Vector2(-54.0, -28.0)
	var phase_detail := _phase.to_upper()
	if _phase_seconds > 0.0:
		phase_detail += " %.1fs" % _phase_seconds
	draw_string(ThemeDB.fallback_font, label_origin, phase_detail, HORIZONTAL_ALIGNMENT_LEFT, 132.0, 14, color)
	draw_string(
		ThemeDB.fallback_font,
		label_origin + Vector2(0.0, 17.0),
		"OPENING %.1fs" % _recovery_seconds,
		HORIZONTAL_ALIGNMENT_LEFT,
		132.0,
		12,
		Color(COLOR_DIRECTION, 0.92)
	)


func _phase_color() -> Color:
	match _phase:
		"warning":
			return COLOR_HOSTILE_WARNING
		"lunge":
			return COLOR_HOSTILE_LUNGE
		"recovery":
			return COLOR_HOSTILE_RECOVERY
	return COLOR_HOSTILE_HOME


func _draw_path_ticks() -> void:
	for index in range(_path_points.size() - 1):
		var start := _path_points[index]
		var finish := _path_points[index + 1]
		var length := start.distance_to(finish)
		var direction := start.direction_to(finish)
		var side := direction.orthogonal()
		for tick in range(1, maxi(2, int(length / 48.0))):
			var center := start.lerp(finish, float(tick) / float(maxi(2, int(length / 48.0))))
			draw_line(center - side * 4.0, center + side * 4.0, Color(COLOR_DIRECTION, 0.72), 1.5, true)
