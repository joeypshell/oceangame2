extends Node2D

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CaptureController := preload("res://scripts/main/capture_controller.gd")
const OxygenRestPocketFeedback := preload("res://scripts/main/oxygen_rest_pocket_feedback.gd")
const PrePickupRouteCueFeedback := preload("res://scripts/main/pre_pickup_route_cue_feedback.gd")
const ReturnPressureFeedback := preload("res://scripts/main/return_pressure_feedback.gd")
const RouteCommitmentFeedback := preload("res://scripts/main/route_commitment_feedback.gd")
const TimedSalvageController := preload("res://scripts/main/timed_salvage_controller.gd")
const SmokeHazardRouteChecks := preload("res://scripts/main/smoke/smoke_hazard_route_checks.gd")
const SmokeInteractionChecks := preload("res://scripts/main/smoke/smoke_interaction_checks.gd")
const SmokeOxygenRestChecks := preload("res://scripts/main/smoke/smoke_oxygen_rest_checks.gd")
const SmokeRouteCommitmentChecks := preload("res://scripts/main/smoke/smoke_route_commitment_checks.gd")
const SmokeRouteExtensionChecks := preload("res://scripts/main/smoke/smoke_route_extension_checks.gd")
const SmokeRouteChecks := preload("res://scripts/main/smoke/smoke_route_checks.gd")
const SmokeScoreChecks := preload("res://scripts/main/smoke/smoke_score_checks.gd")
const DEFAULT_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const ORIGINAL_MAP_PATH := "res://maps/cave_salvage_test_01.greybox.json"
const TILESET_TEST_MAP_PATH := "res://maps/cave_tileset_test_01.greybox.json"
const ORGANIC_MAP_PATH := "res://maps/cave_salvage_organic_01.greybox.json"
const FULL_SKETCH_MAP_PATH := "res://maps/full_cave_sketch_01.greybox.json"
const PRODUCTION_SLICE_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const PRODUCTION_SLICE_02_MAP_PATH := "res://maps/production_slice_02.greybox.json"
const PRODUCTION_SLICE_03_MAP_PATH := "res://maps/production_slice_03.greybox.json"
const PRODUCTION_SLICE_04_MAP_PATH := "res://maps/production_slice_04.greybox.json"
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
const ROUTE_OUTCOME_CAPTURE_DIR := "res://visual_captures/route_outcome"
const TIMED_SALVAGE_CAPTURE_DIR := "res://visual_captures/timed_salvage"
const HAZARD_PRESSURE_CAPTURE_DIR := "res://visual_captures/hazard_pressure"
const ROUTE_EXTENSION_CAPTURE_DIR := "res://visual_captures/route_extension"
const SOUTHWEST_POCKET_DECISION_CAPTURE_DIR := "res://visual_captures/southwest_pocket_decision"
const PASS_10_RETURN_PRESSURE_CAPTURE_DIR := "res://visual_captures/pass_10_return_pressure"
const PASS_11_PRE_PICKUP_ROUTE_CUE_CAPTURE_DIR := "res://visual_captures/pass_11_pre_pickup_route_cue"
const PASS_12_OXYGEN_REST_PRESSURE_CAPTURE_DIR := "res://visual_captures/pass_12_oxygen_rest_pressure"
const PASS_13_ROUTE_COMMITMENT_CAPTURE_DIR := "res://visual_captures/pass_13_route_commitment"
const BUILD_INFO_PATH := "res://build_info.json"
const MOVEMENT_FEEL_PROBE_CENTER_TILES := Vector2(42, 25)
const SALVAGE_COLLECTION_RADIUS := 34.0
const HELD_SALVAGE_CAPACITY := 2
const HAZARD_CONTACT_RADIUS := 30.0
const HAZARD_WARNING_RADIUS := 80.0
const HAZARD_OXYGEN_PENALTY_SECONDS := 12.0
const HAZARD_COOLDOWN_SECONDS := 1.0
const HAZARD_FEEDBACK_SECONDS := 0.45
const PASS_07_PRESSURE_SEGMENT_ID := "lower_loop_to_deep_cache_pressure"
const PASS_07_PRESSURE_HAZARD_ID := "hazard_right_branch"
const GENERIC_HAZARD_WARNING_PROMPT := "Hazard nearby - keep clear"
const PRESSURE_HAZARD_WARNING_PROMPT := "Hazard ahead - keep clear"
const OXYGEN_MAX_SECONDS := 90.0
const OXYGEN_REFILL_SECONDS_PER_SECOND := 25.0
const OXYGEN_LOW_WARNING_SECONDS := 40.0
const OXYGEN_CRITICAL_WARNING_SECONDS := 15.0
const OXYGEN_BONUS_POINTS_PER_SECOND := 1
const SAFE_ROUTE_CHOICE_ID := "safe_route_choice"
const EXPANDED_ROUTE_CHOICE_ID := "expanded_route_choice"
const SOUTHWEST_POCKET_DECISION_ID := "southwest_pocket_decision"
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
var _capture_controller
var _oxygen_rest_feedback
var _pre_pickup_route_cue_feedback
var _return_pressure_feedback
var _route_commitment_feedback
var _timed_salvage
var _smoke_hazard_route_checks
var _smoke_interaction_checks
var _smoke_oxygen_rest_checks
var _smoke_route_commitment_checks
var _smoke_route_extension_checks
var _smoke_route_checks
var _smoke_score_checks
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
var _banked_salvage_ids: Array[String] = []
var _held_salvage_score := 0
var _banked_score := 0
var _completion_oxygen_bonus := 0
var _session_best_scores_by_map := {}
var _salvage_validation_routes_by_id := {}
var _banked_validation_route_counts := {}
var _hazard_cooldown_seconds := 0.0
var _hazard_feedback_seconds := 0.0
var _hazard_interactions_enabled := true
var _hazard_warning_id := ""
var _oxygen_seconds := OXYGEN_MAX_SECONDS
var _run_complete := false
var _run_failed := false
var _last_status_note := ""


