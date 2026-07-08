extends RefCounted


func build_collision(parent: Node2D, terrain_items: Array, tile_size: int) -> void:
	for item in terrain_items:
		if item.get("type", "") != "solid":
			continue

		var body := StaticBody2D.new()
		body.name = "%sCollision" % item.get("id", "Terrain")
		body.position = _rect_center(item, tile_size)

		var shape := RectangleShape2D.new()
		shape.size = _rect_size(item, tile_size)

		var collision := CollisionShape2D.new()
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)


func collision_rects_from_runtime(collision_root: Node2D, tile_size: int) -> Array:
	var rects := []
	if collision_root == null:
		return rects

	for body_node in collision_root.get_children():
		if not body_node is StaticBody2D:
			continue
		var body := body_node as StaticBody2D
		for shape_node in body.get_children():
			if not shape_node is CollisionShape2D:
				continue
			var collision := shape_node as CollisionShape2D
			if not collision.shape is RectangleShape2D:
				continue
			var rectangle := collision.shape as RectangleShape2D
			var size := rectangle.size
			var center := body.position + collision.position
			rects.append({
				"id": body.name,
				"x": int(round((center.x - size.x * 0.5) / tile_size)),
				"y": int(round((center.y - size.y * 0.5) / tile_size)),
				"w": int(round(size.x / tile_size)),
				"h": int(round(size.y / tile_size)),
			})

	rects.sort_custom(func(a, b): return int(a["x"]) < int(b["x"]) if int(a["y"]) == int(b["y"]) else int(a["y"]) < int(b["y"]))
	return rects


func collision_cells_from_runtime(collision_root: Node2D, tile_size: int) -> Array:
	var cells := []
	for rect in collision_rects_from_runtime(collision_root, tile_size):
		for y in range(int(rect["y"]), int(rect["y"]) + int(rect["h"])):
			for x in range(int(rect["x"]), int(rect["x"]) + int(rect["w"])):
				cells.append(Vector2i(x, y))
	return cells


func sorted_cell_arrays(cells: Array) -> Array:
	var sorted_cells := cells.duplicate()
	sorted_cells.sort_custom(func(a, b): return a.x < b.x if a.y == b.y else a.y < b.y)

	var output := []
	for cell in sorted_cells:
		output.append([cell.x, cell.y])
	return output


func _rect_center(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2(
		(float(item["x"]) + float(item["w"]) * 0.5) * tile_size,
		(float(item["y"]) + float(item["h"]) * 0.5) * tile_size
	)


func _rect_size(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)
