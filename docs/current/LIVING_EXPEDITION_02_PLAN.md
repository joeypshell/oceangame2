# Living Expedition 02 Plan

Date: 2026-08-05

Issue: #1251 `Plan Living Expedition 02 around a two-individual stable and active choice`

Status: Completed through #1253-#1262 with owner GO.

## Decision

Living Expedition 02 will prove a compact boat habitat and a meaningful choice
between **two total individuals**:

- Kite, the implemented Spark Ray, remains the mounted mobility/protection option.
- Mica, one juvenile Veil Cuttle, becomes an independent sensing companion that
  cannot be ridden.
- Exactly one committed individual is active on a launched sortie.
- The inactive individual remains visible at the canonical boat with its name,
  species, memories, and adaptation history intact.

This is not a general roster or stable-management system. It is the smallest
proof that species identity changes preparation and that an inactive companion
still feels like someone the player will return to.

## Target Experience

The review starts from a profile with Kite committed and the Veil Cuttle still
in the world:

1. The player finds and physically aids Mica in one source-authored,
   already-accessible branch of `production_level_01`.
2. Returning together to the canonical boat commits Mica exactly once.
3. A compact habitat view shows Kite and Mica as two named individuals, not
   inventory slots.
4. At the boat, the player deliberately selects the companion for the next
   sortie. Selection cannot change in open water.
5. With Mica active, close-following cuttle movement and a deliberate
   `Reveal Trace` BOND action contrast with Kite's riding and Spark Ray actions.
6. `Reveal Trace` exposes one optional nearby ecological trace inside terrain
   the diver can already access. The scanner still identifies it; Mica does not
   grant light, pressure, current, oxygen, collision, tool, or reward access.
7. Back at the boat, both individuals remain visible. Selecting Kite for a later
   sortie restores Kite's mounted command/action set while Mica stays at home.
8. Save/reload preserves both complete records and the active selection.

The proof must be understandable without an external roster tutorial.

## Meaningful-Change Filter

The milestone is successful only if:

- Kite and Mica are recognizable from motion, controls, and field affordance,
  not merely different names or colors;
- selecting one changes the expected expedition experience;
- the boat feels more inhabited after the second commitment;
- the inactive individual remains emotionally legible without granting a
  passive global bonus; and
- the result creates curiosity about future individual development.

Do not add another clue, recipe, score cache, or generic scan solely to justify
the new species.

## Species Boundary

The Veil Cuttle is a bounded prototype species decision:

- roles: independent sensing/support only;
- ride capable: false;
- base action: `reveal_trace`;
- movement identity: close, soft hovering with short investigative excursions;
- source relationship: one rescue site, one habitat relationship, and one
  optional ecological trace in existing topology;
- growth: no new memory/adaptation tree in this milestone.

`Reveal Trace` is a deliberate BOND command with readable range, direction, and
result. It can reveal an authored trace that was visually concealed, but it
cannot scan, collect, award progression, illuminate a darkness route, or satisfy
an equipment prerequisite. This previews later ecological field roles without
implementing Living Expedition 03.

The prototype name and final art may change in a later reviewed issue; the
independent, non-mounted role and gate boundary are the milestone contract.

## Boat Habitat And Selection

- The canonical boat remains the only commitment and selection authority.
- The habitat is a compact world/presentation surface, not a full-screen roster.
- With two committed individuals, BOND at the boat opens a two-entry selection;
  existing selection/confirm inputs remain shared by desktop and mobile.
- A confirmed selection applies on the next launched sortie.
- The active individual leaves with the diver; the other remains visibly at the
  boat and receives no offscreen simulation, passive yield, or hidden care debt.
- Callsign, species, earned memories, and selected adaptation stay visible in a
  compact read-only identity summary.

The implementation may reuse the existing debrief/input routing, but it must not
add habitat ownership to `main.gd` or overload `Q`/`E` with another unexplained
mode.

## Source And State Boundaries

### Immutable source

- `config/creature_catalog.json` owns species role/action declarations.
- Generated map source owns Mica's habitat, rescue, optional trace, relationships,
  review camera, and provenance.
- No terrain topology change is expected.

### Persistent profile

- `companion_profile_state.gd` advances to schema v2 with a bounded
  `individuals` collection and one `active_individual_id`.
