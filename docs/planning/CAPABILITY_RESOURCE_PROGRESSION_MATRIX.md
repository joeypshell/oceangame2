# Capability And Resource Progression Framework

Date: 2026-08-05

Status: directional design contract. Exact names, counts, placements, and balance belong to the milestone that implements each row.

## Purpose

Plan maps, materials, tools, weapons, wildlife, companion adaptations, and upgrades as one dependency system. This prevents isolated stat upgrades, progression blocked by random seeds, and map regions that do not pay off a capability.

The required pattern is:

```text
visible promise -> practical knowledge -> guaranteed materials
-> special component -> project -> changed capability -> remembered return payoff
```

The proposed companion path is separate from equipment crafting:

```text
meaningful shared experience -> individual memory -> night consolidation
-> visible adaptation -> changed exploration or protection payoff
```

## Progression Nouns

- Knowledge: a durable scan, survey, recovered plan, or analyzed sample that explains why a project is possible.
- Base material: a reusable mineral, salvage, fiber, glass, conductive, or structural input.
- Special component: a low-count wreck, environment, passive-wildlife, or enemy-derived input tied to the capability's function.
- Project: a compact night-phase requirement set. It is not a free-form crafting grid.
- Tool: an active interaction verb such as cut, pry, drill, sample, or clear.
- Suit capability: passive access or survival behavior such as oxygen, light, current resistance, or pressure protection.
- Weapon: an active combat option with a distinct tactical role.
- Memory: an exact-once individual record of a meaningful shared encounter.
- Adaptation: a deliberate night-consolidated change to one companion's body and behavior.
- Payoff: a new route, interaction, material class, research result, threat response, or mystery lead.

## Gate Grammar

| Gate | Default role | Without capability | With capability |
| --- | --- | --- | --- |
| Oxygen distance | Soft route/return gate | Risky scout or early return | Larger useful margin |
| Darkness | Soft information gate | Poor readability and uncertain risk | Clear navigation or signal reading |
| Current | Soft or authored hard traversal gate | Pushback, high effort, or denial | Stable crossing and return planning |
| Pressure | Hard safety gate | Clear safe denial | Access to deeper habitat |
| Sealed wreck/material | Hard tool gate | Readable required-tool feedback | New interaction and component |
| Enemy territory | Risk gate | Evade, abandon, or limited counterplay | Fight, disable, or prepared crossing |

Gates may block extraction of a resource or entry to a payoff, but required early materials must remain obtainable before the gate they unlock.

Do not add fast travel, pylons, elevators, or permanent route bypasses. The player's mastery and equipment may improve traversal, but the journey remains part of the game.

## Equipment And Companion Boundary

Equipment remains the predictable owner of hard geographic access. Companion
adaptations change what the pair can accomplish inside a region the diver can
already reach or survive.

| Pressure | Equipment responsibility | Companion opportunity |
| --- | --- | --- |
| Strong current | Propulsion fins permit required traversal | Hold position for a difficult scan, cut, sample, or defense |
| Darkness | Dive light permits readable navigation | Reveal behavior, hidden organisms, or threat cues |
| Pressure | Pressure equipment permits safe entry | Improve sensing, protection, or biological interaction |
| Enemy territory | Weapon/health preparation preserves direct agency | Warn, distract, interrupt, defend, or support retreat |

An adaptation must not silently bypass the equipment prerequisite that opens a
mandatory region. Occasional paired gates may be planned later only when the
progression graph proves both prerequisites and a non-circular payoff.

## Candidate Placement Contract

- Author geography, habitat rectangles, legal candidate cells, minimum counts, and gate relationships in source data or generators.
- Select daily opportunities deterministically from those candidates.
- Never spawn progression resources at arbitrary random coordinates.
- Every mandatory project input has a guaranteed reachable source under every supported seed.
- Bonus quantity, exact candidate, rare material, and optional opportunity may vary.
- Validators should reject solid, out-of-bounds, unreachable, circular, or capability-inappropriate placements.
- Map previews should distinguish debug candidate pools from active runtime selections without changing collision.

## Creature Resource Roles

| Creature role | Resource path | Combat expectation |
| --- | --- | --- |
| Passive wildlife | Sample, shed material, or careful harvest | None required |
| Defensive wildlife | Sample or harvest with retaliation risk | Avoid, disable, or fight |
| Territorial enemy | Defeat, stun, distract, or timed harvest according to contract | Prepared encounter |
| Predator | Advanced material after a dangerous encounter | Evade remains valid; fighting is costly |
| Study-only creature | Knowledge and project unlock | No resource farming |

Creature materials should express function. Examples remain provisional: luminous tissue for light/signal equipment, pressure membrane for deep protection, electrocytes for shock equipment, carapace for reinforcement, or fin/tendon samples for propulsion.

## Dependency Safeguards

