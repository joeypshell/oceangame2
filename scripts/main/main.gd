extends Node2D

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const DEFAULT_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const ORIGINAL_MAP_PATH := "res://maps/cave_salvage_test_01.greybox.json"
const TILESET_TEST_MAP_PATH := "res://maps/cave_tileset_test_01.greybox.json"
const ORGANIC_MAP_PATH := "res://maps/cave_salvage_organic_01.greybox.json"
const FULL_SKETCH_MAP_PATH := "res://maps/full_cave_sketch_01.greybox.json"
const PRODUCTION_SLICE_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const PRODUCTION_SLICE_02_MAP_PATH := "res://maps/production_slice_02.greybox.json"
const PRODUCTION_SLICE_03_MAP_PATH := "res://maps/production_slice_03.greybox.json"
const PRODUCTION_SLICE_04_MAP_PATH := "res://maps/production_slice_04.greybox.json"
const SCREENSHOT_PATH := "res://visual_baselines/001_greybox_in_engine.png"
const CAMERA_TEST_CAPTURE_DIR := "res://visual_captures/latest"
const ORIGINAL_CAPTURE_DIR := "res://visual_captures/original_salvage"
const TILESET_TEST_CAPTURE_DIR := "res://visual_captures/tileset_test"
const ORGANIC_CAPTURE_DIR := "res://visual_captures/organic_salvage"
const FULL_SKETCH_CAPTURE_DIR := "res://visual_captures/full_cave_sketch"
const PRODUCTION_SLICE_CAPTURE_DIR := "res://visual_captures/production_slice_01"
const PRODUCTION_SLICE_DEBUG_CAPTURE_DIR := "res://visual_captures/production_slice_01_debug"
const PRODUCTION_SLICE_02_CAPTURE_DIR := "res://visual_captures/production_slice_02"
const PRODUCTION_SLICE_02_DEBUG_CAPTURE_DIR := "res://visual_captures/production_slice_02_debug"
const PRODUCTION_SLICE_03_CAPTURE_DIR := "res://visual_captures/production_slice_03"
const PRODUCTION_SLICE_03_DEBUG_CAPTURE_DIR := "res://visual_captures/production_slice_03_debug"
const PRODUCTION_SLICE_04_CAPTURE_DIR := "res://visual_captures/production_slice_04"
const PRODUCTION_SLICE_04_DEBUG_CAPTURE_DIR := "res://visual_captures/production_slice_04_debug"
const BUILD_INFO_PATH := "res://build_info.json"
const CAPTURE_ZOOM := Vector2(0.7, 0.7)
const SALVAGE_COLLECTION_RADIUS := 34.0
const HAZARD_CONTACT_RADIUS := 30.0
const HAZARD_COOLDOWN_SECONDS := 1.0
const HAZARD_FEEDBACK_SECONDS := 0.45
const OXYGEN_MAX_SECONDS := 90.0
const OXYGEN_REFILL_SECONDS_PER_SECOND := 25.0
const REVIEW_MAP_OPTIONS := [
	{"label": "Production 01", "path": PRODUCTION_SLICE_MAP_PATH},
	{"label": "Production 02", "path": PRODUCTION_SLICE_02_MAP_PATH},
	{"label": "Production 03", "path": PRODUCTION_SLICE_03_MAP_PATH},
	{"label": "Production 04", "path": PRODUCTION_SLICE_04_MAP_PATH},
	{"label": "Original", "path": ORIGINAL_MAP_PATH},
	{"label": "Organic", "path": ORGANIC_MAP_PATH},
	{"label": "Full Sketch", "path": FULL_SKETCH_MAP_PATH},
]

var _world
var _player
var _review_canvas: CanvasLayer
var _review_label: Label
var _status_label: Label
var _map_selector: OptionButton
var _map_selector_enabled := false
var _debug_overlay_enabled := false
var _held_salvage := 0
var _banked_salvage := 0
var _total_salvage := 0
var _held_salvage_ids: Array[String] = []
var _hazard_cooldown_seconds := 0.0
var _hazard_feedback_seconds := 0.0
var _hazard_interactions_enabled := true
var _oxygen_seconds := OXYGEN_MAX_SECONDS
var _run_complete := false
var _last_status_note := ""


