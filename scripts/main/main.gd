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
const PLAYER_READABILITY_CAPTURE_DIR := "res://visual_captures/player_readability"
const BACKGROUND_DEPTH_CAPTURE_DIR := "res://visual_captures/background_depth"
const FEEDBACK_OVERLAY_CAPTURE_DIR := "res://visual_captures/feedback_overlay"
const BUILD_INFO_PATH := "res://build_info.json"
const CAPTURE_ZOOM := Vector2(0.7, 0.7)
const PLAYER_READABILITY_CAPTURE_ZOOM := Vector2(2.0, 2.0)
const PLAYER_READABILITY_ENTRY_OFFSET_TILES := Vector2(0, 5)
const MOVEMENT_FEEL_PROBE_CENTER_TILES := Vector2(42, 25)
const BACKGROUND_DEPTH_CAPTURE_ZOOM := Vector2(0.52, 0.52)
const BACKGROUND_DEPTH_CENTER_TILES := Vector2(39, 24)
const BACKGROUND_DEPTH_PLAYER_OFFSET_TILES := Vector2(0, 8)
const SALVAGE_COLLECTION_RADIUS := 34.0
const HELD_SALVAGE_CAPACITY := 2
const HAZARD_CONTACT_RADIUS := 30.0
const HAZARD_COOLDOWN_SECONDS := 1.0
const HAZARD_FEEDBACK_SECONDS := 0.45
const OXYGEN_MAX_SECONDS := 90.0
const OXYGEN_REFILL_SECONDS_PER_SECOND := 25.0
const OXYGEN_LOW_WARNING_SECONDS := 35.0
const OXYGEN_CRITICAL_WARNING_SECONDS := 12.0
const OXYGEN_BONUS_POINTS_PER_SECOND := 1
const EXPANDED_ROUTE_CHOICE_ID := "expanded_route_choice"
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
var _result_panel: PanelContainer
var _result_label: Label
var _map_selector: OptionButton
var _map_selector_enabled := false
var _debug_overlay_enabled := false
var _held_salvage := 0
var _banked_salvage := 0
var _total_salvage := 0
var _held_salvage_ids: Array[String] = []
var _held_salvage_score := 0
var _banked_score := 0
var _completion_oxygen_bonus := 0
var _session_best_scores_by_map := {}
var _hazard_cooldown_seconds := 0.0
var _hazard_feedback_seconds := 0.0
var _hazard_interactions_enabled := true
var _oxygen_seconds := OXYGEN_MAX_SECONDS
var _run_complete := false
var _run_failed := false
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
	var capture_player_readability := _has_arg(user_args, engine_args, "--capture-player-readability")
	var capture_background_depth := _has_arg(user_args, engine_args, "--capture-background-depth")
	var capture_feedback_overlay := _has_arg(user_args, engine_args, "--capture-feedback-overlay")
	var check_map_parity := _has_arg(user_args, engine_args, "--check-map-parity")
	var smoke_salvage_loop := _has_arg(user_args, engine_args, "--smoke-salvage-loop")
	var smoke_production_slice_route := _has_arg(user_args, engine_args, "--smoke-production-slice-route")
	var smoke_production_slice_02_route := _has_arg(user_args, engine_args, "--smoke-production-slice-02-route")
	var smoke_production_slice_03_route := _has_arg(user_args, engine_args, "--smoke-production-slice-03-route")
	var smoke_production_slice_04_route := _has_arg(user_args, engine_args, "--smoke-production-slice-04-route")
	var smoke_map_selector := _has_arg(user_args, engine_args, "--smoke-map-selector")
	var smoke_hazard_interaction := _has_arg(user_args, engine_args, "--smoke-hazard-interaction")
	var smoke_oxygen_pressure := _has_arg(user_args, engine_args, "--smoke-oxygen-pressure")
	var smoke_cargo_capacity := _has_arg(user_args, engine_args, "--smoke-cargo-capacity")
	var smoke_session_best_score := _has_arg(user_args, engine_args, "--smoke-session-best-score")
	var smoke_oxygen_bonus_score := _has_arg(user_args, engine_args, "--smoke-oxygen-bonus-score")
	var smoke_route_choice := _has_arg(user_args, engine_args, "--smoke-route-choice")
	var smoke_route_choice_metadata := _has_arg(user_args, engine_args, "--smoke-route-choice-metadata")
	var smoke_expanded_route_choice := _has_arg(user_args, engine_args, "--smoke-expanded-route-choice")
	var smoke_player_facing := _has_arg(user_args, engine_args, "--smoke-player-facing")
	var smoke_movement_feel := _has_arg(user_args, engine_args, "--smoke-movement-feel")
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
	elif capture_player_readability:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_background_depth:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_feedback_overlay:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
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
	elif smoke_session_best_score:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_oxygen_bonus_score:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_route_choice:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_route_choice_metadata:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_expanded_route_choice:
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
		or capture_player_readability
		or capture_background_depth
		or capture_feedback_overlay
		or smoke_salvage_loop
		or smoke_production_slice_route
		or smoke_production_slice_02_route
		or smoke_production_slice_03_route
		or smoke_production_slice_04_route
		or smoke_map_selector
		or smoke_hazard_interaction
		or smoke_oxygen_pressure
		or smoke_cargo_capacity
		or smoke_session_best_score
		or smoke_oxygen_bonus_score
		or smoke_route_choice
		or smoke_route_choice_metadata
		or smoke_expanded_route_choice
		or smoke_player_facing
		or smoke_movement_feel
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
	if smoke_cargo_capacity:
		_smoke_cargo_capacity_and_quit()
		return
	if smoke_session_best_score:
		_smoke_session_best_score_and_quit()
		return
	if smoke_oxygen_bonus_score:
		_smoke_oxygen_bonus_score_and_quit()
		return
	if smoke_route_choice:
		await _smoke_route_choice_and_quit()
		return
	if smoke_route_choice_metadata:
		_smoke_route_choice_metadata_and_quit()
		return
	if smoke_expanded_route_choice:
		await _smoke_expanded_route_choice_and_quit()
		return
	if smoke_player_facing:
		_smoke_player_facing_and_quit()
		return
	if smoke_movement_feel:
		await _smoke_movement_feel_and_quit()
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
	elif capture_player_readability:
		_capture_player_readability_and_quit(PLAYER_READABILITY_CAPTURE_DIR)
	elif capture_background_depth:
		_capture_background_depth_and_quit(BACKGROUND_DEPTH_CAPTURE_DIR)
	elif capture_feedback_overlay:
		_capture_feedback_overlay_and_quit(FEEDBACK_OVERLAY_CAPTURE_DIR)


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
	_held_salvage_score = 0
	_banked_score = 0
	_completion_oxygen_bonus = 0
	_hazard_cooldown_seconds = 0.0
	_hazard_feedback_seconds = 0.0
	_hazard_interactions_enabled = true
	_oxygen_seconds = OXYGEN_MAX_SECONDS
	_run_complete = false
	_run_failed = false
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
	_result_panel = null
	_result_label = null
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
	if _run_complete or _run_failed:
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

	if _held_salvage < HELD_SALVAGE_CAPACITY:
		var collected_salvage: String = _world.collect_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
		if not collected_salvage.is_empty():
			var collected_score: int = _world.get_salvage_score(collected_salvage)
			_held_salvage += 1
			_held_salvage_ids.append(collected_salvage)
			_held_salvage_score += collected_score
			_last_status_note = "Collected salvage +%d" % collected_score
	elif _world.has_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS):
		_last_status_note = "Cargo full - return"

	if _held_salvage > 0 and _world.is_inside_extraction(_player.global_position):
		_banked_salvage += _held_salvage
		_banked_score += _held_salvage_score
		_held_salvage = 0
		_held_salvage_ids = []
		_held_salvage_score = 0
		if _total_salvage > 0 and _banked_salvage >= _total_salvage:
			_run_complete = true
			_completion_oxygen_bonus = _calculate_oxygen_completion_bonus()
			_record_session_best_score()
			_last_status_note = "Run complete"
		else:
			_last_status_note = "Banked salvage"

	_update_status_label()


