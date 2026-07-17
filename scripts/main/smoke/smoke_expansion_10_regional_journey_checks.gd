extends "res://scripts/main/smoke/smoke_check_base.gd"

const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const FullLevelNavigation := preload("res://scripts/main/smoke/smoke_full_level_navigation.gd")
const ScannerProjectJourney := preload("res://scripts/main/smoke/smoke_scanner_project_journey.gd")
const ScannerSmokePose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")

const MAP_ID := "production_level_01"
const BOAT_ENTRY_ID := "surface_boat_entry"
const ROUTE_ID := "east_current_signal_reef_route"
const PROMISE_GATE_ID := "upper_right_current_pocket_gate"
const REGIONAL_GATE_IDS := ["lower_right_west_current_gate", "lower_right_east_current_gate"]
const LANDMARK_ID := "lower_right_signal_reef_landmark"
const SURVEY_TARGET_ID := "lower_right_signal_reef_survey"
const DISCOVERY_ID := "lower_right_signal_reef_discovery"
const BLUEPRINT_CONTAINER_ID := "lower_loop_upgrade_chest"
const PASSABLE_CAPABILITIES := [ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID]
const FIXED_DELTA := 1.0 / 60.0
const ENDPOINT_TOLERANCE_PX := 8.0
const PATH_LOOKAHEAD_POINTS := 3
const PATH_PROGRESS_WINDOW := 8
const MAX_STEP_DISTANCE_PX := 12.0
const MAX_STALL_STEPS := 180
const SIMULATION_STEPS_PER_FRAME := 12
const BLOCKED_SWIM_SECONDS := 2.0

var _body_size := Vector2.ZERO
var _starting_health := 0
var _simulation_seconds := 0.0
var _distance_px := 0.0
var _minimum_oxygen := 0.0
var _connector_prompt_count := 0
var _traversed_gate_ids: Array[String] = []


func _smoke_expansion_10_regional_journey_and_quit() -> void:
	if not await run_to_committed_signal_reef():
		return

	var day_report: Dictionary = _main._expedition_day_state.report()
	var survey := _survey_by_id(SURVEY_TARGET_ID)
	var result_text: String = _main._anomaly_survey.result_text()
	print("Expansion 10 regional journey smoke passed: route=%s promise_gate=%s regional_gates=%s capability=%s blueprint=%s recipe=ti2+rubber1 night_project=true scanner_blueprint=%s scanner_recipe=ti1+coil1 scanner=%s optional_cache_uncollected=true target=%s survey_seconds=%.1f discovery=%s pending_away=true committed_at_boat=true next_lead=\"%s\" movement=continuous_no_teleport collision=active current_e_required=false map=%s distance=%.1fpx elapsed=%.1fs oxygen=%.1f/%.1f day=%d daylight=%.1fs sorties=%d connectors=%d prompts=%d result=\"%s\"." % [
		ROUTE_ID,
		PROMISE_GATE_ID,
		",".join(PackedStringArray(_regional_gate_contacts())),
		ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID,
		ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID,
		ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID,
		ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		SURVEY_TARGET_ID,
		float(survey.get("interaction_seconds", 0.0)),
		DISCOVERY_ID,
		str(survey.get("next_lead_label", "")),
		_world.map_id,
		_distance_px,
		_simulation_seconds,
		_minimum_oxygen,
		_oxygen_seconds,
		int(day_report.get("day_number", 0)),
		float(day_report.get("daylight_remaining_seconds", 0.0)),
		int(day_report.get("sortie_count", 0)),
		int(day_report.get("connector_transition_count", -1)),
		_connector_prompt_count,
		result_text.replace("\n", " | "),
	])
	get_tree().quit(0)

func run_to_committed_signal_reef() -> bool:
	if not _require(_world.map_id == MAP_ID, "loaded unexpected map %s" % _world.map_id):
		return false
	if not _require(_world.get_world_connectors().is_empty(), "full level contains connectors"):
		return false
	var collision := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not _require(collision != null and collision.shape is RectangleShape2D and not collision.disabled, "player collision is unavailable"):
		return false
	_body_size = (collision.shape as RectangleShape2D).size
	_starting_health = int(_main._player_health.current_health)
	_minimum_oxygen = _oxygen_seconds
	if not _verify_fresh_profile():
		return false
	if not _require(_world.is_inside_boat(_player.global_position), "journey did not begin at the canonical boat"):
		return false

	_prepare_controlled_movement()
	await get_tree().physics_frame
	if not await _prove_pre_fins_denial():
		return false
	if not await _recover_blueprint():
		return false
	if not await _collect_and_bank_recipe():
		return false
	if not _build_fins_and_begin_day_two():
		return false
	if not await ScannerProjectJourney.new().run(self):
		return false
	if not await _complete_regional_journey():
		return false
	return true