func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	var engine_args := OS.get_cmdline_args()
	var capture_original_map := _has_arg(user_args, engine_args, "--capture-original-map")
	var capture_tileset_test := _has_arg(user_args, engine_args, "--capture-tileset-test")
	var capture_organic_map := _has_arg(user_args, engine_args, "--capture-organic-map")
	var capture_full_sketch_map := _has_arg(user_args, engine_args, "--capture-full-sketch-map")
	var capture_production_slice_map := _has_arg(user_args, engine_args, "--capture-production-slice-map")
	var capture_production_slice_debug_map := _has_arg(user_args, engine_args, "--capture-production-slice-debug-map")
	var capture_production_slice_02_map := _has_arg(user_args, engine_args, "--capture-production-slice-02-map")
	var capture_production_slice_02_debug_map := _has_arg(user_args, engine_args, "--capture-production-slice-02-debug-map")
	var capture_production_slice_03_map := _has_arg(user_args, engine_args, "--capture-production-slice-03-map")
	var capture_production_slice_03_debug_map := _has_arg(user_args, engine_args, "--capture-production-slice-03-debug-map")
	var capture_production_slice_04_map := _has_arg(user_args, engine_args, "--capture-production-slice-04-map")
	var capture_production_slice_04_debug_map := _has_arg(user_args, engine_args, "--capture-production-slice-04-debug-map")
	var check_map_parity := _has_arg(user_args, engine_args, "--check-map-parity")
	var smoke_salvage_loop := _has_arg(user_args, engine_args, "--smoke-salvage-loop")
	var smoke_production_slice_route := _has_arg(user_args, engine_args, "--smoke-production-slice-route")
	var smoke_production_slice_02_route := _has_arg(user_args, engine_args, "--smoke-production-slice-02-route")
	var smoke_production_slice_03_route := _has_arg(user_args, engine_args, "--smoke-production-slice-03-route")
	var smoke_production_slice_04_route := _has_arg(user_args, engine_args, "--smoke-production-slice-04-route")
	var smoke_map_selector := _has_arg(user_args, engine_args, "--smoke-map-selector")
	var smoke_hazard_interaction := _has_arg(user_args, engine_args, "--smoke-hazard-interaction")
	var smoke_oxygen_pressure := _has_arg(user_args, engine_args, "--smoke-oxygen-pressure")
	var requested_map_path := _arg_value(user_args, engine_args, "--map-path")
	var parity_output_path := _arg_value(user_args, engine_args, "--parity-output")

	var selected_map_path := DEFAULT_MAP_PATH
	if capture_original_map:
		selected_map_path = ORIGINAL_MAP_PATH
	elif capture_tileset_test:
		selected_map_path = TILESET_TEST_MAP_PATH
	elif capture_organic_map:
		selected_map_path = ORGANIC_MAP_PATH
	elif capture_full_sketch_map:
		selected_map_path = FULL_SKETCH_MAP_PATH
	elif capture_production_slice_map:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_production_slice_debug_map:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_production_slice_02_map:
		selected_map_path = PRODUCTION_SLICE_02_MAP_PATH
	elif capture_production_slice_02_debug_map:
		selected_map_path = PRODUCTION_SLICE_02_MAP_PATH
	elif capture_production_slice_03_map:
		selected_map_path = PRODUCTION_SLICE_03_MAP_PATH
	elif capture_production_slice_03_debug_map:
		selected_map_path = PRODUCTION_SLICE_03_MAP_PATH
	elif capture_production_slice_04_map:
		selected_map_path = PRODUCTION_SLICE_04_MAP_PATH
	elif capture_production_slice_04_debug_map:
		selected_map_path = PRODUCTION_SLICE_04_MAP_PATH
	elif smoke_production_slice_route:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_production_slice_02_route:
		selected_map_path = PRODUCTION_SLICE_02_MAP_PATH
	elif smoke_production_slice_03_route:
		selected_map_path = PRODUCTION_SLICE_03_MAP_PATH
	elif smoke_production_slice_04_route:
		selected_map_path = PRODUCTION_SLICE_04_MAP_PATH
	elif smoke_hazard_interaction:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_oxygen_pressure:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif not requested_map_path.is_empty():
		selected_map_path = requested_map_path

	_debug_overlay_enabled = (
		_has_arg(user_args, engine_args, "--show-debug-overlay")
		or capture_production_slice_debug_map
		or capture_production_slice_02_debug_map
		or capture_production_slice_03_debug_map
		or capture_production_slice_04_debug_map
	)
	var automated_review := (
		check_map_parity
		or capture_original_map
		or capture_tileset_test
		or capture_organic_map
		or capture_full_sketch_map
		or capture_production_slice_map
		or capture_production_slice_debug_map
		or capture_production_slice_02_map
		or capture_production_slice_02_debug_map
		or capture_production_slice_03_map
		or capture_production_slice_03_debug_map
		or capture_production_slice_04_map
		or capture_production_slice_04_debug_map
		or smoke_salvage_loop
		or smoke_production_slice_route
		or smoke_production_slice_02_route
		or smoke_production_slice_03_route
		or smoke_production_slice_04_route
		or smoke_map_selector
		or smoke_hazard_interaction
		or smoke_oxygen_pressure
		or _has_arg(user_args, engine_args, "--capture-greybox-screenshot")
		or _has_arg(user_args, engine_args, "--capture-camera-tests")
	)
	_map_selector_enabled = (not automated_review) and _review_map_selector_allowed(user_args, engine_args)

	if check_map_parity:
		var world := _create_world(selected_map_path, _debug_overlay_enabled)
		_write_parity_report_and_quit(world, parity_output_path)
		return

	_load_playable_map(selected_map_path, _debug_overlay_enabled)

	if smoke_salvage_loop:
		_smoke_salvage_loop_and_quit()
		return
	if smoke_production_slice_route:
		await _smoke_salvage_route_and_quit("production_slice_01", "boat extraction")
		return
	if smoke_production_slice_02_route:
		await _smoke_salvage_route_and_quit("production_slice_02", "relay extraction")
		return
	if smoke_production_slice_03_route:
		await _smoke_salvage_route_and_quit("production_slice_03", "relay extraction")
		return
	if smoke_production_slice_04_route:
		await _smoke_salvage_route_and_quit("production_slice_04", "relay extraction")
		return
	if smoke_map_selector:
		_smoke_map_selector_and_quit()
		return
	if smoke_hazard_interaction:
		_smoke_hazard_interaction_and_quit()
		return
	if smoke_oxygen_pressure:
		_smoke_oxygen_pressure_and_quit()
		return

	if _has_arg(user_args, engine_args, "--capture-greybox-screenshot"):
		_capture_screenshot_and_quit()
	elif _has_arg(user_args, engine_args, "--capture-camera-tests"):
		_capture_camera_tests_and_quit(_world, CAMERA_TEST_CAPTURE_DIR)
	elif capture_original_map:
		_capture_camera_tests_and_quit(_world, ORIGINAL_CAPTURE_DIR)
	elif capture_tileset_test:
		_capture_camera_tests_and_quit(_world, TILESET_TEST_CAPTURE_DIR)
	elif capture_organic_map:
		_capture_camera_tests_and_quit(_world, ORGANIC_CAPTURE_DIR)
	elif capture_full_sketch_map:
		_capture_camera_tests_and_quit(_world, FULL_SKETCH_CAPTURE_DIR)
	elif capture_production_slice_map:
		_capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_CAPTURE_DIR)
	elif capture_production_slice_debug_map:
		_capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_DEBUG_CAPTURE_DIR)
	elif capture_production_slice_02_map:
		_capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_02_CAPTURE_DIR)
	elif capture_production_slice_02_debug_map:
		_capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_02_DEBUG_CAPTURE_DIR)
	elif capture_production_slice_03_map:
		_capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_03_CAPTURE_DIR)
	elif capture_production_slice_03_debug_map:
		_capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_03_DEBUG_CAPTURE_DIR)
	elif capture_production_slice_04_map:
		_capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_04_CAPTURE_DIR)
	elif capture_production_slice_04_debug_map:
		_capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_04_DEBUG_CAPTURE_DIR)