func _smoke_salvage_loop_and_quit() -> void:
	if _total_salvage <= 0:
		push_error("Salvage loop smoke requires a map with authored salvage.")
		get_tree().quit(1)
		return

	var expected_score := 0
	for salvage in _world.get_salvage_centers():
		expected_score += int(salvage.get("score", 0))
		_player.global_position = salvage["center"]
		_process(0.0)
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			_player.global_position = _world.get_extraction_center()
			_process(0.0)

	_player.global_position = _world.get_extraction_center()
	_process(0.0)

	if not _run_complete:
		push_error("Salvage loop smoke did not complete after collecting and returning.")
		get_tree().quit(1)
		return
	if _result_panel == null or not _result_panel.visible or _result_label == null:
		push_error("Salvage loop smoke did not show the expedition result panel on completion.")
		get_tree().quit(1)
		return
	var expected_bonus := _completion_oxygen_bonus
	var expected_total_score := expected_score + expected_bonus
	if _result_label.text.find("Score %d" % expected_total_score) == -1 or _result_label.text.find("salvage %d + oxygen %d" % [expected_score, _completion_oxygen_bonus]) == -1 or _result_label.text.find("Salvage %d/%d" % [_banked_salvage, _total_salvage]) == -1:
		push_error("Salvage loop smoke result panel did not report score/salvage: %s" % _result_label.text)
		get_tree().quit(1)
		return
	if _banked_score != expected_score:
		push_error("Salvage loop smoke banked score %d, expected %d." % [_banked_score, expected_score])
		get_tree().quit(1)
		return

	var completed_total := _total_salvage
	var completed_score := _banked_score
	_reset_run()
	if _held_salvage != 0 or _banked_salvage != 0 or _held_salvage_score != 0 or _banked_score != 0 or _completion_oxygen_bonus != 0 or _run_complete or _run_failed:
		push_error("Salvage loop smoke reset left stale run state.")
		get_tree().quit(1)
		return

	print("Salvage loop smoke passed: collected, banked %d score, completed, and reset %d salvage." % [completed_score, completed_total])
	get_tree().quit()


