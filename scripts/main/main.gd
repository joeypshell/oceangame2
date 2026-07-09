extends Node2D

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CaptureController := preload("res://scripts/main/capture_controller.gd")
const CurrentGateCapture := preload("res://scripts/main/captures/current_gate_capture.gd")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")
const DestinationPayoffFeedback := preload("res://scripts/main/destination_payoff_feedback.gd")
const FinalDiveObjectiveSeed := preload("res://scripts/main/final_dive_objective_seed.gd")
const MovingHazardCapture := preload("res://scripts/main/captures/moving_hazard_capture.gd")
const MovingHazardController := preload("res://scripts/main/moving_hazard_controller.gd")
const OxygenRestPocketFeedback := preload("res://scripts/main/oxygen_rest_pocket_feedback.gd")
const Pass22DestinationPayoffCapture := preload("res://scripts/main/captures/pass_22_destination_payoff_capture.gd")
const Pass23NextDiveObjectiveCapture := preload("res://scripts/main/captures/pass_23_next_dive_objective_capture.gd")
const Pass24RelayFollowThroughCapture := preload("res://scripts/main/captures/pass_24_relay_follow_through_capture.gd")
const Pass25FinalDiveObjectiveCapture := preload("res://scripts/main/captures/pass_25_final_dive_objective_capture.gd")
const Pass26ResultPresentationCapture := preload("res://scripts/main/captures/pass_26_result_presentation_capture.gd")
const PrePickupRouteCueFeedback := preload("res://scripts/main/pre_pickup_route_cue_feedback.gd")
const NextDiveObjectivePrompt := preload("res://scripts/main/next_dive_objective_prompt.gd")
const PrimaryDiveObjective := preload("res://scripts/main/primary_dive_objective.gd")
const ProgressionContainerController := preload("res://scripts/main/progression_container_controller.gd")
const PrySalvageController := preload("res://scripts/main/pry_salvage_controller.gd")
const RelayFollowThroughFeedback := preload("res://scripts/main/relay_follow_through_feedback.gd")
const ReturnPressureFeedback := preload("res://scripts/main/return_pressure_feedback.gd")
const ResultPresentationBuilder := preload("res://scripts/main/result_presentation_builder.gd")
const RouteCommitmentFeedback := preload("res://scripts/main/route_commitment_feedback.gd")
const SessionProgression := preload("res://scripts/main/session_progression.gd")
const TimedSalvageController := preload("res://scripts/main/timed_salvage_controller.gd")
const WorldConnectorController := preload("res://scripts/main/world_connector_controller.gd")
const AudioCuePlayer := preload("res://scripts/main/audio_cue_player.gd")
const SmokeFeedbackAudioChecks := preload("res://scripts/main/smoke/smoke_feedback_audio_checks.gd")
const SmokeFinalDiveObjectiveChecks := preload("res://scripts/main/smoke/smoke_final_dive_objective_checks.gd")
const SmokeHazardRouteChecks := preload("res://scripts/main/smoke/smoke_hazard_route_checks.gd")
const SmokeInteractionChecks := preload("res://scripts/main/smoke/smoke_interaction_checks.gd")
const SmokeOxygenRestChecks := preload("res://scripts/main/smoke/smoke_oxygen_rest_checks.gd")
const SmokePrimaryCompletionChecks := preload("res://scripts/main/smoke/smoke_primary_completion_checks.gd")
const SmokeProgressionChecks := preload("res://scripts/main/smoke/smoke_progression_checks.gd")
const SmokePrySalvageChecks := preload("res://scripts/main/smoke/smoke_pry_salvage_checks.gd")
const SmokeResultPresentationChecks := preload("res://scripts/main/smoke/smoke_result_presentation_checks.gd")
const SmokeRouteCommitmentChecks := preload("res://scripts/main/smoke/smoke_route_commitment_checks.gd")
const SmokeRouteExtensionChecks := preload("res://scripts/main/smoke/smoke_route_extension_checks.gd")
const SmokeRouteChecks := preload("res://scripts/main/smoke/smoke_route_checks.gd")
const SmokeScoreChecks := preload("res://scripts/main/smoke/smoke_score_checks.gd")
const SmokeWorldConnectorChecks := preload("res://scripts/main/smoke/smoke_world_connector_checks.gd")
const SmokeCurrentGateChecks := preload("res://scripts/main/smoke/smoke_current_gate_checks.gd")
const SmokeProgressionContainerChecks := preload("res://scripts/main/smoke/smoke_progression_container_checks.gd")
const SmokeMovingHazardChecks := preload("res://scripts/main/smoke/smoke_moving_hazard_checks.gd")
const SmokeNextDiveObjectiveChecks := preload("res://scripts/main/smoke/smoke_next_dive_objective_checks.gd")
const SmokeDarknessLightChecks := preload("res://scripts/main/smoke/smoke_darkness_light_checks.gd")
const UpgradeChestCapture := preload("res://scripts/main/captures/upgrade_chest_capture.gd")
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
const PRY_SALVAGE_CAPTURE_DIR := "res://visual_captures/pry_salvage"
const HAZARD_PRESSURE_CAPTURE_DIR := "res://visual_captures/hazard_pressure"
const ROUTE_EXTENSION_CAPTURE_DIR := "res://visual_captures/route_extension"
const SOUTHWEST_POCKET_DECISION_CAPTURE_DIR := "res://visual_captures/southwest_pocket_decision"
const PASS_10_RETURN_PRESSURE_CAPTURE_DIR := "res://visual_captures/pass_10_return_pressure"
const PASS_11_PRE_PICKUP_ROUTE_CUE_CAPTURE_DIR := "res://visual_captures/pass_11_pre_pickup_route_cue"
const PASS_12_OXYGEN_REST_PRESSURE_CAPTURE_DIR := "res://visual_captures/pass_12_oxygen_rest_pressure"
const PASS_13_ROUTE_COMMITMENT_CAPTURE_DIR := "res://visual_captures/pass_13_route_commitment"
const PASS_14_OBJECTIVE_CUE_CAPTURE_DIR := "res://visual_captures/pass_14_objective_cue"
const PASS_15_OBJECTIVE_FOLLOW_THROUGH_CAPTURE_DIR := "res://visual_captures/pass_15_objective_follow_through"
const PASS_18_PROGRESSION_CAPTURE_DIR := "res://visual_captures/pass_18_progression"
const PASS_19_CARGO_UPGRADE_CAPTURE_DIR := "res://visual_captures/pass_19_cargo_upgrade"
const PASS_20_LIGHT_UPGRADE_CAPTURE_DIR := "res://visual_captures/pass_20_light_upgrade"
const PASS_21_WORLD_CONNECTOR_CAPTURE_DIR := "res://visual_captures/pass_21_world_connector"
const PASS_22_DESTINATION_PAYOFF_CAPTURE_DIR := "res://visual_captures/pass_22_destination_payoff"
const PASS_23_NEXT_DIVE_OBJECTIVE_CAPTURE_DIR := "res://visual_captures/pass_23_next_dive_objective"
const PASS_24_RELAY_FOLLOW_THROUGH_CAPTURE_DIR := "res://visual_captures/pass_24_relay_follow_through"
const PASS_25_FINAL_DIVE_OBJECTIVE_CAPTURE_DIR := "res://visual_captures/pass_25_final_dive_objective"
const PASS_26_RESULT_PRESENTATION_CAPTURE_DIR := "res://visual_captures/pass_26_result_presentation"
const DARKNESS_LIGHT_CAPTURE_DIR := "res://visual_captures/darkness_light_gate"
const CURRENT_GATE_CAPTURE_DIR := "res://visual_captures/current_gate"
const MOVING_HAZARD_CAPTURE_DIR := "res://visual_captures/moving_hazard"
const UPGRADE_CHEST_CAPTURE_DIR := "res://visual_captures/upgrade_chest"
const PRIMARY_DIVE_COMPLETION_CAPTURE_DIR := "res://visual_captures/primary_dive_completion"
const BUILD_INFO_PATH := "res://build_info.json"
const MOVEMENT_FEEL_PROBE_CENTER_TILES := Vector2(42, 25)
const SALVAGE_COLLECTION_RADIUS := 34.0
const HELD_SALVAGE_CAPACITY := 2
const HAZARD_CONTACT_RADIUS := 30.0
const HAZARD_WARNING_RADIUS := 80.0
const HAZARD_OXYGEN_PENALTY_SECONDS := 12.0
const HAZARD_COOLDOWN_SECONDS := 1.0
const HAZARD_FEEDBACK_SECONDS := 0.45
const HAZARD_WARNING_CUE_COOLDOWN_SECONDS := 1.0
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
var _current_gate
var _destination_payoff_feedback
var _final_dive_objective_seed
var _moving_hazards
var _next_dive_objective_prompt
var _oxygen_rest_feedback
var _pre_pickup_route_cue_feedback
var _primary_dive_objective
var _progression_containers
var _pry_salvage
var _relay_follow_through_feedback
var _return_pressure_feedback
var _route_commitment_feedback
var _session_progression
var _timed_salvage
var _world_connector
var _audio_cues
var _smoke_feedback_audio_checks
var _smoke_final_dive_objective_checks
var _smoke_hazard_route_checks
var _smoke_interaction_checks
var _smoke_oxygen_rest_checks
var _smoke_primary_completion_checks
var _smoke_progression_checks
var _smoke_pry_salvage_checks
var _smoke_result_presentation_checks
var _smoke_route_commitment_checks
var _smoke_route_extension_checks
var _smoke_route_checks
var _smoke_score_checks
var _smoke_world_connector_checks
var _smoke_current_gate_checks
var _smoke_progression_container_checks
var _smoke_moving_hazard_checks
var _smoke_next_dive_objective_checks
var _smoke_darkness_light_checks
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
var _hazard_warning_cue_id := ""
var _hazard_warning_cue_cooldown_seconds := 0.0
var _oxygen_seconds := OXYGEN_MAX_SECONDS
var _oxygen_low_cue_emitted := false
var _oxygen_critical_cue_emitted := false
var _run_complete := false
var _run_failed := false
var _last_status_note := ""


