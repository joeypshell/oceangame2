# OceanGame Expansion 14 Plan

Date: 2026-07-18

Status: Selected planning direction through #1029. This document does not
create an implementation milestone or issue batch. A later direction audit may
create one bounded batch from the order below.

## Decision

OceanGame Expansion 14 is **Archive Current Return**.

The committed southeast wreck archive will reveal how to stabilize one
advanced current. At night, that knowledge unlocks the existing
`current_stabilizer_project` with its established Ti2/Coil1 recipe. On a
later day, the durable stabilizer permits normal swimming through one
source-authored current at the eastern approach to the underused upper-left
sector of the continuous `production_level_01`.

Beyond the current, one recognizable Northwest Wreck Relay will provide a
valuable relay core and an explicit scanner survey. The finding remains pending
until the canonical boat and leaves one broad deeper-network lead.

This is not a new traversal system. It turns the archive's unresolved promise
into one remembered-place return using a capability owner that already exists.

## Target Experience

1. The southeast archive finding commits at the boat and names unstable current
   harmonics in the distant wreck network.
2. The night project surface exposes Current Stabilizer only after that
   discovery. Existing banked materials count; held cargo cannot be spent.
3. The player banks Ti2 and Coil1, then builds the project once during night
   debrief.
4. On a later day, the player returns through the same continuous map to a
   visible current that previously pushed them back toward the central route.
5. The stabilizer works passively. The player swims through normally; no
   `E` prompt, connector, teleport, or map load is involved.
6. A distinct wreck relay landmark makes the upper-left destination readable.
7. A valuable relay core uses normal cargo rules, while `Q/SCAN` records the
   relay finding even when cargo is full.
8. Unbanked cargo and pending knowledge survive only according to established
   failure rules. The canonical boat banks and commits each result exactly once.
9. The committed result names a deeper wreck relay still transmitting without
   selecting Expansion 15.

## Meaningful-Change Filter

The milestone must create:

- a direct payoff for the archive's unresolved next lead
- a night-built capability that changes access to remembered geography
- a visible before/after current boundary, not a hidden metadata lock
- a recognizable upper-left place with a useful cargo and knowledge payoff
- material gathering, cargo pressure, daylight, oxygen, and boat return in one
  understandable expedition chain
- a compact held-cargo surface that clarifies what is at risk before banking
- one reason to begin another day after the relay finding commits

A HUD-only pass, free pickup, prompted transition, relocated old cache, longer
timer, or decorative wreck does not satisfy the milestone.

## Locked Journey Contract

Stable ids, locked in
`docs/current/OCEANGAME_EXPANSION_14_SOURCE_STATE_CONTRACT.md`:

- prerequisite discovery: `southeast_wreck_archive_discovery`
- project: `current_stabilizer_project`
- capability: `current_stabilizer`
- recipe: `titanium_scrap: 2`, `conductive_coil: 1`
- prerequisite project: `salvage_cutter_project`
- route: `upper_left_wreck_relay_route`
- current gate: `upper_left_wreck_relay_current`
- landmark: `upper_left_wreck_relay_landmark`
- valuable cargo: `upper_left_wreck_relay_core`
- survey: `upper_left_wreck_relay_survey`
- discovery: `upper_left_wreck_relay_discovery`
- commit entry: `surface_boat_entry`
- next lead: `Next lead: deeper wreck relay still transmitting`

The canonical full-level project uses
`southeast_wreck_archive_discovery` as its knowledge prerequisite. The
legacy slice/provenance project may retain `lower_right_anomaly_discovery`;
it must not redefine the canonical chain. Profiles that already own
`current_stabilizer` remain valid and are never downgraded.

## Source-Of-Truth Boundaries

- `maps/full_cave_sketch_01.greybox.json` remains topology/provenance.
- A focused `tools/production_level_01_expansion_14.py` helper should own the
  project override, current, route, landmark, relay core, survey, cameras, and
  review questions.
- `tools/create_production_level_01_map.py` composes that helper.
- `maps/production_level_01.greybox.json`, its SVG, and review renders remain
  generated outputs.
- Collision-aware player-footprint analysis supersedes the provisional broad
  eastern approach, which has a second entrance. The current belongs in the
  single interior relay-pocket throat at `x=53, y=57, w=3, h=4`, pushes left
  at strength `3.2`, and isolates the player-clear pocket from `(56, 57)`
  through `(60, 60)` when blocked. `full_level_upper_left_anchor` remains a
  sector review anchor, not the capability boundary.
- The current pushes an unequipped diver back toward the central route and
  permits ordinary two-way swimming after the capability is owned.
- The relay landmark and payoff stay in existing open water inside that pocket,
  around tile `(60, 60)`. Do not alter terrain, collision, map bounds, boat
  entry, or slices 01-04.
- A source-authored route relationship must connect archive discovery,
  project, gate, landmark, survey, discovery, and boat commitment. Do not infer
  progression from coordinates or presentation text.

## State And Runtime Boundaries

- Map metadata owns the canonical prerequisite, target gate, route, payoff,
  and commit relationships.
- `ExpansionProfileState` remains the durable owner of committed discoveries
  and `current_stabilizer` capability.
