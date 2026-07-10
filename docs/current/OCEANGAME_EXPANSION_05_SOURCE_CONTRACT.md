# OceanGame Expansion 05 Source Contract

Date: 2026-07-10

Issue: #749 `Define Expansion 05 research and next-day ownership`

## Purpose

Define the minimal JSON relationship between one resource survey and one research-informed material pool. Source describes the authored world promise; validators and runtime derive state from it.

## Resource Survey Target

The new record remains in top-level `survey_targets`:

```json
{
  "id": "upper_right_mineral_trace_survey",
  "target_type": "resource",
  "x": 69,
  "y": 41,
  "w": 2,
  "h": 2,
  "required_capability_id": "survey_scanner_1",
  "interaction": "survey",
  "interaction_seconds": 3.0,
  "interaction_label": "Survey mineral trace",
  "clue_label": "Mineral trace | Composition unknown",
  "finding_label": "Research: coils favor deep-cache machinery",
  "discovery_id": "upper_right_mineral_trace_research",
  "research_material_pool_id": "conductive_coil_pool",
  "route_context": "upper_right_current_pocket",
  "commit_map_id": "production_slice_01",
  "commit_map_path": "res://maps/production_slice_01.greybox.json",
  "commit_entry_id": "surface_boat_entry"
}
```

The rectangle is confirmed as an open, reachable 2x2 area below the existing valuable cache and beyond the gate boundary. The earlier schema draft at `68,38` intersected solid terrain and was corrected through source inspection before generated-map authoring.

Existing `target_type: "anomaly"` records keep their current required fields and session-lead behavior. New clue/finding/pool fields are required for `resource` and unsupported for `anomaly` in this pass.

## Researched Material Pool

The existing `conductive_coil_pool` gains:

```json
{
  "research_discovery_id": "upper_right_mineral_trace_research",
  "researched_candidate_ids": [
    "material_coil_deep_cache"
  ],
  "research_lead_label": "Research lead | Coils near deep-cache machinery"
}
```

These fields augment the existing pool. They do not replace:

- `candidate_ids`
- `selection_strategy: "day_rotation_v1"`
- `select_count: 1`
- `material_id: "conductive_coil"`

Without the committed discovery, selection uses all existing `candidate_ids`. With it, a fresh day selection applies the same deterministic selector to `researched_candidate_ids`.

## Validation Rules

For a `resource` survey target:

- `discovery_id` must be the supported research id and unique across survey targets.
- `research_material_pool_id` must reference an existing material pool in the same map.
- `clue_label` and `finding_label` must be non-empty, single-line, compact display-safe text.
- The clue must not name a candidate id or coordinates.
- The finding may name the material and broad source-authored habitat, not a coordinate or exact path.
- The normal survey rectangle, capability, interaction, commit reference, non-solid placement, bounds, and reachability rules still apply.
- The target must occupy existing open cells beyond the `upper_right_current_pocket_gate` boundary and use its route context.

For a researched material pool:

- all three research fields are required together
- `research_discovery_id` must match exactly one resource survey target that links back to the pool
- `researched_candidate_ids` must be a non-empty unique subset of normal `candidate_ids`
- the subset must contain at least `select_count` candidates
- every researched candidate must retain matching pool/material metadata and normal reachability
- `research_lead_label` must be non-empty, single-line, compact display-safe text without coordinates
- selected yield remains sufficient for every existing project recipe

Existing anomaly targets, unrelated material pools, and maps without research metadata remain valid and keep current behavior.

## Runtime-State Exclusion

Survey targets and material pools must not author:

- active/completed/pending/committed state
- current day, seed, selected/depleted candidate state, or profile state
- progress, oxygen, cargo, score, wallet, or payout
- save paths or result visibility state
- player position, exact route waypoints, or navigation arrows

The source strings are content, not state. Runtime eligibility derives from target state, profile discovery, and day selection.

## Source-Of-Truth Boundary

- Author the target and pool extension through a focused production-slice generator module.
- Regenerate `maps/production_slice_01.greybox.json` and `references/greybox/production_slice_01.svg`.
- Do not hand-edit generated JSON, Godot terrain, collision, scene geometry, or accepted captures.
- Terrain, collision, entries, extraction, connectors, salvage, hazards, camera tests, candidate positions, pool yield, and material projects remain unchanged.

## Required Negative Fixtures

Validator coverage should reject at least:

- resource target missing clue, finding, or pool link
- resource metadata on anomaly targets or unrelated collections
- unsupported/duplicate discovery id
- dangling or mismatched target-to-pool link
- incomplete research field group on a pool
- empty, duplicate, non-subset, or undersized researched candidates
- researched candidate with mismatched material/pool metadata
- multi-line/oversized or coordinate-like compact text
- authored runtime/profile/day-selection fields
- solid, out-of-bounds, unreachable, or wrong-side target placement