func _ready() -> void:
	_capture_controller = CaptureController.new(self)
	_current_gate = CurrentGateController.new()
	_destination_payoff_feedback = DestinationPayoffFeedback.new()
	_final_dive_objective_seed = FinalDiveObjectiveSeed.new()
	_moving_hazards = MovingHazardController.new()
	_next_dive_objective_prompt = NextDiveObjectivePrompt.new()
	_oxygen_rest_feedback = OxygenRestPocketFeedback.new()
	_pre_pickup_route_cue_feedback = PrePickupRouteCueFeedback.new()
	_primary_dive_objective = PrimaryDiveObjective.new()
	_progression_containers = ProgressionContainerController.new()
	_pry_salvage = PrySalvageController.new()
	_relay_follow_through_feedback = RelayFollowThroughFeedback.new()
	_return_pressure_feedback = ReturnPressureFeedback.new()
	_route_commitment_feedback = RouteCommitmentFeedback.new()
	_session_progression = SessionProgression.new()
	_timed_salvage = TimedSalvageController.new()
	_world_connector = WorldConnectorController.new()
	_audio_cues = AudioCuePlayer.new()
	add_child(_audio_cues)
	_smoke_feedback_audio_checks = SmokeFeedbackAudioChecks.new(self)
	_smoke_final_dive_objective_checks = SmokeFinalDiveObjectiveChecks.new(self)
	_smoke_hazard_route_checks = SmokeHazardRouteChecks.new(self)
	_smoke_interaction_checks = SmokeInteractionChecks.new(self)
	_smoke_oxygen_rest_checks = SmokeOxygenRestChecks.new(self)
	_smoke_primary_completion_checks = SmokePrimaryCompletionChecks.new(self)
	_smoke_progression_checks = SmokeProgressionChecks.new(self)
	_smoke_pry_salvage_checks = SmokePrySalvageChecks.new(self)
	_smoke_result_presentation_checks = SmokeResultPresentationChecks.new(self)
	_smoke_route_commitment_checks = SmokeRouteCommitmentChecks.new(self)
	_smoke_route_extension_checks = SmokeRouteExtensionChecks.new(self)
	_smoke_route_checks = SmokeRouteChecks.new(self)
	_smoke_score_checks = SmokeScoreChecks.new(self)
	_smoke_world_connector_checks = SmokeWorldConnectorChecks.new(self)
	_smoke_current_gate_checks = SmokeCurrentGateChecks.new(self)
	_smoke_progression_container_checks = SmokeProgressionContainerChecks.new(self)
	_smoke_moving_hazard_checks = SmokeMovingHazardChecks.new(self)
	_smoke_next_dive_objective_checks = SmokeNextDiveObjectiveChecks.new(self)
	_smoke_darkness_light_checks = SmokeDarknessLightChecks.new(self)
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
	var capture_pry_salvage := _has_arg(user_args, engine_args, "--capture-pry-salvage")
	var capture_hazard_pressure := _has_arg(user_args, engine_args, "--capture-pass-07-hazard-pressure")
	var capture_route_extension := _has_arg(user_args, engine_args, "--capture-pass-08-route-extension")
	var capture_southwest_pocket_decision := _has_arg(user_args, engine_args, "--capture-pass-09-southwest-pocket-decision")
	var capture_pass_10_return_pressure := _has_arg(user_args, engine_args, "--capture-pass-10-return-pressure")
	var capture_pass_11_pre_pickup_route_cue := _has_arg(user_args, engine_args, "--capture-pass-11-pre-pickup-route-cue")
	var capture_pass_12_oxygen_rest_pressure := _has_arg(user_args, engine_args, "--capture-pass-12-oxygen-rest-pressure")
	var capture_pass_13_route_commitment := _has_arg(user_args, engine_args, "--capture-pass-13-route-commitment")
	var capture_pass_14_objective_cue := _has_arg(user_args, engine_args, "--capture-pass-14-objective-cue")
	var capture_pass_15_objective_follow_through := _has_arg(user_args, engine_args, "--capture-pass-15-objective-follow-through")
	var capture_pass_18_progression := _has_arg(user_args, engine_args, "--capture-pass-18-progression")
	var capture_pass_19_cargo_upgrade := _has_arg(user_args, engine_args, "--capture-pass-19-cargo-upgrade")
	var capture_pass_20_light_upgrade := _has_arg(user_args, engine_args, "--capture-pass-20-light-upgrade")
	var capture_pass_21_world_connector := _has_arg(user_args, engine_args, "--capture-pass-21-world-connector")
	var capture_pass_22_destination_payoff := _has_arg(user_args, engine_args, "--capture-pass-22-destination-payoff")
	var capture_pass_23_next_dive_objective := _has_arg(user_args, engine_args, "--capture-pass-23-next-dive-objective")
	var capture_pass_24_relay_follow_through := _has_arg(user_args, engine_args, "--capture-pass-24-relay-follow-through")
	var capture_pass_25_final_dive_objective := _has_arg(user_args, engine_args, "--capture-pass-25-final-dive-objective")
	var capture_pass_26_result_presentation := _has_arg(user_args, engine_args, "--capture-pass-26-result-presentation")
	var capture_darkness_light_gate := _has_arg(user_args, engine_args, "--capture-darkness-light-gate")
	var capture_current_gate := _has_arg(user_args, engine_args, "--capture-current-gate")
	var capture_moving_hazard := _has_arg(user_args, engine_args, "--capture-moving-hazard")
	var capture_upgrade_chest := _has_arg(user_args, engine_args, "--capture-upgrade-chest")
	var capture_primary_dive_completion := _has_arg(user_args, engine_args, "--capture-primary-dive-completion")
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
	var smoke_pass_15_objective_follow_through := _has_arg(user_args, engine_args, "--smoke-pass-15-objective-follow-through")
	var smoke_pass_18_progression := _has_arg(user_args, engine_args, "--smoke-pass-18-progression")
	var smoke_pass_19_cargo_upgrade := _has_arg(user_args, engine_args, "--smoke-pass-19-cargo-upgrade")
	var smoke_pass_20_light_upgrade := _has_arg(user_args, engine_args, "--smoke-pass-20-light-upgrade")
	var smoke_pass_21_world_connector := _has_arg(user_args, engine_args, "--smoke-pass-21-world-connector")
	var smoke_pass_22_destination_payoff := _has_arg(user_args, engine_args, "--smoke-pass-22-destination-payoff")
	var smoke_pass_24_relay_follow_through := _has_arg(user_args, engine_args, "--smoke-pass-24-relay-follow-through")
	var smoke_pass_25_final_dive_objective := _has_arg(user_args, engine_args, "--smoke-pass-25-final-dive-objective")
	var smoke_pass_26_result_presentation := _has_arg(user_args, engine_args, "--smoke-pass-26-result-presentation")
	var smoke_current_gate := _has_arg(user_args, engine_args, "--smoke-current-gate")
	var smoke_moving_hazard := _has_arg(user_args, engine_args, "--smoke-moving-hazard")
	var smoke_darkness_light_gate := _has_arg(user_args, engine_args, "--smoke-darkness-light-gate")
	var smoke_upgrade_chest := _has_arg(user_args, engine_args, "--smoke-upgrade-chest")
	var smoke_primary_dive_completion := _has_arg(user_args, engine_args, "--smoke-primary-dive-completion")
	var smoke_pass_23_next_dive_objective := _has_arg(user_args, engine_args, "--smoke-pass-23-next-dive-objective")
	var smoke_oxygen_pressure := _has_arg(user_args, engine_args, "--smoke-oxygen-pressure")
	var smoke_timed_salvage := _has_arg(user_args, engine_args, "--smoke-timed-salvage")
	var smoke_pry_salvage := _has_arg(user_args, engine_args, "--smoke-pry-salvage")
	var smoke_cargo_capacity := _has_arg(user_args, engine_args, "--smoke-cargo-capacity")
	var smoke_feedback_cues := _has_arg(user_args, engine_args, "--smoke-feedback-cues")
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
	elif capture_pry_salvage:
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
	elif capture_pass_14_objective_cue:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_15_objective_follow_through:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_18_progression:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_19_cargo_upgrade:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_20_light_upgrade:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_21_world_connector:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_22_destination_payoff:
		selected_map_path = PRODUCTION_SLICE_04_MAP_PATH
	elif capture_pass_23_next_dive_objective:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_pass_24_relay_follow_through:
		selected_map_path = PRODUCTION_SLICE_04_MAP_PATH
	elif capture_pass_25_final_dive_objective:
		selected_map_path = PRODUCTION_SLICE_04_MAP_PATH
	elif capture_pass_26_result_presentation:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_darkness_light_gate:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_current_gate:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_moving_hazard:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_upgrade_chest:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_primary_dive_completion:
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
	elif smoke_pass_15_objective_follow_through:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_18_progression:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_19_cargo_upgrade:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_20_light_upgrade:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_21_world_connector:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_22_destination_payoff:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_26_result_presentation:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_current_gate:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_moving_hazard:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_darkness_light_gate:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_upgrade_chest:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_primary_dive_completion:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pass_23_next_dive_objective:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_oxygen_pressure:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_timed_salvage:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_pry_salvage:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_feedback_cues:
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
		or capture_pry_salvage
		or capture_hazard_pressure
		or capture_route_extension
		or capture_southwest_pocket_decision
		or capture_pass_10_return_pressure
		or capture_pass_11_pre_pickup_route_cue
		or capture_pass_12_oxygen_rest_pressure
		or capture_pass_13_route_commitment
		or capture_pass_14_objective_cue
		or capture_pass_15_objective_follow_through
		or capture_pass_18_progression
		or capture_pass_19_cargo_upgrade
		or capture_pass_20_light_upgrade
		or capture_pass_21_world_connector
		or capture_pass_22_destination_payoff
		or capture_pass_23_next_dive_objective
		or capture_pass_24_relay_follow_through
		or capture_pass_25_final_dive_objective
		or capture_pass_26_result_presentation
		or capture_darkness_light_gate
		or capture_current_gate
		or capture_moving_hazard
		or capture_upgrade_chest
		or capture_primary_dive_completion
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
		or smoke_pass_15_objective_follow_through
		or smoke_pass_18_progression
		or smoke_pass_19_cargo_upgrade
		or smoke_pass_20_light_upgrade
		or smoke_pass_21_world_connector
		or smoke_pass_22_destination_payoff
		or smoke_pass_24_relay_follow_through
		or smoke_pass_25_final_dive_objective
		or smoke_pass_26_result_presentation
		or smoke_current_gate
		or smoke_moving_hazard
		or smoke_darkness_light_gate
		or smoke_upgrade_chest
		or smoke_primary_dive_completion
		or smoke_pass_23_next_dive_objective
		or smoke_oxygen_pressure
		or smoke_timed_salvage
		or smoke_pry_salvage
		or smoke_cargo_capacity
		or smoke_feedback_cues
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
	if smoke_pass_15_objective_follow_through:
		_smoke_route_commitment_checks._smoke_pass_15_objective_follow_through_and_quit()
		return
	if smoke_pass_18_progression:
		_smoke_progression_checks._smoke_pass_18_progression_and_quit()
		return
	if smoke_pass_19_cargo_upgrade:
		_smoke_progression_checks._smoke_pass_19_cargo_upgrade_and_quit()
		return
	if smoke_pass_20_light_upgrade:
		_smoke_progression_checks._smoke_pass_20_light_upgrade_and_quit()
		return
	if smoke_pass_21_world_connector:
		_smoke_world_connector_checks._smoke_pass_21_world_connector_and_quit()
		return
	if smoke_pass_22_destination_payoff:
		_smoke_world_connector_checks._smoke_pass_22_destination_payoff_and_quit()
		return
	if smoke_pass_24_relay_follow_through:
		_smoke_world_connector_checks._smoke_pass_24_relay_follow_through_and_quit()
		return

	if smoke_pass_25_final_dive_objective:
		_smoke_final_dive_objective_checks._smoke_pass_25_final_dive_objective_and_quit()
		return
	if smoke_pass_26_result_presentation:
		_smoke_result_presentation_checks._smoke_pass_26_result_presentation_and_quit()
		return
	if smoke_current_gate:
		_smoke_current_gate_checks._smoke_current_gate_and_quit()
		return
	if smoke_moving_hazard:
		_smoke_moving_hazard_checks._smoke_moving_hazard_and_quit()
		return
	if smoke_darkness_light_gate:
		_smoke_darkness_light_checks._smoke_darkness_light_gate_and_quit()
		return
	if smoke_upgrade_chest:
		_smoke_progression_container_checks._smoke_upgrade_chest_and_quit()
		return
	if smoke_primary_dive_completion:
		_smoke_primary_completion_checks._smoke_primary_dive_completion_and_quit()
		return
	if smoke_pass_23_next_dive_objective:
		_smoke_next_dive_objective_checks._smoke_pass_23_next_dive_objective_and_quit()
		return
	if smoke_oxygen_pressure:
		_smoke_interaction_checks._smoke_oxygen_pressure_and_quit()
		return
	if smoke_timed_salvage:
		_smoke_interaction_checks._smoke_timed_salvage_and_quit()
		return
	if smoke_pry_salvage:
		_smoke_pry_salvage_checks._smoke_pry_salvage_and_quit()
		return
	if smoke_cargo_capacity:
		_smoke_score_checks._smoke_cargo_capacity_and_quit()
		return
	if smoke_feedback_cues:
		_smoke_feedback_audio_checks._smoke_feedback_cues_and_quit()
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
	elif capture_pry_salvage:
		_capture_controller.capture_pry_salvage_and_quit(PRY_SALVAGE_CAPTURE_DIR)
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
	elif capture_pass_14_objective_cue:
		_capture_controller.capture_pass_14_objective_cue_and_quit(PASS_14_OBJECTIVE_CUE_CAPTURE_DIR)
	elif capture_pass_15_objective_follow_through:
		_capture_controller.capture_pass_15_objective_follow_through_and_quit(PASS_15_OBJECTIVE_FOLLOW_THROUGH_CAPTURE_DIR)
	elif capture_pass_18_progression:
		_capture_controller.capture_pass_18_progression_and_quit(PASS_18_PROGRESSION_CAPTURE_DIR)
	elif capture_pass_19_cargo_upgrade:
		_capture_controller.capture_pass_19_cargo_upgrade_and_quit(PASS_19_CARGO_UPGRADE_CAPTURE_DIR)
	elif capture_pass_20_light_upgrade:
		_capture_controller.capture_pass_20_light_upgrade_and_quit(PASS_20_LIGHT_UPGRADE_CAPTURE_DIR)
	elif capture_pass_21_world_connector:
		_capture_controller.capture_pass_21_world_connector_and_quit(PASS_21_WORLD_CONNECTOR_CAPTURE_DIR)
	elif capture_pass_22_destination_payoff:
		var capture := Pass22DestinationPayoffCapture.new(self)
		await capture.capture_and_quit(PASS_22_DESTINATION_PAYOFF_CAPTURE_DIR)
	elif capture_pass_23_next_dive_objective:
		var capture := Pass23NextDiveObjectiveCapture.new(self)
		await capture.capture_and_quit(PASS_23_NEXT_DIVE_OBJECTIVE_CAPTURE_DIR)
	elif capture_pass_24_relay_follow_through:
		var capture := Pass24RelayFollowThroughCapture.new(self)
		await capture.capture_and_quit(PASS_24_RELAY_FOLLOW_THROUGH_CAPTURE_DIR)
	elif capture_pass_25_final_dive_objective:
		var capture := Pass25FinalDiveObjectiveCapture.new(self)
		await capture.capture_and_quit(PASS_25_FINAL_DIVE_OBJECTIVE_CAPTURE_DIR)
	elif capture_pass_26_result_presentation:
		var capture := Pass26ResultPresentationCapture.new(self)
		await capture.capture_and_quit(PASS_26_RESULT_PRESENTATION_CAPTURE_DIR)
	elif capture_darkness_light_gate:
		_capture_controller.capture_darkness_light_gate_and_quit(DARKNESS_LIGHT_CAPTURE_DIR)
	elif capture_current_gate:
		var capture := CurrentGateCapture.new(self)
		await capture.capture_and_quit(CURRENT_GATE_CAPTURE_DIR)
	elif capture_moving_hazard:
		var capture := MovingHazardCapture.new(self)
		await capture.capture_and_quit(MOVING_HAZARD_CAPTURE_DIR)
	elif capture_upgrade_chest:
		var capture := UpgradeChestCapture.new(self)
		await capture.capture_and_quit(UPGRADE_CHEST_CAPTURE_DIR)
	elif capture_primary_dive_completion:
		_capture_controller.capture_primary_dive_completion_and_quit(PRIMARY_DIVE_COMPLETION_CAPTURE_DIR)


