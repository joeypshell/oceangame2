# Living Expedition 04 Plan

Date: 2026-08-08

Issue: #1312 `Plan Living Expedition 04 around one companion-shaped eel encounter`

Status: Selected planning contract. Create the implementation milestone and
issue batch only after this document lands on `main`.

## Decision

Living Expedition 04 will prove that the current active-companion choice changes
how one real-time wildlife encounter is understood and handled. It will reuse
the existing `deep_cache_territorial_eel`, Kite, Mica, Shock Prod, timed cache,
and eel electrocyte harvest in unchanged `production_level_01` geography.

The proof compares three legitimate approaches:

- **Drift-Lens Mica** reads the eel's warning, lunge direction, territory edge,
  and recovery opening without changing hostile state.
- **Guardian-Pulse Kite** deliberately interrupts and knocks back a threatening
  eel without damage, creating a short opening to evade, pass, or attempt the
  cache.
- **The diver** may still evade without companion help or use the Shock Prod to
  damage and defeat the eel. Only defeat exposes the existing electrocyte
  harvest.

This makes nonlethal access and biological harvest a readable choice. It does
not add a second enemy, new resource, generic combat framework, wildlife
reputation, or mandatory kill.

Provisional relationship id:

- `deep_cache_eel_companion_response`

The source contract may refine that id before authoring. Existing hostile,
action, adaptation, and resource ids remain unchanged.

## Target Experience

1. An isolated review profile has Kite and Mica committed, Mica's Drift Lens
   available, Kite's Guardian Pulse branch available, the Shock Prod owned, and
   the existing deep-cache route reachable. It does not mutate the normal
   profile.
2. At the canonical boat, the player selects exactly one companion for the next
   sortie. The inactive individual remains in the habitat.
3. With Mica active, `Read Drift` near the eel shows the current threat phase,
   projected lunge direction, territory edge, and recovery interval in the
   world. The player still moves, evades, and decides when to approach.
4. Mica's read cannot stun, move, damage, slow, pacify, or despawn the eel. It
   cannot open the cache, grant a resource, or change equipment access.
5. With Guardian-Pulse Kite active, the player aims and dispatches the existing
   non-damaging pulse during warning or lunge. A hit produces readable
   knockback and recovery feedback without changing eel health.
6. The opening is temporary. The eel resumes its authored behavior, so the
   player must use the window rather than receive a hidden permanent clear.
7. The player may use a natural missed-lunge recovery, Mica's information, or
   Kite's interruption to pass, retreat, or attempt the guarded timed cache
   while the eel remains alive.
8. The Shock Prod remains the only direct damage owner. Defeat clears the
   territory for the current day and exposes the existing single explicit
   electrocyte harvest.
9. A nonlethal opening never creates that harvest. Defeat never creates an
   automatic drop, score reward, blueprint, or companion adaptation.
10. Failure, Retry, and a fresh day restore the existing day-local hostile and
    harvest state. Profile adaptations and the selected active individual obey
    their current persistence rules.

Anchor-Fins Kite remains a valid individual build but receives no invented
combat action or free adaptation swap. The focused checkpoint may use the
Guardian Pulse branch to review that branch; normal profiles remain unchanged.
Guardian Pulse also retains its existing Shock Prod access requirement; this
proof does not turn the adaptation into a pre-weapon progression bypass.

## Meaningful-Change Filter

The milestone earns runtime cost only if:

- Kite and Mica make the same authored threat legibly different rather than
  providing interchangeable bonuses;
- the player performs the decisive timing, aiming, movement, and tool actions;
- information, interruption, damage, defeat, and harvest remain distinct;
- a nonlethal opening and a defeat/resource outcome create an understandable
  tradeoff under oxygen and daylight pressure;
- the eel reads as territorial wildlife with learnable behavior, not a colored
  lock or passive hit-point target; and
- the result creates curiosity about companion builds in later encounters.

Passive companion damage, a mandatory kill, a second enemy, a new loot table,
or a generic combat-stat layer fails this filter.

## Source And State Boundaries

### Immutable source

- `tools/create_production_level_01_map.py` and one focused Living Expedition 04
  source module own a relationship linking the existing eel, its territory, the
  guarded cache, the existing harvest, and eligible companion responses by id.
- The relationship must reference existing records. It must not duplicate
  territory geometry, hostile phases, cache placement, resource placement, or
  companion action definitions.
- `config/creature_catalog.json` remains authoritative for Guardian Pulse,
  Drift Lens, their roles, and their non-damaging or informational effects.
- Existing terrain, collision, routes, camera anchors, equipment gates, hostile
  health, Shock Prod project, cache, and electrocyte quantity remain unchanged.

### Persistent profile

- `CompanionProfileState` remains the sole owner of individual identity,
  commitment, active selection, memories, and adaptations.
- Living Expedition 04 adds no profile field, memory, adaptation, affinity,
  combat experience, injury, or wildlife reputation.
- Review checkpoints isolate profile state. They may configure existing
  adaptations but cannot persist those choices into the normal profile.

### Live and day-local runtime

- `territorial_hostile_controller.gd` remains authoritative for eel phase,
  target, position, health, contact, knockback, recovery, defeat, and day-local
  restoration.
- `companion_guardian_pulse_runtime.gd` may request the existing support
  interrupt. It cannot apply damage, mark defeat, or expose a harvest.
- `veil_cuttle_drift_lens_runtime.gd` may read an immutable hostile snapshot and
  produce temporary projections. It cannot mutate hostile or resource state.
- The existing Shock Prod owner remains authoritative for direct damage and the
  existing biological-resource owner remains authoritative for the explicit
  post-defeat harvest.
- The timed cache, cargo, oxygen, daylight, health, boat, and failure owners stay
  unchanged.
