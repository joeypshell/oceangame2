extends Node2D

const COLOR_WATER := Color(0.08, 0.72, 0.92, 1.0)
const COLOR_BASE := Color(0.95, 0.78, 0.48, 0.92)
const COLOR_MARKER := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_SALVAGE := Color(1.0, 0.80, 0.22, 1.0)
const COLOR_HAZARD := Color(1.0, 0.22, 0.34, 1.0)
const COLOR_DEBUG_ENTRY := Color(0.72, 1.0, 0.72, 0.88)
const COLOR_DEBUG_EXTRACTION := Color(1.0, 0.92, 0.52, 0.90)

const GreyboxAssetLookup := preload("res://scripts/world/greybox_asset_lookup.gd")
const GreyboxTerrainRenderer := preload("res://scripts/world/greybox_terrain_renderer.gd")
const GreyboxDebugRenderer := preload("res://scripts/world/greybox_debug_renderer.gd")
const GreyboxCollisionBuilder := preload("res://scripts/world/greybox_collision_builder.gd")
const GreyboxBackgroundRenderer := preload("res://scripts/world/greybox_background_renderer.gd")
const GreyboxPropRenderer := preload("res://scripts/world/greybox_prop_renderer.gd")
const GreyboxExtractionRenderer := preload("res://scripts/world/greybox_extraction_renderer.gd")
const GreyboxRouteMarkerRenderer := preload("res://scripts/world/greybox_route_marker_renderer.gd")
const GreyboxVisibilityZoneRenderer := preload("res://scripts/world/greybox_visibility_zone_renderer.gd")

const SALVAGE_TIER_SCORES := {
	"common": 100,
	"valuable": 300,
}

@export var map_path := "res://maps/cave_salvage_test_01.greybox.json"
@export var show_debug_overlay := false

var tile_size := 32
var map_tile_size := Vector2i.ZERO
var map_pixel_size := Vector2.ZERO
var map_id := ""
var map_version := ""
var spawn_position := Vector2.ZERO
var camera_tests: Array = []

var _built := false
var _map_data := {}
var _salvage_entities: Array = []
var _hazard_entities: Array = []
var _extraction_zones: Array = []
var _boat_entities: Array = []
var _world_connector_zones: Array = []
var _current_gate_zones: Array = []
var _visibility_zones: Array = []
var _progression_containers: Array = []
var _moving_hazards: Array = []
var _spawn_positions_by_id := {}
var _collected_salvage := {}
var _salvage_nodes_by_id := {}
var _container_nodes_by_id := {}
var _moving_hazard_nodes_by_id := {}
var _moving_hazard_positions_by_id := {}
var _visibility_zone_nodes_by_id := {}
var _visibility_zone_upgrade_states := {}
var _background_root: Node2D
var _solid_layer: TileMapLayer
var _terrain_layer: TileMapLayer
var _marker_root: Node2D
var _collision_root: Node2D
var _asset_lookup
var _terrain_renderer
var _debug_renderer
var _collision_builder
var _background_renderer
var _prop_renderer
var _extraction_renderer
var _route_marker_renderer
var _visibility_zone_renderer


func _ready() -> void:
	_asset_lookup = GreyboxAssetLookup.new()
	_terrain_renderer = GreyboxTerrainRenderer.new()
	_debug_renderer = GreyboxDebugRenderer.new()
	_collision_builder = GreyboxCollisionBuilder.new()
	_background_renderer = GreyboxBackgroundRenderer.new()
	_prop_renderer = GreyboxPropRenderer.new()
	_extraction_renderer = GreyboxExtractionRenderer.new()
	_route_marker_renderer = GreyboxRouteMarkerRenderer.new()
	_visibility_zone_renderer = GreyboxVisibilityZoneRenderer.new()
	load_greybox()


