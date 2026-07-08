# Smoke Checks

Run whitespace checks:

```bash
git diff --check
```

Run the Godot headless launch smoke check on this Windows setup:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-02-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-03-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-04-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-route-choice-metadata
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expanded-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-safe-deep-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-map-selector
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-interaction
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-07-hazard-route-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-08-route-extension
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-cargo-capacity
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-feedback
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-session-best-score
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-bonus-score
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-route-outcome-result
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-timed-salvage
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-movement-feel
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-feedback-overlay
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-route-outcome-result
```

The import command is important on a fresh clone or CI checkout because `.godot/` and `*.import` files are intentionally untracked. The headless command can exit `0` even when script errors appear in output, so treat `SCRIPT ERROR` or `ERROR:` lines as failures.

The salvage-loop smoke check loads the default production slice, collects all authored salvage through the same runtime methods used in play, returns to extraction, confirms completion, resets, and exits.

The production-slice route smoke loads `production_slice_01`, checks open-water source routes to each authored salvage point, banks cargo at the boat whenever the held capacity fills, confirms completion, resets, and exits.

The route-choice metadata smoke loads `production_slice_01`, verifies the ordered `expanded_route_choice` targets have route-choice IDs, positive valuable scores, and open source routes from spawn and back to extraction, then exits without swimming the player.

The expanded route-choice smoke loads `production_slice_01`, verifies the source route metadata for `salvage_lower_loop` and `salvage_deep_right_cache`, swims through both valuable targets, returns to the boat with full cargo, reports target ids, held capacity, banked salvage, score, and oxygen, resets, and exits.

The safe/deep route-choice smoke loads `production_slice_01`, swims one run to the short `safe_route_choice` target and a second run through the deeper `expanded_route_choice` targets, reports target ids, cargo, banked salvage, score, oxygen, and oxygen feedback for both runs, and asserts the safe route stays comfortable while the deeper route has higher payoff, lower remaining oxygen, and visible `LOW`/`CRITICAL` pressure.

The production-slice-02 route smoke loads `production_slice_02`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The production-slice-03 route smoke loads `production_slice_03`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The production-slice-04 route smoke loads `production_slice_04`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The `Godot Smoke` workflow runs all four production-slice route smoke flags so CI catches broken authored routes across the accepted/reference slices, not only the default preview loop.

The map-selector smoke loads the default map, reloads `production_slice_03`, then reloads `production_slice_01` through the same clean map/player reload path used by the local review selector.

The hazard-interaction smoke loads `production_slice_01`, collects one salvage item, moves to warning-only range near an authored hazard, confirms the overlay reports `Hazard nearby - keep clear` without dropping cargo or moving the player, then touches the hazard, confirms the 12-second oxygen penalty, spawn reset, held-salvage restoration, and recollection behavior, then verifies a low-oxygen hazard hit cleanly shows the failed expedition result panel. `--smoke-hazard-pressure` runs the same deterministic check with CI-oriented output that reports hazard id, warning distance/radii, oxygen before/after, and restored salvage id.

The Pass 07 hazard route pressure smoke loads `production_slice_01`, verifies the source marker `lower_loop_to_deep_cache_pressure`, checks warning-only range and the selected `Hazard ahead - keep clear` prompt for `hazard_right_branch`, confirms contact oxygen/reset/restoration behavior, confirms partial timed-salvage state clears on hazard contact, and confirms the deep cache can still return to extraction.

The Pass 08 route-extension smoke loads `production_slice_01`, verifies the source marker `southwest_return_pocket_extension`, checks open-water paths to `salvage_southwest_return_cache`, the timed deep cache, and boat extraction, confirms the pocket payoff can be collected and banked with existing cargo semantics, and reports segment id, target id, tier, route id, score, path sizes, held cargo, banked score, oxygen, timed target, and Pass 07 context.

The oxygen-pressure smoke loads `production_slice_01`, collects one salvage item, forces oxygen depletion, confirms the player surfaces at spawn with held salvage restored, confirms the failed expedition result panel appears, resets, recollects the salvage, returns to extraction, confirms oxygen refills and salvage banks, resets, and exits.

The cargo-capacity smoke loads `production_slice_01`, fills the current two-pickup held capacity, confirms held score is not banked before extraction, confirms a third pickup remains available and visibly uncollected while cargo is full, confirms the status says to return to extraction, banks held cargo/score at extraction, then confirms the blocked pickup can be collected after capacity frees up.

The salvage-feedback smoke loads `production_slice_01`, collects one common pickup and one valuable pickup in separate reset runs, and confirms the status text reports the correct tier and score for each pickup.

The session-best score smoke loads `production_slice_01`, completes a full collect-return run, confirms the result panel shows score and best score, confirms reset preserves the current map's best score, and confirms oxygen failure does not overwrite that best score.

The oxygen-bonus score smoke loads `production_slice_01`, completes a full collect-return run, confirms salvage banked score remains tier-derived, confirms the completion-only oxygen bonus is based on remaining oxygen, and confirms failed expeditions receive zero oxygen bonus.

The route-outcome result smoke loads `production_slice_01`, completes a route-tagged collect-return run, confirms the compact result panel includes `Route: Deep route`, resets, and confirms a generic failure result does not show stale route text.

The timed-salvage smoke loads `production_slice_01` and reports the active timed target id, interaction seconds, progress, cancel feedback, completion feedback, held cargo, banked score, oxygen, cargo-blocked state, hazard restoration, and oxygen-reset behavior.

The salvage-loop smoke also confirms the completion-only expedition result panel appears after a full collect-return run and reports the banked salvage score, oxygen bonus, best score, and salvage totals.

The player-facing smoke loads `production_slice_01`, asks the player controller to swim right, left, then right again, and confirms the root transform remains stable while only the player visual children flip. This catches one-frame double-facing regressions from flipping the whole `CharacterBody2D`.

The movement-feel smoke loads `production_slice_01`, places the player in the first-route-choice open-water area, drives the real controller through start, stop, horizontal reversal, and diagonal input phases, and reports measured velocities for movement tuning review.

The feedback-overlay capture loads `production_slice_01`, collects one salvage item, forces the overlay into a low-oxygen held-salvage review state, and writes `visual_captures/feedback_overlay/production_slice_01_feedback_overlay.png` without changing map source data or accepted baselines.