func _exit_tree() -> void:
	if _audio_cues != null and _audio_cues.has_method("shutdown"):
		_audio_cues.shutdown()


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


func _load_playable_map(map_path: String, show_debug_overlay: bool, entry_id := "", status_note := "") -> void:
	_clear_loaded_review_nodes()
	var world := _create_world(map_path, show_debug_overlay)
	var player := PLAYER_SCENE.instantiate()
	_player = player
	player.position = world.get_entry_position(entry_id) if not entry_id.is_empty() and world.has_method("get_entry_position") else world.spawn_position
	add_child(player)
	_apply_session_light_profile()

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
	_current_gate.reset()
	_moving_hazards.reset(world)
	_pry_salvage.reset()
	_timed_salvage.reset()
	_progression_containers.apply_opened_to_world(world)
	_primary_dive_objective.reset(world)
	_next_dive_objective_prompt.reset(world)
	_relay_follow_through_feedback.reset(world)
	_final_dive_objective_seed.reset(world)
	_refresh_route_commitment_feedback(world)
	_refresh_salvage_route_metadata(world)
	_refresh_destination_payoff_feedback(world)
	_banked_validation_route_counts = {}
	_hazard_cooldown_seconds = 0.0
	_hazard_feedback_seconds = 0.0
	_hazard_interactions_enabled = true
	_hazard_warning_id = ""
	_reset_hazard_feedback_cues()
	_oxygen_seconds = _oxygen_capacity_seconds()
	_reset_oxygen_feedback_cues()
	_run_complete = false
	_run_failed = false
	_last_status_note = status_note
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