func _verify_fresh_profile() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var report: Dictionary = profile.report()
	var storage_status := str(profile.last_storage_report().get("status", ""))
	return (
		_require(storage_status in ["memory", "missing"], "smoke loaded an existing durable profile")
		and _require(report.get("completed_discoveries", []).is_empty(), "fresh profile already has discoveries")
		and _require(report.get("unlocked_capabilities", []).is_empty(), "fresh profile already has capabilities")
		and _require(report.get("material_inventory", {}).is_empty(), "fresh profile already has materials")
		and _require(report.get("completed_projects", []).is_empty(), "fresh profile already has projects")
	)

func _prove_pre_fins_denial() -> bool:
	var landmark_center: Vector2 = FullLevelNavigation.new().marker_center(_world, LANDMARK_ID)
	var navigation = _navigation_for("", [])
	if not _require(landmark_center.x >= 0.0, "missing landmark %s" % LANDMARK_ID):
		return false
	if not _require(navigation.path_between(_player.global_position, landmark_center).is_empty(), "fresh profile found a no-fins path to Signal Reef"):
		return false
	var gate := _gate_by_id(PROMISE_GATE_ID)
	if not _require(not gate.is_empty(), "missing promise gate %s" % PROMISE_GATE_ID):
		return false
	var gate_rect: Rect2 = gate["rect"]
	var approach := Vector2(gate_rect.position.x - _body_size.x * 0.5 - 24.0, gate_rect.get_center().y)
	if not await _drive_to("pre_fins_promise", approach, navigation):
		return false
	var oxygen_before := _oxygen_seconds
	var max_x: float = _player.global_position.x
	var saw_block := false
	for step in range(int(ceil(BLOCKED_SWIM_SECONDS / FIXED_DELTA))):
		_player.swim_in_direction(Vector2.RIGHT, FIXED_DELTA)
		_advance(FIXED_DELTA)
		max_x = maxf(max_x, _player.global_position.x)
		var blocking_gate: Dictionary = _main._current_gate.blocking_gate()
		saw_block = saw_block or str(blocking_gate.get("id", "")) == PROMISE_GATE_ID
		if step % SIMULATION_STEPS_PER_FRAME == 0:
			await get_tree().physics_frame
	_player.reset_motion()
	if not _require(saw_block, "normal swimming did not encounter the authored pre-fins blocker"):
		return false
	if not _require(max_x <= gate_rect.end.x + 8.0, "fresh diver crossed the promise current"):
		return false
	if not _require(_oxygen_seconds < oxygen_before, "oxygen did not advance during blocked swimming"):
		return false
	return await _return_to_boat("pre_fins_return", navigation)

func _recover_blueprint() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var container := _container_by_id(BLUEPRINT_CONTAINER_ID)
	if not _require(not container.is_empty(), "missing blueprint container %s" % BLUEPRINT_CONTAINER_ID):
		return false
	var navigation = _navigation_for("", [])
	if not await _drive_to("blueprint_outbound", container["center"], navigation):
		return false
	_advance(0.0)
	if not _require(not profile.has_completed_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID), "blueprint auto-recovered from proximity"):
		return false
	_press_key(KEY_E)
	if not _require(profile.has_completed_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID), "E did not recover the fins blueprint"):
		return false
	if not _require(_main._progression_containers.is_opened(BLUEPRINT_CONTAINER_ID), "blueprint container did not open"):
		return false
	if not _require(_main._progression_project_tracker.visible and _main._progression_project_tracker.snapshot_text().find("Titanium  0/2 banked") != -1 and _main._progression_project_tracker.snapshot_text().find("Rubber  0/1 banked") != -1, "blueprint recipe tracker was not visible on the acquisition frame"):
		return false
	return await _return_to_boat("blueprint_return", navigation)