func _smoke_session_best_score_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Session best score smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if _total_salvage <= 0:
		push_error("Session best score smoke requires authored salvage.")
		get_tree().quit(1)
		return
	if _session_best_score() != 0:
		push_error("Session best score smoke expected a fresh map best of 0, got %d." % _session_best_score())
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var salvage_targets: Array = _world.get_salvage_centers()
	var expected_score := 0
	for salvage in salvage_targets:
		expected_score += int(salvage.get("score", 0))
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			_player.global_position = _world.get_extraction_center()
			_process(0.0)
		_player.global_position = salvage["center"]
		_process(0.0)

	if _held_salvage > 0:
		_player.global_position = _world.get_extraction_center()
		_process(0.0)

	if not _run_complete or _banked_score != expected_score:
		push_error("Session best score smoke expected complete score %d, got complete=%s score=%d." % [expected_score, str(_run_complete), _banked_score])
		get_tree().quit(1)
		return
	var expected_bonus := _completion_oxygen_bonus
	var expected_total_score := expected_score + expected_bonus
	if _session_best_score() != expected_total_score:
		push_error("Session best score smoke expected best score %d after completion, got %d." % [expected_total_score, _session_best_score()])
		get_tree().quit(1)
		return
	if _result_panel == null or not _result_panel.visible or _result_label == null:
		push_error("Session best score smoke did not show result panel after completion.")
		get_tree().quit(1)
		return
	if _result_label.text.find("Score %d" % expected_total_score) == -1 or _result_label.text.find("Best %d" % expected_total_score) == -1:
		push_error("Session best score smoke result panel did not show score and best: %s" % _result_label.text)
		get_tree().quit(1)
		return

	_reset_run()
	if _session_best_score() != expected_total_score:
		push_error("Session best score smoke reset cleared best score; expected %d got %d." % [expected_total_score, _session_best_score()])
		get_tree().quit(1)
		return
	if _result_panel != null and _result_panel.visible:
		push_error("Session best score smoke reset left result panel visible.")
		get_tree().quit(1)
		return

	var failure_score := expected_total_score + 100
	_banked_score = failure_score
	_banked_salvage = 1
	_handle_oxygen_depleted()
	_update_status_label()
	if not _run_failed or _session_best_score() != expected_total_score:
		push_error("Session best score smoke failure changed best score; failed=%s best=%d expected=%d." % [str(_run_failed), _session_best_score(), expected_total_score])
		get_tree().quit(1)
		return
	if _result_label == null or _result_label.text.find("Score %d" % failure_score) == -1 or _result_label.text.find("Best %d" % expected_total_score) == -1:
		push_error("Session best score smoke failure panel did not preserve best score: %s" % _result_label.text)
		get_tree().quit(1)
		return

	_reset_run()
	_load_playable_map(PRODUCTION_SLICE_02_MAP_PATH, false)
	if _world.map_id != "production_slice_02" or _session_best_score() != 0:
		push_error("Session best score smoke expected production_slice_02 best to start at 0, got map=%s best=%d." % [_world.map_id, _session_best_score()])
		get_tree().quit(1)
		return
	_load_playable_map(PRODUCTION_SLICE_MAP_PATH, false)
	if _world.map_id != "production_slice_01" or _session_best_score() != expected_total_score:
		push_error("Session best score smoke expected production_slice_01 best %d after map reload, got map=%s best=%d." % [expected_total_score, _world.map_id, _session_best_score()])
		get_tree().quit(1)
		return

	print("Session best score smoke passed: salvage=%d oxygen_bonus=%d best=%d failure_score=%d map_scope=production_slice_01." % [
		expected_score,
		expected_bonus,
		_session_best_score(),
		failure_score,
	])
	get_tree().quit()


