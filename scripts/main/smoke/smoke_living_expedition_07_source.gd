extends SceneTree

const WorldScene := preload("res://scenes/world/GreyboxWorld.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const MarlScene := preload("res://scenes/companion/SiltHoundCompanion.tscn")
const HostileController := preload("res://scripts/main/territorial_hostile_controller.gd")
const DailyConditions := preload("res://scripts/main/daily_condition_state.gd")
const MaterialSelector := preload("res://scripts/main/material_candidate_selector.gd")
const MAP_PATH := "res://maps/production_level_01.greybox.json"
const HOSTILE_ID := "deep_cache_territorial_eel"
const CONTEXT_ID := "deep_cache_eel_marl_ground_pin"
const CAPTURE_PATH := "res://tmp/living_expedition_07/source_contact.png"
const STEP := 1.0 / 60.0

var _failures: Array[String] = []
var _world
var _player: CharacterBody2D
var _marl: CharacterBody2D
var _source: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_source = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	_world = WorldScene.instantiate()
	_world.map_path = MAP_PATH
	root.add_child(_world)
	_player = PlayerScene.instantiate()
	root.add_child(_player)
	_player.set_physics_process(false)
	_marl = MarlScene.instantiate()
	root.add_child(_marl)
	_marl.set_physics_process(false)
	var refuge: Dictionary = _source["burrow_refuges"][0]
	var context := _record("companion_contexts", CONTEXT_ID)
	var anchor := _point(context["ground_anchors"][0])
	var bait := _point(context["ground_anchors"][1])
	var lure := bait - Vector2(0, _world.tile_size)
	# Initial test setup only. Eel starts at its authored home; all subsequent
	# actor approach, settling, lure and dodge motion uses real collision bodies.
	_player.global_position = lure
	_marl.configure(_world, _player, Callable(), {"callsign": "Marl"})
	_marl.global_position = _point(refuge["approach_point"])
	await physics_frame
	_test_daily_source_guarantee()
	_expect(_body_clear(_player) and _body_clear(_marl), "initial full footprints overlap terrain")
	_expect(_marl.begin_excavate_approach(_point(refuge["dig_point"])), "existing Excavate approach rejected source dig point")
	for tick in range(90):
		await physics_frame
		_marl.advance(STEP)
		_expect(_body_clear(_marl), "Excavate approach crossed terrain")
	_expect(_marl.excavate_target_reached(), "existing Excavate motor did not reach its stop envelope")
	_marl.cancel_excavate_action()
	# Ground Pin does not exist yet: prove only that the actual body can travel
	# from the existing dig stop to a planted footprint, without snapping.
	# The current fin gait extends 24.3px below the center (19 + 4 + 1.3).
	# Keep that silhouette clear too; collider clearance alone is insufficient.
	var planted := Vector2(anchor.x, anchor.y + _world.tile_size * 0.5 - 24.5)
	for tick in range(45):
		await physics_frame
		_move_toward(_marl, planted, 118.0 * STEP)
		_expect(_body_clear(_marl), "ground-anchor approach crossed terrain")
	_expect(_marl.global_position.distance_to(planted) < 1.0, "Marl could not physically reach planted footprint")
	_expect(_marl.test_move(_marl.global_transform, Vector2(0, 16)), "ground anchor has no floor within fin reach")
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		_expect(not _marl.test_move(_marl.global_transform, direction * 8), "ground anchor traps Marl")
	_marl.advance(0.0)
	await _test_live_lure_and_dodge(lure, bait, anchor)
	_world.free()
	_player.free()
	_marl.free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("LE07 source smoke: %s" % failure)
		quit(1)
		return
	print("LE07 source smoke passed: days=16 source_guaranteed=true full_bodies_clear=true excavate_approach=true grounded_contact=true eel_unchanged=true. No refuge/pin gameplay implemented.")
	quit(0)


func _test_daily_source_guarantee() -> void:
	var daily := DailyConditions.new()
	var before: Dictionary = _world._map_data.duplicate(true)
	for day in range(1, 17):
		daily.sync(_world.get_daily_conditions(), day)
		var selected := MaterialSelector.select_for_day(
			_world.map_id, _world.get_material_candidate_pools(), day, [], daily.current_ids()
		)
		_world.configure_material_candidates(selected, [])
		_world.configure_moving_hazards(daily.current_ids())
		_expect(selected.has("silt_hound_buried_titanium_01"), "daily selection lost LE05's guaranteed deposit")
		_expect(not selected.has("deep_cache_burrow_refuge_01"), "refuge became optional loot")
		_expect(_world._map_data == before, "day/seed selection mutated authored relationships")
		var eel := HostileController.new()
		eel.on_map_loaded(_world)
		_expect(str(eel.state_for(HOSTILE_ID).get("phase")) == "home", "fresh eligible day lacks its live threat")
	_world.configure_moving_hazards([])
	_world.set_visibility_upgrade_state("dive_light_1", true)


func _test_live_lure_and_dodge(lure: Vector2, bait: Vector2, anchor: Vector2) -> void:
	var controller := HostileController.new()
	controller.on_map_loaded(_world)
	var original := controller.state_for(HOSTILE_ID)
	var warnings := 0
	var lunges := 0
	var contacts := 0
	var contact_opening := false
	for tick in range(330):
		await physics_frame
		# Descend during the first recovery; dodge left only AFTER the second
		# lunge locks its target. Never assign hostile position or phase.
		var target := lure
		if tick >= 110:
			target = bait
		if lunges >= 2:
			target = anchor - Vector2(_world.tile_size, 0)
		_move_toward(_player, target, 180.0 * STEP)
		var event := controller.update(_world, _player.global_position, STEP)
		warnings += int(str(event.get("kind")) == "warning")
		lunges += int(str(event.get("kind")) == "lunge")
		contacts += int(str(event.get("kind")) == "contact")
		var state := controller.state_for(HOSTILE_ID)
		_expect(_body_clear(_player), "lure/dodge crossed terrain")
		_expect(_eel_clear(), "normal eel lunge intersects terrain")
		if str(state["phase"]) == "lunge" and _physical_contact():
			contact_opening = true
			print("LE07 live contact: warnings=%d lunges=%d diver_hits=%d eel=%s Marl=%s" % [warnings, lunges, contacts, state["position"], _marl.global_position])
			if "--capture-source-placement" in OS.get_cmdline_args():
				await _capture_source()
			break
	_expect(warnings == 2 and lunges == 2, "unchanged eel did not provide the two-lunge low opening")
	_expect(contacts == 0, "lure route required absorbing an eel hit")
	_expect(contact_opening, "eel stayed too high/far for Marl's physical footprint")
	var final := controller.state_for(HOSTILE_ID)
	for field in original:
		if field not in ["position", "phase", "phase_seconds", "lunge_target", "contact_consumed"]:
			_expect(final[field] == original[field], "eel definition mutated: %s" % field)
	controller.update(_world, Vector2.ZERO, STEP)
	for tick in range(240):
		controller.update(_world, Vector2.ZERO, STEP)
	_expect(str(controller.state_for(HOSTILE_ID)["phase"]) == "home", "eel cannot return normally after the opening")


func _body_clear(body: CharacterBody2D) -> bool:
	var collider := body.get_node("CollisionShape2D") as CollisionShape2D
	return _shape_clear(collider.shape, collider.global_transform, [body.get_rid()])


func _shape_clear(shape: Shape2D, transform: Transform2D, excluded: Array[RID] = []) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = transform
	query.collision_mask = 1
	query.collide_with_areas = false
	query.exclude = excluded
	return _world.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _eel_bounds() -> Rect2:
	var eel := _world.get_node("Markers/%s" % HOSTILE_ID) as Node2D
	var bounds := Rect2(eel.global_position, Vector2.ZERO)
	for name in ["Body", "Tail", "Fin"]:
		var polygon := eel.get_node(name) as Polygon2D
		for point in polygon.polygon:
			bounds = bounds.expand(polygon.to_global(point))
	return bounds


func _eel_clear() -> bool:
	# Conservative full visual-body bound: this hostile has no physics collider.
	# Its 24px damage radius is not evidence of physical grip reach.
	var bounds := _eel_bounds()
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	return _shape_clear(shape, Transform2D(0, bounds.get_center()), [_player.get_rid()])


func _physical_contact() -> bool:
	var size: Vector2 = _marl.get_node("CollisionShape2D").shape.size
	var bounds := Rect2(_marl.global_position - size * 0.5, size)
	var corners := PackedVector2Array([
		bounds.position, bounds.position + Vector2(size.x, 0),
		bounds.end, bounds.position + Vector2(0, size.y),
	])
	var eel := _world.get_node("Markers/%s" % HOSTILE_ID) as Node2D
	for name in ["Body", "Tail", "Fin"]:
		var polygon := eel.get_node(name) as Polygon2D
		var points := PackedVector2Array()
		for point in polygon.polygon:
			points.append(polygon.to_global(point))
		if not Geometry2D.intersect_polygons(corners, points).is_empty():
			return true
	return false


func _move_toward(body: CharacterBody2D, target: Vector2, distance: float) -> void:
	body.move_and_collide(body.global_position.direction_to(target) * minf(distance, body.global_position.distance_to(target)))


func _record(field: String, id: String) -> Dictionary:
	for record in _source[field]:
		if str(record["id"]) == id:
			return record
	return {}


func _point(value: Dictionary) -> Vector2:
	return Vector2(float(value["x"]) + 0.5, float(value["y"]) + 0.5) * _world.tile_size


func _capture_source() -> void:
	if DisplayServer.get_name() == "headless":
		_expect(false, "source capture requires non-headless rendering")
		return
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.position = Vector2(122, 77) * _world.tile_size
	camera.zoom = Vector2.ONE * 1.7
	camera.make_current()
	var refuge: Dictionary = _source["burrow_refuges"][0]
	var outline := Line2D.new()
	root.add_child(outline)
	outline.default_color = Color(1, 0.85, 0.4)
	outline.width = 1.5
	outline.z_index = 30
	var corner: Vector2 = Vector2(refuge["x"], refuge["y"]) * _world.tile_size
	var size: Vector2 = Vector2(refuge["w"], refuge["h"]) * _world.tile_size
	outline.points = PackedVector2Array([corner, corner + Vector2(size.x, 0), corner + size, corner + Vector2(0, size.y), corner])
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_PATH.get_base_dir()))
	_expect(root.get_texture().get_image().save_png(CAPTURE_PATH) == OK, "source placement capture failed")
	print("Source-only placement capture: ", CAPTURE_PATH)
	outline.free()
	camera.free()


func _expect(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
