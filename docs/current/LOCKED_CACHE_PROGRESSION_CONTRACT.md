# Locked Cache Progression Contract

Date: 2026-07-09

Issue: #445 `Define treasure chest, key, and locked-cache progression contract`

## Decision

Use small source-authored containers as progression beats, not as a full inventory system. An `upgrade_chest` may grant session wallet/state or one durable recovered-plan discovery already supported by the profile owner.

The contract also reserves `key_chest` and `locked_salvage_cache` for later, but they should not be implemented together with the first upgrade chest.

## Supported Container Types

- `upgrade_chest`: opened directly, grants wallet, one session flag, or one linked blueprint discovery.
- `key_chest`: opened directly, grants one session key flag.
- `locked_salvage_cache`: requires a key flag, then exposes or collects one authored salvage reward.

Defer `locked_route_marker`, full inventory UI, keyrings, loot tables, persistent save files, and multi-step chest chains.

## Source Metadata

Containers should be authored in a top-level `progression_containers` list so they stay separate from terrain collision, salvage entities, and marker-only route rectangles.

Required fields:

- `id`: unique lower_snake_case container id.
- `container_type`: `upgrade_chest`, `key_chest`, or `locked_salvage_cache`.
- `x`, `y`, `w`, `h`: tile rectangle for the container interaction zone.
- `display_label`: compact display-safe text.
- `interaction`: `instant`, `timed_salvage`, or `pry_salvage`; reuse existing interaction rules where possible.
- `reward_type`: `wallet`, `blueprint`, `upgrade_flag`, `key_flag`, or `salvage_unlock`.
- `reward_id`: lower_snake_case reward id, key id, upgrade id, or target salvage id depending on `reward_type`.

Optional fields:

- `reward_amount`: positive integer for `wallet` rewards; forbidden for `blueprint`.
- `required_key_id`: lower_snake_case key flag required by `locked_salvage_cache`.
- `lock_id`: lower_snake_case lock grouping for smoke/capture reporting.
- `route_context`: lower_snake_case route grouping.
- `intent`: human-readable source note.

Source metadata must not author runtime opened state, save state, score formulas, oxygen values, cargo limits, collision, terrain edits, or UI layout.

## Runtime Semantics

Opened wallet/flag container state is session-local. A blueprint reward uses existing durable profile discovery state, and that discovery restores the chest's opened visual after reload; no second inventory is introduced.

`upgrade_chest` and `key_chest` rewards apply immediately when opened and do not enter cargo. They are not banked at extraction.

`locked_salvage_cache` can require a key flag before opening. Once opened, its salvage reward should follow normal salvage semantics: held cargo must be banked at extraction, cargo-full must not delete the reward, and oxygen or hazard failure restores unbanked held salvage.

Manual reset should preserve opened container rewards that already updated session progression, but should restore any unbanked salvage reward from an opened cache.

## First Candidate

`lower_loop_upgrade_chest` remains at the reachable lower-loop detour. Issue #825 repurposes it from a wallet bonus into the guaranteed pre-fins recovered plan.

Recommended first metadata:

```json
{
  "id": "lower_loop_upgrade_chest",
  "container_type": "upgrade_chest",
  "x": 18,
  "y": 72,
  "w": 2,
  "h": 2,
  "display_label": "Fins blueprint chest",
  "interaction": "instant",
  "reward_type": "blueprint",
  "reward_id": "propulsion_fins_blueprint",
  "route_context": "lower_loop_reward",
  "intent": "Guaranteed recovered plan before the propulsion-fins gate."
}
```

## Validation Expectations

Validation confirms ids are unique, rectangles are in bounds/non-solid/reachable, labels are compact, wallet amounts are positive, and each blueprint reward links to exactly one material project's `required_discovery_id` without `reward_amount`.

## Verification For Implementation

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- focused chest/reward smoke
- focused chest/reward capture
- existing progression, salvage loop, cargo capacity, oxygen pressure, and route smokes
- `python tools/check_file_lengths.py`
- `git diff --check`
