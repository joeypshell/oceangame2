# Living Expedition 03 Plan

Date: 2026-08-06

Issue: #1274 `Plan Living Expedition 03 around Mica reading a living migration`

Status: Selected planning contract. Create the implementation milestone and
issue batch only after this document lands on `main`.

## Decision

Living Expedition 03 will prove one ecological field journey with Mica and the
existing southwest jellyfish bloom. It will turn Reveal Trace from an anonymous
no-consequence marker into a deliberate observation of a real, source-authored
organism behavior.

The player will use Mica to reveal the bloom's migration evidence, hold the
Scanner to identify it, return the observation to the canonical boat, and
consolidate one Mica memory at night. On a later sortie, the resulting **Drift
Lens** adaptation will let Mica deliberately read the path and direction of an
authored moving jellyfish patrol.

This is a knowledge and partnership payoff, not a new key. Drift Lens does not
stop, move, damage, or neutralize jellyfish; grant cargo, score, materials, or a
blueprint; or change hard geographic access.

Provisional stable ids:

- relationship/trace: `southwest_bloom_migration_trace`
- memory: `followed_the_bloom`
- adaptation: `drift_lens`
- adapted action: `read_drift`

The source/state contract may improve player-facing labels, but changing these
ids after runtime lands requires an explicit migration.

## Target Experience

1. A deterministic Day 2 review starts with Kite and Mica committed, Mica
   selected, the Scanner available, and the southwest bloom active.
2. Existing forecast or route guidance names the **Southwest Jellyfish Bloom**;
   it does not tell the player to scan a generic circle.
3. Near the moving bloom patrol, Mica visibly reacts. Pressing `B/BOND` opens the
   palette and desktop `2` directly activates Reveal Trace.
4. Reveal Trace draws a living migration filament derived from the authored
   patrol relationship. It does not duplicate or invent patrol geometry.
5. The diver deliberately holds `Space/USE` with the Scanner to identify the
   **jellyfish migration trail** while oxygen, daylight, movement, and hazard
   pressure continue normally.
6. Identification creates one pending companion observation. It is not cargo
   and gives no immediate reward or access.
7. Returning to the canonical boat commits the observation exactly once and
   records Mica's `followed_the_bloom` memory.
8. At night, the player may deliberately consolidate that memory into Drift
   Lens at no score or material cost. Reload and Retry cannot duplicate it.
9. On the next sortie, Mica's bounded BOND palette includes `Read Drift`.
   Dispatching it near any source-authored moving jellyfish patrol projects its
   current direction, path, and approach warning for a short readable interval.
10. The player still chooses whether to wait, evade, retreat, or continue. The
    hazard and every diver-equipment gate remain authoritative.

## Meaningful-Change Filter

This milestone earns its runtime cost only if:

- the subject is a visible, named organism behavior already occurring in the
  world, not an abstract scan target;
- Mica is required for interpretation but not for geographic access;
- the observation survives only through a real boat return;
- night changes the same individual in a visible and useful way;
- the learned affordance applies to authored jellyfish patrols generally, not
  one matching lock; and
- the result creates a reason to choose Mica for a later expedition.

No score line, unrelated blueprint, generic research currency, or bonus material
may substitute for those outcomes.

## Source And State Boundaries

### Immutable source

- `tools/create_production_level_01_map.py` and one focused Living Expedition 03
  source module own the relationship, trace anchor, linked daily condition,
  linked moving-hazard subject, memory opportunity, payoff context, review
  camera, and provenance.
- `config/creature_catalog.json` owns Mica's eligible memory, adaptation, and
  deliberate action definitions.
- The ecological relationship references the existing
  `southwest_jellyfish_bloom` and `southwest_bloom_jellyfish_patrol` by id. It
  must not duplicate the patrol path.
- Existing `production_level_01` terrain, collision, hard access, daily schedule,
  hazard path, material opportunity, and roster remain unchanged.

### Persistent profile

- `CompanionProfileState` remains the versioned owner of individual memories and
  selected adaptations. Its schema-v2 individual shape already supports the
  exact-once Mica memory/adaptation, so no profile-shape migration is planned.
- Committed observation is represented by Mica's earned memory; do not create a
  parallel generic research wallet or unrelated discovery reward.
- Kite's memories, selected adaptation, riding availability, and active
  selection remain byte-for-byte compatible through migration.

### Live runtime

- A focused ecology journey owner holds revealed/identified/pending observation
  state until canonical-boat commitment.
- `veil_cuttle_trace_runtime.gd` may coordinate Mica's deliberate action but
  does not own source records, profile persistence, scanner completion, hazard
  movement, or rewards.
- Existing Scanner owners retain held-use progress and identification authority.
- Existing daily-condition and moving-hazard owners retain activation, position,
  movement, contact, and failure semantics.
