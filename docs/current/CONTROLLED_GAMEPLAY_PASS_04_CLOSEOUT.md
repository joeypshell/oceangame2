# Controlled Gameplay Pass 04 Closeout

Date: 2026-07-07

Issue: #148 `Add Pass 04 backlog closeout and next-step evaluation`
Planned pass: `docs/current/CONTROLLED_GAMEPLAY_PASS_04_PLAN.md`

## Result

Controlled Gameplay Pass 04 is complete. The pass made the default `production_slice_01` expedition loop more readable and more replayable without expanding scope into economy, upgrades, enemies, procedural maps, save files, inventory screens, or broad art replacement.

The pass stayed within the source-of-truth workflow:

- route decisions are authored in map JSON metadata and validated by tooling/smoke tests
- runtime behavior uses salvage metadata and current run state, not scene-local hand edits
- visual review used targeted captures and baseline comparison instead of regenerating the whole scene
- public Web preview verification checked deployed build metadata and browser initialization

## What Landed

- Route metadata and validation: #130, #131, #132, #141, #142
- Score, cargo, result, and retry pressure: #133, #134, #135, #136, #137
- Hazard and oxygen pressure: #138, #139, #140, #143
- Route outcome/result readability: #144, #145
- Visual/Web review and closeout: #146, #147, #148

## Current Prototype State

The default slice now supports a small expedition loop with:

- source-authored safe and deep route metadata
- a safe route that stays oxygen-comfortable
- a deeper route that pays more and shows `LOW`/`CRITICAL` oxygen pressure
- two-slot cargo pressure
- tier-derived salvage score
- completion-only oxygen bonus
- per-map session best score
- compact run result panel with route outcome
- hazard warning before contact
- hazard oxygen penalty and held-cargo drop/reset behavior
- deterministic smokes for route metadata, route comparison, cargo, scoring, hazard pressure, oxygen pressure, result text, and player facing

The latest accepted visual state remains stable:

- normal `production_slice_01` captures showed no drift after Pass 04 runtime/UI work
- focused route-outcome capture shows the completed result panel
- public Pages preview serves runtime commit `088a608` and initializes without missing-resource or Godot errors

## Remaining Goal Gaps

The prototype is still not at the larger OceanGame-style goal. The main remaining gaps are:

- Map scale: the default playable experience is still one focused slice, not a multi-region expedition or connected larger map.
- Interaction depth: salvage is still mostly instant pickup/return; there is no tool use, timed action, cutting, hauling, scanning, or environment manipulation.
- Encounter depth: hazards are pressure/reset markers, not moving threats or authored encounter patterns.
- Progression: score and session best exist, but there is no upgrade economy, persistent unlocks, or loadout choice.
- Production art: terrain and core props are readable, but background, salvage variants, hazards, and UI remain prototype-quality.
- Validation coverage: current smokes are strong for the default route loop, but future mechanics need the same source/schema/smoke discipline before map scale increases.

## Next Focus Decision

The next pass should focus on moment-to-moment interaction, not broad map scale yet.

Reasoning:

- Pass 04 already gives the current slice route choice, pressure, payoff, and result feedback.
- Expanding to a much larger map now would mostly create longer swimming routes with the same instant-pickup verb.
- A small new in-cave interaction gives future larger maps something meaningful to place, validate, and tune.
- Art polish should follow a chosen interaction target so visual work supports a real gameplay read.
- Validation debt should be handled inside the interaction pass rather than split into abstract cleanup.

Map scale should come after one more meaningful verb proves it can be authored in source data, rendered clearly, validated, smoked, captured, and deployed.

## Recommended Next Issue Shapes

Create a focused Controlled Gameplay Pass 05 batch around one authored salvage interaction:

1. Plan Controlled Gameplay Pass 05 around a timed or tool-like salvage interaction.
2. Add map schema and validator support for interaction metadata on salvage, such as `interaction: instant | timed_salvage`.
3. Implement one timed salvage interaction with compact progress feedback and cancel behavior.
4. Author one timed valuable salvage target in `production_slice_01` source data and regenerate/validate previews.
5. Add deterministic smoke coverage for timed salvage collect, cancel, cargo banking, oxygen pressure, and reset/failure restoration.
6. Add a focused timed-salvage review capture without replacing accepted baselines.
7. Review visual baseline impact and verify public Web preview after the interaction pass.
8. After the interaction pass, evaluate whether the next pass should extend map scale by connecting a second authored route or selecting a larger production slice.

Keep #52 and #53 deferred unless the selected goal shifts back to slice-03 presentation. They are still useful slice-03 polish tasks, but they do not unblock the default route-pressure loop or the next interaction pass.

## Verification

Closeout is documentation-only. Verification for this closeout:

```powershell
git diff --check
```
