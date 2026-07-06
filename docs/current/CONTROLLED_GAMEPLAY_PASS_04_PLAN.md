# Controlled Gameplay Pass 04 Plan

Date: 2026-07-06

## Decision

Controlled Gameplay Pass 04 should make the current expedition loop easier to read and more worth replaying. The pass should stay centered on `production_slice_01` and should build on the existing scored salvage, two-slot cargo, oxygen, result panel, and expanded route-choice smoke.

This pass should not add a full economy, upgrades, enemies, procedural maps, save files, health system, inventory screen, or whole-scene visual replacement.

## Target Experience

The player should be able to:

1. Understand which pickups belong to the safer route and which belong to the deeper route.
2. See why a deep route is riskier: lower oxygen margin, hazard pressure, and full cargo return.
3. Get clearer feedback when cargo is full, when salvage has meaningful value, and when hazards are nearby.
4. Return to the boat and see a result that explains score, route outcome, oxygen margin, and best-session progress.
5. Retry with a concrete goal: beat the current session best or choose a different route.

## Meaningful Change Filter

Issues in this pass should create at least one of:

- pressure
- payoff
- route readability
- remembered-place progress
- a reason to retry
- better validation of the source-authored route contract

Pure polish, broad refactors, and optional slice-03 work stay out of this pass unless they directly support the playable route-pressure loop.

## Planned Issue Batch

- #129 `Plan Controlled Gameplay Pass 04 around route readability and replay pressure`
- #130 `Add route-choice metadata schema to map spec and validator`
- #131 `Use route-choice metadata in expanded route smoke`
- #132 `Add deterministic route-choice metadata smoke to CI`
- #133 `Add session best score to expedition result loop`
- #134 `Add oxygen return bonus to run scoring`
- #135 `Show score breakdown in expedition result panel`
- #136 `Add cargo-full feedback to nearby salvage interaction`
- #137 `Add collection feedback for salvage tier and score`
- #138 `Add hazard proximity warning before contact`
- #139 `Add oxygen penalty for hazard hit`
- #140 `Add hazard pressure smoke for warning and oxygen penalty`
- #141 `Add authored safe-route metadata for production slice 01`
- #142 `Add safe-versus-deep route comparison smoke`
- #143 `Tune oxygen thresholds for safe and deep route readability`
- #144 `Add route outcome text to result panel`
- #145 `Add focused route-outcome visual capture`
- #146 `Review and accept Pass 04 route-pressure visual baseline`
- #147 `Verify public Web preview after Pass 04 route-pressure pass`
- #148 `Add Pass 04 backlog closeout and next-step evaluation`

## Source-Of-Truth Boundaries

- Map and route-label changes must start in `tools/create_production_slice_map.py` or validated JSON source, then regenerate `maps/production_slice_01.greybox.json` and `references/greybox/production_slice_01.svg` when source data changes.
- Collision remains renderer/source-derived.
- Route-choice smokes should read machine-readable metadata instead of hard-coded entity ids wherever practical.
- Runtime score, cargo, oxygen, and route-outcome behavior should use authored salvage metadata and current run state, not scene-local node edits.
- Visual changes should be limited to compact UI/status/capture work unless a separate controlled visual issue explicitly approves asset work.

## Deferred Work

- #52 `Tune production slice 03 camera framing` remains optional slice-03 presentation polish.
- #53 `Clean production slice 03 topology artifacts in source generator` remains optional slice-03 source cleanup.
- Neither #52 nor #53 should be pulled into this pass unless the selected goal shifts back to slice-03 presentation.

## Verification Pattern

Use focused checks as the pass lands:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
python tools/check_asset_manifest.py
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expanded-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-cargo-capacity
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-interaction
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

Add more specific smoke flags as route metadata, best score, oxygen bonus, hazard warning, hazard penalty, and safe-versus-deep route comparison become deterministic.