- The existing material-project runtime remains the sole night-build owner.
  The project builds exactly once and never spends held cargo.
- `SortieState` retains oxygen, salvage cargo, failure, and offload ownership.
  The material runtime retains held typed materials and boat deposits.
- The current controller reuses passive pushback and capability checks. Do not
  add an activation key, charge meter, placement mode, or second stabilizer
  system.
- The relay core uses normal valuable-cargo capacity and restoration semantics.
  Cargo-full feedback must not delete or complete it.
- The scanner keeps explicit `Q/SCAN`, leave-range cancellation, full-cargo
  operation, pending feedback, and exact-once boat commitment.
- Hazard, oxygen, combat defeat, reload, and day transitions must not duplicate
  the core, discovery, project, or capability.

## Bounded Held-Cargo Strip

The first held-cargo strip belongs in Expansion 14 because the stabilizer recipe
asks the player to gather and protect specific materials.

- Show current-sortie held cargo only: material/special-component icons,
  valuable salvage, compact counts, and used/available capacity.
- Use a stable top-center strip with existing named item assets and readable
  fallbacks. Empty slots may remain subtle.
- Keep active-tool selection in its existing owner and on a distinct surface.
  It may be repositioned only enough to avoid overlap; tool behavior and input
  do not change.
- Keep persistent vitals/objectives at the edge and temporary prompts
  contextual. Banked profile inventory remains in the project/debrief surface.
- Verify desktop and landscape-mobile layouts, including touch controls.

This is not an inventory grid, drag/drop system, item-use bar, equipment screen,
banked-resource ledger, minimap, or full HUD replacement. Food, Water, and
Power are not introduced.

## Validation And Smoke Plan

- regenerate `production_level_01` twice and prove deterministic output
- validate schema, source provenance, water-only gate bounds, unchanged terrain
  and collision, player-footprint reachability, and direct boat return
- extend the progression audit so the archive has an outgoing project and the
  relay discovery becomes the new canonical terminal stage
- prove the canonical archive prerequisite while retaining the legacy slice
  fixture and already-owned profile compatibility
- prove blocked pre-project traversal and passive post-project two-way travel
- prove exact Ti2/Coil1 night spending, exact-once capability ownership, reload,
  and no held-cargo spending
- prove core cargo-full safety, failure restoration, explicit scan behavior,
  pending return, and exact-once boat commitment
- prove the cargo strip matches held material/salvage state and clears only
  through established banking/restoration paths
- keep existing current, material-project, archive-return, progression, slice,
  and release smokes green
- run the complete release suite once after integrated journey and HUD work,
  then use focused checks for later visual/documentation issues

## Visual And Deployment Plan

Capture only the affected full-level states:

- archive result and stabilizer project promise
- upper-left approach blocked without the stabilizer
- the same approach traversable after the night build
- relay arrival with its landmark and bounded cargo strip
- partial scanner progress and pending boat return
- desktop and landscape-mobile overlap checks

Compare against accepted full-level baselines before changing them. Accept only
intentional current, relay, payoff, and bounded HUD differences. Keep terrain,
player, boat, existing landmarks, camera behavior, and slices unchanged.
Verify the merged candidate's exact SHA on the public Web preview before the
owner gate.

## Active Issue Batch

The frozen milestone batch is:

1. #1031 lock the source, state, and presentation contract
2. #1032 validate canonical progression and legacy compatibility
3. #1033 author the current, route, relay, survey, and review source
4. #1034 integrate runtime journey and canonical-boat semantics
5. #1035 add the bounded held-cargo strip
6. #1036 add deterministic coverage and run the integrated release suite
7. #1037 add focused desktop and landscape-mobile captures
8. #1038 review and accept only intentional baseline changes
9. #1039 verify the exact merged candidate on the public Web preview
10. #1040 run the owner journey and close with GO, HOLD, or one correction

Dependency order: #1031 -> #1032 -> #1033 -> #1034 -> #1035 -> #1036 ->
#1037 -> #1038 -> #1039 -> #1040.

## Deferred Work

- no terrain expansion, loaded interior, connector, teleport, map menu,
  shortcut, or fast travel
- no new tool, weapon, enemy, material type, recipe, oxygen tier, pressure tier,
  or score requirement
- no broad economy, inventory, crafting grid, production HUD, final art/audio,
  vehicle, save expansion, or ecosystem simulation
- no change to the legacy slice current gate beyond compatibility protection
- no slice-03 presentation work; #52/#53 remain deferred
- no closure of #849 inside this gameplay milestone

## Exit Criteria

Expansion 14 reaches its player gate when the committed archive clearly unlocks
one exact night project, the existing stabilizer visibly changes access to the
upper-left wreck relay without a transition or terrain edit, held cargo is
readable and honestly at risk, the core and pending survey obey established
failure/boat semantics, and source, progression, smoke, visual, mobile, and
exact-SHA Web evidence all agree.

Exit question: **Did the archive clue, night-built stabilizer, visible current,
and Northwest Wreck Relay feel like one place I earned access to, with a payoff
clear enough to make me begin and finish another expedition?**
