# Living Expedition 03 Web Verification

Date: 2026-08-08

Issues:

- #1307 `Stop repeated Mica migration scans after identification`
- #1308 `Verify corrected Living Expedition 03 repeated-scan Web build`

## Result

**PASS for the corrected exact deployment, checkpoint startup, responsive
framing, mobile control dispatch, and deterministic repeat-scan behavior.**

- exact runtime SHA: `0e92dd77fa6dccf8cde4969111a101d225bd354e`
- build version: `0e92dd7`
- `git_ref`: `main`
- `dirty`: `false`
- generated UTC: `2026-08-08T09:31:27-05:00`
- [Web export and Pages run 31262131714](https://github.com/joeypshell/oceangame2/actions/runs/31262131714):
  export browser verification and GitHub Pages deployment passed
- [Correction PR #1309](https://github.com/joeypshell/oceangame2/pull/1309):
  repeat migration identification now stops immediately without replaying
  progress or feedback

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=0e92dd77fa6dccf8cde4969111a101d225bd354e`
- Living Expedition 03 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=0e92dd77fa6dccf8cde4969111a101d225bd354e&checkpoint=living_expedition_03_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=0e92dd77fa6dccf8cde4969111a101d225bd354e&map=production_slice_01`

## Exact Build Evidence

Public `build_info.json` reports the full SHA above, clean `main`, and the
generated timestamp above. The independent post-deployment checker confirmed:

- root and fresh review load `production_level_01`
- `living_expedition_03_start` loads an isolated profile on
  `production_level_01` with propulsion fins available
- the explicit fallback loads `production_slice_01`
- desktop canvas: 1280x720
- wide canvas: 1920x1080
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` with zero visual-viewport offset
- checkpoint touch differences: move-down `13.30`, oxygen `4.91`, cargo
  `5.50`, TOOL `5.52`, project `5.60`, day `5.40`, RESET `5.83`, ACT `5.17`,
  USE `5.10`, and BOND `5.82`, all above the required `2`
- root touch differences: move-down `8.60`; all command values match the
  checkpoint values and pass
- framing mean difference: `1.33`, below the maximum `18`
- no failed requests, page errors, uncaught browser exceptions, Godot
  `SCRIPT ERROR`, or Godot `ERROR:` occurred

Chromium emitted only the accepted WebGL `ReadPixels` performance warning.

## Corrected Scan Contract

The deterministic Living Expedition 03 integration smoke proves:

1. Reveal Trace exposes the migration filament but grants no identification.
2. The first held Scanner use completes the 1.5-second identification and
   creates exactly one pending shared observation.
3. A repeat use reports `already_identified`, starts no progress, clears the
   held-use state, emits no Scanner pulse, and leaves observation state
   unchanged.
4. The player is directed to return to the surface boat with Mica rather than
   repeating the same scan.
5. Failure still clears only uncommitted observation state; a fresh retry can
   identify the trace normally.
6. Canonical-boat return commits `Followed the Bloom` once, night consolidation
   grants Drift Lens, and next-sortie Read Drift remains intact.

The correction also removes the stale large Reveal Trace prompt from the
pending-return capture state. No generated captures or baselines were
committed.

## Stable Areas

No drift was found in default-map startup, explicit slice fallback,
desktop/wide framing, iPhone-landscape placement, touch alignment, isolated
profile behavior, named checkpoint selection, boat commitment, night Drift
Lens consolidation, or next-sortie Read Drift behavior.

The correction changed no map source, topology, assets, accepted baselines,
generated captures, or export workflow. The push runs for
[Godot Smoke 31262131730](https://github.com/joeypshell/oceangame2/actions/runs/31262131730)
and [Progression Audit 31262131719](https://github.com/joeypshell/oceangame2/actions/runs/31262131719)
also passed.

This technical PASS does not decide whether the Mica journey is understandable
or motivating. Issue #1285 remains the human GO/HOLD gate.

## Verification

```powershell
gh run view 31262131714 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 0e92dd77fa6dccf8cde4969111a101d225bd354e --checkpoint living_expedition_03_start
python tools/check_file_lengths.py
git diff --check
```