func _play_feedback_cue(cue_id: String, dedupe_key := "") -> bool:
	if _audio_cues == null:
		return false
	return _audio_cues.play_cue(cue_id, dedupe_key)


func _input(event: InputEvent) -> void:
	_unlock_feedback_audio_from_event(event)


func _unlock_feedback_audio_from_event(event: InputEvent) -> void:
	if _audio_cues == null or not _audio_cues.has_method("unlock_playback"):
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_audio_cues.unlock_playback()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			_audio_cues.unlock_playback()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_audio_cues.unlock_playback()
	elif event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if button_event.pressed:
			_audio_cues.unlock_playback()
	elif event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) > 0.2:
			_audio_cues.unlock_playback()


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
	_update_current_gate(delta)
	_update_moving_hazards(delta)
	_update_progression_containers()

	if _hazard_cooldown_seconds > 0.0:
		_hazard_cooldown_seconds = maxf(0.0, _hazard_cooldown_seconds - delta)
	elif _hazard_interactions_enabled:
		var hazard_id: String = _world.get_hazard_near(_player.global_position, HAZARD_CONTACT_RADIUS)
		if not hazard_id.is_empty():
			_handle_hazard_hit(hazard_id)
			_update_status_label()
			return
	_update_hazard_warning(delta)

	if _held_salvage < _held_salvage_capacity():
		var nearby_salvage: Dictionary = _world.get_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
		var nearby_interaction := str(nearby_salvage.get("interaction", "instant"))
		if not nearby_salvage.is_empty() and nearby_interaction == "timed_salvage":
			_pry_salvage.update({}, delta)
			var timed_result: Dictionary = _timed_salvage.update(nearby_salvage, delta)
			if str(timed_result.get("state", "")) == "complete":
				var timed_salvage_id := str(timed_result.get("id", ""))
				if _world.collect_salvage_by_id(timed_salvage_id):
					var completed_note := _timed_salvage_completion_feedback(timed_salvage_id, str(timed_result.get("label", "")))
					_collect_salvage_into_cargo(timed_salvage_id, completed_note)
			elif timed_result.has("note"):
				_last_status_note = str(timed_result["note"])
		elif not nearby_salvage.is_empty() and nearby_interaction == "pry_salvage":
			_timed_salvage.update({}, delta)
			var pry_result: Dictionary = _pry_salvage.update(nearby_salvage, delta)
			if str(pry_result.get("state", "")) == "complete":
				var pry_salvage_id := str(pry_result.get("id", ""))
				if _world.collect_salvage_by_id(pry_salvage_id):
					var completed_note := _pry_salvage_completion_feedback(pry_salvage_id, str(pry_result.get("label", "")))
					_collect_salvage_into_cargo(pry_salvage_id, completed_note)
			elif pry_result.has("note"):
				_last_status_note = str(pry_result["note"])
		else:
			var timed_cancel: Dictionary = _timed_salvage.update({}, delta)
			if str(timed_cancel.get("state", "")) == "canceled":
				_last_status_note = str(timed_cancel.get("note", "Salvage interrupted"))
			var pry_cancel: Dictionary = _pry_salvage.update({}, delta)
			if str(pry_cancel.get("state", "")) == "canceled":
				_last_status_note = str(pry_cancel.get("note", "Pry interrupted"))
			var collected_salvage: String = _world.collect_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
			if not collected_salvage.is_empty():
				_collect_salvage_into_cargo(collected_salvage)
	else:
		var blocked_salvage: Dictionary = _world.get_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
		_timed_salvage.reset()
		_pry_salvage.update({}, delta)
		if not blocked_salvage.is_empty():
			_last_status_note = _return_pressure_feedback.cargo_full_prompt(blocked_salvage)

	if _held_salvage > 0 and _world.is_inside_extraction(_player.global_position):
		var banked_cue_key := "%d:%s" % [_banked_salvage + _held_salvage, str(_held_salvage_ids)]
		_banked_salvage += _held_salvage
		_banked_score += _held_salvage_score
		_record_session_payout(_held_salvage_score)
		_record_banked_route_outcomes(_held_salvage_ids)
		_banked_salvage_ids.append_array(_held_salvage_ids)
		var relay_follow_through_note: String = _relay_follow_through_feedback.banked_feedback(_held_salvage_ids)
		var final_dive_note: String = _final_dive_objective_seed.banked_feedback(_held_salvage_ids)
		_held_salvage = 0
		_held_salvage_ids = []
		_held_salvage_score = 0
		if _should_complete_run_after_banking():
			_run_complete = true
			_completion_oxygen_bonus = _calculate_oxygen_completion_bonus()
			_record_session_best_score()
			_last_status_note = "Run complete"
		elif not relay_follow_through_note.is_empty():
			_last_status_note = relay_follow_through_note
			if not final_dive_note.is_empty():
				_last_status_note = "%s\n%s" % [relay_follow_through_note, final_dive_note]
		elif not final_dive_note.is_empty():
			_last_status_note = final_dive_note
		else:
			_last_status_note = "Banked salvage"
		_play_feedback_cue("salvage_bank", banked_cue_key)

	_update_status_label()


