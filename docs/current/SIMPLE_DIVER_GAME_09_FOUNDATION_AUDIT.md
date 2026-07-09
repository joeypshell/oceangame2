# Simple Diver Game 09 Foundation Audit

Date: 2026-07-09

Issue: #645
Milestone: Simple Diver Game 09 `2D Subnautica Expansion Planning`

## Verdict

The release candidate is a sound expansion foundation, but its proven behavior should be treated as a stable product boundary rather than a place to keep appending orchestration code.

The strongest reusable asset is the complete source-to-runtime validation loop: authored/generator-owned JSON, reachability validation, Godot parity, deterministic smokes, focused captures, controlled baselines, and Web verification. The main growth risk is concentrated ownership in `main.gd` and `greybox_world.gd`, plus several capture/smoke files already at the 500-line limit.

## Evidence

- Simple Diver Game 08 closeout: GO, with no release-candidate blockers.
- `python tools/run_release_candidate_validation.py --list`: 28 gates covering hygiene, assets, captures, baselines, maps, Godot import/startup/parity, the core loop, release journey, progression, and facing transitions.
- `python tools/check_file_lengths.py`: no non-allowlisted oversized files.
- Temporary debt: `scripts/main/main.gd` at 2,175 lines and `scripts/world/greybox_world.gd` at 1,088 lines.
- `main.gd`: 92 functions spanning boot/load, run state, oxygen, hazards, cargo, progression, objectives, connectors, overlay/result presentation, parity, and argument dispatch.
- `greybox_world.gd`: 99 functions spanning source loading, runtime entity state, path queries, collision/parity, renderer delegation, and debug geometry.
- Near-limit helpers: `capture_controller.gd` at 500 lines; three smoke helpers at 497 lines; another smoke helper at 491 lines.

## Foundation Classification

| Area | Classification | Expansion rule |
| --- | --- | --- |
| JSON map/generator ownership | Preserve | Extend schemas and generators before runtime consumers; never hand-author topology in Godot scenes. |
| Reachability and entity validation | Preserve | Add narrow rules with each new source concept and keep intended areas reachable from authored entries/returns. |
| Godot terrain/collision parity | Preserve | New world work must keep source, rendered terrain, and collision cells in agreement. |
| Focused production slices | Extend carefully | Add or connect a bounded authored area only for a selected experience outcome. Do not productionize the whole sketch. |
| World connectors | Extend carefully | Preserve explicit map/entry IDs and destination-local reset behavior; reconcile persistence rules before growth. |
| Core expedition loop | Preserve | Oxygen, cargo, salvage, return, result, failure, and retry remain the legible frame for expansion. |
| Timed/pry interactions | Extend carefully | Reuse interaction semantics where they create route decisions; do not turn them into a generic tool framework prematurely. |
| Session progression | Extend carefully | Current wallet/upgrades remain stable until the persistence contract decides what, if anything, survives sessions. |
| Objectives/result presentation | Preserve | New content must use source-authored goals and compact result hierarchy rather than a broad quest system. |
| Static/moving hazard semantics | Extend carefully | Reuse deterministic warning/contact/reset behavior as the baseline for any bounded fauna candidate. |
| Deterministic smokes | Preserve | Add one focused domain smoke per behavior; keep the release-journey smoke as the integration floor. |
| Focused captures | Preserve | Add captures only for visible review decisions and place new capture owners below 500 lines. |
| Accepted visual baselines | Preserve | Compare before acceptance; unrelated terrain/player/boat/prop/camera drift remains a failure. |
| Web export/Pages checker | Preserve | Every visible/runtime expansion pass must verify metadata, canvas initialization, requests, and Godot errors. |
| `main.gd` orchestration | Refactor before growth | New persistent/world/content domains need focused owners instead of more state and update branches in this file. |
| `greybox_world.gd` coordination | Refactor before growth | New entity families or world-state queries need an extracted source/runtime owner before they are added. |
| Near-limit capture/smoke helpers | Refactor before growth | Split by domain before adding another capture or smoke to a file already near the policy ceiling. |
| Full-sketch direct production | Retire/defer | Keep it as topology/planning source; derive bounded production sources through generators. |
| Comparison maps and prototype-only review paths | Retire/defer | Keep them for regression/reference use, but do not make them the expansion default or duplicate new gameplay into them. |
| Broad generated art replacement | Retire/defer | Continue named asset changes and review sheets; do not regenerate the scene as a style pass. |

## Ownership Risks

### Main Runtime Shell

`main.gd` currently combines application orchestration with expedition state, oxygen/hazard updates, cargo/progression transactions, objective/result text, connectors, review UI, and command-line dispatch. Existing focused controllers are useful seams, but the remaining shell is still the default destination for cross-domain state.

Before adding persistence, discoveries, equipment/resources, or fauna state, extract the selected domain behind a narrow API. `main.gd` should coordinate that owner and update presentation, not store a second copy of its rules.

### World Coordinator

`greybox_world.gd` successfully delegates terrain, collision, background, props, extraction, route markers, visibility, and asset lookup. It still owns source parsing, runtime entity dictionaries, path queries, collection state, zone lookup, parity reporting, and debug-shape compatibility helpers.

Before adding a new source entity family, extract either source/entity indexing and runtime state, or world query/path responsibilities, according to the selected expansion outcome. Do not split arbitrary line ranges; preserve public query behavior and parity.

### Test And Capture Capacity

The capture controller is exactly 500 lines, while route/progression/interaction smoke helpers are close to the ceiling. Expansion checks should be added to new domain files and registered by existing dispatch, not appended to full helpers.

## Smallest Technical Prerequisites

The first implementation batch should include only prerequisites required by its selected player-facing outcome:

1. Name the source/runtime/state contract before code or map changes.
2. Extract one focused owner from `main.gd` if the outcome introduces persistent, equipment/resource, discovery, or fauna state.
3. Extract one focused source/query owner from `greybox_world.gd` if the outcome introduces a new world entity family or world-state query.
4. Add schema validation before authoring source data.
5. Author through the established generator/source path and verify reachability/parity before screenshots.
6. Put new deterministic smoke and capture logic in new sub-500-line domain files.
7. Keep the full release-candidate runner green, then add only the focused gate needed for the new outcome.

These are gates, not a mandate to refactor both oversized files before any progress. The selected outcome should pay for the smallest ownership extraction it actually needs.

## Explicitly Stable During Planning

- gameplay behavior, command-line flags, and default map selection
- map JSON, generators, terrain, collision, and camera tests
- visual/audio assets, captures, and accepted baselines
- release-candidate smokes, validation runner, workflows, and public preview
- #52/#53 deferred slice-03 polish status

## Verification

```powershell
python tools/check_file_lengths.py
python tools/run_release_candidate_validation.py --list
git diff --check
```
