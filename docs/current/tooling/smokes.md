# Smoke Checks

Run whitespace checks:

```bash
git diff --check
```

Run the Godot headless launch smoke check on this Windows setup:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_daylight_runtime.gd
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_surface_boat_semantics.gd
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_multiple_sorties.gd
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_daylight_presentation.gd
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_night_debrief.gd
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_combat_runtime_state.gd
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expedition-day
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-03-material-project
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-06-combat-foundation
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-07-biological-progression
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
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-09-southwest-pocket-decision
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-cargo-capacity
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-feedback
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-session-best-score
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-bonus-score
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-route-outcome-result
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-pass-18-progression
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-current-gate
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-upgrade-chest
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-moving-hazard
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-timed-salvage
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-27-facing-transitions
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-movement-feel
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-feedback-overlay
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-route-outcome-result
```

The import command is important on a fresh clone or CI checkout because `.godot/` and `*.import` files are intentionally untracked. The headless command can exit `0` even when script errors appear in output, so treat `SCRIPT ERROR` or `ERROR:` lines as failures.

The standalone daylight runtime smoke uses a five-second deterministic override to verify countdown, connector preservation, one exact nightfall event, and clean next-day reset without waiting on wall-clock time.

The standalone surface/boat smoke derives an open top-row water cell outside the authored boat, verifies oxygen refill without cargo/profile/wallet mutation, then confirms the canonical boat banks the held cargo.

The standalone multiple-sortie smoke banks two separate departures into one shared day, verifies refreshed sortie oxygen and persistent daylight/day totals, then confirms a failed third sortie restores only unbanked cargo without duplicating rewards.

The standalone daylight-presentation smoke verifies the fixed-width day/time/dive line, surface-versus-boat action text, dusk/night warnings, and safe boat-only `N` end-day request.

The standalone night-debrief smoke verifies voluntary and forced night resolution, day-summary totals, unbanked-state cleanup, next-day reset at the canonical boat, profile reload persistence, and the absence of unimplemented survival taxes or planning controls.

The standalone combat-runtime smoke verifies the source-derived hostile visual/state boundary, warning/lunge/contact cycle, unarmed warning retreat, capability-locked and three-hit shock-prod behavior, reward-free defeat, connector-day persistence, and new-day/failure restoration.

The integrated expedition-day smoke verifies shared daylight across open-surface recovery, boat offload, connector travel, and repeated sorties, then covers voluntary debrief, forced nightfall cleanup, next-day reset, and durable profile reload. CI and release validation run it as `--smoke-expedition-day`.

The integrated Expansion 03 smoke verifies deterministic recipe selection, connector-preserved material cargo, cargo pressure, canonical-boat commitment, knowledge/project gating, exact-once cutter completion, profile reload, next-day rotation, locked/unlocked sealed-wreck interaction, failure restoration, and final payoff banking. CI and release validation run it as `--smoke-expansion-03-material-project`.

The integrated Expansion 06 smoke verifies source territory/timing, normal unarmed cache progress, active-eel contact/knockback interruption, health/oxygen separation, exact-once non-enemy shock-prod construction, profile reload, reward-free armed victory, guarded-cache collection/banking, connector/day persistence, and combat/hazard/oxygen restoration. CI and release validation run it as `--smoke-expansion-06-combat-foundation`.

The integrated Expansion 07 smoke verifies nonlethal timed sampling, explicit post-defeat harvesting, cargo-full and failure restoration, boat banking, exact-once capacitor construction/reload, and a one-damage warning interruption. CI and release validation run it as `--smoke-expansion-07-biological-progression`.

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

The Pass 09 southwest pocket decision smoke loads `production_slice_01`, verifies `salvage_southwest_return_cache` is the valuable instant `southwest_pocket_decision` payoff, checks open-water paths to the target, deep cache, and extraction, confirms the `Southwest pocket payoff` feedback, banks the target, verifies route bookkeeping and label text, then resets cleanly.

The oxygen-pressure smoke loads `production_slice_01`, collects one salvage item, forces oxygen depletion, confirms the player surfaces at spawn with held salvage restored, confirms the failed expedition result panel appears, resets, recollects the salvage, returns to extraction, confirms oxygen refills and salvage banks, resets, and exits.

The cargo-capacity smoke loads `production_slice_01`, fills the current two-pickup held capacity, confirms held score is not banked before extraction, confirms a third pickup remains available and visibly uncollected while cargo is full, confirms the status says to return to extraction, banks held cargo/score at extraction, then confirms the blocked pickup can be collected after capacity frees up.

The feedback-cue smoke loads `production_slice_01`, triggers pickup, banking, oxygen warning/failure, and hazard warning/contact paths, then reports deterministic audio cue event counts without requiring audio hardware. Use `docs/current/FIRST_FEEDBACK_AUDIO_REVIEW.md` as the focused review artifact.

The salvage-feedback smoke loads `production_slice_01`, collects one common pickup and one valuable pickup in separate reset runs, and confirms the status text reports the correct tier and score for each pickup.

The session-best score smoke loads `production_slice_01`, completes a full collect-return run, confirms the result panel shows score and best score, confirms reset preserves the current map's best score, and confirms oxygen failure does not overwrite that best score.

The oxygen-bonus score smoke loads `production_slice_01`, completes a full collect-return run, confirms salvage banked score remains tier-derived, confirms the completion-only oxygen bonus is based on remaining oxygen, and confirms failed expeditions receive zero oxygen bonus.

The route-outcome result smoke loads `production_slice_01`, completes a route-tagged collect-return run, confirms the compact result panel includes `Route: Deep route`, resets, and confirms a generic failure result does not show stale route text.

The release-journey smoke loads `production_slice_01`, collects and banks the required primary deep-cache objective targets, verifies the completed result and next-dive prompt, resets, prepares durable recipe-built fins, transitions through the lower-left connector to `production_slice_04`, banks the destination payoff, and verifies the final-dive result cue. Run it with `--smoke-release-journey`.

The Pass 18 progression smoke loads `production_slice_01`, confirms held and failed unbanked salvage do not create wallet payout, confirms banked salvage creates spendable wallet, confirms insufficient-funds purchase is blocked, buys the single oxygen tank upgrade, verifies wallet spend and upgraded capacity, then confirms reset/refill preserve the session upgrade.

The current-gate smoke loads `production_slice_01`, verifies the source-authored `lower_left_loop_current` soft-push marker and visible affordance before `propulsion_fins`, confirms oxygen continues draining, builds durable fins from exactly Ti2+Rubber1 without spending wallet, then confirms the same location presents and uses the relay connector.

The upgrade-chest smoke is now the blueprint-fins journey check. From a fresh profile it traverses validated path-query cells with controller directions, recovers `propulsion_fins_blueprint`, distinguishes held/banked recipe counts, builds at night, reaches the visible relay, presses `E`, banks the destination payoff, and verifies scanner-next guidance without premature shock-prod text.

The moving-hazard smoke loads `production_slice_01`, verifies `deep_route_jellyfish_patrol` moves deterministically, shows the compact warning prompt, applies existing hazard oxygen/reset/restoration semantics on contact, and preserves nearby route behavior.

The timed-salvage smoke loads `production_slice_01` and reports the active timed target id, interaction seconds, progress, cancel feedback, completion feedback, held cargo, banked score, oxygen, cargo-blocked state, hazard restoration, and oxygen-reset behavior.

The salvage-loop smoke also confirms the completion-only expedition result panel appears after a full collect-return run and reports the banked salvage score, oxygen bonus, best score, and salvage totals.

The player-facing smoke loads `production_slice_01`, asks the player controller to swim right, left, then right again, and confirms the root transform remains stable while only the player visual children flip. This catches one-frame double-facing regressions from flipping the whole `CharacterBody2D`.

The Pass 27 facing-transition smoke loads `production_slice_01`, drives repeated one-frame left/right reversals, and confirms root scale, body flip, frame-filter clipping, body frame bounds, light cone position/scale, light range, and light alpha remain coherent after every reversal and reset.

The movement-feel smoke loads `production_slice_01`, places the player in the first-route-choice open-water area, drives the real controller through start, stop, horizontal reversal, and diagonal input phases, and reports measured velocities for movement tuning review.

The feedback-overlay capture loads `production_slice_01`, collects one salvage item, forces the overlay into a low-oxygen held-salvage review state, and writes `visual_captures/feedback_overlay/production_slice_01_feedback_overlay.png` without changing map source data or accepted baselines.
