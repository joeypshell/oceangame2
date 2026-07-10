# Simple Diver Game 09 Expansion Planning Closeout

Date: 2026-07-09

Roadmap status: historical planning closeout. Later owner decisions supersede its immediate territorial-eel sequencing; use `docs/planning/OCEANGAME_PHASE_2_ROADMAP.md` for active direction.

Issue: #652
Milestone: Simple Diver Game 09 `2D Subnautica Expansion Planning`

## Decision

GO from expansion planning to one bounded implementation milestone:

```text
OceanGame Expansion 01: Anomaly Survey Foundation
```

Issues #662-#671 implement the smallest coherent step beyond the Simple Diver Game 08 release candidate: follow the existing final-dive signal, unlock one scanner, travel from slice 04 to adjacent slice 02, survey one authored anomaly, return across the known route, and commit one discovery.

Milestone 09 is planning-complete. No gameplay, map, profile, scanner, fauna, asset, capture, baseline, workflow, or Web runtime change was made by #643-#652.

## Accepted Experience

The first expansion is an anomaly-survey expedition, not a feature catalog.

```text
final-dive lead -> one preparation unlock -> remembered route -> anomaly survey
-> risky return -> one durable discovery -> next lead
```

The release-candidate oxygen, cargo, salvage, hazards, connectors, progression, objectives, result, failure, retry, capture, baseline, and Web behavior remain the foundation.

## Accepted World Shape

Use an explicit source-authored connector graph:

```text
production_slice_01 <-> production_slice_04 <-> production_slice_02
```

- Slice 01 remains the default surface boat hub and public preview.
- Slice 04 remains the remembered relay route and final-dive-signal source.
- Slice 02 becomes the bounded anomaly destination because it is adjacent to slice 04 in full-sketch coordinates and already has validated relay, route, parity, capture, and baseline coverage.
- The full sketch remains topology/planning source, not a seamless runtime map.
- Slice 03 is not selected; #52/#53 remain deferred.

No new terrain topology is required for Expansion 01 unless implementation reproduces a separate reachability blocker.

## Accepted State Model

- Map-leg oxygen, cargo, salvage, hazards, objectives, and interaction progress keep current reset/load behavior.
- Session wallet, current upgrades, opened progression containers, and best scores remain session-only.
- One pending anomaly discovery may cross connectors during the return journey.
- Reset, hazard restoration, or oxygen failure clears uncommitted discovery.
- Canonical slice-01 boat return commits one discovery exactly once.
- The minimal profile stores schema version, completed discovery IDs, and selected capability IDs only.
- No world-persistent depletion, fauna, placed objects, or arbitrary node state is introduced.

## Accepted Tool And Resource Model

- Add one profile capability: `survey_scanner_1`.
- Unlock it once at the boat using the existing session wallet; an already-unlocked profile never pays twice.
- Add one non-salvage `survey` interaction with continuous in-range progress, leave-range cancel, oxygen drain, and compact feedback.
- Survey completion creates pending discovery, not cargo or direct score.
- Existing instant, timed, and pry salvage remain unchanged.
- No inventory, equipment slots, loadouts, batteries, charges, consumables, material stacks, recipes, or crafting UI.

## Fauna Decision

The territorial eel contract is accepted as the first bounded fauna candidate, but it is Phase B and is not part of Expansion 01 Foundation.

The survey state, map link, return path, failure cleanup, smoke, and visual review must prove stable before the source-authored `idle -> warning -> fixed lunge -> return -> cooldown` encounter is layered onto the anomaly approach.

No combat, health, loot, spawning, pathfinding, pursuit, or ecosystem simulation is selected.

## Architecture Gates

Expansion 01 starts with two no-behavior extractions:

1. Move progression purchase/overlay/result wrappers out of `main.gd` before scanner/profile growth.
2. Move world query/path/reachability helpers out of `greybox_world.gd` before survey/fauna queries.

Additional rules:

- `main.gd` and `greybox_world.gd` must not grow.
- New profile, expedition, survey, smoke, and capture owners stay under 500 lines.
- The 500-line capture controller and 491-497-line smoke helpers are closed to expansion additions.
- Source contract/validation precedes generator authoring, which precedes runtime.
- Focused capture and baseline decisions precede Web closeout.
- The 28-gate release-candidate runner remains the regression floor.

## Resolved Contract Questions

### Profile Capability With Session Wallet

The scanner is the only profile unlock in Expansion 01. It may be purchased with current session wallet because the unlock itself is durable and idempotent; wallet and existing upgrades do not become persistent.

### Cargo Reset With Cross-Map Discovery

Connector travel continues to reset map-leg cargo/oxygen/objectives. Pending discovery is a separate expedition-state token and is the only new cross-map payload.

### Return Commitment

Surveying at slice 02 is not success. The discovery commits only after the player returns through slice 04 to the slice-01 boat, preserving expedition tension and remembered-route value.

### Fauna Timing

The territorial eel is deferred to Phase B. Adding reactive pressure before the survey/return state is deterministic would combine too many failure sources in the first implementation batch.

## Expansion 01 Issue Order

1. #662 plan the anomaly-survey foundation implementation pass.
2. #663 extract progression runtime wrappers from `main.gd`.
3. #664 extract world query/path helpers from `greybox_world.gd`.
4. #665 add survey source schema and validator coverage.
5. #666 implement profile and expedition discovery state ownership.
6. #667 author slice-04/slice-02 connectors and the anomaly target through generators.
7. #668 implement scanner unlock and survey/return runtime.
8. #669 add deterministic anomaly journey smoke and CI coverage.
9. #670 add focused captures and the visual baseline decision.
10. #671 verify public Web deployment and close Expansion 01.

Issues #663/#664 are no-behavior prerequisites. #665 may proceed after the plan, but source authoring waits for both the schema and world-query extraction. Runtime waits for source and state owners. Visual/Web work waits for deterministic smoke.

## Expansion 01 Exit Criteria

- The existing final-dive lead points to a playable survey follow-up.
- The scanner unlock is affordable, one-time, profile-backed, and readable.
- Slice-04/slice-02 travel is source-authored, bidirectional, reachable, and parity-clean.
- Survey progress, cancel, no-cargo completion, pending state, failure cleanup, return, commit, and reload are deterministic.
- The complete release journey remains green.
- Focused captures communicate the survey and committed result without unrelated baseline drift.
- Public Web preview serves the intended commit without failed requests or Godot errors.
- Closeout decides whether Phase B territorial fauna is the next meaningful step.

## Explicitly Deferred

- territorial eel implementation until Expansion 01 closeout
- slice-03 integration and #52/#53 polish
- additional tools, survey targets, destinations, connectors, resources, or fauna
- inventory/crafting, persistent wallet/economy, base building, vehicles, combat, ecosystem AI, procedural generation, broad biomes, full-map productionization, and broad art/audio replacement

## Verification

```powershell
gh issue list --state open --limit 100
python tools/check_file_lengths.py
git diff --check
```