func _ready() -> void:
	_capture_controller = CaptureController.new(self)
	_oxygen_rest_feedback = OxygenRestPocketFeedback.new()
	_pre_pickup_route_cue_feedback = PrePickupRouteCueFeedback.new()
	_return_pressure_feedback = ReturnPressureFeedback.new()
	_route_commitment_feedback = RouteCommitmentFeedback.new()
	_timed_salvage = TimedSalvageController.new()
	_smoke_hazard_route_checks = SmokeHazardRouteChecks.new(self)
	_smoke_interaction_checks = SmokeInteractionChecks.new(self)
	_smoke_oxygen_rest_checks = SmokeOxygenRestChecks.new(self)
	_smoke_route_commitment_checks = SmokeRouteCommitmentChecks.new(self)
	_smoke_route_extension_checks = SmokeRouteExtensionChecks.new(self)
	_smoke_route_checks = SmokeRouteChecks.new(self)
	_smoke_score_checks = SmokeScoreChecks.new(self)
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
	var capture_route_outcome := _has_arg(user_args, engine_args, "--capture-route-outcome-result")
	var capture_timed_salvage := _has_arg(user_args, engine_args, "--capture-timed-salvage")
	var capture_hazard_pressure := _has_arg(user_args, engine_args, "--capture-pass-07-hazard-pressure")
	var capture_route_extension := _has_arg(user_args, engine_args, "--capture-pass-08-route-extension")
	var capture_southwest_pocket_decision := _has_arg(user_args, engine_args, "--capture-pass-09-southwest-pocket-decision")
	var capture_pass_10_return_pressure := _has_arg(user_args, engine_args, "--capture-pass-10-return-pressure")
	var capture_pass_11_pre_pickup_route_cue := _has_arg(user_args, engine_args, "--capture-pass-11-pre-pickup-route-cue")
	var capture_pass_12_oxygen_rest_pressure := _has_arg(user_args, engine_args, "--capture-pass-12-oxygen-rest-pressure")
	var capture_pass_13_route_commitment := _has_arg(user_args, engine_args, "--capture-pass-13-route-commitment")
	var check_map_parity := _has_arg(user_args, engine_args, "--check-map-parity")
	var smoke_salvage_loop := _has_arg(user_args, engine_args, "--smoke-salvage-loop")
	var smoke_production_slice_route := _has_arg(user_args, engine_args, "--smoke-production-slice-route")
	var smoke_production_slice_02_route := _has_arg(user_args, engine_args, "--smoke-production-slice-02-route")
	var smoke_production_slice_03_route := _has_arg(user_args, engine_args, "--smoke-production-slice-03-route")
	var smoke_production_slice_04_route := _has_arg(user_args, engine_args, "--smoke-production-slice-04-route")
	var smoke_map_selector := _has_arg(user_args, engine_args, "--smoke-map-selector")
	var smoke_hazard_interaction := _has_arg(user_args, engine_args, "--smoke-hazard-interaction")
	var smoke_hazard_pressure := _has_arg(user_args, engine_args, "--smoke-hazard-pressure")
	var smoke_pass_07_hazard_route_pressure := _has_arg(user_args, engine_args, "--smoke-pass-07-hazard-route-pressure")
	var smoke_pass_08_route_extension := _has_arg(user_args, engine_args, "--smoke-pass-08-route-extension")
	var smoke_pass_09_southwest_pocket_decision := _has_arg(user_args, engine_args, "--smoke-pass-09-southwest-pocket-decision")
	var smoke_pass_10_return_pressure := _has_arg(user_args, engine_args, "--smoke-pass-10-return-pressure")
	var smoke_pass_11_pre_pickup_route_cue := _has_arg(user_args, engine_args, "--smoke-pass-11-pre-pickup-route-cue")
	var smoke_pass_12_oxygen_rest_pressure := _has_arg(user_args, engine_args, "--smoke-pass-12-oxygen-rest-pressure")
	var smoke_pass_13_route_commitment := _has_arg(user_args, engine_args, "--smoke-pass-13-route-commitment")
	var smoke_pass_14_objective_cue := _has_arg(user_args, engine_args, "--smoke-pass-14-objective-cue")
	var smoke_oxygen_pressure := _has_arg(user_args, engine_args, "--smoke-oxygen-pressure")
	var smoke_timed_salvage := _has_arg(user_args, engine_args, "--smoke-timed-salvage")
	var smoke_cargo_capacity := _has_arg(user_args, engine_args, "--smoke-cargo-capacity")
	var smoke_salvage_feedback := _has_arg(user_args, engine_args, "--smoke-salvage-feedback")
	var smoke_session_best_score := _has_arg(user_args, engine_args, "--smoke-session-best-score")
	var smoke_oxygen_bonus_score := _has_arg(user_args, engine_args, "--smoke-oxygen-bonus-score")
	var smoke_route_outcome_result := _has_arg(user_args, engine_args, "--smoke-route-outcome-result")
	var smoke_route_choice := _has_arg(user_args, engine_args, "--smoke-route-choice")
	var smoke_route_choice_metadata := _has_arg(user_args, engine_args, "--smoke-route-choice-metadata")
	var smoke_expanded_route_choice := _has_arg(user_args, engine_args, "--smoke-expanded-route-choice")
	var smoke_safe_deep_route_choice := _has_arg(user_args, engine_args, "--smoke-safe-deep-route-choice")
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
	elif capture_route_outcome:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_timed_salvage:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_hazard_pressure:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_route_extension:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_southwest_pocket_decision:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_10_return_pressure:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_11_pre_pickup_route_cue:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_12_oxygen_rest_pressure:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_13_route_commitment:
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
	elif smoke_hazard_pressure:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_07_hazard_route_pressure:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_08_route_extension:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_09_southwest_pocket_decision:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_10_return_pressure:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_11_pre_pickup_route_cue:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_13_route_commitment:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_14_objective_cue:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_oxygen_pressure:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_timed_salvage:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_session_best_score:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_salvage_feedback:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_oxygen_bonus_score:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_route_outcome_result:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_route_choice:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_route_choice_metadata:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_expanded_route_choice:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_safe_deep_route_choice:
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
		or capture_route_outcome
		or capture_timed_salvage
		or capture_hazard_pressure
		or capture_route_extension
		or capture_southwest_pocket_decision
		or capture_pass_10_return_pressure
		or capture_pass_11_pre_pickup_route_cue
		or capture_pass_12_oxygen_rest_pressure
		or capture_pass_13_route_commitment
		or smoke_salvage_loop
		or smoke_production_slice_route
		or smoke_production_slice_02_route
		or smoke_production_slice_03_route
		or smoke_production_slice_04_route
		or smoke_map_selector
		or smoke_hazard_interaction
		or smoke_hazard_pressure
		or smoke_pass_07_hazard_route_pressure
		or smoke_pass_08_route_extension
		or smoke_pass_09_southwest_pocket_decision
		or smoke_pass_10_return_pressure
		or smoke_pass_11_pre_pickup_route_cue
		or smoke_pass_12_oxygen_rest_pressure
		or smoke_pass_13_route_commitment
		or smoke_pass_14_objective_cue
		or smoke_oxygen_pressure
		or smoke_timed_salvage
		or smoke_cargo_capacity
		or smoke_salvage_feedback
		or smoke_session_best_score
		or smoke_oxygen_bonus_score
		or smoke_route_outcome_result
		or smoke_route_choice
		or smoke_route_choice_metadata
		or smoke_expanded_route_choice
		or smoke_safe_deep_route_choice
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
		_smoke_score_checks._smoke_salvage_loop_and_quit()
		return
	if smoke_production_slice_route:
		await _smoke_route_checks._smoke_salvage_route_and_quit("production_slice_01", "boat extraction")
		return
	if smoke_production_slice_02_route:
		await _smoke_route_checks._smoke_salvage_route_and_quit("production_slice_02", "relay extraction")
		return
	if smoke_production_slice_03_route:
		await _smoke_route_checks._smoke_salvage_route_and_quit("production_slice_03", "relay extraction")
		return
	if smoke_production_slice_04_route:
		await _smoke_route_checks._smoke_salvage_route_and_quit("production_slice_04", "relay extraction")
		return
	if smoke_map_selector:
		_smoke_interaction_checks._smoke_map_selector_and_quit()
		return
	if smoke_hazard_interaction:
		_smoke_interaction_checks._smoke_hazard_interaction_and_quit()
		return
	if smoke_hazard_pressure:
		_smoke_interaction_checks._smoke_hazard_interaction_and_quit()
		return
	if smoke_pass_07_hazard_route_pressure:
		_smoke_hazard_route_checks._smoke_pass_07_hazard_route_pressure_and_quit()
		return
	if smoke_pass_08_route_extension:
		_smoke_route_extension_checks._smoke_pass_08_route_extension_and_quit()
		return
	if smoke_pass_09_southwest_pocket_decision:
		_smoke_route_extension_checks._smoke_pass_09_southwest_pocket_decision_and_quit()
		return
	if smoke_pass_10_return_pressure:
		_smoke_route_extension_checks._smoke_pass_10_return_pressure_and_quit()
		return
	if smoke_pass_11_pre_pickup_route_cue:
		_smoke_route_extension_checks._smoke_pass_11_pre_pickup_route_cue_and_quit()
		return
	if smoke_pass_12_oxygen_rest_pressure:
		_smoke_oxygen_rest_checks._smoke_pass_12_oxygen_rest_pressure_and_quit()
		return
	if smoke_pass_13_route_commitment:
		_smoke_route_commitment_checks._smoke_pass_13_route_commitment_and_quit()
		return
	if smoke_pass_14_objective_cue:
		_smoke_route_commitment_checks._smoke_pass_14_objective_cue_and_quit()
		return
	if smoke_oxygen_pressure:
		_smoke_interaction_checks._smoke_oxygen_pressure_and_quit()
		return
	if smoke_timed_salvage:
		_smoke_interaction_checks._smoke_timed_salvage_and_quit()
		return
	if smoke_cargo_capacity:
		_smoke_score_checks._smoke_cargo_capacity_and_quit()
		return
	if smoke_salvage_feedback:
		_smoke_score_checks._smoke_salvage_feedback_and_quit()
		return
	if smoke_session_best_score:
		_smoke_score_checks._smoke_session_best_score_and_quit()
		return
	if smoke_oxygen_bonus_score:
		_smoke_score_checks._smoke_oxygen_bonus_score_and_quit()
		return
	if smoke_route_outcome_result:
		_smoke_score_checks._smoke_route_outcome_result_and_quit()
		return
	if smoke_route_choice:
		await _smoke_route_checks._smoke_route_choice_and_quit()
		return
	if smoke_route_choice_metadata:
		_smoke_route_checks._smoke_route_choice_metadata_and_quit()
		return
	if smoke_expanded_route_choice:
		await _smoke_route_checks._smoke_expanded_route_choice_and_quit()
		return
	if smoke_safe_deep_route_choice:
		await _smoke_route_checks._smoke_safe_deep_route_choice_and_quit()
		return
	if smoke_player_facing:
		_smoke_interaction_checks._smoke_player_facing_and_quit()
		return
	if smoke_movement_feel:
		await _smoke_interaction_checks._smoke_movement_feel_and_quit()
		return

	if _has_arg(user_args, engine_args, "--capture-greybox-screenshot"):
		_capture_controller.capture_screenshot_and_quit()
	elif _has_arg(user_args, engine_args, "--capture-camera-tests"):
		_capture_controller.capture_camera_tests_and_quit(_world, CAMERA_TEST_CAPTURE_DIR)
	elif capture_original_map:
		_capture_controller.capture_camera_tests_and_quit(_world, ORIGINAL_CAPTURE_DIR)
	elif capture_tileset_test:
		_capture_controller.capture_camera_tests_and_quit(_world, TILESET_TEST_CAPTURE_DIR)
	elif capture_organic_map:
		_capture_controller.capture_camera_tests_and_quit(_world, ORGANIC_CAPTURE_DIR)
	elif capture_full_sketch_map:
		_capture_controller.capture_camera_tests_and_quit(_world, FULL_SKETCH_CAPTURE_DIR)
	elif capture_production_slice_map:
		_capture_controller.capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_CAPTURE_DIR)
	elif capture_production_slice_debug_map:
		_capture_controller.capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_DEBUG_CAPTURE_DIR)
	elif capture_production_slice_02_map:
		_capture_controller.capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_02_CAPTURE_DIR)
	elif capture_production_slice_02_debug_map:
		_capture_controller.capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_02_DEBUG_CAPTURE_DIR)
	elif capture_production_slice_03_map:
		_capture_controller.capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_03_CAPTURE_DIR)
	elif capture_production_slice_03_debug_map:
		_capture_controller.capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_03_DEBUG_CAPTURE_DIR)
	elif capture_production_slice_04_map:
		_capture_controller.capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_04_CAPTURE_DIR)
	elif capture_production_slice_04_debug_map:
		_capture_controller.capture_camera_tests_and_quit(_world, PRODUCTION_SLICE_04_DEBUG_CAPTURE_DIR)
	elif capture_player_readability:
		_capture_controller.capture_player_readability_and_quit(PLAYER_READABILITY_CAPTURE_DIR)
	elif capture_background_depth:
		_capture_controller.capture_background_depth_and_quit(BACKGROUND_DEPTH_CAPTURE_DIR)
	elif capture_feedback_overlay:
		_capture_controller.capture_feedback_overlay_and_quit(FEEDBACK_OVERLAY_CAPTURE_DIR)
	elif capture_route_outcome:
		_capture_controller.capture_route_outcome_result_and_quit(ROUTE_OUTCOME_CAPTURE_DIR)
	elif capture_timed_salvage:
		_capture_controller.capture_timed_salvage_and_quit(TIMED_SALVAGE_CAPTURE_DIR)
	elif capture_hazard_pressure:
		_capture_controller.capture_hazard_pressure_and_quit(HAZARD_PRESSURE_CAPTURE_DIR)
	elif capture_route_extension:
		_capture_controller.capture_route_extension_and_quit(ROUTE_EXTENSION_CAPTURE_DIR)
	elif capture_southwest_pocket_decision:
		_capture_controller.capture_southwest_pocket_decision_and_quit(SOUTHWEST_POCKET_DECISION_CAPTURE_DIR)
	elif capture_pass_10_return_pressure:
		_capture_controller.capture_pass_10_return_pressure_and_quit(PASS_10_RETURN_PRESSURE_CAPTURE_DIR)
	elif capture_pass_11_pre_pickup_route_cue:
		_capture_controller.capture_pass_11_pre_pickup_route_cue_and_quit(PASS_11_PRE_PICKUP_ROUTE_CUE_CAPTURE_DIR)
	elif capture_pass_12_oxygen_rest_pressure:
		_capture_controller.capture_pass_12_oxygen_rest_pressure_and_quit(PASS_12_OXYGEN_REST_PRESSURE_CAPTURE_DIR)
	elif capture_pass_13_route_commitment:
		_capture_controller.capture_pass_13_route_commitment_and_quit(PASS_13_ROUTE_COMMITMENT_CAPTURE_DIR)


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
	_banked_salvage_ids = []
	_held_salvage_score = 0
	_banked_score = 0
	_completion_oxygen_bonus = 0
	_timed_salvage.reset()
	_refresh_route_commitment_feedback(world)
	_refresh_salvage_route_metadata(world)
	_banked_validation_route_counts = {}
	_hazard_cooldown_seconds = 0.0
	_hazard_feedback_seconds = 0.0
	_hazard_interactions_enabled = true
	_hazard_warning_id = ""
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
	_update_hazard_warning()

	if _held_salvage < HELD_SALVAGE_CAPACITY:
		var nearby_salvage: Dictionary = _world.get_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
		if not nearby_salvage.is_empty() and str(nearby_salvage.get("interaction", "instant")) == "timed_salvage":
			var timed_result: Dictionary = _timed_salvage.update(nearby_salvage, delta)
			if str(timed_result.get("state", "")) == "complete":
				var timed_salvage_id := str(timed_result.get("id", ""))
				if _world.collect_salvage_by_id(timed_salvage_id):
					var completed_note := _timed_salvage_completion_feedback(timed_salvage_id, str(timed_result.get("label", "")))
					_collect_salvage_into_cargo(timed_salvage_id, completed_note)
			elif timed_result.has("note"):
				_last_status_note = str(timed_result["note"])
		else:
			var timed_cancel: Dictionary = _timed_salvage.update({}, delta)
			if str(timed_cancel.get("state", "")) == "canceled":
				_last_status_note = str(timed_cancel.get("note", "Salvage interrupted"))
			var collected_salvage: String = _world.collect_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
			if not collected_salvage.is_empty():
				_collect_salvage_into_cargo(collected_salvage)
	else:
		var blocked_salvage: Dictionary = _world.get_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
		_timed_salvage.reset()
		if not blocked_salvage.is_empty():
			_last_status_note = _return_pressure_feedback.cargo_full_prompt(blocked_salvage)

	if _held_salvage > 0 and _world.is_inside_extraction(_player.global_position):
		_banked_salvage += _held_salvage
		_banked_score += _held_salvage_score
		_record_banked_route_outcomes(_held_salvage_ids)
		_banked_salvage_ids.append_array(_held_salvage_ids)
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


