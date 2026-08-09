extends Node2D

const VeilCuttleIntentCard := preload("res://scripts/companion/veil_cuttle_intent_card.gd")

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
var _intent_layer: CanvasLayer
var _intent_card


func _ready() -> void:
	_intent_layer = CanvasLayer.new()
	_intent_layer.name = "MicaIntentLayer"
	_intent_layer.layer = 20
	add_child(_intent_layer)
	_intent_card = VeilCuttleIntentCard.new()
	_intent_card.name = "MicaIntentCard"
	_intent_layer.add_child(_intent_card)


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
	_sync_intent_card()
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
	if _intent_card != null:
		_intent_card.clear_prediction()
	queue_redraw()


func report() -> Dictionary:
	var card: Dictionary = _intent_card.report() if _intent_card != null else {}
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
		"heading_text": str(card.get("heading_text", "")),
		"primary_text": str(card.get("primary_text", "")),
		"response_text": str(card.get("response_text", "")),
		"card_rect": card.get("rect", Rect2()),
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
		draw_rect(_territory_rect, Color(color, 0.07), true)
		draw_rect(_territory_rect, Color(color, 0.72), false, 2.0, true)
	if _projected_lunge_target.distance_to(_current_center) > 0.01:
		_draw_lunge_arrow(color)


func _draw_lunge_arrow(color: Color) -> void:
	var direction := _current_center.direction_to(_projected_lunge_target)
	var side := direction.orthogonal()
	draw_line(_current_center, _projected_lunge_target, Color(color, 0.92), 5.0, true)
	draw_colored_polygon(PackedVector2Array([
		_projected_lunge_target,
		_projected_lunge_target - direction * 15.0 + side * 9.0,
		_projected_lunge_target - direction * 15.0 - side * 9.0,
	]), color)


func _sync_intent_card() -> void:
	if _intent_card == null:
		return
	if _subject_kind != "territorial_hostile" or not _visible:
		_intent_card.clear_prediction()
		return
	_intent_card.show_prediction(
		global_transform * _current_center,
		_phase,
		_movement_direction,
		_phase_seconds
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
