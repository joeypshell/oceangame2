# Living Expedition 06 Web Verification

Date: 2026-08-13

Issue: #1374

Status: **TECHNICAL PASS; OWNER GO RECORDED IN CLOSEOUT**

## Result

The exact public build initializes the complete Signal Reef Nursery review
surface. Both adaptation-ready checkpoints and the restored next-day nursery
load on the full production level with isolated profiles, required equipment,
Kite as the active companion, and responsive desktop/mobile framing.

This proves deployment and review readiness. It does not decide whether the
adaptation feels satisfying or whether the changed nursery motivates another
visit. The owner's separate 2026-09-06 GO through #1375 is recorded in the
[closeout](LIVING_EXPEDITION_06_CLOSEOUT.md).

- exact runtime SHA: `16300a9ca4cbe93b5e4ab74ffa6707cf049646a0`
- build version: `16300a9`
- `git_ref`: `main`
- `dirty`: `false`
- generated timestamp: `2026-08-13T22:04:24-05:00`
- [Web export and Pages run 31765637507](https://github.com/joeypshell/oceangame2/actions/runs/31765637507):
  export runtime check and Pages deployment passed
- [Godot Smoke run 31765637634](https://github.com/joeypshell/oceangame2/actions/runs/31765637634):
  source/map, core runtime, and regional journey jobs passed
- [Progression Audit run 31765637553](https://github.com/joeypshell/oceangame2/actions/runs/31765637553):
  progression audit passed

## Public Review

- [Anchor Fins branch](https://joeypshell.github.io/oceangame2/?review=16300a9ca4cbe93b5e4ab74ffa6707cf049646a0&checkpoint=living_expedition_06_anchor_ready)
- [Guardian Pulse branch](https://joeypshell.github.io/oceangame2/?review=16300a9ca4cbe93b5e4ab74ffa6707cf049646a0&checkpoint=living_expedition_06_guardian_ready)
- [Restored next-day nursery](https://joeypshell.github.io/oceangame2/?review=16300a9ca4cbe93b5e4ab74ffa6707cf049646a0&checkpoint=living_expedition_06_restored_nursery)
- [Fresh isolated profile](https://joeypshell.github.io/oceangame2/?review=16300a9ca4cbe93b5e4ab74ffa6707cf049646a0)

Each checkpoint reports its id, `persistence=false`, and Propulsion Fins
ownership. It cannot read, delete, or write the normal durable profile.

## Browser Evidence

The independent post-deployment checker ran separately for all three named
checkpoints and confirmed:

- public `build_info.json` reports the exact full SHA above;
- root and checkpoint pages initialize `production_level_01`;
- desktop canvas is `1280x720` and wide canvas is `1920x1080`;
- touch-mobile canvas is `2532x1170` intrinsic at `844x390` CSS, positioned at
  `(0, 0)` with zero visual-viewport offset;
- movement and every mobile command control, including BOND, TOOL, and USE,
  exceeded the required pixel-difference threshold in every checkpoint;
- the reference-slice framing mean difference was `1.33`, below the maximum
  `18`;
- no failed request, page error, Godot `SCRIPT ERROR`, or Godot `ERROR:` was
  emitted.

Chromium emitted only the accepted WebGL `ReadPixels` performance warning.
Focused visual inspection also confirmed that each branch setup is readable,
the restored nursery visibly contains the larger school, equipment context
remains present, and the status panel does not cover the reviewed subjects.

## Preserved Boundaries

- The generated 12-frame LE06 evidence set remains ignored and uncommitted.
- Accepted baselines for the full level, slices 01-04, and transfer hub remain
  clean and unchanged.
- Terrain, topology, rewards, equipment access, companion identity, and profile
  ownership did not change during visual or Web review.
- #52/#53 remain deferred optional slice-03 presentation work.

## Verification

```powershell
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 16300a9ca4cbe93b5e4ab74ffa6707cf049646a0 --checkpoint living_expedition_06_anchor_ready
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 16300a9ca4cbe93b5e4ab74ffa6707cf049646a0 --checkpoint living_expedition_06_guardian_ready
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 16300a9ca4cbe93b5e4ab74ffa6707cf049646a0 --checkpoint living_expedition_06_restored_nursery
python tools/check_file_lengths.py
git diff --check
```

The owner comparison closed with GO through #1375. Public metadata was
rechecked on 2026-09-06 and still matched the exact runtime above; the browser
evidence remains the original technical pass, not a new matrix run. No next
milestone is started by this closeout.
