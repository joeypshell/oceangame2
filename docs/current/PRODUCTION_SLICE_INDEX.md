# Production Slice Index

Date: 2026-07-06

Issue: #66 `Add production slice status index`

## Purpose

Use this index as the quick source-of-truth for the current focused production slices. It summarizes what each slice is meant to test, how it is loaded, and which validation and visual-baseline artifacts protect it.

Detailed rationale remains in the slice decision, evaluation, and baseline docs linked below. This file is an index, not a replacement for those records.

## Slice Summary

| Slice | Role | Source Bounds | Entry And Extraction | Preview Status | Baseline Status |
|---|---|---:|---|---|---|
| `production_slice_01` | Top-center entry hub and first-area onboarding slice | `x=58, y=0, w=72, h=84` | `boat_spawn` at top water | Default Godot and public preview map | Accepted baseline at `visual_baselines/production_slice_01_accepted/` |
| `production_slice_02` | Lower-right later-game chamber route and relay-base proof | `x=88, y=78, w=66, h=72` | In-water `spawn` plus `base` relay extraction | Reference slice only | Accepted baseline at `visual_baselines/production_slice_02_accepted/` |
| `production_slice_03` | Upper-left compact connector / landmark room-cluster slice | `x=0, y=8, w=76, h=82` | In-water `spawn` plus `base` relay extraction | Reference slice only | Accepted baseline at `visual_baselines/production_slice_03_accepted/` |
| `production_slice_04` | Lower-left connector / return-loop slice with curved corridor movement | `x=0, y=86, w=88, h=50` | In-water `spawn` plus `base` relay extraction | Reference slice only | Accepted baseline at `visual_baselines/production_slice_04_accepted/` |

## Source And Review Artifacts

| Slice | Map Source | Generator | SVG Preview | Source/Render/Collision Review |
|---|---|---|---|---|
| `production_slice_01` | `maps/production_slice_01.greybox.json` | `tools/create_production_slice_map.py` | `references/greybox/production_slice_01.svg` | `references/greybox/production_slice_01_source_render_collision_review.png` |
| `production_slice_02` | `maps/production_slice_02.greybox.json` | `tools/create_production_slice_02_map.py` | `references/greybox/production_slice_02.svg` | `references/greybox/production_slice_02_source_render_collision_review.png` |
| `production_slice_03` | `maps/production_slice_03.greybox.json` | `tools/create_production_slice_03_map.py` | `references/greybox/production_slice_03.svg` | `references/greybox/production_slice_03_source_render_collision_review.png` |
| `production_slice_04` | `maps/production_slice_04.greybox.json` | `tools/create_production_slice_04_map.py` | `references/greybox/production_slice_04.svg` | `references/greybox/production_slice_04_source_render_collision_review.png` |

## Local Launch And Smoke Coverage

| Slice | PowerShell Launch | Command Prompt Wrapper | Route Smoke Flag | CI Route Smoke |
|---|---|---|---|---|
| `production_slice_01` | `.\tools\open_godot_project.ps1 -Run -ProductionSliceMap` | `run-production-slice-01.cmd` | `--smoke-production-slice-route` | Yes |
| `production_slice_02` | `.\tools\open_godot_project.ps1 -Run -ProductionSlice2Map` | `run-production-slice-02.cmd` | `--smoke-production-slice-02-route` | Yes |
| `production_slice_03` | `.\tools\open_godot_project.ps1 -Run -ProductionSlice3Map` | `run-production-slice-03.cmd` | `--smoke-production-slice-03-route` | Yes |
| `production_slice_04` | `.\tools\open_godot_project.ps1 -Run -ProductionSlice4Map` | `run-production-slice-04.cmd` | `--smoke-production-slice-04-route` | Yes |

Local/editor review runs also expose the map selector in the overlay, so the supported review maps can be switched without relaunching.

## Capture And Baseline Artifacts

| Slice | Normal Captures | Debug Captures | Baseline Review Sheet | Notes |
|---|---|---|---|---|
| `production_slice_01` | `visual_captures/production_slice_01/` | `visual_captures/production_slice_01_debug/` | `references/asset_reviews/production_slice_01_visual_baseline_review.png` | Reconciled under #75 so the accepted default-slice baseline now covers the current six-view capture set. |
| `production_slice_02` | `visual_captures/production_slice_02/` | `visual_captures/production_slice_02_debug/` | `references/asset_reviews/production_slice_02_visual_baseline_review.png` | Accepted after the original framing and relay-readability blockers were resolved; refreshed under #71 for the prop sprite pass. |
| `production_slice_03` | `visual_captures/production_slice_03/` | `visual_captures/production_slice_03_debug/` | `references/asset_reviews/production_slice_03_visual_baseline_review.png` | Keep as a connector/landmark reference; refreshed under #71 for the prop sprite pass; optional #52/#53 polish is deferred unless the accepted baseline intentionally changes. |
| `production_slice_04` | `visual_captures/production_slice_04/` | `visual_captures/production_slice_04_debug/` | `references/asset_reviews/production_slice_04_visual_baseline_review.png` | Keep as a lower-left loop reference; refreshed under #71 for the prop sprite pass; curved-corridor stair steps are intentional for this prototype pass. |

## Decision Docs

| Slice | Decision And Evaluation Records |
|---|---|
| `production_slice_01` | `docs/current/PRODUCTION_SLICE_SELECTION_CRITERIA.md`, `docs/current/PRODUCTION_SLICE_01_VISUAL_BASELINE_RECONCILIATION.md`, plus issue history #21, #23, #31, #36, #75 |
| `production_slice_02` | `docs/current/PRODUCTION_SLICE_02_DECISION.md`, `docs/current/PRODUCTION_SLICE_02_EVALUATION.md`, `docs/current/PRODUCTION_SLICE_02_VISUAL_BASELINE_DECISION.md` |
| `production_slice_03` | `docs/current/PRODUCTION_SLICE_03_DECISION.md`, `docs/current/PRODUCTION_SLICE_03_EVALUATION.md`, `docs/current/PRODUCTION_SLICE_03_VISUAL_BASELINE_DECISION.md`, `docs/current/PRODUCTION_SLICE_03_DEFAULT_PREVIEW_DECISION.md` |
| `production_slice_04` | `docs/current/PRODUCTION_SLICE_04_DECISION.md`, `docs/current/PRODUCTION_SLICE_04_EVALUATION.md`, `docs/current/PRODUCTION_SLICE_04_VISUAL_BASELINE_DECISION.md` |

## Next-Use Guidance

Before changing terrain, camera framing, entity visuals, or route design for an accepted slice, compare against that slice's accepted baseline and decide whether the change is an intentional replacement or a regression.

Use `python tools/manage_production_slice_baseline.py compare-all` to refresh all accepted baseline/current/difference review sheets before reviewing a controlled visual change.

Do not promote another slice to the default preview as part of unrelated visual or tooling work. The default-preview decision should remain a separate scoped issue with launch smoke, route smoke, capture checks, docs, and web-preview expectation updates.
