# OceanGame Expansion 18 Source And State Contract

Date: 2026-08-02

Issue: #1192

Plan: `docs/current/OCEANGAME_EXPANSION_18_PLAN.md`

## Decision

Expansion 18 adds one physically reached exceptional interior. The player
swims through `production_level_01` to a source-authored Transfer Hub entrance,
uses `E/ACT` to enter, frees one navigation core with the existing Cutter and
`Space/USE`, returns through the paired doorway, and carries the core to the
canonical boat.

Entry and return are map loads inside one live sortie. They do not refill
oxygen, restore health, bank cargo, advance to night, create a second boat, or
reset expedition state. Historical slice connectors keep their existing
regression contract and are not converted into normal traversal.

## Stable IDs

| Role | ID |
| --- | --- |
| expansion | `transfer_hub_interior_expedition` |
| prerequisite discovery | `wreck_network_triangulation_discovery` |
| exterior map | `production_level_01` |
| exterior entrance marker | `transfer_hub_exterior_entrance` |
| exterior return entry | `transfer_hub_exterior_return` |
| interior map | `transfer_hub_interior_01` |
| interior arrival entry | `transfer_hub_interior_entry` |
| interior return marker | `transfer_hub_interior_return` |
| core tool target | `transfer_hub_navigation_core_cradle` |
| core discovery/cargo id | `transfer_hub_navigation_core_discovery` |
| canonical boat entry | `surface_boat_entry` |
| review checkpoint | `expansion_18_start` |

Exact source cells and camera rectangles belong to authoring issue #1194.
They must be selected through footprint, reachability, route, and camera
validation rather than by editing generated JSON.

## Exceptional-Interior Source Contract

Both transition markers keep the established marker-zone connector fields and
add only the fields needed to distinguish a paired interior round trip:

```text
world_connector = true
connector_kind = exceptional_interior
paired_connector_id = <marker id in destination map>
destination_map_id = <map id>
destination_map_path = res://maps/<map>.greybox.json
destination_entry_id = <spawn id in destination map>
connector_direction = forward | return
```

The exterior forward marker also declares:

```text
required_discovery_id = wreck_network_triangulation_discovery
```

The return marker must not repeat or invent a progression prerequisite. Its
paired destination is the exterior return entry beside the original entrance.
The pair is reciprocal by map id and marker id; it is not a destination list,
shortcut network, boat transition, or map-menu node.

The source owns marker rectangles, labels, destination references,
prerequisite, direction, mission id, approach/return guidance, intent,
provenance, and review questions. The real `expansion_18_start` checkpoint and
the normal post-triangulation profile both resolve that same metadata: the
exterior names the lowest central chamber, the interior names the Cutter
objective, and held core cargo names the return leg. While this mission is
unresolved, older route and research hints must not outrank it. The source owns no
unlocked flag, active transition, origin snapshot, oxygen, daylight, health,
cargo, consumed core, failure, profile, or UI state.

## Interior Map Contract

`transfer_hub_interior_01` is a generated greybox map with:

- one normal `spawn` entry named `transfer_hub_interior_entry`
- one reachable non-solid return marker named `transfer_hub_interior_return`
- one reachable Cutter target named `transfer_hub_navigation_core_cradle`
- compact terrain/collision, a distinct physical landmark, camera tests,
  provenance, and review metadata

It has no `boat_spawn`, extraction/offload zone, open-surface oxygen refill,
night owner, second entrance, second core, enemy, recipe, capability grant, or
ordinary salvage requirement. The existing world renderer and query surface
remain source readers; they do not infer transition or recovery state.

## Navigation-Core Source Contract

The core cradle is a `tool_target` using the existing deliberate cutter shape:

```text
interaction = cutter_salvage
interaction_seconds = <positive duration>
interaction_label = chain-sealed navigation core
required_tool_id = salvage_cutter
tool_affordance_id = chain_seal
reward_kind = held_discovery_cargo
reward_id = transfer_hub_navigation_core_discovery
reward_commit_map_id = production_level_01
reward_commit_entry_id = surface_boat_entry
```

`held_discovery_cargo` is a narrow Expansion 18 reward shape. It requires one
normal cargo slot and becomes one held/pending item only after Cutter progress
completes. Full cargo leaves the cradle present and unconsumed. The source may
provide compact held, blocked, and commit labels, but cannot author progress,
capacity, consumed state, pending state, completion, score, materials, profile
data, or UI visibility.

`chain_seal` is presentation-only. It replaces the core's generic valuable and
timed rings with visible linked chains and a central cut seal. Because the
affordance is a child of the target node, it hides on successful recovery and
returns with the target after existing failure restoration.

The reward grants no score, wallet value, recipe, capability, tool, material,
or automatic route unlock. Its payoff is the physical core and one broad
committed route discovery.

## Transition State Contract

A focused `InteriorExpeditionTransitionState` (or equivalently named owner)
owns only:

- whether the exceptional round trip is inactive, entering, inside, returning,
  or failed
- source-derived origin/destination map, entry, and paired-marker identities
- the active round-trip identity needed to reject unrelated connectors
- per-map consumed ids needed to prevent duplication during the live sortie

