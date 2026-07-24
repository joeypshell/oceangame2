# Playtest Checkpoints

Last updated: 2026-07-24

## Purpose

Named checkpoints shorten focused player review without weakening progression
ownership. A checkpoint seeds one reviewed milestone boundary in memory through
the same profile transactions used by gameplay. It never reads, deletes, or
writes the normal durable profile.

Use a checkpoint to review the feature that just changed. Use a fresh profile
for occasional full-journey review, and keep deterministic journey smokes as
the routine end-to-end regression layer.

## Current Checkpoint

| ID | Starts with | Deliberately incomplete |
| --- | --- | --- |
| `expansion_14_start` | Earlier projects and discoveries complete; southeast archive and recorder committed; Ti2 + Coil1 banked | Current Stabilizer build, advanced-current crossing, relay core, relay survey, and boat commitment |

Local:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --review-checkpoint=expansion_14_start
```

Verified public Web candidate:

```text
https://joeypshell.github.io/oceangame2/?review=ddbf5f776b61daef3cfff29040cf40b3cb1c417b&checkpoint=expansion_14_start
```

The checkpoint forces `production_level_01` and identifies itself in the
review overlay. The ordinary `?review=<sha>` URL remains a completely empty,
isolated profile.

The current candidate includes the bottom active-tool hotbar, top passive
equipment strip, visible Northwest Wreck Relay, held scanner progression with
a target-local readout, and readable Shock Prod hit/miss feedback. Checkpoint
progression semantics are unchanged.

Public verification passed for exact SHA `ddbf5f776b61daef3cfff29040cf40b3cb1c417b`
in [Godot Web Export run 30127311508](https://github.com/joeypshell/oceangame2/actions/runs/30127311508).
The independent checker confirmed the checkpoint marker, full-level map,
fresh-profile fallback, retained slice fallback, viewport framing, mobile touch
alignment, and clean browser/resource startup.

## Current Owner Replay

1. Build the Current Stabilizer and pass through the left advanced current by
   swimming; no `E` interaction is expected.
2. Find the visible Northwest Wreck Relay, equip Scanner, and hold `Q/USE`.
   Releasing the input or switching tools must cancel partial progress.
3. Aim the Scanner at ordinary subjects and confirm the temporary local card
   identifies them without awarding progression.
4. Use the Shock Prod against the eel and confirm forward miss/fizzle feedback,
   connected-hit bolt, eel health, recoil separation, cadence, and defeat.
5. Confirm passive upgrades appear under top `EQUIPPED` slots while Scanner,
   Cutter, and Shock Prod remain in the bottom active-tool hotbar.

## Guardrails

- Checkpoints are named, reviewed fixtures, not arbitrary save injection.
- Seed durable state only through `ExpansionProfileState` transactions and
  source-authored project definitions.
- Leave the feature under review incomplete.
- Keep normal saves isolated and unknown checkpoint ids on a fresh fallback.
- Add a focused deterministic smoke and Web startup assertion for each new
  checkpoint.
- Do not use checkpoints as evidence that the full journey is fun or clear.

## Review Rhythm

1. Play the active checkpoint after a player-facing change.
2. Report the first unclear or broken step.
3. Let focused smokes cover the corrected owner and CI cover the full journey.
4. Run a fresh-profile player journey at milestone closeout or when progression
   order itself changes.
