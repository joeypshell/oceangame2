# OceanGame Expansion 05 State Contract

Date: 2026-07-10

Issue: #749 `Define Expansion 05 research and next-day ownership`

## Purpose

Lock durable, expedition, day, and presentation ownership for one practical mineral-research journey without changing the persisted profile shape or existing anomaly behavior.

## Supported Ids

- existing scanner capability: `survey_scanner_1`
- existing discovery: `lower_right_anomaly_discovery`
- new discovery: `upper_right_mineral_trace_research`
- new target: `upper_right_mineral_trace_survey`
- affected pool: `conductive_coil_pool`
- researched candidate: `material_coil_deep_cache`

These are separate ids. Completing the old anomaly does not complete mineral research, and the new finding does not replace the anomaly prerequisite used by existing projects.

## Profile Ownership

`expansion_profile_state.gd` owns committed discovery ids.

- `completed_discoveries` remains an ordered-on-write list of supported ids.
- The persisted object shape stays unchanged, so profile schema version 3 remains current.
- Valid v1-v3 payloads retain existing scanner, anomaly, material, project, cutter, and stabilizer state.
- A v3 profile may contain either, both, or neither supported discovery id.
- Unknown and duplicate discovery ids remain invalid.
- Committing an already-completed finding is idempotent.
- Storage failure leaves the durable discovery absent and the pending expedition finding available for a retry.

No material selection, route hint, pending state, or display text is persisted in the profile. Those values derive from the committed id plus current source data.

## Pending Expedition Ownership

`expedition_discovery_state.gd` owns at most one uncommitted finding:

```text
idle -> survey complete -> pending -> canonical boat commit -> idle
```

The pending record contains only the source identity and commit contract needed across map transitions:

- discovery id
- source map id
- source target id
- commit map id
- commit entry id
- compact source-derived finding/result labels needed after leaving the source map

Rules:

- completing the same target while it is pending is idempotent
- another discovery cannot replace an existing pending finding
- source-authored connector travel preserves pending state
- entering open surface without reaching the canonical boat does not commit it
- manual reset, hazard contact, and oxygen failure clear it
- canonical `production_slice_01` / `surface_boat_entry` commits it exactly once
- commit records the discovery in the profile before pending state is cleared
- failed profile storage retains pending state and reports failure

Pending research is not cargo, salvage, score, a material, or a day-level committed discovery until boat commit succeeds.

## Survey Runtime Ownership

The existing survey runtime coordinates target state and delegates timing to `survey_interaction_controller.gd`.

- Anomaly targets preserve their session lead requirement and existing scanner-unlock journey.
- Resource targets do not reactivate or consume the old anomaly lead.
- Every target still requires its source-authored scanner capability.
- Entering a valid target begins automatic timed survey progress.
- Leaving range cancels partial progress.
- A completed durable target reports completed rather than creating another pending finding.
- Target-specific clue, finding, and result text comes from validated source metadata.
- Compatibility methods used by existing anomaly/project smokes retain their current meaning.

The runtime does not decide material candidate selection.

## Day And Material Ownership

`expedition_day_state.gd` owns the per-day, per-map material selection cache.

1. The first material load for a map/day resolves source pools and stores selected candidate ids.
2. Research committed later that day cannot replace the stored selection.
3. `begin_next_day()` clears the selection cache and advances the deterministic day seed.
4. The next map load resolves the same pool against the now-committed profile discovery.
5. A researched pool selects from its validated researched candidate subset; unrelated pools use normal day rotation.

`material_candidate_selector.gd` owns deterministic selection from the effective candidate list. `material_runtime_controller.gd` supplies only committed discovery state and source pool data, then configures world candidates from the day-owned result.

The researched coil pool still selects exactly one candidate. Titanium selection, quantities, depletion, restoration, cargo, boat deposit, recipes, and scoring remain unchanged.

## Presentation Ownership

Validated source owns compact semantic text:

- clue: `Mineral trace | Composition unknown`
- finding: `Research: coils favor deep-cache machinery`
- next-day lead: `Research lead | Coils near deep-cache machinery`

Runtime decides when each line is eligible:

- clue while the incomplete resource target is relevant
- survey progress while inside the target
- finding after successful canonical boat commit
- lead when a fresh researched selection is active

A focused presentation helper should format the research lead. `main.gd` may order the line in the existing overlay but must not own research rules or copy source strings.

## Failure And Reload Matrix

| Event | Pending finding | Committed profile | Current-day selection | Future fresh selection |
| --- | --- | --- | --- | --- |
| Connector travel | preserved | unchanged | preserved | source-derived later |
| Manual reset | cleared | unchanged | preserved | source-derived later |
| Hazard | cleared | unchanged | preserved | source-derived later |
| Oxygen failure | cleared | unchanged | preserved | source-derived later |
| Boat commit succeeds | cleared | finding added | preserved | researched subset |
| Boat commit save fails | preserved | unchanged | preserved | normal until retry succeeds |
| Profile reload | no pending state | committed ids restored | new session/day state | researched subset when fresh |
| Begin next day | none expected | unchanged | cache cleared | resolved on map load |

## Compatibility Gates

- Existing anomaly lead, scanner purchase, survey timing, canonical commit, result text, and smoke flags remain unchanged.
- Existing cutter and stabilizer projects continue to require `lower_right_anomaly_discovery`, not the new research id.
- Expansion 03/04 material guarantees and profile project/capability pair rules remain unchanged.
- No inventory screen, field guide, research catalog, exact map marker, new recipe, or additional resource quantity is introduced.
