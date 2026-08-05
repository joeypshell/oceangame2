# Expedition Adaptation Direction

Date: 2026-08-05

Status: Active first-proof contract under the Living Expedition roadmap.
Expansion 18 closes with strategic HOLD; the Spark Ray milestone is the next
bounded implementation batch.

## Decision

Develop OceanGame toward an underwater expedition-raising game centered on one
bonded active sea companion and a small future stable.

The signature promise is:

> Every dive writes the creature you are raising; every night lets you decide
> what those shared experiences become.

The companion does not gain generic experience points or receive an unrelated
menu skill tree. Meaningful events during real expeditions create memories.
During night debrief, the player reinforces one eligible memory into a visible,
mechanical adaptation.

The first implementation is a direction proof, not a roster or complete combat
RPG. It must show that one creature can make the existing dive, return, and
night loop more personal and create a reason to begin another day.

## Why This Direction

The current foundation has strong authored geography, pressure, tools,
progression validation, and deployment discipline. Its weak point is emotional
and expressive motivation: too many journeys reduce to following guidance,
collecting exact prerequisites, resolving a predetermined gate, and receiving
text or score.

Expedition Adaptation adds questions the current loop does not answer:

- What did my companion learn from what happened today?
- Which experience should I reinforce tonight?
- How will that choice change its body and behavior tomorrow?
- Which individual should accompany a later region or threat?
- What new opportunity can this particular partnership handle?

The idea borrows the legible causality of use-based advancement without
rewarding repetitive grinding. It borrows creature attachment and field roles
without turning creatures into interchangeable keys or a large party menu.

## Progression Model

Use one explicit sequence:

```text
meaningful expedition action
-> source-authored experience condition
-> individual memory earned
-> night consolidation choice
-> permanent adaptation
-> visible next-day behavior and payoff
```

Routine activity may build small, capped familiarity later, but it must not
unlock major progression by repetition. Major memories require distinct
encounters, outcomes, or decisions.

The player should always understand:

- which event created a memory
- why an adaptation is available
- what will change if it is selected
- whether the choice is permanent for that individual

The selected balance is mostly deliberate with a small amount of personality:
the player chooses the major adaptation, while temperament may influence
animation, proximity, or secondary behavior. Critical capability changes are
never random.

## Diver And Companion Boundaries

Diver equipment remains the predictable hard-access progression:

- propulsion fins open major current traversal
- dive light supports darkness access
- pressure equipment supports depth access
- cutter and other tools resolve physical interactions
- weapons give the diver direct threat response

Companion adaptations change what the pair can accomplish after the diver can
reach or survive a region:

- stabilize an interaction inside difficult water
- warn about or respond to a creature behavior
- reveal biological or environmental information
- protect, distract, or support during combat
- reach a situational payoff that is not a replacement for basic gear

Occasional later challenges may require both gear and a companion adaptation,
but the first proof must not invalidate an existing equipment gate. A companion
is not a colored key and does not replace the diver's agency.

## First Companion Proof

Use one juvenile bioelectric ray, working name **Spark Ray**.

The individual is curious but cautious, follows the diver closely, and is
introduced through rescue rather than capture. Its broad fins, luminous body
marks, and bioelectric organ make two initial development paths physically
plausible and visually distinct.

The proof includes:

- one rescued individual with a stable callsign
- one active companion at a time
- deterministic follow, separation recovery, and context response
- one committed-bond riding unlock with seamless mount/dismount
- one dedicated slow-time command palette and direct mounted action surface
- two meaningful expedition memories
- one mutually exclusive night adaptation choice
- one changed silhouette or body-pattern detail
- one exploration payoff and one protection payoff across the branches
- no feeding schedule, lifespan, breeding, fusion, roster management, or death

The companion is not placed in the diver tool hotbar. Unmounted tools retain
their existing cycle and `Space/USE` action. `Shift/BOND` opens a bounded
slow-time companion palette. While mounted, the bottom hotbar deliberately
projects creature actions instead of diver tools; dismount restores the tool
surface.

