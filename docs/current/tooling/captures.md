# Captures

Capture the current greybox screenshot baseline:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 5 --capture-greybox-screenshot
```

Do not use `--headless` for screenshot capture on this local setup. Headless uses Godot's dummy renderer here, so the viewport texture is unavailable. Use headless for smoke checks and non-headless for visual capture.

Capture the current named camera test views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-camera-tests
```

This reads `camera_tests` from the default preview map, currently `maps/production_level_01.greybox.json`, and writes PNGs to `visual_captures/latest/`.
Normal gameplay and capture views hide the greybox source grid. Add `--show-debug-overlay` when you specifically need the source TileMap/grid overlay for map debugging.

Capture the focused player-readability view for Controlled Visual Revision review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-player-readability
```

This explicitly loads `production_slice_01`, places the player a few tiles below the source-defined boat entry for a readable start-context shot, uses a close runtime camera, and writes `visual_captures/player_readability/production_slice_01_player_start.png`. Use this capture to review player sprite changes without changing map topology, gameplay, camera tests, or accepted baselines.

Capture the focused background-depth view for Controlled Visual Revision review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-background-depth
```

This explicitly loads `production_slice_01`, keeps map data and authored camera tests unchanged, frames the entry/crossing background silhouettes with terrain, water, player, props, and boat context, and writes `visual_captures/background_depth/production_slice_01_background_depth.png`. Use this capture to review non-collision background-depth changes without changing map topology, gameplay, camera tests, or accepted baselines.

Capture the focused route-outcome result view for Controlled Gameplay review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-route-outcome-result
```

This explicitly loads `production_slice_01`, completes a deterministic route-tagged collect-return run, keeps map data and accepted baselines unchanged, and writes `visual_captures/route_outcome/production_slice_01_route_outcome_result.png`. Use this capture to review the compact route outcome/result panel before accepting or replacing broader visual baselines.

Capture the focused timed-salvage interaction view for Controlled Gameplay review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-timed-salvage
```

This explicitly loads `production_slice_01`, places the player on the authored timed salvage target, advances to a partial `Salvaging deep cache` progress state, frames the Pass 06 in-world marker and overlay progress bar, keeps map data and accepted baselines unchanged, and writes `visual_captures/timed_salvage/production_slice_01_timed_salvage.png`.

Capture the focused pry-salvage interaction view for Controlled Gameplay review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pry-salvage
```

This explicitly loads `production_slice_01`, places the player on the authored pry salvage target, advances to a partial `Prying sealed cache` stage-progress state, keeps map data and accepted baselines unchanged, and writes `visual_captures/pry_salvage/production_slice_01_pry_salvage.png`.

Capture the focused Pass 07 hazard/navigation pressure view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-07-hazard-pressure
```

This explicitly loads `production_slice_01`, collects the lower-loop payoff into held cargo, places the player in warning-only range near `hazard_right_branch`, frames the selected pressure segment with the deep-cache payoff and overlay warning, keeps map data and accepted baselines unchanged, and writes `visual_captures/hazard_pressure/production_slice_01_hazard_pressure.png`.

Capture the focused Pass 08 route-extension view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-08-route-extension
```

This explicitly loads `production_slice_01`, places the player near `salvage_southwest_return_cache` without collecting it, frames `southwest_return_pocket_extension` with compact overlay context, keeps map data and accepted baselines unchanged, and writes `visual_captures/route_extension/production_slice_01_route_extension.png`.

Capture the focused Pass 09 southwest pocket route-decision view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-09-southwest-pocket-decision
```

This explicitly loads `production_slice_01`, collects `salvage_southwest_return_cache` through the normal runtime path, frames `southwest_return_pocket_extension` with compact payoff feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/southwest_pocket_decision/production_slice_01_southwest_pocket_decision.png`.

Capture the focused Pass 10 return-pressure view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-10-return-pressure
```

This explicitly loads `production_slice_01`, fills cargo with the lower-loop and timed deep-cache pickups, places the player at `salvage_return_branch`, frames the compact `Cargo full - bank at boat` feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_10_return_pressure/production_slice_01_return_pressure.png`.

Capture the focused Pass 11 pre-pickup route-cue view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-11-pre-pickup-route-cue
```

