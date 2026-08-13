# Playtest Checkpoints

Last updated: 2026-08-13

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
| `living_expedition_05_start` | Day 4 at the canonical boat; Kite and Mica committed; prior required progression available; empty cargo | Marl's Cutter rescue, boat commitment, three-partner selection, and Silt Hound sortie |
| `living_expedition_05_excavate_ready` | Day 4 beside the closed lower-loop mound; Kite, Mica, and Marl committed; Marl active; empty cargo | Deliberate BOND Excavate, physical reveal, typed-material pickup, and optional return |
| `living_expedition_04_start` | Day 3 at the canonical boat; Kite and Mica committed and adapted; Mica active; Shock Prod and prior required progression available; empty cargo | Select Kite for the Guardian-Pulse eel opening, compare ordinary evade and defeat-only harvest, and verify Mica has no eel response |
| `living_expedition_03_start` | Kite and Mica committed; Mica active; prior required progression available | Mica migration observation, night consolidation, and next-sortie Read Drift |
| `living_expedition_02_start` | Prior required projects/discoveries committed; Cutter and Scanner available; Kite committed and selected; empty cargo | Mica rescue/commitment, two-partner habitat selection, Mica Reveal Trace sortie, and return to Kite |
| `living_expedition_01_start` | Prior required projects/discoveries committed; Cutter, Fins, and Shock Prod available; empty cargo; no companion | Spark Ray rescue, boat commitment, command/riding proof, shared memory, night adaptation, and Day 3 payoff |

Local:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --review-checkpoint=living_expedition_05_start
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --review-checkpoint=living_expedition_05_excavate_ready
```

The checkpoint forces `production_level_01` and identifies itself in the
review overlay. The ordinary `?review=<sha>` URL remains a completely empty,
isolated profile.

Exact public Web closeout build:

```text
https://joeypshell.github.io/oceangame2/?review=7792a087c4f685b104846430e9aecb90e2c2bd71&checkpoint=living_expedition_05_start
https://joeypshell.github.io/oceangame2/?review=7792a087c4f685b104846430e9aecb90e2c2bd71&checkpoint=living_expedition_05_excavate_ready
```

The Pages workflow, merge smoke suite, and focused desktop/mobile inspection
passed for corrected exact SHA `7792a087c4f685b104846430e9aecb90e2c2bd71`.
The earlier `267c5e1` checkpoint URL is superseded: owner review found its
excavation-ready start intersected solid terrain and suppressed Excavate.
Correction #1362 fixes that boundary and protects it with an actual-scene smoke.
Technical evidence is recorded in
[Living Expedition 05 Web Verification](LIVING_EXPEDITION_05_WEB_VERIFICATION.md).
The corrected owner retest received GO; the links remain as regression fixtures.

## Living Expedition 05 Replay

Fresh rescue:

1. Open `living_expedition_05_start`; close or leave the boat habitat, then swim
   into the lower loop to the orange-cabled juvenile Silt Hound.
2. Select the Cutter and hold `Space/USE` until Marl is free. Return together to
   the canonical surface boat to commit the rescue.
3. At the boat, press `B/BOND`, use `Tab/TOOL` to highlight Marl, and confirm
   with `Space/USE`. Leave the boat and confirm Marl follows as the active
   partner.

Excavate payoff:

1. Open `living_expedition_05_excavate_ready`; Marl and the closed mound are
   already framed together.
2. Desktop: press `B`, then `2` for Excavate. Mobile: tap `BOND`, use `TOOL` to
   select Excavate, then tap `USE`.
3. Watch whether Marl's approach, anticipation, impact, and material reveal are
   understandable without relying only on the status panel.
4. Move into the exposed titanium and confirm it becomes held cargo. Return to
   the boat only if you also want to verify normal banking.

Then answer: Did rescuing and choosing the Silt Hound make the material run
feel like a distinct partnership, and was the Excavate payoff clear and useful
enough to choose that individual for another day?

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
