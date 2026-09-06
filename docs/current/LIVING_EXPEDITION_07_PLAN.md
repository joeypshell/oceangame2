# Living Expedition 07: Marl's Root Claws

Date: 2026-09-06

Status: Selected planning contract from #1387, not implemented. The latest
owner-approved runtime remains LE06 at `16300a9`. The implementation milestone
and numbered batch have not been created; the outline below is not an active queue.

## Decision

Deepen Marl before adding another individual or implementing release. Prove one
shared event, **Guarded the Nest**, that becomes **Root Claws** at night and a
deliberate **Ground Pin** on the next sortie. Marl remains independent-only.

| Candidate | Evidence and decision |
| --- | --- |
| Marl's first adaptation | Selected. Kite and Mica already grow; Marl's implemented catalog has no memories/adaptations. A physical dig-to-protection arc advances raising the same individual. |
| Growth, Release, And Habitat Legacy | Keep directional. LE06 proves remembered habitat change, but does not establish that surrendering an individual is meaningful. First develop the third companion; this is sequencing, not an in-game release prerequisite. |
| Vein Whiskers | Defer. Better direction/confidence risks another subtle detector, repeating the Mica readability and usefulness failures. No passive yield/stat bonus substitutes for a tangible action. |
| Root Claws | Select one bounded ground-control branch. Walking/digging fins become a visible planted grip, not a magic stun or Kite pulse recolor. Reject the proof if existing geometry cannot support physical contact without a combat rewrite. |

LE04's HOLD requires an action that changes an outcome rather than describes
danger. LE05's checkpoint correction requires real-scene clearance and command
tests. LE06's GO supports continuity, not a claim of measured long-term attachment.
Evidence: [LE04](LIVING_EXPEDITION_04_CLOSEOUT.md),
[LE05](LIVING_EXPEDITION_05_CLOSEOUT.md), [LE06](LIVING_EXPEDITION_06_CLOSEOUT.md).

## Target Experience

1. Select already-rescued Marl at the canonical boat. His six walking fins and
   existing Excavate are unchanged; a nearby burrow group scrabbles at a blocked
   soft-silt refuge while the familiar deep-cache eel threatens the approach.
2. Command Excavate on that refuge. Marl physically digs while the diver draws
   and evades one real eel warning/lunge cycle away from the entrance. The group
   visibly retreats into the opened refuge; this outcome, not the input, matters.
3. See a brief Marl-specific acknowledgement and return together to secure
   `guarded_the_nest`. A pending field memory is not yet saved growth.
4. At night, deliberately choose Root Claws or **not tonight**. Broader hooked
   fin tips and a low planted posture accompany an explanation of the new action.
5. Next sortie, draw the same eel low over the remembered floor and command
   Ground Pin. Marl plants and visibly grips it, giving the diver a short opening
   for one Shock Prod hit or retreat. He releases and resumes following.

The reason to choose Marl tomorrow is ground-based protection plus digging.
Kite provides a quick aimed recoil/recovery opening and riding; Marl holds a
near-floor target stationary but must stop travelling or excavating to do it.
Neither supplants the diver's weapon, health decisions, or equipment.

## Meaningful-Change Filter

- Qualify only with active committed `silt_hound_juvenile_01`, a completed
  physical refuge dig, one source-bound live warning/lunge cycle during that
  attempt, and the burrow group reaching shelter with the pair still present.
- A finished LE05 titanium dig, ordinary pickup, generic scan, time in a zone,
  or repeated Excavate never earns this memory. Repeated commands cannot stack
  progress or refresh a qualifying attempt.
- The existing eel still targets the diver. Passive burrow wildlife reads its
  snapshots; add no prey-target AI, wildlife injury, death, or material harvest.
- A quiet/defeated-eel visit may open shelter but does not fabricate a threat
  memory. An uncommitted opportunity resets on the normal next day, when the eel
  normally returns. Never revive it early or require wildlife to take damage.
- No extra score/cache/recipe reward. The payoff must remain worthwhile because
  of what Marl does, not a completion number or another locked destination.

## Source And Access Boundaries

Use unchanged `production_level_01` topology and its existing
`lower_loop_to_deep_cache_pressure` approach, `deep_cache_dark_pocket`, and
`deep_cache_territorial_eel`. Its territory is `(118,71,10,8)` and home is
`(124,74)`; existing solid floor spans cells `x=118..123` at `y=79`.
The open band above that floor is the candidate refuge/anchor region, not an
approved collider placement. Source authoring must prove full actor footprints,
eel contact reach, a real swim approach, and a return route before runtime work.
Do not carve terrain or teleport the eel to make a fixture pass.

