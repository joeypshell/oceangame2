# OceanGame Expansion 18 Web Preview Verification

Date: 2026-08-02

Issue: #1200 `Verify exact public Web preview for Expansion 18`

## Result

**PASS for the exact deployment, deterministic Transfer Hub journey,
browser initialization, responsive framing, and mobile ACT/USE controls.**

- exact SHA: `6889c5017f4dbb27c8126f6d34e547a8a34dfbcc`
- build version: `6889c50`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Smoke run 30768641513](https://github.com/joeypshell/oceangame2/actions/runs/30768641513):
  source/map validation, core runtime, and regional journey jobs passed
- [Progression Audit run 30768641514](https://github.com/joeypshell/oceangame2/actions/runs/30768641514):
  focused fixtures and source-derived progression graph passed
- [Godot Web Export run 30768730618](https://github.com/joeypshell/oceangame2/actions/runs/30768730618):
  export browser check and GitHub Pages deployment passed

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=6889c5017f4dbb27c8126f6d34e547a8a34dfbcc`
- focused Expansion 18 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=6889c5017f4dbb27c8126f6d34e547a8a34dfbcc&checkpoint=expansion_18_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=6889c5017f4dbb27c8126f6d34e547a8a34dfbcc&map=production_slice_01`

## Exact Build Evidence

Public `build_info.json` reports the exact full SHA, clean `main`, and build
timestamp `2026-08-02T16:50:06-05:00`. The repository Web checker confirmed:

- root continuing play and fresh isolated review load `production_level_01`
- the retained Expansion 14 checkpoint still initializes
- the explicit fallback loads `production_slice_01`
- desktop canvas: 1280x720
- wide canvas: 1920x1080
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` with zero visual-viewport offset
- mobile touch differences are `8.60` for move-down, `4.91` for oxygen,
  `5.60` for build/project, and `5.10` for use, all above the required `2`
- framing mean difference is `1.33`, below the maximum `18`
- no failed requests, page errors, browser-console failures, Godot
  `SCRIPT ERROR`, or Godot `ERROR:` occurred

Chromium emitted only the accepted WebGL `ReadPixels` performance warnings.

## Expansion 18 Checkpoint

Separate public desktop and touch-emulated iPhone-landscape probes opened
`expansion_18_start`. Both reported:

```text
Review checkpoint active: id=expansion_18_start persistence=false propulsion_fins=true.
Web map active: map=production_level_01 review=true.
```

The checkpoint starts at the canonical boat with the wreck-network
triangulation committed and the navigation core unresolved. It does not read
or mutate the normal durable profile. On the live mobile build:

- the canvas covers and remains centered in the 844x390 visual viewport
- cargo, gear, status, active tools, movement, and command controls render
- pressed-state differences are `5.19` for `ACT` and `5.46` for `USE`
- no request, page, browser-console, or Godot error occurred

## Journey Contract

The exact-SHA `--smoke-expansion-18-transfer-hub` run passed the complete
deterministic journey:

1. The discovered exterior entrance accepts `E`/`ACT` and loads
   `transfer_hub_interior_01` without resetting the sortie.
2. Oxygen, daylight, health, cargo, held materials, and the pinned plan remain
   continuous inside.
3. The Cutter uses `Space`/`USE`; full cargo leaves the navigation core
   retryable instead of deleting it.
4. The paired return restores `production_level_01` with the core still held.
5. Hazard, manual reset, oxygen failure, and health failure restore unbanked
   core state correctly.
6. Only the canonical boat commits the core, exactly once, with result text
   `Navigation core delivered | Transfer Hub core ready for night analysis`.

The smoke also reports `no_interior_bank_refill_night=true`; the exceptional
interior is not a normal connector, extraction, oxygen-refill, banking, night,
or fast-travel destination. Legacy connector behavior remains unchanged.

## Stable Areas

No deployment drift was found in the public default map, explicit slice
fallback, terrain/collision parity, accepted visual baselines, desktop/wide
framing, iPhone-landscape canvas placement, touch alignment, or isolated
profile behavior. The Expansion 18 visual decision remains the source of truth
for the intentional exterior entrance and accepted compact interior views.

No stale Expansion 17 triangulation command is present: the checkpoint begins
after the automatic two-half comparison and directs the player toward the
physically reached Transfer Hub. No gameplay, map, asset, capture, workflow, or
baseline file changed during this verification.

## Remaining Owner Gate

This technical PASS does not answer the milestone exit question. Issue #1201
must still judge whether entering the discovered place, recovering its core,
and carrying it back through the ocean feels like one earned expedition rather
than a teleport or reset.

## Verification

```powershell
gh run view 30768641513 --repo joeypshell/oceangame2
gh run view 30768641514 --repo joeypshell/oceangame2
gh run view 30768730618 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 6889c5017f4dbb27c8126f6d34e547a8a34dfbcc
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . -- --smoke-expansion-18-transfer-hub
python tools/check_file_lengths.py
git diff --check
```
