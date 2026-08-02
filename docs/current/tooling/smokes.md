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
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-expansion-08-daily-condition-journey
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-09-full-level-journey
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-11-deep-harmonic-light-return
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-12-abyssal-pressure-return
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-13-southeast-wreck-return
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-13-scanner-cutter-correction
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
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --fresh-review-profile --smoke-current-gate
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

GitHub Actions preserves the complete smoke suite in three concurrent lanes: source/map validation, core runtime checks, and the longer regional-journey/route checks. The lanes share checked helpers under `tools/ci/`; they do not skip tests based on changed paths, and every Godot invocation fails on a nonzero exit or logged script/error line. Superseded runs on the same ref are canceled so only the newest cumulative change continues consuming CI time.

The standalone daylight runtime smoke uses a five-second deterministic override to verify countdown, connector preservation, one exact nightfall event, and clean next-day reset without waiting on wall-clock time.

The standalone surface/boat smoke derives an open top-row water cell outside the authored boat, verifies oxygen refill without cargo/profile/wallet mutation, then confirms the canonical boat banks the held cargo.

The standalone multiple-sortie smoke banks two separate departures into one shared day, verifies refreshed sortie oxygen and persistent daylight/day totals, then confirms a failed third sortie restores only unbanked cargo without duplicating rewards.

The standalone daylight-presentation smoke verifies the fixed-width day/time/dive line, surface-versus-boat action text, dusk/night warnings, and safe boat-only `N` end-day request.

The standalone night-debrief smoke verifies voluntary and forced night resolution, day-summary totals, unbanked-state cleanup, next-day reset at the canonical boat, profile reload persistence, and the absence of unimplemented survival taxes or planning controls.

The standalone combat-runtime smoke verifies the source-derived hostile visual/state boundary, warning/lunge/contact cycle, unarmed warning retreat, capability-locked and three-hit shock-prod behavior, reward-free defeat, connector-day persistence, and new-day/failure restoration.

The integrated expedition-day smoke verifies shared daylight across open-surface recovery, boat offload, connector travel, and repeated sorties, then covers voluntary debrief, forced nightfall cleanup, next-day reset, and durable profile reload. CI and release validation run it as `--smoke-expedition-day`.

The integrated Expansion 03 smoke verifies deterministic recipe selection, connector-preserved material cargo, cargo pressure, canonical-boat commitment, knowledge/project gating, exact-once cutter completion, profile reload, next-day rotation, locked/unlocked sealed-wreck interaction, failure restoration, and final payoff banking. CI and release validation run it as `--smoke-expansion-03-material-project`.

The integrated Expansion 06 smoke verifies source territory/timing, normal unarmed cache progress, active-eel contact/knockback interruption, health/oxygen separation, exact-once non-enemy shock-prod construction, selected-tool `Space` attacks, blocked legacy attack input, profile reload, reward-free armed victory, guarded-cache collection/banking, connector/day persistence, and combat/hazard/oxygen restoration. CI and release validation run it as `--smoke-expansion-06-combat-foundation`.

The mobile-control smoke protects the accepted eight-region landscape layout, 104 px bottom interaction inset, simultaneous stick/command input, shared `TOOL`/`USE` actions, and non-overlapping active-tool HUD states at 1280x720 and 844x390. CI runs it directly as `smoke_mobile_test_controls.gd`.

The named-checkpoint Shock Prod path is covered with:

```powershell
& $godot --headless --path . --review-checkpoint=expansion_14_start --smoke-checkpoint-shock-prod
```

It verifies checkpoint ownership, Scanner-first selection, `Tab`/`TOOL` cycling,
`Space`/`USE` dispatch, in-range facing, capacitor interruption, and honest
owned-versus-selected HUD text against the full-level eel. It also verifies
that switching away from Scanner cancels partial relay progress.

Run the complete bounded owner-HOLD correction matrix with:

```bash
bash tools/ci/run_expansion_14_hold_correction.sh
```

The matrix composes the focused combat, scanner, relay, checkpoint, passive
equipment, mobile-control, and Expansion 14 journey checks. CI runs it once in
the regional-journey lane after the correction owners merge.

