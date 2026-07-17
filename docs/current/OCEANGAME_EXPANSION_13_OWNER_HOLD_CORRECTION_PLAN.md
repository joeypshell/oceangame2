# OceanGame Expansion 13 Owner-HOLD Correction Plan

Date: 2026-07-17

Planning issue: #1000

Player gate: #969

## Decision

Expansion 13 remains at **HOLD** after the project owner's review of exact
runtime `89371d6`. The earlier scanner-to-cutter correction fixed discovery
causality, but the playable loop still has three bounded failures:

- rubber and conductive-coil pickups do not read as their materials
- cutter use starts automatically from proximity while scanner and shock prod
  use unrelated buttons
- the first sealed-wreck return pays only ordinary `+300` salvage value and
  does not durably advance the southeast journey

Issues #1000-#1009 correct those failures inside milestone #39. Do not select
Expansion 14 or add the broader economy during this work.

The five-unfamiliar-player requirement is not a blocker at this prototype
stage. Owner playtesting plus deterministic technical validation is the gate;
outside playtests remain valuable at larger product milestones.

## Target Experience

1. The diver's owned active equipment appears in one compact tool slot.
2. `Tab` cycles scanner, salvage cutter, and shock prod while skipping unowned
   tools. Mobile exposes the same cycle action.
3. `Q` uses the selected tool. Mobile exposes the same use action.
4. Selecting the scanner emits its existing deliberate forward cone.
5. Selecting the cutter and pressing use near a valid target begins the timed
   cut. Proximity alone never advances it.
6. Selecting the shock prod and pressing use performs the existing attack.
7. Fins, tanks, light, pressure suit, and other always-on upgrades remain
   passive and never occupy the active slot.
8. Rubber reads as bundled/rolled elastomer and coil reads as a spring or wound
   conductor at gameplay scale.
9. Opening the remembered sealed wreck yields valuable salvage plus pending
   southeast navigation data.
10. Boat return banks the salvage and commits the data exactly once, then
    reveals the broad deep-southeast lead.

## Meaningful-Change Filter

This correction serves the roadmap north star because it:

- makes tools intentional rather than automatic
- improves recognition and planning around recipe materials
- turns a remembered-place return into durable map progress
- gives the player a reason to launch the next expedition

It does not qualify as permission for a full inventory, crafting tree, economy,
new region, weapon tier, or map expansion.

## Planned Issue Batch

1. #1000 plan and source/state contract
2. #1001 active-tool selection and input actions
3. #1002 scanner/cutter/shock-prod integration
4. #1003 compact tool HUD and testing mobile controls
5. #1004 readable rubber and conductive-coil material sprites
6. #1005 source-authored sealed-wreck navigation-data reward
7. #1006 pending/boat-committed reward runtime and southeast lead
8. #1007 focused and integrated deterministic coverage
9. #1008 desktop/mobile review captures
10. #1009 controlled baseline and exact-SHA Web review
11. Return to #969 for the owner replay

The issue set is frozen. Follow-up findings stay out unless they block these
exit criteria.

## Source-Of-Truth Boundaries

- Active-tool rules live in runtime helpers and input actions, not map data.
- Material identity already lives in source `material_id`; the material
  renderer maps that identity to a named visual without changing placement.
- Sealed-wreck reward metadata lives in
  `tools/production_level_01_scanner_artifact.py`, which regenerates the full
  production JSON. Generated JSON is not hand-edited.
- The southeast journey reads its prerequisite from generated source data.
- Terrain, collision, spawn, boat, routes, cameras, and slices 01-04 remain
  unchanged.

## Runtime And UI Boundaries

- A small active-tool controller owns selection, capability filtering, cycling,
  and use dispatch.
- Existing scanner, cutter, and shock-prod owners retain their domain logic.
- A cutter use press activates the existing timed interaction; staying in range
  continues it, while leaving range, switching tools, failure, or reset cancels
  it under the established contract.
- The HUD adds one compact selected-tool control. It is not an inventory screen.
- The mobile testing overlay replaces separate `SCAN` and `HIT` controls with
  `TOOL` and `USE` actions.
- Existing automation flags remain stable unless a focused new flag is added.

## Reward And Economy Boundary

The sealed wreck has two distinct outcomes:

- **salvage value:** the existing valuable cargo and `+300` bookkeeping value
- **progression:** `southeast_wreck_navigation_data`, pending until canonical
  boat return and then durable in the profile

Materials remain consumed by recipes. Blueprints and discoveries unlock
possibilities. Salvage value is not spendable currency in this correction.
A future credits contract may convert banked generic value into money for
services, consumables, research, or boat improvements, but credits must not
replace authored discoveries or recipe materials.

## Validation And Smoke Plan

- focused active-tool ordering, ownership, cycle, and normalization checks
- scanner, cutter, and shock-prod use/wrong-tool checks
- proximity-only cutter denial and timed cancellation checks
- material visual identity checks without map/source changes
- generator repeatability, full-level validation, progression audit, parity,
  and unchanged terrain signature
- pending data failure restoration, boat commitment, exact-once profile reload,
  and southeast prerequisite checks
- one integrated fresh-profile correction journey at the batch boundary
- existing scanner, cutter, combat, cargo, failure, and Web regressions

## Visual And Capture Plan

Focused captures show:

- each active tool selected at desktop and mobile sizes
- wrong-tool denial and selected-cutter progress
- titanium, rubber, and coil together at gameplay scale
- sealed-wreck salvage/data pending, boat commitment, and southeast lead

Compare the full-level baseline before accepting anything. Only material
sprites, compact tool presentation, and intentional reward text may change.
Slices 01-04, terrain, collision, boat, diver, cameras, lighting, and unrelated
props remain fixed.

## Deferred Work

- spendable credits, shops, pricing, selling UI, or economy balance
- inventory grid, tool durability, batteries, ammunition, tool upgrades, or
  quick-slot loadouts
- controller bindings beyond reserving action ownership
- broad HUD replacement or production icon suite
- additional wrecks, regions, enemies, weapons, materials, or map topology
- optional slice-03 polish #52/#53

## Exit Criteria

Return to #969 only when the owner can identify rubber and coil, deliberately
select and use scanner/cutter/shock prod through one control model, open the
sealed wreck only after an explicit cutter action, bring its navigation data
back to the boat, and understand that the new southeast lead is progression
while `+300` is secondary salvage value.

Exit question: **Did selecting and using the cutter feel intentional, and did
the wreck reward create a clear reason to launch the next expedition?**