## Three-Day Experience

### Day One: Rescue And Bond

1. A physical clue after the Transfer Hub result leads to one source-authored
   rescue site in existing continuous geography.
2. The player finds the juvenile trapped or exhausted by an environmental
   condition, not waiting as an abstract collectible.
3. The rescue uses an already understood diver verb and returns the creature to
   the canonical boat.
4. The canonical boat commits the individual and riding becomes available on
   the next launched sortie; free-form naming remains deferred.

The rescue grants no score purchase and no surprise blueprint.

### Day Two: Shared Experiences

1. The Spark Ray accompanies the diver through normal oxygen and daylight
   pressure, accepts deliberate commands, and can be mounted or dismounted in
   valid clearance.
2. Mounted control proves direct movement and one non-damaging `glide_surge`
   without bypassing an equipment gate.
3. One authored current situation creates `held_the_flow` when the pair
   completes a meaningful interaction rather than idling in current water.
4. One territorial-threat situation creates `stood_ground` when the companion
   remains with or protects the diver through a real warning/attack cycle.
5. Each earned memory receives one short in-world acknowledgement. It does not
   interrupt the dive with a permanent panel.
6. Returning to the boat preserves the memories; failure restores the
   pre-sortie state according to the contract instead of duplicating them.

### Night Two: Consolidation

The night debrief shows only memories actually earned and previews the concrete
next-day effect. The player reinforces one:

- `held_the_flow` -> **Anchor Fins**
- `stood_ground` -> **Guardian Pulse**

The proof uses no score payment or generic material recipe for adaptation.
Later adaptations may require a thematically related care item or biological
catalyst, but an item can never substitute for the lived memory.

### Day Three: Immediate Payoff

The chosen adaptation appears on the creature and matters within the first
short sortie. The player should not need a tooltip to discover whether the
choice worked.

The day ends with a new unresolved creature, habitat, or behavior promise. It
must not end only with score or an instruction to repeat the same action.

## Initial Adaptations

### Anchor Fins

- Visual: broader fin tips and a stable, low swimming posture in strong flow.
- Trigger: a deliberate independent command or mounted brace action at the
  authored interaction.
- Effect: reduces local drift and lets the pair hold position long enough to
  scan, cut, sample, or protect something inside difficult water.
- Boundary: does not open a current gate that still requires propulsion fins.
- Payoff: one previously impractical interaction inside an already reachable
  current region.

### Guardian Pulse

- Visual: brighter conductive stripe and a readable charge before discharge.
- Trigger: a deliberately aimed independent `BOND` command or selected mounted
  creature action against a clearly targeted threat.
- Effect: interrupts and knocks back one territorial lunge on a visible
  cooldown. It does not silently kill the enemy or replace the Shock Prod.
- Boundary: unmounted diver weapons and mounted creature actions are mutually
  exclusive; diver health, oxygen, and retreat remain authoritative.
- Payoff: enough breathing room to escape, recover position, or deliberately
  continue the encounter.

The two branches are mutually exclusive for this individual in the proof.
Retraining, inheritance, and raising another Spark Ray remain later decisions.

## Source Of Truth

Map or encounter source should own:

- species and habitat identity
- rescue site and prerequisite relationships
- memory-opportunity ids and their meaningful completion conditions
- regional payoff relationships
- review cameras and provenance

Versioned profile state should own:

- individual companion id, species, name, and temperament seed
- rescued/available status
- active companion selection
- earned memories and selected adaptation

Runtime should own only live follow position, current behavior state, temporary
cooldowns, presentation, and in-progress encounter state. Map JSON must not own
mutable bond or adaptation state.

The progression audit should merge equipment prerequisites, rescue conditions,
memory opportunities, adaptation requirements, and payoffs so no creature path
creates a circular mandatory dependency.

