# Visual Captures

`visual_captures/latest/` contains generated screenshots from the current default preview map, currently `maps/cave_salvage_organic_01.greybox.json`.

`visual_captures/original_salvage/` contains generated screenshots from the original rectangular salvage map for comparison.

`visual_captures/tileset_test/` contains generated screenshots from the organic cave tileset stress-test map.

`visual_captures/full_cave_sketch/` contains generated screenshots from the supplied full-map sketch topology draft.

`visual_captures/production_slice_01/` contains generated screenshots from the first focused production slice.

`visual_captures/route_outcome/` contains a focused generated screenshot of the completed route-outcome result panel for Controlled Gameplay review.

`visual_captures/hazard_pressure/` contains a focused generated screenshot of the selected Pass 07 hazard/navigation pressure state for Controlled Gameplay review.

`visual_captures/route_extension/` contains a focused generated screenshot of the selected Pass 08 route-extension state for Controlled Gameplay review.

`visual_captures/pass_13_route_commitment/` contains a focused generated screenshot of the Pass 13 deep-cache route objective while the timed salvage interaction is in progress.

`visual_captures/pass_14_objective_cue/` contains a focused generated screenshot of the Pass 14 start-of-run objective cue at the boat/extraction area.

`visual_captures/pass_15_objective_follow_through/` contains a focused generated screenshot of the Pass 15 in-route objective-follow-through cue before collecting `salvage_lower_loop`.

`visual_captures/primary_dive_completion/` contains a focused generated screenshot of the Pass 16 primary dive completion result panel after banking the required objective targets.

`visual_captures/pry_salvage/` contains a focused generated screenshot of the Pass 17 pry salvage interaction with staged progress visible.

`visual_captures/pass_18_progression/` contains a focused generated screenshot of the Pass 18 wallet and oxygen tank upgrade feedback after banking enough salvage and purchasing at extraction.

`visual_captures/pass_19_cargo_upgrade/` contains a focused generated screenshot of the Pass 19 wallet and cargo capacity upgrade feedback after banking enough salvage and purchasing at extraction.

`visual_captures/pass_20_light_upgrade/` contains a focused generated screenshot of the Pass 20 wallet and light upgrade feedback after banking enough salvage and purchasing at extraction.

These captures are not automatically approved baselines. They are review artifacts used to compare the current in-engine result against `visual_baselines/` and the art direction docs.

Preview captures include the compact review overlay with map id, build label, and salvage progress.

Regenerate named camera captures with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-camera-tests
```

The named views come from `camera_tests` in the current default preview map.

Regenerate original salvage comparison captures with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-original-map
```

Those named views come from `camera_tests` in `maps/cave_salvage_test_01.greybox.json`.

Regenerate tileset stress-test captures with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-tileset-test
```

Those named views come from `camera_tests` in `maps/cave_tileset_test_01.greybox.json`.

Regenerate full-map sketch draft captures with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-full-sketch-map
```

Those named views come from `camera_tests` in `maps/full_cave_sketch_01.greybox.json`.

Regenerate first production-slice captures with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-production-slice-map
```

Those named views come from `camera_tests` in `maps/production_slice_01.greybox.json`.

Regenerate the focused route-outcome result capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-route-outcome-result
```

This capture completes a deterministic route-tagged collect-return run and is a review artifact, not an accepted baseline by itself.

Regenerate the focused Pass 07 hazard/navigation pressure capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-07-hazard-pressure
```

This capture frames the selected warning-only route pressure state near `hazard_right_branch` and is a review artifact, not an accepted baseline by itself.

Regenerate the focused Pass 08 route-extension capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-08-route-extension
```

This capture frames `southwest_return_pocket_extension` with the player and `salvage_southwest_return_cache`, and is a review artifact, not an accepted baseline by itself.

Regenerate the focused Pass 13 route-commitment capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-13-route-commitment
```

This capture frames the deep-cache objective with lower-loop cargo held, timed salvage progress visible, and is a review artifact, not an accepted baseline by itself.

Regenerate the focused Pass 14 objective-cue capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-14-objective-cue
```

This capture frames the boat/extraction start context with `Objective: Deep cache 0/2` visible, and is a review artifact, not an accepted baseline by itself.

Regenerate the focused Pass 15 objective-follow-through capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-15-objective-follow-through
```

This capture frames `deep_cache_first_step_cue` with `Objective route: Lower loop` visible before collecting `salvage_lower_loop`, and is a review artifact, not an accepted baseline by itself.

Regenerate the focused primary dive completion capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-primary-dive-completion
```

This capture frames the completed primary objective result panel after banking the required deep-cache targets, and is a review artifact, not an accepted baseline by itself.

Regenerate the focused pry salvage capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pry-salvage
```

This capture frames `salvage_pry_locker` with staged pry progress visible, and is a review artifact, not an accepted baseline by itself.

Regenerate the focused Pass 18 progression capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-18-progression
```

This capture frames the extraction area with wallet spend and `O2 tank upgraded` feedback visible, and is a review artifact, not an accepted baseline by itself.

Regenerate the focused Pass 20 light upgrade capture with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-20-light-upgrade
```

This capture frames the extraction area with wallet spend, `Light +range upgraded` feedback, and the upgraded light cone visible, and is a review artifact, not an accepted baseline by itself.
