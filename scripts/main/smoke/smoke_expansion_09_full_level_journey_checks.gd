extends "res://scripts/main/smoke/smoke_check_base.gd"

const FullLevelNavigation := preload("res://scripts/main/smoke/smoke_full_level_navigation.gd")
const SessionProgression := preload("res://scripts/main/session_progression.gd")
const ExpeditionDayPresentation := preload("res://scripts/main/expedition_day_presentation.gd")

const MAP_ID := "production_level_01"
const ENTRY_TARGET_ID := "salvage_entry_shaft"
const MATERIAL_TARGET_ID := "material_rubber_entry"
const BOAT_ENTRY_ID := "surface_boat_entry"
const EXPECTED_SIZE_TILES := Vector2i(158, 161)
const ANCHOR_IDS := [
	"full_level_upper_left_anchor",
	"full_level_lower_right_anchor",
	"full_level_lower_left_anchor",
]
const PASSABLE_CAPABILITIES := ["propulsion_fins"]
const FIXED_DELTA := 1.0 / 60.0
const ENDPOINT_TOLERANCE_PX := 8.0
const PATH_LOOKAHEAD_POINTS := 3
const PATH_PROGRESS_WINDOW := 8
const MAX_STEP_DISTANCE_PX := 12.0
const MAX_STALL_STEPS := 180
const SIMULATION_STEPS_PER_FRAME := 12

var _navigation
var _simulation_seconds := 0.0
var _connector_prompt_count := 0
var _starting_health := 0