func load_greybox() -> void:
	if _built:
		return
	_built = true

	var map_data := _load_map_data()
	if map_data.is_empty():
		return

	_map_data = map_data
	map_id = str(map_data.get("id", "unknown_map"))
	map_version = _display_version(map_data.get("version", ""))
	tile_size = int(map_data["units"]["tile_size_px"])
	map_tile_size = Vector2i(int(map_data["units"]["width_tiles"]), int(map_data["units"]["height_tiles"]))
	map_pixel_size = Vector2(map_tile_size * tile_size)
	camera_tests = map_data.get("camera_tests", [])
	_salvage_entities = []
	_hazard_entities = []
	_extraction_zones = []
	_boat_entities = []
	_world_connector_zones = []
	_current_gate_zones = []
	_visibility_zones = []
	_progression_containers = []
	_moving_hazards = []
	_spawn_positions_by_id = {}
	_collected_salvage = {}
	_salvage_nodes_by_id = {}
	_container_nodes_by_id = {}
	_moving_hazard_nodes_by_id = {}
	_moving_hazard_positions_by_id = {}
	_visibility_zone_nodes_by_id = {}
	_visibility_zone_upgrade_states = {}

	_background_root = Node2D.new()
	_background_root.name = "BackgroundArt"
	add_child(_background_root)
	_build_background(map_data.get("background", []))

	_build_tilemap(map_data)
	_build_cave_terrain_layer(map_data.get("terrain", []))

	_collision_root = Node2D.new()
	_collision_root.name = "Collision"
	add_child(_collision_root)
	_build_collision(map_data.get("terrain", []))

	_marker_root = Node2D.new()
	_marker_root.name = "Markers"
	add_child(_marker_root)
	_build_zones(map_data.get("zones", []))
	_build_progression_containers(map_data.get("progression_containers", []))
	_build_moving_hazards(map_data.get("moving_hazards", []))
	_build_entities(map_data.get("entities", []))
	queue_redraw()


func get_map_label() -> String:
	if map_version.is_empty():
		return map_id
	return "%s v%s" % [map_id, map_version]


func _display_version(value) -> String:
	if typeof(value) == TYPE_FLOAT and is_equal_approx(value, float(int(value))):
		return str(int(value))
	return str(value)


func get_total_salvage_count() -> int:
	return _salvage_entities.size()


func get_salvage_centers() -> Array:
	var centers := []
	for entity in _salvage_entities:
		centers.append(_salvage_runtime_info(entity))
	return centers


func get_route_objectives() -> Array:
	var objectives := []
	for objective in _map_data.get("route_objectives", []):
		if typeof(objective) == TYPE_DICTIONARY:
			objectives.append(objective.duplicate(true))
	return objectives


func get_primary_route_objective_id() -> String:
	return str(_map_data.get("primary_route_objective_id", "")).strip_edges()


func get_next_dive_objective_prompts() -> Array:
	var prompts := []
	for prompt in _map_data.get("next_dive_objective_prompts", []):
		if typeof(prompt) == TYPE_DICTIONARY:
			prompts.append(prompt.duplicate(true))
	return prompts


func get_relay_follow_through_objectives() -> Array:
	var objectives := []
	for objective in _map_data.get("relay_follow_through_objectives", []):
		if typeof(objective) == TYPE_DICTIONARY:
			objectives.append(objective.duplicate(true))
	return objectives


func get_salvage_score(salvage_id: String) -> int:
	for entity in _salvage_entities:
		if str(entity.get("id", "salvage")) == salvage_id:
			return _salvage_score(entity)
	return int(SALVAGE_TIER_SCORES["common"])


func get_salvage_tier(salvage_id: String) -> String:
	for entity in _salvage_entities:
		if str(entity.get("id", "salvage")) == salvage_id:
			return str(entity.get("tier", "common"))
	return "common"


func is_salvage_collected(salvage_id: String) -> bool:
	return bool(_collected_salvage.get(salvage_id, false))


func get_hazard_centers() -> Array:
	var centers := []
	for entity in _hazard_entities:
		centers.append({
			"id": str(entity.get("id", "hazard")),
			"center": _entity_center(entity),
		})
	return centers


func get_marker_zone(marker_id: String) -> Dictionary:
	for zone in _map_data.get("zones", []):
		if zone.get("type", "") == "marker" and str(zone.get("id", "")) == marker_id:
			return zone
	return {}


func get_world_connectors() -> Array:
	var connectors := []
	for zone in _world_connector_zones:
		connectors.append(_world_connector_runtime_info(zone))
	return connectors


func get_current_gates() -> Array:
	var gates := []
	for zone in _current_gate_zones:
		gates.append(_current_gate_runtime_info(zone))
	return gates


func get_current_gate_at(position: Vector2) -> Dictionary:
	for zone in _current_gate_zones:
		if _rect_from_item(zone).has_point(position):
			return _current_gate_runtime_info(zone)
	return {}


func get_visibility_zones() -> Array:
	var zones := []
	for zone in _visibility_zones:
		zones.append(_visibility_zone_runtime_info(zone))
	return zones


func get_visibility_zone_at(position: Vector2) -> Dictionary:
	for zone in _visibility_zones:
		if _rect_from_item(zone).has_point(position):
			return _visibility_zone_runtime_info(zone)
	return {}