- The first weapon uses non-enemy materials.
- A required enemy material cannot be locked behind the weapon upgrade that requires that same material.
- Required creature materials use low counts and guaranteed authored habitat candidates.
- Day-boundary replenishment is acceptable; a full breeding or ecosystem simulation is not required.
- Passive/nonlethal collection should remain available for some species, but hostile materials may legitimately require combat.
- Creature materials occupy cargo and are not secured until banked at the boat.
- Duplicate scans and already-completed knowledge should have a useful, bounded outcome rather than becoming dead interactions.
- No project should be only a wallet payment once typed materials exist.
- Major companion adaptations require distinct memories, not generic XP or repeated exposure. A material or biological catalyst may support a later adaptation but cannot substitute for its memory.
- Equipment capabilities use explicit ingredient recipes. Score may gate access to blueprint research later, but never substitutes for required materials.
- #825 gates the `propulsion_fins` recipe behind the guaranteed recovered `propulsion_fins_blueprint`; it does not settle whether future plans require overnight research or whether every known recipe builds during debrief.
- #829 makes fins a passive same-map current capability, moves the scanner promise and anomaly into the east pocket, and keeps `current_stabilizer` as a later optional advanced-current tier rather than a weapon prerequisite.
- #927 replaces scanner funding with a guaranteed blueprint plus Ti1/Coil1 night project. A reachable source-authored coil candidate is mandatory until committed research selects the deep-cache candidate on a fresh day. The nearby upper side-room cache remains optional score; light and scanner no longer have direct-score paths.
- Direct-score oxygen and cargo upgrades remain intentionally session-scoped. They do not substitute for durable equipment knowledge or materials.
- `python tools/audit_progression_graph.py` is the executable cross-map safeguard. Production map metadata owns authored relationships; `config/progression_contract.json` owns only runtime purchase/scoring relationships that maps cannot own.

## Preliminary Progression Matrix

| Milestone | Promise or pressure | Capability/project | Knowledge source | Input shape | Guarantee | Payoff |
| --- | --- | --- | --- | --- | --- | --- |
| Landed | Visible east current pocket | `propulsion_fins` then `survey_scanner_1` | Recovered fins plan, then scanner blueprint | Ti2/Rubber1, then Ti1/Coil1 | Same-map guaranteed journey | Returned anomaly reveals cutter plan |
| Expansion 03 | Readable sealed salvage/wreck interaction | First active tool, likely cutter-class | Wreck scan or recovered plan | Titanium/basic material plus ordinary special component | Shallow authored candidates | New component/material and next gate clue |
| Expansion 04 | Remembered current, darkness, pressure, or sealed route | First durable capability gate | Practical environment survey | Base materials plus themed non-hostile component | Pre-gate reachable sources | Authored area and meaningful reward |
| Expansion 05 | Unknown resource habitat or environmental behavior | Research/project knowledge | Scanner and sample analysis | Knowledge-first; no broad material expansion | Authored scannables | Better preparation and project unlock |
| Expansion 06 | Hostile territory on a valuable route | First weapon and health loop | Creature observation plus weapon plan | Non-enemy structural/mechanical inputs | Safe pre-combat sources | Fight-or-evade route decision |
| Expansion 07 | Valuable biological component | Weapon/suit upgrade | Creature scan and analyzed material | Base inputs plus low-count creature material | Guaranteed habitat candidate | New tactical behavior or access |
| Expansion 08 | Tomorrow-specific opportunity | Condition-informed loadout/project choice | Forecast and existing knowledge | Seed-selected authored opportunities | Mandatory floor plus optional variance | A reason to choose another day/route |
| Expansion 09 | New regional promise | Region-specific capability chain | Landmark, research, and mystery clues | Region materials plus prior capability | Cross-region dependency validation | Durable campaign progression |
| Proposed Expansion 19 | Rescued individual changes through shared dives | One memory-selected companion adaptation | Meaningful current or threat experience | No generic XP or score purchase in the proof | Exact-once source condition plus profile persistence | Immediate exploration or protection payoff and another-day motivation |

This matrix is sequencing guidance, not authorization to implement every named example. Each milestone plan must select one narrow row and lock exact source fields, dependencies, counts, failure rules, and validation.

## Required Issue Checklist

Every capability, material, tool, weapon, or creature-resource issue should answer:

- Where is the promise first seen?
- What exactly prevents use or access?
- What knowledge explains the solution?
- Which base materials are required?
- Is there a special component, and why does it fit?
- Where is every mandatory input guaranteed?
- Can the seed or enemy dependency make progression impossible?
- What changes after completion?
- What remains risky on the return journey?
- If a companion is involved, what exact experience creates its memory and why does its adaptation not replace the diver's access equipment?
- Which generator, validator, runtime owner, smoke, and capture prove the contract?
