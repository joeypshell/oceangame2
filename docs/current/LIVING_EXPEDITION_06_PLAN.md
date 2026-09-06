# Living Expedition 06 Plan

Date: 2026-08-13

Status: Completed with owner GO on 2026-09-06; retained as the implemented
contract. See [closeout](LIVING_EXPEDITION_06_CLOSEOUT.md).

Planning issue: #1364

## Decision

Living Expedition 06 is **Signal Reef Nursery**, one bounded regional return
journey for the already-bonded Spark Ray, Kite.

The existing Signal Reef route becomes a living place rather than another
clue-and-cache destination. A visible school of juvenile filter skates is being
displaced inside the reef by the same current and hazard language the player
already understands. Kite's selected adaptation creates one of two deliberate,
immediately legible ways to shelter the school:

- **Anchor Fins:** brace in the source-authored current context so the school
  gathers in Kite's lee and reaches the nursery.
- **Guardian Pulse:** deliberately interrupt a source-authored nonlethal
  jellyfish pressure cycle so the school crosses to the nursery.

Both routes protect the same habitat. Neither changes access, grants score or
cargo, or claims that one adaptation is universally better. Returning to the
canonical boat commits the shared regional history. On the following day, a
revisit shows the nursery occupied and reacting to Kite, providing the payoff
and the reason to return.

The two approaches use existing open-water lanes that converge on Signal Reef:
Anchor Fins addresses a current interaction beside
`lower_right_east_current_gate`; Guardian Pulse addresses a non-damaging
jellyfish pressure cycle beside the west approach without disabling
`lower_right_west_current_gate`. Propulsion Fins remain required at both gates.

## Why This Proof

Three current-roster candidates were compared:

| Candidate | Strength | Reason not selected |
| --- | --- | --- |
| Kite at Signal Reef | Existing region, two accepted mutually exclusive adaptations, current ecology, mounted/independent identity | Selected; directly tests whether a build changes a remembered place |
| Mica in another migration | Strong existing ecology ownership | Risks repeating Living Expedition 03's reveal/identify/read loop and the passive-information failure from Living Expedition 04 |
| Marl in a larger silt basin | Clear physical material relationship | Risks repeating Living Expedition 05 as broader prospecting before Marl has an adaptation choice |

Signal Reef is already the source of `held_the_flow`, the Anchor Fins payoff,
and a remembered fins/light route. Deepening that relationship is more useful
than adding a fourth species or another generic destination.

## Target Experience

1. At the boat, the selected Kite's history points toward visible changed
   behavior at Signal Reef; no abstract reward marker is created.
2. The diver reaches the lower-right reef through normal contiguous geography.
3. Propulsion Fins own current access and the Dive Light owns readable travel
   in the dark pocket. Riding or commands bypass neither requirement.
4. The player sees the filter-skate school and its pressure before receiving a
   compact local action prompt.
5. The available Kite adaptation produces one deliberate field action and an
   immediate physical school response.
6. The shared result remains pending until the pair returns to the surface boat.
7. The following day, the occupied nursery is visible without a menu, score
   award, generic scan circle, or unrelated blueprint.

The journey must still be visitable with Mica, Marl, or unadapted Kite. They do
not complete Kite's optional relationship outcome, but no geography, required
resource, or main progression is withheld from them.

## Meaningful-Change Filter

This milestone is worthwhile only if it proves all four claims:

- a selected adaptation changes a visible action, not a stat line;
- one existing region gains recognizable wildlife behavior and history;
- the companion is chosen for a relationship within reachable geography, not
  used as a colored key;
- completing the event creates curiosity to revisit on the next day.

The milestone should be held if it reads as “press the highlighted companion
button,” if both branches look equivalent, or if the restored nursery is only
text in the HUD.

## Source Of Truth

Keep `production_level_01` topology, collision, boat, gates, and existing
regional journey records unchanged.

Source work belongs in a composable
`tools/production_level_01_living_expedition_06.py` transform called by
`tools/create_production_level_01_map.py`. Generated JSON and SVG remain outputs,
not hand-edited ownership.

The exact existing boundary is `east_current_signal_reef_route`, its
`lower_right_west_current_gate` and `lower_right_east_current_gate` entries,
`lower_right_signal_reef_landmark`, and the deeper
`signal_reef_deep_harmonic_dark_zone`. The nursery remains inside that reachable
water. The new filter skates are passive unbondable wildlife, not a fourth
companion or a required resource source.

The bounded source records should relate stable ids for:

- `signal_reef_nursery_journey_01`;
- one visible filter-skate school and nursery destination;
- one Anchor Fins current context and one Guardian Pulse hazard context;
- the existing `east_current_signal_reef_route`, Propulsion Fins requirement,
  Dive Light boundary, Signal Reef landmark, and canonical boat;
- pending, restored, and review states plus focused camera provenance.

Any daily presentation variation may be optional. The school, both valid
adaptation paths, and next-day payoff must be guaranteed under every supported
seed.

## State And Runtime Ownership

- **Persistent:** a focused versioned regional-journey subrecord composed by
  `ExpansionProfileState` owns journey id, Kite's individual id, adaptation
  method, boat commitment, and next-day restoration. Do not overload score,
  cargo, generic discoveries, or map JSON with mutable state.
- **Transient:** a focused Signal Reef nursery runtime owns school movement,
  pressure phase, selected context, local action progress, cooldown handoff,
  and the unresolved/pending field state.
- **Companion:** existing Anchor Fins and Guardian Pulse owners remain
  authoritative for command eligibility and effects. LE06 integrates them; it
  does not duplicate or silently auto-fire them.
- **World:** the generated map owns positions and relationships. World helpers
  expose source records and presentation state but do not persist profile data.
- **Existing systems:** equipment, oxygen, daylight, health, collision, BOND
  pause, mounted controls, failure, boat return, and day transition retain
  authority.

Resolving the event before boat return is uncommitted. Oxygen failure, Retry,
or reload restores the source-authored unresolved field state. Boat commitment
is exact-once and survives reload. Full cargo cannot block this non-cargo event.

## Presentation Boundaries

- Use real filter-skate silhouettes, movement, current response, and habitat
  placement rather than abstract circles or a large instructional overlay.
- Show one compact local context label only while the player can act.
- Anchor Fins must visibly form a stable lee; Guardian Pulse must visibly move
  the hazard pressure away without damage or a reward drop.
- The school must move to safety immediately after the action.
- The next-day nursery must visibly contain more settled behavior and recognize
  Kite at gameplay scale.
- Reuse current controls and the maximum-three-row BOND palette. Add no key,
  tool slot, quest log, map marker, or broad HUD replacement.

## Validation And Review

Source and progression checks must prove:

- all ids and relationships resolve;
- both branch contexts are reachable with Propulsion Fins and Dive Light;
- neither branch changes current, darkness, pressure, collision, or topology;
- required wildlife and contexts exist under every supported seed;
- Mica, Marl, mounted Kite, and unmounted Kite cannot bypass equipment gates;
- no reward, recipe, resource, or future species depends on this optional event.

Deterministic journey coverage must prove both adaptations separately, immediate
school response, pending state, failure restoration, exact-once boat commit,
next-day restoration, reload, and no duplicate completion.

Focused desktop and landscape-mobile evidence should show approach, each branch
action, immediate sheltering, and the restored nursery. Compare affected views
before any baseline decision and verify the exact public Web SHA. Existing
terrain, diver, boat, other companions, and unrelated regions must not drift.

## Completed Issue Batch

1. Lock the LE06 Signal Reef source and state contract.
2. Add regional creature-journey schema and progression validation.
3. Author the Signal Reef nursery through the production-level source pipeline.
4. Add exact-once regional journey profile state and migration coverage.
5. Implement filter-skate school, pressure, and restored-nursery presentation.
6. Integrate Anchor Fins and Guardian Pulse as distinct nursery responses.
7. Add compact guidance, focused checkpoints, and next-day journey flow.
8. Add deterministic branch, failure, reload, and equipment-gate coverage.
9. Capture and review focused desktop/mobile evidence and verify the exact Web build.
10. Run the owner experience closeout and record GO, HOLD, or bounded correction.

The dependency-ordered #1366-#1375 batch is complete. Exact Web runtime
`16300a9` received owner GO through #1375 after technical evidence and the
three-checkpoint comparison handoff. No next milestone is selected here.

## Non-Goals

- no fourth species, rescue, stable expansion, breeding, release, or lineage;
- no new adaptation, equipment, recipe, currency, score, material, or blueprint;
- no terrain expansion, teleport, connector, shortcut, or scene-owned topology;
- no broad ecosystem simulation, random required spawn, combat rewrite, or
  creature health/death;
- no restoration of Mica's rejected eel prediction;
- no accepted-baseline sweep or slice-03 work; #52/#53 remain deferred.

## Exit Question

> Did returning to Signal Reef with adapted Kite feel like revisiting a living
> place that remembered this individual, did the chosen adaptation create a
> clear and satisfying way to protect the nursery, and did the next-day change
> make another visit feel worthwhile?

Automation can establish source, state, branch, failure, visual, and deployment
evidence. Only player review can answer this question.