func _complete_route_outcome_review_state() -> bool:
	for salvage in _salvage_centers_for_full_collection():
		_player.global_position = salvage["center"]
		_collect_salvage_for_review_state(salvage)
		if _held_salvage >= _held_salvage_capacity():
			_player.global_position = _world.get_extraction_center()
			_process(0.0)

	if _held_salvage > 0:
		_player.global_position = _world.get_extraction_center()
		_process(0.0)

	if not _run_complete:
		push_error("Route outcome review setup did not complete after collecting and returning.")
		return false
	return true


func _salvage_centers_for_full_collection() -> Array:
	if _world == null or not _world.has_method("get_salvage_centers"):
		return []
	if _primary_dive_objective == null:
		return _world.get_salvage_centers()
	return _primary_dive_objective.ordered_salvage_for_full_collection(_world.get_salvage_centers())


func _should_complete_run_after_banking() -> bool:
	if _primary_dive_objective != null and _primary_dive_objective.has_primary_objective():
		return _primary_dive_objective.is_complete(_banked_salvage_ids)
	return _total_salvage > 0 and _banked_salvage >= _total_salvage


func _collect_salvage_for_review_state(salvage: Dictionary) -> void:
	var salvage_id := str(salvage.get("id", "salvage"))
	_process(0.0)
	if _world.is_salvage_collected(salvage_id):
		return
	var interaction := str(salvage.get("interaction", "instant"))
	if interaction == "timed_salvage":
		var interaction_seconds := maxf(0.01, float(salvage.get("interaction_seconds", 0.0)))
		_process(interaction_seconds + 0.1)
		return
	if interaction == "pry_salvage":
		var interaction_seconds := maxf(0.01, float(salvage.get("interaction_seconds", 0.0)))
		var pry_stages: int = max(1, int(salvage.get("pry_stages", 1)))
		_process(interaction_seconds * float(pry_stages) + 0.1)


func _collect_salvage_into_cargo(salvage_id: String, status_note := "") -> void:
	var collected_score: int = _world.get_salvage_score(salvage_id)
	var collected_tier: String = _world.get_salvage_tier(salvage_id)
	_held_salvage += 1
	_held_salvage_ids.append(salvage_id)
	_held_salvage_score += collected_score
	_last_status_note = status_note if not status_note.is_empty() else _salvage_collection_feedback_for_id(salvage_id, collected_tier, collected_score)
	_play_feedback_cue("salvage_pickup", salvage_id)


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


func _pry_salvage_completion_feedback(salvage_id: String, label: String) -> String:
	var display_label := label
	if display_label.is_empty():
		display_label = salvage_id
		if display_label.begins_with("salvage_"):
			display_label = display_label.substr("salvage_".length())
		display_label = display_label.replace("_", " ")
	if not display_label.is_empty():
		display_label = display_label.substr(0, 1).to_upper() + display_label.substr(1)
	return "%s opened +%d" % [display_label, _world.get_salvage_score(salvage_id)]


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
		_reset_run()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_U:
		_try_purchase_oxygen_tank_upgrade()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_C:
		_try_purchase_cargo_capacity_upgrade()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_L:
		_try_purchase_light_upgrade()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_P:
		_try_purchase_propulsion_upgrade()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_E:
		_try_world_connector_transition()


func _reset_run() -> void:
	if _world == null or _player == null:
		return

	_world.reset_salvage()
	_oxygen_rest_feedback.reset()
	_current_gate.reset()
	_pry_salvage.reset()
	_timed_salvage.reset()
	_relay_follow_through_feedback.reset(_world)
	_final_dive_objective_seed.reset(_world)
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
	_reset_hazard_feedback_cues()
	_oxygen_seconds = _oxygen_capacity_seconds()
	_reset_oxygen_feedback_cues()
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


func _try_world_connector_transition() -> bool:
	if _world_connector == null or _world == null or _player == null or _run_complete or _run_failed:
		return false

	var connector: Dictionary = _world_connector.connector_at(_world, _player.global_position)
	if connector.is_empty():
		return false
	var blocking_gate: Dictionary = _current_gate.gate_blocks_position(_world, _player.global_position, Callable(self, "_has_upgrade_id"))
	if not blocking_gate.is_empty():
		_last_status_note = _current_gate_block_prompt(blocking_gate)
		_update_status_label()
		return false

	var destination_map_path := str(connector.get("destination_map_path", "")).strip_edges()
	if destination_map_path.is_empty():
		_last_status_note = "Connector unavailable"
		_update_status_label()
		return false

	var destination_entry_id := str(connector.get("destination_entry_id", "")).strip_edges()
	var arrival_note: String = _world_connector.arrival_note(connector)
	_load_playable_map(destination_map_path, _debug_overlay_enabled, destination_entry_id, arrival_note)
	return true