func set_visibility_upgrade_state(upgrade_id: String, active: bool) -> void:
	if upgrade_id.is_empty():
		return
	_visibility_zone_upgrade_states[upgrade_id] = active
	for zone in _visibility_zones:
		if str(zone.get("required_upgrade_id", "")) != upgrade_id:
			continue
		var zone_id := str(zone.get("id", "visibility_zone"))
		if not _visibility_zone_nodes_by_id.has(zone_id):
			continue
		_visibility_zone_renderer_helper().update_zone_readability(
			_visibility_zone_nodes_by_id[zone_id] as Polygon2D,
			zone,
			active
		)


func get_moving_hazards() -> Array:
	var hazards := []
	for hazard in _moving_hazards:
		hazards.append(_moving_hazard_runtime_info(hazard))
	return hazards


func set_moving_hazard_center(hazard_id: String, center: Vector2) -> void:
	_moving_hazard_positions_by_id[hazard_id] = center
	if not _moving_hazard_nodes_by_id.has(hazard_id):
		return
	var hazard_node := _moving_hazard_nodes_by_id[hazard_id] as Node2D
	hazard_node.global_position = center


func get_progression_containers() -> Array:
	var containers := []
	for container in _progression_containers:
		containers.append(_progression_container_runtime_info(container))
	return containers


func get_progression_container_at(position: Vector2) -> Dictionary:
	for container in _progression_containers:
		if _rect_from_item(container).has_point(position):
			return _progression_container_runtime_info(container)
	return {}


func set_progression_container_opened(container_id: String, opened: bool) -> void:
	if not _container_nodes_by_id.has(container_id):
		return
	var container_node := _container_nodes_by_id[container_id] as Node2D
	container_node.modulate.a = 0.42 if opened else 1.0


func get_world_connector_at(position: Vector2) -> Dictionary:
	for zone in _world_connector_zones:
		if _rect_from_item(zone).has_point(position):
			return _world_connector_runtime_info(zone)
	return {}


func get_entry_position(entry_id: String) -> Vector2:
	var id := entry_id.strip_edges()
	if not id.is_empty() and _spawn_positions_by_id.has(id):
		return _spawn_positions_by_id[id]
	return spawn_position


func get_nearest_hazard_within(position: Vector2, radius_px: float) -> Dictionary:
	var nearest := {}
	var nearest_distance := radius_px
	for entity in _hazard_entities:
		var center := _entity_center(entity)
		var distance := position.distance_to(center)
		if distance <= radius_px and (nearest.is_empty() or distance < nearest_distance):
			nearest = {
				"id": str(entity.get("id", "hazard")),
				"center": center,
				"distance": distance,
			}
			nearest_distance = distance
	for hazard in get_moving_hazards():
		var center := hazard["center"] as Vector2
		var distance := position.distance_to(center)
		if distance <= radius_px and (nearest.is_empty() or distance < nearest_distance):
			nearest = {
				"id": str(hazard.get("id", "moving_hazard")),
				"center": center,
				"distance": distance,
				"moving": true,
				"display_label": str(hazard.get("display_label", "")),
			}
			nearest_distance = distance
	return nearest


func get_hazard_near(position: Vector2, radius_px: float) -> String:
	for entity in _hazard_entities:
		if position.distance_to(_entity_center(entity)) <= radius_px:
			return str(entity.get("id", "hazard"))
	for hazard in get_moving_hazards():
		if position.distance_to(hazard["center"]) <= radius_px:
			return str(hazard.get("id", "moving_hazard"))
	return ""


func find_open_path(start_position: Vector2, target_position: Vector2) -> Array:
	var start := _position_to_cell(start_position)
	var target := _position_to_cell(target_position)
	var solid_cells := _solid_cells_from_terrain(_map_data.get("terrain", []))
	if solid_cells.has(start) or solid_cells.has(target):
		return []

	var queue: Array[Vector2i] = [start]
	var cursor := 0
	var came_from := {start: start}
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		if cell == target:
			break

		for neighbor in [
			cell + Vector2i.RIGHT,
			cell + Vector2i.LEFT,
			cell + Vector2i.DOWN,
			cell + Vector2i.UP,
		]:
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= map_tile_size.x or neighbor.y >= map_tile_size.y:
				continue
			if solid_cells.has(neighbor) or came_from.has(neighbor):
				continue
			came_from[neighbor] = cell
			queue.append(neighbor)

	if not came_from.has(target):
		return []

	var cells: Array[Vector2i] = []
	var current := target
	while current != start:
		cells.append(current)
		current = came_from[current]
	cells.append(start)
	cells.reverse()

	var path := []
	for cell in cells:
		path.append(_cell_center(cell))
	return path


func get_extraction_center() -> Vector2:
	if _extraction_zones.is_empty():
		if not _boat_entities.is_empty():
			return _boat_entry_center(_boat_entities[0])
		return spawn_position
	return _rect_center(_extraction_zones[0])