func _review_map_selector_allowed(user_args: PackedStringArray, engine_args: PackedStringArray) -> bool:
	return OS.has_feature("editor") or _has_arg(user_args, engine_args, "--review-map-selector")


func _create_world(map_path: String, show_debug_overlay: bool) -> Node:
	var world := WORLD_SCENE.instantiate()
	_world = world
	world.map_path = map_path
	world.show_debug_overlay = show_debug_overlay
	add_child(world)
	world.load_greybox()
	return world


func _load_playable_map(map_path: String, show_debug_overlay: bool) -> void:
	_clear_loaded_review_nodes()
	var world := _create_world(map_path, show_debug_overlay)
	var player := PLAYER_SCENE.instantiate()
	_player = player
	player.position = world.spawn_position
	add_child(player)

	if player.has_method("set_camera_limits"):
		player.set_camera_limits(Rect2(Vector2.ZERO, world.map_pixel_size))
	if player.has_method("snap_camera"):
		player.snap_camera()

	_held_salvage = 0
	_banked_salvage = 0
	_total_salvage = world.get_total_salvage_count()
	_held_salvage_ids = []
	_hazard_cooldown_seconds = 0.0
	_hazard_feedback_seconds = 0.0
	_hazard_interactions_enabled = true
	_oxygen_seconds = OXYGEN_MAX_SECONDS
	_run_complete = false
	_last_status_note = ""
	_create_review_overlay(world)
	_update_status_label()


