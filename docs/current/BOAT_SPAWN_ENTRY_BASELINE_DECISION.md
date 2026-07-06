# Boat Spawn Entry Baseline Decision

Date: 2026-07-06

Issue: #86 `Decide boat spawn entry art baseline acceptance`

## Decision

Accept the #85 boat spawn entry art pass as the current prototype baseline.

The `boat_spawn_01.png` asset is approved for current prototype use. The accepted `production_slice_01` visual baseline has been updated to include the new top-water boat/entry craft.

## Review Result

Reviewed artifacts:

- `references/asset_reviews/boat_spawn_01_review.png`
- `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- `visual_captures/production_slice_01/production_slice_entry_shaft.png`
- `visual_captures/production_slice_01/production_slice_return_to_boat.png`
- `visual_captures/production_slice_01_debug/production_slice_entry_shaft.png`

The expected visual difference is limited to the top-water boat/entry craft in default-slice views that include the boat. The source-positioned hatch/tether cue remains tied to the authored entry cell, and debug entry/extraction markers remain visible in debug captures.

Reference slices 02-04 use in-water relay extraction instead of `boat_spawn`, so their accepted baselines remain unchanged.

## Accepted Baseline Update

Updated accepted baseline:

```text
visual_baselines/production_slice_01_accepted/
```

Command:

```bash
python tools/manage_production_slice_baseline.py accept
```

The acceptance command replaced the six configured slice-01 baseline PNGs and the baseline manifest. It did not accept or change slice-02, slice-03, or slice-04 baselines.

## Verification

Completed:

```bash
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

The regenerated slice-01 baseline review sheet now shows no accepted/current differences after acceptance.

Follow-up:

- #87 verifies the public Web preview after the boat entry art pass deploys.