func collect_salvage_near(position: Vector2, radius_px: float) -> String:
	for entity in _salvage_entities:
		var salvage_id := str(entity.get("id", "salvage"))
		if _collected_salvage.get(salvage_id, false):
			continue
		if position.distance_to(_entity_center(entity)) > radius_px:
			continue
		if _salvage_interaction(entity) != "instant":
			continue

		return salvage_id if collect_salvage_by_id(salvage_id) else ""
	return ""


func get_available_salvage_near(position: Vector2, radius_px: float) -> Dictionary:
	for entity in _salvage_entities:
		var salvage_id := str(entity.get("id", "salvage"))
		if _collected_salvage.get(salvage_id, false):
			continue
		if position.distance_to(_entity_center(entity)) <= radius_px:
			return _salvage_runtime_info(entity)
	return {}


func collect_salvage_by_id(salvage_id: String) -> bool:
	for entity in _salvage_entities:
		if str(entity.get("id", "salvage")) != salvage_id:
			continue
		if _collected_salvage.get(salvage_id, false):
			return false

		_collected_salvage[salvage_id] = true
		if _salvage_nodes_by_id.has(salvage_id):
			var salvage_node := _salvage_nodes_by_id[salvage_id] as Node2D
			salvage_node.visible = false
		return true
	return false


func has_available_salvage_near(position: Vector2, radius_px: float) -> bool:
	for entity in _salvage_entities:
		var salvage_id := str(entity.get("id", "salvage"))
		if _collected_salvage.get(salvage_id, false):
			continue
		if position.distance_to(_entity_center(entity)) <= radius_px:
			return true
	return false


func _salvage_score(entity: Dictionary) -> int:
	var tier := str(entity.get("tier", "common"))
	return int(SALVAGE_TIER_SCORES.get(tier, SALVAGE_TIER_SCORES["common"]))


func _salvage_runtime_info(entity: Dictionary) -> Dictionary:
	return {
		"id": str(entity.get("id", "salvage")),
		"center": _entity_center(entity),
		"tier": str(entity.get("tier", "common")),
		"route_choice_id": str(entity.get("route_choice_id", "")),
		"validation_route": str(entity.get("validation_route", "")),
		"destination_payoff_id": str(entity.get("destination_payoff_id", "")),
		"destination_payoff_label": str(entity.get("destination_payoff_label", "")),
		"destination_payoff_connector_id": str(entity.get("destination_payoff_connector_id", "")),
		"has_route_order": entity.has("route_order"),
		"route_order": int(entity.get("route_order", 0)),
		"score": _salvage_score(entity),
		"interaction": _salvage_interaction(entity),
		"interaction_seconds": float(entity.get("interaction_seconds", 0.0)),
		"pry_stages": int(entity.get("pry_stages", 1)),
		"interaction_label": str(entity.get("interaction_label", "")),
	}


func _salvage_interaction(entity: Dictionary) -> String:
	return str(entity.get("interaction", "instant"))


func _world_connector_runtime_info(zone: Dictionary) -> Dictionary:
	return {
		"id": str(zone.get("id", "world_connector")),
		"center": _rect_center(zone),
		"rect": _rect_from_item(zone),
		"connector_label": str(zone.get("connector_label", "")),
		"destination_map_id": str(zone.get("destination_map_id", "")),
		"destination_map_path": str(zone.get("destination_map_path", "")),
		"destination_entry_id": str(zone.get("destination_entry_id", "")),
		"connector_direction": str(zone.get("connector_direction", "")),
	}


func _current_gate_runtime_info(zone: Dictionary) -> Dictionary:
	return {
		"id": str(zone.get("id", "current_gate")),
		"center": _rect_center(zone),
		"rect": _rect_from_item(zone),
		"current_gate_label": str(zone.get("current_gate_label", "")),
		"current_direction": str(zone.get("current_direction", "")),
		"current_strength": float(zone.get("current_strength", 1.0)),
		"required_upgrade_id": str(zone.get("required_upgrade_id", "")),
		"route_context": str(zone.get("route_context", "")),
	}


func _visibility_zone_runtime_info(zone: Dictionary) -> Dictionary:
	var upgraded := _visibility_zone_upgrade_active(zone)
	return {
		"id": str(zone.get("id", "visibility_zone")),
		"center": _rect_center(zone),
		"rect": _rect_from_item(zone),
		"visibility_level": str(zone.get("visibility_level", "dim")),
		"visibility_label": str(zone.get("visibility_label", "")),
		"required_upgrade_id": str(zone.get("required_upgrade_id", "")),
		"route_context": str(zone.get("route_context", "")),
		"readability_upgraded": upgraded,
		"overlay_alpha": _visibility_zone_renderer_helper().overlay_alpha(zone, upgraded),
		"visual_only": bool(zone.get("visual_only", false)),
	}