func _smoke_oxygen_bonus_score_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Oxygen bonus score smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if _total_salvage <= 0:
		push_error("Oxygen bonus score smoke requires authored salvage.")
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var expected_salvage_score := 0
	for salvage in _world.get_salvage_centers():
		expected_salvage_score += int(salvage.get("score", 0))
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			_player.global_position = _world.get_extraction_center()
			_process(0.0)
		_player.global_position = salvage["center"]
		_process(0.0)

	if _held_salvage > 0:
		_player.global_position = _world.get_extraction_center()
		_process(0.0)

	var expected_bonus := int(ceil(_oxygen_seconds)) * OXYGEN_BONUS_POINTS_PER_SECOND
	var expected_total_score := expected_salvage_score + expected_bonus
	if not _run_complete:
		push_error("Oxygen bonus score smoke did not complete run.")
		get_tree().quit(1)
		return
	if _banked_score != expected_salvage_score:
		push_error("Oxygen bonus score smoke changed salvage banked score; got %d expected %d." % [_banked_score, expected_salvage_score])
		get_tree().quit(1)
		return
	if _completion_oxygen_bonus != expected_bonus or _current_expedition_score() != expected_total_score:
		push_error("Oxygen bonus score smoke expected salvage %d + bonus %d = %d, got bonus=%d total=%d." % [expected_salvage_score, expected_bonus, expected_total_score, _completion_oxygen_bonus, _current_expedition_score()])
		get_tree().quit(1)
		return
	if expected_bonus <= 0 or expected_bonus > OXYGEN_MAX_SECONDS * OXYGEN_BONUS_POINTS_PER_SECOND:
		push_error("Oxygen bonus score smoke computed out-of-range bonus %d." % expected_bonus)
		get_tree().quit(1)
		return
	if _result_label == null or _result_label.text.find("Score %d" % expected_total_score) == -1 or _result_label.text.find("salvage %d + oxygen %d" % [expected_salvage_score, expected_bonus]) == -1:
		push_error("Oxygen bonus score smoke result panel did not report score breakdown: %s" % _result_label.text)
		get_tree().quit(1)
		return

	_reset_run()
	_banked_score = expected_salvage_score
	_banked_salvage = 1
	_oxygen_seconds = 0.0
	_handle_oxygen_depleted()
	_update_status_label()
	if not _run_failed or _completion_oxygen_bonus != 0:
		push_error("Oxygen bonus score smoke failure received completion bonus; failed=%s bonus=%d." % [str(_run_failed), _completion_oxygen_bonus])
		get_tree().quit(1)
		return
	if _result_label == null or _result_label.text.find("Score %d" % expected_salvage_score) == -1 or _result_label.text.find("oxygen 0") == -1:
		push_error("Oxygen bonus score smoke failure panel did not show zero oxygen bonus: %s" % _result_label.text)
		get_tree().quit(1)
		return

	_reset_run()
	print("Oxygen bonus score smoke passed: salvage=%d oxygen_bonus=%d total=%d failure_bonus=0." % [
		expected_salvage_score,
		expected_bonus,
		expected_total_score,
	])
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
	var salvage_targets: Array = _world.get_salvage_centers()
	var extraction_center: Vector2 = _world.get_extraction_center()
	for salvage in salvage_targets:
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			if _world.find_open_path(_player.global_position, extraction_center).is_empty():
				push_error("%s route smoke found no open return route to %s." % [expected_map_id, extraction_label])
				get_tree().quit(1)
				return
			_player.global_position = extraction_center
			_process(0.0)
		var salvage_id := str(salvage.get("id", "salvage"))
		var target_center: Vector2 = salvage["center"]
		if _world.find_open_path(_player.global_position, target_center).is_empty():
			push_error("%s route smoke found no open route to %s." % [expected_map_id, salvage_id])
			get_tree().quit(1)
			return

		_player.global_position = target_center
		_process(0.0)
		if not _world.is_salvage_collected(salvage_id):
			push_error("%s route smoke did not collect reachable salvage %s; held=%d." % [expected_map_id, salvage_id, _held_salvage])
			get_tree().quit(1)
			return

	if _held_salvage > 0:
		if _world.find_open_path(_player.global_position, extraction_center).is_empty():
			push_error("%s route smoke found no final open return route to %s." % [expected_map_id, extraction_label])
			get_tree().quit(1)
			return
		_player.global_position = extraction_center
		_process(0.0)

	if not _run_complete:
		push_error("%s route smoke did not complete after swimming through salvage route." % expected_map_id)
		get_tree().quit(1)
		return

	var completed_total := _total_salvage
	_reset_run()
	print("%s route smoke passed: checked routes to %d salvage and banked at %s." % [
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
	if not _run_failed:
		push_error("Oxygen pressure smoke did not enter a failed retry state.")
		get_tree().quit(1)
		return
	if _result_panel == null or not _result_panel.visible or _result_label.text.find("Expedition failed") == -1:
		push_error("Oxygen pressure smoke did not show failed expedition result panel: %s" % _result_label.text)
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

	_reset_run()
	if _run_failed or _held_salvage != 0 or _banked_salvage != 0 or _banked_score != 0:
		push_error("Oxygen pressure smoke reset did not clear failed run state.")
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


func _smoke_cargo_capacity_and_quit() -> void:
	var salvage: Array = _world.get_salvage_centers()
	if salvage.size() <= HELD_SALVAGE_CAPACITY:
		push_error("Cargo capacity smoke requires more salvage than capacity.")
		get_tree().quit(1)
		return

	for index in range(HELD_SALVAGE_CAPACITY):
		_player.global_position = salvage[index]["center"]
		_process(0.0)

	var expected_held_score := 0
	for index in range(HELD_SALVAGE_CAPACITY):
		expected_held_score += int(salvage[index].get("score", 0))

	if _held_salvage != HELD_SALVAGE_CAPACITY:
		push_error("Cargo capacity smoke expected held cargo to reach capacity, got %d." % _held_salvage)
		get_tree().quit(1)
		return
	if _held_salvage_score != expected_held_score or _banked_score != 0:
		push_error("Cargo capacity smoke expected held score %d and banked score 0 before extraction, got held score %d banked score %d." % [expected_held_score, _held_salvage_score, _banked_score])
		get_tree().quit(1)
		return

	var blocked_id := str(salvage[HELD_SALVAGE_CAPACITY].get("id", "salvage"))
	var blocked_score := int(salvage[HELD_SALVAGE_CAPACITY].get("score", 0))
	_player.global_position = salvage[HELD_SALVAGE_CAPACITY]["center"]
	_process(0.0)
	if _held_salvage != HELD_SALVAGE_CAPACITY or _held_salvage_ids.has(blocked_id):
		push_error("Cargo capacity smoke collected beyond capacity; held=%d ids=%s." % [_held_salvage, _held_salvage_ids])
		get_tree().quit(1)
		return
	if not _world.has_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS):
		push_error("Cargo capacity smoke lost blocked salvage %s." % blocked_id)
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage != HELD_SALVAGE_CAPACITY:
		push_error("Cargo capacity smoke did not bank and free capacity; held=%d banked=%d." % [_held_salvage, _banked_salvage])
		get_tree().quit(1)
		return
	if _held_salvage_score != 0 or _banked_score != expected_held_score:
		push_error("Cargo capacity smoke did not move held score into banked score; held score=%d banked score=%d expected=%d." % [_held_salvage_score, _banked_score, expected_held_score])
		get_tree().quit(1)
		return

	_player.global_position = salvage[HELD_SALVAGE_CAPACITY]["center"]
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids[0] != blocked_id:
		push_error("Cargo capacity smoke could not collect blocked salvage after banking.")
		get_tree().quit(1)
		return
	if _held_salvage_score != blocked_score:
		push_error("Cargo capacity smoke collected blocked salvage with held score %d, expected %d." % [_held_salvage_score, blocked_score])
		get_tree().quit(1)
		return

	_reset_run()
	print("Cargo capacity smoke passed: held=%d capacity=%d held_score=%d banked=%d banked_score=%d blocked=%s blocked_score=%d." % [
		1,
		HELD_SALVAGE_CAPACITY,
		blocked_score,
		HELD_SALVAGE_CAPACITY,
		expected_held_score,
		blocked_id,
		blocked_score,
	])
	get_tree().quit()


func _smoke_route_choice_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Route choice probe loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if not _player.has_method("swim_in_direction"):
		push_error("Route choice probe requires player swim_in_direction().")
		get_tree().quit(1)
		return

	var salvage: Array = _world.get_salvage_centers()
	if salvage.is_empty():
		push_error("Route choice probe requires authored salvage.")
		get_tree().quit(1)
		return

	var target: Dictionary = _route_choice_target(salvage)
	if target.is_empty():
		push_error("Route choice probe requires one authored valuable salvage target.")
		get_tree().quit(1)
		return
	var target_id := str(target.get("id", "salvage"))
	var target_center: Vector2 = target["center"]
	var extraction_center: Vector2 = _world.get_extraction_center()

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	var reached_target := await _swim_to_target(target_center)
	if not reached_target:
		get_tree().quit(1)
		return
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids.is_empty() or _held_salvage_ids[0] != target_id:
		push_error("Route choice probe did not collect target %s; held=%d ids=%s." % [target_id, _held_salvage, _held_salvage_ids])
		get_tree().quit(1)
		return

	var reached_extraction := await _swim_to_target(extraction_center)
	if not reached_extraction:
		get_tree().quit(1)
		return
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage < 1 or not _world.is_inside_extraction(_player.global_position):
		push_error("Route choice probe did not return/bank target %s; held=%d banked=%d position=%s." % [target_id, _held_salvage, _banked_salvage, _player.global_position])
		get_tree().quit(1)
		return

	var oxygen_after_return := _oxygen_seconds
	var completed_after_return := _run_complete
	var banked_after_return := _banked_salvage
	var score_after_return := _banked_score
	var target_score := int(target.get("score", 0))
	if score_after_return < target_score:
		push_error("Route choice probe banked score %d below target score %d." % [score_after_return, target_score])
		get_tree().quit(1)
		return
	_reset_run()
	print("Route choice probe passed: target=%s collected=1 banked=%d score=%d returned_to=boat extraction run_complete=%s oxygen=%.1f." % [target_id, banked_after_return, score_after_return, str(completed_after_return), oxygen_after_return])
	get_tree().quit()


func _smoke_expanded_route_choice_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Expanded route choice probe loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if not _player.has_method("swim_in_direction"):
		push_error("Expanded route choice probe requires player swim_in_direction().")
		get_tree().quit(1)
		return

	var route_targets: Array = _route_choice_targets_for_route(_world.get_salvage_centers(), EXPANDED_ROUTE_CHOICE_ID)
	if route_targets.size() < 2:
		push_error("Expanded route choice probe requires at least two targets for validation_route=%s, got %d." % [EXPANDED_ROUTE_CHOICE_ID, route_targets.size()])
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	var target_ids := PackedStringArray()
	for target in route_targets:
		var target_id := str(target.get("id", "salvage"))
		target_ids.append(target_id)
		var reached_target := await _swim_to_target(target["center"])
		if not reached_target:
			get_tree().quit(1)
			return
		_process(0.0)
		if not _held_salvage_ids.has(target_id):
			push_error("Expanded route choice probe did not collect target %s; held=%d ids=%s." % [target_id, _held_salvage, _held_salvage_ids])
			get_tree().quit(1)
			return

	var expected_score := 0
	for target in route_targets:
		expected_score += int(target.get("score", 0))
	if _held_salvage != route_targets.size() or _held_salvage_score != expected_score:
		push_error("Expanded route choice probe expected %d held pickups worth %d, got held=%d score=%d ids=%s." % [route_targets.size(), expected_score, _held_salvage, _held_salvage_score, _held_salvage_ids])
		get_tree().quit(1)
		return

	var reached_return_waypoint := await _swim_to_target(route_targets[0]["center"])
	if not reached_return_waypoint:
		get_tree().quit(1)
		return

	var extraction_center: Vector2 = _world.get_extraction_center()
	var reached_extraction := await _swim_to_target(extraction_center)
	if not reached_extraction:
		get_tree().quit(1)
		return
	_process(0.0)

	if _held_salvage != 0 or _banked_salvage < route_targets.size() or _banked_score < expected_score or not _world.is_inside_extraction(_player.global_position):
		push_error("Expanded route choice probe did not bank both targets; held=%d banked=%d score=%d position=%s." % [_held_salvage, _banked_salvage, _banked_score, _player.global_position])
		get_tree().quit(1)
		return

	var oxygen_after_return := _oxygen_seconds
	var banked_after_return := _banked_salvage
	var score_after_return := _banked_score
	_reset_run()
	print("Expanded route choice probe passed: route=%s targets=%s held_capacity=%d banked=%d score=%d returned_to=boat extraction oxygen=%.1f." % [
		EXPANDED_ROUTE_CHOICE_ID,
		",".join(target_ids),
		HELD_SALVAGE_CAPACITY,
		banked_after_return,
		score_after_return,
		oxygen_after_return,
	])
	get_tree().quit()


func _smoke_route_choice_metadata_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Route choice metadata smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return

	var salvage: Array = _world.get_salvage_centers()
	var route_targets: Array = _route_choice_targets_for_route(salvage, EXPANDED_ROUTE_CHOICE_ID)
	if route_targets.size() < 2:
		push_error("Route choice metadata smoke requires at least two targets for validation_route=%s, got %d." % [EXPANDED_ROUTE_CHOICE_ID, route_targets.size()])
		get_tree().quit(1)
		return

	var default_target := _route_choice_target(salvage)
	if default_target.is_empty():
		push_error("Route choice metadata smoke requires a default valuable target.")
		get_tree().quit(1)
		return
	if str(default_target.get("id", "")) != str(route_targets[0].get("id", "")):
		push_error("Route choice metadata smoke expected first ordered route target %s to match default route target %s." % [str(route_targets[0].get("id", "")), str(default_target.get("id", ""))])
		get_tree().quit(1)
		return

	var extraction_center: Vector2 = _world.get_extraction_center()
	var previous_order := -1
	var target_ids := PackedStringArray()
	var target_orders := PackedStringArray()
	var target_scores := PackedStringArray()
	for target in route_targets:
		var target_id := str(target.get("id", "salvage"))
		var route_choice_id := str(target.get("route_choice_id", ""))
		var route_order := int(target.get("route_order", -1))
		target_ids.append(target_id)
		target_orders.append(str(route_order))
		target_scores.append(str(int(target.get("score", 0))))

		if route_choice_id.is_empty():
			push_error("Route choice metadata smoke found target %s without route_choice_id." % target_id)
			get_tree().quit(1)
			return
		if not bool(target.get("has_route_order", false)):
			push_error("Route choice metadata smoke found target %s without route_order." % target_id)
			get_tree().quit(1)
			return
		if route_order <= previous_order:
			push_error("Route choice metadata smoke found non-increasing route_order at %s: %d after %d." % [target_id, route_order, previous_order])
			get_tree().quit(1)
			return
		if str(target.get("tier", "common")) != "valuable":
			push_error("Route choice metadata smoke expected target %s to be valuable." % target_id)
			get_tree().quit(1)
			return
		if int(target.get("score", 0)) <= 0:
			push_error("Route choice metadata smoke expected target %s to have positive score." % target_id)
			get_tree().quit(1)
			return

		var target_center: Vector2 = target["center"]
		if _world.find_open_path(_world.spawn_position, target_center).is_empty():
			push_error("Route choice metadata smoke found no open route from spawn to %s." % target_id)
			get_tree().quit(1)
			return
		if _world.find_open_path(target_center, extraction_center).is_empty():
			push_error("Route choice metadata smoke found no open return route from %s to extraction." % target_id)
			get_tree().quit(1)
			return

		previous_order = route_order

	print("Route choice metadata smoke passed: route=%s targets=%s orders=%s scores=%s first_target=%s." % [
		EXPANDED_ROUTE_CHOICE_ID,
		",".join(target_ids),
		",".join(target_orders),
		",".join(target_scores),
		str(default_target.get("id", "")),
	])
	get_tree().quit()


func _route_choice_target(salvage: Array) -> Dictionary:
	for item in salvage:
		if str(item.get("tier", "common")) == "valuable":
			return item
	return {}


func _route_choice_targets_for_route(salvage: Array, route_id: String) -> Array:
	var targets: Array = []
	for item in salvage:
		if str(item.get("validation_route", "")) == route_id:
			targets.append(item)
	targets.sort_custom(Callable(self, "_sort_route_choice_targets"))
	return targets


func _sort_route_choice_targets(a: Dictionary, b: Dictionary) -> bool:
	var a_order := int(a.get("route_order", 0))
	var b_order := int(b.get("route_order", 0))
	if a_order != b_order:
		return a_order < b_order
	return str(a.get("id", "")) < str(b.get("id", ""))


func _smoke_player_facing_and_quit() -> void:
	if not _player.has_method("swim_in_direction") or not _player.has_method("get_facing_report"):
		push_error("Player facing smoke requires swim_in_direction() and get_facing_report().")
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_player.swim_in_direction(Vector2.RIGHT, 1.0 / 60.0)
	var right_report: Dictionary = _player.get_facing_report()
	_player.swim_in_direction(Vector2.LEFT, 1.0 / 60.0)
	var left_report: Dictionary = _player.get_facing_report()
	_player.swim_in_direction(Vector2.RIGHT, 1.0 / 60.0)
	var restored_report: Dictionary = _player.get_facing_report()

	if not _facing_report_matches(right_report, false, 88.0, 1.0):
		push_error("Player facing smoke expected right-facing visual children, got %s." % right_report)
		get_tree().quit(1)
		return
	if not _facing_report_matches(left_report, true, -88.0, -1.0):
		push_error("Player facing smoke expected left-facing visual children, got %s." % left_report)
		get_tree().quit(1)
		return
	if not _facing_report_matches(restored_report, false, 88.0, 1.0):
		push_error("Player facing smoke expected restored right-facing visual children, got %s." % restored_report)
		get_tree().quit(1)
		return

	print("Player facing smoke passed: root scale stayed stable while visual children flipped left/right.")
	get_tree().quit()


func _smoke_movement_feel_and_quit() -> void:
	if not _player.has_method("swim_in_direction"):
		push_error("Movement feel probe requires player swim_in_direction().")
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = MOVEMENT_FEEL_PROBE_CENTER_TILES * float(_world.tile_size)
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	await _swim_for_frames(Vector2.RIGHT, 15)
	var start_velocity: Vector2 = _player.velocity
	await _swim_for_frames(Vector2.ZERO, 15)
	var stop_velocity: Vector2 = _player.velocity
	await _swim_for_frames(Vector2.LEFT, 20)
	var reverse_velocity: Vector2 = _player.velocity
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	await _swim_for_frames(Vector2(1.0, -1.0), 15)
	var diagonal_velocity: Vector2 = _player.velocity

	if start_velocity.x <= 0.0:
		push_error("Movement feel probe expected positive x velocity after right input, got %s." % start_velocity)
		get_tree().quit(1)
		return
	if stop_velocity.length() >= start_velocity.length():
		push_error("Movement feel probe expected stop phase to slow the player, got start %s stop %s." % [start_velocity, stop_velocity])
		get_tree().quit(1)
		return
	if reverse_velocity.x >= 0.0:
		push_error("Movement feel probe expected negative x velocity after left reversal, got %s." % reverse_velocity)
		get_tree().quit(1)
		return
	if diagonal_velocity.length() > _player.swim_speed + 1.0:
		push_error("Movement feel probe expected diagonal speed to stay normalized, got %s." % diagonal_velocity)
		get_tree().quit(1)
		return

	print("Movement feel probe passed: start=%s stop=%s reverse=%s diagonal=%s." % [
		_format_vector(start_velocity),
		_format_vector(stop_velocity),
		_format_vector(reverse_velocity),
		_format_vector(diagonal_velocity),
	])
	get_tree().quit()


func _swim_for_frames(direction: Vector2, frame_count: int) -> void:
	for _frame in range(frame_count):
		_player.swim_in_direction(direction, 1.0 / 60.0)
		await get_tree().physics_frame


func _format_vector(value: Vector2) -> String:
	return "(%.1f, %.1f)" % [value.x, value.y]


func _facing_report_matches(report: Dictionary, body_flip_h: bool, light_x: float, light_scale_x: float) -> bool:
	return (
		is_equal_approx(float(report.get("root_scale_x", 0.0)), 1.0)
		and bool(report.get("body_flip_h", not body_flip_h)) == body_flip_h
		and is_equal_approx(float(report.get("light_cone_position_x", 0.0)), light_x)
		and is_equal_approx(float(report.get("light_cone_scale_x", 0.0)), light_scale_x)
	)


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
	_held_salvage_score = 0
	_banked_salvage = 0
	_banked_score = 0
	_completion_oxygen_bonus = 0
	_hazard_cooldown_seconds = 0.0
	_hazard_feedback_seconds = 0.0
	_hazard_interactions_enabled = true
	_oxygen_seconds = OXYGEN_MAX_SECONDS
	_run_complete = false
	_run_failed = false
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
		_held_salvage_score = 0
		_last_status_note = "Oxygen depleted - press R"
	else:
		_last_status_note = "Oxygen depleted - press R"

	_oxygen_seconds = OXYGEN_MAX_SECONDS
	_run_failed = true
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
		_held_salvage_score = 0
		_last_status_note = "Hazard hit: dropped held"
	else:
		_last_status_note = "Hazard hit: reset"

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

	_create_result_panel(canvas)


func _create_result_panel(canvas: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.name = "ExpeditionResultPanel"
	panel.position = Vector2(12, 204)
	panel.custom_minimum_size = Vector2(260, 0)
	panel.visible = false
	_result_panel = panel

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.09, 0.12, 0.82)
	panel_style.border_color = Color(1.0, 0.88, 0.45, 0.34)
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

	_result_label = Label.new()
	_result_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 0.96))
	_result_label.add_theme_font_size_override("font_size", 14)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(_result_label)