## Runtime Boundaries

- Do not extend the one-off territorial eel controller into a general creature
  framework.
- Do not add companion state directly to `main.gd`.
- Use focused owners for definition data, individual/profile state, follow and
  context behavior, memory qualification, and night consolidation.
- Keep behavior deterministic enough for source, smoke, and replay validation.
- Companion pathing must recover from ordinary separation without teleporting
  through collision as its normal presentation.
- Failure, Retry, profile reload, day transition, and Web review checkpoints
  must not duplicate, erase, or reroll the individual.

## Visual Direction

The companion must read as a living individual, not a marker or floating tool:

- identifiable body silhouette at gameplay scale
- idle, follow, worried/separated, memory-response, and adaptation animations
- individually authored adaptation overlays or variants
- restrained effects that remain readable in the existing cave palette
- no whole-scene regeneration to revise the creature

The first visual review compares base independent/mounted, Anchor Fins, and
Guardian Pulse states at desktop and landscape-mobile scale before accepting any
baseline.

## Validation And Review

Deterministic evidence should prove:

- rescue and canonical-boat commitment occur exactly once
- riding unlocks only after commitment; mode switching, rider clearance,
  movement authority, hotbar projection, and mobile `BOND` controls are stable
- `glide_surge` is non-damaging and bypasses no access gate
- only meaningful conditions award each memory
- repetition cannot grind duplicate memory or adaptation progress
- only earned memories appear at night
- exactly one adaptation is selected and persists across reload/day transition
- Anchor Fins does not bypass propulsion-fin access
- Guardian Pulse has clear targeting, knockback, cooldown, and no silent kill
- failure/reset semantics do not duplicate or lose the companion
- existing maps, tools, combat, day state, and accepted baselines remain stable

Automation proves the contract, not attachment or fun. The final gate requires
the owner to play the three-day journey on the exact public build.

## First Milestone

Title: **Living Expedition 01: Spark Ray Adaptation Proof**.

Freeze one bounded issue batch in this order after the target-game and
creature-system planning reset lands:

1. Lock the companion experience, source, state, failure, and control contract.
2. Add species, rescue, memory, adaptation, and payoff schema validation.
3. Add versioned individual companion/profile state with migration coverage.
4. Implement one deterministic Spark Ray follow and context-behavior owner.
5. Implement companion commands, riding, mounted movement, and action projection.
6. Author the rescue and two memory opportunities through the source pipeline.
7. Implement memory qualification and exact-once night consolidation.
8. Implement Anchor Fins and Guardian Pulse with visible individual/mounted
   changes.
9. Add deterministic rescue, riding, memory, adaptation, failure, and regression
   smoke.
10. Add focused desktop/mobile captures and controlled visual review.
11. Verify the exact public Web build and run the three-day owner closeout.

Do not create a second creature or the next creature milestone during this
proof.

## Deferred Work

- roster or habitat management beyond the one active individual
- broad species catalog, egg loops, breeding, fusion, genes, or inheritance
- turn-based party combat or three-creature teams
- generalized enemy/ecosystem simulation
- feeding chores, loyalty meters, lifespan, forced retirement, or death
- random mutation, procedural creatures, or repeated exposure grinding
- companion equipment, inventory grid, economy, or new survival taxes
- large terrain expansion, fast travel, or shortcut networks
- final creature art, broad HUD replacement, or full audio production
- #52/#53 slice-03 presentation polish

## Exit Criteria

The direction proof succeeds only if the owner can answer yes to both:

> Did the companion feel like an individual shaped by what happened during the
> expedition rather than a tool, quest reward, or skill-tree token?

> After commanding, riding, and seeing the adaptation the next morning, did you
> want to begin another day to discover what this partnership could become?

If the proof produces another checklist, generic unlock, passive key, or
unexplained command, hold the milestone and correct the experience before
adding species or systems.