func _clear_loaded_review_nodes() -> void:
	for node in [_review_canvas, _player, _world]:
		if node == null or not is_instance_valid(node):
			continue
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()
	_review_canvas = null
	_player = null
	_world = null
	_review_label = null
	_status_label = null
	_map_selector = null


func _on_review_map_selected(index: int) -> void:
	if _map_selector == null or index < 0:
		return
	var map_path := str(_map_selector.get_item_metadata(index))
	if map_path.is_empty():
		return
	if _world != null and _world.map_path == map_path:
		return
	_load_playable_map(map_path, _debug_overlay_enabled)


func _process(delta: float) -> void:
	if _world == null or _player == null:
		return
	_update_hazard_feedback(delta)
	if _run_complete:
		_update_status_label()
		return

	if _update_oxygen(delta):
		_update_status_label()
		return

	if _hazard_cooldown_seconds > 0.0:
		_hazard_cooldown_seconds = maxf(0.0, _hazard_cooldown_seconds - delta)
	elif _hazard_interactions_enabled:
		var hazard_id: String = _world.get_hazard_near(_player.global_position, HAZARD_CONTACT_RADIUS)
		if not hazard_id.is_empty():
			_handle_hazard_hit(hazard_id)
			_update_status_label()
			return

	var collected_salvage: String = _world.collect_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
	if not collected_salvage.is_empty():
		_held_salvage += 1
		_held_salvage_ids.append(collected_salvage)
		_last_status_note = "Collected %s" % collected_salvage

	if _held_salvage > 0 and _world.is_inside_extraction(_player.global_position):
		_banked_salvage += _held_salvage
		_held_salvage = 0
		_held_salvage_ids = []
		if _total_salvage > 0 and _banked_salvage >= _total_salvage:
			_run_complete = true
			_last_status_note = "Run complete"
		else:
			_last_status_note = "Banked salvage"

	_update_status_label()


func _smoke_salvage_loop_and_quit() -> void:
	if _total_salvage <= 0:
		push_error("Salvage loop smoke requires a map with authored salvage.")
		get_tree().quit(1)
		return

	for salvage in _world.get_salvage_centers():
		_player.global_position = salvage["center"]
		_process(0.0)

	_player.global_position = _world.get_extraction_center()
	_process(0.0)

	if not _run_complete:
		push_error("Salvage loop smoke did not complete after collecting and returning.")
		get_tree().quit(1)
		return

	var completed_total := _total_salvage
	_reset_run()
	if _held_salvage != 0 or _banked_salvage != 0 or _run_complete:
		push_error("Salvage loop smoke reset left stale run state.")
		get_tree().quit(1)
		return

	print("Salvage loop smoke passed: collected, banked, completed, and reset %d salvage." % completed_total)
	get_tree().quit()


func _smoke_salvage_route_and_quit(expected_map_id: String, extraction_label: String) -> void:
	if _world.map_id != expected_map_id:
		push_error("%s route smoke loaded unexpected map: %s" % [expected_map_id, _world.map_id])
		get_tree().quit(1)
		return
	if not _player.has_method("swim_in_direction"):
		push_error("%s route smoke requires player swim_in_direction()." % expected_map_id)
		get_tree().quit(1)
		return
	if _total_salvage <= 0:
		push_error("%s route smoke requires authored salvage." % expected_map_id)
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var targets := []
	for salvage in _world.get_salvage_centers():
		targets.append(salvage["center"])
	targets.append(_world.get_extraction_center())

	for target in targets:
		var reached := await _swim_to_target(target)
		if not reached:
			get_tree().quit(1)
			return
		_process(0.0)

	if not _run_complete:
		push_error("%s route smoke did not complete after swimming through salvage route." % expected_map_id)
		get_tree().quit(1)
		return

	var completed_total := _total_salvage
	_reset_run()
	print("%s route smoke passed: swam to %d salvage and returned to %s." % [
		expected_map_id,
		completed_total,
		extraction_label,
	])
	get_tree().quit()