Proposed immutable ids, to be locked by the source/state issue:

| Relationship | Proposed id / responsibility |
| --- | --- |
| Burrow group and refuge | `deep_cache_burrow_refuge_01`: bounded passive burrow scallops, closed/open shelter presentation, clear approach and grounded interaction point |
| Shared event | `marl_guarded_nest_opportunity_01`: links that refuge, existing eel, Marl, qualifying cycle, memory, and return promise |
| Adaptation response | `deep_cache_eel_marl_ground_pin`: links existing hostile to Marl's learned action and validated ground anchors; does not alter territory or cache locks |
| Catalog growth | `guarded_the_nest` -> `root_claws` -> `ground_pin`, allowed only for Silt Hound |

The graph starts from Marl's existing Cutter rescue, canonical-boat commitment,
and active selection. Declare Dive Light for this dark-pocket opportunity and
Shock Prod for its intended armed review; neither is a new recipe or a lock on
the existing cache. The current darkness marker is visual-only: do not silently
turn it into terrain collision. Existing Fins, pressure, oxygen, health, cargo,
and route checks remain authoritative wherever the approach uses them.

Compose a focused transform from `tools/create_production_level_01_map.py`.
Generate JSON and SVG; never hand-place Godot geometry or edit generated JSON.
Guarantee the opportunity on every supported seed and fresh eligible day, with
no dependence on optional materials, Root Claws, or defeating its own threat.
Preserve `silt_hound_rescue_01` at `(52,75)`,
`silt_hound_buried_titanium_01` at `(97,80)`, its normal daily material rules,
`salvage_deep_right_cache`, and all LE06 Signal Reef relationships.

## Profile And Night Ownership

Reuse catalog validation, `CompanionProfileState` schema v3, and its one
`selected_adaptation_id` per individual. Do not introduce a growth tree or a
profile-version bump merely to add catalog ids.

- A focused Marl event owner holds attempt flags and pending memory together
  with the individual id. Do not put them into the Spark-Ray-specific memory
  controller or attribute them to whichever individual is selected later.
- Canonical-boat return calls the existing profile commit/save boundary once.
  Full cargo never blocks memory; ordinary material offload remains unchanged.
- Failure, Retry, abandoned attempts, or reload discard uncommitted field state.
  Committed memory and confirmed adaptation survive these operations.
- Derive the refuge's lasting sheltered state from Marl's committed memory.
  No additional persistent nursery subsystem or mutable map fields are needed.
- Extend `companion_adaptation_debrief.gd` with one eligible Root Claws option.
  Deferred consolidation leaves the memory available. Repeated confirm/reload
  cannot duplicate the adaptation; profiles without this memory offer nothing.
- Root Claws is the only offered Marl branch in LE07. Vein Whiskers is not a
  second selectable option or an invented lock. The current single-slot contract
  precludes stacking; future alternate branches/respec need their own plan.

## Runtime And Controls

Extend focused Silt Hound control/action/presentation owners, not `main.gd`.
Reuse physical approach/dig phases through a small result boundary: the existing
deposit still reveals a material, while the refuge releases a passive group.
Do not retarget LE05's hardcoded deposit or duplicate its mutable action state.

Ground Pin's starting proof contract:

- Deliberate command only, with learned Root Claws, a valid nearby floor anchor,
  clear approach/contact geometry, and the existing live eel in warning or lunge.
  Approach must physically reach it; never home through walls or snap it down.
- Marl visibly plants and grips within reach. Hold at most **1.75 seconds**;
  impose **8 seconds** cooldown after release. A whiff does not freeze a target.
  Both timing values are gameplay time and freeze during the BOND pause.
- While held, the hostile owner suspends movement/attack/contact for that target.
  No damage, defeat, harvest, current immunity, or protection from other hazards.
- Release on timeout, Recall, separation, lost anchor/line of sight, any weapon
  hit, failure, reload, or teardown. Restore the existing recovery path, never a
  stale mid-lunge velocity/contact. No refresh, stacking, or permanent stun.
  A weapon hit releases first, then keeps normal damage/recoil/defeat handling.
- Cancel an approach without applying a hold if its target becomes invalid.
  Marl cannot Excavate and pin concurrently. Existing movement/collision owners
  determine both approach and follow recovery.
- `territorial_hostile_controller.gd` remains the sole owner of eel position,
  phase, health, and contact. Add a narrow bounded support-hold request/release
  boundary; do not repeatedly call the recoil-based Guardian Pulse interruption
  or let companion presentation write hostile state. Shock Prod owns damage.