func _complete_route_outcome_review_state() -> bool:
	for salvage in _world.get_salvage_centers():
		_player.global_position = salvage["center"]
		_collect_salvage_for_review_state(salvage)
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			_player.global_position = _world.get_extraction_center()
			_process(0.0)

	if _held_salvage > 0:
		_player.global_position = _world.get_extraction_center()
		_process(0.0)

	if not _run_complete:
		push_error("Route outcome review setup did not complete after collecting and returning.")
		return false
	return true


func _collect_salvage_for_review_state(salvage: Dictionary) -> void:
	var salvage_id := str(salvage.get("id", "salvage"))
	_process(0.0)
	if _world.is_salvage_collected(salvage_id):
		return
	if str(salvage.get("interaction", "instant")) != "timed_salvage":
		return

	var interaction_seconds := maxf(0.01, float(salvage.get("interaction_seconds", 0.0)))
	_process(interaction_seconds + 0.1)


func _collect_salvage_into_cargo(salvage_id: String, status_note := "") -> void:
	var collected_score: int = _world.get_salvage_score(salvage_id)
	var collected_tier: String = _world.get_salvage_tier(salvage_id)
	_held_salvage += 1
	_held_salvage_ids.append(salvage_id)
	_held_salvage_score += collected_score
	_last_status_note = status_note if not status_note.is_empty() else _salvage_collection_feedback_for_id(salvage_id, collected_tier, collected_score)


