# Simple Diver Game 09 Tool And Resource Contract

Date: 2026-07-09

Issue: #649
Milestone: Simple Diver Game 09 `2D Subnautica Expansion Planning`

## Decision

The first expansion adds one capability, `survey_scanner_1`, and one corresponding `survey` interaction. It does not add an inventory, loadout, crafting, battery, consumable, or resource-stack system.

The scanner is a permanent profile capability after one boat-side unlock. It lets the player investigate the source-authored slice-02 anomaly through a timed in-range interaction while oxygen continues to drain. Completion creates expedition-level pending discovery, not cargo; the discovery becomes durable only through the return/commit rules in the state contract.

This mechanic serves the anomaly-survey experience by turning the final-dive signal, prior salvage payout, route knowledge, interaction time, and return risk into one connected decision.

## System Vocabulary

### Interaction

An authored action performed at a world target. Interaction rules own timing, cancel/complete behavior, and feedback, but do not imply an inventory item.

Current salvage interactions remain:

- `instant`: immediate salvage pickup
- `timed_salvage`: continuous in-range progress, then held cargo
- `pry_salvage`: staged in-range progress, then held cargo

First expansion interaction:

- `survey`: continuous in-range anomaly scan, then pending discovery

### Capability

A durable permission or method the diver knows/has available. A capability is not a scene node, cargo entry, stack, consumable, or equipment slot.

First expansion capability:

- `survey_scanner_1`

### Resource

Only these resource-like values exist in the first expansion:

- salvage cargo: existing held capacity and banking rules
- wallet: existing session payout currency
- capability IDs: minimal profile unlock facts
- discovery IDs: pending expedition state or completed profile facts

There are no ore/material stacks, recipes, components, fuel, batteries, scanner charges, food, repair parts, or craftable items.

## Survey Scanner Unlock

- The final-dive signal must be completed in the current progression path before the scanner offer appears.
- Unlock is available only at the canonical slice-01 boat/extraction context.
- It is a one-time purchase using the existing wallet, not a new currency.
- The implementation contract must choose a cost reachable through the existing release journey and verify affordability; this planning contract does not set a balance number.
- Successful purchase records `survey_scanner_1` in the minimal profile capability set and deducts wallet once.
- Already-unlocked profiles never pay again, even though wallet itself remains session-only.
- Insufficient funds leaves state unchanged and gives compact existing-style feedback.

The scanner has no equip/unequip step. Once unlocked, it is always available at valid survey targets so the project does not need a loadout screen or input-mode selector.

## Survey Interaction

At a valid source-authored anomaly target:

1. Without `survey_scanner_1`, show one compact requirement prompt and do not start progress.
2. With the capability, staying in range advances one continuous survey timer.
3. Oxygen and normal route/hazard pressure continue during the interaction.
4. Moving outside range cancels partial progress; no staged progress is saved.
5. Completion records one pending discovery ID and shows a compact `Survey complete - return to boat` message.
6. The target does not disappear into held cargo and does not add salvage score directly.
7. While that discovery is pending or completed, the target cannot produce a duplicate pending record.

Use one pending discovery at a time in the first expansion. This is an expedition-state constraint, not an inventory capacity UI.

## Failure And Return Rules

- `R`, hazard restoration, or oxygen failure clears partial survey progress and any uncommitted pending discovery.
- Scanner ownership remains profile state and is never consumed by use or failure.
- Connector travel preserves a completed pending discovery while map-leg oxygen/cargo/objective state resets normally.
- Canonical boat return commits the pending discovery exactly once.
- A committed discovery survives retries and process restart once profile storage is implemented.
- Repeating a completed target may show a compact already-surveyed state, but it must not repay, duplicate, or create stale pending feedback.

## Feedback Boundary

Required compact states:

- boat unlock available / insufficient funds / scanner unlocked
- scanner required at anomaly
- survey progress with target label and percentage/bar
- survey interrupted
- survey complete, return to boat
- discovery committed
- already surveyed

Use the existing status/result overlay hierarchy and one small in-world affordance. Do not add an inventory panel, radial tool menu, crafting screen, recipe list, scanner viewport, journal, or full research UI.

## Compatibility With Existing Salvage

- Instant, timed, and pry source fields and controllers keep current behavior.
- Survey targets are not salvage and must not be counted by cargo capacity, salvage totals, score, route objective salvage requirements, or restore-salvage logic.
- Existing cargo pressure still matters because optional salvage can consume capacity/time on the anomaly route, but survey completion itself uses no cargo slot.
- Existing timed/pry reset and cargo-full smokes remain unchanged.
- The survey implementation should use a focused sub-500-line controller rather than adding another branch to either salvage controller.

The later source contract should give survey targets a dedicated source collection or explicit non-salvage entity type. Do not disguise the anomaly as a salvage entity solely to reuse collection code.

## Ownership Boundary

| Concern | Owner |
| --- | --- |
| Scanner ownership/profile serialization | Focused profile/capability state owner |
| Boat-side unlock transaction | Focused scanner unlock helper using the existing wallet API |
| Survey source metadata | Slice generator plus MAP_SPEC/validator contract |
| Survey timing/cancel/complete | Focused survey interaction controller |
| Pending/committed discovery | Expansion state owner from #648 |
| Progress/result feedback | Existing overlay/result orchestration consuming helper reports |
| Deterministic checks | New survey smoke helper, not near-limit existing helpers |

`main.gd` should delegate and coordinate these owners; it must not become the primary data model for scanner ownership or survey progress.

## Meaningful-Change Check

`survey_scanner_1` passes the AGENTS.md filter because it:

- turns the final-dive signal into a concrete curiosity payoff
- uses existing salvage payout for one preparation choice
- makes a remembered connector route relevant again
- adds oxygen/time commitment at a distinct destination
- creates a risky return with a pending non-cargo result
- leaves a durable discovery and next lead after success

It would fail the filter if implemented only as a new key prompt, generic item schema, or menu without the authored anomaly route and return consequence.

## Explicitly Deferred

- equipment slots and loadouts
- inventory or cargo item grids
- scanner battery, charge, durability, repair, or upgrades
- raw materials, recipes, stations, crafting time, or recipe unlocks
- multiple tools or survey target families
- persistent wallet or migration of existing upgrades to profile state
- broad economy rebalance

## Future Verification Expectations

A focused smoke should prove unlock gating/payment/idempotence, capability persistence, no-cargo survey progress/cancel/complete, oxygen drain, pending discovery, reset/failure cleanup, connector preservation, boat commit, and already-completed behavior while existing salvage smokes remain green.

## Planning Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
