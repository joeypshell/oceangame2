# Locked Cache Progression Contract

Date: 2026-07-09

Issue: #445 `Define treasure chest, key, and locked-cache progression contract`

## Decision

Use small source-authored containers as progression beats, not as a full inventory system. The first implementation target should be one `upgrade_chest` that grants session wallet or one simple session reward in `production_slice_01`.

The contract also reserves `key_chest` and `locked_salvage_cache` for later, but they should not be implemented together with the first upgrade chest.

## Supported Container Types

- `upgrade_chest`: opened directly, grants wallet or one session upgrade/reward flag.
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
- `reward_type`: `wallet`, `upgrade_flag`, `key_flag`, or `salvage_unlock`.
- `reward_id`: lower_snake_case reward id, key id, upgrade id, or target salvage id depending on `reward_type`.

Optional fields:

- `reward_amount`: positive integer for `wallet` rewards.
- `required_key_id`: lower_snake_case key flag required by `locked_salvage_cache`.
- `lock_id`: lower_snake_case lock grouping for smoke/capture reporting.
- `route_context`: lower_snake_case route grouping.
- `intent`: human-readable source note.

Source metadata must not author runtime opened state, save state, score formulas, oxygen values, cargo limits, collision, terrain edits, or UI layout.

## Runtime Semantics

Opened container state is session-local. It survives normal run reset, hazard reset, oxygen failure, and world-slice transition during the current play session, but it is not a persistent save system.

`upgrade_chest` and `key_chest` rewards apply immediately when opened and do not enter cargo. They are not banked at extraction.

`locked_salvage_cache` can require a key flag before opening. Once opened, its salvage reward should follow normal salvage semantics: held cargo must be banked at extraction, cargo-full must not delete the reward, and oxygen or hazard failure restores unbanked held salvage.

Manual reset should preserve opened container rewards that already updated session progression, but should restore any unbanked salvage reward from an opened cache.

## First Candidate

Use one `upgrade_chest` in `production_slice_01`, placed on an optional lower-loop or southwest-return detour where it rewards exploration without blocking the primary deep-cache objective. Issue #446 implements the first instance as `lower_loop_upgrade_chest`.

Recommended first metadata:

```json
{
  "id": "lower_loop_upgrade_chest",
  "container_type": "upgrade_chest",
  "x": 18,
  "y": 72,
  "w": 2,
  "h": 2,
  "display_label": "Upgrade chest",
  "interaction": "instant",
  "reward_type": "wallet",
  "reward_id": "upgrade_wallet_bonus",
  "reward_amount": 400,
  "route_context": "lower_loop_reward",
  "intent": "First small progression chest rewarding the lower-loop detour without adding inventory UI."
}
```

## Validation Expectations

Validation confirms container ids are unique, rectangles are in bounds/non-solid/reachable, labels are compact, reward ids use lower_snake_case, wallet rewards have positive amounts, locked caches reference an authored key id, and salvage unlocks reference an existing playable salvage entity.

## Verification For Implementation

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- focused chest/reward smoke
- focused chest/reward capture
- existing progression, salvage loop, cargo capacity, oxygen pressure, and route smokes
- `python tools/check_file_lengths.py`
- `git diff --check`