func _smoke_map_selector_and_quit() -> void:
	_load_playable_map(PRODUCTION_SLICE_03_MAP_PATH, false)
	if _world.map_id != "production_slice_03":
		push_error("Map selector smoke expected production_slice_03, loaded %s." % _world.map_id)
		get_tree().quit(1)
		return

	_load_playable_map(PRODUCTION_SLICE_MAP_PATH, false)
	if _world.map_id != "production_slice_01":
		push_error("Map selector smoke expected production_slice_01, loaded %s." % _world.map_id)
		get_tree().quit(1)
		return

	print("Map selector smoke passed: switched to production_slice_03 and back to production_slice_01.")
	get_tree().quit()


func _smoke_hazard_interaction_and_quit() -> void:
	var salvage: Array = _world.get_salvage_centers()
	var hazards: Array = _world.get_hazard_centers()
	if salvage.is_empty() or hazards.is_empty():
		push_error("Hazard smoke requires authored salvage and hazard entities.")
		get_tree().quit(1)
		return

	_player.global_position = salvage[0]["center"]
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids.is_empty():
		push_error("Hazard smoke could not collect setup salvage.")
		get_tree().quit(1)
		return

	var collected_id := _held_salvage_ids[0]
	_player.global_position = hazards[0]["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _held_salvage != 0 or not _held_salvage_ids.is_empty():
		push_error("Hazard smoke did not drop held salvage.")
		get_tree().quit(1)
		return
	if _player.global_position.distance_to(_world.spawn_position) > 2.0:
		push_error("Hazard smoke did not return player to spawn.")
		get_tree().quit(1)
		return

	_player.global_position = salvage[0]["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids[0] != collected_id:
		push_error("Hazard smoke did not restore dropped salvage for recollection.")
		get_tree().quit(1)
		return

	_reset_run()
	print("Hazard interaction smoke passed: hit hazard, reset to spawn, restored dropped salvage, and recollected it.")
	get_tree().quit()


func _smoke_oxygen_pressure_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Oxygen pressure smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return

	var salvage: Array = _world.get_salvage_centers()
	if salvage.is_empty():
		push_error("Oxygen pressure smoke requires authored salvage.")
		get_tree().quit(1)
		return

	_player.global_position = salvage[0]["center"]
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids.is_empty():
		push_error("Oxygen pressure smoke could not collect setup salvage.")
		get_tree().quit(1)
		return

	var collected_id := _held_salvage_ids[0]
	_oxygen_seconds = 0.1
	_process(0.2)
	if _held_salvage != 0 or not _held_salvage_ids.is_empty():
		push_error("Oxygen pressure smoke did not drop held salvage on depletion.")
		get_tree().quit(1)
		return
	if _player.global_position.distance_to(_world.spawn_position) > 2.0:
		push_error("Oxygen pressure smoke did not return player to spawn.")
		get_tree().quit(1)
		return
	if not is_equal_approx(_oxygen_seconds, OXYGEN_MAX_SECONDS):
		push_error("Oxygen pressure smoke did not refill oxygen after depletion.")
		get_tree().quit(1)
		return

	_player.global_position = salvage[0]["center"]
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids[0] != collected_id:
		push_error("Oxygen pressure smoke did not restore dropped salvage for recollection.")
		get_tree().quit(1)
		return

	_oxygen_seconds = OXYGEN_MAX_SECONDS * 0.5
	_player.global_position = _world.get_extraction_center()
	_process(1.0)
	if _banked_salvage != 1 or _held_salvage != 0:
		push_error("Oxygen pressure smoke did not preserve collect-return banking.")
		get_tree().quit(1)
		return
	if _oxygen_seconds <= OXYGEN_MAX_SECONDS * 0.5:
		push_error("Oxygen pressure smoke did not refill at extraction.")
		get_tree().quit(1)
		return

	_reset_run()
	print("Oxygen pressure smoke passed: depleted, surfaced, restored salvage, refilled, and banked salvage.")
	get_tree().quit()


func _swim_to_target(target: Vector2) -> bool:
	var path: Array = _world.find_open_path(_player.global_position, target)
	if path.is_empty():
		push_error("No open-water path from %s to %s." % [_player.global_position, target])
		return false

	for waypoint_value in path:
		var waypoint: Vector2 = waypoint_value
		var frames_at_waypoint := 0
		while _player.global_position.distance_to(waypoint) > 4.0:
			var direction: Vector2 = (waypoint - _player.global_position).normalized()
			_player.swim_in_direction(direction, 1.0 / 60.0)
			frames_at_waypoint += 1
			if frames_at_waypoint > 120:
				push_error("Timed out swimming toward waypoint %s from %s." % [waypoint, _player.global_position])
				return false
			await get_tree().physics_frame

	_player.swim_in_direction(Vector2.ZERO, 1.0 / 60.0)
	await get_tree().physics_frame
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
		_reset_run()


func _reset_run() -> void:
	if _world == null or _player == null:
		return

	_world.reset_salvage()
	_held_salvage = 0
	_held_salvage_ids = []
	_banked_salvage = 0
	_hazard_cooldown_seconds = 0.0
	_hazard_feedback_seconds = 0.0
	_hazard_interactions_enabled = true
	_oxygen_seconds = OXYGEN_MAX_SECONDS
	_run_complete = false
	_last_status_note = "Reset"
	_player.modulate = Color.WHITE
	_player.position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	if _player.has_method("snap_camera"):
		_player.snap_camera()
	_update_status_label()


func _update_oxygen(delta: float) -> bool:
	if _world.is_inside_extraction(_player.global_position):
		_oxygen_seconds = minf(OXYGEN_MAX_SECONDS, _oxygen_seconds + OXYGEN_REFILL_SECONDS_PER_SECOND * delta)
		return false

	_oxygen_seconds = maxf(0.0, _oxygen_seconds - delta)
	if _oxygen_seconds > 0.0:
		return false

	_handle_oxygen_depleted()
	return true


func _handle_oxygen_depleted() -> void:
	if not _held_salvage_ids.is_empty():
		_world.restore_salvage(_held_salvage_ids)
		_held_salvage_ids = []
		_held_salvage = 0
		_last_status_note = "Oxygen depleted - dropped salvage"
	else:
		_last_status_note = "Oxygen depleted - surfaced"

	_oxygen_seconds = OXYGEN_MAX_SECONDS
	_hazard_cooldown_seconds = HAZARD_COOLDOWN_SECONDS
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	if _player.has_method("snap_camera"):
		_player.snap_camera()


func _handle_hazard_hit(hazard_id: String) -> void:
	if not _held_salvage_ids.is_empty():
		_world.restore_salvage(_held_salvage_ids)
		_held_salvage_ids = []
		_held_salvage = 0
		_last_status_note = "Hazard hit - dropped salvage"
	else:
		_last_status_note = "Hazard hit - reset"

	_hazard_cooldown_seconds = HAZARD_COOLDOWN_SECONDS
	_hazard_feedback_seconds = HAZARD_FEEDBACK_SECONDS
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	if _player.has_method("snap_camera"):
		_player.snap_camera()


func _update_hazard_feedback(delta: float) -> void:
	if _player == null:
		return
	if _hazard_feedback_seconds <= 0.0:
		_player.modulate = Color.WHITE
		return
	_hazard_feedback_seconds = maxf(0.0, _hazard_feedback_seconds - delta)
	_player.modulate = Color(1.0, 0.58, 0.58, 1.0)


func _create_review_overlay(world: Node) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ReviewOverlay"
	_review_canvas = canvas
	add_child(canvas)

	var panel := PanelContainer.new()
	panel.name = "ReviewPanel"
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(260, 0)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.07, 0.10, 0.70)
	panel_style.border_color = Color(0.72, 0.92, 1.0, 0.22)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)

	_review_label = Label.new()
	_review_label.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0, 0.95))
	_review_label.add_theme_font_size_override("font_size", 13)
	_review_label.text = "Map %s\nBuild %s" % [world.get_map_label(), _build_label()]
	stack.add_child(_review_label)

	if _map_selector_enabled:
		_map_selector = OptionButton.new()
		_map_selector.name = "ReviewMapSelector"
		for option in REVIEW_MAP_OPTIONS:
			var index := _map_selector.item_count
			_map_selector.add_item(str(option["label"]))
			_map_selector.set_item_metadata(index, str(option["path"]))
			if str(option["path"]) == world.map_path:
				_map_selector.select(index)
		_map_selector.item_selected.connect(_on_review_map_selected)
		stack.add_child(_map_selector)

	if world.show_debug_overlay:
		var debug_label := Label.new()
		debug_label.add_theme_color_override("font_color", Color(0.78, 0.96, 1.0, 0.95))
		debug_label.add_theme_font_size_override("font_size", 12)
		debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		debug_label.text = "Debug markers: cyan grid/source, white route boxes, amber boat/extraction, green entry/spawn, yellow salvage diamonds, red hazard squares"
		stack.add_child(debug_label)

	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45, 0.98))
	_status_label.add_theme_font_size_override("font_size", 14)
	stack.add_child(_status_label)


