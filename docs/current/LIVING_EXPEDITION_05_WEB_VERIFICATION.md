# Living Expedition 05 Web Verification

Date: 2026-08-12

Issue: #1351

Status: **CORRECTED TECHNICAL PASS; OWNER VERDICT PENDING**

## Result

The corrected public Living Expedition 05 runtime initializes successfully at
the focused excavation checkpoint, starts both partners clear of collision,
exposes `Recall` and `Excavate`, and completes the dig/reveal handoff. This
verifies deployment and the corrected checkpoint boundary; it does not prove
attachment, usefulness, or another-day motivation.

- exact runtime SHA: `7792a087c4f685b104846430e9aecb90e2c2bd71`
- build version: `7792a08`
- `git_ref`: `main`
- `dirty`: `false`
- generated timestamp: `2026-08-12T23:05:31-05:00`
- [Web export and Pages run 31665877710](https://github.com/joeypshell/oceangame2/actions/runs/31665877710):
  export browser verification and GitHub Pages deployment passed
- [Godot Smoke run 31665877655](https://github.com/joeypshell/oceangame2/actions/runs/31665877655):
  source/map validation, core runtime, and regional journey jobs passed
- [Progression Audit run 31665877665](https://github.com/joeypshell/oceangame2/actions/runs/31665877665):
  progression audit passed

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh Silt Hound rescue:
  `https://joeypshell.github.io/oceangame2/?review=7792a087c4f685b104846430e9aecb90e2c2bd71&checkpoint=living_expedition_05_start`
- corrected excavation-ready handoff:
  `https://joeypshell.github.io/oceangame2/?review=7792a087c4f685b104846430e9aecb90e2c2bd71&checkpoint=living_expedition_05_excavate_ready`

## Superseded Candidate

The initial owner review of `267c5e1` found that the excavation-ready checkpoint
started the diver against solid terrain. The invalid position prevented normal
movement and made Excavate fail its runtime context checks, so the palette only
showed Recall. Generic journey/capture tests had chosen their own valid setup
positions and therefore missed the actual checkpoint defect.

Correction #1362 and PR #1363:

- moved only the checkpoint start to a verified open tile near the same mound;
- changed no map source, terrain topology, reward, or excavation behavior;
- added `smoke_living_expedition_05_checkpoint_runtime.gd`, which launches the
  actual `Main.tscn` checkpoint and checks partner collision clearance,
  four-direction diver movement, path/line context, enabled Excavate projection,
  BOND pause, and `approaching` dispatch;
- added that exact-scene smoke to the regional journey CI lane.

## Public Browser Evidence

Focused inspection of the corrected deployed checkpoint confirmed:

- the overlay reports `Build 7792a08` and the expected checkpoint id;
- diver and Marl render above the floor rather than inside terrain;
- pressing `B` displays both `1 Recall` and `2 Excavate`;
- pressing `2` closes the palette, runs the action, opens the mound, reveals the
  titanium pickup, and reports `Marl uncovered titanium scrap`;
- the checkpoint initializes at desktop and `844x390` landscape-mobile framing;
- no browser warnings or errors appeared during startup or excavation.

The merge smoke's focused output reports:

```text
PASS: Living Expedition 05 checkpoint runtime spawn=clear movement=clear
palette=recall+excavate dispatch=approaching
```

## Preserved Evidence

- `smoke_living_expedition_05_journey.gd` still protects migration, rescue,
  commitment, selection, full Excavate phases, cargo-full preservation, pickup,
  banking, restoration, duplicate prevention, and equipment gates.
- `smoke_review_checkpoint_fixture.gd` still protects isolated checkpoint
  profile boundaries.
- The focused visual decision remains a no-baseline-change decision.
- #52/#53 remain deferred optional slice-03 presentation work.

## Known Limits

- The inherited status panel remains dense, particularly on mobile.
- The rescue checkpoint preserves the real swim to Marl; use the corrected
  excavation-ready checkpoint to review the action without replaying that leg.
- Automation cannot decide whether Marl creates attachment or whether the
  payoff motivates another expedition.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_05_checkpoint_runtime.gd --review-checkpoint=living_expedition_05_excavate_ready
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_05_journey.gd --review-checkpoint=living_expedition_05_start
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_review_checkpoint_fixture.gd
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 7792a087c4f685b104846430e9aecb90e2c2bd71 --checkpoint living_expedition_05_excavate_ready
python tools/check_file_lengths.py
git diff --check
```

Issue #1351 and milestone #49 remain open for the corrected owner verdict.
