# Living Expedition 05: Silt Hound Excavation Proof

Date: 2026-08-10

Status: selected implementation plan from issue #1340. Create the bounded
milestone batch only after this planning gate merges.

## Decision

Living Expedition 05 will test one third companion, the Silt Hound, through one
deliberate `Excavate` action that visibly uncovers a source-authored optional
typed-material deposit in existing `production_level_01` geography.

This is not another detector. The player sees a credible buried deposit, chooses
the Silt Hound for a later sortie, commands the action through BOND, watches the
individual dig, and receives a physical material pickup through the existing
cargo and boat-banking loop.

## Candidate Evaluation

| Candidate | Immediate payoff | Another-day reason | Main risk | Decision |
| --- | --- | --- | --- | --- |
| Silt Hound practical proof | a commanded dig physically exposes a useful material | rescue, select, then return with the Hound to claim the deposit | profile migration, third-row habitat clarity, and material handoff | selected |
| Current-roster regional journey | could deepen Kite or Mica in known geography | a new route for an existing companion | likely repeats information, guidance, and route cadence before either companion has a new tangible verb | defer |
| Habitat legacy or release | could eventually make individual history consequential | long-term roster turnover | two companions do not yet carry enough history for retirement to be meaningful rather than administrative | defer |

The selected proof clears the meaningful-change filter because the companion
changes a concrete player outcome with a visible living behavior. It does not
merely label, point toward, predict, multiply, or unlock something abstractly.

## Target Experience

1. The diver finds and aids one juvenile Silt Hound at a source-authored rescue
   situation in already reachable geography.
2. Returning to the canonical boat commits the named individual exactly once.
3. The compact habitat shows Kite, Mica, and the Hound without becoming a broad
   stable-management screen.
4. The player selects the Hound for the following sortie.
5. A visible buried deposit in an already reachable region promises a physical
   excavation opportunity without an arrow, scanner ring, or hidden proximity
   trigger.
6. Near that deposit, BOND offers `Excavate`. Selection resumes the simulation;
   the Hound approaches, digs with readable anticipation and impact, and opens
   the deposit.
7. One existing typed material becomes a normal world pickup. Cargo-full state
   leaves it available rather than deleting it.
8. The player collects and banks the material through existing cargo and boat
   owners. No score, blueprint, recipe, or unrelated progression is awarded.

The rescue and excavation must each make sense from the Hound's anatomy and the
physical scene. HUD text may clarify a state but cannot be the sole explanation.

## Scope Boundaries

In scope:

- one named Silt Hound individual;
- one rescue and canonical-boat commitment;
- versioned migration from the two-individual profile to three individuals;
- one compact third habitat row and existing next-sortie selection;
- one source-authored optional buried deposit relationship;
- one deliberate independent `Excavate` command;
- one existing typed material and existing collection/banking semantics;
- deterministic journey, failure, visual, mobile, and exact-Web evidence.

Out of scope:

- terrain or map-scale expansion;
- a generic digging system or procedural buried-resource placement;
- a new material family, recipe, blueprint, economy, or score reward;
- passive prospecting bonuses, map-wide detection, arrows, or repeated scanning;
- Silt Hound memory/adaptation branches, combat control, or riding;
- release, retirement, lineage, legacy traits, a fourth species, or broad stable
  management;
- accepted-baseline replacement or unrelated art/HUD changes;
- restoring Mica's rejected eel prediction.

The existing equipment gates remain authoritative. The Hound cannot replace
Fins, Dive Light, Pressure Suit, Rebreather, Cutter, Scanner, Shock Prod,
Current Stabilizer, oxygen, health, collision, or daylight.

## Source Of Truth

- `config/creature_catalog.json` owns species identity, the named individual,
  supported role, and stable action id.
- The established production-level source/generator path owns the rescue,
  buried deposit, material-candidate relationship, review camera, and stable
  ids. Generated map JSON is never hand-edited.
- The map owns where the opportunity exists, not whether the player has already
  rescued or selected the individual.
- Existing typed-material definitions own material identity and value. The
  companion action cannot invent quantities or bypass normal cargo rules.
- The progression graph must model rescue, boat commitment, active selection,
  excavation, pickup, and return without making any required recipe depend on
  the optional deposit.

## Persistent And Runtime State

- `CompanionProfileState` advances through an explicit schema migration. It
  owns at most three committed individual records and one active individual id.