func _visibility_zone_upgrade_active(zone: Dictionary) -> bool:
	var upgrade_id := str(zone.get("required_upgrade_id", ""))
	return not upgrade_id.is_empty() and bool(_visibility_zone_upgrade_states.get(upgrade_id, false))


func _moving_hazard_runtime_info(hazard: Dictionary) -> Dictionary:
	var hazard_id := str(hazard.get("id", "moving_hazard"))
	var center: Vector2 = _moving_hazard_positions_by_id.get(hazard_id, _moving_hazard_initial_center(hazard))
	var path := []
	for point in hazard.get("path", []):
		path.append(_point_center(point))
	return {
		"id": hazard_id,
		"center": center,
		"kind": str(hazard.get("kind", "jellyfish")),
		"movement": str(hazard.get("movement", "")),
		"path": path,
		"speed_px_per_second": float(hazard.get("speed_tiles_per_second", 1.0)) * float(tile_size),
		"phase_offset_seconds": float(hazard.get("phase_offset_seconds", 0.0)),
		"route_context": str(hazard.get("route_context", "")),
		"display_label": str(hazard.get("display_label", "")),
	}


func _progression_container_runtime_info(container: Dictionary) -> Dictionary:
	return {
		"id": str(container.get("id", "progression_container")),
		"center": _rect_center(container),
		"rect": _rect_from_item(container),
		"container_type": str(container.get("container_type", "")),
		"display_label": str(container.get("display_label", "")),
		"interaction": str(container.get("interaction", "instant")),
		"reward_type": str(container.get("reward_type", "")),
		"reward_id": str(container.get("reward_id", "")),
		"reward_amount": int(container.get("reward_amount", 0)),
		"route_context": str(container.get("route_context", "")),
	}


func reset_salvage() -> void:
	_collected_salvage = {}
	for salvage_id in _salvage_nodes_by_id.keys():
		var salvage_node := _salvage_nodes_by_id[salvage_id] as Node2D
		salvage_node.visible = true


func restore_salvage(salvage_ids: Array) -> void:
	for salvage_id in salvage_ids:
		var id := str(salvage_id)
		_collected_salvage.erase(id)
		if _salvage_nodes_by_id.has(id):
			var salvage_node := _salvage_nodes_by_id[id] as Node2D
			salvage_node.visible = true


func is_inside_extraction(position: Vector2) -> bool:
	for zone in _extraction_zones:
		if _rect_from_item(zone).has_point(position):
			return true
	for boat in _boat_entities:
		if _entity_rect_from_item(boat).has_point(position):
			return true
	return false


func get_runtime_parity_report() -> Dictionary:
	return {
		"map_path": map_path,
		"map_id": map_id,
		"map_version": map_version,
		"tile_size_px": tile_size,
		"width_tiles": map_tile_size.x,
		"height_tiles": map_tile_size.y,
		"terrain_cells": _sorted_cell_arrays(_terrain_layer.get_used_cells()),
		"collision_rects": _collision_rects_from_runtime(),
		"collision_cells": _sorted_cell_arrays(_collision_cells_from_runtime()),
	}


func _draw() -> void:
	if map_pixel_size == Vector2.ZERO:
		return

	draw_rect(Rect2(Vector2.ZERO, map_pixel_size), COLOR_WATER)
	if not show_debug_overlay:
		return

	_debug_renderer_helper().draw_grid(self, map_pixel_size, tile_size)