It delegates continuity to existing authoritative owners. It must not copy
oxygen, health, daylight, cargo, profile, or pending-discovery values into a
second mutable model.

The transition begins only when the player overlaps the exterior marker,
holds the prerequisite discovery, and presses `E/ACT`. The interior return
uses the same action at its paired marker. Loading any other connector remains
outside this contract.

## Values Preserved Across Entry And Return

The same authoritative objects retain:

- `SortieState`: active state, oxygen, held salvage count/ids/score
- `ExpeditionDayState`: day, daylight, sortie count, selected plan, and day
  condition state
- `PlayerHealthState`: current health and failure state
- material/biological cargo owners: held materials and biological resources
- main run totals: banked salvage/score, completion progress, and capacity
- `ExpeditionDiscoveryState`: pending navigation-core discovery
- `ExpansionProfileState`: durable capabilities and committed discoveries
- transition/core owners: live consumed cradle/core state and origin identity

Normal oxygen and daylight drain continue while the player is inside. A map
load must not reset these values to capacity or zero. A transition cannot call
boat offload or a profile commit.

## Values Reset Or Rederived Per Map Leg

Each loaded leg may reset or derive from its new source:

- player/camera placement from `destination_entry_id`
- partial Cutter progress and local overlap/input state
- transient prompts, warnings, audio, and presentation timers
- map-local hazards, render nodes, source queries, and camera limits
- safely source-derived local target visibility

Resetting partial tool progress does not consume the core. Durable profile
state and held cargo are never reconstructed from map JSON.

## Core Transaction Contract

The existing Cutter owns range, selected-tool eligibility, held `Space/USE`,
progress, leave/release cancellation, and completion. A focused core-recovery
owner interprets completion:

1. Recheck one free cargo slot.
2. Mark the cradle consumed for the live round trip.
3. Add one held cargo item with the core id.
4. Create one pending discovery with canonical map/entry metadata.
5. Preserve both across paired return.

Wrong-map or interior contact cannot commit it. At
`production_level_01/surface_boat_entry`, normal offload removes the held item
and commits the discovery exactly once. Save failure retains pending state;
repeat contact cannot duplicate the profile discovery or reward.

## Failure And Retry Contract

Oxygen or health failure inside the hub immediately uses the existing failed
expedition lock. Movement and interaction stop; the player cannot continue
exploring before Retry.

Retry abandons the entire unbanked round trip and reloads the canonical
`production_level_01` boat state. It restores exterior/interior pickups,
materials, biological cargo, cradle/core availability, pending discovery, and
other unbanked source state. Already committed profile discoveries remain.
Hazard interruption that does not fail the player cancels partial Cutter
progress without consuming the core.

Manual reset follows the same unbanked restoration rule. The interior never
becomes a respawn, refill, save, bank, or night boundary.

## Ownership

| Owner | Responsibility |
| --- | --- |
| Expansion 18 source helpers | immutable entrance, interior, core, labels, cameras, provenance |
| map/progression validators | schema, reciprocal pair, prerequisite, topology, non-circular journey |
| `GreyboxWorld` | source loading, rendering, collision, and read-only queries |
| focused transition state | exceptional round-trip phase, identity, and anti-duplication coordination |
| `SortieState` | active sortie, oxygen, held salvage cargo |
| day/health/material/biological owners | retain their existing live values across map legs |
| Cutter controller | active-tool eligibility, range, held progress, cancellation, completion |
| focused core-recovery owner | cargo guard, live consumed state, pending core transaction |
| `ExpeditionDiscoveryState` | pending core and canonical boat commit |
| `ExpansionProfileState` | exact-once committed core discovery |
| canonical boat owners | offload, commit, refill, night, expedition completion |
| `main.gd` | initialization, delegation, map-node replacement, and presentation refresh only |

## Validation Obligations

Issues #1193-#1200 must prove:

- exact fields, ids, references, reciprocal pairing, and forbidden metadata
- source-first generation and repeatability for both maps
- footprint reachability from exterior boat to entrance, through the interior,
  back to the exterior, and finally to the canonical boat
- prerequisite-gated `E/ACT` entry and unchanged legacy connector behavior
- continuous oxygen, daylight, health, cargo, plan, and run totals
- no interior refill, bank, commit, night, completion, or duplicate state
- deliberate Cutter interaction, full-cargo safety, held core, paired return,
  exact-once boat commit, profile reload, and save-failure retention
- oxygen/health failure lock, canonical Retry, and full unbanked restoration
- focused journey smoke, desktop/mobile captures, intentional baseline review,
  and exact-SHA public Web initialization

Player-experience issue #1201 must remain open until the owner gives GO or a
bounded HOLD. #52/#53 remain deferred optional slice-03 presentation work.

## Non-Goals

No normal connector traversal, fast travel, destination menu, shortcut,
second interior, terrain-scale expansion, new recipe/capability/material,
scanner sequence, enemy, weapon, economy, inventory screen, broad HUD/art
replacement, vehicle, procedural map, or Expansion 19 work belongs here.