func _update_status_label() -> void:
	if _status_label == null:
		return

	if _total_salvage <= 0:
		_status_label.text = "Salvage 0/0\nOxygen --"
		return

	var prompt := ""
	if _run_complete:
		prompt = "Complete - press R"
	elif _held_salvage > 0:
		prompt = "Return to extraction"
	elif not _last_status_note.is_empty():
		prompt = _last_status_note

	var oxygen_seconds := int(ceil(_oxygen_seconds))
	var oxygen_text := "Oxygen %ds" % oxygen_seconds
	if _oxygen_seconds <= 15.0 and not _run_complete:
		oxygen_text = "Oxygen %ds LOW" % oxygen_seconds

	_status_label.text = "Salvage %d/%d  Held %d\n%s" % [
		_banked_salvage,
		_total_salvage,
		_held_salvage,
		oxygen_text,
	]
	if not prompt.is_empty():
		_status_label.text += "\n%s" % prompt


func _build_label() -> String:
	var file := FileAccess.open(BUILD_INFO_PATH, FileAccess.READ)
	if file == null:
		return "local"

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "local"

	var git_sha := str(parsed.get("git_sha", ""))
	if git_sha.is_empty():
		return str(parsed.get("version", "local"))
	if git_sha.length() > 7:
		return git_sha.substr(0, 7)
	return git_sha


