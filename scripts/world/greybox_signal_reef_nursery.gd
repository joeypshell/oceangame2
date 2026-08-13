extends Node2D

const JOURNEY_ID := "signal_reef_nursery_journey_01"
const SCHOOL_ID := "signal_reef_filter_skate_school_01"
const NURSERY_ID := "signal_reef_filter_skate_nursery_01"
const PRESSURE_ID := "signal_reef_jellyfish_pressure_01"
const UNRESOLVED := "unresolved"
const ANCHOR_ACTIVE := "anchor_active"
const GUARDIAN_ACTIVE := "guardian_active"
const SHELTERED_PENDING_RETURN := "sheltered_pending_return"
const COMMITTED_WAITING_NEXT_DAY := "committed_waiting_next_day"
const RESTORED := "restored"
const VALID_STATES := {
	UNRESOLVED: true,
	ANCHOR_ACTIVE: true,
	GUARDIAN_ACTIVE: true,
	SHELTERED_PENDING_RETURN: true,
	COMMITTED_WAITING_NEXT_DAY: true,
	RESTORED: true,
}
const SHELTER_SECONDS := 2.4

var _configured := false
var _show_debug := false
var _tile_size := 32
var _journey := {}
var _school := {}
var _nursery := {}
var _pressure := {}
var _contexts: Array[Dictionary] = []
var _school_path: Array[Vector2] = []
var _pressure_path: Array[Vector2] = []
var _nursery_center := Vector2.ZERO
var _nursery_rect := Rect2()
var _state := UNRESOLVED
var _shelter_progress := 0.0
var _elapsed := 0.0


func build(
	parent: Node2D,
	journeys: Array,
	schools: Array,
	nurseries: Array,
	pressures: Array,
	contexts: Array,
	tile_size: int,
	show_debug: bool
) -> void:
	_tile_size = tile_size
	_show_debug = show_debug
	_journey = _record_by_id(journeys, JOURNEY_ID)
	_school = _record_by_id(schools, SCHOOL_ID)
	_nursery = _record_by_id(nurseries, NURSERY_ID)
	_pressure = _record_by_id(pressures, PRESSURE_ID)
	_contexts = _matching_contexts(contexts)
	_configured = not _journey.is_empty() and not _school.is_empty() and not _nursery.is_empty() and not _pressure.is_empty()
	if not _configured:
		return
	name = "SignalReefNursery"
	z_index = 14
	_school_path = _world_path(_school.get("path", []))
	_pressure_path = _world_path(_pressure.get("path", []))
	_nursery_rect = _world_rect(_nursery)
	_nursery_center = _nursery_rect.get_center()
	parent.add_child(self)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> Dictionary:
	if not _configured or delta <= 0.0:
		return report()
	_elapsed += delta
	if _state in [ANCHOR_ACTIVE, GUARDIAN_ACTIVE]:
		_shelter_progress = minf(1.0, _shelter_progress + delta / SHELTER_SECONDS)
		if is_equal_approx(_shelter_progress, 1.0):
			_state = SHELTERED_PENDING_RETURN
	queue_redraw()
	return report()


func set_state(state: String, shelter_progress := 0.0) -> bool:
	if not _configured or not VALID_STATES.has(state):
		return false
	_state = state
	match state:
		UNRESOLVED:
			_shelter_progress = 0.0
		ANCHOR_ACTIVE, GUARDIAN_ACTIVE:
			_shelter_progress = clampf(shelter_progress, 0.0, 0.99)
		_:
			_shelter_progress = 1.0
	queue_redraw()
	return true


func reset_uncommitted() -> bool:
	if _state in [COMMITTED_WAITING_NEXT_DAY, RESTORED]:
		return false
	return set_state(UNRESOLVED)


