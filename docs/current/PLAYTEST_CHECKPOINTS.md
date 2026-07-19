# Playtest Checkpoints

Last updated: 2026-07-19

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

Public Web candidate:

```text
https://joeypshell.github.io/oceangame2/?review=<sha>&checkpoint=expansion_14_start
```

The checkpoint forces `production_level_01` and identifies itself in the
review overlay. The ordinary `?review=<sha>` URL remains a completely empty,
isolated profile.

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