func _timed_salvage_completion_feedback(salvage_id: String, label: String) -> String:
	var display_label := label
	if display_label.is_empty():
		display_label = salvage_id
		if display_label.begins_with("salvage_"):
			display_label = display_label.substr("salvage_".length())
		display_label = display_label.replace("_", " ")
	if not display_label.is_empty():
		display_label = display_label.substr(0, 1).to_upper() + display_label.substr(1)
	return "%s secured +%d" % [display_label, _world.get_salvage_score(salvage_id)]


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
	_oxygen_rest_feedback.reset()
	_timed_salvage.reset()
	_held_salvage = 0
	_held_salvage_ids = []
	_banked_salvage_ids = []
	_held_salvage_score = 0
	_banked_salvage = 0
	_banked_score = 0
	_completion_oxygen_bonus = 0
	_banked_validation_route_counts = {}
	_hazard_cooldown_seconds = 0.0
	_hazard_feedback_seconds = 0.0
	_hazard_interactions_enabled = true
	_hazard_warning_id = ""
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
		_oxygen_rest_feedback.reset()
		_oxygen_seconds = minf(OXYGEN_MAX_SECONDS, _oxygen_seconds + OXYGEN_REFILL_SECONDS_PER_SECOND * delta)
		return false

	var rest_result: Dictionary = _oxygen_rest_feedback.update(_world, _player.global_position, _oxygen_seconds, delta)
	if bool(rest_result.get("inside", false)):
		_oxygen_seconds = float(rest_result.get("oxygen_seconds", _oxygen_seconds))
		if _oxygen_seconds > 0.0:
			return false
		_handle_oxygen_depleted()
		return true

	_oxygen_seconds = maxf(0.0, _oxygen_seconds - delta)
	if _oxygen_seconds > 0.0:
		return false

	_handle_oxygen_depleted()
	return true