func _smoke_expansion_09_full_level_journey_and_quit() -> void:
	if not _require(_world.map_id == MAP_ID, "loaded unexpected map %s" % _world.map_id):
		return
	if not _require(
		_world.map_tile_size == EXPECTED_SIZE_TILES,
		"map dimensions drifted to %s" % str(_world.map_tile_size)
	):
		return
	if not _require(_world.get_world_connectors().is_empty(), "candidate contains world connectors"):
		return

	var collision := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not _require(
		collision != null and collision.shape is RectangleShape2D and not collision.disabled,
		"player collision is missing or disabled"
	):
		return
	var body_size: Vector2 = (collision.shape as RectangleShape2D).size
	var boat_position: Vector2 = _world.get_entry_position(BOAT_ENTRY_ID)
	if not _require(
		_player.global_position.is_equal_approx(boat_position)
		and _world.is_inside_boat(_player.global_position),
		"journey did not start at the authored top boat"
	):
		return

	var entry_target := _salvage_by_id(ENTRY_TARGET_ID)
	var anchors := _anchor_centers()
	if not _require(not entry_target.is_empty() and anchors.size() == ANCHOR_IDS.size(), "journey source ids are incomplete"):
		return

	var blocked_navigation = FullLevelNavigation.new()
	blocked_navigation.build(_world, body_size, SALVAGE_COLLECTION_RADIUS)
	if not _require(
		blocked_navigation.path_between(boat_position, anchors["full_level_lower_right_anchor"]).is_empty(),
		"fresh navigation found a bypass around the lower-right current seams"
	):
		return
	if not _prepare_propulsion_fins():
		_fail("could not prepare recipe-built fins for the gated lower-right sortie")
		return
	var profile_before := _profile_snapshot()
	var initial_day: Dictionary = _main._expedition_day_state.report()
	_starting_health = int(_main._player_health.report().get("current_health", 0))
	_main._player_health.current_health = maxi(1, _starting_health - 1)
	_process(0.0)
	if not _require(
		int(_main._player_health.current_health) == _starting_health,
		"authored full-level boat did not restore player health"
	):
		return
	if not _prepare_existing_tank_configuration():
		return

	_player.set_physics_process(false)
	_main.set_process(false)
	await get_tree().physics_frame
	_navigation = FullLevelNavigation.new()
	var nav_report: Dictionary = _navigation.build(
		_world, body_size, SALVAGE_COLLECTION_RADIUS, "", PASSABLE_CAPABILITIES
	)

	var route_reports := []
	var upper_report: Dictionary = await _run_sortie(
		ANCHOR_IDS[0],
		[entry_target["center"], anchors[ANCHOR_IDS[0]], boat_position],
		1
	)
	if upper_report.is_empty():
		return
	route_reports.append(upper_report)
	_print_route_report(upper_report)
	if not _require(
		_world.is_salvage_collected(ENTRY_TARGET_ID)
		and _banked_salvage_ids.has(ENTRY_TARGET_ID),
		"transformed entry target was not collected and banked normally"
	):
		return

	var material_target := _material_candidate_by_id(MATERIAL_TARGET_ID)
	var active_material_ids: Array = _world.get_material_candidate_report().get("active_ids", [])
	if not _require(
		not material_target.is_empty() and active_material_ids.has(MATERIAL_TARGET_ID),
		"deterministic full-level material target is missing or inactive"
	):
		return
	var material_id := str(material_target.get("material_id", ""))
	var material_quantity := int(material_target.get("material_quantity", 0))
	var profile = _main._anomaly_survey.profile_state()
	var material_before: int = int(profile.material_quantity(material_id))

	for index in range(1, ANCHOR_IDS.size()):
		var anchor_id: String = ANCHOR_IDS[index]
		var destinations: Array = [anchors[anchor_id], boat_position]
		_navigation = FullLevelNavigation.new()
		if index == 1:
			_navigation.build(
				_world,
				body_size,
				SALVAGE_COLLECTION_RADIUS,
				MATERIAL_TARGET_ID,
				PASSABLE_CAPABILITIES
			)
			destinations = [material_target["center"], anchors[anchor_id], boat_position]
		else:
			_navigation.build(
				_world, body_size, SALVAGE_COLLECTION_RADIUS, "", PASSABLE_CAPABILITIES
			)
		var report: Dictionary = await _run_sortie(
			anchor_id,
			destinations,
			index + 1
		)
		if report.is_empty():
			return
		route_reports.append(report)
		_print_route_report(report)
		if index == 1 and not _require(
			_main._material_runtime.held_count() == 0
			and profile.material_quantity(material_id) == material_before + material_quantity
			and _main._expedition_day_state.material_depleted_ids(MAP_ID).has(MATERIAL_TARGET_ID),
			"second return did not automatically commit full-level material cargo"
		):
			return

	var day_report: Dictionary = _main._expedition_day_state.report()
	var health_report: Dictionary = _main._player_health.report()
	var profile_after := _profile_snapshot()
	if not _require(
		str(_world.map_id) == MAP_ID
		and int(day_report.get("connector_transition_count", -1)) == 0
		and _connector_prompt_count == 0,
		"map or connector state changed during the journey"
	):
		return
	if not _require(
		int(day_report.get("day_number", 0)) == int(initial_day.get("day_number", -1))
		and str(day_report.get("phase", "")) == "active"
		and int(day_report.get("sortie_count", 0)) == ANCHOR_IDS.size()
		and float(day_report.get("daylight_remaining_seconds", 0.0)) < float(initial_day.get("daylight_remaining_seconds", 0.0)),
		"daylight, day, or sortie semantics drifted"
	):
		return
	if not _require(
		int(health_report.get("current_health", -1)) == _starting_health
		and not bool(health_report.get("defeated", true))
		and not _run_failed,
		"health or failure state changed during safe traversal"
	):
		return
	if not _require(
		_held_salvage == 0
		and _main._material_runtime.held_count() == 0
		and _banked_salvage >= 1
		and int(day_report.get("banked_salvage", 0)) == _banked_salvage
		and int(day_report.get("banked_score", 0)) == _banked_score,
		"cargo or bank totals did not follow normal boat semantics"
	):
		return
	var expected_profile_after: Dictionary = profile_before.duplicate(true)
	var expected_inventory: Dictionary = (expected_profile_after.get("material_inventory", {}) as Dictionary).duplicate(true)
	expected_inventory[material_id] = int(expected_inventory.get(material_id, 0)) + material_quantity
	expected_profile_after["material_inventory"] = expected_inventory
	if not _require(profile_after == expected_profile_after, "durable profile changed beyond the expected material deposit"):
		return
	var night_request: Dictionary = ExpeditionDayPresentation.try_request_voluntary_end(_main)
	if not _require(
		bool(night_request.get("requested", false))
		and str(night_request.get("reason", "")) == "requested",
		"night request remained blocked after automatic full-level offload: %s" % str(night_request)
	):
		return

	print("Expansion 09 full-level journey smoke passed: map=%s dimensions=%dx%d sectors=%s routes=%s material=%s:%s+%d auto_offload=true night=requested elapsed=%.1fs tank=%s capacity=%.1fs oxygen=%.1fs sorties=%d connectors=%d prompts=%d held=%d banked=%d score=%d profile=fins_fixture_plus_expected_material day=%d daylight=%.1fs health=%d/%d boat_health_refill=true regional_current=fins no_fins_bypass=false collision=active movement=continuous_no_teleport nav=%s." % [
		_world.map_id,
		_world.map_tile_size.x,
		_world.map_tile_size.y,
		",".join(PackedStringArray(ANCHOR_IDS)),
		_route_summary(route_reports),
		MATERIAL_TARGET_ID,
		material_id,
		material_quantity,
		_simulation_seconds,
		SessionProgression.OXYGEN_TANK_UPGRADE_ID,
		_oxygen_capacity_seconds(),
		_oxygen_seconds,
		int(day_report.get("sortie_count", 0)),
		int(day_report.get("connector_transition_count", 0)),
		_connector_prompt_count,
		_held_salvage,
		_banked_salvage,
		_banked_score,
		int(day_report.get("day_number", 0)),
		float(day_report.get("daylight_remaining_seconds", 0.0)),
		int(health_report.get("current_health", 0)),
		int(health_report.get("max_health", 0)),
		str(nav_report),
	])
	get_tree().quit(0)


