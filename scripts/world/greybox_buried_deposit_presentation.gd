extends Node2D

const STATE_CLOSED := "closed"
const STATE_DISTURBED := "disturbed"
const STATE_ANTICIPATING := "anticipating"
const STATE_DIGGING := "digging"
const STATE_IMPACT := "impact"
const STATE_OPENED := "opened"
const STATE_EMPTY := "empty"

const VALID_STATES := [
	STATE_CLOSED,
	STATE_DISTURBED,
	STATE_ANTICIPATING,
	STATE_DIGGING,
	STATE_IMPACT,
	STATE_OPENED,
	STATE_EMPTY,
]
const COLOR_SILT := Color("a08d68")
const COLOR_SILT_LIGHT := Color("c7b98a")
const COLOR_STONE := Color("526066")
const COLOR_STONE_LIGHT := Color("7f9090")
const COLOR_OPENING := Color("18282d")
const COLOR_IMPACT := Color("9be8eb")

var _state := STATE_CLOSED
var _progress := 0.0


func set_state(state: String, progress := 0.0) -> bool:
	if state not in VALID_STATES:
		return false
	_state = state
	_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()
	return true


func report() -> Dictionary:
	return {
		"state": _state,
		"progress": _progress,
		"excavated": _state in [STATE_OPENED, STATE_EMPTY],
		"pickup_exposed": _state == STATE_OPENED,
	}


func _draw() -> void:
	_draw_bed()
	if _state in [STATE_OPENED, STATE_EMPTY]:
		_draw_opening()
	else:
		_draw_closed_mound()
	_draw_action_cue()


func _draw_bed() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-28.0, 9.0),
		Vector2(-17.0, 4.0),
		Vector2(0.0, 2.0),
		Vector2(20.0, 5.0),
		Vector2(30.0, 11.0),
		Vector2(23.0, 16.0),
		Vector2(-23.0, 16.0),
	]), Color(COLOR_SILT, 0.82))


func _draw_closed_mound() -> void:
	var disturbance := 2.5 * _progress if _state in [STATE_DISTURBED, STATE_ANTICIPATING, STATE_DIGGING, STATE_IMPACT] else 0.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, 8.0),
		Vector2(-15.0, -4.0 - disturbance),
		Vector2(0.0, -10.0 - disturbance),
		Vector2(17.0, -3.0 - disturbance),
		Vector2(25.0, 8.0),
	]), COLOR_SILT)
	draw_arc(Vector2(0.0, 4.0 - disturbance), 18.0, PI, TAU, 20, COLOR_SILT_LIGHT, 2.0, true)
	for stone in [
		[Vector2(-12.0, 0.0 - disturbance), 4.5],
		[Vector2(4.0, -4.0 - disturbance), 5.5],
		[Vector2(15.0, 3.0 - disturbance), 3.5],
	]:
		draw_circle(stone[0], stone[1], COLOR_STONE)
		draw_circle((stone[0] as Vector2) + Vector2(-1.0, -1.0), float(stone[1]) * 0.42, COLOR_STONE_LIGHT)


func _draw_opening() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, 8.0),
		Vector2(-15.0, -1.0),
		Vector2(0.0, -5.0),
		Vector2(18.0, 0.0),
		Vector2(25.0, 8.0),
		Vector2(16.0, 13.0),
		Vector2(-17.0, 13.0),
	]), Color(COLOR_SILT, 0.72))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14.0, 6.0),
		Vector2(-7.0, 0.0),
		Vector2(8.0, 0.0),
		Vector2(16.0, 6.0),
		Vector2(9.0, 11.0),
		Vector2(-8.0, 11.0),
	]), COLOR_OPENING)
	if _state == STATE_EMPTY:
		draw_line(Vector2(-7.0, 5.0), Vector2(7.0, 5.0), Color(COLOR_STONE_LIGHT, 0.7), 1.5, true)


func _draw_action_cue() -> void:
	if _state == STATE_ANTICIPATING:
		var radius := 22.0 + 5.0 * _progress
		draw_arc(Vector2.ZERO, radius, PI * 0.08, PI * 0.92, 24, Color(COLOR_IMPACT, 0.75), 2.0, true)
	elif _state == STATE_DIGGING:
		for index in range(5):
			var angle := float(index) * 0.9 + _progress * 4.0
			var distance := 18.0 + float(index % 2) * 7.0 + _progress * 8.0
			draw_circle(Vector2(cos(angle), sin(angle)) * distance + Vector2(0.0, -2.0), 2.5, Color(COLOR_SILT_LIGHT, 0.74))
	elif _state == STATE_IMPACT:
		var radius := 12.0 + 34.0 * _progress
		draw_arc(Vector2(0.0, 2.0), radius, 0.0, TAU, 32, Color(COLOR_IMPACT, 1.0 - _progress * 0.6), 3.0, true)
