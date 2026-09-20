extends Node2D

# Presentation owns only shelter/group motion. Qualification belongs to Marl's
# event owner; these source-authored animals are not combat or reward actors.
var source := {}
var target := Vector2.ZERO
var _path: Array[Vector2] = []
var _travel := 0.0
var _opened := false
var _phase := "closed"
var _progress := 0.0
var _threatened := false
const TRAVEL_SECONDS := 1.8


func configure(record: Dictionary, tile_size: int) -> void:
	source = record.duplicate(true)
	name = str(record["id"])
	target = _point(record["dig_point"], tile_size)
	position = target
	for point in record["wildlife_path"]:
		_path.append(_point(point, tile_size) - target)
	z_index = 8
	queue_redraw()


func open_shelter() -> bool:
	if _opened:
		return false
	_opened = true
	_phase = "opened"
	queue_redraw()
	return true


func project_dig(phase: String, progress: float) -> void:
	if not _opened:
		_phase = phase
		_progress = progress
	queue_redraw()


func advance(delta: float, threatened: bool) -> void:
	_threatened = threatened
	if _opened:
		_travel = minf(TRAVEL_SECONDS, _travel + maxf(0, delta))
	queue_redraw()


func reset_closed() -> void:
	_opened = false
	_travel = 0.0
	_phase = "closed"
	_progress = 0.0
	_threatened = false
	queue_redraw()


func report() -> Dictionary:
	return {"opened": _opened, "sheltered": _opened and _travel >= TRAVEL_SECONDS,
		"travel_seconds": _travel, "phase": _phase, "threatened": _threatened,
		"target_id": source.get("id", "")}


func _draw() -> void:
	# A low, physically open arch differs from the old material-bearing mound.
	draw_circle(Vector2(0, -1), 18, Color("45666a"))
	draw_circle(Vector2(0, 3), 12, Color("132e37") if _opened else Color("bbad79"))
	draw_line(Vector2(-22, 12), Vector2(22, 12), Color("dfce92"), 3)
	if not _opened:
		for offset in [-10, 0, 10]:
			draw_line(Vector2(offset - 3, 6), Vector2(offset + 3, 0), Color("706845"), 2)
		if _phase in ["digging", "anticipating"]:
			for index in range(5):
				var angle := float(index) * 0.6 + _progress * 2.0
				draw_circle(Vector2(cos(angle) * 21, -absf(sin(angle)) * 20), 2, Color("dfce92"))
	if _path.is_empty():
		return
	for index in range(3):
		var fraction := clampf((_travel - float(index) * 0.2) / (TRAVEL_SECONDS - 0.4), 0, 1)
		var distance := fraction * float(_path.size() - 1)
		var segment := mini(int(distance), _path.size() - 2)
		var center := _path[segment].lerp(_path[segment + 1], distance - segment)
		center += Vector2(index * 7 - 7, -4 + abs(index - 1) * 4)
		var size := 7.0 * (1.0 - fraction * 0.6)
		var tint := Color("e8b0a2") if _threatened and not _opened else Color("afe0cb")
		draw_circle(center, size, Color("254b55"))
		draw_arc(center, size, PI, TAU, 12, tint, 3)
		for rib in [-0.6, 0.0, 0.6]:
			draw_line(center + Vector2(0, 2), center + Vector2(sin(rib) * size, -cos(rib) * size), tint, 1)


func _point(value: Dictionary, size: int) -> Vector2:
	return Vector2(float(value["x"]) + 0.5, float(value["y"]) + 0.5) * size