func _update_status_label() -> void:
	if _status_label == null:
		return

	if _total_salvage <= 0:
		_status_label.text = "Score 0\nSalvage banked 0/0\nHeld 0/%d\nOxygen --" % HELD_SALVAGE_CAPACITY
		_update_result_panel()
		return

	var prompt := ""
	if _run_complete:
		prompt = "Run complete - press R"
	elif _run_failed:
		prompt = "Oxygen depleted - press R"
	elif _held_salvage >= HELD_SALVAGE_CAPACITY:
		prompt = "Cargo full - return"
	elif _held_salvage > 0:
		prompt = "Return to extraction"
	elif not _last_status_note.is_empty():
		prompt = _last_status_note

	var oxygen_seconds := int(ceil(_oxygen_seconds))
	var oxygen_text := "Oxygen %ds" % oxygen_seconds
	if _oxygen_seconds <= OXYGEN_CRITICAL_WARNING_SECONDS and not _run_complete and not _run_failed:
		oxygen_text = "Oxygen %ds CRITICAL" % oxygen_seconds
	elif _oxygen_seconds <= OXYGEN_LOW_WARNING_SECONDS and not _run_complete and not _run_failed:
		oxygen_text = "Oxygen %ds LOW" % oxygen_seconds

	_status_label.text = "Score %d\nSalvage banked %d/%d\nHeld %d/%d (%d pts)\n%s" % [
		_banked_score,
		_banked_salvage,
		_total_salvage,
		_held_salvage,
		HELD_SALVAGE_CAPACITY,
		_held_salvage_score,
		oxygen_text,
	]
	if not prompt.is_empty():
		_status_label.text += "\n%s" % prompt
	_update_result_panel()


