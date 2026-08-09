# Playtest Checkpoints

Last updated: 2026-08-08

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
| `living_expedition_04_start` | Day 3 at the canonical boat; Kite and Mica committed and adapted; Mica active; Shock Prod and prior required progression available; empty cargo | Companion-shaped territorial-eel approach, defeat-only harvest, and owner verdict |
| `living_expedition_03_start` | Kite and Mica committed; Mica active; prior required progression available | Mica migration observation, night consolidation, and next-sortie Read Drift |
| `living_expedition_02_start` | Prior required projects/discoveries committed; Cutter and Scanner available; Kite committed and selected; empty cargo | Mica rescue/commitment, two-partner habitat selection, Mica Reveal Trace sortie, and return to Kite |
| `living_expedition_01_start` | Prior required projects/discoveries committed; Cutter, Fins, and Shock Prod available; empty cargo; no companion | Spark Ray rescue, boat commitment, command/riding proof, shared memory, night adaptation, and Day 3 payoff |

Local:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --review-checkpoint=living_expedition_04_start
```

The checkpoint forces `production_level_01` and identifies itself in the
review overlay. The ordinary `?review=<sha>` URL remains a completely empty,
isolated profile.

Exact public Web candidate:

```text
https://joeypshell.github.io/oceangame2/?review=ce6f23f2fd72939de40bfa78c70d7344da00de46&checkpoint=living_expedition_04_start
```

The Pages workflow and independent desktop/mobile checker passed for exact SHA
`ce6f23f2fd72939de40bfa78c70d7344da00de46`. Technical evidence is recorded in
[Living Expedition 04 Web Verification](LIVING_EXPEDITION_04_WEB_VERIFICATION.md).
The owner verdict remains issue #1323; automation does not decide whether the
encounter is understandable or motivating.

## Living Expedition 01 Replay

1. Select the Cutter and hold `Space/USE` at the trapped juvenile Spark Ray;
   return together to the canonical surface boat to commit the bond.
2. On the following sortie, press `B`, then `1` to mount; move as the Spark Ray,
   use `Tab/TOOL` and `Space/USE` for creature actions, then dismount and confirm
   diver tools return.
3. Earn either `held_the_flow` against the authored current or `stood_ground`
   through the territorial eel cycle, then return to the boat.
4. End Night 2, deliberately consolidate the matching adaptation, and begin
   Day 3.
5. Confirm the selected adaptation has a readable independent and mounted
   payoff without bypassing the diver's equipment gates.

The retained `expansion_14_start` fixture remains available for targeted legacy
regressions, but it is no longer the current owner checkpoint.

## Living Expedition 02 Replay

1. Find Mica in the accessible upper-west chamber, select the Cutter, and hold
   `Space/USE` to free her; return together to the canonical boat.
2. Press `B` at the boat, use `Tab/TOOL` to choose Mica, and confirm with
   `Space/USE`; leave the boat to launch the Mica sortie.
3. Near Mica's authored trace, press `B`, then `2` for `Reveal Trace`; identify
   the revealed evidence with the Scanner. It grants no cargo or access.
4. Return to the boat, select Kite for the next sortie, and confirm Kite's
   Mount action and mounted hotbar return.

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