func _run_sortie(anchor_id: String, destinations: Array, expected_sortie: int) -> Dictionary:
	var planned_distance := 0.0
	var actual_distance := 0.0
	var elapsed_seconds := 0.0
	var minimum_oxygen := _oxygen_seconds
	for destination in destinations:
		var path: PackedVector2Array = _navigation.path_between(_player.global_position, destination)
		if not _require(path.size() > 1, "%s route has no collision-clear path to %s" % [anchor_id, str(destination)]):
			return {}
		planned_distance += _navigation.path_distance(path)
		var leg: Dictionary = await _drive_path(anchor_id, path)
		if leg.is_empty():
			return {}
		actual_distance += float(leg["distance_px"])
		elapsed_seconds += float(leg["elapsed_seconds"])
		minimum_oxygen = minf(minimum_oxygen, float(leg["minimum_oxygen"]))
		_player.reset_motion()
		_process(0.0)

	var final_destination: Vector2 = destinations[destinations.size() - 1]
	if not _require(_player.global_position.distance_to(final_destination) <= ENDPOINT_TOLERANCE_PX, "%s missed its final endpoint" % anchor_id):
		return {}
	if not _require(
		_world.is_inside_boat(_player.global_position)
		and int(_main._expedition_day_state.sortie_count) == expected_sortie,
		"%s did not finish through normal boat return" % anchor_id
	):
		return {}
	if not await _refill_at_boat():
		return {}
	return {
		"id": anchor_id,
		"planned_px": planned_distance,
		"actual_px": actual_distance,
		"elapsed_seconds": elapsed_seconds,
		"minimum_oxygen": minimum_oxygen,
		"return_oxygen": _oxygen_seconds,
	}


func _drive_path(route_id: String, path: PackedVector2Array) -> Dictionary:
	var path_index := 0
	var distance_px := 0.0
	var elapsed_seconds := 0.0
	var minimum_oxygen := _oxygen_seconds
	var stall_steps := 0
	var simulation_steps := 0
	var planned_distance: float = _navigation.path_distance(path)
	var maximum_seconds := planned_distance / maxf(1.0, float(_player.swim_speed)) * 1.6 + 10.0
	while _player.global_position.distance_to(path[path.size() - 1]) > ENDPOINT_TOLERANCE_PX:
		path_index = _closest_forward_path_index(path, path_index)
		var target_index := mini(path.size() - 1, path_index + PATH_LOOKAHEAD_POINTS)
		var waypoint := path[target_index]
		var before: Vector2 = _player.global_position
		_player.swim_in_direction(before.direction_to(waypoint), FIXED_DELTA)
		_process(FIXED_DELTA)
		var moved := before.distance_to(_player.global_position)
		if moved > MAX_STEP_DISTANCE_PX:
			_fail("%s detected a %.1fpx runtime reposition from %s to %s note=%s" % [
				route_id,
				moved,
				str(before),
				str(_player.global_position),
				_last_status_note,
			])
			return {}
		distance_px += moved
		elapsed_seconds += FIXED_DELTA
		_simulation_seconds += FIXED_DELTA
		minimum_oxygen = minf(minimum_oxygen, _oxygen_seconds)
		if not _runtime_state_is_valid(route_id):
			return {}
		stall_steps = stall_steps + 1 if moved < 0.01 else 0
		if stall_steps > MAX_STALL_STEPS:
			_fail("%s stalled near %s with collision active" % [route_id, str(waypoint)])
			return {}
		if elapsed_seconds > maximum_seconds:
			_fail("%s exceeded %.1fs at path point %d/%d position=%s oxygen=%.1f" % [
				route_id,
				maximum_seconds,
				path_index,
				path.size(),
				str(_player.global_position),
				_oxygen_seconds,
			])
			return {}
		simulation_steps += 1
		if simulation_steps % SIMULATION_STEPS_PER_FRAME == 0:
			await get_tree().physics_frame
	return {
		"distance_px": distance_px,
		"elapsed_seconds": elapsed_seconds,
		"minimum_oxygen": minimum_oxygen,
	}