func _update_oxygen(delta: float) -> bool:
	var previous_oxygen := _oxygen_seconds
	if _world.is_inside_extraction(_player.global_position):
		_oxygen_rest_feedback.reset()
		_oxygen_seconds = minf(_oxygen_capacity_seconds(), _oxygen_seconds + OXYGEN_REFILL_SECONDS_PER_SECOND * delta)
		_update_oxygen_feedback_cues(previous_oxygen)
		return false

	var rest_result: Dictionary = _oxygen_rest_feedback.update(_world, _player.global_position, _oxygen_seconds, delta)
	if bool(rest_result.get("inside", false)):
		_oxygen_seconds = float(rest_result.get("oxygen_seconds", _oxygen_seconds))
		if _oxygen_seconds > 0.0:
			_update_oxygen_feedback_cues(previous_oxygen)
			return false
		_handle_oxygen_depleted()
		return true

	_oxygen_seconds = maxf(0.0, _oxygen_seconds - delta)
	if _oxygen_seconds > 0.0:
		_update_oxygen_feedback_cues(previous_oxygen)
		return false

	_handle_oxygen_depleted()
	return true


func _update_oxygen_feedback_cues(previous_oxygen: float) -> void:
	if _run_complete or _run_failed:
		return
	if _oxygen_seconds > OXYGEN_LOW_WARNING_SECONDS:
		_reset_oxygen_feedback_cues()
		return
	if _oxygen_seconds > OXYGEN_CRITICAL_WARNING_SECONDS:
		_oxygen_critical_cue_emitted = false
	if not _oxygen_low_cue_emitted and previous_oxygen > OXYGEN_LOW_WARNING_SECONDS and _oxygen_seconds <= OXYGEN_LOW_WARNING_SECONDS:
		_oxygen_low_cue_emitted = true
		_play_feedback_cue("oxygen_low", "oxygen_low")
	if not _oxygen_critical_cue_emitted and previous_oxygen > OXYGEN_CRITICAL_WARNING_SECONDS and _oxygen_seconds <= OXYGEN_CRITICAL_WARNING_SECONDS:
		_oxygen_critical_cue_emitted = true
		_play_feedback_cue("oxygen_critical", "oxygen_critical")


func _reset_oxygen_feedback_cues() -> void:
	_oxygen_low_cue_emitted = false
	_oxygen_critical_cue_emitted = false


func _update_current_gate(delta: float) -> void:
	if _current_gate == null:
		return
	_current_gate.update(_world, _player, Callable(self, "_has_upgrade_id"), delta)


func _update_moving_hazards(delta: float) -> void:
	if _moving_hazards == null or _world == null or _player == null:
		return
	_moving_hazards.update(_world, _player.global_position, HAZARD_WARNING_RADIUS, delta)


func _current_gate_block_prompt(gate: Dictionary) -> String:
	var label := str(gate.get("current_gate_label", "Strong current")).strip_edges()
	if label.is_empty():
		label = "Strong current"
	var upgrade_label := str(gate.get("required_upgrade_id", "upgrade")).replace("_", " ")
	return "%s - need %s" % [label.replace("_", " "), upgrade_label]


func _handle_oxygen_depleted() -> void:
	if _run_failed:
		return
	_play_feedback_cue("oxygen_failure", "oxygen_failure")
	_oxygen_rest_feedback.reset()
	_current_gate.reset()
	_moving_hazards.reset(_world)
	_pry_salvage.reset()
	_timed_salvage.reset()
	if not _held_salvage_ids.is_empty():
		_world.restore_salvage(_held_salvage_ids)
		_held_salvage_ids = []
		_held_salvage = 0
		_held_salvage_score = 0
		_last_status_note = "Oxygen depleted - press R"
	else:
		_last_status_note = "Oxygen depleted - press R"

	_oxygen_seconds = _oxygen_capacity_seconds()
	_reset_oxygen_feedback_cues()
	_run_failed = true
	_hazard_cooldown_seconds = HAZARD_COOLDOWN_SECONDS
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	if _player.has_method("snap_camera"):
		_player.snap_camera()


func _handle_hazard_hit(hazard_id: String) -> void:
	_hazard_warning_id = ""
	_reset_hazard_feedback_cues()
	_play_feedback_cue("hazard_contact", hazard_id)
	_oxygen_rest_feedback.reset()
	_current_gate.reset()
	_moving_hazards.reset(_world)
	_pry_salvage.reset()
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


func _update_hazard_warning(delta: float) -> void:
	_hazard_warning_id = ""
	if _hazard_warning_cue_cooldown_seconds > 0.0:
		_hazard_warning_cue_cooldown_seconds = maxf(0.0, _hazard_warning_cue_cooldown_seconds - delta)
	if not _hazard_interactions_enabled or _hazard_cooldown_seconds > 0.0:
		_hazard_warning_cue_id = ""
		return
	if _moving_hazards != null and not _moving_hazards.warning_id().is_empty():
		_set_hazard_warning_id(_moving_hazards.warning_id())
		return
	var hazard: Dictionary = _world.get_nearest_hazard_within(_player.global_position, HAZARD_WARNING_RADIUS)
	if hazard.is_empty():
		_hazard_warning_cue_id = ""
		return
	if float(hazard.get("distance", HAZARD_WARNING_RADIUS)) <= HAZARD_CONTACT_RADIUS:
		_hazard_warning_cue_id = ""
		return
	_set_hazard_warning_id(str(hazard.get("id", "hazard")))


func _set_hazard_warning_id(hazard_id: String) -> void:
	_hazard_warning_id = hazard_id
	if hazard_id.is_empty() or _hazard_warning_cue_id == hazard_id or _hazard_warning_cue_cooldown_seconds > 0.0:
		return
	_hazard_warning_cue_id = hazard_id
	_hazard_warning_cue_cooldown_seconds = HAZARD_WARNING_CUE_COOLDOWN_SECONDS
	_play_feedback_cue("hazard_warning", hazard_id)


