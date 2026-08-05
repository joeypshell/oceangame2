#!/usr/bin/env bash
set -euo pipefail

run_godot() {
  bash tools/ci/run_godot_checked.sh "$@"
}

run_godot headless-smoke 120 --headless --path . --quit-after 1
run_godot mobile-test-controls 120 --headless --path . --script res://scripts/main/smoke/smoke_mobile_test_controls.gd
run_godot material-sprite-assets 120 --headless --path . --script res://scripts/main/smoke/smoke_material_sprite_assets.gd
run_godot durable-light-project-state 120 --headless --path . --script res://scripts/main/smoke/smoke_durable_light_project_state.gd
run_godot pressure-suit-project-state 120 --headless --path . --script res://scripts/main/smoke/smoke_pressure_suit_project_state.gd
run_godot pressure-zone-state 120 --headless --path . --script res://scripts/main/smoke/smoke_pressure_zone_state.gd
run_godot oxygen-consumption-zone-state 120 --headless --path . --script res://scripts/main/smoke/smoke_oxygen_consumption_zone_state.gd
run_godot expansion-16-integration-state 180 --headless --path . --script res://scripts/main/smoke/smoke_expansion_16_integration_state.gd
run_godot companion-profile-state 120 --headless --path . --script res://scripts/main/smoke/smoke_companion_profile_state.gd
run_godot companion-memory-night 180 --headless --path . --script res://scripts/main/smoke/smoke_companion_memory_night.gd
run_godot spark-ray-follow 180 --headless --path . --script res://scripts/main/smoke/smoke_spark_ray_follow.gd
run_godot spark-ray-riding 180 --headless --path . --script res://scripts/main/smoke/smoke_spark_ray_riding.gd
run_godot anchor-fins-payoff 180 --headless --path . --script res://scripts/main/smoke/smoke_anchor_fins_payoff.gd
run_godot wreck-network-investigation-state 120 --headless --path . --script res://scripts/main/smoke/smoke_wreck_network_investigation_state.gd
run_godot wreck-network-runtime-integration 180 --headless --path . --script res://scripts/main/smoke/smoke_wreck_network_runtime_integration.gd
run_godot salvage-loop 120 --headless --path . --quit-after 1 --smoke-salvage-loop

score_smokes=(
  --smoke-cargo-capacity
  --smoke-feedback-cues
  --smoke-salvage-feedback
  --smoke-session-best-score
  --smoke-oxygen-bonus-score
  --smoke-route-outcome-result
  --smoke-pass-18-progression
  --smoke-pass-19-cargo-upgrade
  --smoke-pass-20-light-upgrade
  --smoke-pass-21-world-connector
  --smoke-pass-22-destination-payoff
  --smoke-pass-24-relay-follow-through
  --smoke-pass-25-final-dive-objective
  --smoke-pass-26-result-presentation
  --smoke-release-journey
  --smoke-anomaly-survey-journey
  --smoke-expedition-day
  --smoke-expansion-03-material-project
  --smoke-expansion-04-current-pocket
  --smoke-expansion-05-practical-research
  --smoke-expansion-06-combat-foundation
  --smoke-expansion-07-biological-progression
  --smoke-expansion-08-daily-condition-journey
  --smoke-upgrade-chest
  --smoke-moving-hazard
  --smoke-darkness-light-gate
)

for flag in "${score_smokes[@]}"; do
  run_godot "${flag#--smoke-}" 180 --headless --path . --quit-after 1 "${flag}"
done
run_godot current-gate 180 --headless --path . --quit-after 1 --smoke-current-gate --fresh-review-profile

run_godot map-selector 180 --headless --path . --smoke-map-selector
run_godot full-level-runtime 180 --headless --path . --measure-map-runtime
run_godot hazard-pressure 180 --headless --path . --smoke-hazard-pressure
run_godot timed-salvage 180 --headless --path . --smoke-timed-salvage
run_godot pry-salvage 180 --headless --path . --smoke-pry-salvage
run_godot player-facing 180 --headless --path . --smoke-player-facing
run_godot pass-27-facing-transitions 180 --headless --path . --smoke-pass-27-facing-transitions

bash tools/ci/check_tracked_clean.sh
