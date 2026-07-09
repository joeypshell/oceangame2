# Pass 22 Destination Payoff Visual Baseline Decision

Date: 2026-07-09

Issue: #509 `Review Pass 22 destination payoff visual impact`
Implementation issues: #502-#508

## Decision

Do not accept or replace any production-slice visual baselines for Pass 22.

Pass 22 added one source-authored destination cache in `production_slice_04`, compact runtime feedback, deterministic smoke coverage, and a focused review capture command. The normal production-slice baseline comparison remains clean across slices 01-04, so no terrain, camera, sprite, overlay, or accepted-baseline update is needed.

## Reviewed Artifacts

- Normal baseline comparison sheets: `references/asset_reviews/production_slice_01_visual_baseline_review.png` through `production_slice_04_visual_baseline_review.png`
- Accepted baselines: `visual_baselines/production_slice_01_accepted/` through `production_slice_04_accepted/`
- Focused review command: `--capture-pass-22-destination-payoff`
- Focused review output path when local capture is available: `visual_captures/pass_22_destination_payoff/production_slice_04_pass_22_destination_payoff.png`

## Review Result

`python tools/manage_production_slice_baseline.py check-clean --all-slices` reported:

```text
production_slice_01: clean
production_slice_02: clean
production_slice_03: clean
production_slice_04: clean
```

The intentional Pass 22 visible change is runtime/contextual only:

- collecting `slice_04_destination_cache` shows compact overlay feedback: `Destination cache +300`
- the focused capture command frames that state for review when screenshot capture is available

The following remained stable in normal production-slice baseline scope:

- terrain and collision presentation
- camera framing
- player, boat/base, salvage, hazard, and connector visuals
- normal review overlay layout
- existing production-slice baseline images

## Scope Confirmation

This decision does not change or accept changes to:

- map source data
- generated greybox references
- accepted visual baselines
- `.import` sidecars or local Godot cache files
- public Web preview deployment state

## Verification

Commands run:

```powershell
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

The focused local headless capture command was attempted under #508 and timed out before writing a PNG on this setup, consistent with the project warning that local headless screenshot capture may not work. No generated capture was committed.

## Follow-Up

Verify the public Web preview under #510 after the Pass 22 commits deploy.
