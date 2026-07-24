#!/usr/bin/env bash
set -euo pipefail

run_godot() {
  bash tools/ci/run_godot_checked.sh "$@"
}

run_godot scanner-subject-catalog 60 --headless --path . --script res://scripts/main/smoke/smoke_scanner_subject_catalog.gd
run_godot anomaly-survey-runtime 120 --headless --path . --script res://scripts/main/smoke/smoke_anomaly_survey_runtime.gd
run_godot scanner-field-presentation 60 --headless --path . --script res://scripts/main/smoke/smoke_scanner_field_presentation.gd
run_godot combat-runtime-state 60 --headless --path . --script res://scripts/main/smoke/smoke_combat_runtime_state.gd
run_godot expansion-14-runtime-owners 60 --headless --path . --script res://scripts/main/smoke/smoke_expansion_14_runtime_owners.gd
run_godot review-checkpoint-fixture 60 --headless --path . --script res://scripts/main/smoke/smoke_review_checkpoint_fixture.gd
run_godot shock-prod-presentation 60 --headless --path . --script res://scripts/main/smoke/smoke_shock_prod_presentation.gd
run_godot checkpoint-shock-prod 60 --headless --path . --review-checkpoint=expansion_14_start --smoke-checkpoint-shock-prod
run_godot held-cargo-hud 60 --headless --path . --script res://scripts/main/smoke/smoke_held_cargo_hud.gd
run_godot mobile-test-controls 60 --headless --path . --script res://scripts/main/smoke/smoke_mobile_test_controls.gd
run_godot expansion-14-archive-current-return 120 --headless --path . --smoke-expansion-14-archive-current-return

echo "Expansion 14 HOLD correction matrix passed: combat scanner relay checkpoint equipment mobile journey."
