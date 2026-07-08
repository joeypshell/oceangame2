extends RefCounted

const COLOR_SALVAGE := Color(1.0, 0.80, 0.22, 1.0)
const COLOR_SALVAGE_DARK := Color(0.48, 0.30, 0.11, 1.0)
const COLOR_SALVAGE_METAL := Color(0.72, 0.83, 0.78, 1.0)
const COLOR_SALVAGE_VALUABLE := Color(1.0, 0.92, 0.36, 0.92)
const COLOR_SALVAGE_VALUABLE_GLOW := Color(1.0, 0.86, 0.22, 0.24)
const COLOR_SALVAGE_TIMED := Color(0.42, 0.95, 1.0, 0.72)
const COLOR_SALVAGE_TIMED_GLOW := Color(0.28, 0.92, 0.98, 0.16)
const COLOR_HAZARD := Color(1.0, 0.22, 0.34, 1.0)
const COLOR_HAZARD_DARK := Color(0.40, 0.04, 0.10, 1.0)
const COLOR_HAZARD_LIGHT := Color(1.0, 0.58, 0.66, 1.0)


func add_salvage_prop(parent: Node2D, marker_name: String, center: Vector2, kind: String, tier: String, interaction: String, asset_lookup) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.position = center
	root.z_index = 8
	parent.add_child(root)

	if not _add_prop_sprite(root, "PropSprite", _prop_texture(kind, "crate", asset_lookup)):
		match kind:
			"wreck_fragment":
				_add_wreck_fragment_prop(root)
			"relic":
				_add_relic_prop(root)
			_:
				_add_crate_prop(root)
	if tier == "valuable":
		_add_valuable_salvage_cue(root)
	if interaction == "timed_salvage":
		_add_timed_salvage_affordance(root)
	return root


func add_hazard_prop(parent: Node2D, marker_name: String, center: Vector2, kind: String, asset_lookup) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.position = center
	root.z_index = 8
	parent.add_child(root)

	if _add_prop_sprite(root, "PropSprite", _prop_texture(kind, "mine", asset_lookup)):
		return root

	match kind:
		"jellyfish":
			_add_jellyfish_prop(root)
		_:
			_add_mine_prop(root)
	return root


func _prop_texture(kind: String, fallback_kind: String, asset_lookup) -> Texture2D:
	if asset_lookup == null:
		return null
	return asset_lookup.prop_texture(kind, fallback_kind)


func _add_prop_sprite(parent: Node2D, sprite_name: String, texture: Texture2D) -> bool:
	if texture == null:
		return false

	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	parent.add_child(sprite)
	return true


func _add_timed_salvage_affordance(root: Node2D) -> void:
	var glow := _add_local_polygon(root, "TimedActionGlow", _ellipse_points(26.0, 18.0, 24), COLOR_SALVAGE_TIMED_GLOW)
	glow.z_index = -2

	var ring_points := _circle_points(20.0, 28)
	ring_points.append(ring_points[0])
	var ring := _add_local_line(root, "TimedActionRing", ring_points, COLOR_SALVAGE_TIMED, 2.0)
	ring.z_index = 5

	var tick := _add_local_line(root, "TimedActionTick", PackedVector2Array([Vector2(0, -29), Vector2(0, -20)]), COLOR_SALVAGE_TIMED, 2.0)
	tick.z_index = 6

	var dot := _add_local_polygon(root, "TimedActionDot", _circle_points(3.0, 8, Vector2(0, -31)), COLOR_SALVAGE_TIMED)
	dot.z_index = 7


func _add_valuable_salvage_cue(root: Node2D) -> void:
	var glow := _add_local_polygon(root, "ValuableGlow", _diamond_points(22.0), COLOR_SALVAGE_VALUABLE_GLOW)
	glow.z_index = -1

	var ring := _add_local_line(root, "ValuableRing", PackedVector2Array([
		Vector2(0, -24),
		Vector2(24, 0),
		Vector2(0, 24),
		Vector2(-24, 0),
		Vector2(0, -24),
	]), COLOR_SALVAGE_VALUABLE, 2.0)
	ring.z_index = 4

	var sparkle := _add_local_polygon(root, "ValuableSparkle", PackedVector2Array([
		Vector2(0, -8),
		Vector2(3, -2),
		Vector2(9, 0),
		Vector2(3, 2),
		Vector2(0, 8),
		Vector2(-3, 2),
		Vector2(-9, 0),
		Vector2(-3, -2),
	]), COLOR_SALVAGE_VALUABLE)
	sparkle.position = Vector2(13, -13)
	sparkle.z_index = 5