- Migration converts the schema-v1 Spark Ray `individual` into the collection
  exactly once without losing callsign, memories, or adaptation.
- Rescue commitment, identity, memories, adaptation, and active selection are
  persistent; position and live mode are not.

### Live runtime

- Only the selected individual is instantiated for a launched sortie.
- Follow mode, target, command state, cooldowns, presentation, and movement stay
  transient.
- Kite-specific adaptation owners remain focused; do not force Mica through
  mounted or Spark-specific branches.
- A small species/runtime factory may select the correct scene/controller, but
  avoid a broad behavior framework before two concrete species prove the need.

### Presentation

- Boat habitat/selection projects profile state and emits a selection request;
  it does not mutate saves directly.
- Dive HUD and BOND palette show only actions supported by the active species.
- Mica must not show Mount; Kite must retain its existing mounted hotbar.

## Planned Issue Batch

1. Lock Living Expedition 02 source, state, habitat, selection, and failure
   contracts.
2. Extend catalog/schema validation and migrate companion profile state to two
   bounded individuals.
3. Implement the compact canonical-boat habitat and next-sortie active selection.
4. Author the Veil Cuttle rescue, habitat, trace, and review camera through the
   map source/generator path.
5. Implement Veil Cuttle presentation, follow identity, and deliberate
   `Reveal Trace` action.
6. Integrate species-specific sortie instantiation, BOND actions, guidance,
   failure/reset, and save/reload while preserving Kite behavior and gates.
7. Add deterministic two-individual journey, migration, selection, isolation,
   and progression-audit coverage.
8. Add focused desktop/mobile habitat, selection, Mica, and Kite-return captures
   and record the intentional visual decision.
9. Verify the exact public Web build, checkpoint, touch controls, and stable
   unchanged areas.
10. Run the owner closeout and record GO, HOLD, or bounded corrections.

## Validation Plan

Focused validation must prove:

- schema-v1 profiles migrate with no Spark Ray loss;
- duplicate ids, unknown species, invalid active ids, over-capacity collections,
  and species/action mismatches fail;
- Mica's rescue and trace are reachable with guaranteed diver capabilities;
- neither species bypasses equipment, collision, oxygen, daylight, health,
  cargo, boat, or failure authority;
- only the active individual enters a sortie;
- selection cannot change away from the boat;
- full cargo does not delete a pending rescue;
- failure/retry clears transient state but preserves committed individuals and
  active selection;
- old Living Expedition 01 rescue, riding, memory, and both adaptation paths
  remain green; and
- the generated progression graph contains the new relationships without a
  required circular dependency.

Run focused checks per issue and the full integrated journey/release suite once
the runtime, source, and evidence surfaces are assembled.

## Visual And Web Plan

- Create only the Veil Cuttle and compact habitat assets needed for the proof.
- Do not regenerate the world, terrain, player, boat, Spark Ray, or broad HUD.
- Capture boat habitat before/after commitment, selection of each individual,
  Mica following, Reveal Trace, and Kite restored on a later sortie at desktop
  and landscape-mobile sizes.
- Compare all accepted baselines before any acceptance decision.
- Verify the exact merged Web SHA, named checkpoint, touch alignment, and browser
  error surface before owner review.

## Non-Goals

- third species, large stable, scrolling roster, storage catalog, or party UI
- two active companions or mid-sortie switching
- Veil Cuttle riding
- new memory/adaptation tree for Mica
- passive stable bonuses, feeding chores, breeding, fusion, eggs, lineage,
  injury, death, or offscreen simulation
- broad ecology/research framework or multiple hidden-trace targets
- new equipment, recipe, economy, inventory, enemy, map expansion, or topology
- accepted-baseline sweep or broad art/HUD replacement

## Exit Criteria

Technical readiness requires the full two-individual journey, migration,
failure, gate, capture, and exact-Web checks to pass.

The owner gate asks:

> Did choosing between Kite and Mica feel like choosing two recognizable
> partners for different expeditions, did the inactive individual still matter
> at the boat, and did that choice make another day more interesting?

Do not create Living Expedition 03 or a third species until this receives GO.
Use bounded corrections for clarity or identity problems rather than expanding
the roster.