This explicitly loads `production_slice_01`, places the player in `southwest_pocket_pre_pickup_cue` before collecting `salvage_southwest_return_cache`, frames the compact `Relay trail cache ahead` feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_11_pre_pickup_route_cue/production_slice_01_pre_pickup_route_cue.png`.

Capture the focused Pass 15 objective-follow-through view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-15-objective-follow-through
```

This explicitly loads `production_slice_01`, places the player in `deep_cache_first_step_cue` before collecting `salvage_lower_loop`, frames the compact `Objective route: Lower loop` cue, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_15_objective_follow_through/production_slice_01_objective_follow_through.png`.

Capture the focused primary dive completion result view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-primary-dive-completion
```

This explicitly loads `production_slice_01`, collects the primary objective targets through the normal runtime path, banks them at extraction, frames the completed result panel, keeps map data and accepted baselines unchanged, and writes `visual_captures/primary_dive_completion/production_slice_01_primary_dive_completion.png`.

Capture the focused Pass 23 next-dive objective result view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-23-next-dive-objective
```

This explicitly loads `production_slice_01`, completes the primary objective through the normal runtime path, frames the result panel with the current `Next dive: Investigate east current` prompt, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_23_next_dive_objective/production_slice_01_pass_23_next_dive_objective.png`. The flag and output path retain their historical Pass 23 names for compatibility.

Capture the focused Pass 24 relay follow-through feedback view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-24-relay-follow-through
```

This loads production slice 04, collects and banks `slice_04_destination_cache` through the normal runtime path, frames the compact `Relay lead confirmed` overlay feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_24_relay_follow_through/production_slice_04_pass_24_relay_follow_through.png`.

Capture the focused Pass 25 final-dive objective feedback view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-25-final-dive-objective
```

This loads production slice 04, collects and banks `slice_04_destination_cache` through the normal runtime path, frames the combined `Relay lead confirmed` and `Final dive signal discovered` overlay feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_25_final_dive_objective/production_slice_04_pass_25_final_dive_objective.png`.

Capture the focused Pass 26 result presentation view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-26-result-presentation
```

This explicitly starts from `production_slice_01`, travels through the lower-left connector by the normal runtime path, completes the slice-04 final-dive payoff, frames the completed result panel with `Final dive signal locked`, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_26_result_presentation/production_slice_04_pass_26_result_presentation.png`.

Capture the focused Pass 27 player-facing review view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-27-player-facing
```

This explicitly loads `production_slice_01`, places the player in a readable open-water area, applies deterministic left/right reversals, frames the final right-facing body and light alignment, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_27_player_facing/production_slice_01_pass_27_player_facing.png`.

Capture the focused Expansion 01 anomaly survey and commit views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-anomaly-survey
```

This uses the source-authored slice-02 target and focused survey runtime to write a stable 50% progress view plus the committed slice-01 boat result under `visual_captures/anomaly_survey/`. The command is review-only and does not accept or replace production-slice baselines.

Capture the focused Expansion 02 expedition-day views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-expedition-day
```

This writes deterministic dusk surface-refill, boat-offload, and night-debrief frames under `visual_captures/expedition_day/`. The frames keep daylight, oxygen, and cargo context together for review and do not accept or replace production-slice baselines.

Capture the focused Expansion 03 material-project views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 30 --capture-expansion-03-material-project
```

This writes held-material, locked sealed-wreck, project-ready debrief, and 50% cutter-progress states at 1280x720 and 1920x1080 under `visual_captures/expansion_03_material_project/`. The command verifies output dimensions and does not accept or replace production-slice baselines.

Capture the Expansion 04 current-pocket review states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 30 --capture-expansion-04-current-pocket
```

This writes locked-current, stabilizer-ready debrief, unlocked-crossing, payoff-held, and payoff-banked states at 1280x720 and 1920x1080 under `visual_captures/expansion_04_current_pocket/`. The command verifies output dimensions and does not accept or replace production-slice baselines.