Keep toggle `B/BOND`, desktop `1`-`3`, and sequential mobile `BOND/TOOL/USE`.
At most Recall, contextual Excavate, and learned Ground Pin appear. Keep reasons
such as "eel too high", "approach blocked", and cooldown visible on denial.
No new key, held chord, riding, or companion item in the diver hotbar.

## Presentation And Review Boundary

Show a physical shelter blocked with soft silt, a visible dig/open/retreat event,
and Marl's fin grip changing next day. Contrast the same unadapted/adapted action
at the same camera: no pin before night, obvious contact/hold/release afterward.
Keep useful short acknowledgement and night explanation; avoid another long
instruction chain, directional bubble, or full-screen overlay.

Only Marl's named adaptation/action visuals and the small refuge group may
change. Terrain, diver, boat, Kite, Mica, materials, and LE06 nursery stay stable.
No broad art generation or baseline acceptance is authorized by this plan alone.

## Ordered Issue Outline

Create these scoped issues only after #1387's planning PR merges, at the next
batch boundary. Numbers and a GitHub milestone must be recorded then.

| Order | Deliverable | Dependencies / focused evidence |
| --- | --- | --- |
| 1 | Lock and validate catalog/event/ground-response schema and source/state contract | Plan; negative schema and non-circular progression fixtures |
| 2 | Author refuge, event, floor anchors, and review cameras through the generator | 1; seed guarantees, unchanged terrain, clearance/reachability/parity |
| 3 | Implement refuge Excavate outcome and meaningful pending event | 2; actual dig + live threat + sheltered group, cancellation, no farming; retain LE05 material path |
| 4 | Commit Marl memory and offer deliberate Root Claws at night | 3; exact-once boat/night/reload, full cargo, wrong-individual and failure tests |
| 5 | Implement physical Ground Pin and bounded hostile hold lifecycle | 2,4; contact/denial/release/cooldown, weapon interruption, no damage or gate bypass |
| 6 | Make refuge/growth/pin legible and add real-scene isolated checkpoints | 3-5; existing controls, spawn/follow/command clearance, short before/after route |
| 7 | Add deterministic full Marl growth journey and integrate regression coverage | 1-6; one combined integration/release run, not a full suite per prior issue |
| 8 | Review focused desktop/mobile visuals and exact deployed Web build | 7; compare baseline sheets, inspect actual checkpoint/input, record exact SHA |
| 9 | Record owner experience verdict and next-step evaluation | 8 plus owner test; no automatic GO from automation, no next milestone in resolver run |

The highest-risk split is issue 5: interrupt/cancel ownership across a moving
hostile and a planted companion. Keep one authoritative hostile state machine
and a focused hold lifecycle, not a generalized status-effect/combat framework.

## Validation Strategy

- Per issue: affected owner checks, file-length audit, and `git diff --check`.
  Source work also runs generator repeatability, map validator, parity, and the
  progression audit. No full runtime suite for documentation-only edits.
- Integrated journey: base Marl cannot pin; actual event -> boat -> optional
  night choice -> next-sortie pin -> hit/release/retreat; exact-once persistence,
  seeded guarantee, full cargo, defeated eel, failure, and reload boundaries.
- Retain LE05 rescue/dig/material and LE06 nursery journeys, Kite's pulse and
  Mica's ecology roles, active selection, equipment gates, and diver survival.
- Launch each isolated checkpoint through `Main.tscn`: collision-clear spawns,
  four-direction swimming, companion separation/recovery, real BOND dispatch,
  mobile selection, and a whole-simulation pause including eel and hold timers.
- Render only refuge, memory/night, and before/after pin states at desktop and
  landscape-mobile sizes. Compare all accepted sheets before any explicitly
  authorized acceptance; do not commit generated captures or `.import` sidecars.
- Verify public build metadata, initialization, and the actual review journey
  against the integration SHA. Record technical evidence separately from the
  owner verdict; provide a checkpoint that avoids replaying all progression.

## Deferred Work And Exit

No fourth bondable species, release/retirement, forced loss, breeding, XP,
economy, equipment chain, topology expansion, general ecosystem simulation,
creature health/death, or broad combat framework. #52/#53 remain deferred polish.

Owner exit question: **Did helping the burrow group make Marl's changed body and
next-day ground protection understandable and useful enough to choose him for
another expedition, rather than feel like another task or weaker Kite button?**
Judge from the event and one short before/after return. If the pin is unclear,
too fiddly, redundant, or requires a larger combat rewrite, record HOLD and the
specific failed experience; do not pad or silently broaden this milestone.
