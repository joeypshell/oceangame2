extends RefCounted

const CHEST_BODY := Color(0.57, 0.23, 0.80, 0.92)
const CHEST_LID := Color(0.82, 0.55, 1.0, 0.95)
const CHEST_LATCH := Color(1.0, 0.86, 0.28, 0.98)
const BLUEPRINT_GLOW := Color(0.42, 0.92, 1.0, 0.24)
const BLUEPRINT_PAPER := Color(0.72, 0.96, 1.0, 0.98)
const BLUEPRINT_INK := Color(0.08, 0.35, 0.52, 0.92)


func add_container(parent: Node2D, item: Dictionary, tile_size: int) -> Node2D:
	var rect := _rect_from_item(item, tile_size)
	var root := Node2D.new()
	root.name = str(item.get("id", "ProgressionContainer"))
	root.position = rect.get_center()
	root.z_index = 16
	root.set_meta("reward_type", str(item.get("reward_type", "")))
	root.set_meta("interaction", str(item.get("interaction", "instant")))
	parent.add_child(root)

	var body_size := Vector2(maxf(20.0, rect.size.x * 0.7), maxf(14.0, rect.size.y * 0.46))
	var body := _add_polygon(root, "ChestBody", _rect_points(body_size), CHEST_BODY)
	body.position.y = body_size.y * 0.18
	body.z_index = 1

	var lid_size := Vector2(body_size.x * 0.88, maxf(8.0, body_size.y * 0.5))
	var lid := _add_polygon(root, "ChestLid", _rect_points(lid_size), CHEST_LID)
	lid.position.y = -body_size.y * 0.36
	lid.z_index = 2

	var latch := _add_polygon(root, "ChestLatch", _diamond_points(minf(7.0, body_size.y * 0.34)), CHEST_LATCH)
	latch.z_index = 3
	if str(item.get("reward_type", "")) == "blueprint":
		_add_blueprint_cue(root, body_size)
	return root


func _add_blueprint_cue(parent: Node2D, body_size: Vector2) -> void:
	parent.set_meta("cue_kind", "blueprint")
	var cue_y := -body_size.y * 1.05
	var glow := _add_polygon(parent, "BlueprintGlow", _diamond_points(18.0), BLUEPRINT_GLOW)
	glow.position.y = cue_y
	glow.z_index = 3
	var paper := _add_polygon(parent, "BlueprintSheet", _rect_points(Vector2(18.0, 24.0)), BLUEPRINT_PAPER)
	paper.position.y = cue_y
	paper.z_index = 4
	_add_line(parent, "BlueprintLineA", [Vector2(-5.0, cue_y - 4.0), Vector2(5.0, cue_y - 4.0)], BLUEPRINT_INK, 2.0, 5)
	_add_line(parent, "BlueprintLineB", [Vector2(-5.0, cue_y + 2.0), Vector2(3.0, cue_y + 2.0)], BLUEPRINT_INK, 2.0, 5)
	_add_line(parent, "BlueprintLink", [Vector2(0.0, cue_y + 12.0), Vector2(0.0, -body_size.y * 0.48)], BLUEPRINT_PAPER, 2.0, 3)


func _add_polygon(parent: Node2D, node_name: String, points: PackedVector2Array, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	return polygon


func _add_line(parent: Node2D, node_name: String, points: Array, color: Color, width: float, z_index: int) -> void:
	var line := Line2D.new()
	line.name = node_name
	line.points = PackedVector2Array(points)
	line.default_color = color
	line.width = width
	line.antialiased = true
	line.z_index = z_index
	parent.add_child(line)


func _rect_points(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


func _diamond_points(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius, 0.0),
		Vector2(0.0, radius),
		Vector2(-radius, 0.0),
	])


func _rect_from_item(item: Dictionary, tile_size: int) -> Rect2:
	return Rect2(
		Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size),
		Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)
	)
