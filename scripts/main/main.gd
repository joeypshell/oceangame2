extends Node2D

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const AnomalySurveyCapture := preload("res://scripts/main/captures/anomaly_survey_capture.gd")
const ActiveToolController := preload("res://scripts/main/active_tool_controller.gd")
const ActiveToolHud := preload("res://scripts/main/active_tool_hud.gd")
const ActiveToolRuntime := preload("res://scripts/main/active_tool_runtime.gd")
const HeldCargoHud := preload("res://scripts/main/held_cargo_hud.gd")
const CaptureController := preload("res://scripts/main/capture_controller.gd")
const CargoCollectionController := preload("res://scripts/main/cargo_collection_controller.gd")
const BiologicalResourceController := preload("res://scripts/main/biological_resource_controller.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const CurrentGateCapture := preload("res://scripts/main/captures/current_gate_capture.gd")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")
const DestinationPayoffFeedback := preload("res://scripts/main/destination_payoff_feedback.gd")
const ExpeditionDayCapture := preload("res://scripts/main/captures/expedition_day_capture.gd")
const Expansion03MaterialProjectCapture := preload("res://scripts/main/captures/expansion_03_material_project_capture.gd")
const Expansion04CurrentPocketCapture := preload("res://scripts/main/captures/expansion_04_current_pocket_capture.gd")
const Expansion05PracticalResearchCapture := preload("res://scripts/main/captures/expansion_05_practical_research_capture.gd")
const Expansion06CombatFoundationCapture := preload("res://scripts/main/captures/expansion_06_combat_foundation_capture.gd")
const Expansion07BiologicalProgressionCapture := preload("res://scripts/main/captures/expansion_07_biological_progression_capture.gd")
const Expansion08DailyConditionCapture := preload("res://scripts/main/captures/expansion_08_daily_condition_capture.gd")
const Expansion09FullLevelCapture := preload("res://scripts/main/captures/expansion_09_full_level_capture.gd")
const Expansion10RegionalJourneyCapture := preload("res://scripts/main/captures/expansion_10_regional_journey_capture.gd")
const Expansion11LightReturnCapture := preload("res://scripts/main/captures/expansion_11_light_return_capture.gd")
const Expansion12PressureReturnCapture := preload("res://scripts/main/captures/expansion_12_pressure_return_capture.gd")
const Expansion13SoutheastWreckCapture := preload("res://scripts/main/captures/expansion_13_southeast_wreck_capture.gd")
const Expansion13ScannerCutterCorrectionCapture := preload("res://scripts/main/captures/expansion_13_scanner_cutter_correction_capture.gd")
const Expansion14ArchiveCurrentReturnCapture := preload("res://scripts/main/captures/expansion_14_archive_current_return_capture.gd")
const FinalDiveObjectiveSeed := preload("res://scripts/main/final_dive_objective_seed.gd")
const MovingHazardCapture := preload("res://scripts/main/captures/moving_hazard_capture.gd")
const MovingHazardController := preload("res://scripts/main/moving_hazard_controller.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")
const TerritorialHostileController := preload("res://scripts/main/territorial_hostile_controller.gd")
const OxygenRestPocketFeedback := preload("res://scripts/main/oxygen_rest_pocket_feedback.gd")
const Pass22DestinationPayoffCapture := preload("res://scripts/main/captures/pass_22_destination_payoff_capture.gd")
const Pass23NextDiveObjectiveCapture := preload("res://scripts/main/captures/pass_23_next_dive_objective_capture.gd")
const Pass24RelayFollowThroughCapture := preload("res://scripts/main/captures/pass_24_relay_follow_through_capture.gd")
const Pass25FinalDiveObjectiveCapture := preload("res://scripts/main/captures/pass_25_final_dive_objective_capture.gd")
const Pass26ResultPresentationCapture := preload("res://scripts/main/captures/pass_26_result_presentation_capture.gd")
const Pass27PlayerFacingCapture := preload("res://scripts/main/captures/pass_27_player_facing_capture.gd")
const PrePickupRouteCueFeedback := preload("res://scripts/main/pre_pickup_route_cue_feedback.gd")
const PressureZoneController := preload("res://scripts/main/pressure_zone_controller.gd")
const NextDiveObjectivePrompt := preload("res://scripts/main/next_dive_objective_prompt.gd")
const PrimaryDiveObjective := preload("res://scripts/main/primary_dive_objective.gd")
const ProgressionContainerController := preload("res://scripts/main/progression_container_controller.gd")
const ProgressionProjectTracker := preload("res://scripts/main/progression_project_tracker.gd")
const ProgressionRuntimeController := preload("res://scripts/main/progression_runtime_controller.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ReviewProfileMode := preload("res://scripts/main/review_profile_mode.gd")
const PrySalvageController := preload("res://scripts/main/pry_salvage_controller.gd")
const RelayFollowThroughFeedback := preload("res://scripts/main/relay_follow_through_feedback.gd")
const ReturnPressureFeedback := preload("res://scripts/main/return_pressure_feedback.gd")
const ResultPresentationBuilder := preload("res://scripts/main/result_presentation_builder.gd")
const RouteCommitmentFeedback := preload("res://scripts/main/route_commitment_feedback.gd")
const SessionProgression := preload("res://scripts/main/session_progression.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpeditionDayPresentation := preload("res://scripts/main/expedition_day_presentation.gd")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const DailyConditionState := preload("res://scripts/main/daily_condition_state.gd")
const MapCatalog := preload("res://scripts/main/map_catalog.gd")
const MapRuntimeProbe := preload("res://scripts/main/map_runtime_probe.gd")
const MaterialRuntimeController := preload("res://scripts/main/material_runtime_controller.gd")
const MaterialProjectRuntime := preload("res://scripts/main/material_project_runtime.gd")
const PlayerHealthState := preload("res://scripts/main/player_health_state.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")
const TimedSalvageController := preload("res://scripts/main/timed_salvage_controller.gd")
const WorldConnectorController := preload("res://scripts/main/world_connector_controller.gd")
const AudioCuePlayer := preload("res://scripts/main/audio_cue_player.gd")
const SmokeFeedbackAudioChecks := preload("res://scripts/main/smoke/smoke_feedback_audio_checks.gd")
const SmokeActiveToolChecks := preload("res://scripts/main/smoke/smoke_active_tool_checks.gd")
const SmokeAnomalySurveyJourneyChecks := preload("res://scripts/main/smoke/smoke_anomaly_survey_journey_checks.gd")
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
const SmokePlayerFacingTransitionChecks := preload("res://scripts/main/smoke/smoke_player_facing_transition_checks.gd")
const SmokeDarknessLightChecks := preload("res://scripts/main/smoke/smoke_darkness_light_checks.gd")
const SmokeExpeditionDayChecks := preload("res://scripts/main/smoke/smoke_expedition_day_checks.gd")
const SmokeExpansion03JourneyChecks := preload("res://scripts/main/smoke/smoke_expansion_03_journey_checks.gd")
const SmokeExpansion04JourneyChecks := preload("res://scripts/main/smoke/smoke_expansion_04_journey_checks.gd")
const SmokeExpansion05JourneyChecks := preload("res://scripts/main/smoke/smoke_expansion_05_journey_checks.gd")
const SmokeExpansion06CombatJourneyChecks := preload("res://scripts/main/smoke/smoke_expansion_06_combat_journey_checks.gd")
const SmokeExpansion07BiologicalJourneyChecks := preload("res://scripts/main/smoke/smoke_expansion_07_biological_journey_checks.gd")
const SmokeExpansion08DailyConditionJourneyChecks := preload("res://scripts/main/smoke/smoke_expansion_08_daily_condition_journey_checks.gd")
const SmokeExpansion09FullLevelJourneyChecks := preload("res://scripts/main/smoke/smoke_expansion_09_full_level_journey_checks.gd")
const SmokeExpansion10RegionalJourneyChecks := preload("res://scripts/main/smoke/smoke_expansion_10_regional_journey_checks.gd")
const SmokeExpansion11LightReturnChecks := preload("res://scripts/main/smoke/smoke_expansion_11_light_return_checks.gd")
const SmokeExpansion12PressureReturnChecks := preload("res://scripts/main/smoke/smoke_expansion_12_pressure_return_checks.gd")
const SmokeExpansion13SoutheastWreckReturnChecks := preload("res://scripts/main/smoke/smoke_expansion_13_southeast_wreck_return_checks.gd")
const SmokeExpansion13ScannerCutterCorrectionChecks := preload("res://scripts/main/smoke/smoke_expansion_13_scanner_cutter_correction_checks.gd")
const SmokeExpansion14ArchiveCurrentReturnChecks := preload("res://scripts/main/smoke/smoke_expansion_14_archive_current_return_checks.gd")
const SmokeReleaseJourneyChecks := preload("res://scripts/main/smoke/smoke_release_journey_checks.gd")
const UpgradeChestCapture := preload("res://scripts/main/captures/upgrade_chest_capture.gd")
const DEFAULT_MAP_PATH := MapCatalog.DEFAULT_MAP_PATH
const ORIGINAL_MAP_PATH := MapCatalog.ORIGINAL_MAP_PATH
const TILESET_TEST_MAP_PATH := MapCatalog.TILESET_TEST_MAP_PATH
const ORGANIC_MAP_PATH := MapCatalog.ORGANIC_MAP_PATH
const FULL_SKETCH_MAP_PATH := MapCatalog.FULL_SKETCH_MAP_PATH
const PRODUCTION_LEVEL_MAP_PATH := MapCatalog.PRODUCTION_LEVEL_MAP_PATH
const PRODUCTION_SLICE_MAP_PATH := MapCatalog.PRODUCTION_SLICE_MAP_PATH
const PRODUCTION_SLICE_02_MAP_PATH := MapCatalog.PRODUCTION_SLICE_02_MAP_PATH
const PRODUCTION_SLICE_03_MAP_PATH := MapCatalog.PRODUCTION_SLICE_03_MAP_PATH
const PRODUCTION_SLICE_04_MAP_PATH := MapCatalog.PRODUCTION_SLICE_04_MAP_PATH
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
const PASS_21_WORLD_CONNECTOR_CAPTURE_DIR := "res://visual_captures/pass_21_world_connector"
const PASS_22_DESTINATION_PAYOFF_CAPTURE_DIR := "res://visual_captures/pass_22_destination_payoff"
const PASS_23_NEXT_DIVE_OBJECTIVE_CAPTURE_DIR := "res://visual_captures/pass_23_next_dive_objective"
const PASS_24_RELAY_FOLLOW_THROUGH_CAPTURE_DIR := "res://visual_captures/pass_24_relay_follow_through"
const PASS_25_FINAL_DIVE_OBJECTIVE_CAPTURE_DIR := "res://visual_captures/pass_25_final_dive_objective"
const PASS_26_RESULT_PRESENTATION_CAPTURE_DIR := "res://visual_captures/pass_26_result_presentation"
const PASS_27_PLAYER_FACING_CAPTURE_DIR := "res://visual_captures/pass_27_player_facing"
const ANOMALY_SURVEY_CAPTURE_DIR := "res://visual_captures/anomaly_survey"
const EXPEDITION_DAY_CAPTURE_DIR := "res://visual_captures/expedition_day"
const EXPANSION_03_MATERIAL_PROJECT_CAPTURE_DIR := "res://visual_captures/expansion_03_material_project"
const EXPANSION_04_CURRENT_POCKET_CAPTURE_DIR := "res://visual_captures/expansion_04_current_pocket"
const EXPANSION_05_PRACTICAL_RESEARCH_CAPTURE_DIR := "res://visual_captures/expansion_05_practical_research"
const EXPANSION_06_COMBAT_FOUNDATION_CAPTURE_DIR := "res://visual_captures/expansion_06_combat_foundation"
const EXPANSION_07_BIOLOGICAL_PROGRESSION_CAPTURE_DIR := "res://visual_captures/expansion_07_biological_progression"
const EXPANSION_08_DAILY_CONDITION_CAPTURE_DIR := "res://visual_captures/expansion_08_daily_condition"
const EXPANSION_09_FULL_LEVEL_CAPTURE_DIR := "res://visual_captures/expansion_09_full_level"
const EXPANSION_10_REGIONAL_JOURNEY_CAPTURE_DIR := "res://visual_captures/expansion_10_regional_journey"
const EXPANSION_11_LIGHT_RETURN_CAPTURE_DIR := "res://visual_captures/expansion_11_deep_harmonic_light"
const EXPANSION_12_PRESSURE_RETURN_CAPTURE_DIR := "res://visual_captures/expansion_12_abyssal_pressure"
const EXPANSION_13_SOUTHEAST_WRECK_CAPTURE_DIR := "res://visual_captures/expansion_13_southeast_wreck"
const EXPANSION_13_SCANNER_CUTTER_CORRECTION_CAPTURE_DIR := "res://visual_captures/expansion_13_scanner_cutter_correction"
const EXPANSION_14_ARCHIVE_CURRENT_RETURN_CAPTURE_DIR := "res://visual_captures/expansion_14_archive_current_return"
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
const COMBAT_FEEDBACK_SECONDS := 1.4
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
var _world
var _player
var _anomaly_survey
var _active_tools
var _active_tool_runtime
var _capture_controller
var _cargo_collection
var _biological_resources
var _current_gate
var _cutter_salvage
var _destination_payoff_feedback
var _final_dive_objective_seed
var _moving_hazards
var _shock_prod
var _hostiles
var _material_runtime
var _daily_conditions
var _material_project
var _next_dive_objective_prompt
var _oxygen_rest_feedback
var _pre_pickup_route_cue_feedback
var _pressure_zone
var _primary_dive_objective
var _progression_containers
var _progression_project_tracker
var _progression_runtime
var _pry_salvage
var _relay_follow_through_feedback
var _return_pressure_feedback
var _route_commitment_feedback
var _session_progression
var _player_health
var _sortie_state
var _expedition_day_state
var _timed_salvage
var _world_connector
var _audio_cues
var _smoke_feedback_audio_checks
var _smoke_active_tool_checks
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
var _smoke_player_facing_transition_checks
var _smoke_darkness_light_checks
var _smoke_expedition_day_checks
var _smoke_release_journey_checks
var _review_canvas: CanvasLayer
var _review_label: Label
var _active_tool_hud
var _held_cargo_hud
var _status_label: Label
var _result_panel: PanelContainer
var _result_label: Label
var _map_selector: OptionButton
var _map_selector_enabled := false
var _fresh_review_profile_enabled := false
var _review_checkpoint_id := ""
var _review_checkpoint_report := {}
var _debug_overlay_enabled := false
var _banked_salvage := 0
var _total_salvage := 0
var _banked_salvage_ids: Array[String] = []
var _banked_score := 0
var _completion_oxygen_bonus := 0
var _session_best_scores_by_map := {}
var _salvage_validation_routes_by_id := {}
var _banked_validation_route_counts := {}
var _hazard_cooldown_seconds := 0.0
var _hazard_feedback_seconds := 0.0
var _hazard_interactions_enabled := true
var _combat_interactions_enabled := true
var _hazard_warning_id := ""
var _hazard_warning_cue_id := ""
var _hazard_warning_cue_cooldown_seconds := 0.0
var _combat_feedback_seconds := 0.0
var _oxygen_low_cue_emitted := false
var _oxygen_critical_cue_emitted := false
var _run_complete := false
var _last_status_note := ""


func _ready() -> void:
	_active_tools = ActiveToolController.new()
	_active_tool_runtime = ActiveToolRuntime.new(self, _active_tools)
	_capture_controller = CaptureController.new(self)
	_current_gate = CurrentGateController.new()
	_destination_payoff_feedback = DestinationPayoffFeedback.new()
	_final_dive_objective_seed = FinalDiveObjectiveSeed.new()
	_moving_hazards = MovingHazardController.new()
	_shock_prod = ShockProdController.new()
	_hostiles = TerritorialHostileController.new()
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
	_player_health = PlayerHealthState.new()
	_sortie_state = SortieState.new(OXYGEN_MAX_SECONDS)
	_expedition_day_state = ExpeditionDayState.new()
	_daily_conditions = DailyConditionState.new()
	_progression_runtime = ProgressionRuntimeController.new(_session_progression)
	_timed_salvage = TimedSalvageController.new()
	_world_connector = WorldConnectorController.new()
	_audio_cues = AudioCuePlayer.new()
	add_child(_audio_cues)
	_smoke_feedback_audio_checks = SmokeFeedbackAudioChecks.new(self)
	_smoke_active_tool_checks = SmokeActiveToolChecks.new(self)
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
	_smoke_player_facing_transition_checks = SmokePlayerFacingTransitionChecks.new(self)
	_smoke_darkness_light_checks = SmokeDarknessLightChecks.new(self)
	_smoke_expedition_day_checks = SmokeExpeditionDayChecks.new(self)
	_smoke_release_journey_checks = SmokeReleaseJourneyChecks.new(self)
	var user_args := OS.get_cmdline_user_args()
	var engine_args := OS.get_cmdline_args()
	_review_checkpoint_id = ReviewProfileMode.checkpoint_id(user_args, engine_args)
	_fresh_review_profile_enabled = ReviewProfileMode.requested(user_args, engine_args)
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
	var capture_pass_21_world_connector := _has_arg(user_args, engine_args, "--capture-pass-21-world-connector")
	var capture_pass_22_destination_payoff := _has_arg(user_args, engine_args, "--capture-pass-22-destination-payoff")
	var capture_pass_23_next_dive_objective := _has_arg(user_args, engine_args, "--capture-pass-23-next-dive-objective")
	var capture_pass_24_relay_follow_through := _has_arg(user_args, engine_args, "--capture-pass-24-relay-follow-through")
	var capture_pass_25_final_dive_objective := _has_arg(user_args, engine_args, "--capture-pass-25-final-dive-objective")
	var capture_pass_26_result_presentation := _has_arg(user_args, engine_args, "--capture-pass-26-result-presentation")
	var capture_pass_27_player_facing := _has_arg(user_args, engine_args, "--capture-pass-27-player-facing")
	var capture_anomaly_survey := _has_arg(user_args, engine_args, "--capture-anomaly-survey")
	var capture_expedition_day := _has_arg(user_args, engine_args, "--capture-expedition-day")
	var capture_expansion_03_material_project := _has_arg(user_args, engine_args, "--capture-expansion-03-material-project")
	var capture_expansion_04_current_pocket := _has_arg(user_args, engine_args, "--capture-expansion-04-current-pocket")
	var capture_expansion_05_practical_research := _has_arg(user_args, engine_args, "--capture-expansion-05-practical-research")
	var capture_expansion_06_combat_foundation := _has_arg(user_args, engine_args, "--capture-expansion-06-combat-foundation")
	var capture_expansion_07_biological_progression := _has_arg(user_args, engine_args, "--capture-expansion-07-biological-progression")
	var capture_expansion_08_daily_condition := _has_arg(user_args, engine_args, "--capture-expansion-08-daily-condition")
	var capture_expansion_09_full_level := _has_arg(user_args, engine_args, "--capture-expansion-09-full-level")
	var capture_expansion_10_regional_journey := _has_arg(user_args, engine_args, "--capture-expansion-10-regional-journey")
	var capture_expansion_11_light_return := _has_arg(user_args, engine_args, "--capture-expansion-11-light-return")
	var capture_expansion_12_pressure_return := _has_arg(user_args, engine_args, "--capture-expansion-12-pressure-return")
	var capture_expansion_13_southeast_wreck := _has_arg(user_args, engine_args, "--capture-expansion-13-southeast-wreck")
	var capture_expansion_13_scanner_cutter_correction := _has_arg(user_args, engine_args, "--capture-expansion-13-scanner-cutter-correction")
	var capture_expansion_14_archive_current_return := _has_arg(user_args, engine_args, "--capture-expansion-14-archive-current-return")
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
	var smoke_pass_27_facing_transitions := _has_arg(user_args, engine_args, "--smoke-pass-27-facing-transitions")
	var smoke_movement_feel := _has_arg(user_args, engine_args, "--smoke-movement-feel")
	var smoke_release_journey := _has_arg(user_args, engine_args, "--smoke-release-journey")
	var smoke_anomaly_survey_journey := _has_arg(user_args, engine_args, "--smoke-anomaly-survey-journey")
	var smoke_expedition_day := _has_arg(user_args, engine_args, "--smoke-expedition-day")
	var smoke_expansion_03_material_project := _has_arg(user_args, engine_args, "--smoke-expansion-03-material-project")
	var smoke_expansion_04_current_pocket := _has_arg(user_args, engine_args, "--smoke-expansion-04-current-pocket")
	var smoke_expansion_05_practical_research := _has_arg(user_args, engine_args, "--smoke-expansion-05-practical-research")
	var smoke_expansion_06_combat_foundation := _has_arg(user_args, engine_args, "--smoke-expansion-06-combat-foundation")
	var smoke_expansion_07_biological_progression := _has_arg(user_args, engine_args, "--smoke-expansion-07-biological-progression")
	var smoke_expansion_08_daily_condition_journey := _has_arg(user_args, engine_args, "--smoke-expansion-08-daily-condition-journey")
	var smoke_expansion_09_full_level_journey := _has_arg(user_args, engine_args, "--smoke-expansion-09-full-level-journey")
	var smoke_expansion_10_regional_journey := _has_arg(user_args, engine_args, "--smoke-expansion-10-regional-journey")
	var smoke_expansion_11_light_return := _has_arg(user_args, engine_args, "--smoke-expansion-11-deep-harmonic-light-return")
	var smoke_expansion_12_pressure_return := _has_arg(user_args, engine_args, "--smoke-expansion-12-abyssal-pressure-return")
	var smoke_expansion_13_southeast_wreck_return := _has_arg(user_args, engine_args, "--smoke-expansion-13-southeast-wreck-return")
	var smoke_expansion_13_scanner_cutter_correction := _has_arg(user_args, engine_args, "--smoke-expansion-13-scanner-cutter-correction")
	var smoke_expansion_14_archive_current_return := _has_arg(user_args, engine_args, "--smoke-expansion-14-archive-current-return")
	var smoke_active_tool_selection := _has_arg(user_args, engine_args, "--smoke-active-tool-selection")
	var smoke_checkpoint_shock_prod := _has_arg(user_args, engine_args, "--smoke-checkpoint-shock-prod")
	var requested_map_path := MapCatalog.requested_map_path(user_args, engine_args)
	var measure_map_runtime := _has_arg(user_args, engine_args, "--measure-map-runtime")
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
	elif capture_pass_27_player_facing:
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
	elif capture_expansion_05_practical_research:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_expansion_06_combat_foundation:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_expansion_07_biological_progression:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_expansion_08_daily_condition:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif capture_expansion_09_full_level:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif capture_expansion_10_regional_journey:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif capture_expansion_11_light_return:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif capture_expansion_12_pressure_return:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif capture_expansion_13_southeast_wreck:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif capture_expansion_13_scanner_cutter_correction:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif capture_expansion_14_archive_current_return:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
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
	elif smoke_pass_27_facing_transitions:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_release_journey:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_expedition_day:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_expansion_03_material_project:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_expansion_05_practical_research:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_expansion_06_combat_foundation:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_expansion_07_biological_progression:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_expansion_08_daily_condition_journey:
		selected_map_path = PRODUCTION_SLICE_MAP_PATH
	elif smoke_expansion_09_full_level_journey:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif smoke_expansion_10_regional_journey:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif smoke_expansion_11_light_return:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif smoke_expansion_13_scanner_cutter_correction:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif smoke_expansion_14_archive_current_return:
		selected_map_path = PRODUCTION_LEVEL_MAP_PATH
	elif not requested_map_path.is_empty():
		selected_map_path = requested_map_path
	var checkpoint_map_path := ReviewCheckpointFixture.required_map_path(_review_checkpoint_id)
	if not checkpoint_map_path.is_empty():
		selected_map_path = checkpoint_map_path

	_debug_overlay_enabled = (
		_has_arg(user_args, engine_args, "--show-debug-overlay")
		or capture_production_slice_debug_map
		or capture_production_slice_02_debug_map
		or capture_production_slice_03_debug_map
		or capture_production_slice_04_debug_map
	)
	var automated_review := (
		measure_map_runtime
		or check_map_parity
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
		or capture_pass_21_world_connector
		or capture_pass_22_destination_payoff
		or capture_pass_23_next_dive_objective
		or capture_pass_24_relay_follow_through
		or capture_pass_25_final_dive_objective
		or capture_pass_26_result_presentation
		or capture_pass_27_player_facing
		or capture_anomaly_survey
		or capture_expedition_day
		or capture_expansion_03_material_project
		or capture_expansion_04_current_pocket
		or capture_expansion_05_practical_research
		or capture_expansion_06_combat_foundation
		or capture_expansion_07_biological_progression
		or capture_expansion_08_daily_condition
		or capture_expansion_09_full_level
		or capture_expansion_10_regional_journey
		or capture_expansion_11_light_return
		or capture_expansion_12_pressure_return
		or capture_expansion_13_southeast_wreck
		or capture_expansion_13_scanner_cutter_correction
		or capture_expansion_14_archive_current_return
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
		or smoke_pass_27_facing_transitions
		or smoke_movement_feel
		or smoke_release_journey
		or smoke_anomaly_survey_journey
		or smoke_expedition_day
		or smoke_expansion_03_material_project
		or smoke_expansion_04_current_pocket
		or smoke_expansion_05_practical_research
		or smoke_expansion_06_combat_foundation
		or smoke_expansion_07_biological_progression
		or smoke_expansion_08_daily_condition_journey
		or smoke_expansion_09_full_level_journey
		or smoke_expansion_10_regional_journey
		or smoke_expansion_11_light_return
		or smoke_expansion_12_pressure_return
		or smoke_expansion_13_southeast_wreck_return
		or smoke_expansion_13_scanner_cutter_correction
		or smoke_expansion_14_archive_current_return
		or smoke_active_tool_selection
		or smoke_checkpoint_shock_prod
		or _has_arg(user_args, engine_args, "--capture-greybox-screenshot")
		or _has_arg(user_args, engine_args, "--capture-camera-tests")
	)
	var profile_persistence_enabled := ReviewProfileMode.persistence_enabled(automated_review, _fresh_review_profile_enabled)
	var profile_state = null
	if smoke_expansion_13_scanner_cutter_correction:
		profile_state = SmokeExpansion13ScannerCutterCorrectionChecks.create_clean_profile()
	elif smoke_expansion_11_light_return or smoke_expansion_12_pressure_return or smoke_expansion_13_southeast_wreck_return or smoke_expansion_14_archive_current_return:
		profile_state = SmokeExpansion11LightReturnChecks.create_clean_profile()
	_anomaly_survey = AnomalySurveyRuntime.new(_progression_runtime, profile_persistence_enabled, profile_state)
	if not _review_checkpoint_id.is_empty():
		_review_checkpoint_report = ReviewCheckpointFixture.apply(_review_checkpoint_id, _anomaly_survey.profile_state())
	_pressure_zone = PressureZoneController.new()
	_progression_runtime.set_profile_state(_anomaly_survey.profile_state())
	_material_runtime = MaterialRuntimeController.new(_anomaly_survey.profile_state())
	_material_project = MaterialProjectRuntime.new(_anomaly_survey.profile_state())
	_refresh_active_tools()
	_cutter_salvage = CutterSalvageController.new(_anomaly_survey.profile_state())
	_biological_resources = BiologicalResourceController.new(_anomaly_survey.profile_state())
	_cargo_collection = CargoCollectionController.new(self)
	_map_selector_enabled = (not automated_review) and _review_map_selector_allowed(user_args, engine_args)
	if _fresh_review_profile_enabled:
		print(ReviewProfileMode.startup_report(_has_propulsion_upgrade(), _review_checkpoint_id, bool(_review_checkpoint_report.get("ready", false))))

	if check_map_parity:
		var world := _create_world(selected_map_path, _debug_overlay_enabled)
		_write_parity_report_and_quit(world, parity_output_path)
		return

	var map_load_started_usec := Time.get_ticks_usec()
	_load_playable_map(selected_map_path, _debug_overlay_enabled)
	var map_startup_ms := float(Time.get_ticks_usec() - map_load_started_usec) / 1000.0
	if OS.has_feature("web"):
		print("Web map active: map=%s review=%s." % [_world.map_id, str(_fresh_review_profile_enabled).to_lower()])
	if measure_map_runtime:
		await MapRuntimeProbe.measure_and_quit(get_tree(), _world, _player, map_startup_ms)
		return

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
		_smoke_darkness_light_checks._smoke_pass_20_durable_light_and_quit()
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
		await _smoke_current_gate_checks._smoke_current_gate_and_quit()
		return
	if smoke_active_tool_selection:
		_smoke_active_tool_checks.smoke_and_quit()
		return
	if smoke_checkpoint_shock_prod:
		_smoke_active_tool_checks.smoke_checkpoint_shock_prod_and_quit()
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
	if smoke_release_journey:
		_smoke_release_journey_checks._smoke_release_journey_and_quit()
		return
	if smoke_anomaly_survey_journey:
		SmokeAnomalySurveyJourneyChecks.new(self)._smoke_anomaly_survey_journey_and_quit()
		return
	if smoke_expedition_day:
		_smoke_expedition_day_checks._smoke_expedition_day_and_quit()
		return
	if smoke_expansion_03_material_project:
		SmokeExpansion03JourneyChecks.new(self)._smoke_expansion_03_material_project_and_quit()
		return
	if smoke_expansion_04_current_pocket:
		SmokeExpansion04JourneyChecks.new(self)._smoke_expansion_04_current_pocket_and_quit()
	if smoke_expansion_05_practical_research:
		SmokeExpansion05JourneyChecks.new(self)._smoke_expansion_05_practical_research_and_quit()
		return
	if smoke_expansion_06_combat_foundation:
		SmokeExpansion06CombatJourneyChecks.new(self)._smoke_expansion_06_combat_foundation_and_quit()
		return
	if smoke_expansion_07_biological_progression:
		SmokeExpansion07BiologicalJourneyChecks.new(self)._smoke_expansion_07_biological_progression_and_quit()
		return
	if smoke_expansion_08_daily_condition_journey:
		SmokeExpansion08DailyConditionJourneyChecks.new(self)._smoke_expansion_08_daily_condition_journey_and_quit()
		return
	if smoke_expansion_09_full_level_journey:
		await SmokeExpansion09FullLevelJourneyChecks.new(self)._smoke_expansion_09_full_level_journey_and_quit()
		return
	if smoke_expansion_10_regional_journey:
		await SmokeExpansion10RegionalJourneyChecks.new(self)._smoke_expansion_10_regional_journey_and_quit()
		return
	if smoke_expansion_11_light_return:
		await SmokeExpansion11LightReturnChecks.new(self)._smoke_expansion_11_light_return_and_quit()
		return
	if smoke_expansion_12_pressure_return:
		await SmokeExpansion12PressureReturnChecks.new(self)._smoke_expansion_12_pressure_return_and_quit()
		return
	if smoke_expansion_13_southeast_wreck_return:
		await SmokeExpansion13SoutheastWreckReturnChecks.new(self)._smoke_expansion_13_southeast_wreck_return_and_quit()
		return
	if smoke_expansion_13_scanner_cutter_correction:
		await SmokeExpansion13ScannerCutterCorrectionChecks.new(self)._smoke_expansion_13_scanner_cutter_correction_and_quit()
		return
	if smoke_expansion_14_archive_current_return:
		await SmokeExpansion14ArchiveCurrentReturnChecks.new(self)._smoke_expansion_14_archive_current_return_and_quit()
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
	if smoke_pass_27_facing_transitions:
		_smoke_player_facing_transition_checks._smoke_pass_27_facing_transitions_and_quit()
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
	elif capture_pass_27_player_facing:
		var capture := Pass27PlayerFacingCapture.new(self)
		await capture.capture_and_quit(PASS_27_PLAYER_FACING_CAPTURE_DIR)
	elif capture_anomaly_survey:
		var capture := AnomalySurveyCapture.new(self)
		await capture.capture_and_quit(ANOMALY_SURVEY_CAPTURE_DIR)
	elif capture_expedition_day:
		var capture := ExpeditionDayCapture.new(self)
		await capture.capture_and_quit(EXPEDITION_DAY_CAPTURE_DIR)
	elif capture_expansion_03_material_project:
		var capture := Expansion03MaterialProjectCapture.new(self)
		await capture.capture_and_quit(EXPANSION_03_MATERIAL_PROJECT_CAPTURE_DIR)
	elif capture_expansion_04_current_pocket:
		var capture := Expansion04CurrentPocketCapture.new(self)
		await capture.capture_and_quit(EXPANSION_04_CURRENT_POCKET_CAPTURE_DIR)
	elif capture_expansion_05_practical_research:
		var capture := Expansion05PracticalResearchCapture.new(self)
		await capture.capture_and_quit(EXPANSION_05_PRACTICAL_RESEARCH_CAPTURE_DIR)
	elif capture_expansion_06_combat_foundation:
		var capture := Expansion06CombatFoundationCapture.new(self)
		await capture.capture_and_quit(EXPANSION_06_COMBAT_FOUNDATION_CAPTURE_DIR)
	elif capture_expansion_07_biological_progression:
		var capture := Expansion07BiologicalProgressionCapture.new(self)
		await capture.capture_and_quit(EXPANSION_07_BIOLOGICAL_PROGRESSION_CAPTURE_DIR)
	elif capture_expansion_08_daily_condition:
		var capture := Expansion08DailyConditionCapture.new(self)
		await capture.capture_and_quit(EXPANSION_08_DAILY_CONDITION_CAPTURE_DIR)
	elif capture_expansion_09_full_level:
		var capture := Expansion09FullLevelCapture.new(self)
		await capture.capture_and_quit(EXPANSION_09_FULL_LEVEL_CAPTURE_DIR)
	elif capture_expansion_10_regional_journey:
		var capture := Expansion10RegionalJourneyCapture.new(self)
		await capture.capture_and_quit(EXPANSION_10_REGIONAL_JOURNEY_CAPTURE_DIR)
	elif capture_expansion_11_light_return:
		var capture := Expansion11LightReturnCapture.new(self)
		await capture.capture_and_quit(EXPANSION_11_LIGHT_RETURN_CAPTURE_DIR)
	elif capture_expansion_12_pressure_return:
		var capture := Expansion12PressureReturnCapture.new(self)
		await capture.capture_and_quit(EXPANSION_12_PRESSURE_RETURN_CAPTURE_DIR)
	elif capture_expansion_13_southeast_wreck:
		var capture := Expansion13SoutheastWreckCapture.new(self)
		await capture.capture_and_quit(EXPANSION_13_SOUTHEAST_WRECK_CAPTURE_DIR)
	elif capture_expansion_13_scanner_cutter_correction:
		var capture := Expansion13ScannerCutterCorrectionCapture.new(self)
		await capture.capture_and_quit(EXPANSION_13_SCANNER_CUTTER_CORRECTION_CAPTURE_DIR)
	elif capture_expansion_14_archive_current_return:
		var capture := Expansion14ArchiveCurrentReturnCapture.new(self)
		await capture.capture_and_quit(EXPANSION_14_ARCHIVE_CURRENT_RETURN_CAPTURE_DIR)
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

func _load_playable_map(map_path: String, show_debug_overlay: bool, entry_id := "", status_note := "", preserve_sortie := false) -> void:
	if not preserve_sortie and _world != null and _material_runtime != null:
		_biological_resources.restore_material_cargo(_material_runtime, _world, _expedition_day_state, _hostiles, "map_reload")
	_clear_loaded_review_nodes()
	var world := _create_world(map_path, show_debug_overlay)
	var player := PLAYER_SCENE.instantiate()
	_player = player
	_anomaly_survey.on_map_loaded(world)
	_pressure_zone.on_map_loaded(world)
	_expedition_day_state.on_map_loaded(str(world.map_id))
	_daily_conditions.sync(world.get_daily_conditions(), _expedition_day_state.day_number)
	_material_runtime.on_map_loaded(world, _expedition_day_state, _daily_conditions.current_ids())
	_material_project.on_map_loaded(world)
	_refresh_active_tools()
	_cutter_salvage.on_map_loaded(world)
	_hostiles.on_map_loaded(world, preserve_sortie)
	_biological_resources.on_map_loaded(world, preserve_sortie)
	_shock_prod.reset()
	_sortie_state.begin_map_leg(str(world.map_id), entry_id, _oxygen_capacity_seconds(), preserve_sortie)
	_player_health.begin_map_leg(preserve_sortie)
	player.position = world.get_entry_position(entry_id) if not entry_id.is_empty() and world.has_method("get_entry_position") else world.spawn_position
	add_child(player)
	_apply_durable_light_profile()

	if player.has_method("set_camera_limits"):
		player.set_camera_limits(Rect2(Vector2.ZERO, world.map_pixel_size))
	if player.has_method("snap_camera"):
		player.snap_camera()

	_banked_salvage = 0
	_total_salvage = world.get_total_salvage_count()
	if _cutter_salvage.has_cutter():
		_total_salvage += _cutter_salvage.available_target_count(world)
	_banked_salvage_ids = []
	_banked_score = 0
	_completion_oxygen_bonus = 0
	_current_gate.reset()
	_moving_hazards.reset(world, _daily_conditions.current_ids(), preserve_sortie)
	_pry_salvage.reset()
	_timed_salvage.reset()
	_progression_containers.apply_opened_to_world(world, Callable(_anomaly_survey.profile_state(), "has_completed_discovery"))
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
	_reset_oxygen_feedback_cues()
	_run_complete = false
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
	_active_tool_hud = null
	_held_cargo_hud = null
	_status_label = null
	_result_panel = null
	_result_label = null
	_map_selector = null
	_progression_project_tracker = null

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
	if _audio_cues != null:
		_audio_cues.unlock_from_event(event)

func _process(delta: float) -> void:
	if _world == null or _player == null:
		return
	_player.sync_scanner_presentation(_anomaly_survey.report())
	_player_health.update(delta)
	_shock_prod.update(delta)
	_update_combat_feedback(delta)
	if not _sortie_state.failed and _at_canonical_boat():
		_player_health.refill_at_boat()
	_update_hazard_feedback(delta)
	if _sortie_state.update_offload_presence(_world.is_inside_extraction(_player.global_position), _oxygen_capacity_seconds()):
		_expedition_day_state.record_sortie_started()
		_run_complete = false
		_completion_oxygen_bonus = 0
	if _sortie_state.failed:
		_update_status_label()
		return
	if ExpeditionDayDebrief.update(self, delta):
		return
	if _run_complete:
		_update_status_label()
		return

	if _update_oxygen(delta):
		_update_status_label()
		return
	_update_current_gate(delta)
	_update_moving_hazards(delta)
	if _update_hostile_encounter(delta):
		_update_status_label()
		return
	_update_progression_containers()

	if _hazard_cooldown_seconds > 0.0:
		_hazard_cooldown_seconds = maxf(0.0, _hazard_cooldown_seconds - delta)
	elif _hazard_interactions_enabled:
		var hazard_id: String = _world.get_hazard_near(_player.global_position, HAZARD_CONTACT_RADIUS)
		if not hazard_id.is_empty():
			_handle_hazard_hit(hazard_id)
			_update_status_label()
			return
	var survey_result: Dictionary = _anomaly_survey.update(_world, _player, delta)
	_player.sync_scanner_presentation(_anomaly_survey.report())
	if survey_result.has("note"):
		_last_status_note = str(survey_result["note"])
	if bool(survey_result.get("committed", false)):
		_expedition_day_state.record_discovery(str(survey_result.get("discovery_id", "")))
	_update_hazard_warning(delta)

	_cargo_collection.update(delta)

	_update_status_label()

func _complete_route_outcome_review_state() -> bool:
	for salvage in _salvage_centers_for_full_collection():
		_player.global_position = salvage["center"]
		_collect_salvage_for_review_state(salvage)
		if _sortie_state.held_salvage >= _held_salvage_capacity():
			_player.global_position = _world.get_extraction_center()
			_process(0.0)

	if _sortie_state.held_salvage > 0:
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
	_sortie_state.collect_salvage(salvage_id, collected_score)
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
	if _expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF:
		if event is InputEventKey and event.pressed and not event.echo:
			var key_event := event as InputEventKey
			ExpeditionDayDebrief.handle_debrief_key(self, key_event.keycode)
		return
	if _sortie_state.failed:
		if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_R:
			_reset_run()
		return
	var repeated_tool_key := event is InputEventKey and (event as InputEventKey).echo
	if event.is_action_pressed("active_tool_cycle_next") and not repeated_tool_key:
		_cycle_active_tool()
		return
	if event.is_action_pressed("active_tool_use") and not repeated_tool_key:
		_use_active_tool()
		return
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
		_reset_run()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_U:
		_try_purchase_oxygen_tank_upgrade()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_C:
		_try_purchase_cargo_capacity_upgrade()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_P:
		_show_project_guidance()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_E:
		if not _try_progression_container_interaction():
			_try_world_connector_transition()
	elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_N:
		ExpeditionDayDebrief.handle_day_key(self)


func _reset_run() -> void:
	if _world == null or _player == null:
		return
	_refresh_active_tools()

	_world.reset_salvage()
	_anomaly_survey.clear_unbanked("reset", _world)
	_pressure_zone.reset()
	_biological_resources.restore_material_cargo(_material_runtime, _world, _expedition_day_state, _hostiles, "reset")
	_oxygen_rest_feedback.reset()
	_current_gate.reset()
	_pry_salvage.reset()
	_timed_salvage.reset()
	_cutter_salvage.reset()
	_hostiles.reset_for_failure(_world)
	_shock_prod.reset()
	_combat_feedback_seconds = 0.0
	_cutter_salvage.apply_banked_to_world(_world)
	_player_health.reset()
	_relay_follow_through_feedback.reset(_world)
	_final_dive_objective_seed.reset(_world)
	_sortie_state.begin_map_leg(str(_world.map_id), "", _oxygen_capacity_seconds())
	_banked_salvage_ids = []
	_banked_salvage = 0
	_total_salvage = _world.get_total_salvage_count() + (_cutter_salvage.available_target_count(_world) if _cutter_salvage.has_cutter() else 0)
	_banked_score = 0
	_completion_oxygen_bonus = 0
	_banked_validation_route_counts = {}
	_hazard_cooldown_seconds = 0.0
	_hazard_feedback_seconds = 0.0
	_hazard_interactions_enabled = true
	_hazard_warning_id = ""
	_reset_hazard_feedback_cues()
	_reset_oxygen_feedback_cues()
	_run_complete = false
	_last_status_note = "Reset"
	_player.modulate = Color.WHITE
	_player.position = _world.spawn_position
	_player.set_physics_process(true)
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	if _player.has_method("snap_camera"):
		_player.snap_camera()
	_update_status_label()


func _try_world_connector_transition() -> bool:
	if _world_connector == null or _world == null or _player == null or _run_complete or _sortie_state.failed:
		return false

	var connector: Dictionary = _world_connector.connector_at(_world, _player.global_position)
	if connector.is_empty():
		return false
	var blocking_gate: Dictionary = _current_gate.gate_blocks_position(_world, _player.global_position, Callable(self, "_has_upgrade_id"), Callable(_anomaly_survey.profile_state(), "has_capability"))
	if not blocking_gate.is_empty():
		_last_status_note = _current_gate_block_prompt(blocking_gate)
		_update_status_label()
		return false

	var destination_map_path := str(connector.get("destination_map_path", "")).strip_edges()
	if destination_map_path.is_empty():
		_last_status_note = "Connector unavailable"
		_update_status_label()
		return false

	var destination_map_id := str(connector.get("destination_map_id", "")).strip_edges()
	var destination_entry_id := str(connector.get("destination_entry_id", "")).strip_edges()
	var arrival_note: String = _world_connector.arrival_note(connector)
	_anomaly_survey.on_map_transition(destination_map_id)
	_expedition_day_state.on_map_transition(destination_map_id)
	_load_playable_map(destination_map_path, _debug_overlay_enabled, destination_entry_id, arrival_note, true)
	return true


func _update_oxygen(delta: float) -> bool:
	var previous_oxygen: float = _sortie_state.oxygen_seconds
	_pressure_zone.update(_player.global_position, Callable(_anomaly_survey.profile_state(), "has_capability"), delta)
	if _world.is_at_open_surface(_player.global_position) or _world.is_inside_extraction(_player.global_position):
		_oxygen_rest_feedback.reset()
		_sortie_state.oxygen_seconds = minf(_oxygen_capacity_seconds(), _sortie_state.oxygen_seconds + OXYGEN_REFILL_SECONDS_PER_SECOND * delta)
		_update_oxygen_feedback_cues(previous_oxygen)
		return false

	var rest_result: Dictionary = _oxygen_rest_feedback.update(_world, _player.global_position, _sortie_state.oxygen_seconds, delta)
	if bool(rest_result.get("inside", false)):
		_sortie_state.oxygen_seconds = float(rest_result.get("oxygen_seconds", _sortie_state.oxygen_seconds))
		if _sortie_state.oxygen_seconds > 0.0:
			_update_oxygen_feedback_cues(previous_oxygen)
			return false
		_handle_oxygen_depleted()
		return true

	if not _sortie_state.drain_oxygen(delta, _pressure_zone.drain_multiplier()):
		_update_oxygen_feedback_cues(previous_oxygen)
		return false

	_handle_oxygen_depleted()
	return true


func _update_oxygen_feedback_cues(previous_oxygen: float) -> void:
	if _run_complete or _sortie_state.failed:
		return
	if _sortie_state.oxygen_seconds > OXYGEN_LOW_WARNING_SECONDS:
		_reset_oxygen_feedback_cues()
		return
	if _sortie_state.oxygen_seconds > OXYGEN_CRITICAL_WARNING_SECONDS:
		_oxygen_critical_cue_emitted = false
	if not _oxygen_low_cue_emitted and previous_oxygen > OXYGEN_LOW_WARNING_SECONDS and _sortie_state.oxygen_seconds <= OXYGEN_LOW_WARNING_SECONDS:
		_oxygen_low_cue_emitted = true
		_play_feedback_cue("oxygen_low", "oxygen_low")
	if not _oxygen_critical_cue_emitted and previous_oxygen > OXYGEN_CRITICAL_WARNING_SECONDS and _sortie_state.oxygen_seconds <= OXYGEN_CRITICAL_WARNING_SECONDS:
		_oxygen_critical_cue_emitted = true
		_play_feedback_cue("oxygen_critical", "oxygen_critical")


func _reset_oxygen_feedback_cues() -> void:
	_oxygen_low_cue_emitted = false
	_oxygen_critical_cue_emitted = false


func _update_current_gate(delta: float) -> void:
	if _current_gate == null:
		return
	_current_gate.update(_world, _player, Callable(self, "_has_upgrade_id"), Callable(_anomaly_survey.profile_state(), "has_capability"), delta)


func _update_moving_hazards(delta: float) -> void:
	if _moving_hazards == null or _world == null or _player == null:
		return
	_moving_hazards.update(_world, _player.global_position, HAZARD_WARNING_RADIUS, delta)


func _update_hostile_encounter(delta: float) -> bool:
	if not _combat_interactions_enabled or _hostiles == null or _world == null or _player == null:
		return false
	var event: Dictionary = _hostiles.update(_world, _player.global_position, delta)
	if str(event.get("kind", "")) != "contact":
		return false
	var damage: Dictionary = _apply_combat_damage(int(event.get("damage", 1)), str(event.get("id", "hostile")))
	if bool(damage.get("changed", false)):
		_timed_salvage.reset()
		if not bool(damage.get("defeated", false)) and _player.has_method("apply_knockback"):
			_player.apply_knockback(
				_player.global_position - (event.get("position", _player.global_position) as Vector2),
				float(event.get("knockback_force", 0.0)),
				float(event.get("disruption_seconds", 0.0))
			)
			_last_status_note += " | knocked back"
		_combat_feedback_seconds = COMBAT_FEEDBACK_SECONDS
		return true
	return false


func _try_combat_attack() -> bool:
	var result: Dictionary = _active_tool_runtime.use_shock_prod()
	_update_status_label()
	return bool(result.get("changed", false))


func _update_combat_feedback(delta: float) -> void:
	if _combat_feedback_seconds <= 0.0:
		return
	_combat_feedback_seconds = maxf(0.0, _combat_feedback_seconds - maxf(0.0, delta))
	if _combat_feedback_seconds == 0.0 and _is_combat_status_note(_last_status_note):
		_last_status_note = ""


func _current_gate_block_prompt(gate: Dictionary) -> String:
	return _current_gate.block_prompt(gate) if _current_gate != null else ""


func _handle_oxygen_depleted() -> void:
	if _sortie_state.failed:
		return
	_anomaly_survey.clear_unbanked("oxygen_failure", _world)
	_pressure_zone.reset()
	_play_feedback_cue("oxygen_failure", "oxygen_failure")
	_oxygen_rest_feedback.reset()
	_current_gate.reset()
	_moving_hazards.reset(_world)
	_pry_salvage.reset()
	_timed_salvage.reset()
	_cutter_salvage.reset()
	_hostiles.reset_for_failure(_world)
	_shock_prod.reset()
	_combat_feedback_seconds = 0.0
	_biological_resources.restore_material_cargo(_material_runtime, _world, _expedition_day_state, _hostiles, "oxygen_failure")
	if not _sortie_state.held_salvage_ids.is_empty():
		_world.restore_salvage(_sortie_state.clear_held())
	_last_status_note = "Oxygen depleted - press R"

	_sortie_state.oxygen_seconds = _oxygen_capacity_seconds()
	_reset_oxygen_feedback_cues()
	_sortie_state.mark_failed("oxygen_failure")
	_expedition_day_state.record_failure("oxygen_depleted")
	_hazard_cooldown_seconds = HAZARD_COOLDOWN_SECONDS
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	if _player.has_method("snap_camera"):
		_player.snap_camera()


func _apply_combat_damage(amount: int, source_id: String) -> Dictionary:
	if _sortie_state.failed or _run_complete:
		return {"changed": false, "reason": "inactive", "defeated": false}
	var result: Dictionary = _player_health.apply_damage(amount, source_id)
	if not bool(result.get("changed", false)):
		return result
	if bool(result.get("defeated", false)):
		_handle_combat_defeat(source_id)
	else:
		_last_status_note = "Eel hit: health %d/%d (-%d)" % [int(result.get("current_health", 0)), int(result.get("max_health", 0)), amount]
	_update_status_label()
	return result


func _handle_combat_defeat(_source_id: String) -> void:
	_anomaly_survey.clear_unbanked("combat_defeat", _world)
	_pressure_zone.reset()
	_oxygen_rest_feedback.reset()
	_current_gate.reset()
	_moving_hazards.reset(_world)
	_pry_salvage.reset()
	_timed_salvage.reset()
	_cutter_salvage.reset()
	_shock_prod.reset()
	_combat_feedback_seconds = 0.0
	_biological_resources.restore_material_cargo(_material_runtime, _world, _expedition_day_state, _hostiles, "combat_defeat")
	if not _sortie_state.held_salvage_ids.is_empty():
		_world.restore_salvage(_sortie_state.clear_held())
	_last_status_note = "Injured - surfaced, press R"
	_sortie_state.mark_failed("combat_defeat")
	_expedition_day_state.record_failure("combat_defeat")
	_player.global_position = _world.spawn_position
	_player.set_physics_process(false)
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
	_cutter_salvage.reset()
	_hostiles.reset_for_failure(_world)
	_shock_prod.reset()
	_combat_feedback_seconds = 0.0
	_anomaly_survey.clear_unbanked("hazard", _world)
	_pressure_zone.reset()
	var material_drop: Dictionary = _biological_resources.restore_material_cargo(_material_runtime, _world, _expedition_day_state, _hostiles, "hazard")
	var oxygen_depleted := _apply_hazard_oxygen_penalty()
	if oxygen_depleted:
		_handle_oxygen_depleted()
		return

	if not _sortie_state.held_salvage_ids.is_empty():
		_world.restore_salvage(_sortie_state.clear_held())
		_last_status_note = "Hazard hit: dropped held, oxygen -%ds" % int(HAZARD_OXYGEN_PENALTY_SECONDS)
	elif int(material_drop.get("restored_count", 0)) > 0:
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
	return _sortie_state.apply_oxygen_penalty(HAZARD_OXYGEN_PENALTY_SECONDS)


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
	panel.custom_minimum_size = Vector2(300, 0)

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
	_review_label.text = _review_header_text(world)
	stack.add_child(_review_label)

	if _map_selector_enabled:
		_map_selector = OptionButton.new()
		_map_selector.name = "ReviewMapSelector"
		for option in MapCatalog.review_options():
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

	_held_cargo_hud = HeldCargoHud.new()
	canvas.add_child(_held_cargo_hud)

	_active_tool_hud = ActiveToolHud.new()
	canvas.add_child(_active_tool_hud)
	var mobile_controls = get_node_or_null("MobileTestControls")
	if mobile_controls != null:
		_active_tool_hud.set_mobile_controls_visible(bool(mobile_controls.get_test_report().get("enabled", false)))

	_progression_project_tracker = ProgressionProjectTracker.new()
	canvas.add_child(_progression_project_tracker)

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
	if _review_label != null:
		_review_label.text = _review_header_text(_world)
	_update_held_cargo_hud()
	_update_active_tool_hud()
	_update_progression_project_tracker()

	if _total_salvage <= 0:
		_status_label.text = ExpeditionDayPresentation.decorate_status(self, "Score 0\nSalvage banked 0/0\nHeld 0/%d\n%s\nOxygen --" % [_held_salvage_capacity(), _combat_overlay_text()])
		_update_result_panel()
		return

	var prompt := ""
	var objective_step_cue_blocked := false
	var oxygen_feedback := _oxygen_feedback_label()
	var oxygen_rest_prompt := _oxygen_rest_prompt()
	var pressure_prompt: String = _pressure_zone.overlay_text()
	var current_gate_prompt := _current_gate_prompt()
	var progression_container_prompt := _progression_container_prompt()
	var pre_pickup_route_cue := _pre_pickup_route_cue_prompt()
	var world_connector_prompt := _world_connector_prompt()
	if _run_complete:
		prompt = "Run complete - press R"
		objective_step_cue_blocked = true
	elif _sortie_state.failed:
		prompt = _failure_retry_prompt()
		objective_step_cue_blocked = true
	elif _is_combat_status_note(_last_status_note):
		prompt = _last_status_note
		objective_step_cue_blocked = true
	elif not _hazard_warning_id.is_empty():
		prompt = _hazard_warning_prompt()
		objective_step_cue_blocked = true
	elif not pressure_prompt.is_empty():
		prompt = pressure_prompt
		objective_step_cue_blocked = true
	elif not oxygen_rest_prompt.is_empty():
		prompt = oxygen_rest_prompt
		objective_step_cue_blocked = true
	elif not current_gate_prompt.is_empty():
		prompt = current_gate_prompt
		objective_step_cue_blocked = true
	elif not progression_container_prompt.is_empty():
		prompt = progression_container_prompt
		objective_step_cue_blocked = true
	elif not world_connector_prompt.is_empty():
		var keep_connector_note := (
			_last_status_note.begins_with("Arrived:")
			or _is_relay_follow_through_status_note(_last_status_note)
			or _is_final_dive_status_note(_last_status_note)
		)
		prompt = "%s\n%s" % [_last_status_note, world_connector_prompt] if keep_connector_note else world_connector_prompt
		objective_step_cue_blocked = true
	elif _held_cargo_count() >= _held_salvage_capacity():
		prompt = _cargo_full_prompt()
		objective_step_cue_blocked = true
	elif _is_relay_follow_through_status_note(_last_status_note) or _is_final_dive_status_note(_last_status_note):
		prompt = _last_status_note
		objective_step_cue_blocked = true
	elif _is_progression_status_note(_last_status_note) or _anomaly_survey.is_status_note(_last_status_note):
		prompt = _last_status_note
		objective_step_cue_blocked = true
	elif not pre_pickup_route_cue.is_empty():
		prompt = pre_pickup_route_cue
		objective_step_cue_blocked = true
	elif _last_status_note.begins_with("Arrived:"):
		prompt = _last_status_note
	elif not _last_status_note.is_empty():
		prompt = _last_status_note
		objective_step_cue_blocked = _is_collection_status_note(_last_status_note)
	elif _held_cargo_count() > 0:
		prompt = "Return to extraction"
	var hostile_prompt: String = str(_hostiles.prompt()) if _hostiles != null else ""
	var combat_tool_prompt: String = _active_tool_runtime.combat_prompt() if _active_tool_runtime != null else ""
	if not combat_tool_prompt.is_empty():
		hostile_prompt = "%s\n%s" % [hostile_prompt, combat_tool_prompt] if not hostile_prompt.is_empty() else combat_tool_prompt
	if not hostile_prompt.is_empty() and not _run_complete and not _sortie_state.failed and not _last_status_note.begins_with("Eel hit"):
		if prompt.is_empty():
			prompt = hostile_prompt
		elif prompt.find(hostile_prompt) == -1:
			prompt = "%s\n%s" % [hostile_prompt, prompt]
		objective_step_cue_blocked = true
	if not oxygen_feedback.is_empty():
		objective_step_cue_blocked = true
	var objective_text := _route_commitment_overlay_text(not objective_step_cue_blocked)

	var oxygen_seconds := int(ceil(_sortie_state.oxygen_seconds))
	var oxygen_text := "Oxygen %ds" % oxygen_seconds
	if not oxygen_feedback.is_empty():
		oxygen_text = "Oxygen %ds %s" % [oxygen_seconds, oxygen_feedback]
	var progression_text := _progression_overlay_text()
	var anomaly_text: String = _anomaly_survey.overlay_text(_world, _player)
	var material_text: String = _material_runtime.overlay_text()

	_status_label.text = "Score %d\nSalvage banked %d/%d\nHeld %d/%d (%d pts)\n%s\n%s\n%s" % [
		_banked_score,
		_banked_salvage,
		_total_salvage,
		_held_cargo_count(),
		_held_salvage_capacity(),
		_sortie_state.held_salvage_score,
		_combat_overlay_text(),
		oxygen_text,
		progression_text,
	]
	if not objective_text.is_empty():
		_status_label.text += "\n%s" % objective_text
	if not anomaly_text.is_empty():
		_status_label.text += "\n%s" % anomaly_text
	if not material_text.is_empty():
		_status_label.text += "\n%s" % material_text
	if not prompt.is_empty() and prompt != anomaly_text:
		_status_label.text += "\n%s" % prompt
	_status_label.text = ExpeditionDayPresentation.decorate_status(self, _status_label.text)
	_update_result_panel()


func _review_header_text(world) -> String:
	var text := "Map %s\nBuild %s" % [world.get_map_label(), _build_label()]
	if _fresh_review_profile_enabled:
		text += "\n%s" % ReviewProfileMode.overlay_line(_has_propulsion_upgrade(), _review_checkpoint_id, bool(_review_checkpoint_report.get("ready", false)))
	return text


func _failure_retry_prompt() -> String:
	return "Injured - surfaced, press R" if _sortie_state.failure_reason == "combat_defeat" else "Oxygen depleted - press R"


func _combat_overlay_text() -> String:
	if _shock_prod != null and _material_project != null and _material_project.has_shock_prod():
		var selected: bool = _active_tools != null and _active_tools.selected_tool_id() == ActiveToolController.SHOCK_PROD_TOOL_ID
		return "%s | %s" % [_player_health.overlay_text(), _shock_prod.overlay_text(true, _material_project.has_shock_prod_capacitor(), selected)]
	return _player_health.overlay_text()


func _at_canonical_boat() -> bool:
	return _world != null and _player != null and _world.is_inside_boat(_player.global_position)


func _cargo_full_prompt() -> String:
	if _world != null and _player != null:
		var tool_target: Dictionary = _world.get_tool_target_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
		if not tool_target.is_empty():
			return "Cargo full - bank salvage at boat" if _cutter_salvage.has_cutter() else "Sealed wreck | Cutter required"
	if _world != null and _player != null and not _world.get_material_candidate_near(_player.global_position, SALVAGE_COLLECTION_RADIUS).is_empty():
		return "Cargo full - bank materials at boat"
	if _return_pressure_feedback == null or _world == null or _player == null:
		return ReturnPressureFeedback.DEFAULT_CARGO_FULL_PROMPT
	var nearby_salvage: Dictionary = _world.get_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS)
	return _return_pressure_feedback.cargo_full_prompt(nearby_salvage)


func _pre_pickup_route_cue_prompt() -> String:
	if _destination_payoff_feedback != null and _world != null and _player != null:
		var payoff_prompt: String = _destination_payoff_feedback.return_prompt(_world, _player.global_position, Callable(_anomaly_survey.profile_state(), "has_capability"), _sortie_state.held_salvage_ids, _banked_salvage_ids)
		if not payoff_prompt.is_empty():
			return payoff_prompt
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


func _progression_container_prompt() -> String:
	if _progression_containers == null or _world == null or _player == null:
		return ""
	return _progression_containers.prompt_at(_world, _player.global_position)


func _world_connector_prompt() -> String:
	if _world_connector == null or _world == null or _player == null or _run_complete or _sortie_state.failed:
		return ""
	return _world_connector.prompt_for(_world, _player.global_position)


func _route_commitment_overlay_text(show_step_cue := true) -> String:
	if _route_commitment_feedback == null:
		return ""
	var show_start_cue := false
	if _world != null and _player != null and not _run_complete and not _sortie_state.failed:
		show_start_cue = _world.is_inside_extraction(_player.global_position)
	var progress_text: String = _route_commitment_feedback.overlay_text(_sortie_state.held_salvage_ids, _banked_salvage_ids, show_start_cue)
	if not progress_text.is_empty():
		return progress_text
	if _world == null or _player == null or _run_complete or _sortie_state.failed:
		return ""
	return _route_commitment_feedback.objective_step_cue_text(
		_world,
		_player.global_position,
		_sortie_state.held_salvage_ids,
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
		_sortie_state.failed,
		_primary_dive_objective,
		_banked_salvage_ids
	)


func _relay_follow_through_result_text() -> String:
	if _relay_follow_through_feedback == null or not _run_complete or _sortie_state.failed:
		return ""
	return _relay_follow_through_feedback.result_text(_banked_salvage_ids)


func _final_dive_objective_result_text() -> String:
	if _final_dive_objective_seed == null or not _run_complete or _sortie_state.failed:
		return ""
	return _final_dive_objective_seed.result_text(_banked_salvage_ids)


func _hazard_warning_prompt() -> String:
	if _moving_hazards != null and _hazard_warning_id == _moving_hazards.warning_id():
		return _moving_hazards.warning_prompt()
	if _hazard_warning_id == PASS_07_PRESSURE_HAZARD_ID:
		return PRESSURE_HAZARD_WARNING_PROMPT
	return GENERIC_HAZARD_WARNING_PROMPT


func _oxygen_feedback_label() -> String:
	if _run_complete or _sortie_state.failed:
		return ""
	if _sortie_state.oxygen_seconds <= OXYGEN_CRITICAL_WARNING_SECONDS:
		return "CRITICAL"
	if _sortie_state.oxygen_seconds <= OXYGEN_LOW_WARNING_SECONDS:
		return "LOW"
	return ""


func _is_collection_status_note(status_note: String) -> bool:
	return (
		status_note.begins_with("Collected ")
		or status_note.begins_with("Salvaging ")
		or status_note.begins_with("Prying ")
		or status_note.begins_with("Cutting ")
		or status_note.begins_with("Sampling ")
		or status_note.begins_with("Harvesting ")
		or status_note.begins_with("Insulating gel ")
		or status_note.begins_with("Electrocyte ")
		or status_note.begins_with("Pry interrupted")
		or status_note.begins_with("Cutter interrupted")
		or status_note.find("Cutter required") != -1
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
		(_progression_runtime != null and _progression_runtime.is_status_note(status_note))
		or status_note.begins_with("Blueprint recovered")
		or status_note.begins_with("Fins project")
		or status_note.begins_with("Fins ready")
	)


func _is_combat_status_note(status_note: String) -> bool:
	return (
		status_note.begins_with("Eel hit")
		or status_note.begins_with("Shock prod")
		or status_note.begins_with("Territory clear")
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
	return int(ceil(_sortie_state.oxygen_seconds)) * OXYGEN_BONUS_POINTS_PER_SECOND


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
		_destination_payoff_feedback.reset([], [])
		return
	_destination_payoff_feedback.reset(world.get_salvage_centers(), world.get_current_gates())


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
	return _progression_runtime.record_banked_salvage(banked_score) if _progression_runtime != null else 0


func _session_wallet() -> int:
	return _progression_runtime.wallet() if _progression_runtime != null else 0


func _session_payout_total() -> int:
	return _progression_runtime.total_payout_earned() if _progression_runtime != null else 0


func _grant_wallet_reward(amount: int) -> int:
	return _progression_runtime.grant_wallet_reward(amount) if _progression_runtime != null else 0


func _update_progression_containers() -> void:
	if _progression_containers == null or _world == null or _player == null:
		return
	var result: Dictionary = _progression_containers.try_open(
		_world,
		_player.global_position,
		Callable(self, "_grant_wallet_reward"),
		Callable(_anomaly_survey.profile_state(), "complete_discovery")
	)
	if str(result.get("state", "")) == "opened" and result.has("note"):
		_last_status_note = str(result["note"])


func _try_progression_container_interaction() -> bool:
	if _progression_containers == null or _world == null or _player == null:
		return false
	var result: Dictionary = _progression_containers.try_open(
		_world,
		_player.global_position,
		Callable(self, "_grant_wallet_reward"),
		Callable(_anomaly_survey.profile_state(), "complete_discovery"),
		true
	)
	if str(result.get("state", "")) != "opened":
		return false
	_last_status_note = str(result.get("note", "Container opened"))
	_update_status_label()
	return true


func _refresh_active_tools() -> Dictionary:
	return _active_tool_runtime.refresh() if _active_tool_runtime != null else {}


func _update_active_tool_hud() -> void:
	if _active_tool_hud != null and _active_tool_runtime != null:
		_active_tool_hud.refresh(_active_tool_runtime.report())


func _update_held_cargo_hud() -> void:
	if _held_cargo_hud != null:
		_held_cargo_hud.refresh(_material_runtime.report() if _material_runtime != null else {}, _sortie_state.report() if _sortie_state != null else {}, _held_salvage_capacity())


func _cycle_active_tool() -> Dictionary:
	return _active_tool_runtime.cycle()


func _use_active_tool() -> Dictionary:
	return _active_tool_runtime.use()


func _try_purchase_oxygen_tank_upgrade() -> bool:
	return _try_purchase_progression_upgrade(SessionProgression.OXYGEN_TANK_UPGRADE_ID)


func _try_purchase_cargo_capacity_upgrade() -> bool:
	return _try_purchase_progression_upgrade(SessionProgression.CARGO_CAPACITY_UPGRADE_ID)


func _show_project_guidance() -> void:
	if _material_project != null:
		_last_status_note = _material_project.active_day_build_feedback(_current_map_id(), _scanner_blueprint_recovered())
	_update_status_label()


func _try_purchase_progression_upgrade(upgrade_id: String) -> bool:
	if _progression_runtime == null:
		return false
	var result: Dictionary = _progression_runtime.try_purchase(upgrade_id, _world, _player)
	if result.has("note"):
		_last_status_note = str(result["note"])
	_update_status_label()
	return bool(result.get("purchased", false))


func _has_oxygen_tank_upgrade() -> bool:
	return _progression_runtime != null and _progression_runtime.has_oxygen_tank_upgrade()


func _has_cargo_capacity_upgrade() -> bool:
	return _progression_runtime != null and _progression_runtime.has_cargo_capacity_upgrade()


func _has_light_upgrade() -> bool:
	return _progression_runtime != null and _progression_runtime.has_light_upgrade()


func _has_propulsion_upgrade() -> bool:
	return _material_project != null and _material_project.has_propulsion_fins()


func _has_upgrade_id(upgrade_id: String) -> bool:
	return _progression_runtime != null and _progression_runtime.has_upgrade_id(upgrade_id)


func _apply_durable_light_profile() -> void:
	if _progression_runtime != null:
		_progression_runtime.apply_light_profile(_world, _player)


func _held_salvage_capacity() -> int:
	return _progression_runtime.held_salvage_capacity(HELD_SALVAGE_CAPACITY) if _progression_runtime != null else HELD_SALVAGE_CAPACITY


func _held_cargo_count() -> int:
	return _sortie_state.held_salvage + (_material_runtime.held_count() if _material_runtime != null else 0)


func _oxygen_capacity_seconds() -> float:
	return _progression_runtime.oxygen_capacity_seconds(OXYGEN_MAX_SECONDS) if _progression_runtime != null else OXYGEN_MAX_SECONDS


func _progression_overlay_text() -> String:
	var lines: Array[String] = []
	if _progression_runtime != null:
		lines.append(_progression_runtime.overlay_text(_world, _player))
	if _material_project != null:
		var fins_guidance: String = _material_project.propulsion_fins_guidance(_current_map_id(), _scanner_blueprint_recovered())
		if not fins_guidance.is_empty():
			lines.append(fins_guidance)
	return "\n".join(lines)


func _update_progression_project_tracker() -> void:
	if _progression_project_tracker == null or _material_project == null or _material_runtime == null:
		return
	_progression_project_tracker.refresh(
		_material_project.report(),
		_material_runtime.held_quantities(),
		_expedition_day_state != null and _expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF
	)


func _current_map_id() -> String:
	return str(_world.map_id) if _world != null else ""


func _scanner_blueprint_recovered() -> bool:
	return _material_project != null and _material_project.has_scanner_blueprint()


func _progression_result_text() -> String:
	return _progression_runtime.result_text() if _progression_runtime != null else ""


func _update_result_panel() -> void:
	if _result_panel == null or _result_label == null:
		return
	if ExpeditionDayDebrief.apply_result_panel(self):
		return
	_result_panel.visible = _run_complete or _sortie_state.failed
	if not _run_complete and not _sortie_state.failed:
		_result_label.text = ""
		return

	var oxygen_text := "Oxygen %ds" % int(ceil(_sortie_state.oxygen_seconds))
	var failure_text := ""
	if _sortie_state.failed and _sortie_state.failure_reason != "combat_defeat":
		oxygen_text = "Oxygen depleted"
	elif _sortie_state.failed and _sortie_state.failure_reason == "combat_defeat":
		failure_text = "Combat defeat | %s" % _player_health.overlay_text()
	_result_label.text = ResultPresentationBuilder.build_text({
		"run_complete": _run_complete,
		"run_failed": _sortie_state.failed,
		"failure_text": failure_text,
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
		"discovery_text": _anomaly_survey.result_text(),
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