func _handle_oxygen_depleted() -> void:
	_oxygen_rest_feedback.reset()
	_timed_salvage.reset()
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
	_hazard_warning_id = ""
	_oxygen_rest_feedback.reset()
	_timed_salvage.reset()
	var oxygen_depleted := _apply_hazard_oxygen_penalty()
	if oxygen_depleted:
		_handle_oxygen_depleted()
		return

	if not _held_salvage_ids.is_empty():
		_world.restore_salvage(_held_salvage_ids)
		_held_salvage_ids = []
		_held_salvage = 0
		_held_salvage_score = 0
		_last_status_note = "Hazard hit: dropped held, oxygen -%ds" % int(HAZARD_OXYGEN_PENALTY_SECONDS)
	else:
		_last_status_note = "Hazard hit: oxygen -%ds" % int(HAZARD_OXYGEN_PENALTY_SECONDS)

	_hazard_cooldown_seconds = HAZARD_COOLDOWN_SECONDS
	_hazard_feedback_seconds = HAZARD_FEEDBACK_SECONDS
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	if _player.has_method("snap_camera"):
		_player.snap_camera()


func _apply_hazard_oxygen_penalty() -> bool:
	_oxygen_seconds = maxf(0.0, _oxygen_seconds - HAZARD_OXYGEN_PENALTY_SECONDS)
	return _oxygen_seconds <= 0.0