func report() -> Dictionary:
	var school_center := _school_center()
	return {
		"configured": _configured,
		"journey_id": str(_journey.get("id", "")),
		"school_id": str(_school.get("id", "")),
		"nursery_id": str(_nursery.get("id", "")),
		"pressure_id": str(_pressure.get("id", "")),
		"state": _state,
		"shelter_progress": _shelter_progress,
		"school_center": school_center,
		"pressure_center": _pressure_center(),
		"nursery_center": _nursery_center,
		"school_member_count": 7 if _state == RESTORED else 5,
		"context_ids": _context_ids(),
		"passive": not bool(_school.get("bondable", true)),
		"bondable": bool(_school.get("bondable", true)),
		"collectible": bool(_school.get("collectible", true)),
		"harvestable": bool(_school.get("harvestable", true)),
		"damaging": bool(_pressure.get("damaging", true)),
		"reward_ids": (_school.get("reward_ids", []) as Array).duplicate(),
	}


func _draw() -> void:
	if not _configured:
		return
	_draw_nursery()
	if _state not in [SHELTERED_PENDING_RETURN, COMMITTED_WAITING_NEXT_DAY, RESTORED]:
		_draw_pressure()
	_draw_school()
	_draw_response()
	if _show_debug:
		draw_string(ThemeDB.fallback_font, _nursery_center + Vector2(-86, 76), _state, HORIZONTAL_ALIGNMENT_CENTER, 172.0, 16, Color(0.72, 1.0, 0.96, 0.94))


func _draw_nursery() -> void:
	var occupied := _state in [SHELTERED_PENDING_RETURN, COMMITTED_WAITING_NEXT_DAY, RESTORED]
	var fill := Color(0.10, 0.51, 0.48, 0.09 if not occupied else 0.20)
	if _state == RESTORED:
		fill = Color(0.20, 0.76, 0.56, 0.26)
	draw_circle(_nursery_center, 62.0, fill)
	draw_arc(_nursery_center, 62.0, 0.0, TAU, 48, Color(0.43, 0.94, 0.77, 0.34 if not occupied else 0.78), 2.0, true)
	for index in range(5):
		var root := _nursery_center + Vector2(-48.0 + index * 24.0, 44.0)
		var sway := sin(_elapsed * 1.4 + index) * 5.0
		draw_polyline(PackedVector2Array([root, root + Vector2(sway, -20), root + Vector2(-sway * 0.4, -37)]), Color(0.20, 0.72, 0.50, 0.72), 3.0, true)
	if _state == RESTORED:
		for offset in [Vector2(-28, 25), Vector2(-8, 33), Vector2(16, 27), Vector2(34, 35)]:
			draw_circle(_nursery_center + offset, 4.0, Color(0.76, 1.0, 0.78, 0.92))


func _draw_pressure() -> void:
	var center := _pressure_center()
	for index in range(3):
		var phase := _elapsed * 1.6 + index * 2.1
		var jelly_center := center + Vector2((index - 1) * 28.0, sin(phase) * 10.0)
		draw_circle(jelly_center, 11.0, Color(0.83, 0.29, 0.57, 0.72))
		draw_arc(jelly_center, 13.0, PI, TAU, 14, Color(1.0, 0.62, 0.78, 0.88), 2.0, true)
		for tentacle in [-6.0, 0.0, 6.0]:
			draw_polyline(PackedVector2Array([jelly_center + Vector2(tentacle, 8), jelly_center + Vector2(tentacle + sin(phase) * 3.0, 23)]), Color(0.96, 0.54, 0.75, 0.72), 2.0, true)


func _draw_school() -> void:
	var center := _school_center()
	var count := 7 if _state == RESTORED else 5
	for index in range(count):
		var row := index / 3
		var column := index % 3
		var offset := Vector2((column - 1) * 27.0 - row * 8.0, (row - 1) * 22.0)
		offset.y += sin(_elapsed * 2.2 + index * 1.7) * 3.5
		var scale := 0.78 if index >= 5 else 1.0
		_draw_filter_skate(center + offset, scale, index)


