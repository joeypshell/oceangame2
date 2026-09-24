# Living Expedition 07 Web Verification

Date: 2026-09-20

Issue: #1396

Status: **HISTORICAL #1396 WEB EVIDENCE**

Current verdict: [#1397 closeout](LIVING_EXPEDITION_07_CLOSEOUT.md) records owner
GO on 2026-09-23 at corrected runtime `7a78592`, after #1405/#1408. The dated
results below remain historical and are not fresh runs against that runtime.

The warnings below describe `5819f1d`, before the bounded #1405 health-bar
repair. See [diagnosis and regression evidence](LE07_WEBGL_BUFFER_DIAGNOSTIC.md)
and #1405's completion comment for the subsequent exact deployed build.

## Exact Build

At this review, the public preview served the #1395 integration merge:

- full SHA: `5819f1d46425a5c6b0e3c4c5f2e0448b915816f3`
- version: `5819f1d`; `git_ref=main`; `dirty=false`
- generated timestamp: `2026-09-20T11:43:21-05:00`
- [Godot Smoke 35523568223](https://github.com/joeypshell/oceangame2/actions/runs/35523568223): passed
- [Progression Audit 35523568242](https://github.com/joeypshell/oceangame2/actions/runs/35523568242): passed
- [Web export and Pages 35523568233](https://github.com/joeypshell/oceangame2/actions/runs/35523568233): passed;
  local served-export verification passed before deployment, and the Pages job
  completed at `2026-09-20T16:48:14Z`

The external public `build_info.json` was also read independently with cache
bypass. This documentation-only review does not redeploy gameplay. Review query
strings isolate profile state and aid cache-busting; they do not make Pages an
immutable host for this SHA after a later deployment.

## Short Owner Review

Arrival correction #1408 supersedes the original refuge-entry instruction:
the field starts now use the source approach outside the eel's warning range.
See [current steps and live regression](tooling/living_expedition_07.md#isolated-starts).
The evidence and exact SHA below remain historical #1396 results.

These independent shortcuts avoid repeating the equipment chain. Each resets
only its own in-memory review session; it does not touch the normal save.

1. [Refuge, before growth](https://joeypshell.github.io/oceangame2/?review=5819f1d46425a5c6b0e3c4c5f2e0448b915816f3&checkpoint=living_expedition_07_refuge):
   swim a short distance right until the eel warns, then press `B`, `2` for
   Excavate. When it lunges, swim left back past the starting spot while staying
   near the arch. Look for the scallops' retreat and the boat-return instruction.
2. [Night choice at the boat](https://joeypshell.github.io/oceangame2/?review=5819f1d46425a5c6b0e3c4c5f2e0448b915816f3&checkpoint=living_expedition_07_night):
   press `N`. `B` switches Root Claws / Not tonight; `Space` confirms the visible
   choice. This start already has the memory committed, not the adaptation.
3. [Next-day Ground Pin](https://joeypshell.github.io/oceangame2/?review=5819f1d46425a5c6b0e3c4c5f2e0448b915816f3&checkpoint=living_expedition_07_pin):
   lure the eel low over the refuge ledge, then `B` and the numbered Ground Pin
   command when enabled. If it says the eel is too high or not warning/lunging,
   close with `B` and reposition. During the grip, use the Shock Prod or retreat.

Mobile uses sequential `BOND`, `TOOL`, `USE`, not a held chord. At night use
`DAY`, `BOND` to choose, and `USE` to confirm. Local launch commands and the
same short route are in [review tooling](tooling/living_expedition_07.md).

The owner review asked whether growing Root Claws made Marl understandable and
useful, or the pin remained fiddly/redundant. The later [closeout](LIVING_EXPEDITION_07_CLOSEOUT.md)
records "Right it seemed to work fine" as bounded owner GO, not automation-based
acceptance or measured replay motivation. No fourth species or release batch begins here.

## Browser Evidence

The existing public checker passed separately for all three named checkpoints:

| Surface | Observed result |
| --- | --- |
| Root / fresh review | `production_level_01`; fresh review reports `persistence=false propulsion_fins=false` |
| Each LE07 checkpoint | Exact id, `production_level_01`, `persistence=false propulsion_fins=true`, on desktop and touch |
| Desktop / wide root | `1280x720` / `1920x1080`; framing thumbnail mean difference `1.32`, below `18` |
| Landscape touch | `844x390` CSS at `(0,0)`, `2532x1170` intrinsic, zero visual-viewport offset, no independently fixed canvas |
| Movement + nine touch buttons | All reported checkpoint and root pressed-state differences exceeded `2`; minimum checkpoint value was `4.91` |
| Retained slice | Explicit isolated `production_slice_01` initialized at desktop and mobile sizes |

Logs are ignored `tmp/le07-web-{refuge,night,pin}.log`. The checker saves root
screenshots; those alone do not establish checkpoint presentation or action
semantics. Supplemental ordinary Playwright keyboard/CDP-touch input and
screenshots are under `tmp/living_expedition_07/web/<checkpoint>-<size>/`:

- Refuge, desktop/mobile: BOND menu opened, TOOL changed selection to Excavate,
  USE started physical digging, and rightward movement changed the diver's
  position relative to the ledge. The arch and group remained visible.
- Night, desktop/mobile: DAY/N opened the debrief; BOND/B cycled the deliberate
  choice; USE/Space confirmed Root Claws. Habitat and debrief reported the
  confirmed growth. An earlier separate run also confirmed Not tonight.
- Pin, wide/mobile: adapted fins, contextual Ground Pin and its floor/phase
  denial were visible; TOOL/USE and subsequent movement dispatched. This brief
  browser probe did not complete a held-pin encounter. Physical contact/hold/
  release evidence comes from the inspected real-Main native captures and
  [integrated journey](LIVING_EXPEDITION_07_INTEGRATED_VERIFICATION.md).

These probes use fresh browser contexts and ordinary inputs, not runtime-state
injection. `result.json` records markers, warnings and error categories beside
each screenshot sequence. No failed request, HTTP failure, JavaScript page
error, Godot `SCRIPT ERROR`, or Godot `ERROR:` appeared in these probes. No such
error appeared in the three standard checker logs either.

## Warnings And Limits

Chromium emitted the usual `ReadPixels` performance warning. Additionally,
both LE07 field checkpoints emitted repeated WebGL `INVALID_OPERATION`
warnings for `bindBuffer` (element-array target mismatch) and `bufferSubData`
(no buffer), at desktop/wide and touch sizes. Night and the older
`living_expedition_05_excavate_ready` control did not reproduce them.

The inspected field subjects and controls rendered and worked, but this is
**not** a claim of a warning-free console or proof that all rendering operations
succeeded. [Diagnostic follow-up #1405](https://github.com/joeypshell/oceangame2/issues/1405)
isolated the eel health-bar draw path and supplied a bounded repair; no runtime
repair or warning suppression was folded into this original #1396 review.

Chromium touch emulation is not an iPhone Safari device test. The dense inherited
diagnostic HUD, small mobile text, and subtle fin detail remain presentation
limits. The native evidence uses capture-only framing and deterministic steps;
it must not be described as a continuous real-time Web playthrough.

## Verification

```powershell
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 5819f1d46425a5c6b0e3c4c5f2e0448b915816f3 --checkpoint living_expedition_07_refuge
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 5819f1d46425a5c6b0e3c4c5f2e0448b915816f3 --checkpoint living_expedition_07_night
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 5819f1d46425a5c6b0e3c4c5f2e0448b915816f3 --checkpoint living_expedition_07_pin
python tools/check_file_lengths.py
git diff --check
```

Playwright was loaded from the installed local dependency runtime through
`NODE_PATH`; no repository dependencies were installed. The ignored supplemental
probe is `tmp/le07-browser-review.cjs <checkpoint> <desktop|wide|mobile>`.
Visual commands, eighteen native frames, retained comparison sheets, and the
no-baseline-acceptance decision are in the [visual record](LIVING_EXPEDITION_07_VISUAL_DECISION.md).
The 129-gate #1395 release run was reused, not repeated for docs-only work.