func _update_hazard_warning() -> void:
	_hazard_warning_id = ""
	if not _hazard_interactions_enabled or _hazard_cooldown_seconds > 0.0:
		return
	var hazard: Dictionary = _world.get_nearest_hazard_within(_player.global_position, HAZARD_WARNING_RADIUS)
	if hazard.is_empty():
		return
	if float(hazard.get("distance", HAZARD_WARNING_RADIUS)) <= HAZARD_CONTACT_RADIUS:
		return
	_hazard_warning_id = str(hazard.get("id", "hazard"))


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
	var objective_text := _route_commitment_overlay_text()
	var oxygen_rest_prompt := _oxygen_rest_prompt()
	var pre_pickup_route_cue := _pre_pickup_route_cue_prompt()
	if _run_complete:
		prompt = "Run complete - press R"
	elif _run_failed:
		prompt = "Oxygen depleted - press R"
	elif _held_salvage >= HELD_SALVAGE_CAPACITY:
		prompt = _cargo_full_prompt()
	elif not _hazard_warning_id.is_empty():
		prompt = _hazard_warning_prompt()
	elif not oxygen_rest_prompt.is_empty():
		prompt = oxygen_rest_prompt
	elif not pre_pickup_route_cue.is_empty():
		prompt = pre_pickup_route_cue
	elif not _last_status_note.is_empty():
		prompt = _last_status_note
	elif _held_salvage > 0:
		prompt = "Return to extraction"

	var oxygen_seconds := int(ceil(_oxygen_seconds))
	var oxygen_text := "Oxygen %ds" % oxygen_seconds
	var oxygen_feedback := _oxygen_feedback_label()
	if not oxygen_feedback.is_empty():
		oxygen_text = "Oxygen %ds %s" % [oxygen_seconds, oxygen_feedback]

	_status_label.text = "Score %d\nSalvage banked %d/%d\nHeld %d/%d (%d pts)\n%s" % [
		_banked_score,
		_banked_salvage,
		_total_salvage,
		_held_salvage,
		HELD_SALVAGE_CAPACITY,
		_held_salvage_score,
		oxygen_text,
	]
	if not objective_text.is_empty():
		_status_label.text += "\n%s" % objective_text
	if not prompt.is_empty():
		_status_label.text += "\n%s" % prompt
	_update_result_panel()