Capture the Expansion 05 practical-research review states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 30 --capture-expansion-05-practical-research
```

This writes the incomplete mineral clue, 50% survey progress, boat-committed finding, and following-day deep-cache habitat lead at 1280x720 and 1920x1080 under `visual_captures/expansion_05_practical_research/`. The command verifies output dimensions and does not accept or replace production-slice baselines.

Capture the Expansion 06 combat-foundation review states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 40 --capture-expansion-06-combat-foundation
```

This writes warning, lunge/evade, directional Shock Prod miss, and connected
1/3-health damage states at 1280x720, 1920x1080, and 844x390 under
`visual_captures/expansion_06_combat_foundation/`. The command verifies
dimensions and rejects blank or black-region output; it does not accept or
replace production-slice baselines.

Capture the Expansion 07 biological-progression review states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 40 --capture-expansion-07-biological-progression
```

This writes 50% passive-sample, 50% post-defeat harvest, and capacitor interrupt/recovery states at 1280x720 and 1920x1080 under `visual_captures/expansion_07_biological_progression/`. The command uses in-memory setup, verifies dimensions and nonblank output, and does not accept or replace production-slice baselines.

Capture the Expansion 08 night forecast and active southwest bloom:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 40 --capture-expansion-08-daily-condition
```

This writes both states at 1280x720 and 1920x1080 under `visual_captures/expansion_08_daily_condition/`. The command verifies deterministic condition state, dimensions, and nonblank output; it does not accept or replace production-slice baselines.

Capture the focused Pass 18 progression upgrade view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-18-progression
```

This explicitly loads `production_slice_01`, banks enough salvage through the normal runtime path to afford the oxygen tank upgrade, purchases it at extraction, frames the compact wallet/upgrade feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_18_progression/production_slice_01_pass_18_progression.png`.

Capture the focused Pass 19 cargo upgrade view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-19-cargo-upgrade
```

This explicitly loads `production_slice_01`, banks enough salvage through the normal runtime path to afford the cargo capacity upgrade, purchases it at extraction, frames compact wallet, `Cargo +1`, and `Held 0/3` feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_19_cargo_upgrade/production_slice_01_pass_19_cargo_upgrade.png`.

The committed Pass 20 light-upgrade image is historical evidence of the retired
900-score purchase. Its capture command is no longer active; use the focused
darkness/light pair below for durable-light rendering review.

Capture the focused darkness/light gate review pair:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-darkness-light-gate
```

This explicitly loads `production_slice_01`, frames `deep_cache_dark_pocket` with the player in the zone, writes a base-light shot and then prepares the durable profile project fixture for a readability shot, keeps map data and accepted baselines unchanged, and writes `visual_captures/darkness_light_gate/production_slice_01_darkness_light_before_light.png` and `visual_captures/darkness_light_gate/production_slice_01_darkness_light_after_light.png`.

Capture the focused Pass 21 world-connector arrival view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-21-world-connector
```

This explicitly loads `production_slice_01`, moves the player to `lower_left_loop_connector`, triggers the source-authored transition into `production_slice_04`, frames compact `Arrived: Lower-left loop` and return-connector feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/pass_21_world_connector/production_slice_04_world_connector_arrival.png`.

Capture the focused fins/scanner blueprint-project and current views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-upgrade-chest
```

This explicitly loads `production_slice_01` and writes desktop plus 844x390 mobile-viewport canvas captures for the fins and scanner blueprint prompts, both partial banked/held recipe trackers, the post-fins standard current, and the advanced relay current under `visual_captures/upgrade_chest/`. It does not accept or replace baselines. Do not add `--quit-after 10`; the six-state capture exits on completion and a short frame cap can stop it mid-run.

Capture the focused moving-hazard dodge view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-moving-hazard
```

This explicitly loads `production_slice_01`, advances `deep_route_jellyfish_patrol` to a readable patrol state, frames the route with compact `Jellyfish patrol - wait` feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/moving_hazard/production_slice_01_moving_hazard.png`.

Capture the original rectangular salvage map comparison views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-original-map
```

This reads `camera_tests` from `maps/cave_salvage_test_01.greybox.json` and writes PNGs to `visual_captures/original_salvage/`.

Capture the organic tileset stress-test views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-tileset-test
```