func _load_map_data() -> Dictionary:
	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		push_error("Unable to open greybox map: %s" % map_path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Greybox map did not parse as a dictionary: %s" % map_path)
		return {}

	return parsed


func _build_tilemap(map_data: Dictionary) -> void:
	_solid_layer = _debug_renderer_helper().build_source_layer(map_data, tile_size, show_debug_overlay, COLOR_BASE)
	add_child(_solid_layer)


func _build_cave_terrain_layer(terrain_items: Array) -> void:
	_terrain_layer = _terrain_renderer_helper().build_layer(terrain_items, tile_size, map_tile_size, _asset_lookup_helper())
	add_child(_terrain_layer)


func _solid_cells_from_terrain(terrain_items: Array) -> Dictionary:
	return _terrain_renderer_helper().solid_cells_from_terrain(terrain_items)


func _build_collision(terrain_items: Array) -> void:
	_collision_builder_helper().build_collision(_collision_root, terrain_items, tile_size)


func _collision_rects_from_runtime() -> Array:
	return _collision_builder_helper().collision_rects_from_runtime(_collision_root, tile_size)


func _collision_cells_from_runtime() -> Array:
	return _collision_builder_helper().collision_cells_from_runtime(_collision_root, tile_size)


func _sorted_cell_arrays(cells: Array) -> Array:
	return _collision_builder_helper().sorted_cell_arrays(cells)


func _build_background(items: Array) -> void:
	_background_renderer_helper().build_background(_background_root, items, tile_size, _asset_lookup_helper())


func _build_zones(zones: Array) -> void:
	for zone in zones:
		if zone.get("type", "") == "base":
			_extraction_zones.append(zone)
			var base: Node2D = _extraction_renderer_helper().add_relay_extraction_prop(_marker_root, str(zone.get("id", "Base")), _rect_from_item(zone))
			if show_debug_overlay:
				_add_rect_outline(zone, "%sDebugOutline" % base.name, COLOR_DEBUG_EXTRACTION, 3.0, 22)
				_add_debug_label("EXTRACTION", _rect_from_item(zone).position + Vector2(6, 6), COLOR_DEBUG_EXTRACTION)
		elif zone.get("type", "") == "marker":
			if bool(zone.get("world_connector", false)):
				_world_connector_zones.append(zone)
			if bool(zone.get("current_gate", false)):
				_current_gate_zones.append(zone)
			if bool(zone.get("visibility_zone", false)):
				_visibility_zones.append(zone)
				var visibility_node: Polygon2D = _visibility_zone_renderer_helper().add_visibility_zone(_marker_root, zone, tile_size, show_debug_overlay, _debug_renderer_helper())
				_visibility_zone_nodes_by_id[str(zone.get("id", "visibility_zone"))] = visibility_node
			else:
				_route_marker_renderer_helper().add_route_marker(_marker_root, zone, tile_size, show_debug_overlay, _debug_renderer_helper())


func _build_progression_containers(containers: Array) -> void:
	for container in containers:
		_progression_containers.append(container)
		var container_id := str(container.get("id", "ProgressionContainer"))
		var rect := _rect_from_item(container)
		var container_node := _add_chest_marker(container_id, rect)
		_container_nodes_by_id[container_id] = container_node
		if show_debug_overlay:
			_add_rect_outline(container, "%sDebugOutline" % container_id, Color(0.84, 0.55, 1.0, 0.65), 3.0, 23)
			_add_debug_label("CHEST", rect.position + Vector2(6, -18), Color(0.84, 0.55, 1.0, 0.9))


func _build_moving_hazards(hazards: Array) -> void:
	for hazard in hazards:
		_moving_hazards.append(hazard)
		var hazard_id := str(hazard.get("id", "MovingHazard"))
		var center := _moving_hazard_initial_center(hazard)
		var hazard_node: Node2D = _prop_renderer_helper().add_hazard_prop(
			_marker_root,
			hazard_id,
			center,
			str(hazard.get("kind", "jellyfish")),
			_asset_lookup_helper()
		)
		hazard_node.z_index = 12
		_moving_hazard_nodes_by_id[hazard_id] = hazard_node
		_moving_hazard_positions_by_id[hazard_id] = center
		_add_moving_hazard_path_marker(hazard_id, hazard.get("path", []))
		if show_debug_overlay:
			_add_debug_label("MOVING HAZARD", center + Vector2(18, -22), Color(1.0, 0.58, 0.69, 0.9))


func _build_entities(entities: Array) -> void:
	var has_boat_spawn := _has_entity_type(entities, "boat_spawn")
	for entity in entities:
		var entity_type := str(entity.get("type", ""))
		var center := _entity_center(entity)

		if entity_type == "boat_spawn":
			_boat_entities.append(entity)
			spawn_position = _boat_entry_center(entity)
			_spawn_positions_by_id[str(entity.get("id", "boat_spawn"))] = spawn_position
			var boat_rect := _entity_rect_from_item(entity)
			var boat_entry_local := _boat_entry_center(entity) - boat_rect.position
			var boat_node: Node2D = _extraction_renderer_helper().add_boat_marker(
				_marker_root,
				str(entity.get("id", "BoatSpawn")),
				boat_rect,
				boat_entry_local,
				_asset_lookup_helper()
			)
			if show_debug_overlay:
				var debug_rect := _add_local_line(boat_node, "DebugBoatExtractionRect", _rect_outline_points(boat_rect.size), COLOR_DEBUG_EXTRACTION, 3.0)
				debug_rect.z_index = 22
				var debug_entry := _add_local_polygon(boat_node, "DebugEntryCell", _diamond_points(14.0), COLOR_DEBUG_ENTRY)
				debug_entry.position = boat_entry_local
				debug_entry.z_index = 23
				_add_debug_label("BOAT / RETURN", boat_rect.position + Vector2(6, boat_rect.size.y + 8), COLOR_DEBUG_EXTRACTION)
				_add_debug_label("ENTRY", boat_rect.position + boat_entry_local + Vector2(18, -20), COLOR_DEBUG_ENTRY)
		elif entity_type == "spawn":
			_spawn_positions_by_id[str(entity.get("id", "spawn"))] = center
			if has_boat_spawn:
				var legacy_marker := _add_marker("LegacyPlayerStart", center, COLOR_MARKER, 18.0)
				if show_debug_overlay:
					legacy_marker.color = COLOR_DEBUG_ENTRY
					_add_debug_label("LEGACY SPAWN", center + Vector2(18, -22), COLOR_DEBUG_ENTRY)
				continue
			spawn_position = center
			var spawn_in_extraction := is_inside_extraction(center)
			var spawn_marker: Node2D
			if spawn_in_extraction:
				spawn_marker = _extraction_renderer_helper().add_relay_spawn_cue(_marker_root, "PlayerStartRelayCue", center)
			else:
				spawn_marker = _add_marker("PlayerStart", center, COLOR_MARKER, 28.0)
			if show_debug_overlay:
				if spawn_in_extraction:
					var debug_spawn := _add_diamond("PlayerStartDebug", center, COLOR_DEBUG_ENTRY, 16.0)
					debug_spawn.z_index = 23
				elif spawn_marker is Polygon2D:
					(spawn_marker as Polygon2D).color = COLOR_DEBUG_ENTRY
				_add_debug_label("SPAWN", center + Vector2(18, -22), COLOR_DEBUG_ENTRY)
		elif entity_type == "salvage":
			_salvage_entities.append(entity)
			var salvage_id := str(entity.get("id", "Salvage"))
			var salvage_node: Node2D = _prop_renderer_helper().add_salvage_prop(
				_marker_root,
				salvage_id,
				center,
				str(entity.get("kind", "crate")),
				str(entity.get("tier", "common")),
				_salvage_interaction(entity),
				_asset_lookup_helper()
			)
			_salvage_nodes_by_id[salvage_id] = salvage_node
			if show_debug_overlay:
				var debug_marker := _add_local_polygon(salvage_node, "DebugDiamond", _diamond_points(16.0), Color(1.0, 0.80, 0.22, 0.35))
				debug_marker.z_index = 20
				_add_debug_label("SALVAGE", center + Vector2(18, -22), COLOR_SALVAGE)
		elif entity_type == "hazard":
			_hazard_entities.append(entity)
			var hazard_id := str(entity.get("id", "Hazard"))
			var hazard_node: Node2D = _prop_renderer_helper().add_hazard_prop(
				_marker_root,
				hazard_id,
				center,
				str(entity.get("kind", "mine")),
				_asset_lookup_helper()
			)
			if show_debug_overlay:
				var debug_marker := _add_local_polygon(hazard_node, "DebugMarker", _rect_points(Vector2(18, 18)), Color(1.0, 0.22, 0.34, 0.35))
				debug_marker.z_index = 20
				_add_debug_label("HAZARD", center + Vector2(18, -22), COLOR_HAZARD)


func _has_entity_type(entities: Array, entity_type: String) -> bool:
	for entity in entities:
		if str(entity.get("type", "")) == entity_type:
			return true
	return false


func _terrain_renderer_helper():
	if _terrain_renderer == null:
		_terrain_renderer = GreyboxTerrainRenderer.new()
	return _terrain_renderer


func _debug_renderer_helper():
	if _debug_renderer == null:
		_debug_renderer = GreyboxDebugRenderer.new()
	return _debug_renderer


func _collision_builder_helper():
	if _collision_builder == null:
		_collision_builder = GreyboxCollisionBuilder.new()
	return _collision_builder


func _background_renderer_helper():
	if _background_renderer == null:
		_background_renderer = GreyboxBackgroundRenderer.new()
	return _background_renderer


func _prop_renderer_helper():
	if _prop_renderer == null:
		_prop_renderer = GreyboxPropRenderer.new()
	return _prop_renderer


func _extraction_renderer_helper():
	if _extraction_renderer == null:
		_extraction_renderer = GreyboxExtractionRenderer.new()
	return _extraction_renderer


func _route_marker_renderer_helper():
	if _route_marker_renderer == null:
		_route_marker_renderer = GreyboxRouteMarkerRenderer.new()
	return _route_marker_renderer


func _visibility_zone_renderer_helper():
	if _visibility_zone_renderer == null:
		_visibility_zone_renderer = GreyboxVisibilityZoneRenderer.new()
	return _visibility_zone_renderer


func _asset_lookup_helper():
	if _asset_lookup == null:
		_asset_lookup = GreyboxAssetLookup.new()
	return _asset_lookup


func _add_marker(marker_name: String, center: Vector2, color: Color, radius: float) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = marker_name
	poly.position = center
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(radius, radius),
		Vector2(-radius, radius),
	])
	_marker_root.add_child(poly)
	return poly