func _cargo_full_prompt() -> String:
	if _return_pressure_feedback == null or _world == null or _player == null:
		return ReturnPressureFeedback.DEFAULT_CARGO_FULL_PROMPT
	var nearby_salvage: Dictionary = _world.get_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
	return _return_pressure_feedback.cargo_full_prompt(nearby_salvage)


func _pre_pickup_route_cue_prompt() -> String:
	if _pre_pickup_route_cue_feedback == null or _world == null or _player == null:
		return ""
	return _pre_pickup_route_cue_feedback.current_prompt(_world, _player.global_position)


func _oxygen_rest_prompt() -> String:
	if _oxygen_rest_feedback == null:
		return ""
	return _oxygen_rest_feedback.current_prompt()


func _route_commitment_overlay_text() -> String:
	if _route_commitment_feedback == null:
		return ""
	var show_start_cue := false
	if _world != null and _player != null and not _run_complete and not _run_failed:
		show_start_cue = _world.is_inside_extraction(_player.global_position)
	return _route_commitment_feedback.overlay_text(_held_salvage_ids, _banked_salvage_ids, show_start_cue)


func _route_commitment_result_text() -> String:
	if _route_commitment_feedback == null:
		return ""
	return _route_commitment_feedback.result_text(_banked_salvage_ids)