func _session_best_map_key() -> String:
	if _world == null:
		return ""
	if not str(_world.map_id).is_empty():
		return str(_world.map_id)
	return str(_world.map_path)


func _session_best_score() -> int:
	var key := _session_best_map_key()
	if key.is_empty():
		return 0
	return int(_session_best_scores_by_map.get(key, 0))


func _current_expedition_score() -> int:
	return _banked_score + _completion_oxygen_bonus


func _calculate_oxygen_completion_bonus() -> int:
	return int(ceil(_oxygen_seconds)) * OXYGEN_BONUS_POINTS_PER_SECOND


func _record_session_best_score() -> void:
	var key := _session_best_map_key()
	if key.is_empty():
		return
	var score := _current_expedition_score()
	if score > _session_best_score():
		_session_best_scores_by_map[key] = score


func _update_result_panel() -> void:
	if _result_panel == null or _result_label == null:
		return
	_result_panel.visible = _run_complete or _run_failed
	if not _run_complete and not _run_failed:
		_result_label.text = ""
		return

	var title := "Expedition complete" if _run_complete else "Expedition failed"
	var oxygen_text := "Oxygen %ds" % int(ceil(_oxygen_seconds))
	if _run_failed:
		oxygen_text = "Oxygen depleted"
	_result_label.text = "%s\nScore %d (salvage %d + oxygen %d)\nBest %d\nSalvage %d/%d\n%s\nPress R to retry" % [
		title,
		_current_expedition_score(),
		_banked_score,
		_completion_oxygen_bonus,
		_session_best_score(),
		_banked_salvage,
		_total_salvage,
		oxygen_text,
	]


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