This reads `camera_tests` from `maps/cave_tileset_test_01.greybox.json` and writes PNGs to `visual_captures/tileset_test/`.

Capture the organic salvage map pass:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-organic-map
```

This reads `camera_tests` from `maps/cave_salvage_organic_01.greybox.json` and writes PNGs to `visual_captures/organic_salvage/`.

Capture the full-map sketch topology draft:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-full-sketch-map
```

This reads `camera_tests` from `maps/full_cave_sketch_01.greybox.json` and writes PNGs to `visual_captures/full_cave_sketch/`.

Capture the contiguous full level for Expansion 09 regression review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-09-full-level
```

This writes the authored `production_level_*` overview, boat, opening-gameplay, upper-left, lower-left, lower-right, and return contexts at 1280x720 and mobile 844x390 review sizes under `visual_captures/expansion_09_full_level/`. These captures are the source for the accepted `production_level_01` baseline; regeneration does not accept or replace that baseline automatically.

Capture the focused Expansion 10 regional journey review states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-10-regional-journey
```

This writes pre-fins current-promise, post-fins regional-entry, and Signal Reef pending-return frames at 1280x720 and mobile 844x390 review sizes under `visual_captures/expansion_10_regional_journey/`. It uses the authored Expansion 10 camera tests and does not accept or replace baselines.

Capture the focused Expansion 11 light-return review states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-11-light-return
```

This writes the pre-light harmonic requirement, exact incomplete light recipe, post-light 50% survey progress, and pending boat-return states at 1280x720 and mobile 844x390 review sizes under ignored `visual_captures/expansion_11_deep_harmonic_light/`. It uses the authored Expansion 11 camera tests and does not accept or replace baselines.

Capture the focused Expansion 12 pressure-return review states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-12-pressure-return
```

This writes the pre-suit warning, incomplete pressure-suit recipe, protected crossing, 50% abyssal survey, and pending boat-return states at 1280x720 and mobile 844x390 review sizes under ignored `visual_captures/expansion_12_abyssal_pressure/`. It uses the authored Expansion 12 camera tests and does not accept or replace baselines.

Capture the focused Expansion 13 southeast-wreck review states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-13-southeast-wreck
```

This writes the broad wreck promise, arrival with cutter requirement, 50% recorder cut, 50% explicit archive survey, and pending canonical-boat return states at 1280x720 and mobile 844x390 review sizes under ignored `visual_captures/expansion_13_southeast_wreck/`. It uses the authored Expansion 13 camera tests and does not accept or replace baselines.

Run the focused Expansion 13 scanner-to-cutter correction captures:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-13-scanner-cutter-correction
```

This writes broad artifact clue, off-axis miss, acquired artifact, 50% scan, pending boat return, committed cutter recipe, scanner/cutter/shock-prod selections, titanium/rubber/coil gameplay-scale samples, wrong-tool denial, 50% deliberate cutter progress, pending navigation data with held salvage, and canonical-boat commitment with the southeast lead. Every state is captured at 1280x720 and mobile 844x390 under ignored `visual_captures/expansion_13_scanner_cutter_correction/`; the command does not accept or replace baselines.

Capture the focused Expansion 14 archive-current return states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-14-archive-current-return
```

This writes the committed archive result, blocked relay current, night project
promise, passive post-build current, ordinary current identification, relay
arrival, mixed full cargo/equipment, 50% held scanner progress, and pending
boat return at 1280x720 and mobile 844x390 under ignored
`visual_captures/expansion_14_archive_current_return/`. Mobile gameplay frames
include the test controls and fail on cargo/tool overlap; the command does not
accept or replace baselines.

Capture the focused Expansion 15 expedition-planning states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-15-expedition-planning
```

This writes the alternate-highlighted night choice, build-ready pinned relay,
and next-day relay guidance at 1280x720 and mobile 844x390 review sizes under
ignored `visual_captures/expansion_15_expedition_planning/`. It does not accept
or replace baselines.

