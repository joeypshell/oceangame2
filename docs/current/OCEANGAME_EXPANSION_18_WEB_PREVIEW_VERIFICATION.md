# OceanGame Expansion 18 Web Preview Verification

Date: 2026-08-03

Issue: #1213 `Review and deploy Expansion 18 owner-HOLD corrections`

## Result

**PASS for the corrected exact deployment, deterministic Transfer Hub journey,
browser initialization, responsive framing, and mobile controls.**

- exact SHA: `fb4aa9645ffa44ba9540c4f25a3fe60421af1270`
- build version: `fb4aa96`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Smoke run 30821673739](https://github.com/joeypshell/oceangame2/actions/runs/30821673739):
  source/map validation, core runtime, and regional journey jobs passed
- [Progression Audit run 30821673820](https://github.com/joeypshell/oceangame2/actions/runs/30821673820):
  focused fixtures and source-derived progression graph passed
- [Godot Web Export run 30821674224](https://github.com/joeypshell/oceangame2/actions/runs/30821674224):
  export browser check and GitHub Pages deployment passed

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=fb4aa9645ffa44ba9540c4f25a3fe60421af1270`
- focused Expansion 18 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=fb4aa9645ffa44ba9540c4f25a3fe60421af1270&checkpoint=expansion_18_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=fb4aa9645ffa44ba9540c4f25a3fe60421af1270&map=production_slice_01`

## Exact Build Evidence

Public `build_info.json` reports the exact full SHA, clean `main`, and build
timestamp `2026-08-03T09:14:10-05:00`. The repository Web checker confirmed:

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

The public desktop probe opened `expansion_18_start` and reported:

```text
Review checkpoint active: id=expansion_18_start persistence=false propulsion_fins=true.
Web map active: map=production_level_01 review=true.
```

The checkpoint starts at the canonical boat with the wreck-network
triangulation committed and the navigation core unresolved. It does not read
or mutate the normal durable profile. Its source-owned objective reads
`Transfer Hub | Descend to lowest central chamber | Find marked bulkhead` and
remains active at unrelated legacy current gates.

The exact public build's general iPhone-landscape probe confirmed:

- the canvas covers and remains centered in the 844x390 visual viewport
- cargo, gear, status, active tools, movement, and command controls render
- no request, page, browser-console, or Godot error occurred

The accepted `844x390` focused interior captures confirm the chained core and
mission guidance remain legible beside ACT/USE controls.

## Journey Contract

The exact-SHA `--smoke-expansion-18-transfer-hub` run passed the complete
deterministic journey:

1. The discovered exterior entrance accepts `E`/`ACT` and loads
   `transfer_hub_interior_01` without resetting the sortie.
2. Oxygen, daylight, health, cargo, held materials, and mission guidance remain
   continuous inside.
3. The navigation core is visibly chain-sealed; the Cutter uses `Space`/`USE`,
   and full cargo leaves the core retryable instead of deleting it.
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
for the intentional exterior entrance and corrected compact interior views.

No stale Expansion 17 triangulation command is present: the checkpoint begins
after the automatic two-half comparison and directs the player toward the
physically reached Transfer Hub. The exact-SHA browser probe itself made no
runtime, map, asset, workflow, capture, or baseline change.

## Recorded Owner Decision

This technical PASS did not answer the milestone exit question. The subsequent
owner review closed #1201 with strategic HOLD: the Transfer Hub remains valid
regression foundation, but extending its clue, recipe, gate, and scan cadence is
not the active product direction. See `OCEANGAME_EXPANSION_18_CLOSEOUT.md`.

## Verification

```powershell
gh run view 30821673739 --repo joeypshell/oceangame2
gh run view 30821673820 --repo joeypshell/oceangame2
gh run view 30821674224 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha fb4aa9645ffa44ba9540c4f25a3fe60421af1270
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . -- --smoke-expansion-18-transfer-hub
python tools/check_file_lengths.py
git diff --check
```
