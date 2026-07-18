# OceanGame Expansion 13 Owner-HOLD Correction Visual And Web Verification

Date: 2026-07-17

Issue: #1009

Runtime candidate: `86ba106eff4c703d9b0d5e4ac6f93735af49857e`

## Result

**Technical PASS. Player GO was later recorded in #969 after the bounded audio
interlude and owner review of the final exact runtime.**

Issues #1000-#1009 now provide deliberate shared tool use, compact desktop and
mobile tool presentation, named material sprites, a separate +300 sealed-wreck
salvage payoff, failure-safe pending navigation data, exact-once boat
commitment, deterministic evidence, focused captures, and exact-SHA Web
verification. Automation does not prove clarity, engagement, or player GO.

- Public preview: `https://joeypshell.github.io/oceangame2/`
- Fresh owner review:
  `https://joeypshell.github.io/oceangame2/?review=86ba106eff4c703d9b0d5e4ac6f93735af49857e`
- [Godot Web Export run 29619027177](https://github.com/joeypshell/oceangame2/actions/runs/29619027177): success

The later documentation/baseline merge records this decision; it is not a new
runtime candidate.

## Visual Decision

The `production_level_01` baseline is accepted from exact runtime `86ba106`.
All comparison sheets were rendered and inspected before acceptance.

Accepted intentional differences from the prior `89371d6` baseline are:

- the compact active-tool HUD on desktop and mobile
- scanner, cutter, and shock-prod selected-tool presentation
- source-authored titanium ingot, folded rubber, and spring-like coil sprites
- the review build label advancing from `89371d6` to `86ba106`
- focused wrong-tool guidance, deliberate cutter progress, separate +300 and
  pending navigation-data feedback, boat commitment, and southeast lead

Stable unchanged areas are terrain, collision-facing edges, boat, diver,
camera framing, lighting, background layers, unrelated props, and the accepted
HUD outside the selected-tool surface, and the accepted slice-01 through
slice-04 baselines. Only the 14 full-level views were
accepted. After acceptance, all 14 accepted/current hashes match and every
comparison difference column is black.

The 32 focused correction PNGs remain ignored under
`visual_captures/expansion_13_scanner_cutter_correction/`. Two exact-runtime
runs produced 32/32 identical SHA-256 hashes. No focused capture, `.import`
sidecar, cache, or unrelated generated file entered the baseline.

## Browser Evidence

The public checker independently verified deployed runtime `86ba106`:

- external `build_info.json` reports the exact 40-character SHA
- root and fresh-review URLs initialize `production_level_01`
- an explicit slice-review URL initializes `production_slice_01` on desktop/mobile
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` over an 844x390 visual viewport with zero offset
- mobile touch differences: stick-down `8.60`, oxygen `4.91`, build `5.60`,
  use `5.10`; all exceed the minimum `2`
- framing mean difference: `1.35`, below the maximum `18`
- no failed requests, missing assets, `SCRIPT ERROR`, or Godot `ERROR:` output

Independent desktop and mobile screenshots were inspected. The canvas is top
anchored, the mobile controls remain reachable, the compact tool HUD does not
overlap them, and the expected aspect-preserving side bars remain inside the
canvas. Chromium emitted only allowed software-WebGL fallback and `ReadPixels`
performance warnings.

## Player Gate Outcome

The owner later reviewed final exact runtime `ede39d1`, which includes this
accepted visual correction plus the bounded audio interlude, reported the
corrected experience was fine, and gave GO through #969. The final decision is
recorded in `OCEANGAME_EXPANSION_13_CLOSEOUT.md`; this document remains the
exact visual-baseline and Web evidence for runtime `86ba106`.

## Verification

```powershell
python tools/write_build_info.py
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-13-scanner-cutter-correction
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-09-full-level
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_level_01 accept
python tools/manage_production_slice_baseline.py check-clean --all-slices
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 86ba106eff4c703d9b0d5e4ac6f93735af49857e
python tools/check_file_lengths.py
git diff --check
```