Capture the focused Expansion 16 deeper-wreck states:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-16-deeper-wreck
```

This writes matched pre-rebreather warning and protected threshold views plus
50% explicit cutter and held-scanner recorder interactions at 1280x720 and
mobile 844x390 review sizes under ignored
`visual_captures/expansion_16_deeper_wreck/`. It uses source camera and target
ids, checks HUD/touch-control separation, and does not accept or replace
baselines.

Expansion 17 uses the [focused wreck-network capture guide](expansion_17_capture.md).

Capture the first production slice:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
```

This reads `camera_tests` from `maps/production_slice_01.greybox.json` and writes six PNGs to `visual_captures/production_slice_01/`: overview, entry shaft, first route choice, central crossing, lower loop, and return-to-boat context.

Capture the first production slice with debug/review markers visible:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
```

This writes PNGs to `visual_captures/production_slice_01_debug/`. The debug overlay uses cyan source grid, white route rectangles, amber boat/extraction outlines, green entry/spawn labels, yellow salvage diamonds, and red hazard squares. Normal production-slice captures stay terrain-first and should not be overwritten with debug views.

Capture the focused current-gate review state:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-current-gate
```

This writes `visual_captures/current_gate/production_slice_01_east_current_before_fins.png` and `visual_captures/current_gate/production_slice_01_east_current_after_fins.png`. The pair frames the same standard east current before pushback is overcome and after fins make it passively swimmable; it is review evidence, not baseline acceptance.

Capture the second production slice:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-map
```

This reads `camera_tests` from `maps/production_slice_02.greybox.json` and writes five PNGs to `visual_captures/production_slice_02/`: overview, relay entry, main chamber, lower terminal, and return route.

Capture the second production slice with debug/review markers visible:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-debug-map
```

This writes the same five camera views to `visual_captures/production_slice_02_debug/`.

Capture the third production slice:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-03-map
```

This reads `camera_tests` from `maps/production_slice_03.greybox.json` and writes five PNGs to `visual_captures/production_slice_03/`: overview, relay entry, stacked rooms, connector, and return route.

Capture the third production slice with debug/review markers visible:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-03-debug-map
```

This writes the same five camera views to `visual_captures/production_slice_03_debug/`.

Capture the fourth production slice:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-04-map
```

This reads `camera_tests` from `maps/production_slice_04.greybox.json` and writes five PNGs to `visual_captures/production_slice_04/`: overview, relay entry, lower-left loop, curved corridor, and return route.

Capture the fourth production slice with debug/review markers visible:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-04-debug-map
```

This writes the same five camera views to `visual_captures/production_slice_04_debug/`.

Check that a capture directory contains every authored `camera_tests` view for a map:

```bash
python tools/check_camera_captures.py maps/production_slice_01.greybox.json visual_captures/production_slice_01
python tools/check_camera_captures.py maps/production_slice_01.greybox.json visual_captures/production_slice_01_debug
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02_debug
python tools/check_camera_captures.py maps/production_slice_03.greybox.json visual_captures/production_slice_03
python tools/check_camera_captures.py maps/production_slice_03.greybox.json visual_captures/production_slice_03_debug
python tools/check_camera_captures.py maps/production_slice_04.greybox.json visual_captures/production_slice_04
python tools/check_camera_captures.py maps/production_slice_04.greybox.json visual_captures/production_slice_04_debug
python tools/check_camera_captures.py maps/production_level_01.greybox.json visual_captures/expansion_09_full_level --camera-id-prefix production_level_ --suffix 1280x720 --suffix mobile_844x390
```

The checker reads expected PNG names from the map JSON, ignores Godot `.import` sidecars, fails on missing/extra/invalid PNGs, and reports captures that look older than the source map. It does not regenerate visual files.

Run the aggregate committed-capture check for every production slice:

```bash
python tools/check_production_slice_captures.py
```

Use the stale-file check locally after regenerating map JSON and captures in the same workspace:

```bash
python tools/check_production_slice_captures.py --fail-on-stale
```

The `Godot Smoke` workflow runs the aggregate check without `--fail-on-stale` so CI catches missing, extra, or invalid committed captures without relying on git checkout file mtimes or a display renderer.