The material-sprite smoke loads the named 32x32 titanium, bundled-rubber, and spring-coil textures, verifies `material_id` selection replaces the generic prop without tint, and confirms candidate identity plus fallback `kind` remain unchanged. CI and release validation run it directly as `smoke_material_sprite_assets.gd`.

The integrated Expansion 07 smoke verifies nonlethal timed sampling, explicit post-defeat harvesting, cargo-full and failure restoration, boat banking, exact-once capacitor construction/reload, and a one-damage warning interruption. CI and release validation run it as `--smoke-expansion-07-biological-progression`.

The integrated Expansion 08 smoke verifies baseline day, night-ahead forecast, southwest bloom patrol and bonus coil activation, unchanged normal pools/patrol, cargo-full, banking, connector, hazard/oxygen restoration, day-three removal, and required progression. CI and release validation run it as `--smoke-expansion-08-daily-condition-journey`.

The integrated Expansion 09 smoke uses active player collision to swim three direct boat-return sorties through the default contiguous `production_level_01`. It reaches the upper-left, lower-right, and lower-left sector anchors without position assignment, connector travel, collision disablement, or oxygen disablement; banks transformed salvage through the canonical boat; and reports route distance, oxygen, daylight, health, cargo, profile, day, and connector state. CI and release validation run it as `--smoke-expansion-09-full-level-journey`.

The integrated Expansion 10 smoke starts from a memory-only fresh profile, proves the pre-fins current denial, recovers and builds the authored fins recipe at night, recovers the east-pocket scanner blueprint, banks Ti1/Coil1, and builds the scanner on the following night without collecting the optional cache. It then swims the collision-active Signal Reef route out and back without teleport or connector travel. It reports source ids, world positions, route distance, oxygen/day state, pending survey state, boat commitment, and the next-expedition lead. CI and release validation run it as `--smoke-expansion-10-regional-journey`.

The integrated Expansion 11 smoke reuses that real prerequisite journey with an isolated temporary profile, scouts the harmonic target before light, banks Ti1+Coil1+Gel1 through cargo-capacity pressure, builds the durable light during a real night debrief, verifies next-day readability and failure cleanup, then swims the harmonic return and commits its discovery only at the canonical boat. It checks duplicate prevention and reload before deleting the temporary profile. CI and release validation run it as `--smoke-expansion-11-deep-harmonic-light-return`.

The integrated Expansion 12 smoke extends that journey through the pressure-suit project, scoutable pressure warning, protected abyssal survey, canonical-boat commitment, and profile reload. CI and release validation run it as `--smoke-expansion-12-abyssal-pressure-return`.

The integrated Expansion 13 smoke starts with an empty temporary profile, prepares only the already-earned prerequisites, and then swims the real collision-active boat-to-wreck-to-boat route once. It protects pressure crossing, base and upgraded oxygen margins, recorder and scanner timing, full-cargo behavior, explicit `Space/USE`, leave-range cancellation, all three failure restorations, pending return, durable clearance, exact-once discovery commitment, and profile reload. CI and release validation run it as `--smoke-expansion-13-southeast-wreck-return`.

The active-tool selection smoke checks the ordered scanner/cutter/shock-prod catalog, passive-capability exclusion, first-owned selection, cycle/wrap behavior, invalid-selection normalization, single-tool dispatch, and the `Tab`/`Space` input bindings. Run it as `--smoke-active-tool-selection`.

The focused sealed-wreck reward state check runs directly with `--script res://scripts/main/smoke/smoke_sealed_wreck_reward_state.gd`. It protects cargo-full blocking, separate +300 salvage value and pending navigation data, failure restoration, canonical-boat exact-once commitment, southeast-lead presentation, profile reload, and completed-archive migration. Integrated route coverage remains in the Expansion 13 journey smoke.

Expansion 13 correction coverage is intentionally distributed: active-tool selection protects ownership/order/one-tool dispatch; cutter state protects wrong-tool, proximity, cancellation, cargo, and hazard behavior; Expansion 06 protects selected shock-prod use; sealed-wreck reward state protects pending/restore/commit/reload; the scanner-cutter correction smoke joins scanner and cutter use with the reward; and the southeast-return smoke protects hazard/oxygen/combat cleanup plus durable recorder clearance. CI and release validation run this matrix without embedding the entire release suite in one smoke.