func _write_parity_report_and_quit(world: Node, output_path: String) -> void:
	var report_json := JSON.stringify(world.get_runtime_parity_report(), "\t")
	if output_path.is_empty():
		print(report_json)
	else:
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_error("Unable to write parity report: %s" % output_path)
			get_tree().quit(1)
			return
		file.store_string(report_json)
		print("Wrote map parity report: %s" % output_path)
	get_tree().quit()


func _capture_screenshot_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://visual_baselines"))
	var image := get_viewport().get_texture().get_image()
	image.save_png(SCREENSHOT_PATH)
	print("Saved screenshot: %s" % ProjectSettings.globalize_path(SCREENSHOT_PATH))
	get_tree().quit()


func _capture_camera_tests_and_quit(world: Node, capture_dir: String) -> void:
	var camera_tests: Array = world.camera_tests
	if camera_tests.is_empty():
		push_error("No camera_tests found in greybox map source.")
		get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "VisualCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.map_pixel_size.x)
	camera.limit_bottom = int(world.map_pixel_size.y)
	add_child(camera)
	camera.make_current()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))

	for camera_test in camera_tests:
		var view_id := _safe_filename(str(camera_test.get("id", "camera_test")))
		var center := Vector2(
			float(camera_test.get("center_x", 0.0)) * world.tile_size,
			float(camera_test.get("center_y", 0.0)) * world.tile_size
		)
		var zoom := float(camera_test.get("zoom", CAPTURE_ZOOM.x))
		camera.zoom = Vector2(zoom, zoom)
		camera.position = center

		await get_tree().process_frame
		await get_tree().process_frame

		var output_path := "%s/%s.png" % [capture_dir, view_id]
		var image := get_viewport().get_texture().get_image()
		image.save_png(output_path)
		print("Saved camera test capture: %s" % ProjectSettings.globalize_path(output_path))

	get_tree().quit()


func _has_arg(user_args: PackedStringArray, engine_args: PackedStringArray, value: String) -> bool:
	return value in user_args or value in engine_args


func _arg_value(user_args: PackedStringArray, engine_args: PackedStringArray, name: String) -> String:
	for args in [user_args, engine_args]:
		for index in range(args.size()):
			var arg: String = str(args[index])
			if arg == name and index + 1 < args.size():
				return str(args[index + 1])
			var prefix := "%s=" % name
			if arg.begins_with(prefix):
				return arg.substr(prefix.length())
	return ""


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
