# OceanGame Expansion 16 Plan

Date: 2026-07-28

Status: Active in GitHub milestone #42. The frozen implementation batch is
#1124-#1133; #1133 is the owner GO/HOLD closeout gate.

## Decision

OceanGame Expansion 16 is **Deeper Wreck Oxygen Return**.

The committed Northwest Wreck Relay discovery will reveal one deeper wreck
signal in the underused far-west/lower-left portion of the existing contiguous
`production_level_01`. The player will build one durable closed-circuit
rebreather project, return through remembered geography, cross a visible
source-authored high-consumption oxygen zone, use the existing cutter and
scanner at the wreck, and bring one progression discovery back to the canonical
boat.

The rebreather is not another wallet purchase or a global percentage bump. It
normalizes accelerated oxygen drain only in source-authored confined-wreck
high-consumption zones. Normal water, base tank size, the optional session
`O2 tank +15`, surface refill, boat offload, pressure-suit behavior, and
failure rules remain unchanged.

## Evidence

The current executable progression graph passes and ends at stage 25 with
`upper_left_wreck_relay_discovery`. Its source record already promises:

```text
Next lead: deeper wreck relay still transmitting
```

The full-level source preview and footprint-aware traversal validator show:

- the existing upper-left anchor is only a `25.4s` ideal round trip from the
  boat, so a nearby relay continuation would not prove oxygen-route progression
- the far-west chamber around tiles `x=12..32`, `y=90..121` is continuous,
  reachable, lightly used, and needs no terrain or connector change
- representative tile `(15,95)` is about `7156.7px` one way from the boat,
  or `71.6s` of ideal round-trip swimming at the current `200px/s`
- that leaves only `18.4s` of the base 90-second tank before interaction,
  navigation error, route pressure, and a safe return reserve
- the optional session tank raises that ideal headroom to `33.4s`, so distance
  alone cannot distinguish a durable oxygen capability reliably

Therefore the milestone selects a readable route-local oxygen pressure zone.
Implementation must measure real runtime movement and interaction time; these
planning numbers are evidence, not final tuning.

## Target Experience

1. Returning the Northwest Wreck Relay survey to the boat commits the deeper
   wreck lead.
2. Night debrief reveals one closed-circuit rebreather project with exact
   blueprint/knowledge and material requirements.
3. The player can follow the broad west/deeper lead through normal swimming
   and recognize the distant wreck route before owning the capability.
4. Entering the confined wreck pressure produces immediate oxygen-consumption
   feedback. The player can scout and retreat, but cannot complete the wreck
   operation and return safely with only the base tank or session tank.
5. Building the rebreather at night changes that same place: the pressure
   becomes manageable while ordinary oxygen and daylight pressure continue.
6. The player uses the existing salvage cutter to expose the wreck record and
   the existing scanner to investigate it deliberately.
7. The finding remains pending until canonical-boat return, where it commits
   once and reveals the next broad promise.

The route should feel like a prepared expedition, not a locked prompt followed
by ordinary score.

## Capability And Project Contract

Locked durable capability:

```text
closed_circuit_rebreather
```

Project shape:

| Requirement | Owner / rationale |
| --- | --- |
| Knowledge | committed `upper_left_wreck_relay_discovery` |
| Titanium Scrap x1 | structural frame; existing guaranteed pool |
| Rubber Sheet x1 | pressure seals; existing guaranteed pool |
| Conductive Coil x1 | circulation/control; existing guaranteed pool |
| Insulating Gel x1 | scrubber/seal medium; existing nonlethal source |
| Build phase | exact-once night debrief |
| Changed behavior | normalize route-local accelerated oxygen drain |

The locked source/state contract preserves this dependency shape. Validation
may report HOLD if source authoring cannot satisfy it without circularity.

Safeguards:

- no new material type or creature resource is required
- all ingredients are available before the route they unlock
- score never substitutes for knowledge or ingredients
- the session `O2 tank +15` may improve general preparation but cannot satisfy
  the route's deterministic completion-and-return contract by itself
- the rebreather does not unlock pressure zones, currents, darkness, sealed
  targets, or scanner/cutter interactions owned by other capabilities
- no recipe is inferred from source-array order

## Route And Payoff Contract

The Expansion 16 source helper will own one bounded journey in the existing
far-west/lower-left review region:

```text
promise: upper_left_wreck_relay_discovery
destination review bounds: x=12..32, y=90..121
representative route point: x=15, y=95
travel model: continuous production_level_01 swimming
terrain changes: none expected
```

Exact entity and zone cells belong to source authoring after player-footprint
and camera review. The selected area must remain reachable from the boat and
directly returnable with collision active.

The wreck should contain:

- one recognizable non-collision landmark
- one visible confined-wreck high-consumption oxygen zone
- one existing-cutter interaction that exposes the survey subject
- one explicit held-scanner survey
- one boat-committed deeper-wreck discovery
- optional valuable cargo only as secondary expedition risk/payoff

The committed discovery, not score, is the progression result. It should give a
broad next lead without selecting Expansion 17 inside this milestone.

## Meaningful-Change Filter

Expansion 16 fails if it only:

- adds thirty seconds to the oxygen bar globally
- places another valuable cache in empty water
- blocks the wreck with an invisible capability check or `E` transition
- lets the session tank fully substitute for the durable project
- grants the discovery on arrival, cutter completion, or scan completion
  without canonical-boat return