func _add_diamond(marker_name: String, center: Vector2, color: Color, radius: float) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = marker_name
	poly.position = center
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius, 0),
		Vector2(0, radius),
		Vector2(-radius, 0),
	])
	_marker_root.add_child(poly)
	return poly


func _add_chest_marker(marker_name: String, rect: Rect2) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.position = rect.position + rect.size * 0.5
	root.z_index = 16
	_marker_root.add_child(root)

	var body_size := Vector2(maxf(20.0, rect.size.x * 0.7), maxf(14.0, rect.size.y * 0.46))
	var body := _add_local_polygon(root, "ChestBody", _rect_points(body_size), Color(0.57, 0.23, 0.80, 0.92))
	body.position.y = body_size.y * 0.18
	body.z_index = 1

	var lid_size := Vector2(body_size.x * 0.88, maxf(8.0, body_size.y * 0.5))
	var lid := _add_local_polygon(root, "ChestLid", _rect_points(lid_size), Color(0.82, 0.55, 1.0, 0.95))
	lid.position.y = -body_size.y * 0.36
	lid.z_index = 2

	var latch := _add_local_polygon(root, "ChestLatch", _diamond_points(minf(7.0, body_size.y * 0.34)), Color(1.0, 0.86, 0.28, 0.98))
	latch.z_index = 3
	return root