func _reset_hazard_feedback_cues() -> void:
	_hazard_warning_cue_id = ""
	_hazard_warning_cue_cooldown_seconds = 0.0


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
		_status_label.text = "Score 0\nSalvage banked 0/0\nHeld 0/%d\nOxygen --" % _held_salvage_capacity()
		_update_result_panel()
		return

	var prompt := ""
	var objective_step_cue_blocked := false
	var oxygen_feedback := _oxygen_feedback_label()
	var oxygen_rest_prompt := _oxygen_rest_prompt()
	var current_gate_prompt := _current_gate_prompt()
	var pre_pickup_route_cue := _pre_pickup_route_cue_prompt()
	var world_connector_prompt := _world_connector_prompt()
	if _run_complete:
		prompt = "Run complete - press R"
		objective_step_cue_blocked = true
	elif _run_failed:
		prompt = "Oxygen depleted - press R"
		objective_step_cue_blocked = true
	elif _held_salvage >= _held_salvage_capacity():
		prompt = _cargo_full_prompt()
		objective_step_cue_blocked = true
	elif not _hazard_warning_id.is_empty():
		prompt = _hazard_warning_prompt()
		objective_step_cue_blocked = true
	elif not oxygen_rest_prompt.is_empty():
		prompt = oxygen_rest_prompt
		objective_step_cue_blocked = true
	elif not current_gate_prompt.is_empty():
		prompt = current_gate_prompt
		objective_step_cue_blocked = true
	elif _is_relay_follow_through_status_note(_last_status_note) or _is_final_dive_status_note(_last_status_note):
		prompt = _last_status_note
		objective_step_cue_blocked = true
	elif _is_progression_status_note(_last_status_note):
		prompt = _last_status_note
		objective_step_cue_blocked = true
	elif not pre_pickup_route_cue.is_empty():
		prompt = pre_pickup_route_cue
		objective_step_cue_blocked = true
	elif _last_status_note.begins_with("Arrived:") and not world_connector_prompt.is_empty():
		prompt = "%s\n%s" % [_last_status_note, world_connector_prompt]
	elif _last_status_note.begins_with("Arrived:"):
		prompt = _last_status_note
	elif not world_connector_prompt.is_empty():
		prompt = world_connector_prompt
	elif not _last_status_note.is_empty():
		prompt = _last_status_note
		objective_step_cue_blocked = _is_collection_status_note(_last_status_note)
	elif _held_salvage > 0:
		prompt = "Return to extraction"
	if not oxygen_feedback.is_empty():
		objective_step_cue_blocked = true
	var objective_text := _route_commitment_overlay_text(not objective_step_cue_blocked)

	var oxygen_seconds := int(ceil(_oxygen_seconds))
	var oxygen_text := "Oxygen %ds" % oxygen_seconds
	if not oxygen_feedback.is_empty():
		oxygen_text = "Oxygen %ds %s" % [oxygen_seconds, oxygen_feedback]
	var progression_text := _progression_overlay_text()

	_status_label.text = "Score %d\nSalvage banked %d/%d\nHeld %d/%d (%d pts)\n%s\n%s" % [
		_banked_score,
		_banked_salvage,
		_total_salvage,
		_held_salvage,
		_held_salvage_capacity(),
		_held_salvage_score,
		oxygen_text,
		progression_text,
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


func _current_gate_prompt() -> String:
	if _current_gate == null:
		return ""
	return _current_gate.current_prompt()


func _world_connector_prompt() -> String:
	if _world_connector == null or _world == null or _player == null or _run_complete or _run_failed:
		return ""
	return _world_connector.prompt_for(_world, _player.global_position)


func _route_commitment_overlay_text(show_step_cue := true) -> String:
	if _route_commitment_feedback == null:
		return ""
	var show_start_cue := false
	if _world != null and _player != null and not _run_complete and not _run_failed:
		show_start_cue = _world.is_inside_extraction(_player.global_position)
	var progress_text: String = _route_commitment_feedback.overlay_text(_held_salvage_ids, _banked_salvage_ids, show_start_cue)
	if not progress_text.is_empty():
		return progress_text
	if _world == null or _player == null or _run_complete or _run_failed:
		return ""
	return _route_commitment_feedback.objective_step_cue_text(
		_world,
		_player.global_position,
		_held_salvage_ids,
		_banked_salvage_ids,
		show_step_cue
	)


func _route_commitment_result_text() -> String:
	if _route_commitment_feedback == null:
		return ""
	return _route_commitment_feedback.result_text(_banked_salvage_ids)


func _next_dive_objective_result_text() -> String:
	if _next_dive_objective_prompt == null:
		return ""
	return _next_dive_objective_prompt.result_text(
		_run_complete,
		_run_failed,
		_primary_dive_objective,
		_banked_salvage_ids
	)


func _relay_follow_through_result_text() -> String:
	if _relay_follow_through_feedback == null or not _run_complete or _run_failed:
		return ""
	return _relay_follow_through_feedback.result_text(_banked_salvage_ids)


func _final_dive_objective_result_text() -> String:
	if _final_dive_objective_seed == null or not _run_complete or _run_failed:
		return ""
	return _final_dive_objective_seed.result_text(_banked_salvage_ids)


func _hazard_warning_prompt() -> String:
	if _moving_hazards != null and _hazard_warning_id == _moving_hazards.warning_id():
		return _moving_hazards.warning_prompt()
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


func _is_collection_status_note(status_note: String) -> bool:
	return (
		status_note.begins_with("Collected ")
		or status_note.begins_with("Salvaging ")
		or status_note.begins_with("Prying ")
		or status_note.begins_with("Pry interrupted")
		or status_note.find(" secured +") != -1
		or status_note.find(" opened +") != -1
		or (_destination_payoff_feedback != null and _destination_payoff_feedback.is_collection_note(status_note))
		or status_note == "Salvage interrupted"
	)


func _is_relay_follow_through_status_note(status_note: String) -> bool:
	return _status_note_contains_feedback(status_note, _relay_follow_through_feedback)


func _is_final_dive_status_note(status_note: String) -> bool:
	return _status_note_contains_feedback(status_note, _final_dive_objective_seed)


func _status_note_contains_feedback(status_note: String, feedback) -> bool:
	if feedback == null or not feedback.has_method("is_feedback_note"):
		return false
	for line in status_note.split("\n", false):
		if feedback.is_feedback_note(str(line)):
			return true
	return false


func _is_progression_status_note(status_note: String) -> bool:
	return (
		status_note == "O2 tank upgraded"
		or status_note == "O2 tank already upgraded"
		or status_note == "Cargo +1 upgraded"
		or status_note == "Cargo +1 already upgraded"
		or status_note == "Light +range upgraded"
		or status_note == "Light +range already upgraded"
		or status_note == "Fins upgraded"
		or status_note == "Fins already upgraded"
		or status_note.begins_with("Upgrade chest +")
		or status_note == "Upgrade at extraction"
		or status_note == "Upgrade blocked"
		or status_note.begins_with("Need ")
	)


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


func _refresh_destination_payoff_feedback(world) -> void:
	if _destination_payoff_feedback == null:
		return
	if world == null or not world.has_method("get_salvage_centers"):
		_destination_payoff_feedback.reset([])
		return
	_destination_payoff_feedback.reset(world.get_salvage_centers())


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
	if _destination_payoff_feedback != null:
		var destination_label: String = _destination_payoff_feedback.route_label(validation_route)
		if not destination_label.is_empty():
			return destination_label
	return validation_route.replace("_", " ")


func _salvage_collection_feedback_for_id(salvage_id: String, tier: String, score: int) -> String:
	var validation_route := str(_salvage_validation_routes_by_id.get(salvage_id, ""))
	if validation_route == SOUTHWEST_POCKET_DECISION_ID:
		return "Southwest pocket payoff +%d" % score
	if _destination_payoff_feedback != null:
		var destination_feedback: String = _destination_payoff_feedback.collection_feedback(salvage_id, score)
		if not destination_feedback.is_empty():
			return destination_feedback
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


func _record_session_payout(banked_score: int) -> int:
	if _session_progression == null:
		return 0
	return _session_progression.record_banked_salvage(banked_score)


func _session_wallet() -> int:
	if _session_progression == null:
		return 0
	return _session_progression.wallet()


func _session_payout_total() -> int:
	if _session_progression == null:
		return 0
	return _session_progression.total_payout_earned()


func _grant_wallet_reward(amount: int) -> int:
	if _session_progression == null:
		return 0
	return _session_progression.grant_wallet_reward(amount)


func _update_progression_containers() -> void:
	if _progression_containers == null or _world == null or _player == null:
		return
	var result: Dictionary = _progression_containers.try_open(_world, _player.global_position, Callable(self, "_grant_wallet_reward"))
	if str(result.get("state", "")) == "opened" and result.has("note"):
		_last_status_note = str(result["note"])


func _try_purchase_oxygen_tank_upgrade() -> bool:
	if _world == null or _player == null or _session_progression == null:
		return false
	if not _world.is_inside_extraction(_player.global_position):
		_last_status_note = "Upgrade at extraction"
		_update_status_label()
		return false
	var result: Dictionary = _session_progression.purchase_oxygen_tank_upgrade()
	if bool(result.get("purchased", false)):
		_last_status_note = "O2 tank upgraded"
		_update_status_label()
		return true
	var reason := str(result.get("reason", "blocked"))
	if reason == "insufficient_funds":
		_last_status_note = "Need %d more" % int(result.get("needed", 0))
	elif reason == "already_purchased":
		_last_status_note = "O2 tank already upgraded"
	else:
		_last_status_note = "Upgrade blocked"
	_update_status_label()
	return false


func _try_purchase_cargo_capacity_upgrade() -> bool:
	if _world == null or _player == null or _session_progression == null:
		return false
	if not _world.is_inside_extraction(_player.global_position):
		_last_status_note = "Upgrade at extraction"
		_update_status_label()
		return false
	var result: Dictionary = _session_progression.purchase_cargo_capacity_upgrade()
	if bool(result.get("purchased", false)):
		_last_status_note = "Cargo +1 upgraded"
		_update_status_label()
		return true
	var reason := str(result.get("reason", "blocked"))
	if reason == "insufficient_funds":
		_last_status_note = "Need %d more" % int(result.get("needed", 0))
	elif reason == "already_purchased":
		_last_status_note = "Cargo +1 already upgraded"
	else:
		_last_status_note = "Upgrade blocked"
	_update_status_label()
	return false


func _try_purchase_light_upgrade() -> bool:
	if _world == null or _player == null or _session_progression == null:
		return false
	if not _world.is_inside_extraction(_player.global_position):
		_last_status_note = "Upgrade at extraction"
		_update_status_label()
		return false
	var result: Dictionary = _session_progression.purchase_light_upgrade()
	if bool(result.get("purchased", false)):
		_apply_session_light_profile()
		_last_status_note = "Light +range upgraded"
		_update_status_label()
		return true
	var reason := str(result.get("reason", "blocked"))
	if reason == "insufficient_funds":
		_last_status_note = "Need %d more" % int(result.get("needed", 0))
	elif reason == "already_purchased":
		_last_status_note = "Light +range already upgraded"
	else:
		_last_status_note = "Upgrade blocked"
	_update_status_label()
	return false


func _try_purchase_propulsion_upgrade() -> bool:
	if _world == null or _player == null or _session_progression == null:
		return false
	if not _world.is_inside_extraction(_player.global_position):
		_last_status_note = "Upgrade at extraction"
		_update_status_label()
		return false
	var result: Dictionary = _session_progression.purchase_propulsion_upgrade()
	if bool(result.get("purchased", false)):
		_last_status_note = "Fins upgraded"
		_update_status_label()
		return true
	var reason := str(result.get("reason", "blocked"))
	if reason == "insufficient_funds":
		_last_status_note = "Need %d more" % int(result.get("needed", 0))
	elif reason == "already_purchased":
		_last_status_note = "Fins already upgraded"
	else:
		_last_status_note = "Upgrade blocked"
	_update_status_label()
	return false


func _has_oxygen_tank_upgrade() -> bool:
	return _session_progression != null and _session_progression.has_oxygen_tank_upgrade()


func _has_cargo_capacity_upgrade() -> bool:
	return _session_progression != null and _session_progression.has_cargo_capacity_upgrade()


func _has_light_upgrade() -> bool:
	return _session_progression != null and _session_progression.has_light_upgrade()


func _has_propulsion_upgrade() -> bool:
	return _session_progression != null and _session_progression.has_propulsion_upgrade()


func _has_upgrade_id(upgrade_id: String) -> bool:
	match upgrade_id:
		SessionProgression.OXYGEN_TANK_UPGRADE_ID:
			return _has_oxygen_tank_upgrade()
		SessionProgression.CARGO_CAPACITY_UPGRADE_ID:
			return _has_cargo_capacity_upgrade()
		SessionProgression.LIGHT_UPGRADE_ID:
			return _has_light_upgrade()
		SessionProgression.PROPULSION_UPGRADE_ID:
			return _has_propulsion_upgrade()
	return false


func _apply_session_light_profile() -> void:
	if _session_progression == null:
		return
	if _player != null and _player.has_method("apply_light_profile"):
		_player.apply_light_profile(_session_progression.light_range_scale(), _session_progression.light_alpha())
	if _world != null and _world.has_method("set_visibility_upgrade_state"):
		_world.set_visibility_upgrade_state(SessionProgression.LIGHT_UPGRADE_ID, _session_progression.has_light_upgrade())


func _held_salvage_capacity() -> int:
	if _session_progression == null:
		return HELD_SALVAGE_CAPACITY
	return HELD_SALVAGE_CAPACITY + _session_progression.cargo_capacity_bonus()


func _oxygen_capacity_seconds() -> float:
	if _session_progression == null:
		return OXYGEN_MAX_SECONDS
	return OXYGEN_MAX_SECONDS + _session_progression.oxygen_bonus_seconds()


func _progression_overlay_text() -> String:
	var oxygen_text := "O2 tank +%ds" % int(SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS)
	if not _has_oxygen_tank_upgrade():
		oxygen_text = "U: O2 +%ds (%d)" % [
			int(SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS),
			SessionProgression.OXYGEN_TANK_UPGRADE_COST,
		]
	var cargo_text := "Cargo +%d" % int(SessionProgression.CARGO_CAPACITY_UPGRADE_BONUS)
	if not _has_cargo_capacity_upgrade():
		cargo_text = "C: Cargo +%d (%d)" % [
			int(SessionProgression.CARGO_CAPACITY_UPGRADE_BONUS),
			SessionProgression.CARGO_CAPACITY_UPGRADE_COST,
		]
	var light_text := "Light +range"
	if not _has_light_upgrade():
		light_text = "Light base"
		if _world != null and _player != null and _world.is_inside_extraction(_player.global_position):
			light_text = "L: Light +range (%d)" % SessionProgression.LIGHT_UPGRADE_COST
	var fins_text := "Fins" if _has_propulsion_upgrade() else "Fins base"
	if not _has_propulsion_upgrade() and _world != null and _player != null and _world.is_inside_extraction(_player.global_position):
		fins_text = "P: Fins (%d)" % SessionProgression.PROPULSION_UPGRADE_COST
	return "Wallet %d\n%s | %s\n%s | %s" % [
		_session_wallet(),
		oxygen_text,
		cargo_text,
		light_text,
		fins_text,
	]


func _progression_result_text() -> String:
	var oxygen_text := "O2 tank +%ds" % int(SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS) if _has_oxygen_tank_upgrade() else "O2 tank base"
	var cargo_text := "Cargo +%d" % int(SessionProgression.CARGO_CAPACITY_UPGRADE_BONUS) if _has_cargo_capacity_upgrade() else "Cargo base"
	var light_text := "Light +range" if _has_light_upgrade() else "Light base"
	var fins_text := "Fins" if _has_propulsion_upgrade() else "Fins base"
	return "Wallet %d | %s | %s | %s | %s" % [_session_wallet(), oxygen_text, cargo_text, light_text, fins_text]


func _update_result_panel() -> void:
	if _result_panel == null or _result_label == null:
		return
	_result_panel.visible = _run_complete or _run_failed
	if not _run_complete and not _run_failed:
		_result_label.text = ""
		return

	var oxygen_text := "Oxygen %ds" % int(ceil(_oxygen_seconds))
	if _run_failed:
		oxygen_text = "Oxygen depleted"
	_result_label.text = ResultPresentationBuilder.build_text({
		"run_complete": _run_complete,
		"run_failed": _run_failed,
		"score": _current_expedition_score(),
		"salvage_score": _banked_score,
		"oxygen_bonus": _completion_oxygen_bonus,
		"best_score": _session_best_score(),
		"banked_salvage": _banked_salvage,
		"total_salvage": _total_salvage,
		"route_text": _route_outcome_text(),
		"objective_text": _route_commitment_result_text(),
		"next_dive_text": _next_dive_objective_result_text(),
		"relay_follow_through_text": _relay_follow_through_result_text(),
		"final_dive_text": _final_dive_objective_result_text(),
		"progression_text": _progression_result_text(),
		"progression_status_note": _last_status_note if _is_progression_status_note(_last_status_note) else "",
		"oxygen_text": oxygen_text,
	})


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
