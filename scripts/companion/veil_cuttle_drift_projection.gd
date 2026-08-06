extends Node2D

const COLOR_PATH := Color("72e6d1")
const COLOR_DIRECTION := Color("d9fff2")
const COLOR_APPROACH := Color("ffd166")

var _path_points := PackedVector2Array()
var _current_center := Vector2.ZERO
var _movement_direction := Vector2.ZERO
var _approaching := false
var _visible := false


func show_projection(
	path_points: Array,
	current_center: Vector2,
	movement_direction: Vector2,
	approaching: bool
) -> void:
	_path_points = PackedVector2Array()
	for point in path_points:
		_path_points.append(point as Vector2)
	_current_center = current_center
	_movement_direction = movement_direction.normalized()
	_approaching = approaching
	_visible = _path_points.size() >= 2
	queue_redraw()


func clear_projection() -> void:
	_path_points = PackedVector2Array()
	_current_center = Vector2.ZERO
	_movement_direction = Vector2.ZERO
	_approaching = false
	_visible = false
	queue_redraw()


func report() -> Dictionary:
	return {
		"visible": _visible,
		"path_point_count": _path_points.size(),
		"current_center": _current_center,
		"movement_direction": _movement_direction,
		"approaching": _approaching,
	}


func _draw() -> void:
	if not _visible:
		return
	draw_polyline(_path_points, Color(COLOR_PATH, 0.24), 8.0, true)
	draw_polyline(_path_points, Color(COLOR_PATH, 0.88), 2.5, true)
	_draw_path_ticks()
	var subject_color := COLOR_APPROACH if _approaching else COLOR_DIRECTION
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