The salvage-loop smoke check loads the default production level, collects authored salvage through the same runtime methods used in play, returns to extraction, confirms completion, resets, and exits.

The production-slice route smoke loads `production_slice_01`, checks open-water source routes to each authored salvage point, banks cargo at the boat whenever the held capacity fills, confirms completion, resets, and exits.

The route-choice metadata smoke loads `production_slice_01`, verifies the ordered `expanded_route_choice` targets have route-choice IDs, positive valuable scores, and open source routes from spawn and back to extraction, then exits without swimming the player.

The expanded route-choice smoke loads `production_slice_01`, verifies the source route metadata for `salvage_lower_loop` and `salvage_deep_right_cache`, swims through both valuable targets, returns to the boat with full cargo, reports target ids, held capacity, banked salvage, score, and oxygen, resets, and exits.

The safe/deep route-choice smoke loads `production_slice_01`, swims one run to the short `safe_route_choice` target and a second run through the deeper `expanded_route_choice` targets, reports target ids, cargo, banked salvage, score, oxygen, and oxygen feedback for both runs, and asserts the safe route stays comfortable while the deeper route has higher payoff, lower remaining oxygen, and visible `LOW`/`CRITICAL` pressure.

The production-slice-02 route smoke loads `production_slice_02`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The production-slice-03 route smoke loads `production_slice_03`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The production-slice-04 route smoke loads `production_slice_04`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The `Godot Smoke` workflow runs all four production-slice route smoke flags so CI catches broken authored routes across the accepted/reference slices, not only the default preview loop.

The map-selector smoke explicitly loads `production_level_01`, then `production_slice_03`, then `production_slice_01` through the same clean map/player reload path used by the local review selector.

The hazard-interaction smoke loads `production_slice_01`, collects one salvage item, moves to warning-only range near an authored hazard, confirms the overlay reports `Hazard nearby - keep clear` without dropping cargo or moving the player, then touches the hazard, confirms the 12-second oxygen penalty, spawn reset, held-salvage restoration, and recollection behavior, then verifies a low-oxygen hazard hit cleanly shows the failed expedition result panel. `--smoke-hazard-pressure` runs the same deterministic check with CI-oriented output that reports hazard id, warning distance/radii, oxygen before/after, and restored salvage id.

The Pass 07 hazard route pressure smoke loads `production_slice_01`, verifies the source marker `lower_loop_to_deep_cache_pressure`, checks warning-only range and the selected `Hazard ahead - keep clear` prompt for `hazard_right_branch`, confirms contact oxygen/reset/restoration behavior, confirms partial timed-salvage state clears on hazard contact, and confirms the deep cache can still return to extraction.

The Pass 08 route-extension smoke loads `production_slice_01`, verifies the source marker `southwest_return_pocket_extension`, checks open-water paths to `salvage_southwest_return_cache`, the timed deep cache, and boat extraction, confirms the pocket payoff can be collected and banked with existing cargo semantics, and reports segment id, target id, tier, route id, score, path sizes, held cargo, banked score, oxygen, timed target, and Pass 07 context.

The Pass 09 southwest pocket decision smoke loads `production_slice_01`, verifies `salvage_southwest_return_cache` is the valuable instant `southwest_pocket_decision` payoff, checks open-water paths to the target, deep cache, and extraction, confirms the `Southwest pocket payoff` feedback, banks the target, verifies route bookkeeping and label text, then resets cleanly.

The oxygen-pressure smoke loads `production_slice_01`, collects one salvage item, forces oxygen depletion, confirms the player surfaces at spawn with held salvage restored, confirms the failed expedition result panel appears, resets, recollects the salvage, returns to extraction, confirms oxygen refills and salvage banks, resets, and exits.

The cargo-capacity smoke loads `production_slice_01`, fills the current two-pickup held capacity, confirms held score is not banked before extraction, confirms a third pickup remains available and visibly uncollected while cargo is full, confirms the status says to return to extraction, banks held cargo/score at extraction, then confirms the blocked pickup can be collected after capacity frees up.