- Read Drift projects source-derived information only. It cannot mutate a hazard
  or provide collision/access immunity.
- Keep new owners under 500 lines and do not grow `main.gd` for feature logic.

### Failure and reset

- Leaving range or releasing the Scanner cancels progress under existing held-use
  rules.
- Hazard, oxygen, health, manual reset, or Retry clears revealed, identified,
  and pending uncommitted observation state.
- Canonical-boat commitment awards the memory once. Committed memory and Drift
  Lens survive day transition, Retry, and profile reload.
- Review checkpoints isolate all profile mutation.

## Runtime And UI Boundaries

- Use the toggle `B/BOND` tactical-pause palette with at most three contextual
  commands. Desktop `1`-`3` activates matching rows; do not reuse `Q` or `E/ACT`.
- Mica remains independent and non-mounted. Kite retains all mounted behavior.
- Before identification, world feedback should resemble a directional migration
  filament/path, not a generic circle or unexplained marker.
- Scanner presentation names the subject and shows held progress near it.
- Boat and night presentation explain the shared event and Drift Lens effect in
  compact language; no permanent quest panel is added.
- Read Drift has a visible direction/path projection and clear out-of-range,
  no-subject, and cooldown feedback on desktop and landscape mobile.

## Planned Issue Batch

Create one milestone with this dependency order:

1. Lock the ecological relationship, profile, scanner, failure, and access
   contract.
2. Extend catalog/map schema validation for linked ecological behavior,
   `followed_the_bloom`, Drift Lens, and Read Drift.
3. Author the bloom relationship, trace, memory/payoff context, provenance, and
   review camera through the production map generator.
4. Implement exact-once pending observation, boat commitment, Mica memory, and
   night consolidation without changing Kite state.
5. Implement the source-derived migration trail and deliberate Read Drift field
   projection without mutating moving hazards.
6. Integrate Mica guidance, Scanner handoff, BOND commands, day/night flow,
   failure, reload, and mobile controls.
7. Add deterministic source, profile, journey, failure, access, and regression
   coverage; run the full release-candidate suite once at integration.
8. Add focused desktop/mobile captures and record an explicit visual decision
   without replacing accepted baselines.
9. Verify the exact public Web build and named isolated checkpoint.
10. Run the player closeout and record GO, HOLD, or bounded corrections.

## Validation And Smoke Plan

- Validate catalog ids, source references, all-supported-seed availability,
  reachable trace/return path, no duplicated patrol geometry, and no topology
  delta.
- Prove reveal is not identification, Scanner completion is not commitment,
  boat return awards the memory once, and night consolidation persists.
- Prove Read Drift works on the conditional southwest patrol and the existing
  unconditional deep-route jellyfish patrol.
- Prove Read Drift cannot disable or reposition hazards, change access, grant a
  reward, or bypass fins, light, pressure, oxygen, health, or collision.
- Preserve Kite rescue, profile migration, selection, riding, adaptation,
  failure, and reload smokes.
- Run the full release-candidate suite once after integrated runtime and focused
  journey coverage are ready, rather than after every small issue.

## Visual And Web Plan

- Capture at desktop `1280x720` and landscape-mobile `844x390`:
  Mica reaction, Reveal Trace migration filament, held Scanner identification,
  pending boat return, night consolidation, and next-sortie Read Drift.
- Compare all accepted baseline families before any decision. Focused evidence
  remains generated/ignored unless a separate issue explicitly accepts a
  baseline replacement.
- Verify exact deployed SHA, default map, isolated checkpoint, canvas framing,
  touch BOND/TOOL/USE dispatch, and the deterministic journey.

## Non-Goals

- third companion species, larger stable, breeding, release, or legacy
- Mica riding, direct-control mode, broad adaptation tree, or passive bonuses
- new terrain, map region, connector, teleport, or accepted-baseline sweep
- hazard disable, jellyfish combat, capture, harvest, or ecology simulation
- score, material, blueprint, cargo, or generic research-currency reward
- changing the bloom schedule, patrol route, coil opportunity, or equipment
  progression
- broad scanner, HUD, combat, audio, art, or `main.gd` rewrite

## Exit Criteria

- The complete sequence is deterministic, reload-safe, failure-safe, playable
  on desktop and landscape mobile, and verified on an exact public Web build.
- The player can explain what organism behavior Mica noticed, why the Scanner
  was still needed, what returning to the boat changed, and how Drift Lens helps
  without acting as a key.
- Existing Kite, map, hazard, survival, and equipment behavior remains stable.
- A human owner answers the milestone question:

> Did Mica help you notice and understand a living migration that the Scanner
> alone would not have found, and did turning that shared observation into a
> useful next-day field skill make you want to choose Mica again?

If HOLD, correct this one relationship or adaptation before adding a third
species, broader ecology, duo combat, or another region.