func _collect_and_bank_recipe() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var candidates := _active_recipe_candidates()
	if not _require(candidates.size() == 3, "day-one source did not guarantee two titanium and one rubber"):
		return false
	for candidate in candidates:
		var material_id := str(candidate.get("material_id", ""))
		var quantity := int(candidate.get("material_quantity", 0))
		var before: int = profile.material_quantity(material_id) + int(_main._material_runtime.held_quantities().get(material_id, 0))
		var navigation = _navigation_for(str(candidate.get("id", "")), [])
		if not await _drive_to("recipe_%s" % candidate.get("id", "material"), candidate["center"], navigation):
			return false
		_advance(0.0)
		var after: int = profile.material_quantity(material_id) + int(_main._material_runtime.held_quantities().get(material_id, 0))
		if not _require(after == before + quantity, "material %s did not enter held cargo" % candidate.get("id", "")):
			return false
		if not await _return_to_boat("recipe_return_%s" % candidate.get("id", "material"), navigation):
			return false
		if not _require(_main._material_runtime.held_count() == 0, "boat did not bank recipe material"):
			return false
	return _require(
		profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2
		and profile.material_quantity(ExpansionProfileState.RUBBER_MATERIAL_ID) == 1,
		"banked recipe was not exactly titanium 2 and rubber 1"
	)