func _closest_forward_path_index(path: PackedVector2Array, current_index: int) -> int:
	var closest_index := current_index
	var closest_distance: float = _player.global_position.distance_squared_to(path[current_index])
	var last_index := mini(path.size() - 1, current_index + PATH_PROGRESS_WINDOW)
	for index in range(current_index + 1, last_index + 1):
		var distance: float = _player.global_position.distance_squared_to(path[index])
		if distance < closest_distance:
			closest_distance = distance
			closest_index = index
	return closest_index


func _runtime_state_is_valid(route_id: String) -> bool:
	if str(_world.map_id) != MAP_ID:
		_fail("%s changed maps to %s" % [route_id, _world.map_id])
		return false
	if int(_main._expedition_day_state.connector_transition_count) != 0:
		_fail("%s recorded a connector transition" % route_id)
		return false
	var connector_prompt: String = _main._world_connector_prompt()
	if not connector_prompt.is_empty():
		_connector_prompt_count += 1
		_fail("%s exposed connector prompt %s" % [route_id, connector_prompt])
		return false
	if _run_failed or str(_main._expedition_day_state.phase) != "active":
		_fail("%s entered failure or night state" % route_id)
		return false
	if int(_main._player_health.current_health) != _starting_health:
		_fail("%s took hostile damage" % route_id)
		return false
	return true


func _refill_at_boat() -> bool:
	var capacity := _oxygen_capacity_seconds()
	var steps := 0
	while _oxygen_seconds < capacity - 0.01:
		_process(FIXED_DELTA)
		_simulation_seconds += FIXED_DELTA
		steps += 1
		if not _runtime_state_is_valid("boat_refill"):
			return false
		if steps % SIMULATION_STEPS_PER_FRAME == 0:
			await get_tree().physics_frame
		if steps > 600:
			_fail("boat oxygen refill did not reach %.1f" % capacity)
			return false
	return true


func _prepare_existing_tank_configuration() -> bool:
	var wallet_before := _session_wallet()
	_main._progression_runtime.grant_wallet_reward(SessionProgression.OXYGEN_TANK_UPGRADE_COST)
	if not _require(_try_purchase_oxygen_tank_upgrade(), "could not purchase the existing oxygen tank configuration"):
		return false
	if not _require(
		_has_oxygen_tank_upgrade()
		and is_equal_approx(_oxygen_capacity_seconds(), OXYGEN_MAX_SECONDS + SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS)
		and _session_wallet() == wallet_before,
		"oxygen tank capacity or exact-cost transaction drifted"
	):
		return false
	return true


func _anchor_centers() -> Dictionary:
	var centers := {}
	for anchor_id in ANCHOR_IDS:
		var center: Vector2 = FullLevelNavigation.new().marker_center(_world, anchor_id)
		if center.x >= 0.0:
			centers[anchor_id] = center
	return centers


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _material_candidate_by_id(candidate_id: String) -> Dictionary:
	for candidate in _world.get_material_candidates():
		if str(candidate.get("id", "")) == candidate_id:
			return candidate
	return {}


func _profile_snapshot() -> Dictionary:
	var report: Dictionary = _main._anomaly_survey.profile_state().report()
	return {
		"completed_discoveries": report.get("completed_discoveries", []).duplicate(),
		"unlocked_capabilities": report.get("unlocked_capabilities", []).duplicate(),
		"material_inventory": (report.get("material_inventory", {}) as Dictionary).duplicate(true),
		"completed_projects": report.get("completed_projects", []).duplicate(),
	}


func _route_summary(route_reports: Array) -> String:
	var values := PackedStringArray()
	for report in route_reports:
		values.append("%s:%.0f/%.0fpx@%.1fs,o2=%.1f" % [
			str(report["id"]),
			float(report["planned_px"]),
			float(report["actual_px"]),
			float(report["elapsed_seconds"]),
			float(report["minimum_oxygen"]),
		])
	return ";".join(values)


func _print_route_report(report: Dictionary) -> void:
	print("Expansion 09 journey route: sector=%s planned=%.1fpx actual=%.1fpx elapsed=%.1fs minimum_oxygen=%.1f return_oxygen=%.1f." % [
		str(report["id"]),
		float(report["planned_px"]),
		float(report["actual_px"]),
		float(report["elapsed_seconds"]),
		float(report["minimum_oxygen"]),
		float(report["return_oxygen"]),
	])


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("Expansion 09 full-level journey smoke failed: %s." % message)
	get_tree().quit(1)