The feedback-cue smoke loads `production_slice_01` and protects the complete first-pickup lifecycle without requiring audio hardware. It verifies locked-Web handling without stale replay, first and later material/salvage pickup events across two sorties, one bank cue per offload, cargo-full silence, canceled timed/pry silence, oxygen and hazard cues, exact event counts, and cue priority ownership. Pair it with `python tools/check_feedback_audio_assets.py` for deterministic WAV validation and use `docs/current/FIRST_FEEDBACK_AUDIO_REVIEW.md` as the focused review artifact.

The salvage-feedback smoke loads `production_slice_01`, collects one common pickup and one valuable pickup in separate reset runs, and confirms the status text reports the correct tier and score for each pickup.

The session-best score smoke loads `production_slice_01`, completes a full collect-return run, confirms the result panel shows score and best score, confirms reset preserves the current map's best score, and confirms oxygen failure does not overwrite that best score.

The oxygen-bonus score smoke loads `production_slice_01`, completes a full collect-return run, confirms salvage banked score remains tier-derived, confirms the completion-only oxygen bonus is based on remaining oxygen, and confirms failed expeditions receive zero oxygen bonus.

The route-outcome result smoke loads `production_slice_01`, completes a route-tagged collect-return run, confirms the compact result panel includes `Route: Deep route`, resets, and confirms a generic failure result does not show stale route text.

The release-journey smoke loads `production_slice_01`, collects and banks the required primary deep-cache objective targets, verifies the completed result and next-dive prompt, resets, prepares durable recipe-built fins, transitions through the lower-left connector to `production_slice_04`, banks the destination payoff, and verifies the final-dive result cue. Run it with `--smoke-release-journey`.

The Pass 18 progression smoke loads `production_slice_01`, confirms held and failed unbanked salvage do not create wallet payout, confirms banked salvage creates spendable wallet, confirms insufficient-funds purchase is blocked, buys the single oxygen tank upgrade, verifies wallet spend and upgraded capacity, then confirms reset/refill preserve the session upgrade.

The current-gate smoke loads `production_slice_01` with isolated in-memory profile state, holds the real eastward swim input against `upper_right_current_pocket_gate`, proves a fresh diver cannot cross, builds fins from exactly Ti2+Rubber1 without spending wallet, then proves the same controller movement crosses passively without `E`.

The upgrade-chest smoke is the blueprint-project journey check. From a fresh profile it proves proximity cannot auto-recover either plan, uses `E`, verifies active-day BUILD mutates nothing, tracks exact held/banked recipes, builds fins at night, crosses the standard current through controller movement, recovers the scanner blueprint, and proves optional score cannot bypass its Ti1/Coil1 night project.

The moving-hazard smoke loads `production_slice_01`, verifies `deep_route_jellyfish_patrol` moves deterministically, shows the compact warning prompt, applies existing hazard oxygen/reset/restoration semantics on contact, and preserves nearby route behavior.

The timed-salvage smoke loads `production_slice_01` and reports the active timed target id, interaction seconds, progress, cancel feedback, completion feedback, held cargo, banked score, oxygen, cargo-blocked state, hazard restoration, and oxygen-reset behavior.

The salvage-loop smoke also confirms the completion-only expedition result panel appears after a full collect-return run and reports the banked salvage score, oxygen bonus, best score, and salvage totals.

The player-facing smoke loads `production_slice_01`, asks the player controller to swim right, left, then right again, and confirms the root transform remains stable while only the player visual children flip. This catches one-frame double-facing regressions from flipping the whole `CharacterBody2D`.

The Pass 27 facing-transition smoke loads `production_slice_01`, drives repeated one-frame left/right reversals, and confirms root scale, body flip, frame-filter clipping, body frame bounds, light cone position/scale, light range, and light alpha remain coherent after every reversal and reset.

The movement-feel smoke loads `production_slice_01`, places the player in the first-route-choice open-water area, drives the real controller through start, stop, horizontal reversal, and diagonal input phases, and reports measured velocities for movement tuning review.

The feedback-overlay capture loads `production_slice_01`, collects one salvage item, forces the overlay into a low-oxygen held-salvage review state, and writes `visual_captures/feedback_overlay/production_slice_01_feedback_overlay.png` without changing map source data or accepted baselines.
