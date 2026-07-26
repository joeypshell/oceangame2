#!/usr/bin/env bash
set -euo pipefail

run_godot() {
  bash tools/ci/run_godot_checked.sh "$@"
}

run_godot expansion-09-full-level-journey 240 --headless --path . --smoke-expansion-09-full-level-journey
run_godot expansion-10-regional-journey 300 --headless --path . --smoke-expansion-10-regional-journey
run_godot expansion-11-light-return 420 --headless --path . --smoke-expansion-11-deep-harmonic-light-return
run_godot expansion-12-pressure-return 540 --headless --path . --smoke-expansion-12-abyssal-pressure-return
run_godot expansion-13-southeast-wreck-return 300 --headless --path . --smoke-expansion-13-southeast-wreck-return
run_godot expansion-13-scanner-cutter-correction 120 --headless --path . --smoke-expansion-13-scanner-cutter-correction
run_godot expansion-15-expedition-planning 180 --headless --path . --smoke-expansion-15-expedition-planning
run_godot active-tool-selection 60 --headless --path . --smoke-active-tool-selection
run_godot cutter-salvage-state 60 --headless --path . --script res://scripts/main/smoke/smoke_cutter_salvage_state.gd
run_godot sealed-wreck-reward-state 60 --headless --path . --script res://scripts/main/smoke/smoke_sealed_wreck_reward_state.gd
bash tools/ci/run_expansion_14_hold_correction.sh

route_smokes=(
  --smoke-production-slice-route
  --smoke-route-choice
  --smoke-route-choice-metadata
  --smoke-expanded-route-choice
  --smoke-safe-deep-route-choice
  --smoke-pass-07-hazard-route-pressure
  --smoke-pass-08-route-extension
  --smoke-pass-09-southwest-pocket-decision
  --smoke-pass-10-return-pressure
  --smoke-pass-11-pre-pickup-route-cue
  --smoke-pass-12-oxygen-rest-pressure
  --smoke-pass-13-route-commitment
  --smoke-pass-14-objective-cue
  --smoke-pass-15-objective-follow-through
  --smoke-primary-dive-completion
  --smoke-pass-23-next-dive-objective
  --smoke-production-slice-02-route
  --smoke-production-slice-03-route
  --smoke-production-slice-04-route
)

for flag in "${route_smokes[@]}"; do
  run_godot "${flag#--smoke-}" 240 --headless --path . "${flag}"
done

bash tools/ci/check_tracked_clean.sh
