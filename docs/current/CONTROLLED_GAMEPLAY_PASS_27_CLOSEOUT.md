# Controlled Gameplay Pass 27 Closeout

Date: 2026-07-09

Issues: #602-#610
Milestone: Simple Diver Game 07 `Presentation And Game Feel`

## Result

Pass 27 completed the player movement/facing readability pass selected by the #591 Milestone 07 release-readiness audit.

The reported direction-change flash is now addressed as a rendering/facing-state problem rather than a movement-tuning problem. The player root stays stable, the body sprite clips to the active swim-sheet frame, body/light facing alignment is covered by repeated-reversal smoke, and a focused review capture exists for local visual inspection.

## Behavior Changed

- `Body.region_filter_clip_enabled` is enabled for the player body sprite so only the active swim frame is visible during flips.
- The player-facing report exposes the body sprite clipping flag for smoke coverage.
- `--smoke-pass-27-facing-transitions` drives repeated left/right reversals and verifies root scale, body flip, light cone alignment, active frame, clipping, and reset facing state.
- `--capture-pass-27-player-facing` frames the default production slice player after deterministic reversals for review.

## Intentionally Unchanged

- Movement speed, acceleration, deceleration, collision, camera, input actions, oxygen, cargo, salvage, hazard, objective, result, map, and route semantics.
- Player art source pixels and broad animation structure.
- Production-slice maps, terrain, accepted baselines, visual captures, and generated map previews.
- #52 and #53 remain deferred optional slice-03 polish.

## Visual And Web Decisions

- `docs/current/PASS_27_PLAYER_FACING_VISUAL_BASELINE_DECISION.md` records that no production-slice baseline acceptance was needed.
- `python tools/manage_production_slice_baseline.py compare-all` produced no accepted/current differences for production slices 01-04.
- `python tools/manage_production_slice_baseline.py check-clean --all-slices` reported all accepted baseline dirs clean.
- `docs/current/PASS_27_PLAYER_FACING_WEB_PREVIEW_VERIFICATION.md` records public Web verification for deployed commit `dcfa188a06af3c98c900875b29fc2744e0fff32d`.
- The public preview initialized at `1280x720` and `1920x1080`, matched build metadata, and emitted no missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages.

## Verification

Commands run across the pass:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-movement-feel
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-27-facing-transitions
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-27-player-facing
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha dcfa188a06af3c98c900875b29fc2744e0fff32d
python tools/check_file_lengths.py
git diff --check
```

## Remaining Blockers

- #611 should refresh the release-readiness blocker list now that Pass 27 has landed.
- Manual local review can still be used to sanity-check the feel of repeated direction changes, but deterministic smoke/capture coverage now exists for future regressions.
- Broader presentation polish, audio systems, inventory/loadouts, save systems, enemy AI, procedural generation, economy expansion, broad art replacement, and full-map productionization remain out of scope until selected by a roadmap issue batch.

## Next Direction

Resolve #611 next. After the blocker refresh, choose one small Milestone 07 follow-up only if it materially improves release readiness; otherwise move toward Simple Diver Game 08 release-candidate preparation.