- creates a long hold interaction to manufacture oxygen pressure
- introduces a new material, enemy, or interior merely to enlarge the batch

The same visible route must be scoutable before the project and meaningfully
safer/completable after it.

## Source-Of-Truth Boundaries

Future authoring must extend:

```text
tools/create_production_level_01_map.py
tools/production_level_01_expansion_16.py
maps/production_level_01.greybox.json
```

The focused helper should author project, journey, zone, landmark, tool-target,
survey, background, camera, and provenance records. Generated JSON is never
hand-edited.

The map validator and progression audit must reject:

- unsupported oxygen-pressure metadata
- dangling capability, project, route, target, survey, or commit references
- an oxygen zone that blocks all pre-upgrade scouting
- a completion route that the session tank can substitute for
- unreachable ingredients or circular knowledge/project dependencies
- solid/out-of-bounds targets or a missing direct return
- transition, connector, teleport, or topology metadata in this journey

## Runtime And State Boundaries

Prefer one focused oxygen-route controller or a small generalization at an
existing stable environmental-pressure boundary. Do not grow `main.gd`.

Ownership remains:

| Owner | Responsibility |
| --- | --- |
| `SortieState` | mutable oxygen and failure/reset state |
| focused oxygen-route controller | zone overlap, multiplier, warning, capability normalization |
| `ExpansionProfileState` | durable rebreather capability and committed discovery |
| `MaterialProjectRuntime` | exact recipe and night transaction |
| cutter/scanner owners | explicit active-tool interaction and cancellation |
| discovery state | pending finding and canonical-boat commit |
| source map | route, zone, landmark, target, survey, labels, and relationships |

HUD work is limited to compact contextual oxygen-pressure, project, pending,
and result text through existing surfaces. No new persistent panel is added.

## Frozen Implementation Batch

Milestone #42 contains exactly:

1. #1124 lock the source, state, route-margin, and presentation contract
2. #1125 add schema validation and progression auditing
3. #1126 author the project and far-west deeper-wreck journey in source
4. #1127 implement focused oxygen-zone and rebreather runtime behavior
5. #1128 integrate cutter, scanner, pending finding, and boat payoff
6. #1129 add deterministic full-journey smoke and CI coverage
7. #1130 add focused desktop/mobile review captures
8. #1131 review and accept only intentional visual differences
9. #1132 verify the exact public Web candidate and isolated checkpoint
10. #1133 run the owner journey and close with GO or HOLD

Issues #1124-#1132 are the bounded technical cycle. #1133 intentionally
remains open until the owner reviews the exact Web candidate. Do not refill
the queue or select Expansion 17 during this milestone.

Dependency order:

```text
contract -> schema/audit -> source -> oxygen runtime -> wreck integration
-> smoke -> capture -> visual review -> Web verification -> player closeout
```

## Validation And Smoke Plan

The focused deterministic journey must prove:

- committed relay discovery unlocks the exact project
- all required materials are guaranteed and spent once at night
- pre-project route pressure is visible and retreat remains possible
- base 90 seconds cannot complete the operation and return with the contracted
  reserve
- session `O2 tank +15` alone still cannot satisfy that contract
- rebreather ownership normalizes only the authored zone and leaves ordinary
  water unchanged
- existing cutter and held scanner inputs remain explicit
- cargo-full does not delete the target or prevent scanning
- failure clears pending/local state and restores unbanked cargo
- canonical-boat return commits the discovery exactly once
- reload preserves durable project/discovery state
- current, light, pressure suit, combat, planning choice, and prior journey
  regressions remain stable

Run the integrated release suite once after the complete runtime/smoke surface
is ready, not after every small issue.

## Visual And Web Plan

Focused captures should show:

- pre-project wreck-route promise and oxygen warning
- night rebreather recipe with banked/held counts
- unprotected zone pressure and retreat state
- equipped traversal with readable oxygen margin
- cutter-ready wreck, held scanner progress, pending finding, and boat result
- desktop and iPhone-landscape framing

No accepted terrain or slice baseline should change because topology is
unchanged. Compare established full-level and slice baselines before accepting
any HUD, landmark, or zone-presentation difference. Exact-SHA Web verification
must include root continuing play, fresh review, the focused checkpoint,
desktop/wide/mobile framing, touch controls, resources, and browser/Godot
errors.

## Deferred Work

- #52/#53 remain optional slice-03 presentation polish.
- Exceptional interiors, connectors, teleports, shortcuts, and fast travel
  remain deferred.
- A broad oxygen system, multiple rebreather tiers, consumable tanks, air
  stations, decompression simulation, and global rebalance are deferred.
- New materials, enemies, weapons, vehicles, inventory, broad economy, broad
  HUD replacement, and map topology expansion are outside this milestone.
- The deeper-wreck discovery may point forward, but Expansion 17 is not chosen.

## Exit Criteria

Expansion 16 is complete only when:

1. the source-authored deeper-wreck journey uses existing contiguous geography
2. the player can see and retreat from the oxygen pressure before the project
3. the session tank cannot substitute for the durable recipe-built rebreather
4. the rebreather makes the same route completable with a readable return margin
5. cutter, scanner, cargo, failure, night, and boat-commit owners remain stable
6. progression audit, route validation, smoke, focused visual review, exact Web
   verification, and owner review agree
7. the owner answers GO to:

> Did the relay clue, material project, and rebreather turn the far-west wreck
> into a place I could first scout and later complete safely, with a discovery
> worth carrying back to the boat and a reason to begin another expedition?