func _build_fins_and_begin_day_two() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var wallet_before := _session_wallet()
	_press_key(KEY_P)
	if not _require(not profile.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID), "fins built during active day"):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "boat did not enter night debrief"):
		return false
	_press_key(KEY_P)
	if not _require(profile.has_completed_project(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID), "night project did not complete"):
		return false
	if not _require(profile.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID), "night project did not unlock fins"):
		return false
	if not _require(profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 0 and profile.material_quantity(ExpansionProfileState.RUBBER_MATERIAL_ID) == 0, "fins project did not spend the recipe"):
		return false
	if not _require(_session_wallet() == wallet_before, "recipe project changed wallet value"):
		return false
	_press_key(KEY_N)
	_advance(0.0)
	_prepare_controlled_movement()
	_body_size = ((_player.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size
	_starting_health = int(_main._player_health.current_health)
	_minimum_oxygen = _oxygen_seconds
	return (
		_require(_world.map_id == MAP_ID, "real next-day transition left the full level")
		and _require(_main._expedition_day_state.day_number == 2 and _main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE, "day two did not begin active")
		and _require(_world.is_inside_boat(_player.global_position), "day two did not begin at the boat")
		and _require(not _gate_by_id(REGIONAL_GATE_IDS[0]).is_empty(), "day two lost the regional current passage")
		and _require(FullLevelNavigation.new().marker_center(_world, LANDMARK_ID).x >= 0.0, "day two lost the Signal Reef landmark")
	)

func _complete_regional_journey() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var target := _survey_by_id(SURVEY_TARGET_ID)
	var landmark_center: Vector2 = FullLevelNavigation.new().marker_center(_world, LANDMARK_ID)
	if not _require(not target.is_empty() and landmark_center.x >= 0.0, "regional destination source ids are incomplete"):
		return false
	var navigation = _navigation_for("", PASSABLE_CAPABILITIES)
	var regional_start_distance := _distance_px
	var boat_position: Vector2 = _player.global_position
	var daylight_before: float = _main._expedition_day_state.daylight_remaining_seconds
	if not await _drive_to("signal_reef_landmark", landmark_center, navigation):
		return false
	var landmark_position: Vector2 = _player.global_position
	var scan_pose: Dictionary = ScannerSmokePose.new().find_pose(_world, target)
	if not _require(bool(scan_pose.get("found", false)), "regional destination has no clear scan pose"):
		return false
	if not await _drive_to("signal_reef_survey", scan_pose.get("origin", Vector2.ZERO), navigation):
		return false
	if not _place_for_scan(target):
		return false
	var survey_position: Vector2 = _player.global_position
	_advance(0.0)
	_press_key(KEY_Q)
	var interaction_seconds := float(target.get("interaction_seconds", 0.0))
	_advance(interaction_seconds * 0.5)
	var interaction: Dictionary = _main._anomaly_survey.report().get("interaction", {})
	if not _require(float(interaction.get("progress", 0.0)) > 0.0 and float(interaction.get("progress", 0.0)) < 1.0, "regional survey did not expose partial progress"):
		return false
	_advance(interaction_seconds * 0.5 + 0.01)
	if not _require(_main._anomaly_survey.has_pending_discovery(), "completed regional survey did not become pending"):
		return false
	if not _require(not _world.is_inside_boat(_player.global_position), "regional discovery became pending at the boat"):
		return false
	if not _require(not profile.has_completed_discovery(DISCOVERY_ID), "regional discovery committed before return"):
		return false
	if not await _return_to_boat("signal_reef_return", navigation):
		return false
	var expected_result := "%s\n%s" % [target.get("finding_label", ""), target.get("next_lead_label", "")]
	if not _require(not _main._anomaly_survey.has_pending_discovery(), "boat return retained pending discovery"):
		return false
	if not _require(profile.has_completed_discovery(DISCOVERY_ID), "boat return did not commit regional discovery"):
		return false
	if not _require(_main._anomaly_survey.result_text() == expected_result, "commit lost finding or next-expedition lead"):
		return false
	if not _require(not _regional_gate_contacts().is_empty(), "journey did not cross an authored regional current seam"):
		return false
	if not _require(_main._expedition_day_state.daylight_remaining_seconds < daylight_before, "daylight did not advance during regional journey"):
		return false
	print("Expansion 10 route evidence: route=%s boat=%s landmark=%s survey=%s return=%s distance=%.1fpx gates=%s oxygen_min=%.1f daylight=%.1f." % [
		ROUTE_ID,
		str(boat_position),
		str(landmark_position),
		str(survey_position),
		str(_player.global_position),
		_distance_px - regional_start_distance,
		",".join(PackedStringArray(_regional_gate_contacts())),
		_minimum_oxygen,
		_main._expedition_day_state.daylight_remaining_seconds,
	])
	return true


func _place_for_scan(target: Dictionary) -> bool:
	var pose: Dictionary = ScannerSmokePose.new().place(_world, _player, target)
	return _require(bool(pose.get("found", false)), "no clear scan pose for %s" % target.get("id", "target"))


func _navigation_for(material_id: String, capabilities: Array, allowed_salvage_id := ""):
	var navigation = FullLevelNavigation.new()
	navigation.build(
		_world,
		_body_size,
		SALVAGE_COLLECTION_RADIUS,
		material_id,
		capabilities,
		_blocked_salvage_ids(allowed_salvage_id)
	)
	return navigation


func _drive_to(route_id: String, destination: Vector2, navigation) -> bool:
	if _player.global_position.distance_to(destination) <= ENDPOINT_TOLERANCE_PX:
		return true
	var path: PackedVector2Array = navigation.path_between(_player.global_position, destination)
	if not _require(path.size() > 1, "%s has no collision-clear path to %s" % [route_id, str(destination)]):
		return false
	return await _drive_path(route_id, path, navigation.path_distance(path))


func _drive_path(route_id: String, path: PackedVector2Array, planned_distance: float) -> bool:
	var path_index := 0
	var stall_steps := 0
	var elapsed_seconds := 0.0
	var simulation_steps := 0
	var maximum_seconds := planned_distance / maxf(1.0, float(_player.swim_speed)) * 1.8 + 15.0
	while _player.global_position.distance_to(path[path.size() - 1]) > ENDPOINT_TOLERANCE_PX:
		path_index = _closest_forward_path_index(path, path_index)
		var target_index := mini(path.size() - 1, path_index + PATH_LOOKAHEAD_POINTS)
		var before: Vector2 = _player.global_position
		_player.swim_in_direction(before.direction_to(path[target_index]), FIXED_DELTA)
		_advance(FIXED_DELTA)
		var moved := before.distance_to(_player.global_position)
		if not _require(moved <= MAX_STEP_DISTANCE_PX, "%s detected a %.1fpx reposition" % [route_id, moved]):
			return false
		_distance_px += moved
		_record_gate_contact()
		if not _runtime_state_is_valid(route_id):
			return false
		stall_steps = stall_steps + 1 if moved < 0.01 else 0
		if not _require(stall_steps <= MAX_STALL_STEPS, "%s stalled with collision active" % route_id):
			return false
		elapsed_seconds += FIXED_DELTA
		if not _require(elapsed_seconds <= maximum_seconds, "%s exceeded %.1fs near %s" % [route_id, maximum_seconds, str(_player.global_position)]):
			return false
		simulation_steps += 1
		if simulation_steps % SIMULATION_STEPS_PER_FRAME == 0:
			await get_tree().physics_frame
	_player.reset_motion()
	_advance(0.0)
	return _require(_player.global_position.distance_to(path[path.size() - 1]) <= ENDPOINT_TOLERANCE_PX, "%s missed its endpoint" % route_id)


func _return_to_boat(route_id: String, navigation) -> bool:
	if not await _drive_to(route_id, _world.get_entry_position(BOAT_ENTRY_ID), navigation):
		return false
	_advance(0.0)
	if not _require(_world.is_inside_boat(_player.global_position), "%s did not reach the canonical boat" % route_id):
		return false
	var capacity := _oxygen_capacity_seconds()
	var steps := 0
	while _oxygen_seconds < capacity - 0.01:
		_advance(FIXED_DELTA)
		steps += 1
		if not _runtime_state_is_valid(route_id):
			return false
		if steps % SIMULATION_STEPS_PER_FRAME == 0:
			await get_tree().physics_frame
		if not _require(steps <= 600, "boat oxygen refill timed out"):
			return false
	return true


func _runtime_state_is_valid(route_id: String) -> bool:
	if not _require(_world.map_id == MAP_ID, "%s changed maps to %s" % [route_id, _world.map_id]):
		return false
	if not _require(not _run_failed and _main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE, "%s entered failure or night state" % route_id):
		return false
	if not _require(int(_main._player_health.current_health) == _starting_health, "%s took hostile damage" % route_id):
		return false
	if not _require(int(_main._expedition_day_state.connector_transition_count) == 0, "%s recorded a connector transition" % route_id):
		return false
	var connector_prompt: String = _main._world_connector_prompt()
	if not connector_prompt.is_empty():
		_connector_prompt_count += 1
		return _require(false, "%s exposed connector prompt %s" % [route_id, connector_prompt])
	return true


func _advance(delta: float) -> void:
	_process(delta)
	_simulation_seconds += maxf(0.0, delta)
	_minimum_oxygen = minf(_minimum_oxygen, _oxygen_seconds)


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
func _prepare_controlled_movement() -> void:
	_player.set_physics_process(false)
	_main.set_process(false)
	_player.reset_motion()
func _record_gate_contact() -> void:
	var gate: Dictionary = _world.get_current_gate_at(_player.global_position)
	var gate_id := str(gate.get("id", ""))
	if not gate_id.is_empty() and not _traversed_gate_ids.has(gate_id):
		_traversed_gate_ids.append(gate_id)


func _regional_gate_contacts() -> Array[String]:
	var ids: Array[String] = []
	for gate_id in REGIONAL_GATE_IDS:
		if _traversed_gate_ids.has(gate_id):
			ids.append(gate_id)
	return ids


func _active_recipe_candidates() -> Array:
	var active_ids: Array = _world.get_material_candidate_report().get("active_ids", [])
	var values := []
	var counts := {
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 0,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 0,
	}
	for candidate in _world.get_material_candidates():
		var candidate_id := str(candidate.get("id", ""))
		var material_id := str(candidate.get("material_id", ""))
		if not active_ids.has(candidate_id) or not counts.has(material_id):
			continue
		values.append(candidate)
		counts[material_id] = int(counts[material_id]) + int(candidate.get("material_quantity", 0))
	if counts[ExpansionProfileState.TITANIUM_MATERIAL_ID] != 2 or counts[ExpansionProfileState.RUBBER_MATERIAL_ID] != 1:
		return []
	return values


func _blocked_salvage_ids(allowed_id := "") -> Array[String]:
	var ids: Array[String] = []
	for salvage in _world.get_salvage_centers():
		var salvage_id := str(salvage.get("id", ""))
		if salvage_id != allowed_id and not _world.is_salvage_collected(salvage_id):
			ids.append(salvage_id)
	return ids


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	_main._unhandled_input(event)


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _container_by_id(container_id: String) -> Dictionary:
	for container in _world.get_progression_containers():
		if str(container.get("id", "")) == container_id:
			return container
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _survey_by_id(target_id: String) -> Dictionary:
	for target in _world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Expansion 10 regional journey smoke failed: %s." % message)
	get_tree().quit(1)
	return false