- Migration preserves valid Kite/Mica identity, memories, adaptations, and
  selection. It cannot silently add, select, duplicate, or lose the Hound.
- Rescue commitment is persistent only after canonical-boat return.
- Position, follow mode, target, command selection, approach, dig progress,
  cooldown, and deposit reveal are transient runtime state.
- The focused excavation owner coordinates only eligibility and the visual
  action. Existing material runtime owns pickup, cargo capacity, restoration,
  depletion, and boat banking.
- Retry, oxygen failure, hazard reset, reload, and fresh-day selection must
  restore source/profile-derived state without duplicating the material or
  erasing a cargo-blocked pickup.

The source/state contract issue must settle exact daily reset behavior before
map authoring or runtime implementation begins.

## Runtime And UI Boundaries

- Existing species-factory dispatch receives one focused Silt Hound scene and
  control owner. Do not add species conditionals throughout `main.gd`.
- Unmounted diver movement and active tools remain unchanged.
- B/BOND keeps the whole-simulation tactical pause. `Excavate` appears only
  when the active Hound and a valid deposit are in actionable context.
- Activating the command returns to real time and makes the Hound perform the
  work visibly; no hidden autonomous excavation occurs.
- The habitat panel remains a compact projection of profile state. It may grow
  to three readable rows but not into a management menu.
- Desktop and landscape-mobile BOND selection must remain sequential and use
  the existing control contract.

## Planned Issue Batch

Resolve in this dependency order:

1. Lock the Living Expedition 05 source, profile, runtime, material, reset, and
   presentation contract.
2. Extend creature/map schema validation and progression relationships for one
   Silt Hound rescue and buried deposit.
3. Migrate companion profile state to three individuals and prove compact
   three-row habitat selection.
4. Author the rescue, deposit, relationship, and review camera through the
   production-level source path without topology changes.
5. Add the Silt Hound scene, physical identity, follow, separation, and rescue
   presentation.
6. Implement deliberate Excavate approach, dig, reveal, cargo-full, reset, and
   existing-material handoff behavior.
7. Integrate the complete rescue -> boat -> select -> excavate -> bank journey
   with concise guidance and review checkpoints.
8. Add deterministic schema, migration, journey, failure, mobile-control, and
   progression-audit coverage without duplicating the full release suite.
9. Regenerate only focused captures, compare all accepted baselines, and record
   the visual decision without accepting unrelated drift.
10. Verify the exact public Web build, then run the owner playtest closeout.

Do not begin later issues before their contract or source dependencies merge.

## Validation And Evidence

Focused implementation checks must prove:

- old empty, Kite-only, and Kite/Mica profiles migrate and reload safely;
- rescue and commitment are exact-once;
- only the selected committed Hound launches;
- all three habitat rows remain readable and selectable;
- Excavate is unavailable without the Hound, out of range, or at an invalid
  target, with clear feedback;
- action anticipation, dig, reveal, and pickup are visibly distinct;
- no automatic detection, collection, score, recipe, or capability grant occurs;
- cargo-full, failure, Retry, reload, banking, and fresh-day behavior cannot
  delete or duplicate the material;
- equipment gates and existing Kite/Mica behavior remain intact;
- desktop and landscape-mobile BOND controls remain usable.

Use focused checks during implementation and run the applicable release,
progression, file-length, and diff gates at integration and closeout. Capture
the rescue, habitat selection, command anticipation, opened deposit, cargo-full
state, and successful pickup at both review sizes. Verify exact public build
metadata and browser initialization before asking for the player verdict.

## Deferred Work

- Growth, release, retirement, lineage, and habitat legacy remain directional
  until at least three individuals have enough reviewed history to make those
  decisions emotional rather than clerical.
- Regional creature journeys remain directional after this bounded proof.
- Silt Hound `silt_read`, memory branches, Vein Whiskers, Root Claws, buried
  organisms, and random daily prospecting remain unimplemented possibilities.
- #52/#53 remain deferred optional slice-03 presentation work.

## Exit Criteria

Technical completion requires the bounded journey, profile migration, source
parity, deterministic checks, focused visual decision, and exact-Web evidence.
Automation cannot answer the milestone's owner gate:

> Did rescuing and choosing the Silt Hound make the material run feel like a
> distinct partnership, and was Excavate's payoff clear and useful enough to
> choose that individual for another day?

Record GO, HOLD, or a narrowly bounded correction. Do not create a fourth
species or the next milestone from technical completion alone.