func _add_crate_prop(root: Node2D) -> void:
	_add_local_polygon(root, "CrateBody", _rect_points(Vector2(24, 20)), Color(0.82, 0.52, 0.20, 1.0))
	_add_local_line(root, "CrateOutline", _closed_rect_points(Vector2(24, 20)), COLOR_SALVAGE_DARK, 2.0)
	_add_local_line(root, "CrateBandHorizontal", PackedVector2Array([Vector2(-12, 0), Vector2(12, 0)]), COLOR_SALVAGE_DARK, 2.0)
	_add_local_line(root, "CrateBandVertical", PackedVector2Array([Vector2(0, -10), Vector2(0, 10)]), COLOR_SALVAGE_DARK, 2.0)
	_add_local_polygon(root, "CrateGlint", PackedVector2Array([Vector2(5, -8), Vector2(10, -8), Vector2(10, -4), Vector2(5, -4)]), COLOR_SALVAGE)


func _add_wreck_fragment_prop(root: Node2D) -> void:
	_add_local_polygon(root, "FragmentBody", PackedVector2Array([
		Vector2(-15, -7),
		Vector2(12, -11),
		Vector2(17, 1),
		Vector2(-9, 9),
	]), COLOR_SALVAGE_METAL)
	_add_local_polygon(root, "FragmentRust", PackedVector2Array([
		Vector2(-13, -5),
		Vector2(-2, -7),
		Vector2(0, 3),
		Vector2(-10, 6),
	]), Color(0.73, 0.39, 0.17, 1.0))
	_add_local_line(root, "FragmentEdge", PackedVector2Array([
		Vector2(-15, -7),
		Vector2(12, -11),
		Vector2(17, 1),
		Vector2(-9, 9),
		Vector2(-15, -7),
	]), Color(0.16, 0.23, 0.25, 1.0), 2.0)
	_add_local_polygon(root, "FragmentGlint", PackedVector2Array([Vector2(7, -8), Vector2(13, -9), Vector2(14, -5), Vector2(8, -4)]), COLOR_SALVAGE)


func _add_relic_prop(root: Node2D) -> void:
	_add_local_polygon(root, "RelicGlow", _circle_points(13.0, 16), Color(0.24, 0.94, 0.90, 0.38))
	_add_local_polygon(root, "RelicCore", _circle_points(8.0, 16), Color(0.10, 0.70, 0.72, 1.0))
	_add_local_line(root, "RelicBand", PackedVector2Array([Vector2(-12, 4), Vector2(12, 4)]), COLOR_SALVAGE_DARK, 2.0)
	_add_local_polygon(root, "RelicGold", PackedVector2Array([
		Vector2(-7, -11),
		Vector2(7, -11),
		Vector2(9, -6),
		Vector2(-9, -6),
	]), COLOR_SALVAGE)


func _add_mine_prop(root: Node2D) -> void:
	_add_local_polygon(root, "MineSpikes", _star_points(10.0, 18.0, 8), COLOR_HAZARD_DARK)
	_add_local_polygon(root, "MineBody", _circle_points(11.0, 18), COLOR_HAZARD)
	_add_local_polygon(root, "MineHighlight", _circle_points(4.0, 10, Vector2(-4, -4)), COLOR_HAZARD_LIGHT)


func _add_jellyfish_prop(root: Node2D) -> void:
	_add_local_polygon(root, "JellyBell", PackedVector2Array([
		Vector2(-14, 1),
		Vector2(-11, -8),
		Vector2(-4, -13),
		Vector2(5, -13),
		Vector2(12, -8),
		Vector2(15, 1),
		Vector2(9, 7),
		Vector2(3, 3),
		Vector2(-3, 7),
		Vector2(-9, 3),
	]), COLOR_HAZARD)
	_add_local_line(root, "JellyTentacleLeft", PackedVector2Array([Vector2(-7, 5), Vector2(-10, 13), Vector2(-7, 18)]), COLOR_HAZARD_LIGHT, 2.0)
	_add_local_line(root, "JellyTentacleCenter", PackedVector2Array([Vector2(0, 5), Vector2(2, 13), Vector2(0, 20)]), COLOR_HAZARD_LIGHT, 2.0)
	_add_local_line(root, "JellyTentacleRight", PackedVector2Array([Vector2(7, 5), Vector2(10, 13), Vector2(7, 18)]), COLOR_HAZARD_LIGHT, 2.0)
	_add_local_polygon(root, "JellyHighlight", _circle_points(3.0, 8, Vector2(-4, -6)), COLOR_HAZARD_LIGHT)


func _add_local_polygon(parent: Node2D, polygon_name: String, points: PackedVector2Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = polygon_name
	poly.color = color
	poly.polygon = points
	parent.add_child(poly)
	return poly


func _add_local_line(parent: Node2D, line_name: String, points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.points = points
	line.default_color = color
	line.width = width
	parent.add_child(line)
	return line


func _rect_points(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


func _closed_rect_points(size: Vector2) -> PackedVector2Array:
	var points := _rect_points(size)
	points.append(points[0])
	return points


func _diamond_points(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius, 0),
		Vector2(0, radius),
		Vector2(-radius, 0),
	])


func _circle_points(radius: float, steps: int, offset := Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(offset + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _ellipse_points(radius_x: float, radius_y: float, steps: int, offset := Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(offset + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _star_points(inner_radius: float, outer_radius: float, spikes: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(spikes * 2):
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + TAU * float(index) / float(spikes * 2)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
