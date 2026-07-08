# Controlled Gameplay Pass 08 Source Rules

Date: 2026-07-08

Issue: #182 `Document Pass 08 route-scale source rules`

Related docs:

- `docs/current/CONTROLLED_GAMEPLAY_PASS_08_PLAN.md`
- `docs/current/CONTROLLED_GAMEPLAY_PASS_08_SEGMENT_DECISION.md`
- `docs/MAP_SPEC.md`
- `docs/current/ARCHITECTURE.md`

## Decision

Pass 08 may add one tiny source-authored route extension in `production_slice_01`:

```text
southwest_return_pocket_extension
```

The change should activate the lower-left return pocket near `salvage_return_branch` as a small optional route beat. It must stay smaller than whole-map productionization and must preserve the existing default-slice loop.

## Allowed Source Changes

Pass 08 implementation issues may change:

- `tools/create_production_slice_map.py`
- generated `maps/production_slice_01.greybox.json`
- generated `references/greybox/production_slice_01.svg`
- focused production-slice-01 captures and accepted baselines only in the dedicated visual-review issue

Allowed map-source changes:

- one marker zone named `southwest_return_pocket_extension`
- one focused camera test if the existing lower-loop camera does not frame the pocket clearly
- a tiny terrain cleanup, alcove, connector, or return-pocket adjustment near the selected segment
- at most one small payoff or cue entity near the pocket
- source `intent` text that explains the route role

Any topology edit must be authored through the generator. Do not hand-edit Godot scene geometry, collision, runtime nodes, or camera transforms.

## Terrain Rules

The selected terrain work must:

- stay near the lower-left return pocket and lower-loop route
- avoid the entry shaft and boat spawn
- avoid the `salvage_deep_right_cache` timed-salvage pocket
- avoid the Pass 07 `hazard_right_branch` pressure corridor
- preserve sealed crop edges so the player cannot leave the focused slice
- preserve reachability from the boat entry to all intended gameplay entities and extraction
- keep collision generated from JSON terrain

If the chosen topology edit requires broad terrain churn, stop and document a blocker instead of expanding scope.

## Payoff/Cue Rules

The route extension may add at most one small payoff or cue.

Preferred options:

- one `common` salvage target
- one marker-style return cue
- one non-gameplay review marker

Avoid:

- another timed-salvage target
- a new high-value deep-route reward unless a later plan explicitly chooses it
- new scoring rules
- new route outcome categories
- new inventory, economy, upgrade, tool, or save systems

If a salvage entity is added, it must use existing schema:

- `type: "salvage"`
- valid `kind`
- optional `tier`, preferably omitted or `common`
- in-bounds, non-solid, and reachable

## Runtime Rules

Pass 08 should not change runtime behavior unless a later issue documents a very small hook for smoke or capture setup.

Preserve:

- boat entry and extraction semantics
- cargo capacity and banking
- tier-derived salvage score
- timed-salvage progress, cancel, completion, hazard reset, and oxygen reset
- hazard warning/contact/reset behavior
- Pass 07 route-specific `hazard_right_branch` warning text
- oxygen drain, refill, failure, completion bonus, and result-panel semantics

## Validation Rules

After any source or generated-map change, run:

```powershell
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
```

Reachability must include:

- boat entry to the Pass 08 segment
- Pass 08 segment back to boat extraction
- existing safe route
- existing deep route
- existing timed-salvage target
- existing hazards and salvage

## Smoke Rules

Pass 08 should add one focused smoke, expected as:

```text
--smoke-pass-08-route-extension
```

The smoke should report:

- segment id
- any Pass 08 target/cue id
- route reach/return state
- held cargo
- banked score
- oxygen
- confirmation that existing deep-route pressure remains intact

Existing smokes should remain stable:

- `--smoke-production-slice-route`
- `--smoke-safe-deep-route-choice`
- `--smoke-pass-07-hazard-route-pressure`
- `--smoke-timed-salvage`
- `--smoke-hazard-pressure`
- `--smoke-oxygen-pressure`
- `--smoke-cargo-capacity`

## Capture And Baseline Rules

Pass 08 should add one focused route-extension capture before visual baseline acceptance.

The focused capture should:

- load `production_slice_01`
- frame the selected southwest pocket
- show the player, relevant cue/payoff, route context, and compact overlay
- write to a focused review folder
- not accept or replace baselines

Visual baseline acceptance must be a later issue. Before accepting anything:

- regenerate only affected captures
- run comparison sheets
- accept only intentional route-extension differences
- confirm player, boat, timed-salvage marker, Pass 07 marker, props, camera framing, and unrelated slices remain stable
- do not commit `.import` sidecars

## Web Preview Rules

After runtime/source and visual review land:

- confirm the relevant `Godot Web Export` run succeeded
- confirm the relevant `Godot Smoke` run succeeded
- verify `https://joeypshell.github.io/oceangame2/` with `tools/check_web_preview.cjs`
- record deployed `build_info.json` metadata in a current-state doc

## Deferred Work

Keep out of Pass 08:

- full-map productionization
- production slices 02-04 changes
- slice-03 polish #52/#53 unless slice-03 presentation becomes the selected goal
- broad art replacement
- economy, upgrades, inventory, enemies, procedural generation, save files, or new tool systems