- Keep new owners under 500 lines and do not add feature logic to `main.gd`.

### Failure and reset

- Oxygen, health, hazard, manual reset, or Retry clears temporary companion
  projections, active charges, cooldowns, and unbanked sortie state under the
  current contracts.
- Hostile defeat and harvested electrocyte remain day-local. A fresh day
  restores both through existing owners.
- Committed companion identity and adaptations survive Retry and reload.
- Switching companions remains boat-only and cannot occur mid-sortie.

## Runtime And UI Boundaries

- Preserve toggle `B/BOND`, the numbered slow-time palette, direct numbered
  commands, and sequential mobile controls. Do not reintroduce held key chords.
- Mica's projection should show source-derived direction, territory, and phase
  timing close to the eel. It must not become a permanent quest panel or exact
  route arrow.
- Guardian Pulse should communicate charge, direction, hit or miss, knockback,
  recovery opening, and cooldown. Because it deals no damage, its result copy
  should not imply that eel health changed.
- Existing eel health feedback remains relevant only when the Shock Prod deals
  damage.
- The bottom action surface continues to reflect the active diver or mounted
  owner. No new combat hotbar, party HUD, or companion health bar is added.
- Desktop and landscape-mobile presentation must keep the eel, player,
  companion, warning, action, and result readable without crowding controls.

## Planned Issue Batch

Create one implementation milestone with this dependency order:

1. Lock the encounter relationship, hostile, companion-action, resource,
   failure, and access contract.
2. Extend focused source/catalog validation for the eel relationship, legal
   informational and support effects, stable references, and non-circular
   harvest rules.
3. Author the single relationship, provenance, and review checkpoint through
   the production map generator without changing topology.
4. Extend Drift Lens to read the existing eel's source-derived threat phases and
   direction without mutating hostile state.
5. Refine Guardian Pulse encounter feedback and its temporary non-damaging
   opening without changing health, defeat, or harvest authority.
6. Integrate active-companion selection, encounter outcomes, cache attempt,
   resource consequence, failure, fresh-day restoration, and mobile controls.
7. Add deterministic source, Mica, Kite, Shock Prod, harvest, failure, access,
   and regression coverage; run the full release-candidate suite once here.
8. Add focused desktop/mobile captures and record an explicit visual decision
   without replacing unrelated accepted baselines.
9. Verify the exact public Web build and named isolated checkpoint.
10. Run the player closeout and record GO, HOLD, or bounded corrections.

Do not create these issues in the planning-gate run that lands this document.

## Validation And Smoke Plan

- Validate all relationship ids, role/effect compatibility, existing hostile
  and resource references, reachable approach/retreat, and zero topology delta.
- Prove Mica reports phase/direction but never changes eel position, phase,
  health, damage, recovery, defeat, harvest, cache, reward, or access state.
- Prove Guardian Pulse changes position/recovery only, leaves health unchanged,
  never defeats, and never exposes or duplicates the electrocyte harvest.
- Prove Shock Prod damage, three-hit defeat, day-local territory clear, explicit
  harvest, cargo handling, and next-day restoration remain authoritative.
- Prove ordinary evade and retreat remain viable with no companion action.
- Prove Anchor-Fins Kite gains no combat action and no adaptation is swapped.
- Preserve Kite riding, Mica ecology, active selection, boat habitat, day/night,
  oxygen, health, cargo, equipment gates, and progression-audit regressions.
- Run the complete release-candidate suite once after integrated focused checks,
  not after every implementation issue.

## Visual And Web Plan

- Capture at desktop `1280x720` and landscape-mobile `844x390`:
  Mica reading eel intent, Guardian Pulse hit/opening, Shock Prod damage, and
  defeat with the explicit harvest available.
- Compare all accepted baseline families before a visual decision. Regenerate
  only affected focused captures and reject unrelated map, player, companion,
  boat, camera, HUD, or control drift.
- Focused evidence remains generated/ignored unless an explicit issue authorizes
  a baseline replacement.
- Verify exact deployed SHA, default map, isolated checkpoint, canvas framing,
  touch BOND/TOOL/USE behavior, and the deterministic encounter paths.

## Non-Goals

- third companion species, larger stable, breeding, release, or habitat legacy
- second hostile, broad enemy AI, procedural spawning, boss, or combat arena
- new weapon, damage type, armor, ammo, combat XP, or generalized combat layer
- new biological resource, loot table, automatic drop, economy, or recipe
- new memory, adaptation branch, adaptation swap, or passive companion attack
- creature health, injury, permanent death, hidden loyalty, or wildlife
  reputation
- map expansion, terrain/collision change, connector, teleport, or new region
- mandatory kill, permanent pacification, or companion-owned hard access
- broad HUD, art, animation, audio, accessibility, or input replacement
- accepted-baseline sweep or `main.gd`/hostile-framework rewrite
- #52/#53 optional slice-03 presentation polish

## Exit Criteria

- The same authored eel supports readable Mica-assisted information,
  Guardian-Pulse interruption, ordinary evade, and Shock-Prod defeat paths.
- The player can explain what each active companion contributed and which
  actions still belonged to the diver.
- Nonlethal access creates no electrocyte; direct defeat exposes exactly the
  existing bounded harvest and no automatic reward.
- Existing companion builds, source topology, hostile authority, hard access,
  survival, cargo, day, failure, and profile behavior remain deterministic.
- Focused evidence, full release validation, exact Web verification, and a human
  owner review pass.
- The owner answers the milestone question:

> Did choosing Kite or Mica give you a different, understandable way to handle
> the same eel, and did choosing between a nonlethal opening and a Shock-Prod
> harvest feel like a real expedition decision?

If HOLD, correct this one encounter or its feedback before adding another
enemy, species, combat framework, wildlife system, or region.