func _hazard_warning_prompt() -> String:
	if _hazard_warning_id == PASS_07_PRESSURE_HAZARD_ID:
		return PRESSURE_HAZARD_WARNING_PROMPT
	return GENERIC_HAZARD_WARNING_PROMPT


func _oxygen_feedback_label() -> String:
	if _run_complete or _run_failed:
		return ""
	if _oxygen_seconds <= OXYGEN_CRITICAL_WARNING_SECONDS:
		return "CRITICAL"
	if _oxygen_seconds <= OXYGEN_LOW_WARNING_SECONDS:
		return "LOW"
	return ""


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


func _refresh_salvage_route_metadata(world) -> void:
	_salvage_validation_routes_by_id = {}
	if world == null or not world.has_method("get_salvage_centers"):
		return

	for salvage in world.get_salvage_centers():
		var salvage_id := str(salvage.get("id", ""))
		var validation_route := str(salvage.get("validation_route", ""))
		if salvage_id.is_empty() or validation_route.is_empty():
			continue
		_salvage_validation_routes_by_id[salvage_id] = validation_route


func _refresh_route_commitment_feedback(world) -> void:
	if _route_commitment_feedback == null:
		return
	if world == null or not world.has_method("get_route_objectives"):
		_route_commitment_feedback.reset([])
		return
	_route_commitment_feedback.reset(world.get_route_objectives())


func _record_banked_route_outcomes(salvage_ids: Array[String]) -> void:
	for salvage_id in salvage_ids:
		var validation_route := str(_salvage_validation_routes_by_id.get(salvage_id, ""))
		if validation_route.is_empty():
			continue
		_banked_validation_route_counts[validation_route] = int(_banked_validation_route_counts.get(validation_route, 0)) + 1


func _route_outcome_text() -> String:
	if not _run_complete:
		return ""

	var validation_route := _route_outcome_validation_route()
	if validation_route.is_empty():
		return ""
	return "Route: %s" % _route_outcome_label(validation_route)


func _route_outcome_validation_route() -> String:
	if int(_banked_validation_route_counts.get(EXPANDED_ROUTE_CHOICE_ID, 0)) > 0:
		return EXPANDED_ROUTE_CHOICE_ID
	if int(_banked_validation_route_counts.get(SAFE_ROUTE_CHOICE_ID, 0)) > 0:
		return SAFE_ROUTE_CHOICE_ID

	for route_id_value in _banked_validation_route_counts.keys():
		var validation_route := str(route_id_value)
		if validation_route.is_empty() or int(_banked_validation_route_counts.get(validation_route, 0)) <= 0:
			continue
		return validation_route
	return ""


func _route_outcome_label(validation_route: String) -> String:
	if validation_route == SAFE_ROUTE_CHOICE_ID:
		return "Safe route"
	if validation_route == EXPANDED_ROUTE_CHOICE_ID:
		return "Deep route"
	if validation_route == SOUTHWEST_POCKET_DECISION_ID:
		return "Southwest pocket"
	return validation_route.replace("_", " ")


func _salvage_collection_feedback_for_id(salvage_id: String, tier: String, score: int) -> String:
	var validation_route := str(_salvage_validation_routes_by_id.get(salvage_id, ""))
	if validation_route == SOUTHWEST_POCKET_DECISION_ID:
		return "Southwest pocket payoff +%d" % score
	return _salvage_collection_feedback(tier, score)


func _salvage_collection_feedback(tier: String, score: int) -> String:
	if tier == "valuable":
		return "Collected valuable salvage +%d" % score
	return "Collected common salvage +%d" % score


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
	var result_lines := PackedStringArray()
	result_lines.append(title)
	result_lines.append("Score %d" % _current_expedition_score())
	result_lines.append("Salvage score %d" % _banked_score)
	result_lines.append("Oxygen bonus +%d" % _completion_oxygen_bonus)
	result_lines.append("Best %d" % _session_best_score())
	result_lines.append("Salvage %d/%d" % [_banked_salvage, _total_salvage])
	var route_text := _route_outcome_text()
	if not route_text.is_empty():
		result_lines.append(route_text)
	var objective_text := _route_commitment_result_text()
	if not objective_text.is_empty():
		result_lines.append(objective_text)
	result_lines.append(oxygen_text)
	result_lines.append("Press R to retry")
	_result_label.text = "\n".join(result_lines)


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
