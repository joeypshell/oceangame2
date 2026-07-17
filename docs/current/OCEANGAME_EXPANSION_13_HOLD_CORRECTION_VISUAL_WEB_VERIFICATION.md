# OceanGame Expansion 13 HOLD Correction Visual And Web Verification

Date: 2026-07-17

Issues: #989 focused capture, #990 visual review and Web verification

Status note: this document remains the exact technical evidence for runtime
`89371d6`. Its five-unfamiliar-player gate was superseded by the project
owner's HOLD review and the bounded #1000-#1009 correction documented in
`OCEANGAME_EXPANSION_13_OWNER_HOLD_CORRECTION_PLAN.md`.

## Result

**PASS for technical readiness. Player approval remains open in #969.**

The corrected scanner-to-cutter journey is deployed at exact runtime commit
`89371d6a56d672c6cb8471f696b5986357ed8913` (`89371d6`). The verification
merge that records this decision is documentation and baseline evidence, not a
new runtime candidate.

- Public preview: `https://joeypshell.github.io/oceangame2/`
- Fresh-profile review:
  `https://joeypshell.github.io/oceangame2/?review=89371d6a56d672c6cb8471f696b5986357ed8913`
- [Godot Web Export run 29603240947](https://github.com/joeypshell/oceangame2/actions/runs/29603240947): success

## Visual Decision

The corrected `production_level_01` full-level baseline is accepted from
runtime `89371d6`. The comparison sheet was rendered and inspected before
acceptance. Two consecutive full-level and focused capture runs produced
byte-identical output across all 28 PNGs.

Accepted intentional differences are limited to:

- replacing the generic lower-right survey ring with a physical green
  maintenance case in its source-authored location
- the case appearing at the edge of a few established camera views
- removal of the old generic anomaly-ring presentation
- the review-only build label advancing from `d864a9e` to `89371d6`
- focused transient scanner feedback: forward cone, acquired-target bracket,
  miss feedback, timed progress, pending return, committed cutter recipe, and
  sealed-target payoff

Terrain topology, collision-facing edges, boat, diver, camera framing,
lighting, unrelated props, and unrelated HUD presentation remained stable.
The accepted slice-01 through slice-04 baselines and comparison sheets did not
change.

Only the full-level baseline was accepted. Focused correction captures remain
ignored under `visual_captures/expansion_13_scanner_cutter_correction/`.
No `.import` sidecar, generated cache, or focused capture entered the baseline.
After acceptance, all 14 configured current and accepted full-level images are
byte-identical.

## Browser Evidence

`tools/check_web_preview.cjs` independently verified the public Pages build:

- external metadata reports exact SHA
  `89371d6a56d672c6cb8471f696b5986357ed8913`
- root and fresh-review URLs initialize `production_level_01`
- explicit review fallback initializes `production_slice_01` on desktop and
  mobile with isolated profile state
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` over an 844x390 visual viewport with zero offset
- mobile touch differences: stick-down `8.60`, oxygen `4.91`, project `5.60`,
  attack `4.93`; all exceed the minimum `2`
- framing mean difference: `1.29`, below the maximum `18`
- no failed requests, missing assets, `SCRIPT ERROR`, or Godot `ERROR:` output

Chromium emitted only the allowed software-WebGL fallback and `ReadPixels`
performance warnings. They did not affect initialization, input, framing, or
network checks.

## Player Gate

#969 and milestone #39 remain open. Owner playtesting plus deterministic
validation is the current prototype gate; outside playtests are encouraged but
not a numeric blocker. The next owner replay follows #1000-#1009 and should
confirm whether the player can:

1. follow the broad maintenance clue beyond the east current
2. deliberately face and scan the physical case with `Q/SCAN`
3. understand that the cutter blueprint is pending until boat return
4. see the Ti2/Coil1 recipe only after commitment and build it at night
5. return to the remembered sealed wreck for the +300 payoff and next mystery

Automation proves technical readiness only. It cannot claim clarity,
engagement, payoff, or another-expedition motivation.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-09-full-level
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-13-scanner-cutter-correction
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_level_01 accept
python tools/manage_production_slice_baseline.py check-clean --all-slices
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 89371d6a56d672c6cb8471f696b5986357ed8913
python tools/check_file_lengths.py
git diff --check
```