func _draw_filter_skate(center: Vector2, scale: float, index: int) -> void:
	var body_color := Color(0.20, 0.60, 0.65, 1.0) if _state != RESTORED else Color(0.24, 0.78, 0.66, 1.0)
	var wing := PackedVector2Array([Vector2(-2, 0), Vector2(-17, -8), Vector2(-13, 1), Vector2(-17, 9), Vector2(0, 4), Vector2(16, 9), Vector2(12, 0), Vector2(16, -8), Vector2(2, -3)])
	for point_index in range(wing.size()):
		wing[point_index] = center + wing[point_index] * scale
	draw_colored_polygon(wing, body_color)
	draw_circle(center + Vector2(3, 0) * scale, 4.2 * scale, Color(0.68, 0.96, 0.88, 1.0))
	draw_line(center + Vector2(-14, 0) * scale, center + Vector2(-25 - index % 2 * 4, 0) * scale, Color(0.28, 0.75, 0.72, 0.9), 1.8 * scale, true)


func _draw_response() -> void:
	if _state == ANCHOR_ACTIVE:
		var center := _school_path[-1] if not _school_path.is_empty() else _nursery_center
		for radius in [34.0, 48.0, 62.0]:
			draw_arc(center, radius, -PI * 0.65, PI * 0.65, 22, Color(0.34, 0.94, 1.0, 0.54), 3.0, true)
	elif _state == GUARDIAN_ACTIVE:
		var center := _pressure_center()
		for radius in [28.0, 47.0, 66.0]:
			draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 0.82, 0.31, 0.62), 3.0, true)


func _school_center() -> Vector2:
	if _school_path.is_empty():
		return _nursery_center
	if _state in [SHELTERED_PENDING_RETURN, COMMITTED_WAITING_NEXT_DAY, RESTORED]:
		return _nursery_center + Vector2(sin(_elapsed * 0.8) * 12.0, cos(_elapsed * 0.9) * 7.0)
	if _state in [ANCHOR_ACTIVE, GUARDIAN_ACTIVE]:
		return _path_lerp(_school_path, _shelter_progress)
	var passive_progress := (sin(_elapsed * 0.42) + 1.0) * 0.18
	return _path_lerp(_school_path, passive_progress)


func _pressure_center() -> Vector2:
	if _pressure_path.is_empty():
		return Vector2(float(_pressure.get("x", 0)) + 0.5, float(_pressure.get("y", 0)) + 0.5) * _tile_size
	var progress := (sin(_elapsed * 0.55) + 1.0) * 0.5
	return _path_lerp(_pressure_path, progress)


func _path_lerp(path: Array[Vector2], progress: float) -> Vector2:
	if path.size() == 1:
		return path[0]
	var scaled := clampf(progress, 0.0, 1.0) * float(path.size() - 1)
	var start_index := mini(int(floor(scaled)), path.size() - 2)
	return path[start_index].lerp(path[start_index + 1], scaled - float(start_index))


func _world_path(values: Array) -> Array[Vector2]:
	var path: Array[Vector2] = []
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			path.append(Vector2(float(value.get("x", 0)) + 0.5, float(value.get("y", 0)) + 0.5) * _tile_size)
	return path


func _world_rect(value: Dictionary) -> Rect2:
	return Rect2(Vector2(float(value.get("x", 0)), float(value.get("y", 0))) * _tile_size, Vector2(float(value.get("w", 0)), float(value.get("h", 0))) * _tile_size)


func _record_by_id(values: Array, record_id: String) -> Dictionary:
	for value in values:
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == record_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _matching_contexts(values: Array) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for value in values:
		if typeof(value) == TYPE_DICTIONARY and str(value.get("journey_id", "")) == JOURNEY_ID:
			matches.append((value as Dictionary).duplicate(true))
	return matches


func _context_ids() -> Array[String]:
	var ids: Array[String] = []
	for context in _contexts:
		ids.append(str(context.get("id", "")))
	return ids