func _add_moving_hazard_path_marker(marker_name: String, path: Array) -> void:
	if path.size() < 2:
		return
	var points := PackedVector2Array()
	for point in path:
		points.append(_point_center(point))
	var line := _add_local_line(_marker_root, "%sPatrolPath" % marker_name, points, Color(1.0, 0.58, 0.69, 0.42), 3.0)
	line.z_index = 6


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


func _rect_outline_points(size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0),
		size,
		Vector2(0, size.y),
		Vector2.ZERO,
	])


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


func _rect_center(item: Dictionary) -> Vector2:
	return Vector2(
		(float(item["x"]) + float(item["w"]) * 0.5) * tile_size,
		(float(item["y"]) + float(item["h"]) * 0.5) * tile_size
	)


func _point_center(item: Dictionary) -> Vector2:
	return Vector2((float(item["x"]) + 0.5) * tile_size, (float(item["y"]) + 0.5) * tile_size)


func _moving_hazard_initial_center(hazard: Dictionary) -> Vector2:
	return _point_center({"x": int(hazard.get("x", 0)), "y": int(hazard.get("y", 0))})


func _rect_size(item: Dictionary) -> Vector2:
	return Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)


func _add_rect_outline(item: Dictionary, outline_name: String, color: Color, width: float, z_index: int) -> Line2D:
	return _debug_renderer_helper().add_rect_outline(_marker_root, _rect_from_item(item), outline_name, color, width, z_index)


func _add_debug_label(label_text: String, position: Vector2, color: Color) -> Label:
	return _debug_renderer_helper().add_debug_label(_marker_root, label_text, position, color)


func _rect_from_item(item: Dictionary) -> Rect2:
	return Rect2(
		Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size),
		_rect_size(item)
	)


func _entity_rect_from_item(item: Dictionary) -> Rect2:
	return Rect2(
		Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size),
		Vector2(
			float(item.get("w", 1)) * tile_size,
			float(item.get("h", 1)) * tile_size
		)
	)


func _entity_center(item: Dictionary) -> Vector2:
	return Vector2((float(item["x"]) + 0.5) * tile_size, (float(item["y"]) + 0.5) * tile_size)


func _position_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor(position.x / tile_size)), 0, map_tile_size.x - 1),
		clampi(int(floor(position.y / tile_size)), 0, map_tile_size.y - 1)
	)


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) * tile_size, (float(cell.y) + 0.5) * tile_size)


func _boat_entry_center(item: Dictionary) -> Vector2:
	return Vector2(
		(float(item.get("entry_x", item["x"])) + 0.5) * tile_size,
		(float(item.get("entry_y", item["y"])) + 0.5) * tile_size
	)
