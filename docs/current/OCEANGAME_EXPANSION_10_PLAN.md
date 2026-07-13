# OceanGame Expansion 10 Plan

Date: 2026-07-13

Status: Committed after player GO on planning issue #879. Implementation has not
started.

GitHub milestone: [#36 OceanGame Expansion 10: East-Current Regional
Journey](https://github.com/joeypshell/oceangame2/milestone/36)

Frozen issue batch: #880-#889

## Decision

Expansion 10 will turn the existing passive east-current promise into the first
meaningful regional journey on the promoted full level. Propulsion fins will
remain the traversal answer. After crossing the current through normal swimming,
the player will follow continuous authored geography to one recognizable
lower-right landmark, resolve one scanner-backed regional payoff, and return it
to the canonical boat.

The current pocket near the transformed opening and the distant lower-right
sector anchor are separate source facts today. This pass must connect them as a
readable journey; it must not pretend that Expansion 09 already authored the
regional experience.

## Evidence And Alternatives

- Fresh-browser review accepted `production_level_01` as the normal map after
  the boat-offload correction; the apparent arrow-key regression did not
  reproduce in an isolated browser profile.
- Source review confirms the current pocket is near the transformed opening
  while `full_level_lower_right_anchor` is a distant, reachable but sparse
  sector. Expansion 09 proved traversal between anchors, not regional meaning.
- The lower-right journey was selected because it reuses the already taught fins
  and scanner chain and matches the intended promise that the current should
  open a larger area rather than a single pickup alcove.
- An upper-left or lower-left identity pass remains valid later, but neither has
  an equally mature blocker-to-capability chain today. A new pressure or darkness
  gate would add another capability before the full level proves it can carry an
  existing one, so both remain deferred.

## Target Experience

1. Before owning fins, the player encounters the east current and understands
   that it blocks a larger route rather than only hiding a nearby pickup.
2. The existing blueprint, material, and night-project chain produces propulsion
   fins without score substituting for ingredients.
3. Fins allow passive movement through the current. No `E` prompt, teleport,
   relay, map menu, or current-stabilizer activation is used.
4. The route continues through the same `production_level_01` water space to a
   visually recognizable lower-right landmark.
5. The existing scanner resolves one authored regional target there. The result
   remains uncommitted until the player returns to the surface boat.
6. Boat commitment provides a named payoff and a broad reason to plan another
   expedition without implementing the next capability in this milestone.

The landmark and payoff names may be selected during source authoring, but they
must describe one place and one discovery rather than generic salvage volume.

## Meaningful-Change Filter

The pass succeeds only if it creates all of these:

- remembered-place progress: the current changes from blocker to route
- route meaning: crossing leads to a real region, not a tiny cache alcove
- payoff: the lower-right destination contains one useful scanner-backed result
- return pressure: the result matters only after the boat commitment journey
- tomorrow motivation: the committed result points broadly toward later work

Terrain population, more pickups, or another isolated HUD message do not satisfy
the milestone by themselves.

## Source-Of-Truth Boundaries

- `maps/full_cave_sketch_01.greybox.json` remains the topology/provenance source.
- `tools/create_production_level_01_map.py` and focused source helpers own new
  regional metadata, entities, camera tests, and any narrowly required terrain
  clearance.
- `maps/production_level_01.greybox.json` and its SVG are generated outputs. Do
  not hand-edit them or copy slice JSON into them.
- The existing east-current gate and propulsion-fins capability IDs remain
  stable unless a contract issue proves a correction is necessary.
- The upper-right current pocket and lower-right sector remain distinct named
  locations connected by an authored journey contract.
- Slices 01-04 remain unchanged regression/provenance fixtures.

## Runtime And UI Boundaries

- Reuse existing current, fins, scanner, pending-discovery, boat-commitment,
  daylight, oxygen, cargo, and night owners.
- Add only focused regional objective/feedback behavior that cannot be expressed
  by existing metadata.
- Keep progress and prompts compact. Do not redesign the full HUD.
- Do not grow `main.gd` or `greybox_world.gd` when a focused existing owner can
  handle the change.
- Preserve keyboard, WASD, touch, and current fresh-profile behavior.

## Planned Issue Batch

Dependency order:

1. #880 locks the regional journey source and experience contract.
2. #881 audits `production_level_01` directly in the progression graph.
3. #882 authors the east-current route and lower-right landmark.
4. #883 authors one scanner-backed payoff and boat-return objective.
5. #884 integrates only the focused runtime/feedback needed by that source.
6. #885 adds deterministic fresh-profile regional journey coverage.
7. #886 adds focused desktop and mobile review captures.
8. #887 compares and accepts only intentional full-level baseline changes.
9. #888 verifies the exact merged SHA on the public Web preview.
10. #889 runs the player gate and closes with GO, HOLD, or a bounded fix.

## Validation Plan

- Extend the executable progression audit to include the default full level or a
  canonical-equivalence contract; it currently loads only production slices.
- Prove the fins blueprint and required materials remain reachable before the
  current they unlock.
- Prove the current blocks an unupgraded player and permits normal swimming with
  fins.
- Prove the landmark, survey target, boat return, and all mandatory prerequisites
  are reachable with player-footprint collision.
- Preserve generated-map repeatability, map validation, reachability, source/render
  parity, and unchanged slice outputs.
- Add one integrated journey smoke from a fresh profile. Run the full release
  suite once at the integrated boundary rather than after each small issue.

## Visual And Web Plan

- Capture the pre-fins blocker, the regional transition/landmark, and the
  lower-right payoff/return context at desktop and mobile review sizes.
- Regenerate only affected `production_level_01` captures.
- Render comparison sheets before accepting baseline changes. Existing terrain,
  boat, player, opening overlay, slices, and unrelated camera views must not drift.
- Verify public build metadata against the exact merged runtime SHA, desktop and
  mobile canvas initialization, touch alignment, fresh-profile state, and the
  default `production_level_01` selection.

## Non-Goals

- no teleport, prompted connector, fast travel, or map menu
- no `E` interaction for a standard current crossing
- no current-stabilizer entry requirement
- no pressure capability or second new traversal capability
- no broad regional population or full-map content pass
- no inventory, economy, crafting-tree, or HUD overhaul
- no broad art replacement, enemy roster, or ecosystem simulation
- no slice-03 presentation work (#52/#53 remain deferred)

## Exit Criteria

Expansion 10 reaches the player gate when:

- the existing current visibly promises a larger route before fins
- the established recipe/night-project chain unlocks passive crossing
- one continuous, collision-active journey reaches a recognizable lower-right
  landmark and scanner-backed payoff
- the payoff commits only after a successful return to the canonical boat
- source, progression, smoke, visual, mobile, and Web evidence pass without
  unrelated drift

Exit question: **Did building fins turn the east current into the entrance to a
place the player remembers, and did the lower-right payoff make the return journey
and another expedition feel worthwhile?**