func _capture_player_readability_and_quit(capture_dir: String) -> void:
	if _world == null or _player == null:
		push_error("Player readability capture requires a loaded playable map.")
		get_tree().quit(1)
		return

	var review_position: Vector2 = _world.spawn_position + PLAYER_READABILITY_ENTRY_OFFSET_TILES * float(_world.tile_size)
	_player.global_position = review_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	var camera := Camera2D.new()
	camera.name = "PlayerReadabilityCaptureCamera"
	camera.zoom = PLAYER_READABILITY_CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_world.map_pixel_size.x)
	camera.limit_bottom = int(_world.map_pixel_size.y)
	add_child(camera)
	camera.make_current()
	camera.position = review_position + Vector2(64, -16)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var view_id := "%s_player_start" % _safe_filename(_world.map_id)
	var output_path := "%s/%s.png" % [capture_dir, view_id]
	var image := get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved player readability capture: %s" % ProjectSettings.globalize_path(output_path))
	get_tree().quit()


func _capture_background_depth_and_quit(capture_dir: String) -> void:
	if _world == null or _player == null:
		push_error("Background depth capture requires a loaded playable map.")
		get_tree().quit(1)
		return

	var review_position: Vector2 = _world.spawn_position + BACKGROUND_DEPTH_PLAYER_OFFSET_TILES * float(_world.tile_size)
	_player.global_position = review_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	var camera := Camera2D.new()
	camera.name = "BackgroundDepthCaptureCamera"
	camera.zoom = BACKGROUND_DEPTH_CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_world.map_pixel_size.x)
	camera.limit_bottom = int(_world.map_pixel_size.y)
	add_child(camera)
	camera.make_current()
	camera.position = BACKGROUND_DEPTH_CENTER_TILES * float(_world.tile_size)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_background_depth.png" % [capture_dir, _safe_filename(_world.map_id)]
	var image := get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved background depth capture: %s" % ProjectSettings.globalize_path(output_path))
	get_tree().quit()


func _capture_feedback_overlay_and_quit(capture_dir: String) -> void:
	if _world == null or _player == null:
		push_error("Feedback overlay capture requires a loaded playable map.")
		get_tree().quit(1)
		return

	var salvage_centers: Array = _world.get_salvage_centers()
	if salvage_centers.is_empty():
		push_error("Feedback overlay capture requires authored salvage.")
		get_tree().quit(1)
		return

	_player.global_position = salvage_centers[0]["center"]
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	_process(0.0)
	_oxygen_seconds = 12.0
	_update_status_label()

	var camera := Camera2D.new()
	camera.name = "FeedbackOverlayCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_world.map_pixel_size.x)
	camera.limit_bottom = int(_world.map_pixel_size.y)
	add_child(camera)
	camera.make_current()
	camera.position = _world.spawn_position + Vector2(180, 180)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_feedback_overlay.png" % [capture_dir, _safe_filename(_world.map_id)]
	var image := get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved feedback overlay capture: %s" % ProjectSettings.globalize_path(output_path))
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
